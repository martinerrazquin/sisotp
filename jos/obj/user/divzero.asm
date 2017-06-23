
obj/user/divzero:     file format elf32-i386


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
  80002c:	e8 2f 00 00 00       	call   800060 <libmain>
1:	jmp 1b
  800031:	eb fe                	jmp    800031 <args_exist+0x5>

00800033 <umain>:

int zero;

void
umain(int argc, char **argv)
{
  800033:	55                   	push   %ebp
  800034:	89 e5                	mov    %esp,%ebp
  800036:	83 ec 10             	sub    $0x10,%esp
	zero = 0;
  800039:	c7 05 04 20 80 00 00 	movl   $0x0,0x802004
  800040:	00 00 00 
	cprintf("1/0 is %08x!\n", 1/zero);
  800043:	b8 01 00 00 00       	mov    $0x1,%eax
  800048:	b9 00 00 00 00       	mov    $0x0,%ecx
  80004d:	99                   	cltd   
  80004e:	f7 f9                	idiv   %ecx
  800050:	50                   	push   %eax
  800051:	68 e0 0e 80 00       	push   $0x800ee0
  800056:	e8 f4 00 00 00       	call   80014f <cprintf>
}
  80005b:	83 c4 10             	add    $0x10,%esp
  80005e:	c9                   	leave  
  80005f:	c3                   	ret    

00800060 <libmain>:
const volatile struct Env *thisenv;
const char *binaryname = "<unknown>";

void
libmain(int argc, char **argv)
{
  800060:	55                   	push   %ebp
  800061:	89 e5                	mov    %esp,%ebp
  800063:	56                   	push   %esi
  800064:	53                   	push   %ebx
  800065:	8b 5d 08             	mov    0x8(%ebp),%ebx
  800068:	8b 75 0c             	mov    0xc(%ebp),%esi
	// set thisenv to point at our Env structure in envs[].
	// LAB 3: Your code here.
	envid_t id = sys_getenvid();
  80006b:	e8 49 0a 00 00       	call   800ab9 <sys_getenvid>
	if (id >= 0)
  800070:	85 c0                	test   %eax,%eax
  800072:	78 12                	js     800086 <libmain+0x26>
		thisenv = &envs[ENVX(id)];
  800074:	25 ff 03 00 00       	and    $0x3ff,%eax
  800079:	6b c0 7c             	imul   $0x7c,%eax,%eax
  80007c:	05 00 00 c0 ee       	add    $0xeec00000,%eax
  800081:	a3 08 20 80 00       	mov    %eax,0x802008

	// save the name of the program so that panic() can use it
	if (argc > 0)
  800086:	85 db                	test   %ebx,%ebx
  800088:	7e 07                	jle    800091 <libmain+0x31>
		binaryname = argv[0];
  80008a:	8b 06                	mov    (%esi),%eax
  80008c:	a3 00 20 80 00       	mov    %eax,0x802000

	// call user main routine
	umain(argc, argv);
  800091:	83 ec 08             	sub    $0x8,%esp
  800094:	56                   	push   %esi
  800095:	53                   	push   %ebx
  800096:	e8 98 ff ff ff       	call   800033 <umain>

	// exit gracefully
	exit();
  80009b:	e8 0a 00 00 00       	call   8000aa <exit>
}
  8000a0:	83 c4 10             	add    $0x10,%esp
  8000a3:	8d 65 f8             	lea    -0x8(%ebp),%esp
  8000a6:	5b                   	pop    %ebx
  8000a7:	5e                   	pop    %esi
  8000a8:	5d                   	pop    %ebp
  8000a9:	c3                   	ret    

008000aa <exit>:

#include <inc/lib.h>

void
exit(void)
{
  8000aa:	55                   	push   %ebp
  8000ab:	89 e5                	mov    %esp,%ebp
  8000ad:	83 ec 14             	sub    $0x14,%esp
	sys_env_destroy(0);
  8000b0:	6a 00                	push   $0x0
  8000b2:	e8 e0 09 00 00       	call   800a97 <sys_env_destroy>
}
  8000b7:	83 c4 10             	add    $0x10,%esp
  8000ba:	c9                   	leave  
  8000bb:	c3                   	ret    

008000bc <putch>:
};


static void
putch(int ch, struct printbuf *b)
{
  8000bc:	55                   	push   %ebp
  8000bd:	89 e5                	mov    %esp,%ebp
  8000bf:	53                   	push   %ebx
  8000c0:	83 ec 04             	sub    $0x4,%esp
  8000c3:	8b 5d 0c             	mov    0xc(%ebp),%ebx
	b->buf[b->idx++] = ch;
  8000c6:	8b 13                	mov    (%ebx),%edx
  8000c8:	8d 42 01             	lea    0x1(%edx),%eax
  8000cb:	89 03                	mov    %eax,(%ebx)
  8000cd:	8b 4d 08             	mov    0x8(%ebp),%ecx
  8000d0:	88 4c 13 08          	mov    %cl,0x8(%ebx,%edx,1)
	if (b->idx == 256-1) {
  8000d4:	3d ff 00 00 00       	cmp    $0xff,%eax
  8000d9:	75 1a                	jne    8000f5 <putch+0x39>
		sys_cputs(b->buf, b->idx);
  8000db:	83 ec 08             	sub    $0x8,%esp
  8000de:	68 ff 00 00 00       	push   $0xff
  8000e3:	8d 43 08             	lea    0x8(%ebx),%eax
  8000e6:	50                   	push   %eax
  8000e7:	e8 61 09 00 00       	call   800a4d <sys_cputs>
		b->idx = 0;
  8000ec:	c7 03 00 00 00 00    	movl   $0x0,(%ebx)
  8000f2:	83 c4 10             	add    $0x10,%esp
	}
	b->cnt++;
  8000f5:	83 43 04 01          	addl   $0x1,0x4(%ebx)
}
  8000f9:	8b 5d fc             	mov    -0x4(%ebp),%ebx
  8000fc:	c9                   	leave  
  8000fd:	c3                   	ret    

008000fe <vcprintf>:

int
vcprintf(const char *fmt, va_list ap)
{
  8000fe:	55                   	push   %ebp
  8000ff:	89 e5                	mov    %esp,%ebp
  800101:	81 ec 18 01 00 00    	sub    $0x118,%esp
	struct printbuf b;

	b.idx = 0;
  800107:	c7 85 f0 fe ff ff 00 	movl   $0x0,-0x110(%ebp)
  80010e:	00 00 00 
	b.cnt = 0;
  800111:	c7 85 f4 fe ff ff 00 	movl   $0x0,-0x10c(%ebp)
  800118:	00 00 00 
	vprintfmt((void*)putch, &b, fmt, ap);
  80011b:	ff 75 0c             	pushl  0xc(%ebp)
  80011e:	ff 75 08             	pushl  0x8(%ebp)
  800121:	8d 85 f0 fe ff ff    	lea    -0x110(%ebp),%eax
  800127:	50                   	push   %eax
  800128:	68 bc 00 80 00       	push   $0x8000bc
  80012d:	e8 86 01 00 00       	call   8002b8 <vprintfmt>
	sys_cputs(b.buf, b.idx);
  800132:	83 c4 08             	add    $0x8,%esp
  800135:	ff b5 f0 fe ff ff    	pushl  -0x110(%ebp)
  80013b:	8d 85 f8 fe ff ff    	lea    -0x108(%ebp),%eax
  800141:	50                   	push   %eax
  800142:	e8 06 09 00 00       	call   800a4d <sys_cputs>

	return b.cnt;
}
  800147:	8b 85 f4 fe ff ff    	mov    -0x10c(%ebp),%eax
  80014d:	c9                   	leave  
  80014e:	c3                   	ret    

0080014f <cprintf>:

int
cprintf(const char *fmt, ...)
{
  80014f:	55                   	push   %ebp
  800150:	89 e5                	mov    %esp,%ebp
  800152:	83 ec 10             	sub    $0x10,%esp
	va_list ap;
	int cnt;

	va_start(ap, fmt);
  800155:	8d 45 0c             	lea    0xc(%ebp),%eax
	cnt = vcprintf(fmt, ap);
  800158:	50                   	push   %eax
  800159:	ff 75 08             	pushl  0x8(%ebp)
  80015c:	e8 9d ff ff ff       	call   8000fe <vcprintf>
	va_end(ap);

	return cnt;
}
  800161:	c9                   	leave  
  800162:	c3                   	ret    

00800163 <printnum>:
 * using specified putch function and associated pointer putdat.
 */
static void
printnum(void (*putch)(int, void*), void *putdat,
	 unsigned long long num, unsigned base, int width, int padc)
{
  800163:	55                   	push   %ebp
  800164:	89 e5                	mov    %esp,%ebp
  800166:	57                   	push   %edi
  800167:	56                   	push   %esi
  800168:	53                   	push   %ebx
  800169:	83 ec 1c             	sub    $0x1c,%esp
  80016c:	89 c7                	mov    %eax,%edi
  80016e:	89 d6                	mov    %edx,%esi
  800170:	8b 45 08             	mov    0x8(%ebp),%eax
  800173:	8b 55 0c             	mov    0xc(%ebp),%edx
  800176:	89 45 d8             	mov    %eax,-0x28(%ebp)
  800179:	89 55 dc             	mov    %edx,-0x24(%ebp)
	// first recursively print all preceding (more significant) digits
	if (num >= base) {
  80017c:	8b 4d 10             	mov    0x10(%ebp),%ecx
  80017f:	bb 00 00 00 00       	mov    $0x0,%ebx
  800184:	89 4d e0             	mov    %ecx,-0x20(%ebp)
  800187:	89 5d e4             	mov    %ebx,-0x1c(%ebp)
  80018a:	39 d3                	cmp    %edx,%ebx
  80018c:	72 05                	jb     800193 <printnum+0x30>
  80018e:	39 45 10             	cmp    %eax,0x10(%ebp)
  800191:	77 45                	ja     8001d8 <printnum+0x75>
		printnum(putch, putdat, num / base, base, width - 1, padc);
  800193:	83 ec 0c             	sub    $0xc,%esp
  800196:	ff 75 18             	pushl  0x18(%ebp)
  800199:	8b 45 14             	mov    0x14(%ebp),%eax
  80019c:	8d 58 ff             	lea    -0x1(%eax),%ebx
  80019f:	53                   	push   %ebx
  8001a0:	ff 75 10             	pushl  0x10(%ebp)
  8001a3:	83 ec 08             	sub    $0x8,%esp
  8001a6:	ff 75 e4             	pushl  -0x1c(%ebp)
  8001a9:	ff 75 e0             	pushl  -0x20(%ebp)
  8001ac:	ff 75 dc             	pushl  -0x24(%ebp)
  8001af:	ff 75 d8             	pushl  -0x28(%ebp)
  8001b2:	e8 99 0a 00 00       	call   800c50 <__udivdi3>
  8001b7:	83 c4 18             	add    $0x18,%esp
  8001ba:	52                   	push   %edx
  8001bb:	50                   	push   %eax
  8001bc:	89 f2                	mov    %esi,%edx
  8001be:	89 f8                	mov    %edi,%eax
  8001c0:	e8 9e ff ff ff       	call   800163 <printnum>
  8001c5:	83 c4 20             	add    $0x20,%esp
  8001c8:	eb 18                	jmp    8001e2 <printnum+0x7f>
	} else {
		// print any needed pad characters before first digit
		while (--width > 0)
			putch(padc, putdat);
  8001ca:	83 ec 08             	sub    $0x8,%esp
  8001cd:	56                   	push   %esi
  8001ce:	ff 75 18             	pushl  0x18(%ebp)
  8001d1:	ff d7                	call   *%edi
  8001d3:	83 c4 10             	add    $0x10,%esp
  8001d6:	eb 03                	jmp    8001db <printnum+0x78>
  8001d8:	8b 5d 14             	mov    0x14(%ebp),%ebx
	// first recursively print all preceding (more significant) digits
	if (num >= base) {
		printnum(putch, putdat, num / base, base, width - 1, padc);
	} else {
		// print any needed pad characters before first digit
		while (--width > 0)
  8001db:	83 eb 01             	sub    $0x1,%ebx
  8001de:	85 db                	test   %ebx,%ebx
  8001e0:	7f e8                	jg     8001ca <printnum+0x67>
			putch(padc, putdat);
	}

	// then print this (the least significant) digit
	putch("0123456789abcdef"[num % base], putdat);
  8001e2:	83 ec 08             	sub    $0x8,%esp
  8001e5:	56                   	push   %esi
  8001e6:	83 ec 04             	sub    $0x4,%esp
  8001e9:	ff 75 e4             	pushl  -0x1c(%ebp)
  8001ec:	ff 75 e0             	pushl  -0x20(%ebp)
  8001ef:	ff 75 dc             	pushl  -0x24(%ebp)
  8001f2:	ff 75 d8             	pushl  -0x28(%ebp)
  8001f5:	e8 86 0b 00 00       	call   800d80 <__umoddi3>
  8001fa:	83 c4 14             	add    $0x14,%esp
  8001fd:	0f be 80 f8 0e 80 00 	movsbl 0x800ef8(%eax),%eax
  800204:	50                   	push   %eax
  800205:	ff d7                	call   *%edi
}
  800207:	83 c4 10             	add    $0x10,%esp
  80020a:	8d 65 f4             	lea    -0xc(%ebp),%esp
  80020d:	5b                   	pop    %ebx
  80020e:	5e                   	pop    %esi
  80020f:	5f                   	pop    %edi
  800210:	5d                   	pop    %ebp
  800211:	c3                   	ret    

00800212 <getuint>:

// Get an unsigned int of various possible sizes from a varargs list,
// depending on the lflag parameter.
static unsigned long long
getuint(va_list *ap, int lflag)
{
  800212:	55                   	push   %ebp
  800213:	89 e5                	mov    %esp,%ebp
	if (lflag >= 2)
  800215:	83 fa 01             	cmp    $0x1,%edx
  800218:	7e 0e                	jle    800228 <getuint+0x16>
		return va_arg(*ap, unsigned long long);
  80021a:	8b 10                	mov    (%eax),%edx
  80021c:	8d 4a 08             	lea    0x8(%edx),%ecx
  80021f:	89 08                	mov    %ecx,(%eax)
  800221:	8b 02                	mov    (%edx),%eax
  800223:	8b 52 04             	mov    0x4(%edx),%edx
  800226:	eb 22                	jmp    80024a <getuint+0x38>
	else if (lflag)
  800228:	85 d2                	test   %edx,%edx
  80022a:	74 10                	je     80023c <getuint+0x2a>
		return va_arg(*ap, unsigned long);
  80022c:	8b 10                	mov    (%eax),%edx
  80022e:	8d 4a 04             	lea    0x4(%edx),%ecx
  800231:	89 08                	mov    %ecx,(%eax)
  800233:	8b 02                	mov    (%edx),%eax
  800235:	ba 00 00 00 00       	mov    $0x0,%edx
  80023a:	eb 0e                	jmp    80024a <getuint+0x38>
	else
		return va_arg(*ap, unsigned int);
  80023c:	8b 10                	mov    (%eax),%edx
  80023e:	8d 4a 04             	lea    0x4(%edx),%ecx
  800241:	89 08                	mov    %ecx,(%eax)
  800243:	8b 02                	mov    (%edx),%eax
  800245:	ba 00 00 00 00       	mov    $0x0,%edx
}
  80024a:	5d                   	pop    %ebp
  80024b:	c3                   	ret    

0080024c <getint>:

// Same as getuint but signed - can't use getuint
// because of sign extension
static long long
getint(va_list *ap, int lflag)
{
  80024c:	55                   	push   %ebp
  80024d:	89 e5                	mov    %esp,%ebp
	if (lflag >= 2)
  80024f:	83 fa 01             	cmp    $0x1,%edx
  800252:	7e 0e                	jle    800262 <getint+0x16>
		return va_arg(*ap, long long);
  800254:	8b 10                	mov    (%eax),%edx
  800256:	8d 4a 08             	lea    0x8(%edx),%ecx
  800259:	89 08                	mov    %ecx,(%eax)
  80025b:	8b 02                	mov    (%edx),%eax
  80025d:	8b 52 04             	mov    0x4(%edx),%edx
  800260:	eb 1a                	jmp    80027c <getint+0x30>
	else if (lflag)
  800262:	85 d2                	test   %edx,%edx
  800264:	74 0c                	je     800272 <getint+0x26>
		return va_arg(*ap, long);
  800266:	8b 10                	mov    (%eax),%edx
  800268:	8d 4a 04             	lea    0x4(%edx),%ecx
  80026b:	89 08                	mov    %ecx,(%eax)
  80026d:	8b 02                	mov    (%edx),%eax
  80026f:	99                   	cltd   
  800270:	eb 0a                	jmp    80027c <getint+0x30>
	else
		return va_arg(*ap, int);
  800272:	8b 10                	mov    (%eax),%edx
  800274:	8d 4a 04             	lea    0x4(%edx),%ecx
  800277:	89 08                	mov    %ecx,(%eax)
  800279:	8b 02                	mov    (%edx),%eax
  80027b:	99                   	cltd   
}
  80027c:	5d                   	pop    %ebp
  80027d:	c3                   	ret    

0080027e <sprintputch>:
	int cnt;
};

