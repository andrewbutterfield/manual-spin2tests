/* SPDX-License-Identifier: BSD-2-Clause */

/*
 * Copyright (C) 2019, 2020 Trinity College Dublin, Ireland
 *
 * Redistribution and use in source and binary forms, with or without
 * modification, are permitted provided that the following conditions are
 * met:
 *
 *     * Redistributions of source code must retain the above copyright
 *       notice, this list of conditions and the following disclaimer.
 *
 *     * Redistributions in binary form must reproduce the above
 *       copyright notice, this list of conditions and the following
 *       disclaimer in the documentation and/or other materials provided
 *       with the distribution.
 *
 * THIS SOFTWARE IS PROVIDED BY THE COPYRIGHT HOLDERS AND CONTRIBUTORS
 * "AS IS" AND ANY EXPRESS OR IMPLIED WARRANTIES, INCLUDING, BUT NOT
 * LIMITED TO, THE IMPLIED WARRANTIES OF MERCHANTABILITY AND FITNESS FOR
 * A PARTICULAR PURPOSE ARE DISCLAIMED. IN NO EVENT SHALL THE COPYRIGHT
 * OWNER OR CONTRIBUTORS BE LIABLE FOR ANY DIRECT, INDIRECT, INCIDENTAL,
 * SPECIAL, EXEMPLARY, OR CONSEQUENTIAL DAMAGES (INCLUDING, BUT NOT
 * LIMITED TO, PROCUREMENT OF SUBSTITUTE GOODS OR SERVICES; LOSS OF USE,
 * DATA, OR PROFITS; OR BUSINESS INTERRUPTION) HOWEVER CAUSED AND ON ANY
 * THEORY OF LIABILITY, WHETHER IN CONTRACT, STRICT LIABILITY, OR TORT
 * (INCLUDING NEGLIGENCE OR OTHERWISE) ARISING IN ANY WAY OUT OF THE USE
 * OF THIS SOFTWARE, EVEN IF ADVISED OF THE POSSIBILITY OF SUCH DAMAGE.
 */
 
// Sizings, MEM_SIZE = 2 ** PTR_SIZE
#define PTR_SIZE 3
#define MEM_SIZE 8

// Nodes types
typedef Node {
  unsigned nxt  : PTR_SIZE
; unsigned prv  : PTR_SIZE
; byte     itm
}

inline ncopy (dst,src) {
  dst.nxt = src.nxt; dst.prv=src.prv; dst.itm = src.itm
}

// Memory
Node memory[MEM_SIZE] ;
unsigned nptr : PTR_SIZE ;  // one node pointer

inline show_node (){
   atomic{
     printf("@@@PTR nptr %d\n",nptr);
     if
     :: nptr -> printf("@@@STRUCT nptr\n");
                printf("@@@PTR nxt %d\n", memory[nptr].nxt);
                printf("@@@PTR prv %d\n", memory[nptr].prv);
                printf("@@@SCALAR itm %d\n", memory[nptr].itm);
                printf("@@@END nptr\n")
     :: else -> skip
     fi
   }
}

typedef Control {
  unsigned head : PTR_SIZE
; unsigned tail : PTR_SIZE
; unsigned size : PTR_SIZE
}

Control chain ; // one chain


inline show_chain () {
   int cnp;
   atomic{
     cnp = chain.head;
     printf("@@@SEQ chain\n");
     do
       :: (cnp == 0) -> break;
       :: (cnp != 0) ->
            printf("@@@SCALAR _ %d\n",memory[cnp].itm);
            cnp = memory[cnp].nxt
     od
     printf("@@@END chain\n");
   }
}

inline append(ch,np) {
  assert(np!=0);
  assert(ch.size < 7);
  if
    :: (ch.head == 0) ->
         ch.head = np;
         ch.tail = np;
         ch.size = 1;
         memory[np].nxt = 0;
         memory[np].prv = 0;
    :: (ch.head != 0) ->
         memory[ch.tail].nxt = np;
         memory[np].prv = ch.tail;
         ch.tail = np;
         ch.size = ch.size + 1;
  fi
}

proctype doAppend(int addr; int val) {
  atomic{
    memory[addr].itm = val;
    append(chain,addr);
    printf("@@@CALL append %d %d\n",val,addr);
    show_chain();
  } ;
}

/* np = get(ch) */
inline get(ch,np) {
  np = ch.head ;
  if
    :: (np != 0) ->
         ch.head = memory[np].nxt;
         ch.size = ch.size - 1;
         // memory[np].nxt = 0
    :: (np == 0) -> skip
  fi
  if
    :: (ch.head == 0) -> ch.tail = 0
    :: (ch.head != 0) -> skip
  fi
}

proctype doGet() {
  atomic{
    get(chain,nptr);
    printf("@@@CALL get %d\n",nptr);
    show_chain();
    assert(nptr != 0);
    show_node();
  } ;
}

/* -----------------------------
 doNonNullGet waits for a non-empty chain
 before doing a get.
 In generated sequential C code this can be simply be treated
  the same as a call to doGet()
*/
proctype doNonNullGet() {
  atomic{
    chain.head != 0;
    get(chain,nptr);
    printf("@@@CALL getNonNull %d\n",nptr);
    show_chain();
    assert(nptr != 0);
    show_node();
  } ;
}


init {
  pid nr;
  atomic{
    printf("\n\n Chain Model running.\n");
    printf("@@@NAME Chain_AutoGen\n")
    printf("@@@DEF MAX_SIZE 8\n");
    printf("@@@DECL Node memory[MAX_SIZE]\n");
    printf("@@@DECL unsigned nptr NULL\n")
    printf("@@@DECL Control chain\n");

    printf("\nInitialising...\n")
    printf("@@@INIT\n");
    chain.head = 0; chain.tail = 0; chain.size = 0;
    show_chain();
    show_node();
  } ;

  nr = _nr_pr;

  run doAppend(6,21);
  run doAppend(3,22);
  run doAppend(4,23);
  run doNonNullGet();
  run doNonNullGet();
  run doNonNullGet();

  nr == _nr_pr;

  assert (chain.size != 0);

  printf("\nChain Model finished !\n\n")
}
