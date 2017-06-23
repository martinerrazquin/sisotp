
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
  800039:	68 e0 0e 80 00       	push   $0x800ee0
  80003e:	e8 07 01 00 00       	call   80014a <cprintf>
	cprintf("i am environment %08x\n", sys_getenvid());
  800043:	e8 6c 0a 00 00       	call   800ab4 <sys_getenvid>
  800048:	83 c4 08             	add    $0x8,%esp
  80004b:	50                   	push   %eax
  80004c:	68 ee 0e 80 00       	push   $0x800eee
  800051:	e8 f4 00 00 00       	call   80014a <cprintf>
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
  80005e:	56                   	push   %esi
  80005f:	53                   	push   %ebx
  800060:	8b 5d 08             	mov    0x8(%ebp),%ebx
  800063:	8b 75 0c             	mov    0xc(%ebp),%esi
	// set thisenv to point at our Env structure in envs[].
	// LAB 3: Your code here.
	envid_t id = sys_getenvid();
  800066:	e8 49 0a 00 00       	call   800ab4 <sys_getenvid>
	if (id >= 0)
  80006b:	85 c0                	test   %eax,%eax
  80006d:	78 12                	js     800081 <libmain+0x26>
		thisenv = &envs[ENVX(id)];
  80006f:	25 ff 03 00 00       	and    $0x3ff,%eax
  800074:	6b c0 7c             	imul   $0x7c,%eax,%eax
  800077:	05 00 00 c0 ee       	add    $0xeec00000,%eax
  80007c:	a3 04 20 80 00       	mov    %eax,0x802004

	// save the name of the program so that panic() can use it
	if (argc > 0)
  800081:	85 db                	test   %ebx,%ebx
  800083:	7e 07                	jle    80008c <libmain+0x31>
		binaryname = argv[0];
  800085:	8b 06                	mov    (%esi),%eax
  800087:	a3 00 20 80 00       	mov    %eax,0x802000

	// call user main routine
	umain(argc, argv);
  80008c:	83 ec 08             	sub    $0x8,%esp
  80008f:	56                   	push   %esi
  800090:	53                   	push   %ebx
  800091:	e8 9d ff ff ff       	call   800033 <umain>

	// exit gracefully
	exit();
  800096:	e8 0a 00 00 00       	call   8000a5 <exit>
}
  80009b:	83 c4 10             	add    $0x10,%esp
  80009e:	8d 65 f8             	lea    -0x8(%ebp),%esp
  8000a1:	5b                   	pop    %ebx
  8000a2:	5e                   	pop    %esi
  8000a3:	5d                   	pop    %ebp
  8000a4:	c3                   	ret    

008000a5 <exit>:

#include <inc/lib.h>

void
exit(void)
{
  8000a5:	55                   	push   %ebp
  8000a6:	89 e5                	mov    %esp,%ebp
  8000a8:	83 ec 14             	sub    $0x14,%esp
	sys_env_destroy(0);
  8000ab:	6a 00                	push   $0x0
  8000ad:	e8 e0 09 00 00       	call   800a92 <sys_env_destroy>
}
  8000b2:	83 c4 10             	add    $0x10,%esp
  8000b5:	c9                   	leave  
  8000b6:	c3                   	ret    

008000b7 <putch>:
};


static void
putch(int ch, struct printbuf *b)
{
  8000b7:	55                   	push   %ebp
  8000b8:	89 e5                	mov    %esp,%ebp
  8000ba:	53                   	push   %ebx
  8000bb:	83 ec 04             	sub    $0x4,%esp
  8000be:	8b 5d 0c             	mov    0xc(%ebp),%ebx
	b->buf[b->idx++] = ch;
  8000c1:	8b 13                	mov    (%ebx),%edx
  8000c3:	8d 42 01             	lea    0x1(%edx),%eax
  8000c6:	89 03                	mov    %eax,(%ebx)
  8000c8:	8b 4d 08             	mov    0x8(%ebp),%ecx
  8000cb:	88 4c 13 08          	mov    %cl,0x8(%ebx,%edx,1)
	if (b->idx == 256-1) {
  8000cf:	3d ff 00 00 00       	cmp    $0xff,%eax
  8000d4:	75 1a                	jne    8000f0 <putch+0x39>
		sys_cputs(b->buf, b->idx);
  8000d6:	83 ec 08             	sub    $0x8,%esp
  8000d9:	68 ff 00 00 00       	push   $0xff
  8000de:	8d 43 08             	lea    0x8(%ebx),%eax
  8000e1:	50                   	push   %eax
  8000e2:	e8 61 09 00 00       	call   800a48 <sys_cputs>
		b->idx = 0;
  8000e7:	c7 03 00 00 00 00    	movl   $0x0,(%ebx)
  8000ed:	83 c4 10             	add    $0x10,%esp
	}
	b->cnt++;
  8000f0:	83 43 04 01          	addl   $0x1,0x4(%ebx)
}
  8000f4:	8b 5d fc             	mov    -0x4(%ebp),%ebx
  8000f7:	c9                   	leave  
  8000f8:	c3                   	ret    

008000f9 <vcprintf>:

int
vcprintf(const char *fmt, va_list ap)
{
  8000f9:	55                   	push   %ebp
  8000fa:	89 e5                	mov    %esp,%ebp
  8000fc:	81 ec 18 01 00 00    	sub    $0x118,%esp
	struct printbuf b;

	b.idx = 0;
  800102:	c7 85 f0 fe ff ff 00 	movl   $0x0,-0x110(%ebp)
  800109:	00 00 00 
	b.cnt = 0;
  80010c:	c7 85 f4 fe ff ff 00 	movl   $0x0,-0x10c(%ebp)
  800113:	00 00 00 
	vprintfmt((void*)putch, &b, fmt, ap);
  800116:	ff 75 0c             	pushl  0xc(%ebp)
  800119:	ff 75 08             	pushl  0x8(%ebp)
  80011c:	8d 85 f0 fe ff ff    	lea    -0x110(%ebp),%eax
  800122:	50                   	push   %eax
  800123:	68 b7 00 80 00       	push   $0x8000b7
  800128:	e8 86 01 00 00       	call   8002b3 <vprintfmt>
	sys_cputs(b.buf, b.idx);
  80012d:	83 c4 08             	add    $0x8,%esp
  800130:	ff b5 f0 fe ff ff    	pushl  -0x110(%ebp)
  800136:	8d 85 f8 fe ff ff    	lea    -0x108(%ebp),%eax
  80013c:	50                   	push   %eax
  80013d:	e8 06 09 00 00       	call   800a48 <sys_cputs>

	return b.cnt;
}
  800142:	8b 85 f4 fe ff ff    	mov    -0x10c(%ebp),%eax
  800148:	c9                   	leave  
  800149:	c3                   	ret    

0080014a <cprintf>:

int
cprintf(const char *fmt, ...)
{
  80014a:	55                   	push   %ebp
  80014b:	89 e5                	mov    %esp,%ebp
  80014d:	83 ec 10             	sub    $0x10,%esp
	va_list ap;
	int cnt;

	va_start(ap, fmt);
  800150:	8d 45 0c             	lea    0xc(%ebp),%eax
	cnt = vcprintf(fmt, ap);
  800153:	50                   	push   %eax
  800154:	ff 75 08             	pushl  0x8(%ebp)
  800157:	e8 9d ff ff ff       	call   8000f9 <vcprintf>
	va_end(ap);

	return cnt;
}
  80015c:	c9                   	leave  
  80015d:	c3                   	ret    

0080015e <printnum>:
 * using specified putch function and associated pointer putdat.
 */
static void
printnum(void (*putch)(int, void*), void *putdat,
	 unsigned long long num, unsigned base, int width, int padc)
{
  80015e:	55                   	push   %ebp
  80015f:	89 e5                	mov    %esp,%ebp
  800161:	57                   	push   %edi
  800162:	56                   	push   %esi
  800163:	53                   	push   %ebx
  800164:	83 ec 1c             	sub    $0x1c,%esp
  800167:	89 c7                	mov    %eax,%edi
  800169:	89 d6                	mov    %edx,%esi
  80016b:	8b 45 08             	mov    0x8(%ebp),%eax
  80016e:	8b 55 0c             	mov    0xc(%ebp),%edx
  800171:	89 45 d8             	mov    %eax,-0x28(%ebp)
  800174:	89 55 dc             	mov    %edx,-0x24(%ebp)
	// first recursively print all preceding (more significant) digits
	if (num >= base) {
  800177:	8b 4d 10             	mov    0x10(%ebp),%ecx
  80017a:	bb 00 00 00 00       	mov    $0x0,%ebx
  80017f:	89 4d e0             	mov    %ecx,-0x20(%ebp)
  800182:	89 5d e4             	mov    %ebx,-0x1c(%ebp)
  800185:	39 d3                	cmp    %edx,%ebx
  800187:	72 05                	jb     80018e <printnum+0x30>
  800189:	39 45 10             	cmp    %eax,0x10(%ebp)
  80018c:	77 45                	ja     8001d3 <printnum+0x75>
		printnum(putch, putdat, num / base, base, width - 1, padc);
  80018e:	83 ec 0c             	sub    $0xc,%esp
  800191:	ff 75 18             	pushl  0x18(%ebp)
  800194:	8b 45 14             	mov    0x14(%ebp),%eax
  800197:	8d 58 ff             	lea    -0x1(%eax),%ebx
  80019a:	53                   	push   %ebx
  80019b:	ff 75 10             	pushl  0x10(%ebp)
  80019e:	83 ec 08             	sub    $0x8,%esp
  8001a1:	ff 75 e4             	pushl  -0x1c(%ebp)
  8001a4:	ff 75 e0             	pushl  -0x20(%ebp)
  8001a7:	ff 75 dc             	pushl  -0x24(%ebp)
  8001aa:	ff 75 d8             	pushl  -0x28(%ebp)
  8001ad:	e8 8e 0a 00 00       	call   800c40 <__udivdi3>
  8001b2:	83 c4 18             	add    $0x18,%esp
  8001b5:	52                   	push   %edx
  8001b6:	50                   	push   %eax
  8001b7:	89 f2                	mov    %esi,%edx
  8001b9:	89 f8                	mov    %edi,%eax
  8001bb:	e8 9e ff ff ff       	call   80015e <printnum>
  8001c0:	83 c4 20             	add    $0x20,%esp
  8001c3:	eb 18                	jmp    8001dd <printnum+0x7f>
	} else {
		// print any needed pad characters before first digit
		while (--width > 0)
			putch(padc, putdat);
  8001c5:	83 ec 08             	sub    $0x8,%esp
  8001c8:	56                   	push   %esi
  8001c9:	ff 75 18             	pushl  0x18(%ebp)
  8001cc:	ff d7                	call   *%edi
  8001ce:	83 c4 10             	add    $0x10,%esp
  8001d1:	eb 03                	jmp    8001d6 <printnum+0x78>
  8001d3:	8b 5d 14             	mov    0x14(%ebp),%ebx
	// first recursively print all preceding (more significant) digits
	if (num >= base) {
		printnum(putch, putdat, num / base, base, width - 1, padc);
	} else {
		// print any needed pad characters before first digit
		while (--width > 0)
  8001d6:	83 eb 01             	sub    $0x1,%ebx
  8001d9:	85 db                	test   %ebx,%ebx
  8001db:	7f e8                	jg     8001c5 <printnum+0x67>
			putch(padc, putdat);
	}

	// then print this (the least significant) digit
	putch("0123456789abcdef"[num % base], putdat);
  8001dd:	83 ec 08             	sub    $0x8,%esp
  8001e0:	56                   	push   %esi
  8001e1:	83 ec 04             	sub    $0x4,%esp
  8001e4:	ff 75 e4             	pushl  -0x1c(%ebp)
  8001e7:	ff 75 e0             	pushl  -0x20(%ebp)
  8001ea:	ff 75 dc             	pushl  -0x24(%ebp)
  8001ed:	ff 75 d8             	pushl  -0x28(%ebp)
  8001f0:	e8 7b 0b 00 00       	call   800d70 <__umoddi3>
  8001f5:	83 c4 14             	add    $0x14,%esp
  8001f8:	0f be 80 0f 0f 80 00 	movsbl 0x800f0f(%eax),%eax
  8001ff:	50                   	push   %eax
  800200:	ff d7                	call   *%edi
}
  800202:	83 c4 10             	add    $0x10,%esp
  800205:	8d 65 f4             	lea    -0xc(%ebp),%esp
  800208:	5b                   	pop    %ebx
  800209:	5e                   	pop    %esi
  80020a:	5f                   	pop    %edi
  80020b:	5d                   	pop    %ebp
  80020c:	c3                   	ret    

0080020d <getuint>:

// Get an unsigned int of various possible sizes from a varargs list,
// depending on the lflag parameter.
static unsigned long long
getuint(va_list *ap, int lflag)
{
  80020d:	55                   	push   %ebp
  80020e:	89 e5                	mov    %esp,%ebp
	if (lflag >= 2)
  800210:	83 fa 01             	cmp    $0x1,%edx
  800213:	7e 0e                	jle    800223 <getuint+0x16>
		return va_arg(*ap, unsigned long long);
  800215:	8b 10                	mov    (%eax),%edx
  800217:	8d 4a 08             	lea    0x8(%edx),%ecx
  80021a:	89 08                	mov    %ecx,(%eax)
  80021c:	8b 02                	mov    (%edx),%eax
  80021e:	8b 52 04             	mov    0x4(%edx),%edx
  800221:	eb 22                	jmp    800245 <getuint+0x38>
	else if (lflag)
  800223:	85 d2                	test   %edx,%edx
  800225:	74 10                	je     800237 <getuint+0x2a>
		return va_arg(*ap, unsigned long);
  800227:	8b 10                	mov    (%eax),%edx
  800229:	8d 4a 04             	lea    0x4(%edx),%ecx
  80022c:	89 08                	mov    %ecx,(%eax)
  80022e:	8b 02                	mov    (%edx),%eax
  800230:	ba 00 00 00 00       	mov    $0x0,%edx
  800235:	eb 0e                	jmp    800245 <getuint+0x38>
	else
		return va_arg(*ap, unsigned int);
  800237:	8b 10                	mov    (%eax),%edx
  800239:	8d 4a 04             	lea    0x4(%edx),%ecx
  80023c:	89 08                	mov    %ecx,(%eax)
  80023e:	8b 02                	mov    (%edx),%eax
  800240:	ba 00 00 00 00       	mov    $0x0,%edx
}
  800245:	5d                   	pop    %ebp
  800246:	c3                   	ret    

00800247 <getint>:

// Same as getuint but signed - can't use getuint
// because of sign extension
static long long
getint(va_list *ap, int lflag)
{
  800247:	55                   	push   %ebp
  800248:	89 e5                	mov    %esp,%ebp
	if (lflag >= 2)
  80024a:	83 fa 01             	cmp    $0x1,%edx
  80024d:	7e 0e                	jle    80025d <getint+0x16>
		return va_arg(*ap, long long);
  80024f:	8b 10                	mov    (%eax),%edx
  800251:	8d 4a 08             	lea    0x8(%edx),%ecx
  800254:	89 08                	mov    %ecx,(%eax)
  800256:	8b 02                	mov    (%edx),%eax
  800258:	8b 52 04             	mov    0x4(%edx),%edx
  80025b:	eb 1a                	jmp    800277 <getint+0x30>
	else if (lflag)
  80025d:	85 d2                	test   %edx,%edx
  80025f:	74 0c                	je     80026d <getint+0x26>
		return va_arg(*ap, long);
  800261:	8b 10                	mov    (%eax),%edx
  800263:	8d 4a 04             	lea    0x4(%edx),%ecx
  800266:	89 08                	mov    %ecx,(%eax)
  800268:	8b 02                	mov    (%edx),%eax
  80026a:	99                   	cltd   
  80026b:	eb 0a                	jmp    800277 <getint+0x30>
	else
		return va_arg(*ap, int);
  80026d:	8b 10                	mov    (%eax),%edx
  80026f:	8d 4a 04             	lea    0x4(%edx),%ecx
  800272:	89 08                	mov    %ecx,(%eax)
  800274:	8b 02                	mov    (%edx),%eax
  800276:	99                   	cltd   
}
  800277:	5d                   	pop    %ebp
  800278:	c3                   	ret    

00800279 <sprintputch>:
	int cnt;
};