static void
sprintputch(int ch, struct sprintbuf *b)
{
  80027e:	55                   	push   %ebp
  80027f:	89 e5                	mov    %esp,%ebp
  800281:	8b 45 0c             	mov    0xc(%ebp),%eax
	b->cnt++;
  800284:	83 40 08 01          	addl   $0x1,0x8(%eax)
	if (b->buf < b->ebuf)
  800288:	8b 10                	mov    (%eax),%edx
  80028a:	3b 50 04             	cmp    0x4(%eax),%edx
  80028d:	73 0a                	jae    800299 <sprintputch+0x1b>
		*b->buf++ = ch;
  80028f:	8d 4a 01             	lea    0x1(%edx),%ecx
  800292:	89 08                	mov    %ecx,(%eax)
  800294:	8b 45 08             	mov    0x8(%ebp),%eax
  800297:	88 02                	mov    %al,(%edx)
}
  800299:	5d                   	pop    %ebp
  80029a:	c3                   	ret    

0080029b <printfmt>:
	}
}

void
printfmt(void (*putch)(int, void*), void *putdat, const char *fmt, ...)
{
  80029b:	55                   	push   %ebp
  80029c:	89 e5                	mov    %esp,%ebp
  80029e:	83 ec 08             	sub    $0x8,%esp
	va_list ap;

	va_start(ap, fmt);
  8002a1:	8d 45 14             	lea    0x14(%ebp),%eax
	vprintfmt(putch, putdat, fmt, ap);
  8002a4:	50                   	push   %eax
  8002a5:	ff 75 10             	pushl  0x10(%ebp)
  8002a8:	ff 75 0c             	pushl  0xc(%ebp)
  8002ab:	ff 75 08             	pushl  0x8(%ebp)
  8002ae:	e8 05 00 00 00       	call   8002b8 <vprintfmt>
	va_end(ap);
}
  8002b3:	83 c4 10             	add    $0x10,%esp
  8002b6:	c9                   	leave  
  8002b7:	c3                   	ret    

008002b8 <vprintfmt>:
// Main function to format and print a string.
void printfmt(void (*putch)(int, void*), void *putdat, const char *fmt, ...);

