
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
  800039:	c7 05 04 10 80 00 00 	movl   $0x0,0x801004
  800040:	00 00 00 
	cprintf("1/0 is %08x!\n", 1/zero);
  800043:	b8 01 00 00 00       	mov    $0x1,%eax
  800048:	b9 00 00 00 00       	mov    $0x0,%ecx
  80004d:	99                   	cltd   
  80004e:	f7 f9                	idiv   %ecx
  800050:	50                   	push   %eax
  800051:	68 94 0d 80 00       	push   $0x800d94
  800056:	e8 e0 00 00 00       	call   80013b <cprintf>
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
  800063:	83 ec 08             	sub    $0x8,%esp
  800066:	8b 45 08             	mov    0x8(%ebp),%eax
  800069:	8b 55 0c             	mov    0xc(%ebp),%edx
	// set thisenv to point at our Env structure in envs[].
	// LAB 3: Your code here.
	thisenv = 0;
  80006c:	c7 05 08 10 80 00 00 	movl   $0x0,0x801008
  800073:	00 00 00 

	// save the name of the program so that panic() can use it
	if (argc > 0)
  800076:	85 c0                	test   %eax,%eax
  800078:	7e 08                	jle    800082 <libmain+0x22>
		binaryname = argv[0];
  80007a:	8b 0a                	mov    (%edx),%ecx
  80007c:	89 0d 00 10 80 00    	mov    %ecx,0x801000

	// call user main routine
	umain(argc, argv);
  800082:	83 ec 08             	sub    $0x8,%esp
  800085:	52                   	push   %edx
  800086:	50                   	push   %eax
  800087:	e8 a7 ff ff ff       	call   800033 <umain>

	// exit gracefully
	exit();
  80008c:	e8 05 00 00 00       	call   800096 <exit>
}
  800091:	83 c4 10             	add    $0x10,%esp
  800094:	c9                   	leave  
  800095:	c3                   	ret    

00800096 <exit>:

#include <inc/lib.h>

void
exit(void)
{
  800096:	55                   	push   %ebp
  800097:	89 e5                	mov    %esp,%ebp
  800099:	83 ec 14             	sub    $0x14,%esp
	sys_env_destroy(0);
  80009c:	6a 00                	push   $0x0
  80009e:	e8 e0 09 00 00       	call   800a83 <sys_env_destroy>
}
  8000a3:	83 c4 10             	add    $0x10,%esp
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
  8000ac:	83 ec 04             	sub    $0x4,%esp
  8000af:	8b 5d 0c             	mov    0xc(%ebp),%ebx
	b->buf[b->idx++] = ch;
  8000b2:	8b 13                	mov    (%ebx),%edx
  8000b4:	8d 42 01             	lea    0x1(%edx),%eax
  8000b7:	89 03                	mov    %eax,(%ebx)
  8000b9:	8b 4d 08             	mov    0x8(%ebp),%ecx
  8000bc:	88 4c 13 08          	mov    %cl,0x8(%ebx,%edx,1)
	if (b->idx == 256-1) {
  8000c0:	3d ff 00 00 00       	cmp    $0xff,%eax
  8000c5:	75 1a                	jne    8000e1 <putch+0x39>
		sys_cputs(b->buf, b->idx);
  8000c7:	83 ec 08             	sub    $0x8,%esp
  8000ca:	68 ff 00 00 00       	push   $0xff
  8000cf:	8d 43 08             	lea    0x8(%ebx),%eax
  8000d2:	50                   	push   %eax
  8000d3:	e8 61 09 00 00       	call   800a39 <sys_cputs>
		b->idx = 0;
  8000d8:	c7 03 00 00 00 00    	movl   $0x0,(%ebx)
  8000de:	83 c4 10             	add    $0x10,%esp
	}
	b->cnt++;
  8000e1:	83 43 04 01          	addl   $0x1,0x4(%ebx)
}
  8000e5:	8b 5d fc             	mov    -0x4(%ebp),%ebx
  8000e8:	c9                   	leave  
  8000e9:	c3                   	ret    

008000ea <vcprintf>:

int
vcprintf(const char *fmt, va_list ap)
{
  8000ea:	55                   	push   %ebp
  8000eb:	89 e5                	mov    %esp,%ebp
  8000ed:	81 ec 18 01 00 00    	sub    $0x118,%esp
	struct printbuf b;

	b.idx = 0;
  8000f3:	c7 85 f0 fe ff ff 00 	movl   $0x0,-0x110(%ebp)
  8000fa:	00 00 00 
	b.cnt = 0;
  8000fd:	c7 85 f4 fe ff ff 00 	movl   $0x0,-0x10c(%ebp)
  800104:	00 00 00 
	vprintfmt((void*)putch, &b, fmt, ap);
  800107:	ff 75 0c             	pushl  0xc(%ebp)
  80010a:	ff 75 08             	pushl  0x8(%ebp)
  80010d:	8d 85 f0 fe ff ff    	lea    -0x110(%ebp),%eax
  800113:	50                   	push   %eax
  800114:	68 a8 00 80 00       	push   $0x8000a8
  800119:	e8 86 01 00 00       	call   8002a4 <vprintfmt>
	sys_cputs(b.buf, b.idx);
  80011e:	83 c4 08             	add    $0x8,%esp
  800121:	ff b5 f0 fe ff ff    	pushl  -0x110(%ebp)
  800127:	8d 85 f8 fe ff ff    	lea    -0x108(%ebp),%eax
  80012d:	50                   	push   %eax
  80012e:	e8 06 09 00 00       	call   800a39 <sys_cputs>

	return b.cnt;
}
  800133:	8b 85 f4 fe ff ff    	mov    -0x10c(%ebp),%eax
  800139:	c9                   	leave  
  80013a:	c3                   	ret    

0080013b <cprintf>:

int
cprintf(const char *fmt, ...)
{
  80013b:	55                   	push   %ebp
  80013c:	89 e5                	mov    %esp,%ebp
  80013e:	83 ec 10             	sub    $0x10,%esp
	va_list ap;
	int cnt;

	va_start(ap, fmt);
  800141:	8d 45 0c             	lea    0xc(%ebp),%eax
	cnt = vcprintf(fmt, ap);
  800144:	50                   	push   %eax
  800145:	ff 75 08             	pushl  0x8(%ebp)
  800148:	e8 9d ff ff ff       	call   8000ea <vcprintf>
	va_end(ap);

	return cnt;
}
  80014d:	c9                   	leave  
  80014e:	c3                   	ret    

0080014f <printnum>:
 * using specified putch function and associated pointer putdat.
 */
static void
printnum(void (*putch)(int, void*), void *putdat,
	 unsigned long long num, unsigned base, int width, int padc)
{
  80014f:	55                   	push   %ebp
  800150:	89 e5                	mov    %esp,%ebp
  800152:	57                   	push   %edi
  800153:	56                   	push   %esi
  800154:	53                   	push   %ebx
  800155:	83 ec 1c             	sub    $0x1c,%esp
  800158:	89 c7                	mov    %eax,%edi
  80015a:	89 d6                	mov    %edx,%esi
  80015c:	8b 45 08             	mov    0x8(%ebp),%eax
  80015f:	8b 55 0c             	mov    0xc(%ebp),%edx
  800162:	89 45 d8             	mov    %eax,-0x28(%ebp)
  800165:	89 55 dc             	mov    %edx,-0x24(%ebp)
	// first recursively print all preceding (more significant) digits
	if (num >= base) {
  800168:	8b 4d 10             	mov    0x10(%ebp),%ecx
  80016b:	bb 00 00 00 00       	mov    $0x0,%ebx
  800170:	89 4d e0             	mov    %ecx,-0x20(%ebp)
  800173:	89 5d e4             	mov    %ebx,-0x1c(%ebp)
  800176:	39 d3                	cmp    %edx,%ebx
  800178:	72 05                	jb     80017f <printnum+0x30>
  80017a:	39 45 10             	cmp    %eax,0x10(%ebp)
  80017d:	77 45                	ja     8001c4 <printnum+0x75>
		printnum(putch, putdat, num / base, base, width - 1, padc);
  80017f:	83 ec 0c             	sub    $0xc,%esp
  800182:	ff 75 18             	pushl  0x18(%ebp)
  800185:	8b 45 14             	mov    0x14(%ebp),%eax
  800188:	8d 58 ff             	lea    -0x1(%eax),%ebx
  80018b:	53                   	push   %ebx
  80018c:	ff 75 10             	pushl  0x10(%ebp)
  80018f:	83 ec 08             	sub    $0x8,%esp
  800192:	ff 75 e4             	pushl  -0x1c(%ebp)
  800195:	ff 75 e0             	pushl  -0x20(%ebp)
  800198:	ff 75 dc             	pushl  -0x24(%ebp)
  80019b:	ff 75 d8             	pushl  -0x28(%ebp)
  80019e:	e8 6d 09 00 00       	call   800b10 <__udivdi3>
  8001a3:	83 c4 18             	add    $0x18,%esp
  8001a6:	52                   	push   %edx
  8001a7:	50                   	push   %eax
  8001a8:	89 f2                	mov    %esi,%edx
  8001aa:	89 f8                	mov    %edi,%eax
  8001ac:	e8 9e ff ff ff       	call   80014f <printnum>
  8001b1:	83 c4 20             	add    $0x20,%esp
  8001b4:	eb 18                	jmp    8001ce <printnum+0x7f>
	} else {
		// print any needed pad characters before first digit
		while (--width > 0)
			putch(padc, putdat);
  8001b6:	83 ec 08             	sub    $0x8,%esp
  8001b9:	56                   	push   %esi
  8001ba:	ff 75 18             	pushl  0x18(%ebp)
  8001bd:	ff d7                	call   *%edi
  8001bf:	83 c4 10             	add    $0x10,%esp
  8001c2:	eb 03                	jmp    8001c7 <printnum+0x78>
  8001c4:	8b 5d 14             	mov    0x14(%ebp),%ebx
	// first recursively print all preceding (more significant) digits
	if (num >= base) {
		printnum(putch, putdat, num / base, base, width - 1, padc);
	} else {
		// print any needed pad characters before first digit
		while (--width > 0)
  8001c7:	83 eb 01             	sub    $0x1,%ebx
  8001ca:	85 db                	test   %ebx,%ebx
  8001cc:	7f e8                	jg     8001b6 <printnum+0x67>
			putch(padc, putdat);
	}

	// then print this (the least significant) digit
	putch("0123456789abcdef"[num % base], putdat);
  8001ce:	83 ec 08             	sub    $0x8,%esp
  8001d1:	56                   	push   %esi
  8001d2:	83 ec 04             	sub    $0x4,%esp
  8001d5:	ff 75 e4             	pushl  -0x1c(%ebp)
  8001d8:	ff 75 e0             	pushl  -0x20(%ebp)
  8001db:	ff 75 dc             	pushl  -0x24(%ebp)
  8001de:	ff 75 d8             	pushl  -0x28(%ebp)
  8001e1:	e8 5a 0a 00 00       	call   800c40 <__umoddi3>
  8001e6:	83 c4 14             	add    $0x14,%esp
  8001e9:	0f be 80 ac 0d 80 00 	movsbl 0x800dac(%eax),%eax
  8001f0:	50                   	push   %eax
  8001f1:	ff d7                	call   *%edi
}
  8001f3:	83 c4 10             	add    $0x10,%esp
  8001f6:	8d 65 f4             	lea    -0xc(%ebp),%esp
  8001f9:	5b                   	pop    %ebx
  8001fa:	5e                   	pop    %esi
  8001fb:	5f                   	pop    %edi
  8001fc:	5d                   	pop    %ebp
  8001fd:	c3                   	ret    

008001fe <getuint>:

// Get an unsigned int of various possible sizes from a varargs list,
// depending on the lflag parameter.
static unsigned long long
getuint(va_list *ap, int lflag)
{
  8001fe:	55                   	push   %ebp
  8001ff:	89 e5                	mov    %esp,%ebp
	if (lflag >= 2)
  800201:	83 fa 01             	cmp    $0x1,%edx
  800204:	7e 0e                	jle    800214 <getuint+0x16>
		return va_arg(*ap, unsigned long long);
  800206:	8b 10                	mov    (%eax),%edx
  800208:	8d 4a 08             	lea    0x8(%edx),%ecx
  80020b:	89 08                	mov    %ecx,(%eax)
  80020d:	8b 02                	mov    (%edx),%eax
  80020f:	8b 52 04             	mov    0x4(%edx),%edx
  800212:	eb 22                	jmp    800236 <getuint+0x38>
	else if (lflag)
  800214:	85 d2                	test   %edx,%edx
  800216:	74 10                	je     800228 <getuint+0x2a>
		return va_arg(*ap, unsigned long);
  800218:	8b 10                	mov    (%eax),%edx
  80021a:	8d 4a 04             	lea    0x4(%edx),%ecx
  80021d:	89 08                	mov    %ecx,(%eax)
  80021f:	8b 02                	mov    (%edx),%eax
  800221:	ba 00 00 00 00       	mov    $0x0,%edx
  800226:	eb 0e                	jmp    800236 <getuint+0x38>
	else
		return va_arg(*ap, unsigned int);
  800228:	8b 10                	mov    (%eax),%edx
  80022a:	8d 4a 04             	lea    0x4(%edx),%ecx
  80022d:	89 08                	mov    %ecx,(%eax)
  80022f:	8b 02                	mov    (%edx),%eax
  800231:	ba 00 00 00 00       	mov    $0x0,%edx
}
  800236:	5d                   	pop    %ebp
  800237:	c3                   	ret    

00800238 <getint>:

// Same as getuint but signed - can't use getuint
// because of sign extension
static long long
getint(va_list *ap, int lflag)
{
  800238:	55                   	push   %ebp
  800239:	89 e5                	mov    %esp,%ebp
	if (lflag >= 2)
  80023b:	83 fa 01             	cmp    $0x1,%edx
  80023e:	7e 0e                	jle    80024e <getint+0x16>
		return va_arg(*ap, long long);
  800240:	8b 10                	mov    (%eax),%edx
  800242:	8d 4a 08             	lea    0x8(%edx),%ecx
  800245:	89 08                	mov    %ecx,(%eax)
  800247:	8b 02                	mov    (%edx),%eax
  800249:	8b 52 04             	mov    0x4(%edx),%edx
  80024c:	eb 1a                	jmp    800268 <getint+0x30>
	else if (lflag)
  80024e:	85 d2                	test   %edx,%edx
  800250:	74 0c                	je     80025e <getint+0x26>
		return va_arg(*ap, long);
  800252:	8b 10                	mov    (%eax),%edx
  800254:	8d 4a 04             	lea    0x4(%edx),%ecx
  800257:	89 08                	mov    %ecx,(%eax)
  800259:	8b 02                	mov    (%edx),%eax
  80025b:	99                   	cltd   
  80025c:	eb 0a                	jmp    800268 <getint+0x30>
	else
		return va_arg(*ap, int);
  80025e:	8b 10                	mov    (%eax),%edx
  800260:	8d 4a 04             	lea    0x4(%edx),%ecx
  800263:	89 08                	mov    %ecx,(%eax)
  800265:	8b 02                	mov    (%edx),%eax
  800267:	99                   	cltd   
}
  800268:	5d                   	pop    %ebp
  800269:	c3                   	ret    

0080026a <sprintputch>:
	int cnt;
};

