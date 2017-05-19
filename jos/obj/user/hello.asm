
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
  80002c:	e8 2a 00 00 00       	call   80005b <libmain>
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
  800036:	83 ec 14             	sub    $0x14,%esp
	cprintf("hello, world\n");
  800039:	68 94 0d 80 00       	push   $0x800d94
  80003e:	e8 f3 00 00 00       	call   800136 <cprintf>
	cprintf("i am environment %08x\n", sys_getenvid());
  800043:	e8 58 0a 00 00       	call   800aa0 <sys_getenvid>
  800048:	83 c4 08             	add    $0x8,%esp
  80004b:	50                   	push   %eax
  80004c:	68 a2 0d 80 00       	push   $0x800da2
  800051:	e8 e0 00 00 00       	call   800136 <cprintf>
}
  800056:	83 c4 10             	add    $0x10,%esp
  800059:	c9                   	leave  
  80005a:	c3                   	ret    

0080005b <libmain>:
const volatile struct Env *thisenv;
const char *binaryname = "<unknown>";

void
libmain(int argc, char **argv)
{
  80005b:	55                   	push   %ebp
  80005c:	89 e5                	mov    %esp,%ebp
  80005e:	83 ec 08             	sub    $0x8,%esp
  800061:	8b 45 08             	mov    0x8(%ebp),%eax
  800064:	8b 55 0c             	mov    0xc(%ebp),%edx
	// set thisenv to point at our Env structure in envs[].
	// LAB 3: Your code here.
	thisenv = 0;
  800067:	c7 05 04 20 80 00 00 	movl   $0x0,0x802004
  80006e:	00 00 00 

	// save the name of the program so that panic() can use it
	if (argc > 0)
  800071:	85 c0                	test   %eax,%eax
  800073:	7e 08                	jle    80007d <libmain+0x22>
		binaryname = argv[0];
  800075:	8b 0a                	mov    (%edx),%ecx
  800077:	89 0d 00 20 80 00    	mov    %ecx,0x802000

	// call user main routine
	umain(argc, argv);
  80007d:	83 ec 08             	sub    $0x8,%esp
  800080:	52                   	push   %edx
  800081:	50                   	push   %eax
  800082:	e8 ac ff ff ff       	call   800033 <umain>

	// exit gracefully
	exit();
  800087:	e8 05 00 00 00       	call   800091 <exit>
}
  80008c:	83 c4 10             	add    $0x10,%esp
  80008f:	c9                   	leave  
  800090:	c3                   	ret    

00800091 <exit>:

#include <inc/lib.h>

void
exit(void)
{
  800091:	55                   	push   %ebp
  800092:	89 e5                	mov    %esp,%ebp
  800094:	83 ec 14             	sub    $0x14,%esp
	sys_env_destroy(0);
  800097:	6a 00                	push   $0x0
  800099:	e8 e0 09 00 00       	call   800a7e <sys_env_destroy>
}
  80009e:	83 c4 10             	add    $0x10,%esp
  8000a1:	c9                   	leave  
  8000a2:	c3                   	ret    

008000a3 <putch>:
};


static void
putch(int ch, struct printbuf *b)
{
  8000a3:	55                   	push   %ebp
  8000a4:	89 e5                	mov    %esp,%ebp
  8000a6:	53                   	push   %ebx
  8000a7:	83 ec 04             	sub    $0x4,%esp
  8000aa:	8b 5d 0c             	mov    0xc(%ebp),%ebx
	b->buf[b->idx++] = ch;
  8000ad:	8b 13                	mov    (%ebx),%edx
  8000af:	8d 42 01             	lea    0x1(%edx),%eax
  8000b2:	89 03                	mov    %eax,(%ebx)
  8000b4:	8b 4d 08             	mov    0x8(%ebp),%ecx
  8000b7:	88 4c 13 08          	mov    %cl,0x8(%ebx,%edx,1)
	if (b->idx == 256-1) {
  8000bb:	3d ff 00 00 00       	cmp    $0xff,%eax
  8000c0:	75 1a                	jne    8000dc <putch+0x39>
		sys_cputs(b->buf, b->idx);
  8000c2:	83 ec 08             	sub    $0x8,%esp
  8000c5:	68 ff 00 00 00       	push   $0xff
  8000ca:	8d 43 08             	lea    0x8(%ebx),%eax
  8000cd:	50                   	push   %eax
  8000ce:	e8 61 09 00 00       	call   800a34 <sys_cputs>
		b->idx = 0;
  8000d3:	c7 03 00 00 00 00    	movl   $0x0,(%ebx)
  8000d9:	83 c4 10             	add    $0x10,%esp
	}
	b->cnt++;
  8000dc:	83 43 04 01          	addl   $0x1,0x4(%ebx)
}
  8000e0:	8b 5d fc             	mov    -0x4(%ebp),%ebx
  8000e3:	c9                   	leave  
  8000e4:	c3                   	ret    

008000e5 <vcprintf>:

int
vcprintf(const char *fmt, va_list ap)
{
  8000e5:	55                   	push   %ebp
  8000e6:	89 e5                	mov    %esp,%ebp
  8000e8:	81 ec 18 01 00 00    	sub    $0x118,%esp
	struct printbuf b;

	b.idx = 0;
  8000ee:	c7 85 f0 fe ff ff 00 	movl   $0x0,-0x110(%ebp)
  8000f5:	00 00 00 
	b.cnt = 0;
  8000f8:	c7 85 f4 fe ff ff 00 	movl   $0x0,-0x10c(%ebp)
  8000ff:	00 00 00 
	vprintfmt((void*)putch, &b, fmt, ap);
  800102:	ff 75 0c             	pushl  0xc(%ebp)
  800105:	ff 75 08             	pushl  0x8(%ebp)
  800108:	8d 85 f0 fe ff ff    	lea    -0x110(%ebp),%eax
  80010e:	50                   	push   %eax
  80010f:	68 a3 00 80 00       	push   $0x8000a3
  800114:	e8 86 01 00 00       	call   80029f <vprintfmt>
	sys_cputs(b.buf, b.idx);
  800119:	83 c4 08             	add    $0x8,%esp
  80011c:	ff b5 f0 fe ff ff    	pushl  -0x110(%ebp)
  800122:	8d 85 f8 fe ff ff    	lea    -0x108(%ebp),%eax
  800128:	50                   	push   %eax
  800129:	e8 06 09 00 00       	call   800a34 <sys_cputs>

	return b.cnt;
}
  80012e:	8b 85 f4 fe ff ff    	mov    -0x10c(%ebp),%eax
  800134:	c9                   	leave  
  800135:	c3                   	ret    

00800136 <cprintf>:

int
cprintf(const char *fmt, ...)
{
  800136:	55                   	push   %ebp
  800137:	89 e5                	mov    %esp,%ebp
  800139:	83 ec 10             	sub    $0x10,%esp
	va_list ap;
	int cnt;

	va_start(ap, fmt);
  80013c:	8d 45 0c             	lea    0xc(%ebp),%eax
	cnt = vcprintf(fmt, ap);
  80013f:	50                   	push   %eax
  800140:	ff 75 08             	pushl  0x8(%ebp)
  800143:	e8 9d ff ff ff       	call   8000e5 <vcprintf>
	va_end(ap);

	return cnt;
}
  800148:	c9                   	leave  
  800149:	c3                   	ret    

0080014a <printnum>:
 * using specified putch function and associated pointer putdat.
 */
static void
printnum(void (*putch)(int, void*), void *putdat,
	 unsigned long long num, unsigned base, int width, int padc)
{
  80014a:	55                   	push   %ebp
  80014b:	89 e5                	mov    %esp,%ebp
  80014d:	57                   	push   %edi
  80014e:	56                   	push   %esi
  80014f:	53                   	push   %ebx
  800150:	83 ec 1c             	sub    $0x1c,%esp
  800153:	89 c7                	mov    %eax,%edi
  800155:	89 d6                	mov    %edx,%esi
  800157:	8b 45 08             	mov    0x8(%ebp),%eax
  80015a:	8b 55 0c             	mov    0xc(%ebp),%edx
  80015d:	89 45 d8             	mov    %eax,-0x28(%ebp)
  800160:	89 55 dc             	mov    %edx,-0x24(%ebp)
	// first recursively print all preceding (more significant) digits
	if (num >= base) {
  800163:	8b 4d 10             	mov    0x10(%ebp),%ecx
  800166:	bb 00 00 00 00       	mov    $0x0,%ebx
  80016b:	89 4d e0             	mov    %ecx,-0x20(%ebp)
  80016e:	89 5d e4             	mov    %ebx,-0x1c(%ebp)
  800171:	39 d3                	cmp    %edx,%ebx
  800173:	72 05                	jb     80017a <printnum+0x30>
  800175:	39 45 10             	cmp    %eax,0x10(%ebp)
  800178:	77 45                	ja     8001bf <printnum+0x75>
		printnum(putch, putdat, num / base, base, width - 1, padc);
  80017a:	83 ec 0c             	sub    $0xc,%esp
  80017d:	ff 75 18             	pushl  0x18(%ebp)
  800180:	8b 45 14             	mov    0x14(%ebp),%eax
  800183:	8d 58 ff             	lea    -0x1(%eax),%ebx
  800186:	53                   	push   %ebx
  800187:	ff 75 10             	pushl  0x10(%ebp)
  80018a:	83 ec 08             	sub    $0x8,%esp
  80018d:	ff 75 e4             	pushl  -0x1c(%ebp)
  800190:	ff 75 e0             	pushl  -0x20(%ebp)
  800193:	ff 75 dc             	pushl  -0x24(%ebp)
  800196:	ff 75 d8             	pushl  -0x28(%ebp)
  800199:	e8 72 09 00 00       	call   800b10 <__udivdi3>
  80019e:	83 c4 18             	add    $0x18,%esp
  8001a1:	52                   	push   %edx
  8001a2:	50                   	push   %eax
  8001a3:	89 f2                	mov    %esi,%edx
  8001a5:	89 f8                	mov    %edi,%eax
  8001a7:	e8 9e ff ff ff       	call   80014a <printnum>
  8001ac:	83 c4 20             	add    $0x20,%esp
  8001af:	eb 18                	jmp    8001c9 <printnum+0x7f>
	} else {
		// print any needed pad characters before first digit
		while (--width > 0)
			putch(padc, putdat);
  8001b1:	83 ec 08             	sub    $0x8,%esp
  8001b4:	56                   	push   %esi
  8001b5:	ff 75 18             	pushl  0x18(%ebp)
  8001b8:	ff d7                	call   *%edi
  8001ba:	83 c4 10             	add    $0x10,%esp
  8001bd:	eb 03                	jmp    8001c2 <printnum+0x78>
  8001bf:	8b 5d 14             	mov    0x14(%ebp),%ebx
	// first recursively print all preceding (more significant) digits
	if (num >= base) {
		printnum(putch, putdat, num / base, base, width - 1, padc);
	} else {
		// print any needed pad characters before first digit
		while (--width > 0)
  8001c2:	83 eb 01             	sub    $0x1,%ebx
  8001c5:	85 db                	test   %ebx,%ebx
  8001c7:	7f e8                	jg     8001b1 <printnum+0x67>
			putch(padc, putdat);
	}

	// then print this (the least significant) digit
	putch("0123456789abcdef"[num % base], putdat);
  8001c9:	83 ec 08             	sub    $0x8,%esp
  8001cc:	56                   	push   %esi
  8001cd:	83 ec 04             	sub    $0x4,%esp
  8001d0:	ff 75 e4             	pushl  -0x1c(%ebp)
  8001d3:	ff 75 e0             	pushl  -0x20(%ebp)
  8001d6:	ff 75 dc             	pushl  -0x24(%ebp)
  8001d9:	ff 75 d8             	pushl  -0x28(%ebp)
  8001dc:	e8 5f 0a 00 00       	call   800c40 <__umoddi3>
  8001e1:	83 c4 14             	add    $0x14,%esp
  8001e4:	0f be 80 c3 0d 80 00 	movsbl 0x800dc3(%eax),%eax
  8001eb:	50                   	push   %eax
  8001ec:	ff d7                	call   *%edi
}
  8001ee:	83 c4 10             	add    $0x10,%esp
  8001f1:	8d 65 f4             	lea    -0xc(%ebp),%esp
  8001f4:	5b                   	pop    %ebx
  8001f5:	5e                   	pop    %esi
  8001f6:	5f                   	pop    %edi
  8001f7:	5d                   	pop    %ebp
  8001f8:	c3                   	ret    

008001f9 <getuint>:

// Get an unsigned int of various possible sizes from a varargs list,
// depending on the lflag parameter.
static unsigned long long
getuint(va_list *ap, int lflag)
{
  8001f9:	55                   	push   %ebp
  8001fa:	89 e5                	mov    %esp,%ebp
	if (lflag >= 2)
  8001fc:	83 fa 01             	cmp    $0x1,%edx
  8001ff:	7e 0e                	jle    80020f <getuint+0x16>
		return va_arg(*ap, unsigned long long);
  800201:	8b 10                	mov    (%eax),%edx
  800203:	8d 4a 08             	lea    0x8(%edx),%ecx
  800206:	89 08                	mov    %ecx,(%eax)
  800208:	8b 02                	mov    (%edx),%eax
  80020a:	8b 52 04             	mov    0x4(%edx),%edx
  80020d:	eb 22                	jmp    800231 <getuint+0x38>
	else if (lflag)
  80020f:	85 d2                	test   %edx,%edx
  800211:	74 10                	je     800223 <getuint+0x2a>
		return va_arg(*ap, unsigned long);
  800213:	8b 10                	mov    (%eax),%edx
  800215:	8d 4a 04             	lea    0x4(%edx),%ecx
  800218:	89 08                	mov    %ecx,(%eax)
  80021a:	8b 02                	mov    (%edx),%eax
  80021c:	ba 00 00 00 00       	mov    $0x0,%edx
  800221:	eb 0e                	jmp    800231 <getuint+0x38>
	else
		return va_arg(*ap, unsigned int);
  800223:	8b 10                	mov    (%eax),%edx
  800225:	8d 4a 04             	lea    0x4(%edx),%ecx
  800228:	89 08                	mov    %ecx,(%eax)
  80022a:	8b 02                	mov    (%edx),%eax
  80022c:	ba 00 00 00 00       	mov    $0x0,%edx
}
  800231:	5d                   	pop    %ebp
  800232:	c3                   	ret    

00800233 <getint>:

// Same as getuint but signed - can't use getuint
// because of sign extension
static long long
getint(va_list *ap, int lflag)
{
  800233:	55                   	push   %ebp
  800234:	89 e5                	mov    %esp,%ebp
	if (lflag >= 2)
  800236:	83 fa 01             	cmp    $0x1,%edx
  800239:	7e 0e                	jle    800249 <getint+0x16>
		return va_arg(*ap, long long);
  80023b:	8b 10                	mov    (%eax),%edx
  80023d:	8d 4a 08             	lea    0x8(%edx),%ecx
  800240:	89 08                	mov    %ecx,(%eax)
  800242:	8b 02                	mov    (%edx),%eax
  800244:	8b 52 04             	mov    0x4(%edx),%edx
  800247:	eb 1a                	jmp    800263 <getint+0x30>
	else if (lflag)
  800249:	85 d2                	test   %edx,%edx
  80024b:	74 0c                	je     800259 <getint+0x26>
		return va_arg(*ap, long);
  80024d:	8b 10                	mov    (%eax),%edx
  80024f:	8d 4a 04             	lea    0x4(%edx),%ecx
  800252:	89 08                	mov    %ecx,(%eax)
  800254:	8b 02                	mov    (%edx),%eax
  800256:	99                   	cltd   
  800257:	eb 0a                	jmp    800263 <getint+0x30>
	else
		return va_arg(*ap, int);
  800259:	8b 10                	mov    (%eax),%edx
  80025b:	8d 4a 04             	lea    0x4(%edx),%ecx
  80025e:	89 08                	mov    %ecx,(%eax)
  800260:	8b 02                	mov    (%edx),%eax
  800262:	99                   	cltd   
}
  800263:	5d                   	pop    %ebp
  800264:	c3                   	ret    

00800265 <sprintputch>:
	int cnt;
};

