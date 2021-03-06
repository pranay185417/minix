#	$NetBSD: sys.mk,v 1.118 2013/11/01 17:07:37 christos Exp $
#	@(#)sys.mk	8.2 (Berkeley) 3/21/94
#
# This file contains the basic rules for make(1) and is read first
# Do not put conditionals that are set on different files here and
# expect them to work.

# This variable should be used to differentiate Minix builds in Makefiles.
__MINIX=	yes

.if !defined(__MINIX)
unix?=		We run NetBSD.

.SUFFIXES: .a .o .ln .s .S .c .cc .cpp .cxx .C .f .F .r .p .l .y .sh
.else
unix?=		We run MINIX.

.SUFFIXES: .a .o .bc .ln .s .S .c .cc .cpp .cxx .C .f .F .r .p .l .y .sh

.if ${MKSMALL:U} == "yes"
CPPFLAGS+= -DNDEBUG
DBG=	-Os
.endif

#LSC: Be a bit smarter about the default compiler
.if exists(/usr/pkg/bin/clang) || exists(/usr/bin/clang)
CC?=	clang
.endif

.if exists(/usr/pkg/bin/gcc) || exists(/usr/bin/gcc)
CC?=	gcc
.endif
.endif # defined(__MINIX)

.LIBS:		.a

AR?=		ar
ARFLAGS?=	rl
RANLIB?=	ranlib

AS?=		as
AFLAGS?=
COMPILE.s?=	${CC} ${AFLAGS} ${AFLAGS.${<:T}} -c
LINK.s?=	${CC} ${AFLAGS} ${AFLAGS.${<:T}} ${LDFLAGS}
#_ASM_TRADITIONAL_CPP=	-x assembler-with-cpp
_ASM_TRADITIONAL_CPP= 
COMPILE.S?=	${CC} ${AFLAGS} ${AFLAGS.${<:T}} ${CPPFLAGS} ${_ASM_TRADITIONAL_CPP} -c
LINK.S?=	${CC} ${AFLAGS} ${AFLAGS.${<:T}} ${CPPFLAGS} ${LDFLAGS}

CC?=		cc
.if ${MACHINE_ARCH} == "sh3el" || ${MACHINE_ARCH} == "sh3eb"
# -O2 is too -falign-* zealous for low-memory sh3 machines
DBG?=	-Os -freorder-blocks
.elif ${MACHINE_ARCH} == "m68k" || ${MACHINE_ARCH} == "m68000"
# see src/doc/HACKS for details
DBG?=	-Os
.elif ${MACHINE_ARCH} == "coldfire"
DBG?=	-O1
.elif ${MACHINE_ARCH} == "vax"
DBG?=	-O1 -fgcse -fstrength-reduce -fgcse-after-reload
.else
DBG?=	-O2
.endif
CFLAGS?=	${DBG}
LDFLAGS?=
COMPILE.c?=	${CC} ${CFLAGS} ${CPPFLAGS} -c
LINK.c?=	${CC} ${CFLAGS} ${CPPFLAGS} ${LDFLAGS}

# C Type Format data is required for DTrace
CTFFLAGS	?=	-g -L VERSION
CTFMFLAGS	?=	-g -t -L VERSION

# We don't define these here, we let the bsd.own.mk to do it
#CTFCONVERT	?=	ctfconvert
#CTFMERGE	?=	ctfmerge

CXX?=		c++
CXXFLAGS?=	${CFLAGS:N-Wno-traditional:N-Wstrict-prototypes:N-Wmissing-prototypes:N-Wno-pointer-sign:N-ffreestanding:N-std=gnu[0-9][0-9]:N-Wold-style-definition:N-Wno-format-zero-length}

__ALLSRC1=	${empty(DESTDIR):?${.ALLSRC}:${.ALLSRC:S|^${DESTDIR}|^destdir|}}
__ALLSRC2=	${empty(MAKEOBJDIR):?${__ALLSRC1}:${__ALLSRC1:S|^${MAKEOBJDIR}|^obj|}}
__ALLSRC3=	${empty(NETBSDSRCDIR):?${__ALLSRC2}:${__ALLSRC2:S|^${NETBSDSRCDIR}|^src|}}
__BUILDSEED=	${BUILDSEED}/${__ALLSRC3:O}/${.TARGET}
_CXXSEED?=	${BUILDSEED:D-frandom-seed=${__BUILDSEED:hash}}