static void
sprintputch(int ch, struct sprintbuf *b)
{
  80026a:	55                   	push   %ebp
  80026b:	89 e5                	mov    %esp,%ebp
  80026d:	8b 45 0c             	mov    0xc(%ebp),%eax
	b->cnt++;
  800270:	83 40 08 01          	addl   $0x1,0x8(%eax)
	if (b->buf < b->ebuf)
  800274:	8b 10                	mov    (%eax),%edx
  800276:	3b 50 04             	cmp    0x4(%eax),%edx
  800279:	73 0a                	jae    800285 <sprintputch+0x1b>
		*b->buf++ = ch;
  80027b:	8d 4a 01             	lea    0x1(%edx),%ecx
  80027e:	89 08                	mov    %ecx,(%eax)
  800280:	8b 45 08             	mov    0x8(%ebp),%eax
  800283:	88 02                	mov    %al,(%edx)
}
  800285:	5d                   	pop    %ebp
  800286:	c3                   	ret    

00800287 <printfmt>:
	}
}

void
printfmt(void (*putch)(int, void*), void *putdat, const char *fmt, ...)
{
  800287:	55                   	push   %ebp
  800288:	89 e5                	mov    %esp,%ebp
  80028a:	83 ec 08             	sub    $0x8,%esp
	va_list ap;

	va_start(ap, fmt);
  80028d:	8d 45 14             	lea    0x14(%ebp),%eax
	vprintfmt(putch, putdat, fmt, ap);
  800290:	50                   	push   %eax
  800291:	ff 75 10             	pushl  0x10(%ebp)
  800294:	ff 75 0c             	pushl  0xc(%ebp)
  800297:	ff 75 08             	pushl  0x8(%ebp)
  80029a:	e8 05 00 00 00       	call   8002a4 <vprintfmt>
	va_end(ap);
}
  80029f:	83 c4 10             	add    $0x10,%esp
  8002a2:	c9                   	leave  
  8002a3:	c3                   	ret    

008002a4 <vprintfmt>:
// Main function to format and print a string.
void printfmt(void (*putch)(int, void*), void *putdat, const char *fmt, ...);

