
obj/user/faultread:     file format elf32-i386


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
  80002c:	e8 1d 00 00 00       	call   80004e <libmain>
1:	jmp 1b
  800031:	eb fe                	jmp    800031 <args_exist+0x5>

00800033 <umain>:

#include <inc/lib.h>

void
umain(int argc, char **argv)
{
  800033:	55                   	push   %ebp
  800034:	89 e5                	mov    %esp,%ebp
  800036:	83 ec 10             	sub    $0x10,%esp
	cprintf("I read %08x from location 0!\n", *(unsigned*)0);
  800039:	ff 35 00 00 00 00    	pushl  0x0
  80003f:	68 e0 0e 80 00       	push   $0x800ee0
  800044:	e8 f4 00 00 00       	call   80013d <cprintf>
}
  800049:	83 c4 10             	add    $0x10,%esp
  80004c:	c9                   	leave  
  80004d:	c3                   	ret    

0080004e <libmain>:
const volatile struct Env *thisenv;
const char *binaryname = "<unknown>";

void
libmain(int argc, char **argv)
{
  80004e:	55                   	push   %ebp
  80004f:	89 e5                	mov    %esp,%ebp
  800051:	56                   	push   %esi
  800052:	53                   	push   %ebx
  800053:	8b 5d 08             	mov    0x8(%ebp),%ebx
  800056:	8b 75 0c             	mov    0xc(%ebp),%esi
	// set thisenv to point at our Env structure in envs[].
	// LAB 3: Your code here.
	envid_t id = sys_getenvid();
  800059:	e8 49 0a 00 00       	call   800aa7 <sys_getenvid>
	if (id >= 0)
  80005e:	85 c0                	test   %eax,%eax
  800060:	78 12                	js     800074 <libmain+0x26>
		thisenv = &envs[ENVX(id)];
  800062:	25 ff 03 00 00       	and    $0x3ff,%eax
  800067:	6b c0 7c             	imul   $0x7c,%eax,%eax
  80006a:	05 00 00 c0 ee       	add    $0xeec00000,%eax
  80006f:	a3 04 20 80 00       	mov    %eax,0x802004

	// save the name of the program so that panic() can use it
	if (argc > 0)
  800074:	85 db                	test   %ebx,%ebx
  800076:	7e 07                	jle    80007f <libmain+0x31>
		binaryname = argv[0];
  800078:	8b 06                	mov    (%esi),%eax
  80007a:	a3 00 20 80 00       	mov    %eax,0x802000

	// call user main routine
	umain(argc, argv);
  80007f:	83 ec 08             	sub    $0x8,%esp
  800082:	56                   	push   %esi
  800083:	53                   	push   %ebx
  800084:	e8 aa ff ff ff       	call   800033 <umain>

	// exit gracefully
	exit();
  800089:	e8 0a 00 00 00       	call   800098 <exit>
}
  80008e:	83 c4 10             	add    $0x10,%esp
  800091:	8d 65 f8             	lea    -0x8(%ebp),%esp
  800094:	5b                   	pop    %ebx
  800095:	5e                   	pop    %esi
  800096:	5d                   	pop    %ebp
  800097:	c3                   	ret    

00800098 <exit>:

#include <inc/lib.h>

void
exit(void)
{
  800098:	55                   	push   %ebp
  800099:	89 e5                	mov    %esp,%ebp
  80009b:	83 ec 14             	sub    $0x14,%esp
	sys_env_destroy(0);
  80009e:	6a 00                	push   $0x0
  8000a0:	e8 e0 09 00 00       	call   800a85 <sys_env_destroy>
}
  8000a5:	83 c4 10             	add    $0x10,%esp
  8000a8:	c9                   	leave  
  8000a9:	c3                   	ret    

008000aa <putch>:
};


static void
putch(int ch, struct printbuf *b)
{
  8000aa:	55                   	push   %ebp
  8000ab:	89 e5                	mov    %esp,%ebp
  8000ad:	53                   	push   %ebx
  8000ae:	83 ec 04             	sub    $0x4,%esp
  8000b1:	8b 5d 0c             	mov    0xc(%ebp),%ebx
	b->buf[b->idx++] = ch;
  8000b4:	8b 13                	mov    (%ebx),%edx
  8000b6:	8d 42 01             	lea    0x1(%edx),%eax
  8000b9:	89 03                	mov    %eax,(%ebx)
  8000bb:	8b 4d 08             	mov    0x8(%ebp),%ecx
  8000be:	88 4c 13 08          	mov    %cl,0x8(%ebx,%edx,1)
	if (b->idx == 256-1) {
  8000c2:	3d ff 00 00 00       	cmp    $0xff,%eax
  8000c7:	75 1a                	jne    8000e3 <putch+0x39>
		sys_cputs(b->buf, b->idx);
  8000c9:	83 ec 08             	sub    $0x8,%esp
  8000cc:	68 ff 00 00 00       	push   $0xff
  8000d1:	8d 43 08             	lea    0x8(%ebx),%eax
  8000d4:	50                   	push   %eax
  8000d5:	e8 61 09 00 00       	call   800a3b <sys_cputs>
		b->idx = 0;
  8000da:	c7 03 00 00 00 00    	movl   $0x0,(%ebx)
  8000e0:	83 c4 10             	add    $0x10,%esp
	}
	b->cnt++;
  8000e3:	83 43 04 01          	addl   $0x1,0x4(%ebx)
}
  8000e7:	8b 5d fc             	mov    -0x4(%ebp),%ebx
  8000ea:	c9                   	leave  
  8000eb:	c3                   	ret    

008000ec <vcprintf>:

int
vcprintf(const char *fmt, va_list ap)
{
  8000ec:	55                   	push   %ebp
  8000ed:	89 e5                	mov    %esp,%ebp
  8000ef:	81 ec 18 01 00 00    	sub    $0x118,%esp
	struct printbuf b;

	b.idx = 0;
  8000f5:	c7 85 f0 fe ff ff 00 	movl   $0x0,-0x110(%ebp)
  8000fc:	00 00 00 
	b.cnt = 0;
  8000ff:	c7 85 f4 fe ff ff 00 	movl   $0x0,-0x10c(%ebp)
  800106:	00 00 00 
	vprintfmt((void*)putch, &b, fmt, ap);
  800109:	ff 75 0c             	pushl  0xc(%ebp)
  80010c:	ff 75 08             	pushl  0x8(%ebp)
  80010f:	8d 85 f0 fe ff ff    	lea    -0x110(%ebp),%eax
  800115:	50                   	push   %eax
  800116:	68 aa 00 80 00       	push   $0x8000aa
  80011b:	e8 86 01 00 00       	call   8002a6 <vprintfmt>
	sys_cputs(b.buf, b.idx);
  800120:	83 c4 08             	add    $0x8,%esp
  800123:	ff b5 f0 fe ff ff    	pushl  -0x110(%ebp)
  800129:	8d 85 f8 fe ff ff    	lea    -0x108(%ebp),%eax
  80012f:	50                   	push   %eax
  800130:	e8 06 09 00 00       	call   800a3b <sys_cputs>

	return b.cnt;
}
  800135:	8b 85 f4 fe ff ff    	mov    -0x10c(%ebp),%eax
  80013b:	c9                   	leave  
  80013c:	c3                   	ret    

0080013d <cprintf>:

int
cprintf(const char *fmt, ...)
{
  80013d:	55                   	push   %ebp
  80013e:	89 e5                	mov    %esp,%ebp
  800140:	83 ec 10             	sub    $0x10,%esp
	va_list ap;
	int cnt;

	va_start(ap, fmt);
  800143:	8d 45 0c             	lea    0xc(%ebp),%eax
	cnt = vcprintf(fmt, ap);
  800146:	50                   	push   %eax
  800147:	ff 75 08             	pushl  0x8(%ebp)
  80014a:	e8 9d ff ff ff       	call   8000ec <vcprintf>
	va_end(ap);

	return cnt;
}
  80014f:	c9                   	leave  
  800150:	c3                   	ret    

00800151 <printnum>:
 * using specified putch function and associated pointer putdat.
 */
static void
printnum(void (*putch)(int, void*), void *putdat,
	 unsigned long long num, unsigned base, int width, int padc)
{
  800151:	55                   	push   %ebp
  800152:	89 e5                	mov    %esp,%ebp
  800154:	57                   	push   %edi
  800155:	56                   	push   %esi
  800156:	53                   	push   %ebx
  800157:	83 ec 1c             	sub    $0x1c,%esp
  80015a:	89 c7                	mov    %eax,%edi
  80015c:	89 d6                	mov    %edx,%esi
  80015e:	8b 45 08             	mov    0x8(%ebp),%eax
  800161:	8b 55 0c             	mov    0xc(%ebp),%edx
  800164:	89 45 d8             	mov    %eax,-0x28(%ebp)
  800167:	89 55 dc             	mov    %edx,-0x24(%ebp)
	// first recursively print all preceding (more significant) digits
	if (num >= base) {
  80016a:	8b 4d 10             	mov    0x10(%ebp),%ecx
  80016d:	bb 00 00 00 00       	mov    $0x0,%ebx
  800172:	89 4d e0             	mov    %ecx,-0x20(%ebp)
  800175:	89 5d e4             	mov    %ebx,-0x1c(%ebp)
  800178:	39 d3                	cmp    %edx,%ebx
  80017a:	72 05                	jb     800181 <printnum+0x30>
  80017c:	39 45 10             	cmp    %eax,0x10(%ebp)
  80017f:	77 45                	ja     8001c6 <printnum+0x75>
		printnum(putch, putdat, num / base, base, width - 1, padc);
  800181:	83 ec 0c             	sub    $0xc,%esp
  800184:	ff 75 18             	pushl  0x18(%ebp)
  800187:	8b 45 14             	mov    0x14(%ebp),%eax
  80018a:	8d 58 ff             	lea    -0x1(%eax),%ebx
  80018d:	53                   	push   %ebx
  80018e:	ff 75 10             	pushl  0x10(%ebp)
  800191:	83 ec 08             	sub    $0x8,%esp
  800194:	ff 75 e4             	pushl  -0x1c(%ebp)
  800197:	ff 75 e0             	pushl  -0x20(%ebp)
  80019a:	ff 75 dc             	pushl  -0x24(%ebp)
  80019d:	ff 75 d8             	pushl  -0x28(%ebp)
  8001a0:	e8 9b 0a 00 00       	call   800c40 <__udivdi3>
  8001a5:	83 c4 18             	add    $0x18,%esp
  8001a8:	52                   	push   %edx
  8001a9:	50                   	push   %eax
  8001aa:	89 f2                	mov    %esi,%edx
  8001ac:	89 f8                	mov    %edi,%eax
  8001ae:	e8 9e ff ff ff       	call   800151 <printnum>
  8001b3:	83 c4 20             	add    $0x20,%esp
  8001b6:	eb 18                	jmp    8001d0 <printnum+0x7f>
	} else {
		// print any needed pad characters before first digit
		while (--width > 0)
			putch(padc, putdat);
  8001b8:	83 ec 08             	sub    $0x8,%esp
  8001bb:	56                   	push   %esi
  8001bc:	ff 75 18             	pushl  0x18(%ebp)
  8001bf:	ff d7                	call   *%edi
  8001c1:	83 c4 10             	add    $0x10,%esp
  8001c4:	eb 03                	jmp    8001c9 <printnum+0x78>
  8001c6:	8b 5d 14             	mov    0x14(%ebp),%ebx
	// first recursively print all preceding (more significant) digits
	if (num >= base) {
		printnum(putch, putdat, num / base, base, width - 1, padc);
	} else {
		// print any needed pad characters before first digit
		while (--width > 0)
  8001c9:	83 eb 01             	sub    $0x1,%ebx
  8001cc:	85 db                	test   %ebx,%ebx
  8001ce:	7f e8                	jg     8001b8 <printnum+0x67>
			putch(padc, putdat);
	}

	// then print this (the least significant) digit
	putch("0123456789abcdef"[num % base], putdat);
  8001d0:	83 ec 08             	sub    $0x8,%esp
  8001d3:	56                   	push   %esi
  8001d4:	83 ec 04             	sub    $0x4,%esp
  8001d7:	ff 75 e4             	pushl  -0x1c(%ebp)
  8001da:	ff 75 e0             	pushl  -0x20(%ebp)
  8001dd:	ff 75 dc             	pushl  -0x24(%ebp)
  8001e0:	ff 75 d8             	pushl  -0x28(%ebp)
  8001e3:	e8 88 0b 00 00       	call   800d70 <__umoddi3>
  8001e8:	83 c4 14             	add    $0x14,%esp
  8001eb:	0f be 80 08 0f 80 00 	movsbl 0x800f08(%eax),%eax
  8001f2:	50                   	push   %eax
  8001f3:	ff d7                	call   *%edi
}
  8001f5:	83 c4 10             	add    $0x10,%esp
  8001f8:	8d 65 f4             	lea    -0xc(%ebp),%esp
  8001fb:	5b                   	pop    %ebx
  8001fc:	5e                   	pop    %esi
  8001fd:	5f                   	pop    %edi
  8001fe:	5d                   	pop    %ebp
  8001ff:	c3                   	ret    

00800200 <getuint>:

// Get an unsigned int of various possible sizes from a varargs list,
// depending on the lflag parameter.
static unsigned long long
getuint(va_list *ap, int lflag)
{
  800200:	55                   	push   %ebp
  800201:	89 e5                	mov    %esp,%ebp
	if (lflag >= 2)
  800203:	83 fa 01             	cmp    $0x1,%edx
  800206:	7e 0e                	jle    800216 <getuint+0x16>
		return va_arg(*ap, unsigned long long);
  800208:	8b 10                	mov    (%eax),%edx
  80020a:	8d 4a 08             	lea    0x8(%edx),%ecx
  80020d:	89 08                	mov    %ecx,(%eax)
  80020f:	8b 02                	mov    (%edx),%eax
  800211:	8b 52 04             	mov    0x4(%edx),%edx
  800214:	eb 22                	jmp    800238 <getuint+0x38>
	else if (lflag)
  800216:	85 d2                	test   %edx,%edx
  800218:	74 10                	je     80022a <getuint+0x2a>
		return va_arg(*ap, unsigned long);
  80021a:	8b 10                	mov    (%eax),%edx
  80021c:	8d 4a 04             	lea    0x4(%edx),%ecx
  80021f:	89 08                	mov    %ecx,(%eax)
  800221:	8b 02                	mov    (%edx),%eax
  800223:	ba 00 00 00 00       	mov    $0x0,%edx
  800228:	eb 0e                	jmp    800238 <getuint+0x38>
	else
		return va_arg(*ap, unsigned int);
  80022a:	8b 10                	mov    (%eax),%edx
  80022c:	8d 4a 04             	lea    0x4(%edx),%ecx
  80022f:	89 08                	mov    %ecx,(%eax)
  800231:	8b 02                	mov    (%edx),%eax
  800233:	ba 00 00 00 00       	mov    $0x0,%edx
}
  800238:	5d                   	pop    %ebp
  800239:	c3                   	ret    

0080023a <getint>:

// Same as getuint but signed - can't use getuint
// because of sign extension
static long long
getint(va_list *ap, int lflag)
{
  80023a:	55                   	push   %ebp
  80023b:	89 e5                	mov    %esp,%ebp
	if (lflag >= 2)
  80023d:	83 fa 01             	cmp    $0x1,%edx
  800240:	7e 0e                	jle    800250 <getint+0x16>
		return va_arg(*ap, long long);
  800242:	8b 10                	mov    (%eax),%edx
  800244:	8d 4a 08             	lea    0x8(%edx),%ecx
  800247:	89 08                	mov    %ecx,(%eax)
  800249:	8b 02                	mov    (%edx),%eax
  80024b:	8b 52 04             	mov    0x4(%edx),%edx
  80024e:	eb 1a                	jmp    80026a <getint+0x30>
	else if (lflag)
  800250:	85 d2                	test   %edx,%edx
  800252:	74 0c                	je     800260 <getint+0x26>
		return va_arg(*ap, long);
  800254:	8b 10                	mov    (%eax),%edx
  800256:	8d 4a 04             	lea    0x4(%edx),%ecx
  800259:	89 08                	mov    %ecx,(%eax)
  80025b:	8b 02                	mov    (%edx),%eax
  80025d:	99                   	cltd   
  80025e:	eb 0a                	jmp    80026a <getint+0x30>
	else
		return va_arg(*ap, int);
  800260:	8b 10                	mov    (%eax),%edx
  800262:	8d 4a 04             	lea    0x4(%edx),%ecx
  800265:	89 08                	mov    %ecx,(%eax)
  800267:	8b 02                	mov    (%edx),%eax
  800269:	99                   	cltd   
}
  80026a:	5d                   	pop    %ebp
  80026b:	c3                   	ret    

0080026c <sprintputch>:
	int cnt;
};

