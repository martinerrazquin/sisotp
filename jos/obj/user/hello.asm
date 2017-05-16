
obj/user/hello:     file format elf32-i386


Disassembly of section .text:

00800020 <_start>:
// starts us running when we are initially loaded into a new environment.
.text
.globl _start
_start:
	// See if we were started with arguments on the stack
	cmpl $USTACKTOP, %esp
  800020:	81 fc 00 e0 bf ee    	cmp    $0xeebfe000,%esp
	jne args_exist
  800026:	75 04                	jne    80002c <args_exist>

	// If not, push dummy argc/argv arguments.
	// This happens when we are loaded by the kernel,
	// because the kernel does not know about passing arguments.
	pushl $0
  800028:	6a 00                	push   $0x0
	pushl $0
  80002a:	6a 00                	push   $0x0

0080002c <args_exist>:

args_exist:
	call libmain
  80002c:	e8 2e 00 00 00       	call   80005f <libmain>
1:	jmp 1b
  800031:	eb fe                	jmp    800031 <args_exist+0x5>

00800033 <umain>:
// hello, world
#include <inc/lib.h>

void
umain(int argc, char **argv)
{
  800033:	55                   	push   %ebp
  800034:	89 e5                	mov    %esp,%ebp
  800036:	83 ec 18             	sub    $0x18,%esp
	cprintf("hello, world\n");
  800039:	c7 04 24 c8 0e 80 00 	movl   $0x800ec8,(%esp)
  800040:	e8 06 01 00 00       	call   80014b <cprintf>
	cprintf("i am environment %08x\n", thisenv->env_id);
  800045:	a1 04 20 80 00       	mov    0x802004,%eax
  80004a:	8b 40 48             	mov    0x48(%eax),%eax
  80004d:	89 44 24 04          	mov    %eax,0x4(%esp)
  800051:	c7 04 24 d6 0e 80 00 	movl   $0x800ed6,(%esp)
  800058:	e8 ee 00 00 00       	call   80014b <cprintf>
}
  80005d:	c9                   	leave  
  80005e:	c3                   	ret    

0080005f <libmain>:
const volatile struct Env *thisenv;
const char *binaryname = "<unknown>";

void
libmain(int argc, char **argv)
{
  80005f:	55                   	push   %ebp
  800060:	89 e5                	mov    %esp,%ebp
  800062:	83 ec 18             	sub    $0x18,%esp
  800065:	8b 45 08             	mov    0x8(%ebp),%eax
  800068:	8b 55 0c             	mov    0xc(%ebp),%edx
	// set thisenv to point at our Env structure in envs[].
	// LAB 3: Your code here.
	thisenv = 0;
  80006b:	c7 05 04 20 80 00 00 	movl   $0x0,0x802004
  800072:	00 00 00 

	// save the name of the program so that panic() can use it
	if (argc > 0)
  800075:	85 c0                	test   %eax,%eax
  800077:	7e 08                	jle    800081 <libmain+0x22>
		binaryname = argv[0];
  800079:	8b 0a                	mov    (%edx),%ecx
  80007b:	89 0d 00 20 80 00    	mov    %ecx,0x802000

	// call user main routine
	umain(argc, argv);
  800081:	89 54 24 04          	mov    %edx,0x4(%esp)
  800085:	89 04 24             	mov    %eax,(%esp)
  800088:	e8 a6 ff ff ff       	call   800033 <umain>

	// exit gracefully
	exit();
  80008d:	e8 02 00 00 00       	call   800094 <exit>
}
  800092:	c9                   	leave  
  800093:	c3                   	ret    

00800094 <exit>:

#include <inc/lib.h>

void
exit(void)
{
  800094:	55                   	push   %ebp
  800095:	89 e5                	mov    %esp,%ebp
  800097:	83 ec 18             	sub    $0x18,%esp
	sys_env_destroy(0);
  80009a:	c7 04 24 00 00 00 00 	movl   $0x0,(%esp)
  8000a1:	e8 cc 0a 00 00       	call   800b72 <sys_env_destroy>
}
  8000a6:	c9                   	leave  
  8000a7:	c3                   	ret    

008000a8 <putch>:
};


static void
putch(int ch, struct printbuf *b)
{
  8000a8:	55                   	push   %ebp
  8000a9:	89 e5                	mov    %esp,%ebp
  8000ab:	53                   	push   %ebx
  8000ac:	83 ec 14             	sub    $0x14,%esp
  8000af:	8b 5d 0c             	mov    0xc(%ebp),%ebx
	b->buf[b->idx++] = ch;
  8000b2:	8b 13                	mov    (%ebx),%edx
  8000b4:	8d 42 01             	lea    0x1(%edx),%eax
  8000b7:	89 03                	mov    %eax,(%ebx)
  8000b9:	8b 4d 08             	mov    0x8(%ebp),%ecx
  8000bc:	88 4c 13 08          	mov    %cl,0x8(%ebx,%edx,1)
	if (b->idx == 256-1) {
  8000c0:	3d ff 00 00 00       	cmp    $0xff,%eax
  8000c5:	75 19                	jne    8000e0 <putch+0x38>
		sys_cputs(b->buf, b->idx);
  8000c7:	c7 44 24 04 ff 00 00 	movl   $0xff,0x4(%esp)
  8000ce:	00 
  8000cf:	8d 43 08             	lea    0x8(%ebx),%eax
  8000d2:	89 04 24             	mov    %eax,(%esp)
  8000d5:	e8 25 0a 00 00       	call   800aff <sys_cputs>
		b->idx = 0;
  8000da:	c7 03 00 00 00 00    	movl   $0x0,(%ebx)
	}
	b->cnt++;
  8000e0:	83 43 04 01          	addl   $0x1,0x4(%ebx)
}
  8000e4:	83 c4 14             	add    $0x14,%esp
  8000e7:	5b                   	pop    %ebx
  8000e8:	5d                   	pop    %ebp
  8000e9:	c3                   	ret    

008000ea <vcprintf>:

int
vcprintf(const char *fmt, va_list ap)
{
  8000ea:	55                   	push   %ebp
  8000eb:	89 e5                	mov    %esp,%ebp
  8000ed:	81 ec 28 01 00 00    	sub    $0x128,%esp
	struct printbuf b;

	b.idx = 0;
  8000f3:	c7 85 f0 fe ff ff 00 	movl   $0x0,-0x110(%ebp)
  8000fa:	00 00 00 
	b.cnt = 0;
  8000fd:	c7 85 f4 fe ff ff 00 	movl   $0x0,-0x10c(%ebp)
  800104:	00 00 00 
	vprintfmt((void*)putch, &b, fmt, ap);
  800107:	8b 45 0c             	mov    0xc(%ebp),%eax
  80010a:	89 44 24 0c          	mov    %eax,0xc(%esp)
  80010e:	8b 45 08             	mov    0x8(%ebp),%eax
  800111:	89 44 24 08          	mov    %eax,0x8(%esp)
  800115:	8d 85 f0 fe ff ff    	lea    -0x110(%ebp),%eax
  80011b:	89 44 24 04          	mov    %eax,0x4(%esp)
  80011f:	c7 04 24 a8 00 80 00 	movl   $0x8000a8,(%esp)
  800126:	e8 e5 01 00 00       	call   800310 <vprintfmt>
	sys_cputs(b.buf, b.idx);
  80012b:	8b 85 f0 fe ff ff    	mov    -0x110(%ebp),%eax
  800131:	89 44 24 04          	mov    %eax,0x4(%esp)
  800135:	8d 85 f8 fe ff ff    	lea    -0x108(%ebp),%eax
  80013b:	89 04 24             	mov    %eax,(%esp)
  80013e:	e8 bc 09 00 00       	call   800aff <sys_cputs>

	return b.cnt;
}
  800143:	8b 85 f4 fe ff ff    	mov    -0x10c(%ebp),%eax
  800149:	c9                   	leave  
  80014a:	c3                   	ret    

0080014b <cprintf>:

int
cprintf(const char *fmt, ...)
{
  80014b:	55                   	push   %ebp
  80014c:	89 e5                	mov    %esp,%ebp
  80014e:	83 ec 18             	sub    $0x18,%esp
	va_list ap;
	int cnt;

	va_start(ap, fmt);
  800151:	8d 45 0c             	lea    0xc(%ebp),%eax
	cnt = vcprintf(fmt, ap);
  800154:	89 44 24 04          	mov    %eax,0x4(%esp)
  800158:	8b 45 08             	mov    0x8(%ebp),%eax
  80015b:	89 04 24             	mov    %eax,(%esp)
  80015e:	e8 87 ff ff ff       	call   8000ea <vcprintf>
	va_end(ap);

	return cnt;
}
  800163:	c9                   	leave  
  800164:	c3                   	ret    
  800165:	66 90                	xchg   %ax,%ax
  800167:	66 90                	xchg   %ax,%ax
  800169:	66 90                	xchg   %ax,%ax
  80016b:	66 90                	xchg   %ax,%ax
  80016d:	66 90                	xchg   %ax,%ax
  80016f:	90                   	nop

00800170 <printnum>:
 * using specified putch function and associated pointer putdat.
 */
static void
printnum(void (*putch)(int, void*), void *putdat,
	 unsigned long long num, unsigned base, int width, int padc)
{
  800170:	55                   	push   %ebp
  800171:	89 e5                	mov    %esp,%ebp
  800173:	57                   	push   %edi
  800174:	56                   	push   %esi
  800175:	53                   	push   %ebx
  800176:	83 ec 3c             	sub    $0x3c,%esp
  800179:	89 45 e4             	mov    %eax,-0x1c(%ebp)
  80017c:	89 d7                	mov    %edx,%edi
  80017e:	8b 45 08             	mov    0x8(%ebp),%eax
  800181:	89 45 e0             	mov    %eax,-0x20(%ebp)
  800184:	8b 45 0c             	mov    0xc(%ebp),%eax
  800187:	89 c3                	mov    %eax,%ebx
  800189:	89 45 d4             	mov    %eax,-0x2c(%ebp)
  80018c:	8b 45 10             	mov    0x10(%ebp),%eax
  80018f:	8b 75 14             	mov    0x14(%ebp),%esi
	// first recursively print all preceding (more significant) digits
	if (num >= base) {
  800192:	b9 00 00 00 00       	mov    $0x0,%ecx
  800197:	89 45 d8             	mov    %eax,-0x28(%ebp)
  80019a:	89 4d dc             	mov    %ecx,-0x24(%ebp)
  80019d:	39 d9                	cmp    %ebx,%ecx
  80019f:	72 05                	jb     8001a6 <printnum+0x36>
  8001a1:	3b 45 e0             	cmp    -0x20(%ebp),%eax
  8001a4:	77 69                	ja     80020f <printnum+0x9f>
		printnum(putch, putdat, num / base, base, width - 1, padc);
  8001a6:	8b 4d 18             	mov    0x18(%ebp),%ecx
  8001a9:	89 4c 24 10          	mov    %ecx,0x10(%esp)
  8001ad:	83 ee 01             	sub    $0x1,%esi
  8001b0:	89 74 24 0c          	mov    %esi,0xc(%esp)
  8001b4:	89 44 24 08          	mov    %eax,0x8(%esp)
  8001b8:	8b 44 24 08          	mov    0x8(%esp),%eax
  8001bc:	8b 54 24 0c          	mov    0xc(%esp),%edx
  8001c0:	89 c3                	mov    %eax,%ebx
  8001c2:	89 d6                	mov    %edx,%esi
  8001c4:	8b 55 d8             	mov    -0x28(%ebp),%edx
  8001c7:	8b 4d dc             	mov    -0x24(%ebp),%ecx
  8001ca:	89 54 24 08          	mov    %edx,0x8(%esp)
  8001ce:	89 4c 24 0c          	mov    %ecx,0xc(%esp)
  8001d2:	8b 45 e0             	mov    -0x20(%ebp),%eax
  8001d5:	89 04 24             	mov    %eax,(%esp)
  8001d8:	8b 45 d4             	mov    -0x2c(%ebp),%eax
  8001db:	89 44 24 04          	mov    %eax,0x4(%esp)
  8001df:	e8 5c 0a 00 00       	call   800c40 <__udivdi3>
  8001e4:	89 d9                	mov    %ebx,%ecx
  8001e6:	89 4c 24 08          	mov    %ecx,0x8(%esp)
  8001ea:	89 74 24 0c          	mov    %esi,0xc(%esp)
  8001ee:	89 04 24             	mov    %eax,(%esp)
  8001f1:	89 54 24 04          	mov    %edx,0x4(%esp)
  8001f5:	89 fa                	mov    %edi,%edx
  8001f7:	8b 45 e4             	mov    -0x1c(%ebp),%eax
  8001fa:	e8 71 ff ff ff       	call   800170 <printnum>
  8001ff:	eb 1b                	jmp    80021c <printnum+0xac>
	} else {
		// print any needed pad characters before first digit
		while (--width > 0)
			putch(padc, putdat);
  800201:	89 7c 24 04          	mov    %edi,0x4(%esp)
  800205:	8b 45 18             	mov    0x18(%ebp),%eax
  800208:	89 04 24             	mov    %eax,(%esp)
  80020b:	ff d3                	call   *%ebx
  80020d:	eb 03                	jmp    800212 <printnum+0xa2>
  80020f:	8b 5d e4             	mov    -0x1c(%ebp),%ebx
	// first recursively print all preceding (more significant) digits
	if (num >= base) {
		printnum(putch, putdat, num / base, base, width - 1, padc);
	} else {
		// print any needed pad characters before first digit
		while (--width > 0)
  800212:	83 ee 01             	sub    $0x1,%esi
  800215:	85 f6                	test   %esi,%esi
  800217:	7f e8                	jg     800201 <printnum+0x91>
  800219:	89 5d e4             	mov    %ebx,-0x1c(%ebp)
			putch(padc, putdat);
	}

	// then print this (the least significant) digit
	putch("0123456789abcdef"[num % base], putdat);
  80021c:	89 7c 24 04          	mov    %edi,0x4(%esp)
  800220:	8b 7c 24 04          	mov    0x4(%esp),%edi
  800224:	8b 45 d8             	mov    -0x28(%ebp),%eax
  800227:	8b 55 dc             	mov    -0x24(%ebp),%edx
  80022a:	89 44 24 08          	mov    %eax,0x8(%esp)
  80022e:	89 54 24 0c          	mov    %edx,0xc(%esp)
  800232:	8b 45 e0             	mov    -0x20(%ebp),%eax
  800235:	89 04 24             	mov    %eax,(%esp)
  800238:	8b 45 d4             	mov    -0x2c(%ebp),%eax
  80023b:	89 44 24 04          	mov    %eax,0x4(%esp)
  80023f:	e8 2c 0b 00 00       	call   800d70 <__umoddi3>
  800244:	89 7c 24 04          	mov    %edi,0x4(%esp)
  800248:	0f be 80 f7 0e 80 00 	movsbl 0x800ef7(%eax),%eax
  80024f:	89 04 24             	mov    %eax,(%esp)
  800252:	8b 45 e4             	mov    -0x1c(%ebp),%eax
  800255:	ff d0                	call   *%eax
}
  800257:	83 c4 3c             	add    $0x3c,%esp
  80025a:	5b                   	pop    %ebx
  80025b:	5e                   	pop    %esi
  80025c:	5f                   	pop    %edi
  80025d:	5d                   	pop    %ebp
  80025e:	c3                   	ret    

0080025f <getuint>:

// Get an unsigned int of various possible sizes from a varargs list,
// depending on the lflag parameter.
static unsigned long long
getuint(va_list *ap, int lflag)
{
  80025f:	55                   	push   %ebp
  800260:	89 e5                	mov    %esp,%ebp
	if (lflag >= 2)
  800262:	83 fa 01             	cmp    $0x1,%edx
  800265:	7e 0e                	jle    800275 <getuint+0x16>
		return va_arg(*ap, unsigned long long);
  800267:	8b 10                	mov    (%eax),%edx
  800269:	8d 4a 08             	lea    0x8(%edx),%ecx
  80026c:	89 08                	mov    %ecx,(%eax)
  80026e:	8b 02                	mov    (%edx),%eax
  800270:	8b 52 04             	mov    0x4(%edx),%edx
  800273:	eb 22                	jmp    800297 <getuint+0x38>
	else if (lflag)
  800275:	85 d2                	test   %edx,%edx
  800277:	74 10                	je     800289 <getuint+0x2a>
		return va_arg(*ap, unsigned long);
  800279:	8b 10                	mov    (%eax),%edx
  80027b:	8d 4a 04             	lea    0x4(%edx),%ecx
  80027e:	89 08                	mov    %ecx,(%eax)
  800280:	8b 02                	mov    (%edx),%eax
  800282:	ba 00 00 00 00       	mov    $0x0,%edx
  800287:	eb 0e                	jmp    800297 <getuint+0x38>
	else
		return va_arg(*ap, unsigned int);
  800289:	8b 10                	mov    (%eax),%edx
  80028b:	8d 4a 04             	lea    0x4(%edx),%ecx
  80028e:	89 08                	mov    %ecx,(%eax)
  800290:	8b 02                	mov    (%edx),%eax
  800292:	ba 00 00 00 00       	mov    $0x0,%edx
}
  800297:	5d                   	pop    %ebp
  800298:	c3                   	ret    

00800299 <getint>:

// Same as getuint but signed - can't use getuint
// because of sign extension
static long long
getint(va_list *ap, int lflag)
{
  800299:	55                   	push   %ebp
  80029a:	89 e5                	mov    %esp,%ebp
	if (lflag >= 2)
  80029c:	83 fa 01             	cmp    $0x1,%edx
  80029f:	7e 0e                	jle    8002af <getint+0x16>
		return va_arg(*ap, long long);
  8002a1:	8b 10                	mov    (%eax),%edx
  8002a3:	8d 4a 08             	lea    0x8(%edx),%ecx
  8002a6:	89 08                	mov    %ecx,(%eax)
  8002a8:	8b 02                	mov    (%edx),%eax
  8002aa:	8b 52 04             	mov    0x4(%edx),%edx
  8002ad:	eb 1a                	jmp    8002c9 <getint+0x30>
	else if (lflag)
  8002af:	85 d2                	test   %edx,%edx
  8002b1:	74 0c                	je     8002bf <getint+0x26>
		return va_arg(*ap, long);
  8002b3:	8b 10                	mov    (%eax),%edx
  8002b5:	8d 4a 04             	lea    0x4(%edx),%ecx
  8002b8:	89 08                	mov    %ecx,(%eax)
  8002ba:	8b 02                	mov    (%edx),%eax
  8002bc:	99                   	cltd   
  8002bd:	eb 0a                	jmp    8002c9 <getint+0x30>
	else
		return va_arg(*ap, int);
  8002bf:	8b 10                	mov    (%eax),%edx
  8002c1:	8d 4a 04             	lea    0x4(%edx),%ecx
  8002c4:	89 08                	mov    %ecx,(%eax)
  8002c6:	8b 02                	mov    (%edx),%eax
  8002c8:	99                   	cltd   
}
  8002c9:	5d                   	pop    %ebp
  8002ca:	c3                   	ret    

008002cb <sprintputch>:
	int cnt;
};

