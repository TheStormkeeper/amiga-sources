

*			Sync Operating System 1.0 (SOS)
*			~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
*				  Le Systeme
*				  ~~~~~~~~~~


* Les includes pour le hardware et pour SOS
* ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
	incdir "asm:.s/Sync_Operating_System/"
	include "SOS_registers.i"
	include "SOS_Def.i"

* SOS est localis� � l'adresse $400 ( 1024 )
* ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
	section SOS,code
	org $400

* Routine � appeller en premier pour initialiser SOS
* ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
*   ->	a0=*FileName
SOS_Init
	move.l #AllocMem,$80.w			-> trap #0
	move.l #FreeMem,$84.w			-> trap #1
	move.l #LoadSeg,$88.w			-> trap #2
	move.l #UnLoadSeg,$8c.w			-> trap #3
	move.l #LoadData,$90.w			-> trap #4
	move.l #UnLoadData,$94.w		-> trap #5
	move.l #LoadPack,$98.w			-> trap #6
	move.l #UnLoadPack,$9c.w		-> trap #7

	SOS_LoadSeg
	tst.l d0
	beq SOS_Fatal_Error
	move.l d0,a0
	jmp (a0)

* Routine d'allocation de m�moire
* ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
*   ->	d0=Taille de la m�moire � allouer
*	d1=Type de la m�moire ( SOS_Any / SOS_Chip / SOS_Fast )
*   <-	a0=Adresse de la m�moire allou�e ou 0 si erreur
AllocMem
	addq.l #4,d0				ajoute 4 pour stocker la taille

	tst.w d1
	beq Alloc_Any_Fast
	bpl Alloc_Fast

* Tente une allocation m�moire en CHIP
* ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
Alloc_Chip
	move.l (SOS_Chip_Memory).w,d1		pointe la Chip_Memory
	beq.s Alloc_Chip_End			la liste existe ?
	bsr Alloc
Alloc_Chip_End
	rte
* Tente une allocation m�moire en FAST
* ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
Alloc_Fast
	move.l (SOS_Chip_Memory).w,d1		pointe la Fast_Memory
	beq.s Alloc_Chip_End			la liste existe ?
	bsr Alloc
Alloc_Chip_End
	rte
* Tente d'abord une allocation en FAST puis en CHIP en cas d'�chec
* ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
Alloc_Any_Fast
	move.l (SOS_Fast_Memory).w,d1		pointe la Fast_Memory
	beq.s Alloc_Any_Chip			la liste existe ?
	bsr Alloc
	tst.l d1
	bne.s Alloc_Any_End
Alloc_Any_Chip
	move.l (SOS_Chip_Memory).w,d1		pointe la Chip_Memory
	bsr Alloc				la liste existe ?
Alloc_Any_End
	rte
* Routine d'allocation m�moire dans une liste quelconque
* ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
*   ->	d0=Taille m�moire � allouer
*	d1=SOS_xxx_Memory
*   <-	d1=Adresse m�moire allou�e ou 0 si erreur
Alloc
	move.l d1,a0				mh_Next

	move.l mh_First(a0),d1			pointe le premier Chunk
	beq.s Try_Next				yen a encore ?
Next_Chunk
	move.l d1,a1
	cmp.l mc_Bytes(a1),d0			compare les tailles
	ble.s Memory_Found			ca correspond � ce kon veut ?
	move.l mc_Next(a1),d1			nan.. Memory Chunk suivant
	bne.s Next_Chunk
Try_Next
	move.l mh_Next(a0),d1			cherche le Memory Header suivant
	bne.s Alloc				elle existe ?
	rts

* Un Memory Chunk a �t� trouv� : on l'alloue
* ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
*	d0=Taille m�moire � allouer
*	a0=Memory Header
*	a1=Memory_Chunk
*	Z=??
Memory_Found
	beq.s Remove_Hunk			ca tombe pile ?
Eat_Hunk
	

	


* Routine de lib�ration de la m�moire
* ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
*   ->	a0=Adresse de la m�moire � lib�rer
FreeMem
	rte

* Routine de chargement d'un fichier executable avec relocation et hunks
* ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
*   ->	a0=Ptr sur un nom de fichier
*   <-	d0=Adresse du premier hunk ou 0 si erreur
LoadSeg
	rte

* Routine de lib�ration de la m�moire occup�e par un executable
* ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
*   ->	a0=Adresse du premier hunk ou 0 si erreur
UnLoadSeg
	rte

* Routine de chargement d'un fichier en m�moire
*�~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
*   ->	a0=Ptr sur un nom de fichier
*   <-	d0=Adresse de chargement du fichier ou 0 si erreur
LoadData
	rte

* Routine de lib�ration de la m�moire occup�e par un fichier
* ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
*   ->	a0=Adresse de chargement du fichier
UnLoadData
	rte

* Routine de chargement d'un fichier pack� en m�moire
*�~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
*   ->	a0=Ptr sur un nom de fichier
*   <-	d0=Adresse de chargement du fichier ou 0 si erreur
LoadPack
	rte

* Routine de lib�ration de la m�moire occup�e par un fichier pack�
* ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
*   ->	a0=Adresse de chargement du fichier
UnLoadPack
	rte



* Routine appell�e quand il y a une erreur fatale pendant l'initialisation
* ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
SOS_Fatal_Error
	lea 2.w,a0
	cnop 0,4
	reset
	jmp (a0)