static void
sprintputch(int ch, struct sprintbuf *b)
{
  800279:	55                   	push   %ebp
  80027a:	89 e5                	mov    %esp,%ebp
  80027c:	8b 45 0c             	mov    0xc(%ebp),%eax
	b->cnt++;
  80027f:	83 40 08 01          	addl   $0x1,0x8(%eax)
	if (b->buf < b->ebuf)
  800283:	8b 10                	mov    (%eax),%edx
  800285:	3b 50 04             	cmp    0x4(%eax),%edx
  800288:	73 0a                	jae    800294 <sprintputch+0x1b>
		*b->buf++ = ch;
  80028a:	8d 4a 01             	lea    0x1(%edx),%ecx
  80028d:	89 08                	mov    %ecx,(%eax)
  80028f:	8b 45 08             	mov    0x8(%ebp),%eax
  800292:	88 02                	mov    %al,(%edx)
}
  800294:	5d                   	pop    %ebp
  800295:	c3                   	ret    

00800296 <printfmt>:
	}
}

void
printfmt(void (*putch)(int, void*), void *putdat, const char *fmt, ...)
{
  800296:	55                   	push   %ebp
  800297:	89 e5                	mov    %esp,%ebp
  800299:	83 ec 08             	sub    $0x8,%esp
	va_list ap;

	va_start(ap, fmt);
  80029c:	8d 45 14             	lea    0x14(%ebp),%eax
	vprintfmt(putch, putdat, fmt, ap);
  80029f:	50                   	push   %eax
  8002a0:	ff 75 10             	pushl  0x10(%ebp)
  8002a3:	ff 75 0c             	pushl  0xc(%ebp)
  8002a6:	ff 75 08             	pushl  0x8(%ebp)
  8002a9:	e8 05 00 00 00       	call   8002b3 <vprintfmt>
	va_end(ap);
}
  8002ae:	83 c4 10             	add    $0x10,%esp
  8002b1:	c9                   	leave  
  8002b2:	c3                   	ret    

008002b3 <vprintfmt>:
// Main function to format and print a string.
void printfmt(void (*putch)(int, void*), void *putdat, const char *fmt, ...);

