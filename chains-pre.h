/******************************************************************************
 * FV2-201
 *
 * Copyright (c) 2020 Trinity College Dublin, Ireland
 *
 * All rights reserved.
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
 *     * Neither the name of the copyright holders nor the names of its
 *       contributors may be used to endorse or promote products derived
 *       from this software without specific prior written permission.
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
 ******************************************************************************/


#include <tmacros.h>
#include <rtems.h>
#include <t.h>
#include <rtems/score/chain.h>

static const T_config config = {
    .name = "Promela-Chains",
    .putchar = T_putchar_default,
    .verbosity = T_VERBOSE,
    .now = T_now_clock
};


rtems_chain_control chain;

typedef struct item
{
    rtems_chain_node node;
    int               val;
} item;

item* get_item( rtems_chain_control* control);
item* get_item( rtems_chain_control* control)
{
    return (item*) rtems_chain_get(control);
}

#define BUFSIZE 80
char buffer[BUFSIZE];


void show_chain(rtems_chain_control *control, char *str);
void show_chain(rtems_chain_control *control, char *str)
{
    item *itm;
    rtems_chain_node *nod;
    int cp, len;
    char *s;

    nod = (rtems_chain_node *)&control->Head;
    itm = (item *)nod->next;
    s = str;
    len = BUFSIZE;
    while (itm) {
        cp = T_snprintf(s, len, " %d",itm->val);
        s += cp;
        len -= cp;
        itm = (item*)((rtems_chain_node*)itm)->next;
     }
}