static void
sprintputch(int ch, struct sprintbuf *b)
{
  8002cb:	55                   	push   %ebp
  8002cc:	89 e5                	mov    %esp,%ebp
  8002ce:	8b 45 0c             	mov    0xc(%ebp),%eax
	b->cnt++;
  8002d1:	83 40 08 01          	addl   $0x1,0x8(%eax)
	if (b->buf < b->ebuf)
  8002d5:	8b 10                	mov    (%eax),%edx
  8002d7:	3b 50 04             	cmp    0x4(%eax),%edx
  8002da:	73 0a                	jae    8002e6 <sprintputch+0x1b>
		*b->buf++ = ch;
  8002dc:	8d 4a 01             	lea    0x1(%edx),%ecx
  8002df:	89 08                	mov    %ecx,(%eax)
  8002e1:	8b 45 08             	mov    0x8(%ebp),%eax
  8002e4:	88 02                	mov    %al,(%edx)
}
  8002e6:	5d                   	pop    %ebp
  8002e7:	c3                   	ret    

008002e8 <printfmt>:
	}
}

void
printfmt(void (*putch)(int, void*), void *putdat, const char *fmt, ...)
{
  8002e8:	55                   	push   %ebp
  8002e9:	89 e5                	mov    %esp,%ebp
  8002eb:	83 ec 18             	sub    $0x18,%esp
	va_list ap;

	va_start(ap, fmt);
  8002ee:	8d 45 14             	lea    0x14(%ebp),%eax
	vprintfmt(putch, putdat, fmt, ap);
  8002f1:	89 44 24 0c          	mov    %eax,0xc(%esp)
  8002f5:	8b 45 10             	mov    0x10(%ebp),%eax
  8002f8:	89 44 24 08          	mov    %eax,0x8(%esp)
  8002fc:	8b 45 0c             	mov    0xc(%ebp),%eax
  8002ff:	89 44 24 04          	mov    %eax,0x4(%esp)
  800303:	8b 45 08             	mov    0x8(%ebp),%eax
  800306:	89 04 24             	mov    %eax,(%esp)
  800309:	e8 02 00 00 00       	call   800310 <vprintfmt>
	va_end(ap);
}
  80030e:	c9                   	leave  
  80030f:	c3                   	ret    

00800310 <vprintfmt>:
// Main function to format and print a string.
void printfmt(void (*putch)(int, void*), void *putdat, const char *fmt, ...);

