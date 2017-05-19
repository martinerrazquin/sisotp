
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
	cprintf("I read %08x from location 0xf0100000!\n", *(unsigned*)0xf0100000);
  800039:	ff 35 00 00 10 f0    	pushl  0xf0100000
  80003f:	68 84 0d 80 00       	push   $0x800d84
  800044:	e8 e0 00 00 00       	call   800129 <cprintf>
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
  800051:	83 ec 08             	sub    $0x8,%esp
  800054:	8b 45 08             	mov    0x8(%ebp),%eax
  800057:	8b 55 0c             	mov    0xc(%ebp),%edx
	// set thisenv to point at our Env structure in envs[].
	// LAB 3: Your code here.
	thisenv = 0;
  80005a:	c7 05 04 20 80 00 00 	movl   $0x0,0x802004
  800061:	00 00 00 

	// save the name of the program so that panic() can use it
	if (argc > 0)
  800064:	85 c0                	test   %eax,%eax
  800066:	7e 08                	jle    800070 <libmain+0x22>
		binaryname = argv[0];
  800068:	8b 0a                	mov    (%edx),%ecx
  80006a:	89 0d 00 20 80 00    	mov    %ecx,0x802000

	// call user main routine
	umain(argc, argv);
  800070:	83 ec 08             	sub    $0x8,%esp
  800073:	52                   	push   %edx
  800074:	50                   	push   %eax
  800075:	e8 b9 ff ff ff       	call   800033 <umain>

	// exit gracefully
	exit();
  80007a:	e8 05 00 00 00       	call   800084 <exit>
}
  80007f:	83 c4 10             	add    $0x10,%esp
  800082:	c9                   	leave  
  800083:	c3                   	ret    

00800084 <exit>:

#include <inc/lib.h>

void
exit(void)
{
  800084:	55                   	push   %ebp
  800085:	89 e5                	mov    %esp,%ebp
  800087:	83 ec 14             	sub    $0x14,%esp
	sys_env_destroy(0);
  80008a:	6a 00                	push   $0x0
  80008c:	e8 e0 09 00 00       	call   800a71 <sys_env_destroy>
}
  800091:	83 c4 10             	add    $0x10,%esp
  800094:	c9                   	leave  
  800095:	c3                   	ret    

00800096 <putch>:
};


static void
putch(int ch, struct printbuf *b)
{
  800096:	55                   	push   %ebp
  800097:	89 e5                	mov    %esp,%ebp
  800099:	53                   	push   %ebx
  80009a:	83 ec 04             	sub    $0x4,%esp
  80009d:	8b 5d 0c             	mov    0xc(%ebp),%ebx
	b->buf[b->idx++] = ch;
  8000a0:	8b 13                	mov    (%ebx),%edx
  8000a2:	8d 42 01             	lea    0x1(%edx),%eax
  8000a5:	89 03                	mov    %eax,(%ebx)
  8000a7:	8b 4d 08             	mov    0x8(%ebp),%ecx
  8000aa:	88 4c 13 08          	mov    %cl,0x8(%ebx,%edx,1)
	if (b->idx == 256-1) {
  8000ae:	3d ff 00 00 00       	cmp    $0xff,%eax
  8000b3:	75 1a                	jne    8000cf <putch+0x39>
		sys_cputs(b->buf, b->idx);
  8000b5:	83 ec 08             	sub    $0x8,%esp
  8000b8:	68 ff 00 00 00       	push   $0xff
  8000bd:	8d 43 08             	lea    0x8(%ebx),%eax
  8000c0:	50                   	push   %eax
  8000c1:	e8 61 09 00 00       	call   800a27 <sys_cputs>
		b->idx = 0;
  8000c6:	c7 03 00 00 00 00    	movl   $0x0,(%ebx)
  8000cc:	83 c4 10             	add    $0x10,%esp
	}
	b->cnt++;
  8000cf:	83 43 04 01          	addl   $0x1,0x4(%ebx)
}
  8000d3:	8b 5d fc             	mov    -0x4(%ebp),%ebx
  8000d6:	c9                   	leave  
  8000d7:	c3                   	ret    

008000d8 <vcprintf>:

int
vcprintf(const char *fmt, va_list ap)
{
  8000d8:	55                   	push   %ebp
  8000d9:	89 e5                	mov    %esp,%ebp
  8000db:	81 ec 18 01 00 00    	sub    $0x118,%esp
	struct printbuf b;

	b.idx = 0;
  8000e1:	c7 85 f0 fe ff ff 00 	movl   $0x0,-0x110(%ebp)
  8000e8:	00 00 00 
	b.cnt = 0;
  8000eb:	c7 85 f4 fe ff ff 00 	movl   $0x0,-0x10c(%ebp)
  8000f2:	00 00 00 
	vprintfmt((void*)putch, &b, fmt, ap);
  8000f5:	ff 75 0c             	pushl  0xc(%ebp)
  8000f8:	ff 75 08             	pushl  0x8(%ebp)
  8000fb:	8d 85 f0 fe ff ff    	lea    -0x110(%ebp),%eax
  800101:	50                   	push   %eax
  800102:	68 96 00 80 00       	push   $0x800096
  800107:	e8 86 01 00 00       	call   800292 <vprintfmt>
	sys_cputs(b.buf, b.idx);
  80010c:	83 c4 08             	add    $0x8,%esp
  80010f:	ff b5 f0 fe ff ff    	pushl  -0x110(%ebp)
  800115:	8d 85 f8 fe ff ff    	lea    -0x108(%ebp),%eax
  80011b:	50                   	push   %eax
  80011c:	e8 06 09 00 00       	call   800a27 <sys_cputs>

	return b.cnt;
}
  800121:	8b 85 f4 fe ff ff    	mov    -0x10c(%ebp),%eax
  800127:	c9                   	leave  
  800128:	c3                   	ret    

00800129 <cprintf>:

int
cprintf(const char *fmt, ...)
{
  800129:	55                   	push   %ebp
  80012a:	89 e5                	mov    %esp,%ebp
  80012c:	83 ec 10             	sub    $0x10,%esp
	va_list ap;
	int cnt;

	va_start(ap, fmt);
  80012f:	8d 45 0c             	lea    0xc(%ebp),%eax
	cnt = vcprintf(fmt, ap);
  800132:	50                   	push   %eax
  800133:	ff 75 08             	pushl  0x8(%ebp)
  800136:	e8 9d ff ff ff       	call   8000d8 <vcprintf>
	va_end(ap);

	return cnt;
}
  80013b:	c9                   	leave  
  80013c:	c3                   	ret    

0080013d <printnum>:
 * using specified putch function and associated pointer putdat.
 */
static void
printnum(void (*putch)(int, void*), void *putdat,
	 unsigned long long num, unsigned base, int width, int padc)
{
  80013d:	55                   	push   %ebp
  80013e:	89 e5                	mov    %esp,%ebp
  800140:	57                   	push   %edi
  800141:	56                   	push   %esi
  800142:	53                   	push   %ebx
  800143:	83 ec 1c             	sub    $0x1c,%esp
  800146:	89 c7                	mov    %eax,%edi
  800148:	89 d6                	mov    %edx,%esi
  80014a:	8b 45 08             	mov    0x8(%ebp),%eax
  80014d:	8b 55 0c             	mov    0xc(%ebp),%edx
  800150:	89 45 d8             	mov    %eax,-0x28(%ebp)
  800153:	89 55 dc             	mov    %edx,-0x24(%ebp)
	// first recursively print all preceding (more significant) digits
	if (num >= base) {
  800156:	8b 4d 10             	mov    0x10(%ebp),%ecx
  800159:	bb 00 00 00 00       	mov    $0x0,%ebx
  80015e:	89 4d e0             	mov    %ecx,-0x20(%ebp)
  800161:	89 5d e4             	mov    %ebx,-0x1c(%ebp)
  800164:	39 d3                	cmp    %edx,%ebx
  800166:	72 05                	jb     80016d <printnum+0x30>
  800168:	39 45 10             	cmp    %eax,0x10(%ebp)
  80016b:	77 45                	ja     8001b2 <printnum+0x75>
		printnum(putch, putdat, num / base, base, width - 1, padc);
  80016d:	83 ec 0c             	sub    $0xc,%esp
  800170:	ff 75 18             	pushl  0x18(%ebp)
  800173:	8b 45 14             	mov    0x14(%ebp),%eax
  800176:	8d 58 ff             	lea    -0x1(%eax),%ebx
  800179:	53                   	push   %ebx
  80017a:	ff 75 10             	pushl  0x10(%ebp)
  80017d:	83 ec 08             	sub    $0x8,%esp
  800180:	ff 75 e4             	pushl  -0x1c(%ebp)
  800183:	ff 75 e0             	pushl  -0x20(%ebp)
  800186:	ff 75 dc             	pushl  -0x24(%ebp)
  800189:	ff 75 d8             	pushl  -0x28(%ebp)
  80018c:	e8 6f 09 00 00       	call   800b00 <__udivdi3>
  800191:	83 c4 18             	add    $0x18,%esp
  800194:	52                   	push   %edx
  800195:	50                   	push   %eax
  800196:	89 f2                	mov    %esi,%edx
  800198:	89 f8                	mov    %edi,%eax
  80019a:	e8 9e ff ff ff       	call   80013d <printnum>
  80019f:	83 c4 20             	add    $0x20,%esp
  8001a2:	eb 18                	jmp    8001bc <printnum+0x7f>
	} else {
		// print any needed pad characters before first digit
		while (--width > 0)
			putch(padc, putdat);
  8001a4:	83 ec 08             	sub    $0x8,%esp
  8001a7:	56                   	push   %esi
  8001a8:	ff 75 18             	pushl  0x18(%ebp)
  8001ab:	ff d7                	call   *%edi
  8001ad:	83 c4 10             	add    $0x10,%esp
  8001b0:	eb 03                	jmp    8001b5 <printnum+0x78>
  8001b2:	8b 5d 14             	mov    0x14(%ebp),%ebx
	// first recursively print all preceding (more significant) digits
	if (num >= base) {
		printnum(putch, putdat, num / base, base, width - 1, padc);
	} else {
		// print any needed pad characters before first digit
		while (--width > 0)
  8001b5:	83 eb 01             	sub    $0x1,%ebx
  8001b8:	85 db                	test   %ebx,%ebx
  8001ba:	7f e8                	jg     8001a4 <printnum+0x67>
			putch(padc, putdat);
	}

	// then print this (the least significant) digit
	putch("0123456789abcdef"[num % base], putdat);
  8001bc:	83 ec 08             	sub    $0x8,%esp
  8001bf:	56                   	push   %esi
  8001c0:	83 ec 04             	sub    $0x4,%esp
  8001c3:	ff 75 e4             	pushl  -0x1c(%ebp)
  8001c6:	ff 75 e0             	pushl  -0x20(%ebp)
  8001c9:	ff 75 dc             	pushl  -0x24(%ebp)
  8001cc:	ff 75 d8             	pushl  -0x28(%ebp)
  8001cf:	e8 5c 0a 00 00       	call   800c30 <__umoddi3>
  8001d4:	83 c4 14             	add    $0x14,%esp
  8001d7:	0f be 80 b5 0d 80 00 	movsbl 0x800db5(%eax),%eax
  8001de:	50                   	push   %eax
  8001df:	ff d7                	call   *%edi
}
  8001e1:	83 c4 10             	add    $0x10,%esp
  8001e4:	8d 65 f4             	lea    -0xc(%ebp),%esp
  8001e7:	5b                   	pop    %ebx
  8001e8:	5e                   	pop    %esi
  8001e9:	5f                   	pop    %edi
  8001ea:	5d                   	pop    %ebp
  8001eb:	c3                   	ret    

008001ec <getuint>:

// Get an unsigned int of various possible sizes from a varargs list,
// depending on the lflag parameter.
static unsigned long long
getuint(va_list *ap, int lflag)
{
  8001ec:	55                   	push   %ebp
  8001ed:	89 e5                	mov    %esp,%ebp
	if (lflag >= 2)
  8001ef:	83 fa 01             	cmp    $0x1,%edx
  8001f2:	7e 0e                	jle    800202 <getuint+0x16>
		return va_arg(*ap, unsigned long long);
  8001f4:	8b 10                	mov    (%eax),%edx
  8001f6:	8d 4a 08             	lea    0x8(%edx),%ecx
  8001f9:	89 08                	mov    %ecx,(%eax)
  8001fb:	8b 02                	mov    (%edx),%eax
  8001fd:	8b 52 04             	mov    0x4(%edx),%edx
  800200:	eb 22                	jmp    800224 <getuint+0x38>
	else if (lflag)
  800202:	85 d2                	test   %edx,%edx
  800204:	74 10                	je     800216 <getuint+0x2a>
		return va_arg(*ap, unsigned long);
  800206:	8b 10                	mov    (%eax),%edx
  800208:	8d 4a 04             	lea    0x4(%edx),%ecx
  80020b:	89 08                	mov    %ecx,(%eax)
  80020d:	8b 02                	mov    (%edx),%eax
  80020f:	ba 00 00 00 00       	mov    $0x0,%edx
  800214:	eb 0e                	jmp    800224 <getuint+0x38>
	else
		return va_arg(*ap, unsigned int);
  800216:	8b 10                	mov    (%eax),%edx
  800218:	8d 4a 04             	lea    0x4(%edx),%ecx
  80021b:	89 08                	mov    %ecx,(%eax)
  80021d:	8b 02                	mov    (%edx),%eax
  80021f:	ba 00 00 00 00       	mov    $0x0,%edx
}
  800224:	5d                   	pop    %ebp
  800225:	c3                   	ret    

00800226 <getint>:

// Same as getuint but signed - can't use getuint
// because of sign extension
static long long
getint(va_list *ap, int lflag)
{
  800226:	55                   	push   %ebp
  800227:	89 e5                	mov    %esp,%ebp
	if (lflag >= 2)
  800229:	83 fa 01             	cmp    $0x1,%edx
  80022c:	7e 0e                	jle    80023c <getint+0x16>
		return va_arg(*ap, long long);
  80022e:	8b 10                	mov    (%eax),%edx
  800230:	8d 4a 08             	lea    0x8(%edx),%ecx
  800233:	89 08                	mov    %ecx,(%eax)
  800235:	8b 02                	mov    (%edx),%eax
  800237:	8b 52 04             	mov    0x4(%edx),%edx
  80023a:	eb 1a                	jmp    800256 <getint+0x30>
	else if (lflag)
  80023c:	85 d2                	test   %edx,%edx
  80023e:	74 0c                	je     80024c <getint+0x26>
		return va_arg(*ap, long);
  800240:	8b 10                	mov    (%eax),%edx
  800242:	8d 4a 04             	lea    0x4(%edx),%ecx
  800245:	89 08                	mov    %ecx,(%eax)
  800247:	8b 02                	mov    (%edx),%eax
  800249:	99                   	cltd   
  80024a:	eb 0a                	jmp    800256 <getint+0x30>
	else
		return va_arg(*ap, int);
  80024c:	8b 10                	mov    (%eax),%edx
  80024e:	8d 4a 04             	lea    0x4(%edx),%ecx
  800251:	89 08                	mov    %ecx,(%eax)
  800253:	8b 02                	mov    (%edx),%eax
  800255:	99                   	cltd   
}
  800256:	5d                   	pop    %ebp
  800257:	c3                   	ret    

00800258 <sprintputch>:
	int cnt;
};

