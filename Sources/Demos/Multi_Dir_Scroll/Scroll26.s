
*
*	Scrolling multidirectionnel ( for Nounours' Land ??? )
*	~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
*		Done in 1993 by Sync/DreamDealers
*		~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
*
* l'IT pour la synchro ecran est assur�e par le copper juste au d�but
* du panel( en $eb01 ) => evite une 2�me coplist lourde a g�rer.
*


	OPT C+,O-


	incdir "asm:"
	incdir "Blocks"
	incdir "asm:songs/medium"
	incdir "ram:"

	include "sources/registers.i"

* EQU pour le heros
* ~~~~~~~~~~~~~~~~~
HERO_X=32
HERO_Y=32

* EQU pour les blocks du scrolling
* ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
BLOCK_X=16
BLOCK_Y=16
BLOCK_DEPTH=4
BLOCK_WIDTH=BLOCK_X/8
BLOCK_SIZE=BLOCK_WIDTH*BLOCK_Y*BLOCK_DEPTH+17*2
HORIZ_BLOCK=20+1
VERT_BLOCK=11+1

* EQU pour la map
* ~~~~~~~~~~~~~~~
MAP_X=80
MAP_Y=80
MAP_WIDTH=MAP_X*2

* EQU pour le heros
* ~~~~~~~~~~~~~~~~~
MIN_X=$f
MIN_Y=0
MAX_X=MAP_X*BLOCK_X-HERO_X-1
MAX_Y=MAP_Y*BLOCK_Y-HERO_Y

* EQU pour les ecrans du scrolling
* ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
BPL_X=320
BPL_Y=176
BPL_DEPTH=4
BPL_MODULO=2
BPL_WIDTH=BPL_X/8+BPL_MODULO
MIN_SCROLL_X=$f
MIN_SCROLL_Y=0
MAX_SCROLL_X=(MAP_X-HORIZ_BLOCK+1)*16-1
MAX_SCROLL_Y=(MAP_Y-VERT_BLOCK+1)*16
MAX_SCROLL_SPEED=3<<16
MIN_BOX_X=160-HERO_X/2
MAX_BOX_X=BPL_X-160+HERO_X/2
MIN_BOX_Y=88-HERO_Y/2
MAX_BOX_Y=BPL_Y-88+HERO_Y/2

* STRUCTURE pour les logiques/physiques
* ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
	rsreset
screen	rs.l 1


* Le programme principal
* ~~~~~~~~~~~~~~~~~~~~~~
	section Nounours,code
	KILL_SYSTEM MAIN
	moveq #0,d0
	rts

MAIN

	lea db(pc),a5
	lea $dff000,a6

	bsr build_map				construit la map
	bsr init_vars				va initialiser les variables
	bsr init_sprites
	bsr build_first_screen			construit les 1er ecrans

	bsr mt_init
	move.l #my_vbl,$6c.w
	move.l #coplist,cop1lc(a6)
	clr.w copjmp1(a6)

	move.w #$87e0,dmacon(a6)
	move.w #$c010,intena(a6)

	WAIT_LMB_DOWN				bon.. y veux sortir le Mr ??!
	bsr mt_end				stop zizik
	RESTORE_SYSTEM				youpla.. return to CLI

my_vbl
	SAVE_REGS

	bsr mt_music

	lea db(pc),a5				\ NE JAMAIS CHANGER
	lea $dff000,a6				/ CES REGISTRES !!!

	move.w #$888,color00(a6)
	bsr rebuild_coplist
	bsr display_hero

	bsr swap_struct
	bsr gestion_joy
	bsr ForeGround_Scrolling

	move.w #$000,color00(a6)
	move.w #$0010,intreq(a6)		sort de l'IT copper
	RESTORE_REGS
	rte



********************************************************************************
*                     INITIALISE TOUTES LES VARIABLES DU JEU                   *
* EN ENTREE : A5=db                                                            *
* EN SORTIE : rien du tout                                                     *
********************************************************************************
init_vars
	move.l #screen_log,d0			ptr ecran sur multiples de 8
	move.l d0,struct_log-db(a5)
	add.l #BPL_WIDTH*(BPL_Y+MAP_Y)*BPL_DEPTH,d0
	move.l d0,struct_phy-db(a5)

	move.w HeroX(pc),d0			centre le personnage au
	sub.w #BPL_X/2-HERO_X/2,d0		beau milieu de l'�cran
	cmp.w #MIN_SCROLL_X,d0			sur les X
	bge.s set_scroll_X
	move.w #MIN_SCROLL_X,d0
set_scroll_X
	move.w d0,ScrollX-db(a5)
	move.w d0,Old_ScrollX-db(a5)
	move.w d0,Very_Old_ScrollX-db(a5)

	move.w HeroY(pc),d0			idem mais sur les Y
	sub.w #BPL_Y/2-HERO_Y/2,d0
	bge.s set_scroll_Y
	move.w #MIN_SCROLL_Y,d0
set_scroll_Y
	move.w d0,ScrollY-db(a5)
	move.w d0,Old_ScrollY-db(a5)
	move.w d0,Very_Old_ScrollY-db(a5)

	move.l #$8000,VIT_X-db(a5)	init les vitesses
	move.l #$8000,VIT_Y-db(a5)
	rts



********************************************************************************
*                         INITIALISE LES SPRITES
* EN ENTREE : A5=db                                                            *
* EN SORTIE : rien du tout                                                     *
********************************************************************************
init_sprites
	move.l #HeroPic0,d0			installe le sprite 0
	move.w d0,install_sprites+4+8*0
	swap d0
	move.w d0,install_sprites+8*0

	move.l #HeroPic1,d0			installe le sprite 1
	move.w d0,install_sprites+4+8*1
	swap d0
	move.w d0,install_sprites+8*1

	move.l #HeroPic2,d0			installe le sprite 2
	move.w d0,install_sprites+4+8*2
	swap d0
	move.w d0,install_sprites+8*2

	move.l #HeroPic3,d0			installe le sprite 3
	move.w d0,install_sprites+4+8*3
	swap d0
	move.w d0,install_sprites+8*3


	lea install_sprites+8*4,a0		installe les sprites 4-7
	move.l #blk_spr,d0
	moveq #4-1,d1
.install_spr
	move.w d0,4(a0)
	swap d0
	move.w d0,(a0)
	swap d0
	addq.l #8,a0
	dbf d1,.install_spr
	rts



********************************************************************************
*                  ECHANGE DES STRUCTURES LOGIQUES ET PHYSIQUES                *
* EN ENTREE : A5=db                                                            *
* EN SORTIE : rien du tout                                                     *
********************************************************************************
swap_struct
	move.l log_struct(pc),a0
	move.l phy_struct(pc),log_struct-db(a5)
	move.l a0,phy_struct-db(a5)
	rts



********************************************************************************
*                             GESTION DU JOYSTICK                              *
* EN ENTREE : A5=db  A6=$dff000                                                *
* EN SORTIE : rien du tout                                                     *
********************************************************************************
gestion_joy
	move.l HeroX(pc),Old_HeroX-db(a5)	pour avoir le Delta X/Y

	move.l VIT_X(pc),d0
	move.l VIT_Y(pc),d1

	move.w joy1dat(a6),d2
	ror.b #2,d2
	lsr.w #4,d2
	and.w #%111100,d2
	jmp JoyRout(pc,d2.w)
JoyRout
	bra.w move_none
	bra.w move_down
	bra.w move_down_right
	bra.w move_right
	bra.w move_up
	bra.w move_none
	bra.w move_none
	bra.w move_up_right
	bra.w move_up_left
	bra.w move_none
	bra.w move_none
	bra.w move_none
	bra.w move_left
	bra.w move_down_left
	bra.w move_none
	bra.w move_none

move_none
	rts

move_left
	move.l #-2<<16,d0
	moveq #0,d1
	bra.s move_speed

move_right
	move.l #2<<16,d0
	moveq #0,d1
	bra.s move_speed

move_up
	moveq #0,d0
	move.l #-2<<16,d1
	bra.s move_speed

move_down
	moveq #0,d0
	move.l #2<<16,d1
	bra.s move_speed

move_up_right
	move.l #2<<16,d0
	move.l #-2<<16,d1
	bra.s move_speed

move_up_left
	move.l #-2<<16,d0
	move.l #-2<<16,d1
	bra.s move_speed

move_down_right
	move.l #2<<16,d0
	move.l #2<<16,d1
	bra.s move_speed

move_down_left
	move.l #-2<<16,d0
	move.l #2<<16,d1

* Modification de la vitesse du heros
* ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
move_speed
	cmp.l #MAX_SCROLL_SPEED,d0		sauve VIT_X
	ble.s .X_ok
	move.l #MAX_SCROLL_SPEED,d0
	bra.s move_set_X
.X_ok
	cmp.l #-MAX_SCROLL_SPEED,d0
	bge.s move_set_X
	move.l #-MAX_SCROLL_SPEED,d0
move_set_X
	move.l d0,VIT_X-db(a5)
	swap d0
	add.w d0,HeroX-db(a5)

	cmp.l #MAX_SCROLL_SPEED,d1		sauve VIT_Y
	ble.s .Y_ok
	move.l #MAX_SCROLL_SPEED,d1
	bra.s move_set_Y
.Y_ok
	cmp.l #-MAX_SCROLL_SPEED,d1
	bge.s move_set_Y
	move.l #-MAX_SCROLL_SPEED,d1
move_set_Y
	move.l d1,VIT_Y-db(a5)
	swap d1
	add.w d1,HeroY-db(a5)

* Fait gaffe que le heros ne sorte pas de l'ecran
* ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
move_tstX_min
	cmp.w #MIN_X,HeroX-db(a5)
	bge.s move_tstX_max
	move.w #MIN_X,HeroX-db(a5)
	clr.l VIT_X-db(a5)
	bra.s move_tstY_min
move_tstX_max
	cmp.w #MAX_X,HeroX-db(a5)
	ble.s move_tstY_min
	move.w #MAX_X,HeroX-db(a5)
	clr.l VIT_X-db(a5)

move_tstY_min
	tst.w HeroY-db(a5)
	bge.s move_tstY_max
	clr.w HeroY-db(a5)
	clr.l VIT_Y-db(a5)
	bra.s move_exit
move_tstY_max
	cmp.w #MAX_Y,HeroY-db(a5)
	ble.s move_exit
	move.w #MAX_Y,HeroY-db(a5)
	clr.l VIT_Y-db(a5)

* Modification du scrolling en fonction du heros
* ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
move_exit
	move.w HeroX(pc),d0
	sub.w Old_HeroX(pc),d0
	beq.s no_moveX
	bpl.s chk_rightX
chk_leftX
	move.w HeroX(pc),d1
	sub.w ScrollX(pc),d1
	cmp.w #MIN_BOX_X,d1
	bge.s no_moveX
	add.w d0,ScrollX-db(a5)
	cmp.w #MIN_SCROLL_X,ScrollX-db(a5)
	bge.s no_moveX
	move.w #MIN_SCROLL_X,ScrollX-db(a5)
	bra.s no_moveX
chk_rightX
	move.w HeroX(pc),d1
	sub.w ScrollX(pc),d1
	cmp.w #MAX_BOX_X,d1
	ble.s no_moveX
	add.w d0,ScrollX-db(a5)
	cmp.w #MAX_SCROLL_X,ScrollX-db(a5)
	ble.s no_moveX
	move.w #MAX_SCROLL_X,ScrollX-db(a5)

no_moveX
	move.w HeroY(pc),d0
	sub.w Old_HeroY(pc),d0
	beq.s no_moveY
	bpl.s chk_downY
chk_upX
	move.w HeroY(pc),d1
	sub.w ScrollY(pc),d1
	cmp.w #MIN_BOX_Y,d1
	bge.s no_moveY
	add.w d0,ScrollY-db(a5)
	bge.s no_moveY
	clr.w ScrollY-db(a5)
	bra.s no_moveY
chk_downY
	move.w HeroY(pc),d1
	sub.w ScrollY(pc),d1
	cmp.w #MAX_BOX_Y,d1
	ble.s no_moveY
	add.w d0,ScrollY-db(a5)
	cmp.w #MAX_SCROLL_Y,ScrollY-db(a5)
	ble.s no_moveY
	move.w #MAX_SCROLL_Y,ScrollY-db(a5)

no_moveY
	rts



********************************************************************************
*                              AFFICHAGE DU HEROS                              *
* EN ENTREE : A5=data_base  A6=$dff000                                         *
* EN SORTIE : rien du tout                                                     *
********************************************************************************
display_hero
	move.w HeroX(pc),d0
	sub.w ScrollX(pc),d0
	move.w HeroY(pc),d1
	sub.w ScrollY(pc),d1
	move.w #HERO_Y<<8,d2
	bsr put_sprite
	or.w #$80,d3
	move.l d3,HeroPic0
	move.l d3,HeroPic1

	move.w HeroX(pc),d0
	sub.w ScrollX(pc),d0
	add.w #16,d0
	move.w HeroY(pc),d1
	sub.w ScrollY(pc),d1
	bsr put_sprite
	or.w #$80,d3
	move.l d3,HeroPic2
	move.l d3,HeroPic3
	rts



********************************************************************************
***************** CALCUL DES 2 MOTS DE CONTROLE D'UN SPRITE ********************
***************** EN ENTREE :  D0=COORD X		    ********************
*****************              D1=COORD Y		    ********************
*****************              D2=HAUTEUR DU SPRITE<<8	    ********************
***************** EN SORTIE :  D3=CONTROL LONG WORD         ********************
********************************************************************************
put_sprite
	moveq #0,d3
	add.w #$2b,d1				recentre sur les Y
	lsl.w #8,d1
	add.w #$80,d0				recentre sur les X
	lsr.w #1,d0				bit 0 dans X
	or.w d1,d0
	move.w d0,d3
	swap d3
	addx.w d3,d3				ins�re X !!
	add.w d2,d1				calcule de vstop
	or.w d1,d3
	rts



********************************************************************************
*                        GESTION COMPLETE DU SCROLLING                         *
* EN ENTREE : A5=db  A6=$dff000                                                *
* EN SORTIE : rien du tout                                                     *
********************************************************************************
ForeGround_Scrolling
	move.l log_struct(pc),a0		recherche l'ecran de travail
	move.l screen(a0),a0
	move.w ScrollX(pc),d0
	move.w d0,d1
	lsr.w #4,d1				/----\  lsr.w #3,d1
	lea (a0,d1.w*2),a0			\----/  and.w #$fffe,d1
	move.l a0,Screen_Ptr-db(a5)

	not.w d0				calcul le delay de l'ecran
	and.w #8*BPL_MODULO-1,d0		8 pixels dans chaque octet
	move.w d0,Screen_Delay-db(a5)

	moveq #0,d0
	move.w ScrollY(pc),d0			recherche le debut et la
	divu.w #BPL_Y+BLOCK_Y,d0		taille de la premiere
	swap d0					partie du scrolling
	move.w d0,First_Part_Start-db(a5)
	neg.w d0
	add.w #BPL_Y+BLOCK_Y,d0
	cmp.w #BPL_Y,d0
	ble.s .not_full_screen_part
	move.w #BPL_Y,d0
.not_full_screen_part
	move.w d0,First_Part_Size-db(a5)

	moveq #0,d0				recherche la fin de la
	move.w ScrollY(pc),d0			2�me partie du scrolling
	add.w #BPL_Y,d0
	divu.w #BPL_Y+BLOCK_Y,d0
	swap d0
	move.w d0,Second_Part_End-db(a5)

	move.l Map_Ptr-db(a5),a0		recherche le pointeur
	move.w ScrollX(pc),d0			sur la map du decor
	lsr.w #4,d0				/----\  lsr.w #3,d0
	lea (a0,d0.w*2),a0			\----/  and.w #$fffe,d0
	move.w ScrollY(pc),d0
	lsr.w #4,d0				divise par 16
	mulu.w #MAP_WIDTH,d0
	lea (a0,d0.l),a0
	move.l a0,Map_Current-db(a5)

	WAIT_BLITTER
	move.l #$09f00000,bltcon0(a6)
	move.l #BPL_WIDTH-BLOCK_WIDTH,bltamod(a6)
	moveq #-1,d0
	move.l d0,bltafwm(a6)
	move.w #BLOCK_Y*BLOCK_DEPTH,bltsizV(a6)



	move.l Map_Current(pc),a0		-------------------------
	move.l Screen_Ptr(pc),a1
	move.w First_Part_Start(pc),d0		init quelques pointeurs
	and.w #$fff0,d0				pour l'affichage vertical
	mulu.w #BPL_WIDTH*BPL_DEPTH,d0
	lea (a1,d0.l),a1			-------------------------

	move.w ScrollX(pc),d0			affichage vertical des blocks
	cmp.w Very_Old_ScrollX(pc),d0		du scrolling
	beq.s .no_scroll_horiz			on a boug� sur les X ?
	blt.s .scroll_left
.scroll_right
	lea (HORIZ_BLOCK-1)*2(a0),a0		*2 car c des mots ds la map !!
	lea BPL_WIDTH-BPL_MODULO(a1),a1
.scroll_left
	bsr Display_Colonne


.no_scroll_horiz
	move.l Map_Current(pc),a0		init quelques pointeurs
	move.w First_Part_Start(pc),d0		pour le scrolling vertical

	move.w ScrollY(pc),d1
	cmp.w Very_Old_ScrollY(pc),d1
	beq.s .no_scroll_vert			on a boug� sur les Y ?
	blt.s .scroll_up
.scroll_down
	lea (VERT_BLOCK-1)*MAP_WIDTH(a0),a0
	move.w Second_Part_End(pc),d0
.scroll_up
	and.w #$fff0,d0
	mulu #BPL_WIDTH*BPL_DEPTH,d0
	move.l Screen_Ptr(pc),a1
	lea (a1,d0.l),a1
	bsr Display_Line

.no_scroll_vert
	move.l Old_ScrollX(pc),Very_Old_ScrollX-db(a5)
	move.l ScrollX(pc),Old_ScrollX-db(a5)
	rts



********************************************************************************
*               REFAIT LA COPLIST POUR BIEN AFFICHER LE SCROLLING              *
* EN ENTREE : A6=$dff000                                                       *
* EN SORTIE : rien du tout                                                     *
********************************************************************************
rebuild_coplist
	move.w Screen_Delay(pc),d0		installe le delay des bitplans
	move.w d0,d1
	and.w #$0f,d0				fabrication des bits 0-7
	move.w d0,d2
	lsl.w #4,d2
	or.w d2,d0
	and.w #$30,d1				fabrication des bits 8-15
	lsl.w #6,d1
	or.w d1,d0
	lsl.w #4,d1
	or.w d1,d0
	move.w d0,install_delay

	move.w First_Part_Start(pc),d0		installe les ptrs videos
	mulu.w #BPL_WIDTH*BPL_DEPTH,d0		pour la 1�re partie du
	add.l Screen_Ptr(pc),d0			scrolling
	and.l #-BPL_MODULO,d0
	lea install_part1,a0
	moveq #BPL_DEPTH-1,d1
.install_part1
	move.w d0,4(a0)				met PtrLow
	swap d0
	move.w d0,(a0)				met PtrHigh
	swap d0
	add.l #BPL_WIDTH,d0
	addq.l #8,a0
	dbf d1,.install_part1

	move.w First_Part_Size(pc),d0		installe le wait
	add.b #$2b-1,d0				-1 : il faut avoir le temps de
	move.b d0,install_wait_cut1		recharger les ptrs bpl
	addq.b #1,d0
	move.b d0,install_wait_cut2

	movec cacr,d0
	or.l #1<<11,d0				clear data_cache
	movec d0,cacr
	rts



********************************************************************************
*                      AFFICHAGE D'UNE COLONNE DE BLOCKS                       *
* EN ENTREE : A0=ptr sur la map  A1=ptr sur l'ecran  A6=$dff000                *
*             bltsizV=BLOCK_Y*BLOCK_DEPTH                                      *
* EN SORTIE : rien du tout                                                     *
********************************************************************************
Display_Colonne
	moveq #VERT_BLOCK-1,d0
	moveq #0,d1				flag pour l'affichage
	lea Block_Gfx,a2
	move.l Screen_Ptr(pc),a3
	add.l #BPL_WIDTH*(BPL_Y+BLOCK_Y)*BPL_DEPTH,a3
.loop_each_vert_block
	move.w (a0),d2				pointe le bon block
	and.w #$1ff,d2				9 bits = # du block
	mulu #BLOCK_SIZE,d2
	lea (a2,d2.l),a4
	WAIT_BLITTER
	move.l a4,bltapt(a6)			block � copier
	move.l a1,bltdpt(a6)			destination
	move.w #BLOCK_X/16,bltsizH(a6)

	lea MAP_WIDTH(a0),a0			blocks suivant
	lea BPL_WIDTH*BLOCK_Y*BPL_DEPTH(a1),a1	ligne suivante

	tst.w d1				on affiche koi ?
	bne.s .not_end_first_part
	cmp.l a3,a1				on arrive � la fin ?
	blt.s .not_end_first_part
	moveq #-1,d1				on affiche la 2�me partie
	sub.l #BPL_WIDTH*(BPL_Y+BLOCK_Y)*BPL_DEPTH,a1	revient en haut de l'ecran
.not_end_first_part
	dbf d0,.loop_each_vert_block
	rts



********************************************************************************
*                       AFFICHAGE D'UNE LIGNE DE BLOCKS                        *
* EN ENTREE : A0=ptr sur la map  A1=ptr sur l'ecran  A6=$dff000                *
*             bltsizV=BLOCK_Y*BLOCK_DEPTH                                      *
* EN SORTIE : rien du tout                                                     *
********************************************************************************
Display_Line
	moveq #HORIZ_BLOCK-1,d0
	lea Block_Gfx,a2
.loop_each_horiz_block
	move.w (a0)+,d1				pointe le bon block
	and.w #$1ff,d1				9 bits = # du block 
	mulu #BLOCK_SIZE,d1
	lea 0(a2,d1.l),a3
	WAIT_BLITTER
	move.l a3,bltapt(a6)
	move.l a1,bltdpt(a6)
	move.w #BLOCK_X/16,bltsizH(a6)

	addq.l #BLOCK_WIDTH,a1
	dbf d0,.loop_each_horiz_block
	rts	



********************************************************************************
*                       FABRICATION DES ECRANS DE DEPART                       *
* EN ENTREE : A5=db  A6=$dff000                                                *
* EN SORTIE : rien du tout                                                     *
********************************************************************************
build_first_screen
	move.w #$8240,dmacon(a6)		autorise le DMA-blitter

	move.l log_struct(pc),a0		recherche l'ecran de travail
	move.l screen(a0),a0
	move.w ScrollX(pc),d0
	lsr.w #4,d0				/----\  lsr.w #3,d0
	add.w d0,d0				\----/  and.w #$fffe,d0
	lea (a0,d0.w),a0
	move.l a0,Screen_Ptr-db(a5)

	moveq #0,d0
	move.w ScrollY(pc),d0			recherche le debut et la
	divu #BPL_Y+BLOCK_Y,d0			taille de la premiere
	swap d0					partie du scrolling
	move.w d0,First_Part_Start-db(a5)
	neg.w d0
	add.w #BPL_Y+BLOCK_Y,d0
	cmp.w #BPL_Y,d0
	ble.s .not_full_screen_part
	move.w #BPL_Y,d0
.not_full_screen_part
	move.w d0,First_Part_Size-db(a5)

	lea Map,a0				recherche le pointeur
	move.w ScrollX(pc),d0			sur la map du decor
	lsr.w #4,d0
	add.w d0,d0
	lea (a0,d0.w),a0
	move.w ScrollY(pc),d0
	lsr.w #4,d0				divise par 16
	mulu #MAP_WIDTH,d0
	lea (a0,d0.l),a0
	move.l a0,Map_Current-db(a5)

	WAIT_BLITTER
	move.l #$09f00000,bltcon0(a6)
	move.l #BPL_WIDTH-BLOCK_WIDTH,bltamod(a6)
	moveq #-1,d0
	move.l d0,bltafwm(a6)
	move.w #BLOCK_Y*BLOCK_DEPTH,bltsizV(a6)
	


	move.l Map_Current(pc),a0		---------------------------
	move.l Screen_Ptr(pc),a1
	move.w First_Part_Start(pc),d0		init quelques pointeurs
	and.w #$fff0,d0				pour l'affichage horizontal
	mulu #BPL_WIDTH*BPL_DEPTH,d0
	lea (a1,d0.l),a1			---------------------------

	moveq #HORIZ_BLOCK-1,d7			construit l'ecran logique
.build_log_screen
	movem.l a0-a1,-(sp)
	bsr Display_Colonne
	movem.l (sp)+,a0-a1
	addq.l #2,a0				la map est bas�e sur des mots
	addq.l #BLOCK_WIDTH,a1
	dbf d7,.build_log_screen


	move.l phy_struct(pc),a0		recherche l'ecran de travail
	move.l screen(a0),a0
	move.w ScrollX(pc),d0
	lsr.w #4,d0				/----\  lsr.w #3,d0
	add.w d0,d0				\----/  and.w #$fffe,d0
	lea (a0,d0.w),a0
	move.l a0,Screen_Ptr-db(a5)

	move.l Map_Current(pc),a0		---------------------------
	move.l Screen_Ptr(pc),a1
	move.w First_Part_Start(pc),d0		init quelques pointeurs
	and.w #$fff0,d0				pour l'affichage horizontal
	mulu #BPL_WIDTH*BPL_DEPTH,d0
	lea (a1,d0.l),a1			---------------------------

	moveq #HORIZ_BLOCK-1,d7			construit l'ecran logique
.build_phy_screen
	movem.l a0-a1,-(sp)
	bsr Display_Colonne
	movem.l (sp)+,a0-a1
	addq.l #2,a0				la map est bas�e sur des mots
	addq.l #BLOCK_WIDTH,a1
	dbf d7,.build_phy_screen

	WAIT_BLITTER
	move.w #$0240,dmacon(a6)		vire le DMA-blitter
	rts



********************************************************************************
*                           FABRICATION DE LA MAP                              *
* EN ENTREE : A5=db  A6=$dff000                                                *
* EN SORTIE : rien du tout                                                     *
********************************************************************************
build_map
	lea Map,a0
	moveq #MAP_Y/4-1,d0
build_all
	moveq #MAP_X/4-1,d1
build_line1
	move.l #$00000001,(a0)+
	move.l #$00080008,(a0)+
	dbf d1,build_line1
	moveq #MAP_X/4-1,d1
build_line2
	move.l #$00020003,(a0)+
	move.l #$00080008,(a0)+
	dbf d1,build_line2
	moveq #MAP_X/4-1,d1
build_line3
	move.l #$00080008,(a0)+
	move.l #$00000001,(a0)+
	dbf d1,build_line3
	moveq #MAP_X/4-1,d1
build_line4
	move.l #$00080008,(a0)+
	move.l #$00020003,(a0)+
	dbf d1,build_line4
	dbf d0,build_all
	rts



* Les datas du programme
* ~~~~~~~~~~~~~~~~~~~~~~
db

* Datas pour le heros
* ~~~~~~~~~~~~~~~~~~~
VIT_X			dc.l 0
VIT_Y			dc.l 0
ACC_X			dc.l 0
ACC_Y			dc.l 0
HeroX			dc.w 10
HeroY			dc.w 10
Old_HeroX		dc.w 0
Old_HeroY		dc.w 0

* Datas du scrolling
* ~~~~~~~~~~~~~~~~~~
ScrollX			dc.w 0
ScrollY			dc.w 0
Old_ScrollX		dc.w 0
Old_ScrollY		dc.w 0
Very_Old_ScrollX	dc.w 0
Very_Old_ScrollY	dc.w 0
First_Part_Start	dc.w 0
First_Part_Size		dc.w 0
Second_Part_End		dc.w 0
Map_Ptr			dc.l Map
Map_Current		dc.l 0
Screen_Ptr		dc.l 0
Screen_Delay		dc.w 0

* Datas pour les structures logiques et physiques
* ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
log_struct		dc.l struct_log
phy_struct		dc.l struct_phy

struct_log		dc.l 0
struct_phy		dc.l 0

* La replay
* ~~~~~~~~~
	include "asm:sources/TMC_Replay.s"
* La musique
* ~~~~~~~~~~
	include "Song.s"




* Les coplist � fusionner dans la vraie coplist
* ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
	IFNE 0
Degrad_coplist
	dc.w (Degrad_coplist_size/2)-1
color set $f0f
dummy set $2b
	REPT 16
	dc.b dummy,$01
	dc.w $fffe
	dc.w color00,color
	IFEQ (color=$f0f)
	dc.b dummy+1,$01
	dc.w $fffe
	dc.w color00,color+$100-$010
	dc.b dummy+2,$01
	dc.w $fffe
	dc.w color00,color
	ENDC
color set color-$100+$010
dummy set dummy+12
	ENDR
Degrad_coplist_size=(*-(Degrad_coplist+2))/4
	ENDC




	section map,bss
* La map du jeu
* ~~~~~~~~~~~~~
Map
	ds.w MAP_X*MAP_Y


* La coplist
* ~~~~~~~~~~
	section pirouette,data_c
coplist
	dc.w fmode,%00
	dc.w bplcon0,(BPL_DEPTH<<12)|$0201
install_delay=*+2
	dc.w bplcon1,$0000
	dc.w bplcon2,%100100
	dc.w bplcon3,$0c20
;	dc.w ddfstrt,$0028
;	dc.w ddfstop,$00c8
	dc.w ddfstrt,$0030
	dc.w ddfstop,$00d0
	dc.w diwstrt,$2b81
	dc.w diwstop,$dbc1
	dc.w bpl1mod,BPL_WIDTH*(BPL_DEPTH-1)
	dc.w bpl2mod,BPL_WIDTH*(BPL_DEPTH-1)

cop1:	dc.w	$0180,$0000
	dc.w	$0182,$05A9
	dc.w	$0184,$0498
	dc.w	$0186,$0397
	dc.w	$0188,$0297
	dc.w	$018A,$0186
	dc.w	$018C,$0085
	dc.w	$018E,$0555
	dc.w	$0190,$0777
	dc.w	$0192,$0999
	dc.w	$0194,$0AAA
	dc.w	$0196,$0CCC
	dc.w	$0198,$0EEE
	dc.w	$019A,$0FFF
	dc.w	$019C,$0555
	dc.w	$019E,$0999
	dc.w color16,$000
	dc.w color17,$ECA
	dc.w color18,$C00
	dc.w color19,$F60
	dc.w color20,$F80
	dc.w color21,$3F1
	dc.w color22,$00F
	dc.w color23,$2CD
	dc.w color24,$F0C
	dc.w color25,$630
	dc.w color26,$950
	dc.w color27,$FCA
	dc.w color28,$FE0
	dc.w color29,$CCC
	dc.w color30,$888
	dc.w color31,$444

install_sprites=*+2
dummy set spr0ptH
	REPT 8					pointeurs pour les sprites
	dc.w dummy,$0000
	dc.w dummy+2,$0000
dummy set dummy+4
	ENDR

install_part1=*+2
dummy set bpl1ptH
	REPT BPL_DEPTH				pointeurs pour la 1�re partie
	dc.w dummy,$0000
	dc.w dummy+2,$0000
dummy set dummy+4
	ENDR

install_wait_cut1
	dc.w $0001,$fffe
	dc.w color00,$f00
	dc.w bpl1mod,-BPL_WIDTH*BPL_DEPTH*(BPL_Y+BLOCK_Y-1)-BPL_WIDTH
	dc.w bpl2mod,-BPL_WIDTH*BPL_DEPTH*(BPL_Y+BLOCK_Y-1)-BPL_WIDTH
install_wait_cut2
	dc.w $0001,$fffe
	dc.w color00,$000
	dc.w bpl1mod,BPL_WIDTH*(BPL_DEPTH-1)
	dc.w bpl2mod,BPL_WIDTH*(BPL_DEPTH-1)

	dc.w $db01,$fffe			\ lance une IT copper
	dc.w intreq,$8010			/
	dc.w color00,$fff
	dc.w bplcon0,$0200

	dc.l $fffffffe

* Les blocks du jeu
* ~~~~~~~~~~~~~~~~~
Block_Gfx
	incbin "Block1_0_0.RAW"
	ds.w 17
	incbin "Block1_1_0.RAW"
	ds.w 17
	incbin "Block1_0_1.RAW"
	ds.w 17
	incbin "Block1_1_1.RAW"
	ds.w 17
	incbin "Block2_0_0.RAW"
	ds.w 17
	incbin "Block2_1_0.RAW"
	ds.w 17
	incbin "Block2_0_1.RAW"
	ds.w 17
	incbin "Block2_1_1.RAW"
	ds.w 17
	ds.b BLOCK_SIZE


* Image du heros
* ~~~~~~~~~~~~~~
HeroPic0
	dc.l 0
	dc.w $0000,$01E0
	dc.w $0000,$03F7
	dc.w $00E0,$031F
	dc.w $00E0,$031F
	dc.w $00C0,$013F
	dc.w $0018,$01E7
	dc.w $0018,$01EF
	dc.w $0000,$01FF
	dc.w $0007,$01FF
	dc.w $0007,$01FF
	dc.w $0000,$00FF
	dc.w $0000,$F0FF
	dc.w $6000,$987F
	dc.w $6000,$9CFF
	dc.w $0000,$7FFF
	dc.w $0007,$3FF8
	dc.w $001F,$1FE0
	dc.w $003F,$07C0
	dc.w $003F,$07C0
	dc.w $003F,$07C0
	dc.w $003F,$07C0
	dc.w $001F,$07E0
	dc.w $001F,$03E0
	dc.w $000F,$03F0
	dc.w $0003,$01FC
	dc.w $0000,$01FF
	dc.w $0000,$03FF
	dc.w $0000,$03FB
	dc.w $0000,$03F0
	dc.w $0200,$01E0
	dc.w $0080,$0160
	dc.w $0000,$0000
	dc.l 0
HeroPic1
	dc.l 0
	dc.w $0000,$01E0
	dc.w $0000,$03F7
	dc.w $0000,$03FF
	dc.w $0000,$03FF
	dc.w $0000,$01FF
	dc.w $0018,$01FF
	dc.w $0018,$01FF
	dc.w $0000,$01FF
	dc.w $0007,$01FF
	dc.w $0007,$01FF
	dc.w $0000,$00FF
	dc.w $0000,$F0F8
	dc.w $0000,$F87D
	dc.w $0000,$FCFF
	dc.w $0000,$7FFF
	dc.w $0000,$3FFF
	dc.w $0000,$1FFF
	dc.w $0000,$07FF
	dc.w $0000,$07FF
	dc.w $0000,$07FF
	dc.w $0000,$07FF
	dc.w $0000,$07FF
	dc.w $0000,$03FF
	dc.w $0000,$03FF
	dc.w $0000,$01FF
	dc.w $0000,$01FF
	dc.w $0000,$03FF
	dc.w $0000,$03FB
	dc.w $0000,$03F0
	dc.w $0000,$03E0
	dc.w $0000,$01E0
	dc.w $0000,$0000
	dc.l 0
HeroPic2
	dc.l 0
	dc.w $0000,$3C00
	dc.w $1800,$6600
	dc.w $3800,$C600
	dc.w $3C00,$C200
	dc.w $0800,$F400
	dc.w $C000,$3C00
	dc.w $C000,$7C00
	dc.w $0000,$FC00
	dc.w $0000,$FC00
	dc.w $0000,$F800
	dc.w $0000,$F800
	dc.w $0000,$F000
	dc.w $0000,$FC78
	dc.w $0030,$FEC8
	dc.w $0030,$FFC8
	dc.w $C000,$3FF0
	dc.w $E000,$1FE0
	dc.w $F000,$0FC0
	dc.w $F800,$0780
	dc.w $F800,$0780
	dc.w $F800,$0780
	dc.w $F800,$0780
	dc.w $F000,$0F80
	dc.w $E000,$1F80
	dc.w $C000,$3F00
	dc.w $0000,$FE00
	dc.w $0000,$FF00
	dc.w $0000,$FF80
	dc.w $0000,$1F80
	dc.w $0000,$1F80
	dc.w $0080,$0F00
	dc.w $0200,$0500
	dc.l 0
HeroPic3
	dc.l 0
	dc.w $0000,$3C00
	dc.w $0000,$7E00
	dc.w $0000,$FE00
	dc.w $0000,$FE00
	dc.w $0000,$FC00
	dc.w $C000,$FC00
	dc.w $C000,$FC00
	dc.w $0000,$FC00
	dc.w $0000,$FC00
	dc.w $0000,$F800
	dc.w $0000,$F800
	dc.w $0000,$F000
	dc.w $0000,$FC78
	dc.w $0000,$FEF8
	dc.w $0000,$FFF8
	dc.w $0000,$FFF0
	dc.w $0000,$FFE0
	dc.w $0000,$FFC0
	dc.w $0000,$FF80
	dc.w $0000,$FF80
	dc.w $0000,$FF80
	dc.w $0000,$FF80
	dc.w $0000,$FF80
	dc.w $0000,$FF80
	dc.w $0000,$FF00
	dc.w $0000,$FE00
	dc.w $0000,$FF00
	dc.w $0000,$FF80
	dc.w $0000,$1F80
	dc.w $0000,$1F80
	dc.w $0000,$0F80
	dc.w $0000,$0700
blk_spr
	dc.w $0000,$0000

* Les samples de la musique
* ~~~~~~~~~~~~~~~~~~~~~~~~~
	include "Samples.s"


* Les ecrans
* ~~~~~~~~~~
	section Screens,bss_c
screen_log		ds.b BPL_WIDTH*(BPL_Y+MAP_Y)*BPL_DEPTH
screen_phy		ds.b BPL_WIDTH*(BPL_Y+MAP_Y)*BPL_DEPTH