static void
sprintputch(int ch, struct sprintbuf *b)
{
  80026c:	55                   	push   %ebp
  80026d:	89 e5                	mov    %esp,%ebp
  80026f:	8b 45 0c             	mov    0xc(%ebp),%eax
	b->cnt++;
  800272:	83 40 08 01          	addl   $0x1,0x8(%eax)
	if (b->buf < b->ebuf)
  800276:	8b 10                	mov    (%eax),%edx
  800278:	3b 50 04             	cmp    0x4(%eax),%edx
  80027b:	73 0a                	jae    800287 <sprintputch+0x1b>
		*b->buf++ = ch;
  80027d:	8d 4a 01             	lea    0x1(%edx),%ecx
  800280:	89 08                	mov    %ecx,(%eax)
  800282:	8b 45 08             	mov    0x8(%ebp),%eax
  800285:	88 02                	mov    %al,(%edx)
}
  800287:	5d                   	pop    %ebp
  800288:	c3                   	ret    

00800289 <printfmt>:
	}
}

void
printfmt(void (*putch)(int, void*), void *putdat, const char *fmt, ...)
{
  800289:	55                   	push   %ebp
  80028a:	89 e5                	mov    %esp,%ebp
  80028c:	83 ec 08             	sub    $0x8,%esp
	va_list ap;

	va_start(ap, fmt);
  80028f:	8d 45 14             	lea    0x14(%ebp),%eax
	vprintfmt(putch, putdat, fmt, ap);
  800292:	50                   	push   %eax
  800293:	ff 75 10             	pushl  0x10(%ebp)
  800296:	ff 75 0c             	pushl  0xc(%ebp)
  800299:	ff 75 08             	pushl  0x8(%ebp)
  80029c:	e8 05 00 00 00       	call   8002a6 <vprintfmt>
	va_end(ap);
}
  8002a1:	83 c4 10             	add    $0x10,%esp
  8002a4:	c9                   	leave  
  8002a5:	c3                   	ret    

008002a6 <vprintfmt>:
// Main function to format and print a string.
void printfmt(void (*putch)(int, void*), void *putdat, const char *fmt, ...);