static void
sprintputch(int ch, struct sprintbuf *b)
{
  800258:	55                   	push   %ebp
  800259:	89 e5                	mov    %esp,%ebp
  80025b:	8b 45 0c             	mov    0xc(%ebp),%eax
	b->cnt++;
  80025e:	83 40 08 01          	addl   $0x1,0x8(%eax)
	if (b->buf < b->ebuf)
  800262:	8b 10                	mov    (%eax),%edx
  800264:	3b 50 04             	cmp    0x4(%eax),%edx
  800267:	73 0a                	jae    800273 <sprintputch+0x1b>
		*b->buf++ = ch;
  800269:	8d 4a 01             	lea    0x1(%edx),%ecx
  80026c:	89 08                	mov    %ecx,(%eax)
  80026e:	8b 45 08             	mov    0x8(%ebp),%eax
  800271:	88 02                	mov    %al,(%edx)
}
  800273:	5d                   	pop    %ebp
  800274:	c3                   	ret    

00800275 <printfmt>:
	}
}

void
printfmt(void (*putch)(int, void*), void *putdat, const char *fmt, ...)
{
  800275:	55                   	push   %ebp
  800276:	89 e5                	mov    %esp,%ebp
  800278:	83 ec 08             	sub    $0x8,%esp
	va_list ap;

	va_start(ap, fmt);
  80027b:	8d 45 14             	lea    0x14(%ebp),%eax
	vprintfmt(putch, putdat, fmt, ap);
  80027e:	50                   	push   %eax
  80027f:	ff 75 10             	pushl  0x10(%ebp)
  800282:	ff 75 0c             	pushl  0xc(%ebp)
  800285:	ff 75 08             	pushl  0x8(%ebp)
  800288:	e8 05 00 00 00       	call   800292 <vprintfmt>
	va_end(ap);
}
  80028d:	83 c4 10             	add    $0x10,%esp
  800290:	c9                   	leave  
  800291:	c3                   	ret    

00800292 <vprintfmt>:
// Main function to format and print a string.
void printfmt(void (*putch)(int, void*), void *putdat, const char *fmt, ...);