void
vprintfmt(void (*putch)(int, void*), void *putdat, const char *fmt, va_list ap)
{
  800310:	55                   	push   %ebp
  800311:	89 e5                	mov    %esp,%ebp
  800313:	57                   	push   %edi
  800314:	56                   	push   %esi
  800315:	53                   	push   %ebx
  800316:	83 ec 3c             	sub    $0x3c,%esp
  800319:	8b 75 0c             	mov    0xc(%ebp),%esi
  80031c:	8b 7d 10             	mov    0x10(%ebp),%edi
  80031f:	eb 14                	jmp    800335 <vprintfmt+0x25>
	int base, lflag, width, precision, altflag;
	char padc;

	while (1) {
		while ((ch = *(unsigned char *) fmt++) != '%') {
			if (ch == '\0')
  800321:	85 c0                	test   %eax,%eax
  800323:	0f 84 63 03 00 00    	je     80068c <vprintfmt+0x37c>
				return;
			putch(ch, putdat);
  800329:	89 74 24 04          	mov    %esi,0x4(%esp)
  80032d:	89 04 24             	mov    %eax,(%esp)
  800330:	ff 55 08             	call   *0x8(%ebp)
	unsigned long long num;
	int base, lflag, width, precision, altflag;
	char padc;

	while (1) {
		while ((ch = *(unsigned char *) fmt++) != '%') {
  800333:	89 df                	mov    %ebx,%edi
  800335:	8d 5f 01             	lea    0x1(%edi),%ebx
  800338:	0f b6 07             	movzbl (%edi),%eax
  80033b:	83 f8 25             	cmp    $0x25,%eax
  80033e:	75 e1                	jne    800321 <vprintfmt+0x11>
  800340:	c6 45 d8 20          	movb   $0x20,-0x28(%ebp)
  800344:	c7 45 e0 00 00 00 00 	movl   $0x0,-0x20(%ebp)
  80034b:	c7 45 d4 ff ff ff ff 	movl   $0xffffffff,-0x2c(%ebp)
  800352:	c7 45 dc ff ff ff ff 	movl   $0xffffffff,-0x24(%ebp)
  800359:	ba 00 00 00 00       	mov    $0x0,%edx
  80035e:	eb 1d                	jmp    80037d <vprintfmt+0x6d>
		width = -1;
		precision = -1;
		lflag = 0;
		altflag = 0;
	reswitch:
		switch (ch = *(unsigned char *) fmt++) {
  800360:	89 fb                	mov    %edi,%ebx

		// flag to pad on the right
		case '-':
			padc = '-';
  800362:	c6 45 d8 2d          	movb   $0x2d,-0x28(%ebp)
  800366:	eb 15                	jmp    80037d <vprintfmt+0x6d>
		width = -1;
		precision = -1;
		lflag = 0;
		altflag = 0;
	reswitch:
		switch (ch = *(unsigned char *) fmt++) {
  800368:	89 fb                	mov    %edi,%ebx
			padc = '-';
			goto reswitch;

		// flag to pad with 0's instead of spaces
		case '0':
			padc = '0';
  80036a:	c6 45 d8 30          	movb   $0x30,-0x28(%ebp)
  80036e:	eb 0d                	jmp    80037d <vprintfmt+0x6d>
			altflag = 1;
			goto reswitch;

		process_precision:
			if (width < 0)
				width = precision, precision = -1;
  800370:	8b 45 d4             	mov    -0x2c(%ebp),%eax
  800373:	89 45 dc             	mov    %eax,-0x24(%ebp)
  800376:	c7 45 d4 ff ff ff ff 	movl   $0xffffffff,-0x2c(%ebp)
		width = -1;
		precision = -1;
		lflag = 0;
		altflag = 0;
	reswitch:
		switch (ch = *(unsigned char *) fmt++) {
  80037d:	8d 7b 01             	lea    0x1(%ebx),%edi
  800380:	0f b6 0b             	movzbl (%ebx),%ecx
  800383:	0f b6 c1             	movzbl %cl,%eax
  800386:	83 e9 23             	sub    $0x23,%ecx
  800389:	80 f9 55             	cmp    $0x55,%cl
  80038c:	0f 87 da 02 00 00    	ja     80066c <vprintfmt+0x35c>
  800392:	0f b6 c9             	movzbl %cl,%ecx
  800395:	ff 24 8d 84 0f 80 00 	jmp    *0x800f84(,%ecx,4)
  80039c:	89 fb                	mov    %edi,%ebx
  80039e:	b9 00 00 00 00       	mov    $0x0,%ecx
		case '6':
		case '7':
		case '8':
		case '9':
			for (precision = 0; ; ++fmt) {
				precision = precision * 10 + ch - '0';
  8003a3:	8d 0c 89             	lea    (%ecx,%ecx,4),%ecx
  8003a6:	8d 4c 48 d0          	lea    -0x30(%eax,%ecx,2),%ecx
				ch = *fmt;
  8003aa:	0f be 03             	movsbl (%ebx),%eax
				if (ch < '0' || ch > '9')
  8003ad:	8d 78 d0             	lea    -0x30(%eax),%edi
  8003b0:	83 ff 09             	cmp    $0x9,%edi
  8003b3:	77 36                	ja     8003eb <vprintfmt+0xdb>
		case '5':
		case '6':
		case '7':
		case '8':
		case '9':
			for (precision = 0; ; ++fmt) {
  8003b5:	83 c3 01             	add    $0x1,%ebx
				precision = precision * 10 + ch - '0';
				ch = *fmt;
				if (ch < '0' || ch > '9')
					break;
			}
  8003b8:	eb e9                	jmp    8003a3 <vprintfmt+0x93>
			goto process_precision;

		case '*':
			precision = va_arg(ap, int);
  8003ba:	8b 45 14             	mov    0x14(%ebp),%eax
  8003bd:	8d 48 04             	lea    0x4(%eax),%ecx
  8003c0:	89 4d 14             	mov    %ecx,0x14(%ebp)
  8003c3:	8b 00                	mov    (%eax),%eax
  8003c5:	89 45 d4             	mov    %eax,-0x2c(%ebp)
		width = -1;
		precision = -1;
		lflag = 0;
		altflag = 0;
	reswitch:
		switch (ch = *(unsigned char *) fmt++) {
  8003c8:	89 fb                	mov    %edi,%ebx
			}
			goto process_precision;

		case '*':
			precision = va_arg(ap, int);
			goto process_precision;
  8003ca:	eb 22                	jmp    8003ee <vprintfmt+0xde>
  8003cc:	8b 4d dc             	mov    -0x24(%ebp),%ecx
  8003cf:	85 c9                	test   %ecx,%ecx
  8003d1:	b8 00 00 00 00       	mov    $0x0,%eax
  8003d6:	0f 49 c1             	cmovns %ecx,%eax
  8003d9:	89 45 dc             	mov    %eax,-0x24(%ebp)
		width = -1;
		precision = -1;
		lflag = 0;
		altflag = 0;
	reswitch:
		switch (ch = *(unsigned char *) fmt++) {
  8003dc:	89 fb                	mov    %edi,%ebx
  8003de:	eb 9d                	jmp    80037d <vprintfmt+0x6d>
  8003e0:	89 fb                	mov    %edi,%ebx
			if (width < 0)
				width = 0;
			goto reswitch;

		case '#':
			altflag = 1;
  8003e2:	c7 45 e0 01 00 00 00 	movl   $0x1,-0x20(%ebp)
			goto reswitch;
  8003e9:	eb 92                	jmp    80037d <vprintfmt+0x6d>
  8003eb:	89 4d d4             	mov    %ecx,-0x2c(%ebp)

		process_precision:
			if (width < 0)
  8003ee:	83 7d dc 00          	cmpl   $0x0,-0x24(%ebp)
  8003f2:	79 89                	jns    80037d <vprintfmt+0x6d>
  8003f4:	e9 77 ff ff ff       	jmp    800370 <vprintfmt+0x60>
				width = precision, precision = -1;
			goto reswitch;

		// long flag (doubled for long long)
		case 'l':
			lflag++;
  8003f9:	83 c2 01             	add    $0x1,%edx
		width = -1;
		precision = -1;
		lflag = 0;
		altflag = 0;
	reswitch:
		switch (ch = *(unsigned char *) fmt++) {
  8003fc:	89 fb                	mov    %edi,%ebx
			goto reswitch;

		// long flag (doubled for long long)
		case 'l':
			lflag++;
			goto reswitch;
  8003fe:	e9 7a ff ff ff       	jmp    80037d <vprintfmt+0x6d>

		// character
		case 'c':
			putch(va_arg(ap, int), putdat);
  800403:	8b 45 14             	mov    0x14(%ebp),%eax
  800406:	8d 50 04             	lea    0x4(%eax),%edx
  800409:	89 55 14             	mov    %edx,0x14(%ebp)
  80040c:	89 74 24 04          	mov    %esi,0x4(%esp)
  800410:	8b 00                	mov    (%eax),%eax
  800412:	89 04 24             	mov    %eax,(%esp)
  800415:	ff 55 08             	call   *0x8(%ebp)
			break;
  800418:	e9 18 ff ff ff       	jmp    800335 <vprintfmt+0x25>

		// error message
		case 'e':
			err = va_arg(ap, int);
  80041d:	8b 45 14             	mov    0x14(%ebp),%eax
  800420:	8d 50 04             	lea    0x4(%eax),%edx
  800423:	89 55 14             	mov    %edx,0x14(%ebp)
  800426:	8b 00                	mov    (%eax),%eax
  800428:	99                   	cltd   
  800429:	31 d0                	xor    %edx,%eax
  80042b:	29 d0                	sub    %edx,%eax
			if (err < 0)
				err = -err;
			if (err >= MAXERROR || (p = error_string[err]) == NULL)
  80042d:	83 f8 06             	cmp    $0x6,%eax
  800430:	7f 0b                	jg     80043d <vprintfmt+0x12d>
  800432:	8b 14 85 dc 10 80 00 	mov    0x8010dc(,%eax,4),%edx
  800439:	85 d2                	test   %edx,%edx
  80043b:	75 20                	jne    80045d <vprintfmt+0x14d>
				printfmt(putch, putdat, "error %d", err);
  80043d:	89 44 24 0c          	mov    %eax,0xc(%esp)
  800441:	c7 44 24 08 0f 0f 80 	movl   $0x800f0f,0x8(%esp)
  800448:	00 
  800449:	89 74 24 04          	mov    %esi,0x4(%esp)
  80044d:	8b 45 08             	mov    0x8(%ebp),%eax
  800450:	89 04 24             	mov    %eax,(%esp)
  800453:	e8 90 fe ff ff       	call   8002e8 <printfmt>
  800458:	e9 d8 fe ff ff       	jmp    800335 <vprintfmt+0x25>
			else
				printfmt(putch, putdat, "%s", p);
  80045d:	89 54 24 0c          	mov    %edx,0xc(%esp)
  800461:	c7 44 24 08 18 0f 80 	movl   $0x800f18,0x8(%esp)
  800468:	00 
  800469:	89 74 24 04          	mov    %esi,0x4(%esp)
  80046d:	8b 45 08             	mov    0x8(%ebp),%eax
  800470:	89 04 24             	mov    %eax,(%esp)
  800473:	e8 70 fe ff ff       	call   8002e8 <printfmt>
  800478:	e9 b8 fe ff ff       	jmp    800335 <vprintfmt+0x25>
		width = -1;
		precision = -1;
		lflag = 0;
		altflag = 0;
	reswitch:
		switch (ch = *(unsigned char *) fmt++) {
  80047d:	8b 4d d4             	mov    -0x2c(%ebp),%ecx
  800480:	8b 45 dc             	mov    -0x24(%ebp),%eax
  800483:	89 45 d0             	mov    %eax,-0x30(%ebp)
				printfmt(putch, putdat, "%s", p);
			break;

		// string
		case 's':
			if ((p = va_arg(ap, char *)) == NULL)
  800486:	8b 45 14             	mov    0x14(%ebp),%eax
  800489:	8d 50 04             	lea    0x4(%eax),%edx
  80048c:	89 55 14             	mov    %edx,0x14(%ebp)
  80048f:	8b 18                	mov    (%eax),%ebx
				p = "(null)";
  800491:	85 db                	test   %ebx,%ebx
  800493:	b8 08 0f 80 00       	mov    $0x800f08,%eax
  800498:	0f 44 d8             	cmove  %eax,%ebx
			if (width > 0 && padc != '-')
  80049b:	80 7d d8 2d          	cmpb   $0x2d,-0x28(%ebp)
  80049f:	0f 84 97 00 00 00    	je     80053c <vprintfmt+0x22c>
  8004a5:	83 7d d0 00          	cmpl   $0x0,-0x30(%ebp)
  8004a9:	0f 8e 9b 00 00 00    	jle    80054a <vprintfmt+0x23a>
				for (width -= strnlen(p, precision); width > 0; width--)
  8004af:	89 4c 24 04          	mov    %ecx,0x4(%esp)
  8004b3:	89 1c 24             	mov    %ebx,(%esp)
  8004b6:	e8 7d 02 00 00       	call   800738 <strnlen>
  8004bb:	8b 55 d0             	mov    -0x30(%ebp),%edx
  8004be:	29 c2                	sub    %eax,%edx
  8004c0:	89 55 d0             	mov    %edx,-0x30(%ebp)
					putch(padc, putdat);
  8004c3:	0f be 45 d8          	movsbl -0x28(%ebp),%eax
  8004c7:	89 45 dc             	mov    %eax,-0x24(%ebp)
  8004ca:	89 5d d8             	mov    %ebx,-0x28(%ebp)
  8004cd:	89 d3                	mov    %edx,%ebx
  8004cf:	89 7d 10             	mov    %edi,0x10(%ebp)
  8004d2:	8b 7d 08             	mov    0x8(%ebp),%edi
		// string
		case 's':
			if ((p = va_arg(ap, char *)) == NULL)
				p = "(null)";
			if (width > 0 && padc != '-')
				for (width -= strnlen(p, precision); width > 0; width--)
  8004d5:	eb 0f                	jmp    8004e6 <vprintfmt+0x1d6>
					putch(padc, putdat);
  8004d7:	89 74 24 04          	mov    %esi,0x4(%esp)
  8004db:	8b 45 dc             	mov    -0x24(%ebp),%eax
  8004de:	89 04 24             	mov    %eax,(%esp)
  8004e1:	ff d7                	call   *%edi
		// string
		case 's':
			if ((p = va_arg(ap, char *)) == NULL)
				p = "(null)";
			if (width > 0 && padc != '-')
				for (width -= strnlen(p, precision); width > 0; width--)
  8004e3:	83 eb 01             	sub    $0x1,%ebx
  8004e6:	85 db                	test   %ebx,%ebx
  8004e8:	7f ed                	jg     8004d7 <vprintfmt+0x1c7>
  8004ea:	8b 5d d8             	mov    -0x28(%ebp),%ebx
  8004ed:	8b 55 d0             	mov    -0x30(%ebp),%edx
  8004f0:	85 d2                	test   %edx,%edx
  8004f2:	b8 00 00 00 00       	mov    $0x0,%eax
  8004f7:	0f 49 c2             	cmovns %edx,%eax
  8004fa:	29 c2                	sub    %eax,%edx
  8004fc:	89 75 0c             	mov    %esi,0xc(%ebp)
  8004ff:	89 d6                	mov    %edx,%esi
  800501:	8b 7d d4             	mov    -0x2c(%ebp),%edi
  800504:	eb 50                	jmp    800556 <vprintfmt+0x246>
					putch(padc, putdat);
			for (; (ch = *p++) != '\0' && (precision < 0 || --precision >= 0); width--)
				if (altflag && (ch < ' ' || ch > '~'))
  800506:	83 7d e0 00          	cmpl   $0x0,-0x20(%ebp)
  80050a:	74 1e                	je     80052a <vprintfmt+0x21a>
  80050c:	0f be d2             	movsbl %dl,%edx
  80050f:	83 ea 20             	sub    $0x20,%edx
  800512:	83 fa 5e             	cmp    $0x5e,%edx
  800515:	76 13                	jbe    80052a <vprintfmt+0x21a>
					putch('?', putdat);
  800517:	8b 45 0c             	mov    0xc(%ebp),%eax
  80051a:	89 44 24 04          	mov    %eax,0x4(%esp)
  80051e:	c7 04 24 3f 00 00 00 	movl   $0x3f,(%esp)
  800525:	ff 55 08             	call   *0x8(%ebp)
  800528:	eb 0d                	jmp    800537 <vprintfmt+0x227>
				else
					putch(ch, putdat);
  80052a:	8b 55 0c             	mov    0xc(%ebp),%edx
  80052d:	89 54 24 04          	mov    %edx,0x4(%esp)
  800531:	89 04 24             	mov    %eax,(%esp)
  800534:	ff 55 08             	call   *0x8(%ebp)
			if ((p = va_arg(ap, char *)) == NULL)
				p = "(null)";
			if (width > 0 && padc != '-')
				for (width -= strnlen(p, precision); width > 0; width--)
					putch(padc, putdat);
			for (; (ch = *p++) != '\0' && (precision < 0 || --precision >= 0); width--)
  800537:	83 ee 01             	sub    $0x1,%esi
  80053a:	eb 1a                	jmp    800556 <vprintfmt+0x246>
  80053c:	89 75 0c             	mov    %esi,0xc(%ebp)
  80053f:	8b 75 dc             	mov    -0x24(%ebp),%esi
  800542:	89 7d 10             	mov    %edi,0x10(%ebp)
  800545:	8b 7d d4             	mov    -0x2c(%ebp),%edi
  800548:	eb 0c                	jmp    800556 <vprintfmt+0x246>
  80054a:	89 75 0c             	mov    %esi,0xc(%ebp)
  80054d:	8b 75 dc             	mov    -0x24(%ebp),%esi
  800550:	89 7d 10             	mov    %edi,0x10(%ebp)
  800553:	8b 7d d4             	mov    -0x2c(%ebp),%edi
  800556:	83 c3 01             	add    $0x1,%ebx
  800559:	0f b6 53 ff          	movzbl -0x1(%ebx),%edx
  80055d:	0f be c2             	movsbl %dl,%eax
  800560:	85 c0                	test   %eax,%eax
  800562:	74 25                	je     800589 <vprintfmt+0x279>
  800564:	85 ff                	test   %edi,%edi
  800566:	78 9e                	js     800506 <vprintfmt+0x1f6>
  800568:	83 ef 01             	sub    $0x1,%edi
  80056b:	79 99                	jns    800506 <vprintfmt+0x1f6>
  80056d:	89 f3                	mov    %esi,%ebx
  80056f:	8b 75 0c             	mov    0xc(%ebp),%esi
  800572:	8b 7d 08             	mov    0x8(%ebp),%edi
  800575:	eb 1a                	jmp    800591 <vprintfmt+0x281>
				if (altflag && (ch < ' ' || ch > '~'))
					putch('?', putdat);
				else
					putch(ch, putdat);
			for (; width > 0; width--)
				putch(' ', putdat);
  800577:	89 74 24 04          	mov    %esi,0x4(%esp)
  80057b:	c7 04 24 20 00 00 00 	movl   $0x20,(%esp)
  800582:	ff d7                	call   *%edi
			for (; (ch = *p++) != '\0' && (precision < 0 || --precision >= 0); width--)
				if (altflag && (ch < ' ' || ch > '~'))
					putch('?', putdat);
				else
					putch(ch, putdat);
			for (; width > 0; width--)
  800584:	83 eb 01             	sub    $0x1,%ebx
  800587:	eb 08                	jmp    800591 <vprintfmt+0x281>
  800589:	89 f3                	mov    %esi,%ebx
  80058b:	8b 7d 08             	mov    0x8(%ebp),%edi
  80058e:	8b 75 0c             	mov    0xc(%ebp),%esi
  800591:	85 db                	test   %ebx,%ebx
  800593:	7f e2                	jg     800577 <vprintfmt+0x267>
  800595:	89 7d 08             	mov    %edi,0x8(%ebp)
  800598:	8b 7d 10             	mov    0x10(%ebp),%edi
  80059b:	e9 95 fd ff ff       	jmp    800335 <vprintfmt+0x25>
				putch(' ', putdat);
			break;

		// (signed) decimal
		case 'd':
			num = getint(&ap, lflag);
  8005a0:	8d 45 14             	lea    0x14(%ebp),%eax
  8005a3:	e8 f1 fc ff ff       	call   800299 <getint>
  8005a8:	89 45 e0             	mov    %eax,-0x20(%ebp)
  8005ab:	89 55 e4             	mov    %edx,-0x1c(%ebp)
			if ((long long) num < 0) {
				putch('-', putdat);
				num = -(long long) num;
			}
			base = 10;
  8005ae:	bb 0a 00 00 00       	mov    $0xa,%ebx
			break;

		// (signed) decimal
		case 'd':
			num = getint(&ap, lflag);
			if ((long long) num < 0) {
  8005b3:	83 7d e4 00          	cmpl   $0x0,-0x1c(%ebp)
  8005b7:	79 7b                	jns    800634 <vprintfmt+0x324>
				putch('-', putdat);
  8005b9:	89 74 24 04          	mov    %esi,0x4(%esp)
  8005bd:	c7 04 24 2d 00 00 00 	movl   $0x2d,(%esp)
  8005c4:	ff 55 08             	call   *0x8(%ebp)
				num = -(long long) num;
  8005c7:	8b 45 e0             	mov    -0x20(%ebp),%eax
  8005ca:	8b 55 e4             	mov    -0x1c(%ebp),%edx
  8005cd:	f7 d8                	neg    %eax
  8005cf:	83 d2 00             	adc    $0x0,%edx
  8005d2:	f7 da                	neg    %edx
  8005d4:	eb 5e                	jmp    800634 <vprintfmt+0x324>
			base = 10;
			goto number;

		// unsigned decimal
		case 'u':
			num = getuint(&ap, lflag);
  8005d6:	8d 45 14             	lea    0x14(%ebp),%eax
  8005d9:	e8 81 fc ff ff       	call   80025f <getuint>
			base = 10;
  8005de:	bb 0a 00 00 00       	mov    $0xa,%ebx
			goto number;
  8005e3:	eb 4f                	jmp    800634 <vprintfmt+0x324>

		// (unsigned) octal
		case 'o':
			num = getuint(&ap, lflag);
  8005e5:	8d 45 14             	lea    0x14(%ebp),%eax
  8005e8:	e8 72 fc ff ff       	call   80025f <getuint>
			base = 8;
  8005ed:	bb 08 00 00 00       	mov    $0x8,%ebx
			goto number;
  8005f2:	eb 40                	jmp    800634 <vprintfmt+0x324>

		// pointer
		case 'p':
			putch('0', putdat);
  8005f4:	89 74 24 04          	mov    %esi,0x4(%esp)
  8005f8:	c7 04 24 30 00 00 00 	movl   $0x30,(%esp)
  8005ff:	ff 55 08             	call   *0x8(%ebp)
			putch('x', putdat);
  800602:	89 74 24 04          	mov    %esi,0x4(%esp)
  800606:	c7 04 24 78 00 00 00 	movl   $0x78,(%esp)
  80060d:	ff 55 08             	call   *0x8(%ebp)
			num = (unsigned long long)
				(uintptr_t) va_arg(ap, void *);
  800610:	8b 45 14             	mov    0x14(%ebp),%eax
  800613:	8d 50 04             	lea    0x4(%eax),%edx
  800616:	89 55 14             	mov    %edx,0x14(%ebp)

		// pointer
		case 'p':
			putch('0', putdat);
			putch('x', putdat);
			num = (unsigned long long)
  800619:	8b 00                	mov    (%eax),%eax
  80061b:	ba 00 00 00 00       	mov    $0x0,%edx
				(uintptr_t) va_arg(ap, void *);
			base = 16;
  800620:	bb 10 00 00 00       	mov    $0x10,%ebx
			goto number;
  800625:	eb 0d                	jmp    800634 <vprintfmt+0x324>

		// (unsigned) hexadecimal
		case 'x':
			num = getuint(&ap, lflag);
  800627:	8d 45 14             	lea    0x14(%ebp),%eax
  80062a:	e8 30 fc ff ff       	call   80025f <getuint>
			base = 16;
  80062f:	bb 10 00 00 00       	mov    $0x10,%ebx
		number:
			printnum(putch, putdat, num, base, width, padc);
  800634:	0f be 4d d8          	movsbl -0x28(%ebp),%ecx
  800638:	89 4c 24 10          	mov    %ecx,0x10(%esp)
  80063c:	8b 4d dc             	mov    -0x24(%ebp),%ecx
  80063f:	89 4c 24 0c          	mov    %ecx,0xc(%esp)
  800643:	89 5c 24 08          	mov    %ebx,0x8(%esp)
  800647:	89 04 24             	mov    %eax,(%esp)
  80064a:	89 54 24 04          	mov    %edx,0x4(%esp)
  80064e:	89 f2                	mov    %esi,%edx
  800650:	8b 45 08             	mov    0x8(%ebp),%eax
  800653:	e8 18 fb ff ff       	call   800170 <printnum>
			break;
  800658:	e9 d8 fc ff ff       	jmp    800335 <vprintfmt+0x25>

		// escaped '%' character
		case '%':
			putch(ch, putdat);
  80065d:	89 74 24 04          	mov    %esi,0x4(%esp)
  800661:	89 04 24             	mov    %eax,(%esp)
  800664:	ff 55 08             	call   *0x8(%ebp)
			break;
  800667:	e9 c9 fc ff ff       	jmp    800335 <vprintfmt+0x25>

		// unrecognized escape sequence - just print it literally
		default:
			putch('%', putdat);
  80066c:	89 74 24 04          	mov    %esi,0x4(%esp)
  800670:	c7 04 24 25 00 00 00 	movl   $0x25,(%esp)
  800677:	ff 55 08             	call   *0x8(%ebp)
			for (fmt--; fmt[-1] != '%'; fmt--)
  80067a:	89 df                	mov    %ebx,%edi
  80067c:	eb 03                	jmp    800681 <vprintfmt+0x371>
  80067e:	83 ef 01             	sub    $0x1,%edi
  800681:	80 7f ff 25          	cmpb   $0x25,-0x1(%edi)
  800685:	75 f7                	jne    80067e <vprintfmt+0x36e>
  800687:	e9 a9 fc ff ff       	jmp    800335 <vprintfmt+0x25>
				/* do nothing */;
			break;
		}
	}
}
  80068c:	83 c4 3c             	add    $0x3c,%esp
  80068f:	5b                   	pop    %ebx
  800690:	5e                   	pop    %esi
  800691:	5f                   	pop    %edi
  800692:	5d                   	pop    %ebp
  800693:	c3                   	ret    

00800694 <vsnprintf>:
		*b->buf++ = ch;
}

int
vsnprintf(char *buf, int n, const char *fmt, va_list ap)
{
  800694:	55                   	push   %ebp
  800695:	89 e5                	mov    %esp,%ebp
  800697:	83 ec 28             	sub    $0x28,%esp
  80069a:	8b 45 08             	mov    0x8(%ebp),%eax
  80069d:	8b 55 0c             	mov    0xc(%ebp),%edx
	struct sprintbuf b = {buf, buf+n-1, 0};
  8006a0:	89 45 ec             	mov    %eax,-0x14(%ebp)
  8006a3:	8d 4c 10 ff          	lea    -0x1(%eax,%edx,1),%ecx
  8006a7:	89 4d f0             	mov    %ecx,-0x10(%ebp)
  8006aa:	c7 45 f4 00 00 00 00 	movl   $0x0,-0xc(%ebp)

	if (buf == NULL || n < 1)
  8006b1:	85 c0                	test   %eax,%eax
  8006b3:	74 30                	je     8006e5 <vsnprintf+0x51>
  8006b5:	85 d2                	test   %edx,%edx
  8006b7:	7e 2c                	jle    8006e5 <vsnprintf+0x51>
		return -E_INVAL;

	// print the string to the buffer
	vprintfmt((void*)sprintputch, &b, fmt, ap);
  8006b9:	8b 45 14             	mov    0x14(%ebp),%eax
  8006bc:	89 44 24 0c          	mov    %eax,0xc(%esp)
  8006c0:	8b 45 10             	mov    0x10(%ebp),%eax
  8006c3:	89 44 24 08          	mov    %eax,0x8(%esp)
  8006c7:	8d 45 ec             	lea    -0x14(%ebp),%eax
  8006ca:	89 44 24 04          	mov    %eax,0x4(%esp)
  8006ce:	c7 04 24 cb 02 80 00 	movl   $0x8002cb,(%esp)
  8006d5:	e8 36 fc ff ff       	call   800310 <vprintfmt>

	// null terminate the buffer
	*b.buf = '\0';
  8006da:	8b 45 ec             	mov    -0x14(%ebp),%eax
  8006dd:	c6 00 00             	movb   $0x0,(%eax)

	return b.cnt;
  8006e0:	8b 45 f4             	mov    -0xc(%ebp),%eax
  8006e3:	eb 05                	jmp    8006ea <vsnprintf+0x56>
vsnprintf(char *buf, int n, const char *fmt, va_list ap)
{
	struct sprintbuf b = {buf, buf+n-1, 0};

	if (buf == NULL || n < 1)
		return -E_INVAL;
  8006e5:	b8 fd ff ff ff       	mov    $0xfffffffd,%eax

	// null terminate the buffer
	*b.buf = '\0';

	return b.cnt;
}
  8006ea:	c9                   	leave  
  8006eb:	c3                   	ret    

008006ec <snprintf>:

int
snprintf(char *buf, int n, const char *fmt, ...)
{
  8006ec:	55                   	push   %ebp
  8006ed:	89 e5                	mov    %esp,%ebp
  8006ef:	83 ec 18             	sub    $0x18,%esp
	va_list ap;
	int rc;

	va_start(ap, fmt);
  8006f2:	8d 45 14             	lea    0x14(%ebp),%eax
	rc = vsnprintf(buf, n, fmt, ap);
  8006f5:	89 44 24 0c          	mov    %eax,0xc(%esp)
  8006f9:	8b 45 10             	mov    0x10(%ebp),%eax
  8006fc:	89 44 24 08          	mov    %eax,0x8(%esp)
  800700:	8b 45 0c             	mov    0xc(%ebp),%eax
  800703:	89 44 24 04          	mov    %eax,0x4(%esp)
  800707:	8b 45 08             	mov    0x8(%ebp),%eax
  80070a:	89 04 24             	mov    %eax,(%esp)
  80070d:	e8 82 ff ff ff       	call   800694 <vsnprintf>
	va_end(ap);

	return rc;
}
  800712:	c9                   	leave  
  800713:	c3                   	ret    
  800714:	66 90                	xchg   %ax,%ax
  800716:	66 90                	xchg   %ax,%ax
  800718:	66 90                	xchg   %ax,%ax
  80071a:	66 90                	xchg   %ax,%ax
  80071c:	66 90                	xchg   %ax,%ax
  80071e:	66 90                	xchg   %ax,%ax

00800720 <strlen>:
// Primespipe runs 3x faster this way.
#define ASM 1

int
strlen(const char *s)
{
  800720:	55                   	push   %ebp
  800721:	89 e5                	mov    %esp,%ebp
  800723:	8b 55 08             	mov    0x8(%ebp),%edx
	int n;

	for (n = 0; *s != '\0'; s++)
  800726:	b8 00 00 00 00       	mov    $0x0,%eax
  80072b:	eb 03                	jmp    800730 <strlen+0x10>
		n++;
  80072d:	83 c0 01             	add    $0x1,%eax
int
strlen(const char *s)
{
	int n;

	for (n = 0; *s != '\0'; s++)
  800730:	80 3c 02 00          	cmpb   $0x0,(%edx,%eax,1)
  800734:	75 f7                	jne    80072d <strlen+0xd>
		n++;
	return n;
}
  800736:	5d                   	pop    %ebp
  800737:	c3                   	ret    

00800738 <strnlen>:

int
strnlen(const char *s, size_t size)
{
  800738:	55                   	push   %ebp
  800739:	89 e5                	mov    %esp,%ebp
  80073b:	8b 4d 08             	mov    0x8(%ebp),%ecx
  80073e:	8b 55 0c             	mov    0xc(%ebp),%edx
	int n;

	for (n = 0; size > 0 && *s != '\0'; s++, size--)
  800741:	b8 00 00 00 00       	mov    $0x0,%eax
  800746:	eb 03                	jmp    80074b <strnlen+0x13>
		n++;
  800748:	83 c0 01             	add    $0x1,%eax
int
strnlen(const char *s, size_t size)
{
	int n;

	for (n = 0; size > 0 && *s != '\0'; s++, size--)
  80074b:	39 d0                	cmp    %edx,%eax
  80074d:	74 06                	je     800755 <strnlen+0x1d>
  80074f:	80 3c 01 00          	cmpb   $0x0,(%ecx,%eax,1)
  800753:	75 f3                	jne    800748 <strnlen+0x10>
		n++;
	return n;
}
  800755:	5d                   	pop    %ebp
  800756:	c3                   	ret    

00800757 <strcpy>:

char *
strcpy(char *dst, const char *src)
{
  800757:	55                   	push   %ebp
  800758:	89 e5                	mov    %esp,%ebp
  80075a:	53                   	push   %ebx
  80075b:	8b 45 08             	mov    0x8(%ebp),%eax
  80075e:	8b 4d 0c             	mov    0xc(%ebp),%ecx
	char *ret;

	ret = dst;
	while ((*dst++ = *src++) != '\0')
  800761:	89 c2                	mov    %eax,%edx
  800763:	83 c2 01             	add    $0x1,%edx
  800766:	83 c1 01             	add    $0x1,%ecx
  800769:	0f b6 59 ff          	movzbl -0x1(%ecx),%ebx
  80076d:	88 5a ff             	mov    %bl,-0x1(%edx)
  800770:	84 db                	test   %bl,%bl
  800772:	75 ef                	jne    800763 <strcpy+0xc>
		/* do nothing */;
	return ret;
}
  800774:	5b                   	pop    %ebx
  800775:	5d                   	pop    %ebp
  800776:	c3                   	ret    

00800777 <strcat>:

char *
strcat(char *dst, const char *src)
{
  800777:	55                   	push   %ebp
  800778:	89 e5                	mov    %esp,%ebp
  80077a:	53                   	push   %ebx
  80077b:	83 ec 08             	sub    $0x8,%esp
  80077e:	8b 5d 08             	mov    0x8(%ebp),%ebx
	int len = strlen(dst);
  800781:	89 1c 24             	mov    %ebx,(%esp)
  800784:	e8 97 ff ff ff       	call   800720 <strlen>
	strcpy(dst + len, src);
  800789:	8b 55 0c             	mov    0xc(%ebp),%edx
  80078c:	89 54 24 04          	mov    %edx,0x4(%esp)
  800790:	01 d8                	add    %ebx,%eax
  800792:	89 04 24             	mov    %eax,(%esp)
  800795:	e8 bd ff ff ff       	call   800757 <strcpy>
	return dst;
}
  80079a:	89 d8                	mov    %ebx,%eax
  80079c:	83 c4 08             	add    $0x8,%esp
  80079f:	5b                   	pop    %ebx
  8007a0:	5d                   	pop    %ebp
  8007a1:	c3                   	ret    

008007a2 <strncpy>:

char *
strncpy(char *dst, const char *src, size_t size) {
  8007a2:	55                   	push   %ebp
  8007a3:	89 e5                	mov    %esp,%ebp
  8007a5:	56                   	push   %esi
  8007a6:	53                   	push   %ebx
  8007a7:	8b 75 08             	mov    0x8(%ebp),%esi
  8007aa:	8b 4d 0c             	mov    0xc(%ebp),%ecx
  8007ad:	89 f3                	mov    %esi,%ebx
  8007af:	03 5d 10             	add    0x10(%ebp),%ebx
	size_t i;
	char *ret;

	ret = dst;
	for (i = 0; i < size; i++) {
  8007b2:	89 f2                	mov    %esi,%edx
  8007b4:	eb 0f                	jmp    8007c5 <strncpy+0x23>
		*dst++ = *src;
  8007b6:	83 c2 01             	add    $0x1,%edx
  8007b9:	0f b6 01             	movzbl (%ecx),%eax
  8007bc:	88 42 ff             	mov    %al,-0x1(%edx)
		// If strlen(src) < size, null-pad 'dst' out to 'size' chars
		if (*src != '\0')
			src++;
  8007bf:	80 39 01             	cmpb   $0x1,(%ecx)
  8007c2:	83 d9 ff             	sbb    $0xffffffff,%ecx
strncpy(char *dst, const char *src, size_t size) {
	size_t i;
	char *ret;

	ret = dst;
	for (i = 0; i < size; i++) {
  8007c5:	39 da                	cmp    %ebx,%edx
  8007c7:	75 ed                	jne    8007b6 <strncpy+0x14>
		// If strlen(src) < size, null-pad 'dst' out to 'size' chars
		if (*src != '\0')
			src++;
	}
	return ret;
}
  8007c9:	89 f0                	mov    %esi,%eax
  8007cb:	5b                   	pop    %ebx
  8007cc:	5e                   	pop    %esi
  8007cd:	5d                   	pop    %ebp
  8007ce:	c3                   	ret    

008007cf <strlcpy>:

size_t
strlcpy(char *dst, const char *src, size_t size)
{
  8007cf:	55                   	push   %ebp
  8007d0:	89 e5                	mov    %esp,%ebp
  8007d2:	56                   	push   %esi
  8007d3:	53                   	push   %ebx
  8007d4:	8b 75 08             	mov    0x8(%ebp),%esi
  8007d7:	8b 55 0c             	mov    0xc(%ebp),%edx
  8007da:	8b 4d 10             	mov    0x10(%ebp),%ecx
  8007dd:	89 f0                	mov    %esi,%eax
  8007df:	8d 5c 0e ff          	lea    -0x1(%esi,%ecx,1),%ebx
	char *dst_in;

	dst_in = dst;
	if (size > 0) {
  8007e3:	85 c9                	test   %ecx,%ecx
  8007e5:	75 0b                	jne    8007f2 <strlcpy+0x23>
  8007e7:	eb 1d                	jmp    800806 <strlcpy+0x37>
		while (--size > 0 && *src != '\0')
			*dst++ = *src++;
  8007e9:	83 c0 01             	add    $0x1,%eax
  8007ec:	83 c2 01             	add    $0x1,%edx
  8007ef:	88 48 ff             	mov    %cl,-0x1(%eax)
{
	char *dst_in;

	dst_in = dst;
	if (size > 0) {
		while (--size > 0 && *src != '\0')
  8007f2:	39 d8                	cmp    %ebx,%eax
  8007f4:	74 0b                	je     800801 <strlcpy+0x32>
  8007f6:	0f b6 0a             	movzbl (%edx),%ecx
  8007f9:	84 c9                	test   %cl,%cl
  8007fb:	75 ec                	jne    8007e9 <strlcpy+0x1a>
  8007fd:	89 c2                	mov    %eax,%edx
  8007ff:	eb 02                	jmp    800803 <strlcpy+0x34>
  800801:	89 c2                	mov    %eax,%edx
			*dst++ = *src++;
		*dst = '\0';
  800803:	c6 02 00             	movb   $0x0,(%edx)
	}
	return dst - dst_in;
  800806:	29 f0                	sub    %esi,%eax
}
  800808:	5b                   	pop    %ebx
  800809:	5e                   	pop    %esi
  80080a:	5d                   	pop    %ebp
  80080b:	c3                   	ret    

0080080c <strcmp>:

int
strcmp(const char *p, const char *q)
{
  80080c:	55                   	push   %ebp
  80080d:	89 e5                	mov    %esp,%ebp
  80080f:	8b 4d 08             	mov    0x8(%ebp),%ecx
  800812:	8b 55 0c             	mov    0xc(%ebp),%edx
	while (*p && *p == *q)
  800815:	eb 06                	jmp    80081d <strcmp+0x11>
		p++, q++;
  800817:	83 c1 01             	add    $0x1,%ecx
  80081a:	83 c2 01             	add    $0x1,%edx
}

int
strcmp(const char *p, const char *q)
{
	while (*p && *p == *q)
  80081d:	0f b6 01             	movzbl (%ecx),%eax
  800820:	84 c0                	test   %al,%al
  800822:	74 04                	je     800828 <strcmp+0x1c>
  800824:	3a 02                	cmp    (%edx),%al
  800826:	74 ef                	je     800817 <strcmp+0xb>
		p++, q++;
	return (int) ((unsigned char) *p - (unsigned char) *q);
  800828:	0f b6 c0             	movzbl %al,%eax
  80082b:	0f b6 12             	movzbl (%edx),%edx
  80082e:	29 d0                	sub    %edx,%eax
}
  800830:	5d                   	pop    %ebp
  800831:	c3                   	ret    

00800832 <strncmp>:

int
strncmp(const char *p, const char *q, size_t n)
{
  800832:	55                   	push   %ebp
  800833:	89 e5                	mov    %esp,%ebp
  800835:	53                   	push   %ebx
  800836:	8b 45 08             	mov    0x8(%ebp),%eax
  800839:	8b 55 0c             	mov    0xc(%ebp),%edx
  80083c:	89 c3                	mov    %eax,%ebx
  80083e:	03 5d 10             	add    0x10(%ebp),%ebx
	while (n > 0 && *p && *p == *q)
  800841:	eb 06                	jmp    800849 <strncmp+0x17>
		n--, p++, q++;
  800843:	83 c0 01             	add    $0x1,%eax
  800846:	83 c2 01             	add    $0x1,%edx
}

int
strncmp(const char *p, const char *q, size_t n)
{
	while (n > 0 && *p && *p == *q)
  800849:	39 d8                	cmp    %ebx,%eax
  80084b:	74 15                	je     800862 <strncmp+0x30>
  80084d:	0f b6 08             	movzbl (%eax),%ecx
  800850:	84 c9                	test   %cl,%cl
  800852:	74 04                	je     800858 <strncmp+0x26>
  800854:	3a 0a                	cmp    (%edx),%cl
  800856:	74 eb                	je     800843 <strncmp+0x11>
		n--, p++, q++;
	if (n == 0)
		return 0;
	else
		return (int) ((unsigned char) *p - (unsigned char) *q);
  800858:	0f b6 00             	movzbl (%eax),%eax
  80085b:	0f b6 12             	movzbl (%edx),%edx
  80085e:	29 d0                	sub    %edx,%eax
  800860:	eb 05                	jmp    800867 <strncmp+0x35>
strncmp(const char *p, const char *q, size_t n)
{
	while (n > 0 && *p && *p == *q)
		n--, p++, q++;
	if (n == 0)
		return 0;
  800862:	b8 00 00 00 00       	mov    $0x0,%eax
	else
		return (int) ((unsigned char) *p - (unsigned char) *q);
}
  800867:	5b                   	pop    %ebx
  800868:	5d                   	pop    %ebp
  800869:	c3                   	ret    

0080086a <strchr>:

// Return a pointer to the first occurrence of 'c' in 's',
// or a null pointer if the string has no 'c'.
char *
strchr(const char *s, char c)
{
  80086a:	55                   	push   %ebp
  80086b:	89 e5                	mov    %esp,%ebp
  80086d:	8b 45 08             	mov    0x8(%ebp),%eax
  800870:	0f b6 4d 0c          	movzbl 0xc(%ebp),%ecx
	for (; *s; s++)
  800874:	eb 07                	jmp    80087d <strchr+0x13>
		if (*s == c)
  800876:	38 ca                	cmp    %cl,%dl
  800878:	74 0f                	je     800889 <strchr+0x1f>
// Return a pointer to the first occurrence of 'c' in 's',
// or a null pointer if the string has no 'c'.
char *
strchr(const char *s, char c)
{
	for (; *s; s++)
  80087a:	83 c0 01             	add    $0x1,%eax
  80087d:	0f b6 10             	movzbl (%eax),%edx
  800880:	84 d2                	test   %dl,%dl
  800882:	75 f2                	jne    800876 <strchr+0xc>
		if (*s == c)
			return (char *) s;
	return 0;
  800884:	b8 00 00 00 00       	mov    $0x0,%eax
}
  800889:	5d                   	pop    %ebp
  80088a:	c3                   	ret    

0080088b <strfind>:

// Return a pointer to the first occurrence of 'c' in 's',
// or a pointer to the string-ending null character if the string has no 'c'.
char *
strfind(const char *s, char c)
{
  80088b:	55                   	push   %ebp
  80088c:	89 e5                	mov    %esp,%ebp
  80088e:	8b 45 08             	mov    0x8(%ebp),%eax
  800891:	0f b6 4d 0c          	movzbl 0xc(%ebp),%ecx
	for (; *s; s++)
  800895:	eb 07                	jmp    80089e <strfind+0x13>
		if (*s == c)
  800897:	38 ca                	cmp    %cl,%dl
  800899:	74 0a                	je     8008a5 <strfind+0x1a>
// Return a pointer to the first occurrence of 'c' in 's',
// or a pointer to the string-ending null character if the string has no 'c'.
char *
strfind(const char *s, char c)
{
	for (; *s; s++)
  80089b:	83 c0 01             	add    $0x1,%eax
  80089e:	0f b6 10             	movzbl (%eax),%edx
  8008a1:	84 d2                	test   %dl,%dl
  8008a3:	75 f2                	jne    800897 <strfind+0xc>
		if (*s == c)
			break;
	return (char *) s;
}
  8008a5:	5d                   	pop    %ebp
  8008a6:	c3                   	ret    

008008a7 <memset>:

#if ASM
void *
memset(void *v, int c, size_t n)
{
  8008a7:	55                   	push   %ebp
  8008a8:	89 e5                	mov    %esp,%ebp
  8008aa:	57                   	push   %edi
  8008ab:	56                   	push   %esi
  8008ac:	53                   	push   %ebx
  8008ad:	8b 55 08             	mov    0x8(%ebp),%edx
  8008b0:	8b 4d 10             	mov    0x10(%ebp),%ecx
	char *p = v;

	if (n == 0)
  8008b3:	85 c9                	test   %ecx,%ecx
  8008b5:	74 37                	je     8008ee <memset+0x47>
		return v;
	if ((int)v%4 == 0 && n%4 == 0) {
  8008b7:	f6 c2 03             	test   $0x3,%dl
  8008ba:	75 2a                	jne    8008e6 <memset+0x3f>
  8008bc:	f6 c1 03             	test   $0x3,%cl
  8008bf:	75 25                	jne    8008e6 <memset+0x3f>
		c &= 0xFF;
  8008c1:	0f b6 7d 0c          	movzbl 0xc(%ebp),%edi
		c = (c<<24)|(c<<16)|(c<<8)|c;
  8008c5:	89 fb                	mov    %edi,%ebx
  8008c7:	c1 e3 08             	shl    $0x8,%ebx
  8008ca:	89 fe                	mov    %edi,%esi
  8008cc:	c1 e6 18             	shl    $0x18,%esi
  8008cf:	89 f8                	mov    %edi,%eax
  8008d1:	c1 e0 10             	shl    $0x10,%eax
  8008d4:	09 f0                	or     %esi,%eax
  8008d6:	09 c7                	or     %eax,%edi
		asm volatile("cld; rep stosl\n"
			: "=D" (p), "=c" (n)
			: "D" (p), "a" (c), "c" (n/4)
  8008d8:	c1 e9 02             	shr    $0x2,%ecx

	if (n == 0)
		return v;
	if ((int)v%4 == 0 && n%4 == 0) {
		c &= 0xFF;
		c = (c<<24)|(c<<16)|(c<<8)|c;
  8008db:	89 f8                	mov    %edi,%eax
  8008dd:	09 d8                	or     %ebx,%eax
		asm volatile("cld; rep stosl\n"
  8008df:	89 d7                	mov    %edx,%edi
  8008e1:	fc                   	cld    
  8008e2:	f3 ab                	rep stos %eax,%es:(%edi)
  8008e4:	eb 08                	jmp    8008ee <memset+0x47>
			: "=D" (p), "=c" (n)
			: "D" (p), "a" (c), "c" (n/4)
			: "cc", "memory");
	} else
		asm volatile("cld; rep stosb\n"
  8008e6:	89 d7                	mov    %edx,%edi
  8008e8:	8b 45 0c             	mov    0xc(%ebp),%eax
  8008eb:	fc                   	cld    
  8008ec:	f3 aa                	rep stos %al,%es:(%edi)
			: "=D" (p), "=c" (n)
			: "0" (p), "a" (c), "1" (n)
			: "cc", "memory");
	return v;
}
  8008ee:	89 d0                	mov    %edx,%eax
  8008f0:	5b                   	pop    %ebx
  8008f1:	5e                   	pop    %esi
  8008f2:	5f                   	pop    %edi
  8008f3:	5d                   	pop    %ebp
  8008f4:	c3                   	ret    

008008f5 <memmove>:

void *
memmove(void *dst, const void *src, size_t n)
{
  8008f5:	55                   	push   %ebp
  8008f6:	89 e5                	mov    %esp,%ebp
  8008f8:	57                   	push   %edi
  8008f9:	56                   	push   %esi
  8008fa:	8b 45 08             	mov    0x8(%ebp),%eax
  8008fd:	8b 75 0c             	mov    0xc(%ebp),%esi
  800900:	8b 4d 10             	mov    0x10(%ebp),%ecx
	const char *s;
	char *d;

	s = src;
	d = dst;
	if (s < d && s + n > d) {
  800903:	39 c6                	cmp    %eax,%esi
  800905:	73 35                	jae    80093c <memmove+0x47>
  800907:	8d 14 0e             	lea    (%esi,%ecx,1),%edx
  80090a:	39 d0                	cmp    %edx,%eax
  80090c:	73 2e                	jae    80093c <memmove+0x47>
		s += n;
		d += n;
  80090e:	8d 3c 08             	lea    (%eax,%ecx,1),%edi
  800911:	89 d6                	mov    %edx,%esi
  800913:	09 fe                	or     %edi,%esi
		if ((int)s%4 == 0 && (int)d%4 == 0 && n%4 == 0)
  800915:	f7 c6 03 00 00 00    	test   $0x3,%esi
  80091b:	75 13                	jne    800930 <memmove+0x3b>
  80091d:	f6 c1 03             	test   $0x3,%cl
  800920:	75 0e                	jne    800930 <memmove+0x3b>
			asm volatile("std; rep movsl\n"
				:: "D" (d-4), "S" (s-4), "c" (n/4) : "cc", "memory");
  800922:	83 ef 04             	sub    $0x4,%edi
  800925:	8d 72 fc             	lea    -0x4(%edx),%esi
  800928:	c1 e9 02             	shr    $0x2,%ecx
	d = dst;
	if (s < d && s + n > d) {
		s += n;
		d += n;
		if ((int)s%4 == 0 && (int)d%4 == 0 && n%4 == 0)
			asm volatile("std; rep movsl\n"
  80092b:	fd                   	std    
  80092c:	f3 a5                	rep movsl %ds:(%esi),%es:(%edi)
  80092e:	eb 09                	jmp    800939 <memmove+0x44>
				:: "D" (d-4), "S" (s-4), "c" (n/4) : "cc", "memory");
		else
			asm volatile("std; rep movsb\n"
				:: "D" (d-1), "S" (s-1), "c" (n) : "cc", "memory");
  800930:	83 ef 01             	sub    $0x1,%edi
  800933:	8d 72 ff             	lea    -0x1(%edx),%esi
		d += n;
		if ((int)s%4 == 0 && (int)d%4 == 0 && n%4 == 0)
			asm volatile("std; rep movsl\n"
				:: "D" (d-4), "S" (s-4), "c" (n/4) : "cc", "memory");
		else
			asm volatile("std; rep movsb\n"
  800936:	fd                   	std    
  800937:	f3 a4                	rep movsb %ds:(%esi),%es:(%edi)
				:: "D" (d-1), "S" (s-1), "c" (n) : "cc", "memory");
		// Some versions of GCC rely on DF being clear
		asm volatile("cld" ::: "cc");
  800939:	fc                   	cld    
  80093a:	eb 1d                	jmp    800959 <memmove+0x64>
  80093c:	89 f2                	mov    %esi,%edx
  80093e:	09 c2                	or     %eax,%edx
	} else {
		if ((int)s%4 == 0 && (int)d%4 == 0 && n%4 == 0)
  800940:	f6 c2 03             	test   $0x3,%dl
  800943:	75 0f                	jne    800954 <memmove+0x5f>
  800945:	f6 c1 03             	test   $0x3,%cl
  800948:	75 0a                	jne    800954 <memmove+0x5f>
			asm volatile("cld; rep movsl\n"
				:: "D" (d), "S" (s), "c" (n/4) : "cc", "memory");
  80094a:	c1 e9 02             	shr    $0x2,%ecx
				:: "D" (d-1), "S" (s-1), "c" (n) : "cc", "memory");
		// Some versions of GCC rely on DF being clear
		asm volatile("cld" ::: "cc");
	} else {
		if ((int)s%4 == 0 && (int)d%4 == 0 && n%4 == 0)
			asm volatile("cld; rep movsl\n"
  80094d:	89 c7                	mov    %eax,%edi
  80094f:	fc                   	cld    
  800950:	f3 a5                	rep movsl %ds:(%esi),%es:(%edi)
  800952:	eb 05                	jmp    800959 <memmove+0x64>
				:: "D" (d), "S" (s), "c" (n/4) : "cc", "memory");
		else
			asm volatile("cld; rep movsb\n"
  800954:	89 c7                	mov    %eax,%edi
  800956:	fc                   	cld    
  800957:	f3 a4                	rep movsb %ds:(%esi),%es:(%edi)
				:: "D" (d), "S" (s), "c" (n) : "cc", "memory");
	}
	return dst;
}
  800959:	5e                   	pop    %esi
  80095a:	5f                   	pop    %edi
  80095b:	5d                   	pop    %ebp
  80095c:	c3                   	ret    

0080095d <memcpy>:
}
#endif

void *
memcpy(void *dst, const void *src, size_t n)
{
  80095d:	55                   	push   %ebp
  80095e:	89 e5                	mov    %esp,%ebp
  800960:	83 ec 0c             	sub    $0xc,%esp
	return memmove(dst, src, n);
  800963:	8b 45 10             	mov    0x10(%ebp),%eax
  800966:	89 44 24 08          	mov    %eax,0x8(%esp)
  80096a:	8b 45 0c             	mov    0xc(%ebp),%eax
  80096d:	89 44 24 04          	mov    %eax,0x4(%esp)
  800971:	8b 45 08             	mov    0x8(%ebp),%eax
  800974:	89 04 24             	mov    %eax,(%esp)
  800977:	e8 79 ff ff ff       	call   8008f5 <memmove>
}
  80097c:	c9                   	leave  
  80097d:	c3                   	ret    

0080097e <memcmp>:

int
memcmp(const void *v1, const void *v2, size_t n)
{
  80097e:	55                   	push   %ebp
  80097f:	89 e5                	mov    %esp,%ebp
  800981:	56                   	push   %esi
  800982:	53                   	push   %ebx
  800983:	8b 55 08             	mov    0x8(%ebp),%edx
  800986:	8b 4d 0c             	mov    0xc(%ebp),%ecx
  800989:	89 d6                	mov    %edx,%esi
  80098b:	03 75 10             	add    0x10(%ebp),%esi
	const uint8_t *s1 = (const uint8_t *) v1;
	const uint8_t *s2 = (const uint8_t *) v2;

	while (n-- > 0) {
  80098e:	eb 1a                	jmp    8009aa <memcmp+0x2c>
		if (*s1 != *s2)
  800990:	0f b6 02             	movzbl (%edx),%eax
  800993:	0f b6 19             	movzbl (%ecx),%ebx
  800996:	38 d8                	cmp    %bl,%al
  800998:	74 0a                	je     8009a4 <memcmp+0x26>
			return (int) *s1 - (int) *s2;
  80099a:	0f b6 c0             	movzbl %al,%eax
  80099d:	0f b6 db             	movzbl %bl,%ebx
  8009a0:	29 d8                	sub    %ebx,%eax
  8009a2:	eb 0f                	jmp    8009b3 <memcmp+0x35>
		s1++, s2++;
  8009a4:	83 c2 01             	add    $0x1,%edx
  8009a7:	83 c1 01             	add    $0x1,%ecx
memcmp(const void *v1, const void *v2, size_t n)
{
	const uint8_t *s1 = (const uint8_t *) v1;
	const uint8_t *s2 = (const uint8_t *) v2;

	while (n-- > 0) {
  8009aa:	39 f2                	cmp    %esi,%edx
  8009ac:	75 e2                	jne    800990 <memcmp+0x12>
		if (*s1 != *s2)
			return (int) *s1 - (int) *s2;
		s1++, s2++;
	}

	return 0;
  8009ae:	b8 00 00 00 00       	mov    $0x0,%eax
}
  8009b3:	5b                   	pop    %ebx
  8009b4:	5e                   	pop    %esi
  8009b5:	5d                   	pop    %ebp
  8009b6:	c3                   	ret    

008009b7 <memfind>:

void *
memfind(const void *s, int c, size_t n)
{
  8009b7:	55                   	push   %ebp
  8009b8:	89 e5                	mov    %esp,%ebp
  8009ba:	8b 45 08             	mov    0x8(%ebp),%eax
  8009bd:	8b 4d 0c             	mov    0xc(%ebp),%ecx
	const void *ends = (const char *) s + n;
  8009c0:	89 c2                	mov    %eax,%edx
  8009c2:	03 55 10             	add    0x10(%ebp),%edx
	for (; s < ends; s++)
  8009c5:	eb 07                	jmp    8009ce <memfind+0x17>
		if (*(const unsigned char *) s == (unsigned char) c)
  8009c7:	38 08                	cmp    %cl,(%eax)
  8009c9:	74 07                	je     8009d2 <memfind+0x1b>

void *
memfind(const void *s, int c, size_t n)
{
	const void *ends = (const char *) s + n;
	for (; s < ends; s++)
  8009cb:	83 c0 01             	add    $0x1,%eax
  8009ce:	39 d0                	cmp    %edx,%eax
  8009d0:	72 f5                	jb     8009c7 <memfind+0x10>
		if (*(const unsigned char *) s == (unsigned char) c)
			break;
	return (void *) s;
}
  8009d2:	5d                   	pop    %ebp
  8009d3:	c3                   	ret    

008009d4 <strtol>:

long
strtol(const char *s, char **endptr, int base)
{
  8009d4:	55                   	push   %ebp
  8009d5:	89 e5                	mov    %esp,%ebp
  8009d7:	57                   	push   %edi
  8009d8:	56                   	push   %esi
  8009d9:	53                   	push   %ebx
  8009da:	8b 55 08             	mov    0x8(%ebp),%edx
  8009dd:	8b 45 10             	mov    0x10(%ebp),%eax
	int neg = 0;
	long val = 0;

	// gobble initial whitespace
	while (*s == ' ' || *s == '\t')
  8009e0:	eb 03                	jmp    8009e5 <strtol+0x11>
		s++;
  8009e2:	83 c2 01             	add    $0x1,%edx
{
	int neg = 0;
	long val = 0;

	// gobble initial whitespace
	while (*s == ' ' || *s == '\t')
  8009e5:	0f b6 0a             	movzbl (%edx),%ecx
  8009e8:	80 f9 09             	cmp    $0x9,%cl
  8009eb:	74 f5                	je     8009e2 <strtol+0xe>
  8009ed:	80 f9 20             	cmp    $0x20,%cl
  8009f0:	74 f0                	je     8009e2 <strtol+0xe>
		s++;

	// plus/minus sign
	if (*s == '+')
  8009f2:	80 f9 2b             	cmp    $0x2b,%cl
  8009f5:	75 0a                	jne    800a01 <strtol+0x2d>
		s++;
  8009f7:	83 c2 01             	add    $0x1,%edx
}

long
strtol(const char *s, char **endptr, int base)
{
	int neg = 0;
  8009fa:	bf 00 00 00 00       	mov    $0x0,%edi
  8009ff:	eb 11                	jmp    800a12 <strtol+0x3e>
  800a01:	bf 00 00 00 00       	mov    $0x0,%edi
		s++;

	// plus/minus sign
	if (*s == '+')
		s++;
	else if (*s == '-')
  800a06:	80 f9 2d             	cmp    $0x2d,%cl
  800a09:	75 07                	jne    800a12 <strtol+0x3e>
		s++, neg = 1;
  800a0b:	8d 52 01             	lea    0x1(%edx),%edx
  800a0e:	66 bf 01 00          	mov    $0x1,%di

	// hex or octal base prefix
	if ((base == 0 || base == 16) && (s[0] == '0' && s[1] == 'x'))
  800a12:	a9 ef ff ff ff       	test   $0xffffffef,%eax
  800a17:	75 15                	jne    800a2e <strtol+0x5a>
  800a19:	80 3a 30             	cmpb   $0x30,(%edx)
  800a1c:	75 10                	jne    800a2e <strtol+0x5a>
  800a1e:	80 7a 01 78          	cmpb   $0x78,0x1(%edx)
  800a22:	75 0a                	jne    800a2e <strtol+0x5a>
		s += 2, base = 16;
  800a24:	83 c2 02             	add    $0x2,%edx
  800a27:	b8 10 00 00 00       	mov    $0x10,%eax
  800a2c:	eb 10                	jmp    800a3e <strtol+0x6a>
	else if (base == 0 && s[0] == '0')
  800a2e:	85 c0                	test   %eax,%eax
  800a30:	75 0c                	jne    800a3e <strtol+0x6a>
		s++, base = 8;
	else if (base == 0)
		base = 10;
  800a32:	b0 0a                	mov    $0xa,%al
		s++, neg = 1;

	// hex or octal base prefix
	if ((base == 0 || base == 16) && (s[0] == '0' && s[1] == 'x'))
		s += 2, base = 16;
	else if (base == 0 && s[0] == '0')
  800a34:	80 3a 30             	cmpb   $0x30,(%edx)
  800a37:	75 05                	jne    800a3e <strtol+0x6a>
		s++, base = 8;
  800a39:	83 c2 01             	add    $0x1,%edx
  800a3c:	b0 08                	mov    $0x8,%al
	else if (base == 0)
		base = 10;
  800a3e:	bb 00 00 00 00       	mov    $0x0,%ebx
  800a43:	89 45 10             	mov    %eax,0x10(%ebp)

	// digits
	while (1) {
		int dig;

		if (*s >= '0' && *s <= '9')
  800a46:	0f b6 0a             	movzbl (%edx),%ecx
  800a49:	8d 71 d0             	lea    -0x30(%ecx),%esi
  800a4c:	89 f0                	mov    %esi,%eax
  800a4e:	3c 09                	cmp    $0x9,%al
  800a50:	77 08                	ja     800a5a <strtol+0x86>
			dig = *s - '0';
  800a52:	0f be c9             	movsbl %cl,%ecx
  800a55:	83 e9 30             	sub    $0x30,%ecx
  800a58:	eb 20                	jmp    800a7a <strtol+0xa6>
		else if (*s >= 'a' && *s <= 'z')
  800a5a:	8d 71 9f             	lea    -0x61(%ecx),%esi
  800a5d:	89 f0                	mov    %esi,%eax
  800a5f:	3c 19                	cmp    $0x19,%al
  800a61:	77 08                	ja     800a6b <strtol+0x97>
			dig = *s - 'a' + 10;
  800a63:	0f be c9             	movsbl %cl,%ecx
  800a66:	83 e9 57             	sub    $0x57,%ecx
  800a69:	eb 0f                	jmp    800a7a <strtol+0xa6>
		else if (*s >= 'A' && *s <= 'Z')
  800a6b:	8d 71 bf             	lea    -0x41(%ecx),%esi
  800a6e:	89 f0                	mov    %esi,%eax
  800a70:	3c 19                	cmp    $0x19,%al
  800a72:	77 16                	ja     800a8a <strtol+0xb6>
			dig = *s - 'A' + 10;
  800a74:	0f be c9             	movsbl %cl,%ecx
  800a77:	83 e9 37             	sub    $0x37,%ecx
		else
			break;
		if (dig >= base)
  800a7a:	3b 4d 10             	cmp    0x10(%ebp),%ecx
  800a7d:	7d 0f                	jge    800a8e <strtol+0xba>
			break;
		s++, val = (val * base) + dig;
  800a7f:	83 c2 01             	add    $0x1,%edx
  800a82:	0f af 5d 10          	imul   0x10(%ebp),%ebx
  800a86:	01 cb                	add    %ecx,%ebx
		// we don't properly detect overflow!
	}
  800a88:	eb bc                	jmp    800a46 <strtol+0x72>
  800a8a:	89 d8                	mov    %ebx,%eax
  800a8c:	eb 02                	jmp    800a90 <strtol+0xbc>
  800a8e:	89 d8                	mov    %ebx,%eax

	if (endptr)
  800a90:	83 7d 0c 00          	cmpl   $0x0,0xc(%ebp)
  800a94:	74 05                	je     800a9b <strtol+0xc7>
		*endptr = (char *) s;
  800a96:	8b 75 0c             	mov    0xc(%ebp),%esi
  800a99:	89 16                	mov    %edx,(%esi)
	return (neg ? -val : val);
  800a9b:	f7 d8                	neg    %eax
  800a9d:	85 ff                	test   %edi,%edi
  800a9f:	0f 44 c3             	cmove  %ebx,%eax
}
  800aa2:	5b                   	pop    %ebx
  800aa3:	5e                   	pop    %esi
  800aa4:	5f                   	pop    %edi
  800aa5:	5d                   	pop    %ebp
  800aa6:	c3                   	ret    

00800aa7 <syscall>:
#include <inc/syscall.h>
#include <inc/lib.h>

static inline int32_t
syscall(int num, int check, uint32_t a1, uint32_t a2, uint32_t a3, uint32_t a4, uint32_t a5)
{
  800aa7:	55                   	push   %ebp
  800aa8:	89 e5                	mov    %esp,%ebp
  800aaa:	57                   	push   %edi
  800aab:	56                   	push   %esi
  800aac:	53                   	push   %ebx
  800aad:	83 ec 2c             	sub    $0x2c,%esp
  800ab0:	89 45 e4             	mov    %eax,-0x1c(%ebp)
  800ab3:	89 55 e0             	mov    %edx,-0x20(%ebp)
  800ab6:	89 ca                	mov    %ecx,%edx
	//
	// The last clause tells the assembler that this can
	// potentially change the condition codes and arbitrary
	// memory locations.

	asm volatile("int %1\n"
  800ab8:	8b 4d 08             	mov    0x8(%ebp),%ecx
  800abb:	8b 5d 0c             	mov    0xc(%ebp),%ebx
  800abe:	8b 7d 10             	mov    0x10(%ebp),%edi
  800ac1:	8b 75 14             	mov    0x14(%ebp),%esi
  800ac4:	cd 30                	int    $0x30
		       "b" (a3),
		       "D" (a4),
		       "S" (a5)
		     : "cc", "memory");

	if(check && ret > 0)
  800ac6:	85 c0                	test   %eax,%eax
  800ac8:	7e 2d                	jle    800af7 <syscall+0x50>
  800aca:	83 7d e0 00          	cmpl   $0x0,-0x20(%ebp)
  800ace:	74 27                	je     800af7 <syscall+0x50>
		panic("syscall %d returned %d (> 0)", num, ret);
  800ad0:	89 44 24 10          	mov    %eax,0x10(%esp)
  800ad4:	8b 45 e4             	mov    -0x1c(%ebp),%eax
  800ad7:	89 44 24 0c          	mov    %eax,0xc(%esp)
  800adb:	c7 44 24 08 f8 10 80 	movl   $0x8010f8,0x8(%esp)
  800ae2:	00 
  800ae3:	c7 44 24 04 23 00 00 	movl   $0x23,0x4(%esp)
  800aea:	00 
  800aeb:	c7 04 24 15 11 80 00 	movl   $0x801115,(%esp)
  800af2:	e8 ef 00 00 00       	call   800be6 <_panic>

	return ret;
}
  800af7:	83 c4 2c             	add    $0x2c,%esp
  800afa:	5b                   	pop    %ebx
  800afb:	5e                   	pop    %esi
  800afc:	5f                   	pop    %edi
  800afd:	5d                   	pop    %ebp
  800afe:	c3                   	ret    

00800aff <sys_cputs>:

void
sys_cputs(const char *s, size_t len)
{
  800aff:	55                   	push   %ebp
  800b00:	89 e5                	mov    %esp,%ebp
  800b02:	83 ec 18             	sub    $0x18,%esp
	syscall(SYS_cputs, 0, (uint32_t)s, len, 0, 0, 0);
  800b05:	c7 44 24 0c 00 00 00 	movl   $0x0,0xc(%esp)
  800b0c:	00 
  800b0d:	c7 44 24 08 00 00 00 	movl   $0x0,0x8(%esp)
  800b14:	00 
  800b15:	c7 44 24 04 00 00 00 	movl   $0x0,0x4(%esp)
  800b1c:	00 
  800b1d:	8b 45 0c             	mov    0xc(%ebp),%eax
  800b20:	89 04 24             	mov    %eax,(%esp)
  800b23:	8b 4d 08             	mov    0x8(%ebp),%ecx
  800b26:	ba 00 00 00 00       	mov    $0x0,%edx
  800b2b:	b8 00 00 00 00       	mov    $0x0,%eax
  800b30:	e8 72 ff ff ff       	call   800aa7 <syscall>
}
  800b35:	c9                   	leave  
  800b36:	c3                   	ret    

00800b37 <sys_cgetc>:

int
sys_cgetc(void)
{
  800b37:	55                   	push   %ebp
  800b38:	89 e5                	mov    %esp,%ebp
  800b3a:	83 ec 18             	sub    $0x18,%esp
	return syscall(SYS_cgetc, 0, 0, 0, 0, 0, 0);
  800b3d:	c7 44 24 0c 00 00 00 	movl   $0x0,0xc(%esp)
  800b44:	00 
  800b45:	c7 44 24 08 00 00 00 	movl   $0x0,0x8(%esp)
  800b4c:	00 
  800b4d:	c7 44 24 04 00 00 00 	movl   $0x0,0x4(%esp)
  800b54:	00 
  800b55:	c7 04 24 00 00 00 00 	movl   $0x0,(%esp)
  800b5c:	b9 00 00 00 00       	mov    $0x0,%ecx
  800b61:	ba 00 00 00 00       	mov    $0x0,%edx
  800b66:	b8 01 00 00 00       	mov    $0x1,%eax
  800b6b:	e8 37 ff ff ff       	call   800aa7 <syscall>
}
  800b70:	c9                   	leave  
  800b71:	c3                   	ret    

00800b72 <sys_env_destroy>:

int
sys_env_destroy(envid_t envid)
{
  800b72:	55                   	push   %ebp
  800b73:	89 e5                	mov    %esp,%ebp
  800b75:	83 ec 18             	sub    $0x18,%esp
	return syscall(SYS_env_destroy, 1, envid, 0, 0, 0, 0);
  800b78:	c7 44 24 0c 00 00 00 	movl   $0x0,0xc(%esp)
  800b7f:	00 
  800b80:	c7 44 24 08 00 00 00 	movl   $0x0,0x8(%esp)
  800b87:	00 
  800b88:	c7 44 24 04 00 00 00 	movl   $0x0,0x4(%esp)
  800b8f:	00 
  800b90:	c7 04 24 00 00 00 00 	movl   $0x0,(%esp)
  800b97:	8b 4d 08             	mov    0x8(%ebp),%ecx
  800b9a:	ba 01 00 00 00       	mov    $0x1,%edx
  800b9f:	b8 03 00 00 00       	mov    $0x3,%eax
  800ba4:	e8 fe fe ff ff       	call   800aa7 <syscall>
}
  800ba9:	c9                   	leave  
  800baa:	c3                   	ret    

00800bab <sys_getenvid>:

envid_t
sys_getenvid(void)
{
  800bab:	55                   	push   %ebp
  800bac:	89 e5                	mov    %esp,%ebp
  800bae:	83 ec 18             	sub    $0x18,%esp
	 return syscall(SYS_getenvid, 0, 0, 0, 0, 0, 0);
  800bb1:	c7 44 24 0c 00 00 00 	movl   $0x0,0xc(%esp)
  800bb8:	00 
  800bb9:	c7 44 24 08 00 00 00 	movl   $0x0,0x8(%esp)
  800bc0:	00 
  800bc1:	c7 44 24 04 00 00 00 	movl   $0x0,0x4(%esp)
  800bc8:	00 
  800bc9:	c7 04 24 00 00 00 00 	movl   $0x0,(%esp)
  800bd0:	b9 00 00 00 00       	mov    $0x0,%ecx
  800bd5:	ba 00 00 00 00       	mov    $0x0,%edx
  800bda:	b8 02 00 00 00       	mov    $0x2,%eax
  800bdf:	e8 c3 fe ff ff       	call   800aa7 <syscall>
}
  800be4:	c9                   	leave  
  800be5:	c3                   	ret    

00800be6 <_panic>:
 * It prints "panic: <message>", then causes a breakpoint exception,
 * which causes JOS to enter the JOS kernel monitor.
 */
void
_panic(const char *file, int line, const char *fmt, ...)
{
  800be6:	55                   	push   %ebp
  800be7:	89 e5                	mov    %esp,%ebp
  800be9:	56                   	push   %esi
  800bea:	53                   	push   %ebx
  800beb:	83 ec 20             	sub    $0x20,%esp
	va_list ap;

	va_start(ap, fmt);
  800bee:	8d 5d 14             	lea    0x14(%ebp),%ebx

	// Print the panic message
	cprintf("[%08x] user panic in %s at %s:%d: ",
  800bf1:	8b 35 00 20 80 00    	mov    0x802000,%esi
  800bf7:	e8 af ff ff ff       	call   800bab <sys_getenvid>
  800bfc:	8b 55 0c             	mov    0xc(%ebp),%edx
  800bff:	89 54 24 10          	mov    %edx,0x10(%esp)
  800c03:	8b 55 08             	mov    0x8(%ebp),%edx
  800c06:	89 54 24 0c          	mov    %edx,0xc(%esp)
  800c0a:	89 74 24 08          	mov    %esi,0x8(%esp)
  800c0e:	89 44 24 04          	mov    %eax,0x4(%esp)
  800c12:	c7 04 24 24 11 80 00 	movl   $0x801124,(%esp)
  800c19:	e8 2d f5 ff ff       	call   80014b <cprintf>
		sys_getenvid(), binaryname, file, line);
	vcprintf(fmt, ap);
  800c1e:	89 5c 24 04          	mov    %ebx,0x4(%esp)
  800c22:	8b 45 10             	mov    0x10(%ebp),%eax
  800c25:	89 04 24             	mov    %eax,(%esp)
  800c28:	e8 bd f4 ff ff       	call   8000ea <vcprintf>
	cprintf("\n");
  800c2d:	c7 04 24 d4 0e 80 00 	movl   $0x800ed4,(%esp)
  800c34:	e8 12 f5 ff ff       	call   80014b <cprintf>

	// Cause a breakpoint exception
	while (1)
		asm volatile("int3");
  800c39:	cc                   	int3   
  800c3a:	eb fd                	jmp    800c39 <_panic+0x53>
  800c3c:	66 90                	xchg   %ax,%ax
  800c3e:	66 90                	xchg   %ax,%ax

00800c40 <__udivdi3>:
  800c40:	55                   	push   %ebp
  800c41:	57                   	push   %edi
  800c42:	56                   	push   %esi
  800c43:	83 ec 0c             	sub    $0xc,%esp
  800c46:	8b 44 24 28          	mov    0x28(%esp),%eax
  800c4a:	8b 7c 24 1c          	mov    0x1c(%esp),%edi
  800c4e:	8b 6c 24 20          	mov    0x20(%esp),%ebp
  800c52:	8b 4c 24 24          	mov    0x24(%esp),%ecx
  800c56:	85 c0                	test   %eax,%eax
  800c58:	89 7c 24 04          	mov    %edi,0x4(%esp)
  800c5c:	89 ea                	mov    %ebp,%edx
  800c5e:	89 0c 24             	mov    %ecx,(%esp)
  800c61:	75 2d                	jne    800c90 <__udivdi3+0x50>
  800c63:	39 e9                	cmp    %ebp,%ecx
  800c65:	77 61                	ja     800cc8 <__udivdi3+0x88>
  800c67:	85 c9                	test   %ecx,%ecx
  800c69:	89 ce                	mov    %ecx,%esi
  800c6b:	75 0b                	jne    800c78 <__udivdi3+0x38>
  800c6d:	b8 01 00 00 00       	mov    $0x1,%eax
  800c72:	31 d2                	xor    %edx,%edx
  800c74:	f7 f1                	div    %ecx
  800c76:	89 c6                	mov    %eax,%esi
  800c78:	31 d2                	xor    %edx,%edx
  800c7a:	89 e8                	mov    %ebp,%eax
  800c7c:	f7 f6                	div    %esi
  800c7e:	89 c5                	mov    %eax,%ebp
  800c80:	89 f8                	mov    %edi,%eax
  800c82:	f7 f6                	div    %esi
  800c84:	89 ea                	mov    %ebp,%edx
  800c86:	83 c4 0c             	add    $0xc,%esp
  800c89:	5e                   	pop    %esi
  800c8a:	5f                   	pop    %edi
  800c8b:	5d                   	pop    %ebp
  800c8c:	c3                   	ret    
  800c8d:	8d 76 00             	lea    0x0(%esi),%esi
  800c90:	39 e8                	cmp    %ebp,%eax
  800c92:	77 24                	ja     800cb8 <__udivdi3+0x78>
  800c94:	0f bd e8             	bsr    %eax,%ebp
  800c97:	83 f5 1f             	xor    $0x1f,%ebp
  800c9a:	75 3c                	jne    800cd8 <__udivdi3+0x98>
  800c9c:	8b 74 24 04          	mov    0x4(%esp),%esi
  800ca0:	39 34 24             	cmp    %esi,(%esp)
  800ca3:	0f 86 9f 00 00 00    	jbe    800d48 <__udivdi3+0x108>
  800ca9:	39 d0                	cmp    %edx,%eax
  800cab:	0f 82 97 00 00 00    	jb     800d48 <__udivdi3+0x108>
  800cb1:	8d b4 26 00 00 00 00 	lea    0x0(%esi,%eiz,1),%esi
  800cb8:	31 d2                	xor    %edx,%edx
  800cba:	31 c0                	xor    %eax,%eax
  800cbc:	83 c4 0c             	add    $0xc,%esp
  800cbf:	5e                   	pop    %esi
  800cc0:	5f                   	pop    %edi
  800cc1:	5d                   	pop    %ebp
  800cc2:	c3                   	ret    
  800cc3:	90                   	nop
  800cc4:	8d 74 26 00          	lea    0x0(%esi,%eiz,1),%esi
  800cc8:	89 f8                	mov    %edi,%eax
  800cca:	f7 f1                	div    %ecx
  800ccc:	31 d2                	xor    %edx,%edx
  800cce:	83 c4 0c             	add    $0xc,%esp
  800cd1:	5e                   	pop    %esi
  800cd2:	5f                   	pop    %edi
  800cd3:	5d                   	pop    %ebp
  800cd4:	c3                   	ret    
  800cd5:	8d 76 00             	lea    0x0(%esi),%esi
  800cd8:	89 e9                	mov    %ebp,%ecx
  800cda:	8b 3c 24             	mov    (%esp),%edi
  800cdd:	d3 e0                	shl    %cl,%eax
  800cdf:	89 c6                	mov    %eax,%esi
  800ce1:	b8 20 00 00 00       	mov    $0x20,%eax
  800ce6:	29 e8                	sub    %ebp,%eax
  800ce8:	89 c1                	mov    %eax,%ecx
  800cea:	d3 ef                	shr    %cl,%edi
  800cec:	89 e9                	mov    %ebp,%ecx
  800cee:	89 7c 24 08          	mov    %edi,0x8(%esp)
  800cf2:	8b 3c 24             	mov    (%esp),%edi
  800cf5:	09 74 24 08          	or     %esi,0x8(%esp)
  800cf9:	89 d6                	mov    %edx,%esi
  800cfb:	d3 e7                	shl    %cl,%edi
  800cfd:	89 c1                	mov    %eax,%ecx
  800cff:	89 3c 24             	mov    %edi,(%esp)
  800d02:	8b 7c 24 04          	mov    0x4(%esp),%edi
  800d06:	d3 ee                	shr    %cl,%esi
  800d08:	89 e9                	mov    %ebp,%ecx
  800d0a:	d3 e2                	shl    %cl,%edx
  800d0c:	89 c1                	mov    %eax,%ecx
  800d0e:	d3 ef                	shr    %cl,%edi
  800d10:	09 d7                	or     %edx,%edi
  800d12:	89 f2                	mov    %esi,%edx
  800d14:	89 f8                	mov    %edi,%eax
  800d16:	f7 74 24 08          	divl   0x8(%esp)
  800d1a:	89 d6                	mov    %edx,%esi
  800d1c:	89 c7                	mov    %eax,%edi
  800d1e:	f7 24 24             	mull   (%esp)
  800d21:	39 d6                	cmp    %edx,%esi
  800d23:	89 14 24             	mov    %edx,(%esp)
  800d26:	72 30                	jb     800d58 <__udivdi3+0x118>
  800d28:	8b 54 24 04          	mov    0x4(%esp),%edx
  800d2c:	89 e9                	mov    %ebp,%ecx
  800d2e:	d3 e2                	shl    %cl,%edx
  800d30:	39 c2                	cmp    %eax,%edx
  800d32:	73 05                	jae    800d39 <__udivdi3+0xf9>
  800d34:	3b 34 24             	cmp    (%esp),%esi
  800d37:	74 1f                	je     800d58 <__udivdi3+0x118>
  800d39:	89 f8                	mov    %edi,%eax
  800d3b:	31 d2                	xor    %edx,%edx
  800d3d:	e9 7a ff ff ff       	jmp    800cbc <__udivdi3+0x7c>
  800d42:	8d b6 00 00 00 00    	lea    0x0(%esi),%esi
  800d48:	31 d2                	xor    %edx,%edx
  800d4a:	b8 01 00 00 00       	mov    $0x1,%eax
  800d4f:	e9 68 ff ff ff       	jmp    800cbc <__udivdi3+0x7c>
  800d54:	8d 74 26 00          	lea    0x0(%esi,%eiz,1),%esi
  800d58:	8d 47 ff             	lea    -0x1(%edi),%eax
  800d5b:	31 d2                	xor    %edx,%edx
  800d5d:	83 c4 0c             	add    $0xc,%esp
  800d60:	5e                   	pop    %esi
  800d61:	5f                   	pop    %edi
  800d62:	5d                   	pop    %ebp
  800d63:	c3                   	ret    
  800d64:	66 90                	xchg   %ax,%ax
  800d66:	66 90                	xchg   %ax,%ax
  800d68:	66 90                	xchg   %ax,%ax
  800d6a:	66 90                	xchg   %ax,%ax
  800d6c:	66 90                	xchg   %ax,%ax
  800d6e:	66 90                	xchg   %ax,%ax

00800d70 <__umoddi3>:
  800d70:	55                   	push   %ebp
  800d71:	57                   	push   %edi
  800d72:	56                   	push   %esi
  800d73:	83 ec 14             	sub    $0x14,%esp
  800d76:	8b 44 24 28          	mov    0x28(%esp),%eax
  800d7a:	8b 4c 24 24          	mov    0x24(%esp),%ecx
  800d7e:	8b 74 24 2c          	mov    0x2c(%esp),%esi
  800d82:	89 c7                	mov    %eax,%edi
  800d84:	89 44 24 04          	mov    %eax,0x4(%esp)
  800d88:	8b 44 24 30          	mov    0x30(%esp),%eax
  800d8c:	89 4c 24 10          	mov    %ecx,0x10(%esp)
  800d90:	89 34 24             	mov    %esi,(%esp)
  800d93:	89 4c 24 08          	mov    %ecx,0x8(%esp)
  800d97:	85 c0                	test   %eax,%eax
  800d99:	89 c2                	mov    %eax,%edx
  800d9b:	89 7c 24 0c          	mov    %edi,0xc(%esp)
  800d9f:	75 17                	jne    800db8 <__umoddi3+0x48>
  800da1:	39 fe                	cmp    %edi,%esi
  800da3:	76 4b                	jbe    800df0 <__umoddi3+0x80>
  800da5:	89 c8                	mov    %ecx,%eax
  800da7:	89 fa                	mov    %edi,%edx
  800da9:	f7 f6                	div    %esi
  800dab:	89 d0                	mov    %edx,%eax
  800dad:	31 d2                	xor    %edx,%edx
  800daf:	83 c4 14             	add    $0x14,%esp
  800db2:	5e                   	pop    %esi
  800db3:	5f                   	pop    %edi
  800db4:	5d                   	pop    %ebp
  800db5:	c3                   	ret    
  800db6:	66 90                	xchg   %ax,%ax
  800db8:	39 f8                	cmp    %edi,%eax
  800dba:	77 54                	ja     800e10 <__umoddi3+0xa0>
  800dbc:	0f bd e8             	bsr    %eax,%ebp
  800dbf:	83 f5 1f             	xor    $0x1f,%ebp
  800dc2:	75 5c                	jne    800e20 <__umoddi3+0xb0>
  800dc4:	8b 7c 24 08          	mov    0x8(%esp),%edi
  800dc8:	39 3c 24             	cmp    %edi,(%esp)
  800dcb:	0f 87 e7 00 00 00    	ja     800eb8 <__umoddi3+0x148>
  800dd1:	8b 7c 24 04          	mov    0x4(%esp),%edi
  800dd5:	29 f1                	sub    %esi,%ecx
  800dd7:	19 c7                	sbb    %eax,%edi
  800dd9:	89 4c 24 08          	mov    %ecx,0x8(%esp)
  800ddd:	89 7c 24 0c          	mov    %edi,0xc(%esp)
  800de1:	8b 44 24 08          	mov    0x8(%esp),%eax
  800de5:	8b 54 24 0c          	mov    0xc(%esp),%edx
  800de9:	83 c4 14             	add    $0x14,%esp
  800dec:	5e                   	pop    %esi
  800ded:	5f                   	pop    %edi
  800dee:	5d                   	pop    %ebp
  800def:	c3                   	ret    
  800df0:	85 f6                	test   %esi,%esi
  800df2:	89 f5                	mov    %esi,%ebp
  800df4:	75 0b                	jne    800e01 <__umoddi3+0x91>
  800df6:	b8 01 00 00 00       	mov    $0x1,%eax
  800dfb:	31 d2                	xor    %edx,%edx
  800dfd:	f7 f6                	div    %esi
  800dff:	89 c5                	mov    %eax,%ebp
  800e01:	8b 44 24 04          	mov    0x4(%esp),%eax
  800e05:	31 d2                	xor    %edx,%edx
  800e07:	f7 f5                	div    %ebp
  800e09:	89 c8                	mov    %ecx,%eax
  800e0b:	f7 f5                	div    %ebp
  800e0d:	eb 9c                	jmp    800dab <__umoddi3+0x3b>
  800e0f:	90                   	nop
  800e10:	89 c8                	mov    %ecx,%eax
  800e12:	89 fa                	mov    %edi,%edx
  800e14:	83 c4 14             	add    $0x14,%esp
  800e17:	5e                   	pop    %esi
  800e18:	5f                   	pop    %edi
  800e19:	5d                   	pop    %ebp
  800e1a:	c3                   	ret    
  800e1b:	90                   	nop
  800e1c:	8d 74 26 00          	lea    0x0(%esi,%eiz,1),%esi
  800e20:	8b 04 24             	mov    (%esp),%eax
  800e23:	be 20 00 00 00       	mov    $0x20,%esi
  800e28:	89 e9                	mov    %ebp,%ecx
  800e2a:	29 ee                	sub    %ebp,%esi
  800e2c:	d3 e2                	shl    %cl,%edx
  800e2e:	89 f1                	mov    %esi,%ecx
  800e30:	d3 e8                	shr    %cl,%eax
  800e32:	89 e9                	mov    %ebp,%ecx
  800e34:	89 44 24 04          	mov    %eax,0x4(%esp)
  800e38:	8b 04 24             	mov    (%esp),%eax
  800e3b:	09 54 24 04          	or     %edx,0x4(%esp)
  800e3f:	89 fa                	mov    %edi,%edx
  800e41:	d3 e0                	shl    %cl,%eax
  800e43:	89 f1                	mov    %esi,%ecx
  800e45:	89 44 24 08          	mov    %eax,0x8(%esp)
  800e49:	8b 44 24 10          	mov    0x10(%esp),%eax
  800e4d:	d3 ea                	shr    %cl,%edx
  800e4f:	89 e9                	mov    %ebp,%ecx
  800e51:	d3 e7                	shl    %cl,%edi
  800e53:	89 f1                	mov    %esi,%ecx
  800e55:	d3 e8                	shr    %cl,%eax
  800e57:	89 e9                	mov    %ebp,%ecx
  800e59:	09 f8                	or     %edi,%eax
  800e5b:	8b 7c 24 10          	mov    0x10(%esp),%edi
  800e5f:	f7 74 24 04          	divl   0x4(%esp)
  800e63:	d3 e7                	shl    %cl,%edi
  800e65:	89 7c 24 0c          	mov    %edi,0xc(%esp)
  800e69:	89 d7                	mov    %edx,%edi
  800e6b:	f7 64 24 08          	mull   0x8(%esp)
  800e6f:	39 d7                	cmp    %edx,%edi
  800e71:	89 c1                	mov    %eax,%ecx
  800e73:	89 14 24             	mov    %edx,(%esp)
  800e76:	72 2c                	jb     800ea4 <__umoddi3+0x134>
  800e78:	39 44 24 0c          	cmp    %eax,0xc(%esp)
  800e7c:	72 22                	jb     800ea0 <__umoddi3+0x130>
  800e7e:	8b 44 24 0c          	mov    0xc(%esp),%eax
  800e82:	29 c8                	sub    %ecx,%eax
  800e84:	19 d7                	sbb    %edx,%edi
  800e86:	89 e9                	mov    %ebp,%ecx
  800e88:	89 fa                	mov    %edi,%edx
  800e8a:	d3 e8                	shr    %cl,%eax
  800e8c:	89 f1                	mov    %esi,%ecx
  800e8e:	d3 e2                	shl    %cl,%edx
  800e90:	89 e9                	mov    %ebp,%ecx
  800e92:	d3 ef                	shr    %cl,%edi
  800e94:	09 d0                	or     %edx,%eax
  800e96:	89 fa                	mov    %edi,%edx
  800e98:	83 c4 14             	add    $0x14,%esp
  800e9b:	5e                   	pop    %esi
  800e9c:	5f                   	pop    %edi
  800e9d:	5d                   	pop    %ebp
  800e9e:	c3                   	ret    
  800e9f:	90                   	nop
  800ea0:	39 d7                	cmp    %edx,%edi
  800ea2:	75 da                	jne    800e7e <__umoddi3+0x10e>
  800ea4:	8b 14 24             	mov    (%esp),%edx
  800ea7:	89 c1                	mov    %eax,%ecx
  800ea9:	2b 4c 24 08          	sub    0x8(%esp),%ecx
  800ead:	1b 54 24 04          	sbb    0x4(%esp),%edx
  800eb1:	eb cb                	jmp    800e7e <__umoddi3+0x10e>
  800eb3:	90                   	nop
  800eb4:	8d 74 26 00          	lea    0x0(%esi,%eiz,1),%esi
  800eb8:	3b 44 24 0c          	cmp    0xc(%esp),%eax
  800ebc:	0f 82 0f ff ff ff    	jb     800dd1 <__umoddi3+0x61>
  800ec2:	e9 1a ff ff ff       	jmp    800de1 <__umoddi3+0x71>