COMPILE.cc?=	${CXX} ${_CXXSEED} ${CXXFLAGS} ${CPPFLAGS} -c
LINK.cc?=	${CXX} ${CXXFLAGS} ${CPPFLAGS} ${LDFLAGS}

OBJC?=		${CC}
OBJCFLAGS?=	${CFLAGS}
COMPILE.m?=	${OBJC} ${OBJCFLAGS} ${CPPFLAGS} -c
LINK.m?=	${OBJC} ${OBJCFLAGS} ${CPPFLAGS} ${LDFLAGS}

CPP?=		cpp
CPPFLAGS?=

FC?=		f77
FFLAGS?=	-O
RFLAGS?=
COMPILE.f?=	${FC} ${FFLAGS} -c
LINK.f?=	${FC} ${FFLAGS} ${LDFLAGS}
COMPILE.F?=	${FC} ${FFLAGS} ${CPPFLAGS} -c
LINK.F?=	${FC} ${FFLAGS} ${CPPFLAGS} ${LDFLAGS}
COMPILE.r?=	${FC} ${FFLAGS} ${RFLAGS} -c
LINK.r?=	${FC} ${FFLAGS} ${RFLAGS} ${LDFLAGS}

INSTALL?=	install

LD?=		ld

LEX?=		lex
LFLAGS?=
LEX.l?=		${LEX} ${LFLAGS}

LINT?=		lint
LINTFLAGS?=	-chapbxzFS

LORDER?=	lorder

MAKE?=		make

NM?=		nm

PC?=		pc
PFLAGS?=
COMPILE.p?=	${PC} ${PFLAGS} ${CPPFLAGS} -c
LINK.p?=	${PC} ${PFLAGS} ${CPPFLAGS} ${LDFLAGS}

SHELL?=		sh

SIZE?=		size

TSORT?= 	tsort -q

YACC?=		yacc
YFLAGS?=
YACC.y?=	${YACC} ${YFLAGS}

# C
.c:
	${LINK.c} -o ${.TARGET} ${.IMPSRC} ${LDLIBS}
.if defined(CTFCONVERT)
	${CTFCONVERT} ${CTFFLAGS} ${.TARGET}
.endif
.c.o:
	${COMPILE.c} ${.IMPSRC}
.if defined(CTFCONVERT)
	${CTFCONVERT} ${CTFFLAGS} ${.TARGET}
.endif
.c.a:
	${COMPILE.c} ${.IMPSRC}
	${AR} ${ARFLAGS} ${.TARGET} ${.PREFIX}.o
	rm -f ${.PREFIX}.o
.c.ln:
	${LINT} ${LINTFLAGS} \
	    ${CPPFLAGS:C/-([IDU])[  ]*/-\1/Wg:M-[IDU]*} \
	    -i ${.IMPSRC}

# C++
.cc .cpp .cxx .C:
	${LINK.cc} -o ${.TARGET} ${.IMPSRC} ${LDLIBS}
.cc.o .cpp.o .cxx.o .C.o:
	${COMPILE.cc} ${.IMPSRC}
.cc.a .cpp.a .cxx.a .C.a:
	${COMPILE.cc} ${.IMPSRC}
	${AR} ${ARFLAGS} ${.TARGET} ${.PREFIX}.o
	rm -f ${.PREFIX}.o

# Fortran/Ratfor
.f:
	${LINK.f} -o ${.TARGET} ${.IMPSRC} ${LDLIBS}
.f.o:
	${COMPILE.f} ${.IMPSRC}
.if defined(CTFCONVERT)
	${CTFCONVERT} ${CTFFLAGS} ${.TARGET}
.endif
.f.a:
	${COMPILE.f} ${.IMPSRC}
	${AR} ${ARFLAGS} ${.TARGET} ${.PREFIX}.o
	rm -f ${.PREFIX}.o

.F:
	${LINK.F} -o ${.TARGET} ${.IMPSRC} ${LDLIBS}
.if defined(CTFCONVERT)
	${CTFCONVERT} ${CTFFLAGS} ${.TARGET}
