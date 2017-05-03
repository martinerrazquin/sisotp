
obj/user/faultreadkernel:     file format elf32-i386


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
  80002c:	e8 1f 00 00 00       	call   800050 <libmain>
1:	jmp 1b
  800031:	eb fe                	jmp    800031 <args_exist+0x5>

00800033 <umain>:

#include <inc/lib.h>

void
umain(int argc, char **argv)
{
  800033:	55                   	push   %ebp
  800034:	89 e5                	mov    %esp,%ebp
  800036:	83 ec 18             	sub    $0x18,%esp
	cprintf("I read %08x from location 0xf0100000!\n", *(unsigned*)0xf0100000);
  800039:	a1 00 00 10 f0       	mov    0xf0100000,%eax
  80003e:	89 44 24 04          	mov    %eax,0x4(%esp)
  800042:	c7 04 24 b8 0e 80 00 	movl   $0x800eb8,(%esp)
  800049:	e8 ee 00 00 00       	call   80013c <cprintf>
}
  80004e:	c9                   	leave  
  80004f:	c3                   	ret    

00800050 <libmain>:
const volatile struct Env *thisenv;
const char *binaryname = "<unknown>";

void
libmain(int argc, char **argv)
{
  800050:	55                   	push   %ebp
  800051:	89 e5                	mov    %esp,%ebp
  800053:	83 ec 18             	sub    $0x18,%esp
  800056:	8b 45 08             	mov    0x8(%ebp),%eax
  800059:	8b 55 0c             	mov    0xc(%ebp),%edx
	// set thisenv to point at our Env structure in envs[].
	// LAB 3: Your code here.
	thisenv = 0;
  80005c:	c7 05 04 20 80 00 00 	movl   $0x0,0x802004
  800063:	00 00 00 

	// save the name of the program so that panic() can use it
	if (argc > 0)
  800066:	85 c0                	test   %eax,%eax
  800068:	7e 08                	jle    800072 <libmain+0x22>
		binaryname = argv[0];
  80006a:	8b 0a                	mov    (%edx),%ecx
  80006c:	89 0d 00 20 80 00    	mov    %ecx,0x802000

	// call user main routine
	umain(argc, argv);
  800072:	89 54 24 04          	mov    %edx,0x4(%esp)
  800076:	89 04 24             	mov    %eax,(%esp)
  800079:	e8 b5 ff ff ff       	call   800033 <umain>

	// exit gracefully
	exit();
  80007e:	e8 02 00 00 00       	call   800085 <exit>
}
  800083:	c9                   	leave  
  800084:	c3                   	ret    

00800085 <exit>:

#include <inc/lib.h>

void
exit(void)
{
  800085:	55                   	push   %ebp
  800086:	89 e5                	mov    %esp,%ebp
  800088:	83 ec 18             	sub    $0x18,%esp
	sys_env_destroy(0);
  80008b:	c7 04 24 00 00 00 00 	movl   $0x0,(%esp)
  800092:	e8 cb 0a 00 00       	call   800b62 <sys_env_destroy>
}
  800097:	c9                   	leave  
  800098:	c3                   	ret    

00800099 <putch>:
};


static void
putch(int ch, struct printbuf *b)
{
  800099:	55                   	push   %ebp
  80009a:	89 e5                	mov    %esp,%ebp
  80009c:	53                   	push   %ebx
  80009d:	83 ec 14             	sub    $0x14,%esp
  8000a0:	8b 5d 0c             	mov    0xc(%ebp),%ebx
	b->buf[b->idx++] = ch;
  8000a3:	8b 13                	mov    (%ebx),%edx
  8000a5:	8d 42 01             	lea    0x1(%edx),%eax
  8000a8:	89 03                	mov    %eax,(%ebx)
  8000aa:	8b 4d 08             	mov    0x8(%ebp),%ecx
  8000ad:	88 4c 13 08          	mov    %cl,0x8(%ebx,%edx,1)
	if (b->idx == 256-1) {
  8000b1:	3d ff 00 00 00       	cmp    $0xff,%eax
  8000b6:	75 19                	jne    8000d1 <putch+0x38>
		sys_cputs(b->buf, b->idx);
  8000b8:	c7 44 24 04 ff 00 00 	movl   $0xff,0x4(%esp)
  8000bf:	00 
  8000c0:	8d 43 08             	lea    0x8(%ebx),%eax
  8000c3:	89 04 24             	mov    %eax,(%esp)
  8000c6:	e8 24 0a 00 00       	call   800aef <sys_cputs>
		b->idx = 0;
  8000cb:	c7 03 00 00 00 00    	movl   $0x0,(%ebx)
	}
	b->cnt++;
  8000d1:	83 43 04 01          	addl   $0x1,0x4(%ebx)
}
  8000d5:	83 c4 14             	add    $0x14,%esp
  8000d8:	5b                   	pop    %ebx
  8000d9:	5d                   	pop    %ebp
  8000da:	c3                   	ret    

008000db <vcprintf>:

int
vcprintf(const char *fmt, va_list ap)
{
  8000db:	55                   	push   %ebp
  8000dc:	89 e5                	mov    %esp,%ebp
  8000de:	81 ec 28 01 00 00    	sub    $0x128,%esp
	struct printbuf b;

	b.idx = 0;
  8000e4:	c7 85 f0 fe ff ff 00 	movl   $0x0,-0x110(%ebp)
  8000eb:	00 00 00 
	b.cnt = 0;
  8000ee:	c7 85 f4 fe ff ff 00 	movl   $0x0,-0x10c(%ebp)
  8000f5:	00 00 00 
	vprintfmt((void*)putch, &b, fmt, ap);
  8000f8:	8b 45 0c             	mov    0xc(%ebp),%eax
  8000fb:	89 44 24 0c          	mov    %eax,0xc(%esp)
  8000ff:	8b 45 08             	mov    0x8(%ebp),%eax
  800102:	89 44 24 08          	mov    %eax,0x8(%esp)
  800106:	8d 85 f0 fe ff ff    	lea    -0x110(%ebp),%eax
  80010c:	89 44 24 04          	mov    %eax,0x4(%esp)
  800110:	c7 04 24 99 00 80 00 	movl   $0x800099,(%esp)
  800117:	e8 e4 01 00 00       	call   800300 <vprintfmt>
	sys_cputs(b.buf, b.idx);
  80011c:	8b 85 f0 fe ff ff    	mov    -0x110(%ebp),%eax
  800122:	89 44 24 04          	mov    %eax,0x4(%esp)
  800126:	8d 85 f8 fe ff ff    	lea    -0x108(%ebp),%eax
  80012c:	89 04 24             	mov    %eax,(%esp)
  80012f:	e8 bb 09 00 00       	call   800aef <sys_cputs>

	return b.cnt;
}
  800134:	8b 85 f4 fe ff ff    	mov    -0x10c(%ebp),%eax
  80013a:	c9                   	leave  
  80013b:	c3                   	ret    

0080013c <cprintf>:

int
cprintf(const char *fmt, ...)
{
  80013c:	55                   	push   %ebp
  80013d:	89 e5                	mov    %esp,%ebp
  80013f:	83 ec 18             	sub    $0x18,%esp
	va_list ap;
	int cnt;

	va_start(ap, fmt);
  800142:	8d 45 0c             	lea    0xc(%ebp),%eax
	cnt = vcprintf(fmt, ap);
  800145:	89 44 24 04          	mov    %eax,0x4(%esp)
  800149:	8b 45 08             	mov    0x8(%ebp),%eax
  80014c:	89 04 24             	mov    %eax,(%esp)
  80014f:	e8 87 ff ff ff       	call   8000db <vcprintf>
	va_end(ap);

	return cnt;
}
  800154:	c9                   	leave  
  800155:	c3                   	ret    
  800156:	66 90                	xchg   %ax,%ax
  800158:	66 90                	xchg   %ax,%ax
  80015a:	66 90                	xchg   %ax,%ax
  80015c:	66 90                	xchg   %ax,%ax
  80015e:	66 90                	xchg   %ax,%ax

00800160 <printnum>:
 * using specified putch function and associated pointer putdat.
 */
static void
printnum(void (*putch)(int, void*), void *putdat,
	 unsigned long long num, unsigned base, int width, int padc)
{
  800160:	55                   	push   %ebp
  800161:	89 e5                	mov    %esp,%ebp
  800163:	57                   	push   %edi
  800164:	56                   	push   %esi
  800165:	53                   	push   %ebx
  800166:	83 ec 3c             	sub    $0x3c,%esp
  800169:	89 45 e4             	mov    %eax,-0x1c(%ebp)
  80016c:	89 d7                	mov    %edx,%edi
  80016e:	8b 45 08             	mov    0x8(%ebp),%eax
  800171:	89 45 e0             	mov    %eax,-0x20(%ebp)
  800174:	8b 45 0c             	mov    0xc(%ebp),%eax
  800177:	89 c3                	mov    %eax,%ebx
  800179:	89 45 d4             	mov    %eax,-0x2c(%ebp)
  80017c:	8b 45 10             	mov    0x10(%ebp),%eax
  80017f:	8b 75 14             	mov    0x14(%ebp),%esi
	// first recursively print all preceding (more significant) digits
	if (num >= base) {
  800182:	b9 00 00 00 00       	mov    $0x0,%ecx
  800187:	89 45 d8             	mov    %eax,-0x28(%ebp)
  80018a:	89 4d dc             	mov    %ecx,-0x24(%ebp)
  80018d:	39 d9                	cmp    %ebx,%ecx
  80018f:	72 05                	jb     800196 <printnum+0x36>
  800191:	3b 45 e0             	cmp    -0x20(%ebp),%eax
  800194:	77 69                	ja     8001ff <printnum+0x9f>
		printnum(putch, putdat, num / base, base, width - 1, padc);
  800196:	8b 4d 18             	mov    0x18(%ebp),%ecx
  800199:	89 4c 24 10          	mov    %ecx,0x10(%esp)
  80019d:	83 ee 01             	sub    $0x1,%esi
  8001a0:	89 74 24 0c          	mov    %esi,0xc(%esp)
  8001a4:	89 44 24 08          	mov    %eax,0x8(%esp)
  8001a8:	8b 44 24 08          	mov    0x8(%esp),%eax
  8001ac:	8b 54 24 0c          	mov    0xc(%esp),%edx
  8001b0:	89 c3                	mov    %eax,%ebx
  8001b2:	89 d6                	mov    %edx,%esi
  8001b4:	8b 55 d8             	mov    -0x28(%ebp),%edx
  8001b7:	8b 4d dc             	mov    -0x24(%ebp),%ecx
  8001ba:	89 54 24 08          	mov    %edx,0x8(%esp)
  8001be:	89 4c 24 0c          	mov    %ecx,0xc(%esp)
  8001c2:	8b 45 e0             	mov    -0x20(%ebp),%eax
  8001c5:	89 04 24             	mov    %eax,(%esp)
  8001c8:	8b 45 d4             	mov    -0x2c(%ebp),%eax
  8001cb:	89 44 24 04          	mov    %eax,0x4(%esp)
  8001cf:	e8 5c 0a 00 00       	call   800c30 <__udivdi3>
  8001d4:	89 d9                	mov    %ebx,%ecx
  8001d6:	89 4c 24 08          	mov    %ecx,0x8(%esp)
  8001da:	89 74 24 0c          	mov    %esi,0xc(%esp)
  8001de:	89 04 24             	mov    %eax,(%esp)
  8001e1:	89 54 24 04          	mov    %edx,0x4(%esp)
  8001e5:	89 fa                	mov    %edi,%edx
  8001e7:	8b 45 e4             	mov    -0x1c(%ebp),%eax
  8001ea:	e8 71 ff ff ff       	call   800160 <printnum>
  8001ef:	eb 1b                	jmp    80020c <printnum+0xac>
	} else {
		// print any needed pad characters before first digit
		while (--width > 0)
			putch(padc, putdat);
  8001f1:	89 7c 24 04          	mov    %edi,0x4(%esp)
  8001f5:	8b 45 18             	mov    0x18(%ebp),%eax
  8001f8:	89 04 24             	mov    %eax,(%esp)
  8001fb:	ff d3                	call   *%ebx
  8001fd:	eb 03                	jmp    800202 <printnum+0xa2>
  8001ff:	8b 5d e4             	mov    -0x1c(%ebp),%ebx
	// first recursively print all preceding (more significant) digits
	if (num >= base) {
		printnum(putch, putdat, num / base, base, width - 1, padc);
	} else {
		// print any needed pad characters before first digit
		while (--width > 0)
  800202:	83 ee 01             	sub    $0x1,%esi
  800205:	85 f6                	test   %esi,%esi
  800207:	7f e8                	jg     8001f1 <printnum+0x91>
  800209:	89 5d e4             	mov    %ebx,-0x1c(%ebp)
			putch(padc, putdat);
	}

	// then print this (the least significant) digit
	putch("0123456789abcdef"[num % base], putdat);
  80020c:	89 7c 24 04          	mov    %edi,0x4(%esp)
  800210:	8b 7c 24 04          	mov    0x4(%esp),%edi
  800214:	8b 45 d8             	mov    -0x28(%ebp),%eax
  800217:	8b 55 dc             	mov    -0x24(%ebp),%edx
  80021a:	89 44 24 08          	mov    %eax,0x8(%esp)
  80021e:	89 54 24 0c          	mov    %edx,0xc(%esp)
  800222:	8b 45 e0             	mov    -0x20(%ebp),%eax
  800225:	89 04 24             	mov    %eax,(%esp)
  800228:	8b 45 d4             	mov    -0x2c(%ebp),%eax
  80022b:	89 44 24 04          	mov    %eax,0x4(%esp)
  80022f:	e8 2c 0b 00 00       	call   800d60 <__umoddi3>
  800234:	89 7c 24 04          	mov    %edi,0x4(%esp)
  800238:	0f be 80 e9 0e 80 00 	movsbl 0x800ee9(%eax),%eax
  80023f:	89 04 24             	mov    %eax,(%esp)
  800242:	8b 45 e4             	mov    -0x1c(%ebp),%eax
  800245:	ff d0                	call   *%eax
}
  800247:	83 c4 3c             	add    $0x3c,%esp
  80024a:	5b                   	pop    %ebx
  80024b:	5e                   	pop    %esi
  80024c:	5f                   	pop    %edi
  80024d:	5d                   	pop    %ebp
  80024e:	c3                   	ret    

0080024f <getuint>:

// Get an unsigned int of various possible sizes from a varargs list,
// depending on the lflag parameter.
static unsigned long long
getuint(va_list *ap, int lflag)
{
  80024f:	55                   	push   %ebp
  800250:	89 e5                	mov    %esp,%ebp
	if (lflag >= 2)
  800252:	83 fa 01             	cmp    $0x1,%edx
  800255:	7e 0e                	jle    800265 <getuint+0x16>
		return va_arg(*ap, unsigned long long);
  800257:	8b 10                	mov    (%eax),%edx
  800259:	8d 4a 08             	lea    0x8(%edx),%ecx
  80025c:	89 08                	mov    %ecx,(%eax)
  80025e:	8b 02                	mov    (%edx),%eax
  800260:	8b 52 04             	mov    0x4(%edx),%edx
  800263:	eb 22                	jmp    800287 <getuint+0x38>
	else if (lflag)
  800265:	85 d2                	test   %edx,%edx
  800267:	74 10                	je     800279 <getuint+0x2a>
		return va_arg(*ap, unsigned long);
  800269:	8b 10                	mov    (%eax),%edx
  80026b:	8d 4a 04             	lea    0x4(%edx),%ecx
  80026e:	89 08                	mov    %ecx,(%eax)
  800270:	8b 02                	mov    (%edx),%eax
  800272:	ba 00 00 00 00       	mov    $0x0,%edx
  800277:	eb 0e                	jmp    800287 <getuint+0x38>
	else
		return va_arg(*ap, unsigned int);
  800279:	8b 10                	mov    (%eax),%edx
  80027b:	8d 4a 04             	lea    0x4(%edx),%ecx
  80027e:	89 08                	mov    %ecx,(%eax)
  800280:	8b 02                	mov    (%edx),%eax
  800282:	ba 00 00 00 00       	mov    $0x0,%edx
}
  800287:	5d                   	pop    %ebp
  800288:	c3                   	ret    

00800289 <getint>:

// Same as getuint but signed - can't use getuint
// because of sign extension
static long long
getint(va_list *ap, int lflag)
{
  800289:	55                   	push   %ebp
  80028a:	89 e5                	mov    %esp,%ebp
	if (lflag >= 2)
  80028c:	83 fa 01             	cmp    $0x1,%edx
  80028f:	7e 0e                	jle    80029f <getint+0x16>
		return va_arg(*ap, long long);
  800291:	8b 10                	mov    (%eax),%edx
  800293:	8d 4a 08             	lea    0x8(%edx),%ecx
  800296:	89 08                	mov    %ecx,(%eax)
  800298:	8b 02                	mov    (%edx),%eax
  80029a:	8b 52 04             	mov    0x4(%edx),%edx
  80029d:	eb 1a                	jmp    8002b9 <getint+0x30>
	else if (lflag)
  80029f:	85 d2                	test   %edx,%edx
  8002a1:	74 0c                	je     8002af <getint+0x26>
		return va_arg(*ap, long);
  8002a3:	8b 10                	mov    (%eax),%edx
  8002a5:	8d 4a 04             	lea    0x4(%edx),%ecx
  8002a8:	89 08                	mov    %ecx,(%eax)
  8002aa:	8b 02                	mov    (%edx),%eax
  8002ac:	99                   	cltd   
  8002ad:	eb 0a                	jmp    8002b9 <getint+0x30>
	else
		return va_arg(*ap, int);
  8002af:	8b 10                	mov    (%eax),%edx
  8002b1:	8d 4a 04             	lea    0x4(%edx),%ecx
  8002b4:	89 08                	mov    %ecx,(%eax)
  8002b6:	8b 02                	mov    (%edx),%eax
  8002b8:	99                   	cltd   
}
  8002b9:	5d                   	pop    %ebp
  8002ba:	c3                   	ret    

008002bb <sprintputch>:
	int cnt;
};