static void
sprintputch(int ch, struct sprintbuf *b)
{
  800265:	55                   	push   %ebp
  800266:	89 e5                	mov    %esp,%ebp
  800268:	8b 45 0c             	mov    0xc(%ebp),%eax
	b->cnt++;
  80026b:	83 40 08 01          	addl   $0x1,0x8(%eax)
	if (b->buf < b->ebuf)
  80026f:	8b 10                	mov    (%eax),%edx
  800271:	3b 50 04             	cmp    0x4(%eax),%edx
  800274:	73 0a                	jae    800280 <sprintputch+0x1b>
		*b->buf++ = ch;
  800276:	8d 4a 01             	lea    0x1(%edx),%ecx
  800279:	89 08                	mov    %ecx,(%eax)
  80027b:	8b 45 08             	mov    0x8(%ebp),%eax
  80027e:	88 02                	mov    %al,(%edx)
}
  800280:	5d                   	pop    %ebp
  800281:	c3                   	ret    

00800282 <printfmt>:
	}
}

void
printfmt(void (*putch)(int, void*), void *putdat, const char *fmt, ...)
{
  800282:	55                   	push   %ebp
  800283:	89 e5                	mov    %esp,%ebp
  800285:	83 ec 08             	sub    $0x8,%esp
	va_list ap;

	va_start(ap, fmt);
  800288:	8d 45 14             	lea    0x14(%ebp),%eax
	vprintfmt(putch, putdat, fmt, ap);
  80028b:	50                   	push   %eax
  80028c:	ff 75 10             	pushl  0x10(%ebp)
  80028f:	ff 75 0c             	pushl  0xc(%ebp)
  800292:	ff 75 08             	pushl  0x8(%ebp)
  800295:	e8 05 00 00 00       	call   80029f <vprintfmt>
	va_end(ap);
}
  80029a:	83 c4 10             	add    $0x10,%esp
  80029d:	c9                   	leave  
  80029e:	c3                   	ret    

0080029f <vprintfmt>:
// Main function to format and print a string.
void printfmt(void (*putch)(int, void*), void *putdat, const char *fmt, ...);