.endif
.F.o:
	${COMPILE.F} ${.IMPSRC}
.if defined(CTFCONVERT)
	${CTFCONVERT} ${CTFFLAGS} ${.TARGET}
.endif
.F.a:
	${COMPILE.F} ${.IMPSRC}
	${AR} ${ARFLAGS} ${.TARGET} ${.PREFIX}.o
	rm -f ${.PREFIX}.o

.r:
	${LINK.r} -o ${.TARGET} ${.IMPSRC} ${LDLIBS}
.r.o:
	${COMPILE.r} ${.IMPSRC}
.if defined(CTFCONVERT)
	${CTFCONVERT} ${CTFFLAGS} ${.TARGET}
.endif
.r.a:
	${COMPILE.r} ${.IMPSRC}
	${AR} ${ARFLAGS} ${.TARGET} ${.PREFIX}.o
	rm -f ${.PREFIX}.o

# Pascal
.p:
	${LINK.p} -o ${.TARGET} ${.IMPSRC} ${LDLIBS}
.if defined(CTFCONVERT)
	${CTFCONVERT} ${CTFFLAGS} ${.TARGET}
.endif
.p.o:
	${COMPILE.p} ${.IMPSRC}
.if defined(CTFCONVERT)
	${CTFCONVERT} ${CTFFLAGS} ${.TARGET}
.endif
.p.a:
	${COMPILE.p} ${.IMPSRC}
	${AR} ${ARFLAGS} ${.TARGET} ${.PREFIX}.o
	rm -f ${.PREFIX}.o

# Assembly
.s:
	${LINK.s} -o ${.TARGET} ${.IMPSRC} ${LDLIBS}
.if defined(CTFCONVERT)
	${CTFCONVERT} ${CTFFLAGS} ${.TARGET}
.endif
.s.o:
	${COMPILE.s} ${.IMPSRC}
.if defined(CTFCONVERT)
	${CTFCONVERT} ${CTFFLAGS} ${.TARGET}
.endif
.s.a:
	${COMPILE.s} ${.IMPSRC}
	${AR} ${ARFLAGS} ${.TARGET} ${.PREFIX}.o
	rm -f ${.PREFIX}.o
.S:
	${LINK.S} -o ${.TARGET} ${.IMPSRC} ${LDLIBS}
.if defined(CTFCONVERT)
	${CTFCONVERT} ${CTFFLAGS} ${.TARGET}
.endif
.S.o:
	${COMPILE.S} ${.IMPSRC}
.if defined(CTFCONVERT)
	${CTFCONVERT} ${CTFFLAGS} ${.TARGET}
.endif
.S.a:
	${COMPILE.S} ${.IMPSRC}
	${AR} ${ARFLAGS} ${.TARGET} ${.PREFIX}.o
	rm -f ${.PREFIX}.o

# Lex
.l:
	${LEX.l} ${.IMPSRC}
	${LINK.c} -o ${.TARGET} lex.yy.c ${LDLIBS} -ll
	rm -f lex.yy.c
.l.c:
	${LEX.l} ${.IMPSRC}
	mv lex.yy.c ${.TARGET}
.l.o:
	${LEX.l} ${.IMPSRC}
	${COMPILE.c} -o ${.TARGET} lex.yy.c
.if defined(CTFCONVERT)
	${CTFCONVERT} ${CTFFLAGS} ${.TARGET}
.endif
	rm -f lex.yy.c

# Yacc
.y:
	${YACC.y} ${.IMPSRC}
	${LINK.c} -o ${.TARGET} y.tab.c ${LDLIBS}
	rm -f y.tab.c
.y.c:
	${YACC.y} ${.IMPSRC}
	mv y.tab.c ${.TARGET}
.y.o:
	${YACC.y} ${.IMPSRC}
	${COMPILE.c} -o ${.TARGET} y.tab.c
.if defined(CTFCONVERT)
	${CTFCONVERT} ${CTFFLAGS} ${.TARGET}
.endif
	rm -f y.tab.c

# Shell
.sh:
	rm -f ${.TARGET}
	cp ${.IMPSRC} ${.TARGET}
	chmod a+x ${.TARGET}