void
vprintfmt(void (*putch)(int, void*), void *putdat, const char *fmt, va_list ap)
{
  800292:	55                   	push   %ebp
  800293:	89 e5                	mov    %esp,%ebp
  800295:	57                   	push   %edi
  800296:	56                   	push   %esi
  800297:	53                   	push   %ebx
  800298:	83 ec 2c             	sub    $0x2c,%esp
  80029b:	8b 75 08             	mov    0x8(%ebp),%esi
  80029e:	8b 5d 0c             	mov    0xc(%ebp),%ebx
  8002a1:	8b 7d 10             	mov    0x10(%ebp),%edi
  8002a4:	eb 12                	jmp    8002b8 <vprintfmt+0x26>
	int base, lflag, width, precision, altflag;
	char padc;

	while (1) {
		while ((ch = *(unsigned char *) fmt++) != '%') {
			if (ch == '\0')
  8002a6:	85 c0                	test   %eax,%eax
  8002a8:	0f 84 44 03 00 00    	je     8005f2 <vprintfmt+0x360>
				return;
			putch(ch, putdat);
  8002ae:	83 ec 08             	sub    $0x8,%esp
  8002b1:	53                   	push   %ebx
  8002b2:	50                   	push   %eax
  8002b3:	ff d6                	call   *%esi
  8002b5:	83 c4 10             	add    $0x10,%esp
	unsigned long long num;
	int base, lflag, width, precision, altflag;
	char padc;

	while (1) {
		while ((ch = *(unsigned char *) fmt++) != '%') {
  8002b8:	83 c7 01             	add    $0x1,%edi
  8002bb:	0f b6 47 ff          	movzbl -0x1(%edi),%eax
  8002bf:	83 f8 25             	cmp    $0x25,%eax
  8002c2:	75 e2                	jne    8002a6 <vprintfmt+0x14>
  8002c4:	c6 45 d4 20          	movb   $0x20,-0x2c(%ebp)
  8002c8:	c7 45 d8 00 00 00 00 	movl   $0x0,-0x28(%ebp)
  8002cf:	c7 45 d0 ff ff ff ff 	movl   $0xffffffff,-0x30(%ebp)
  8002d6:	c7 45 e0 ff ff ff ff 	movl   $0xffffffff,-0x20(%ebp)
  8002dd:	ba 00 00 00 00       	mov    $0x0,%edx
  8002e2:	eb 07                	jmp    8002eb <vprintfmt+0x59>
		width = -1;
		precision = -1;
		lflag = 0;
		altflag = 0;
	reswitch:
		switch (ch = *(unsigned char *) fmt++) {
  8002e4:	8b 7d e4             	mov    -0x1c(%ebp),%edi

		// flag to pad on the right
		case '-':
			padc = '-';
  8002e7:	c6 45 d4 2d          	movb   $0x2d,-0x2c(%ebp)
		width = -1;
		precision = -1;
		lflag = 0;
		altflag = 0;
	reswitch:
		switch (ch = *(unsigned char *) fmt++) {
  8002eb:	8d 47 01             	lea    0x1(%edi),%eax
  8002ee:	89 45 e4             	mov    %eax,-0x1c(%ebp)
  8002f1:	0f b6 07             	movzbl (%edi),%eax
  8002f4:	0f b6 c8             	movzbl %al,%ecx
  8002f7:	83 e8 23             	sub    $0x23,%eax
  8002fa:	3c 55                	cmp    $0x55,%al
  8002fc:	0f 87 d5 02 00 00    	ja     8005d7 <vprintfmt+0x345>
  800302:	0f b6 c0             	movzbl %al,%eax
  800305:	ff 24 85 44 0e 80 00 	jmp    *0x800e44(,%eax,4)
  80030c:	8b 7d e4             	mov    -0x1c(%ebp),%edi
			padc = '-';
			goto reswitch;

		// flag to pad with 0's instead of spaces
		case '0':
			padc = '0';
  80030f:	c6 45 d4 30          	movb   $0x30,-0x2c(%ebp)
  800313:	eb d6                	jmp    8002eb <vprintfmt+0x59>
		width = -1;
		precision = -1;
		lflag = 0;
		altflag = 0;
	reswitch:
		switch (ch = *(unsigned char *) fmt++) {
  800315:	8b 7d e4             	mov    -0x1c(%ebp),%edi
  800318:	b8 00 00 00 00       	mov    $0x0,%eax
  80031d:	89 55 e4             	mov    %edx,-0x1c(%ebp)
		case '6':
		case '7':
		case '8':
		case '9':
			for (precision = 0; ; ++fmt) {
				precision = precision * 10 + ch - '0';
  800320:	8d 04 80             	lea    (%eax,%eax,4),%eax
  800323:	8d 44 41 d0          	lea    -0x30(%ecx,%eax,2),%eax
				ch = *fmt;
  800327:	0f be 0f             	movsbl (%edi),%ecx
				if (ch < '0' || ch > '9')
  80032a:	8d 51 d0             	lea    -0x30(%ecx),%edx
  80032d:	83 fa 09             	cmp    $0x9,%edx
  800330:	77 39                	ja     80036b <vprintfmt+0xd9>
		case '5':
		case '6':
		case '7':
		case '8':
		case '9':
			for (precision = 0; ; ++fmt) {
  800332:	83 c7 01             	add    $0x1,%edi
				precision = precision * 10 + ch - '0';
				ch = *fmt;
				if (ch < '0' || ch > '9')
					break;
			}
  800335:	eb e9                	jmp    800320 <vprintfmt+0x8e>
			goto process_precision;

		case '*':
			precision = va_arg(ap, int);
  800337:	8b 45 14             	mov    0x14(%ebp),%eax
  80033a:	8d 48 04             	lea    0x4(%eax),%ecx
  80033d:	89 4d 14             	mov    %ecx,0x14(%ebp)
  800340:	8b 00                	mov    (%eax),%eax
  800342:	89 45 d0             	mov    %eax,-0x30(%ebp)
		width = -1;
		precision = -1;
		lflag = 0;
		altflag = 0;
	reswitch:
		switch (ch = *(unsigned char *) fmt++) {
  800345:	8b 7d e4             	mov    -0x1c(%ebp),%edi
			}
			goto process_precision;

		case '*':
			precision = va_arg(ap, int);
			goto process_precision;
  800348:	eb 27                	jmp    800371 <vprintfmt+0xdf>
  80034a:	8b 45 e0             	mov    -0x20(%ebp),%eax
  80034d:	85 c0                	test   %eax,%eax
  80034f:	b9 00 00 00 00       	mov    $0x0,%ecx
  800354:	0f 49 c8             	cmovns %eax,%ecx
  800357:	89 4d e0             	mov    %ecx,-0x20(%ebp)
		width = -1;
		precision = -1;
		lflag = 0;
		altflag = 0;
	reswitch:
		switch (ch = *(unsigned char *) fmt++) {
  80035a:	8b 7d e4             	mov    -0x1c(%ebp),%edi
  80035d:	eb 8c                	jmp    8002eb <vprintfmt+0x59>
  80035f:	8b 7d e4             	mov    -0x1c(%ebp),%edi
			if (width < 0)
				width = 0;
			goto reswitch;

		case '#':
			altflag = 1;
  800362:	c7 45 d8 01 00 00 00 	movl   $0x1,-0x28(%ebp)
			goto reswitch;
  800369:	eb 80                	jmp    8002eb <vprintfmt+0x59>
  80036b:	8b 55 e4             	mov    -0x1c(%ebp),%edx
  80036e:	89 45 d0             	mov    %eax,-0x30(%ebp)

		process_precision:
			if (width < 0)
  800371:	83 7d e0 00          	cmpl   $0x0,-0x20(%ebp)
  800375:	0f 89 70 ff ff ff    	jns    8002eb <vprintfmt+0x59>
				width = precision, precision = -1;
  80037b:	8b 45 d0             	mov    -0x30(%ebp),%eax
  80037e:	89 45 e0             	mov    %eax,-0x20(%ebp)
  800381:	c7 45 d0 ff ff ff ff 	movl   $0xffffffff,-0x30(%ebp)
  800388:	e9 5e ff ff ff       	jmp    8002eb <vprintfmt+0x59>
			goto reswitch;

		// long flag (doubled for long long)
		case 'l':
			lflag++;
  80038d:	83 c2 01             	add    $0x1,%edx
		width = -1;
		precision = -1;
		lflag = 0;
		altflag = 0;
	reswitch:
		switch (ch = *(unsigned char *) fmt++) {
  800390:	8b 7d e4             	mov    -0x1c(%ebp),%edi
			goto reswitch;

		// long flag (doubled for long long)
		case 'l':
			lflag++;
			goto reswitch;
  800393:	e9 53 ff ff ff       	jmp    8002eb <vprintfmt+0x59>

		// character
		case 'c':
			putch(va_arg(ap, int), putdat);
  800398:	8b 45 14             	mov    0x14(%ebp),%eax
  80039b:	8d 50 04             	lea    0x4(%eax),%edx
  80039e:	89 55 14             	mov    %edx,0x14(%ebp)
  8003a1:	83 ec 08             	sub    $0x8,%esp
  8003a4:	53                   	push   %ebx
  8003a5:	ff 30                	pushl  (%eax)
  8003a7:	ff d6                	call   *%esi
			break;
  8003a9:	83 c4 10             	add    $0x10,%esp
		width = -1;
		precision = -1;
		lflag = 0;
		altflag = 0;
	reswitch:
		switch (ch = *(unsigned char *) fmt++) {
  8003ac:	8b 7d e4             	mov    -0x1c(%ebp),%edi
			goto reswitch;

		// character
		case 'c':
			putch(va_arg(ap, int), putdat);
			break;
  8003af:	e9 04 ff ff ff       	jmp    8002b8 <vprintfmt+0x26>

		// error message
		case 'e':
			err = va_arg(ap, int);
  8003b4:	8b 45 14             	mov    0x14(%ebp),%eax
  8003b7:	8d 50 04             	lea    0x4(%eax),%edx
  8003ba:	89 55 14             	mov    %edx,0x14(%ebp)
  8003bd:	8b 00                	mov    (%eax),%eax
  8003bf:	99                   	cltd   
  8003c0:	31 d0                	xor    %edx,%eax
  8003c2:	29 d0                	sub    %edx,%eax
			if (err < 0)
				err = -err;
			if (err >= MAXERROR || (p = error_string[err]) == NULL)
  8003c4:	83 f8 06             	cmp    $0x6,%eax
  8003c7:	7f 0b                	jg     8003d4 <vprintfmt+0x142>
  8003c9:	8b 14 85 9c 0f 80 00 	mov    0x800f9c(,%eax,4),%edx
  8003d0:	85 d2                	test   %edx,%edx
  8003d2:	75 18                	jne    8003ec <vprintfmt+0x15a>
				printfmt(putch, putdat, "error %d", err);
  8003d4:	50                   	push   %eax
  8003d5:	68 cd 0d 80 00       	push   $0x800dcd
  8003da:	53                   	push   %ebx
  8003db:	56                   	push   %esi
  8003dc:	e8 94 fe ff ff       	call   800275 <printfmt>
  8003e1:	83 c4 10             	add    $0x10,%esp
		width = -1;
		precision = -1;
		lflag = 0;
		altflag = 0;
	reswitch:
		switch (ch = *(unsigned char *) fmt++) {
  8003e4:	8b 7d e4             	mov    -0x1c(%ebp),%edi
		case 'e':
			err = va_arg(ap, int);
			if (err < 0)
				err = -err;
			if (err >= MAXERROR || (p = error_string[err]) == NULL)
				printfmt(putch, putdat, "error %d", err);
  8003e7:	e9 cc fe ff ff       	jmp    8002b8 <vprintfmt+0x26>
			else
				printfmt(putch, putdat, "%s", p);
  8003ec:	52                   	push   %edx
  8003ed:	68 d6 0d 80 00       	push   $0x800dd6
  8003f2:	53                   	push   %ebx
  8003f3:	56                   	push   %esi
  8003f4:	e8 7c fe ff ff       	call   800275 <printfmt>
  8003f9:	83 c4 10             	add    $0x10,%esp
		width = -1;
		precision = -1;
		lflag = 0;
		altflag = 0;
	reswitch:
		switch (ch = *(unsigned char *) fmt++) {
  8003fc:	8b 7d e4             	mov    -0x1c(%ebp),%edi
  8003ff:	e9 b4 fe ff ff       	jmp    8002b8 <vprintfmt+0x26>
				printfmt(putch, putdat, "%s", p);
			break;

		// string
		case 's':
			if ((p = va_arg(ap, char *)) == NULL)
  800404:	8b 45 14             	mov    0x14(%ebp),%eax
  800407:	8d 50 04             	lea    0x4(%eax),%edx
  80040a:	89 55 14             	mov    %edx,0x14(%ebp)
  80040d:	8b 38                	mov    (%eax),%edi
				p = "(null)";
  80040f:	85 ff                	test   %edi,%edi
  800411:	b8 c6 0d 80 00       	mov    $0x800dc6,%eax
  800416:	0f 44 f8             	cmove  %eax,%edi
			if (width > 0 && padc != '-')
  800419:	83 7d e0 00          	cmpl   $0x0,-0x20(%ebp)
  80041d:	0f 8e 94 00 00 00    	jle    8004b7 <vprintfmt+0x225>
  800423:	80 7d d4 2d          	cmpb   $0x2d,-0x2c(%ebp)
  800427:	0f 84 98 00 00 00    	je     8004c5 <vprintfmt+0x233>
				for (width -= strnlen(p, precision); width > 0; width--)
  80042d:	83 ec 08             	sub    $0x8,%esp
  800430:	ff 75 d0             	pushl  -0x30(%ebp)
  800433:	57                   	push   %edi
  800434:	e8 41 02 00 00       	call   80067a <strnlen>
  800439:	8b 4d e0             	mov    -0x20(%ebp),%ecx
  80043c:	29 c1                	sub    %eax,%ecx
  80043e:	89 4d cc             	mov    %ecx,-0x34(%ebp)
  800441:	83 c4 10             	add    $0x10,%esp
					putch(padc, putdat);
  800444:	0f be 45 d4          	movsbl -0x2c(%ebp),%eax
  800448:	89 45 e0             	mov    %eax,-0x20(%ebp)
  80044b:	89 7d d4             	mov    %edi,-0x2c(%ebp)
  80044e:	89 cf                	mov    %ecx,%edi
		// string
		case 's':
			if ((p = va_arg(ap, char *)) == NULL)
				p = "(null)";
			if (width > 0 && padc != '-')
				for (width -= strnlen(p, precision); width > 0; width--)
  800450:	eb 0f                	jmp    800461 <vprintfmt+0x1cf>
					putch(padc, putdat);
  800452:	83 ec 08             	sub    $0x8,%esp
  800455:	53                   	push   %ebx
  800456:	ff 75 e0             	pushl  -0x20(%ebp)
  800459:	ff d6                	call   *%esi
		// string
		case 's':
			if ((p = va_arg(ap, char *)) == NULL)
				p = "(null)";
			if (width > 0 && padc != '-')
				for (width -= strnlen(p, precision); width > 0; width--)
  80045b:	83 ef 01             	sub    $0x1,%edi
  80045e:	83 c4 10             	add    $0x10,%esp
  800461:	85 ff                	test   %edi,%edi
  800463:	7f ed                	jg     800452 <vprintfmt+0x1c0>
  800465:	8b 7d d4             	mov    -0x2c(%ebp),%edi
  800468:	8b 4d cc             	mov    -0x34(%ebp),%ecx
  80046b:	85 c9                	test   %ecx,%ecx
  80046d:	b8 00 00 00 00       	mov    $0x0,%eax
  800472:	0f 49 c1             	cmovns %ecx,%eax
  800475:	29 c1                	sub    %eax,%ecx
  800477:	89 75 08             	mov    %esi,0x8(%ebp)
  80047a:	8b 75 d0             	mov    -0x30(%ebp),%esi
  80047d:	89 5d 0c             	mov    %ebx,0xc(%ebp)
  800480:	89 cb                	mov    %ecx,%ebx
  800482:	eb 4d                	jmp    8004d1 <vprintfmt+0x23f>
					putch(padc, putdat);
			for (; (ch = *p++) != '\0' && (precision < 0 || --precision >= 0); width--)
				if (altflag && (ch < ' ' || ch > '~'))
  800484:	83 7d d8 00          	cmpl   $0x0,-0x28(%ebp)
  800488:	74 1b                	je     8004a5 <vprintfmt+0x213>
  80048a:	0f be c0             	movsbl %al,%eax
  80048d:	83 e8 20             	sub    $0x20,%eax
  800490:	83 f8 5e             	cmp    $0x5e,%eax
  800493:	76 10                	jbe    8004a5 <vprintfmt+0x213>
					putch('?', putdat);
  800495:	83 ec 08             	sub    $0x8,%esp
  800498:	ff 75 0c             	pushl  0xc(%ebp)
  80049b:	6a 3f                	push   $0x3f
  80049d:	ff 55 08             	call   *0x8(%ebp)
  8004a0:	83 c4 10             	add    $0x10,%esp
  8004a3:	eb 0d                	jmp    8004b2 <vprintfmt+0x220>
				else
					putch(ch, putdat);
  8004a5:	83 ec 08             	sub    $0x8,%esp
  8004a8:	ff 75 0c             	pushl  0xc(%ebp)
  8004ab:	52                   	push   %edx
  8004ac:	ff 55 08             	call   *0x8(%ebp)
  8004af:	83 c4 10             	add    $0x10,%esp
			if ((p = va_arg(ap, char *)) == NULL)
				p = "(null)";
			if (width > 0 && padc != '-')
				for (width -= strnlen(p, precision); width > 0; width--)
					putch(padc, putdat);
			for (; (ch = *p++) != '\0' && (precision < 0 || --precision >= 0); width--)
  8004b2:	83 eb 01             	sub    $0x1,%ebx
  8004b5:	eb 1a                	jmp    8004d1 <vprintfmt+0x23f>
  8004b7:	89 75 08             	mov    %esi,0x8(%ebp)
  8004ba:	8b 75 d0             	mov    -0x30(%ebp),%esi
  8004bd:	89 5d 0c             	mov    %ebx,0xc(%ebp)
  8004c0:	8b 5d e0             	mov    -0x20(%ebp),%ebx
  8004c3:	eb 0c                	jmp    8004d1 <vprintfmt+0x23f>
  8004c5:	89 75 08             	mov    %esi,0x8(%ebp)
  8004c8:	8b 75 d0             	mov    -0x30(%ebp),%esi
  8004cb:	89 5d 0c             	mov    %ebx,0xc(%ebp)
  8004ce:	8b 5d e0             	mov    -0x20(%ebp),%ebx
  8004d1:	83 c7 01             	add    $0x1,%edi
  8004d4:	0f b6 47 ff          	movzbl -0x1(%edi),%eax
  8004d8:	0f be d0             	movsbl %al,%edx
  8004db:	85 d2                	test   %edx,%edx
  8004dd:	74 23                	je     800502 <vprintfmt+0x270>
  8004df:	85 f6                	test   %esi,%esi
  8004e1:	78 a1                	js     800484 <vprintfmt+0x1f2>
  8004e3:	83 ee 01             	sub    $0x1,%esi
  8004e6:	79 9c                	jns    800484 <vprintfmt+0x1f2>
  8004e8:	89 df                	mov    %ebx,%edi
  8004ea:	8b 75 08             	mov    0x8(%ebp),%esi
  8004ed:	8b 5d 0c             	mov    0xc(%ebp),%ebx
  8004f0:	eb 18                	jmp    80050a <vprintfmt+0x278>
				if (altflag && (ch < ' ' || ch > '~'))
					putch('?', putdat);
				else
					putch(ch, putdat);
			for (; width > 0; width--)
				putch(' ', putdat);
  8004f2:	83 ec 08             	sub    $0x8,%esp
  8004f5:	53                   	push   %ebx
  8004f6:	6a 20                	push   $0x20
  8004f8:	ff d6                	call   *%esi
			for (; (ch = *p++) != '\0' && (precision < 0 || --precision >= 0); width--)
				if (altflag && (ch < ' ' || ch > '~'))
					putch('?', putdat);
				else
					putch(ch, putdat);
			for (; width > 0; width--)
  8004fa:	83 ef 01             	sub    $0x1,%edi
  8004fd:	83 c4 10             	add    $0x10,%esp
  800500:	eb 08                	jmp    80050a <vprintfmt+0x278>
  800502:	89 df                	mov    %ebx,%edi
  800504:	8b 75 08             	mov    0x8(%ebp),%esi
  800507:	8b 5d 0c             	mov    0xc(%ebp),%ebx
  80050a:	85 ff                	test   %edi,%edi
  80050c:	7f e4                	jg     8004f2 <vprintfmt+0x260>
		width = -1;
		precision = -1;
		lflag = 0;
		altflag = 0;
	reswitch:
		switch (ch = *(unsigned char *) fmt++) {
  80050e:	8b 7d e4             	mov    -0x1c(%ebp),%edi
  800511:	e9 a2 fd ff ff       	jmp    8002b8 <vprintfmt+0x26>
				putch(' ', putdat);
			break;

		// (signed) decimal
		case 'd':
			num = getint(&ap, lflag);
  800516:	8d 45 14             	lea    0x14(%ebp),%eax
  800519:	e8 08 fd ff ff       	call   800226 <getint>
  80051e:	89 45 d8             	mov    %eax,-0x28(%ebp)
  800521:	89 55 dc             	mov    %edx,-0x24(%ebp)
			if ((long long) num < 0) {
				putch('-', putdat);
				num = -(long long) num;
			}
			base = 10;
  800524:	b9 0a 00 00 00       	mov    $0xa,%ecx
			break;

		// (signed) decimal
		case 'd':
			num = getint(&ap, lflag);
			if ((long long) num < 0) {
  800529:	83 7d dc 00          	cmpl   $0x0,-0x24(%ebp)
  80052d:	79 74                	jns    8005a3 <vprintfmt+0x311>
				putch('-', putdat);
  80052f:	83 ec 08             	sub    $0x8,%esp
  800532:	53                   	push   %ebx
  800533:	6a 2d                	push   $0x2d
  800535:	ff d6                	call   *%esi
				num = -(long long) num;
  800537:	8b 45 d8             	mov    -0x28(%ebp),%eax
  80053a:	8b 55 dc             	mov    -0x24(%ebp),%edx
  80053d:	f7 d8                	neg    %eax
  80053f:	83 d2 00             	adc    $0x0,%edx
  800542:	f7 da                	neg    %edx
  800544:	83 c4 10             	add    $0x10,%esp
			}
			base = 10;
  800547:	b9 0a 00 00 00       	mov    $0xa,%ecx
  80054c:	eb 55                	jmp    8005a3 <vprintfmt+0x311>
			goto number;

		// unsigned decimal
		case 'u':
			num = getuint(&ap, lflag);
  80054e:	8d 45 14             	lea    0x14(%ebp),%eax
  800551:	e8 96 fc ff ff       	call   8001ec <getuint>
			base = 10;
  800556:	b9 0a 00 00 00       	mov    $0xa,%ecx
			goto number;
  80055b:	eb 46                	jmp    8005a3 <vprintfmt+0x311>

		// (unsigned) octal
		case 'o':
			num = getuint(&ap, lflag);
  80055d:	8d 45 14             	lea    0x14(%ebp),%eax
  800560:	e8 87 fc ff ff       	call   8001ec <getuint>
			base = 8;
  800565:	b9 08 00 00 00       	mov    $0x8,%ecx
			goto number;
  80056a:	eb 37                	jmp    8005a3 <vprintfmt+0x311>

		// pointer
		case 'p':
			putch('0', putdat);
  80056c:	83 ec 08             	sub    $0x8,%esp
  80056f:	53                   	push   %ebx
  800570:	6a 30                	push   $0x30
  800572:	ff d6                	call   *%esi
			putch('x', putdat);
  800574:	83 c4 08             	add    $0x8,%esp
  800577:	53                   	push   %ebx
  800578:	6a 78                	push   $0x78
  80057a:	ff d6                	call   *%esi
			num = (unsigned long long)
				(uintptr_t) va_arg(ap, void *);
  80057c:	8b 45 14             	mov    0x14(%ebp),%eax
  80057f:	8d 50 04             	lea    0x4(%eax),%edx
  800582:	89 55 14             	mov    %edx,0x14(%ebp)

		// pointer
		case 'p':
			putch('0', putdat);
			putch('x', putdat);
			num = (unsigned long long)
  800585:	8b 00                	mov    (%eax),%eax
  800587:	ba 00 00 00 00       	mov    $0x0,%edx
				(uintptr_t) va_arg(ap, void *);
			base = 16;
			goto number;
  80058c:	83 c4 10             	add    $0x10,%esp
		case 'p':
			putch('0', putdat);
			putch('x', putdat);
			num = (unsigned long long)
				(uintptr_t) va_arg(ap, void *);
			base = 16;
  80058f:	b9 10 00 00 00       	mov    $0x10,%ecx
			goto number;
  800594:	eb 0d                	jmp    8005a3 <vprintfmt+0x311>

		// (unsigned) hexadecimal
		case 'x':
			num = getuint(&ap, lflag);
  800596:	8d 45 14             	lea    0x14(%ebp),%eax
  800599:	e8 4e fc ff ff       	call   8001ec <getuint>
			base = 16;
  80059e:	b9 10 00 00 00       	mov    $0x10,%ecx
		number:
			printnum(putch, putdat, num, base, width, padc);
  8005a3:	83 ec 0c             	sub    $0xc,%esp
  8005a6:	0f be 7d d4          	movsbl -0x2c(%ebp),%edi
  8005aa:	57                   	push   %edi
  8005ab:	ff 75 e0             	pushl  -0x20(%ebp)
  8005ae:	51                   	push   %ecx
  8005af:	52                   	push   %edx
  8005b0:	50                   	push   %eax
  8005b1:	89 da                	mov    %ebx,%edx
  8005b3:	89 f0                	mov    %esi,%eax
  8005b5:	e8 83 fb ff ff       	call   80013d <printnum>
			break;
  8005ba:	83 c4 20             	add    $0x20,%esp
  8005bd:	8b 7d e4             	mov    -0x1c(%ebp),%edi
  8005c0:	e9 f3 fc ff ff       	jmp    8002b8 <vprintfmt+0x26>

		// escaped '%' character
		case '%':
			putch(ch, putdat);
  8005c5:	83 ec 08             	sub    $0x8,%esp
  8005c8:	53                   	push   %ebx
  8005c9:	51                   	push   %ecx
  8005ca:	ff d6                	call   *%esi
			break;
  8005cc:	83 c4 10             	add    $0x10,%esp
		width = -1;
		precision = -1;
		lflag = 0;
		altflag = 0;
	reswitch:
		switch (ch = *(unsigned char *) fmt++) {
  8005cf:	8b 7d e4             	mov    -0x1c(%ebp),%edi
			break;

		// escaped '%' character
		case '%':
			putch(ch, putdat);
			break;
  8005d2:	e9 e1 fc ff ff       	jmp    8002b8 <vprintfmt+0x26>

		// unrecognized escape sequence - just print it literally
		default:
			putch('%', putdat);
  8005d7:	83 ec 08             	sub    $0x8,%esp
  8005da:	53                   	push   %ebx
  8005db:	6a 25                	push   $0x25
  8005dd:	ff d6                	call   *%esi
			for (fmt--; fmt[-1] != '%'; fmt--)
  8005df:	83 c4 10             	add    $0x10,%esp
  8005e2:	eb 03                	jmp    8005e7 <vprintfmt+0x355>
  8005e4:	83 ef 01             	sub    $0x1,%edi
  8005e7:	80 7f ff 25          	cmpb   $0x25,-0x1(%edi)
  8005eb:	75 f7                	jne    8005e4 <vprintfmt+0x352>
  8005ed:	e9 c6 fc ff ff       	jmp    8002b8 <vprintfmt+0x26>
				/* do nothing */;
			break;
		}
	}
}
  8005f2:	8d 65 f4             	lea    -0xc(%ebp),%esp
  8005f5:	5b                   	pop    %ebx
  8005f6:	5e                   	pop    %esi
  8005f7:	5f                   	pop    %edi
  8005f8:	5d                   	pop    %ebp
  8005f9:	c3                   	ret    

008005fa <vsnprintf>:
		*b->buf++ = ch;
}

int
vsnprintf(char *buf, int n, const char *fmt, va_list ap)
{
  8005fa:	55                   	push   %ebp
  8005fb:	89 e5                	mov    %esp,%ebp
  8005fd:	83 ec 18             	sub    $0x18,%esp
  800600:	8b 45 08             	mov    0x8(%ebp),%eax
  800603:	8b 55 0c             	mov    0xc(%ebp),%edx
	struct sprintbuf b = {buf, buf+n-1, 0};
  800606:	89 45 ec             	mov    %eax,-0x14(%ebp)
  800609:	8d 4c 10 ff          	lea    -0x1(%eax,%edx,1),%ecx
  80060d:	89 4d f0             	mov    %ecx,-0x10(%ebp)
  800610:	c7 45 f4 00 00 00 00 	movl   $0x0,-0xc(%ebp)

	if (buf == NULL || n < 1)
  800617:	85 c0                	test   %eax,%eax
  800619:	74 26                	je     800641 <vsnprintf+0x47>
  80061b:	85 d2                	test   %edx,%edx
  80061d:	7e 22                	jle    800641 <vsnprintf+0x47>
		return -E_INVAL;

	// print the string to the buffer
	vprintfmt((void*)sprintputch, &b, fmt, ap);
  80061f:	ff 75 14             	pushl  0x14(%ebp)
  800622:	ff 75 10             	pushl  0x10(%ebp)
  800625:	8d 45 ec             	lea    -0x14(%ebp),%eax
  800628:	50                   	push   %eax
  800629:	68 58 02 80 00       	push   $0x800258
  80062e:	e8 5f fc ff ff       	call   800292 <vprintfmt>

	// null terminate the buffer
	*b.buf = '\0';
  800633:	8b 45 ec             	mov    -0x14(%ebp),%eax
  800636:	c6 00 00             	movb   $0x0,(%eax)

	return b.cnt;
  800639:	8b 45 f4             	mov    -0xc(%ebp),%eax
  80063c:	83 c4 10             	add    $0x10,%esp
  80063f:	eb 05                	jmp    800646 <vsnprintf+0x4c>
vsnprintf(char *buf, int n, const char *fmt, va_list ap)
{
	struct sprintbuf b = {buf, buf+n-1, 0};

	if (buf == NULL || n < 1)
		return -E_INVAL;
  800641:	b8 fd ff ff ff       	mov    $0xfffffffd,%eax

	// null terminate the buffer
	*b.buf = '\0';

	return b.cnt;
}
  800646:	c9                   	leave  
  800647:	c3                   	ret    

00800648 <snprintf>:

int
snprintf(char *buf, int n, const char *fmt, ...)
{
  800648:	55                   	push   %ebp
  800649:	89 e5                	mov    %esp,%ebp
  80064b:	83 ec 08             	sub    $0x8,%esp
	va_list ap;
	int rc;

	va_start(ap, fmt);
  80064e:	8d 45 14             	lea    0x14(%ebp),%eax
	rc = vsnprintf(buf, n, fmt, ap);
  800651:	50                   	push   %eax
  800652:	ff 75 10             	pushl  0x10(%ebp)
  800655:	ff 75 0c             	pushl  0xc(%ebp)
  800658:	ff 75 08             	pushl  0x8(%ebp)
  80065b:	e8 9a ff ff ff       	call   8005fa <vsnprintf>
	va_end(ap);

	return rc;
}
  800660:	c9                   	leave  
  800661:	c3                   	ret    

00800662 <strlen>:
// Primespipe runs 3x faster this way.
#define ASM 1

int
strlen(const char *s)
{
  800662:	55                   	push   %ebp
  800663:	89 e5                	mov    %esp,%ebp
  800665:	8b 55 08             	mov    0x8(%ebp),%edx
	int n;

	for (n = 0; *s != '\0'; s++)
  800668:	b8 00 00 00 00       	mov    $0x0,%eax
  80066d:	eb 03                	jmp    800672 <strlen+0x10>
		n++;
  80066f:	83 c0 01             	add    $0x1,%eax
int
strlen(const char *s)
{
	int n;

	for (n = 0; *s != '\0'; s++)
  800672:	80 3c 02 00          	cmpb   $0x0,(%edx,%eax,1)
  800676:	75 f7                	jne    80066f <strlen+0xd>
		n++;
	return n;
}
  800678:	5d                   	pop    %ebp
  800679:	c3                   	ret    

0080067a <strnlen>:

int
strnlen(const char *s, size_t size)
{
  80067a:	55                   	push   %ebp
  80067b:	89 e5                	mov    %esp,%ebp
  80067d:	8b 4d 08             	mov    0x8(%ebp),%ecx
  800680:	8b 45 0c             	mov    0xc(%ebp),%eax
	int n;

	for (n = 0; size > 0 && *s != '\0'; s++, size--)
  800683:	ba 00 00 00 00       	mov    $0x0,%edx
  800688:	eb 03                	jmp    80068d <strnlen+0x13>
		n++;
  80068a:	83 c2 01             	add    $0x1,%edx
int
strnlen(const char *s, size_t size)
{
	int n;

	for (n = 0; size > 0 && *s != '\0'; s++, size--)
  80068d:	39 c2                	cmp    %eax,%edx
  80068f:	74 08                	je     800699 <strnlen+0x1f>
  800691:	80 3c 11 00          	cmpb   $0x0,(%ecx,%edx,1)
  800695:	75 f3                	jne    80068a <strnlen+0x10>
  800697:	89 d0                	mov    %edx,%eax
		n++;
	return n;
}
  800699:	5d                   	pop    %ebp
  80069a:	c3                   	ret    

0080069b <strcpy>:

char *
strcpy(char *dst, const char *src)
{
  80069b:	55                   	push   %ebp
  80069c:	89 e5                	mov    %esp,%ebp
  80069e:	53                   	push   %ebx
  80069f:	8b 45 08             	mov    0x8(%ebp),%eax
  8006a2:	8b 4d 0c             	mov    0xc(%ebp),%ecx
	char *ret;

	ret = dst;
	while ((*dst++ = *src++) != '\0')
  8006a5:	89 c2                	mov    %eax,%edx
  8006a7:	83 c2 01             	add    $0x1,%edx
  8006aa:	83 c1 01             	add    $0x1,%ecx
  8006ad:	0f b6 59 ff          	movzbl -0x1(%ecx),%ebx
  8006b1:	88 5a ff             	mov    %bl,-0x1(%edx)
  8006b4:	84 db                	test   %bl,%bl
  8006b6:	75 ef                	jne    8006a7 <strcpy+0xc>
		/* do nothing */;
	return ret;
}
  8006b8:	5b                   	pop    %ebx
  8006b9:	5d                   	pop    %ebp
  8006ba:	c3                   	ret    

008006bb <strcat>:

char *
strcat(char *dst, const char *src)
{
  8006bb:	55                   	push   %ebp
  8006bc:	89 e5                	mov    %esp,%ebp
  8006be:	53                   	push   %ebx
  8006bf:	8b 5d 08             	mov    0x8(%ebp),%ebx
	int len = strlen(dst);
  8006c2:	53                   	push   %ebx
  8006c3:	e8 9a ff ff ff       	call   800662 <strlen>
  8006c8:	83 c4 04             	add    $0x4,%esp
	strcpy(dst + len, src);
  8006cb:	ff 75 0c             	pushl  0xc(%ebp)
  8006ce:	01 d8                	add    %ebx,%eax
  8006d0:	50                   	push   %eax
  8006d1:	e8 c5 ff ff ff       	call   80069b <strcpy>
	return dst;
}
  8006d6:	89 d8                	mov    %ebx,%eax
  8006d8:	8b 5d fc             	mov    -0x4(%ebp),%ebx
  8006db:	c9                   	leave  
  8006dc:	c3                   	ret    

008006dd <strncpy>:

char *
strncpy(char *dst, const char *src, size_t size) {
  8006dd:	55                   	push   %ebp
  8006de:	89 e5                	mov    %esp,%ebp
  8006e0:	56                   	push   %esi
  8006e1:	53                   	push   %ebx
  8006e2:	8b 75 08             	mov    0x8(%ebp),%esi
  8006e5:	8b 4d 0c             	mov    0xc(%ebp),%ecx
  8006e8:	89 f3                	mov    %esi,%ebx
  8006ea:	03 5d 10             	add    0x10(%ebp),%ebx
	size_t i;
	char *ret;

	ret = dst;
	for (i = 0; i < size; i++) {
  8006ed:	89 f2                	mov    %esi,%edx
  8006ef:	eb 0f                	jmp    800700 <strncpy+0x23>
		*dst++ = *src;
  8006f1:	83 c2 01             	add    $0x1,%edx
  8006f4:	0f b6 01             	movzbl (%ecx),%eax
  8006f7:	88 42 ff             	mov    %al,-0x1(%edx)
		// If strlen(src) < size, null-pad 'dst' out to 'size' chars
		if (*src != '\0')
			src++;
  8006fa:	80 39 01             	cmpb   $0x1,(%ecx)
  8006fd:	83 d9 ff             	sbb    $0xffffffff,%ecx
strncpy(char *dst, const char *src, size_t size) {
	size_t i;
	char *ret;

	ret = dst;
	for (i = 0; i < size; i++) {
  800700:	39 da                	cmp    %ebx,%edx
  800702:	75 ed                	jne    8006f1 <strncpy+0x14>
		// If strlen(src) < size, null-pad 'dst' out to 'size' chars
		if (*src != '\0')
			src++;
	}
	return ret;
}
  800704:	89 f0                	mov    %esi,%eax
  800706:	5b                   	pop    %ebx
  800707:	5e                   	pop    %esi
  800708:	5d                   	pop    %ebp
  800709:	c3                   	ret    

0080070a <strlcpy>:

size_t
strlcpy(char *dst, const char *src, size_t size)
{
  80070a:	55                   	push   %ebp
  80070b:	89 e5                	mov    %esp,%ebp
  80070d:	56                   	push   %esi
  80070e:	53                   	push   %ebx
  80070f:	8b 75 08             	mov    0x8(%ebp),%esi
  800712:	8b 4d 0c             	mov    0xc(%ebp),%ecx
  800715:	8b 55 10             	mov    0x10(%ebp),%edx
  800718:	89 f0                	mov    %esi,%eax
	char *dst_in;

	dst_in = dst;
	if (size > 0) {
  80071a:	85 d2                	test   %edx,%edx
  80071c:	74 21                	je     80073f <strlcpy+0x35>
  80071e:	8d 44 16 ff          	lea    -0x1(%esi,%edx,1),%eax
  800722:	89 f2                	mov    %esi,%edx
  800724:	eb 09                	jmp    80072f <strlcpy+0x25>
		while (--size > 0 && *src != '\0')
			*dst++ = *src++;
  800726:	83 c2 01             	add    $0x1,%edx
  800729:	83 c1 01             	add    $0x1,%ecx
  80072c:	88 5a ff             	mov    %bl,-0x1(%edx)
{
	char *dst_in;

	dst_in = dst;
	if (size > 0) {
		while (--size > 0 && *src != '\0')
  80072f:	39 c2                	cmp    %eax,%edx
  800731:	74 09                	je     80073c <strlcpy+0x32>
  800733:	0f b6 19             	movzbl (%ecx),%ebx
  800736:	84 db                	test   %bl,%bl
  800738:	75 ec                	jne    800726 <strlcpy+0x1c>
  80073a:	89 d0                	mov    %edx,%eax
			*dst++ = *src++;
		*dst = '\0';
  80073c:	c6 00 00             	movb   $0x0,(%eax)
	}
	return dst - dst_in;
  80073f:	29 f0                	sub    %esi,%eax
}
  800741:	5b                   	pop    %ebx
  800742:	5e                   	pop    %esi
  800743:	5d                   	pop    %ebp
  800744:	c3                   	ret    

00800745 <strcmp>:

int
strcmp(const char *p, const char *q)
{
  800745:	55                   	push   %ebp
  800746:	89 e5                	mov    %esp,%ebp
  800748:	8b 4d 08             	mov    0x8(%ebp),%ecx
  80074b:	8b 55 0c             	mov    0xc(%ebp),%edx
	while (*p && *p == *q)
  80074e:	eb 06                	jmp    800756 <strcmp+0x11>
		p++, q++;
  800750:	83 c1 01             	add    $0x1,%ecx
  800753:	83 c2 01             	add    $0x1,%edx
}

int
strcmp(const char *p, const char *q)
{
	while (*p && *p == *q)
  800756:	0f b6 01             	movzbl (%ecx),%eax
  800759:	84 c0                	test   %al,%al
  80075b:	74 04                	je     800761 <strcmp+0x1c>
  80075d:	3a 02                	cmp    (%edx),%al
  80075f:	74 ef                	je     800750 <strcmp+0xb>
		p++, q++;
	return (int) ((unsigned char) *p - (unsigned char) *q);
  800761:	0f b6 c0             	movzbl %al,%eax
  800764:	0f b6 12             	movzbl (%edx),%edx
  800767:	29 d0                	sub    %edx,%eax
}
  800769:	5d                   	pop    %ebp
  80076a:	c3                   	ret    

0080076b <strncmp>:

int
strncmp(const char *p, const char *q, size_t n)
{
  80076b:	55                   	push   %ebp
  80076c:	89 e5                	mov    %esp,%ebp
  80076e:	53                   	push   %ebx
  80076f:	8b 45 08             	mov    0x8(%ebp),%eax
  800772:	8b 55 0c             	mov    0xc(%ebp),%edx
  800775:	89 c3                	mov    %eax,%ebx
  800777:	03 5d 10             	add    0x10(%ebp),%ebx
	while (n > 0 && *p && *p == *q)
  80077a:	eb 06                	jmp    800782 <strncmp+0x17>
		n--, p++, q++;
  80077c:	83 c0 01             	add    $0x1,%eax
  80077f:	83 c2 01             	add    $0x1,%edx
}

int
strncmp(const char *p, const char *q, size_t n)
{
	while (n > 0 && *p && *p == *q)
  800782:	39 d8                	cmp    %ebx,%eax
  800784:	74 15                	je     80079b <strncmp+0x30>
  800786:	0f b6 08             	movzbl (%eax),%ecx
  800789:	84 c9                	test   %cl,%cl
  80078b:	74 04                	je     800791 <strncmp+0x26>
  80078d:	3a 0a                	cmp    (%edx),%cl
  80078f:	74 eb                	je     80077c <strncmp+0x11>
		n--, p++, q++;
	if (n == 0)
		return 0;
	else
		return (int) ((unsigned char) *p - (unsigned char) *q);
  800791:	0f b6 00             	movzbl (%eax),%eax
  800794:	0f b6 12             	movzbl (%edx),%edx
  800797:	29 d0                	sub    %edx,%eax
  800799:	eb 05                	jmp    8007a0 <strncmp+0x35>
strncmp(const char *p, const char *q, size_t n)
{
	while (n > 0 && *p && *p == *q)
		n--, p++, q++;
	if (n == 0)
		return 0;
  80079b:	b8 00 00 00 00       	mov    $0x0,%eax
	else
		return (int) ((unsigned char) *p - (unsigned char) *q);
}
  8007a0:	5b                   	pop    %ebx
  8007a1:	5d                   	pop    %ebp
  8007a2:	c3                   	ret    

008007a3 <strchr>:

// Return a pointer to the first occurrence of 'c' in 's',
// or a null pointer if the string has no 'c'.
char *
strchr(const char *s, char c)
{
  8007a3:	55                   	push   %ebp
  8007a4:	89 e5                	mov    %esp,%ebp
  8007a6:	8b 45 08             	mov    0x8(%ebp),%eax
  8007a9:	0f b6 4d 0c          	movzbl 0xc(%ebp),%ecx
	for (; *s; s++)
  8007ad:	eb 07                	jmp    8007b6 <strchr+0x13>
		if (*s == c)
  8007af:	38 ca                	cmp    %cl,%dl
  8007b1:	74 0f                	je     8007c2 <strchr+0x1f>
// Return a pointer to the first occurrence of 'c' in 's',
// or a null pointer if the string has no 'c'.
char *
strchr(const char *s, char c)
{
	for (; *s; s++)
  8007b3:	83 c0 01             	add    $0x1,%eax
  8007b6:	0f b6 10             	movzbl (%eax),%edx
  8007b9:	84 d2                	test   %dl,%dl
  8007bb:	75 f2                	jne    8007af <strchr+0xc>
		if (*s == c)
			return (char *) s;
	return 0;
  8007bd:	b8 00 00 00 00       	mov    $0x0,%eax
}
  8007c2:	5d                   	pop    %ebp
  8007c3:	c3                   	ret    

008007c4 <strfind>:

// Return a pointer to the first occurrence of 'c' in 's',
// or a pointer to the string-ending null character if the string has no 'c'.
char *
strfind(const char *s, char c)
{
  8007c4:	55                   	push   %ebp
  8007c5:	89 e5                	mov    %esp,%ebp
  8007c7:	8b 45 08             	mov    0x8(%ebp),%eax
  8007ca:	0f b6 4d 0c          	movzbl 0xc(%ebp),%ecx
	for (; *s; s++)
  8007ce:	eb 03                	jmp    8007d3 <strfind+0xf>
  8007d0:	83 c0 01             	add    $0x1,%eax
  8007d3:	0f b6 10             	movzbl (%eax),%edx
		if (*s == c)
  8007d6:	38 ca                	cmp    %cl,%dl
  8007d8:	74 04                	je     8007de <strfind+0x1a>
  8007da:	84 d2                	test   %dl,%dl
  8007dc:	75 f2                	jne    8007d0 <strfind+0xc>
			break;
	return (char *) s;
}
  8007de:	5d                   	pop    %ebp
  8007df:	c3                   	ret    

008007e0 <memset>:

#if ASM
void *
memset(void *v, int c, size_t n)
{
  8007e0:	55                   	push   %ebp
  8007e1:	89 e5                	mov    %esp,%ebp
  8007e3:	57                   	push   %edi
  8007e4:	56                   	push   %esi
  8007e5:	53                   	push   %ebx
  8007e6:	8b 55 08             	mov    0x8(%ebp),%edx
  8007e9:	8b 4d 10             	mov    0x10(%ebp),%ecx
	char *p = v;

	if (n == 0)
  8007ec:	85 c9                	test   %ecx,%ecx
  8007ee:	74 37                	je     800827 <memset+0x47>
		return v;
	if ((int)v%4 == 0 && n%4 == 0) {
  8007f0:	f6 c2 03             	test   $0x3,%dl
  8007f3:	75 2a                	jne    80081f <memset+0x3f>
  8007f5:	f6 c1 03             	test   $0x3,%cl
  8007f8:	75 25                	jne    80081f <memset+0x3f>
		c &= 0xFF;
  8007fa:	0f b6 5d 0c          	movzbl 0xc(%ebp),%ebx
		c = (c<<24)|(c<<16)|(c<<8)|c;
  8007fe:	89 df                	mov    %ebx,%edi
  800800:	c1 e7 08             	shl    $0x8,%edi
  800803:	89 de                	mov    %ebx,%esi
  800805:	c1 e6 18             	shl    $0x18,%esi
  800808:	89 d8                	mov    %ebx,%eax
  80080a:	c1 e0 10             	shl    $0x10,%eax
  80080d:	09 f0                	or     %esi,%eax
  80080f:	09 c3                	or     %eax,%ebx
		asm volatile("cld; rep stosl\n"
			: "=D" (p), "=c" (n)
			: "D" (p), "a" (c), "c" (n/4)
  800811:	c1 e9 02             	shr    $0x2,%ecx
	if (n == 0)
		return v;
	if ((int)v%4 == 0 && n%4 == 0) {
		c &= 0xFF;
		c = (c<<24)|(c<<16)|(c<<8)|c;
		asm volatile("cld; rep stosl\n"
  800814:	89 f8                	mov    %edi,%eax
  800816:	09 d8                	or     %ebx,%eax
  800818:	89 d7                	mov    %edx,%edi
  80081a:	fc                   	cld    
  80081b:	f3 ab                	rep stos %eax,%es:(%edi)
  80081d:	eb 08                	jmp    800827 <memset+0x47>
			: "=D" (p), "=c" (n)
			: "D" (p), "a" (c), "c" (n/4)
			: "cc", "memory");
	} else
		asm volatile("cld; rep stosb\n"
  80081f:	89 d7                	mov    %edx,%edi
  800821:	8b 45 0c             	mov    0xc(%ebp),%eax
  800824:	fc                   	cld    
  800825:	f3 aa                	rep stos %al,%es:(%edi)
			: "=D" (p), "=c" (n)
			: "0" (p), "a" (c), "1" (n)
			: "cc", "memory");
	return v;
}
  800827:	89 d0                	mov    %edx,%eax
  800829:	5b                   	pop    %ebx
  80082a:	5e                   	pop    %esi
  80082b:	5f                   	pop    %edi
  80082c:	5d                   	pop    %ebp
  80082d:	c3                   	ret    

0080082e <memmove>:

void *
memmove(void *dst, const void *src, size_t n)
{
  80082e:	55                   	push   %ebp
  80082f:	89 e5                	mov    %esp,%ebp
  800831:	57                   	push   %edi
  800832:	56                   	push   %esi
  800833:	8b 45 08             	mov    0x8(%ebp),%eax
  800836:	8b 75 0c             	mov    0xc(%ebp),%esi
  800839:	8b 4d 10             	mov    0x10(%ebp),%ecx
	const char *s;
	char *d;

	s = src;
	d = dst;
	if (s < d && s + n > d) {
  80083c:	39 c6                	cmp    %eax,%esi
  80083e:	73 35                	jae    800875 <memmove+0x47>
  800840:	8d 14 0e             	lea    (%esi,%ecx,1),%edx
  800843:	39 d0                	cmp    %edx,%eax
  800845:	73 2e                	jae    800875 <memmove+0x47>
		s += n;
		d += n;
  800847:	8d 3c 08             	lea    (%eax,%ecx,1),%edi
		if ((int)s%4 == 0 && (int)d%4 == 0 && n%4 == 0)
  80084a:	89 d6                	mov    %edx,%esi
  80084c:	09 fe                	or     %edi,%esi
  80084e:	f7 c6 03 00 00 00    	test   $0x3,%esi
  800854:	75 13                	jne    800869 <memmove+0x3b>
  800856:	f6 c1 03             	test   $0x3,%cl
  800859:	75 0e                	jne    800869 <memmove+0x3b>
			asm volatile("std; rep movsl\n"
  80085b:	83 ef 04             	sub    $0x4,%edi
  80085e:	8d 72 fc             	lea    -0x4(%edx),%esi
  800861:	c1 e9 02             	shr    $0x2,%ecx
  800864:	fd                   	std    
  800865:	f3 a5                	rep movsl %ds:(%esi),%es:(%edi)
  800867:	eb 09                	jmp    800872 <memmove+0x44>
				:: "D" (d-4), "S" (s-4), "c" (n/4) : "cc", "memory");
		else
			asm volatile("std; rep movsb\n"
  800869:	83 ef 01             	sub    $0x1,%edi
  80086c:	8d 72 ff             	lea    -0x1(%edx),%esi
  80086f:	fd                   	std    
  800870:	f3 a4                	rep movsb %ds:(%esi),%es:(%edi)
				:: "D" (d-1), "S" (s-1), "c" (n) : "cc", "memory");
		// Some versions of GCC rely on DF being clear
		asm volatile("cld" ::: "cc");
  800872:	fc                   	cld    
  800873:	eb 1d                	jmp    800892 <memmove+0x64>
	} else {
		if ((int)s%4 == 0 && (int)d%4 == 0 && n%4 == 0)
  800875:	89 f2                	mov    %esi,%edx
  800877:	09 c2                	or     %eax,%edx
  800879:	f6 c2 03             	test   $0x3,%dl
  80087c:	75 0f                	jne    80088d <memmove+0x5f>
  80087e:	f6 c1 03             	test   $0x3,%cl
  800881:	75 0a                	jne    80088d <memmove+0x5f>
			asm volatile("cld; rep movsl\n"
  800883:	c1 e9 02             	shr    $0x2,%ecx
  800886:	89 c7                	mov    %eax,%edi
  800888:	fc                   	cld    
  800889:	f3 a5                	rep movsl %ds:(%esi),%es:(%edi)
  80088b:	eb 05                	jmp    800892 <memmove+0x64>
				:: "D" (d), "S" (s), "c" (n/4) : "cc", "memory");
		else
			asm volatile("cld; rep movsb\n"
  80088d:	89 c7                	mov    %eax,%edi
  80088f:	fc                   	cld    
  800890:	f3 a4                	rep movsb %ds:(%esi),%es:(%edi)
				:: "D" (d), "S" (s), "c" (n) : "cc", "memory");
	}
	return dst;
}
  800892:	5e                   	pop    %esi
  800893:	5f                   	pop    %edi
  800894:	5d                   	pop    %ebp
  800895:	c3                   	ret    

00800896 <memcpy>:
}
#endif

void *
memcpy(void *dst, const void *src, size_t n)
{
  800896:	55                   	push   %ebp
  800897:	89 e5                	mov    %esp,%ebp
	return memmove(dst, src, n);
  800899:	ff 75 10             	pushl  0x10(%ebp)
  80089c:	ff 75 0c             	pushl  0xc(%ebp)
  80089f:	ff 75 08             	pushl  0x8(%ebp)
  8008a2:	e8 87 ff ff ff       	call   80082e <memmove>
}
  8008a7:	c9                   	leave  
  8008a8:	c3                   	ret    

008008a9 <memcmp>:

int
memcmp(const void *v1, const void *v2, size_t n)
{
  8008a9:	55                   	push   %ebp
  8008aa:	89 e5                	mov    %esp,%ebp
  8008ac:	56                   	push   %esi
  8008ad:	53                   	push   %ebx
  8008ae:	8b 45 08             	mov    0x8(%ebp),%eax
  8008b1:	8b 55 0c             	mov    0xc(%ebp),%edx
  8008b4:	89 c6                	mov    %eax,%esi
  8008b6:	03 75 10             	add    0x10(%ebp),%esi
	const uint8_t *s1 = (const uint8_t *) v1;
	const uint8_t *s2 = (const uint8_t *) v2;

	while (n-- > 0) {
  8008b9:	eb 1a                	jmp    8008d5 <memcmp+0x2c>
		if (*s1 != *s2)
  8008bb:	0f b6 08             	movzbl (%eax),%ecx
  8008be:	0f b6 1a             	movzbl (%edx),%ebx
  8008c1:	38 d9                	cmp    %bl,%cl
  8008c3:	74 0a                	je     8008cf <memcmp+0x26>
			return (int) *s1 - (int) *s2;
  8008c5:	0f b6 c1             	movzbl %cl,%eax
  8008c8:	0f b6 db             	movzbl %bl,%ebx
  8008cb:	29 d8                	sub    %ebx,%eax
  8008cd:	eb 0f                	jmp    8008de <memcmp+0x35>
		s1++, s2++;
  8008cf:	83 c0 01             	add    $0x1,%eax
  8008d2:	83 c2 01             	add    $0x1,%edx
memcmp(const void *v1, const void *v2, size_t n)
{
	const uint8_t *s1 = (const uint8_t *) v1;
	const uint8_t *s2 = (const uint8_t *) v2;

	while (n-- > 0) {
  8008d5:	39 f0                	cmp    %esi,%eax
  8008d7:	75 e2                	jne    8008bb <memcmp+0x12>
		if (*s1 != *s2)
			return (int) *s1 - (int) *s2;
		s1++, s2++;
	}

	return 0;
  8008d9:	b8 00 00 00 00       	mov    $0x0,%eax
}
  8008de:	5b                   	pop    %ebx
  8008df:	5e                   	pop    %esi
  8008e0:	5d                   	pop    %ebp
  8008e1:	c3                   	ret    

008008e2 <memfind>:

void *
memfind(const void *s, int c, size_t n)
{
  8008e2:	55                   	push   %ebp
  8008e3:	89 e5                	mov    %esp,%ebp
  8008e5:	8b 45 08             	mov    0x8(%ebp),%eax
  8008e8:	8b 4d 0c             	mov    0xc(%ebp),%ecx
	const void *ends = (const char *) s + n;
  8008eb:	89 c2                	mov    %eax,%edx
  8008ed:	03 55 10             	add    0x10(%ebp),%edx
	for (; s < ends; s++)
  8008f0:	eb 07                	jmp    8008f9 <memfind+0x17>
		if (*(const unsigned char *) s == (unsigned char) c)
  8008f2:	38 08                	cmp    %cl,(%eax)
  8008f4:	74 07                	je     8008fd <memfind+0x1b>

void *
memfind(const void *s, int c, size_t n)
{
	const void *ends = (const char *) s + n;
	for (; s < ends; s++)
  8008f6:	83 c0 01             	add    $0x1,%eax
  8008f9:	39 d0                	cmp    %edx,%eax
  8008fb:	72 f5                	jb     8008f2 <memfind+0x10>
		if (*(const unsigned char *) s == (unsigned char) c)
			break;
	return (void *) s;
}
  8008fd:	5d                   	pop    %ebp
  8008fe:	c3                   	ret    

008008ff <strtol>:

long
strtol(const char *s, char **endptr, int base)
{
  8008ff:	55                   	push   %ebp
  800900:	89 e5                	mov    %esp,%ebp
  800902:	57                   	push   %edi
  800903:	56                   	push   %esi
  800904:	53                   	push   %ebx
  800905:	8b 4d 08             	mov    0x8(%ebp),%ecx
  800908:	8b 5d 10             	mov    0x10(%ebp),%ebx
	int neg = 0;
	long val = 0;

	// gobble initial whitespace
	while (*s == ' ' || *s == '\t')
  80090b:	eb 03                	jmp    800910 <strtol+0x11>
		s++;
  80090d:	83 c1 01             	add    $0x1,%ecx
{
	int neg = 0;
	long val = 0;

	// gobble initial whitespace
	while (*s == ' ' || *s == '\t')
  800910:	0f b6 01             	movzbl (%ecx),%eax
  800913:	3c 20                	cmp    $0x20,%al
  800915:	74 f6                	je     80090d <strtol+0xe>
  800917:	3c 09                	cmp    $0x9,%al
  800919:	74 f2                	je     80090d <strtol+0xe>
		s++;

	// plus/minus sign
	if (*s == '+')
  80091b:	3c 2b                	cmp    $0x2b,%al
  80091d:	75 0a                	jne    800929 <strtol+0x2a>
		s++;
  80091f:	83 c1 01             	add    $0x1,%ecx
}

long
strtol(const char *s, char **endptr, int base)
{
	int neg = 0;
  800922:	bf 00 00 00 00       	mov    $0x0,%edi
  800927:	eb 11                	jmp    80093a <strtol+0x3b>
  800929:	bf 00 00 00 00       	mov    $0x0,%edi
		s++;

	// plus/minus sign
	if (*s == '+')
		s++;
	else if (*s == '-')
  80092e:	3c 2d                	cmp    $0x2d,%al
  800930:	75 08                	jne    80093a <strtol+0x3b>
		s++, neg = 1;
  800932:	83 c1 01             	add    $0x1,%ecx
  800935:	bf 01 00 00 00       	mov    $0x1,%edi

	// hex or octal base prefix
	if ((base == 0 || base == 16) && (s[0] == '0' && s[1] == 'x'))
  80093a:	f7 c3 ef ff ff ff    	test   $0xffffffef,%ebx
  800940:	75 15                	jne    800957 <strtol+0x58>
  800942:	80 39 30             	cmpb   $0x30,(%ecx)
  800945:	75 10                	jne    800957 <strtol+0x58>
  800947:	80 79 01 78          	cmpb   $0x78,0x1(%ecx)
  80094b:	75 7c                	jne    8009c9 <strtol+0xca>
		s += 2, base = 16;
  80094d:	83 c1 02             	add    $0x2,%ecx
  800950:	bb 10 00 00 00       	mov    $0x10,%ebx
  800955:	eb 16                	jmp    80096d <strtol+0x6e>
	else if (base == 0 && s[0] == '0')
  800957:	85 db                	test   %ebx,%ebx
  800959:	75 12                	jne    80096d <strtol+0x6e>
		s++, base = 8;
	else if (base == 0)
		base = 10;
  80095b:	bb 0a 00 00 00       	mov    $0xa,%ebx
		s++, neg = 1;

	// hex or octal base prefix
	if ((base == 0 || base == 16) && (s[0] == '0' && s[1] == 'x'))
		s += 2, base = 16;
	else if (base == 0 && s[0] == '0')
  800960:	80 39 30             	cmpb   $0x30,(%ecx)
  800963:	75 08                	jne    80096d <strtol+0x6e>
		s++, base = 8;
  800965:	83 c1 01             	add    $0x1,%ecx
  800968:	bb 08 00 00 00       	mov    $0x8,%ebx
	else if (base == 0)
		base = 10;
  80096d:	b8 00 00 00 00       	mov    $0x0,%eax
  800972:	89 5d 10             	mov    %ebx,0x10(%ebp)

	// digits
	while (1) {
		int dig;

		if (*s >= '0' && *s <= '9')
  800975:	0f b6 11             	movzbl (%ecx),%edx
  800978:	8d 72 d0             	lea    -0x30(%edx),%esi
  80097b:	89 f3                	mov    %esi,%ebx
  80097d:	80 fb 09             	cmp    $0x9,%bl
  800980:	77 08                	ja     80098a <strtol+0x8b>
			dig = *s - '0';
  800982:	0f be d2             	movsbl %dl,%edx
  800985:	83 ea 30             	sub    $0x30,%edx
  800988:	eb 22                	jmp    8009ac <strtol+0xad>
		else if (*s >= 'a' && *s <= 'z')
  80098a:	8d 72 9f             	lea    -0x61(%edx),%esi
  80098d:	89 f3                	mov    %esi,%ebx
  80098f:	80 fb 19             	cmp    $0x19,%bl
  800992:	77 08                	ja     80099c <strtol+0x9d>
			dig = *s - 'a' + 10;
  800994:	0f be d2             	movsbl %dl,%edx
  800997:	83 ea 57             	sub    $0x57,%edx
  80099a:	eb 10                	jmp    8009ac <strtol+0xad>
		else if (*s >= 'A' && *s <= 'Z')
  80099c:	8d 72 bf             	lea    -0x41(%edx),%esi
  80099f:	89 f3                	mov    %esi,%ebx
  8009a1:	80 fb 19             	cmp    $0x19,%bl
  8009a4:	77 16                	ja     8009bc <strtol+0xbd>
			dig = *s - 'A' + 10;
  8009a6:	0f be d2             	movsbl %dl,%edx
  8009a9:	83 ea 37             	sub    $0x37,%edx
		else
			break;
		if (dig >= base)
  8009ac:	3b 55 10             	cmp    0x10(%ebp),%edx
  8009af:	7d 0b                	jge    8009bc <strtol+0xbd>
			break;
		s++, val = (val * base) + dig;
  8009b1:	83 c1 01             	add    $0x1,%ecx
  8009b4:	0f af 45 10          	imul   0x10(%ebp),%eax
  8009b8:	01 d0                	add    %edx,%eax
		// we don't properly detect overflow!
	}
  8009ba:	eb b9                	jmp    800975 <strtol+0x76>

	if (endptr)
  8009bc:	83 7d 0c 00          	cmpl   $0x0,0xc(%ebp)
  8009c0:	74 0d                	je     8009cf <strtol+0xd0>
		*endptr = (char *) s;
  8009c2:	8b 75 0c             	mov    0xc(%ebp),%esi
  8009c5:	89 0e                	mov    %ecx,(%esi)
  8009c7:	eb 06                	jmp    8009cf <strtol+0xd0>
		s++, neg = 1;

	// hex or octal base prefix
	if ((base == 0 || base == 16) && (s[0] == '0' && s[1] == 'x'))
		s += 2, base = 16;
	else if (base == 0 && s[0] == '0')
  8009c9:	85 db                	test   %ebx,%ebx
  8009cb:	74 98                	je     800965 <strtol+0x66>
  8009cd:	eb 9e                	jmp    80096d <strtol+0x6e>
		// we don't properly detect overflow!
	}

	if (endptr)
		*endptr = (char *) s;
	return (neg ? -val : val);
  8009cf:	89 c2                	mov    %eax,%edx
  8009d1:	f7 da                	neg    %edx
  8009d3:	85 ff                	test   %edi,%edi
  8009d5:	0f 45 c2             	cmovne %edx,%eax
}
  8009d8:	5b                   	pop    %ebx
  8009d9:	5e                   	pop    %esi
  8009da:	5f                   	pop    %edi
  8009db:	5d                   	pop    %ebp
  8009dc:	c3                   	ret    

008009dd <syscall>:
#include <inc/syscall.h>
#include <inc/lib.h>

static inline int32_t
syscall(int num, int check, uint32_t a1, uint32_t a2, uint32_t a3, uint32_t a4, uint32_t a5)
{
  8009dd:	55                   	push   %ebp
  8009de:	89 e5                	mov    %esp,%ebp
  8009e0:	57                   	push   %edi
  8009e1:	56                   	push   %esi
  8009e2:	53                   	push   %ebx
  8009e3:	83 ec 1c             	sub    $0x1c,%esp
  8009e6:	89 45 e0             	mov    %eax,-0x20(%ebp)
  8009e9:	89 55 e4             	mov    %edx,-0x1c(%ebp)
  8009ec:	89 ca                	mov    %ecx,%edx
	//
	// The last clause tells the assembler that this can
	// potentially change the condition codes and arbitrary
	// memory locations.

	asm volatile("int %1\n"
  8009ee:	8b 4d 08             	mov    0x8(%ebp),%ecx
  8009f1:	8b 5d 0c             	mov    0xc(%ebp),%ebx
  8009f4:	8b 7d 10             	mov    0x10(%ebp),%edi
  8009f7:	8b 75 14             	mov    0x14(%ebp),%esi
  8009fa:	cd 30                	int    $0x30
		       "b" (a3),
		       "D" (a4),
		       "S" (a5)
		     : "cc", "memory");

	if(check && ret > 0)
  8009fc:	83 7d e4 00          	cmpl   $0x0,-0x1c(%ebp)
  800a00:	74 1d                	je     800a1f <syscall+0x42>
  800a02:	85 c0                	test   %eax,%eax
  800a04:	7e 19                	jle    800a1f <syscall+0x42>
  800a06:	8b 55 e0             	mov    -0x20(%ebp),%edx
		panic("syscall %d returned %d (> 0)", num, ret);
  800a09:	83 ec 0c             	sub    $0xc,%esp
  800a0c:	50                   	push   %eax
  800a0d:	52                   	push   %edx
  800a0e:	68 b8 0f 80 00       	push   $0x800fb8
  800a13:	6a 23                	push   $0x23
  800a15:	68 d5 0f 80 00       	push   $0x800fd5
  800a1a:	e8 98 00 00 00       	call   800ab7 <_panic>

	return ret;
}
  800a1f:	8d 65 f4             	lea    -0xc(%ebp),%esp
  800a22:	5b                   	pop    %ebx
  800a23:	5e                   	pop    %esi
  800a24:	5f                   	pop    %edi
  800a25:	5d                   	pop    %ebp
  800a26:	c3                   	ret    

00800a27 <sys_cputs>:

void
sys_cputs(const char *s, size_t len)
{
  800a27:	55                   	push   %ebp
  800a28:	89 e5                	mov    %esp,%ebp
  800a2a:	83 ec 08             	sub    $0x8,%esp
	syscall(SYS_cputs, 0, (uint32_t)s, len, 0, 0, 0);
  800a2d:	6a 00                	push   $0x0
  800a2f:	6a 00                	push   $0x0
  800a31:	6a 00                	push   $0x0
  800a33:	ff 75 0c             	pushl  0xc(%ebp)
  800a36:	8b 4d 08             	mov    0x8(%ebp),%ecx
  800a39:	ba 00 00 00 00       	mov    $0x0,%edx
  800a3e:	b8 00 00 00 00       	mov    $0x0,%eax
  800a43:	e8 95 ff ff ff       	call   8009dd <syscall>
}
  800a48:	83 c4 10             	add    $0x10,%esp
  800a4b:	c9                   	leave  
  800a4c:	c3                   	ret    

00800a4d <sys_cgetc>:

int
sys_cgetc(void)
{
  800a4d:	55                   	push   %ebp
  800a4e:	89 e5                	mov    %esp,%ebp
  800a50:	83 ec 08             	sub    $0x8,%esp
	return syscall(SYS_cgetc, 0, 0, 0, 0, 0, 0);
  800a53:	6a 00                	push   $0x0
  800a55:	6a 00                	push   $0x0
  800a57:	6a 00                	push   $0x0
  800a59:	6a 00                	push   $0x0
  800a5b:	b9 00 00 00 00       	mov    $0x0,%ecx
  800a60:	ba 00 00 00 00       	mov    $0x0,%edx
  800a65:	b8 01 00 00 00       	mov    $0x1,%eax
  800a6a:	e8 6e ff ff ff       	call   8009dd <syscall>
}
  800a6f:	c9                   	leave  
  800a70:	c3                   	ret    

00800a71 <sys_env_destroy>:

int
sys_env_destroy(envid_t envid)
{
  800a71:	55                   	push   %ebp
  800a72:	89 e5                	mov    %esp,%ebp
  800a74:	83 ec 08             	sub    $0x8,%esp
	return syscall(SYS_env_destroy, 1, envid, 0, 0, 0, 0);
  800a77:	6a 00                	push   $0x0
  800a79:	6a 00                	push   $0x0
  800a7b:	6a 00                	push   $0x0
  800a7d:	6a 00                	push   $0x0
  800a7f:	8b 4d 08             	mov    0x8(%ebp),%ecx
  800a82:	ba 01 00 00 00       	mov    $0x1,%edx
  800a87:	b8 03 00 00 00       	mov    $0x3,%eax
  800a8c:	e8 4c ff ff ff       	call   8009dd <syscall>
}
  800a91:	c9                   	leave  
  800a92:	c3                   	ret    

00800a93 <sys_getenvid>:

envid_t
sys_getenvid(void)
{
  800a93:	55                   	push   %ebp
  800a94:	89 e5                	mov    %esp,%ebp
  800a96:	83 ec 08             	sub    $0x8,%esp
	 return syscall(SYS_getenvid, 0, 0, 0, 0, 0, 0);
  800a99:	6a 00                	push   $0x0
  800a9b:	6a 00                	push   $0x0
  800a9d:	6a 00                	push   $0x0
  800a9f:	6a 00                	push   $0x0
  800aa1:	b9 00 00 00 00       	mov    $0x0,%ecx
  800aa6:	ba 00 00 00 00       	mov    $0x0,%edx
  800aab:	b8 02 00 00 00       	mov    $0x2,%eax
  800ab0:	e8 28 ff ff ff       	call   8009dd <syscall>
}
  800ab5:	c9                   	leave  
  800ab6:	c3                   	ret    

00800ab7 <_panic>:
 * It prints "panic: <message>", then causes a breakpoint exception,
 * which causes JOS to enter the JOS kernel monitor.
 */
void
_panic(const char *file, int line, const char *fmt, ...)
{
  800ab7:	55                   	push   %ebp
  800ab8:	89 e5                	mov    %esp,%ebp
  800aba:	56                   	push   %esi
  800abb:	53                   	push   %ebx
	va_list ap;

	va_start(ap, fmt);
  800abc:	8d 5d 14             	lea    0x14(%ebp),%ebx

	// Print the panic message
	cprintf("[%08x] user panic in %s at %s:%d: ",
  800abf:	8b 35 00 20 80 00    	mov    0x802000,%esi
  800ac5:	e8 c9 ff ff ff       	call   800a93 <sys_getenvid>
  800aca:	83 ec 0c             	sub    $0xc,%esp
  800acd:	ff 75 0c             	pushl  0xc(%ebp)
  800ad0:	ff 75 08             	pushl  0x8(%ebp)
  800ad3:	56                   	push   %esi
  800ad4:	50                   	push   %eax
  800ad5:	68 e4 0f 80 00       	push   $0x800fe4
  800ada:	e8 4a f6 ff ff       	call   800129 <cprintf>
		sys_getenvid(), binaryname, file, line);
	vcprintf(fmt, ap);
  800adf:	83 c4 18             	add    $0x18,%esp
  800ae2:	53                   	push   %ebx
  800ae3:	ff 75 10             	pushl  0x10(%ebp)
  800ae6:	e8 ed f5 ff ff       	call   8000d8 <vcprintf>
	cprintf("\n");
  800aeb:	c7 04 24 08 10 80 00 	movl   $0x801008,(%esp)
  800af2:	e8 32 f6 ff ff       	call   800129 <cprintf>
  800af7:	83 c4 10             	add    $0x10,%esp

	// Cause a breakpoint exception
	while (1)
		asm volatile("int3");
  800afa:	cc                   	int3   
  800afb:	eb fd                	jmp    800afa <_panic+0x43>
  800afd:	66 90                	xchg   %ax,%ax
  800aff:	90                   	nop

00800b00 <__udivdi3>:
  800b00:	55                   	push   %ebp
  800b01:	57                   	push   %edi
  800b02:	56                   	push   %esi
  800b03:	53                   	push   %ebx
  800b04:	83 ec 1c             	sub    $0x1c,%esp
  800b07:	8b 74 24 3c          	mov    0x3c(%esp),%esi
  800b0b:	8b 5c 24 30          	mov    0x30(%esp),%ebx
  800b0f:	8b 4c 24 34          	mov    0x34(%esp),%ecx
  800b13:	8b 7c 24 38          	mov    0x38(%esp),%edi
  800b17:	85 f6                	test   %esi,%esi
  800b19:	89 5c 24 08          	mov    %ebx,0x8(%esp)
  800b1d:	89 ca                	mov    %ecx,%edx
  800b1f:	89 f8                	mov    %edi,%eax
  800b21:	75 3d                	jne    800b60 <__udivdi3+0x60>
  800b23:	39 cf                	cmp    %ecx,%edi
  800b25:	0f 87 c5 00 00 00    	ja     800bf0 <__udivdi3+0xf0>
  800b2b:	85 ff                	test   %edi,%edi
  800b2d:	89 fd                	mov    %edi,%ebp
  800b2f:	75 0b                	jne    800b3c <__udivdi3+0x3c>
  800b31:	b8 01 00 00 00       	mov    $0x1,%eax
  800b36:	31 d2                	xor    %edx,%edx
  800b38:	f7 f7                	div    %edi
  800b3a:	89 c5                	mov    %eax,%ebp
  800b3c:	89 c8                	mov    %ecx,%eax
  800b3e:	31 d2                	xor    %edx,%edx
  800b40:	f7 f5                	div    %ebp
  800b42:	89 c1                	mov    %eax,%ecx
  800b44:	89 d8                	mov    %ebx,%eax
  800b46:	89 cf                	mov    %ecx,%edi
  800b48:	f7 f5                	div    %ebp
  800b4a:	89 c3                	mov    %eax,%ebx
  800b4c:	89 d8                	mov    %ebx,%eax
  800b4e:	89 fa                	mov    %edi,%edx
  800b50:	83 c4 1c             	add    $0x1c,%esp
  800b53:	5b                   	pop    %ebx
  800b54:	5e                   	pop    %esi
  800b55:	5f                   	pop    %edi
  800b56:	5d                   	pop    %ebp
  800b57:	c3                   	ret    
  800b58:	90                   	nop
  800b59:	8d b4 26 00 00 00 00 	lea    0x0(%esi,%eiz,1),%esi
  800b60:	39 ce                	cmp    %ecx,%esi
  800b62:	77 74                	ja     800bd8 <__udivdi3+0xd8>
  800b64:	0f bd fe             	bsr    %esi,%edi
  800b67:	83 f7 1f             	xor    $0x1f,%edi
  800b6a:	0f 84 98 00 00 00    	je     800c08 <__udivdi3+0x108>
  800b70:	bb 20 00 00 00       	mov    $0x20,%ebx
  800b75:	89 f9                	mov    %edi,%ecx
  800b77:	89 c5                	mov    %eax,%ebp
  800b79:	29 fb                	sub    %edi,%ebx
  800b7b:	d3 e6                	shl    %cl,%esi
  800b7d:	89 d9                	mov    %ebx,%ecx
  800b7f:	d3 ed                	shr    %cl,%ebp
  800b81:	89 f9                	mov    %edi,%ecx
  800b83:	d3 e0                	shl    %cl,%eax
  800b85:	09 ee                	or     %ebp,%esi
  800b87:	89 d9                	mov    %ebx,%ecx
  800b89:	89 44 24 0c          	mov    %eax,0xc(%esp)
  800b8d:	89 d5                	mov    %edx,%ebp
  800b8f:	8b 44 24 08          	mov    0x8(%esp),%eax
  800b93:	d3 ed                	shr    %cl,%ebp
  800b95:	89 f9                	mov    %edi,%ecx
  800b97:	d3 e2                	shl    %cl,%edx
  800b99:	89 d9                	mov    %ebx,%ecx
  800b9b:	d3 e8                	shr    %cl,%eax
  800b9d:	09 c2                	or     %eax,%edx
  800b9f:	89 d0                	mov    %edx,%eax
  800ba1:	89 ea                	mov    %ebp,%edx
  800ba3:	f7 f6                	div    %esi
  800ba5:	89 d5                	mov    %edx,%ebp
  800ba7:	89 c3                	mov    %eax,%ebx
  800ba9:	f7 64 24 0c          	mull   0xc(%esp)
  800bad:	39 d5                	cmp    %edx,%ebp
  800baf:	72 10                	jb     800bc1 <__udivdi3+0xc1>
  800bb1:	8b 74 24 08          	mov    0x8(%esp),%esi
  800bb5:	89 f9                	mov    %edi,%ecx
  800bb7:	d3 e6                	shl    %cl,%esi
  800bb9:	39 c6                	cmp    %eax,%esi
  800bbb:	73 07                	jae    800bc4 <__udivdi3+0xc4>
  800bbd:	39 d5                	cmp    %edx,%ebp
  800bbf:	75 03                	jne    800bc4 <__udivdi3+0xc4>
  800bc1:	83 eb 01             	sub    $0x1,%ebx
  800bc4:	31 ff                	xor    %edi,%edi
  800bc6:	89 d8                	mov    %ebx,%eax
  800bc8:	89 fa                	mov    %edi,%edx
  800bca:	83 c4 1c             	add    $0x1c,%esp
  800bcd:	5b                   	pop    %ebx
  800bce:	5e                   	pop    %esi
  800bcf:	5f                   	pop    %edi
  800bd0:	5d                   	pop    %ebp
  800bd1:	c3                   	ret    
  800bd2:	8d b6 00 00 00 00    	lea    0x0(%esi),%esi
  800bd8:	31 ff                	xor    %edi,%edi
  800bda:	31 db                	xor    %ebx,%ebx
  800bdc:	89 d8                	mov    %ebx,%eax
  800bde:	89 fa                	mov    %edi,%edx
  800be0:	83 c4 1c             	add    $0x1c,%esp
  800be3:	5b                   	pop    %ebx
  800be4:	5e                   	pop    %esi
  800be5:	5f                   	pop    %edi
  800be6:	5d                   	pop    %ebp
  800be7:	c3                   	ret    
  800be8:	90                   	nop
  800be9:	8d b4 26 00 00 00 00 	lea    0x0(%esi,%eiz,1),%esi
  800bf0:	89 d8                	mov    %ebx,%eax
  800bf2:	f7 f7                	div    %edi
  800bf4:	31 ff                	xor    %edi,%edi
  800bf6:	89 c3                	mov    %eax,%ebx
  800bf8:	89 d8                	mov    %ebx,%eax
  800bfa:	89 fa                	mov    %edi,%edx
  800bfc:	83 c4 1c             	add    $0x1c,%esp
  800bff:	5b                   	pop    %ebx
  800c00:	5e                   	pop    %esi
  800c01:	5f                   	pop    %edi
  800c02:	5d                   	pop    %ebp
  800c03:	c3                   	ret    
  800c04:	8d 74 26 00          	lea    0x0(%esi,%eiz,1),%esi
  800c08:	39 ce                	cmp    %ecx,%esi
  800c0a:	72 0c                	jb     800c18 <__udivdi3+0x118>
  800c0c:	31 db                	xor    %ebx,%ebx
  800c0e:	3b 44 24 08          	cmp    0x8(%esp),%eax
  800c12:	0f 87 34 ff ff ff    	ja     800b4c <__udivdi3+0x4c>
  800c18:	bb 01 00 00 00       	mov    $0x1,%ebx
  800c1d:	e9 2a ff ff ff       	jmp    800b4c <__udivdi3+0x4c>
  800c22:	66 90                	xchg   %ax,%ax
  800c24:	66 90                	xchg   %ax,%ax
  800c26:	66 90                	xchg   %ax,%ax
  800c28:	66 90                	xchg   %ax,%ax
  800c2a:	66 90                	xchg   %ax,%ax
  800c2c:	66 90                	xchg   %ax,%ax
  800c2e:	66 90                	xchg   %ax,%ax

00800c30 <__umoddi3>:
  800c30:	55                   	push   %ebp
  800c31:	57                   	push   %edi
  800c32:	56                   	push   %esi
  800c33:	53                   	push   %ebx
  800c34:	83 ec 1c             	sub    $0x1c,%esp
  800c37:	8b 54 24 3c          	mov    0x3c(%esp),%edx
  800c3b:	8b 4c 24 30          	mov    0x30(%esp),%ecx
  800c3f:	8b 74 24 34          	mov    0x34(%esp),%esi
  800c43:	8b 7c 24 38          	mov    0x38(%esp),%edi
  800c47:	85 d2                	test   %edx,%edx
  800c49:	89 4c 24 0c          	mov    %ecx,0xc(%esp)
  800c4d:	89 4c 24 08          	mov    %ecx,0x8(%esp)
  800c51:	89 f3                	mov    %esi,%ebx
  800c53:	89 3c 24             	mov    %edi,(%esp)
  800c56:	89 74 24 04          	mov    %esi,0x4(%esp)
  800c5a:	75 1c                	jne    800c78 <__umoddi3+0x48>
  800c5c:	39 f7                	cmp    %esi,%edi
  800c5e:	76 50                	jbe    800cb0 <__umoddi3+0x80>
  800c60:	89 c8                	mov    %ecx,%eax
  800c62:	89 f2                	mov    %esi,%edx
  800c64:	f7 f7                	div    %edi
  800c66:	89 d0                	mov    %edx,%eax
  800c68:	31 d2                	xor    %edx,%edx
  800c6a:	83 c4 1c             	add    $0x1c,%esp
  800c6d:	5b                   	pop    %ebx
  800c6e:	5e                   	pop    %esi
  800c6f:	5f                   	pop    %edi
  800c70:	5d                   	pop    %ebp
  800c71:	c3                   	ret    
  800c72:	8d b6 00 00 00 00    	lea    0x0(%esi),%esi
  800c78:	39 f2                	cmp    %esi,%edx
  800c7a:	89 d0                	mov    %edx,%eax
  800c7c:	77 52                	ja     800cd0 <__umoddi3+0xa0>
  800c7e:	0f bd ea             	bsr    %edx,%ebp
  800c81:	83 f5 1f             	xor    $0x1f,%ebp
  800c84:	75 5a                	jne    800ce0 <__umoddi3+0xb0>
  800c86:	3b 54 24 04          	cmp    0x4(%esp),%edx
  800c8a:	0f 82 e0 00 00 00    	jb     800d70 <__umoddi3+0x140>
  800c90:	39 0c 24             	cmp    %ecx,(%esp)
  800c93:	0f 86 d7 00 00 00    	jbe    800d70 <__umoddi3+0x140>
  800c99:	8b 44 24 08          	mov    0x8(%esp),%eax
  800c9d:	8b 54 24 04          	mov    0x4(%esp),%edx
  800ca1:	83 c4 1c             	add    $0x1c,%esp
  800ca4:	5b                   	pop    %ebx
  800ca5:	5e                   	pop    %esi
  800ca6:	5f                   	pop    %edi
  800ca7:	5d                   	pop    %ebp
  800ca8:	c3                   	ret    
  800ca9:	8d b4 26 00 00 00 00 	lea    0x0(%esi,%eiz,1),%esi
  800cb0:	85 ff                	test   %edi,%edi
  800cb2:	89 fd                	mov    %edi,%ebp
  800cb4:	75 0b                	jne    800cc1 <__umoddi3+0x91>
  800cb6:	b8 01 00 00 00       	mov    $0x1,%eax
  800cbb:	31 d2                	xor    %edx,%edx
  800cbd:	f7 f7                	div    %edi
  800cbf:	89 c5                	mov    %eax,%ebp
  800cc1:	89 f0                	mov    %esi,%eax
  800cc3:	31 d2                	xor    %edx,%edx
  800cc5:	f7 f5                	div    %ebp
  800cc7:	89 c8                	mov    %ecx,%eax
  800cc9:	f7 f5                	div    %ebp
  800ccb:	89 d0                	mov    %edx,%eax
  800ccd:	eb 99                	jmp    800c68 <__umoddi3+0x38>
  800ccf:	90                   	nop
  800cd0:	89 c8                	mov    %ecx,%eax
  800cd2:	89 f2                	mov    %esi,%edx
  800cd4:	83 c4 1c             	add    $0x1c,%esp
  800cd7:	5b                   	pop    %ebx
  800cd8:	5e                   	pop    %esi
  800cd9:	5f                   	pop    %edi
  800cda:	5d                   	pop    %ebp
  800cdb:	c3                   	ret    
  800cdc:	8d 74 26 00          	lea    0x0(%esi,%eiz,1),%esi
  800ce0:	8b 34 24             	mov    (%esp),%esi
  800ce3:	bf 20 00 00 00       	mov    $0x20,%edi
  800ce8:	89 e9                	mov    %ebp,%ecx
  800cea:	29 ef                	sub    %ebp,%edi
  800cec:	d3 e0                	shl    %cl,%eax
  800cee:	89 f9                	mov    %edi,%ecx
  800cf0:	89 f2                	mov    %esi,%edx
  800cf2:	d3 ea                	shr    %cl,%edx
  800cf4:	89 e9                	mov    %ebp,%ecx
  800cf6:	09 c2                	or     %eax,%edx
  800cf8:	89 d8                	mov    %ebx,%eax
  800cfa:	89 14 24             	mov    %edx,(%esp)
  800cfd:	89 f2                	mov    %esi,%edx
  800cff:	d3 e2                	shl    %cl,%edx
  800d01:	89 f9                	mov    %edi,%ecx
  800d03:	89 54 24 04          	mov    %edx,0x4(%esp)
  800d07:	8b 54 24 0c          	mov    0xc(%esp),%edx
  800d0b:	d3 e8                	shr    %cl,%eax
  800d0d:	89 e9                	mov    %ebp,%ecx
  800d0f:	89 c6                	mov    %eax,%esi
  800d11:	d3 e3                	shl    %cl,%ebx
  800d13:	89 f9                	mov    %edi,%ecx
  800d15:	89 d0                	mov    %edx,%eax
  800d17:	d3 e8                	shr    %cl,%eax
  800d19:	89 e9                	mov    %ebp,%ecx
  800d1b:	09 d8                	or     %ebx,%eax
  800d1d:	89 d3                	mov    %edx,%ebx
  800d1f:	89 f2                	mov    %esi,%edx
  800d21:	f7 34 24             	divl   (%esp)
  800d24:	89 d6                	mov    %edx,%esi
  800d26:	d3 e3                	shl    %cl,%ebx
  800d28:	f7 64 24 04          	mull   0x4(%esp)
  800d2c:	39 d6                	cmp    %edx,%esi
  800d2e:	89 5c 24 08          	mov    %ebx,0x8(%esp)
  800d32:	89 d1                	mov    %edx,%ecx
  800d34:	89 c3                	mov    %eax,%ebx
  800d36:	72 08                	jb     800d40 <__umoddi3+0x110>
  800d38:	75 11                	jne    800d4b <__umoddi3+0x11b>
  800d3a:	39 44 24 08          	cmp    %eax,0x8(%esp)
  800d3e:	73 0b                	jae    800d4b <__umoddi3+0x11b>
  800d40:	2b 44 24 04          	sub    0x4(%esp),%eax
  800d44:	1b 14 24             	sbb    (%esp),%edx
  800d47:	89 d1                	mov    %edx,%ecx
  800d49:	89 c3                	mov    %eax,%ebx
  800d4b:	8b 54 24 08          	mov    0x8(%esp),%edx
  800d4f:	29 da                	sub    %ebx,%edx
  800d51:	19 ce                	sbb    %ecx,%esi
  800d53:	89 f9                	mov    %edi,%ecx
  800d55:	89 f0                	mov    %esi,%eax
  800d57:	d3 e0                	shl    %cl,%eax
  800d59:	89 e9                	mov    %ebp,%ecx
  800d5b:	d3 ea                	shr    %cl,%edx
  800d5d:	89 e9                	mov    %ebp,%ecx
  800d5f:	d3 ee                	shr    %cl,%esi
  800d61:	09 d0                	or     %edx,%eax
  800d63:	89 f2                	mov    %esi,%edx
  800d65:	83 c4 1c             	add    $0x1c,%esp
  800d68:	5b                   	pop    %ebx
  800d69:	5e                   	pop    %esi
  800d6a:	5f                   	pop    %edi
  800d6b:	5d                   	pop    %ebp
  800d6c:	c3                   	ret    
  800d6d:	8d 76 00             	lea    0x0(%esi),%esi
  800d70:	29 f9                	sub    %edi,%ecx
  800d72:	19 d6                	sbb    %edx,%esi
  800d74:	89 74 24 04          	mov    %esi,0x4(%esp)
  800d78:	89 4c 24 08          	mov    %ecx,0x8(%esp)
  800d7c:	e9 18 ff ff ff       	jmp    800c99 <__umoddi3+0x69>