void
vprintfmt(void (*putch)(int, void*), void *putdat, const char *fmt, va_list ap)
{
  80029f:	55                   	push   %ebp
  8002a0:	89 e5                	mov    %esp,%ebp
  8002a2:	57                   	push   %edi
  8002a3:	56                   	push   %esi
  8002a4:	53                   	push   %ebx
  8002a5:	83 ec 2c             	sub    $0x2c,%esp
  8002a8:	8b 75 08             	mov    0x8(%ebp),%esi
  8002ab:	8b 5d 0c             	mov    0xc(%ebp),%ebx
  8002ae:	8b 7d 10             	mov    0x10(%ebp),%edi
  8002b1:	eb 12                	jmp    8002c5 <vprintfmt+0x26>
	int base, lflag, width, precision, altflag;
	char padc;

	while (1) {
		while ((ch = *(unsigned char *) fmt++) != '%') {
			if (ch == '\0')
  8002b3:	85 c0                	test   %eax,%eax
  8002b5:	0f 84 44 03 00 00    	je     8005ff <vprintfmt+0x360>
				return;
			putch(ch, putdat);
  8002bb:	83 ec 08             	sub    $0x8,%esp
  8002be:	53                   	push   %ebx
  8002bf:	50                   	push   %eax
  8002c0:	ff d6                	call   *%esi
  8002c2:	83 c4 10             	add    $0x10,%esp
	unsigned long long num;
	int base, lflag, width, precision, altflag;
	char padc;

	while (1) {
		while ((ch = *(unsigned char *) fmt++) != '%') {
  8002c5:	83 c7 01             	add    $0x1,%edi
  8002c8:	0f b6 47 ff          	movzbl -0x1(%edi),%eax
  8002cc:	83 f8 25             	cmp    $0x25,%eax
  8002cf:	75 e2                	jne    8002b3 <vprintfmt+0x14>
  8002d1:	c6 45 d4 20          	movb   $0x20,-0x2c(%ebp)
  8002d5:	c7 45 d8 00 00 00 00 	movl   $0x0,-0x28(%ebp)
  8002dc:	c7 45 d0 ff ff ff ff 	movl   $0xffffffff,-0x30(%ebp)
  8002e3:	c7 45 e0 ff ff ff ff 	movl   $0xffffffff,-0x20(%ebp)
  8002ea:	ba 00 00 00 00       	mov    $0x0,%edx
  8002ef:	eb 07                	jmp    8002f8 <vprintfmt+0x59>
		width = -1;
		precision = -1;
		lflag = 0;
		altflag = 0;
	reswitch:
		switch (ch = *(unsigned char *) fmt++) {
  8002f1:	8b 7d e4             	mov    -0x1c(%ebp),%edi

		// flag to pad on the right
		case '-':
			padc = '-';
  8002f4:	c6 45 d4 2d          	movb   $0x2d,-0x2c(%ebp)
		width = -1;
		precision = -1;
		lflag = 0;
		altflag = 0;
	reswitch:
		switch (ch = *(unsigned char *) fmt++) {
  8002f8:	8d 47 01             	lea    0x1(%edi),%eax
  8002fb:	89 45 e4             	mov    %eax,-0x1c(%ebp)
  8002fe:	0f b6 07             	movzbl (%edi),%eax
  800301:	0f b6 c8             	movzbl %al,%ecx
  800304:	83 e8 23             	sub    $0x23,%eax
  800307:	3c 55                	cmp    $0x55,%al
  800309:	0f 87 d5 02 00 00    	ja     8005e4 <vprintfmt+0x345>
  80030f:	0f b6 c0             	movzbl %al,%eax
  800312:	ff 24 85 50 0e 80 00 	jmp    *0x800e50(,%eax,4)
  800319:	8b 7d e4             	mov    -0x1c(%ebp),%edi
			padc = '-';
			goto reswitch;

		// flag to pad with 0's instead of spaces
		case '0':
			padc = '0';
  80031c:	c6 45 d4 30          	movb   $0x30,-0x2c(%ebp)
  800320:	eb d6                	jmp    8002f8 <vprintfmt+0x59>
		width = -1;
		precision = -1;
		lflag = 0;
		altflag = 0;
	reswitch:
		switch (ch = *(unsigned char *) fmt++) {
  800322:	8b 7d e4             	mov    -0x1c(%ebp),%edi
  800325:	b8 00 00 00 00       	mov    $0x0,%eax
  80032a:	89 55 e4             	mov    %edx,-0x1c(%ebp)
		case '6':
		case '7':
		case '8':
		case '9':
			for (precision = 0; ; ++fmt) {
				precision = precision * 10 + ch - '0';
  80032d:	8d 04 80             	lea    (%eax,%eax,4),%eax
  800330:	8d 44 41 d0          	lea    -0x30(%ecx,%eax,2),%eax
				ch = *fmt;
  800334:	0f be 0f             	movsbl (%edi),%ecx
				if (ch < '0' || ch > '9')
  800337:	8d 51 d0             	lea    -0x30(%ecx),%edx
  80033a:	83 fa 09             	cmp    $0x9,%edx
  80033d:	77 39                	ja     800378 <vprintfmt+0xd9>
		case '5':
		case '6':
		case '7':
		case '8':
		case '9':
			for (precision = 0; ; ++fmt) {
  80033f:	83 c7 01             	add    $0x1,%edi
				precision = precision * 10 + ch - '0';
				ch = *fmt;
				if (ch < '0' || ch > '9')
					break;
			}
  800342:	eb e9                	jmp    80032d <vprintfmt+0x8e>
			goto process_precision;

		case '*':
			precision = va_arg(ap, int);
  800344:	8b 45 14             	mov    0x14(%ebp),%eax
  800347:	8d 48 04             	lea    0x4(%eax),%ecx
  80034a:	89 4d 14             	mov    %ecx,0x14(%ebp)
  80034d:	8b 00                	mov    (%eax),%eax
  80034f:	89 45 d0             	mov    %eax,-0x30(%ebp)
		width = -1;
		precision = -1;
		lflag = 0;
		altflag = 0;
	reswitch:
		switch (ch = *(unsigned char *) fmt++) {
  800352:	8b 7d e4             	mov    -0x1c(%ebp),%edi
			}
			goto process_precision;

		case '*':
			precision = va_arg(ap, int);
			goto process_precision;
  800355:	eb 27                	jmp    80037e <vprintfmt+0xdf>
  800357:	8b 45 e0             	mov    -0x20(%ebp),%eax
  80035a:	85 c0                	test   %eax,%eax
  80035c:	b9 00 00 00 00       	mov    $0x0,%ecx
  800361:	0f 49 c8             	cmovns %eax,%ecx
  800364:	89 4d e0             	mov    %ecx,-0x20(%ebp)
		width = -1;
		precision = -1;
		lflag = 0;
		altflag = 0;
	reswitch:
		switch (ch = *(unsigned char *) fmt++) {
  800367:	8b 7d e4             	mov    -0x1c(%ebp),%edi
  80036a:	eb 8c                	jmp    8002f8 <vprintfmt+0x59>
  80036c:	8b 7d e4             	mov    -0x1c(%ebp),%edi
			if (width < 0)
				width = 0;
			goto reswitch;

		case '#':
			altflag = 1;
  80036f:	c7 45 d8 01 00 00 00 	movl   $0x1,-0x28(%ebp)
			goto reswitch;
  800376:	eb 80                	jmp    8002f8 <vprintfmt+0x59>
  800378:	8b 55 e4             	mov    -0x1c(%ebp),%edx
  80037b:	89 45 d0             	mov    %eax,-0x30(%ebp)

		process_precision:
			if (width < 0)
  80037e:	83 7d e0 00          	cmpl   $0x0,-0x20(%ebp)
  800382:	0f 89 70 ff ff ff    	jns    8002f8 <vprintfmt+0x59>
				width = precision, precision = -1;
  800388:	8b 45 d0             	mov    -0x30(%ebp),%eax
  80038b:	89 45 e0             	mov    %eax,-0x20(%ebp)
  80038e:	c7 45 d0 ff ff ff ff 	movl   $0xffffffff,-0x30(%ebp)
  800395:	e9 5e ff ff ff       	jmp    8002f8 <vprintfmt+0x59>
			goto reswitch;

		// long flag (doubled for long long)
		case 'l':
			lflag++;
  80039a:	83 c2 01             	add    $0x1,%edx
		width = -1;
		precision = -1;
		lflag = 0;
		altflag = 0;
	reswitch:
		switch (ch = *(unsigned char *) fmt++) {
  80039d:	8b 7d e4             	mov    -0x1c(%ebp),%edi
			goto reswitch;

		// long flag (doubled for long long)
		case 'l':
			lflag++;
			goto reswitch;
  8003a0:	e9 53 ff ff ff       	jmp    8002f8 <vprintfmt+0x59>

		// character
		case 'c':
			putch(va_arg(ap, int), putdat);
  8003a5:	8b 45 14             	mov    0x14(%ebp),%eax
  8003a8:	8d 50 04             	lea    0x4(%eax),%edx
  8003ab:	89 55 14             	mov    %edx,0x14(%ebp)
  8003ae:	83 ec 08             	sub    $0x8,%esp
  8003b1:	53                   	push   %ebx
  8003b2:	ff 30                	pushl  (%eax)
  8003b4:	ff d6                	call   *%esi
			break;
  8003b6:	83 c4 10             	add    $0x10,%esp
		width = -1;
		precision = -1;
		lflag = 0;
		altflag = 0;
	reswitch:
		switch (ch = *(unsigned char *) fmt++) {
  8003b9:	8b 7d e4             	mov    -0x1c(%ebp),%edi
			goto reswitch;

		// character
		case 'c':
			putch(va_arg(ap, int), putdat);
			break;
  8003bc:	e9 04 ff ff ff       	jmp    8002c5 <vprintfmt+0x26>

		// error message
		case 'e':
			err = va_arg(ap, int);
  8003c1:	8b 45 14             	mov    0x14(%ebp),%eax
  8003c4:	8d 50 04             	lea    0x4(%eax),%edx
  8003c7:	89 55 14             	mov    %edx,0x14(%ebp)
  8003ca:	8b 00                	mov    (%eax),%eax
  8003cc:	99                   	cltd   
  8003cd:	31 d0                	xor    %edx,%eax
  8003cf:	29 d0                	sub    %edx,%eax
			if (err < 0)
				err = -err;
			if (err >= MAXERROR || (p = error_string[err]) == NULL)
  8003d1:	83 f8 06             	cmp    $0x6,%eax
  8003d4:	7f 0b                	jg     8003e1 <vprintfmt+0x142>
  8003d6:	8b 14 85 a8 0f 80 00 	mov    0x800fa8(,%eax,4),%edx
  8003dd:	85 d2                	test   %edx,%edx
  8003df:	75 18                	jne    8003f9 <vprintfmt+0x15a>
				printfmt(putch, putdat, "error %d", err);
  8003e1:	50                   	push   %eax
  8003e2:	68 db 0d 80 00       	push   $0x800ddb
  8003e7:	53                   	push   %ebx
  8003e8:	56                   	push   %esi
  8003e9:	e8 94 fe ff ff       	call   800282 <printfmt>
  8003ee:	83 c4 10             	add    $0x10,%esp
		width = -1;
		precision = -1;
		lflag = 0;
		altflag = 0;
	reswitch:
		switch (ch = *(unsigned char *) fmt++) {
  8003f1:	8b 7d e4             	mov    -0x1c(%ebp),%edi
		case 'e':
			err = va_arg(ap, int);
			if (err < 0)
				err = -err;
			if (err >= MAXERROR || (p = error_string[err]) == NULL)
				printfmt(putch, putdat, "error %d", err);
  8003f4:	e9 cc fe ff ff       	jmp    8002c5 <vprintfmt+0x26>
			else
				printfmt(putch, putdat, "%s", p);
  8003f9:	52                   	push   %edx
  8003fa:	68 e4 0d 80 00       	push   $0x800de4
  8003ff:	53                   	push   %ebx
  800400:	56                   	push   %esi
  800401:	e8 7c fe ff ff       	call   800282 <printfmt>
  800406:	83 c4 10             	add    $0x10,%esp
		width = -1;
		precision = -1;
		lflag = 0;
		altflag = 0;
	reswitch:
		switch (ch = *(unsigned char *) fmt++) {
  800409:	8b 7d e4             	mov    -0x1c(%ebp),%edi
  80040c:	e9 b4 fe ff ff       	jmp    8002c5 <vprintfmt+0x26>
				printfmt(putch, putdat, "%s", p);
			break;

		// string
		case 's':
			if ((p = va_arg(ap, char *)) == NULL)
  800411:	8b 45 14             	mov    0x14(%ebp),%eax
  800414:	8d 50 04             	lea    0x4(%eax),%edx
  800417:	89 55 14             	mov    %edx,0x14(%ebp)
  80041a:	8b 38                	mov    (%eax),%edi
				p = "(null)";
  80041c:	85 ff                	test   %edi,%edi
  80041e:	b8 d4 0d 80 00       	mov    $0x800dd4,%eax
  800423:	0f 44 f8             	cmove  %eax,%edi
			if (width > 0 && padc != '-')
  800426:	83 7d e0 00          	cmpl   $0x0,-0x20(%ebp)
  80042a:	0f 8e 94 00 00 00    	jle    8004c4 <vprintfmt+0x225>
  800430:	80 7d d4 2d          	cmpb   $0x2d,-0x2c(%ebp)
  800434:	0f 84 98 00 00 00    	je     8004d2 <vprintfmt+0x233>
				for (width -= strnlen(p, precision); width > 0; width--)
  80043a:	83 ec 08             	sub    $0x8,%esp
  80043d:	ff 75 d0             	pushl  -0x30(%ebp)
  800440:	57                   	push   %edi
  800441:	e8 41 02 00 00       	call   800687 <strnlen>
  800446:	8b 4d e0             	mov    -0x20(%ebp),%ecx
  800449:	29 c1                	sub    %eax,%ecx
  80044b:	89 4d cc             	mov    %ecx,-0x34(%ebp)
  80044e:	83 c4 10             	add    $0x10,%esp
					putch(padc, putdat);
  800451:	0f be 45 d4          	movsbl -0x2c(%ebp),%eax
  800455:	89 45 e0             	mov    %eax,-0x20(%ebp)
  800458:	89 7d d4             	mov    %edi,-0x2c(%ebp)
  80045b:	89 cf                	mov    %ecx,%edi
		// string
		case 's':
			if ((p = va_arg(ap, char *)) == NULL)
				p = "(null)";
			if (width > 0 && padc != '-')
				for (width -= strnlen(p, precision); width > 0; width--)
  80045d:	eb 0f                	jmp    80046e <vprintfmt+0x1cf>
					putch(padc, putdat);
  80045f:	83 ec 08             	sub    $0x8,%esp
  800462:	53                   	push   %ebx
  800463:	ff 75 e0             	pushl  -0x20(%ebp)
  800466:	ff d6                	call   *%esi
		// string
		case 's':
			if ((p = va_arg(ap, char *)) == NULL)
				p = "(null)";
			if (width > 0 && padc != '-')
				for (width -= strnlen(p, precision); width > 0; width--)
  800468:	83 ef 01             	sub    $0x1,%edi
  80046b:	83 c4 10             	add    $0x10,%esp
  80046e:	85 ff                	test   %edi,%edi
  800470:	7f ed                	jg     80045f <vprintfmt+0x1c0>
  800472:	8b 7d d4             	mov    -0x2c(%ebp),%edi
  800475:	8b 4d cc             	mov    -0x34(%ebp),%ecx
  800478:	85 c9                	test   %ecx,%ecx
  80047a:	b8 00 00 00 00       	mov    $0x0,%eax
  80047f:	0f 49 c1             	cmovns %ecx,%eax
  800482:	29 c1                	sub    %eax,%ecx
  800484:	89 75 08             	mov    %esi,0x8(%ebp)
  800487:	8b 75 d0             	mov    -0x30(%ebp),%esi
  80048a:	89 5d 0c             	mov    %ebx,0xc(%ebp)
  80048d:	89 cb                	mov    %ecx,%ebx
  80048f:	eb 4d                	jmp    8004de <vprintfmt+0x23f>
					putch(padc, putdat);
			for (; (ch = *p++) != '\0' && (precision < 0 || --precision >= 0); width--)
				if (altflag && (ch < ' ' || ch > '~'))
  800491:	83 7d d8 00          	cmpl   $0x0,-0x28(%ebp)
  800495:	74 1b                	je     8004b2 <vprintfmt+0x213>
  800497:	0f be c0             	movsbl %al,%eax
  80049a:	83 e8 20             	sub    $0x20,%eax
  80049d:	83 f8 5e             	cmp    $0x5e,%eax
  8004a0:	76 10                	jbe    8004b2 <vprintfmt+0x213>
					putch('?', putdat);
  8004a2:	83 ec 08             	sub    $0x8,%esp
  8004a5:	ff 75 0c             	pushl  0xc(%ebp)
  8004a8:	6a 3f                	push   $0x3f
  8004aa:	ff 55 08             	call   *0x8(%ebp)
  8004ad:	83 c4 10             	add    $0x10,%esp
  8004b0:	eb 0d                	jmp    8004bf <vprintfmt+0x220>
				else
					putch(ch, putdat);
  8004b2:	83 ec 08             	sub    $0x8,%esp
  8004b5:	ff 75 0c             	pushl  0xc(%ebp)
  8004b8:	52                   	push   %edx
  8004b9:	ff 55 08             	call   *0x8(%ebp)
  8004bc:	83 c4 10             	add    $0x10,%esp
			if ((p = va_arg(ap, char *)) == NULL)
				p = "(null)";
			if (width > 0 && padc != '-')
				for (width -= strnlen(p, precision); width > 0; width--)
					putch(padc, putdat);
			for (; (ch = *p++) != '\0' && (precision < 0 || --precision >= 0); width--)
  8004bf:	83 eb 01             	sub    $0x1,%ebx
  8004c2:	eb 1a                	jmp    8004de <vprintfmt+0x23f>
  8004c4:	89 75 08             	mov    %esi,0x8(%ebp)
  8004c7:	8b 75 d0             	mov    -0x30(%ebp),%esi
  8004ca:	89 5d 0c             	mov    %ebx,0xc(%ebp)
  8004cd:	8b 5d e0             	mov    -0x20(%ebp),%ebx
  8004d0:	eb 0c                	jmp    8004de <vprintfmt+0x23f>
  8004d2:	89 75 08             	mov    %esi,0x8(%ebp)
  8004d5:	8b 75 d0             	mov    -0x30(%ebp),%esi
  8004d8:	89 5d 0c             	mov    %ebx,0xc(%ebp)
  8004db:	8b 5d e0             	mov    -0x20(%ebp),%ebx
  8004de:	83 c7 01             	add    $0x1,%edi
  8004e1:	0f b6 47 ff          	movzbl -0x1(%edi),%eax
  8004e5:	0f be d0             	movsbl %al,%edx
  8004e8:	85 d2                	test   %edx,%edx
  8004ea:	74 23                	je     80050f <vprintfmt+0x270>
  8004ec:	85 f6                	test   %esi,%esi
  8004ee:	78 a1                	js     800491 <vprintfmt+0x1f2>
  8004f0:	83 ee 01             	sub    $0x1,%esi
  8004f3:	79 9c                	jns    800491 <vprintfmt+0x1f2>
  8004f5:	89 df                	mov    %ebx,%edi
  8004f7:	8b 75 08             	mov    0x8(%ebp),%esi
  8004fa:	8b 5d 0c             	mov    0xc(%ebp),%ebx
  8004fd:	eb 18                	jmp    800517 <vprintfmt+0x278>
				if (altflag && (ch < ' ' || ch > '~'))
					putch('?', putdat);
				else
					putch(ch, putdat);
			for (; width > 0; width--)
				putch(' ', putdat);
  8004ff:	83 ec 08             	sub    $0x8,%esp
  800502:	53                   	push   %ebx
  800503:	6a 20                	push   $0x20
  800505:	ff d6                	call   *%esi
			for (; (ch = *p++) != '\0' && (precision < 0 || --precision >= 0); width--)
				if (altflag && (ch < ' ' || ch > '~'))
					putch('?', putdat);
				else
					putch(ch, putdat);
			for (; width > 0; width--)
  800507:	83 ef 01             	sub    $0x1,%edi
  80050a:	83 c4 10             	add    $0x10,%esp
  80050d:	eb 08                	jmp    800517 <vprintfmt+0x278>
  80050f:	89 df                	mov    %ebx,%edi
  800511:	8b 75 08             	mov    0x8(%ebp),%esi
  800514:	8b 5d 0c             	mov    0xc(%ebp),%ebx
  800517:	85 ff                	test   %edi,%edi
  800519:	7f e4                	jg     8004ff <vprintfmt+0x260>
		width = -1;
		precision = -1;
		lflag = 0;
		altflag = 0;
	reswitch:
		switch (ch = *(unsigned char *) fmt++) {
  80051b:	8b 7d e4             	mov    -0x1c(%ebp),%edi
  80051e:	e9 a2 fd ff ff       	jmp    8002c5 <vprintfmt+0x26>
				putch(' ', putdat);
			break;

		// (signed) decimal
		case 'd':
			num = getint(&ap, lflag);
  800523:	8d 45 14             	lea    0x14(%ebp),%eax
  800526:	e8 08 fd ff ff       	call   800233 <getint>
  80052b:	89 45 d8             	mov    %eax,-0x28(%ebp)
  80052e:	89 55 dc             	mov    %edx,-0x24(%ebp)
			if ((long long) num < 0) {
				putch('-', putdat);
				num = -(long long) num;
			}
			base = 10;
  800531:	b9 0a 00 00 00       	mov    $0xa,%ecx
			break;

		// (signed) decimal
		case 'd':
			num = getint(&ap, lflag);
			if ((long long) num < 0) {
  800536:	83 7d dc 00          	cmpl   $0x0,-0x24(%ebp)
  80053a:	79 74                	jns    8005b0 <vprintfmt+0x311>
				putch('-', putdat);
  80053c:	83 ec 08             	sub    $0x8,%esp
  80053f:	53                   	push   %ebx
  800540:	6a 2d                	push   $0x2d
  800542:	ff d6                	call   *%esi
				num = -(long long) num;
  800544:	8b 45 d8             	mov    -0x28(%ebp),%eax
  800547:	8b 55 dc             	mov    -0x24(%ebp),%edx
  80054a:	f7 d8                	neg    %eax
  80054c:	83 d2 00             	adc    $0x0,%edx
  80054f:	f7 da                	neg    %edx
  800551:	83 c4 10             	add    $0x10,%esp
			}
			base = 10;
  800554:	b9 0a 00 00 00       	mov    $0xa,%ecx
  800559:	eb 55                	jmp    8005b0 <vprintfmt+0x311>
			goto number;

		// unsigned decimal
		case 'u':
			num = getuint(&ap, lflag);
  80055b:	8d 45 14             	lea    0x14(%ebp),%eax
  80055e:	e8 96 fc ff ff       	call   8001f9 <getuint>
			base = 10;
  800563:	b9 0a 00 00 00       	mov    $0xa,%ecx
			goto number;
  800568:	eb 46                	jmp    8005b0 <vprintfmt+0x311>

		// (unsigned) octal
		case 'o':
			num = getuint(&ap, lflag);
  80056a:	8d 45 14             	lea    0x14(%ebp),%eax
  80056d:	e8 87 fc ff ff       	call   8001f9 <getuint>
			base = 8;
  800572:	b9 08 00 00 00       	mov    $0x8,%ecx
			goto number;
  800577:	eb 37                	jmp    8005b0 <vprintfmt+0x311>

		// pointer
		case 'p':
			putch('0', putdat);
  800579:	83 ec 08             	sub    $0x8,%esp
  80057c:	53                   	push   %ebx
  80057d:	6a 30                	push   $0x30
  80057f:	ff d6                	call   *%esi
			putch('x', putdat);
  800581:	83 c4 08             	add    $0x8,%esp
  800584:	53                   	push   %ebx
  800585:	6a 78                	push   $0x78
  800587:	ff d6                	call   *%esi
			num = (unsigned long long)
				(uintptr_t) va_arg(ap, void *);
  800589:	8b 45 14             	mov    0x14(%ebp),%eax
  80058c:	8d 50 04             	lea    0x4(%eax),%edx
  80058f:	89 55 14             	mov    %edx,0x14(%ebp)

		// pointer
		case 'p':
			putch('0', putdat);
			putch('x', putdat);
			num = (unsigned long long)
  800592:	8b 00                	mov    (%eax),%eax
  800594:	ba 00 00 00 00       	mov    $0x0,%edx
				(uintptr_t) va_arg(ap, void *);
			base = 16;
			goto number;
  800599:	83 c4 10             	add    $0x10,%esp
		case 'p':
			putch('0', putdat);
			putch('x', putdat);
			num = (unsigned long long)
				(uintptr_t) va_arg(ap, void *);
			base = 16;
  80059c:	b9 10 00 00 00       	mov    $0x10,%ecx
			goto number;
  8005a1:	eb 0d                	jmp    8005b0 <vprintfmt+0x311>

		// (unsigned) hexadecimal
		case 'x':
			num = getuint(&ap, lflag);
  8005a3:	8d 45 14             	lea    0x14(%ebp),%eax
  8005a6:	e8 4e fc ff ff       	call   8001f9 <getuint>
			base = 16;
  8005ab:	b9 10 00 00 00       	mov    $0x10,%ecx
		number:
			printnum(putch, putdat, num, base, width, padc);
  8005b0:	83 ec 0c             	sub    $0xc,%esp
  8005b3:	0f be 7d d4          	movsbl -0x2c(%ebp),%edi
  8005b7:	57                   	push   %edi
  8005b8:	ff 75 e0             	pushl  -0x20(%ebp)
  8005bb:	51                   	push   %ecx
  8005bc:	52                   	push   %edx
  8005bd:	50                   	push   %eax
  8005be:	89 da                	mov    %ebx,%edx
  8005c0:	89 f0                	mov    %esi,%eax
  8005c2:	e8 83 fb ff ff       	call   80014a <printnum>
			break;
  8005c7:	83 c4 20             	add    $0x20,%esp
  8005ca:	8b 7d e4             	mov    -0x1c(%ebp),%edi
  8005cd:	e9 f3 fc ff ff       	jmp    8002c5 <vprintfmt+0x26>

		// escaped '%' character
		case '%':
			putch(ch, putdat);
  8005d2:	83 ec 08             	sub    $0x8,%esp
  8005d5:	53                   	push   %ebx
  8005d6:	51                   	push   %ecx
  8005d7:	ff d6                	call   *%esi
			break;
  8005d9:	83 c4 10             	add    $0x10,%esp
		width = -1;
		precision = -1;
		lflag = 0;
		altflag = 0;
	reswitch:
		switch (ch = *(unsigned char *) fmt++) {
  8005dc:	8b 7d e4             	mov    -0x1c(%ebp),%edi
			break;

		// escaped '%' character
		case '%':
			putch(ch, putdat);
			break;
  8005df:	e9 e1 fc ff ff       	jmp    8002c5 <vprintfmt+0x26>

		// unrecognized escape sequence - just print it literally
		default:
			putch('%', putdat);
  8005e4:	83 ec 08             	sub    $0x8,%esp
  8005e7:	53                   	push   %ebx
  8005e8:	6a 25                	push   $0x25
  8005ea:	ff d6                	call   *%esi
			for (fmt--; fmt[-1] != '%'; fmt--)
  8005ec:	83 c4 10             	add    $0x10,%esp
  8005ef:	eb 03                	jmp    8005f4 <vprintfmt+0x355>
  8005f1:	83 ef 01             	sub    $0x1,%edi
  8005f4:	80 7f ff 25          	cmpb   $0x25,-0x1(%edi)
  8005f8:	75 f7                	jne    8005f1 <vprintfmt+0x352>
  8005fa:	e9 c6 fc ff ff       	jmp    8002c5 <vprintfmt+0x26>
				/* do nothing */;
			break;
		}
	}
}
  8005ff:	8d 65 f4             	lea    -0xc(%ebp),%esp
  800602:	5b                   	pop    %ebx
  800603:	5e                   	pop    %esi
  800604:	5f                   	pop    %edi
  800605:	5d                   	pop    %ebp
  800606:	c3                   	ret    

00800607 <vsnprintf>:
		*b->buf++ = ch;
}

int
vsnprintf(char *buf, int n, const char *fmt, va_list ap)
{
  800607:	55                   	push   %ebp
  800608:	89 e5                	mov    %esp,%ebp
  80060a:	83 ec 18             	sub    $0x18,%esp
  80060d:	8b 45 08             	mov    0x8(%ebp),%eax
  800610:	8b 55 0c             	mov    0xc(%ebp),%edx
	struct sprintbuf b = {buf, buf+n-1, 0};
  800613:	89 45 ec             	mov    %eax,-0x14(%ebp)
  800616:	8d 4c 10 ff          	lea    -0x1(%eax,%edx,1),%ecx
  80061a:	89 4d f0             	mov    %ecx,-0x10(%ebp)
  80061d:	c7 45 f4 00 00 00 00 	movl   $0x0,-0xc(%ebp)

	if (buf == NULL || n < 1)
  800624:	85 c0                	test   %eax,%eax
  800626:	74 26                	je     80064e <vsnprintf+0x47>
  800628:	85 d2                	test   %edx,%edx
  80062a:	7e 22                	jle    80064e <vsnprintf+0x47>
		return -E_INVAL;

	// print the string to the buffer
	vprintfmt((void*)sprintputch, &b, fmt, ap);
  80062c:	ff 75 14             	pushl  0x14(%ebp)
  80062f:	ff 75 10             	pushl  0x10(%ebp)
  800632:	8d 45 ec             	lea    -0x14(%ebp),%eax
  800635:	50                   	push   %eax
  800636:	68 65 02 80 00       	push   $0x800265
  80063b:	e8 5f fc ff ff       	call   80029f <vprintfmt>

	// null terminate the buffer
	*b.buf = '\0';
  800640:	8b 45 ec             	mov    -0x14(%ebp),%eax
  800643:	c6 00 00             	movb   $0x0,(%eax)

	return b.cnt;
  800646:	8b 45 f4             	mov    -0xc(%ebp),%eax
  800649:	83 c4 10             	add    $0x10,%esp
  80064c:	eb 05                	jmp    800653 <vsnprintf+0x4c>
vsnprintf(char *buf, int n, const char *fmt, va_list ap)
{
	struct sprintbuf b = {buf, buf+n-1, 0};

	if (buf == NULL || n < 1)
		return -E_INVAL;
  80064e:	b8 fd ff ff ff       	mov    $0xfffffffd,%eax

	// null terminate the buffer
	*b.buf = '\0';

	return b.cnt;
}
  800653:	c9                   	leave  
  800654:	c3                   	ret    

00800655 <snprintf>:

int
snprintf(char *buf, int n, const char *fmt, ...)
{
  800655:	55                   	push   %ebp
  800656:	89 e5                	mov    %esp,%ebp
  800658:	83 ec 08             	sub    $0x8,%esp
	va_list ap;
	int rc;

	va_start(ap, fmt);
  80065b:	8d 45 14             	lea    0x14(%ebp),%eax
	rc = vsnprintf(buf, n, fmt, ap);
  80065e:	50                   	push   %eax
  80065f:	ff 75 10             	pushl  0x10(%ebp)
  800662:	ff 75 0c             	pushl  0xc(%ebp)
  800665:	ff 75 08             	pushl  0x8(%ebp)
  800668:	e8 9a ff ff ff       	call   800607 <vsnprintf>
	va_end(ap);

	return rc;
}
  80066d:	c9                   	leave  
  80066e:	c3                   	ret    

0080066f <strlen>:
// Primespipe runs 3x faster this way.
#define ASM 1

int
strlen(const char *s)
{
  80066f:	55                   	push   %ebp
  800670:	89 e5                	mov    %esp,%ebp
  800672:	8b 55 08             	mov    0x8(%ebp),%edx
	int n;

	for (n = 0; *s != '\0'; s++)
  800675:	b8 00 00 00 00       	mov    $0x0,%eax
  80067a:	eb 03                	jmp    80067f <strlen+0x10>
		n++;
  80067c:	83 c0 01             	add    $0x1,%eax
int
strlen(const char *s)
{
	int n;

	for (n = 0; *s != '\0'; s++)
  80067f:	80 3c 02 00          	cmpb   $0x0,(%edx,%eax,1)
  800683:	75 f7                	jne    80067c <strlen+0xd>
		n++;
	return n;
}
  800685:	5d                   	pop    %ebp
  800686:	c3                   	ret    

00800687 <strnlen>:

int
strnlen(const char *s, size_t size)
{
  800687:	55                   	push   %ebp
  800688:	89 e5                	mov    %esp,%ebp
  80068a:	8b 4d 08             	mov    0x8(%ebp),%ecx
  80068d:	8b 45 0c             	mov    0xc(%ebp),%eax
	int n;

	for (n = 0; size > 0 && *s != '\0'; s++, size--)
  800690:	ba 00 00 00 00       	mov    $0x0,%edx
  800695:	eb 03                	jmp    80069a <strnlen+0x13>
		n++;
  800697:	83 c2 01             	add    $0x1,%edx
int
strnlen(const char *s, size_t size)
{
	int n;

	for (n = 0; size > 0 && *s != '\0'; s++, size--)
  80069a:	39 c2                	cmp    %eax,%edx
  80069c:	74 08                	je     8006a6 <strnlen+0x1f>
  80069e:	80 3c 11 00          	cmpb   $0x0,(%ecx,%edx,1)
  8006a2:	75 f3                	jne    800697 <strnlen+0x10>
  8006a4:	89 d0                	mov    %edx,%eax
		n++;
	return n;
}
  8006a6:	5d                   	pop    %ebp
  8006a7:	c3                   	ret    

008006a8 <strcpy>:

char *
strcpy(char *dst, const char *src)
{
  8006a8:	55                   	push   %ebp
  8006a9:	89 e5                	mov    %esp,%ebp
  8006ab:	53                   	push   %ebx
  8006ac:	8b 45 08             	mov    0x8(%ebp),%eax
  8006af:	8b 4d 0c             	mov    0xc(%ebp),%ecx
	char *ret;

	ret = dst;
	while ((*dst++ = *src++) != '\0')
  8006b2:	89 c2                	mov    %eax,%edx
  8006b4:	83 c2 01             	add    $0x1,%edx
  8006b7:	83 c1 01             	add    $0x1,%ecx
  8006ba:	0f b6 59 ff          	movzbl -0x1(%ecx),%ebx
  8006be:	88 5a ff             	mov    %bl,-0x1(%edx)
  8006c1:	84 db                	test   %bl,%bl
  8006c3:	75 ef                	jne    8006b4 <strcpy+0xc>
		/* do nothing */;
	return ret;
}
  8006c5:	5b                   	pop    %ebx
  8006c6:	5d                   	pop    %ebp
  8006c7:	c3                   	ret    

008006c8 <strcat>:

char *
strcat(char *dst, const char *src)
{
  8006c8:	55                   	push   %ebp
  8006c9:	89 e5                	mov    %esp,%ebp
  8006cb:	53                   	push   %ebx
  8006cc:	8b 5d 08             	mov    0x8(%ebp),%ebx
	int len = strlen(dst);
  8006cf:	53                   	push   %ebx
  8006d0:	e8 9a ff ff ff       	call   80066f <strlen>
  8006d5:	83 c4 04             	add    $0x4,%esp
	strcpy(dst + len, src);
  8006d8:	ff 75 0c             	pushl  0xc(%ebp)
  8006db:	01 d8                	add    %ebx,%eax
  8006dd:	50                   	push   %eax
  8006de:	e8 c5 ff ff ff       	call   8006a8 <strcpy>
	return dst;
}
  8006e3:	89 d8                	mov    %ebx,%eax
  8006e5:	8b 5d fc             	mov    -0x4(%ebp),%ebx
  8006e8:	c9                   	leave  
  8006e9:	c3                   	ret    

008006ea <strncpy>:

char *
strncpy(char *dst, const char *src, size_t size) {
  8006ea:	55                   	push   %ebp
  8006eb:	89 e5                	mov    %esp,%ebp
  8006ed:	56                   	push   %esi
  8006ee:	53                   	push   %ebx
  8006ef:	8b 75 08             	mov    0x8(%ebp),%esi
  8006f2:	8b 4d 0c             	mov    0xc(%ebp),%ecx
  8006f5:	89 f3                	mov    %esi,%ebx
  8006f7:	03 5d 10             	add    0x10(%ebp),%ebx
	size_t i;
	char *ret;

	ret = dst;
	for (i = 0; i < size; i++) {
  8006fa:	89 f2                	mov    %esi,%edx
  8006fc:	eb 0f                	jmp    80070d <strncpy+0x23>
		*dst++ = *src;
  8006fe:	83 c2 01             	add    $0x1,%edx
  800701:	0f b6 01             	movzbl (%ecx),%eax
  800704:	88 42 ff             	mov    %al,-0x1(%edx)
		// If strlen(src) < size, null-pad 'dst' out to 'size' chars
		if (*src != '\0')
			src++;
  800707:	80 39 01             	cmpb   $0x1,(%ecx)
  80070a:	83 d9 ff             	sbb    $0xffffffff,%ecx
strncpy(char *dst, const char *src, size_t size) {
	size_t i;
	char *ret;

	ret = dst;
	for (i = 0; i < size; i++) {
  80070d:	39 da                	cmp    %ebx,%edx
  80070f:	75 ed                	jne    8006fe <strncpy+0x14>
		// If strlen(src) < size, null-pad 'dst' out to 'size' chars
		if (*src != '\0')
			src++;
	}
	return ret;
}
  800711:	89 f0                	mov    %esi,%eax
  800713:	5b                   	pop    %ebx
  800714:	5e                   	pop    %esi
  800715:	5d                   	pop    %ebp
  800716:	c3                   	ret    

00800717 <strlcpy>:

size_t
strlcpy(char *dst, const char *src, size_t size)
{
  800717:	55                   	push   %ebp
  800718:	89 e5                	mov    %esp,%ebp
  80071a:	56                   	push   %esi
  80071b:	53                   	push   %ebx
  80071c:	8b 75 08             	mov    0x8(%ebp),%esi
  80071f:	8b 4d 0c             	mov    0xc(%ebp),%ecx
  800722:	8b 55 10             	mov    0x10(%ebp),%edx
  800725:	89 f0                	mov    %esi,%eax
	char *dst_in;

	dst_in = dst;
	if (size > 0) {
  800727:	85 d2                	test   %edx,%edx
  800729:	74 21                	je     80074c <strlcpy+0x35>
  80072b:	8d 44 16 ff          	lea    -0x1(%esi,%edx,1),%eax
  80072f:	89 f2                	mov    %esi,%edx
  800731:	eb 09                	jmp    80073c <strlcpy+0x25>
		while (--size > 0 && *src != '\0')
			*dst++ = *src++;
  800733:	83 c2 01             	add    $0x1,%edx
  800736:	83 c1 01             	add    $0x1,%ecx
  800739:	88 5a ff             	mov    %bl,-0x1(%edx)
{
	char *dst_in;

	dst_in = dst;
	if (size > 0) {
		while (--size > 0 && *src != '\0')
  80073c:	39 c2                	cmp    %eax,%edx
  80073e:	74 09                	je     800749 <strlcpy+0x32>
  800740:	0f b6 19             	movzbl (%ecx),%ebx
  800743:	84 db                	test   %bl,%bl
  800745:	75 ec                	jne    800733 <strlcpy+0x1c>
  800747:	89 d0                	mov    %edx,%eax
			*dst++ = *src++;
		*dst = '\0';
  800749:	c6 00 00             	movb   $0x0,(%eax)
	}
	return dst - dst_in;
  80074c:	29 f0                	sub    %esi,%eax
}
  80074e:	5b                   	pop    %ebx
  80074f:	5e                   	pop    %esi
  800750:	5d                   	pop    %ebp
  800751:	c3                   	ret    

00800752 <strcmp>:

int
strcmp(const char *p, const char *q)
{
  800752:	55                   	push   %ebp
  800753:	89 e5                	mov    %esp,%ebp
  800755:	8b 4d 08             	mov    0x8(%ebp),%ecx
  800758:	8b 55 0c             	mov    0xc(%ebp),%edx
	while (*p && *p == *q)
  80075b:	eb 06                	jmp    800763 <strcmp+0x11>
		p++, q++;
  80075d:	83 c1 01             	add    $0x1,%ecx
  800760:	83 c2 01             	add    $0x1,%edx
}

int
strcmp(const char *p, const char *q)
{
	while (*p && *p == *q)
  800763:	0f b6 01             	movzbl (%ecx),%eax
  800766:	84 c0                	test   %al,%al
  800768:	74 04                	je     80076e <strcmp+0x1c>
  80076a:	3a 02                	cmp    (%edx),%al
  80076c:	74 ef                	je     80075d <strcmp+0xb>
		p++, q++;
	return (int) ((unsigned char) *p - (unsigned char) *q);
  80076e:	0f b6 c0             	movzbl %al,%eax
  800771:	0f b6 12             	movzbl (%edx),%edx
  800774:	29 d0                	sub    %edx,%eax
}
  800776:	5d                   	pop    %ebp
  800777:	c3                   	ret    

00800778 <strncmp>:

int
strncmp(const char *p, const char *q, size_t n)
{
  800778:	55                   	push   %ebp
  800779:	89 e5                	mov    %esp,%ebp
  80077b:	53                   	push   %ebx
  80077c:	8b 45 08             	mov    0x8(%ebp),%eax
  80077f:	8b 55 0c             	mov    0xc(%ebp),%edx
  800782:	89 c3                	mov    %eax,%ebx
  800784:	03 5d 10             	add    0x10(%ebp),%ebx
	while (n > 0 && *p && *p == *q)
  800787:	eb 06                	jmp    80078f <strncmp+0x17>
		n--, p++, q++;
  800789:	83 c0 01             	add    $0x1,%eax
  80078c:	83 c2 01             	add    $0x1,%edx
}

int
strncmp(const char *p, const char *q, size_t n)
{
	while (n > 0 && *p && *p == *q)
  80078f:	39 d8                	cmp    %ebx,%eax
  800791:	74 15                	je     8007a8 <strncmp+0x30>
  800793:	0f b6 08             	movzbl (%eax),%ecx
  800796:	84 c9                	test   %cl,%cl
  800798:	74 04                	je     80079e <strncmp+0x26>
  80079a:	3a 0a                	cmp    (%edx),%cl
  80079c:	74 eb                	je     800789 <strncmp+0x11>
		n--, p++, q++;
	if (n == 0)
		return 0;
	else
		return (int) ((unsigned char) *p - (unsigned char) *q);
  80079e:	0f b6 00             	movzbl (%eax),%eax
  8007a1:	0f b6 12             	movzbl (%edx),%edx
  8007a4:	29 d0                	sub    %edx,%eax
  8007a6:	eb 05                	jmp    8007ad <strncmp+0x35>
strncmp(const char *p, const char *q, size_t n)
{
	while (n > 0 && *p && *p == *q)
		n--, p++, q++;
	if (n == 0)
		return 0;
  8007a8:	b8 00 00 00 00       	mov    $0x0,%eax
	else
		return (int) ((unsigned char) *p - (unsigned char) *q);
}
  8007ad:	5b                   	pop    %ebx
  8007ae:	5d                   	pop    %ebp
  8007af:	c3                   	ret    

008007b0 <strchr>:

// Return a pointer to the first occurrence of 'c' in 's',
// or a null pointer if the string has no 'c'.
char *
strchr(const char *s, char c)
{
  8007b0:	55                   	push   %ebp
  8007b1:	89 e5                	mov    %esp,%ebp
  8007b3:	8b 45 08             	mov    0x8(%ebp),%eax
  8007b6:	0f b6 4d 0c          	movzbl 0xc(%ebp),%ecx
	for (; *s; s++)
  8007ba:	eb 07                	jmp    8007c3 <strchr+0x13>
		if (*s == c)
  8007bc:	38 ca                	cmp    %cl,%dl
  8007be:	74 0f                	je     8007cf <strchr+0x1f>
// Return a pointer to the first occurrence of 'c' in 's',
// or a null pointer if the string has no 'c'.
char *
strchr(const char *s, char c)
{
	for (; *s; s++)
  8007c0:	83 c0 01             	add    $0x1,%eax
  8007c3:	0f b6 10             	movzbl (%eax),%edx
  8007c6:	84 d2                	test   %dl,%dl
  8007c8:	75 f2                	jne    8007bc <strchr+0xc>
		if (*s == c)
			return (char *) s;
	return 0;
  8007ca:	b8 00 00 00 00       	mov    $0x0,%eax
}
  8007cf:	5d                   	pop    %ebp
  8007d0:	c3                   	ret    

008007d1 <strfind>:

// Return a pointer to the first occurrence of 'c' in 's',
// or a pointer to the string-ending null character if the string has no 'c'.
char *
strfind(const char *s, char c)
{
  8007d1:	55                   	push   %ebp
  8007d2:	89 e5                	mov    %esp,%ebp
  8007d4:	8b 45 08             	mov    0x8(%ebp),%eax
  8007d7:	0f b6 4d 0c          	movzbl 0xc(%ebp),%ecx
	for (; *s; s++)
  8007db:	eb 03                	jmp    8007e0 <strfind+0xf>
  8007dd:	83 c0 01             	add    $0x1,%eax
  8007e0:	0f b6 10             	movzbl (%eax),%edx
		if (*s == c)
  8007e3:	38 ca                	cmp    %cl,%dl
  8007e5:	74 04                	je     8007eb <strfind+0x1a>
  8007e7:	84 d2                	test   %dl,%dl
  8007e9:	75 f2                	jne    8007dd <strfind+0xc>
			break;
	return (char *) s;
}
  8007eb:	5d                   	pop    %ebp
  8007ec:	c3                   	ret    

008007ed <memset>:

#if ASM
void *
memset(void *v, int c, size_t n)
{
  8007ed:	55                   	push   %ebp
  8007ee:	89 e5                	mov    %esp,%ebp
  8007f0:	57                   	push   %edi
  8007f1:	56                   	push   %esi
  8007f2:	53                   	push   %ebx
  8007f3:	8b 55 08             	mov    0x8(%ebp),%edx
  8007f6:	8b 4d 10             	mov    0x10(%ebp),%ecx
	char *p = v;

	if (n == 0)
  8007f9:	85 c9                	test   %ecx,%ecx
  8007fb:	74 37                	je     800834 <memset+0x47>
		return v;
	if ((int)v%4 == 0 && n%4 == 0) {
  8007fd:	f6 c2 03             	test   $0x3,%dl
  800800:	75 2a                	jne    80082c <memset+0x3f>
  800802:	f6 c1 03             	test   $0x3,%cl
  800805:	75 25                	jne    80082c <memset+0x3f>
		c &= 0xFF;
  800807:	0f b6 5d 0c          	movzbl 0xc(%ebp),%ebx
		c = (c<<24)|(c<<16)|(c<<8)|c;
  80080b:	89 df                	mov    %ebx,%edi
  80080d:	c1 e7 08             	shl    $0x8,%edi
  800810:	89 de                	mov    %ebx,%esi
  800812:	c1 e6 18             	shl    $0x18,%esi
  800815:	89 d8                	mov    %ebx,%eax
  800817:	c1 e0 10             	shl    $0x10,%eax
  80081a:	09 f0                	or     %esi,%eax
  80081c:	09 c3                	or     %eax,%ebx
		asm volatile("cld; rep stosl\n"
			: "=D" (p), "=c" (n)
			: "D" (p), "a" (c), "c" (n/4)
  80081e:	c1 e9 02             	shr    $0x2,%ecx
	if (n == 0)
		return v;
	if ((int)v%4 == 0 && n%4 == 0) {
		c &= 0xFF;
		c = (c<<24)|(c<<16)|(c<<8)|c;
		asm volatile("cld; rep stosl\n"
  800821:	89 f8                	mov    %edi,%eax
  800823:	09 d8                	or     %ebx,%eax
  800825:	89 d7                	mov    %edx,%edi
  800827:	fc                   	cld    
  800828:	f3 ab                	rep stos %eax,%es:(%edi)
  80082a:	eb 08                	jmp    800834 <memset+0x47>
			: "=D" (p), "=c" (n)
			: "D" (p), "a" (c), "c" (n/4)
			: "cc", "memory");
	} else
		asm volatile("cld; rep stosb\n"
  80082c:	89 d7                	mov    %edx,%edi
  80082e:	8b 45 0c             	mov    0xc(%ebp),%eax
  800831:	fc                   	cld    
  800832:	f3 aa                	rep stos %al,%es:(%edi)
			: "=D" (p), "=c" (n)
			: "0" (p), "a" (c), "1" (n)
			: "cc", "memory");
	return v;
}
  800834:	89 d0                	mov    %edx,%eax
  800836:	5b                   	pop    %ebx
  800837:	5e                   	pop    %esi
  800838:	5f                   	pop    %edi
  800839:	5d                   	pop    %ebp
  80083a:	c3                   	ret    

0080083b <memmove>:

void *
memmove(void *dst, const void *src, size_t n)
{
  80083b:	55                   	push   %ebp
  80083c:	89 e5                	mov    %esp,%ebp
  80083e:	57                   	push   %edi
  80083f:	56                   	push   %esi
  800840:	8b 45 08             	mov    0x8(%ebp),%eax
  800843:	8b 75 0c             	mov    0xc(%ebp),%esi
  800846:	8b 4d 10             	mov    0x10(%ebp),%ecx
	const char *s;
	char *d;

	s = src;
	d = dst;
	if (s < d && s + n > d) {
  800849:	39 c6                	cmp    %eax,%esi
  80084b:	73 35                	jae    800882 <memmove+0x47>
  80084d:	8d 14 0e             	lea    (%esi,%ecx,1),%edx
  800850:	39 d0                	cmp    %edx,%eax
  800852:	73 2e                	jae    800882 <memmove+0x47>
		s += n;
		d += n;
  800854:	8d 3c 08             	lea    (%eax,%ecx,1),%edi
		if ((int)s%4 == 0 && (int)d%4 == 0 && n%4 == 0)
  800857:	89 d6                	mov    %edx,%esi
  800859:	09 fe                	or     %edi,%esi
  80085b:	f7 c6 03 00 00 00    	test   $0x3,%esi
  800861:	75 13                	jne    800876 <memmove+0x3b>
  800863:	f6 c1 03             	test   $0x3,%cl
  800866:	75 0e                	jne    800876 <memmove+0x3b>
			asm volatile("std; rep movsl\n"
  800868:	83 ef 04             	sub    $0x4,%edi
  80086b:	8d 72 fc             	lea    -0x4(%edx),%esi
  80086e:	c1 e9 02             	shr    $0x2,%ecx
  800871:	fd                   	std    
  800872:	f3 a5                	rep movsl %ds:(%esi),%es:(%edi)
  800874:	eb 09                	jmp    80087f <memmove+0x44>
				:: "D" (d-4), "S" (s-4), "c" (n/4) : "cc", "memory");
		else
			asm volatile("std; rep movsb\n"
  800876:	83 ef 01             	sub    $0x1,%edi
  800879:	8d 72 ff             	lea    -0x1(%edx),%esi
  80087c:	fd                   	std    
  80087d:	f3 a4                	rep movsb %ds:(%esi),%es:(%edi)
				:: "D" (d-1), "S" (s-1), "c" (n) : "cc", "memory");
		// Some versions of GCC rely on DF being clear
		asm volatile("cld" ::: "cc");
  80087f:	fc                   	cld    
  800880:	eb 1d                	jmp    80089f <memmove+0x64>
	} else {
		if ((int)s%4 == 0 && (int)d%4 == 0 && n%4 == 0)
  800882:	89 f2                	mov    %esi,%edx
  800884:	09 c2                	or     %eax,%edx
  800886:	f6 c2 03             	test   $0x3,%dl
  800889:	75 0f                	jne    80089a <memmove+0x5f>
  80088b:	f6 c1 03             	test   $0x3,%cl
  80088e:	75 0a                	jne    80089a <memmove+0x5f>
			asm volatile("cld; rep movsl\n"
  800890:	c1 e9 02             	shr    $0x2,%ecx
  800893:	89 c7                	mov    %eax,%edi
  800895:	fc                   	cld    
  800896:	f3 a5                	rep movsl %ds:(%esi),%es:(%edi)
  800898:	eb 05                	jmp    80089f <memmove+0x64>
				:: "D" (d), "S" (s), "c" (n/4) : "cc", "memory");
		else
			asm volatile("cld; rep movsb\n"
  80089a:	89 c7                	mov    %eax,%edi
  80089c:	fc                   	cld    
  80089d:	f3 a4                	rep movsb %ds:(%esi),%es:(%edi)
				:: "D" (d), "S" (s), "c" (n) : "cc", "memory");
	}
	return dst;
}
  80089f:	5e                   	pop    %esi
  8008a0:	5f                   	pop    %edi
  8008a1:	5d                   	pop    %ebp
  8008a2:	c3                   	ret    

008008a3 <memcpy>:
}
#endif

void *
memcpy(void *dst, const void *src, size_t n)
{
  8008a3:	55                   	push   %ebp
  8008a4:	89 e5                	mov    %esp,%ebp
	return memmove(dst, src, n);
  8008a6:	ff 75 10             	pushl  0x10(%ebp)
  8008a9:	ff 75 0c             	pushl  0xc(%ebp)
  8008ac:	ff 75 08             	pushl  0x8(%ebp)
  8008af:	e8 87 ff ff ff       	call   80083b <memmove>
}
  8008b4:	c9                   	leave  
  8008b5:	c3                   	ret    

008008b6 <memcmp>:

int
memcmp(const void *v1, const void *v2, size_t n)
{
  8008b6:	55                   	push   %ebp
  8008b7:	89 e5                	mov    %esp,%ebp
  8008b9:	56                   	push   %esi
  8008ba:	53                   	push   %ebx
  8008bb:	8b 45 08             	mov    0x8(%ebp),%eax
  8008be:	8b 55 0c             	mov    0xc(%ebp),%edx
  8008c1:	89 c6                	mov    %eax,%esi
  8008c3:	03 75 10             	add    0x10(%ebp),%esi
	const uint8_t *s1 = (const uint8_t *) v1;
	const uint8_t *s2 = (const uint8_t *) v2;

	while (n-- > 0) {
  8008c6:	eb 1a                	jmp    8008e2 <memcmp+0x2c>
		if (*s1 != *s2)
  8008c8:	0f b6 08             	movzbl (%eax),%ecx
  8008cb:	0f b6 1a             	movzbl (%edx),%ebx
  8008ce:	38 d9                	cmp    %bl,%cl
  8008d0:	74 0a                	je     8008dc <memcmp+0x26>
			return (int) *s1 - (int) *s2;
  8008d2:	0f b6 c1             	movzbl %cl,%eax
  8008d5:	0f b6 db             	movzbl %bl,%ebx
  8008d8:	29 d8                	sub    %ebx,%eax
  8008da:	eb 0f                	jmp    8008eb <memcmp+0x35>
		s1++, s2++;
  8008dc:	83 c0 01             	add    $0x1,%eax
  8008df:	83 c2 01             	add    $0x1,%edx
memcmp(const void *v1, const void *v2, size_t n)
{
	const uint8_t *s1 = (const uint8_t *) v1;
	const uint8_t *s2 = (const uint8_t *) v2;

	while (n-- > 0) {
  8008e2:	39 f0                	cmp    %esi,%eax
  8008e4:	75 e2                	jne    8008c8 <memcmp+0x12>
		if (*s1 != *s2)
			return (int) *s1 - (int) *s2;
		s1++, s2++;
	}

	return 0;
  8008e6:	b8 00 00 00 00       	mov    $0x0,%eax
}
  8008eb:	5b                   	pop    %ebx
  8008ec:	5e                   	pop    %esi
  8008ed:	5d                   	pop    %ebp
  8008ee:	c3                   	ret    

008008ef <memfind>:

void *
memfind(const void *s, int c, size_t n)
{
  8008ef:	55                   	push   %ebp
  8008f0:	89 e5                	mov    %esp,%ebp
  8008f2:	8b 45 08             	mov    0x8(%ebp),%eax
  8008f5:	8b 4d 0c             	mov    0xc(%ebp),%ecx
	const void *ends = (const char *) s + n;
  8008f8:	89 c2                	mov    %eax,%edx
  8008fa:	03 55 10             	add    0x10(%ebp),%edx
	for (; s < ends; s++)
  8008fd:	eb 07                	jmp    800906 <memfind+0x17>
		if (*(const unsigned char *) s == (unsigned char) c)
  8008ff:	38 08                	cmp    %cl,(%eax)
  800901:	74 07                	je     80090a <memfind+0x1b>

void *
memfind(const void *s, int c, size_t n)
{
	const void *ends = (const char *) s + n;
	for (; s < ends; s++)
  800903:	83 c0 01             	add    $0x1,%eax
  800906:	39 d0                	cmp    %edx,%eax
  800908:	72 f5                	jb     8008ff <memfind+0x10>
		if (*(const unsigned char *) s == (unsigned char) c)
			break;
	return (void *) s;
}
  80090a:	5d                   	pop    %ebp
  80090b:	c3                   	ret    

0080090c <strtol>:

long
strtol(const char *s, char **endptr, int base)
{
  80090c:	55                   	push   %ebp
  80090d:	89 e5                	mov    %esp,%ebp
  80090f:	57                   	push   %edi
  800910:	56                   	push   %esi
  800911:	53                   	push   %ebx
  800912:	8b 4d 08             	mov    0x8(%ebp),%ecx
  800915:	8b 5d 10             	mov    0x10(%ebp),%ebx
	int neg = 0;
	long val = 0;

	// gobble initial whitespace
	while (*s == ' ' || *s == '\t')
  800918:	eb 03                	jmp    80091d <strtol+0x11>
		s++;
  80091a:	83 c1 01             	add    $0x1,%ecx
{
	int neg = 0;
	long val = 0;

	// gobble initial whitespace
	while (*s == ' ' || *s == '\t')
  80091d:	0f b6 01             	movzbl (%ecx),%eax
  800920:	3c 20                	cmp    $0x20,%al
  800922:	74 f6                	je     80091a <strtol+0xe>
  800924:	3c 09                	cmp    $0x9,%al
  800926:	74 f2                	je     80091a <strtol+0xe>
		s++;

	// plus/minus sign
	if (*s == '+')
  800928:	3c 2b                	cmp    $0x2b,%al
  80092a:	75 0a                	jne    800936 <strtol+0x2a>
		s++;
  80092c:	83 c1 01             	add    $0x1,%ecx
}

long
strtol(const char *s, char **endptr, int base)
{
	int neg = 0;
  80092f:	bf 00 00 00 00       	mov    $0x0,%edi
  800934:	eb 11                	jmp    800947 <strtol+0x3b>
  800936:	bf 00 00 00 00       	mov    $0x0,%edi
		s++;

	// plus/minus sign
	if (*s == '+')
		s++;
	else if (*s == '-')
  80093b:	3c 2d                	cmp    $0x2d,%al
  80093d:	75 08                	jne    800947 <strtol+0x3b>
		s++, neg = 1;
  80093f:	83 c1 01             	add    $0x1,%ecx
  800942:	bf 01 00 00 00       	mov    $0x1,%edi

	// hex or octal base prefix
	if ((base == 0 || base == 16) && (s[0] == '0' && s[1] == 'x'))
  800947:	f7 c3 ef ff ff ff    	test   $0xffffffef,%ebx
  80094d:	75 15                	jne    800964 <strtol+0x58>
  80094f:	80 39 30             	cmpb   $0x30,(%ecx)
  800952:	75 10                	jne    800964 <strtol+0x58>
  800954:	80 79 01 78          	cmpb   $0x78,0x1(%ecx)
  800958:	75 7c                	jne    8009d6 <strtol+0xca>
		s += 2, base = 16;
  80095a:	83 c1 02             	add    $0x2,%ecx
  80095d:	bb 10 00 00 00       	mov    $0x10,%ebx
  800962:	eb 16                	jmp    80097a <strtol+0x6e>
	else if (base == 0 && s[0] == '0')
  800964:	85 db                	test   %ebx,%ebx
  800966:	75 12                	jne    80097a <strtol+0x6e>
		s++, base = 8;
	else if (base == 0)
		base = 10;
  800968:	bb 0a 00 00 00       	mov    $0xa,%ebx
		s++, neg = 1;

	// hex or octal base prefix
	if ((base == 0 || base == 16) && (s[0] == '0' && s[1] == 'x'))
		s += 2, base = 16;
	else if (base == 0 && s[0] == '0')
  80096d:	80 39 30             	cmpb   $0x30,(%ecx)
  800970:	75 08                	jne    80097a <strtol+0x6e>
		s++, base = 8;
  800972:	83 c1 01             	add    $0x1,%ecx
  800975:	bb 08 00 00 00       	mov    $0x8,%ebx
	else if (base == 0)
		base = 10;
  80097a:	b8 00 00 00 00       	mov    $0x0,%eax
  80097f:	89 5d 10             	mov    %ebx,0x10(%ebp)

	// digits
	while (1) {
		int dig;

		if (*s >= '0' && *s <= '9')
  800982:	0f b6 11             	movzbl (%ecx),%edx
  800985:	8d 72 d0             	lea    -0x30(%edx),%esi
  800988:	89 f3                	mov    %esi,%ebx
  80098a:	80 fb 09             	cmp    $0x9,%bl
  80098d:	77 08                	ja     800997 <strtol+0x8b>
			dig = *s - '0';
  80098f:	0f be d2             	movsbl %dl,%edx
  800992:	83 ea 30             	sub    $0x30,%edx
  800995:	eb 22                	jmp    8009b9 <strtol+0xad>
		else if (*s >= 'a' && *s <= 'z')
  800997:	8d 72 9f             	lea    -0x61(%edx),%esi
  80099a:	89 f3                	mov    %esi,%ebx
  80099c:	80 fb 19             	cmp    $0x19,%bl
  80099f:	77 08                	ja     8009a9 <strtol+0x9d>
			dig = *s - 'a' + 10;
  8009a1:	0f be d2             	movsbl %dl,%edx
  8009a4:	83 ea 57             	sub    $0x57,%edx
  8009a7:	eb 10                	jmp    8009b9 <strtol+0xad>
		else if (*s >= 'A' && *s <= 'Z')
  8009a9:	8d 72 bf             	lea    -0x41(%edx),%esi
  8009ac:	89 f3                	mov    %esi,%ebx
  8009ae:	80 fb 19             	cmp    $0x19,%bl
  8009b1:	77 16                	ja     8009c9 <strtol+0xbd>
			dig = *s - 'A' + 10;
  8009b3:	0f be d2             	movsbl %dl,%edx
  8009b6:	83 ea 37             	sub    $0x37,%edx
		else
			break;
		if (dig >= base)
  8009b9:	3b 55 10             	cmp    0x10(%ebp),%edx
  8009bc:	7d 0b                	jge    8009c9 <strtol+0xbd>
			break;
		s++, val = (val * base) + dig;
  8009be:	83 c1 01             	add    $0x1,%ecx
  8009c1:	0f af 45 10          	imul   0x10(%ebp),%eax
  8009c5:	01 d0                	add    %edx,%eax
		// we don't properly detect overflow!
	}
  8009c7:	eb b9                	jmp    800982 <strtol+0x76>

	if (endptr)
  8009c9:	83 7d 0c 00          	cmpl   $0x0,0xc(%ebp)
  8009cd:	74 0d                	je     8009dc <strtol+0xd0>
		*endptr = (char *) s;
  8009cf:	8b 75 0c             	mov    0xc(%ebp),%esi
  8009d2:	89 0e                	mov    %ecx,(%esi)
  8009d4:	eb 06                	jmp    8009dc <strtol+0xd0>
		s++, neg = 1;

	// hex or octal base prefix
	if ((base == 0 || base == 16) && (s[0] == '0' && s[1] == 'x'))
		s += 2, base = 16;
	else if (base == 0 && s[0] == '0')
  8009d6:	85 db                	test   %ebx,%ebx
  8009d8:	74 98                	je     800972 <strtol+0x66>
  8009da:	eb 9e                	jmp    80097a <strtol+0x6e>
		// we don't properly detect overflow!
	}

	if (endptr)
		*endptr = (char *) s;
	return (neg ? -val : val);
  8009dc:	89 c2                	mov    %eax,%edx
  8009de:	f7 da                	neg    %edx
  8009e0:	85 ff                	test   %edi,%edi
  8009e2:	0f 45 c2             	cmovne %edx,%eax
}
  8009e5:	5b                   	pop    %ebx
  8009e6:	5e                   	pop    %esi
  8009e7:	5f                   	pop    %edi
  8009e8:	5d                   	pop    %ebp
  8009e9:	c3                   	ret    

008009ea <syscall>:
#include <inc/syscall.h>
#include <inc/lib.h>

static inline int32_t
syscall(int num, int check, uint32_t a1, uint32_t a2, uint32_t a3, uint32_t a4, uint32_t a5)
{
  8009ea:	55                   	push   %ebp
  8009eb:	89 e5                	mov    %esp,%ebp
  8009ed:	57                   	push   %edi
  8009ee:	56                   	push   %esi
  8009ef:	53                   	push   %ebx
  8009f0:	83 ec 1c             	sub    $0x1c,%esp
  8009f3:	89 45 e0             	mov    %eax,-0x20(%ebp)
  8009f6:	89 55 e4             	mov    %edx,-0x1c(%ebp)
  8009f9:	89 ca                	mov    %ecx,%edx
	//
	// The last clause tells the assembler that this can
	// potentially change the condition codes and arbitrary
	// memory locations.

	asm volatile("int %1\n"
  8009fb:	8b 4d 08             	mov    0x8(%ebp),%ecx
  8009fe:	8b 5d 0c             	mov    0xc(%ebp),%ebx
  800a01:	8b 7d 10             	mov    0x10(%ebp),%edi
  800a04:	8b 75 14             	mov    0x14(%ebp),%esi
  800a07:	cd 30                	int    $0x30
		       "b" (a3),
		       "D" (a4),
		       "S" (a5)
		     : "cc", "memory");

	if(check && ret > 0)
  800a09:	83 7d e4 00          	cmpl   $0x0,-0x1c(%ebp)
  800a0d:	74 1d                	je     800a2c <syscall+0x42>
  800a0f:	85 c0                	test   %eax,%eax
  800a11:	7e 19                	jle    800a2c <syscall+0x42>
  800a13:	8b 55 e0             	mov    -0x20(%ebp),%edx
		panic("syscall %d returned %d (> 0)", num, ret);
  800a16:	83 ec 0c             	sub    $0xc,%esp
  800a19:	50                   	push   %eax
  800a1a:	52                   	push   %edx
  800a1b:	68 c4 0f 80 00       	push   $0x800fc4
  800a20:	6a 23                	push   $0x23
  800a22:	68 e1 0f 80 00       	push   $0x800fe1
  800a27:	e8 98 00 00 00       	call   800ac4 <_panic>

	return ret;
}
  800a2c:	8d 65 f4             	lea    -0xc(%ebp),%esp
  800a2f:	5b                   	pop    %ebx
  800a30:	5e                   	pop    %esi
  800a31:	5f                   	pop    %edi
  800a32:	5d                   	pop    %ebp
  800a33:	c3                   	ret    

00800a34 <sys_cputs>:

void
sys_cputs(const char *s, size_t len)
{
  800a34:	55                   	push   %ebp
  800a35:	89 e5                	mov    %esp,%ebp
  800a37:	83 ec 08             	sub    $0x8,%esp
	syscall(SYS_cputs, 0, (uint32_t)s, len, 0, 0, 0);
  800a3a:	6a 00                	push   $0x0
  800a3c:	6a 00                	push   $0x0
  800a3e:	6a 00                	push   $0x0
  800a40:	ff 75 0c             	pushl  0xc(%ebp)
  800a43:	8b 4d 08             	mov    0x8(%ebp),%ecx
  800a46:	ba 00 00 00 00       	mov    $0x0,%edx
  800a4b:	b8 00 00 00 00       	mov    $0x0,%eax
  800a50:	e8 95 ff ff ff       	call   8009ea <syscall>
}
  800a55:	83 c4 10             	add    $0x10,%esp
  800a58:	c9                   	leave  
  800a59:	c3                   	ret    

00800a5a <sys_cgetc>:

int
sys_cgetc(void)
{
  800a5a:	55                   	push   %ebp
  800a5b:	89 e5                	mov    %esp,%ebp
  800a5d:	83 ec 08             	sub    $0x8,%esp
	return syscall(SYS_cgetc, 0, 0, 0, 0, 0, 0);
  800a60:	6a 00                	push   $0x0
  800a62:	6a 00                	push   $0x0
  800a64:	6a 00                	push   $0x0
  800a66:	6a 00                	push   $0x0
  800a68:	b9 00 00 00 00       	mov    $0x0,%ecx
  800a6d:	ba 00 00 00 00       	mov    $0x0,%edx
  800a72:	b8 01 00 00 00       	mov    $0x1,%eax
  800a77:	e8 6e ff ff ff       	call   8009ea <syscall>
}
  800a7c:	c9                   	leave  
  800a7d:	c3                   	ret    

00800a7e <sys_env_destroy>:

int
sys_env_destroy(envid_t envid)
{
  800a7e:	55                   	push   %ebp
  800a7f:	89 e5                	mov    %esp,%ebp
  800a81:	83 ec 08             	sub    $0x8,%esp
	return syscall(SYS_env_destroy, 1, envid, 0, 0, 0, 0);
  800a84:	6a 00                	push   $0x0
  800a86:	6a 00                	push   $0x0
  800a88:	6a 00                	push   $0x0
  800a8a:	6a 00                	push   $0x0
  800a8c:	8b 4d 08             	mov    0x8(%ebp),%ecx
  800a8f:	ba 01 00 00 00       	mov    $0x1,%edx
  800a94:	b8 03 00 00 00       	mov    $0x3,%eax
  800a99:	e8 4c ff ff ff       	call   8009ea <syscall>
}
  800a9e:	c9                   	leave  
  800a9f:	c3                   	ret    

00800aa0 <sys_getenvid>:

envid_t
sys_getenvid(void)
{
  800aa0:	55                   	push   %ebp
  800aa1:	89 e5                	mov    %esp,%ebp
  800aa3:	83 ec 08             	sub    $0x8,%esp
	 return syscall(SYS_getenvid, 0, 0, 0, 0, 0, 0);
  800aa6:	6a 00                	push   $0x0
  800aa8:	6a 00                	push   $0x0
  800aaa:	6a 00                	push   $0x0
  800aac:	6a 00                	push   $0x0
  800aae:	b9 00 00 00 00       	mov    $0x0,%ecx
  800ab3:	ba 00 00 00 00       	mov    $0x0,%edx
  800ab8:	b8 02 00 00 00       	mov    $0x2,%eax
  800abd:	e8 28 ff ff ff       	call   8009ea <syscall>
}
  800ac2:	c9                   	leave  
  800ac3:	c3                   	ret    

00800ac4 <_panic>:
 * It prints "panic: <message>", then causes a breakpoint exception,
 * which causes JOS to enter the JOS kernel monitor.
 */
void
_panic(const char *file, int line, const char *fmt, ...)
{
  800ac4:	55                   	push   %ebp
  800ac5:	89 e5                	mov    %esp,%ebp
  800ac7:	56                   	push   %esi
  800ac8:	53                   	push   %ebx
	va_list ap;

	va_start(ap, fmt);
  800ac9:	8d 5d 14             	lea    0x14(%ebp),%ebx

	// Print the panic message
	cprintf("[%08x] user panic in %s at %s:%d: ",
  800acc:	8b 35 00 20 80 00    	mov    0x802000,%esi
  800ad2:	e8 c9 ff ff ff       	call   800aa0 <sys_getenvid>
  800ad7:	83 ec 0c             	sub    $0xc,%esp
  800ada:	ff 75 0c             	pushl  0xc(%ebp)
  800add:	ff 75 08             	pushl  0x8(%ebp)
  800ae0:	56                   	push   %esi
  800ae1:	50                   	push   %eax
  800ae2:	68 f0 0f 80 00       	push   $0x800ff0
  800ae7:	e8 4a f6 ff ff       	call   800136 <cprintf>
		sys_getenvid(), binaryname, file, line);
	vcprintf(fmt, ap);
  800aec:	83 c4 18             	add    $0x18,%esp
  800aef:	53                   	push   %ebx
  800af0:	ff 75 10             	pushl  0x10(%ebp)
  800af3:	e8 ed f5 ff ff       	call   8000e5 <vcprintf>
	cprintf("\n");
  800af8:	c7 04 24 a0 0d 80 00 	movl   $0x800da0,(%esp)
  800aff:	e8 32 f6 ff ff       	call   800136 <cprintf>
  800b04:	83 c4 10             	add    $0x10,%esp

	// Cause a breakpoint exception
	while (1)
		asm volatile("int3");
  800b07:	cc                   	int3   
  800b08:	eb fd                	jmp    800b07 <_panic+0x43>
  800b0a:	66 90                	xchg   %ax,%ax
  800b0c:	66 90                	xchg   %ax,%ax
  800b0e:	66 90                	xchg   %ax,%ax

00800b10 <__udivdi3>:
  800b10:	55                   	push   %ebp
  800b11:	57                   	push   %edi
  800b12:	56                   	push   %esi
  800b13:	53                   	push   %ebx
  800b14:	83 ec 1c             	sub    $0x1c,%esp
  800b17:	8b 74 24 3c          	mov    0x3c(%esp),%esi
  800b1b:	8b 5c 24 30          	mov    0x30(%esp),%ebx
  800b1f:	8b 4c 24 34          	mov    0x34(%esp),%ecx
  800b23:	8b 7c 24 38          	mov    0x38(%esp),%edi
  800b27:	85 f6                	test   %esi,%esi
  800b29:	89 5c 24 08          	mov    %ebx,0x8(%esp)
  800b2d:	89 ca                	mov    %ecx,%edx
  800b2f:	89 f8                	mov    %edi,%eax
  800b31:	75 3d                	jne    800b70 <__udivdi3+0x60>
  800b33:	39 cf                	cmp    %ecx,%edi
  800b35:	0f 87 c5 00 00 00    	ja     800c00 <__udivdi3+0xf0>
  800b3b:	85 ff                	test   %edi,%edi
  800b3d:	89 fd                	mov    %edi,%ebp
  800b3f:	75 0b                	jne    800b4c <__udivdi3+0x3c>
  800b41:	b8 01 00 00 00       	mov    $0x1,%eax
  800b46:	31 d2                	xor    %edx,%edx
  800b48:	f7 f7                	div    %edi
  800b4a:	89 c5                	mov    %eax,%ebp
  800b4c:	89 c8                	mov    %ecx,%eax
  800b4e:	31 d2                	xor    %edx,%edx
  800b50:	f7 f5                	div    %ebp
  800b52:	89 c1                	mov    %eax,%ecx
  800b54:	89 d8                	mov    %ebx,%eax
  800b56:	89 cf                	mov    %ecx,%edi
  800b58:	f7 f5                	div    %ebp
  800b5a:	89 c3                	mov    %eax,%ebx
  800b5c:	89 d8                	mov    %ebx,%eax
  800b5e:	89 fa                	mov    %edi,%edx
  800b60:	83 c4 1c             	add    $0x1c,%esp
  800b63:	5b                   	pop    %ebx
  800b64:	5e                   	pop    %esi
  800b65:	5f                   	pop    %edi
  800b66:	5d                   	pop    %ebp
  800b67:	c3                   	ret    
  800b68:	90                   	nop
  800b69:	8d b4 26 00 00 00 00 	lea    0x0(%esi,%eiz,1),%esi
  800b70:	39 ce                	cmp    %ecx,%esi
  800b72:	77 74                	ja     800be8 <__udivdi3+0xd8>
  800b74:	0f bd fe             	bsr    %esi,%edi
  800b77:	83 f7 1f             	xor    $0x1f,%edi
  800b7a:	0f 84 98 00 00 00    	je     800c18 <__udivdi3+0x108>
  800b80:	bb 20 00 00 00       	mov    $0x20,%ebx
  800b85:	89 f9                	mov    %edi,%ecx
  800b87:	89 c5                	mov    %eax,%ebp
  800b89:	29 fb                	sub    %edi,%ebx
  800b8b:	d3 e6                	shl    %cl,%esi
  800b8d:	89 d9                	mov    %ebx,%ecx
  800b8f:	d3 ed                	shr    %cl,%ebp
  800b91:	89 f9                	mov    %edi,%ecx
  800b93:	d3 e0                	shl    %cl,%eax
  800b95:	09 ee                	or     %ebp,%esi
  800b97:	89 d9                	mov    %ebx,%ecx
  800b99:	89 44 24 0c          	mov    %eax,0xc(%esp)
  800b9d:	89 d5                	mov    %edx,%ebp
  800b9f:	8b 44 24 08          	mov    0x8(%esp),%eax
  800ba3:	d3 ed                	shr    %cl,%ebp
  800ba5:	89 f9                	mov    %edi,%ecx
  800ba7:	d3 e2                	shl    %cl,%edx
  800ba9:	89 d9                	mov    %ebx,%ecx
  800bab:	d3 e8                	shr    %cl,%eax
  800bad:	09 c2                	or     %eax,%edx
  800baf:	89 d0                	mov    %edx,%eax
  800bb1:	89 ea                	mov    %ebp,%edx
  800bb3:	f7 f6                	div    %esi
  800bb5:	89 d5                	mov    %edx,%ebp
  800bb7:	89 c3                	mov    %eax,%ebx
  800bb9:	f7 64 24 0c          	mull   0xc(%esp)
  800bbd:	39 d5                	cmp    %edx,%ebp
  800bbf:	72 10                	jb     800bd1 <__udivdi3+0xc1>
  800bc1:	8b 74 24 08          	mov    0x8(%esp),%esi
  800bc5:	89 f9                	mov    %edi,%ecx
  800bc7:	d3 e6                	shl    %cl,%esi
  800bc9:	39 c6                	cmp    %eax,%esi
  800bcb:	73 07                	jae    800bd4 <__udivdi3+0xc4>
  800bcd:	39 d5                	cmp    %edx,%ebp
  800bcf:	75 03                	jne    800bd4 <__udivdi3+0xc4>
  800bd1:	83 eb 01             	sub    $0x1,%ebx
  800bd4:	31 ff                	xor    %edi,%edi
  800bd6:	89 d8                	mov    %ebx,%eax
  800bd8:	89 fa                	mov    %edi,%edx
  800bda:	83 c4 1c             	add    $0x1c,%esp
  800bdd:	5b                   	pop    %ebx
  800bde:	5e                   	pop    %esi
  800bdf:	5f                   	pop    %edi
  800be0:	5d                   	pop    %ebp
  800be1:	c3                   	ret    
  800be2:	8d b6 00 00 00 00    	lea    0x0(%esi),%esi
  800be8:	31 ff                	xor    %edi,%edi
  800bea:	31 db                	xor    %ebx,%ebx
  800bec:	89 d8                	mov    %ebx,%eax
  800bee:	89 fa                	mov    %edi,%edx
  800bf0:	83 c4 1c             	add    $0x1c,%esp
  800bf3:	5b                   	pop    %ebx
  800bf4:	5e                   	pop    %esi
  800bf5:	5f                   	pop    %edi
  800bf6:	5d                   	pop    %ebp
  800bf7:	c3                   	ret    
  800bf8:	90                   	nop
  800bf9:	8d b4 26 00 00 00 00 	lea    0x0(%esi,%eiz,1),%esi
  800c00:	89 d8                	mov    %ebx,%eax
  800c02:	f7 f7                	div    %edi
  800c04:	31 ff                	xor    %edi,%edi
  800c06:	89 c3                	mov    %eax,%ebx
  800c08:	89 d8                	mov    %ebx,%eax
  800c0a:	89 fa                	mov    %edi,%edx
  800c0c:	83 c4 1c             	add    $0x1c,%esp
  800c0f:	5b                   	pop    %ebx
  800c10:	5e                   	pop    %esi
  800c11:	5f                   	pop    %edi
  800c12:	5d                   	pop    %ebp
  800c13:	c3                   	ret    
  800c14:	8d 74 26 00          	lea    0x0(%esi,%eiz,1),%esi
  800c18:	39 ce                	cmp    %ecx,%esi
  800c1a:	72 0c                	jb     800c28 <__udivdi3+0x118>
  800c1c:	31 db                	xor    %ebx,%ebx
  800c1e:	3b 44 24 08          	cmp    0x8(%esp),%eax
  800c22:	0f 87 34 ff ff ff    	ja     800b5c <__udivdi3+0x4c>
  800c28:	bb 01 00 00 00       	mov    $0x1,%ebx
  800c2d:	e9 2a ff ff ff       	jmp    800b5c <__udivdi3+0x4c>
  800c32:	66 90                	xchg   %ax,%ax
  800c34:	66 90                	xchg   %ax,%ax
  800c36:	66 90                	xchg   %ax,%ax
  800c38:	66 90                	xchg   %ax,%ax
  800c3a:	66 90                	xchg   %ax,%ax
  800c3c:	66 90                	xchg   %ax,%ax
  800c3e:	66 90                	xchg   %ax,%ax

00800c40 <__umoddi3>:
  800c40:	55                   	push   %ebp
  800c41:	57                   	push   %edi
  800c42:	56                   	push   %esi
  800c43:	53                   	push   %ebx
  800c44:	83 ec 1c             	sub    $0x1c,%esp
  800c47:	8b 54 24 3c          	mov    0x3c(%esp),%edx
  800c4b:	8b 4c 24 30          	mov    0x30(%esp),%ecx
  800c4f:	8b 74 24 34          	mov    0x34(%esp),%esi
  800c53:	8b 7c 24 38          	mov    0x38(%esp),%edi
  800c57:	85 d2                	test   %edx,%edx
  800c59:	89 4c 24 0c          	mov    %ecx,0xc(%esp)
  800c5d:	89 4c 24 08          	mov    %ecx,0x8(%esp)
  800c61:	89 f3                	mov    %esi,%ebx
  800c63:	89 3c 24             	mov    %edi,(%esp)
  800c66:	89 74 24 04          	mov    %esi,0x4(%esp)
  800c6a:	75 1c                	jne    800c88 <__umoddi3+0x48>
  800c6c:	39 f7                	cmp    %esi,%edi
  800c6e:	76 50                	jbe    800cc0 <__umoddi3+0x80>
  800c70:	89 c8                	mov    %ecx,%eax
  800c72:	89 f2                	mov    %esi,%edx
  800c74:	f7 f7                	div    %edi
  800c76:	89 d0                	mov    %edx,%eax
  800c78:	31 d2                	xor    %edx,%edx
  800c7a:	83 c4 1c             	add    $0x1c,%esp
  800c7d:	5b                   	pop    %ebx
  800c7e:	5e                   	pop    %esi
  800c7f:	5f                   	pop    %edi
  800c80:	5d                   	pop    %ebp
  800c81:	c3                   	ret    
  800c82:	8d b6 00 00 00 00    	lea    0x0(%esi),%esi
  800c88:	39 f2                	cmp    %esi,%edx
  800c8a:	89 d0                	mov    %edx,%eax
  800c8c:	77 52                	ja     800ce0 <__umoddi3+0xa0>
  800c8e:	0f bd ea             	bsr    %edx,%ebp
  800c91:	83 f5 1f             	xor    $0x1f,%ebp
  800c94:	75 5a                	jne    800cf0 <__umoddi3+0xb0>
  800c96:	3b 54 24 04          	cmp    0x4(%esp),%edx
  800c9a:	0f 82 e0 00 00 00    	jb     800d80 <__umoddi3+0x140>
  800ca0:	39 0c 24             	cmp    %ecx,(%esp)
  800ca3:	0f 86 d7 00 00 00    	jbe    800d80 <__umoddi3+0x140>
  800ca9:	8b 44 24 08          	mov    0x8(%esp),%eax
  800cad:	8b 54 24 04          	mov    0x4(%esp),%edx
  800cb1:	83 c4 1c             	add    $0x1c,%esp
  800cb4:	5b                   	pop    %ebx
  800cb5:	5e                   	pop    %esi
  800cb6:	5f                   	pop    %edi
  800cb7:	5d                   	pop    %ebp
  800cb8:	c3                   	ret    
  800cb9:	8d b4 26 00 00 00 00 	lea    0x0(%esi,%eiz,1),%esi
  800cc0:	85 ff                	test   %edi,%edi
  800cc2:	89 fd                	mov    %edi,%ebp
  800cc4:	75 0b                	jne    800cd1 <__umoddi3+0x91>
  800cc6:	b8 01 00 00 00       	mov    $0x1,%eax
  800ccb:	31 d2                	xor    %edx,%edx
  800ccd:	f7 f7                	div    %edi
  800ccf:	89 c5                	mov    %eax,%ebp
  800cd1:	89 f0                	mov    %esi,%eax
  800cd3:	31 d2                	xor    %edx,%edx
  800cd5:	f7 f5                	div    %ebp
  800cd7:	89 c8                	mov    %ecx,%eax
  800cd9:	f7 f5                	div    %ebp
  800cdb:	89 d0                	mov    %edx,%eax
  800cdd:	eb 99                	jmp    800c78 <__umoddi3+0x38>
  800cdf:	90                   	nop
  800ce0:	89 c8                	mov    %ecx,%eax
  800ce2:	89 f2                	mov    %esi,%edx
  800ce4:	83 c4 1c             	add    $0x1c,%esp
  800ce7:	5b                   	pop    %ebx
  800ce8:	5e                   	pop    %esi
  800ce9:	5f                   	pop    %edi
  800cea:	5d                   	pop    %ebp
  800ceb:	c3                   	ret    
  800cec:	8d 74 26 00          	lea    0x0(%esi,%eiz,1),%esi
  800cf0:	8b 34 24             	mov    (%esp),%esi
  800cf3:	bf 20 00 00 00       	mov    $0x20,%edi
  800cf8:	89 e9                	mov    %ebp,%ecx
  800cfa:	29 ef                	sub    %ebp,%edi
  800cfc:	d3 e0                	shl    %cl,%eax
  800cfe:	89 f9                	mov    %edi,%ecx
  800d00:	89 f2                	mov    %esi,%edx
  800d02:	d3 ea                	shr    %cl,%edx
  800d04:	89 e9                	mov    %ebp,%ecx
  800d06:	09 c2                	or     %eax,%edx
  800d08:	89 d8                	mov    %ebx,%eax
  800d0a:	89 14 24             	mov    %edx,(%esp)
  800d0d:	89 f2                	mov    %esi,%edx
  800d0f:	d3 e2                	shl    %cl,%edx
  800d11:	89 f9                	mov    %edi,%ecx
  800d13:	89 54 24 04          	mov    %edx,0x4(%esp)
  800d17:	8b 54 24 0c          	mov    0xc(%esp),%edx
  800d1b:	d3 e8                	shr    %cl,%eax
  800d1d:	89 e9                	mov    %ebp,%ecx
  800d1f:	89 c6                	mov    %eax,%esi
  800d21:	d3 e3                	shl    %cl,%ebx
  800d23:	89 f9                	mov    %edi,%ecx
  800d25:	89 d0                	mov    %edx,%eax
  800d27:	d3 e8                	shr    %cl,%eax
  800d29:	89 e9                	mov    %ebp,%ecx
  800d2b:	09 d8                	or     %ebx,%eax
  800d2d:	89 d3                	mov    %edx,%ebx
  800d2f:	89 f2                	mov    %esi,%edx
  800d31:	f7 34 24             	divl   (%esp)
  800d34:	89 d6                	mov    %edx,%esi
  800d36:	d3 e3                	shl    %cl,%ebx
  800d38:	f7 64 24 04          	mull   0x4(%esp)
  800d3c:	39 d6                	cmp    %edx,%esi
  800d3e:	89 5c 24 08          	mov    %ebx,0x8(%esp)
  800d42:	89 d1                	mov    %edx,%ecx
  800d44:	89 c3                	mov    %eax,%ebx
  800d46:	72 08                	jb     800d50 <__umoddi3+0x110>
  800d48:	75 11                	jne    800d5b <__umoddi3+0x11b>
  800d4a:	39 44 24 08          	cmp    %eax,0x8(%esp)
  800d4e:	73 0b                	jae    800d5b <__umoddi3+0x11b>
  800d50:	2b 44 24 04          	sub    0x4(%esp),%eax
  800d54:	1b 14 24             	sbb    (%esp),%edx
  800d57:	89 d1                	mov    %edx,%ecx
  800d59:	89 c3                	mov    %eax,%ebx
  800d5b:	8b 54 24 08          	mov    0x8(%esp),%edx
  800d5f:	29 da                	sub    %ebx,%edx
  800d61:	19 ce                	sbb    %ecx,%esi
  800d63:	89 f9                	mov    %edi,%ecx
  800d65:	89 f0                	mov    %esi,%eax
  800d67:	d3 e0                	shl    %cl,%eax
  800d69:	89 e9                	mov    %ebp,%ecx
  800d6b:	d3 ea                	shr    %cl,%edx
  800d6d:	89 e9                	mov    %ebp,%ecx
  800d6f:	d3 ee                	shr    %cl,%esi
  800d71:	09 d0                	or     %edx,%eax
  800d73:	89 f2                	mov    %esi,%edx
  800d75:	83 c4 1c             	add    $0x1c,%esp
  800d78:	5b                   	pop    %ebx
  800d79:	5e                   	pop    %esi
  800d7a:	5f                   	pop    %edi
  800d7b:	5d                   	pop    %ebp
  800d7c:	c3                   	ret    
  800d7d:	8d 76 00             	lea    0x0(%esi),%esi
  800d80:	29 f9                	sub    %edi,%ecx
  800d82:	19 d6                	sbb    %edx,%esi
  800d84:	89 74 24 04          	mov    %esi,0x4(%esp)
  800d88:	89 4c 24 08          	mov    %ecx,0x8(%esp)
  800d8c:	e9 18 ff ff ff       	jmp    800ca9 <__umoddi3+0x69>