void
vprintfmt(void (*putch)(int, void*), void *putdat, const char *fmt, va_list ap)
{
  8002b3:	55                   	push   %ebp
  8002b4:	89 e5                	mov    %esp,%ebp
  8002b6:	57                   	push   %edi
  8002b7:	56                   	push   %esi
  8002b8:	53                   	push   %ebx
  8002b9:	83 ec 2c             	sub    $0x2c,%esp
  8002bc:	8b 75 08             	mov    0x8(%ebp),%esi
  8002bf:	8b 5d 0c             	mov    0xc(%ebp),%ebx
  8002c2:	8b 7d 10             	mov    0x10(%ebp),%edi
  8002c5:	eb 12                	jmp    8002d9 <vprintfmt+0x26>
	int base, lflag, width, precision, altflag;
	char padc;

	while (1) {
		while ((ch = *(unsigned char *) fmt++) != '%') {
			if (ch == '\0')
  8002c7:	85 c0                	test   %eax,%eax
  8002c9:	0f 84 44 03 00 00    	je     800613 <vprintfmt+0x360>
				return;
			putch(ch, putdat);
  8002cf:	83 ec 08             	sub    $0x8,%esp
  8002d2:	53                   	push   %ebx
  8002d3:	50                   	push   %eax
  8002d4:	ff d6                	call   *%esi
  8002d6:	83 c4 10             	add    $0x10,%esp
	unsigned long long num;
	int base, lflag, width, precision, altflag;
	char padc;

	while (1) {
		while ((ch = *(unsigned char *) fmt++) != '%') {
  8002d9:	83 c7 01             	add    $0x1,%edi
  8002dc:	0f b6 47 ff          	movzbl -0x1(%edi),%eax
  8002e0:	83 f8 25             	cmp    $0x25,%eax
  8002e3:	75 e2                	jne    8002c7 <vprintfmt+0x14>
  8002e5:	c6 45 d4 20          	movb   $0x20,-0x2c(%ebp)
  8002e9:	c7 45 d8 00 00 00 00 	movl   $0x0,-0x28(%ebp)
  8002f0:	c7 45 d0 ff ff ff ff 	movl   $0xffffffff,-0x30(%ebp)
  8002f7:	c7 45 e0 ff ff ff ff 	movl   $0xffffffff,-0x20(%ebp)
  8002fe:	ba 00 00 00 00       	mov    $0x0,%edx
  800303:	eb 07                	jmp    80030c <vprintfmt+0x59>
		width = -1;
		precision = -1;
		lflag = 0;
		altflag = 0;
	reswitch:
		switch (ch = *(unsigned char *) fmt++) {
  800305:	8b 7d e4             	mov    -0x1c(%ebp),%edi

		// flag to pad on the right
		case '-':
			padc = '-';
  800308:	c6 45 d4 2d          	movb   $0x2d,-0x2c(%ebp)
		width = -1;
		precision = -1;
		lflag = 0;
		altflag = 0;
	reswitch:
		switch (ch = *(unsigned char *) fmt++) {
  80030c:	8d 47 01             	lea    0x1(%edi),%eax
  80030f:	89 45 e4             	mov    %eax,-0x1c(%ebp)
  800312:	0f b6 07             	movzbl (%edi),%eax
  800315:	0f b6 c8             	movzbl %al,%ecx
  800318:	83 e8 23             	sub    $0x23,%eax
  80031b:	3c 55                	cmp    $0x55,%al
  80031d:	0f 87 d5 02 00 00    	ja     8005f8 <vprintfmt+0x345>
  800323:	0f b6 c0             	movzbl %al,%eax
  800326:	ff 24 85 e0 0f 80 00 	jmp    *0x800fe0(,%eax,4)
  80032d:	8b 7d e4             	mov    -0x1c(%ebp),%edi
			padc = '-';
			goto reswitch;

		// flag to pad with 0's instead of spaces
		case '0':
			padc = '0';
  800330:	c6 45 d4 30          	movb   $0x30,-0x2c(%ebp)
  800334:	eb d6                	jmp    80030c <vprintfmt+0x59>
		width = -1;
		precision = -1;
		lflag = 0;
		altflag = 0;
	reswitch:
		switch (ch = *(unsigned char *) fmt++) {
  800336:	8b 7d e4             	mov    -0x1c(%ebp),%edi
  800339:	b8 00 00 00 00       	mov    $0x0,%eax
  80033e:	89 55 e4             	mov    %edx,-0x1c(%ebp)
		case '6':
		case '7':
		case '8':
		case '9':
			for (precision = 0; ; ++fmt) {
				precision = precision * 10 + ch - '0';
  800341:	8d 04 80             	lea    (%eax,%eax,4),%eax
  800344:	8d 44 41 d0          	lea    -0x30(%ecx,%eax,2),%eax
				ch = *fmt;
  800348:	0f be 0f             	movsbl (%edi),%ecx
				if (ch < '0' || ch > '9')
  80034b:	8d 51 d0             	lea    -0x30(%ecx),%edx
  80034e:	83 fa 09             	cmp    $0x9,%edx
  800351:	77 39                	ja     80038c <vprintfmt+0xd9>
		case '5':
		case '6':
		case '7':
		case '8':
		case '9':
			for (precision = 0; ; ++fmt) {
  800353:	83 c7 01             	add    $0x1,%edi
				precision = precision * 10 + ch - '0';
				ch = *fmt;
				if (ch < '0' || ch > '9')
					break;
			}
  800356:	eb e9                	jmp    800341 <vprintfmt+0x8e>
			goto process_precision;

		case '*':
			precision = va_arg(ap, int);
  800358:	8b 45 14             	mov    0x14(%ebp),%eax
  80035b:	8d 48 04             	lea    0x4(%eax),%ecx
  80035e:	89 4d 14             	mov    %ecx,0x14(%ebp)
  800361:	8b 00                	mov    (%eax),%eax
  800363:	89 45 d0             	mov    %eax,-0x30(%ebp)
		width = -1;
		precision = -1;
		lflag = 0;
		altflag = 0;
	reswitch:
		switch (ch = *(unsigned char *) fmt++) {
  800366:	8b 7d e4             	mov    -0x1c(%ebp),%edi
			}
			goto process_precision;

		case '*':
			precision = va_arg(ap, int);
			goto process_precision;
  800369:	eb 27                	jmp    800392 <vprintfmt+0xdf>
  80036b:	8b 45 e0             	mov    -0x20(%ebp),%eax
  80036e:	85 c0                	test   %eax,%eax
  800370:	b9 00 00 00 00       	mov    $0x0,%ecx
  800375:	0f 49 c8             	cmovns %eax,%ecx
  800378:	89 4d e0             	mov    %ecx,-0x20(%ebp)
		width = -1;
		precision = -1;
		lflag = 0;
		altflag = 0;
	reswitch:
		switch (ch = *(unsigned char *) fmt++) {
  80037b:	8b 7d e4             	mov    -0x1c(%ebp),%edi
  80037e:	eb 8c                	jmp    80030c <vprintfmt+0x59>
  800380:	8b 7d e4             	mov    -0x1c(%ebp),%edi
			if (width < 0)
				width = 0;
			goto reswitch;

		case '#':
			altflag = 1;
  800383:	c7 45 d8 01 00 00 00 	movl   $0x1,-0x28(%ebp)
			goto reswitch;
  80038a:	eb 80                	jmp    80030c <vprintfmt+0x59>
  80038c:	8b 55 e4             	mov    -0x1c(%ebp),%edx
  80038f:	89 45 d0             	mov    %eax,-0x30(%ebp)

		process_precision:
			if (width < 0)
  800392:	83 7d e0 00          	cmpl   $0x0,-0x20(%ebp)
  800396:	0f 89 70 ff ff ff    	jns    80030c <vprintfmt+0x59>
				width = precision, precision = -1;
  80039c:	8b 45 d0             	mov    -0x30(%ebp),%eax
  80039f:	89 45 e0             	mov    %eax,-0x20(%ebp)
  8003a2:	c7 45 d0 ff ff ff ff 	movl   $0xffffffff,-0x30(%ebp)
  8003a9:	e9 5e ff ff ff       	jmp    80030c <vprintfmt+0x59>
			goto reswitch;

		// long flag (doubled for long long)
		case 'l':
			lflag++;
  8003ae:	83 c2 01             	add    $0x1,%edx
		width = -1;
		precision = -1;
		lflag = 0;
		altflag = 0;
	reswitch:
		switch (ch = *(unsigned char *) fmt++) {
  8003b1:	8b 7d e4             	mov    -0x1c(%ebp),%edi
			goto reswitch;

		// long flag (doubled for long long)
		case 'l':
			lflag++;
			goto reswitch;
  8003b4:	e9 53 ff ff ff       	jmp    80030c <vprintfmt+0x59>

		// character
		case 'c':
			putch(va_arg(ap, int), putdat);
  8003b9:	8b 45 14             	mov    0x14(%ebp),%eax
  8003bc:	8d 50 04             	lea    0x4(%eax),%edx
  8003bf:	89 55 14             	mov    %edx,0x14(%ebp)
  8003c2:	83 ec 08             	sub    $0x8,%esp
  8003c5:	53                   	push   %ebx
  8003c6:	ff 30                	pushl  (%eax)
  8003c8:	ff d6                	call   *%esi
			break;
  8003ca:	83 c4 10             	add    $0x10,%esp
		width = -1;
		precision = -1;
		lflag = 0;
		altflag = 0;
	reswitch:
		switch (ch = *(unsigned char *) fmt++) {
  8003cd:	8b 7d e4             	mov    -0x1c(%ebp),%edi
			goto reswitch;

		// character
		case 'c':
			putch(va_arg(ap, int), putdat);
			break;
  8003d0:	e9 04 ff ff ff       	jmp    8002d9 <vprintfmt+0x26>

		// error message
		case 'e':
			err = va_arg(ap, int);
  8003d5:	8b 45 14             	mov    0x14(%ebp),%eax
  8003d8:	8d 50 04             	lea    0x4(%eax),%edx
  8003db:	89 55 14             	mov    %edx,0x14(%ebp)
  8003de:	8b 00                	mov    (%eax),%eax
  8003e0:	99                   	cltd   
  8003e1:	31 d0                	xor    %edx,%eax
  8003e3:	29 d0                	sub    %edx,%eax
			if (err < 0)
				err = -err;
			if (err >= MAXERROR || (p = error_string[err]) == NULL)
  8003e5:	83 f8 08             	cmp    $0x8,%eax
  8003e8:	7f 0b                	jg     8003f5 <vprintfmt+0x142>
  8003ea:	8b 14 85 40 11 80 00 	mov    0x801140(,%eax,4),%edx
  8003f1:	85 d2                	test   %edx,%edx
  8003f3:	75 18                	jne    80040d <vprintfmt+0x15a>
				printfmt(putch, putdat, "error %d", err);
  8003f5:	50                   	push   %eax
  8003f6:	68 27 0f 80 00       	push   $0x800f27
  8003fb:	53                   	push   %ebx
  8003fc:	56                   	push   %esi
  8003fd:	e8 94 fe ff ff       	call   800296 <printfmt>
  800402:	83 c4 10             	add    $0x10,%esp
		width = -1;
		precision = -1;
		lflag = 0;
		altflag = 0;
	reswitch:
		switch (ch = *(unsigned char *) fmt++) {
  800405:	8b 7d e4             	mov    -0x1c(%ebp),%edi
		case 'e':
			err = va_arg(ap, int);
			if (err < 0)
				err = -err;
			if (err >= MAXERROR || (p = error_string[err]) == NULL)
				printfmt(putch, putdat, "error %d", err);
  800408:	e9 cc fe ff ff       	jmp    8002d9 <vprintfmt+0x26>
			else
				printfmt(putch, putdat, "%s", p);
  80040d:	52                   	push   %edx
  80040e:	68 30 0f 80 00       	push   $0x800f30
  800413:	53                   	push   %ebx
  800414:	56                   	push   %esi
  800415:	e8 7c fe ff ff       	call   800296 <printfmt>
  80041a:	83 c4 10             	add    $0x10,%esp
		width = -1;
		precision = -1;
		lflag = 0;
		altflag = 0;
	reswitch:
		switch (ch = *(unsigned char *) fmt++) {
  80041d:	8b 7d e4             	mov    -0x1c(%ebp),%edi
  800420:	e9 b4 fe ff ff       	jmp    8002d9 <vprintfmt+0x26>
				printfmt(putch, putdat, "%s", p);
			break;

		// string
		case 's':
			if ((p = va_arg(ap, char *)) == NULL)
  800425:	8b 45 14             	mov    0x14(%ebp),%eax
  800428:	8d 50 04             	lea    0x4(%eax),%edx
  80042b:	89 55 14             	mov    %edx,0x14(%ebp)
  80042e:	8b 38                	mov    (%eax),%edi
				p = "(null)";
  800430:	85 ff                	test   %edi,%edi
  800432:	b8 20 0f 80 00       	mov    $0x800f20,%eax
  800437:	0f 44 f8             	cmove  %eax,%edi
			if (width > 0 && padc != '-')
  80043a:	83 7d e0 00          	cmpl   $0x0,-0x20(%ebp)
  80043e:	0f 8e 94 00 00 00    	jle    8004d8 <vprintfmt+0x225>
  800444:	80 7d d4 2d          	cmpb   $0x2d,-0x2c(%ebp)
  800448:	0f 84 98 00 00 00    	je     8004e6 <vprintfmt+0x233>
				for (width -= strnlen(p, precision); width > 0; width--)
  80044e:	83 ec 08             	sub    $0x8,%esp
  800451:	ff 75 d0             	pushl  -0x30(%ebp)
  800454:	57                   	push   %edi
  800455:	e8 41 02 00 00       	call   80069b <strnlen>
  80045a:	8b 4d e0             	mov    -0x20(%ebp),%ecx
  80045d:	29 c1                	sub    %eax,%ecx
  80045f:	89 4d cc             	mov    %ecx,-0x34(%ebp)
  800462:	83 c4 10             	add    $0x10,%esp
					putch(padc, putdat);
  800465:	0f be 45 d4          	movsbl -0x2c(%ebp),%eax
  800469:	89 45 e0             	mov    %eax,-0x20(%ebp)
  80046c:	89 7d d4             	mov    %edi,-0x2c(%ebp)
  80046f:	89 cf                	mov    %ecx,%edi
		// string
		case 's':
			if ((p = va_arg(ap, char *)) == NULL)
				p = "(null)";
			if (width > 0 && padc != '-')
				for (width -= strnlen(p, precision); width > 0; width--)
  800471:	eb 0f                	jmp    800482 <vprintfmt+0x1cf>
					putch(padc, putdat);
  800473:	83 ec 08             	sub    $0x8,%esp
  800476:	53                   	push   %ebx
  800477:	ff 75 e0             	pushl  -0x20(%ebp)
  80047a:	ff d6                	call   *%esi
		// string
		case 's':
			if ((p = va_arg(ap, char *)) == NULL)
				p = "(null)";
			if (width > 0 && padc != '-')
				for (width -= strnlen(p, precision); width > 0; width--)
  80047c:	83 ef 01             	sub    $0x1,%edi
  80047f:	83 c4 10             	add    $0x10,%esp
  800482:	85 ff                	test   %edi,%edi
  800484:	7f ed                	jg     800473 <vprintfmt+0x1c0>
  800486:	8b 7d d4             	mov    -0x2c(%ebp),%edi
  800489:	8b 4d cc             	mov    -0x34(%ebp),%ecx
  80048c:	85 c9                	test   %ecx,%ecx
  80048e:	b8 00 00 00 00       	mov    $0x0,%eax
  800493:	0f 49 c1             	cmovns %ecx,%eax
  800496:	29 c1                	sub    %eax,%ecx
  800498:	89 75 08             	mov    %esi,0x8(%ebp)
  80049b:	8b 75 d0             	mov    -0x30(%ebp),%esi
  80049e:	89 5d 0c             	mov    %ebx,0xc(%ebp)
  8004a1:	89 cb                	mov    %ecx,%ebx
  8004a3:	eb 4d                	jmp    8004f2 <vprintfmt+0x23f>
					putch(padc, putdat);
			for (; (ch = *p++) != '\0' && (precision < 0 || --precision >= 0); width--)
				if (altflag && (ch < ' ' || ch > '~'))
  8004a5:	83 7d d8 00          	cmpl   $0x0,-0x28(%ebp)
  8004a9:	74 1b                	je     8004c6 <vprintfmt+0x213>
  8004ab:	0f be c0             	movsbl %al,%eax
  8004ae:	83 e8 20             	sub    $0x20,%eax
  8004b1:	83 f8 5e             	cmp    $0x5e,%eax
  8004b4:	76 10                	jbe    8004c6 <vprintfmt+0x213>
					putch('?', putdat);
  8004b6:	83 ec 08             	sub    $0x8,%esp
  8004b9:	ff 75 0c             	pushl  0xc(%ebp)
  8004bc:	6a 3f                	push   $0x3f
  8004be:	ff 55 08             	call   *0x8(%ebp)
  8004c1:	83 c4 10             	add    $0x10,%esp
  8004c4:	eb 0d                	jmp    8004d3 <vprintfmt+0x220>
				else
					putch(ch, putdat);
  8004c6:	83 ec 08             	sub    $0x8,%esp
  8004c9:	ff 75 0c             	pushl  0xc(%ebp)
  8004cc:	52                   	push   %edx
  8004cd:	ff 55 08             	call   *0x8(%ebp)
  8004d0:	83 c4 10             	add    $0x10,%esp
			if ((p = va_arg(ap, char *)) == NULL)
				p = "(null)";
			if (width > 0 && padc != '-')
				for (width -= strnlen(p, precision); width > 0; width--)
					putch(padc, putdat);
			for (; (ch = *p++) != '\0' && (precision < 0 || --precision >= 0); width--)
  8004d3:	83 eb 01             	sub    $0x1,%ebx
  8004d6:	eb 1a                	jmp    8004f2 <vprintfmt+0x23f>
  8004d8:	89 75 08             	mov    %esi,0x8(%ebp)
  8004db:	8b 75 d0             	mov    -0x30(%ebp),%esi
  8004de:	89 5d 0c             	mov    %ebx,0xc(%ebp)
  8004e1:	8b 5d e0             	mov    -0x20(%ebp),%ebx
  8004e4:	eb 0c                	jmp    8004f2 <vprintfmt+0x23f>
  8004e6:	89 75 08             	mov    %esi,0x8(%ebp)
  8004e9:	8b 75 d0             	mov    -0x30(%ebp),%esi
  8004ec:	89 5d 0c             	mov    %ebx,0xc(%ebp)
  8004ef:	8b 5d e0             	mov    -0x20(%ebp),%ebx
  8004f2:	83 c7 01             	add    $0x1,%edi
  8004f5:	0f b6 47 ff          	movzbl -0x1(%edi),%eax
  8004f9:	0f be d0             	movsbl %al,%edx
  8004fc:	85 d2                	test   %edx,%edx
  8004fe:	74 23                	je     800523 <vprintfmt+0x270>
  800500:	85 f6                	test   %esi,%esi
  800502:	78 a1                	js     8004a5 <vprintfmt+0x1f2>
  800504:	83 ee 01             	sub    $0x1,%esi
  800507:	79 9c                	jns    8004a5 <vprintfmt+0x1f2>
  800509:	89 df                	mov    %ebx,%edi
  80050b:	8b 75 08             	mov    0x8(%ebp),%esi
  80050e:	8b 5d 0c             	mov    0xc(%ebp),%ebx
  800511:	eb 18                	jmp    80052b <vprintfmt+0x278>
				if (altflag && (ch < ' ' || ch > '~'))
					putch('?', putdat);
				else
					putch(ch, putdat);
			for (; width > 0; width--)
				putch(' ', putdat);
  800513:	83 ec 08             	sub    $0x8,%esp
  800516:	53                   	push   %ebx
  800517:	6a 20                	push   $0x20
  800519:	ff d6                	call   *%esi
			for (; (ch = *p++) != '\0' && (precision < 0 || --precision >= 0); width--)
				if (altflag && (ch < ' ' || ch > '~'))
					putch('?', putdat);
				else
					putch(ch, putdat);
			for (; width > 0; width--)
  80051b:	83 ef 01             	sub    $0x1,%edi
  80051e:	83 c4 10             	add    $0x10,%esp
  800521:	eb 08                	jmp    80052b <vprintfmt+0x278>
  800523:	89 df                	mov    %ebx,%edi
  800525:	8b 75 08             	mov    0x8(%ebp),%esi
  800528:	8b 5d 0c             	mov    0xc(%ebp),%ebx
  80052b:	85 ff                	test   %edi,%edi
  80052d:	7f e4                	jg     800513 <vprintfmt+0x260>
		width = -1;
		precision = -1;
		lflag = 0;
		altflag = 0;
	reswitch:
		switch (ch = *(unsigned char *) fmt++) {
  80052f:	8b 7d e4             	mov    -0x1c(%ebp),%edi
  800532:	e9 a2 fd ff ff       	jmp    8002d9 <vprintfmt+0x26>
				putch(' ', putdat);
			break;

		// (signed) decimal
		case 'd':
			num = getint(&ap, lflag);
  800537:	8d 45 14             	lea    0x14(%ebp),%eax
  80053a:	e8 08 fd ff ff       	call   800247 <getint>
  80053f:	89 45 d8             	mov    %eax,-0x28(%ebp)
  800542:	89 55 dc             	mov    %edx,-0x24(%ebp)
			if ((long long) num < 0) {
				putch('-', putdat);
				num = -(long long) num;
			}
			base = 10;
  800545:	b9 0a 00 00 00       	mov    $0xa,%ecx
			break;

		// (signed) decimal
		case 'd':
			num = getint(&ap, lflag);
			if ((long long) num < 0) {
  80054a:	83 7d dc 00          	cmpl   $0x0,-0x24(%ebp)
  80054e:	79 74                	jns    8005c4 <vprintfmt+0x311>
				putch('-', putdat);
  800550:	83 ec 08             	sub    $0x8,%esp
  800553:	53                   	push   %ebx
  800554:	6a 2d                	push   $0x2d
  800556:	ff d6                	call   *%esi
				num = -(long long) num;
  800558:	8b 45 d8             	mov    -0x28(%ebp),%eax
  80055b:	8b 55 dc             	mov    -0x24(%ebp),%edx
  80055e:	f7 d8                	neg    %eax
  800560:	83 d2 00             	adc    $0x0,%edx
  800563:	f7 da                	neg    %edx
  800565:	83 c4 10             	add    $0x10,%esp
			}
			base = 10;
  800568:	b9 0a 00 00 00       	mov    $0xa,%ecx
  80056d:	eb 55                	jmp    8005c4 <vprintfmt+0x311>
			goto number;

		// unsigned decimal
		case 'u':
			num = getuint(&ap, lflag);
  80056f:	8d 45 14             	lea    0x14(%ebp),%eax
  800572:	e8 96 fc ff ff       	call   80020d <getuint>
			base = 10;
  800577:	b9 0a 00 00 00       	mov    $0xa,%ecx
			goto number;
  80057c:	eb 46                	jmp    8005c4 <vprintfmt+0x311>

		// (unsigned) octal
		case 'o':
			num = getuint(&ap, lflag);
  80057e:	8d 45 14             	lea    0x14(%ebp),%eax
  800581:	e8 87 fc ff ff       	call   80020d <getuint>
			base = 8;
  800586:	b9 08 00 00 00       	mov    $0x8,%ecx
			goto number;
  80058b:	eb 37                	jmp    8005c4 <vprintfmt+0x311>

		// pointer
		case 'p':
			putch('0', putdat);
  80058d:	83 ec 08             	sub    $0x8,%esp
  800590:	53                   	push   %ebx
  800591:	6a 30                	push   $0x30
  800593:	ff d6                	call   *%esi
			putch('x', putdat);
  800595:	83 c4 08             	add    $0x8,%esp
  800598:	53                   	push   %ebx
  800599:	6a 78                	push   $0x78
  80059b:	ff d6                	call   *%esi
			num = (unsigned long long)
				(uintptr_t) va_arg(ap, void *);
  80059d:	8b 45 14             	mov    0x14(%ebp),%eax
  8005a0:	8d 50 04             	lea    0x4(%eax),%edx
  8005a3:	89 55 14             	mov    %edx,0x14(%ebp)

		// pointer
		case 'p':
			putch('0', putdat);
			putch('x', putdat);
			num = (unsigned long long)
  8005a6:	8b 00                	mov    (%eax),%eax
  8005a8:	ba 00 00 00 00       	mov    $0x0,%edx
				(uintptr_t) va_arg(ap, void *);
			base = 16;
			goto number;
  8005ad:	83 c4 10             	add    $0x10,%esp
		case 'p':
			putch('0', putdat);
			putch('x', putdat);
			num = (unsigned long long)
				(uintptr_t) va_arg(ap, void *);
			base = 16;
  8005b0:	b9 10 00 00 00       	mov    $0x10,%ecx
			goto number;
  8005b5:	eb 0d                	jmp    8005c4 <vprintfmt+0x311>

		// (unsigned) hexadecimal
		case 'x':
			num = getuint(&ap, lflag);
  8005b7:	8d 45 14             	lea    0x14(%ebp),%eax
  8005ba:	e8 4e fc ff ff       	call   80020d <getuint>
			base = 16;
  8005bf:	b9 10 00 00 00       	mov    $0x10,%ecx
		number:
			printnum(putch, putdat, num, base, width, padc);
  8005c4:	83 ec 0c             	sub    $0xc,%esp
  8005c7:	0f be 7d d4          	movsbl -0x2c(%ebp),%edi
  8005cb:	57                   	push   %edi
  8005cc:	ff 75 e0             	pushl  -0x20(%ebp)
  8005cf:	51                   	push   %ecx
  8005d0:	52                   	push   %edx
  8005d1:	50                   	push   %eax
  8005d2:	89 da                	mov    %ebx,%edx
  8005d4:	89 f0                	mov    %esi,%eax
  8005d6:	e8 83 fb ff ff       	call   80015e <printnum>
			break;
  8005db:	83 c4 20             	add    $0x20,%esp
  8005de:	8b 7d e4             	mov    -0x1c(%ebp),%edi
  8005e1:	e9 f3 fc ff ff       	jmp    8002d9 <vprintfmt+0x26>

		// escaped '%' character
		case '%':
			putch(ch, putdat);
  8005e6:	83 ec 08             	sub    $0x8,%esp
  8005e9:	53                   	push   %ebx
  8005ea:	51                   	push   %ecx
  8005eb:	ff d6                	call   *%esi
			break;
  8005ed:	83 c4 10             	add    $0x10,%esp
		width = -1;
		precision = -1;
		lflag = 0;
		altflag = 0;
	reswitch:
		switch (ch = *(unsigned char *) fmt++) {
  8005f0:	8b 7d e4             	mov    -0x1c(%ebp),%edi
			break;

		// escaped '%' character
		case '%':
			putch(ch, putdat);
			break;
  8005f3:	e9 e1 fc ff ff       	jmp    8002d9 <vprintfmt+0x26>

		// unrecognized escape sequence - just print it literally
		default:
			putch('%', putdat);
  8005f8:	83 ec 08             	sub    $0x8,%esp
  8005fb:	53                   	push   %ebx
  8005fc:	6a 25                	push   $0x25
  8005fe:	ff d6                	call   *%esi
			for (fmt--; fmt[-1] != '%'; fmt--)
  800600:	83 c4 10             	add    $0x10,%esp
  800603:	eb 03                	jmp    800608 <vprintfmt+0x355>
  800605:	83 ef 01             	sub    $0x1,%edi
  800608:	80 7f ff 25          	cmpb   $0x25,-0x1(%edi)
  80060c:	75 f7                	jne    800605 <vprintfmt+0x352>
  80060e:	e9 c6 fc ff ff       	jmp    8002d9 <vprintfmt+0x26>
				/* do nothing */;
			break;
		}
	}
}
  800613:	8d 65 f4             	lea    -0xc(%ebp),%esp
  800616:	5b                   	pop    %ebx
  800617:	5e                   	pop    %esi
  800618:	5f                   	pop    %edi
  800619:	5d                   	pop    %ebp
  80061a:	c3                   	ret    

0080061b <vsnprintf>:
		*b->buf++ = ch;
}

int
vsnprintf(char *buf, int n, const char *fmt, va_list ap)
{
  80061b:	55                   	push   %ebp
  80061c:	89 e5                	mov    %esp,%ebp
  80061e:	83 ec 18             	sub    $0x18,%esp
  800621:	8b 45 08             	mov    0x8(%ebp),%eax
  800624:	8b 55 0c             	mov    0xc(%ebp),%edx
	struct sprintbuf b = {buf, buf+n-1, 0};
  800627:	89 45 ec             	mov    %eax,-0x14(%ebp)
  80062a:	8d 4c 10 ff          	lea    -0x1(%eax,%edx,1),%ecx
  80062e:	89 4d f0             	mov    %ecx,-0x10(%ebp)
  800631:	c7 45 f4 00 00 00 00 	movl   $0x0,-0xc(%ebp)

	if (buf == NULL || n < 1)
  800638:	85 c0                	test   %eax,%eax
  80063a:	74 26                	je     800662 <vsnprintf+0x47>
  80063c:	85 d2                	test   %edx,%edx
  80063e:	7e 22                	jle    800662 <vsnprintf+0x47>
		return -E_INVAL;

	// print the string to the buffer
	vprintfmt((void*)sprintputch, &b, fmt, ap);
  800640:	ff 75 14             	pushl  0x14(%ebp)
  800643:	ff 75 10             	pushl  0x10(%ebp)
  800646:	8d 45 ec             	lea    -0x14(%ebp),%eax
  800649:	50                   	push   %eax
  80064a:	68 79 02 80 00       	push   $0x800279
  80064f:	e8 5f fc ff ff       	call   8002b3 <vprintfmt>

	// null terminate the buffer
	*b.buf = '\0';
  800654:	8b 45 ec             	mov    -0x14(%ebp),%eax
  800657:	c6 00 00             	movb   $0x0,(%eax)

	return b.cnt;
  80065a:	8b 45 f4             	mov    -0xc(%ebp),%eax
  80065d:	83 c4 10             	add    $0x10,%esp
  800660:	eb 05                	jmp    800667 <vsnprintf+0x4c>
vsnprintf(char *buf, int n, const char *fmt, va_list ap)
{
	struct sprintbuf b = {buf, buf+n-1, 0};

	if (buf == NULL || n < 1)
		return -E_INVAL;
  800662:	b8 fd ff ff ff       	mov    $0xfffffffd,%eax

	// null terminate the buffer
	*b.buf = '\0';

	return b.cnt;
}
  800667:	c9                   	leave  
  800668:	c3                   	ret    

00800669 <snprintf>:

int
snprintf(char *buf, int n, const char *fmt, ...)
{
  800669:	55                   	push   %ebp
  80066a:	89 e5                	mov    %esp,%ebp
  80066c:	83 ec 08             	sub    $0x8,%esp
	va_list ap;
	int rc;

	va_start(ap, fmt);
  80066f:	8d 45 14             	lea    0x14(%ebp),%eax
	rc = vsnprintf(buf, n, fmt, ap);
  800672:	50                   	push   %eax
  800673:	ff 75 10             	pushl  0x10(%ebp)
  800676:	ff 75 0c             	pushl  0xc(%ebp)
  800679:	ff 75 08             	pushl  0x8(%ebp)
  80067c:	e8 9a ff ff ff       	call   80061b <vsnprintf>
	va_end(ap);

	return rc;
}
  800681:	c9                   	leave  
  800682:	c3                   	ret    

00800683 <strlen>:
// Primespipe runs 3x faster this way.
#define ASM 1

int
strlen(const char *s)
{
  800683:	55                   	push   %ebp
  800684:	89 e5                	mov    %esp,%ebp
  800686:	8b 55 08             	mov    0x8(%ebp),%edx
	int n;

	for (n = 0; *s != '\0'; s++)
  800689:	b8 00 00 00 00       	mov    $0x0,%eax
  80068e:	eb 03                	jmp    800693 <strlen+0x10>
		n++;
  800690:	83 c0 01             	add    $0x1,%eax
int
strlen(const char *s)
{
	int n;

	for (n = 0; *s != '\0'; s++)
  800693:	80 3c 02 00          	cmpb   $0x0,(%edx,%eax,1)
  800697:	75 f7                	jne    800690 <strlen+0xd>
		n++;
	return n;
}
  800699:	5d                   	pop    %ebp
  80069a:	c3                   	ret    

0080069b <strnlen>:

int
strnlen(const char *s, size_t size)
{
  80069b:	55                   	push   %ebp
  80069c:	89 e5                	mov    %esp,%ebp
  80069e:	8b 4d 08             	mov    0x8(%ebp),%ecx
  8006a1:	8b 45 0c             	mov    0xc(%ebp),%eax
	int n;

	for (n = 0; size > 0 && *s != '\0'; s++, size--)
  8006a4:	ba 00 00 00 00       	mov    $0x0,%edx
  8006a9:	eb 03                	jmp    8006ae <strnlen+0x13>
		n++;
  8006ab:	83 c2 01             	add    $0x1,%edx
int
strnlen(const char *s, size_t size)
{
	int n;

	for (n = 0; size > 0 && *s != '\0'; s++, size--)
  8006ae:	39 c2                	cmp    %eax,%edx
  8006b0:	74 08                	je     8006ba <strnlen+0x1f>
  8006b2:	80 3c 11 00          	cmpb   $0x0,(%ecx,%edx,1)
  8006b6:	75 f3                	jne    8006ab <strnlen+0x10>
  8006b8:	89 d0                	mov    %edx,%eax
		n++;
	return n;
}
  8006ba:	5d                   	pop    %ebp
  8006bb:	c3                   	ret    

008006bc <strcpy>:

char *
strcpy(char *dst, const char *src)
{
  8006bc:	55                   	push   %ebp
  8006bd:	89 e5                	mov    %esp,%ebp
  8006bf:	53                   	push   %ebx
  8006c0:	8b 45 08             	mov    0x8(%ebp),%eax
  8006c3:	8b 4d 0c             	mov    0xc(%ebp),%ecx
	char *ret;

	ret = dst;
	while ((*dst++ = *src++) != '\0')
  8006c6:	89 c2                	mov    %eax,%edx
  8006c8:	83 c2 01             	add    $0x1,%edx
  8006cb:	83 c1 01             	add    $0x1,%ecx
  8006ce:	0f b6 59 ff          	movzbl -0x1(%ecx),%ebx
  8006d2:	88 5a ff             	mov    %bl,-0x1(%edx)
  8006d5:	84 db                	test   %bl,%bl
  8006d7:	75 ef                	jne    8006c8 <strcpy+0xc>
		/* do nothing */;
	return ret;
}
  8006d9:	5b                   	pop    %ebx
  8006da:	5d                   	pop    %ebp
  8006db:	c3                   	ret    

008006dc <strcat>:

char *
strcat(char *dst, const char *src)
{
  8006dc:	55                   	push   %ebp
  8006dd:	89 e5                	mov    %esp,%ebp
  8006df:	53                   	push   %ebx
  8006e0:	8b 5d 08             	mov    0x8(%ebp),%ebx
	int len = strlen(dst);
  8006e3:	53                   	push   %ebx
  8006e4:	e8 9a ff ff ff       	call   800683 <strlen>
  8006e9:	83 c4 04             	add    $0x4,%esp
	strcpy(dst + len, src);
  8006ec:	ff 75 0c             	pushl  0xc(%ebp)
  8006ef:	01 d8                	add    %ebx,%eax
  8006f1:	50                   	push   %eax
  8006f2:	e8 c5 ff ff ff       	call   8006bc <strcpy>
	return dst;
}
  8006f7:	89 d8                	mov    %ebx,%eax
  8006f9:	8b 5d fc             	mov    -0x4(%ebp),%ebx
  8006fc:	c9                   	leave  
  8006fd:	c3                   	ret    

008006fe <strncpy>:

char *
strncpy(char *dst, const char *src, size_t size) {
  8006fe:	55                   	push   %ebp
  8006ff:	89 e5                	mov    %esp,%ebp
  800701:	56                   	push   %esi
  800702:	53                   	push   %ebx
  800703:	8b 75 08             	mov    0x8(%ebp),%esi
  800706:	8b 4d 0c             	mov    0xc(%ebp),%ecx
  800709:	89 f3                	mov    %esi,%ebx
  80070b:	03 5d 10             	add    0x10(%ebp),%ebx
	size_t i;
	char *ret;

	ret = dst;
	for (i = 0; i < size; i++) {
  80070e:	89 f2                	mov    %esi,%edx
  800710:	eb 0f                	jmp    800721 <strncpy+0x23>
		*dst++ = *src;
  800712:	83 c2 01             	add    $0x1,%edx
  800715:	0f b6 01             	movzbl (%ecx),%eax
  800718:	88 42 ff             	mov    %al,-0x1(%edx)
		// If strlen(src) < size, null-pad 'dst' out to 'size' chars
		if (*src != '\0')
			src++;
  80071b:	80 39 01             	cmpb   $0x1,(%ecx)
  80071e:	83 d9 ff             	sbb    $0xffffffff,%ecx
strncpy(char *dst, const char *src, size_t size) {
	size_t i;
	char *ret;

	ret = dst;
	for (i = 0; i < size; i++) {
  800721:	39 da                	cmp    %ebx,%edx
  800723:	75 ed                	jne    800712 <strncpy+0x14>
		// If strlen(src) < size, null-pad 'dst' out to 'size' chars
		if (*src != '\0')
			src++;
	}
	return ret;
}
  800725:	89 f0                	mov    %esi,%eax
  800727:	5b                   	pop    %ebx
  800728:	5e                   	pop    %esi
  800729:	5d                   	pop    %ebp
  80072a:	c3                   	ret    

0080072b <strlcpy>:

size_t
strlcpy(char *dst, const char *src, size_t size)
{
  80072b:	55                   	push   %ebp
  80072c:	89 e5                	mov    %esp,%ebp
  80072e:	56                   	push   %esi
  80072f:	53                   	push   %ebx
  800730:	8b 75 08             	mov    0x8(%ebp),%esi
  800733:	8b 4d 0c             	mov    0xc(%ebp),%ecx
  800736:	8b 55 10             	mov    0x10(%ebp),%edx
  800739:	89 f0                	mov    %esi,%eax
	char *dst_in;

	dst_in = dst;
	if (size > 0) {
  80073b:	85 d2                	test   %edx,%edx
  80073d:	74 21                	je     800760 <strlcpy+0x35>
  80073f:	8d 44 16 ff          	lea    -0x1(%esi,%edx,1),%eax
  800743:	89 f2                	mov    %esi,%edx
  800745:	eb 09                	jmp    800750 <strlcpy+0x25>
		while (--size > 0 && *src != '\0')
			*dst++ = *src++;
  800747:	83 c2 01             	add    $0x1,%edx
  80074a:	83 c1 01             	add    $0x1,%ecx
  80074d:	88 5a ff             	mov    %bl,-0x1(%edx)
{
	char *dst_in;

	dst_in = dst;
	if (size > 0) {
		while (--size > 0 && *src != '\0')
  800750:	39 c2                	cmp    %eax,%edx
  800752:	74 09                	je     80075d <strlcpy+0x32>
  800754:	0f b6 19             	movzbl (%ecx),%ebx
  800757:	84 db                	test   %bl,%bl
  800759:	75 ec                	jne    800747 <strlcpy+0x1c>
  80075b:	89 d0                	mov    %edx,%eax
			*dst++ = *src++;
		*dst = '\0';
  80075d:	c6 00 00             	movb   $0x0,(%eax)
	}
	return dst - dst_in;
  800760:	29 f0                	sub    %esi,%eax
}
  800762:	5b                   	pop    %ebx
  800763:	5e                   	pop    %esi
  800764:	5d                   	pop    %ebp
  800765:	c3                   	ret    

00800766 <strcmp>:

int
strcmp(const char *p, const char *q)
{
  800766:	55                   	push   %ebp
  800767:	89 e5                	mov    %esp,%ebp
  800769:	8b 4d 08             	mov    0x8(%ebp),%ecx
  80076c:	8b 55 0c             	mov    0xc(%ebp),%edx
	while (*p && *p == *q)
  80076f:	eb 06                	jmp    800777 <strcmp+0x11>
		p++, q++;
  800771:	83 c1 01             	add    $0x1,%ecx
  800774:	83 c2 01             	add    $0x1,%edx
}

int
strcmp(const char *p, const char *q)
{
	while (*p && *p == *q)
  800777:	0f b6 01             	movzbl (%ecx),%eax
  80077a:	84 c0                	test   %al,%al
  80077c:	74 04                	je     800782 <strcmp+0x1c>
  80077e:	3a 02                	cmp    (%edx),%al
  800780:	74 ef                	je     800771 <strcmp+0xb>
		p++, q++;
	return (int) ((unsigned char) *p - (unsigned char) *q);
  800782:	0f b6 c0             	movzbl %al,%eax
  800785:	0f b6 12             	movzbl (%edx),%edx
  800788:	29 d0                	sub    %edx,%eax
}
  80078a:	5d                   	pop    %ebp
  80078b:	c3                   	ret    

0080078c <strncmp>:

int
strncmp(const char *p, const char *q, size_t n)
{
  80078c:	55                   	push   %ebp
  80078d:	89 e5                	mov    %esp,%ebp
  80078f:	53                   	push   %ebx
  800790:	8b 45 08             	mov    0x8(%ebp),%eax
  800793:	8b 55 0c             	mov    0xc(%ebp),%edx
  800796:	89 c3                	mov    %eax,%ebx
  800798:	03 5d 10             	add    0x10(%ebp),%ebx
	while (n > 0 && *p && *p == *q)
  80079b:	eb 06                	jmp    8007a3 <strncmp+0x17>
		n--, p++, q++;
  80079d:	83 c0 01             	add    $0x1,%eax
  8007a0:	83 c2 01             	add    $0x1,%edx
}

int
strncmp(const char *p, const char *q, size_t n)
{
	while (n > 0 && *p && *p == *q)
  8007a3:	39 d8                	cmp    %ebx,%eax
  8007a5:	74 15                	je     8007bc <strncmp+0x30>
  8007a7:	0f b6 08             	movzbl (%eax),%ecx
  8007aa:	84 c9                	test   %cl,%cl
  8007ac:	74 04                	je     8007b2 <strncmp+0x26>
  8007ae:	3a 0a                	cmp    (%edx),%cl
  8007b0:	74 eb                	je     80079d <strncmp+0x11>
		n--, p++, q++;
	if (n == 0)
		return 0;
	else
		return (int) ((unsigned char) *p - (unsigned char) *q);
  8007b2:	0f b6 00             	movzbl (%eax),%eax
  8007b5:	0f b6 12             	movzbl (%edx),%edx
  8007b8:	29 d0                	sub    %edx,%eax
  8007ba:	eb 05                	jmp    8007c1 <strncmp+0x35>
strncmp(const char *p, const char *q, size_t n)
{
	while (n > 0 && *p && *p == *q)
		n--, p++, q++;
	if (n == 0)
		return 0;
  8007bc:	b8 00 00 00 00       	mov    $0x0,%eax
	else
		return (int) ((unsigned char) *p - (unsigned char) *q);
}
  8007c1:	5b                   	pop    %ebx
  8007c2:	5d                   	pop    %ebp
  8007c3:	c3                   	ret    

008007c4 <strchr>:

// Return a pointer to the first occurrence of 'c' in 's',
// or a null pointer if the string has no 'c'.
char *
strchr(const char *s, char c)
{
  8007c4:	55                   	push   %ebp
  8007c5:	89 e5                	mov    %esp,%ebp
  8007c7:	8b 45 08             	mov    0x8(%ebp),%eax
  8007ca:	0f b6 4d 0c          	movzbl 0xc(%ebp),%ecx
	for (; *s; s++)
  8007ce:	eb 07                	jmp    8007d7 <strchr+0x13>
		if (*s == c)
  8007d0:	38 ca                	cmp    %cl,%dl
  8007d2:	74 0f                	je     8007e3 <strchr+0x1f>
// Return a pointer to the first occurrence of 'c' in 's',
// or a null pointer if the string has no 'c'.
char *
strchr(const char *s, char c)
{
	for (; *s; s++)
  8007d4:	83 c0 01             	add    $0x1,%eax
  8007d7:	0f b6 10             	movzbl (%eax),%edx
  8007da:	84 d2                	test   %dl,%dl
  8007dc:	75 f2                	jne    8007d0 <strchr+0xc>
		if (*s == c)
			return (char *) s;
	return 0;
  8007de:	b8 00 00 00 00       	mov    $0x0,%eax
}
  8007e3:	5d                   	pop    %ebp
  8007e4:	c3                   	ret    

008007e5 <strfind>:

// Return a pointer to the first occurrence of 'c' in 's',
// or a pointer to the string-ending null character if the string has no 'c'.
char *
strfind(const char *s, char c)
{
  8007e5:	55                   	push   %ebp
  8007e6:	89 e5                	mov    %esp,%ebp
  8007e8:	8b 45 08             	mov    0x8(%ebp),%eax
  8007eb:	0f b6 4d 0c          	movzbl 0xc(%ebp),%ecx
	for (; *s; s++)
  8007ef:	eb 03                	jmp    8007f4 <strfind+0xf>
  8007f1:	83 c0 01             	add    $0x1,%eax
  8007f4:	0f b6 10             	movzbl (%eax),%edx
		if (*s == c)
  8007f7:	38 ca                	cmp    %cl,%dl
  8007f9:	74 04                	je     8007ff <strfind+0x1a>
  8007fb:	84 d2                	test   %dl,%dl
  8007fd:	75 f2                	jne    8007f1 <strfind+0xc>
			break;
	return (char *) s;
}
  8007ff:	5d                   	pop    %ebp
  800800:	c3                   	ret    

00800801 <memset>:

#if ASM
void *
memset(void *v, int c, size_t n)
{
  800801:	55                   	push   %ebp
  800802:	89 e5                	mov    %esp,%ebp
  800804:	57                   	push   %edi
  800805:	56                   	push   %esi
  800806:	53                   	push   %ebx
  800807:	8b 55 08             	mov    0x8(%ebp),%edx
  80080a:	8b 4d 10             	mov    0x10(%ebp),%ecx
	char *p = v;

	if (n == 0)
  80080d:	85 c9                	test   %ecx,%ecx
  80080f:	74 37                	je     800848 <memset+0x47>
		return v;
	if ((int)v%4 == 0 && n%4 == 0) {
  800811:	f6 c2 03             	test   $0x3,%dl
  800814:	75 2a                	jne    800840 <memset+0x3f>
  800816:	f6 c1 03             	test   $0x3,%cl
  800819:	75 25                	jne    800840 <memset+0x3f>
		c &= 0xFF;
  80081b:	0f b6 5d 0c          	movzbl 0xc(%ebp),%ebx
		c = (c<<24)|(c<<16)|(c<<8)|c;
  80081f:	89 df                	mov    %ebx,%edi
  800821:	c1 e7 08             	shl    $0x8,%edi
  800824:	89 de                	mov    %ebx,%esi
  800826:	c1 e6 18             	shl    $0x18,%esi
  800829:	89 d8                	mov    %ebx,%eax
  80082b:	c1 e0 10             	shl    $0x10,%eax
  80082e:	09 f0                	or     %esi,%eax
  800830:	09 c3                	or     %eax,%ebx
		asm volatile("cld; rep stosl\n"
			: "=D" (p), "=c" (n)
			: "D" (p), "a" (c), "c" (n/4)
  800832:	c1 e9 02             	shr    $0x2,%ecx
	if (n == 0)
		return v;
	if ((int)v%4 == 0 && n%4 == 0) {
		c &= 0xFF;
		c = (c<<24)|(c<<16)|(c<<8)|c;
		asm volatile("cld; rep stosl\n"
  800835:	89 f8                	mov    %edi,%eax
  800837:	09 d8                	or     %ebx,%eax
  800839:	89 d7                	mov    %edx,%edi
  80083b:	fc                   	cld    
  80083c:	f3 ab                	rep stos %eax,%es:(%edi)
  80083e:	eb 08                	jmp    800848 <memset+0x47>
			: "=D" (p), "=c" (n)
			: "D" (p), "a" (c), "c" (n/4)
			: "cc", "memory");
	} else
		asm volatile("cld; rep stosb\n"
  800840:	89 d7                	mov    %edx,%edi
  800842:	8b 45 0c             	mov    0xc(%ebp),%eax
  800845:	fc                   	cld    
  800846:	f3 aa                	rep stos %al,%es:(%edi)
			: "=D" (p), "=c" (n)
			: "0" (p), "a" (c), "1" (n)
			: "cc", "memory");
	return v;
}
  800848:	89 d0                	mov    %edx,%eax
  80084a:	5b                   	pop    %ebx
  80084b:	5e                   	pop    %esi
  80084c:	5f                   	pop    %edi
  80084d:	5d                   	pop    %ebp
  80084e:	c3                   	ret    

0080084f <memmove>:

void *
memmove(void *dst, const void *src, size_t n)
{
  80084f:	55                   	push   %ebp
  800850:	89 e5                	mov    %esp,%ebp
  800852:	57                   	push   %edi
  800853:	56                   	push   %esi
  800854:	8b 45 08             	mov    0x8(%ebp),%eax
  800857:	8b 75 0c             	mov    0xc(%ebp),%esi
  80085a:	8b 4d 10             	mov    0x10(%ebp),%ecx
	const char *s;
	char *d;

	s = src;
	d = dst;
	if (s < d && s + n > d) {
  80085d:	39 c6                	cmp    %eax,%esi
  80085f:	73 35                	jae    800896 <memmove+0x47>
  800861:	8d 14 0e             	lea    (%esi,%ecx,1),%edx
  800864:	39 d0                	cmp    %edx,%eax
  800866:	73 2e                	jae    800896 <memmove+0x47>
		s += n;
		d += n;
  800868:	8d 3c 08             	lea    (%eax,%ecx,1),%edi
		if ((int)s%4 == 0 && (int)d%4 == 0 && n%4 == 0)
  80086b:	89 d6                	mov    %edx,%esi
  80086d:	09 fe                	or     %edi,%esi
  80086f:	f7 c6 03 00 00 00    	test   $0x3,%esi
  800875:	75 13                	jne    80088a <memmove+0x3b>
  800877:	f6 c1 03             	test   $0x3,%cl
  80087a:	75 0e                	jne    80088a <memmove+0x3b>
			asm volatile("std; rep movsl\n"
  80087c:	83 ef 04             	sub    $0x4,%edi
  80087f:	8d 72 fc             	lea    -0x4(%edx),%esi
  800882:	c1 e9 02             	shr    $0x2,%ecx
  800885:	fd                   	std    
  800886:	f3 a5                	rep movsl %ds:(%esi),%es:(%edi)
  800888:	eb 09                	jmp    800893 <memmove+0x44>
				:: "D" (d-4), "S" (s-4), "c" (n/4) : "cc", "memory");
		else
			asm volatile("std; rep movsb\n"
  80088a:	83 ef 01             	sub    $0x1,%edi
  80088d:	8d 72 ff             	lea    -0x1(%edx),%esi
  800890:	fd                   	std    
  800891:	f3 a4                	rep movsb %ds:(%esi),%es:(%edi)
				:: "D" (d-1), "S" (s-1), "c" (n) : "cc", "memory");
		// Some versions of GCC rely on DF being clear
		asm volatile("cld" ::: "cc");
  800893:	fc                   	cld    
  800894:	eb 1d                	jmp    8008b3 <memmove+0x64>
	} else {
		if ((int)s%4 == 0 && (int)d%4 == 0 && n%4 == 0)
  800896:	89 f2                	mov    %esi,%edx
  800898:	09 c2                	or     %eax,%edx
  80089a:	f6 c2 03             	test   $0x3,%dl
  80089d:	75 0f                	jne    8008ae <memmove+0x5f>
  80089f:	f6 c1 03             	test   $0x3,%cl
  8008a2:	75 0a                	jne    8008ae <memmove+0x5f>
			asm volatile("cld; rep movsl\n"
  8008a4:	c1 e9 02             	shr    $0x2,%ecx
  8008a7:	89 c7                	mov    %eax,%edi
  8008a9:	fc                   	cld    
  8008aa:	f3 a5                	rep movsl %ds:(%esi),%es:(%edi)
  8008ac:	eb 05                	jmp    8008b3 <memmove+0x64>
				:: "D" (d), "S" (s), "c" (n/4) : "cc", "memory");
		else
			asm volatile("cld; rep movsb\n"
  8008ae:	89 c7                	mov    %eax,%edi
  8008b0:	fc                   	cld    
  8008b1:	f3 a4                	rep movsb %ds:(%esi),%es:(%edi)
				:: "D" (d), "S" (s), "c" (n) : "cc", "memory");
	}
	return dst;
}
  8008b3:	5e                   	pop    %esi
  8008b4:	5f                   	pop    %edi
  8008b5:	5d                   	pop    %ebp
  8008b6:	c3                   	ret    

008008b7 <memcpy>:
}
#endif

void *
memcpy(void *dst, const void *src, size_t n)
{
  8008b7:	55                   	push   %ebp
  8008b8:	89 e5                	mov    %esp,%ebp
	return memmove(dst, src, n);
  8008ba:	ff 75 10             	pushl  0x10(%ebp)
  8008bd:	ff 75 0c             	pushl  0xc(%ebp)
  8008c0:	ff 75 08             	pushl  0x8(%ebp)
  8008c3:	e8 87 ff ff ff       	call   80084f <memmove>
}
  8008c8:	c9                   	leave  
  8008c9:	c3                   	ret    

008008ca <memcmp>:

int
memcmp(const void *v1, const void *v2, size_t n)
{
  8008ca:	55                   	push   %ebp
  8008cb:	89 e5                	mov    %esp,%ebp
  8008cd:	56                   	push   %esi
  8008ce:	53                   	push   %ebx
  8008cf:	8b 45 08             	mov    0x8(%ebp),%eax
  8008d2:	8b 55 0c             	mov    0xc(%ebp),%edx
  8008d5:	89 c6                	mov    %eax,%esi
  8008d7:	03 75 10             	add    0x10(%ebp),%esi
	const uint8_t *s1 = (const uint8_t *) v1;
	const uint8_t *s2 = (const uint8_t *) v2;

	while (n-- > 0) {
  8008da:	eb 1a                	jmp    8008f6 <memcmp+0x2c>
		if (*s1 != *s2)
  8008dc:	0f b6 08             	movzbl (%eax),%ecx
  8008df:	0f b6 1a             	movzbl (%edx),%ebx
  8008e2:	38 d9                	cmp    %bl,%cl
  8008e4:	74 0a                	je     8008f0 <memcmp+0x26>
			return (int) *s1 - (int) *s2;
  8008e6:	0f b6 c1             	movzbl %cl,%eax
  8008e9:	0f b6 db             	movzbl %bl,%ebx
  8008ec:	29 d8                	sub    %ebx,%eax
  8008ee:	eb 0f                	jmp    8008ff <memcmp+0x35>
		s1++, s2++;
  8008f0:	83 c0 01             	add    $0x1,%eax
  8008f3:	83 c2 01             	add    $0x1,%edx
memcmp(const void *v1, const void *v2, size_t n)
{
	const uint8_t *s1 = (const uint8_t *) v1;
	const uint8_t *s2 = (const uint8_t *) v2;

	while (n-- > 0) {
  8008f6:	39 f0                	cmp    %esi,%eax
  8008f8:	75 e2                	jne    8008dc <memcmp+0x12>
		if (*s1 != *s2)
			return (int) *s1 - (int) *s2;
		s1++, s2++;
	}

	return 0;
  8008fa:	b8 00 00 00 00       	mov    $0x0,%eax
}
  8008ff:	5b                   	pop    %ebx
  800900:	5e                   	pop    %esi
  800901:	5d                   	pop    %ebp
  800902:	c3                   	ret    

00800903 <memfind>:

void *
memfind(const void *s, int c, size_t n)
{
  800903:	55                   	push   %ebp
  800904:	89 e5                	mov    %esp,%ebp
  800906:	8b 45 08             	mov    0x8(%ebp),%eax
  800909:	8b 4d 0c             	mov    0xc(%ebp),%ecx
	const void *ends = (const char *) s + n;
  80090c:	89 c2                	mov    %eax,%edx
  80090e:	03 55 10             	add    0x10(%ebp),%edx
	for (; s < ends; s++)
  800911:	eb 07                	jmp    80091a <memfind+0x17>
		if (*(const unsigned char *) s == (unsigned char) c)
  800913:	38 08                	cmp    %cl,(%eax)
  800915:	74 07                	je     80091e <memfind+0x1b>

void *
memfind(const void *s, int c, size_t n)
{
	const void *ends = (const char *) s + n;
	for (; s < ends; s++)
  800917:	83 c0 01             	add    $0x1,%eax
  80091a:	39 d0                	cmp    %edx,%eax
  80091c:	72 f5                	jb     800913 <memfind+0x10>
		if (*(const unsigned char *) s == (unsigned char) c)
			break;
	return (void *) s;
}
  80091e:	5d                   	pop    %ebp
  80091f:	c3                   	ret    

00800920 <strtol>:

long
strtol(const char *s, char **endptr, int base)
{
  800920:	55                   	push   %ebp
  800921:	89 e5                	mov    %esp,%ebp
  800923:	57                   	push   %edi
  800924:	56                   	push   %esi
  800925:	53                   	push   %ebx
  800926:	8b 4d 08             	mov    0x8(%ebp),%ecx
  800929:	8b 5d 10             	mov    0x10(%ebp),%ebx
	int neg = 0;
	long val = 0;

	// gobble initial whitespace
	while (*s == ' ' || *s == '\t')
  80092c:	eb 03                	jmp    800931 <strtol+0x11>
		s++;
  80092e:	83 c1 01             	add    $0x1,%ecx
{
	int neg = 0;
	long val = 0;

	// gobble initial whitespace
	while (*s == ' ' || *s == '\t')
  800931:	0f b6 01             	movzbl (%ecx),%eax
  800934:	3c 20                	cmp    $0x20,%al
  800936:	74 f6                	je     80092e <strtol+0xe>
  800938:	3c 09                	cmp    $0x9,%al
  80093a:	74 f2                	je     80092e <strtol+0xe>
		s++;

	// plus/minus sign
	if (*s == '+')
  80093c:	3c 2b                	cmp    $0x2b,%al
  80093e:	75 0a                	jne    80094a <strtol+0x2a>
		s++;
  800940:	83 c1 01             	add    $0x1,%ecx
}

long
strtol(const char *s, char **endptr, int base)
{
	int neg = 0;
  800943:	bf 00 00 00 00       	mov    $0x0,%edi
  800948:	eb 11                	jmp    80095b <strtol+0x3b>
  80094a:	bf 00 00 00 00       	mov    $0x0,%edi
		s++;

	// plus/minus sign
	if (*s == '+')
		s++;
	else if (*s == '-')
  80094f:	3c 2d                	cmp    $0x2d,%al
  800951:	75 08                	jne    80095b <strtol+0x3b>
		s++, neg = 1;
  800953:	83 c1 01             	add    $0x1,%ecx
  800956:	bf 01 00 00 00       	mov    $0x1,%edi

	// hex or octal base prefix
	if ((base == 0 || base == 16) && (s[0] == '0' && s[1] == 'x'))
  80095b:	f7 c3 ef ff ff ff    	test   $0xffffffef,%ebx
  800961:	75 15                	jne    800978 <strtol+0x58>
  800963:	80 39 30             	cmpb   $0x30,(%ecx)
  800966:	75 10                	jne    800978 <strtol+0x58>
  800968:	80 79 01 78          	cmpb   $0x78,0x1(%ecx)
  80096c:	75 7c                	jne    8009ea <strtol+0xca>
		s += 2, base = 16;
  80096e:	83 c1 02             	add    $0x2,%ecx
  800971:	bb 10 00 00 00       	mov    $0x10,%ebx
  800976:	eb 16                	jmp    80098e <strtol+0x6e>
	else if (base == 0 && s[0] == '0')
  800978:	85 db                	test   %ebx,%ebx
  80097a:	75 12                	jne    80098e <strtol+0x6e>
		s++, base = 8;
	else if (base == 0)
		base = 10;
  80097c:	bb 0a 00 00 00       	mov    $0xa,%ebx
		s++, neg = 1;

	// hex or octal base prefix
	if ((base == 0 || base == 16) && (s[0] == '0' && s[1] == 'x'))
		s += 2, base = 16;
	else if (base == 0 && s[0] == '0')
  800981:	80 39 30             	cmpb   $0x30,(%ecx)
  800984:	75 08                	jne    80098e <strtol+0x6e>
		s++, base = 8;
  800986:	83 c1 01             	add    $0x1,%ecx
  800989:	bb 08 00 00 00       	mov    $0x8,%ebx
	else if (base == 0)
		base = 10;
  80098e:	b8 00 00 00 00       	mov    $0x0,%eax
  800993:	89 5d 10             	mov    %ebx,0x10(%ebp)

	// digits
	while (1) {
		int dig;

		if (*s >= '0' && *s <= '9')
  800996:	0f b6 11             	movzbl (%ecx),%edx
  800999:	8d 72 d0             	lea    -0x30(%edx),%esi
  80099c:	89 f3                	mov    %esi,%ebx
  80099e:	80 fb 09             	cmp    $0x9,%bl
  8009a1:	77 08                	ja     8009ab <strtol+0x8b>
			dig = *s - '0';
  8009a3:	0f be d2             	movsbl %dl,%edx
  8009a6:	83 ea 30             	sub    $0x30,%edx
  8009a9:	eb 22                	jmp    8009cd <strtol+0xad>
		else if (*s >= 'a' && *s <= 'z')
  8009ab:	8d 72 9f             	lea    -0x61(%edx),%esi
  8009ae:	89 f3                	mov    %esi,%ebx
  8009b0:	80 fb 19             	cmp    $0x19,%bl
  8009b3:	77 08                	ja     8009bd <strtol+0x9d>
			dig = *s - 'a' + 10;
  8009b5:	0f be d2             	movsbl %dl,%edx
  8009b8:	83 ea 57             	sub    $0x57,%edx
  8009bb:	eb 10                	jmp    8009cd <strtol+0xad>
		else if (*s >= 'A' && *s <= 'Z')
  8009bd:	8d 72 bf             	lea    -0x41(%edx),%esi
  8009c0:	89 f3                	mov    %esi,%ebx
  8009c2:	80 fb 19             	cmp    $0x19,%bl
  8009c5:	77 16                	ja     8009dd <strtol+0xbd>
			dig = *s - 'A' + 10;
  8009c7:	0f be d2             	movsbl %dl,%edx
  8009ca:	83 ea 37             	sub    $0x37,%edx
		else
			break;
		if (dig >= base)
  8009cd:	3b 55 10             	cmp    0x10(%ebp),%edx
  8009d0:	7d 0b                	jge    8009dd <strtol+0xbd>
			break;
		s++, val = (val * base) + dig;
  8009d2:	83 c1 01             	add    $0x1,%ecx
  8009d5:	0f af 45 10          	imul   0x10(%ebp),%eax
  8009d9:	01 d0                	add    %edx,%eax
		// we don't properly detect overflow!
	}
  8009db:	eb b9                	jmp    800996 <strtol+0x76>

	if (endptr)
  8009dd:	83 7d 0c 00          	cmpl   $0x0,0xc(%ebp)
  8009e1:	74 0d                	je     8009f0 <strtol+0xd0>
		*endptr = (char *) s;
  8009e3:	8b 75 0c             	mov    0xc(%ebp),%esi
  8009e6:	89 0e                	mov    %ecx,(%esi)
  8009e8:	eb 06                	jmp    8009f0 <strtol+0xd0>
		s++, neg = 1;

	// hex or octal base prefix
	if ((base == 0 || base == 16) && (s[0] == '0' && s[1] == 'x'))
		s += 2, base = 16;
	else if (base == 0 && s[0] == '0')
  8009ea:	85 db                	test   %ebx,%ebx
  8009ec:	74 98                	je     800986 <strtol+0x66>
  8009ee:	eb 9e                	jmp    80098e <strtol+0x6e>
		// we don't properly detect overflow!
	}

	if (endptr)
		*endptr = (char *) s;
	return (neg ? -val : val);
  8009f0:	89 c2                	mov    %eax,%edx
  8009f2:	f7 da                	neg    %edx
  8009f4:	85 ff                	test   %edi,%edi
  8009f6:	0f 45 c2             	cmovne %edx,%eax
}
  8009f9:	5b                   	pop    %ebx
  8009fa:	5e                   	pop    %esi
  8009fb:	5f                   	pop    %edi
  8009fc:	5d                   	pop    %ebp
  8009fd:	c3                   	ret    

008009fe <syscall>:
#include <inc/syscall.h>
#include <inc/lib.h>

static inline int32_t
syscall(int num, int check, uint32_t a1, uint32_t a2, uint32_t a3, uint32_t a4, uint32_t a5)
{
  8009fe:	55                   	push   %ebp
  8009ff:	89 e5                	mov    %esp,%ebp
  800a01:	57                   	push   %edi
  800a02:	56                   	push   %esi
  800a03:	53                   	push   %ebx
  800a04:	83 ec 1c             	sub    $0x1c,%esp
  800a07:	89 45 e0             	mov    %eax,-0x20(%ebp)
  800a0a:	89 55 e4             	mov    %edx,-0x1c(%ebp)
  800a0d:	89 ca                	mov    %ecx,%edx
	//
	// The last clause tells the assembler that this can
	// potentially change the condition codes and arbitrary
	// memory locations.

	asm volatile("int %1\n"
  800a0f:	8b 4d 08             	mov    0x8(%ebp),%ecx
  800a12:	8b 5d 0c             	mov    0xc(%ebp),%ebx
  800a15:	8b 7d 10             	mov    0x10(%ebp),%edi
  800a18:	8b 75 14             	mov    0x14(%ebp),%esi
  800a1b:	cd 30                	int    $0x30
		       "b" (a3),
		       "D" (a4),
		       "S" (a5)
		     : "cc", "memory");

	if(check && ret > 0)
  800a1d:	83 7d e4 00          	cmpl   $0x0,-0x1c(%ebp)
  800a21:	74 1d                	je     800a40 <syscall+0x42>
  800a23:	85 c0                	test   %eax,%eax
  800a25:	7e 19                	jle    800a40 <syscall+0x42>
  800a27:	8b 55 e0             	mov    -0x20(%ebp),%edx
		panic("syscall %d returned %d (> 0)", num, ret);
  800a2a:	83 ec 0c             	sub    $0xc,%esp
  800a2d:	50                   	push   %eax
  800a2e:	52                   	push   %edx
  800a2f:	68 64 11 80 00       	push   $0x801164
  800a34:	6a 23                	push   $0x23
  800a36:	68 81 11 80 00       	push   $0x801181
  800a3b:	e8 b9 01 00 00       	call   800bf9 <_panic>

	return ret;
}
  800a40:	8d 65 f4             	lea    -0xc(%ebp),%esp
  800a43:	5b                   	pop    %ebx
  800a44:	5e                   	pop    %esi
  800a45:	5f                   	pop    %edi
  800a46:	5d                   	pop    %ebp
  800a47:	c3                   	ret    

00800a48 <sys_cputs>:

void
sys_cputs(const char *s, size_t len)
{
  800a48:	55                   	push   %ebp
  800a49:	89 e5                	mov    %esp,%ebp
  800a4b:	83 ec 08             	sub    $0x8,%esp
	syscall(SYS_cputs, 0, (uint32_t)s, len, 0, 0, 0);
  800a4e:	6a 00                	push   $0x0
  800a50:	6a 00                	push   $0x0
  800a52:	6a 00                	push   $0x0
  800a54:	ff 75 0c             	pushl  0xc(%ebp)
  800a57:	8b 4d 08             	mov    0x8(%ebp),%ecx
  800a5a:	ba 00 00 00 00       	mov    $0x0,%edx
  800a5f:	b8 00 00 00 00       	mov    $0x0,%eax
  800a64:	e8 95 ff ff ff       	call   8009fe <syscall>
}
  800a69:	83 c4 10             	add    $0x10,%esp
  800a6c:	c9                   	leave  
  800a6d:	c3                   	ret    

00800a6e <sys_cgetc>:

int
sys_cgetc(void)
{
  800a6e:	55                   	push   %ebp
  800a6f:	89 e5                	mov    %esp,%ebp
  800a71:	83 ec 08             	sub    $0x8,%esp
	return syscall(SYS_cgetc, 0, 0, 0, 0, 0, 0);
  800a74:	6a 00                	push   $0x0
  800a76:	6a 00                	push   $0x0
  800a78:	6a 00                	push   $0x0
  800a7a:	6a 00                	push   $0x0
  800a7c:	b9 00 00 00 00       	mov    $0x0,%ecx
  800a81:	ba 00 00 00 00       	mov    $0x0,%edx
  800a86:	b8 01 00 00 00       	mov    $0x1,%eax
  800a8b:	e8 6e ff ff ff       	call   8009fe <syscall>
}
  800a90:	c9                   	leave  
  800a91:	c3                   	ret    

00800a92 <sys_env_destroy>:

int
sys_env_destroy(envid_t envid)
{
  800a92:	55                   	push   %ebp
  800a93:	89 e5                	mov    %esp,%ebp
  800a95:	83 ec 08             	sub    $0x8,%esp
	return syscall(SYS_env_destroy, 1, envid, 0, 0, 0, 0);
  800a98:	6a 00                	push   $0x0
  800a9a:	6a 00                	push   $0x0
  800a9c:	6a 00                	push   $0x0
  800a9e:	6a 00                	push   $0x0
  800aa0:	8b 4d 08             	mov    0x8(%ebp),%ecx
  800aa3:	ba 01 00 00 00       	mov    $0x1,%edx
  800aa8:	b8 03 00 00 00       	mov    $0x3,%eax
  800aad:	e8 4c ff ff ff       	call   8009fe <syscall>
}
  800ab2:	c9                   	leave  
  800ab3:	c3                   	ret    

00800ab4 <sys_getenvid>:

envid_t
sys_getenvid(void)
{
  800ab4:	55                   	push   %ebp
  800ab5:	89 e5                	mov    %esp,%ebp
  800ab7:	83 ec 08             	sub    $0x8,%esp
	 return syscall(SYS_getenvid, 0, 0, 0, 0, 0, 0);
  800aba:	6a 00                	push   $0x0
  800abc:	6a 00                	push   $0x0
  800abe:	6a 00                	push   $0x0
  800ac0:	6a 00                	push   $0x0
  800ac2:	b9 00 00 00 00       	mov    $0x0,%ecx
  800ac7:	ba 00 00 00 00       	mov    $0x0,%edx
  800acc:	b8 02 00 00 00       	mov    $0x2,%eax
  800ad1:	e8 28 ff ff ff       	call   8009fe <syscall>
}
  800ad6:	c9                   	leave  
  800ad7:	c3                   	ret    

00800ad8 <sys_yield>:

void
sys_yield(void)
{
  800ad8:	55                   	push   %ebp
  800ad9:	89 e5                	mov    %esp,%ebp
  800adb:	83 ec 08             	sub    $0x8,%esp
	syscall(SYS_yield, 0, 0, 0, 0, 0, 0);
  800ade:	6a 00                	push   $0x0
  800ae0:	6a 00                	push   $0x0
  800ae2:	6a 00                	push   $0x0
  800ae4:	6a 00                	push   $0x0
  800ae6:	b9 00 00 00 00       	mov    $0x0,%ecx
  800aeb:	ba 00 00 00 00       	mov    $0x0,%edx
  800af0:	b8 0a 00 00 00       	mov    $0xa,%eax
  800af5:	e8 04 ff ff ff       	call   8009fe <syscall>
}
  800afa:	83 c4 10             	add    $0x10,%esp
  800afd:	c9                   	leave  
  800afe:	c3                   	ret    

00800aff <sys_page_alloc>:

int
sys_page_alloc(envid_t envid, void *va, int perm)
{
  800aff:	55                   	push   %ebp
  800b00:	89 e5                	mov    %esp,%ebp
  800b02:	83 ec 08             	sub    $0x8,%esp
	return syscall(SYS_page_alloc, 1, envid, (uint32_t) va, perm, 0, 0);
  800b05:	6a 00                	push   $0x0
  800b07:	6a 00                	push   $0x0
  800b09:	ff 75 10             	pushl  0x10(%ebp)
  800b0c:	ff 75 0c             	pushl  0xc(%ebp)
  800b0f:	8b 4d 08             	mov    0x8(%ebp),%ecx
  800b12:	ba 01 00 00 00       	mov    $0x1,%edx
  800b17:	b8 04 00 00 00       	mov    $0x4,%eax
  800b1c:	e8 dd fe ff ff       	call   8009fe <syscall>
}
  800b21:	c9                   	leave  
  800b22:	c3                   	ret    

00800b23 <sys_page_map>:

int
sys_page_map(envid_t srcenv, void *srcva, envid_t dstenv, void *dstva, int perm)
{
  800b23:	55                   	push   %ebp
  800b24:	89 e5                	mov    %esp,%ebp
  800b26:	83 ec 08             	sub    $0x8,%esp
	return syscall(SYS_page_map, 1, srcenv, (uint32_t) srcva, dstenv, (uint32_t) dstva, perm);
  800b29:	ff 75 18             	pushl  0x18(%ebp)
  800b2c:	ff 75 14             	pushl  0x14(%ebp)
  800b2f:	ff 75 10             	pushl  0x10(%ebp)
  800b32:	ff 75 0c             	pushl  0xc(%ebp)
  800b35:	8b 4d 08             	mov    0x8(%ebp),%ecx
  800b38:	ba 01 00 00 00       	mov    $0x1,%edx
  800b3d:	b8 05 00 00 00       	mov    $0x5,%eax
  800b42:	e8 b7 fe ff ff       	call   8009fe <syscall>
}
  800b47:	c9                   	leave  
  800b48:	c3                   	ret    

00800b49 <sys_page_unmap>:

int
sys_page_unmap(envid_t envid, void *va)
{
  800b49:	55                   	push   %ebp
  800b4a:	89 e5                	mov    %esp,%ebp
  800b4c:	83 ec 08             	sub    $0x8,%esp
	return syscall(SYS_page_unmap, 1, envid, (uint32_t) va, 0, 0, 0);
  800b4f:	6a 00                	push   $0x0
  800b51:	6a 00                	push   $0x0
  800b53:	6a 00                	push   $0x0
  800b55:	ff 75 0c             	pushl  0xc(%ebp)
  800b58:	8b 4d 08             	mov    0x8(%ebp),%ecx
  800b5b:	ba 01 00 00 00       	mov    $0x1,%edx
  800b60:	b8 06 00 00 00       	mov    $0x6,%eax
  800b65:	e8 94 fe ff ff       	call   8009fe <syscall>
}
  800b6a:	c9                   	leave  
  800b6b:	c3                   	ret    

00800b6c <sys_env_set_status>:

// sys_exofork is inlined in lib.h

int
sys_env_set_status(envid_t envid, int status)
{
  800b6c:	55                   	push   %ebp
  800b6d:	89 e5                	mov    %esp,%ebp
  800b6f:	83 ec 08             	sub    $0x8,%esp
	return syscall(SYS_env_set_status, 1, envid, status, 0, 0, 0);
  800b72:	6a 00                	push   $0x0
  800b74:	6a 00                	push   $0x0
  800b76:	6a 00                	push   $0x0
  800b78:	ff 75 0c             	pushl  0xc(%ebp)
  800b7b:	8b 4d 08             	mov    0x8(%ebp),%ecx
  800b7e:	ba 01 00 00 00       	mov    $0x1,%edx
  800b83:	b8 08 00 00 00       	mov    $0x8,%eax
  800b88:	e8 71 fe ff ff       	call   8009fe <syscall>
}
  800b8d:	c9                   	leave  
  800b8e:	c3                   	ret    

00800b8f <sys_env_set_pgfault_upcall>:

int
sys_env_set_pgfault_upcall(envid_t envid, void *upcall)
{
  800b8f:	55                   	push   %ebp
  800b90:	89 e5                	mov    %esp,%ebp
  800b92:	83 ec 08             	sub    $0x8,%esp
	return syscall(SYS_env_set_pgfault_upcall, 1, envid, (uint32_t) upcall, 0, 0, 0);
  800b95:	6a 00                	push   $0x0
  800b97:	6a 00                	push   $0x0
  800b99:	6a 00                	push   $0x0
  800b9b:	ff 75 0c             	pushl  0xc(%ebp)
  800b9e:	8b 4d 08             	mov    0x8(%ebp),%ecx
  800ba1:	ba 01 00 00 00       	mov    $0x1,%edx
  800ba6:	b8 09 00 00 00       	mov    $0x9,%eax
  800bab:	e8 4e fe ff ff       	call   8009fe <syscall>
}
  800bb0:	c9                   	leave  
  800bb1:	c3                   	ret    

00800bb2 <sys_ipc_try_send>:

int
sys_ipc_try_send(envid_t envid, uint32_t value, void *srcva, int perm)
{
  800bb2:	55                   	push   %ebp
  800bb3:	89 e5                	mov    %esp,%ebp
  800bb5:	83 ec 08             	sub    $0x8,%esp
	return syscall(SYS_ipc_try_send, 0, envid, value, (uint32_t) srcva, perm, 0);
  800bb8:	6a 00                	push   $0x0
  800bba:	ff 75 14             	pushl  0x14(%ebp)
  800bbd:	ff 75 10             	pushl  0x10(%ebp)
  800bc0:	ff 75 0c             	pushl  0xc(%ebp)
  800bc3:	8b 4d 08             	mov    0x8(%ebp),%ecx
  800bc6:	ba 00 00 00 00       	mov    $0x0,%edx
  800bcb:	b8 0b 00 00 00       	mov    $0xb,%eax
  800bd0:	e8 29 fe ff ff       	call   8009fe <syscall>
}
  800bd5:	c9                   	leave  
  800bd6:	c3                   	ret    

00800bd7 <sys_ipc_recv>:

int
sys_ipc_recv(void *dstva)
{
  800bd7:	55                   	push   %ebp
  800bd8:	89 e5                	mov    %esp,%ebp
  800bda:	83 ec 08             	sub    $0x8,%esp
	return syscall(SYS_ipc_recv, 1, (uint32_t)dstva, 0, 0, 0, 0);
  800bdd:	6a 00                	push   $0x0
  800bdf:	6a 00                	push   $0x0
  800be1:	6a 00                	push   $0x0
  800be3:	6a 00                	push   $0x0
  800be5:	8b 4d 08             	mov    0x8(%ebp),%ecx
  800be8:	ba 01 00 00 00       	mov    $0x1,%edx
  800bed:	b8 0c 00 00 00       	mov    $0xc,%eax
  800bf2:	e8 07 fe ff ff       	call   8009fe <syscall>
}
  800bf7:	c9                   	leave  
  800bf8:	c3                   	ret    

00800bf9 <_panic>:
 * It prints "panic: <message>", then causes a breakpoint exception,
 * which causes JOS to enter the JOS kernel monitor.
 */
void
_panic(const char *file, int line, const char *fmt, ...)
{
  800bf9:	55                   	push   %ebp
  800bfa:	89 e5                	mov    %esp,%ebp
  800bfc:	56                   	push   %esi
  800bfd:	53                   	push   %ebx
	va_list ap;

	va_start(ap, fmt);
  800bfe:	8d 5d 14             	lea    0x14(%ebp),%ebx

	// Print the panic message
	cprintf("[%08x] user panic in %s at %s:%d: ",
  800c01:	8b 35 00 20 80 00    	mov    0x802000,%esi
  800c07:	e8 a8 fe ff ff       	call   800ab4 <sys_getenvid>
  800c0c:	83 ec 0c             	sub    $0xc,%esp
  800c0f:	ff 75 0c             	pushl  0xc(%ebp)
  800c12:	ff 75 08             	pushl  0x8(%ebp)
  800c15:	56                   	push   %esi
  800c16:	50                   	push   %eax
  800c17:	68 90 11 80 00       	push   $0x801190
  800c1c:	e8 29 f5 ff ff       	call   80014a <cprintf>
		sys_getenvid(), binaryname, file, line);
	vcprintf(fmt, ap);
  800c21:	83 c4 18             	add    $0x18,%esp
  800c24:	53                   	push   %ebx
  800c25:	ff 75 10             	pushl  0x10(%ebp)
  800c28:	e8 cc f4 ff ff       	call   8000f9 <vcprintf>
	cprintf("\n");
  800c2d:	c7 04 24 ec 0e 80 00 	movl   $0x800eec,(%esp)
  800c34:	e8 11 f5 ff ff       	call   80014a <cprintf>
  800c39:	83 c4 10             	add    $0x10,%esp

	// Cause a breakpoint exception
	while (1)
		asm volatile("int3");
  800c3c:	cc                   	int3   
  800c3d:	eb fd                	jmp    800c3c <_panic+0x43>
  800c3f:	90                   	nop

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