void
vprintfmt(void (*putch)(int, void*), void *putdat, const char *fmt, va_list ap)
{
  8002a4:	55                   	push   %ebp
  8002a5:	89 e5                	mov    %esp,%ebp
  8002a7:	57                   	push   %edi
  8002a8:	56                   	push   %esi
  8002a9:	53                   	push   %ebx
  8002aa:	83 ec 2c             	sub    $0x2c,%esp
  8002ad:	8b 75 08             	mov    0x8(%ebp),%esi
  8002b0:	8b 5d 0c             	mov    0xc(%ebp),%ebx
  8002b3:	8b 7d 10             	mov    0x10(%ebp),%edi
  8002b6:	eb 12                	jmp    8002ca <vprintfmt+0x26>
	int base, lflag, width, precision, altflag;
	char padc;

	while (1) {
		while ((ch = *(unsigned char *) fmt++) != '%') {
			if (ch == '\0')
  8002b8:	85 c0                	test   %eax,%eax
  8002ba:	0f 84 44 03 00 00    	je     800604 <vprintfmt+0x360>
				return;
			putch(ch, putdat);
  8002c0:	83 ec 08             	sub    $0x8,%esp
  8002c3:	53                   	push   %ebx
  8002c4:	50                   	push   %eax
  8002c5:	ff d6                	call   *%esi
  8002c7:	83 c4 10             	add    $0x10,%esp
	unsigned long long num;
	int base, lflag, width, precision, altflag;
	char padc;

	while (1) {
		while ((ch = *(unsigned char *) fmt++) != '%') {
  8002ca:	83 c7 01             	add    $0x1,%edi
  8002cd:	0f b6 47 ff          	movzbl -0x1(%edi),%eax
  8002d1:	83 f8 25             	cmp    $0x25,%eax
  8002d4:	75 e2                	jne    8002b8 <vprintfmt+0x14>
  8002d6:	c6 45 d4 20          	movb   $0x20,-0x2c(%ebp)
  8002da:	c7 45 d8 00 00 00 00 	movl   $0x0,-0x28(%ebp)
  8002e1:	c7 45 d0 ff ff ff ff 	movl   $0xffffffff,-0x30(%ebp)
  8002e8:	c7 45 e0 ff ff ff ff 	movl   $0xffffffff,-0x20(%ebp)
  8002ef:	ba 00 00 00 00       	mov    $0x0,%edx
  8002f4:	eb 07                	jmp    8002fd <vprintfmt+0x59>
		width = -1;
		precision = -1;
		lflag = 0;
		altflag = 0;
	reswitch:
		switch (ch = *(unsigned char *) fmt++) {
  8002f6:	8b 7d e4             	mov    -0x1c(%ebp),%edi

		// flag to pad on the right
		case '-':
			padc = '-';
  8002f9:	c6 45 d4 2d          	movb   $0x2d,-0x2c(%ebp)
		width = -1;
		precision = -1;
		lflag = 0;
		altflag = 0;
	reswitch:
		switch (ch = *(unsigned char *) fmt++) {
  8002fd:	8d 47 01             	lea    0x1(%edi),%eax
  800300:	89 45 e4             	mov    %eax,-0x1c(%ebp)
  800303:	0f b6 07             	movzbl (%edi),%eax
  800306:	0f b6 c8             	movzbl %al,%ecx
  800309:	83 e8 23             	sub    $0x23,%eax
  80030c:	3c 55                	cmp    $0x55,%al
  80030e:	0f 87 d5 02 00 00    	ja     8005e9 <vprintfmt+0x345>
  800314:	0f b6 c0             	movzbl %al,%eax
  800317:	ff 24 85 3c 0e 80 00 	jmp    *0x800e3c(,%eax,4)
  80031e:	8b 7d e4             	mov    -0x1c(%ebp),%edi
			padc = '-';
			goto reswitch;

		// flag to pad with 0's instead of spaces
		case '0':
			padc = '0';
  800321:	c6 45 d4 30          	movb   $0x30,-0x2c(%ebp)
  800325:	eb d6                	jmp    8002fd <vprintfmt+0x59>
		width = -1;
		precision = -1;
		lflag = 0;
		altflag = 0;
	reswitch:
		switch (ch = *(unsigned char *) fmt++) {
  800327:	8b 7d e4             	mov    -0x1c(%ebp),%edi
  80032a:	b8 00 00 00 00       	mov    $0x0,%eax
  80032f:	89 55 e4             	mov    %edx,-0x1c(%ebp)
		case '6':
		case '7':
		case '8':
		case '9':
			for (precision = 0; ; ++fmt) {
				precision = precision * 10 + ch - '0';
  800332:	8d 04 80             	lea    (%eax,%eax,4),%eax
  800335:	8d 44 41 d0          	lea    -0x30(%ecx,%eax,2),%eax
				ch = *fmt;
  800339:	0f be 0f             	movsbl (%edi),%ecx
				if (ch < '0' || ch > '9')
  80033c:	8d 51 d0             	lea    -0x30(%ecx),%edx
  80033f:	83 fa 09             	cmp    $0x9,%edx
  800342:	77 39                	ja     80037d <vprintfmt+0xd9>
		case '5':
		case '6':
		case '7':
		case '8':
		case '9':
			for (precision = 0; ; ++fmt) {
  800344:	83 c7 01             	add    $0x1,%edi
				precision = precision * 10 + ch - '0';
				ch = *fmt;
				if (ch < '0' || ch > '9')
					break;
			}
  800347:	eb e9                	jmp    800332 <vprintfmt+0x8e>
			goto process_precision;

		case '*':
			precision = va_arg(ap, int);
  800349:	8b 45 14             	mov    0x14(%ebp),%eax
  80034c:	8d 48 04             	lea    0x4(%eax),%ecx
  80034f:	89 4d 14             	mov    %ecx,0x14(%ebp)
  800352:	8b 00                	mov    (%eax),%eax
  800354:	89 45 d0             	mov    %eax,-0x30(%ebp)
		width = -1;
		precision = -1;
		lflag = 0;
		altflag = 0;
	reswitch:
		switch (ch = *(unsigned char *) fmt++) {
  800357:	8b 7d e4             	mov    -0x1c(%ebp),%edi
			}
			goto process_precision;

		case '*':
			precision = va_arg(ap, int);
			goto process_precision;
  80035a:	eb 27                	jmp    800383 <vprintfmt+0xdf>
  80035c:	8b 45 e0             	mov    -0x20(%ebp),%eax
  80035f:	85 c0                	test   %eax,%eax
  800361:	b9 00 00 00 00       	mov    $0x0,%ecx
  800366:	0f 49 c8             	cmovns %eax,%ecx
  800369:	89 4d e0             	mov    %ecx,-0x20(%ebp)
		width = -1;
		precision = -1;
		lflag = 0;
		altflag = 0;
	reswitch:
		switch (ch = *(unsigned char *) fmt++) {
  80036c:	8b 7d e4             	mov    -0x1c(%ebp),%edi
  80036f:	eb 8c                	jmp    8002fd <vprintfmt+0x59>
  800371:	8b 7d e4             	mov    -0x1c(%ebp),%edi
			if (width < 0)
				width = 0;
			goto reswitch;

		case '#':
			altflag = 1;
  800374:	c7 45 d8 01 00 00 00 	movl   $0x1,-0x28(%ebp)
			goto reswitch;
  80037b:	eb 80                	jmp    8002fd <vprintfmt+0x59>
  80037d:	8b 55 e4             	mov    -0x1c(%ebp),%edx
  800380:	89 45 d0             	mov    %eax,-0x30(%ebp)

		process_precision:
			if (width < 0)
  800383:	83 7d e0 00          	cmpl   $0x0,-0x20(%ebp)
  800387:	0f 89 70 ff ff ff    	jns    8002fd <vprintfmt+0x59>
				width = precision, precision = -1;
  80038d:	8b 45 d0             	mov    -0x30(%ebp),%eax
  800390:	89 45 e0             	mov    %eax,-0x20(%ebp)
  800393:	c7 45 d0 ff ff ff ff 	movl   $0xffffffff,-0x30(%ebp)
  80039a:	e9 5e ff ff ff       	jmp    8002fd <vprintfmt+0x59>
			goto reswitch;

		// long flag (doubled for long long)
		case 'l':
			lflag++;
  80039f:	83 c2 01             	add    $0x1,%edx
		width = -1;
		precision = -1;
		lflag = 0;
		altflag = 0;
	reswitch:
		switch (ch = *(unsigned char *) fmt++) {
  8003a2:	8b 7d e4             	mov    -0x1c(%ebp),%edi
			goto reswitch;

		// long flag (doubled for long long)
		case 'l':
			lflag++;
			goto reswitch;
  8003a5:	e9 53 ff ff ff       	jmp    8002fd <vprintfmt+0x59>

		// character
		case 'c':
			putch(va_arg(ap, int), putdat);
  8003aa:	8b 45 14             	mov    0x14(%ebp),%eax
  8003ad:	8d 50 04             	lea    0x4(%eax),%edx
  8003b0:	89 55 14             	mov    %edx,0x14(%ebp)
  8003b3:	83 ec 08             	sub    $0x8,%esp
  8003b6:	53                   	push   %ebx
  8003b7:	ff 30                	pushl  (%eax)
  8003b9:	ff d6                	call   *%esi
			break;
  8003bb:	83 c4 10             	add    $0x10,%esp
		width = -1;
		precision = -1;
		lflag = 0;
		altflag = 0;
	reswitch:
		switch (ch = *(unsigned char *) fmt++) {
  8003be:	8b 7d e4             	mov    -0x1c(%ebp),%edi
			goto reswitch;

		// character
		case 'c':
			putch(va_arg(ap, int), putdat);
			break;
  8003c1:	e9 04 ff ff ff       	jmp    8002ca <vprintfmt+0x26>

		// error message
		case 'e':
			err = va_arg(ap, int);
  8003c6:	8b 45 14             	mov    0x14(%ebp),%eax
  8003c9:	8d 50 04             	lea    0x4(%eax),%edx
  8003cc:	89 55 14             	mov    %edx,0x14(%ebp)
  8003cf:	8b 00                	mov    (%eax),%eax
  8003d1:	99                   	cltd   
  8003d2:	31 d0                	xor    %edx,%eax
  8003d4:	29 d0                	sub    %edx,%eax
			if (err < 0)
				err = -err;
			if (err >= MAXERROR || (p = error_string[err]) == NULL)
  8003d6:	83 f8 06             	cmp    $0x6,%eax
  8003d9:	7f 0b                	jg     8003e6 <vprintfmt+0x142>
  8003db:	8b 14 85 94 0f 80 00 	mov    0x800f94(,%eax,4),%edx
  8003e2:	85 d2                	test   %edx,%edx
  8003e4:	75 18                	jne    8003fe <vprintfmt+0x15a>
				printfmt(putch, putdat, "error %d", err);
  8003e6:	50                   	push   %eax
  8003e7:	68 c4 0d 80 00       	push   $0x800dc4
  8003ec:	53                   	push   %ebx
  8003ed:	56                   	push   %esi
  8003ee:	e8 94 fe ff ff       	call   800287 <printfmt>
  8003f3:	83 c4 10             	add    $0x10,%esp
		width = -1;
		precision = -1;
		lflag = 0;
		altflag = 0;
	reswitch:
		switch (ch = *(unsigned char *) fmt++) {
  8003f6:	8b 7d e4             	mov    -0x1c(%ebp),%edi
		case 'e':
			err = va_arg(ap, int);
			if (err < 0)
				err = -err;
			if (err >= MAXERROR || (p = error_string[err]) == NULL)
				printfmt(putch, putdat, "error %d", err);
  8003f9:	e9 cc fe ff ff       	jmp    8002ca <vprintfmt+0x26>
			else
				printfmt(putch, putdat, "%s", p);
  8003fe:	52                   	push   %edx
  8003ff:	68 cd 0d 80 00       	push   $0x800dcd
  800404:	53                   	push   %ebx
  800405:	56                   	push   %esi
  800406:	e8 7c fe ff ff       	call   800287 <printfmt>
  80040b:	83 c4 10             	add    $0x10,%esp
		width = -1;
		precision = -1;
		lflag = 0;
		altflag = 0;
	reswitch:
		switch (ch = *(unsigned char *) fmt++) {
  80040e:	8b 7d e4             	mov    -0x1c(%ebp),%edi
  800411:	e9 b4 fe ff ff       	jmp    8002ca <vprintfmt+0x26>
				printfmt(putch, putdat, "%s", p);
			break;

		// string
		case 's':
			if ((p = va_arg(ap, char *)) == NULL)
  800416:	8b 45 14             	mov    0x14(%ebp),%eax
  800419:	8d 50 04             	lea    0x4(%eax),%edx
  80041c:	89 55 14             	mov    %edx,0x14(%ebp)
  80041f:	8b 38                	mov    (%eax),%edi
				p = "(null)";
  800421:	85 ff                	test   %edi,%edi
  800423:	b8 bd 0d 80 00       	mov    $0x800dbd,%eax
  800428:	0f 44 f8             	cmove  %eax,%edi
			if (width > 0 && padc != '-')
  80042b:	83 7d e0 00          	cmpl   $0x0,-0x20(%ebp)
  80042f:	0f 8e 94 00 00 00    	jle    8004c9 <vprintfmt+0x225>
  800435:	80 7d d4 2d          	cmpb   $0x2d,-0x2c(%ebp)
  800439:	0f 84 98 00 00 00    	je     8004d7 <vprintfmt+0x233>
				for (width -= strnlen(p, precision); width > 0; width--)
  80043f:	83 ec 08             	sub    $0x8,%esp
  800442:	ff 75 d0             	pushl  -0x30(%ebp)
  800445:	57                   	push   %edi
  800446:	e8 41 02 00 00       	call   80068c <strnlen>
  80044b:	8b 4d e0             	mov    -0x20(%ebp),%ecx
  80044e:	29 c1                	sub    %eax,%ecx
  800450:	89 4d cc             	mov    %ecx,-0x34(%ebp)
  800453:	83 c4 10             	add    $0x10,%esp
					putch(padc, putdat);
  800456:	0f be 45 d4          	movsbl -0x2c(%ebp),%eax
  80045a:	89 45 e0             	mov    %eax,-0x20(%ebp)
  80045d:	89 7d d4             	mov    %edi,-0x2c(%ebp)
  800460:	89 cf                	mov    %ecx,%edi
		// string
		case 's':
			if ((p = va_arg(ap, char *)) == NULL)
				p = "(null)";
			if (width > 0 && padc != '-')
				for (width -= strnlen(p, precision); width > 0; width--)
  800462:	eb 0f                	jmp    800473 <vprintfmt+0x1cf>
					putch(padc, putdat);
  800464:	83 ec 08             	sub    $0x8,%esp
  800467:	53                   	push   %ebx
  800468:	ff 75 e0             	pushl  -0x20(%ebp)
  80046b:	ff d6                	call   *%esi
		// string
		case 's':
			if ((p = va_arg(ap, char *)) == NULL)
				p = "(null)";
			if (width > 0 && padc != '-')
				for (width -= strnlen(p, precision); width > 0; width--)
  80046d:	83 ef 01             	sub    $0x1,%edi
  800470:	83 c4 10             	add    $0x10,%esp
  800473:	85 ff                	test   %edi,%edi
  800475:	7f ed                	jg     800464 <vprintfmt+0x1c0>
  800477:	8b 7d d4             	mov    -0x2c(%ebp),%edi
  80047a:	8b 4d cc             	mov    -0x34(%ebp),%ecx
  80047d:	85 c9                	test   %ecx,%ecx
  80047f:	b8 00 00 00 00       	mov    $0x0,%eax
  800484:	0f 49 c1             	cmovns %ecx,%eax
  800487:	29 c1                	sub    %eax,%ecx
  800489:	89 75 08             	mov    %esi,0x8(%ebp)
  80048c:	8b 75 d0             	mov    -0x30(%ebp),%esi
  80048f:	89 5d 0c             	mov    %ebx,0xc(%ebp)
  800492:	89 cb                	mov    %ecx,%ebx
  800494:	eb 4d                	jmp    8004e3 <vprintfmt+0x23f>
					putch(padc, putdat);
			for (; (ch = *p++) != '\0' && (precision < 0 || --precision >= 0); width--)
				if (altflag && (ch < ' ' || ch > '~'))
  800496:	83 7d d8 00          	cmpl   $0x0,-0x28(%ebp)
  80049a:	74 1b                	je     8004b7 <vprintfmt+0x213>
  80049c:	0f be c0             	movsbl %al,%eax
  80049f:	83 e8 20             	sub    $0x20,%eax
  8004a2:	83 f8 5e             	cmp    $0x5e,%eax
  8004a5:	76 10                	jbe    8004b7 <vprintfmt+0x213>
					putch('?', putdat);
  8004a7:	83 ec 08             	sub    $0x8,%esp
  8004aa:	ff 75 0c             	pushl  0xc(%ebp)
  8004ad:	6a 3f                	push   $0x3f
  8004af:	ff 55 08             	call   *0x8(%ebp)
  8004b2:	83 c4 10             	add    $0x10,%esp
  8004b5:	eb 0d                	jmp    8004c4 <vprintfmt+0x220>
				else
					putch(ch, putdat);
  8004b7:	83 ec 08             	sub    $0x8,%esp
  8004ba:	ff 75 0c             	pushl  0xc(%ebp)
  8004bd:	52                   	push   %edx
  8004be:	ff 55 08             	call   *0x8(%ebp)
  8004c1:	83 c4 10             	add    $0x10,%esp
			if ((p = va_arg(ap, char *)) == NULL)
				p = "(null)";
			if (width > 0 && padc != '-')
				for (width -= strnlen(p, precision); width > 0; width--)
					putch(padc, putdat);
			for (; (ch = *p++) != '\0' && (precision < 0 || --precision >= 0); width--)
  8004c4:	83 eb 01             	sub    $0x1,%ebx
  8004c7:	eb 1a                	jmp    8004e3 <vprintfmt+0x23f>
  8004c9:	89 75 08             	mov    %esi,0x8(%ebp)
  8004cc:	8b 75 d0             	mov    -0x30(%ebp),%esi
  8004cf:	89 5d 0c             	mov    %ebx,0xc(%ebp)
  8004d2:	8b 5d e0             	mov    -0x20(%ebp),%ebx
  8004d5:	eb 0c                	jmp    8004e3 <vprintfmt+0x23f>
  8004d7:	89 75 08             	mov    %esi,0x8(%ebp)
  8004da:	8b 75 d0             	mov    -0x30(%ebp),%esi
  8004dd:	89 5d 0c             	mov    %ebx,0xc(%ebp)
  8004e0:	8b 5d e0             	mov    -0x20(%ebp),%ebx
  8004e3:	83 c7 01             	add    $0x1,%edi
  8004e6:	0f b6 47 ff          	movzbl -0x1(%edi),%eax
  8004ea:	0f be d0             	movsbl %al,%edx
  8004ed:	85 d2                	test   %edx,%edx
  8004ef:	74 23                	je     800514 <vprintfmt+0x270>
  8004f1:	85 f6                	test   %esi,%esi
  8004f3:	78 a1                	js     800496 <vprintfmt+0x1f2>
  8004f5:	83 ee 01             	sub    $0x1,%esi
  8004f8:	79 9c                	jns    800496 <vprintfmt+0x1f2>
  8004fa:	89 df                	mov    %ebx,%edi
  8004fc:	8b 75 08             	mov    0x8(%ebp),%esi
  8004ff:	8b 5d 0c             	mov    0xc(%ebp),%ebx
  800502:	eb 18                	jmp    80051c <vprintfmt+0x278>
				if (altflag && (ch < ' ' || ch > '~'))
					putch('?', putdat);
				else
					putch(ch, putdat);
			for (; width > 0; width--)
				putch(' ', putdat);
  800504:	83 ec 08             	sub    $0x8,%esp
  800507:	53                   	push   %ebx
  800508:	6a 20                	push   $0x20
  80050a:	ff d6                	call   *%esi
			for (; (ch = *p++) != '\0' && (precision < 0 || --precision >= 0); width--)
				if (altflag && (ch < ' ' || ch > '~'))
					putch('?', putdat);
				else
					putch(ch, putdat);
			for (; width > 0; width--)
  80050c:	83 ef 01             	sub    $0x1,%edi
  80050f:	83 c4 10             	add    $0x10,%esp
  800512:	eb 08                	jmp    80051c <vprintfmt+0x278>
  800514:	89 df                	mov    %ebx,%edi
  800516:	8b 75 08             	mov    0x8(%ebp),%esi
  800519:	8b 5d 0c             	mov    0xc(%ebp),%ebx
  80051c:	85 ff                	test   %edi,%edi
  80051e:	7f e4                	jg     800504 <vprintfmt+0x260>
		width = -1;
		precision = -1;
		lflag = 0;
		altflag = 0;
	reswitch:
		switch (ch = *(unsigned char *) fmt++) {
  800520:	8b 7d e4             	mov    -0x1c(%ebp),%edi
  800523:	e9 a2 fd ff ff       	jmp    8002ca <vprintfmt+0x26>
				putch(' ', putdat);
			break;

		// (signed) decimal
		case 'd':
			num = getint(&ap, lflag);
  800528:	8d 45 14             	lea    0x14(%ebp),%eax
  80052b:	e8 08 fd ff ff       	call   800238 <getint>
  800530:	89 45 d8             	mov    %eax,-0x28(%ebp)
  800533:	89 55 dc             	mov    %edx,-0x24(%ebp)
			if ((long long) num < 0) {
				putch('-', putdat);
				num = -(long long) num;
			}
			base = 10;
  800536:	b9 0a 00 00 00       	mov    $0xa,%ecx
			break;

		// (signed) decimal
		case 'd':
			num = getint(&ap, lflag);
			if ((long long) num < 0) {
  80053b:	83 7d dc 00          	cmpl   $0x0,-0x24(%ebp)
  80053f:	79 74                	jns    8005b5 <vprintfmt+0x311>
				putch('-', putdat);
  800541:	83 ec 08             	sub    $0x8,%esp
  800544:	53                   	push   %ebx
  800545:	6a 2d                	push   $0x2d
  800547:	ff d6                	call   *%esi
				num = -(long long) num;
  800549:	8b 45 d8             	mov    -0x28(%ebp),%eax
  80054c:	8b 55 dc             	mov    -0x24(%ebp),%edx
  80054f:	f7 d8                	neg    %eax
  800551:	83 d2 00             	adc    $0x0,%edx
  800554:	f7 da                	neg    %edx
  800556:	83 c4 10             	add    $0x10,%esp
			}
			base = 10;
  800559:	b9 0a 00 00 00       	mov    $0xa,%ecx
  80055e:	eb 55                	jmp    8005b5 <vprintfmt+0x311>
			goto number;

		// unsigned decimal
		case 'u':
			num = getuint(&ap, lflag);
  800560:	8d 45 14             	lea    0x14(%ebp),%eax
  800563:	e8 96 fc ff ff       	call   8001fe <getuint>
			base = 10;
  800568:	b9 0a 00 00 00       	mov    $0xa,%ecx
			goto number;
  80056d:	eb 46                	jmp    8005b5 <vprintfmt+0x311>

		// (unsigned) octal
		case 'o':
			num = getuint(&ap, lflag);
  80056f:	8d 45 14             	lea    0x14(%ebp),%eax
  800572:	e8 87 fc ff ff       	call   8001fe <getuint>
			base = 8;
  800577:	b9 08 00 00 00       	mov    $0x8,%ecx
			goto number;
  80057c:	eb 37                	jmp    8005b5 <vprintfmt+0x311>

		// pointer
		case 'p':
			putch('0', putdat);
  80057e:	83 ec 08             	sub    $0x8,%esp
  800581:	53                   	push   %ebx
  800582:	6a 30                	push   $0x30
  800584:	ff d6                	call   *%esi
			putch('x', putdat);
  800586:	83 c4 08             	add    $0x8,%esp
  800589:	53                   	push   %ebx
  80058a:	6a 78                	push   $0x78
  80058c:	ff d6                	call   *%esi
			num = (unsigned long long)
				(uintptr_t) va_arg(ap, void *);
  80058e:	8b 45 14             	mov    0x14(%ebp),%eax
  800591:	8d 50 04             	lea    0x4(%eax),%edx
  800594:	89 55 14             	mov    %edx,0x14(%ebp)

		// pointer
		case 'p':
			putch('0', putdat);
			putch('x', putdat);
			num = (unsigned long long)
  800597:	8b 00                	mov    (%eax),%eax
  800599:	ba 00 00 00 00       	mov    $0x0,%edx
				(uintptr_t) va_arg(ap, void *);
			base = 16;
			goto number;
  80059e:	83 c4 10             	add    $0x10,%esp
		case 'p':
			putch('0', putdat);
			putch('x', putdat);
			num = (unsigned long long)
				(uintptr_t) va_arg(ap, void *);
			base = 16;
  8005a1:	b9 10 00 00 00       	mov    $0x10,%ecx
			goto number;
  8005a6:	eb 0d                	jmp    8005b5 <vprintfmt+0x311>

		// (unsigned) hexadecimal
		case 'x':
			num = getuint(&ap, lflag);
  8005a8:	8d 45 14             	lea    0x14(%ebp),%eax
  8005ab:	e8 4e fc ff ff       	call   8001fe <getuint>
			base = 16;
  8005b0:	b9 10 00 00 00       	mov    $0x10,%ecx
		number:
			printnum(putch, putdat, num, base, width, padc);
  8005b5:	83 ec 0c             	sub    $0xc,%esp
  8005b8:	0f be 7d d4          	movsbl -0x2c(%ebp),%edi
  8005bc:	57                   	push   %edi
  8005bd:	ff 75 e0             	pushl  -0x20(%ebp)
  8005c0:	51                   	push   %ecx
  8005c1:	52                   	push   %edx
  8005c2:	50                   	push   %eax
  8005c3:	89 da                	mov    %ebx,%edx
  8005c5:	89 f0                	mov    %esi,%eax
  8005c7:	e8 83 fb ff ff       	call   80014f <printnum>
			break;
  8005cc:	83 c4 20             	add    $0x20,%esp
  8005cf:	8b 7d e4             	mov    -0x1c(%ebp),%edi
  8005d2:	e9 f3 fc ff ff       	jmp    8002ca <vprintfmt+0x26>

		// escaped '%' character
		case '%':
			putch(ch, putdat);
  8005d7:	83 ec 08             	sub    $0x8,%esp
  8005da:	53                   	push   %ebx
  8005db:	51                   	push   %ecx
  8005dc:	ff d6                	call   *%esi
			break;
  8005de:	83 c4 10             	add    $0x10,%esp
		width = -1;
		precision = -1;
		lflag = 0;
		altflag = 0;
	reswitch:
		switch (ch = *(unsigned char *) fmt++) {
  8005e1:	8b 7d e4             	mov    -0x1c(%ebp),%edi
			break;

		// escaped '%' character
		case '%':
			putch(ch, putdat);
			break;
  8005e4:	e9 e1 fc ff ff       	jmp    8002ca <vprintfmt+0x26>

		// unrecognized escape sequence - just print it literally
		default:
			putch('%', putdat);
  8005e9:	83 ec 08             	sub    $0x8,%esp
  8005ec:	53                   	push   %ebx
  8005ed:	6a 25                	push   $0x25
  8005ef:	ff d6                	call   *%esi
			for (fmt--; fmt[-1] != '%'; fmt--)
  8005f1:	83 c4 10             	add    $0x10,%esp
  8005f4:	eb 03                	jmp    8005f9 <vprintfmt+0x355>
  8005f6:	83 ef 01             	sub    $0x1,%edi
  8005f9:	80 7f ff 25          	cmpb   $0x25,-0x1(%edi)
  8005fd:	75 f7                	jne    8005f6 <vprintfmt+0x352>
  8005ff:	e9 c6 fc ff ff       	jmp    8002ca <vprintfmt+0x26>
				/* do nothing */;
			break;
		}
	}
}
  800604:	8d 65 f4             	lea    -0xc(%ebp),%esp
  800607:	5b                   	pop    %ebx
  800608:	5e                   	pop    %esi
  800609:	5f                   	pop    %edi
  80060a:	5d                   	pop    %ebp
  80060b:	c3                   	ret    

0080060c <vsnprintf>:
		*b->buf++ = ch;
}

int
vsnprintf(char *buf, int n, const char *fmt, va_list ap)
{
  80060c:	55                   	push   %ebp
  80060d:	89 e5                	mov    %esp,%ebp
  80060f:	83 ec 18             	sub    $0x18,%esp
  800612:	8b 45 08             	mov    0x8(%ebp),%eax
  800615:	8b 55 0c             	mov    0xc(%ebp),%edx
	struct sprintbuf b = {buf, buf+n-1, 0};
  800618:	89 45 ec             	mov    %eax,-0x14(%ebp)
  80061b:	8d 4c 10 ff          	lea    -0x1(%eax,%edx,1),%ecx
  80061f:	89 4d f0             	mov    %ecx,-0x10(%ebp)
  800622:	c7 45 f4 00 00 00 00 	movl   $0x0,-0xc(%ebp)

	if (buf == NULL || n < 1)
  800629:	85 c0                	test   %eax,%eax
  80062b:	74 26                	je     800653 <vsnprintf+0x47>
  80062d:	85 d2                	test   %edx,%edx
  80062f:	7e 22                	jle    800653 <vsnprintf+0x47>
		return -E_INVAL;

	// print the string to the buffer
	vprintfmt((void*)sprintputch, &b, fmt, ap);
  800631:	ff 75 14             	pushl  0x14(%ebp)
  800634:	ff 75 10             	pushl  0x10(%ebp)
  800637:	8d 45 ec             	lea    -0x14(%ebp),%eax
  80063a:	50                   	push   %eax
  80063b:	68 6a 02 80 00       	push   $0x80026a
  800640:	e8 5f fc ff ff       	call   8002a4 <vprintfmt>

	// null terminate the buffer
	*b.buf = '\0';
  800645:	8b 45 ec             	mov    -0x14(%ebp),%eax
  800648:	c6 00 00             	movb   $0x0,(%eax)

	return b.cnt;
  80064b:	8b 45 f4             	mov    -0xc(%ebp),%eax
  80064e:	83 c4 10             	add    $0x10,%esp
  800651:	eb 05                	jmp    800658 <vsnprintf+0x4c>
vsnprintf(char *buf, int n, const char *fmt, va_list ap)
{
	struct sprintbuf b = {buf, buf+n-1, 0};

	if (buf == NULL || n < 1)
		return -E_INVAL;
  800653:	b8 fd ff ff ff       	mov    $0xfffffffd,%eax

	// null terminate the buffer
	*b.buf = '\0';

	return b.cnt;
}
  800658:	c9                   	leave  
  800659:	c3                   	ret    

0080065a <snprintf>:

int
snprintf(char *buf, int n, const char *fmt, ...)
{
  80065a:	55                   	push   %ebp
  80065b:	89 e5                	mov    %esp,%ebp
  80065d:	83 ec 08             	sub    $0x8,%esp
	va_list ap;
	int rc;

	va_start(ap, fmt);
  800660:	8d 45 14             	lea    0x14(%ebp),%eax
	rc = vsnprintf(buf, n, fmt, ap);
  800663:	50                   	push   %eax
  800664:	ff 75 10             	pushl  0x10(%ebp)
  800667:	ff 75 0c             	pushl  0xc(%ebp)
  80066a:	ff 75 08             	pushl  0x8(%ebp)
  80066d:	e8 9a ff ff ff       	call   80060c <vsnprintf>
	va_end(ap);

	return rc;
}
  800672:	c9                   	leave  
  800673:	c3                   	ret    

00800674 <strlen>:
// Primespipe runs 3x faster this way.
#define ASM 1

int
strlen(const char *s)
{
  800674:	55                   	push   %ebp
  800675:	89 e5                	mov    %esp,%ebp
  800677:	8b 55 08             	mov    0x8(%ebp),%edx
	int n;

	for (n = 0; *s != '\0'; s++)
  80067a:	b8 00 00 00 00       	mov    $0x0,%eax
  80067f:	eb 03                	jmp    800684 <strlen+0x10>
		n++;
  800681:	83 c0 01             	add    $0x1,%eax
int
strlen(const char *s)
{
	int n;

	for (n = 0; *s != '\0'; s++)
  800684:	80 3c 02 00          	cmpb   $0x0,(%edx,%eax,1)
  800688:	75 f7                	jne    800681 <strlen+0xd>
		n++;
	return n;
}
  80068a:	5d                   	pop    %ebp
  80068b:	c3                   	ret    

0080068c <strnlen>:

int
strnlen(const char *s, size_t size)
{
  80068c:	55                   	push   %ebp
  80068d:	89 e5                	mov    %esp,%ebp
  80068f:	8b 4d 08             	mov    0x8(%ebp),%ecx
  800692:	8b 45 0c             	mov    0xc(%ebp),%eax
	int n;

	for (n = 0; size > 0 && *s != '\0'; s++, size--)
  800695:	ba 00 00 00 00       	mov    $0x0,%edx
  80069a:	eb 03                	jmp    80069f <strnlen+0x13>
		n++;
  80069c:	83 c2 01             	add    $0x1,%edx
int
strnlen(const char *s, size_t size)
{
	int n;

	for (n = 0; size > 0 && *s != '\0'; s++, size--)
  80069f:	39 c2                	cmp    %eax,%edx
  8006a1:	74 08                	je     8006ab <strnlen+0x1f>
  8006a3:	80 3c 11 00          	cmpb   $0x0,(%ecx,%edx,1)
  8006a7:	75 f3                	jne    80069c <strnlen+0x10>
  8006a9:	89 d0                	mov    %edx,%eax
		n++;
	return n;
}
  8006ab:	5d                   	pop    %ebp
  8006ac:	c3                   	ret    

008006ad <strcpy>:

char *
strcpy(char *dst, const char *src)
{
  8006ad:	55                   	push   %ebp
  8006ae:	89 e5                	mov    %esp,%ebp
  8006b0:	53                   	push   %ebx
  8006b1:	8b 45 08             	mov    0x8(%ebp),%eax
  8006b4:	8b 4d 0c             	mov    0xc(%ebp),%ecx
	char *ret;

	ret = dst;
	while ((*dst++ = *src++) != '\0')
  8006b7:	89 c2                	mov    %eax,%edx
  8006b9:	83 c2 01             	add    $0x1,%edx
  8006bc:	83 c1 01             	add    $0x1,%ecx
  8006bf:	0f b6 59 ff          	movzbl -0x1(%ecx),%ebx
  8006c3:	88 5a ff             	mov    %bl,-0x1(%edx)
  8006c6:	84 db                	test   %bl,%bl
  8006c8:	75 ef                	jne    8006b9 <strcpy+0xc>
		/* do nothing */;
	return ret;
}
  8006ca:	5b                   	pop    %ebx
  8006cb:	5d                   	pop    %ebp
  8006cc:	c3                   	ret    

008006cd <strcat>:

char *
strcat(char *dst, const char *src)
{
  8006cd:	55                   	push   %ebp
  8006ce:	89 e5                	mov    %esp,%ebp
  8006d0:	53                   	push   %ebx
  8006d1:	8b 5d 08             	mov    0x8(%ebp),%ebx
	int len = strlen(dst);
  8006d4:	53                   	push   %ebx
  8006d5:	e8 9a ff ff ff       	call   800674 <strlen>
  8006da:	83 c4 04             	add    $0x4,%esp
	strcpy(dst + len, src);
  8006dd:	ff 75 0c             	pushl  0xc(%ebp)
  8006e0:	01 d8                	add    %ebx,%eax
  8006e2:	50                   	push   %eax
  8006e3:	e8 c5 ff ff ff       	call   8006ad <strcpy>
	return dst;
}
  8006e8:	89 d8                	mov    %ebx,%eax
  8006ea:	8b 5d fc             	mov    -0x4(%ebp),%ebx
  8006ed:	c9                   	leave  
  8006ee:	c3                   	ret    

008006ef <strncpy>:

char *
strncpy(char *dst, const char *src, size_t size) {
  8006ef:	55                   	push   %ebp
  8006f0:	89 e5                	mov    %esp,%ebp
  8006f2:	56                   	push   %esi
  8006f3:	53                   	push   %ebx
  8006f4:	8b 75 08             	mov    0x8(%ebp),%esi
  8006f7:	8b 4d 0c             	mov    0xc(%ebp),%ecx
  8006fa:	89 f3                	mov    %esi,%ebx
  8006fc:	03 5d 10             	add    0x10(%ebp),%ebx
	size_t i;
	char *ret;

	ret = dst;
	for (i = 0; i < size; i++) {
  8006ff:	89 f2                	mov    %esi,%edx
  800701:	eb 0f                	jmp    800712 <strncpy+0x23>
		*dst++ = *src;
  800703:	83 c2 01             	add    $0x1,%edx
  800706:	0f b6 01             	movzbl (%ecx),%eax
  800709:	88 42 ff             	mov    %al,-0x1(%edx)
		// If strlen(src) < size, null-pad 'dst' out to 'size' chars
		if (*src != '\0')
			src++;
  80070c:	80 39 01             	cmpb   $0x1,(%ecx)
  80070f:	83 d9 ff             	sbb    $0xffffffff,%ecx
strncpy(char *dst, const char *src, size_t size) {
	size_t i;
	char *ret;

	ret = dst;
	for (i = 0; i < size; i++) {
  800712:	39 da                	cmp    %ebx,%edx
  800714:	75 ed                	jne    800703 <strncpy+0x14>
		// If strlen(src) < size, null-pad 'dst' out to 'size' chars
		if (*src != '\0')
			src++;
	}
	return ret;
}
  800716:	89 f0                	mov    %esi,%eax
  800718:	5b                   	pop    %ebx
  800719:	5e                   	pop    %esi
  80071a:	5d                   	pop    %ebp
  80071b:	c3                   	ret    

0080071c <strlcpy>:

size_t
strlcpy(char *dst, const char *src, size_t size)
{
  80071c:	55                   	push   %ebp
  80071d:	89 e5                	mov    %esp,%ebp
  80071f:	56                   	push   %esi
  800720:	53                   	push   %ebx
  800721:	8b 75 08             	mov    0x8(%ebp),%esi
  800724:	8b 4d 0c             	mov    0xc(%ebp),%ecx
  800727:	8b 55 10             	mov    0x10(%ebp),%edx
  80072a:	89 f0                	mov    %esi,%eax
	char *dst_in;

	dst_in = dst;
	if (size > 0) {
  80072c:	85 d2                	test   %edx,%edx
  80072e:	74 21                	je     800751 <strlcpy+0x35>
  800730:	8d 44 16 ff          	lea    -0x1(%esi,%edx,1),%eax
  800734:	89 f2                	mov    %esi,%edx
  800736:	eb 09                	jmp    800741 <strlcpy+0x25>
		while (--size > 0 && *src != '\0')
			*dst++ = *src++;
  800738:	83 c2 01             	add    $0x1,%edx
  80073b:	83 c1 01             	add    $0x1,%ecx
  80073e:	88 5a ff             	mov    %bl,-0x1(%edx)
{
	char *dst_in;

	dst_in = dst;
	if (size > 0) {
		while (--size > 0 && *src != '\0')
  800741:	39 c2                	cmp    %eax,%edx
  800743:	74 09                	je     80074e <strlcpy+0x32>
  800745:	0f b6 19             	movzbl (%ecx),%ebx
  800748:	84 db                	test   %bl,%bl
  80074a:	75 ec                	jne    800738 <strlcpy+0x1c>
  80074c:	89 d0                	mov    %edx,%eax
			*dst++ = *src++;
		*dst = '\0';
  80074e:	c6 00 00             	movb   $0x0,(%eax)
	}
	return dst - dst_in;
  800751:	29 f0                	sub    %esi,%eax
}
  800753:	5b                   	pop    %ebx
  800754:	5e                   	pop    %esi
  800755:	5d                   	pop    %ebp
  800756:	c3                   	ret    

00800757 <strcmp>:

int
strcmp(const char *p, const char *q)
{
  800757:	55                   	push   %ebp
  800758:	89 e5                	mov    %esp,%ebp
  80075a:	8b 4d 08             	mov    0x8(%ebp),%ecx
  80075d:	8b 55 0c             	mov    0xc(%ebp),%edx
	while (*p && *p == *q)
  800760:	eb 06                	jmp    800768 <strcmp+0x11>
		p++, q++;
  800762:	83 c1 01             	add    $0x1,%ecx
  800765:	83 c2 01             	add    $0x1,%edx
}

int
strcmp(const char *p, const char *q)
{
	while (*p && *p == *q)
  800768:	0f b6 01             	movzbl (%ecx),%eax
  80076b:	84 c0                	test   %al,%al
  80076d:	74 04                	je     800773 <strcmp+0x1c>
  80076f:	3a 02                	cmp    (%edx),%al
  800771:	74 ef                	je     800762 <strcmp+0xb>
		p++, q++;
	return (int) ((unsigned char) *p - (unsigned char) *q);
  800773:	0f b6 c0             	movzbl %al,%eax
  800776:	0f b6 12             	movzbl (%edx),%edx
  800779:	29 d0                	sub    %edx,%eax
}
  80077b:	5d                   	pop    %ebp
  80077c:	c3                   	ret    

0080077d <strncmp>:

int
strncmp(const char *p, const char *q, size_t n)
{
  80077d:	55                   	push   %ebp
  80077e:	89 e5                	mov    %esp,%ebp
  800780:	53                   	push   %ebx
  800781:	8b 45 08             	mov    0x8(%ebp),%eax
  800784:	8b 55 0c             	mov    0xc(%ebp),%edx
  800787:	89 c3                	mov    %eax,%ebx
  800789:	03 5d 10             	add    0x10(%ebp),%ebx
	while (n > 0 && *p && *p == *q)
  80078c:	eb 06                	jmp    800794 <strncmp+0x17>
		n--, p++, q++;
  80078e:	83 c0 01             	add    $0x1,%eax
  800791:	83 c2 01             	add    $0x1,%edx
}

int
strncmp(const char *p, const char *q, size_t n)
{
	while (n > 0 && *p && *p == *q)
  800794:	39 d8                	cmp    %ebx,%eax
  800796:	74 15                	je     8007ad <strncmp+0x30>
  800798:	0f b6 08             	movzbl (%eax),%ecx
  80079b:	84 c9                	test   %cl,%cl
  80079d:	74 04                	je     8007a3 <strncmp+0x26>
  80079f:	3a 0a                	cmp    (%edx),%cl
  8007a1:	74 eb                	je     80078e <strncmp+0x11>
		n--, p++, q++;
	if (n == 0)
		return 0;
	else
		return (int) ((unsigned char) *p - (unsigned char) *q);
  8007a3:	0f b6 00             	movzbl (%eax),%eax
  8007a6:	0f b6 12             	movzbl (%edx),%edx
  8007a9:	29 d0                	sub    %edx,%eax
  8007ab:	eb 05                	jmp    8007b2 <strncmp+0x35>
strncmp(const char *p, const char *q, size_t n)
{
	while (n > 0 && *p && *p == *q)
		n--, p++, q++;
	if (n == 0)
		return 0;
  8007ad:	b8 00 00 00 00       	mov    $0x0,%eax
	else
		return (int) ((unsigned char) *p - (unsigned char) *q);
}
  8007b2:	5b                   	pop    %ebx
  8007b3:	5d                   	pop    %ebp
  8007b4:	c3                   	ret    

008007b5 <strchr>:

// Return a pointer to the first occurrence of 'c' in 's',
// or a null pointer if the string has no 'c'.
char *
strchr(const char *s, char c)
{
  8007b5:	55                   	push   %ebp
  8007b6:	89 e5                	mov    %esp,%ebp
  8007b8:	8b 45 08             	mov    0x8(%ebp),%eax
  8007bb:	0f b6 4d 0c          	movzbl 0xc(%ebp),%ecx
	for (; *s; s++)
  8007bf:	eb 07                	jmp    8007c8 <strchr+0x13>
		if (*s == c)
  8007c1:	38 ca                	cmp    %cl,%dl
  8007c3:	74 0f                	je     8007d4 <strchr+0x1f>
// Return a pointer to the first occurrence of 'c' in 's',
// or a null pointer if the string has no 'c'.
char *
strchr(const char *s, char c)
{
	for (; *s; s++)
  8007c5:	83 c0 01             	add    $0x1,%eax
  8007c8:	0f b6 10             	movzbl (%eax),%edx
  8007cb:	84 d2                	test   %dl,%dl
  8007cd:	75 f2                	jne    8007c1 <strchr+0xc>
		if (*s == c)
			return (char *) s;
	return 0;
  8007cf:	b8 00 00 00 00       	mov    $0x0,%eax
}
  8007d4:	5d                   	pop    %ebp
  8007d5:	c3                   	ret    

008007d6 <strfind>:

// Return a pointer to the first occurrence of 'c' in 's',
// or a pointer to the string-ending null character if the string has no 'c'.
char *
strfind(const char *s, char c)
{
  8007d6:	55                   	push   %ebp
  8007d7:	89 e5                	mov    %esp,%ebp
  8007d9:	8b 45 08             	mov    0x8(%ebp),%eax
  8007dc:	0f b6 4d 0c          	movzbl 0xc(%ebp),%ecx
	for (; *s; s++)
  8007e0:	eb 03                	jmp    8007e5 <strfind+0xf>
  8007e2:	83 c0 01             	add    $0x1,%eax
  8007e5:	0f b6 10             	movzbl (%eax),%edx
		if (*s == c)
  8007e8:	38 ca                	cmp    %cl,%dl
  8007ea:	74 04                	je     8007f0 <strfind+0x1a>
  8007ec:	84 d2                	test   %dl,%dl
  8007ee:	75 f2                	jne    8007e2 <strfind+0xc>
			break;
	return (char *) s;
}
  8007f0:	5d                   	pop    %ebp
  8007f1:	c3                   	ret    

008007f2 <memset>:

#if ASM
void *
memset(void *v, int c, size_t n)
{
  8007f2:	55                   	push   %ebp
  8007f3:	89 e5                	mov    %esp,%ebp
  8007f5:	57                   	push   %edi
  8007f6:	56                   	push   %esi
  8007f7:	53                   	push   %ebx
  8007f8:	8b 55 08             	mov    0x8(%ebp),%edx
  8007fb:	8b 4d 10             	mov    0x10(%ebp),%ecx
	char *p = v;

	if (n == 0)
  8007fe:	85 c9                	test   %ecx,%ecx
  800800:	74 37                	je     800839 <memset+0x47>
		return v;
	if ((int)v%4 == 0 && n%4 == 0) {
  800802:	f6 c2 03             	test   $0x3,%dl
  800805:	75 2a                	jne    800831 <memset+0x3f>
  800807:	f6 c1 03             	test   $0x3,%cl
  80080a:	75 25                	jne    800831 <memset+0x3f>
		c &= 0xFF;
  80080c:	0f b6 5d 0c          	movzbl 0xc(%ebp),%ebx
		c = (c<<24)|(c<<16)|(c<<8)|c;
  800810:	89 df                	mov    %ebx,%edi
  800812:	c1 e7 08             	shl    $0x8,%edi
  800815:	89 de                	mov    %ebx,%esi
  800817:	c1 e6 18             	shl    $0x18,%esi
  80081a:	89 d8                	mov    %ebx,%eax
  80081c:	c1 e0 10             	shl    $0x10,%eax
  80081f:	09 f0                	or     %esi,%eax
  800821:	09 c3                	or     %eax,%ebx
		asm volatile("cld; rep stosl\n"
			: "=D" (p), "=c" (n)
			: "D" (p), "a" (c), "c" (n/4)
  800823:	c1 e9 02             	shr    $0x2,%ecx
	if (n == 0)
		return v;
	if ((int)v%4 == 0 && n%4 == 0) {
		c &= 0xFF;
		c = (c<<24)|(c<<16)|(c<<8)|c;
		asm volatile("cld; rep stosl\n"
  800826:	89 f8                	mov    %edi,%eax
  800828:	09 d8                	or     %ebx,%eax
  80082a:	89 d7                	mov    %edx,%edi
  80082c:	fc                   	cld    
  80082d:	f3 ab                	rep stos %eax,%es:(%edi)
  80082f:	eb 08                	jmp    800839 <memset+0x47>
			: "=D" (p), "=c" (n)
			: "D" (p), "a" (c), "c" (n/4)
			: "cc", "memory");
	} else
		asm volatile("cld; rep stosb\n"
  800831:	89 d7                	mov    %edx,%edi
  800833:	8b 45 0c             	mov    0xc(%ebp),%eax
  800836:	fc                   	cld    
  800837:	f3 aa                	rep stos %al,%es:(%edi)
			: "=D" (p), "=c" (n)
			: "0" (p), "a" (c), "1" (n)
			: "cc", "memory");
	return v;
}
  800839:	89 d0                	mov    %edx,%eax
  80083b:	5b                   	pop    %ebx
  80083c:	5e                   	pop    %esi
  80083d:	5f                   	pop    %edi
  80083e:	5d                   	pop    %ebp
  80083f:	c3                   	ret    

00800840 <memmove>:

void *
memmove(void *dst, const void *src, size_t n)
{
  800840:	55                   	push   %ebp
  800841:	89 e5                	mov    %esp,%ebp
  800843:	57                   	push   %edi
  800844:	56                   	push   %esi
  800845:	8b 45 08             	mov    0x8(%ebp),%eax
  800848:	8b 75 0c             	mov    0xc(%ebp),%esi
  80084b:	8b 4d 10             	mov    0x10(%ebp),%ecx
	const char *s;
	char *d;

	s = src;
	d = dst;
	if (s < d && s + n > d) {
  80084e:	39 c6                	cmp    %eax,%esi
  800850:	73 35                	jae    800887 <memmove+0x47>
  800852:	8d 14 0e             	lea    (%esi,%ecx,1),%edx
  800855:	39 d0                	cmp    %edx,%eax
  800857:	73 2e                	jae    800887 <memmove+0x47>
		s += n;
		d += n;
  800859:	8d 3c 08             	lea    (%eax,%ecx,1),%edi
		if ((int)s%4 == 0 && (int)d%4 == 0 && n%4 == 0)
  80085c:	89 d6                	mov    %edx,%esi
  80085e:	09 fe                	or     %edi,%esi
  800860:	f7 c6 03 00 00 00    	test   $0x3,%esi
  800866:	75 13                	jne    80087b <memmove+0x3b>
  800868:	f6 c1 03             	test   $0x3,%cl
  80086b:	75 0e                	jne    80087b <memmove+0x3b>
			asm volatile("std; rep movsl\n"
  80086d:	83 ef 04             	sub    $0x4,%edi
  800870:	8d 72 fc             	lea    -0x4(%edx),%esi
  800873:	c1 e9 02             	shr    $0x2,%ecx
  800876:	fd                   	std    
  800877:	f3 a5                	rep movsl %ds:(%esi),%es:(%edi)
  800879:	eb 09                	jmp    800884 <memmove+0x44>
				:: "D" (d-4), "S" (s-4), "c" (n/4) : "cc", "memory");
		else
			asm volatile("std; rep movsb\n"
  80087b:	83 ef 01             	sub    $0x1,%edi
  80087e:	8d 72 ff             	lea    -0x1(%edx),%esi
  800881:	fd                   	std    
  800882:	f3 a4                	rep movsb %ds:(%esi),%es:(%edi)
				:: "D" (d-1), "S" (s-1), "c" (n) : "cc", "memory");
		// Some versions of GCC rely on DF being clear
		asm volatile("cld" ::: "cc");
  800884:	fc                   	cld    
  800885:	eb 1d                	jmp    8008a4 <memmove+0x64>
	} else {
		if ((int)s%4 == 0 && (int)d%4 == 0 && n%4 == 0)
  800887:	89 f2                	mov    %esi,%edx
  800889:	09 c2                	or     %eax,%edx
  80088b:	f6 c2 03             	test   $0x3,%dl
  80088e:	75 0f                	jne    80089f <memmove+0x5f>
  800890:	f6 c1 03             	test   $0x3,%cl
  800893:	75 0a                	jne    80089f <memmove+0x5f>
			asm volatile("cld; rep movsl\n"
  800895:	c1 e9 02             	shr    $0x2,%ecx
  800898:	89 c7                	mov    %eax,%edi
  80089a:	fc                   	cld    
  80089b:	f3 a5                	rep movsl %ds:(%esi),%es:(%edi)
  80089d:	eb 05                	jmp    8008a4 <memmove+0x64>
				:: "D" (d), "S" (s), "c" (n/4) : "cc", "memory");
		else
			asm volatile("cld; rep movsb\n"
  80089f:	89 c7                	mov    %eax,%edi
  8008a1:	fc                   	cld    
  8008a2:	f3 a4                	rep movsb %ds:(%esi),%es:(%edi)
				:: "D" (d), "S" (s), "c" (n) : "cc", "memory");
	}
	return dst;
}
  8008a4:	5e                   	pop    %esi
  8008a5:	5f                   	pop    %edi
  8008a6:	5d                   	pop    %ebp
  8008a7:	c3                   	ret    

008008a8 <memcpy>:
}
#endif

void *
memcpy(void *dst, const void *src, size_t n)
{
  8008a8:	55                   	push   %ebp
  8008a9:	89 e5                	mov    %esp,%ebp
	return memmove(dst, src, n);
  8008ab:	ff 75 10             	pushl  0x10(%ebp)
  8008ae:	ff 75 0c             	pushl  0xc(%ebp)
  8008b1:	ff 75 08             	pushl  0x8(%ebp)
  8008b4:	e8 87 ff ff ff       	call   800840 <memmove>
}
  8008b9:	c9                   	leave  
  8008ba:	c3                   	ret    

008008bb <memcmp>:

int
memcmp(const void *v1, const void *v2, size_t n)
{
  8008bb:	55                   	push   %ebp
  8008bc:	89 e5                	mov    %esp,%ebp
  8008be:	56                   	push   %esi
  8008bf:	53                   	push   %ebx
  8008c0:	8b 45 08             	mov    0x8(%ebp),%eax
  8008c3:	8b 55 0c             	mov    0xc(%ebp),%edx
  8008c6:	89 c6                	mov    %eax,%esi
  8008c8:	03 75 10             	add    0x10(%ebp),%esi
	const uint8_t *s1 = (const uint8_t *) v1;
	const uint8_t *s2 = (const uint8_t *) v2;

	while (n-- > 0) {
  8008cb:	eb 1a                	jmp    8008e7 <memcmp+0x2c>
		if (*s1 != *s2)
  8008cd:	0f b6 08             	movzbl (%eax),%ecx
  8008d0:	0f b6 1a             	movzbl (%edx),%ebx
  8008d3:	38 d9                	cmp    %bl,%cl
  8008d5:	74 0a                	je     8008e1 <memcmp+0x26>
			return (int) *s1 - (int) *s2;
  8008d7:	0f b6 c1             	movzbl %cl,%eax
  8008da:	0f b6 db             	movzbl %bl,%ebx
  8008dd:	29 d8                	sub    %ebx,%eax
  8008df:	eb 0f                	jmp    8008f0 <memcmp+0x35>
		s1++, s2++;
  8008e1:	83 c0 01             	add    $0x1,%eax
  8008e4:	83 c2 01             	add    $0x1,%edx
memcmp(const void *v1, const void *v2, size_t n)
{
	const uint8_t *s1 = (const uint8_t *) v1;
	const uint8_t *s2 = (const uint8_t *) v2;

	while (n-- > 0) {
  8008e7:	39 f0                	cmp    %esi,%eax
  8008e9:	75 e2                	jne    8008cd <memcmp+0x12>
		if (*s1 != *s2)
			return (int) *s1 - (int) *s2;
		s1++, s2++;
	}

	return 0;
  8008eb:	b8 00 00 00 00       	mov    $0x0,%eax
}
  8008f0:	5b                   	pop    %ebx
  8008f1:	5e                   	pop    %esi
  8008f2:	5d                   	pop    %ebp
  8008f3:	c3                   	ret    

008008f4 <memfind>:

void *
memfind(const void *s, int c, size_t n)
{
  8008f4:	55                   	push   %ebp
  8008f5:	89 e5                	mov    %esp,%ebp
  8008f7:	8b 45 08             	mov    0x8(%ebp),%eax
  8008fa:	8b 4d 0c             	mov    0xc(%ebp),%ecx
	const void *ends = (const char *) s + n;
  8008fd:	89 c2                	mov    %eax,%edx
  8008ff:	03 55 10             	add    0x10(%ebp),%edx
	for (; s < ends; s++)
  800902:	eb 07                	jmp    80090b <memfind+0x17>
		if (*(const unsigned char *) s == (unsigned char) c)
  800904:	38 08                	cmp    %cl,(%eax)
  800906:	74 07                	je     80090f <memfind+0x1b>

void *
memfind(const void *s, int c, size_t n)
{
	const void *ends = (const char *) s + n;
	for (; s < ends; s++)
  800908:	83 c0 01             	add    $0x1,%eax
  80090b:	39 d0                	cmp    %edx,%eax
  80090d:	72 f5                	jb     800904 <memfind+0x10>
		if (*(const unsigned char *) s == (unsigned char) c)
			break;
	return (void *) s;
}
  80090f:	5d                   	pop    %ebp
  800910:	c3                   	ret    

00800911 <strtol>:

long
strtol(const char *s, char **endptr, int base)
{
  800911:	55                   	push   %ebp
  800912:	89 e5                	mov    %esp,%ebp
  800914:	57                   	push   %edi
  800915:	56                   	push   %esi
  800916:	53                   	push   %ebx
  800917:	8b 4d 08             	mov    0x8(%ebp),%ecx
  80091a:	8b 5d 10             	mov    0x10(%ebp),%ebx
	int neg = 0;
	long val = 0;

	// gobble initial whitespace
	while (*s == ' ' || *s == '\t')
  80091d:	eb 03                	jmp    800922 <strtol+0x11>
		s++;
  80091f:	83 c1 01             	add    $0x1,%ecx
{
	int neg = 0;
	long val = 0;

	// gobble initial whitespace
	while (*s == ' ' || *s == '\t')
  800922:	0f b6 01             	movzbl (%ecx),%eax
  800925:	3c 20                	cmp    $0x20,%al
  800927:	74 f6                	je     80091f <strtol+0xe>
  800929:	3c 09                	cmp    $0x9,%al
  80092b:	74 f2                	je     80091f <strtol+0xe>
		s++;

	// plus/minus sign
	if (*s == '+')
  80092d:	3c 2b                	cmp    $0x2b,%al
  80092f:	75 0a                	jne    80093b <strtol+0x2a>
		s++;
  800931:	83 c1 01             	add    $0x1,%ecx
}

long
strtol(const char *s, char **endptr, int base)
{
	int neg = 0;
  800934:	bf 00 00 00 00       	mov    $0x0,%edi
  800939:	eb 11                	jmp    80094c <strtol+0x3b>
  80093b:	bf 00 00 00 00       	mov    $0x0,%edi
		s++;

	// plus/minus sign
	if (*s == '+')
		s++;
	else if (*s == '-')
  800940:	3c 2d                	cmp    $0x2d,%al
  800942:	75 08                	jne    80094c <strtol+0x3b>
		s++, neg = 1;
  800944:	83 c1 01             	add    $0x1,%ecx
  800947:	bf 01 00 00 00       	mov    $0x1,%edi

	// hex or octal base prefix
	if ((base == 0 || base == 16) && (s[0] == '0' && s[1] == 'x'))
  80094c:	f7 c3 ef ff ff ff    	test   $0xffffffef,%ebx
  800952:	75 15                	jne    800969 <strtol+0x58>
  800954:	80 39 30             	cmpb   $0x30,(%ecx)
  800957:	75 10                	jne    800969 <strtol+0x58>
  800959:	80 79 01 78          	cmpb   $0x78,0x1(%ecx)
  80095d:	75 7c                	jne    8009db <strtol+0xca>
		s += 2, base = 16;
  80095f:	83 c1 02             	add    $0x2,%ecx
  800962:	bb 10 00 00 00       	mov    $0x10,%ebx
  800967:	eb 16                	jmp    80097f <strtol+0x6e>
	else if (base == 0 && s[0] == '0')
  800969:	85 db                	test   %ebx,%ebx
  80096b:	75 12                	jne    80097f <strtol+0x6e>
		s++, base = 8;
	else if (base == 0)
		base = 10;
  80096d:	bb 0a 00 00 00       	mov    $0xa,%ebx
		s++, neg = 1;

	// hex or octal base prefix
	if ((base == 0 || base == 16) && (s[0] == '0' && s[1] == 'x'))
		s += 2, base = 16;
	else if (base == 0 && s[0] == '0')
  800972:	80 39 30             	cmpb   $0x30,(%ecx)
  800975:	75 08                	jne    80097f <strtol+0x6e>
		s++, base = 8;
  800977:	83 c1 01             	add    $0x1,%ecx
  80097a:	bb 08 00 00 00       	mov    $0x8,%ebx
	else if (base == 0)
		base = 10;
  80097f:	b8 00 00 00 00       	mov    $0x0,%eax
  800984:	89 5d 10             	mov    %ebx,0x10(%ebp)

	// digits
	while (1) {
		int dig;

		if (*s >= '0' && *s <= '9')
  800987:	0f b6 11             	movzbl (%ecx),%edx
  80098a:	8d 72 d0             	lea    -0x30(%edx),%esi
  80098d:	89 f3                	mov    %esi,%ebx
  80098f:	80 fb 09             	cmp    $0x9,%bl
  800992:	77 08                	ja     80099c <strtol+0x8b>
			dig = *s - '0';
  800994:	0f be d2             	movsbl %dl,%edx
  800997:	83 ea 30             	sub    $0x30,%edx
  80099a:	eb 22                	jmp    8009be <strtol+0xad>
		else if (*s >= 'a' && *s <= 'z')
  80099c:	8d 72 9f             	lea    -0x61(%edx),%esi
  80099f:	89 f3                	mov    %esi,%ebx
  8009a1:	80 fb 19             	cmp    $0x19,%bl
  8009a4:	77 08                	ja     8009ae <strtol+0x9d>
			dig = *s - 'a' + 10;
  8009a6:	0f be d2             	movsbl %dl,%edx
  8009a9:	83 ea 57             	sub    $0x57,%edx
  8009ac:	eb 10                	jmp    8009be <strtol+0xad>
		else if (*s >= 'A' && *s <= 'Z')
  8009ae:	8d 72 bf             	lea    -0x41(%edx),%esi
  8009b1:	89 f3                	mov    %esi,%ebx
  8009b3:	80 fb 19             	cmp    $0x19,%bl
  8009b6:	77 16                	ja     8009ce <strtol+0xbd>
			dig = *s - 'A' + 10;
  8009b8:	0f be d2             	movsbl %dl,%edx
  8009bb:	83 ea 37             	sub    $0x37,%edx
		else
			break;
		if (dig >= base)
  8009be:	3b 55 10             	cmp    0x10(%ebp),%edx
  8009c1:	7d 0b                	jge    8009ce <strtol+0xbd>
			break;
		s++, val = (val * base) + dig;
  8009c3:	83 c1 01             	add    $0x1,%ecx
  8009c6:	0f af 45 10          	imul   0x10(%ebp),%eax
  8009ca:	01 d0                	add    %edx,%eax
		// we don't properly detect overflow!
	}
  8009cc:	eb b9                	jmp    800987 <strtol+0x76>

	if (endptr)
  8009ce:	83 7d 0c 00          	cmpl   $0x0,0xc(%ebp)
  8009d2:	74 0d                	je     8009e1 <strtol+0xd0>
		*endptr = (char *) s;
  8009d4:	8b 75 0c             	mov    0xc(%ebp),%esi
  8009d7:	89 0e                	mov    %ecx,(%esi)
  8009d9:	eb 06                	jmp    8009e1 <strtol+0xd0>
		s++, neg = 1;

	// hex or octal base prefix
	if ((base == 0 || base == 16) && (s[0] == '0' && s[1] == 'x'))
		s += 2, base = 16;
	else if (base == 0 && s[0] == '0')
  8009db:	85 db                	test   %ebx,%ebx
  8009dd:	74 98                	je     800977 <strtol+0x66>
  8009df:	eb 9e                	jmp    80097f <strtol+0x6e>
		// we don't properly detect overflow!
	}

	if (endptr)
		*endptr = (char *) s;
	return (neg ? -val : val);
  8009e1:	89 c2                	mov    %eax,%edx
  8009e3:	f7 da                	neg    %edx
  8009e5:	85 ff                	test   %edi,%edi
  8009e7:	0f 45 c2             	cmovne %edx,%eax
}
  8009ea:	5b                   	pop    %ebx
  8009eb:	5e                   	pop    %esi
  8009ec:	5f                   	pop    %edi
  8009ed:	5d                   	pop    %ebp
  8009ee:	c3                   	ret    

008009ef <syscall>:
#include <inc/syscall.h>
#include <inc/lib.h>

static inline int32_t
syscall(int num, int check, uint32_t a1, uint32_t a2, uint32_t a3, uint32_t a4, uint32_t a5)
{
  8009ef:	55                   	push   %ebp
  8009f0:	89 e5                	mov    %esp,%ebp
  8009f2:	57                   	push   %edi
  8009f3:	56                   	push   %esi
  8009f4:	53                   	push   %ebx
  8009f5:	83 ec 1c             	sub    $0x1c,%esp
  8009f8:	89 45 e0             	mov    %eax,-0x20(%ebp)
  8009fb:	89 55 e4             	mov    %edx,-0x1c(%ebp)
  8009fe:	89 ca                	mov    %ecx,%edx
	//
	// The last clause tells the assembler that this can
	// potentially change the condition codes and arbitrary
	// memory locations.

	asm volatile("int %1\n"
  800a00:	8b 4d 08             	mov    0x8(%ebp),%ecx
  800a03:	8b 5d 0c             	mov    0xc(%ebp),%ebx
  800a06:	8b 7d 10             	mov    0x10(%ebp),%edi
  800a09:	8b 75 14             	mov    0x14(%ebp),%esi
  800a0c:	cd 30                	int    $0x30
		       "b" (a3),
		       "D" (a4),
		       "S" (a5)
		     : "cc", "memory");

	if(check && ret > 0)
  800a0e:	83 7d e4 00          	cmpl   $0x0,-0x1c(%ebp)
  800a12:	74 1d                	je     800a31 <syscall+0x42>
  800a14:	85 c0                	test   %eax,%eax
  800a16:	7e 19                	jle    800a31 <syscall+0x42>
  800a18:	8b 55 e0             	mov    -0x20(%ebp),%edx
		panic("syscall %d returned %d (> 0)", num, ret);
  800a1b:	83 ec 0c             	sub    $0xc,%esp
  800a1e:	50                   	push   %eax
  800a1f:	52                   	push   %edx
  800a20:	68 b0 0f 80 00       	push   $0x800fb0
  800a25:	6a 23                	push   $0x23
  800a27:	68 cd 0f 80 00       	push   $0x800fcd
  800a2c:	e8 98 00 00 00       	call   800ac9 <_panic>

	return ret;
}
  800a31:	8d 65 f4             	lea    -0xc(%ebp),%esp
  800a34:	5b                   	pop    %ebx
  800a35:	5e                   	pop    %esi
  800a36:	5f                   	pop    %edi
  800a37:	5d                   	pop    %ebp
  800a38:	c3                   	ret    

00800a39 <sys_cputs>:

void
sys_cputs(const char *s, size_t len)
{
  800a39:	55                   	push   %ebp
  800a3a:	89 e5                	mov    %esp,%ebp
  800a3c:	83 ec 08             	sub    $0x8,%esp
	syscall(SYS_cputs, 0, (uint32_t)s, len, 0, 0, 0);
  800a3f:	6a 00                	push   $0x0
  800a41:	6a 00                	push   $0x0
  800a43:	6a 00                	push   $0x0
  800a45:	ff 75 0c             	pushl  0xc(%ebp)
  800a48:	8b 4d 08             	mov    0x8(%ebp),%ecx
  800a4b:	ba 00 00 00 00       	mov    $0x0,%edx
  800a50:	b8 00 00 00 00       	mov    $0x0,%eax
  800a55:	e8 95 ff ff ff       	call   8009ef <syscall>
}
  800a5a:	83 c4 10             	add    $0x10,%esp
  800a5d:	c9                   	leave  
  800a5e:	c3                   	ret    

00800a5f <sys_cgetc>:

int
sys_cgetc(void)
{
  800a5f:	55                   	push   %ebp
  800a60:	89 e5                	mov    %esp,%ebp
  800a62:	83 ec 08             	sub    $0x8,%esp
	return syscall(SYS_cgetc, 0, 0, 0, 0, 0, 0);
  800a65:	6a 00                	push   $0x0
  800a67:	6a 00                	push   $0x0
  800a69:	6a 00                	push   $0x0
  800a6b:	6a 00                	push   $0x0
  800a6d:	b9 00 00 00 00       	mov    $0x0,%ecx
  800a72:	ba 00 00 00 00       	mov    $0x0,%edx
  800a77:	b8 01 00 00 00       	mov    $0x1,%eax
  800a7c:	e8 6e ff ff ff       	call   8009ef <syscall>
}
  800a81:	c9                   	leave  
  800a82:	c3                   	ret    

00800a83 <sys_env_destroy>:

int
sys_env_destroy(envid_t envid)
{
  800a83:	55                   	push   %ebp
  800a84:	89 e5                	mov    %esp,%ebp
  800a86:	83 ec 08             	sub    $0x8,%esp
	return syscall(SYS_env_destroy, 1, envid, 0, 0, 0, 0);
  800a89:	6a 00                	push   $0x0
  800a8b:	6a 00                	push   $0x0
  800a8d:	6a 00                	push   $0x0
  800a8f:	6a 00                	push   $0x0
  800a91:	8b 4d 08             	mov    0x8(%ebp),%ecx
  800a94:	ba 01 00 00 00       	mov    $0x1,%edx
  800a99:	b8 03 00 00 00       	mov    $0x3,%eax
  800a9e:	e8 4c ff ff ff       	call   8009ef <syscall>
}
  800aa3:	c9                   	leave  
  800aa4:	c3                   	ret    

00800aa5 <sys_getenvid>:

envid_t
sys_getenvid(void)
{
  800aa5:	55                   	push   %ebp
  800aa6:	89 e5                	mov    %esp,%ebp
  800aa8:	83 ec 08             	sub    $0x8,%esp
	 return syscall(SYS_getenvid, 0, 0, 0, 0, 0, 0);
  800aab:	6a 00                	push   $0x0
  800aad:	6a 00                	push   $0x0
  800aaf:	6a 00                	push   $0x0
  800ab1:	6a 00                	push   $0x0
  800ab3:	b9 00 00 00 00       	mov    $0x0,%ecx
  800ab8:	ba 00 00 00 00       	mov    $0x0,%edx
  800abd:	b8 02 00 00 00       	mov    $0x2,%eax
  800ac2:	e8 28 ff ff ff       	call   8009ef <syscall>
}
  800ac7:	c9                   	leave  
  800ac8:	c3                   	ret    

00800ac9 <_panic>:
 * It prints "panic: <message>", then causes a breakpoint exception,
 * which causes JOS to enter the JOS kernel monitor.
 */
void
_panic(const char *file, int line, const char *fmt, ...)
{
  800ac9:	55                   	push   %ebp
  800aca:	89 e5                	mov    %esp,%ebp
  800acc:	56                   	push   %esi
  800acd:	53                   	push   %ebx
	va_list ap;

	va_start(ap, fmt);
  800ace:	8d 5d 14             	lea    0x14(%ebp),%ebx

	// Print the panic message
	cprintf("[%08x] user panic in %s at %s:%d: ",
  800ad1:	8b 35 00 10 80 00    	mov    0x801000,%esi
  800ad7:	e8 c9 ff ff ff       	call   800aa5 <sys_getenvid>
  800adc:	83 ec 0c             	sub    $0xc,%esp
  800adf:	ff 75 0c             	pushl  0xc(%ebp)
  800ae2:	ff 75 08             	pushl  0x8(%ebp)
  800ae5:	56                   	push   %esi
  800ae6:	50                   	push   %eax
  800ae7:	68 dc 0f 80 00       	push   $0x800fdc
  800aec:	e8 4a f6 ff ff       	call   80013b <cprintf>
		sys_getenvid(), binaryname, file, line);
	vcprintf(fmt, ap);
  800af1:	83 c4 18             	add    $0x18,%esp
  800af4:	53                   	push   %ebx
  800af5:	ff 75 10             	pushl  0x10(%ebp)
  800af8:	e8 ed f5 ff ff       	call   8000ea <vcprintf>
	cprintf("\n");
  800afd:	c7 04 24 a0 0d 80 00 	movl   $0x800da0,(%esp)
  800b04:	e8 32 f6 ff ff       	call   80013b <cprintf>
  800b09:	83 c4 10             	add    $0x10,%esp

	// Cause a breakpoint exception
	while (1)
		asm volatile("int3");
  800b0c:	cc                   	int3   
  800b0d:	eb fd                	jmp    800b0c <_panic+0x43>
  800b0f:	90                   	nop

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