static void
sprintputch(int ch, struct sprintbuf *b)
{
  8002bb:	55                   	push   %ebp
  8002bc:	89 e5                	mov    %esp,%ebp
  8002be:	8b 45 0c             	mov    0xc(%ebp),%eax
	b->cnt++;
  8002c1:	83 40 08 01          	addl   $0x1,0x8(%eax)
	if (b->buf < b->ebuf)
  8002c5:	8b 10                	mov    (%eax),%edx
  8002c7:	3b 50 04             	cmp    0x4(%eax),%edx
  8002ca:	73 0a                	jae    8002d6 <sprintputch+0x1b>
		*b->buf++ = ch;
  8002cc:	8d 4a 01             	lea    0x1(%edx),%ecx
  8002cf:	89 08                	mov    %ecx,(%eax)
  8002d1:	8b 45 08             	mov    0x8(%ebp),%eax
  8002d4:	88 02                	mov    %al,(%edx)
}
  8002d6:	5d                   	pop    %ebp
  8002d7:	c3                   	ret    

008002d8 <printfmt>:
	}
}

void
printfmt(void (*putch)(int, void*), void *putdat, const char *fmt, ...)
{
  8002d8:	55                   	push   %ebp
  8002d9:	89 e5                	mov    %esp,%ebp
  8002db:	83 ec 18             	sub    $0x18,%esp
	va_list ap;

	va_start(ap, fmt);
  8002de:	8d 45 14             	lea    0x14(%ebp),%eax
	vprintfmt(putch, putdat, fmt, ap);
  8002e1:	89 44 24 0c          	mov    %eax,0xc(%esp)
  8002e5:	8b 45 10             	mov    0x10(%ebp),%eax
  8002e8:	89 44 24 08          	mov    %eax,0x8(%esp)
  8002ec:	8b 45 0c             	mov    0xc(%ebp),%eax
  8002ef:	89 44 24 04          	mov    %eax,0x4(%esp)
  8002f3:	8b 45 08             	mov    0x8(%ebp),%eax
  8002f6:	89 04 24             	mov    %eax,(%esp)
  8002f9:	e8 02 00 00 00       	call   800300 <vprintfmt>
	va_end(ap);
}
  8002fe:	c9                   	leave  
  8002ff:	c3                   	ret    

00800300 <vprintfmt>:
// Main function to format and print a string.
void printfmt(void (*putch)(int, void*), void *putdat, const char *fmt, ...);