void
vprintfmt(void (*putch)(int, void*), void *putdat, const char *fmt, va_list ap)
{
  8002a6:	55                   	push   %ebp
  8002a7:	89 e5                	mov    %esp,%ebp
  8002a9:	57                   	push   %edi
  8002aa:	56                   	push   %esi
  8002ab:	53                   	push   %ebx
  8002ac:	83 ec 2c             	sub    $0x2c,%esp
  8002af:	8b 75 08             	mov    0x8(%ebp),%esi
  8002b2:	8b 5d 0c             	mov    0xc(%ebp),%ebx
  8002b5:	8b 7d 10             	mov    0x10(%ebp),%edi
  8002b8:	eb 12                	jmp    8002cc <vprintfmt+0x26>
	int base, lflag, width, precision, altflag;
	char padc;

	while (1) {
		while ((ch = *(unsigned char *) fmt++) != '%') {
			if (ch == '\0')
  8002ba:	85 c0                	test   %eax,%eax
  8002bc:	0f 84 44 03 00 00    	je     800606 <vprintfmt+0x360>
				return;
			putch(ch, putdat);
  8002c2:	83 ec 08             	sub    $0x8,%esp
  8002c5:	53                   	push   %ebx
  8002c6:	50                   	push   %eax
  8002c7:	ff d6                	call   *%esi
  8002c9:	83 c4 10             	add    $0x10,%esp
	unsigned long long num;
	int base, lflag, width, precision, altflag;
	char padc;

	while (1) {
		while ((ch = *(unsigned char *) fmt++) != '%') {
  8002cc:	83 c7 01             	add    $0x1,%edi
  8002cf:	0f b6 47 ff          	movzbl -0x1(%edi),%eax
  8002d3:	83 f8 25             	cmp    $0x25,%eax
  8002d6:	75 e2                	jne    8002ba <vprintfmt+0x14>
  8002d8:	c6 45 d4 20          	movb   $0x20,-0x2c(%ebp)
  8002dc:	c7 45 d8 00 00 00 00 	movl   $0x0,-0x28(%ebp)
  8002e3:	c7 45 d0 ff ff ff ff 	movl   $0xffffffff,-0x30(%ebp)
  8002ea:	c7 45 e0 ff ff ff ff 	movl   $0xffffffff,-0x20(%ebp)
  8002f1:	ba 00 00 00 00       	mov    $0x0,%edx
  8002f6:	eb 07                	jmp    8002ff <vprintfmt+0x59>
		width = -1;
		precision = -1;
		lflag = 0;
		altflag = 0;
	reswitch:
		switch (ch = *(unsigned char *) fmt++) {
  8002f8:	8b 7d e4             	mov    -0x1c(%ebp),%edi

		// flag to pad on the right
		case '-':
			padc = '-';
  8002fb:	c6 45 d4 2d          	movb   $0x2d,-0x2c(%ebp)
		width = -1;
		precision = -1;
		lflag = 0;
		altflag = 0;
	reswitch:
		switch (ch = *(unsigned char *) fmt++) {
  8002ff:	8d 47 01             	lea    0x1(%edi),%eax
  800302:	89 45 e4             	mov    %eax,-0x1c(%ebp)
  800305:	0f b6 07             	movzbl (%edi),%eax
  800308:	0f b6 c8             	movzbl %al,%ecx
  80030b:	83 e8 23             	sub    $0x23,%eax
  80030e:	3c 55                	cmp    $0x55,%al
  800310:	0f 87 d5 02 00 00    	ja     8005eb <vprintfmt+0x345>
  800316:	0f b6 c0             	movzbl %al,%eax
  800319:	ff 24 85 c0 0f 80 00 	jmp    *0x800fc0(,%eax,4)
  800320:	8b 7d e4             	mov    -0x1c(%ebp),%edi
			padc = '-';
			goto reswitch;

		// flag to pad with 0's instead of spaces
		case '0':
			padc = '0';
  800323:	c6 45 d4 30          	movb   $0x30,-0x2c(%ebp)
  800327:	eb d6                	jmp    8002ff <vprintfmt+0x59>
		width = -1;
		precision = -1;
		lflag = 0;
		altflag = 0;
	reswitch:
		switch (ch = *(unsigned char *) fmt++) {
  800329:	8b 7d e4             	mov    -0x1c(%ebp),%edi
  80032c:	b8 00 00 00 00       	mov    $0x0,%eax
  800331:	89 55 e4             	mov    %edx,-0x1c(%ebp)
		case '6':
		case '7':
		case '8':
		case '9':
			for (precision = 0; ; ++fmt) {
				precision = precision * 10 + ch - '0';
  800334:	8d 04 80             	lea    (%eax,%eax,4),%eax
  800337:	8d 44 41 d0          	lea    -0x30(%ecx,%eax,2),%eax
				ch = *fmt;
  80033b:	0f be 0f             	movsbl (%edi),%ecx
				if (ch < '0' || ch > '9')
  80033e:	8d 51 d0             	lea    -0x30(%ecx),%edx
  800341:	83 fa 09             	cmp    $0x9,%edx
  800344:	77 39                	ja     80037f <vprintfmt+0xd9>
		case '5':
		case '6':
		case '7':
		case '8':
		case '9':
			for (precision = 0; ; ++fmt) {
  800346:	83 c7 01             	add    $0x1,%edi
				precision = precision * 10 + ch - '0';
				ch = *fmt;
				if (ch < '0' || ch > '9')
					break;
			}
  800349:	eb e9                	jmp    800334 <vprintfmt+0x8e>
			goto process_precision;

		case '*':
			precision = va_arg(ap, int);
  80034b:	8b 45 14             	mov    0x14(%ebp),%eax
  80034e:	8d 48 04             	lea    0x4(%eax),%ecx
  800351:	89 4d 14             	mov    %ecx,0x14(%ebp)
  800354:	8b 00                	mov    (%eax),%eax
  800356:	89 45 d0             	mov    %eax,-0x30(%ebp)
		width = -1;
		precision = -1;
		lflag = 0;
		altflag = 0;
	reswitch:
		switch (ch = *(unsigned char *) fmt++) {
  800359:	8b 7d e4             	mov    -0x1c(%ebp),%edi
			}
			goto process_precision;

		case '*':
			precision = va_arg(ap, int);
			goto process_precision;
  80035c:	eb 27                	jmp    800385 <vprintfmt+0xdf>
  80035e:	8b 45 e0             	mov    -0x20(%ebp),%eax
  800361:	85 c0                	test   %eax,%eax
  800363:	b9 00 00 00 00       	mov    $0x0,%ecx
  800368:	0f 49 c8             	cmovns %eax,%ecx
  80036b:	89 4d e0             	mov    %ecx,-0x20(%ebp)
		width = -1;
		precision = -1;
		lflag = 0;
		altflag = 0;
	reswitch:
		switch (ch = *(unsigned char *) fmt++) {
  80036e:	8b 7d e4             	mov    -0x1c(%ebp),%edi
  800371:	eb 8c                	jmp    8002ff <vprintfmt+0x59>
  800373:	8b 7d e4             	mov    -0x1c(%ebp),%edi
			if (width < 0)
				width = 0;
			goto reswitch;

		case '#':
			altflag = 1;
  800376:	c7 45 d8 01 00 00 00 	movl   $0x1,-0x28(%ebp)
			goto reswitch;
  80037d:	eb 80                	jmp    8002ff <vprintfmt+0x59>
  80037f:	8b 55 e4             	mov    -0x1c(%ebp),%edx
  800382:	89 45 d0             	mov    %eax,-0x30(%ebp)

		process_precision:
			if (width < 0)
  800385:	83 7d e0 00          	cmpl   $0x0,-0x20(%ebp)
  800389:	0f 89 70 ff ff ff    	jns    8002ff <vprintfmt+0x59>
				width = precision, precision = -1;
  80038f:	8b 45 d0             	mov    -0x30(%ebp),%eax
  800392:	89 45 e0             	mov    %eax,-0x20(%ebp)
  800395:	c7 45 d0 ff ff ff ff 	movl   $0xffffffff,-0x30(%ebp)
  80039c:	e9 5e ff ff ff       	jmp    8002ff <vprintfmt+0x59>
			goto reswitch;

		// long flag (doubled for long long)
		case 'l':
			lflag++;
  8003a1:	83 c2 01             	add    $0x1,%edx
		width = -1;
		precision = -1;
		lflag = 0;
		altflag = 0;
	reswitch:
		switch (ch = *(unsigned char *) fmt++) {
  8003a4:	8b 7d e4             	mov    -0x1c(%ebp),%edi
			goto reswitch;

		// long flag (doubled for long long)
		case 'l':
			lflag++;
			goto reswitch;
  8003a7:	e9 53 ff ff ff       	jmp    8002ff <vprintfmt+0x59>

		// character
		case 'c':
			putch(va_arg(ap, int), putdat);
  8003ac:	8b 45 14             	mov    0x14(%ebp),%eax
  8003af:	8d 50 04             	lea    0x4(%eax),%edx
  8003b2:	89 55 14             	mov    %edx,0x14(%ebp)
  8003b5:	83 ec 08             	sub    $0x8,%esp
  8003b8:	53                   	push   %ebx
  8003b9:	ff 30                	pushl  (%eax)
  8003bb:	ff d6                	call   *%esi
			break;
  8003bd:	83 c4 10             	add    $0x10,%esp
		width = -1;
		precision = -1;
		lflag = 0;
		altflag = 0;
	reswitch:
		switch (ch = *(unsigned char *) fmt++) {
  8003c0:	8b 7d e4             	mov    -0x1c(%ebp),%edi
			goto reswitch;

		// character
		case 'c':
			putch(va_arg(ap, int), putdat);
			break;
  8003c3:	e9 04 ff ff ff       	jmp    8002cc <vprintfmt+0x26>

		// error message
		case 'e':
			err = va_arg(ap, int);
  8003c8:	8b 45 14             	mov    0x14(%ebp),%eax
  8003cb:	8d 50 04             	lea    0x4(%eax),%edx
  8003ce:	89 55 14             	mov    %edx,0x14(%ebp)
  8003d1:	8b 00                	mov    (%eax),%eax
  8003d3:	99                   	cltd   
  8003d4:	31 d0                	xor    %edx,%eax
  8003d6:	29 d0                	sub    %edx,%eax
			if (err < 0)
				err = -err;
			if (err >= MAXERROR || (p = error_string[err]) == NULL)
  8003d8:	83 f8 08             	cmp    $0x8,%eax
  8003db:	7f 0b                	jg     8003e8 <vprintfmt+0x142>
  8003dd:	8b 14 85 20 11 80 00 	mov    0x801120(,%eax,4),%edx
  8003e4:	85 d2                	test   %edx,%edx
  8003e6:	75 18                	jne    800400 <vprintfmt+0x15a>
				printfmt(putch, putdat, "error %d", err);
  8003e8:	50                   	push   %eax
  8003e9:	68 20 0f 80 00       	push   $0x800f20
  8003ee:	53                   	push   %ebx
  8003ef:	56                   	push   %esi
  8003f0:	e8 94 fe ff ff       	call   800289 <printfmt>
  8003f5:	83 c4 10             	add    $0x10,%esp
		width = -1;
		precision = -1;
		lflag = 0;
		altflag = 0;
	reswitch:
		switch (ch = *(unsigned char *) fmt++) {
  8003f8:	8b 7d e4             	mov    -0x1c(%ebp),%edi
		case 'e':
			err = va_arg(ap, int);
			if (err < 0)
				err = -err;
			if (err >= MAXERROR || (p = error_string[err]) == NULL)
				printfmt(putch, putdat, "error %d", err);
  8003fb:	e9 cc fe ff ff       	jmp    8002cc <vprintfmt+0x26>
			else
				printfmt(putch, putdat, "%s", p);
  800400:	52                   	push   %edx
  800401:	68 29 0f 80 00       	push   $0x800f29
  800406:	53                   	push   %ebx
  800407:	56                   	push   %esi
  800408:	e8 7c fe ff ff       	call   800289 <printfmt>
  80040d:	83 c4 10             	add    $0x10,%esp
		width = -1;
		precision = -1;
		lflag = 0;
		altflag = 0;
	reswitch:
		switch (ch = *(unsigned char *) fmt++) {
  800410:	8b 7d e4             	mov    -0x1c(%ebp),%edi
  800413:	e9 b4 fe ff ff       	jmp    8002cc <vprintfmt+0x26>
				printfmt(putch, putdat, "%s", p);
			break;

		// string
		case 's':
			if ((p = va_arg(ap, char *)) == NULL)
  800418:	8b 45 14             	mov    0x14(%ebp),%eax
  80041b:	8d 50 04             	lea    0x4(%eax),%edx
  80041e:	89 55 14             	mov    %edx,0x14(%ebp)
  800421:	8b 38                	mov    (%eax),%edi
				p = "(null)";
  800423:	85 ff                	test   %edi,%edi
  800425:	b8 19 0f 80 00       	mov    $0x800f19,%eax
  80042a:	0f 44 f8             	cmove  %eax,%edi
			if (width > 0 && padc != '-')
  80042d:	83 7d e0 00          	cmpl   $0x0,-0x20(%ebp)
  800431:	0f 8e 94 00 00 00    	jle    8004cb <vprintfmt+0x225>
  800437:	80 7d d4 2d          	cmpb   $0x2d,-0x2c(%ebp)
  80043b:	0f 84 98 00 00 00    	je     8004d9 <vprintfmt+0x233>
				for (width -= strnlen(p, precision); width > 0; width--)
  800441:	83 ec 08             	sub    $0x8,%esp
  800444:	ff 75 d0             	pushl  -0x30(%ebp)
  800447:	57                   	push   %edi
  800448:	e8 41 02 00 00       	call   80068e <strnlen>
  80044d:	8b 4d e0             	mov    -0x20(%ebp),%ecx
  800450:	29 c1                	sub    %eax,%ecx
  800452:	89 4d cc             	mov    %ecx,-0x34(%ebp)
  800455:	83 c4 10             	add    $0x10,%esp
					putch(padc, putdat);
  800458:	0f be 45 d4          	movsbl -0x2c(%ebp),%eax
  80045c:	89 45 e0             	mov    %eax,-0x20(%ebp)
  80045f:	89 7d d4             	mov    %edi,-0x2c(%ebp)
  800462:	89 cf                	mov    %ecx,%edi
		// string
		case 's':
			if ((p = va_arg(ap, char *)) == NULL)
				p = "(null)";
			if (width > 0 && padc != '-')
				for (width -= strnlen(p, precision); width > 0; width--)
  800464:	eb 0f                	jmp    800475 <vprintfmt+0x1cf>
					putch(padc, putdat);
  800466:	83 ec 08             	sub    $0x8,%esp
  800469:	53                   	push   %ebx
  80046a:	ff 75 e0             	pushl  -0x20(%ebp)
  80046d:	ff d6                	call   *%esi
		// string
		case 's':
			if ((p = va_arg(ap, char *)) == NULL)
				p = "(null)";
			if (width > 0 && padc != '-')
				for (width -= strnlen(p, precision); width > 0; width--)
  80046f:	83 ef 01             	sub    $0x1,%edi
  800472:	83 c4 10             	add    $0x10,%esp
  800475:	85 ff                	test   %edi,%edi
  800477:	7f ed                	jg     800466 <vprintfmt+0x1c0>
  800479:	8b 7d d4             	mov    -0x2c(%ebp),%edi
  80047c:	8b 4d cc             	mov    -0x34(%ebp),%ecx
  80047f:	85 c9                	test   %ecx,%ecx
  800481:	b8 00 00 00 00       	mov    $0x0,%eax
  800486:	0f 49 c1             	cmovns %ecx,%eax
  800489:	29 c1                	sub    %eax,%ecx
  80048b:	89 75 08             	mov    %esi,0x8(%ebp)
  80048e:	8b 75 d0             	mov    -0x30(%ebp),%esi
  800491:	89 5d 0c             	mov    %ebx,0xc(%ebp)
  800494:	89 cb                	mov    %ecx,%ebx
  800496:	eb 4d                	jmp    8004e5 <vprintfmt+0x23f>
					putch(padc, putdat);
			for (; (ch = *p++) != '\0' && (precision < 0 || --precision >= 0); width--)
				if (altflag && (ch < ' ' || ch > '~'))
  800498:	83 7d d8 00          	cmpl   $0x0,-0x28(%ebp)
  80049c:	74 1b                	je     8004b9 <vprintfmt+0x213>
  80049e:	0f be c0             	movsbl %al,%eax
  8004a1:	83 e8 20             	sub    $0x20,%eax
  8004a4:	83 f8 5e             	cmp    $0x5e,%eax
  8004a7:	76 10                	jbe    8004b9 <vprintfmt+0x213>
					putch('?', putdat);
  8004a9:	83 ec 08             	sub    $0x8,%esp
  8004ac:	ff 75 0c             	pushl  0xc(%ebp)
  8004af:	6a 3f                	push   $0x3f
  8004b1:	ff 55 08             	call   *0x8(%ebp)
  8004b4:	83 c4 10             	add    $0x10,%esp
  8004b7:	eb 0d                	jmp    8004c6 <vprintfmt+0x220>
				else
					putch(ch, putdat);
  8004b9:	83 ec 08             	sub    $0x8,%esp
  8004bc:	ff 75 0c             	pushl  0xc(%ebp)
  8004bf:	52                   	push   %edx
  8004c0:	ff 55 08             	call   *0x8(%ebp)
  8004c3:	83 c4 10             	add    $0x10,%esp
			if ((p = va_arg(ap, char *)) == NULL)
				p = "(null)";
			if (width > 0 && padc != '-')
				for (width -= strnlen(p, precision); width > 0; width--)
					putch(padc, putdat);
			for (; (ch = *p++) != '\0' && (precision < 0 || --precision >= 0); width--)
  8004c6:	83 eb 01             	sub    $0x1,%ebx
  8004c9:	eb 1a                	jmp    8004e5 <vprintfmt+0x23f>
  8004cb:	89 75 08             	mov    %esi,0x8(%ebp)
  8004ce:	8b 75 d0             	mov    -0x30(%ebp),%esi
  8004d1:	89 5d 0c             	mov    %ebx,0xc(%ebp)
  8004d4:	8b 5d e0             	mov    -0x20(%ebp),%ebx
  8004d7:	eb 0c                	jmp    8004e5 <vprintfmt+0x23f>
  8004d9:	89 75 08             	mov    %esi,0x8(%ebp)
  8004dc:	8b 75 d0             	mov    -0x30(%ebp),%esi
  8004df:	89 5d 0c             	mov    %ebx,0xc(%ebp)
  8004e2:	8b 5d e0             	mov    -0x20(%ebp),%ebx
  8004e5:	83 c7 01             	add    $0x1,%edi
  8004e8:	0f b6 47 ff          	movzbl -0x1(%edi),%eax
  8004ec:	0f be d0             	movsbl %al,%edx
  8004ef:	85 d2                	test   %edx,%edx
  8004f1:	74 23                	je     800516 <vprintfmt+0x270>
  8004f3:	85 f6                	test   %esi,%esi
  8004f5:	78 a1                	js     800498 <vprintfmt+0x1f2>
  8004f7:	83 ee 01             	sub    $0x1,%esi
  8004fa:	79 9c                	jns    800498 <vprintfmt+0x1f2>
  8004fc:	89 df                	mov    %ebx,%edi
  8004fe:	8b 75 08             	mov    0x8(%ebp),%esi
  800501:	8b 5d 0c             	mov    0xc(%ebp),%ebx
  800504:	eb 18                	jmp    80051e <vprintfmt+0x278>
				if (altflag && (ch < ' ' || ch > '~'))
					putch('?', putdat);
				else
					putch(ch, putdat);
			for (; width > 0; width--)
				putch(' ', putdat);
  800506:	83 ec 08             	sub    $0x8,%esp
  800509:	53                   	push   %ebx
  80050a:	6a 20                	push   $0x20
  80050c:	ff d6                	call   *%esi
			for (; (ch = *p++) != '\0' && (precision < 0 || --precision >= 0); width--)
				if (altflag && (ch < ' ' || ch > '~'))
					putch('?', putdat);
				else
					putch(ch, putdat);
			for (; width > 0; width--)
  80050e:	83 ef 01             	sub    $0x1,%edi
  800511:	83 c4 10             	add    $0x10,%esp
  800514:	eb 08                	jmp    80051e <vprintfmt+0x278>
  800516:	89 df                	mov    %ebx,%edi
  800518:	8b 75 08             	mov    0x8(%ebp),%esi
  80051b:	8b 5d 0c             	mov    0xc(%ebp),%ebx
  80051e:	85 ff                	test   %edi,%edi
  800520:	7f e4                	jg     800506 <vprintfmt+0x260>
		width = -1;
		precision = -1;
		lflag = 0;
		altflag = 0;
	reswitch:
		switch (ch = *(unsigned char *) fmt++) {
  800522:	8b 7d e4             	mov    -0x1c(%ebp),%edi
  800525:	e9 a2 fd ff ff       	jmp    8002cc <vprintfmt+0x26>
				putch(' ', putdat);
			break;

		// (signed) decimal
		case 'd':
			num = getint(&ap, lflag);
  80052a:	8d 45 14             	lea    0x14(%ebp),%eax
  80052d:	e8 08 fd ff ff       	call   80023a <getint>
  800532:	89 45 d8             	mov    %eax,-0x28(%ebp)
  800535:	89 55 dc             	mov    %edx,-0x24(%ebp)
			if ((long long) num < 0) {
				putch('-', putdat);
				num = -(long long) num;
			}
			base = 10;
  800538:	b9 0a 00 00 00       	mov    $0xa,%ecx
			break;

		// (signed) decimal
		case 'd':
			num = getint(&ap, lflag);
			if ((long long) num < 0) {
  80053d:	83 7d dc 00          	cmpl   $0x0,-0x24(%ebp)
  800541:	79 74                	jns    8005b7 <vprintfmt+0x311>
				putch('-', putdat);
  800543:	83 ec 08             	sub    $0x8,%esp
  800546:	53                   	push   %ebx
  800547:	6a 2d                	push   $0x2d
  800549:	ff d6                	call   *%esi
				num = -(long long) num;
  80054b:	8b 45 d8             	mov    -0x28(%ebp),%eax
  80054e:	8b 55 dc             	mov    -0x24(%ebp),%edx
  800551:	f7 d8                	neg    %eax
  800553:	83 d2 00             	adc    $0x0,%edx
  800556:	f7 da                	neg    %edx
  800558:	83 c4 10             	add    $0x10,%esp
			}
			base = 10;
  80055b:	b9 0a 00 00 00       	mov    $0xa,%ecx
  800560:	eb 55                	jmp    8005b7 <vprintfmt+0x311>
			goto number;

		// unsigned decimal
		case 'u':
			num = getuint(&ap, lflag);
  800562:	8d 45 14             	lea    0x14(%ebp),%eax
  800565:	e8 96 fc ff ff       	call   800200 <getuint>
			base = 10;
  80056a:	b9 0a 00 00 00       	mov    $0xa,%ecx
			goto number;
  80056f:	eb 46                	jmp    8005b7 <vprintfmt+0x311>

		// (unsigned) octal
		case 'o':
			num = getuint(&ap, lflag);
  800571:	8d 45 14             	lea    0x14(%ebp),%eax
  800574:	e8 87 fc ff ff       	call   800200 <getuint>
			base = 8;
  800579:	b9 08 00 00 00       	mov    $0x8,%ecx
			goto number;
  80057e:	eb 37                	jmp    8005b7 <vprintfmt+0x311>

		// pointer
		case 'p':
			putch('0', putdat);
  800580:	83 ec 08             	sub    $0x8,%esp
  800583:	53                   	push   %ebx
  800584:	6a 30                	push   $0x30
  800586:	ff d6                	call   *%esi
			putch('x', putdat);
  800588:	83 c4 08             	add    $0x8,%esp
  80058b:	53                   	push   %ebx
  80058c:	6a 78                	push   $0x78
  80058e:	ff d6                	call   *%esi
			num = (unsigned long long)
				(uintptr_t) va_arg(ap, void *);
  800590:	8b 45 14             	mov    0x14(%ebp),%eax
  800593:	8d 50 04             	lea    0x4(%eax),%edx
  800596:	89 55 14             	mov    %edx,0x14(%ebp)

		// pointer
		case 'p':
			putch('0', putdat);
			putch('x', putdat);
			num = (unsigned long long)
  800599:	8b 00                	mov    (%eax),%eax
  80059b:	ba 00 00 00 00       	mov    $0x0,%edx
				(uintptr_t) va_arg(ap, void *);
			base = 16;
			goto number;
  8005a0:	83 c4 10             	add    $0x10,%esp
		case 'p':
			putch('0', putdat);
			putch('x', putdat);
			num = (unsigned long long)
				(uintptr_t) va_arg(ap, void *);
			base = 16;
  8005a3:	b9 10 00 00 00       	mov    $0x10,%ecx
			goto number;
  8005a8:	eb 0d                	jmp    8005b7 <vprintfmt+0x311>

		// (unsigned) hexadecimal
		case 'x':
			num = getuint(&ap, lflag);
  8005aa:	8d 45 14             	lea    0x14(%ebp),%eax
  8005ad:	e8 4e fc ff ff       	call   800200 <getuint>
			base = 16;
  8005b2:	b9 10 00 00 00       	mov    $0x10,%ecx
		number:
			printnum(putch, putdat, num, base, width, padc);
  8005b7:	83 ec 0c             	sub    $0xc,%esp
  8005ba:	0f be 7d d4          	movsbl -0x2c(%ebp),%edi
  8005be:	57                   	push   %edi
  8005bf:	ff 75 e0             	pushl  -0x20(%ebp)
  8005c2:	51                   	push   %ecx
  8005c3:	52                   	push   %edx
  8005c4:	50                   	push   %eax
  8005c5:	89 da                	mov    %ebx,%edx
  8005c7:	89 f0                	mov    %esi,%eax
  8005c9:	e8 83 fb ff ff       	call   800151 <printnum>
			break;
  8005ce:	83 c4 20             	add    $0x20,%esp
  8005d1:	8b 7d e4             	mov    -0x1c(%ebp),%edi
  8005d4:	e9 f3 fc ff ff       	jmp    8002cc <vprintfmt+0x26>

		// escaped '%' character
		case '%':
			putch(ch, putdat);
  8005d9:	83 ec 08             	sub    $0x8,%esp
  8005dc:	53                   	push   %ebx
  8005dd:	51                   	push   %ecx
  8005de:	ff d6                	call   *%esi
			break;
  8005e0:	83 c4 10             	add    $0x10,%esp
		width = -1;
		precision = -1;
		lflag = 0;
		altflag = 0;
	reswitch:
		switch (ch = *(unsigned char *) fmt++) {
  8005e3:	8b 7d e4             	mov    -0x1c(%ebp),%edi
			break;

		// escaped '%' character
		case '%':
			putch(ch, putdat);
			break;
  8005e6:	e9 e1 fc ff ff       	jmp    8002cc <vprintfmt+0x26>

		// unrecognized escape sequence - just print it literally
		default:
			putch('%', putdat);
  8005eb:	83 ec 08             	sub    $0x8,%esp
  8005ee:	53                   	push   %ebx
  8005ef:	6a 25                	push   $0x25
  8005f1:	ff d6                	call   *%esi
			for (fmt--; fmt[-1] != '%'; fmt--)
  8005f3:	83 c4 10             	add    $0x10,%esp
  8005f6:	eb 03                	jmp    8005fb <vprintfmt+0x355>
  8005f8:	83 ef 01             	sub    $0x1,%edi
  8005fb:	80 7f ff 25          	cmpb   $0x25,-0x1(%edi)
  8005ff:	75 f7                	jne    8005f8 <vprintfmt+0x352>
  800601:	e9 c6 fc ff ff       	jmp    8002cc <vprintfmt+0x26>
				/* do nothing */;
			break;
		}
	}
}
  800606:	8d 65 f4             	lea    -0xc(%ebp),%esp
  800609:	5b                   	pop    %ebx
  80060a:	5e                   	pop    %esi
  80060b:	5f                   	pop    %edi
  80060c:	5d                   	pop    %ebp
  80060d:	c3                   	ret    

0080060e <vsnprintf>:
		*b->buf++ = ch;
}

int
vsnprintf(char *buf, int n, const char *fmt, va_list ap)
{
  80060e:	55                   	push   %ebp
  80060f:	89 e5                	mov    %esp,%ebp
  800611:	83 ec 18             	sub    $0x18,%esp
  800614:	8b 45 08             	mov    0x8(%ebp),%eax
  800617:	8b 55 0c             	mov    0xc(%ebp),%edx
	struct sprintbuf b = {buf, buf+n-1, 0};
  80061a:	89 45 ec             	mov    %eax,-0x14(%ebp)
  80061d:	8d 4c 10 ff          	lea    -0x1(%eax,%edx,1),%ecx
  800621:	89 4d f0             	mov    %ecx,-0x10(%ebp)
  800624:	c7 45 f4 00 00 00 00 	movl   $0x0,-0xc(%ebp)

	if (buf == NULL || n < 1)
  80062b:	85 c0                	test   %eax,%eax
  80062d:	74 26                	je     800655 <vsnprintf+0x47>
  80062f:	85 d2                	test   %edx,%edx
  800631:	7e 22                	jle    800655 <vsnprintf+0x47>
		return -E_INVAL;

	// print the string to the buffer
	vprintfmt((void*)sprintputch, &b, fmt, ap);
  800633:	ff 75 14             	pushl  0x14(%ebp)
  800636:	ff 75 10             	pushl  0x10(%ebp)
  800639:	8d 45 ec             	lea    -0x14(%ebp),%eax
  80063c:	50                   	push   %eax
  80063d:	68 6c 02 80 00       	push   $0x80026c
  800642:	e8 5f fc ff ff       	call   8002a6 <vprintfmt>

	// null terminate the buffer
	*b.buf = '\0';
  800647:	8b 45 ec             	mov    -0x14(%ebp),%eax
  80064a:	c6 00 00             	movb   $0x0,(%eax)

	return b.cnt;
  80064d:	8b 45 f4             	mov    -0xc(%ebp),%eax
  800650:	83 c4 10             	add    $0x10,%esp
  800653:	eb 05                	jmp    80065a <vsnprintf+0x4c>
vsnprintf(char *buf, int n, const char *fmt, va_list ap)
{
	struct sprintbuf b = {buf, buf+n-1, 0};

	if (buf == NULL || n < 1)
		return -E_INVAL;
  800655:	b8 fd ff ff ff       	mov    $0xfffffffd,%eax

	// null terminate the buffer
	*b.buf = '\0';

	return b.cnt;
}
  80065a:	c9                   	leave  
  80065b:	c3                   	ret    

0080065c <snprintf>:

int
snprintf(char *buf, int n, const char *fmt, ...)
{
  80065c:	55                   	push   %ebp
  80065d:	89 e5                	mov    %esp,%ebp
  80065f:	83 ec 08             	sub    $0x8,%esp
	va_list ap;
	int rc;

	va_start(ap, fmt);
  800662:	8d 45 14             	lea    0x14(%ebp),%eax
	rc = vsnprintf(buf, n, fmt, ap);
  800665:	50                   	push   %eax
  800666:	ff 75 10             	pushl  0x10(%ebp)
  800669:	ff 75 0c             	pushl  0xc(%ebp)
  80066c:	ff 75 08             	pushl  0x8(%ebp)
  80066f:	e8 9a ff ff ff       	call   80060e <vsnprintf>
	va_end(ap);

	return rc;
}
  800674:	c9                   	leave  
  800675:	c3                   	ret    

00800676 <strlen>:
// Primespipe runs 3x faster this way.
#define ASM 1

int
strlen(const char *s)
{
  800676:	55                   	push   %ebp
  800677:	89 e5                	mov    %esp,%ebp
  800679:	8b 55 08             	mov    0x8(%ebp),%edx
	int n;

	for (n = 0; *s != '\0'; s++)
  80067c:	b8 00 00 00 00       	mov    $0x0,%eax
  800681:	eb 03                	jmp    800686 <strlen+0x10>
		n++;
  800683:	83 c0 01             	add    $0x1,%eax
int
strlen(const char *s)
{
	int n;

	for (n = 0; *s != '\0'; s++)
  800686:	80 3c 02 00          	cmpb   $0x0,(%edx,%eax,1)
  80068a:	75 f7                	jne    800683 <strlen+0xd>
		n++;
	return n;
}
  80068c:	5d                   	pop    %ebp
  80068d:	c3                   	ret    

0080068e <strnlen>:

int
strnlen(const char *s, size_t size)
{
  80068e:	55                   	push   %ebp
  80068f:	89 e5                	mov    %esp,%ebp
  800691:	8b 4d 08             	mov    0x8(%ebp),%ecx
  800694:	8b 45 0c             	mov    0xc(%ebp),%eax
	int n;

	for (n = 0; size > 0 && *s != '\0'; s++, size--)
  800697:	ba 00 00 00 00       	mov    $0x0,%edx
  80069c:	eb 03                	jmp    8006a1 <strnlen+0x13>
		n++;
  80069e:	83 c2 01             	add    $0x1,%edx
int
strnlen(const char *s, size_t size)
{
	int n;

	for (n = 0; size > 0 && *s != '\0'; s++, size--)
  8006a1:	39 c2                	cmp    %eax,%edx
  8006a3:	74 08                	je     8006ad <strnlen+0x1f>
  8006a5:	80 3c 11 00          	cmpb   $0x0,(%ecx,%edx,1)
  8006a9:	75 f3                	jne    80069e <strnlen+0x10>
  8006ab:	89 d0                	mov    %edx,%eax
		n++;
	return n;
}
  8006ad:	5d                   	pop    %ebp
  8006ae:	c3                   	ret    

008006af <strcpy>:

char *
strcpy(char *dst, const char *src)
{
  8006af:	55                   	push   %ebp
  8006b0:	89 e5                	mov    %esp,%ebp
  8006b2:	53                   	push   %ebx
  8006b3:	8b 45 08             	mov    0x8(%ebp),%eax
  8006b6:	8b 4d 0c             	mov    0xc(%ebp),%ecx
	char *ret;

	ret = dst;
	while ((*dst++ = *src++) != '\0')
  8006b9:	89 c2                	mov    %eax,%edx
  8006bb:	83 c2 01             	add    $0x1,%edx
  8006be:	83 c1 01             	add    $0x1,%ecx
  8006c1:	0f b6 59 ff          	movzbl -0x1(%ecx),%ebx
  8006c5:	88 5a ff             	mov    %bl,-0x1(%edx)
  8006c8:	84 db                	test   %bl,%bl
  8006ca:	75 ef                	jne    8006bb <strcpy+0xc>
		/* do nothing */;
	return ret;
}
  8006cc:	5b                   	pop    %ebx
  8006cd:	5d                   	pop    %ebp
  8006ce:	c3                   	ret    

008006cf <strcat>:

char *
strcat(char *dst, const char *src)
{
  8006cf:	55                   	push   %ebp
  8006d0:	89 e5                	mov    %esp,%ebp
  8006d2:	53                   	push   %ebx
  8006d3:	8b 5d 08             	mov    0x8(%ebp),%ebx
	int len = strlen(dst);
  8006d6:	53                   	push   %ebx
  8006d7:	e8 9a ff ff ff       	call   800676 <strlen>
  8006dc:	83 c4 04             	add    $0x4,%esp
	strcpy(dst + len, src);
  8006df:	ff 75 0c             	pushl  0xc(%ebp)
  8006e2:	01 d8                	add    %ebx,%eax
  8006e4:	50                   	push   %eax
  8006e5:	e8 c5 ff ff ff       	call   8006af <strcpy>
	return dst;
}
  8006ea:	89 d8                	mov    %ebx,%eax
  8006ec:	8b 5d fc             	mov    -0x4(%ebp),%ebx
  8006ef:	c9                   	leave  
  8006f0:	c3                   	ret    

008006f1 <strncpy>:

char *
strncpy(char *dst, const char *src, size_t size) {
  8006f1:	55                   	push   %ebp
  8006f2:	89 e5                	mov    %esp,%ebp
  8006f4:	56                   	push   %esi
  8006f5:	53                   	push   %ebx
  8006f6:	8b 75 08             	mov    0x8(%ebp),%esi
  8006f9:	8b 4d 0c             	mov    0xc(%ebp),%ecx
  8006fc:	89 f3                	mov    %esi,%ebx
  8006fe:	03 5d 10             	add    0x10(%ebp),%ebx
	size_t i;
	char *ret;

	ret = dst;
	for (i = 0; i < size; i++) {
  800701:	89 f2                	mov    %esi,%edx
  800703:	eb 0f                	jmp    800714 <strncpy+0x23>
		*dst++ = *src;
  800705:	83 c2 01             	add    $0x1,%edx
  800708:	0f b6 01             	movzbl (%ecx),%eax
  80070b:	88 42 ff             	mov    %al,-0x1(%edx)
		// If strlen(src) < size, null-pad 'dst' out to 'size' chars
		if (*src != '\0')
			src++;
  80070e:	80 39 01             	cmpb   $0x1,(%ecx)
  800711:	83 d9 ff             	sbb    $0xffffffff,%ecx
strncpy(char *dst, const char *src, size_t size) {
	size_t i;
	char *ret;

	ret = dst;
	for (i = 0; i < size; i++) {
  800714:	39 da                	cmp    %ebx,%edx
  800716:	75 ed                	jne    800705 <strncpy+0x14>
		// If strlen(src) < size, null-pad 'dst' out to 'size' chars
		if (*src != '\0')
			src++;
	}
	return ret;
}
  800718:	89 f0                	mov    %esi,%eax
  80071a:	5b                   	pop    %ebx
  80071b:	5e                   	pop    %esi
  80071c:	5d                   	pop    %ebp
  80071d:	c3                   	ret    

0080071e <strlcpy>:

size_t
strlcpy(char *dst, const char *src, size_t size)
{
  80071e:	55                   	push   %ebp
  80071f:	89 e5                	mov    %esp,%ebp
  800721:	56                   	push   %esi
  800722:	53                   	push   %ebx
  800723:	8b 75 08             	mov    0x8(%ebp),%esi
  800726:	8b 4d 0c             	mov    0xc(%ebp),%ecx
  800729:	8b 55 10             	mov    0x10(%ebp),%edx
  80072c:	89 f0                	mov    %esi,%eax
	char *dst_in;

	dst_in = dst;
	if (size > 0) {
  80072e:	85 d2                	test   %edx,%edx
  800730:	74 21                	je     800753 <strlcpy+0x35>
  800732:	8d 44 16 ff          	lea    -0x1(%esi,%edx,1),%eax
  800736:	89 f2                	mov    %esi,%edx
  800738:	eb 09                	jmp    800743 <strlcpy+0x25>
		while (--size > 0 && *src != '\0')
			*dst++ = *src++;
  80073a:	83 c2 01             	add    $0x1,%edx
  80073d:	83 c1 01             	add    $0x1,%ecx
  800740:	88 5a ff             	mov    %bl,-0x1(%edx)
{
	char *dst_in;

	dst_in = dst;
	if (size > 0) {
		while (--size > 0 && *src != '\0')
  800743:	39 c2                	cmp    %eax,%edx
  800745:	74 09                	je     800750 <strlcpy+0x32>
  800747:	0f b6 19             	movzbl (%ecx),%ebx
  80074a:	84 db                	test   %bl,%bl
  80074c:	75 ec                	jne    80073a <strlcpy+0x1c>
  80074e:	89 d0                	mov    %edx,%eax
			*dst++ = *src++;
		*dst = '\0';
  800750:	c6 00 00             	movb   $0x0,(%eax)
	}
	return dst - dst_in;
  800753:	29 f0                	sub    %esi,%eax
}
  800755:	5b                   	pop    %ebx
  800756:	5e                   	pop    %esi
  800757:	5d                   	pop    %ebp
  800758:	c3                   	ret    

00800759 <strcmp>:

int
strcmp(const char *p, const char *q)
{
  800759:	55                   	push   %ebp
  80075a:	89 e5                	mov    %esp,%ebp
  80075c:	8b 4d 08             	mov    0x8(%ebp),%ecx
  80075f:	8b 55 0c             	mov    0xc(%ebp),%edx
	while (*p && *p == *q)
  800762:	eb 06                	jmp    80076a <strcmp+0x11>
		p++, q++;
  800764:	83 c1 01             	add    $0x1,%ecx
  800767:	83 c2 01             	add    $0x1,%edx
}

int
strcmp(const char *p, const char *q)
{
	while (*p && *p == *q)
  80076a:	0f b6 01             	movzbl (%ecx),%eax
  80076d:	84 c0                	test   %al,%al
  80076f:	74 04                	je     800775 <strcmp+0x1c>
  800771:	3a 02                	cmp    (%edx),%al
  800773:	74 ef                	je     800764 <strcmp+0xb>
		p++, q++;
	return (int) ((unsigned char) *p - (unsigned char) *q);
  800775:	0f b6 c0             	movzbl %al,%eax
  800778:	0f b6 12             	movzbl (%edx),%edx
  80077b:	29 d0                	sub    %edx,%eax
}
  80077d:	5d                   	pop    %ebp
  80077e:	c3                   	ret    

0080077f <strncmp>:

int
strncmp(const char *p, const char *q, size_t n)
{
  80077f:	55                   	push   %ebp
  800780:	89 e5                	mov    %esp,%ebp
  800782:	53                   	push   %ebx
  800783:	8b 45 08             	mov    0x8(%ebp),%eax
  800786:	8b 55 0c             	mov    0xc(%ebp),%edx
  800789:	89 c3                	mov    %eax,%ebx
  80078b:	03 5d 10             	add    0x10(%ebp),%ebx
	while (n > 0 && *p && *p == *q)
  80078e:	eb 06                	jmp    800796 <strncmp+0x17>
		n--, p++, q++;
  800790:	83 c0 01             	add    $0x1,%eax
  800793:	83 c2 01             	add    $0x1,%edx
}

int
strncmp(const char *p, const char *q, size_t n)
{
	while (n > 0 && *p && *p == *q)
  800796:	39 d8                	cmp    %ebx,%eax
  800798:	74 15                	je     8007af <strncmp+0x30>
  80079a:	0f b6 08             	movzbl (%eax),%ecx
  80079d:	84 c9                	test   %cl,%cl
  80079f:	74 04                	je     8007a5 <strncmp+0x26>
  8007a1:	3a 0a                	cmp    (%edx),%cl
  8007a3:	74 eb                	je     800790 <strncmp+0x11>
		n--, p++, q++;
	if (n == 0)
		return 0;
	else
		return (int) ((unsigned char) *p - (unsigned char) *q);
  8007a5:	0f b6 00             	movzbl (%eax),%eax
  8007a8:	0f b6 12             	movzbl (%edx),%edx
  8007ab:	29 d0                	sub    %edx,%eax
  8007ad:	eb 05                	jmp    8007b4 <strncmp+0x35>
strncmp(const char *p, const char *q, size_t n)
{
	while (n > 0 && *p && *p == *q)
		n--, p++, q++;
	if (n == 0)
		return 0;
  8007af:	b8 00 00 00 00       	mov    $0x0,%eax
	else
		return (int) ((unsigned char) *p - (unsigned char) *q);
}
  8007b4:	5b                   	pop    %ebx
  8007b5:	5d                   	pop    %ebp
  8007b6:	c3                   	ret    

008007b7 <strchr>:

// Return a pointer to the first occurrence of 'c' in 's',
// or a null pointer if the string has no 'c'.
char *
strchr(const char *s, char c)
{
  8007b7:	55                   	push   %ebp
  8007b8:	89 e5                	mov    %esp,%ebp
  8007ba:	8b 45 08             	mov    0x8(%ebp),%eax
  8007bd:	0f b6 4d 0c          	movzbl 0xc(%ebp),%ecx
	for (; *s; s++)
  8007c1:	eb 07                	jmp    8007ca <strchr+0x13>
		if (*s == c)
  8007c3:	38 ca                	cmp    %cl,%dl
  8007c5:	74 0f                	je     8007d6 <strchr+0x1f>
// Return a pointer to the first occurrence of 'c' in 's',
// or a null pointer if the string has no 'c'.
char *
strchr(const char *s, char c)
{
	for (; *s; s++)
  8007c7:	83 c0 01             	add    $0x1,%eax
  8007ca:	0f b6 10             	movzbl (%eax),%edx
  8007cd:	84 d2                	test   %dl,%dl
  8007cf:	75 f2                	jne    8007c3 <strchr+0xc>
		if (*s == c)
			return (char *) s;
	return 0;
  8007d1:	b8 00 00 00 00       	mov    $0x0,%eax
}
  8007d6:	5d                   	pop    %ebp
  8007d7:	c3                   	ret    

008007d8 <strfind>:

// Return a pointer to the first occurrence of 'c' in 's',
// or a pointer to the string-ending null character if the string has no 'c'.
char *
strfind(const char *s, char c)
{
  8007d8:	55                   	push   %ebp
  8007d9:	89 e5                	mov    %esp,%ebp
  8007db:	8b 45 08             	mov    0x8(%ebp),%eax
  8007de:	0f b6 4d 0c          	movzbl 0xc(%ebp),%ecx
	for (; *s; s++)
  8007e2:	eb 03                	jmp    8007e7 <strfind+0xf>
  8007e4:	83 c0 01             	add    $0x1,%eax
  8007e7:	0f b6 10             	movzbl (%eax),%edx
		if (*s == c)
  8007ea:	38 ca                	cmp    %cl,%dl
  8007ec:	74 04                	je     8007f2 <strfind+0x1a>
  8007ee:	84 d2                	test   %dl,%dl
  8007f0:	75 f2                	jne    8007e4 <strfind+0xc>
			break;
	return (char *) s;
}
  8007f2:	5d                   	pop    %ebp
  8007f3:	c3                   	ret    

008007f4 <memset>:

#if ASM
void *
memset(void *v, int c, size_t n)
{
  8007f4:	55                   	push   %ebp
  8007f5:	89 e5                	mov    %esp,%ebp
  8007f7:	57                   	push   %edi
  8007f8:	56                   	push   %esi
  8007f9:	53                   	push   %ebx
  8007fa:	8b 55 08             	mov    0x8(%ebp),%edx
  8007fd:	8b 4d 10             	mov    0x10(%ebp),%ecx
	char *p = v;

	if (n == 0)
  800800:	85 c9                	test   %ecx,%ecx
  800802:	74 37                	je     80083b <memset+0x47>
		return v;
	if ((int)v%4 == 0 && n%4 == 0) {
  800804:	f6 c2 03             	test   $0x3,%dl
  800807:	75 2a                	jne    800833 <memset+0x3f>
  800809:	f6 c1 03             	test   $0x3,%cl
  80080c:	75 25                	jne    800833 <memset+0x3f>
		c &= 0xFF;
  80080e:	0f b6 5d 0c          	movzbl 0xc(%ebp),%ebx
		c = (c<<24)|(c<<16)|(c<<8)|c;
  800812:	89 df                	mov    %ebx,%edi
  800814:	c1 e7 08             	shl    $0x8,%edi
  800817:	89 de                	mov    %ebx,%esi
  800819:	c1 e6 18             	shl    $0x18,%esi
  80081c:	89 d8                	mov    %ebx,%eax
  80081e:	c1 e0 10             	shl    $0x10,%eax
  800821:	09 f0                	or     %esi,%eax
  800823:	09 c3                	or     %eax,%ebx
		asm volatile("cld; rep stosl\n"
			: "=D" (p), "=c" (n)
			: "D" (p), "a" (c), "c" (n/4)
  800825:	c1 e9 02             	shr    $0x2,%ecx
	if (n == 0)
		return v;
	if ((int)v%4 == 0 && n%4 == 0) {
		c &= 0xFF;
		c = (c<<24)|(c<<16)|(c<<8)|c;
		asm volatile("cld; rep stosl\n"
  800828:	89 f8                	mov    %edi,%eax
  80082a:	09 d8                	or     %ebx,%eax
  80082c:	89 d7                	mov    %edx,%edi
  80082e:	fc                   	cld    
  80082f:	f3 ab                	rep stos %eax,%es:(%edi)
  800831:	eb 08                	jmp    80083b <memset+0x47>
			: "=D" (p), "=c" (n)
			: "D" (p), "a" (c), "c" (n/4)
			: "cc", "memory");
	} else
		asm volatile("cld; rep stosb\n"
  800833:	89 d7                	mov    %edx,%edi
  800835:	8b 45 0c             	mov    0xc(%ebp),%eax
  800838:	fc                   	cld    
  800839:	f3 aa                	rep stos %al,%es:(%edi)
			: "=D" (p), "=c" (n)
			: "0" (p), "a" (c), "1" (n)
			: "cc", "memory");
	return v;
}
  80083b:	89 d0                	mov    %edx,%eax
  80083d:	5b                   	pop    %ebx
  80083e:	5e                   	pop    %esi
  80083f:	5f                   	pop    %edi
  800840:	5d                   	pop    %ebp
  800841:	c3                   	ret    

00800842 <memmove>:

void *
memmove(void *dst, const void *src, size_t n)
{
  800842:	55                   	push   %ebp
  800843:	89 e5                	mov    %esp,%ebp
  800845:	57                   	push   %edi
  800846:	56                   	push   %esi
  800847:	8b 45 08             	mov    0x8(%ebp),%eax
  80084a:	8b 75 0c             	mov    0xc(%ebp),%esi
  80084d:	8b 4d 10             	mov    0x10(%ebp),%ecx
	const char *s;
	char *d;

	s = src;
	d = dst;
	if (s < d && s + n > d) {
  800850:	39 c6                	cmp    %eax,%esi
  800852:	73 35                	jae    800889 <memmove+0x47>
  800854:	8d 14 0e             	lea    (%esi,%ecx,1),%edx
  800857:	39 d0                	cmp    %edx,%eax
  800859:	73 2e                	jae    800889 <memmove+0x47>
		s += n;
		d += n;
  80085b:	8d 3c 08             	lea    (%eax,%ecx,1),%edi
		if ((int)s%4 == 0 && (int)d%4 == 0 && n%4 == 0)
  80085e:	89 d6                	mov    %edx,%esi
  800860:	09 fe                	or     %edi,%esi
  800862:	f7 c6 03 00 00 00    	test   $0x3,%esi
  800868:	75 13                	jne    80087d <memmove+0x3b>
  80086a:	f6 c1 03             	test   $0x3,%cl
  80086d:	75 0e                	jne    80087d <memmove+0x3b>
			asm volatile("std; rep movsl\n"
  80086f:	83 ef 04             	sub    $0x4,%edi
  800872:	8d 72 fc             	lea    -0x4(%edx),%esi
  800875:	c1 e9 02             	shr    $0x2,%ecx
  800878:	fd                   	std    
  800879:	f3 a5                	rep movsl %ds:(%esi),%es:(%edi)
  80087b:	eb 09                	jmp    800886 <memmove+0x44>
				:: "D" (d-4), "S" (s-4), "c" (n/4) : "cc", "memory");
		else
			asm volatile("std; rep movsb\n"
  80087d:	83 ef 01             	sub    $0x1,%edi
  800880:	8d 72 ff             	lea    -0x1(%edx),%esi
  800883:	fd                   	std    
  800884:	f3 a4                	rep movsb %ds:(%esi),%es:(%edi)
				:: "D" (d-1), "S" (s-1), "c" (n) : "cc", "memory");
		// Some versions of GCC rely on DF being clear
		asm volatile("cld" ::: "cc");
  800886:	fc                   	cld    
  800887:	eb 1d                	jmp    8008a6 <memmove+0x64>
	} else {
		if ((int)s%4 == 0 && (int)d%4 == 0 && n%4 == 0)
  800889:	89 f2                	mov    %esi,%edx
  80088b:	09 c2                	or     %eax,%edx
  80088d:	f6 c2 03             	test   $0x3,%dl
  800890:	75 0f                	jne    8008a1 <memmove+0x5f>
  800892:	f6 c1 03             	test   $0x3,%cl
  800895:	75 0a                	jne    8008a1 <memmove+0x5f>
			asm volatile("cld; rep movsl\n"
  800897:	c1 e9 02             	shr    $0x2,%ecx
  80089a:	89 c7                	mov    %eax,%edi
  80089c:	fc                   	cld    
  80089d:	f3 a5                	rep movsl %ds:(%esi),%es:(%edi)
  80089f:	eb 05                	jmp    8008a6 <memmove+0x64>
				:: "D" (d), "S" (s), "c" (n/4) : "cc", "memory");
		else
			asm volatile("cld; rep movsb\n"
  8008a1:	89 c7                	mov    %eax,%edi
  8008a3:	fc                   	cld    
  8008a4:	f3 a4                	rep movsb %ds:(%esi),%es:(%edi)
				:: "D" (d), "S" (s), "c" (n) : "cc", "memory");
	}
	return dst;
}
  8008a6:	5e                   	pop    %esi
  8008a7:	5f                   	pop    %edi
  8008a8:	5d                   	pop    %ebp
  8008a9:	c3                   	ret    

008008aa <memcpy>:
}
#endif

void *
memcpy(void *dst, const void *src, size_t n)
{
  8008aa:	55                   	push   %ebp
  8008ab:	89 e5                	mov    %esp,%ebp
	return memmove(dst, src, n);
  8008ad:	ff 75 10             	pushl  0x10(%ebp)
  8008b0:	ff 75 0c             	pushl  0xc(%ebp)
  8008b3:	ff 75 08             	pushl  0x8(%ebp)
  8008b6:	e8 87 ff ff ff       	call   800842 <memmove>
}
  8008bb:	c9                   	leave  
  8008bc:	c3                   	ret    

008008bd <memcmp>:

int
memcmp(const void *v1, const void *v2, size_t n)
{
  8008bd:	55                   	push   %ebp
  8008be:	89 e5                	mov    %esp,%ebp
  8008c0:	56                   	push   %esi
  8008c1:	53                   	push   %ebx
  8008c2:	8b 45 08             	mov    0x8(%ebp),%eax
  8008c5:	8b 55 0c             	mov    0xc(%ebp),%edx
  8008c8:	89 c6                	mov    %eax,%esi
  8008ca:	03 75 10             	add    0x10(%ebp),%esi
	const uint8_t *s1 = (const uint8_t *) v1;
	const uint8_t *s2 = (const uint8_t *) v2;

	while (n-- > 0) {
  8008cd:	eb 1a                	jmp    8008e9 <memcmp+0x2c>
		if (*s1 != *s2)
  8008cf:	0f b6 08             	movzbl (%eax),%ecx
  8008d2:	0f b6 1a             	movzbl (%edx),%ebx
  8008d5:	38 d9                	cmp    %bl,%cl
  8008d7:	74 0a                	je     8008e3 <memcmp+0x26>
			return (int) *s1 - (int) *s2;
  8008d9:	0f b6 c1             	movzbl %cl,%eax
  8008dc:	0f b6 db             	movzbl %bl,%ebx
  8008df:	29 d8                	sub    %ebx,%eax
  8008e1:	eb 0f                	jmp    8008f2 <memcmp+0x35>
		s1++, s2++;
  8008e3:	83 c0 01             	add    $0x1,%eax
  8008e6:	83 c2 01             	add    $0x1,%edx
memcmp(const void *v1, const void *v2, size_t n)
{
	const uint8_t *s1 = (const uint8_t *) v1;
	const uint8_t *s2 = (const uint8_t *) v2;

	while (n-- > 0) {
  8008e9:	39 f0                	cmp    %esi,%eax
  8008eb:	75 e2                	jne    8008cf <memcmp+0x12>
		if (*s1 != *s2)
			return (int) *s1 - (int) *s2;
		s1++, s2++;
	}

	return 0;
  8008ed:	b8 00 00 00 00       	mov    $0x0,%eax
}
  8008f2:	5b                   	pop    %ebx
  8008f3:	5e                   	pop    %esi
  8008f4:	5d                   	pop    %ebp
  8008f5:	c3                   	ret    

008008f6 <memfind>:

void *
memfind(const void *s, int c, size_t n)
{
  8008f6:	55                   	push   %ebp
  8008f7:	89 e5                	mov    %esp,%ebp
  8008f9:	8b 45 08             	mov    0x8(%ebp),%eax
  8008fc:	8b 4d 0c             	mov    0xc(%ebp),%ecx
	const void *ends = (const char *) s + n;
  8008ff:	89 c2                	mov    %eax,%edx
  800901:	03 55 10             	add    0x10(%ebp),%edx
	for (; s < ends; s++)
  800904:	eb 07                	jmp    80090d <memfind+0x17>
		if (*(const unsigned char *) s == (unsigned char) c)
  800906:	38 08                	cmp    %cl,(%eax)
  800908:	74 07                	je     800911 <memfind+0x1b>

void *
memfind(const void *s, int c, size_t n)
{
	const void *ends = (const char *) s + n;
	for (; s < ends; s++)
  80090a:	83 c0 01             	add    $0x1,%eax
  80090d:	39 d0                	cmp    %edx,%eax
  80090f:	72 f5                	jb     800906 <memfind+0x10>
		if (*(const unsigned char *) s == (unsigned char) c)
			break;
	return (void *) s;
}
  800911:	5d                   	pop    %ebp
  800912:	c3                   	ret    

00800913 <strtol>:

long
strtol(const char *s, char **endptr, int base)
{
  800913:	55                   	push   %ebp
  800914:	89 e5                	mov    %esp,%ebp
  800916:	57                   	push   %edi
  800917:	56                   	push   %esi
  800918:	53                   	push   %ebx
  800919:	8b 4d 08             	mov    0x8(%ebp),%ecx
  80091c:	8b 5d 10             	mov    0x10(%ebp),%ebx
	int neg = 0;
	long val = 0;

	// gobble initial whitespace
	while (*s == ' ' || *s == '\t')
  80091f:	eb 03                	jmp    800924 <strtol+0x11>
		s++;
  800921:	83 c1 01             	add    $0x1,%ecx
{
	int neg = 0;
	long val = 0;

	// gobble initial whitespace
	while (*s == ' ' || *s == '\t')
  800924:	0f b6 01             	movzbl (%ecx),%eax
  800927:	3c 20                	cmp    $0x20,%al
  800929:	74 f6                	je     800921 <strtol+0xe>
  80092b:	3c 09                	cmp    $0x9,%al
  80092d:	74 f2                	je     800921 <strtol+0xe>
		s++;

	// plus/minus sign
	if (*s == '+')
  80092f:	3c 2b                	cmp    $0x2b,%al
  800931:	75 0a                	jne    80093d <strtol+0x2a>
		s++;
  800933:	83 c1 01             	add    $0x1,%ecx
}

long
strtol(const char *s, char **endptr, int base)
{
	int neg = 0;
  800936:	bf 00 00 00 00       	mov    $0x0,%edi
  80093b:	eb 11                	jmp    80094e <strtol+0x3b>
  80093d:	bf 00 00 00 00       	mov    $0x0,%edi
		s++;

	// plus/minus sign
	if (*s == '+')
		s++;
	else if (*s == '-')
  800942:	3c 2d                	cmp    $0x2d,%al
  800944:	75 08                	jne    80094e <strtol+0x3b>
		s++, neg = 1;
  800946:	83 c1 01             	add    $0x1,%ecx
  800949:	bf 01 00 00 00       	mov    $0x1,%edi

	// hex or octal base prefix
	if ((base == 0 || base == 16) && (s[0] == '0' && s[1] == 'x'))
  80094e:	f7 c3 ef ff ff ff    	test   $0xffffffef,%ebx
  800954:	75 15                	jne    80096b <strtol+0x58>
  800956:	80 39 30             	cmpb   $0x30,(%ecx)
  800959:	75 10                	jne    80096b <strtol+0x58>
  80095b:	80 79 01 78          	cmpb   $0x78,0x1(%ecx)
  80095f:	75 7c                	jne    8009dd <strtol+0xca>
		s += 2, base = 16;
  800961:	83 c1 02             	add    $0x2,%ecx
  800964:	bb 10 00 00 00       	mov    $0x10,%ebx
  800969:	eb 16                	jmp    800981 <strtol+0x6e>
	else if (base == 0 && s[0] == '0')
  80096b:	85 db                	test   %ebx,%ebx
  80096d:	75 12                	jne    800981 <strtol+0x6e>
		s++, base = 8;
	else if (base == 0)
		base = 10;
  80096f:	bb 0a 00 00 00       	mov    $0xa,%ebx
		s++, neg = 1;

	// hex or octal base prefix
	if ((base == 0 || base == 16) && (s[0] == '0' && s[1] == 'x'))
		s += 2, base = 16;
	else if (base == 0 && s[0] == '0')
  800974:	80 39 30             	cmpb   $0x30,(%ecx)
  800977:	75 08                	jne    800981 <strtol+0x6e>
		s++, base = 8;
  800979:	83 c1 01             	add    $0x1,%ecx
  80097c:	bb 08 00 00 00       	mov    $0x8,%ebx
	else if (base == 0)
		base = 10;
  800981:	b8 00 00 00 00       	mov    $0x0,%eax
  800986:	89 5d 10             	mov    %ebx,0x10(%ebp)

	// digits
	while (1) {
		int dig;

		if (*s >= '0' && *s <= '9')
  800989:	0f b6 11             	movzbl (%ecx),%edx
  80098c:	8d 72 d0             	lea    -0x30(%edx),%esi
  80098f:	89 f3                	mov    %esi,%ebx
  800991:	80 fb 09             	cmp    $0x9,%bl
  800994:	77 08                	ja     80099e <strtol+0x8b>
			dig = *s - '0';
  800996:	0f be d2             	movsbl %dl,%edx
  800999:	83 ea 30             	sub    $0x30,%edx
  80099c:	eb 22                	jmp    8009c0 <strtol+0xad>
		else if (*s >= 'a' && *s <= 'z')
  80099e:	8d 72 9f             	lea    -0x61(%edx),%esi
  8009a1:	89 f3                	mov    %esi,%ebx
  8009a3:	80 fb 19             	cmp    $0x19,%bl
  8009a6:	77 08                	ja     8009b0 <strtol+0x9d>
			dig = *s - 'a' + 10;
  8009a8:	0f be d2             	movsbl %dl,%edx
  8009ab:	83 ea 57             	sub    $0x57,%edx
  8009ae:	eb 10                	jmp    8009c0 <strtol+0xad>
		else if (*s >= 'A' && *s <= 'Z')
  8009b0:	8d 72 bf             	lea    -0x41(%edx),%esi
  8009b3:	89 f3                	mov    %esi,%ebx
  8009b5:	80 fb 19             	cmp    $0x19,%bl
  8009b8:	77 16                	ja     8009d0 <strtol+0xbd>
			dig = *s - 'A' + 10;
  8009ba:	0f be d2             	movsbl %dl,%edx
  8009bd:	83 ea 37             	sub    $0x37,%edx
		else
			break;
		if (dig >= base)
  8009c0:	3b 55 10             	cmp    0x10(%ebp),%edx
  8009c3:	7d 0b                	jge    8009d0 <strtol+0xbd>
			break;
		s++, val = (val * base) + dig;
  8009c5:	83 c1 01             	add    $0x1,%ecx
  8009c8:	0f af 45 10          	imul   0x10(%ebp),%eax
  8009cc:	01 d0                	add    %edx,%eax
		// we don't properly detect overflow!
	}
  8009ce:	eb b9                	jmp    800989 <strtol+0x76>

	if (endptr)
  8009d0:	83 7d 0c 00          	cmpl   $0x0,0xc(%ebp)
  8009d4:	74 0d                	je     8009e3 <strtol+0xd0>
		*endptr = (char *) s;
  8009d6:	8b 75 0c             	mov    0xc(%ebp),%esi
  8009d9:	89 0e                	mov    %ecx,(%esi)
  8009db:	eb 06                	jmp    8009e3 <strtol+0xd0>
		s++, neg = 1;

	// hex or octal base prefix
	if ((base == 0 || base == 16) && (s[0] == '0' && s[1] == 'x'))
		s += 2, base = 16;
	else if (base == 0 && s[0] == '0')
  8009dd:	85 db                	test   %ebx,%ebx
  8009df:	74 98                	je     800979 <strtol+0x66>
  8009e1:	eb 9e                	jmp    800981 <strtol+0x6e>
		// we don't properly detect overflow!
	}

	if (endptr)
		*endptr = (char *) s;
	return (neg ? -val : val);
  8009e3:	89 c2                	mov    %eax,%edx
  8009e5:	f7 da                	neg    %edx
  8009e7:	85 ff                	test   %edi,%edi
  8009e9:	0f 45 c2             	cmovne %edx,%eax
}
  8009ec:	5b                   	pop    %ebx
  8009ed:	5e                   	pop    %esi
  8009ee:	5f                   	pop    %edi
  8009ef:	5d                   	pop    %ebp
  8009f0:	c3                   	ret    

008009f1 <syscall>:
#include <inc/syscall.h>
#include <inc/lib.h>

static inline int32_t
syscall(int num, int check, uint32_t a1, uint32_t a2, uint32_t a3, uint32_t a4, uint32_t a5)
{
  8009f1:	55                   	push   %ebp
  8009f2:	89 e5                	mov    %esp,%ebp
  8009f4:	57                   	push   %edi
  8009f5:	56                   	push   %esi
  8009f6:	53                   	push   %ebx
  8009f7:	83 ec 1c             	sub    $0x1c,%esp
  8009fa:	89 45 e0             	mov    %eax,-0x20(%ebp)
  8009fd:	89 55 e4             	mov    %edx,-0x1c(%ebp)
  800a00:	89 ca                	mov    %ecx,%edx
	//
	// The last clause tells the assembler that this can
	// potentially change the condition codes and arbitrary
	// memory locations.

	asm volatile("int %1\n"
  800a02:	8b 4d 08             	mov    0x8(%ebp),%ecx
  800a05:	8b 5d 0c             	mov    0xc(%ebp),%ebx
  800a08:	8b 7d 10             	mov    0x10(%ebp),%edi
  800a0b:	8b 75 14             	mov    0x14(%ebp),%esi
  800a0e:	cd 30                	int    $0x30
		       "b" (a3),
		       "D" (a4),
		       "S" (a5)
		     : "cc", "memory");

	if(check && ret > 0)
  800a10:	83 7d e4 00          	cmpl   $0x0,-0x1c(%ebp)
  800a14:	74 1d                	je     800a33 <syscall+0x42>
  800a16:	85 c0                	test   %eax,%eax
  800a18:	7e 19                	jle    800a33 <syscall+0x42>
  800a1a:	8b 55 e0             	mov    -0x20(%ebp),%edx
		panic("syscall %d returned %d (> 0)", num, ret);
  800a1d:	83 ec 0c             	sub    $0xc,%esp
  800a20:	50                   	push   %eax
  800a21:	52                   	push   %edx
  800a22:	68 44 11 80 00       	push   $0x801144
  800a27:	6a 23                	push   $0x23
  800a29:	68 61 11 80 00       	push   $0x801161
  800a2e:	e8 b9 01 00 00       	call   800bec <_panic>

	return ret;
}
  800a33:	8d 65 f4             	lea    -0xc(%ebp),%esp
  800a36:	5b                   	pop    %ebx
  800a37:	5e                   	pop    %esi
  800a38:	5f                   	pop    %edi
  800a39:	5d                   	pop    %ebp
  800a3a:	c3                   	ret    

00800a3b <sys_cputs>:

void
sys_cputs(const char *s, size_t len)
{
  800a3b:	55                   	push   %ebp
  800a3c:	89 e5                	mov    %esp,%ebp
  800a3e:	83 ec 08             	sub    $0x8,%esp
	syscall(SYS_cputs, 0, (uint32_t)s, len, 0, 0, 0);
  800a41:	6a 00                	push   $0x0
  800a43:	6a 00                	push   $0x0
  800a45:	6a 00                	push   $0x0
  800a47:	ff 75 0c             	pushl  0xc(%ebp)
  800a4a:	8b 4d 08             	mov    0x8(%ebp),%ecx
  800a4d:	ba 00 00 00 00       	mov    $0x0,%edx
  800a52:	b8 00 00 00 00       	mov    $0x0,%eax
  800a57:	e8 95 ff ff ff       	call   8009f1 <syscall>
}
  800a5c:	83 c4 10             	add    $0x10,%esp
  800a5f:	c9                   	leave  
  800a60:	c3                   	ret    

00800a61 <sys_cgetc>:

int
sys_cgetc(void)
{
  800a61:	55                   	push   %ebp
  800a62:	89 e5                	mov    %esp,%ebp
  800a64:	83 ec 08             	sub    $0x8,%esp
	return syscall(SYS_cgetc, 0, 0, 0, 0, 0, 0);
  800a67:	6a 00                	push   $0x0
  800a69:	6a 00                	push   $0x0
  800a6b:	6a 00                	push   $0x0
  800a6d:	6a 00                	push   $0x0
  800a6f:	b9 00 00 00 00       	mov    $0x0,%ecx
  800a74:	ba 00 00 00 00       	mov    $0x0,%edx
  800a79:	b8 01 00 00 00       	mov    $0x1,%eax
  800a7e:	e8 6e ff ff ff       	call   8009f1 <syscall>
}
  800a83:	c9                   	leave  
  800a84:	c3                   	ret    

00800a85 <sys_env_destroy>:

int
sys_env_destroy(envid_t envid)
{
  800a85:	55                   	push   %ebp
  800a86:	89 e5                	mov    %esp,%ebp
  800a88:	83 ec 08             	sub    $0x8,%esp
	return syscall(SYS_env_destroy, 1, envid, 0, 0, 0, 0);
  800a8b:	6a 00                	push   $0x0
  800a8d:	6a 00                	push   $0x0
  800a8f:	6a 00                	push   $0x0
  800a91:	6a 00                	push   $0x0
  800a93:	8b 4d 08             	mov    0x8(%ebp),%ecx
  800a96:	ba 01 00 00 00       	mov    $0x1,%edx
  800a9b:	b8 03 00 00 00       	mov    $0x3,%eax
  800aa0:	e8 4c ff ff ff       	call   8009f1 <syscall>
}
  800aa5:	c9                   	leave  
  800aa6:	c3                   	ret    

00800aa7 <sys_getenvid>:

envid_t
sys_getenvid(void)
{
  800aa7:	55                   	push   %ebp
  800aa8:	89 e5                	mov    %esp,%ebp
  800aaa:	83 ec 08             	sub    $0x8,%esp
	 return syscall(SYS_getenvid, 0, 0, 0, 0, 0, 0);
  800aad:	6a 00                	push   $0x0
  800aaf:	6a 00                	push   $0x0
  800ab1:	6a 00                	push   $0x0
  800ab3:	6a 00                	push   $0x0
  800ab5:	b9 00 00 00 00       	mov    $0x0,%ecx
  800aba:	ba 00 00 00 00       	mov    $0x0,%edx
  800abf:	b8 02 00 00 00       	mov    $0x2,%eax
  800ac4:	e8 28 ff ff ff       	call   8009f1 <syscall>
}
  800ac9:	c9                   	leave  
  800aca:	c3                   	ret    

00800acb <sys_yield>:

void
sys_yield(void)
{
  800acb:	55                   	push   %ebp
  800acc:	89 e5                	mov    %esp,%ebp
  800ace:	83 ec 08             	sub    $0x8,%esp
	syscall(SYS_yield, 0, 0, 0, 0, 0, 0);
  800ad1:	6a 00                	push   $0x0
  800ad3:	6a 00                	push   $0x0
  800ad5:	6a 00                	push   $0x0
  800ad7:	6a 00                	push   $0x0
  800ad9:	b9 00 00 00 00       	mov    $0x0,%ecx
  800ade:	ba 00 00 00 00       	mov    $0x0,%edx
  800ae3:	b8 0a 00 00 00       	mov    $0xa,%eax
  800ae8:	e8 04 ff ff ff       	call   8009f1 <syscall>
}
  800aed:	83 c4 10             	add    $0x10,%esp
  800af0:	c9                   	leave  
  800af1:	c3                   	ret    

00800af2 <sys_page_alloc>:

int
sys_page_alloc(envid_t envid, void *va, int perm)
{
  800af2:	55                   	push   %ebp
  800af3:	89 e5                	mov    %esp,%ebp
  800af5:	83 ec 08             	sub    $0x8,%esp
	return syscall(SYS_page_alloc, 1, envid, (uint32_t) va, perm, 0, 0);
  800af8:	6a 00                	push   $0x0
  800afa:	6a 00                	push   $0x0
  800afc:	ff 75 10             	pushl  0x10(%ebp)
  800aff:	ff 75 0c             	pushl  0xc(%ebp)
  800b02:	8b 4d 08             	mov    0x8(%ebp),%ecx
  800b05:	ba 01 00 00 00       	mov    $0x1,%edx
  800b0a:	b8 04 00 00 00       	mov    $0x4,%eax
  800b0f:	e8 dd fe ff ff       	call   8009f1 <syscall>
}
  800b14:	c9                   	leave  
  800b15:	c3                   	ret    

00800b16 <sys_page_map>:

int
sys_page_map(envid_t srcenv, void *srcva, envid_t dstenv, void *dstva, int perm)
{
  800b16:	55                   	push   %ebp
  800b17:	89 e5                	mov    %esp,%ebp
  800b19:	83 ec 08             	sub    $0x8,%esp
	return syscall(SYS_page_map, 1, srcenv, (uint32_t) srcva, dstenv, (uint32_t) dstva, perm);
  800b1c:	ff 75 18             	pushl  0x18(%ebp)
  800b1f:	ff 75 14             	pushl  0x14(%ebp)
  800b22:	ff 75 10             	pushl  0x10(%ebp)
  800b25:	ff 75 0c             	pushl  0xc(%ebp)
  800b28:	8b 4d 08             	mov    0x8(%ebp),%ecx
  800b2b:	ba 01 00 00 00       	mov    $0x1,%edx
  800b30:	b8 05 00 00 00       	mov    $0x5,%eax
  800b35:	e8 b7 fe ff ff       	call   8009f1 <syscall>
}
  800b3a:	c9                   	leave  
  800b3b:	c3                   	ret    

00800b3c <sys_page_unmap>:

int
sys_page_unmap(envid_t envid, void *va)
{
  800b3c:	55                   	push   %ebp
  800b3d:	89 e5                	mov    %esp,%ebp
  800b3f:	83 ec 08             	sub    $0x8,%esp
	return syscall(SYS_page_unmap, 1, envid, (uint32_t) va, 0, 0, 0);
  800b42:	6a 00                	push   $0x0
  800b44:	6a 00                	push   $0x0
  800b46:	6a 00                	push   $0x0
  800b48:	ff 75 0c             	pushl  0xc(%ebp)
  800b4b:	8b 4d 08             	mov    0x8(%ebp),%ecx
  800b4e:	ba 01 00 00 00       	mov    $0x1,%edx
  800b53:	b8 06 00 00 00       	mov    $0x6,%eax
  800b58:	e8 94 fe ff ff       	call   8009f1 <syscall>
}
  800b5d:	c9                   	leave  
  800b5e:	c3                   	ret    

00800b5f <sys_env_set_status>:

// sys_exofork is inlined in lib.h

int
sys_env_set_status(envid_t envid, int status)
{
  800b5f:	55                   	push   %ebp
  800b60:	89 e5                	mov    %esp,%ebp
  800b62:	83 ec 08             	sub    $0x8,%esp
	return syscall(SYS_env_set_status, 1, envid, status, 0, 0, 0);
  800b65:	6a 00                	push   $0x0
  800b67:	6a 00                	push   $0x0
  800b69:	6a 00                	push   $0x0
  800b6b:	ff 75 0c             	pushl  0xc(%ebp)
  800b6e:	8b 4d 08             	mov    0x8(%ebp),%ecx
  800b71:	ba 01 00 00 00       	mov    $0x1,%edx
  800b76:	b8 08 00 00 00       	mov    $0x8,%eax
  800b7b:	e8 71 fe ff ff       	call   8009f1 <syscall>
}
  800b80:	c9                   	leave  
  800b81:	c3                   	ret    

00800b82 <sys_env_set_pgfault_upcall>:

int
sys_env_set_pgfault_upcall(envid_t envid, void *upcall)
{
  800b82:	55                   	push   %ebp
  800b83:	89 e5                	mov    %esp,%ebp
  800b85:	83 ec 08             	sub    $0x8,%esp
	return syscall(SYS_env_set_pgfault_upcall, 1, envid, (uint32_t) upcall, 0, 0, 0);
  800b88:	6a 00                	push   $0x0
  800b8a:	6a 00                	push   $0x0
  800b8c:	6a 00                	push   $0x0
  800b8e:	ff 75 0c             	pushl  0xc(%ebp)
  800b91:	8b 4d 08             	mov    0x8(%ebp),%ecx
  800b94:	ba 01 00 00 00       	mov    $0x1,%edx
  800b99:	b8 09 00 00 00       	mov    $0x9,%eax
  800b9e:	e8 4e fe ff ff       	call   8009f1 <syscall>
}
  800ba3:	c9                   	leave  
  800ba4:	c3                   	ret    

00800ba5 <sys_ipc_try_send>:

int
sys_ipc_try_send(envid_t envid, uint32_t value, void *srcva, int perm)
{
  800ba5:	55                   	push   %ebp
  800ba6:	89 e5                	mov    %esp,%ebp
  800ba8:	83 ec 08             	sub    $0x8,%esp
	return syscall(SYS_ipc_try_send, 0, envid, value, (uint32_t) srcva, perm, 0);
  800bab:	6a 00                	push   $0x0
  800bad:	ff 75 14             	pushl  0x14(%ebp)
  800bb0:	ff 75 10             	pushl  0x10(%ebp)
  800bb3:	ff 75 0c             	pushl  0xc(%ebp)
  800bb6:	8b 4d 08             	mov    0x8(%ebp),%ecx
  800bb9:	ba 00 00 00 00       	mov    $0x0,%edx
  800bbe:	b8 0b 00 00 00       	mov    $0xb,%eax
  800bc3:	e8 29 fe ff ff       	call   8009f1 <syscall>
}
  800bc8:	c9                   	leave  
  800bc9:	c3                   	ret    

00800bca <sys_ipc_recv>:

int
sys_ipc_recv(void *dstva)
{
  800bca:	55                   	push   %ebp
  800bcb:	89 e5                	mov    %esp,%ebp
  800bcd:	83 ec 08             	sub    $0x8,%esp
	return syscall(SYS_ipc_recv, 1, (uint32_t)dstva, 0, 0, 0, 0);
  800bd0:	6a 00                	push   $0x0
  800bd2:	6a 00                	push   $0x0
  800bd4:	6a 00                	push   $0x0
  800bd6:	6a 00                	push   $0x0
  800bd8:	8b 4d 08             	mov    0x8(%ebp),%ecx
  800bdb:	ba 01 00 00 00       	mov    $0x1,%edx
  800be0:	b8 0c 00 00 00       	mov    $0xc,%eax
  800be5:	e8 07 fe ff ff       	call   8009f1 <syscall>
}
  800bea:	c9                   	leave  
  800beb:	c3                   	ret    

00800bec <_panic>:
 * It prints "panic: <message>", then causes a breakpoint exception,
 * which causes JOS to enter the JOS kernel monitor.
 */
void
_panic(const char *file, int line, const char *fmt, ...)
{
  800bec:	55                   	push   %ebp
  800bed:	89 e5                	mov    %esp,%ebp
  800bef:	56                   	push   %esi
  800bf0:	53                   	push   %ebx
	va_list ap;

	va_start(ap, fmt);
  800bf1:	8d 5d 14             	lea    0x14(%ebp),%ebx

	// Print the panic message
	cprintf("[%08x] user panic in %s at %s:%d: ",
  800bf4:	8b 35 00 20 80 00    	mov    0x802000,%esi
  800bfa:	e8 a8 fe ff ff       	call   800aa7 <sys_getenvid>
  800bff:	83 ec 0c             	sub    $0xc,%esp
  800c02:	ff 75 0c             	pushl  0xc(%ebp)
  800c05:	ff 75 08             	pushl  0x8(%ebp)
  800c08:	56                   	push   %esi
  800c09:	50                   	push   %eax
  800c0a:	68 70 11 80 00       	push   $0x801170
  800c0f:	e8 29 f5 ff ff       	call   80013d <cprintf>
		sys_getenvid(), binaryname, file, line);
	vcprintf(fmt, ap);
  800c14:	83 c4 18             	add    $0x18,%esp
  800c17:	53                   	push   %ebx
  800c18:	ff 75 10             	pushl  0x10(%ebp)
  800c1b:	e8 cc f4 ff ff       	call   8000ec <vcprintf>
	cprintf("\n");
  800c20:	c7 04 24 fc 0e 80 00 	movl   $0x800efc,(%esp)
  800c27:	e8 11 f5 ff ff       	call   80013d <cprintf>
  800c2c:	83 c4 10             	add    $0x10,%esp

	// Cause a breakpoint exception
	while (1)
		asm volatile("int3");
  800c2f:	cc                   	int3   
  800c30:	eb fd                	jmp    800c2f <_panic+0x43>
  800c32:	66 90                	xchg   %ax,%ax
  800c34:	66 90                	xchg   %ax,%ax
  800c36:	66 90                	xchg   %ax,%ax
  800c38:	66 90                	xchg   %ax,%ax
  800c3a:	66 90                	xchg   %ax,%ax
  800c3c:	66 90                	xchg   %ax,%ax
  800c3e:	66 90                	xchg   %ax,%ax

00800c40 <__udivdi3>:
  800c40:	55                   	push   %ebp
  800c41:	57                   	push   %edi
  800c42:	56                   	push   %esi
  800c43:	53                   	push   %ebx
  800c44:	83 ec 1c             	sub    $0x1c,%esp
  800c47:	8b 74 24 3c          	mov    0x3c(%esp),%esi
  800c4b:	8b 5c 24 30          	mov    0x30(%esp),%ebx
  800c4f:	8b 4c 24 34          	mov    0x34(%esp),%ecx
  800c53:	8b 7c 24 38          	mov    0x38(%esp),%edi
  800c57:	85 f6                	test   %esi,%esi
  800c59:	89 5c 24 08          	mov    %ebx,0x8(%esp)
  800c5d:	89 ca                	mov    %ecx,%edx
  800c5f:	89 f8                	mov    %edi,%eax
  800c61:	75 3d                	jne    800ca0 <__udivdi3+0x60>
  800c63:	39 cf                	cmp    %ecx,%edi
  800c65:	0f 87 c5 00 00 00    	ja     800d30 <__udivdi3+0xf0>
  800c6b:	85 ff                	test   %edi,%edi
  800c6d:	89 fd                	mov    %edi,%ebp
  800c6f:	75 0b                	jne    800c7c <__udivdi3+0x3c>
  800c71:	b8 01 00 00 00       	mov    $0x1,%eax
  800c76:	31 d2                	xor    %edx,%edx
  800c78:	f7 f7                	div    %edi
  800c7a:	89 c5                	mov    %eax,%ebp
  800c7c:	89 c8                	mov    %ecx,%eax
  800c7e:	31 d2                	xor    %edx,%edx
  800c80:	f7 f5                	div    %ebp
  800c82:	89 c1                	mov    %eax,%ecx
  800c84:	89 d8                	mov    %ebx,%eax
  800c86:	89 cf                	mov    %ecx,%edi
  800c88:	f7 f5                	div    %ebp
  800c8a:	89 c3                	mov    %eax,%ebx
  800c8c:	89 d8                	mov    %ebx,%eax
  800c8e:	89 fa                	mov    %edi,%edx
  800c90:	83 c4 1c             	add    $0x1c,%esp
  800c93:	5b                   	pop    %ebx
  800c94:	5e                   	pop    %esi
  800c95:	5f                   	pop    %edi
  800c96:	5d                   	pop    %ebp
  800c97:	c3                   	ret    
  800c98:	90                   	nop
  800c99:	8d b4 26 00 00 00 00 	lea    0x0(%esi,%eiz,1),%esi
  800ca0:	39 ce                	cmp    %ecx,%esi
  800ca2:	77 74                	ja     800d18 <__udivdi3+0xd8>
  800ca4:	0f bd fe             	bsr    %esi,%edi
  800ca7:	83 f7 1f             	xor    $0x1f,%edi
  800caa:	0f 84 98 00 00 00    	je     800d48 <__udivdi3+0x108>
  800cb0:	bb 20 00 00 00       	mov    $0x20,%ebx
  800cb5:	89 f9                	mov    %edi,%ecx
  800cb7:	89 c5                	mov    %eax,%ebp
  800cb9:	29 fb                	sub    %edi,%ebx
  800cbb:	d3 e6                	shl    %cl,%esi
  800cbd:	89 d9                	mov    %ebx,%ecx
  800cbf:	d3 ed                	shr    %cl,%ebp
  800cc1:	89 f9                	mov    %edi,%ecx
  800cc3:	d3 e0                	shl    %cl,%eax
  800cc5:	09 ee                	or     %ebp,%esi
  800cc7:	89 d9                	mov    %ebx,%ecx
  800cc9:	89 44 24 0c          	mov    %eax,0xc(%esp)
  800ccd:	89 d5                	mov    %edx,%ebp
  800ccf:	8b 44 24 08          	mov    0x8(%esp),%eax
  800cd3:	d3 ed                	shr    %cl,%ebp
  800cd5:	89 f9                	mov    %edi,%ecx
  800cd7:	d3 e2                	shl    %cl,%edx
  800cd9:	89 d9                	mov    %ebx,%ecx
  800cdb:	d3 e8                	shr    %cl,%eax
  800cdd:	09 c2                	or     %eax,%edx
  800cdf:	89 d0                	mov    %edx,%eax
  800ce1:	89 ea                	mov    %ebp,%edx
  800ce3:	f7 f6                	div    %esi
  800ce5:	89 d5                	mov    %edx,%ebp
  800ce7:	89 c3                	mov    %eax,%ebx
  800ce9:	f7 64 24 0c          	mull   0xc(%esp)
  800ced:	39 d5                	cmp    %edx,%ebp
  800cef:	72 10                	jb     800d01 <__udivdi3+0xc1>
  800cf1:	8b 74 24 08          	mov    0x8(%esp),%esi
  800cf5:	89 f9                	mov    %edi,%ecx
  800cf7:	d3 e6                	shl    %cl,%esi
  800cf9:	39 c6                	cmp    %eax,%esi
  800cfb:	73 07                	jae    800d04 <__udivdi3+0xc4>
  800cfd:	39 d5                	cmp    %edx,%ebp
  800cff:	75 03                	jne    800d04 <__udivdi3+0xc4>
  800d01:	83 eb 01             	sub    $0x1,%ebx
  800d04:	31 ff                	xor    %edi,%edi
  800d06:	89 d8                	mov    %ebx,%eax
  800d08:	89 fa                	mov    %edi,%edx
  800d0a:	83 c4 1c             	add    $0x1c,%esp
  800d0d:	5b                   	pop    %ebx
  800d0e:	5e                   	pop    %esi
  800d0f:	5f                   	pop    %edi
  800d10:	5d                   	pop    %ebp
  800d11:	c3                   	ret    
  800d12:	8d b6 00 00 00 00    	lea    0x0(%esi),%esi
  800d18:	31 ff                	xor    %edi,%edi
  800d1a:	31 db                	xor    %ebx,%ebx
  800d1c:	89 d8                	mov    %ebx,%eax
  800d1e:	89 fa                	mov    %edi,%edx
  800d20:	83 c4 1c             	add    $0x1c,%esp
  800d23:	5b                   	pop    %ebx
  800d24:	5e                   	pop    %esi
  800d25:	5f                   	pop    %edi
  800d26:	5d                   	pop    %ebp
  800d27:	c3                   	ret    
  800d28:	90                   	nop
  800d29:	8d b4 26 00 00 00 00 	lea    0x0(%esi,%eiz,1),%esi
  800d30:	89 d8                	mov    %ebx,%eax
  800d32:	f7 f7                	div    %edi
  800d34:	31 ff                	xor    %edi,%edi
  800d36:	89 c3                	mov    %eax,%ebx
  800d38:	89 d8                	mov    %ebx,%eax
  800d3a:	89 fa                	mov    %edi,%edx
  800d3c:	83 c4 1c             	add    $0x1c,%esp
  800d3f:	5b                   	pop    %ebx
  800d40:	5e                   	pop    %esi
  800d41:	5f                   	pop    %edi
  800d42:	5d                   	pop    %ebp
  800d43:	c3                   	ret    
  800d44:	8d 74 26 00          	lea    0x0(%esi,%eiz,1),%esi
  800d48:	39 ce                	cmp    %ecx,%esi
  800d4a:	72 0c                	jb     800d58 <__udivdi3+0x118>
  800d4c:	31 db                	xor    %ebx,%ebx
  800d4e:	3b 44 24 08          	cmp    0x8(%esp),%eax
  800d52:	0f 87 34 ff ff ff    	ja     800c8c <__udivdi3+0x4c>
  800d58:	bb 01 00 00 00       	mov    $0x1,%ebx
  800d5d:	e9 2a ff ff ff       	jmp    800c8c <__udivdi3+0x4c>
  800d62:	66 90                	xchg   %ax,%ax
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
  800d73:	53                   	push   %ebx
  800d74:	83 ec 1c             	sub    $0x1c,%esp
  800d77:	8b 54 24 3c          	mov    0x3c(%esp),%edx
  800d7b:	8b 4c 24 30          	mov    0x30(%esp),%ecx
  800d7f:	8b 74 24 34          	mov    0x34(%esp),%esi
  800d83:	8b 7c 24 38          	mov    0x38(%esp),%edi
  800d87:	85 d2                	test   %edx,%edx
  800d89:	89 4c 24 0c          	mov    %ecx,0xc(%esp)
  800d8d:	89 4c 24 08          	mov    %ecx,0x8(%esp)
  800d91:	89 f3                	mov    %esi,%ebx
  800d93:	89 3c 24             	mov    %edi,(%esp)
  800d96:	89 74 24 04          	mov    %esi,0x4(%esp)
  800d9a:	75 1c                	jne    800db8 <__umoddi3+0x48>
  800d9c:	39 f7                	cmp    %esi,%edi
  800d9e:	76 50                	jbe    800df0 <__umoddi3+0x80>
  800da0:	89 c8                	mov    %ecx,%eax
  800da2:	89 f2                	mov    %esi,%edx
  800da4:	f7 f7                	div    %edi
  800da6:	89 d0                	mov    %edx,%eax
  800da8:	31 d2                	xor    %edx,%edx
  800daa:	83 c4 1c             	add    $0x1c,%esp
  800dad:	5b                   	pop    %ebx
  800dae:	5e                   	pop    %esi
  800daf:	5f                   	pop    %edi
  800db0:	5d                   	pop    %ebp
  800db1:	c3                   	ret    
  800db2:	8d b6 00 00 00 00    	lea    0x0(%esi),%esi
  800db8:	39 f2                	cmp    %esi,%edx
  800dba:	89 d0                	mov    %edx,%eax
  800dbc:	77 52                	ja     800e10 <__umoddi3+0xa0>
  800dbe:	0f bd ea             	bsr    %edx,%ebp
  800dc1:	83 f5 1f             	xor    $0x1f,%ebp
  800dc4:	75 5a                	jne    800e20 <__umoddi3+0xb0>
  800dc6:	3b 54 24 04          	cmp    0x4(%esp),%edx
  800dca:	0f 82 e0 00 00 00    	jb     800eb0 <__umoddi3+0x140>
  800dd0:	39 0c 24             	cmp    %ecx,(%esp)
  800dd3:	0f 86 d7 00 00 00    	jbe    800eb0 <__umoddi3+0x140>
  800dd9:	8b 44 24 08          	mov    0x8(%esp),%eax
  800ddd:	8b 54 24 04          	mov    0x4(%esp),%edx
  800de1:	83 c4 1c             	add    $0x1c,%esp
  800de4:	5b                   	pop    %ebx
  800de5:	5e                   	pop    %esi
  800de6:	5f                   	pop    %edi
  800de7:	5d                   	pop    %ebp
  800de8:	c3                   	ret    
  800de9:	8d b4 26 00 00 00 00 	lea    0x0(%esi,%eiz,1),%esi
  800df0:	85 ff                	test   %edi,%edi
  800df2:	89 fd                	mov    %edi,%ebp
  800df4:	75 0b                	jne    800e01 <__umoddi3+0x91>
  800df6:	b8 01 00 00 00       	mov    $0x1,%eax
  800dfb:	31 d2                	xor    %edx,%edx
  800dfd:	f7 f7                	div    %edi
  800dff:	89 c5                	mov    %eax,%ebp
  800e01:	89 f0                	mov    %esi,%eax
  800e03:	31 d2                	xor    %edx,%edx
  800e05:	f7 f5                	div    %ebp
  800e07:	89 c8                	mov    %ecx,%eax
  800e09:	f7 f5                	div    %ebp
  800e0b:	89 d0                	mov    %edx,%eax
  800e0d:	eb 99                	jmp    800da8 <__umoddi3+0x38>
  800e0f:	90                   	nop
  800e10:	89 c8                	mov    %ecx,%eax
  800e12:	89 f2                	mov    %esi,%edx
  800e14:	83 c4 1c             	add    $0x1c,%esp
  800e17:	5b                   	pop    %ebx
  800e18:	5e                   	pop    %esi
  800e19:	5f                   	pop    %edi
  800e1a:	5d                   	pop    %ebp
  800e1b:	c3                   	ret    
  800e1c:	8d 74 26 00          	lea    0x0(%esi,%eiz,1),%esi
  800e20:	8b 34 24             	mov    (%esp),%esi
  800e23:	bf 20 00 00 00       	mov    $0x20,%edi
  800e28:	89 e9                	mov    %ebp,%ecx
  800e2a:	29 ef                	sub    %ebp,%edi
  800e2c:	d3 e0                	shl    %cl,%eax
  800e2e:	89 f9                	mov    %edi,%ecx
  800e30:	89 f2                	mov    %esi,%edx
  800e32:	d3 ea                	shr    %cl,%edx
  800e34:	89 e9                	mov    %ebp,%ecx
  800e36:	09 c2                	or     %eax,%edx
  800e38:	89 d8                	mov    %ebx,%eax
  800e3a:	89 14 24             	mov    %edx,(%esp)
  800e3d:	89 f2                	mov    %esi,%edx
  800e3f:	d3 e2                	shl    %cl,%edx
  800e41:	89 f9                	mov    %edi,%ecx
  800e43:	89 54 24 04          	mov    %edx,0x4(%esp)
  800e47:	8b 54 24 0c          	mov    0xc(%esp),%edx
  800e4b:	d3 e8                	shr    %cl,%eax
  800e4d:	89 e9                	mov    %ebp,%ecx
  800e4f:	89 c6                	mov    %eax,%esi
  800e51:	d3 e3                	shl    %cl,%ebx
  800e53:	89 f9                	mov    %edi,%ecx
  800e55:	89 d0                	mov    %edx,%eax
  800e57:	d3 e8                	shr    %cl,%eax
  800e59:	89 e9                	mov    %ebp,%ecx
  800e5b:	09 d8                	or     %ebx,%eax
  800e5d:	89 d3                	mov    %edx,%ebx
  800e5f:	89 f2                	mov    %esi,%edx
  800e61:	f7 34 24             	divl   (%esp)
  800e64:	89 d6                	mov    %edx,%esi
  800e66:	d3 e3                	shl    %cl,%ebx
  800e68:	f7 64 24 04          	mull   0x4(%esp)
  800e6c:	39 d6                	cmp    %edx,%esi
  800e6e:	89 5c 24 08          	mov    %ebx,0x8(%esp)
  800e72:	89 d1                	mov    %edx,%ecx
  800e74:	89 c3                	mov    %eax,%ebx
  800e76:	72 08                	jb     800e80 <__umoddi3+0x110>
  800e78:	75 11                	jne    800e8b <__umoddi3+0x11b>
  800e7a:	39 44 24 08          	cmp    %eax,0x8(%esp)
  800e7e:	73 0b                	jae    800e8b <__umoddi3+0x11b>
  800e80:	2b 44 24 04          	sub    0x4(%esp),%eax
  800e84:	1b 14 24             	sbb    (%esp),%edx
  800e87:	89 d1                	mov    %edx,%ecx
  800e89:	89 c3                	mov    %eax,%ebx
  800e8b:	8b 54 24 08          	mov    0x8(%esp),%edx
  800e8f:	29 da                	sub    %ebx,%edx
  800e91:	19 ce                	sbb    %ecx,%esi
  800e93:	89 f9                	mov    %edi,%ecx
  800e95:	89 f0                	mov    %esi,%eax
  800e97:	d3 e0                	shl    %cl,%eax
  800e99:	89 e9                	mov    %ebp,%ecx
  800e9b:	d3 ea                	shr    %cl,%edx
  800e9d:	89 e9                	mov    %ebp,%ecx
  800e9f:	d3 ee                	shr    %cl,%esi
  800ea1:	09 d0                	or     %edx,%eax
  800ea3:	89 f2                	mov    %esi,%edx
  800ea5:	83 c4 1c             	add    $0x1c,%esp
  800ea8:	5b                   	pop    %ebx
  800ea9:	5e                   	pop    %esi
  800eaa:	5f                   	pop    %edi
  800eab:	5d                   	pop    %ebp
  800eac:	c3                   	ret    
  800ead:	8d 76 00             	lea    0x0(%esi),%esi
  800eb0:	29 f9                	sub    %edi,%ecx
  800eb2:	19 d6                	sbb    %edx,%esi
  800eb4:	89 74 24 04          	mov    %esi,0x4(%esp)
  800eb8:	89 4c 24 08          	mov    %ecx,0x8(%esp)
  800ebc:	e9 18 ff ff ff       	jmp    800dd9 <__umoddi3+0x69>
