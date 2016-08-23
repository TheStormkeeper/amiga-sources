
*				eval.library v2.0
*				~~~~~~~~~~~~~~~~~


* Options de compilation
* ~~~~~~~~~~~~~~~~~~~~~~
	OPT O+

* Les includes
* ~~~~~~~~~~~~
	incdir "hd1:include/"
	incdir "asm:.s/Eval/include/"

	include "exec/types.i"
	include "exec/exec_lib.i"
	include "exec/libraries.i"
	include "exec/initializers.i"
	include "exec/resident.i"
	include "exec/memory.i"
	include "math/mathffp_lib.i"
	include "math/mathtrans_lib.i"
	include "misc/macros.i"

	include "libraries/evalbase.i"
	include "libraries/eval.i"
	include "libraries/eval_lib.i"

VERSION=2
REVISION=0

* Juste pour eviter que le user n'execute la library
* ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
	moveq #0,d0
	rts

* Definition du ROM-TAG
* ~~~~~~~~~~~~~~~~~~~~~
RomTag	dc.w RTC_MATCHWORD
	dc.l RomTag
	dc.l EndTag
	dc.b RTF_AUTOINIT
	dc.b VERSION
	dc.b NT_LIBRARY
	dc.b 0
	dc.l EvalLibName
	dc.l EvalLibID
	dc.l Init
EndTag

* datas pour le chargement de la library
* ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
Init	dc.l EvalBase_SIZEOF
	dc.l FuncTable
	dc.l DataTable
	dc.l InitRoutine

FuncTable
	dc.l Open,Close,Expunge,Reserved
	dc.l AllocToken
	dc.l FreeToken
	dc.l TokenUpCase
	dc.l Tokenize
	dc.l Evaluate
	dc.l -1

DataTable
	INITBYTE LN_TYPE,NT_LIBRARY
	INITLONG LN_NAME,EvalLibName
	INITBYTE LIB_FLAGS,LIBF_SUMUSED!LIBF_CHANGED
	INITWORD LIB_VERSION,VERSION
	INITWORD LIB_REVISION,REVISION
	INITLONG LIB_IDSTRING,EvalLibID
	dc.l 0

EvalLibName
	EVALNAME
MathFFPName
	FFPNAME
MathTransName
	MATHTRANSNAME

EvalLibID
	dc.b "$VER: eval.library v",VERSION+48,".",REVISION+48
	dc.b " (c) 1993 Pierre 'Sync/DreamDealers' Chalamet",0


* Routine appell�e juste apr�s que la library soit charg�e en m�moire
* ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
*  -->	d0=Evalbase
*	a0=SegList
*	a6=ExecBase
InitRoutine
	exg d0,a5
	move.l a0,ev_SegList(a5)	sauve la seglist de la library
	move.l a6,ev_ExecBase(a5)
	exg d0,a5			on sort avec d0=EvalBase
	rts


* Functions syst�me de la library
* ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
Open
	move.l a5,-(sp)
	move.l a6,a5

	lea MathFFPName(pc),a1		ouvre la mathffp.library
	moveq #0,d0			--> fonctions basics ffp
	CALL ev_ExecBase(a5),OpenLibrary
	move.l d0,ev_MathBase(a5)
	beq.s .ret

	lea MathTransName(pc),a1	ouvre la mathtrans.library
	moveq #0,d0
	CALL OpenLibrary
	move.l d0,ev_MathTransBase(a5)
	beq.s .ret

	addq.w #1,LIB_OPENCNT(a5)	c'est OK => on sort en donnant l'adr
	bclr #LIBB_DELEXP,ev_Flags(a5)	de base de la library
	move.l a5,d0
	move.l a5,a6

.ret	move.l (sp)+,a5
	rts


Close
	move.l a5,-(sp)
	move.l a6,a5

	move.l ev_MathTransBase(a5),a1
	CALL ev_ExecBase(a5),CloseLibrary

	move.l ev_MathBase(a5),a1
	CALL CloseLibrary

	moveq #0,d0
	subq.w #1,LIB_OPENCNT(a5)
	bne.s .no_expunge
	bne.s Expunge
.no_expunge
	move.l a5,a6
	move.l (sp)+,a5
	rts


Expunge
	movem.l d2/a5/a6,-(sp)

	move.l a6,a5
	move.l ev_ExecBase(a5),a6
	tst.w LIB_OPENCNT(a5)
	beq.s .do_expunge
	bset #LIBB_DELEXP,ev_Flags(a5)
	moveq #0,d0
	bra.s .ret
.do_expunge
	move.l ev_SegList(a5),d2

	move.l a5,a1
	CALL Remove

	move.l a5,a1
	moveq #0,d0
	move.w LIB_NEGSIZE(a1),d0
	sub.l d0,a1
	CALL FreeMem

	move.l d2,d0
.ret	movem.l (sp)+,d2/a5/a6
	rts


Reserved
	moveq #0,d0
	rts


* Inclusion des fonctions publiques de la library
* ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
	include "Eval_Functions.s"