void
vprintfmt(void (*putch)(int, void*), void *putdat, const char *fmt, va_list ap)
{
  800300:	55                   	push   %ebp
  800301:	89 e5                	mov    %esp,%ebp
  800303:	57                   	push   %edi
  800304:	56                   	push   %esi
  800305:	53                   	push   %ebx
  800306:	83 ec 3c             	sub    $0x3c,%esp
  800309:	8b 75 0c             	mov    0xc(%ebp),%esi
  80030c:	8b 7d 10             	mov    0x10(%ebp),%edi
  80030f:	eb 14                	jmp    800325 <vprintfmt+0x25>
	int base, lflag, width, precision, altflag;
	char padc;

	while (1) {
		while ((ch = *(unsigned char *) fmt++) != '%') {
			if (ch == '\0')
  800311:	85 c0                	test   %eax,%eax
  800313:	0f 84 63 03 00 00    	je     80067c <vprintfmt+0x37c>
				return;
			putch(ch, putdat);
  800319:	89 74 24 04          	mov    %esi,0x4(%esp)
  80031d:	89 04 24             	mov    %eax,(%esp)
  800320:	ff 55 08             	call   *0x8(%ebp)
	unsigned long long num;
	int base, lflag, width, precision, altflag;
	char padc;

	while (1) {
		while ((ch = *(unsigned char *) fmt++) != '%') {
  800323:	89 df                	mov    %ebx,%edi
  800325:	8d 5f 01             	lea    0x1(%edi),%ebx
  800328:	0f b6 07             	movzbl (%edi),%eax
  80032b:	83 f8 25             	cmp    $0x25,%eax
  80032e:	75 e1                	jne    800311 <vprintfmt+0x11>
  800330:	c6 45 d8 20          	movb   $0x20,-0x28(%ebp)
  800334:	c7 45 e0 00 00 00 00 	movl   $0x0,-0x20(%ebp)
  80033b:	c7 45 d4 ff ff ff ff 	movl   $0xffffffff,-0x2c(%ebp)
  800342:	c7 45 dc ff ff ff ff 	movl   $0xffffffff,-0x24(%ebp)
  800349:	ba 00 00 00 00       	mov    $0x0,%edx
  80034e:	eb 1d                	jmp    80036d <vprintfmt+0x6d>
		width = -1;
		precision = -1;
		lflag = 0;
		altflag = 0;
	reswitch:
		switch (ch = *(unsigned char *) fmt++) {
  800350:	89 fb                	mov    %edi,%ebx

		// flag to pad on the right
		case '-':
			padc = '-';
  800352:	c6 45 d8 2d          	movb   $0x2d,-0x28(%ebp)
  800356:	eb 15                	jmp    80036d <vprintfmt+0x6d>
		width = -1;
		precision = -1;
		lflag = 0;
		altflag = 0;
	reswitch:
		switch (ch = *(unsigned char *) fmt++) {
  800358:	89 fb                	mov    %edi,%ebx
			padc = '-';
			goto reswitch;

		// flag to pad with 0's instead of spaces
		case '0':
			padc = '0';
  80035a:	c6 45 d8 30          	movb   $0x30,-0x28(%ebp)
  80035e:	eb 0d                	jmp    80036d <vprintfmt+0x6d>
			altflag = 1;
			goto reswitch;

		process_precision:
			if (width < 0)
				width = precision, precision = -1;
  800360:	8b 45 d4             	mov    -0x2c(%ebp),%eax
  800363:	89 45 dc             	mov    %eax,-0x24(%ebp)
  800366:	c7 45 d4 ff ff ff ff 	movl   $0xffffffff,-0x2c(%ebp)
		width = -1;
		precision = -1;
		lflag = 0;
		altflag = 0;
	reswitch:
		switch (ch = *(unsigned char *) fmt++) {
  80036d:	8d 7b 01             	lea    0x1(%ebx),%edi
  800370:	0f b6 0b             	movzbl (%ebx),%ecx
  800373:	0f b6 c1             	movzbl %cl,%eax
  800376:	83 e9 23             	sub    $0x23,%ecx
  800379:	80 f9 55             	cmp    $0x55,%cl
  80037c:	0f 87 da 02 00 00    	ja     80065c <vprintfmt+0x35c>
  800382:	0f b6 c9             	movzbl %cl,%ecx
  800385:	ff 24 8d 78 0f 80 00 	jmp    *0x800f78(,%ecx,4)
  80038c:	89 fb                	mov    %edi,%ebx
  80038e:	b9 00 00 00 00       	mov    $0x0,%ecx
		case '6':
		case '7':
		case '8':
		case '9':
			for (precision = 0; ; ++fmt) {
				precision = precision * 10 + ch - '0';
  800393:	8d 0c 89             	lea    (%ecx,%ecx,4),%ecx
  800396:	8d 4c 48 d0          	lea    -0x30(%eax,%ecx,2),%ecx
				ch = *fmt;
  80039a:	0f be 03             	movsbl (%ebx),%eax
				if (ch < '0' || ch > '9')
  80039d:	8d 78 d0             	lea    -0x30(%eax),%edi
  8003a0:	83 ff 09             	cmp    $0x9,%edi
  8003a3:	77 36                	ja     8003db <vprintfmt+0xdb>
		case '5':
		case '6':
		case '7':
		case '8':
		case '9':
			for (precision = 0; ; ++fmt) {
  8003a5:	83 c3 01             	add    $0x1,%ebx
				precision = precision * 10 + ch - '0';
				ch = *fmt;
				if (ch < '0' || ch > '9')
					break;
			}
  8003a8:	eb e9                	jmp    800393 <vprintfmt+0x93>
			goto process_precision;

		case '*':
			precision = va_arg(ap, int);
  8003aa:	8b 45 14             	mov    0x14(%ebp),%eax
  8003ad:	8d 48 04             	lea    0x4(%eax),%ecx
  8003b0:	89 4d 14             	mov    %ecx,0x14(%ebp)
  8003b3:	8b 00                	mov    (%eax),%eax
  8003b5:	89 45 d4             	mov    %eax,-0x2c(%ebp)
		width = -1;
		precision = -1;
		lflag = 0;
		altflag = 0;
	reswitch:
		switch (ch = *(unsigned char *) fmt++) {
  8003b8:	89 fb                	mov    %edi,%ebx
			}
			goto process_precision;

		case '*':
			precision = va_arg(ap, int);
			goto process_precision;
  8003ba:	eb 22                	jmp    8003de <vprintfmt+0xde>
  8003bc:	8b 4d dc             	mov    -0x24(%ebp),%ecx
  8003bf:	85 c9                	test   %ecx,%ecx
  8003c1:	b8 00 00 00 00       	mov    $0x0,%eax
  8003c6:	0f 49 c1             	cmovns %ecx,%eax
  8003c9:	89 45 dc             	mov    %eax,-0x24(%ebp)
		width = -1;
		precision = -1;
		lflag = 0;
		altflag = 0;
	reswitch:
		switch (ch = *(unsigned char *) fmt++) {
  8003cc:	89 fb                	mov    %edi,%ebx
  8003ce:	eb 9d                	jmp    80036d <vprintfmt+0x6d>
  8003d0:	89 fb                	mov    %edi,%ebx
			if (width < 0)
				width = 0;
			goto reswitch;

		case '#':
			altflag = 1;
  8003d2:	c7 45 e0 01 00 00 00 	movl   $0x1,-0x20(%ebp)
			goto reswitch;
  8003d9:	eb 92                	jmp    80036d <vprintfmt+0x6d>
  8003db:	89 4d d4             	mov    %ecx,-0x2c(%ebp)

		process_precision:
			if (width < 0)
  8003de:	83 7d dc 00          	cmpl   $0x0,-0x24(%ebp)
  8003e2:	79 89                	jns    80036d <vprintfmt+0x6d>
  8003e4:	e9 77 ff ff ff       	jmp    800360 <vprintfmt+0x60>
				width = precision, precision = -1;
			goto reswitch;

		// long flag (doubled for long long)
		case 'l':
			lflag++;
  8003e9:	83 c2 01             	add    $0x1,%edx
		width = -1;
		precision = -1;
		lflag = 0;
		altflag = 0;
	reswitch:
		switch (ch = *(unsigned char *) fmt++) {
  8003ec:	89 fb                	mov    %edi,%ebx
			goto reswitch;

		// long flag (doubled for long long)
		case 'l':
			lflag++;
			goto reswitch;
  8003ee:	e9 7a ff ff ff       	jmp    80036d <vprintfmt+0x6d>

		// character
		case 'c':
			putch(va_arg(ap, int), putdat);
  8003f3:	8b 45 14             	mov    0x14(%ebp),%eax
  8003f6:	8d 50 04             	lea    0x4(%eax),%edx
  8003f9:	89 55 14             	mov    %edx,0x14(%ebp)
  8003fc:	89 74 24 04          	mov    %esi,0x4(%esp)
  800400:	8b 00                	mov    (%eax),%eax
  800402:	89 04 24             	mov    %eax,(%esp)
  800405:	ff 55 08             	call   *0x8(%ebp)
			break;
  800408:	e9 18 ff ff ff       	jmp    800325 <vprintfmt+0x25>

		// error message
		case 'e':
			err = va_arg(ap, int);
  80040d:	8b 45 14             	mov    0x14(%ebp),%eax
  800410:	8d 50 04             	lea    0x4(%eax),%edx
  800413:	89 55 14             	mov    %edx,0x14(%ebp)
  800416:	8b 00                	mov    (%eax),%eax
  800418:	99                   	cltd   
  800419:	31 d0                	xor    %edx,%eax
  80041b:	29 d0                	sub    %edx,%eax
			if (err < 0)
				err = -err;
			if (err >= MAXERROR || (p = error_string[err]) == NULL)
  80041d:	83 f8 06             	cmp    $0x6,%eax
  800420:	7f 0b                	jg     80042d <vprintfmt+0x12d>
  800422:	8b 14 85 d0 10 80 00 	mov    0x8010d0(,%eax,4),%edx
  800429:	85 d2                	test   %edx,%edx
  80042b:	75 20                	jne    80044d <vprintfmt+0x14d>
				printfmt(putch, putdat, "error %d", err);
  80042d:	89 44 24 0c          	mov    %eax,0xc(%esp)
  800431:	c7 44 24 08 01 0f 80 	movl   $0x800f01,0x8(%esp)
  800438:	00 
  800439:	89 74 24 04          	mov    %esi,0x4(%esp)
  80043d:	8b 45 08             	mov    0x8(%ebp),%eax
  800440:	89 04 24             	mov    %eax,(%esp)
  800443:	e8 90 fe ff ff       	call   8002d8 <printfmt>
  800448:	e9 d8 fe ff ff       	jmp    800325 <vprintfmt+0x25>
			else
				printfmt(putch, putdat, "%s", p);
  80044d:	89 54 24 0c          	mov    %edx,0xc(%esp)
  800451:	c7 44 24 08 0a 0f 80 	movl   $0x800f0a,0x8(%esp)
  800458:	00 
  800459:	89 74 24 04          	mov    %esi,0x4(%esp)
  80045d:	8b 45 08             	mov    0x8(%ebp),%eax
  800460:	89 04 24             	mov    %eax,(%esp)
  800463:	e8 70 fe ff ff       	call   8002d8 <printfmt>
  800468:	e9 b8 fe ff ff       	jmp    800325 <vprintfmt+0x25>
		width = -1;
		precision = -1;
		lflag = 0;
		altflag = 0;
	reswitch:
		switch (ch = *(unsigned char *) fmt++) {
  80046d:	8b 4d d4             	mov    -0x2c(%ebp),%ecx
  800470:	8b 45 dc             	mov    -0x24(%ebp),%eax
  800473:	89 45 d0             	mov    %eax,-0x30(%ebp)
				printfmt(putch, putdat, "%s", p);
			break;

		// string
		case 's':
			if ((p = va_arg(ap, char *)) == NULL)
  800476:	8b 45 14             	mov    0x14(%ebp),%eax
  800479:	8d 50 04             	lea    0x4(%eax),%edx
  80047c:	89 55 14             	mov    %edx,0x14(%ebp)
  80047f:	8b 18                	mov    (%eax),%ebx
				p = "(null)";
  800481:	85 db                	test   %ebx,%ebx
  800483:	b8 fa 0e 80 00       	mov    $0x800efa,%eax
  800488:	0f 44 d8             	cmove  %eax,%ebx
			if (width > 0 && padc != '-')
  80048b:	80 7d d8 2d          	cmpb   $0x2d,-0x28(%ebp)
  80048f:	0f 84 97 00 00 00    	je     80052c <vprintfmt+0x22c>
  800495:	83 7d d0 00          	cmpl   $0x0,-0x30(%ebp)
  800499:	0f 8e 9b 00 00 00    	jle    80053a <vprintfmt+0x23a>
				for (width -= strnlen(p, precision); width > 0; width--)
  80049f:	89 4c 24 04          	mov    %ecx,0x4(%esp)
  8004a3:	89 1c 24             	mov    %ebx,(%esp)
  8004a6:	e8 7d 02 00 00       	call   800728 <strnlen>
  8004ab:	8b 55 d0             	mov    -0x30(%ebp),%edx
  8004ae:	29 c2                	sub    %eax,%edx
  8004b0:	89 55 d0             	mov    %edx,-0x30(%ebp)
					putch(padc, putdat);
  8004b3:	0f be 45 d8          	movsbl -0x28(%ebp),%eax
  8004b7:	89 45 dc             	mov    %eax,-0x24(%ebp)
  8004ba:	89 5d d8             	mov    %ebx,-0x28(%ebp)
  8004bd:	89 d3                	mov    %edx,%ebx
  8004bf:	89 7d 10             	mov    %edi,0x10(%ebp)
  8004c2:	8b 7d 08             	mov    0x8(%ebp),%edi
		// string
		case 's':
			if ((p = va_arg(ap, char *)) == NULL)
				p = "(null)";
			if (width > 0 && padc != '-')
				for (width -= strnlen(p, precision); width > 0; width--)
  8004c5:	eb 0f                	jmp    8004d6 <vprintfmt+0x1d6>
					putch(padc, putdat);
  8004c7:	89 74 24 04          	mov    %esi,0x4(%esp)
  8004cb:	8b 45 dc             	mov    -0x24(%ebp),%eax
  8004ce:	89 04 24             	mov    %eax,(%esp)
  8004d1:	ff d7                	call   *%edi
		// string
		case 's':
			if ((p = va_arg(ap, char *)) == NULL)
				p = "(null)";
			if (width > 0 && padc != '-')
				for (width -= strnlen(p, precision); width > 0; width--)
  8004d3:	83 eb 01             	sub    $0x1,%ebx
  8004d6:	85 db                	test   %ebx,%ebx
  8004d8:	7f ed                	jg     8004c7 <vprintfmt+0x1c7>
  8004da:	8b 5d d8             	mov    -0x28(%ebp),%ebx
  8004dd:	8b 55 d0             	mov    -0x30(%ebp),%edx
  8004e0:	85 d2                	test   %edx,%edx
  8004e2:	b8 00 00 00 00       	mov    $0x0,%eax
  8004e7:	0f 49 c2             	cmovns %edx,%eax
  8004ea:	29 c2                	sub    %eax,%edx
  8004ec:	89 75 0c             	mov    %esi,0xc(%ebp)
  8004ef:	89 d6                	mov    %edx,%esi
  8004f1:	8b 7d d4             	mov    -0x2c(%ebp),%edi
  8004f4:	eb 50                	jmp    800546 <vprintfmt+0x246>
					putch(padc, putdat);
			for (; (ch = *p++) != '\0' && (precision < 0 || --precision >= 0); width--)
				if (altflag && (ch < ' ' || ch > '~'))
  8004f6:	83 7d e0 00          	cmpl   $0x0,-0x20(%ebp)
  8004fa:	74 1e                	je     80051a <vprintfmt+0x21a>
  8004fc:	0f be d2             	movsbl %dl,%edx
  8004ff:	83 ea 20             	sub    $0x20,%edx
  800502:	83 fa 5e             	cmp    $0x5e,%edx
  800505:	76 13                	jbe    80051a <vprintfmt+0x21a>
					putch('?', putdat);
  800507:	8b 45 0c             	mov    0xc(%ebp),%eax
  80050a:	89 44 24 04          	mov    %eax,0x4(%esp)
  80050e:	c7 04 24 3f 00 00 00 	movl   $0x3f,(%esp)
  800515:	ff 55 08             	call   *0x8(%ebp)
  800518:	eb 0d                	jmp    800527 <vprintfmt+0x227>
				else
					putch(ch, putdat);
  80051a:	8b 55 0c             	mov    0xc(%ebp),%edx
  80051d:	89 54 24 04          	mov    %edx,0x4(%esp)
  800521:	89 04 24             	mov    %eax,(%esp)
  800524:	ff 55 08             	call   *0x8(%ebp)
			if ((p = va_arg(ap, char *)) == NULL)
				p = "(null)";
			if (width > 0 && padc != '-')
				for (width -= strnlen(p, precision); width > 0; width--)
					putch(padc, putdat);
			for (; (ch = *p++) != '\0' && (precision < 0 || --precision >= 0); width--)
  800527:	83 ee 01             	sub    $0x1,%esi
  80052a:	eb 1a                	jmp    800546 <vprintfmt+0x246>
  80052c:	89 75 0c             	mov    %esi,0xc(%ebp)
  80052f:	8b 75 dc             	mov    -0x24(%ebp),%esi
  800532:	89 7d 10             	mov    %edi,0x10(%ebp)
  800535:	8b 7d d4             	mov    -0x2c(%ebp),%edi
  800538:	eb 0c                	jmp    800546 <vprintfmt+0x246>
  80053a:	89 75 0c             	mov    %esi,0xc(%ebp)
  80053d:	8b 75 dc             	mov    -0x24(%ebp),%esi
  800540:	89 7d 10             	mov    %edi,0x10(%ebp)
  800543:	8b 7d d4             	mov    -0x2c(%ebp),%edi
  800546:	83 c3 01             	add    $0x1,%ebx
  800549:	0f b6 53 ff          	movzbl -0x1(%ebx),%edx
  80054d:	0f be c2             	movsbl %dl,%eax
  800550:	85 c0                	test   %eax,%eax
  800552:	74 25                	je     800579 <vprintfmt+0x279>
  800554:	85 ff                	test   %edi,%edi
  800556:	78 9e                	js     8004f6 <vprintfmt+0x1f6>
  800558:	83 ef 01             	sub    $0x1,%edi
  80055b:	79 99                	jns    8004f6 <vprintfmt+0x1f6>
  80055d:	89 f3                	mov    %esi,%ebx
  80055f:	8b 75 0c             	mov    0xc(%ebp),%esi
  800562:	8b 7d 08             	mov    0x8(%ebp),%edi
  800565:	eb 1a                	jmp    800581 <vprintfmt+0x281>
				if (altflag && (ch < ' ' || ch > '~'))
					putch('?', putdat);
				else
					putch(ch, putdat);
			for (; width > 0; width--)
				putch(' ', putdat);
  800567:	89 74 24 04          	mov    %esi,0x4(%esp)
  80056b:	c7 04 24 20 00 00 00 	movl   $0x20,(%esp)
  800572:	ff d7                	call   *%edi
			for (; (ch = *p++) != '\0' && (precision < 0 || --precision >= 0); width--)
				if (altflag && (ch < ' ' || ch > '~'))
					putch('?', putdat);
				else
					putch(ch, putdat);
			for (; width > 0; width--)
  800574:	83 eb 01             	sub    $0x1,%ebx
  800577:	eb 08                	jmp    800581 <vprintfmt+0x281>
  800579:	89 f3                	mov    %esi,%ebx
  80057b:	8b 7d 08             	mov    0x8(%ebp),%edi
  80057e:	8b 75 0c             	mov    0xc(%ebp),%esi
  800581:	85 db                	test   %ebx,%ebx
  800583:	7f e2                	jg     800567 <vprintfmt+0x267>
  800585:	89 7d 08             	mov    %edi,0x8(%ebp)
  800588:	8b 7d 10             	mov    0x10(%ebp),%edi
  80058b:	e9 95 fd ff ff       	jmp    800325 <vprintfmt+0x25>
				putch(' ', putdat);
			break;

		// (signed) decimal
		case 'd':
			num = getint(&ap, lflag);
  800590:	8d 45 14             	lea    0x14(%ebp),%eax
  800593:	e8 f1 fc ff ff       	call   800289 <getint>
  800598:	89 45 e0             	mov    %eax,-0x20(%ebp)
  80059b:	89 55 e4             	mov    %edx,-0x1c(%ebp)
			if ((long long) num < 0) {
				putch('-', putdat);
				num = -(long long) num;
			}
			base = 10;
  80059e:	bb 0a 00 00 00       	mov    $0xa,%ebx
			break;

		// (signed) decimal
		case 'd':
			num = getint(&ap, lflag);
			if ((long long) num < 0) {
  8005a3:	83 7d e4 00          	cmpl   $0x0,-0x1c(%ebp)
  8005a7:	79 7b                	jns    800624 <vprintfmt+0x324>
				putch('-', putdat);
  8005a9:	89 74 24 04          	mov    %esi,0x4(%esp)
  8005ad:	c7 04 24 2d 00 00 00 	movl   $0x2d,(%esp)
  8005b4:	ff 55 08             	call   *0x8(%ebp)
				num = -(long long) num;
  8005b7:	8b 45 e0             	mov    -0x20(%ebp),%eax
  8005ba:	8b 55 e4             	mov    -0x1c(%ebp),%edx
  8005bd:	f7 d8                	neg    %eax
  8005bf:	83 d2 00             	adc    $0x0,%edx
  8005c2:	f7 da                	neg    %edx
  8005c4:	eb 5e                	jmp    800624 <vprintfmt+0x324>
			base = 10;
			goto number;

		// unsigned decimal
		case 'u':
			num = getuint(&ap, lflag);
  8005c6:	8d 45 14             	lea    0x14(%ebp),%eax
  8005c9:	e8 81 fc ff ff       	call   80024f <getuint>
			base = 10;
  8005ce:	bb 0a 00 00 00       	mov    $0xa,%ebx
			goto number;
  8005d3:	eb 4f                	jmp    800624 <vprintfmt+0x324>

		// (unsigned) octal
		case 'o':
			num = getuint(&ap, lflag);
  8005d5:	8d 45 14             	lea    0x14(%ebp),%eax
  8005d8:	e8 72 fc ff ff       	call   80024f <getuint>
			base = 8;
  8005dd:	bb 08 00 00 00       	mov    $0x8,%ebx
			goto number;
  8005e2:	eb 40                	jmp    800624 <vprintfmt+0x324>

		// pointer
		case 'p':
			putch('0', putdat);
  8005e4:	89 74 24 04          	mov    %esi,0x4(%esp)
  8005e8:	c7 04 24 30 00 00 00 	movl   $0x30,(%esp)
  8005ef:	ff 55 08             	call   *0x8(%ebp)
			putch('x', putdat);
  8005f2:	89 74 24 04          	mov    %esi,0x4(%esp)
  8005f6:	c7 04 24 78 00 00 00 	movl   $0x78,(%esp)
  8005fd:	ff 55 08             	call   *0x8(%ebp)
			num = (unsigned long long)
				(uintptr_t) va_arg(ap, void *);
  800600:	8b 45 14             	mov    0x14(%ebp),%eax
  800603:	8d 50 04             	lea    0x4(%eax),%edx
  800606:	89 55 14             	mov    %edx,0x14(%ebp)

		// pointer
		case 'p':
			putch('0', putdat);
			putch('x', putdat);
			num = (unsigned long long)
  800609:	8b 00                	mov    (%eax),%eax
  80060b:	ba 00 00 00 00       	mov    $0x0,%edx
				(uintptr_t) va_arg(ap, void *);
			base = 16;
  800610:	bb 10 00 00 00       	mov    $0x10,%ebx
			goto number;
  800615:	eb 0d                	jmp    800624 <vprintfmt+0x324>

		// (unsigned) hexadecimal
		case 'x':
			num = getuint(&ap, lflag);
  800617:	8d 45 14             	lea    0x14(%ebp),%eax
  80061a:	e8 30 fc ff ff       	call   80024f <getuint>
			base = 16;
  80061f:	bb 10 00 00 00       	mov    $0x10,%ebx
		number:
			printnum(putch, putdat, num, base, width, padc);
  800624:	0f be 4d d8          	movsbl -0x28(%ebp),%ecx
  800628:	89 4c 24 10          	mov    %ecx,0x10(%esp)
  80062c:	8b 4d dc             	mov    -0x24(%ebp),%ecx
  80062f:	89 4c 24 0c          	mov    %ecx,0xc(%esp)
  800633:	89 5c 24 08          	mov    %ebx,0x8(%esp)
  800637:	89 04 24             	mov    %eax,(%esp)
  80063a:	89 54 24 04          	mov    %edx,0x4(%esp)
  80063e:	89 f2                	mov    %esi,%edx
  800640:	8b 45 08             	mov    0x8(%ebp),%eax
  800643:	e8 18 fb ff ff       	call   800160 <printnum>
			break;
  800648:	e9 d8 fc ff ff       	jmp    800325 <vprintfmt+0x25>

		// escaped '%' character
		case '%':
			putch(ch, putdat);
  80064d:	89 74 24 04          	mov    %esi,0x4(%esp)
  800651:	89 04 24             	mov    %eax,(%esp)
  800654:	ff 55 08             	call   *0x8(%ebp)
			break;
  800657:	e9 c9 fc ff ff       	jmp    800325 <vprintfmt+0x25>

		// unrecognized escape sequence - just print it literally
		default:
			putch('%', putdat);
  80065c:	89 74 24 04          	mov    %esi,0x4(%esp)
  800660:	c7 04 24 25 00 00 00 	movl   $0x25,(%esp)
  800667:	ff 55 08             	call   *0x8(%ebp)
			for (fmt--; fmt[-1] != '%'; fmt--)
  80066a:	89 df                	mov    %ebx,%edi
  80066c:	eb 03                	jmp    800671 <vprintfmt+0x371>
  80066e:	83 ef 01             	sub    $0x1,%edi
  800671:	80 7f ff 25          	cmpb   $0x25,-0x1(%edi)
  800675:	75 f7                	jne    80066e <vprintfmt+0x36e>
  800677:	e9 a9 fc ff ff       	jmp    800325 <vprintfmt+0x25>
				/* do nothing */;
			break;
		}
	}
}
  80067c:	83 c4 3c             	add    $0x3c,%esp
  80067f:	5b                   	pop    %ebx
  800680:	5e                   	pop    %esi
  800681:	5f                   	pop    %edi
  800682:	5d                   	pop    %ebp
  800683:	c3                   	ret    

00800684 <vsnprintf>:
		*b->buf++ = ch;
}

int
vsnprintf(char *buf, int n, const char *fmt, va_list ap)
{
  800684:	55                   	push   %ebp
  800685:	89 e5                	mov    %esp,%ebp
  800687:	83 ec 28             	sub    $0x28,%esp
  80068a:	8b 45 08             	mov    0x8(%ebp),%eax
  80068d:	8b 55 0c             	mov    0xc(%ebp),%edx
	struct sprintbuf b = {buf, buf+n-1, 0};
  800690:	89 45 ec             	mov    %eax,-0x14(%ebp)
  800693:	8d 4c 10 ff          	lea    -0x1(%eax,%edx,1),%ecx
  800697:	89 4d f0             	mov    %ecx,-0x10(%ebp)
  80069a:	c7 45 f4 00 00 00 00 	movl   $0x0,-0xc(%ebp)

	if (buf == NULL || n < 1)
  8006a1:	85 c0                	test   %eax,%eax
  8006a3:	74 30                	je     8006d5 <vsnprintf+0x51>
  8006a5:	85 d2                	test   %edx,%edx
  8006a7:	7e 2c                	jle    8006d5 <vsnprintf+0x51>
		return -E_INVAL;

	// print the string to the buffer
	vprintfmt((void*)sprintputch, &b, fmt, ap);
  8006a9:	8b 45 14             	mov    0x14(%ebp),%eax
  8006ac:	89 44 24 0c          	mov    %eax,0xc(%esp)
  8006b0:	8b 45 10             	mov    0x10(%ebp),%eax
  8006b3:	89 44 24 08          	mov    %eax,0x8(%esp)
  8006b7:	8d 45 ec             	lea    -0x14(%ebp),%eax
  8006ba:	89 44 24 04          	mov    %eax,0x4(%esp)
  8006be:	c7 04 24 bb 02 80 00 	movl   $0x8002bb,(%esp)
  8006c5:	e8 36 fc ff ff       	call   800300 <vprintfmt>

	// null terminate the buffer
	*b.buf = '\0';
  8006ca:	8b 45 ec             	mov    -0x14(%ebp),%eax
  8006cd:	c6 00 00             	movb   $0x0,(%eax)

	return b.cnt;
  8006d0:	8b 45 f4             	mov    -0xc(%ebp),%eax
  8006d3:	eb 05                	jmp    8006da <vsnprintf+0x56>
vsnprintf(char *buf, int n, const char *fmt, va_list ap)
{
	struct sprintbuf b = {buf, buf+n-1, 0};

	if (buf == NULL || n < 1)
		return -E_INVAL;
  8006d5:	b8 fd ff ff ff       	mov    $0xfffffffd,%eax

	// null terminate the buffer
	*b.buf = '\0';

	return b.cnt;
}
  8006da:	c9                   	leave  
  8006db:	c3                   	ret    

008006dc <snprintf>:

int
snprintf(char *buf, int n, const char *fmt, ...)
{
  8006dc:	55                   	push   %ebp
  8006dd:	89 e5                	mov    %esp,%ebp
  8006df:	83 ec 18             	sub    $0x18,%esp
	va_list ap;
	int rc;

	va_start(ap, fmt);
  8006e2:	8d 45 14             	lea    0x14(%ebp),%eax
	rc = vsnprintf(buf, n, fmt, ap);
  8006e5:	89 44 24 0c          	mov    %eax,0xc(%esp)
  8006e9:	8b 45 10             	mov    0x10(%ebp),%eax
  8006ec:	89 44 24 08          	mov    %eax,0x8(%esp)
  8006f0:	8b 45 0c             	mov    0xc(%ebp),%eax
  8006f3:	89 44 24 04          	mov    %eax,0x4(%esp)
  8006f7:	8b 45 08             	mov    0x8(%ebp),%eax
  8006fa:	89 04 24             	mov    %eax,(%esp)
  8006fd:	e8 82 ff ff ff       	call   800684 <vsnprintf>
	va_end(ap);

	return rc;
}
  800702:	c9                   	leave  
  800703:	c3                   	ret    
  800704:	66 90                	xchg   %ax,%ax
  800706:	66 90                	xchg   %ax,%ax
  800708:	66 90                	xchg   %ax,%ax
  80070a:	66 90                	xchg   %ax,%ax
  80070c:	66 90                	xchg   %ax,%ax
  80070e:	66 90                	xchg   %ax,%ax

00800710 <strlen>:
// Primespipe runs 3x faster this way.
#define ASM 1

int
strlen(const char *s)
{
  800710:	55                   	push   %ebp
  800711:	89 e5                	mov    %esp,%ebp
  800713:	8b 55 08             	mov    0x8(%ebp),%edx
	int n;

	for (n = 0; *s != '\0'; s++)
  800716:	b8 00 00 00 00       	mov    $0x0,%eax
  80071b:	eb 03                	jmp    800720 <strlen+0x10>
		n++;
  80071d:	83 c0 01             	add    $0x1,%eax
int
strlen(const char *s)
{
	int n;

	for (n = 0; *s != '\0'; s++)
  800720:	80 3c 02 00          	cmpb   $0x0,(%edx,%eax,1)
  800724:	75 f7                	jne    80071d <strlen+0xd>
		n++;
	return n;
}
  800726:	5d                   	pop    %ebp
  800727:	c3                   	ret    

00800728 <strnlen>:

int
strnlen(const char *s, size_t size)
{
  800728:	55                   	push   %ebp
  800729:	89 e5                	mov    %esp,%ebp
  80072b:	8b 4d 08             	mov    0x8(%ebp),%ecx
  80072e:	8b 55 0c             	mov    0xc(%ebp),%edx
	int n;

	for (n = 0; size > 0 && *s != '\0'; s++, size--)
  800731:	b8 00 00 00 00       	mov    $0x0,%eax
  800736:	eb 03                	jmp    80073b <strnlen+0x13>
		n++;
  800738:	83 c0 01             	add    $0x1,%eax
int
strnlen(const char *s, size_t size)
{
	int n;

	for (n = 0; size > 0 && *s != '\0'; s++, size--)
  80073b:	39 d0                	cmp    %edx,%eax
  80073d:	74 06                	je     800745 <strnlen+0x1d>
  80073f:	80 3c 01 00          	cmpb   $0x0,(%ecx,%eax,1)
  800743:	75 f3                	jne    800738 <strnlen+0x10>
		n++;
	return n;
}
  800745:	5d                   	pop    %ebp
  800746:	c3                   	ret    

00800747 <strcpy>:

char *
strcpy(char *dst, const char *src)
{
  800747:	55                   	push   %ebp
  800748:	89 e5                	mov    %esp,%ebp
  80074a:	53                   	push   %ebx
  80074b:	8b 45 08             	mov    0x8(%ebp),%eax
  80074e:	8b 4d 0c             	mov    0xc(%ebp),%ecx
	char *ret;

	ret = dst;
	while ((*dst++ = *src++) != '\0')
  800751:	89 c2                	mov    %eax,%edx
  800753:	83 c2 01             	add    $0x1,%edx
  800756:	83 c1 01             	add    $0x1,%ecx
  800759:	0f b6 59 ff          	movzbl -0x1(%ecx),%ebx
  80075d:	88 5a ff             	mov    %bl,-0x1(%edx)
  800760:	84 db                	test   %bl,%bl
  800762:	75 ef                	jne    800753 <strcpy+0xc>
		/* do nothing */;
	return ret;
}
  800764:	5b                   	pop    %ebx
  800765:	5d                   	pop    %ebp
  800766:	c3                   	ret    

00800767 <strcat>:

char *
strcat(char *dst, const char *src)
{
  800767:	55                   	push   %ebp
  800768:	89 e5                	mov    %esp,%ebp
  80076a:	53                   	push   %ebx
  80076b:	83 ec 08             	sub    $0x8,%esp
  80076e:	8b 5d 08             	mov    0x8(%ebp),%ebx
	int len = strlen(dst);
  800771:	89 1c 24             	mov    %ebx,(%esp)
  800774:	e8 97 ff ff ff       	call   800710 <strlen>
	strcpy(dst + len, src);
  800779:	8b 55 0c             	mov    0xc(%ebp),%edx
  80077c:	89 54 24 04          	mov    %edx,0x4(%esp)
  800780:	01 d8                	add    %ebx,%eax
  800782:	89 04 24             	mov    %eax,(%esp)
  800785:	e8 bd ff ff ff       	call   800747 <strcpy>
	return dst;
}
  80078a:	89 d8                	mov    %ebx,%eax
  80078c:	83 c4 08             	add    $0x8,%esp
  80078f:	5b                   	pop    %ebx
  800790:	5d                   	pop    %ebp
  800791:	c3                   	ret    

00800792 <strncpy>:

char *
strncpy(char *dst, const char *src, size_t size) {
  800792:	55                   	push   %ebp
  800793:	89 e5                	mov    %esp,%ebp
  800795:	56                   	push   %esi
  800796:	53                   	push   %ebx
  800797:	8b 75 08             	mov    0x8(%ebp),%esi
  80079a:	8b 4d 0c             	mov    0xc(%ebp),%ecx
  80079d:	89 f3                	mov    %esi,%ebx
  80079f:	03 5d 10             	add    0x10(%ebp),%ebx
	size_t i;
	char *ret;

	ret = dst;
	for (i = 0; i < size; i++) {
  8007a2:	89 f2                	mov    %esi,%edx
  8007a4:	eb 0f                	jmp    8007b5 <strncpy+0x23>
		*dst++ = *src;
  8007a6:	83 c2 01             	add    $0x1,%edx
  8007a9:	0f b6 01             	movzbl (%ecx),%eax
  8007ac:	88 42 ff             	mov    %al,-0x1(%edx)
		// If strlen(src) < size, null-pad 'dst' out to 'size' chars
		if (*src != '\0')
			src++;
  8007af:	80 39 01             	cmpb   $0x1,(%ecx)
  8007b2:	83 d9 ff             	sbb    $0xffffffff,%ecx
strncpy(char *dst, const char *src, size_t size) {
	size_t i;
	char *ret;

	ret = dst;
	for (i = 0; i < size; i++) {
  8007b5:	39 da                	cmp    %ebx,%edx
  8007b7:	75 ed                	jne    8007a6 <strncpy+0x14>
		// If strlen(src) < size, null-pad 'dst' out to 'size' chars
		if (*src != '\0')
			src++;
	}
	return ret;
}
  8007b9:	89 f0                	mov    %esi,%eax
  8007bb:	5b                   	pop    %ebx
  8007bc:	5e                   	pop    %esi
  8007bd:	5d                   	pop    %ebp
  8007be:	c3                   	ret    

008007bf <strlcpy>:

size_t
strlcpy(char *dst, const char *src, size_t size)
{
  8007bf:	55                   	push   %ebp
  8007c0:	89 e5                	mov    %esp,%ebp
  8007c2:	56                   	push   %esi
  8007c3:	53                   	push   %ebx
  8007c4:	8b 75 08             	mov    0x8(%ebp),%esi
  8007c7:	8b 55 0c             	mov    0xc(%ebp),%edx
  8007ca:	8b 4d 10             	mov    0x10(%ebp),%ecx
  8007cd:	89 f0                	mov    %esi,%eax
  8007cf:	8d 5c 0e ff          	lea    -0x1(%esi,%ecx,1),%ebx
	char *dst_in;

	dst_in = dst;
	if (size > 0) {
  8007d3:	85 c9                	test   %ecx,%ecx
  8007d5:	75 0b                	jne    8007e2 <strlcpy+0x23>
  8007d7:	eb 1d                	jmp    8007f6 <strlcpy+0x37>
		while (--size > 0 && *src != '\0')
			*dst++ = *src++;
  8007d9:	83 c0 01             	add    $0x1,%eax
  8007dc:	83 c2 01             	add    $0x1,%edx
  8007df:	88 48 ff             	mov    %cl,-0x1(%eax)
{
	char *dst_in;

	dst_in = dst;
	if (size > 0) {
		while (--size > 0 && *src != '\0')
  8007e2:	39 d8                	cmp    %ebx,%eax
  8007e4:	74 0b                	je     8007f1 <strlcpy+0x32>
  8007e6:	0f b6 0a             	movzbl (%edx),%ecx
  8007e9:	84 c9                	test   %cl,%cl
  8007eb:	75 ec                	jne    8007d9 <strlcpy+0x1a>
  8007ed:	89 c2                	mov    %eax,%edx
  8007ef:	eb 02                	jmp    8007f3 <strlcpy+0x34>
  8007f1:	89 c2                	mov    %eax,%edx
			*dst++ = *src++;
		*dst = '\0';
  8007f3:	c6 02 00             	movb   $0x0,(%edx)
	}
	return dst - dst_in;
  8007f6:	29 f0                	sub    %esi,%eax
}
  8007f8:	5b                   	pop    %ebx
  8007f9:	5e                   	pop    %esi
  8007fa:	5d                   	pop    %ebp
  8007fb:	c3                   	ret    

008007fc <strcmp>:

int
strcmp(const char *p, const char *q)
{
  8007fc:	55                   	push   %ebp
  8007fd:	89 e5                	mov    %esp,%ebp
  8007ff:	8b 4d 08             	mov    0x8(%ebp),%ecx
  800802:	8b 55 0c             	mov    0xc(%ebp),%edx
	while (*p && *p == *q)
  800805:	eb 06                	jmp    80080d <strcmp+0x11>
		p++, q++;
  800807:	83 c1 01             	add    $0x1,%ecx
  80080a:	83 c2 01             	add    $0x1,%edx
}

int
strcmp(const char *p, const char *q)
{
	while (*p && *p == *q)
  80080d:	0f b6 01             	movzbl (%ecx),%eax
  800810:	84 c0                	test   %al,%al
  800812:	74 04                	je     800818 <strcmp+0x1c>
  800814:	3a 02                	cmp    (%edx),%al
  800816:	74 ef                	je     800807 <strcmp+0xb>
		p++, q++;
	return (int) ((unsigned char) *p - (unsigned char) *q);
  800818:	0f b6 c0             	movzbl %al,%eax
  80081b:	0f b6 12             	movzbl (%edx),%edx
  80081e:	29 d0                	sub    %edx,%eax
}
  800820:	5d                   	pop    %ebp
  800821:	c3                   	ret    

00800822 <strncmp>:

int
strncmp(const char *p, const char *q, size_t n)
{
  800822:	55                   	push   %ebp
  800823:	89 e5                	mov    %esp,%ebp
  800825:	53                   	push   %ebx
  800826:	8b 45 08             	mov    0x8(%ebp),%eax
  800829:	8b 55 0c             	mov    0xc(%ebp),%edx
  80082c:	89 c3                	mov    %eax,%ebx
  80082e:	03 5d 10             	add    0x10(%ebp),%ebx
	while (n > 0 && *p && *p == *q)
  800831:	eb 06                	jmp    800839 <strncmp+0x17>
		n--, p++, q++;
  800833:	83 c0 01             	add    $0x1,%eax
  800836:	83 c2 01             	add    $0x1,%edx
}

int
strncmp(const char *p, const char *q, size_t n)
{
	while (n > 0 && *p && *p == *q)
  800839:	39 d8                	cmp    %ebx,%eax
  80083b:	74 15                	je     800852 <strncmp+0x30>
  80083d:	0f b6 08             	movzbl (%eax),%ecx
  800840:	84 c9                	test   %cl,%cl
  800842:	74 04                	je     800848 <strncmp+0x26>
  800844:	3a 0a                	cmp    (%edx),%cl
  800846:	74 eb                	je     800833 <strncmp+0x11>
		n--, p++, q++;
	if (n == 0)
		return 0;
	else
		return (int) ((unsigned char) *p - (unsigned char) *q);
  800848:	0f b6 00             	movzbl (%eax),%eax
  80084b:	0f b6 12             	movzbl (%edx),%edx
  80084e:	29 d0                	sub    %edx,%eax
  800850:	eb 05                	jmp    800857 <strncmp+0x35>
strncmp(const char *p, const char *q, size_t n)
{
	while (n > 0 && *p && *p == *q)
		n--, p++, q++;
	if (n == 0)
		return 0;
  800852:	b8 00 00 00 00       	mov    $0x0,%eax
	else
		return (int) ((unsigned char) *p - (unsigned char) *q);
}
  800857:	5b                   	pop    %ebx
  800858:	5d                   	pop    %ebp
  800859:	c3                   	ret    

0080085a <strchr>:

// Return a pointer to the first occurrence of 'c' in 's',
// or a null pointer if the string has no 'c'.
char *
strchr(const char *s, char c)
{
  80085a:	55                   	push   %ebp
  80085b:	89 e5                	mov    %esp,%ebp
  80085d:	8b 45 08             	mov    0x8(%ebp),%eax
  800860:	0f b6 4d 0c          	movzbl 0xc(%ebp),%ecx
	for (; *s; s++)
  800864:	eb 07                	jmp    80086d <strchr+0x13>
		if (*s == c)
  800866:	38 ca                	cmp    %cl,%dl
  800868:	74 0f                	je     800879 <strchr+0x1f>
// Return a pointer to the first occurrence of 'c' in 's',
// or a null pointer if the string has no 'c'.
char *
strchr(const char *s, char c)
{
	for (; *s; s++)
  80086a:	83 c0 01             	add    $0x1,%eax
  80086d:	0f b6 10             	movzbl (%eax),%edx
  800870:	84 d2                	test   %dl,%dl
  800872:	75 f2                	jne    800866 <strchr+0xc>
		if (*s == c)
			return (char *) s;
	return 0;
  800874:	b8 00 00 00 00       	mov    $0x0,%eax
}
  800879:	5d                   	pop    %ebp
  80087a:	c3                   	ret    

0080087b <strfind>:

// Return a pointer to the first occurrence of 'c' in 's',
// or a pointer to the string-ending null character if the string has no 'c'.
char *
strfind(const char *s, char c)
{
  80087b:	55                   	push   %ebp
  80087c:	89 e5                	mov    %esp,%ebp
  80087e:	8b 45 08             	mov    0x8(%ebp),%eax
  800881:	0f b6 4d 0c          	movzbl 0xc(%ebp),%ecx
	for (; *s; s++)
  800885:	eb 07                	jmp    80088e <strfind+0x13>
		if (*s == c)
  800887:	38 ca                	cmp    %cl,%dl
  800889:	74 0a                	je     800895 <strfind+0x1a>
// Return a pointer to the first occurrence of 'c' in 's',
// or a pointer to the string-ending null character if the string has no 'c'.
char *
strfind(const char *s, char c)
{
	for (; *s; s++)
  80088b:	83 c0 01             	add    $0x1,%eax
  80088e:	0f b6 10             	movzbl (%eax),%edx
  800891:	84 d2                	test   %dl,%dl
  800893:	75 f2                	jne    800887 <strfind+0xc>
		if (*s == c)
			break;
	return (char *) s;
}
  800895:	5d                   	pop    %ebp
  800896:	c3                   	ret    

00800897 <memset>:

#if ASM
void *
memset(void *v, int c, size_t n)
{
  800897:	55                   	push   %ebp
  800898:	89 e5                	mov    %esp,%ebp
  80089a:	57                   	push   %edi
  80089b:	56                   	push   %esi
  80089c:	53                   	push   %ebx
  80089d:	8b 55 08             	mov    0x8(%ebp),%edx
  8008a0:	8b 4d 10             	mov    0x10(%ebp),%ecx
	char *p = v;

	if (n == 0)
  8008a3:	85 c9                	test   %ecx,%ecx
  8008a5:	74 37                	je     8008de <memset+0x47>
		return v;
	if ((int)v%4 == 0 && n%4 == 0) {
  8008a7:	f6 c2 03             	test   $0x3,%dl
  8008aa:	75 2a                	jne    8008d6 <memset+0x3f>
  8008ac:	f6 c1 03             	test   $0x3,%cl
  8008af:	75 25                	jne    8008d6 <memset+0x3f>
		c &= 0xFF;
  8008b1:	0f b6 7d 0c          	movzbl 0xc(%ebp),%edi
		c = (c<<24)|(c<<16)|(c<<8)|c;
  8008b5:	89 fb                	mov    %edi,%ebx
  8008b7:	c1 e3 08             	shl    $0x8,%ebx
  8008ba:	89 fe                	mov    %edi,%esi
  8008bc:	c1 e6 18             	shl    $0x18,%esi
  8008bf:	89 f8                	mov    %edi,%eax
  8008c1:	c1 e0 10             	shl    $0x10,%eax
  8008c4:	09 f0                	or     %esi,%eax
  8008c6:	09 c7                	or     %eax,%edi
		asm volatile("cld; rep stosl\n"
			: "=D" (p), "=c" (n)
			: "D" (p), "a" (c), "c" (n/4)
  8008c8:	c1 e9 02             	shr    $0x2,%ecx

	if (n == 0)
		return v;
	if ((int)v%4 == 0 && n%4 == 0) {
		c &= 0xFF;
		c = (c<<24)|(c<<16)|(c<<8)|c;
  8008cb:	89 f8                	mov    %edi,%eax
  8008cd:	09 d8                	or     %ebx,%eax
		asm volatile("cld; rep stosl\n"
  8008cf:	89 d7                	mov    %edx,%edi
  8008d1:	fc                   	cld    
  8008d2:	f3 ab                	rep stos %eax,%es:(%edi)
  8008d4:	eb 08                	jmp    8008de <memset+0x47>
			: "=D" (p), "=c" (n)
			: "D" (p), "a" (c), "c" (n/4)
			: "cc", "memory");
	} else
		asm volatile("cld; rep stosb\n"
  8008d6:	89 d7                	mov    %edx,%edi
  8008d8:	8b 45 0c             	mov    0xc(%ebp),%eax
  8008db:	fc                   	cld    
  8008dc:	f3 aa                	rep stos %al,%es:(%edi)
			: "=D" (p), "=c" (n)
			: "0" (p), "a" (c), "1" (n)
			: "cc", "memory");
	return v;
}
  8008de:	89 d0                	mov    %edx,%eax
  8008e0:	5b                   	pop    %ebx
  8008e1:	5e                   	pop    %esi
  8008e2:	5f                   	pop    %edi
  8008e3:	5d                   	pop    %ebp
  8008e4:	c3                   	ret    

008008e5 <memmove>:

void *
memmove(void *dst, const void *src, size_t n)
{
  8008e5:	55                   	push   %ebp
  8008e6:	89 e5                	mov    %esp,%ebp
  8008e8:	57                   	push   %edi
  8008e9:	56                   	push   %esi
  8008ea:	8b 45 08             	mov    0x8(%ebp),%eax
  8008ed:	8b 75 0c             	mov    0xc(%ebp),%esi
  8008f0:	8b 4d 10             	mov    0x10(%ebp),%ecx
	const char *s;
	char *d;

	s = src;
	d = dst;
	if (s < d && s + n > d) {
  8008f3:	39 c6                	cmp    %eax,%esi
  8008f5:	73 35                	jae    80092c <memmove+0x47>
  8008f7:	8d 14 0e             	lea    (%esi,%ecx,1),%edx
  8008fa:	39 d0                	cmp    %edx,%eax
  8008fc:	73 2e                	jae    80092c <memmove+0x47>
		s += n;
		d += n;
  8008fe:	8d 3c 08             	lea    (%eax,%ecx,1),%edi
  800901:	89 d6                	mov    %edx,%esi
  800903:	09 fe                	or     %edi,%esi
		if ((int)s%4 == 0 && (int)d%4 == 0 && n%4 == 0)
  800905:	f7 c6 03 00 00 00    	test   $0x3,%esi
  80090b:	75 13                	jne    800920 <memmove+0x3b>
  80090d:	f6 c1 03             	test   $0x3,%cl
  800910:	75 0e                	jne    800920 <memmove+0x3b>
			asm volatile("std; rep movsl\n"
				:: "D" (d-4), "S" (s-4), "c" (n/4) : "cc", "memory");
  800912:	83 ef 04             	sub    $0x4,%edi
  800915:	8d 72 fc             	lea    -0x4(%edx),%esi
  800918:	c1 e9 02             	shr    $0x2,%ecx
	d = dst;
	if (s < d && s + n > d) {
		s += n;
		d += n;
		if ((int)s%4 == 0 && (int)d%4 == 0 && n%4 == 0)
			asm volatile("std; rep movsl\n"
  80091b:	fd                   	std    
  80091c:	f3 a5                	rep movsl %ds:(%esi),%es:(%edi)
  80091e:	eb 09                	jmp    800929 <memmove+0x44>
				:: "D" (d-4), "S" (s-4), "c" (n/4) : "cc", "memory");
		else
			asm volatile("std; rep movsb\n"
				:: "D" (d-1), "S" (s-1), "c" (n) : "cc", "memory");
  800920:	83 ef 01             	sub    $0x1,%edi
  800923:	8d 72 ff             	lea    -0x1(%edx),%esi
		d += n;
		if ((int)s%4 == 0 && (int)d%4 == 0 && n%4 == 0)
			asm volatile("std; rep movsl\n"
				:: "D" (d-4), "S" (s-4), "c" (n/4) : "cc", "memory");
		else
			asm volatile("std; rep movsb\n"
  800926:	fd                   	std    
  800927:	f3 a4                	rep movsb %ds:(%esi),%es:(%edi)
				:: "D" (d-1), "S" (s-1), "c" (n) : "cc", "memory");
		// Some versions of GCC rely on DF being clear
		asm volatile("cld" ::: "cc");
  800929:	fc                   	cld    
  80092a:	eb 1d                	jmp    800949 <memmove+0x64>
  80092c:	89 f2                	mov    %esi,%edx
  80092e:	09 c2                	or     %eax,%edx
	} else {
		if ((int)s%4 == 0 && (int)d%4 == 0 && n%4 == 0)
  800930:	f6 c2 03             	test   $0x3,%dl
  800933:	75 0f                	jne    800944 <memmove+0x5f>
  800935:	f6 c1 03             	test   $0x3,%cl
  800938:	75 0a                	jne    800944 <memmove+0x5f>
			asm volatile("cld; rep movsl\n"
				:: "D" (d), "S" (s), "c" (n/4) : "cc", "memory");
  80093a:	c1 e9 02             	shr    $0x2,%ecx
				:: "D" (d-1), "S" (s-1), "c" (n) : "cc", "memory");
		// Some versions of GCC rely on DF being clear
		asm volatile("cld" ::: "cc");
	} else {
		if ((int)s%4 == 0 && (int)d%4 == 0 && n%4 == 0)
			asm volatile("cld; rep movsl\n"
  80093d:	89 c7                	mov    %eax,%edi
  80093f:	fc                   	cld    
  800940:	f3 a5                	rep movsl %ds:(%esi),%es:(%edi)
  800942:	eb 05                	jmp    800949 <memmove+0x64>
				:: "D" (d), "S" (s), "c" (n/4) : "cc", "memory");
		else
			asm volatile("cld; rep movsb\n"
  800944:	89 c7                	mov    %eax,%edi
  800946:	fc                   	cld    
  800947:	f3 a4                	rep movsb %ds:(%esi),%es:(%edi)
				:: "D" (d), "S" (s), "c" (n) : "cc", "memory");
	}
	return dst;
}
  800949:	5e                   	pop    %esi
  80094a:	5f                   	pop    %edi
  80094b:	5d                   	pop    %ebp
  80094c:	c3                   	ret    

0080094d <memcpy>:
}
#endif

void *
memcpy(void *dst, const void *src, size_t n)
{
  80094d:	55                   	push   %ebp
  80094e:	89 e5                	mov    %esp,%ebp
  800950:	83 ec 0c             	sub    $0xc,%esp
	return memmove(dst, src, n);
  800953:	8b 45 10             	mov    0x10(%ebp),%eax
  800956:	89 44 24 08          	mov    %eax,0x8(%esp)
  80095a:	8b 45 0c             	mov    0xc(%ebp),%eax
  80095d:	89 44 24 04          	mov    %eax,0x4(%esp)
  800961:	8b 45 08             	mov    0x8(%ebp),%eax
  800964:	89 04 24             	mov    %eax,(%esp)
  800967:	e8 79 ff ff ff       	call   8008e5 <memmove>
}
  80096c:	c9                   	leave  
  80096d:	c3                   	ret    

0080096e <memcmp>:

int
memcmp(const void *v1, const void *v2, size_t n)
{
  80096e:	55                   	push   %ebp
  80096f:	89 e5                	mov    %esp,%ebp
  800971:	56                   	push   %esi
  800972:	53                   	push   %ebx
  800973:	8b 55 08             	mov    0x8(%ebp),%edx
  800976:	8b 4d 0c             	mov    0xc(%ebp),%ecx
  800979:	89 d6                	mov    %edx,%esi
  80097b:	03 75 10             	add    0x10(%ebp),%esi
	const uint8_t *s1 = (const uint8_t *) v1;
	const uint8_t *s2 = (const uint8_t *) v2;

	while (n-- > 0) {
  80097e:	eb 1a                	jmp    80099a <memcmp+0x2c>
		if (*s1 != *s2)
  800980:	0f b6 02             	movzbl (%edx),%eax
  800983:	0f b6 19             	movzbl (%ecx),%ebx
  800986:	38 d8                	cmp    %bl,%al
  800988:	74 0a                	je     800994 <memcmp+0x26>
			return (int) *s1 - (int) *s2;
  80098a:	0f b6 c0             	movzbl %al,%eax
  80098d:	0f b6 db             	movzbl %bl,%ebx
  800990:	29 d8                	sub    %ebx,%eax
  800992:	eb 0f                	jmp    8009a3 <memcmp+0x35>
		s1++, s2++;
  800994:	83 c2 01             	add    $0x1,%edx
  800997:	83 c1 01             	add    $0x1,%ecx
memcmp(const void *v1, const void *v2, size_t n)
{
	const uint8_t *s1 = (const uint8_t *) v1;
	const uint8_t *s2 = (const uint8_t *) v2;

	while (n-- > 0) {
  80099a:	39 f2                	cmp    %esi,%edx
  80099c:	75 e2                	jne    800980 <memcmp+0x12>
		if (*s1 != *s2)
			return (int) *s1 - (int) *s2;
		s1++, s2++;
	}

	return 0;
  80099e:	b8 00 00 00 00       	mov    $0x0,%eax
}
  8009a3:	5b                   	pop    %ebx
  8009a4:	5e                   	pop    %esi
  8009a5:	5d                   	pop    %ebp
  8009a6:	c3                   	ret    

008009a7 <memfind>:

void *
memfind(const void *s, int c, size_t n)
{
  8009a7:	55                   	push   %ebp
  8009a8:	89 e5                	mov    %esp,%ebp
  8009aa:	8b 45 08             	mov    0x8(%ebp),%eax
  8009ad:	8b 4d 0c             	mov    0xc(%ebp),%ecx
	const void *ends = (const char *) s + n;
  8009b0:	89 c2                	mov    %eax,%edx
  8009b2:	03 55 10             	add    0x10(%ebp),%edx
	for (; s < ends; s++)
  8009b5:	eb 07                	jmp    8009be <memfind+0x17>
		if (*(const unsigned char *) s == (unsigned char) c)
  8009b7:	38 08                	cmp    %cl,(%eax)
  8009b9:	74 07                	je     8009c2 <memfind+0x1b>

void *
memfind(const void *s, int c, size_t n)
{
	const void *ends = (const char *) s + n;
	for (; s < ends; s++)
  8009bb:	83 c0 01             	add    $0x1,%eax
  8009be:	39 d0                	cmp    %edx,%eax
  8009c0:	72 f5                	jb     8009b7 <memfind+0x10>
		if (*(const unsigned char *) s == (unsigned char) c)
			break;
	return (void *) s;
}
  8009c2:	5d                   	pop    %ebp
  8009c3:	c3                   	ret    

008009c4 <strtol>:

long
strtol(const char *s, char **endptr, int base)
{
  8009c4:	55                   	push   %ebp
  8009c5:	89 e5                	mov    %esp,%ebp
  8009c7:	57                   	push   %edi
  8009c8:	56                   	push   %esi
  8009c9:	53                   	push   %ebx
  8009ca:	8b 55 08             	mov    0x8(%ebp),%edx
  8009cd:	8b 45 10             	mov    0x10(%ebp),%eax
	int neg = 0;
	long val = 0;

	// gobble initial whitespace
	while (*s == ' ' || *s == '\t')
  8009d0:	eb 03                	jmp    8009d5 <strtol+0x11>
		s++;
  8009d2:	83 c2 01             	add    $0x1,%edx
{
	int neg = 0;
	long val = 0;

	// gobble initial whitespace
	while (*s == ' ' || *s == '\t')
  8009d5:	0f b6 0a             	movzbl (%edx),%ecx
  8009d8:	80 f9 09             	cmp    $0x9,%cl
  8009db:	74 f5                	je     8009d2 <strtol+0xe>
  8009dd:	80 f9 20             	cmp    $0x20,%cl
  8009e0:	74 f0                	je     8009d2 <strtol+0xe>
		s++;

	// plus/minus sign
	if (*s == '+')
  8009e2:	80 f9 2b             	cmp    $0x2b,%cl
  8009e5:	75 0a                	jne    8009f1 <strtol+0x2d>
		s++;
  8009e7:	83 c2 01             	add    $0x1,%edx
}

long
strtol(const char *s, char **endptr, int base)
{
	int neg = 0;
  8009ea:	bf 00 00 00 00       	mov    $0x0,%edi
  8009ef:	eb 11                	jmp    800a02 <strtol+0x3e>
  8009f1:	bf 00 00 00 00       	mov    $0x0,%edi
		s++;

	// plus/minus sign
	if (*s == '+')
		s++;
	else if (*s == '-')
  8009f6:	80 f9 2d             	cmp    $0x2d,%cl
  8009f9:	75 07                	jne    800a02 <strtol+0x3e>
		s++, neg = 1;
  8009fb:	8d 52 01             	lea    0x1(%edx),%edx
  8009fe:	66 bf 01 00          	mov    $0x1,%di

	// hex or octal base prefix
	if ((base == 0 || base == 16) && (s[0] == '0' && s[1] == 'x'))
  800a02:	a9 ef ff ff ff       	test   $0xffffffef,%eax
  800a07:	75 15                	jne    800a1e <strtol+0x5a>
  800a09:	80 3a 30             	cmpb   $0x30,(%edx)
  800a0c:	75 10                	jne    800a1e <strtol+0x5a>
  800a0e:	80 7a 01 78          	cmpb   $0x78,0x1(%edx)
  800a12:	75 0a                	jne    800a1e <strtol+0x5a>
		s += 2, base = 16;
  800a14:	83 c2 02             	add    $0x2,%edx
  800a17:	b8 10 00 00 00       	mov    $0x10,%eax
  800a1c:	eb 10                	jmp    800a2e <strtol+0x6a>
	else if (base == 0 && s[0] == '0')
  800a1e:	85 c0                	test   %eax,%eax
  800a20:	75 0c                	jne    800a2e <strtol+0x6a>
		s++, base = 8;
	else if (base == 0)
		base = 10;
  800a22:	b0 0a                	mov    $0xa,%al
		s++, neg = 1;

	// hex or octal base prefix
	if ((base == 0 || base == 16) && (s[0] == '0' && s[1] == 'x'))
		s += 2, base = 16;
	else if (base == 0 && s[0] == '0')
  800a24:	80 3a 30             	cmpb   $0x30,(%edx)
  800a27:	75 05                	jne    800a2e <strtol+0x6a>
		s++, base = 8;
  800a29:	83 c2 01             	add    $0x1,%edx
  800a2c:	b0 08                	mov    $0x8,%al
	else if (base == 0)
		base = 10;
  800a2e:	bb 00 00 00 00       	mov    $0x0,%ebx
  800a33:	89 45 10             	mov    %eax,0x10(%ebp)

	// digits
	while (1) {
		int dig;

		if (*s >= '0' && *s <= '9')
  800a36:	0f b6 0a             	movzbl (%edx),%ecx
  800a39:	8d 71 d0             	lea    -0x30(%ecx),%esi
  800a3c:	89 f0                	mov    %esi,%eax
  800a3e:	3c 09                	cmp    $0x9,%al
  800a40:	77 08                	ja     800a4a <strtol+0x86>
			dig = *s - '0';
  800a42:	0f be c9             	movsbl %cl,%ecx
  800a45:	83 e9 30             	sub    $0x30,%ecx
  800a48:	eb 20                	jmp    800a6a <strtol+0xa6>
		else if (*s >= 'a' && *s <= 'z')
  800a4a:	8d 71 9f             	lea    -0x61(%ecx),%esi
  800a4d:	89 f0                	mov    %esi,%eax
  800a4f:	3c 19                	cmp    $0x19,%al
  800a51:	77 08                	ja     800a5b <strtol+0x97>
			dig = *s - 'a' + 10;
  800a53:	0f be c9             	movsbl %cl,%ecx
  800a56:	83 e9 57             	sub    $0x57,%ecx
  800a59:	eb 0f                	jmp    800a6a <strtol+0xa6>
		else if (*s >= 'A' && *s <= 'Z')
  800a5b:	8d 71 bf             	lea    -0x41(%ecx),%esi
  800a5e:	89 f0                	mov    %esi,%eax
  800a60:	3c 19                	cmp    $0x19,%al
  800a62:	77 16                	ja     800a7a <strtol+0xb6>
			dig = *s - 'A' + 10;
  800a64:	0f be c9             	movsbl %cl,%ecx
  800a67:	83 e9 37             	sub    $0x37,%ecx
		else
			break;
		if (dig >= base)
  800a6a:	3b 4d 10             	cmp    0x10(%ebp),%ecx
  800a6d:	7d 0f                	jge    800a7e <strtol+0xba>
			break;
		s++, val = (val * base) + dig;
  800a6f:	83 c2 01             	add    $0x1,%edx
  800a72:	0f af 5d 10          	imul   0x10(%ebp),%ebx
  800a76:	01 cb                	add    %ecx,%ebx
		// we don't properly detect overflow!
	}
  800a78:	eb bc                	jmp    800a36 <strtol+0x72>
  800a7a:	89 d8                	mov    %ebx,%eax
  800a7c:	eb 02                	jmp    800a80 <strtol+0xbc>
  800a7e:	89 d8                	mov    %ebx,%eax

	if (endptr)
  800a80:	83 7d 0c 00          	cmpl   $0x0,0xc(%ebp)
  800a84:	74 05                	je     800a8b <strtol+0xc7>
		*endptr = (char *) s;
  800a86:	8b 75 0c             	mov    0xc(%ebp),%esi
  800a89:	89 16                	mov    %edx,(%esi)
	return (neg ? -val : val);
  800a8b:	f7 d8                	neg    %eax
  800a8d:	85 ff                	test   %edi,%edi
  800a8f:	0f 44 c3             	cmove  %ebx,%eax
}
  800a92:	5b                   	pop    %ebx
  800a93:	5e                   	pop    %esi
  800a94:	5f                   	pop    %edi
  800a95:	5d                   	pop    %ebp
  800a96:	c3                   	ret    

00800a97 <syscall>:
#include <inc/syscall.h>
#include <inc/lib.h>

static inline int32_t
syscall(int num, int check, uint32_t a1, uint32_t a2, uint32_t a3, uint32_t a4, uint32_t a5)
{
  800a97:	55                   	push   %ebp
  800a98:	89 e5                	mov    %esp,%ebp
  800a9a:	57                   	push   %edi
  800a9b:	56                   	push   %esi
  800a9c:	53                   	push   %ebx
  800a9d:	83 ec 2c             	sub    $0x2c,%esp
  800aa0:	89 45 e4             	mov    %eax,-0x1c(%ebp)
  800aa3:	89 55 e0             	mov    %edx,-0x20(%ebp)
  800aa6:	89 ca                	mov    %ecx,%edx
	//
	// The last clause tells the assembler that this can
	// potentially change the condition codes and arbitrary
	// memory locations.

	asm volatile("int %1\n"
  800aa8:	8b 4d 08             	mov    0x8(%ebp),%ecx
  800aab:	8b 5d 0c             	mov    0xc(%ebp),%ebx
  800aae:	8b 7d 10             	mov    0x10(%ebp),%edi
  800ab1:	8b 75 14             	mov    0x14(%ebp),%esi
  800ab4:	cd 30                	int    $0x30
		       "b" (a3),
		       "D" (a4),
		       "S" (a5)
		     : "cc", "memory");

	if(check && ret > 0)
  800ab6:	85 c0                	test   %eax,%eax
  800ab8:	7e 2d                	jle    800ae7 <syscall+0x50>
  800aba:	83 7d e0 00          	cmpl   $0x0,-0x20(%ebp)
  800abe:	74 27                	je     800ae7 <syscall+0x50>
		panic("syscall %d returned %d (> 0)", num, ret);
  800ac0:	89 44 24 10          	mov    %eax,0x10(%esp)
  800ac4:	8b 45 e4             	mov    -0x1c(%ebp),%eax
  800ac7:	89 44 24 0c          	mov    %eax,0xc(%esp)
  800acb:	c7 44 24 08 ec 10 80 	movl   $0x8010ec,0x8(%esp)
  800ad2:	00 
  800ad3:	c7 44 24 04 23 00 00 	movl   $0x23,0x4(%esp)
  800ada:	00 
  800adb:	c7 04 24 09 11 80 00 	movl   $0x801109,(%esp)
  800ae2:	e8 ef 00 00 00       	call   800bd6 <_panic>

	return ret;
}
  800ae7:	83 c4 2c             	add    $0x2c,%esp
  800aea:	5b                   	pop    %ebx
  800aeb:	5e                   	pop    %esi
  800aec:	5f                   	pop    %edi
  800aed:	5d                   	pop    %ebp
  800aee:	c3                   	ret    

00800aef <sys_cputs>:

void
sys_cputs(const char *s, size_t len)
{
  800aef:	55                   	push   %ebp
  800af0:	89 e5                	mov    %esp,%ebp
  800af2:	83 ec 18             	sub    $0x18,%esp
	syscall(SYS_cputs, 0, (uint32_t)s, len, 0, 0, 0);
  800af5:	c7 44 24 0c 00 00 00 	movl   $0x0,0xc(%esp)
  800afc:	00 
  800afd:	c7 44 24 08 00 00 00 	movl   $0x0,0x8(%esp)
  800b04:	00 
  800b05:	c7 44 24 04 00 00 00 	movl   $0x0,0x4(%esp)
  800b0c:	00 
  800b0d:	8b 45 0c             	mov    0xc(%ebp),%eax
  800b10:	89 04 24             	mov    %eax,(%esp)
  800b13:	8b 4d 08             	mov    0x8(%ebp),%ecx
  800b16:	ba 00 00 00 00       	mov    $0x0,%edx
  800b1b:	b8 00 00 00 00       	mov    $0x0,%eax
  800b20:	e8 72 ff ff ff       	call   800a97 <syscall>
}
  800b25:	c9                   	leave  
  800b26:	c3                   	ret    

00800b27 <sys_cgetc>:

int
sys_cgetc(void)
{
  800b27:	55                   	push   %ebp
  800b28:	89 e5                	mov    %esp,%ebp
  800b2a:	83 ec 18             	sub    $0x18,%esp
	return syscall(SYS_cgetc, 0, 0, 0, 0, 0, 0);
  800b2d:	c7 44 24 0c 00 00 00 	movl   $0x0,0xc(%esp)
  800b34:	00 
  800b35:	c7 44 24 08 00 00 00 	movl   $0x0,0x8(%esp)
  800b3c:	00 
  800b3d:	c7 44 24 04 00 00 00 	movl   $0x0,0x4(%esp)
  800b44:	00 
  800b45:	c7 04 24 00 00 00 00 	movl   $0x0,(%esp)
  800b4c:	b9 00 00 00 00       	mov    $0x0,%ecx
  800b51:	ba 00 00 00 00       	mov    $0x0,%edx
  800b56:	b8 01 00 00 00       	mov    $0x1,%eax
  800b5b:	e8 37 ff ff ff       	call   800a97 <syscall>
}
  800b60:	c9                   	leave  
  800b61:	c3                   	ret    

00800b62 <sys_env_destroy>:

int
sys_env_destroy(envid_t envid)
{
  800b62:	55                   	push   %ebp
  800b63:	89 e5                	mov    %esp,%ebp
  800b65:	83 ec 18             	sub    $0x18,%esp
	return syscall(SYS_env_destroy, 1, envid, 0, 0, 0, 0);
  800b68:	c7 44 24 0c 00 00 00 	movl   $0x0,0xc(%esp)
  800b6f:	00 
  800b70:	c7 44 24 08 00 00 00 	movl   $0x0,0x8(%esp)
  800b77:	00 
  800b78:	c7 44 24 04 00 00 00 	movl   $0x0,0x4(%esp)
  800b7f:	00 
  800b80:	c7 04 24 00 00 00 00 	movl   $0x0,(%esp)
  800b87:	8b 4d 08             	mov    0x8(%ebp),%ecx
  800b8a:	ba 01 00 00 00       	mov    $0x1,%edx
  800b8f:	b8 03 00 00 00       	mov    $0x3,%eax
  800b94:	e8 fe fe ff ff       	call   800a97 <syscall>
}
  800b99:	c9                   	leave  
  800b9a:	c3                   	ret    

00800b9b <sys_getenvid>:

envid_t
sys_getenvid(void)
{
  800b9b:	55                   	push   %ebp
  800b9c:	89 e5                	mov    %esp,%ebp
  800b9e:	83 ec 18             	sub    $0x18,%esp
	 return syscall(SYS_getenvid, 0, 0, 0, 0, 0, 0);
  800ba1:	c7 44 24 0c 00 00 00 	movl   $0x0,0xc(%esp)
  800ba8:	00 
  800ba9:	c7 44 24 08 00 00 00 	movl   $0x0,0x8(%esp)
  800bb0:	00 
  800bb1:	c7 44 24 04 00 00 00 	movl   $0x0,0x4(%esp)
  800bb8:	00 
  800bb9:	c7 04 24 00 00 00 00 	movl   $0x0,(%esp)
  800bc0:	b9 00 00 00 00       	mov    $0x0,%ecx
  800bc5:	ba 00 00 00 00       	mov    $0x0,%edx
  800bca:	b8 02 00 00 00       	mov    $0x2,%eax
  800bcf:	e8 c3 fe ff ff       	call   800a97 <syscall>
}
  800bd4:	c9                   	leave  
  800bd5:	c3                   	ret    

00800bd6 <_panic>:
 * It prints "panic: <message>", then causes a breakpoint exception,
 * which causes JOS to enter the JOS kernel monitor.
 */
void
_panic(const char *file, int line, const char *fmt, ...)
{
  800bd6:	55                   	push   %ebp
  800bd7:	89 e5                	mov    %esp,%ebp
  800bd9:	56                   	push   %esi
  800bda:	53                   	push   %ebx
  800bdb:	83 ec 20             	sub    $0x20,%esp
	va_list ap;

	va_start(ap, fmt);
  800bde:	8d 5d 14             	lea    0x14(%ebp),%ebx

	// Print the panic message
	cprintf("[%08x] user panic in %s at %s:%d: ",
  800be1:	8b 35 00 20 80 00    	mov    0x802000,%esi
  800be7:	e8 af ff ff ff       	call   800b9b <sys_getenvid>
  800bec:	8b 55 0c             	mov    0xc(%ebp),%edx
  800bef:	89 54 24 10          	mov    %edx,0x10(%esp)
  800bf3:	8b 55 08             	mov    0x8(%ebp),%edx
  800bf6:	89 54 24 0c          	mov    %edx,0xc(%esp)
  800bfa:	89 74 24 08          	mov    %esi,0x8(%esp)
  800bfe:	89 44 24 04          	mov    %eax,0x4(%esp)
  800c02:	c7 04 24 18 11 80 00 	movl   $0x801118,(%esp)
  800c09:	e8 2e f5 ff ff       	call   80013c <cprintf>
		sys_getenvid(), binaryname, file, line);
	vcprintf(fmt, ap);
  800c0e:	89 5c 24 04          	mov    %ebx,0x4(%esp)
  800c12:	8b 45 10             	mov    0x10(%ebp),%eax
  800c15:	89 04 24             	mov    %eax,(%esp)
  800c18:	e8 be f4 ff ff       	call   8000db <vcprintf>
	cprintf("\n");
  800c1d:	c7 04 24 3c 11 80 00 	movl   $0x80113c,(%esp)
  800c24:	e8 13 f5 ff ff       	call   80013c <cprintf>

	// Cause a breakpoint exception
	while (1)
		asm volatile("int3");
  800c29:	cc                   	int3   
  800c2a:	eb fd                	jmp    800c29 <_panic+0x53>
  800c2c:	66 90                	xchg   %ax,%ax
  800c2e:	66 90                	xchg   %ax,%ax

00800c30 <__udivdi3>:
  800c30:	55                   	push   %ebp
  800c31:	57                   	push   %edi
  800c32:	56                   	push   %esi
  800c33:	83 ec 0c             	sub    $0xc,%esp
  800c36:	8b 44 24 28          	mov    0x28(%esp),%eax
  800c3a:	8b 7c 24 1c          	mov    0x1c(%esp),%edi
  800c3e:	8b 6c 24 20          	mov    0x20(%esp),%ebp
  800c42:	8b 4c 24 24          	mov    0x24(%esp),%ecx
  800c46:	85 c0                	test   %eax,%eax
  800c48:	89 7c 24 04          	mov    %edi,0x4(%esp)
  800c4c:	89 ea                	mov    %ebp,%edx
  800c4e:	89 0c 24             	mov    %ecx,(%esp)
  800c51:	75 2d                	jne    800c80 <__udivdi3+0x50>
  800c53:	39 e9                	cmp    %ebp,%ecx
  800c55:	77 61                	ja     800cb8 <__udivdi3+0x88>
  800c57:	85 c9                	test   %ecx,%ecx
  800c59:	89 ce                	mov    %ecx,%esi
  800c5b:	75 0b                	jne    800c68 <__udivdi3+0x38>
  800c5d:	b8 01 00 00 00       	mov    $0x1,%eax
  800c62:	31 d2                	xor    %edx,%edx
  800c64:	f7 f1                	div    %ecx
  800c66:	89 c6                	mov    %eax,%esi
  800c68:	31 d2                	xor    %edx,%edx
  800c6a:	89 e8                	mov    %ebp,%eax
  800c6c:	f7 f6                	div    %esi
  800c6e:	89 c5                	mov    %eax,%ebp
  800c70:	89 f8                	mov    %edi,%eax
  800c72:	f7 f6                	div    %esi
  800c74:	89 ea                	mov    %ebp,%edx
  800c76:	83 c4 0c             	add    $0xc,%esp
  800c79:	5e                   	pop    %esi
  800c7a:	5f                   	pop    %edi
  800c7b:	5d                   	pop    %ebp
  800c7c:	c3                   	ret    
  800c7d:	8d 76 00             	lea    0x0(%esi),%esi
  800c80:	39 e8                	cmp    %ebp,%eax
  800c82:	77 24                	ja     800ca8 <__udivdi3+0x78>
  800c84:	0f bd e8             	bsr    %eax,%ebp
  800c87:	83 f5 1f             	xor    $0x1f,%ebp
  800c8a:	75 3c                	jne    800cc8 <__udivdi3+0x98>
  800c8c:	8b 74 24 04          	mov    0x4(%esp),%esi
  800c90:	39 34 24             	cmp    %esi,(%esp)
  800c93:	0f 86 9f 00 00 00    	jbe    800d38 <__udivdi3+0x108>
  800c99:	39 d0                	cmp    %edx,%eax
  800c9b:	0f 82 97 00 00 00    	jb     800d38 <__udivdi3+0x108>
  800ca1:	8d b4 26 00 00 00 00 	lea    0x0(%esi,%eiz,1),%esi
  800ca8:	31 d2                	xor    %edx,%edx
  800caa:	31 c0                	xor    %eax,%eax
  800cac:	83 c4 0c             	add    $0xc,%esp
  800caf:	5e                   	pop    %esi
  800cb0:	5f                   	pop    %edi
  800cb1:	5d                   	pop    %ebp
  800cb2:	c3                   	ret    
  800cb3:	90                   	nop
  800cb4:	8d 74 26 00          	lea    0x0(%esi,%eiz,1),%esi
  800cb8:	89 f8                	mov    %edi,%eax
  800cba:	f7 f1                	div    %ecx
  800cbc:	31 d2                	xor    %edx,%edx
  800cbe:	83 c4 0c             	add    $0xc,%esp
  800cc1:	5e                   	pop    %esi
  800cc2:	5f                   	pop    %edi
  800cc3:	5d                   	pop    %ebp
  800cc4:	c3                   	ret    
  800cc5:	8d 76 00             	lea    0x0(%esi),%esi
  800cc8:	89 e9                	mov    %ebp,%ecx
  800cca:	8b 3c 24             	mov    (%esp),%edi
  800ccd:	d3 e0                	shl    %cl,%eax
  800ccf:	89 c6                	mov    %eax,%esi
  800cd1:	b8 20 00 00 00       	mov    $0x20,%eax
  800cd6:	29 e8                	sub    %ebp,%eax
  800cd8:	89 c1                	mov    %eax,%ecx
  800cda:	d3 ef                	shr    %cl,%edi
  800cdc:	89 e9                	mov    %ebp,%ecx
  800cde:	89 7c 24 08          	mov    %edi,0x8(%esp)
  800ce2:	8b 3c 24             	mov    (%esp),%edi
  800ce5:	09 74 24 08          	or     %esi,0x8(%esp)
  800ce9:	89 d6                	mov    %edx,%esi
  800ceb:	d3 e7                	shl    %cl,%edi
  800ced:	89 c1                	mov    %eax,%ecx
  800cef:	89 3c 24             	mov    %edi,(%esp)
  800cf2:	8b 7c 24 04          	mov    0x4(%esp),%edi
  800cf6:	d3 ee                	shr    %cl,%esi
  800cf8:	89 e9                	mov    %ebp,%ecx
  800cfa:	d3 e2                	shl    %cl,%edx
  800cfc:	89 c1                	mov    %eax,%ecx
  800cfe:	d3 ef                	shr    %cl,%edi
  800d00:	09 d7                	or     %edx,%edi
  800d02:	89 f2                	mov    %esi,%edx
  800d04:	89 f8                	mov    %edi,%eax
  800d06:	f7 74 24 08          	divl   0x8(%esp)
  800d0a:	89 d6                	mov    %edx,%esi
  800d0c:	89 c7                	mov    %eax,%edi
  800d0e:	f7 24 24             	mull   (%esp)
  800d11:	39 d6                	cmp    %edx,%esi
  800d13:	89 14 24             	mov    %edx,(%esp)
  800d16:	72 30                	jb     800d48 <__udivdi3+0x118>
  800d18:	8b 54 24 04          	mov    0x4(%esp),%edx
  800d1c:	89 e9                	mov    %ebp,%ecx
  800d1e:	d3 e2                	shl    %cl,%edx
  800d20:	39 c2                	cmp    %eax,%edx
  800d22:	73 05                	jae    800d29 <__udivdi3+0xf9>
  800d24:	3b 34 24             	cmp    (%esp),%esi
  800d27:	74 1f                	je     800d48 <__udivdi3+0x118>
  800d29:	89 f8                	mov    %edi,%eax
  800d2b:	31 d2                	xor    %edx,%edx
  800d2d:	e9 7a ff ff ff       	jmp    800cac <__udivdi3+0x7c>
  800d32:	8d b6 00 00 00 00    	lea    0x0(%esi),%esi
  800d38:	31 d2                	xor    %edx,%edx
  800d3a:	b8 01 00 00 00       	mov    $0x1,%eax
  800d3f:	e9 68 ff ff ff       	jmp    800cac <__udivdi3+0x7c>
  800d44:	8d 74 26 00          	lea    0x0(%esi,%eiz,1),%esi
  800d48:	8d 47 ff             	lea    -0x1(%edi),%eax
  800d4b:	31 d2                	xor    %edx,%edx
  800d4d:	83 c4 0c             	add    $0xc,%esp
  800d50:	5e                   	pop    %esi
  800d51:	5f                   	pop    %edi
  800d52:	5d                   	pop    %ebp
  800d53:	c3                   	ret    
  800d54:	66 90                	xchg   %ax,%ax
  800d56:	66 90                	xchg   %ax,%ax
  800d58:	66 90                	xchg   %ax,%ax
  800d5a:	66 90                	xchg   %ax,%ax
  800d5c:	66 90                	xchg   %ax,%ax
  800d5e:	66 90                	xchg   %ax,%ax

00800d60 <__umoddi3>:
  800d60:	55                   	push   %ebp
  800d61:	57                   	push   %edi
  800d62:	56                   	push   %esi
  800d63:	83 ec 14             	sub    $0x14,%esp
  800d66:	8b 44 24 28          	mov    0x28(%esp),%eax
  800d6a:	8b 4c 24 24          	mov    0x24(%esp),%ecx
  800d6e:	8b 74 24 2c          	mov    0x2c(%esp),%esi
  800d72:	89 c7                	mov    %eax,%edi
  800d74:	89 44 24 04          	mov    %eax,0x4(%esp)
  800d78:	8b 44 24 30          	mov    0x30(%esp),%eax
  800d7c:	89 4c 24 10          	mov    %ecx,0x10(%esp)
  800d80:	89 34 24             	mov    %esi,(%esp)
  800d83:	89 4c 24 08          	mov    %ecx,0x8(%esp)
  800d87:	85 c0                	test   %eax,%eax
  800d89:	89 c2                	mov    %eax,%edx
  800d8b:	89 7c 24 0c          	mov    %edi,0xc(%esp)
  800d8f:	75 17                	jne    800da8 <__umoddi3+0x48>
  800d91:	39 fe                	cmp    %edi,%esi
  800d93:	76 4b                	jbe    800de0 <__umoddi3+0x80>
  800d95:	89 c8                	mov    %ecx,%eax
  800d97:	89 fa                	mov    %edi,%edx
  800d99:	f7 f6                	div    %esi
  800d9b:	89 d0                	mov    %edx,%eax
  800d9d:	31 d2                	xor    %edx,%edx
  800d9f:	83 c4 14             	add    $0x14,%esp
  800da2:	5e                   	pop    %esi
  800da3:	5f                   	pop    %edi
  800da4:	5d                   	pop    %ebp
  800da5:	c3                   	ret    
  800da6:	66 90                	xchg   %ax,%ax
  800da8:	39 f8                	cmp    %edi,%eax
  800daa:	77 54                	ja     800e00 <__umoddi3+0xa0>
  800dac:	0f bd e8             	bsr    %eax,%ebp
  800daf:	83 f5 1f             	xor    $0x1f,%ebp
  800db2:	75 5c                	jne    800e10 <__umoddi3+0xb0>
  800db4:	8b 7c 24 08          	mov    0x8(%esp),%edi
  800db8:	39 3c 24             	cmp    %edi,(%esp)
  800dbb:	0f 87 e7 00 00 00    	ja     800ea8 <__umoddi3+0x148>
  800dc1:	8b 7c 24 04          	mov    0x4(%esp),%edi
  800dc5:	29 f1                	sub    %esi,%ecx
  800dc7:	19 c7                	sbb    %eax,%edi
  800dc9:	89 4c 24 08          	mov    %ecx,0x8(%esp)
  800dcd:	89 7c 24 0c          	mov    %edi,0xc(%esp)
  800dd1:	8b 44 24 08          	mov    0x8(%esp),%eax
  800dd5:	8b 54 24 0c          	mov    0xc(%esp),%edx
  800dd9:	83 c4 14             	add    $0x14,%esp
  800ddc:	5e                   	pop    %esi
  800ddd:	5f                   	pop    %edi
  800dde:	5d                   	pop    %ebp
  800ddf:	c3                   	ret    
  800de0:	85 f6                	test   %esi,%esi
  800de2:	89 f5                	mov    %esi,%ebp
  800de4:	75 0b                	jne    800df1 <__umoddi3+0x91>
  800de6:	b8 01 00 00 00       	mov    $0x1,%eax
  800deb:	31 d2                	xor    %edx,%edx
  800ded:	f7 f6                	div    %esi
  800def:	89 c5                	mov    %eax,%ebp
  800df1:	8b 44 24 04          	mov    0x4(%esp),%eax
  800df5:	31 d2                	xor    %edx,%edx
  800df7:	f7 f5                	div    %ebp
  800df9:	89 c8                	mov    %ecx,%eax
  800dfb:	f7 f5                	div    %ebp
  800dfd:	eb 9c                	jmp    800d9b <__umoddi3+0x3b>
  800dff:	90                   	nop
  800e00:	89 c8                	mov    %ecx,%eax
  800e02:	89 fa                	mov    %edi,%edx
  800e04:	83 c4 14             	add    $0x14,%esp
  800e07:	5e                   	pop    %esi
  800e08:	5f                   	pop    %edi
  800e09:	5d                   	pop    %ebp
  800e0a:	c3                   	ret    
  800e0b:	90                   	nop
  800e0c:	8d 74 26 00          	lea    0x0(%esi,%eiz,1),%esi
  800e10:	8b 04 24             	mov    (%esp),%eax
  800e13:	be 20 00 00 00       	mov    $0x20,%esi
  800e18:	89 e9                	mov    %ebp,%ecx
  800e1a:	29 ee                	sub    %ebp,%esi
  800e1c:	d3 e2                	shl    %cl,%edx
  800e1e:	89 f1                	mov    %esi,%ecx
  800e20:	d3 e8                	shr    %cl,%eax
  800e22:	89 e9                	mov    %ebp,%ecx
  800e24:	89 44 24 04          	mov    %eax,0x4(%esp)
  800e28:	8b 04 24             	mov    (%esp),%eax
  800e2b:	09 54 24 04          	or     %edx,0x4(%esp)
  800e2f:	89 fa                	mov    %edi,%edx
  800e31:	d3 e0                	shl    %cl,%eax
  800e33:	89 f1                	mov    %esi,%ecx
  800e35:	89 44 24 08          	mov    %eax,0x8(%esp)
  800e39:	8b 44 24 10          	mov    0x10(%esp),%eax
  800e3d:	d3 ea                	shr    %cl,%edx
  800e3f:	89 e9                	mov    %ebp,%ecx
  800e41:	d3 e7                	shl    %cl,%edi
  800e43:	89 f1                	mov    %esi,%ecx
  800e45:	d3 e8                	shr    %cl,%eax
  800e47:	89 e9                	mov    %ebp,%ecx
  800e49:	09 f8                	or     %edi,%eax
  800e4b:	8b 7c 24 10          	mov    0x10(%esp),%edi
  800e4f:	f7 74 24 04          	divl   0x4(%esp)
  800e53:	d3 e7                	shl    %cl,%edi
  800e55:	89 7c 24 0c          	mov    %edi,0xc(%esp)
  800e59:	89 d7                	mov    %edx,%edi
  800e5b:	f7 64 24 08          	mull   0x8(%esp)
  800e5f:	39 d7                	cmp    %edx,%edi
  800e61:	89 c1                	mov    %eax,%ecx
  800e63:	89 14 24             	mov    %edx,(%esp)
  800e66:	72 2c                	jb     800e94 <__umoddi3+0x134>
  800e68:	39 44 24 0c          	cmp    %eax,0xc(%esp)
  800e6c:	72 22                	jb     800e90 <__umoddi3+0x130>
  800e6e:	8b 44 24 0c          	mov    0xc(%esp),%eax
  800e72:	29 c8                	sub    %ecx,%eax
  800e74:	19 d7                	sbb    %edx,%edi
  800e76:	89 e9                	mov    %ebp,%ecx
  800e78:	89 fa                	mov    %edi,%edx
  800e7a:	d3 e8                	shr    %cl,%eax
  800e7c:	89 f1                	mov    %esi,%ecx
  800e7e:	d3 e2                	shl    %cl,%edx
  800e80:	89 e9                	mov    %ebp,%ecx
  800e82:	d3 ef                	shr    %cl,%edi
  800e84:	09 d0                	or     %edx,%eax
  800e86:	89 fa                	mov    %edi,%edx
  800e88:	83 c4 14             	add    $0x14,%esp
  800e8b:	5e                   	pop    %esi
  800e8c:	5f                   	pop    %edi
  800e8d:	5d                   	pop    %ebp
  800e8e:	c3                   	ret    
  800e8f:	90                   	nop
  800e90:	39 d7                	cmp    %edx,%edi
  800e92:	75 da                	jne    800e6e <__umoddi3+0x10e>
  800e94:	8b 14 24             	mov    (%esp),%edx
  800e97:	89 c1                	mov    %eax,%ecx
  800e99:	2b 4c 24 08          	sub    0x8(%esp),%ecx
  800e9d:	1b 54 24 04          	sbb    0x4(%esp),%edx
  800ea1:	eb cb                	jmp    800e6e <__umoddi3+0x10e>
  800ea3:	90                   	nop
  800ea4:	8d 74 26 00          	lea    0x0(%esi,%eiz,1),%esi
  800ea8:	3b 44 24 0c          	cmp    0xc(%esp),%eax
  800eac:	0f 82 0f ff ff ff    	jb     800dc1 <__umoddi3+0x61>
  800eb2:	e9 1a ff ff ff       	jmp    800dd1 <__umoddi3+0x71>