void
vprintfmt(void (*putch)(int, void*), void *putdat, const char *fmt, va_list ap)
{
  8002b8:	55                   	push   %ebp
  8002b9:	89 e5                	mov    %esp,%ebp
  8002bb:	57                   	push   %edi
  8002bc:	56                   	push   %esi
  8002bd:	53                   	push   %ebx
  8002be:	83 ec 2c             	sub    $0x2c,%esp
  8002c1:	8b 75 08             	mov    0x8(%ebp),%esi
  8002c4:	8b 5d 0c             	mov    0xc(%ebp),%ebx
  8002c7:	8b 7d 10             	mov    0x10(%ebp),%edi
  8002ca:	eb 12                	jmp    8002de <vprintfmt+0x26>
	int base, lflag, width, precision, altflag;
	char padc;

	while (1) {
		while ((ch = *(unsigned char *) fmt++) != '%') {
			if (ch == '\0')
  8002cc:	85 c0                	test   %eax,%eax
  8002ce:	0f 84 44 03 00 00    	je     800618 <vprintfmt+0x360>
				return;
			putch(ch, putdat);
  8002d4:	83 ec 08             	sub    $0x8,%esp
  8002d7:	53                   	push   %ebx
  8002d8:	50                   	push   %eax
  8002d9:	ff d6                	call   *%esi
  8002db:	83 c4 10             	add    $0x10,%esp
	unsigned long long num;
	int base, lflag, width, precision, altflag;
	char padc;

	while (1) {
		while ((ch = *(unsigned char *) fmt++) != '%') {
  8002de:	83 c7 01             	add    $0x1,%edi
  8002e1:	0f b6 47 ff          	movzbl -0x1(%edi),%eax
  8002e5:	83 f8 25             	cmp    $0x25,%eax
  8002e8:	75 e2                	jne    8002cc <vprintfmt+0x14>
  8002ea:	c6 45 d4 20          	movb   $0x20,-0x2c(%ebp)
  8002ee:	c7 45 d8 00 00 00 00 	movl   $0x0,-0x28(%ebp)
  8002f5:	c7 45 d0 ff ff ff ff 	movl   $0xffffffff,-0x30(%ebp)
  8002fc:	c7 45 e0 ff ff ff ff 	movl   $0xffffffff,-0x20(%ebp)
  800303:	ba 00 00 00 00       	mov    $0x0,%edx
  800308:	eb 07                	jmp    800311 <vprintfmt+0x59>
		width = -1;
		precision = -1;
		lflag = 0;
		altflag = 0;
	reswitch:
		switch (ch = *(unsigned char *) fmt++) {
  80030a:	8b 7d e4             	mov    -0x1c(%ebp),%edi

		// flag to pad on the right
		case '-':
			padc = '-';
  80030d:	c6 45 d4 2d          	movb   $0x2d,-0x2c(%ebp)
		width = -1;
		precision = -1;
		lflag = 0;
		altflag = 0;
	reswitch:
		switch (ch = *(unsigned char *) fmt++) {
  800311:	8d 47 01             	lea    0x1(%edi),%eax
  800314:	89 45 e4             	mov    %eax,-0x1c(%ebp)
  800317:	0f b6 07             	movzbl (%edi),%eax
  80031a:	0f b6 c8             	movzbl %al,%ecx
  80031d:	83 e8 23             	sub    $0x23,%eax
  800320:	3c 55                	cmp    $0x55,%al
  800322:	0f 87 d5 02 00 00    	ja     8005fd <vprintfmt+0x345>
  800328:	0f b6 c0             	movzbl %al,%eax
  80032b:	ff 24 85 c0 0f 80 00 	jmp    *0x800fc0(,%eax,4)
  800332:	8b 7d e4             	mov    -0x1c(%ebp),%edi
			padc = '-';
			goto reswitch;

		// flag to pad with 0's instead of spaces
		case '0':
			padc = '0';
  800335:	c6 45 d4 30          	movb   $0x30,-0x2c(%ebp)
  800339:	eb d6                	jmp    800311 <vprintfmt+0x59>
		width = -1;
		precision = -1;
		lflag = 0;
		altflag = 0;
	reswitch:
		switch (ch = *(unsigned char *) fmt++) {
  80033b:	8b 7d e4             	mov    -0x1c(%ebp),%edi
  80033e:	b8 00 00 00 00       	mov    $0x0,%eax
  800343:	89 55 e4             	mov    %edx,-0x1c(%ebp)
		case '6':
		case '7':
		case '8':
		case '9':
			for (precision = 0; ; ++fmt) {
				precision = precision * 10 + ch - '0';
  800346:	8d 04 80             	lea    (%eax,%eax,4),%eax
  800349:	8d 44 41 d0          	lea    -0x30(%ecx,%eax,2),%eax
				ch = *fmt;
  80034d:	0f be 0f             	movsbl (%edi),%ecx
				if (ch < '0' || ch > '9')
  800350:	8d 51 d0             	lea    -0x30(%ecx),%edx
  800353:	83 fa 09             	cmp    $0x9,%edx
  800356:	77 39                	ja     800391 <vprintfmt+0xd9>
		case '5':
		case '6':
		case '7':
		case '8':
		case '9':
			for (precision = 0; ; ++fmt) {
  800358:	83 c7 01             	add    $0x1,%edi
				precision = precision * 10 + ch - '0';
				ch = *fmt;
				if (ch < '0' || ch > '9')
					break;
			}
  80035b:	eb e9                	jmp    800346 <vprintfmt+0x8e>
			goto process_precision;

		case '*':
			precision = va_arg(ap, int);
  80035d:	8b 45 14             	mov    0x14(%ebp),%eax
  800360:	8d 48 04             	lea    0x4(%eax),%ecx
  800363:	89 4d 14             	mov    %ecx,0x14(%ebp)
  800366:	8b 00                	mov    (%eax),%eax
  800368:	89 45 d0             	mov    %eax,-0x30(%ebp)
		width = -1;
		precision = -1;
		lflag = 0;
		altflag = 0;
	reswitch:
		switch (ch = *(unsigned char *) fmt++) {
  80036b:	8b 7d e4             	mov    -0x1c(%ebp),%edi
			}
			goto process_precision;

		case '*':
			precision = va_arg(ap, int);
			goto process_precision;
  80036e:	eb 27                	jmp    800397 <vprintfmt+0xdf>
  800370:	8b 45 e0             	mov    -0x20(%ebp),%eax
  800373:	85 c0                	test   %eax,%eax
  800375:	b9 00 00 00 00       	mov    $0x0,%ecx
  80037a:	0f 49 c8             	cmovns %eax,%ecx
  80037d:	89 4d e0             	mov    %ecx,-0x20(%ebp)
		width = -1;
		precision = -1;
		lflag = 0;
		altflag = 0;
	reswitch:
		switch (ch = *(unsigned char *) fmt++) {
  800380:	8b 7d e4             	mov    -0x1c(%ebp),%edi
  800383:	eb 8c                	jmp    800311 <vprintfmt+0x59>
  800385:	8b 7d e4             	mov    -0x1c(%ebp),%edi
			if (width < 0)
				width = 0;
			goto reswitch;

		case '#':
			altflag = 1;
  800388:	c7 45 d8 01 00 00 00 	movl   $0x1,-0x28(%ebp)
			goto reswitch;
  80038f:	eb 80                	jmp    800311 <vprintfmt+0x59>
  800391:	8b 55 e4             	mov    -0x1c(%ebp),%edx
  800394:	89 45 d0             	mov    %eax,-0x30(%ebp)

		process_precision:
			if (width < 0)
  800397:	83 7d e0 00          	cmpl   $0x0,-0x20(%ebp)
  80039b:	0f 89 70 ff ff ff    	jns    800311 <vprintfmt+0x59>
				width = precision, precision = -1;
  8003a1:	8b 45 d0             	mov    -0x30(%ebp),%eax
  8003a4:	89 45 e0             	mov    %eax,-0x20(%ebp)
  8003a7:	c7 45 d0 ff ff ff ff 	movl   $0xffffffff,-0x30(%ebp)
  8003ae:	e9 5e ff ff ff       	jmp    800311 <vprintfmt+0x59>
			goto reswitch;

		// long flag (doubled for long long)
		case 'l':
			lflag++;
  8003b3:	83 c2 01             	add    $0x1,%edx
		width = -1;
		precision = -1;
		lflag = 0;
		altflag = 0;
	reswitch:
		switch (ch = *(unsigned char *) fmt++) {
  8003b6:	8b 7d e4             	mov    -0x1c(%ebp),%edi
			goto reswitch;

		// long flag (doubled for long long)
		case 'l':
			lflag++;
			goto reswitch;
  8003b9:	e9 53 ff ff ff       	jmp    800311 <vprintfmt+0x59>

		// character
		case 'c':
			putch(va_arg(ap, int), putdat);
  8003be:	8b 45 14             	mov    0x14(%ebp),%eax
  8003c1:	8d 50 04             	lea    0x4(%eax),%edx
  8003c4:	89 55 14             	mov    %edx,0x14(%ebp)
  8003c7:	83 ec 08             	sub    $0x8,%esp
  8003ca:	53                   	push   %ebx
  8003cb:	ff 30                	pushl  (%eax)
  8003cd:	ff d6                	call   *%esi
			break;
  8003cf:	83 c4 10             	add    $0x10,%esp
		width = -1;
		precision = -1;
		lflag = 0;
		altflag = 0;
	reswitch:
		switch (ch = *(unsigned char *) fmt++) {
  8003d2:	8b 7d e4             	mov    -0x1c(%ebp),%edi
			goto reswitch;

		// character
		case 'c':
			putch(va_arg(ap, int), putdat);
			break;
  8003d5:	e9 04 ff ff ff       	jmp    8002de <vprintfmt+0x26>

		// error message
		case 'e':
			err = va_arg(ap, int);
  8003da:	8b 45 14             	mov    0x14(%ebp),%eax
  8003dd:	8d 50 04             	lea    0x4(%eax),%edx
  8003e0:	89 55 14             	mov    %edx,0x14(%ebp)
  8003e3:	8b 00                	mov    (%eax),%eax
  8003e5:	99                   	cltd   
  8003e6:	31 d0                	xor    %edx,%eax
  8003e8:	29 d0                	sub    %edx,%eax
			if (err < 0)
				err = -err;
			if (err >= MAXERROR || (p = error_string[err]) == NULL)
  8003ea:	83 f8 08             	cmp    $0x8,%eax
  8003ed:	7f 0b                	jg     8003fa <vprintfmt+0x142>
  8003ef:	8b 14 85 20 11 80 00 	mov    0x801120(,%eax,4),%edx
  8003f6:	85 d2                	test   %edx,%edx
  8003f8:	75 18                	jne    800412 <vprintfmt+0x15a>
				printfmt(putch, putdat, "error %d", err);
  8003fa:	50                   	push   %eax
  8003fb:	68 10 0f 80 00       	push   $0x800f10
  800400:	53                   	push   %ebx
  800401:	56                   	push   %esi
  800402:	e8 94 fe ff ff       	call   80029b <printfmt>
  800407:	83 c4 10             	add    $0x10,%esp
		width = -1;
		precision = -1;
		lflag = 0;
		altflag = 0;
	reswitch:
		switch (ch = *(unsigned char *) fmt++) {
  80040a:	8b 7d e4             	mov    -0x1c(%ebp),%edi
		case 'e':
			err = va_arg(ap, int);
			if (err < 0)
				err = -err;
			if (err >= MAXERROR || (p = error_string[err]) == NULL)
				printfmt(putch, putdat, "error %d", err);
  80040d:	e9 cc fe ff ff       	jmp    8002de <vprintfmt+0x26>
			else
				printfmt(putch, putdat, "%s", p);
  800412:	52                   	push   %edx
  800413:	68 19 0f 80 00       	push   $0x800f19
  800418:	53                   	push   %ebx
  800419:	56                   	push   %esi
  80041a:	e8 7c fe ff ff       	call   80029b <printfmt>
  80041f:	83 c4 10             	add    $0x10,%esp
		width = -1;
		precision = -1;
		lflag = 0;
		altflag = 0;
	reswitch:
		switch (ch = *(unsigned char *) fmt++) {
  800422:	8b 7d e4             	mov    -0x1c(%ebp),%edi
  800425:	e9 b4 fe ff ff       	jmp    8002de <vprintfmt+0x26>
				printfmt(putch, putdat, "%s", p);
			break;

		// string
		case 's':
			if ((p = va_arg(ap, char *)) == NULL)
  80042a:	8b 45 14             	mov    0x14(%ebp),%eax
  80042d:	8d 50 04             	lea    0x4(%eax),%edx
  800430:	89 55 14             	mov    %edx,0x14(%ebp)
  800433:	8b 38                	mov    (%eax),%edi
				p = "(null)";
  800435:	85 ff                	test   %edi,%edi
  800437:	b8 09 0f 80 00       	mov    $0x800f09,%eax
  80043c:	0f 44 f8             	cmove  %eax,%edi
			if (width > 0 && padc != '-')
  80043f:	83 7d e0 00          	cmpl   $0x0,-0x20(%ebp)
  800443:	0f 8e 94 00 00 00    	jle    8004dd <vprintfmt+0x225>
  800449:	80 7d d4 2d          	cmpb   $0x2d,-0x2c(%ebp)
  80044d:	0f 84 98 00 00 00    	je     8004eb <vprintfmt+0x233>
				for (width -= strnlen(p, precision); width > 0; width--)
  800453:	83 ec 08             	sub    $0x8,%esp
  800456:	ff 75 d0             	pushl  -0x30(%ebp)
  800459:	57                   	push   %edi
  80045a:	e8 41 02 00 00       	call   8006a0 <strnlen>
  80045f:	8b 4d e0             	mov    -0x20(%ebp),%ecx
  800462:	29 c1                	sub    %eax,%ecx
  800464:	89 4d cc             	mov    %ecx,-0x34(%ebp)
  800467:	83 c4 10             	add    $0x10,%esp
					putch(padc, putdat);
  80046a:	0f be 45 d4          	movsbl -0x2c(%ebp),%eax
  80046e:	89 45 e0             	mov    %eax,-0x20(%ebp)
  800471:	89 7d d4             	mov    %edi,-0x2c(%ebp)
  800474:	89 cf                	mov    %ecx,%edi
		// string
		case 's':
			if ((p = va_arg(ap, char *)) == NULL)
				p = "(null)";
			if (width > 0 && padc != '-')
				for (width -= strnlen(p, precision); width > 0; width--)
  800476:	eb 0f                	jmp    800487 <vprintfmt+0x1cf>
					putch(padc, putdat);
  800478:	83 ec 08             	sub    $0x8,%esp
  80047b:	53                   	push   %ebx
  80047c:	ff 75 e0             	pushl  -0x20(%ebp)
  80047f:	ff d6                	call   *%esi
		// string
		case 's':
			if ((p = va_arg(ap, char *)) == NULL)
				p = "(null)";
			if (width > 0 && padc != '-')
				for (width -= strnlen(p, precision); width > 0; width--)
  800481:	83 ef 01             	sub    $0x1,%edi
  800484:	83 c4 10             	add    $0x10,%esp
  800487:	85 ff                	test   %edi,%edi
  800489:	7f ed                	jg     800478 <vprintfmt+0x1c0>
  80048b:	8b 7d d4             	mov    -0x2c(%ebp),%edi
  80048e:	8b 4d cc             	mov    -0x34(%ebp),%ecx
  800491:	85 c9                	test   %ecx,%ecx
  800493:	b8 00 00 00 00       	mov    $0x0,%eax
  800498:	0f 49 c1             	cmovns %ecx,%eax
  80049b:	29 c1                	sub    %eax,%ecx
  80049d:	89 75 08             	mov    %esi,0x8(%ebp)
  8004a0:	8b 75 d0             	mov    -0x30(%ebp),%esi
  8004a3:	89 5d 0c             	mov    %ebx,0xc(%ebp)
  8004a6:	89 cb                	mov    %ecx,%ebx
  8004a8:	eb 4d                	jmp    8004f7 <vprintfmt+0x23f>
					putch(padc, putdat);
			for (; (ch = *p++) != '\0' && (precision < 0 || --precision >= 0); width--)
				if (altflag && (ch < ' ' || ch > '~'))
  8004aa:	83 7d d8 00          	cmpl   $0x0,-0x28(%ebp)
  8004ae:	74 1b                	je     8004cb <vprintfmt+0x213>
  8004b0:	0f be c0             	movsbl %al,%eax
  8004b3:	83 e8 20             	sub    $0x20,%eax
  8004b6:	83 f8 5e             	cmp    $0x5e,%eax
  8004b9:	76 10                	jbe    8004cb <vprintfmt+0x213>
					putch('?', putdat);
  8004bb:	83 ec 08             	sub    $0x8,%esp
  8004be:	ff 75 0c             	pushl  0xc(%ebp)
  8004c1:	6a 3f                	push   $0x3f
  8004c3:	ff 55 08             	call   *0x8(%ebp)
  8004c6:	83 c4 10             	add    $0x10,%esp
  8004c9:	eb 0d                	jmp    8004d8 <vprintfmt+0x220>
				else
					putch(ch, putdat);
  8004cb:	83 ec 08             	sub    $0x8,%esp
  8004ce:	ff 75 0c             	pushl  0xc(%ebp)
  8004d1:	52                   	push   %edx
  8004d2:	ff 55 08             	call   *0x8(%ebp)
  8004d5:	83 c4 10             	add    $0x10,%esp
			if ((p = va_arg(ap, char *)) == NULL)
				p = "(null)";
			if (width > 0 && padc != '-')
				for (width -= strnlen(p, precision); width > 0; width--)
					putch(padc, putdat);
			for (; (ch = *p++) != '\0' && (precision < 0 || --precision >= 0); width--)
  8004d8:	83 eb 01             	sub    $0x1,%ebx
  8004db:	eb 1a                	jmp    8004f7 <vprintfmt+0x23f>
  8004dd:	89 75 08             	mov    %esi,0x8(%ebp)
  8004e0:	8b 75 d0             	mov    -0x30(%ebp),%esi
  8004e3:	89 5d 0c             	mov    %ebx,0xc(%ebp)
  8004e6:	8b 5d e0             	mov    -0x20(%ebp),%ebx
  8004e9:	eb 0c                	jmp    8004f7 <vprintfmt+0x23f>
  8004eb:	89 75 08             	mov    %esi,0x8(%ebp)
  8004ee:	8b 75 d0             	mov    -0x30(%ebp),%esi
  8004f1:	89 5d 0c             	mov    %ebx,0xc(%ebp)
  8004f4:	8b 5d e0             	mov    -0x20(%ebp),%ebx
  8004f7:	83 c7 01             	add    $0x1,%edi
  8004fa:	0f b6 47 ff          	movzbl -0x1(%edi),%eax
  8004fe:	0f be d0             	movsbl %al,%edx
  800501:	85 d2                	test   %edx,%edx
  800503:	74 23                	je     800528 <vprintfmt+0x270>
  800505:	85 f6                	test   %esi,%esi
  800507:	78 a1                	js     8004aa <vprintfmt+0x1f2>
  800509:	83 ee 01             	sub    $0x1,%esi
  80050c:	79 9c                	jns    8004aa <vprintfmt+0x1f2>
  80050e:	89 df                	mov    %ebx,%edi
  800510:	8b 75 08             	mov    0x8(%ebp),%esi
  800513:	8b 5d 0c             	mov    0xc(%ebp),%ebx
  800516:	eb 18                	jmp    800530 <vprintfmt+0x278>
				if (altflag && (ch < ' ' || ch > '~'))
					putch('?', putdat);
				else
					putch(ch, putdat);
			for (; width > 0; width--)
				putch(' ', putdat);
  800518:	83 ec 08             	sub    $0x8,%esp
  80051b:	53                   	push   %ebx
  80051c:	6a 20                	push   $0x20
  80051e:	ff d6                	call   *%esi
			for (; (ch = *p++) != '\0' && (precision < 0 || --precision >= 0); width--)
				if (altflag && (ch < ' ' || ch > '~'))
					putch('?', putdat);
				else
					putch(ch, putdat);
			for (; width > 0; width--)
  800520:	83 ef 01             	sub    $0x1,%edi
  800523:	83 c4 10             	add    $0x10,%esp
  800526:	eb 08                	jmp    800530 <vprintfmt+0x278>
  800528:	89 df                	mov    %ebx,%edi
  80052a:	8b 75 08             	mov    0x8(%ebp),%esi
  80052d:	8b 5d 0c             	mov    0xc(%ebp),%ebx
  800530:	85 ff                	test   %edi,%edi
  800532:	7f e4                	jg     800518 <vprintfmt+0x260>
		width = -1;
		precision = -1;
		lflag = 0;
		altflag = 0;
	reswitch:
		switch (ch = *(unsigned char *) fmt++) {
  800534:	8b 7d e4             	mov    -0x1c(%ebp),%edi
  800537:	e9 a2 fd ff ff       	jmp    8002de <vprintfmt+0x26>
				putch(' ', putdat);
			break;

		// (signed) decimal
		case 'd':
			num = getint(&ap, lflag);
  80053c:	8d 45 14             	lea    0x14(%ebp),%eax
  80053f:	e8 08 fd ff ff       	call   80024c <getint>
  800544:	89 45 d8             	mov    %eax,-0x28(%ebp)
  800547:	89 55 dc             	mov    %edx,-0x24(%ebp)
			if ((long long) num < 0) {
				putch('-', putdat);
				num = -(long long) num;
			}
			base = 10;
  80054a:	b9 0a 00 00 00       	mov    $0xa,%ecx
			break;

		// (signed) decimal
		case 'd':
			num = getint(&ap, lflag);
			if ((long long) num < 0) {
  80054f:	83 7d dc 00          	cmpl   $0x0,-0x24(%ebp)
  800553:	79 74                	jns    8005c9 <vprintfmt+0x311>
				putch('-', putdat);
  800555:	83 ec 08             	sub    $0x8,%esp
  800558:	53                   	push   %ebx
  800559:	6a 2d                	push   $0x2d
  80055b:	ff d6                	call   *%esi
				num = -(long long) num;
  80055d:	8b 45 d8             	mov    -0x28(%ebp),%eax
  800560:	8b 55 dc             	mov    -0x24(%ebp),%edx
  800563:	f7 d8                	neg    %eax
  800565:	83 d2 00             	adc    $0x0,%edx
  800568:	f7 da                	neg    %edx
  80056a:	83 c4 10             	add    $0x10,%esp
			}
			base = 10;
  80056d:	b9 0a 00 00 00       	mov    $0xa,%ecx
  800572:	eb 55                	jmp    8005c9 <vprintfmt+0x311>
			goto number;

		// unsigned decimal
		case 'u':
			num = getuint(&ap, lflag);
  800574:	8d 45 14             	lea    0x14(%ebp),%eax
  800577:	e8 96 fc ff ff       	call   800212 <getuint>
			base = 10;
  80057c:	b9 0a 00 00 00       	mov    $0xa,%ecx
			goto number;
  800581:	eb 46                	jmp    8005c9 <vprintfmt+0x311>

		// (unsigned) octal
		case 'o':
			num = getuint(&ap, lflag);
  800583:	8d 45 14             	lea    0x14(%ebp),%eax
  800586:	e8 87 fc ff ff       	call   800212 <getuint>
			base = 8;
  80058b:	b9 08 00 00 00       	mov    $0x8,%ecx
			goto number;
  800590:	eb 37                	jmp    8005c9 <vprintfmt+0x311>

		// pointer
		case 'p':
			putch('0', putdat);
  800592:	83 ec 08             	sub    $0x8,%esp
  800595:	53                   	push   %ebx
  800596:	6a 30                	push   $0x30
  800598:	ff d6                	call   *%esi
			putch('x', putdat);
  80059a:	83 c4 08             	add    $0x8,%esp
  80059d:	53                   	push   %ebx
  80059e:	6a 78                	push   $0x78
  8005a0:	ff d6                	call   *%esi
			num = (unsigned long long)
				(uintptr_t) va_arg(ap, void *);
  8005a2:	8b 45 14             	mov    0x14(%ebp),%eax
  8005a5:	8d 50 04             	lea    0x4(%eax),%edx
  8005a8:	89 55 14             	mov    %edx,0x14(%ebp)

		// pointer
		case 'p':
			putch('0', putdat);
			putch('x', putdat);
			num = (unsigned long long)
  8005ab:	8b 00                	mov    (%eax),%eax
  8005ad:	ba 00 00 00 00       	mov    $0x0,%edx
				(uintptr_t) va_arg(ap, void *);
			base = 16;
			goto number;
  8005b2:	83 c4 10             	add    $0x10,%esp
		case 'p':
			putch('0', putdat);
			putch('x', putdat);
			num = (unsigned long long)
				(uintptr_t) va_arg(ap, void *);
			base = 16;
  8005b5:	b9 10 00 00 00       	mov    $0x10,%ecx
			goto number;
  8005ba:	eb 0d                	jmp    8005c9 <vprintfmt+0x311>

		// (unsigned) hexadecimal
		case 'x':
			num = getuint(&ap, lflag);
  8005bc:	8d 45 14             	lea    0x14(%ebp),%eax
  8005bf:	e8 4e fc ff ff       	call   800212 <getuint>
			base = 16;
  8005c4:	b9 10 00 00 00       	mov    $0x10,%ecx
		number:
			printnum(putch, putdat, num, base, width, padc);
  8005c9:	83 ec 0c             	sub    $0xc,%esp
  8005cc:	0f be 7d d4          	movsbl -0x2c(%ebp),%edi
  8005d0:	57                   	push   %edi
  8005d1:	ff 75 e0             	pushl  -0x20(%ebp)
  8005d4:	51                   	push   %ecx
  8005d5:	52                   	push   %edx
  8005d6:	50                   	push   %eax
  8005d7:	89 da                	mov    %ebx,%edx
  8005d9:	89 f0                	mov    %esi,%eax
  8005db:	e8 83 fb ff ff       	call   800163 <printnum>
			break;
  8005e0:	83 c4 20             	add    $0x20,%esp
  8005e3:	8b 7d e4             	mov    -0x1c(%ebp),%edi
  8005e6:	e9 f3 fc ff ff       	jmp    8002de <vprintfmt+0x26>

		// escaped '%' character
		case '%':
			putch(ch, putdat);
  8005eb:	83 ec 08             	sub    $0x8,%esp
  8005ee:	53                   	push   %ebx
  8005ef:	51                   	push   %ecx
  8005f0:	ff d6                	call   *%esi
			break;
  8005f2:	83 c4 10             	add    $0x10,%esp
		width = -1;
		precision = -1;
		lflag = 0;
		altflag = 0;
	reswitch:
		switch (ch = *(unsigned char *) fmt++) {
  8005f5:	8b 7d e4             	mov    -0x1c(%ebp),%edi
			break;

		// escaped '%' character
		case '%':
			putch(ch, putdat);
			break;
  8005f8:	e9 e1 fc ff ff       	jmp    8002de <vprintfmt+0x26>

		// unrecognized escape sequence - just print it literally
		default:
			putch('%', putdat);
  8005fd:	83 ec 08             	sub    $0x8,%esp
  800600:	53                   	push   %ebx
  800601:	6a 25                	push   $0x25
  800603:	ff d6                	call   *%esi
			for (fmt--; fmt[-1] != '%'; fmt--)
  800605:	83 c4 10             	add    $0x10,%esp
  800608:	eb 03                	jmp    80060d <vprintfmt+0x355>
  80060a:	83 ef 01             	sub    $0x1,%edi
  80060d:	80 7f ff 25          	cmpb   $0x25,-0x1(%edi)
  800611:	75 f7                	jne    80060a <vprintfmt+0x352>
  800613:	e9 c6 fc ff ff       	jmp    8002de <vprintfmt+0x26>
				/* do nothing */;
			break;
		}
	}
}
  800618:	8d 65 f4             	lea    -0xc(%ebp),%esp
  80061b:	5b                   	pop    %ebx
  80061c:	5e                   	pop    %esi
  80061d:	5f                   	pop    %edi
  80061e:	5d                   	pop    %ebp
  80061f:	c3                   	ret    

00800620 <vsnprintf>:
		*b->buf++ = ch;
}

int
vsnprintf(char *buf, int n, const char *fmt, va_list ap)
{
  800620:	55                   	push   %ebp
  800621:	89 e5                	mov    %esp,%ebp
  800623:	83 ec 18             	sub    $0x18,%esp
  800626:	8b 45 08             	mov    0x8(%ebp),%eax
  800629:	8b 55 0c             	mov    0xc(%ebp),%edx
	struct sprintbuf b = {buf, buf+n-1, 0};
  80062c:	89 45 ec             	mov    %eax,-0x14(%ebp)
  80062f:	8d 4c 10 ff          	lea    -0x1(%eax,%edx,1),%ecx
  800633:	89 4d f0             	mov    %ecx,-0x10(%ebp)
  800636:	c7 45 f4 00 00 00 00 	movl   $0x0,-0xc(%ebp)

	if (buf == NULL || n < 1)
  80063d:	85 c0                	test   %eax,%eax
  80063f:	74 26                	je     800667 <vsnprintf+0x47>
  800641:	85 d2                	test   %edx,%edx
  800643:	7e 22                	jle    800667 <vsnprintf+0x47>
		return -E_INVAL;

	// print the string to the buffer
	vprintfmt((void*)sprintputch, &b, fmt, ap);
  800645:	ff 75 14             	pushl  0x14(%ebp)
  800648:	ff 75 10             	pushl  0x10(%ebp)
  80064b:	8d 45 ec             	lea    -0x14(%ebp),%eax
  80064e:	50                   	push   %eax
  80064f:	68 7e 02 80 00       	push   $0x80027e
  800654:	e8 5f fc ff ff       	call   8002b8 <vprintfmt>

	// null terminate the buffer
	*b.buf = '\0';
  800659:	8b 45 ec             	mov    -0x14(%ebp),%eax
  80065c:	c6 00 00             	movb   $0x0,(%eax)

	return b.cnt;
  80065f:	8b 45 f4             	mov    -0xc(%ebp),%eax
  800662:	83 c4 10             	add    $0x10,%esp
  800665:	eb 05                	jmp    80066c <vsnprintf+0x4c>
vsnprintf(char *buf, int n, const char *fmt, va_list ap)
{
	struct sprintbuf b = {buf, buf+n-1, 0};

	if (buf == NULL || n < 1)
		return -E_INVAL;
  800667:	b8 fd ff ff ff       	mov    $0xfffffffd,%eax

	// null terminate the buffer
	*b.buf = '\0';

	return b.cnt;
}
  80066c:	c9                   	leave  
  80066d:	c3                   	ret    

0080066e <snprintf>:

int
snprintf(char *buf, int n, const char *fmt, ...)
{
  80066e:	55                   	push   %ebp
  80066f:	89 e5                	mov    %esp,%ebp
  800671:	83 ec 08             	sub    $0x8,%esp
	va_list ap;
	int rc;

	va_start(ap, fmt);
  800674:	8d 45 14             	lea    0x14(%ebp),%eax
	rc = vsnprintf(buf, n, fmt, ap);
  800677:	50                   	push   %eax
  800678:	ff 75 10             	pushl  0x10(%ebp)
  80067b:	ff 75 0c             	pushl  0xc(%ebp)
  80067e:	ff 75 08             	pushl  0x8(%ebp)
  800681:	e8 9a ff ff ff       	call   800620 <vsnprintf>
	va_end(ap);

	return rc;
}
  800686:	c9                   	leave  
  800687:	c3                   	ret    

00800688 <strlen>:
// Primespipe runs 3x faster this way.
#define ASM 1

int
strlen(const char *s)
{
  800688:	55                   	push   %ebp
  800689:	89 e5                	mov    %esp,%ebp
  80068b:	8b 55 08             	mov    0x8(%ebp),%edx
	int n;

	for (n = 0; *s != '\0'; s++)
  80068e:	b8 00 00 00 00       	mov    $0x0,%eax
  800693:	eb 03                	jmp    800698 <strlen+0x10>
		n++;
  800695:	83 c0 01             	add    $0x1,%eax
int
strlen(const char *s)
{
	int n;

	for (n = 0; *s != '\0'; s++)
  800698:	80 3c 02 00          	cmpb   $0x0,(%edx,%eax,1)
  80069c:	75 f7                	jne    800695 <strlen+0xd>
		n++;
	return n;
}
  80069e:	5d                   	pop    %ebp
  80069f:	c3                   	ret    

008006a0 <strnlen>:

int
strnlen(const char *s, size_t size)
{
  8006a0:	55                   	push   %ebp
  8006a1:	89 e5                	mov    %esp,%ebp
  8006a3:	8b 4d 08             	mov    0x8(%ebp),%ecx
  8006a6:	8b 45 0c             	mov    0xc(%ebp),%eax
	int n;

	for (n = 0; size > 0 && *s != '\0'; s++, size--)
  8006a9:	ba 00 00 00 00       	mov    $0x0,%edx
  8006ae:	eb 03                	jmp    8006b3 <strnlen+0x13>
		n++;
  8006b0:	83 c2 01             	add    $0x1,%edx
int
strnlen(const char *s, size_t size)
{
	int n;

	for (n = 0; size > 0 && *s != '\0'; s++, size--)
  8006b3:	39 c2                	cmp    %eax,%edx
  8006b5:	74 08                	je     8006bf <strnlen+0x1f>
  8006b7:	80 3c 11 00          	cmpb   $0x0,(%ecx,%edx,1)
  8006bb:	75 f3                	jne    8006b0 <strnlen+0x10>
  8006bd:	89 d0                	mov    %edx,%eax
		n++;
	return n;
}
  8006bf:	5d                   	pop    %ebp
  8006c0:	c3                   	ret    

008006c1 <strcpy>:

char *
strcpy(char *dst, const char *src)
{
  8006c1:	55                   	push   %ebp
  8006c2:	89 e5                	mov    %esp,%ebp
  8006c4:	53                   	push   %ebx
  8006c5:	8b 45 08             	mov    0x8(%ebp),%eax
  8006c8:	8b 4d 0c             	mov    0xc(%ebp),%ecx
	char *ret;

	ret = dst;
	while ((*dst++ = *src++) != '\0')
  8006cb:	89 c2                	mov    %eax,%edx
  8006cd:	83 c2 01             	add    $0x1,%edx
  8006d0:	83 c1 01             	add    $0x1,%ecx
  8006d3:	0f b6 59 ff          	movzbl -0x1(%ecx),%ebx
  8006d7:	88 5a ff             	mov    %bl,-0x1(%edx)
  8006da:	84 db                	test   %bl,%bl
  8006dc:	75 ef                	jne    8006cd <strcpy+0xc>
		/* do nothing */;
	return ret;
}
  8006de:	5b                   	pop    %ebx
  8006df:	5d                   	pop    %ebp
  8006e0:	c3                   	ret    

008006e1 <strcat>:

char *
strcat(char *dst, const char *src)
{
  8006e1:	55                   	push   %ebp
  8006e2:	89 e5                	mov    %esp,%ebp
  8006e4:	53                   	push   %ebx
  8006e5:	8b 5d 08             	mov    0x8(%ebp),%ebx
	int len = strlen(dst);
  8006e8:	53                   	push   %ebx
  8006e9:	e8 9a ff ff ff       	call   800688 <strlen>
  8006ee:	83 c4 04             	add    $0x4,%esp
	strcpy(dst + len, src);
  8006f1:	ff 75 0c             	pushl  0xc(%ebp)
  8006f4:	01 d8                	add    %ebx,%eax
  8006f6:	50                   	push   %eax
  8006f7:	e8 c5 ff ff ff       	call   8006c1 <strcpy>
	return dst;
}
  8006fc:	89 d8                	mov    %ebx,%eax
  8006fe:	8b 5d fc             	mov    -0x4(%ebp),%ebx
  800701:	c9                   	leave  
  800702:	c3                   	ret    

00800703 <strncpy>:

char *
strncpy(char *dst, const char *src, size_t size) {
  800703:	55                   	push   %ebp
  800704:	89 e5                	mov    %esp,%ebp
  800706:	56                   	push   %esi
  800707:	53                   	push   %ebx
  800708:	8b 75 08             	mov    0x8(%ebp),%esi
  80070b:	8b 4d 0c             	mov    0xc(%ebp),%ecx
  80070e:	89 f3                	mov    %esi,%ebx
  800710:	03 5d 10             	add    0x10(%ebp),%ebx
	size_t i;
	char *ret;

	ret = dst;
	for (i = 0; i < size; i++) {
  800713:	89 f2                	mov    %esi,%edx
  800715:	eb 0f                	jmp    800726 <strncpy+0x23>
		*dst++ = *src;
  800717:	83 c2 01             	add    $0x1,%edx
  80071a:	0f b6 01             	movzbl (%ecx),%eax
  80071d:	88 42 ff             	mov    %al,-0x1(%edx)
		// If strlen(src) < size, null-pad 'dst' out to 'size' chars
		if (*src != '\0')
			src++;
  800720:	80 39 01             	cmpb   $0x1,(%ecx)
  800723:	83 d9 ff             	sbb    $0xffffffff,%ecx
strncpy(char *dst, const char *src, size_t size) {
	size_t i;
	char *ret;

	ret = dst;
	for (i = 0; i < size; i++) {
  800726:	39 da                	cmp    %ebx,%edx
  800728:	75 ed                	jne    800717 <strncpy+0x14>
		// If strlen(src) < size, null-pad 'dst' out to 'size' chars
		if (*src != '\0')
			src++;
	}
	return ret;
}
  80072a:	89 f0                	mov    %esi,%eax
  80072c:	5b                   	pop    %ebx
  80072d:	5e                   	pop    %esi
  80072e:	5d                   	pop    %ebp
  80072f:	c3                   	ret    

00800730 <strlcpy>:

size_t
strlcpy(char *dst, const char *src, size_t size)
{
  800730:	55                   	push   %ebp
  800731:	89 e5                	mov    %esp,%ebp
  800733:	56                   	push   %esi
  800734:	53                   	push   %ebx
  800735:	8b 75 08             	mov    0x8(%ebp),%esi
  800738:	8b 4d 0c             	mov    0xc(%ebp),%ecx
  80073b:	8b 55 10             	mov    0x10(%ebp),%edx
  80073e:	89 f0                	mov    %esi,%eax
	char *dst_in;

	dst_in = dst;
	if (size > 0) {
  800740:	85 d2                	test   %edx,%edx
  800742:	74 21                	je     800765 <strlcpy+0x35>
  800744:	8d 44 16 ff          	lea    -0x1(%esi,%edx,1),%eax
  800748:	89 f2                	mov    %esi,%edx
  80074a:	eb 09                	jmp    800755 <strlcpy+0x25>
		while (--size > 0 && *src != '\0')
			*dst++ = *src++;
  80074c:	83 c2 01             	add    $0x1,%edx
  80074f:	83 c1 01             	add    $0x1,%ecx
  800752:	88 5a ff             	mov    %bl,-0x1(%edx)
{
	char *dst_in;

	dst_in = dst;
	if (size > 0) {
		while (--size > 0 && *src != '\0')
  800755:	39 c2                	cmp    %eax,%edx
  800757:	74 09                	je     800762 <strlcpy+0x32>
  800759:	0f b6 19             	movzbl (%ecx),%ebx
  80075c:	84 db                	test   %bl,%bl
  80075e:	75 ec                	jne    80074c <strlcpy+0x1c>
  800760:	89 d0                	mov    %edx,%eax
			*dst++ = *src++;
		*dst = '\0';
  800762:	c6 00 00             	movb   $0x0,(%eax)
	}
	return dst - dst_in;
  800765:	29 f0                	sub    %esi,%eax
}
  800767:	5b                   	pop    %ebx
  800768:	5e                   	pop    %esi
  800769:	5d                   	pop    %ebp
  80076a:	c3                   	ret    

0080076b <strcmp>:

int
strcmp(const char *p, const char *q)
{
  80076b:	55                   	push   %ebp
  80076c:	89 e5                	mov    %esp,%ebp
  80076e:	8b 4d 08             	mov    0x8(%ebp),%ecx
  800771:	8b 55 0c             	mov    0xc(%ebp),%edx
	while (*p && *p == *q)
  800774:	eb 06                	jmp    80077c <strcmp+0x11>
		p++, q++;
  800776:	83 c1 01             	add    $0x1,%ecx
  800779:	83 c2 01             	add    $0x1,%edx
}

int
strcmp(const char *p, const char *q)
{
	while (*p && *p == *q)
  80077c:	0f b6 01             	movzbl (%ecx),%eax
  80077f:	84 c0                	test   %al,%al
  800781:	74 04                	je     800787 <strcmp+0x1c>
  800783:	3a 02                	cmp    (%edx),%al
  800785:	74 ef                	je     800776 <strcmp+0xb>
		p++, q++;
	return (int) ((unsigned char) *p - (unsigned char) *q);
  800787:	0f b6 c0             	movzbl %al,%eax
  80078a:	0f b6 12             	movzbl (%edx),%edx
  80078d:	29 d0                	sub    %edx,%eax
}
  80078f:	5d                   	pop    %ebp
  800790:	c3                   	ret    

00800791 <strncmp>:

int
strncmp(const char *p, const char *q, size_t n)
{
  800791:	55                   	push   %ebp
  800792:	89 e5                	mov    %esp,%ebp
  800794:	53                   	push   %ebx
  800795:	8b 45 08             	mov    0x8(%ebp),%eax
  800798:	8b 55 0c             	mov    0xc(%ebp),%edx
  80079b:	89 c3                	mov    %eax,%ebx
  80079d:	03 5d 10             	add    0x10(%ebp),%ebx
	while (n > 0 && *p && *p == *q)
  8007a0:	eb 06                	jmp    8007a8 <strncmp+0x17>
		n--, p++, q++;
  8007a2:	83 c0 01             	add    $0x1,%eax
  8007a5:	83 c2 01             	add    $0x1,%edx
}

int
strncmp(const char *p, const char *q, size_t n)
{
	while (n > 0 && *p && *p == *q)
  8007a8:	39 d8                	cmp    %ebx,%eax
  8007aa:	74 15                	je     8007c1 <strncmp+0x30>
  8007ac:	0f b6 08             	movzbl (%eax),%ecx
  8007af:	84 c9                	test   %cl,%cl
  8007b1:	74 04                	je     8007b7 <strncmp+0x26>
  8007b3:	3a 0a                	cmp    (%edx),%cl
  8007b5:	74 eb                	je     8007a2 <strncmp+0x11>
		n--, p++, q++;
	if (n == 0)
		return 0;
	else
		return (int) ((unsigned char) *p - (unsigned char) *q);
  8007b7:	0f b6 00             	movzbl (%eax),%eax
  8007ba:	0f b6 12             	movzbl (%edx),%edx
  8007bd:	29 d0                	sub    %edx,%eax
  8007bf:	eb 05                	jmp    8007c6 <strncmp+0x35>
strncmp(const char *p, const char *q, size_t n)
{
	while (n > 0 && *p && *p == *q)
		n--, p++, q++;
	if (n == 0)
		return 0;
  8007c1:	b8 00 00 00 00       	mov    $0x0,%eax
	else
		return (int) ((unsigned char) *p - (unsigned char) *q);
}
  8007c6:	5b                   	pop    %ebx
  8007c7:	5d                   	pop    %ebp
  8007c8:	c3                   	ret    

008007c9 <strchr>:

// Return a pointer to the first occurrence of 'c' in 's',
// or a null pointer if the string has no 'c'.
char *
strchr(const char *s, char c)
{
  8007c9:	55                   	push   %ebp
  8007ca:	89 e5                	mov    %esp,%ebp
  8007cc:	8b 45 08             	mov    0x8(%ebp),%eax
  8007cf:	0f b6 4d 0c          	movzbl 0xc(%ebp),%ecx
	for (; *s; s++)
  8007d3:	eb 07                	jmp    8007dc <strchr+0x13>
		if (*s == c)
  8007d5:	38 ca                	cmp    %cl,%dl
  8007d7:	74 0f                	je     8007e8 <strchr+0x1f>
// Return a pointer to the first occurrence of 'c' in 's',
// or a null pointer if the string has no 'c'.
char *
strchr(const char *s, char c)
{
	for (; *s; s++)
  8007d9:	83 c0 01             	add    $0x1,%eax
  8007dc:	0f b6 10             	movzbl (%eax),%edx
  8007df:	84 d2                	test   %dl,%dl
  8007e1:	75 f2                	jne    8007d5 <strchr+0xc>
		if (*s == c)
			return (char *) s;
	return 0;
  8007e3:	b8 00 00 00 00       	mov    $0x0,%eax
}
  8007e8:	5d                   	pop    %ebp
  8007e9:	c3                   	ret    

008007ea <strfind>:

// Return a pointer to the first occurrence of 'c' in 's',
// or a pointer to the string-ending null character if the string has no 'c'.
char *
strfind(const char *s, char c)
{
  8007ea:	55                   	push   %ebp
  8007eb:	89 e5                	mov    %esp,%ebp
  8007ed:	8b 45 08             	mov    0x8(%ebp),%eax
  8007f0:	0f b6 4d 0c          	movzbl 0xc(%ebp),%ecx
	for (; *s; s++)
  8007f4:	eb 03                	jmp    8007f9 <strfind+0xf>
  8007f6:	83 c0 01             	add    $0x1,%eax
  8007f9:	0f b6 10             	movzbl (%eax),%edx
		if (*s == c)
  8007fc:	38 ca                	cmp    %cl,%dl
  8007fe:	74 04                	je     800804 <strfind+0x1a>
  800800:	84 d2                	test   %dl,%dl
  800802:	75 f2                	jne    8007f6 <strfind+0xc>
			break;
	return (char *) s;
}
  800804:	5d                   	pop    %ebp
  800805:	c3                   	ret    

00800806 <memset>:

#if ASM
void *
memset(void *v, int c, size_t n)
{
  800806:	55                   	push   %ebp
  800807:	89 e5                	mov    %esp,%ebp
  800809:	57                   	push   %edi
  80080a:	56                   	push   %esi
  80080b:	53                   	push   %ebx
  80080c:	8b 55 08             	mov    0x8(%ebp),%edx
  80080f:	8b 4d 10             	mov    0x10(%ebp),%ecx
	char *p = v;

	if (n == 0)
  800812:	85 c9                	test   %ecx,%ecx
  800814:	74 37                	je     80084d <memset+0x47>
		return v;
	if ((int)v%4 == 0 && n%4 == 0) {
  800816:	f6 c2 03             	test   $0x3,%dl
  800819:	75 2a                	jne    800845 <memset+0x3f>
  80081b:	f6 c1 03             	test   $0x3,%cl
  80081e:	75 25                	jne    800845 <memset+0x3f>
		c &= 0xFF;
  800820:	0f b6 5d 0c          	movzbl 0xc(%ebp),%ebx
		c = (c<<24)|(c<<16)|(c<<8)|c;
  800824:	89 df                	mov    %ebx,%edi
  800826:	c1 e7 08             	shl    $0x8,%edi
  800829:	89 de                	mov    %ebx,%esi
  80082b:	c1 e6 18             	shl    $0x18,%esi
  80082e:	89 d8                	mov    %ebx,%eax
  800830:	c1 e0 10             	shl    $0x10,%eax
  800833:	09 f0                	or     %esi,%eax
  800835:	09 c3                	or     %eax,%ebx
		asm volatile("cld; rep stosl\n"
			: "=D" (p), "=c" (n)
			: "D" (p), "a" (c), "c" (n/4)
  800837:	c1 e9 02             	shr    $0x2,%ecx
	if (n == 0)
		return v;
	if ((int)v%4 == 0 && n%4 == 0) {
		c &= 0xFF;
		c = (c<<24)|(c<<16)|(c<<8)|c;
		asm volatile("cld; rep stosl\n"
  80083a:	89 f8                	mov    %edi,%eax
  80083c:	09 d8                	or     %ebx,%eax
  80083e:	89 d7                	mov    %edx,%edi
  800840:	fc                   	cld    
  800841:	f3 ab                	rep stos %eax,%es:(%edi)
  800843:	eb 08                	jmp    80084d <memset+0x47>
			: "=D" (p), "=c" (n)
			: "D" (p), "a" (c), "c" (n/4)
			: "cc", "memory");
	} else
		asm volatile("cld; rep stosb\n"
  800845:	89 d7                	mov    %edx,%edi
  800847:	8b 45 0c             	mov    0xc(%ebp),%eax
  80084a:	fc                   	cld    
  80084b:	f3 aa                	rep stos %al,%es:(%edi)
			: "=D" (p), "=c" (n)
			: "0" (p), "a" (c), "1" (n)
			: "cc", "memory");
	return v;
}
  80084d:	89 d0                	mov    %edx,%eax
  80084f:	5b                   	pop    %ebx
  800850:	5e                   	pop    %esi
  800851:	5f                   	pop    %edi
  800852:	5d                   	pop    %ebp
  800853:	c3                   	ret    

00800854 <memmove>:

void *
memmove(void *dst, const void *src, size_t n)
{
  800854:	55                   	push   %ebp
  800855:	89 e5                	mov    %esp,%ebp
  800857:	57                   	push   %edi
  800858:	56                   	push   %esi
  800859:	8b 45 08             	mov    0x8(%ebp),%eax
  80085c:	8b 75 0c             	mov    0xc(%ebp),%esi
  80085f:	8b 4d 10             	mov    0x10(%ebp),%ecx
	const char *s;
	char *d;

	s = src;
	d = dst;
	if (s < d && s + n > d) {
  800862:	39 c6                	cmp    %eax,%esi
  800864:	73 35                	jae    80089b <memmove+0x47>
  800866:	8d 14 0e             	lea    (%esi,%ecx,1),%edx
  800869:	39 d0                	cmp    %edx,%eax
  80086b:	73 2e                	jae    80089b <memmove+0x47>
		s += n;
		d += n;
  80086d:	8d 3c 08             	lea    (%eax,%ecx,1),%edi
		if ((int)s%4 == 0 && (int)d%4 == 0 && n%4 == 0)
  800870:	89 d6                	mov    %edx,%esi
  800872:	09 fe                	or     %edi,%esi
  800874:	f7 c6 03 00 00 00    	test   $0x3,%esi
  80087a:	75 13                	jne    80088f <memmove+0x3b>
  80087c:	f6 c1 03             	test   $0x3,%cl
  80087f:	75 0e                	jne    80088f <memmove+0x3b>
			asm volatile("std; rep movsl\n"
  800881:	83 ef 04             	sub    $0x4,%edi
  800884:	8d 72 fc             	lea    -0x4(%edx),%esi
  800887:	c1 e9 02             	shr    $0x2,%ecx
  80088a:	fd                   	std    
  80088b:	f3 a5                	rep movsl %ds:(%esi),%es:(%edi)
  80088d:	eb 09                	jmp    800898 <memmove+0x44>
				:: "D" (d-4), "S" (s-4), "c" (n/4) : "cc", "memory");
		else
			asm volatile("std; rep movsb\n"
  80088f:	83 ef 01             	sub    $0x1,%edi
  800892:	8d 72 ff             	lea    -0x1(%edx),%esi
  800895:	fd                   	std    
  800896:	f3 a4                	rep movsb %ds:(%esi),%es:(%edi)
				:: "D" (d-1), "S" (s-1), "c" (n) : "cc", "memory");
		// Some versions of GCC rely on DF being clear
		asm volatile("cld" ::: "cc");
  800898:	fc                   	cld    
  800899:	eb 1d                	jmp    8008b8 <memmove+0x64>
	} else {
		if ((int)s%4 == 0 && (int)d%4 == 0 && n%4 == 0)
  80089b:	89 f2                	mov    %esi,%edx
  80089d:	09 c2                	or     %eax,%edx
  80089f:	f6 c2 03             	test   $0x3,%dl
  8008a2:	75 0f                	jne    8008b3 <memmove+0x5f>
  8008a4:	f6 c1 03             	test   $0x3,%cl
  8008a7:	75 0a                	jne    8008b3 <memmove+0x5f>
			asm volatile("cld; rep movsl\n"
  8008a9:	c1 e9 02             	shr    $0x2,%ecx
  8008ac:	89 c7                	mov    %eax,%edi
  8008ae:	fc                   	cld    
  8008af:	f3 a5                	rep movsl %ds:(%esi),%es:(%edi)
  8008b1:	eb 05                	jmp    8008b8 <memmove+0x64>
				:: "D" (d), "S" (s), "c" (n/4) : "cc", "memory");
		else
			asm volatile("cld; rep movsb\n"
  8008b3:	89 c7                	mov    %eax,%edi
  8008b5:	fc                   	cld    
  8008b6:	f3 a4                	rep movsb %ds:(%esi),%es:(%edi)
				:: "D" (d), "S" (s), "c" (n) : "cc", "memory");
	}
	return dst;
}
  8008b8:	5e                   	pop    %esi
  8008b9:	5f                   	pop    %edi
  8008ba:	5d                   	pop    %ebp
  8008bb:	c3                   	ret    

008008bc <memcpy>:
}
#endif

void *
memcpy(void *dst, const void *src, size_t n)
{
  8008bc:	55                   	push   %ebp
  8008bd:	89 e5                	mov    %esp,%ebp
	return memmove(dst, src, n);
  8008bf:	ff 75 10             	pushl  0x10(%ebp)
  8008c2:	ff 75 0c             	pushl  0xc(%ebp)
  8008c5:	ff 75 08             	pushl  0x8(%ebp)
  8008c8:	e8 87 ff ff ff       	call   800854 <memmove>
}
  8008cd:	c9                   	leave  
  8008ce:	c3                   	ret    

008008cf <memcmp>:

int
memcmp(const void *v1, const void *v2, size_t n)
{
  8008cf:	55                   	push   %ebp
  8008d0:	89 e5                	mov    %esp,%ebp
  8008d2:	56                   	push   %esi
  8008d3:	53                   	push   %ebx
  8008d4:	8b 45 08             	mov    0x8(%ebp),%eax
  8008d7:	8b 55 0c             	mov    0xc(%ebp),%edx
  8008da:	89 c6                	mov    %eax,%esi
  8008dc:	03 75 10             	add    0x10(%ebp),%esi
	const uint8_t *s1 = (const uint8_t *) v1;
	const uint8_t *s2 = (const uint8_t *) v2;

	while (n-- > 0) {
  8008df:	eb 1a                	jmp    8008fb <memcmp+0x2c>
		if (*s1 != *s2)
  8008e1:	0f b6 08             	movzbl (%eax),%ecx
  8008e4:	0f b6 1a             	movzbl (%edx),%ebx
  8008e7:	38 d9                	cmp    %bl,%cl
  8008e9:	74 0a                	je     8008f5 <memcmp+0x26>
			return (int) *s1 - (int) *s2;
  8008eb:	0f b6 c1             	movzbl %cl,%eax
  8008ee:	0f b6 db             	movzbl %bl,%ebx
  8008f1:	29 d8                	sub    %ebx,%eax
  8008f3:	eb 0f                	jmp    800904 <memcmp+0x35>
		s1++, s2++;
  8008f5:	83 c0 01             	add    $0x1,%eax
  8008f8:	83 c2 01             	add    $0x1,%edx
memcmp(const void *v1, const void *v2, size_t n)
{
	const uint8_t *s1 = (const uint8_t *) v1;
	const uint8_t *s2 = (const uint8_t *) v2;

	while (n-- > 0) {
  8008fb:	39 f0                	cmp    %esi,%eax
  8008fd:	75 e2                	jne    8008e1 <memcmp+0x12>
		if (*s1 != *s2)
			return (int) *s1 - (int) *s2;
		s1++, s2++;
	}

	return 0;
  8008ff:	b8 00 00 00 00       	mov    $0x0,%eax
}
  800904:	5b                   	pop    %ebx
  800905:	5e                   	pop    %esi
  800906:	5d                   	pop    %ebp
  800907:	c3                   	ret    

00800908 <memfind>:

void *
memfind(const void *s, int c, size_t n)
{
  800908:	55                   	push   %ebp
  800909:	89 e5                	mov    %esp,%ebp
  80090b:	8b 45 08             	mov    0x8(%ebp),%eax
  80090e:	8b 4d 0c             	mov    0xc(%ebp),%ecx
	const void *ends = (const char *) s + n;
  800911:	89 c2                	mov    %eax,%edx
  800913:	03 55 10             	add    0x10(%ebp),%edx
	for (; s < ends; s++)
  800916:	eb 07                	jmp    80091f <memfind+0x17>
		if (*(const unsigned char *) s == (unsigned char) c)
  800918:	38 08                	cmp    %cl,(%eax)
  80091a:	74 07                	je     800923 <memfind+0x1b>

void *
memfind(const void *s, int c, size_t n)
{
	const void *ends = (const char *) s + n;
	for (; s < ends; s++)
  80091c:	83 c0 01             	add    $0x1,%eax
  80091f:	39 d0                	cmp    %edx,%eax
  800921:	72 f5                	jb     800918 <memfind+0x10>
		if (*(const unsigned char *) s == (unsigned char) c)
			break;
	return (void *) s;
}
  800923:	5d                   	pop    %ebp
  800924:	c3                   	ret    

00800925 <strtol>:

long
strtol(const char *s, char **endptr, int base)
{
  800925:	55                   	push   %ebp
  800926:	89 e5                	mov    %esp,%ebp
  800928:	57                   	push   %edi
  800929:	56                   	push   %esi
  80092a:	53                   	push   %ebx
  80092b:	8b 4d 08             	mov    0x8(%ebp),%ecx
  80092e:	8b 5d 10             	mov    0x10(%ebp),%ebx
	int neg = 0;
	long val = 0;

	// gobble initial whitespace
	while (*s == ' ' || *s == '\t')
  800931:	eb 03                	jmp    800936 <strtol+0x11>
		s++;
  800933:	83 c1 01             	add    $0x1,%ecx
{
	int neg = 0;
	long val = 0;

	// gobble initial whitespace
	while (*s == ' ' || *s == '\t')
  800936:	0f b6 01             	movzbl (%ecx),%eax
  800939:	3c 20                	cmp    $0x20,%al
  80093b:	74 f6                	je     800933 <strtol+0xe>
  80093d:	3c 09                	cmp    $0x9,%al
  80093f:	74 f2                	je     800933 <strtol+0xe>
		s++;

	// plus/minus sign
	if (*s == '+')
  800941:	3c 2b                	cmp    $0x2b,%al
  800943:	75 0a                	jne    80094f <strtol+0x2a>
		s++;
  800945:	83 c1 01             	add    $0x1,%ecx
}

long
strtol(const char *s, char **endptr, int base)
{
	int neg = 0;
  800948:	bf 00 00 00 00       	mov    $0x0,%edi
  80094d:	eb 11                	jmp    800960 <strtol+0x3b>
  80094f:	bf 00 00 00 00       	mov    $0x0,%edi
		s++;

	// plus/minus sign
	if (*s == '+')
		s++;
	else if (*s == '-')
  800954:	3c 2d                	cmp    $0x2d,%al
  800956:	75 08                	jne    800960 <strtol+0x3b>
		s++, neg = 1;
  800958:	83 c1 01             	add    $0x1,%ecx
  80095b:	bf 01 00 00 00       	mov    $0x1,%edi

	// hex or octal base prefix
	if ((base == 0 || base == 16) && (s[0] == '0' && s[1] == 'x'))
  800960:	f7 c3 ef ff ff ff    	test   $0xffffffef,%ebx
  800966:	75 15                	jne    80097d <strtol+0x58>
  800968:	80 39 30             	cmpb   $0x30,(%ecx)
  80096b:	75 10                	jne    80097d <strtol+0x58>
  80096d:	80 79 01 78          	cmpb   $0x78,0x1(%ecx)
  800971:	75 7c                	jne    8009ef <strtol+0xca>
		s += 2, base = 16;
  800973:	83 c1 02             	add    $0x2,%ecx
  800976:	bb 10 00 00 00       	mov    $0x10,%ebx
  80097b:	eb 16                	jmp    800993 <strtol+0x6e>
	else if (base == 0 && s[0] == '0')
  80097d:	85 db                	test   %ebx,%ebx
  80097f:	75 12                	jne    800993 <strtol+0x6e>
		s++, base = 8;
	else if (base == 0)
		base = 10;
  800981:	bb 0a 00 00 00       	mov    $0xa,%ebx
		s++, neg = 1;

	// hex or octal base prefix
	if ((base == 0 || base == 16) && (s[0] == '0' && s[1] == 'x'))
		s += 2, base = 16;
	else if (base == 0 && s[0] == '0')
  800986:	80 39 30             	cmpb   $0x30,(%ecx)
  800989:	75 08                	jne    800993 <strtol+0x6e>
		s++, base = 8;
  80098b:	83 c1 01             	add    $0x1,%ecx
  80098e:	bb 08 00 00 00       	mov    $0x8,%ebx
	else if (base == 0)
		base = 10;
  800993:	b8 00 00 00 00       	mov    $0x0,%eax
  800998:	89 5d 10             	mov    %ebx,0x10(%ebp)

	// digits
	while (1) {
		int dig;

		if (*s >= '0' && *s <= '9')
  80099b:	0f b6 11             	movzbl (%ecx),%edx
  80099e:	8d 72 d0             	lea    -0x30(%edx),%esi
  8009a1:	89 f3                	mov    %esi,%ebx
  8009a3:	80 fb 09             	cmp    $0x9,%bl
  8009a6:	77 08                	ja     8009b0 <strtol+0x8b>
			dig = *s - '0';
  8009a8:	0f be d2             	movsbl %dl,%edx
  8009ab:	83 ea 30             	sub    $0x30,%edx
  8009ae:	eb 22                	jmp    8009d2 <strtol+0xad>
		else if (*s >= 'a' && *s <= 'z')
  8009b0:	8d 72 9f             	lea    -0x61(%edx),%esi
  8009b3:	89 f3                	mov    %esi,%ebx
  8009b5:	80 fb 19             	cmp    $0x19,%bl
  8009b8:	77 08                	ja     8009c2 <strtol+0x9d>
			dig = *s - 'a' + 10;
  8009ba:	0f be d2             	movsbl %dl,%edx
  8009bd:	83 ea 57             	sub    $0x57,%edx
  8009c0:	eb 10                	jmp    8009d2 <strtol+0xad>
		else if (*s >= 'A' && *s <= 'Z')
  8009c2:	8d 72 bf             	lea    -0x41(%edx),%esi
  8009c5:	89 f3                	mov    %esi,%ebx
  8009c7:	80 fb 19             	cmp    $0x19,%bl
  8009ca:	77 16                	ja     8009e2 <strtol+0xbd>
			dig = *s - 'A' + 10;
  8009cc:	0f be d2             	movsbl %dl,%edx
  8009cf:	83 ea 37             	sub    $0x37,%edx
		else
			break;
		if (dig >= base)
  8009d2:	3b 55 10             	cmp    0x10(%ebp),%edx
  8009d5:	7d 0b                	jge    8009e2 <strtol+0xbd>
			break;
		s++, val = (val * base) + dig;
  8009d7:	83 c1 01             	add    $0x1,%ecx
  8009da:	0f af 45 10          	imul   0x10(%ebp),%eax
  8009de:	01 d0                	add    %edx,%eax
		// we don't properly detect overflow!
	}
  8009e0:	eb b9                	jmp    80099b <strtol+0x76>

	if (endptr)
  8009e2:	83 7d 0c 00          	cmpl   $0x0,0xc(%ebp)
  8009e6:	74 0d                	je     8009f5 <strtol+0xd0>
		*endptr = (char *) s;
  8009e8:	8b 75 0c             	mov    0xc(%ebp),%esi
  8009eb:	89 0e                	mov    %ecx,(%esi)
  8009ed:	eb 06                	jmp    8009f5 <strtol+0xd0>
		s++, neg = 1;

	// hex or octal base prefix
	if ((base == 0 || base == 16) && (s[0] == '0' && s[1] == 'x'))
		s += 2, base = 16;
	else if (base == 0 && s[0] == '0')
  8009ef:	85 db                	test   %ebx,%ebx
  8009f1:	74 98                	je     80098b <strtol+0x66>
  8009f3:	eb 9e                	jmp    800993 <strtol+0x6e>
		// we don't properly detect overflow!
	}

	if (endptr)
		*endptr = (char *) s;
	return (neg ? -val : val);
  8009f5:	89 c2                	mov    %eax,%edx
  8009f7:	f7 da                	neg    %edx
  8009f9:	85 ff                	test   %edi,%edi
  8009fb:	0f 45 c2             	cmovne %edx,%eax
}
  8009fe:	5b                   	pop    %ebx
  8009ff:	5e                   	pop    %esi
  800a00:	5f                   	pop    %edi
  800a01:	5d                   	pop    %ebp
  800a02:	c3                   	ret    

00800a03 <syscall>:
#include <inc/syscall.h>
#include <inc/lib.h>

static inline int32_t
syscall(int num, int check, uint32_t a1, uint32_t a2, uint32_t a3, uint32_t a4, uint32_t a5)
{
  800a03:	55                   	push   %ebp
  800a04:	89 e5                	mov    %esp,%ebp
  800a06:	57                   	push   %edi
  800a07:	56                   	push   %esi
  800a08:	53                   	push   %ebx
  800a09:	83 ec 1c             	sub    $0x1c,%esp
  800a0c:	89 45 e0             	mov    %eax,-0x20(%ebp)
  800a0f:	89 55 e4             	mov    %edx,-0x1c(%ebp)
  800a12:	89 ca                	mov    %ecx,%edx
	//
	// The last clause tells the assembler that this can
	// potentially change the condition codes and arbitrary
	// memory locations.

	asm volatile("int %1\n"
  800a14:	8b 4d 08             	mov    0x8(%ebp),%ecx
  800a17:	8b 5d 0c             	mov    0xc(%ebp),%ebx
  800a1a:	8b 7d 10             	mov    0x10(%ebp),%edi
  800a1d:	8b 75 14             	mov    0x14(%ebp),%esi
  800a20:	cd 30                	int    $0x30
		       "b" (a3),
		       "D" (a4),
		       "S" (a5)
		     : "cc", "memory");

	if(check && ret > 0)
  800a22:	83 7d e4 00          	cmpl   $0x0,-0x1c(%ebp)
  800a26:	74 1d                	je     800a45 <syscall+0x42>
  800a28:	85 c0                	test   %eax,%eax
  800a2a:	7e 19                	jle    800a45 <syscall+0x42>
  800a2c:	8b 55 e0             	mov    -0x20(%ebp),%edx
		panic("syscall %d returned %d (> 0)", num, ret);
  800a2f:	83 ec 0c             	sub    $0xc,%esp
  800a32:	50                   	push   %eax
  800a33:	52                   	push   %edx
  800a34:	68 44 11 80 00       	push   $0x801144
  800a39:	6a 23                	push   $0x23
  800a3b:	68 61 11 80 00       	push   $0x801161
  800a40:	e8 b9 01 00 00       	call   800bfe <_panic>

	return ret;
}
  800a45:	8d 65 f4             	lea    -0xc(%ebp),%esp
  800a48:	5b                   	pop    %ebx
  800a49:	5e                   	pop    %esi
  800a4a:	5f                   	pop    %edi
  800a4b:	5d                   	pop    %ebp
  800a4c:	c3                   	ret    

00800a4d <sys_cputs>:

void
sys_cputs(const char *s, size_t len)
{
  800a4d:	55                   	push   %ebp
  800a4e:	89 e5                	mov    %esp,%ebp
  800a50:	83 ec 08             	sub    $0x8,%esp
	syscall(SYS_cputs, 0, (uint32_t)s, len, 0, 0, 0);
  800a53:	6a 00                	push   $0x0
  800a55:	6a 00                	push   $0x0
  800a57:	6a 00                	push   $0x0
  800a59:	ff 75 0c             	pushl  0xc(%ebp)
  800a5c:	8b 4d 08             	mov    0x8(%ebp),%ecx
  800a5f:	ba 00 00 00 00       	mov    $0x0,%edx
  800a64:	b8 00 00 00 00       	mov    $0x0,%eax
  800a69:	e8 95 ff ff ff       	call   800a03 <syscall>
}
  800a6e:	83 c4 10             	add    $0x10,%esp
  800a71:	c9                   	leave  
  800a72:	c3                   	ret    

00800a73 <sys_cgetc>:

int
sys_cgetc(void)
{
  800a73:	55                   	push   %ebp
  800a74:	89 e5                	mov    %esp,%ebp
  800a76:	83 ec 08             	sub    $0x8,%esp
	return syscall(SYS_cgetc, 0, 0, 0, 0, 0, 0);
  800a79:	6a 00                	push   $0x0
  800a7b:	6a 00                	push   $0x0
  800a7d:	6a 00                	push   $0x0
  800a7f:	6a 00                	push   $0x0
  800a81:	b9 00 00 00 00       	mov    $0x0,%ecx
  800a86:	ba 00 00 00 00       	mov    $0x0,%edx
  800a8b:	b8 01 00 00 00       	mov    $0x1,%eax
  800a90:	e8 6e ff ff ff       	call   800a03 <syscall>
}
  800a95:	c9                   	leave  
  800a96:	c3                   	ret    

00800a97 <sys_env_destroy>:

int
sys_env_destroy(envid_t envid)
{
  800a97:	55                   	push   %ebp
  800a98:	89 e5                	mov    %esp,%ebp
  800a9a:	83 ec 08             	sub    $0x8,%esp
	return syscall(SYS_env_destroy, 1, envid, 0, 0, 0, 0);
  800a9d:	6a 00                	push   $0x0
  800a9f:	6a 00                	push   $0x0
  800aa1:	6a 00                	push   $0x0
  800aa3:	6a 00                	push   $0x0
  800aa5:	8b 4d 08             	mov    0x8(%ebp),%ecx
  800aa8:	ba 01 00 00 00       	mov    $0x1,%edx
  800aad:	b8 03 00 00 00       	mov    $0x3,%eax
  800ab2:	e8 4c ff ff ff       	call   800a03 <syscall>
}
  800ab7:	c9                   	leave  
  800ab8:	c3                   	ret    

00800ab9 <sys_getenvid>:

envid_t
sys_getenvid(void)
{
  800ab9:	55                   	push   %ebp
  800aba:	89 e5                	mov    %esp,%ebp
  800abc:	83 ec 08             	sub    $0x8,%esp
	 return syscall(SYS_getenvid, 0, 0, 0, 0, 0, 0);
  800abf:	6a 00                	push   $0x0
  800ac1:	6a 00                	push   $0x0
  800ac3:	6a 00                	push   $0x0
  800ac5:	6a 00                	push   $0x0
  800ac7:	b9 00 00 00 00       	mov    $0x0,%ecx
  800acc:	ba 00 00 00 00       	mov    $0x0,%edx
  800ad1:	b8 02 00 00 00       	mov    $0x2,%eax
  800ad6:	e8 28 ff ff ff       	call   800a03 <syscall>
}
  800adb:	c9                   	leave  
  800adc:	c3                   	ret    

00800add <sys_yield>:

void
sys_yield(void)
{
  800add:	55                   	push   %ebp
  800ade:	89 e5                	mov    %esp,%ebp
  800ae0:	83 ec 08             	sub    $0x8,%esp
	syscall(SYS_yield, 0, 0, 0, 0, 0, 0);
  800ae3:	6a 00                	push   $0x0
  800ae5:	6a 00                	push   $0x0
  800ae7:	6a 00                	push   $0x0
  800ae9:	6a 00                	push   $0x0
  800aeb:	b9 00 00 00 00       	mov    $0x0,%ecx
  800af0:	ba 00 00 00 00       	mov    $0x0,%edx
  800af5:	b8 0a 00 00 00       	mov    $0xa,%eax
  800afa:	e8 04 ff ff ff       	call   800a03 <syscall>
}
  800aff:	83 c4 10             	add    $0x10,%esp
  800b02:	c9                   	leave  
  800b03:	c3                   	ret    

00800b04 <sys_page_alloc>:

int
sys_page_alloc(envid_t envid, void *va, int perm)
{
  800b04:	55                   	push   %ebp
  800b05:	89 e5                	mov    %esp,%ebp
  800b07:	83 ec 08             	sub    $0x8,%esp
	return syscall(SYS_page_alloc, 1, envid, (uint32_t) va, perm, 0, 0);
  800b0a:	6a 00                	push   $0x0
  800b0c:	6a 00                	push   $0x0
  800b0e:	ff 75 10             	pushl  0x10(%ebp)
  800b11:	ff 75 0c             	pushl  0xc(%ebp)
  800b14:	8b 4d 08             	mov    0x8(%ebp),%ecx
  800b17:	ba 01 00 00 00       	mov    $0x1,%edx
  800b1c:	b8 04 00 00 00       	mov    $0x4,%eax
  800b21:	e8 dd fe ff ff       	call   800a03 <syscall>
}
  800b26:	c9                   	leave  
  800b27:	c3                   	ret    

00800b28 <sys_page_map>:

int
sys_page_map(envid_t srcenv, void *srcva, envid_t dstenv, void *dstva, int perm)
{
  800b28:	55                   	push   %ebp
  800b29:	89 e5                	mov    %esp,%ebp
  800b2b:	83 ec 08             	sub    $0x8,%esp
	return syscall(SYS_page_map, 1, srcenv, (uint32_t) srcva, dstenv, (uint32_t) dstva, perm);
  800b2e:	ff 75 18             	pushl  0x18(%ebp)
  800b31:	ff 75 14             	pushl  0x14(%ebp)
  800b34:	ff 75 10             	pushl  0x10(%ebp)
  800b37:	ff 75 0c             	pushl  0xc(%ebp)
  800b3a:	8b 4d 08             	mov    0x8(%ebp),%ecx
  800b3d:	ba 01 00 00 00       	mov    $0x1,%edx
  800b42:	b8 05 00 00 00       	mov    $0x5,%eax
  800b47:	e8 b7 fe ff ff       	call   800a03 <syscall>
}
  800b4c:	c9                   	leave  
  800b4d:	c3                   	ret    

00800b4e <sys_page_unmap>:

int
sys_page_unmap(envid_t envid, void *va)
{
  800b4e:	55                   	push   %ebp
  800b4f:	89 e5                	mov    %esp,%ebp
  800b51:	83 ec 08             	sub    $0x8,%esp
	return syscall(SYS_page_unmap, 1, envid, (uint32_t) va, 0, 0, 0);
  800b54:	6a 00                	push   $0x0
  800b56:	6a 00                	push   $0x0
  800b58:	6a 00                	push   $0x0
  800b5a:	ff 75 0c             	pushl  0xc(%ebp)
  800b5d:	8b 4d 08             	mov    0x8(%ebp),%ecx
  800b60:	ba 01 00 00 00       	mov    $0x1,%edx
  800b65:	b8 06 00 00 00       	mov    $0x6,%eax
  800b6a:	e8 94 fe ff ff       	call   800a03 <syscall>
}
  800b6f:	c9                   	leave  
  800b70:	c3                   	ret    

00800b71 <sys_env_set_status>:

// sys_exofork is inlined in lib.h

int
sys_env_set_status(envid_t envid, int status)
{
  800b71:	55                   	push   %ebp
  800b72:	89 e5                	mov    %esp,%ebp
  800b74:	83 ec 08             	sub    $0x8,%esp
	return syscall(SYS_env_set_status, 1, envid, status, 0, 0, 0);
  800b77:	6a 00                	push   $0x0
  800b79:	6a 00                	push   $0x0
  800b7b:	6a 00                	push   $0x0
  800b7d:	ff 75 0c             	pushl  0xc(%ebp)
  800b80:	8b 4d 08             	mov    0x8(%ebp),%ecx
  800b83:	ba 01 00 00 00       	mov    $0x1,%edx
  800b88:	b8 08 00 00 00       	mov    $0x8,%eax
  800b8d:	e8 71 fe ff ff       	call   800a03 <syscall>
}
  800b92:	c9                   	leave  
  800b93:	c3                   	ret    

00800b94 <sys_env_set_pgfault_upcall>:

int
sys_env_set_pgfault_upcall(envid_t envid, void *upcall)
{
  800b94:	55                   	push   %ebp
  800b95:	89 e5                	mov    %esp,%ebp
  800b97:	83 ec 08             	sub    $0x8,%esp
	return syscall(SYS_env_set_pgfault_upcall, 1, envid, (uint32_t) upcall, 0, 0, 0);
  800b9a:	6a 00                	push   $0x0
  800b9c:	6a 00                	push   $0x0
  800b9e:	6a 00                	push   $0x0
  800ba0:	ff 75 0c             	pushl  0xc(%ebp)
  800ba3:	8b 4d 08             	mov    0x8(%ebp),%ecx
  800ba6:	ba 01 00 00 00       	mov    $0x1,%edx
  800bab:	b8 09 00 00 00       	mov    $0x9,%eax
  800bb0:	e8 4e fe ff ff       	call   800a03 <syscall>
}
  800bb5:	c9                   	leave  
  800bb6:	c3                   	ret    

00800bb7 <sys_ipc_try_send>:

int
sys_ipc_try_send(envid_t envid, uint32_t value, void *srcva, int perm)
{
  800bb7:	55                   	push   %ebp
  800bb8:	89 e5                	mov    %esp,%ebp
  800bba:	83 ec 08             	sub    $0x8,%esp
	return syscall(SYS_ipc_try_send, 0, envid, value, (uint32_t) srcva, perm, 0);
  800bbd:	6a 00                	push   $0x0
  800bbf:	ff 75 14             	pushl  0x14(%ebp)
  800bc2:	ff 75 10             	pushl  0x10(%ebp)
  800bc5:	ff 75 0c             	pushl  0xc(%ebp)
  800bc8:	8b 4d 08             	mov    0x8(%ebp),%ecx
  800bcb:	ba 00 00 00 00       	mov    $0x0,%edx
  800bd0:	b8 0b 00 00 00       	mov    $0xb,%eax
  800bd5:	e8 29 fe ff ff       	call   800a03 <syscall>
}
  800bda:	c9                   	leave  
  800bdb:	c3                   	ret    

00800bdc <sys_ipc_recv>:

int
sys_ipc_recv(void *dstva)
{
  800bdc:	55                   	push   %ebp
  800bdd:	89 e5                	mov    %esp,%ebp
  800bdf:	83 ec 08             	sub    $0x8,%esp
	return syscall(SYS_ipc_recv, 1, (uint32_t)dstva, 0, 0, 0, 0);
  800be2:	6a 00                	push   $0x0
  800be4:	6a 00                	push   $0x0
  800be6:	6a 00                	push   $0x0
  800be8:	6a 00                	push   $0x0
  800bea:	8b 4d 08             	mov    0x8(%ebp),%ecx
  800bed:	ba 01 00 00 00       	mov    $0x1,%edx
  800bf2:	b8 0c 00 00 00       	mov    $0xc,%eax
  800bf7:	e8 07 fe ff ff       	call   800a03 <syscall>
}
  800bfc:	c9                   	leave  
  800bfd:	c3                   	ret    

00800bfe <_panic>:
 * It prints "panic: <message>", then causes a breakpoint exception,
 * which causes JOS to enter the JOS kernel monitor.
 */
void
_panic(const char *file, int line, const char *fmt, ...)
{
  800bfe:	55                   	push   %ebp
  800bff:	89 e5                	mov    %esp,%ebp
  800c01:	56                   	push   %esi
  800c02:	53                   	push   %ebx
	va_list ap;

	va_start(ap, fmt);
  800c03:	8d 5d 14             	lea    0x14(%ebp),%ebx

	// Print the panic message
	cprintf("[%08x] user panic in %s at %s:%d: ",
  800c06:	8b 35 00 20 80 00    	mov    0x802000,%esi
  800c0c:	e8 a8 fe ff ff       	call   800ab9 <sys_getenvid>
  800c11:	83 ec 0c             	sub    $0xc,%esp
  800c14:	ff 75 0c             	pushl  0xc(%ebp)
  800c17:	ff 75 08             	pushl  0x8(%ebp)
  800c1a:	56                   	push   %esi
  800c1b:	50                   	push   %eax
  800c1c:	68 70 11 80 00       	push   $0x801170
  800c21:	e8 29 f5 ff ff       	call   80014f <cprintf>
		sys_getenvid(), binaryname, file, line);
	vcprintf(fmt, ap);
  800c26:	83 c4 18             	add    $0x18,%esp
  800c29:	53                   	push   %ebx
  800c2a:	ff 75 10             	pushl  0x10(%ebp)
  800c2d:	e8 cc f4 ff ff       	call   8000fe <vcprintf>
	cprintf("\n");
  800c32:	c7 04 24 ec 0e 80 00 	movl   $0x800eec,(%esp)
  800c39:	e8 11 f5 ff ff       	call   80014f <cprintf>
  800c3e:	83 c4 10             	add    $0x10,%esp

	// Cause a breakpoint exception
	while (1)
		asm volatile("int3");
  800c41:	cc                   	int3   
  800c42:	eb fd                	jmp    800c41 <_panic+0x43>
  800c44:	66 90                	xchg   %ax,%ax
  800c46:	66 90                	xchg   %ax,%ax
  800c48:	66 90                	xchg   %ax,%ax
  800c4a:	66 90                	xchg   %ax,%ax
  800c4c:	66 90                	xchg   %ax,%ax
  800c4e:	66 90                	xchg   %ax,%ax

00800c50 <__udivdi3>:
  800c50:	55                   	push   %ebp
  800c51:	57                   	push   %edi
  800c52:	56                   	push   %esi
  800c53:	53                   	push   %ebx
  800c54:	83 ec 1c             	sub    $0x1c,%esp
  800c57:	8b 74 24 3c          	mov    0x3c(%esp),%esi
  800c5b:	8b 5c 24 30          	mov    0x30(%esp),%ebx
  800c5f:	8b 4c 24 34          	mov    0x34(%esp),%ecx
  800c63:	8b 7c 24 38          	mov    0x38(%esp),%edi
  800c67:	85 f6                	test   %esi,%esi
  800c69:	89 5c 24 08          	mov    %ebx,0x8(%esp)
  800c6d:	89 ca                	mov    %ecx,%edx
  800c6f:	89 f8                	mov    %edi,%eax
  800c71:	75 3d                	jne    800cb0 <__udivdi3+0x60>
  800c73:	39 cf                	cmp    %ecx,%edi
  800c75:	0f 87 c5 00 00 00    	ja     800d40 <__udivdi3+0xf0>
  800c7b:	85 ff                	test   %edi,%edi
  800c7d:	89 fd                	mov    %edi,%ebp
  800c7f:	75 0b                	jne    800c8c <__udivdi3+0x3c>
  800c81:	b8 01 00 00 00       	mov    $0x1,%eax
  800c86:	31 d2                	xor    %edx,%edx
  800c88:	f7 f7                	div    %edi
  800c8a:	89 c5                	mov    %eax,%ebp
  800c8c:	89 c8                	mov    %ecx,%eax
  800c8e:	31 d2                	xor    %edx,%edx
  800c90:	f7 f5                	div    %ebp
  800c92:	89 c1                	mov    %eax,%ecx
  800c94:	89 d8                	mov    %ebx,%eax
  800c96:	89 cf                	mov    %ecx,%edi
  800c98:	f7 f5                	div    %ebp
  800c9a:	89 c3                	mov    %eax,%ebx
  800c9c:	89 d8                	mov    %ebx,%eax
  800c9e:	89 fa                	mov    %edi,%edx
  800ca0:	83 c4 1c             	add    $0x1c,%esp
  800ca3:	5b                   	pop    %ebx
  800ca4:	5e                   	pop    %esi
  800ca5:	5f                   	pop    %edi
  800ca6:	5d                   	pop    %ebp
  800ca7:	c3                   	ret    
  800ca8:	90                   	nop
  800ca9:	8d b4 26 00 00 00 00 	lea    0x0(%esi,%eiz,1),%esi
  800cb0:	39 ce                	cmp    %ecx,%esi
  800cb2:	77 74                	ja     800d28 <__udivdi3+0xd8>
  800cb4:	0f bd fe             	bsr    %esi,%edi
  800cb7:	83 f7 1f             	xor    $0x1f,%edi
  800cba:	0f 84 98 00 00 00    	je     800d58 <__udivdi3+0x108>
  800cc0:	bb 20 00 00 00       	mov    $0x20,%ebx
  800cc5:	89 f9                	mov    %edi,%ecx
  800cc7:	89 c5                	mov    %eax,%ebp
  800cc9:	29 fb                	sub    %edi,%ebx
  800ccb:	d3 e6                	shl    %cl,%esi
  800ccd:	89 d9                	mov    %ebx,%ecx
  800ccf:	d3 ed                	shr    %cl,%ebp
  800cd1:	89 f9                	mov    %edi,%ecx
  800cd3:	d3 e0                	shl    %cl,%eax
  800cd5:	09 ee                	or     %ebp,%esi
  800cd7:	89 d9                	mov    %ebx,%ecx
  800cd9:	89 44 24 0c          	mov    %eax,0xc(%esp)
  800cdd:	89 d5                	mov    %edx,%ebp
  800cdf:	8b 44 24 08          	mov    0x8(%esp),%eax
  800ce3:	d3 ed                	shr    %cl,%ebp
  800ce5:	89 f9                	mov    %edi,%ecx
  800ce7:	d3 e2                	shl    %cl,%edx
  800ce9:	89 d9                	mov    %ebx,%ecx
  800ceb:	d3 e8                	shr    %cl,%eax
  800ced:	09 c2                	or     %eax,%edx
  800cef:	89 d0                	mov    %edx,%eax
  800cf1:	89 ea                	mov    %ebp,%edx
  800cf3:	f7 f6                	div    %esi
  800cf5:	89 d5                	mov    %edx,%ebp
  800cf7:	89 c3                	mov    %eax,%ebx
  800cf9:	f7 64 24 0c          	mull   0xc(%esp)
  800cfd:	39 d5                	cmp    %edx,%ebp
  800cff:	72 10                	jb     800d11 <__udivdi3+0xc1>
  800d01:	8b 74 24 08          	mov    0x8(%esp),%esi
  800d05:	89 f9                	mov    %edi,%ecx
  800d07:	d3 e6                	shl    %cl,%esi
  800d09:	39 c6                	cmp    %eax,%esi
  800d0b:	73 07                	jae    800d14 <__udivdi3+0xc4>
  800d0d:	39 d5                	cmp    %edx,%ebp
  800d0f:	75 03                	jne    800d14 <__udivdi3+0xc4>
  800d11:	83 eb 01             	sub    $0x1,%ebx
  800d14:	31 ff                	xor    %edi,%edi
  800d16:	89 d8                	mov    %ebx,%eax
  800d18:	89 fa                	mov    %edi,%edx
  800d1a:	83 c4 1c             	add    $0x1c,%esp
  800d1d:	5b                   	pop    %ebx
  800d1e:	5e                   	pop    %esi
  800d1f:	5f                   	pop    %edi
  800d20:	5d                   	pop    %ebp
  800d21:	c3                   	ret    
  800d22:	8d b6 00 00 00 00    	lea    0x0(%esi),%esi
  800d28:	31 ff                	xor    %edi,%edi
  800d2a:	31 db                	xor    %ebx,%ebx
  800d2c:	89 d8                	mov    %ebx,%eax
  800d2e:	89 fa                	mov    %edi,%edx
  800d30:	83 c4 1c             	add    $0x1c,%esp
  800d33:	5b                   	pop    %ebx
  800d34:	5e                   	pop    %esi
  800d35:	5f                   	pop    %edi
  800d36:	5d                   	pop    %ebp
  800d37:	c3                   	ret    
  800d38:	90                   	nop
  800d39:	8d b4 26 00 00 00 00 	lea    0x0(%esi,%eiz,1),%esi
  800d40:	89 d8                	mov    %ebx,%eax
  800d42:	f7 f7                	div    %edi
  800d44:	31 ff                	xor    %edi,%edi
  800d46:	89 c3                	mov    %eax,%ebx
  800d48:	89 d8                	mov    %ebx,%eax
  800d4a:	89 fa                	mov    %edi,%edx
  800d4c:	83 c4 1c             	add    $0x1c,%esp
  800d4f:	5b                   	pop    %ebx
  800d50:	5e                   	pop    %esi
  800d51:	5f                   	pop    %edi
  800d52:	5d                   	pop    %ebp
  800d53:	c3                   	ret    
  800d54:	8d 74 26 00          	lea    0x0(%esi,%eiz,1),%esi
  800d58:	39 ce                	cmp    %ecx,%esi
  800d5a:	72 0c                	jb     800d68 <__udivdi3+0x118>
  800d5c:	31 db                	xor    %ebx,%ebx
  800d5e:	3b 44 24 08          	cmp    0x8(%esp),%eax
  800d62:	0f 87 34 ff ff ff    	ja     800c9c <__udivdi3+0x4c>
  800d68:	bb 01 00 00 00       	mov    $0x1,%ebx
  800d6d:	e9 2a ff ff ff       	jmp    800c9c <__udivdi3+0x4c>
  800d72:	66 90                	xchg   %ax,%ax
  800d74:	66 90                	xchg   %ax,%ax
  800d76:	66 90                	xchg   %ax,%ax
  800d78:	66 90                	xchg   %ax,%ax
  800d7a:	66 90                	xchg   %ax,%ax
  800d7c:	66 90                	xchg   %ax,%ax
  800d7e:	66 90                	xchg   %ax,%ax

00800d80 <__umoddi3>:
  800d80:	55                   	push   %ebp
  800d81:	57                   	push   %edi
  800d82:	56                   	push   %esi
  800d83:	53                   	push   %ebx
  800d84:	83 ec 1c             	sub    $0x1c,%esp
  800d87:	8b 54 24 3c          	mov    0x3c(%esp),%edx
  800d8b:	8b 4c 24 30          	mov    0x30(%esp),%ecx
  800d8f:	8b 74 24 34          	mov    0x34(%esp),%esi
  800d93:	8b 7c 24 38          	mov    0x38(%esp),%edi
  800d97:	85 d2                	test   %edx,%edx
  800d99:	89 4c 24 0c          	mov    %ecx,0xc(%esp)
  800d9d:	89 4c 24 08          	mov    %ecx,0x8(%esp)
  800da1:	89 f3                	mov    %esi,%ebx
  800da3:	89 3c 24             	mov    %edi,(%esp)
  800da6:	89 74 24 04          	mov    %esi,0x4(%esp)
  800daa:	75 1c                	jne    800dc8 <__umoddi3+0x48>
  800dac:	39 f7                	cmp    %esi,%edi
  800dae:	76 50                	jbe    800e00 <__umoddi3+0x80>
  800db0:	89 c8                	mov    %ecx,%eax
  800db2:	89 f2                	mov    %esi,%edx
  800db4:	f7 f7                	div    %edi
  800db6:	89 d0                	mov    %edx,%eax
  800db8:	31 d2                	xor    %edx,%edx
  800dba:	83 c4 1c             	add    $0x1c,%esp
  800dbd:	5b                   	pop    %ebx
  800dbe:	5e                   	pop    %esi
  800dbf:	5f                   	pop    %edi
  800dc0:	5d                   	pop    %ebp
  800dc1:	c3                   	ret    
  800dc2:	8d b6 00 00 00 00    	lea    0x0(%esi),%esi
  800dc8:	39 f2                	cmp    %esi,%edx
  800dca:	89 d0                	mov    %edx,%eax
  800dcc:	77 52                	ja     800e20 <__umoddi3+0xa0>
  800dce:	0f bd ea             	bsr    %edx,%ebp
  800dd1:	83 f5 1f             	xor    $0x1f,%ebp
  800dd4:	75 5a                	jne    800e30 <__umoddi3+0xb0>
  800dd6:	3b 54 24 04          	cmp    0x4(%esp),%edx
  800dda:	0f 82 e0 00 00 00    	jb     800ec0 <__umoddi3+0x140>
  800de0:	39 0c 24             	cmp    %ecx,(%esp)
  800de3:	0f 86 d7 00 00 00    	jbe    800ec0 <__umoddi3+0x140>
  800de9:	8b 44 24 08          	mov    0x8(%esp),%eax
  800ded:	8b 54 24 04          	mov    0x4(%esp),%edx
  800df1:	83 c4 1c             	add    $0x1c,%esp
  800df4:	5b                   	pop    %ebx
  800df5:	5e                   	pop    %esi
  800df6:	5f                   	pop    %edi
  800df7:	5d                   	pop    %ebp
  800df8:	c3                   	ret    
  800df9:	8d b4 26 00 00 00 00 	lea    0x0(%esi,%eiz,1),%esi
  800e00:	85 ff                	test   %edi,%edi
  800e02:	89 fd                	mov    %edi,%ebp
  800e04:	75 0b                	jne    800e11 <__umoddi3+0x91>
  800e06:	b8 01 00 00 00       	mov    $0x1,%eax
  800e0b:	31 d2                	xor    %edx,%edx
  800e0d:	f7 f7                	div    %edi
  800e0f:	89 c5                	mov    %eax,%ebp
  800e11:	89 f0                	mov    %esi,%eax
  800e13:	31 d2                	xor    %edx,%edx
  800e15:	f7 f5                	div    %ebp
  800e17:	89 c8                	mov    %ecx,%eax
  800e19:	f7 f5                	div    %ebp
  800e1b:	89 d0                	mov    %edx,%eax
  800e1d:	eb 99                	jmp    800db8 <__umoddi3+0x38>
  800e1f:	90                   	nop
  800e20:	89 c8                	mov    %ecx,%eax
  800e22:	89 f2                	mov    %esi,%edx
  800e24:	83 c4 1c             	add    $0x1c,%esp
  800e27:	5b                   	pop    %ebx
  800e28:	5e                   	pop    %esi
  800e29:	5f                   	pop    %edi
  800e2a:	5d                   	pop    %ebp
  800e2b:	c3                   	ret    
  800e2c:	8d 74 26 00          	lea    0x0(%esi,%eiz,1),%esi
  800e30:	8b 34 24             	mov    (%esp),%esi
  800e33:	bf 20 00 00 00       	mov    $0x20,%edi
  800e38:	89 e9                	mov    %ebp,%ecx
  800e3a:	29 ef                	sub    %ebp,%edi
  800e3c:	d3 e0                	shl    %cl,%eax
  800e3e:	89 f9                	mov    %edi,%ecx
  800e40:	89 f2                	mov    %esi,%edx
  800e42:	d3 ea                	shr    %cl,%edx
  800e44:	89 e9                	mov    %ebp,%ecx
  800e46:	09 c2                	or     %eax,%edx
  800e48:	89 d8                	mov    %ebx,%eax
  800e4a:	89 14 24             	mov    %edx,(%esp)
  800e4d:	89 f2                	mov    %esi,%edx
  800e4f:	d3 e2                	shl    %cl,%edx
  800e51:	89 f9                	mov    %edi,%ecx
  800e53:	89 54 24 04          	mov    %edx,0x4(%esp)
  800e57:	8b 54 24 0c          	mov    0xc(%esp),%edx
  800e5b:	d3 e8                	shr    %cl,%eax
  800e5d:	89 e9                	mov    %ebp,%ecx
  800e5f:	89 c6                	mov    %eax,%esi
  800e61:	d3 e3                	shl    %cl,%ebx
  800e63:	89 f9                	mov    %edi,%ecx
  800e65:	89 d0                	mov    %edx,%eax
  800e67:	d3 e8                	shr    %cl,%eax
  800e69:	89 e9                	mov    %ebp,%ecx
  800e6b:	09 d8                	or     %ebx,%eax
  800e6d:	89 d3                	mov    %edx,%ebx
  800e6f:	89 f2                	mov    %esi,%edx
  800e71:	f7 34 24             	divl   (%esp)
  800e74:	89 d6                	mov    %edx,%esi
  800e76:	d3 e3                	shl    %cl,%ebx
  800e78:	f7 64 24 04          	mull   0x4(%esp)
  800e7c:	39 d6                	cmp    %edx,%esi
  800e7e:	89 5c 24 08          	mov    %ebx,0x8(%esp)
  800e82:	89 d1                	mov    %edx,%ecx
  800e84:	89 c3                	mov    %eax,%ebx
  800e86:	72 08                	jb     800e90 <__umoddi3+0x110>
  800e88:	75 11                	jne    800e9b <__umoddi3+0x11b>
  800e8a:	39 44 24 08          	cmp    %eax,0x8(%esp)
  800e8e:	73 0b                	jae    800e9b <__umoddi3+0x11b>
  800e90:	2b 44 24 04          	sub    0x4(%esp),%eax
  800e94:	1b 14 24             	sbb    (%esp),%edx
  800e97:	89 d1                	mov    %edx,%ecx
  800e99:	89 c3                	mov    %eax,%ebx
  800e9b:	8b 54 24 08          	mov    0x8(%esp),%edx
  800e9f:	29 da                	sub    %ebx,%edx
  800ea1:	19 ce                	sbb    %ecx,%esi
  800ea3:	89 f9                	mov    %edi,%ecx
  800ea5:	89 f0                	mov    %esi,%eax
  800ea7:	d3 e0                	shl    %cl,%eax
  800ea9:	89 e9                	mov    %ebp,%ecx
  800eab:	d3 ea                	shr    %cl,%edx
  800ead:	89 e9                	mov    %ebp,%ecx
  800eaf:	d3 ee                	shr    %cl,%esi
  800eb1:	09 d0                	or     %edx,%eax
  800eb3:	89 f2                	mov    %esi,%edx
  800eb5:	83 c4 1c             	add    $0x1c,%esp
  800eb8:	5b                   	pop    %ebx
  800eb9:	5e                   	pop    %esi
  800eba:	5f                   	pop    %edi
  800ebb:	5d                   	pop    %ebp
  800ebc:	c3                   	ret    
  800ebd:	8d 76 00             	lea    0x0(%esi),%esi
  800ec0:	29 f9                	sub    %edi,%ecx
  800ec2:	19 d6                	sbb    %edx,%esi
  800ec4:	89 74 24 04          	mov    %esi,0x4(%esp)
  800ec8:	89 4c 24 08          	mov    %ecx,0x8(%esp)
  800ecc:	e9 18 ff ff ff       	jmp    800de9 <__umoddi3+0x69>
