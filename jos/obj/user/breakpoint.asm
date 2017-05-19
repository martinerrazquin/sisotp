
obj/user/breakpoint:     file format elf32-i386


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
  80002c:	e8 08 00 00 00       	call   800039 <libmain>
1:	jmp 1b
  800031:	eb fe                	jmp    800031 <args_exist+0x5>

00800033 <umain>:

#include <inc/lib.h>

void
umain(int argc, char **argv)
{
  800033:	55                   	push   %ebp
  800034:	89 e5                	mov    %esp,%ebp
	asm volatile("int $3");
  800036:	cc                   	int3   
}
  800037:	5d                   	pop    %ebp
  800038:	c3                   	ret    

00800039 <libmain>:
const volatile struct Env *thisenv;
const char *binaryname = "<unknown>";

void
libmain(int argc, char **argv)
{
  800039:	55                   	push   %ebp
  80003a:	89 e5                	mov    %esp,%ebp
  80003c:	83 ec 08             	sub    $0x8,%esp
  80003f:	8b 45 08             	mov    0x8(%ebp),%eax
  800042:	8b 55 0c             	mov    0xc(%ebp),%edx
	// set thisenv to point at our Env structure in envs[].
	// LAB 3: Your code here.
	thisenv = 0;
  800045:	c7 05 04 10 80 00 00 	movl   $0x0,0x801004
  80004c:	00 00 00 

	// save the name of the program so that panic() can use it
	if (argc > 0)
  80004f:	85 c0                	test   %eax,%eax
  800051:	7e 08                	jle    80005b <libmain+0x22>
		binaryname = argv[0];
  800053:	8b 0a                	mov    (%edx),%ecx
  800055:	89 0d 00 10 80 00    	mov    %ecx,0x801000

	// call user main routine
	umain(argc, argv);
  80005b:	83 ec 08             	sub    $0x8,%esp
  80005e:	52                   	push   %edx
  80005f:	50                   	push   %eax
  800060:	e8 ce ff ff ff       	call   800033 <umain>

	// exit gracefully
	exit();
  800065:	e8 05 00 00 00       	call   80006f <exit>
}
  80006a:	83 c4 10             	add    $0x10,%esp
  80006d:	c9                   	leave  
  80006e:	c3                   	ret    

0080006f <exit>:

#include <inc/lib.h>

void
exit(void)
{
  80006f:	55                   	push   %ebp
  800070:	89 e5                	mov    %esp,%ebp
  800072:	83 ec 14             	sub    $0x14,%esp
	sys_env_destroy(0);
  800075:	6a 00                	push   $0x0
  800077:	e8 99 00 00 00       	call   800115 <sys_env_destroy>
}
  80007c:	83 c4 10             	add    $0x10,%esp
  80007f:	c9                   	leave  
  800080:	c3                   	ret    

00800081 <syscall>:
#include <inc/syscall.h>
#include <inc/lib.h>

static inline int32_t
syscall(int num, int check, uint32_t a1, uint32_t a2, uint32_t a3, uint32_t a4, uint32_t a5)
{
  800081:	55                   	push   %ebp
  800082:	89 e5                	mov    %esp,%ebp
  800084:	57                   	push   %edi
  800085:	56                   	push   %esi
  800086:	53                   	push   %ebx
  800087:	83 ec 1c             	sub    $0x1c,%esp
  80008a:	89 45 e0             	mov    %eax,-0x20(%ebp)
  80008d:	89 55 e4             	mov    %edx,-0x1c(%ebp)
  800090:	89 ca                	mov    %ecx,%edx
	//
	// The last clause tells the assembler that this can
	// potentially change the condition codes and arbitrary
	// memory locations.

	asm volatile("int %1\n"
  800092:	8b 4d 08             	mov    0x8(%ebp),%ecx
  800095:	8b 5d 0c             	mov    0xc(%ebp),%ebx
  800098:	8b 7d 10             	mov    0x10(%ebp),%edi
  80009b:	8b 75 14             	mov    0x14(%ebp),%esi
  80009e:	cd 30                	int    $0x30
		       "b" (a3),
		       "D" (a4),
		       "S" (a5)
		     : "cc", "memory");

	if(check && ret > 0)
  8000a0:	83 7d e4 00          	cmpl   $0x0,-0x1c(%ebp)
  8000a4:	74 1d                	je     8000c3 <syscall+0x42>
  8000a6:	85 c0                	test   %eax,%eax
  8000a8:	7e 19                	jle    8000c3 <syscall+0x42>
  8000aa:	8b 55 e0             	mov    -0x20(%ebp),%edx
		panic("syscall %d returned %d (> 0)", num, ret);
  8000ad:	83 ec 0c             	sub    $0xc,%esp
  8000b0:	50                   	push   %eax
  8000b1:	52                   	push   %edx
  8000b2:	68 7e 0d 80 00       	push   $0x800d7e
  8000b7:	6a 23                	push   $0x23
  8000b9:	68 9b 0d 80 00       	push   $0x800d9b
  8000be:	e8 98 00 00 00       	call   80015b <_panic>

	return ret;
}
  8000c3:	8d 65 f4             	lea    -0xc(%ebp),%esp
  8000c6:	5b                   	pop    %ebx
  8000c7:	5e                   	pop    %esi
  8000c8:	5f                   	pop    %edi
  8000c9:	5d                   	pop    %ebp
  8000ca:	c3                   	ret    

008000cb <sys_cputs>:

void
sys_cputs(const char *s, size_t len)
{
  8000cb:	55                   	push   %ebp
  8000cc:	89 e5                	mov    %esp,%ebp
  8000ce:	83 ec 08             	sub    $0x8,%esp
	syscall(SYS_cputs, 0, (uint32_t)s, len, 0, 0, 0);
  8000d1:	6a 00                	push   $0x0
  8000d3:	6a 00                	push   $0x0
  8000d5:	6a 00                	push   $0x0
  8000d7:	ff 75 0c             	pushl  0xc(%ebp)
  8000da:	8b 4d 08             	mov    0x8(%ebp),%ecx
  8000dd:	ba 00 00 00 00       	mov    $0x0,%edx
  8000e2:	b8 00 00 00 00       	mov    $0x0,%eax
  8000e7:	e8 95 ff ff ff       	call   800081 <syscall>
}
  8000ec:	83 c4 10             	add    $0x10,%esp
  8000ef:	c9                   	leave  
  8000f0:	c3                   	ret    

008000f1 <sys_cgetc>:

int
sys_cgetc(void)
{
  8000f1:	55                   	push   %ebp
  8000f2:	89 e5                	mov    %esp,%ebp
  8000f4:	83 ec 08             	sub    $0x8,%esp
	return syscall(SYS_cgetc, 0, 0, 0, 0, 0, 0);
  8000f7:	6a 00                	push   $0x0
  8000f9:	6a 00                	push   $0x0
  8000fb:	6a 00                	push   $0x0
  8000fd:	6a 00                	push   $0x0
  8000ff:	b9 00 00 00 00       	mov    $0x0,%ecx
  800104:	ba 00 00 00 00       	mov    $0x0,%edx
  800109:	b8 01 00 00 00       	mov    $0x1,%eax
  80010e:	e8 6e ff ff ff       	call   800081 <syscall>
}
  800113:	c9                   	leave  
  800114:	c3                   	ret    

00800115 <sys_env_destroy>:

int
sys_env_destroy(envid_t envid)
{
  800115:	55                   	push   %ebp
  800116:	89 e5                	mov    %esp,%ebp
  800118:	83 ec 08             	sub    $0x8,%esp
	return syscall(SYS_env_destroy, 1, envid, 0, 0, 0, 0);
  80011b:	6a 00                	push   $0x0
  80011d:	6a 00                	push   $0x0
  80011f:	6a 00                	push   $0x0
  800121:	6a 00                	push   $0x0
  800123:	8b 4d 08             	mov    0x8(%ebp),%ecx
  800126:	ba 01 00 00 00       	mov    $0x1,%edx
  80012b:	b8 03 00 00 00       	mov    $0x3,%eax
  800130:	e8 4c ff ff ff       	call   800081 <syscall>
}
  800135:	c9                   	leave  
  800136:	c3                   	ret    

00800137 <sys_getenvid>:

envid_t
sys_getenvid(void)
{
  800137:	55                   	push   %ebp
  800138:	89 e5                	mov    %esp,%ebp
  80013a:	83 ec 08             	sub    $0x8,%esp
	 return syscall(SYS_getenvid, 0, 0, 0, 0, 0, 0);
  80013d:	6a 00                	push   $0x0
  80013f:	6a 00                	push   $0x0
  800141:	6a 00                	push   $0x0
  800143:	6a 00                	push   $0x0
  800145:	b9 00 00 00 00       	mov    $0x0,%ecx
  80014a:	ba 00 00 00 00       	mov    $0x0,%edx
  80014f:	b8 02 00 00 00       	mov    $0x2,%eax
  800154:	e8 28 ff ff ff       	call   800081 <syscall>
}
  800159:	c9                   	leave  
  80015a:	c3                   	ret    

0080015b <_panic>:
 * It prints "panic: <message>", then causes a breakpoint exception,
 * which causes JOS to enter the JOS kernel monitor.
 */
void
_panic(const char *file, int line, const char *fmt, ...)
{
  80015b:	55                   	push   %ebp
  80015c:	89 e5                	mov    %esp,%ebp
  80015e:	56                   	push   %esi
  80015f:	53                   	push   %ebx
	va_list ap;

	va_start(ap, fmt);
  800160:	8d 5d 14             	lea    0x14(%ebp),%ebx

	// Print the panic message
	cprintf("[%08x] user panic in %s at %s:%d: ",
  800163:	8b 35 00 10 80 00    	mov    0x801000,%esi
  800169:	e8 c9 ff ff ff       	call   800137 <sys_getenvid>
  80016e:	83 ec 0c             	sub    $0xc,%esp
  800171:	ff 75 0c             	pushl  0xc(%ebp)
  800174:	ff 75 08             	pushl  0x8(%ebp)
  800177:	56                   	push   %esi
  800178:	50                   	push   %eax
  800179:	68 ac 0d 80 00       	push   $0x800dac
  80017e:	e8 b1 00 00 00       	call   800234 <cprintf>
		sys_getenvid(), binaryname, file, line);
	vcprintf(fmt, ap);
  800183:	83 c4 18             	add    $0x18,%esp
  800186:	53                   	push   %ebx
  800187:	ff 75 10             	pushl  0x10(%ebp)
  80018a:	e8 54 00 00 00       	call   8001e3 <vcprintf>
	cprintf("\n");
  80018f:	c7 04 24 d0 0d 80 00 	movl   $0x800dd0,(%esp)
  800196:	e8 99 00 00 00       	call   800234 <cprintf>
  80019b:	83 c4 10             	add    $0x10,%esp

	// Cause a breakpoint exception
	while (1)
		asm volatile("int3");
  80019e:	cc                   	int3   
  80019f:	eb fd                	jmp    80019e <_panic+0x43>

008001a1 <putch>:
};


static void
putch(int ch, struct printbuf *b)
{
  8001a1:	55                   	push   %ebp
  8001a2:	89 e5                	mov    %esp,%ebp
  8001a4:	53                   	push   %ebx
  8001a5:	83 ec 04             	sub    $0x4,%esp
  8001a8:	8b 5d 0c             	mov    0xc(%ebp),%ebx
	b->buf[b->idx++] = ch;
  8001ab:	8b 13                	mov    (%ebx),%edx
  8001ad:	8d 42 01             	lea    0x1(%edx),%eax
  8001b0:	89 03                	mov    %eax,(%ebx)
  8001b2:	8b 4d 08             	mov    0x8(%ebp),%ecx
  8001b5:	88 4c 13 08          	mov    %cl,0x8(%ebx,%edx,1)
	if (b->idx == 256-1) {
  8001b9:	3d ff 00 00 00       	cmp    $0xff,%eax
  8001be:	75 1a                	jne    8001da <putch+0x39>
		sys_cputs(b->buf, b->idx);
  8001c0:	83 ec 08             	sub    $0x8,%esp
  8001c3:	68 ff 00 00 00       	push   $0xff
  8001c8:	8d 43 08             	lea    0x8(%ebx),%eax
  8001cb:	50                   	push   %eax
  8001cc:	e8 fa fe ff ff       	call   8000cb <sys_cputs>
		b->idx = 0;
  8001d1:	c7 03 00 00 00 00    	movl   $0x0,(%ebx)
  8001d7:	83 c4 10             	add    $0x10,%esp
	}
	b->cnt++;
  8001da:	83 43 04 01          	addl   $0x1,0x4(%ebx)
}
  8001de:	8b 5d fc             	mov    -0x4(%ebp),%ebx
  8001e1:	c9                   	leave  
  8001e2:	c3                   	ret    

008001e3 <vcprintf>:

int
vcprintf(const char *fmt, va_list ap)
{
  8001e3:	55                   	push   %ebp
  8001e4:	89 e5                	mov    %esp,%ebp
  8001e6:	81 ec 18 01 00 00    	sub    $0x118,%esp
	struct printbuf b;

	b.idx = 0;
  8001ec:	c7 85 f0 fe ff ff 00 	movl   $0x0,-0x110(%ebp)
  8001f3:	00 00 00 
	b.cnt = 0;
  8001f6:	c7 85 f4 fe ff ff 00 	movl   $0x0,-0x10c(%ebp)
  8001fd:	00 00 00 
	vprintfmt((void*)putch, &b, fmt, ap);
  800200:	ff 75 0c             	pushl  0xc(%ebp)
  800203:	ff 75 08             	pushl  0x8(%ebp)
  800206:	8d 85 f0 fe ff ff    	lea    -0x110(%ebp),%eax
  80020c:	50                   	push   %eax
  80020d:	68 a1 01 80 00       	push   $0x8001a1
  800212:	e8 86 01 00 00       	call   80039d <vprintfmt>
	sys_cputs(b.buf, b.idx);
  800217:	83 c4 08             	add    $0x8,%esp
  80021a:	ff b5 f0 fe ff ff    	pushl  -0x110(%ebp)
  800220:	8d 85 f8 fe ff ff    	lea    -0x108(%ebp),%eax
  800226:	50                   	push   %eax
  800227:	e8 9f fe ff ff       	call   8000cb <sys_cputs>

	return b.cnt;
}
  80022c:	8b 85 f4 fe ff ff    	mov    -0x10c(%ebp),%eax
  800232:	c9                   	leave  
  800233:	c3                   	ret    

00800234 <cprintf>:

int
cprintf(const char *fmt, ...)
{
  800234:	55                   	push   %ebp
  800235:	89 e5                	mov    %esp,%ebp
  800237:	83 ec 10             	sub    $0x10,%esp
	va_list ap;
	int cnt;

	va_start(ap, fmt);
  80023a:	8d 45 0c             	lea    0xc(%ebp),%eax
	cnt = vcprintf(fmt, ap);
  80023d:	50                   	push   %eax
  80023e:	ff 75 08             	pushl  0x8(%ebp)
  800241:	e8 9d ff ff ff       	call   8001e3 <vcprintf>
	va_end(ap);

	return cnt;
}
  800246:	c9                   	leave  
  800247:	c3                   	ret    

00800248 <printnum>:
 * using specified putch function and associated pointer putdat.
 */
static void
printnum(void (*putch)(int, void*), void *putdat,
	 unsigned long long num, unsigned base, int width, int padc)
{
  800248:	55                   	push   %ebp
  800249:	89 e5                	mov    %esp,%ebp
  80024b:	57                   	push   %edi
  80024c:	56                   	push   %esi
  80024d:	53                   	push   %ebx
  80024e:	83 ec 1c             	sub    $0x1c,%esp
  800251:	89 c7                	mov    %eax,%edi
  800253:	89 d6                	mov    %edx,%esi
  800255:	8b 45 08             	mov    0x8(%ebp),%eax
  800258:	8b 55 0c             	mov    0xc(%ebp),%edx
  80025b:	89 45 d8             	mov    %eax,-0x28(%ebp)
  80025e:	89 55 dc             	mov    %edx,-0x24(%ebp)
	// first recursively print all preceding (more significant) digits
	if (num >= base) {
  800261:	8b 4d 10             	mov    0x10(%ebp),%ecx
  800264:	bb 00 00 00 00       	mov    $0x0,%ebx
  800269:	89 4d e0             	mov    %ecx,-0x20(%ebp)
  80026c:	89 5d e4             	mov    %ebx,-0x1c(%ebp)
  80026f:	39 d3                	cmp    %edx,%ebx
  800271:	72 05                	jb     800278 <printnum+0x30>
  800273:	39 45 10             	cmp    %eax,0x10(%ebp)
  800276:	77 45                	ja     8002bd <printnum+0x75>
		printnum(putch, putdat, num / base, base, width - 1, padc);
  800278:	83 ec 0c             	sub    $0xc,%esp
  80027b:	ff 75 18             	pushl  0x18(%ebp)
  80027e:	8b 45 14             	mov    0x14(%ebp),%eax
  800281:	8d 58 ff             	lea    -0x1(%eax),%ebx
  800284:	53                   	push   %ebx
  800285:	ff 75 10             	pushl  0x10(%ebp)
  800288:	83 ec 08             	sub    $0x8,%esp
  80028b:	ff 75 e4             	pushl  -0x1c(%ebp)
  80028e:	ff 75 e0             	pushl  -0x20(%ebp)
  800291:	ff 75 dc             	pushl  -0x24(%ebp)
  800294:	ff 75 d8             	pushl  -0x28(%ebp)
  800297:	e8 54 08 00 00       	call   800af0 <__udivdi3>
  80029c:	83 c4 18             	add    $0x18,%esp
  80029f:	52                   	push   %edx
  8002a0:	50                   	push   %eax
  8002a1:	89 f2                	mov    %esi,%edx
  8002a3:	89 f8                	mov    %edi,%eax
  8002a5:	e8 9e ff ff ff       	call   800248 <printnum>
  8002aa:	83 c4 20             	add    $0x20,%esp
  8002ad:	eb 18                	jmp    8002c7 <printnum+0x7f>
	} else {
		// print any needed pad characters before first digit
		while (--width > 0)
			putch(padc, putdat);
  8002af:	83 ec 08             	sub    $0x8,%esp
  8002b2:	56                   	push   %esi
  8002b3:	ff 75 18             	pushl  0x18(%ebp)
  8002b6:	ff d7                	call   *%edi
  8002b8:	83 c4 10             	add    $0x10,%esp
  8002bb:	eb 03                	jmp    8002c0 <printnum+0x78>
  8002bd:	8b 5d 14             	mov    0x14(%ebp),%ebx
	// first recursively print all preceding (more significant) digits
	if (num >= base) {
		printnum(putch, putdat, num / base, base, width - 1, padc);
	} else {
		// print any needed pad characters before first digit
		while (--width > 0)
  8002c0:	83 eb 01             	sub    $0x1,%ebx
  8002c3:	85 db                	test   %ebx,%ebx
  8002c5:	7f e8                	jg     8002af <printnum+0x67>
			putch(padc, putdat);
	}

	// then print this (the least significant) digit
	putch("0123456789abcdef"[num % base], putdat);
  8002c7:	83 ec 08             	sub    $0x8,%esp
  8002ca:	56                   	push   %esi
  8002cb:	83 ec 04             	sub    $0x4,%esp
  8002ce:	ff 75 e4             	pushl  -0x1c(%ebp)
  8002d1:	ff 75 e0             	pushl  -0x20(%ebp)
  8002d4:	ff 75 dc             	pushl  -0x24(%ebp)
  8002d7:	ff 75 d8             	pushl  -0x28(%ebp)
  8002da:	e8 41 09 00 00       	call   800c20 <__umoddi3>
  8002df:	83 c4 14             	add    $0x14,%esp
  8002e2:	0f be 80 d2 0d 80 00 	movsbl 0x800dd2(%eax),%eax
  8002e9:	50                   	push   %eax
  8002ea:	ff d7                	call   *%edi
}
  8002ec:	83 c4 10             	add    $0x10,%esp
  8002ef:	8d 65 f4             	lea    -0xc(%ebp),%esp
  8002f2:	5b                   	pop    %ebx
  8002f3:	5e                   	pop    %esi
  8002f4:	5f                   	pop    %edi
  8002f5:	5d                   	pop    %ebp
  8002f6:	c3                   	ret    

008002f7 <getuint>:

// Get an unsigned int of various possible sizes from a varargs list,
// depending on the lflag parameter.
static unsigned long long
getuint(va_list *ap, int lflag)
{
  8002f7:	55                   	push   %ebp
  8002f8:	89 e5                	mov    %esp,%ebp
	if (lflag >= 2)
  8002fa:	83 fa 01             	cmp    $0x1,%edx
  8002fd:	7e 0e                	jle    80030d <getuint+0x16>
		return va_arg(*ap, unsigned long long);
  8002ff:	8b 10                	mov    (%eax),%edx
  800301:	8d 4a 08             	lea    0x8(%edx),%ecx
  800304:	89 08                	mov    %ecx,(%eax)
  800306:	8b 02                	mov    (%edx),%eax
  800308:	8b 52 04             	mov    0x4(%edx),%edx
  80030b:	eb 22                	jmp    80032f <getuint+0x38>
	else if (lflag)
  80030d:	85 d2                	test   %edx,%edx
  80030f:	74 10                	je     800321 <getuint+0x2a>
		return va_arg(*ap, unsigned long);
  800311:	8b 10                	mov    (%eax),%edx
  800313:	8d 4a 04             	lea    0x4(%edx),%ecx
  800316:	89 08                	mov    %ecx,(%eax)
  800318:	8b 02                	mov    (%edx),%eax
  80031a:	ba 00 00 00 00       	mov    $0x0,%edx
  80031f:	eb 0e                	jmp    80032f <getuint+0x38>
	else
		return va_arg(*ap, unsigned int);
  800321:	8b 10                	mov    (%eax),%edx
  800323:	8d 4a 04             	lea    0x4(%edx),%ecx
  800326:	89 08                	mov    %ecx,(%eax)
  800328:	8b 02                	mov    (%edx),%eax
  80032a:	ba 00 00 00 00       	mov    $0x0,%edx
}
  80032f:	5d                   	pop    %ebp
  800330:	c3                   	ret    

00800331 <getint>:

// Same as getuint but signed - can't use getuint
// because of sign extension
static long long
getint(va_list *ap, int lflag)
{
  800331:	55                   	push   %ebp
  800332:	89 e5                	mov    %esp,%ebp
	if (lflag >= 2)
  800334:	83 fa 01             	cmp    $0x1,%edx
  800337:	7e 0e                	jle    800347 <getint+0x16>
		return va_arg(*ap, long long);
  800339:	8b 10                	mov    (%eax),%edx
  80033b:	8d 4a 08             	lea    0x8(%edx),%ecx
  80033e:	89 08                	mov    %ecx,(%eax)
  800340:	8b 02                	mov    (%edx),%eax
  800342:	8b 52 04             	mov    0x4(%edx),%edx
  800345:	eb 1a                	jmp    800361 <getint+0x30>
	else if (lflag)
  800347:	85 d2                	test   %edx,%edx
  800349:	74 0c                	je     800357 <getint+0x26>
		return va_arg(*ap, long);
  80034b:	8b 10                	mov    (%eax),%edx
  80034d:	8d 4a 04             	lea    0x4(%edx),%ecx
  800350:	89 08                	mov    %ecx,(%eax)
  800352:	8b 02                	mov    (%edx),%eax
  800354:	99                   	cltd   
  800355:	eb 0a                	jmp    800361 <getint+0x30>
	else
		return va_arg(*ap, int);
  800357:	8b 10                	mov    (%eax),%edx
  800359:	8d 4a 04             	lea    0x4(%edx),%ecx
  80035c:	89 08                	mov    %ecx,(%eax)
  80035e:	8b 02                	mov    (%edx),%eax
  800360:	99                   	cltd   
}
  800361:	5d                   	pop    %ebp
  800362:	c3                   	ret    

00800363 <sprintputch>:
	int cnt;
};

static void
sprintputch(int ch, struct sprintbuf *b)
{
  800363:	55                   	push   %ebp
  800364:	89 e5                	mov    %esp,%ebp
  800366:	8b 45 0c             	mov    0xc(%ebp),%eax
	b->cnt++;
  800369:	83 40 08 01          	addl   $0x1,0x8(%eax)
	if (b->buf < b->ebuf)
  80036d:	8b 10                	mov    (%eax),%edx
  80036f:	3b 50 04             	cmp    0x4(%eax),%edx
  800372:	73 0a                	jae    80037e <sprintputch+0x1b>
		*b->buf++ = ch;
  800374:	8d 4a 01             	lea    0x1(%edx),%ecx
  800377:	89 08                	mov    %ecx,(%eax)
  800379:	8b 45 08             	mov    0x8(%ebp),%eax
  80037c:	88 02                	mov    %al,(%edx)
}
  80037e:	5d                   	pop    %ebp
  80037f:	c3                   	ret    

00800380 <printfmt>:
	}
}

void
printfmt(void (*putch)(int, void*), void *putdat, const char *fmt, ...)
{
  800380:	55                   	push   %ebp
  800381:	89 e5                	mov    %esp,%ebp
  800383:	83 ec 08             	sub    $0x8,%esp
	va_list ap;

	va_start(ap, fmt);
  800386:	8d 45 14             	lea    0x14(%ebp),%eax
	vprintfmt(putch, putdat, fmt, ap);
  800389:	50                   	push   %eax
  80038a:	ff 75 10             	pushl  0x10(%ebp)
  80038d:	ff 75 0c             	pushl  0xc(%ebp)
  800390:	ff 75 08             	pushl  0x8(%ebp)
  800393:	e8 05 00 00 00       	call   80039d <vprintfmt>
	va_end(ap);
}
  800398:	83 c4 10             	add    $0x10,%esp
  80039b:	c9                   	leave  
  80039c:	c3                   	ret    

0080039d <vprintfmt>:
// Main function to format and print a string.
void printfmt(void (*putch)(int, void*), void *putdat, const char *fmt, ...);

void
vprintfmt(void (*putch)(int, void*), void *putdat, const char *fmt, va_list ap)
{
  80039d:	55                   	push   %ebp
  80039e:	89 e5                	mov    %esp,%ebp
  8003a0:	57                   	push   %edi
  8003a1:	56                   	push   %esi
  8003a2:	53                   	push   %ebx
  8003a3:	83 ec 2c             	sub    $0x2c,%esp
  8003a6:	8b 75 08             	mov    0x8(%ebp),%esi
  8003a9:	8b 5d 0c             	mov    0xc(%ebp),%ebx
  8003ac:	8b 7d 10             	mov    0x10(%ebp),%edi
  8003af:	eb 12                	jmp    8003c3 <vprintfmt+0x26>
	int base, lflag, width, precision, altflag;
	char padc;

	while (1) {
		while ((ch = *(unsigned char *) fmt++) != '%') {
			if (ch == '\0')
  8003b1:	85 c0                	test   %eax,%eax
  8003b3:	0f 84 44 03 00 00    	je     8006fd <vprintfmt+0x360>
				return;
			putch(ch, putdat);
  8003b9:	83 ec 08             	sub    $0x8,%esp
  8003bc:	53                   	push   %ebx
  8003bd:	50                   	push   %eax
  8003be:	ff d6                	call   *%esi
  8003c0:	83 c4 10             	add    $0x10,%esp
	unsigned long long num;
	int base, lflag, width, precision, altflag;
	char padc;

	while (1) {
		while ((ch = *(unsigned char *) fmt++) != '%') {
  8003c3:	83 c7 01             	add    $0x1,%edi
  8003c6:	0f b6 47 ff          	movzbl -0x1(%edi),%eax
  8003ca:	83 f8 25             	cmp    $0x25,%eax
  8003cd:	75 e2                	jne    8003b1 <vprintfmt+0x14>
  8003cf:	c6 45 d4 20          	movb   $0x20,-0x2c(%ebp)
  8003d3:	c7 45 d8 00 00 00 00 	movl   $0x0,-0x28(%ebp)
  8003da:	c7 45 d0 ff ff ff ff 	movl   $0xffffffff,-0x30(%ebp)
  8003e1:	c7 45 e0 ff ff ff ff 	movl   $0xffffffff,-0x20(%ebp)
  8003e8:	ba 00 00 00 00       	mov    $0x0,%edx
  8003ed:	eb 07                	jmp    8003f6 <vprintfmt+0x59>
		width = -1;
		precision = -1;
		lflag = 0;
		altflag = 0;
	reswitch:
		switch (ch = *(unsigned char *) fmt++) {
  8003ef:	8b 7d e4             	mov    -0x1c(%ebp),%edi

		// flag to pad on the right
		case '-':
			padc = '-';
  8003f2:	c6 45 d4 2d          	movb   $0x2d,-0x2c(%ebp)
		width = -1;
		precision = -1;
		lflag = 0;
		altflag = 0;
	reswitch:
		switch (ch = *(unsigned char *) fmt++) {
  8003f6:	8d 47 01             	lea    0x1(%edi),%eax
  8003f9:	89 45 e4             	mov    %eax,-0x1c(%ebp)
  8003fc:	0f b6 07             	movzbl (%edi),%eax
  8003ff:	0f b6 c8             	movzbl %al,%ecx
  800402:	83 e8 23             	sub    $0x23,%eax
  800405:	3c 55                	cmp    $0x55,%al
  800407:	0f 87 d5 02 00 00    	ja     8006e2 <vprintfmt+0x345>
  80040d:	0f b6 c0             	movzbl %al,%eax
  800410:	ff 24 85 60 0e 80 00 	jmp    *0x800e60(,%eax,4)
  800417:	8b 7d e4             	mov    -0x1c(%ebp),%edi
			padc = '-';
			goto reswitch;

		// flag to pad with 0's instead of spaces
		case '0':
			padc = '0';
  80041a:	c6 45 d4 30          	movb   $0x30,-0x2c(%ebp)
  80041e:	eb d6                	jmp    8003f6 <vprintfmt+0x59>
		width = -1;
		precision = -1;
		lflag = 0;
		altflag = 0;
	reswitch:
		switch (ch = *(unsigned char *) fmt++) {
  800420:	8b 7d e4             	mov    -0x1c(%ebp),%edi
  800423:	b8 00 00 00 00       	mov    $0x0,%eax
  800428:	89 55 e4             	mov    %edx,-0x1c(%ebp)
		case '6':
		case '7':
		case '8':
		case '9':
			for (precision = 0; ; ++fmt) {
				precision = precision * 10 + ch - '0';
  80042b:	8d 04 80             	lea    (%eax,%eax,4),%eax
  80042e:	8d 44 41 d0          	lea    -0x30(%ecx,%eax,2),%eax
				ch = *fmt;
  800432:	0f be 0f             	movsbl (%edi),%ecx
				if (ch < '0' || ch > '9')
  800435:	8d 51 d0             	lea    -0x30(%ecx),%edx
  800438:	83 fa 09             	cmp    $0x9,%edx
  80043b:	77 39                	ja     800476 <vprintfmt+0xd9>
		case '5':
		case '6':
		case '7':
		case '8':
		case '9':
			for (precision = 0; ; ++fmt) {
  80043d:	83 c7 01             	add    $0x1,%edi
				precision = precision * 10 + ch - '0';
				ch = *fmt;
				if (ch < '0' || ch > '9')
					break;
			}
  800440:	eb e9                	jmp    80042b <vprintfmt+0x8e>
			goto process_precision;

		case '*':
			precision = va_arg(ap, int);
  800442:	8b 45 14             	mov    0x14(%ebp),%eax
  800445:	8d 48 04             	lea    0x4(%eax),%ecx
  800448:	89 4d 14             	mov    %ecx,0x14(%ebp)
  80044b:	8b 00                	mov    (%eax),%eax
  80044d:	89 45 d0             	mov    %eax,-0x30(%ebp)
		width = -1;
		precision = -1;
		lflag = 0;
		altflag = 0;
	reswitch:
		switch (ch = *(unsigned char *) fmt++) {
  800450:	8b 7d e4             	mov    -0x1c(%ebp),%edi
			}
			goto process_precision;

		case '*':
			precision = va_arg(ap, int);
			goto process_precision;
  800453:	eb 27                	jmp    80047c <vprintfmt+0xdf>
  800455:	8b 45 e0             	mov    -0x20(%ebp),%eax
  800458:	85 c0                	test   %eax,%eax
  80045a:	b9 00 00 00 00       	mov    $0x0,%ecx
  80045f:	0f 49 c8             	cmovns %eax,%ecx
  800462:	89 4d e0             	mov    %ecx,-0x20(%ebp)
		width = -1;
		precision = -1;
		lflag = 0;
		altflag = 0;
	reswitch:
		switch (ch = *(unsigned char *) fmt++) {
  800465:	8b 7d e4             	mov    -0x1c(%ebp),%edi
  800468:	eb 8c                	jmp    8003f6 <vprintfmt+0x59>
  80046a:	8b 7d e4             	mov    -0x1c(%ebp),%edi
			if (width < 0)
				width = 0;
			goto reswitch;

		case '#':
			altflag = 1;
  80046d:	c7 45 d8 01 00 00 00 	movl   $0x1,-0x28(%ebp)
			goto reswitch;
  800474:	eb 80                	jmp    8003f6 <vprintfmt+0x59>
  800476:	8b 55 e4             	mov    -0x1c(%ebp),%edx
  800479:	89 45 d0             	mov    %eax,-0x30(%ebp)

		process_precision:
			if (width < 0)
  80047c:	83 7d e0 00          	cmpl   $0x0,-0x20(%ebp)
  800480:	0f 89 70 ff ff ff    	jns    8003f6 <vprintfmt+0x59>
				width = precision, precision = -1;
  800486:	8b 45 d0             	mov    -0x30(%ebp),%eax
  800489:	89 45 e0             	mov    %eax,-0x20(%ebp)
  80048c:	c7 45 d0 ff ff ff ff 	movl   $0xffffffff,-0x30(%ebp)
  800493:	e9 5e ff ff ff       	jmp    8003f6 <vprintfmt+0x59>
			goto reswitch;

		// long flag (doubled for long long)
		case 'l':
			lflag++;
  800498:	83 c2 01             	add    $0x1,%edx
		width = -1;
		precision = -1;
		lflag = 0;
		altflag = 0;
	reswitch:
		switch (ch = *(unsigned char *) fmt++) {
  80049b:	8b 7d e4             	mov    -0x1c(%ebp),%edi
			goto reswitch;

		// long flag (doubled for long long)
		case 'l':
			lflag++;
			goto reswitch;
  80049e:	e9 53 ff ff ff       	jmp    8003f6 <vprintfmt+0x59>

		// character
		case 'c':
			putch(va_arg(ap, int), putdat);
  8004a3:	8b 45 14             	mov    0x14(%ebp),%eax
  8004a6:	8d 50 04             	lea    0x4(%eax),%edx
  8004a9:	89 55 14             	mov    %edx,0x14(%ebp)
  8004ac:	83 ec 08             	sub    $0x8,%esp
  8004af:	53                   	push   %ebx
  8004b0:	ff 30                	pushl  (%eax)
  8004b2:	ff d6                	call   *%esi
			break;
  8004b4:	83 c4 10             	add    $0x10,%esp
		width = -1;
		precision = -1;
		lflag = 0;
		altflag = 0;
	reswitch:
		switch (ch = *(unsigned char *) fmt++) {
  8004b7:	8b 7d e4             	mov    -0x1c(%ebp),%edi
			goto reswitch;

		// character
		case 'c':
			putch(va_arg(ap, int), putdat);
			break;
  8004ba:	e9 04 ff ff ff       	jmp    8003c3 <vprintfmt+0x26>

		// error message
		case 'e':
			err = va_arg(ap, int);
  8004bf:	8b 45 14             	mov    0x14(%ebp),%eax
  8004c2:	8d 50 04             	lea    0x4(%eax),%edx
  8004c5:	89 55 14             	mov    %edx,0x14(%ebp)
  8004c8:	8b 00                	mov    (%eax),%eax
  8004ca:	99                   	cltd   
  8004cb:	31 d0                	xor    %edx,%eax
  8004cd:	29 d0                	sub    %edx,%eax
			if (err < 0)
				err = -err;
			if (err >= MAXERROR || (p = error_string[err]) == NULL)
  8004cf:	83 f8 06             	cmp    $0x6,%eax
  8004d2:	7f 0b                	jg     8004df <vprintfmt+0x142>
  8004d4:	8b 14 85 b8 0f 80 00 	mov    0x800fb8(,%eax,4),%edx
  8004db:	85 d2                	test   %edx,%edx
  8004dd:	75 18                	jne    8004f7 <vprintfmt+0x15a>
				printfmt(putch, putdat, "error %d", err);
  8004df:	50                   	push   %eax
  8004e0:	68 ea 0d 80 00       	push   $0x800dea
  8004e5:	53                   	push   %ebx
  8004e6:	56                   	push   %esi
  8004e7:	e8 94 fe ff ff       	call   800380 <printfmt>
  8004ec:	83 c4 10             	add    $0x10,%esp
		width = -1;
		precision = -1;
		lflag = 0;
		altflag = 0;
	reswitch:
		switch (ch = *(unsigned char *) fmt++) {
  8004ef:	8b 7d e4             	mov    -0x1c(%ebp),%edi
		case 'e':
			err = va_arg(ap, int);
			if (err < 0)
				err = -err;
			if (err >= MAXERROR || (p = error_string[err]) == NULL)
				printfmt(putch, putdat, "error %d", err);
  8004f2:	e9 cc fe ff ff       	jmp    8003c3 <vprintfmt+0x26>
			else
				printfmt(putch, putdat, "%s", p);
  8004f7:	52                   	push   %edx
  8004f8:	68 f3 0d 80 00       	push   $0x800df3
  8004fd:	53                   	push   %ebx
  8004fe:	56                   	push   %esi
  8004ff:	e8 7c fe ff ff       	call   800380 <printfmt>
  800504:	83 c4 10             	add    $0x10,%esp
		width = -1;
		precision = -1;
		lflag = 0;
		altflag = 0;
	reswitch:
		switch (ch = *(unsigned char *) fmt++) {
  800507:	8b 7d e4             	mov    -0x1c(%ebp),%edi
  80050a:	e9 b4 fe ff ff       	jmp    8003c3 <vprintfmt+0x26>
				printfmt(putch, putdat, "%s", p);
			break;

		// string
		case 's':
			if ((p = va_arg(ap, char *)) == NULL)
  80050f:	8b 45 14             	mov    0x14(%ebp),%eax
  800512:	8d 50 04             	lea    0x4(%eax),%edx
  800515:	89 55 14             	mov    %edx,0x14(%ebp)
  800518:	8b 38                	mov    (%eax),%edi
				p = "(null)";
  80051a:	85 ff                	test   %edi,%edi
  80051c:	b8 e3 0d 80 00       	mov    $0x800de3,%eax
  800521:	0f 44 f8             	cmove  %eax,%edi
			if (width > 0 && padc != '-')
  800524:	83 7d e0 00          	cmpl   $0x0,-0x20(%ebp)
  800528:	0f 8e 94 00 00 00    	jle    8005c2 <vprintfmt+0x225>
  80052e:	80 7d d4 2d          	cmpb   $0x2d,-0x2c(%ebp)
  800532:	0f 84 98 00 00 00    	je     8005d0 <vprintfmt+0x233>
				for (width -= strnlen(p, precision); width > 0; width--)
  800538:	83 ec 08             	sub    $0x8,%esp
  80053b:	ff 75 d0             	pushl  -0x30(%ebp)
  80053e:	57                   	push   %edi
  80053f:	e8 41 02 00 00       	call   800785 <strnlen>
  800544:	8b 4d e0             	mov    -0x20(%ebp),%ecx
  800547:	29 c1                	sub    %eax,%ecx
  800549:	89 4d cc             	mov    %ecx,-0x34(%ebp)
  80054c:	83 c4 10             	add    $0x10,%esp
					putch(padc, putdat);
  80054f:	0f be 45 d4          	movsbl -0x2c(%ebp),%eax
  800553:	89 45 e0             	mov    %eax,-0x20(%ebp)
  800556:	89 7d d4             	mov    %edi,-0x2c(%ebp)
  800559:	89 cf                	mov    %ecx,%edi
		// string
		case 's':
			if ((p = va_arg(ap, char *)) == NULL)
				p = "(null)";
			if (width > 0 && padc != '-')
				for (width -= strnlen(p, precision); width > 0; width--)
  80055b:	eb 0f                	jmp    80056c <vprintfmt+0x1cf>
					putch(padc, putdat);
  80055d:	83 ec 08             	sub    $0x8,%esp
  800560:	53                   	push   %ebx
  800561:	ff 75 e0             	pushl  -0x20(%ebp)
  800564:	ff d6                	call   *%esi
		// string
		case 's':
			if ((p = va_arg(ap, char *)) == NULL)
				p = "(null)";
			if (width > 0 && padc != '-')
				for (width -= strnlen(p, precision); width > 0; width--)
  800566:	83 ef 01             	sub    $0x1,%edi
  800569:	83 c4 10             	add    $0x10,%esp
  80056c:	85 ff                	test   %edi,%edi
  80056e:	7f ed                	jg     80055d <vprintfmt+0x1c0>
  800570:	8b 7d d4             	mov    -0x2c(%ebp),%edi
  800573:	8b 4d cc             	mov    -0x34(%ebp),%ecx
  800576:	85 c9                	test   %ecx,%ecx
  800578:	b8 00 00 00 00       	mov    $0x0,%eax
  80057d:	0f 49 c1             	cmovns %ecx,%eax
  800580:	29 c1                	sub    %eax,%ecx
  800582:	89 75 08             	mov    %esi,0x8(%ebp)
  800585:	8b 75 d0             	mov    -0x30(%ebp),%esi
  800588:	89 5d 0c             	mov    %ebx,0xc(%ebp)
  80058b:	89 cb                	mov    %ecx,%ebx
  80058d:	eb 4d                	jmp    8005dc <vprintfmt+0x23f>
					putch(padc, putdat);
			for (; (ch = *p++) != '\0' && (precision < 0 || --precision >= 0); width--)
				if (altflag && (ch < ' ' || ch > '~'))
  80058f:	83 7d d8 00          	cmpl   $0x0,-0x28(%ebp)
  800593:	74 1b                	je     8005b0 <vprintfmt+0x213>
  800595:	0f be c0             	movsbl %al,%eax
  800598:	83 e8 20             	sub    $0x20,%eax
  80059b:	83 f8 5e             	cmp    $0x5e,%eax
  80059e:	76 10                	jbe    8005b0 <vprintfmt+0x213>
					putch('?', putdat);
  8005a0:	83 ec 08             	sub    $0x8,%esp
  8005a3:	ff 75 0c             	pushl  0xc(%ebp)
  8005a6:	6a 3f                	push   $0x3f
  8005a8:	ff 55 08             	call   *0x8(%ebp)
  8005ab:	83 c4 10             	add    $0x10,%esp
  8005ae:	eb 0d                	jmp    8005bd <vprintfmt+0x220>
				else
					putch(ch, putdat);
  8005b0:	83 ec 08             	sub    $0x8,%esp
  8005b3:	ff 75 0c             	pushl  0xc(%ebp)
  8005b6:	52                   	push   %edx
  8005b7:	ff 55 08             	call   *0x8(%ebp)
  8005ba:	83 c4 10             	add    $0x10,%esp
			if ((p = va_arg(ap, char *)) == NULL)
				p = "(null)";
			if (width > 0 && padc != '-')
				for (width -= strnlen(p, precision); width > 0; width--)
					putch(padc, putdat);
			for (; (ch = *p++) != '\0' && (precision < 0 || --precision >= 0); width--)
  8005bd:	83 eb 01             	sub    $0x1,%ebx
  8005c0:	eb 1a                	jmp    8005dc <vprintfmt+0x23f>
  8005c2:	89 75 08             	mov    %esi,0x8(%ebp)
  8005c5:	8b 75 d0             	mov    -0x30(%ebp),%esi
  8005c8:	89 5d 0c             	mov    %ebx,0xc(%ebp)
  8005cb:	8b 5d e0             	mov    -0x20(%ebp),%ebx
  8005ce:	eb 0c                	jmp    8005dc <vprintfmt+0x23f>
  8005d0:	89 75 08             	mov    %esi,0x8(%ebp)
  8005d3:	8b 75 d0             	mov    -0x30(%ebp),%esi
  8005d6:	89 5d 0c             	mov    %ebx,0xc(%ebp)
  8005d9:	8b 5d e0             	mov    -0x20(%ebp),%ebx
  8005dc:	83 c7 01             	add    $0x1,%edi
  8005df:	0f b6 47 ff          	movzbl -0x1(%edi),%eax
  8005e3:	0f be d0             	movsbl %al,%edx
  8005e6:	85 d2                	test   %edx,%edx
  8005e8:	74 23                	je     80060d <vprintfmt+0x270>
  8005ea:	85 f6                	test   %esi,%esi
  8005ec:	78 a1                	js     80058f <vprintfmt+0x1f2>
  8005ee:	83 ee 01             	sub    $0x1,%esi
  8005f1:	79 9c                	jns    80058f <vprintfmt+0x1f2>
  8005f3:	89 df                	mov    %ebx,%edi
  8005f5:	8b 75 08             	mov    0x8(%ebp),%esi
  8005f8:	8b 5d 0c             	mov    0xc(%ebp),%ebx
  8005fb:	eb 18                	jmp    800615 <vprintfmt+0x278>
				if (altflag && (ch < ' ' || ch > '~'))
					putch('?', putdat);
				else
					putch(ch, putdat);
			for (; width > 0; width--)
				putch(' ', putdat);
  8005fd:	83 ec 08             	sub    $0x8,%esp
  800600:	53                   	push   %ebx
  800601:	6a 20                	push   $0x20
  800603:	ff d6                	call   *%esi
			for (; (ch = *p++) != '\0' && (precision < 0 || --precision >= 0); width--)
				if (altflag && (ch < ' ' || ch > '~'))
					putch('?', putdat);
				else
					putch(ch, putdat);
			for (; width > 0; width--)
  800605:	83 ef 01             	sub    $0x1,%edi
  800608:	83 c4 10             	add    $0x10,%esp
  80060b:	eb 08                	jmp    800615 <vprintfmt+0x278>
  80060d:	89 df                	mov    %ebx,%edi
  80060f:	8b 75 08             	mov    0x8(%ebp),%esi
  800612:	8b 5d 0c             	mov    0xc(%ebp),%ebx
  800615:	85 ff                	test   %edi,%edi
  800617:	7f e4                	jg     8005fd <vprintfmt+0x260>
		width = -1;
		precision = -1;
		lflag = 0;
		altflag = 0;
	reswitch:
		switch (ch = *(unsigned char *) fmt++) {
  800619:	8b 7d e4             	mov    -0x1c(%ebp),%edi
  80061c:	e9 a2 fd ff ff       	jmp    8003c3 <vprintfmt+0x26>
				putch(' ', putdat);
			break;

		// (signed) decimal
		case 'd':
			num = getint(&ap, lflag);
  800621:	8d 45 14             	lea    0x14(%ebp),%eax
  800624:	e8 08 fd ff ff       	call   800331 <getint>
  800629:	89 45 d8             	mov    %eax,-0x28(%ebp)
  80062c:	89 55 dc             	mov    %edx,-0x24(%ebp)
			if ((long long) num < 0) {
				putch('-', putdat);
				num = -(long long) num;
			}
			base = 10;
  80062f:	b9 0a 00 00 00       	mov    $0xa,%ecx
			break;

		// (signed) decimal
		case 'd':
			num = getint(&ap, lflag);
			if ((long long) num < 0) {
  800634:	83 7d dc 00          	cmpl   $0x0,-0x24(%ebp)
  800638:	79 74                	jns    8006ae <vprintfmt+0x311>
				putch('-', putdat);
  80063a:	83 ec 08             	sub    $0x8,%esp
  80063d:	53                   	push   %ebx
  80063e:	6a 2d                	push   $0x2d
  800640:	ff d6                	call   *%esi
				num = -(long long) num;
  800642:	8b 45 d8             	mov    -0x28(%ebp),%eax
  800645:	8b 55 dc             	mov    -0x24(%ebp),%edx
  800648:	f7 d8                	neg    %eax
  80064a:	83 d2 00             	adc    $0x0,%edx
  80064d:	f7 da                	neg    %edx
  80064f:	83 c4 10             	add    $0x10,%esp
			}
			base = 10;
  800652:	b9 0a 00 00 00       	mov    $0xa,%ecx
  800657:	eb 55                	jmp    8006ae <vprintfmt+0x311>
			goto number;

		// unsigned decimal
		case 'u':
			num = getuint(&ap, lflag);
  800659:	8d 45 14             	lea    0x14(%ebp),%eax
  80065c:	e8 96 fc ff ff       	call   8002f7 <getuint>
			base = 10;
  800661:	b9 0a 00 00 00       	mov    $0xa,%ecx
			goto number;
  800666:	eb 46                	jmp    8006ae <vprintfmt+0x311>

		// (unsigned) octal
		case 'o':
			num = getuint(&ap, lflag);
  800668:	8d 45 14             	lea    0x14(%ebp),%eax
  80066b:	e8 87 fc ff ff       	call   8002f7 <getuint>
			base = 8;
  800670:	b9 08 00 00 00       	mov    $0x8,%ecx
			goto number;
  800675:	eb 37                	jmp    8006ae <vprintfmt+0x311>

		// pointer
		case 'p':
			putch('0', putdat);
  800677:	83 ec 08             	sub    $0x8,%esp
  80067a:	53                   	push   %ebx
  80067b:	6a 30                	push   $0x30
  80067d:	ff d6                	call   *%esi
			putch('x', putdat);
  80067f:	83 c4 08             	add    $0x8,%esp
  800682:	53                   	push   %ebx
  800683:	6a 78                	push   $0x78
  800685:	ff d6                	call   *%esi
			num = (unsigned long long)
				(uintptr_t) va_arg(ap, void *);
  800687:	8b 45 14             	mov    0x14(%ebp),%eax
  80068a:	8d 50 04             	lea    0x4(%eax),%edx
  80068d:	89 55 14             	mov    %edx,0x14(%ebp)

		// pointer
		case 'p':
			putch('0', putdat);
			putch('x', putdat);
			num = (unsigned long long)
  800690:	8b 00                	mov    (%eax),%eax
  800692:	ba 00 00 00 00       	mov    $0x0,%edx
				(uintptr_t) va_arg(ap, void *);
			base = 16;
			goto number;
  800697:	83 c4 10             	add    $0x10,%esp
		case 'p':
			putch('0', putdat);
			putch('x', putdat);
			num = (unsigned long long)
				(uintptr_t) va_arg(ap, void *);
			base = 16;
  80069a:	b9 10 00 00 00       	mov    $0x10,%ecx
			goto number;
  80069f:	eb 0d                	jmp    8006ae <vprintfmt+0x311>

		// (unsigned) hexadecimal
		case 'x':
			num = getuint(&ap, lflag);
  8006a1:	8d 45 14             	lea    0x14(%ebp),%eax
  8006a4:	e8 4e fc ff ff       	call   8002f7 <getuint>
			base = 16;
  8006a9:	b9 10 00 00 00       	mov    $0x10,%ecx
		number:
			printnum(putch, putdat, num, base, width, padc);
  8006ae:	83 ec 0c             	sub    $0xc,%esp
  8006b1:	0f be 7d d4          	movsbl -0x2c(%ebp),%edi
  8006b5:	57                   	push   %edi
  8006b6:	ff 75 e0             	pushl  -0x20(%ebp)
  8006b9:	51                   	push   %ecx
  8006ba:	52                   	push   %edx
  8006bb:	50                   	push   %eax
  8006bc:	89 da                	mov    %ebx,%edx
  8006be:	89 f0                	mov    %esi,%eax
  8006c0:	e8 83 fb ff ff       	call   800248 <printnum>
			break;
  8006c5:	83 c4 20             	add    $0x20,%esp
  8006c8:	8b 7d e4             	mov    -0x1c(%ebp),%edi
  8006cb:	e9 f3 fc ff ff       	jmp    8003c3 <vprintfmt+0x26>

		// escaped '%' character
		case '%':
			putch(ch, putdat);
  8006d0:	83 ec 08             	sub    $0x8,%esp
  8006d3:	53                   	push   %ebx
  8006d4:	51                   	push   %ecx
  8006d5:	ff d6                	call   *%esi
			break;
  8006d7:	83 c4 10             	add    $0x10,%esp
		width = -1;
		precision = -1;
		lflag = 0;
		altflag = 0;
	reswitch:
		switch (ch = *(unsigned char *) fmt++) {
  8006da:	8b 7d e4             	mov    -0x1c(%ebp),%edi
			break;

		// escaped '%' character
		case '%':
			putch(ch, putdat);
			break;
  8006dd:	e9 e1 fc ff ff       	jmp    8003c3 <vprintfmt+0x26>

		// unrecognized escape sequence - just print it literally
		default:
			putch('%', putdat);
  8006e2:	83 ec 08             	sub    $0x8,%esp
  8006e5:	53                   	push   %ebx
  8006e6:	6a 25                	push   $0x25
  8006e8:	ff d6                	call   *%esi
			for (fmt--; fmt[-1] != '%'; fmt--)
  8006ea:	83 c4 10             	add    $0x10,%esp
  8006ed:	eb 03                	jmp    8006f2 <vprintfmt+0x355>
  8006ef:	83 ef 01             	sub    $0x1,%edi
  8006f2:	80 7f ff 25          	cmpb   $0x25,-0x1(%edi)
  8006f6:	75 f7                	jne    8006ef <vprintfmt+0x352>
  8006f8:	e9 c6 fc ff ff       	jmp    8003c3 <vprintfmt+0x26>
				/* do nothing */;
			break;
		}
	}
}
  8006fd:	8d 65 f4             	lea    -0xc(%ebp),%esp
  800700:	5b                   	pop    %ebx
  800701:	5e                   	pop    %esi
  800702:	5f                   	pop    %edi
  800703:	5d                   	pop    %ebp
  800704:	c3                   	ret    

00800705 <vsnprintf>:
		*b->buf++ = ch;
}

int
vsnprintf(char *buf, int n, const char *fmt, va_list ap)
{
  800705:	55                   	push   %ebp
  800706:	89 e5                	mov    %esp,%ebp
  800708:	83 ec 18             	sub    $0x18,%esp
  80070b:	8b 45 08             	mov    0x8(%ebp),%eax
  80070e:	8b 55 0c             	mov    0xc(%ebp),%edx
	struct sprintbuf b = {buf, buf+n-1, 0};
  800711:	89 45 ec             	mov    %eax,-0x14(%ebp)
  800714:	8d 4c 10 ff          	lea    -0x1(%eax,%edx,1),%ecx
  800718:	89 4d f0             	mov    %ecx,-0x10(%ebp)
  80071b:	c7 45 f4 00 00 00 00 	movl   $0x0,-0xc(%ebp)

	if (buf == NULL || n < 1)
  800722:	85 c0                	test   %eax,%eax
  800724:	74 26                	je     80074c <vsnprintf+0x47>
  800726:	85 d2                	test   %edx,%edx
  800728:	7e 22                	jle    80074c <vsnprintf+0x47>
		return -E_INVAL;

	// print the string to the buffer
	vprintfmt((void*)sprintputch, &b, fmt, ap);
  80072a:	ff 75 14             	pushl  0x14(%ebp)
  80072d:	ff 75 10             	pushl  0x10(%ebp)
  800730:	8d 45 ec             	lea    -0x14(%ebp),%eax
  800733:	50                   	push   %eax
  800734:	68 63 03 80 00       	push   $0x800363
  800739:	e8 5f fc ff ff       	call   80039d <vprintfmt>

	// null terminate the buffer
	*b.buf = '\0';
  80073e:	8b 45 ec             	mov    -0x14(%ebp),%eax
  800741:	c6 00 00             	movb   $0x0,(%eax)

	return b.cnt;
  800744:	8b 45 f4             	mov    -0xc(%ebp),%eax
  800747:	83 c4 10             	add    $0x10,%esp
  80074a:	eb 05                	jmp    800751 <vsnprintf+0x4c>
vsnprintf(char *buf, int n, const char *fmt, va_list ap)
{
	struct sprintbuf b = {buf, buf+n-1, 0};

	if (buf == NULL || n < 1)
		return -E_INVAL;
  80074c:	b8 fd ff ff ff       	mov    $0xfffffffd,%eax

	// null terminate the buffer
	*b.buf = '\0';

	return b.cnt;
}
  800751:	c9                   	leave  
  800752:	c3                   	ret    

00800753 <snprintf>:

int
snprintf(char *buf, int n, const char *fmt, ...)
{
  800753:	55                   	push   %ebp
  800754:	89 e5                	mov    %esp,%ebp
  800756:	83 ec 08             	sub    $0x8,%esp
	va_list ap;
	int rc;

	va_start(ap, fmt);
  800759:	8d 45 14             	lea    0x14(%ebp),%eax
	rc = vsnprintf(buf, n, fmt, ap);
  80075c:	50                   	push   %eax
  80075d:	ff 75 10             	pushl  0x10(%ebp)
  800760:	ff 75 0c             	pushl  0xc(%ebp)
  800763:	ff 75 08             	pushl  0x8(%ebp)
  800766:	e8 9a ff ff ff       	call   800705 <vsnprintf>
	va_end(ap);

	return rc;
}
  80076b:	c9                   	leave  
  80076c:	c3                   	ret    

0080076d <strlen>:
// Primespipe runs 3x faster this way.
#define ASM 1

int
strlen(const char *s)
{
  80076d:	55                   	push   %ebp
  80076e:	89 e5                	mov    %esp,%ebp
  800770:	8b 55 08             	mov    0x8(%ebp),%edx
	int n;

	for (n = 0; *s != '\0'; s++)
  800773:	b8 00 00 00 00       	mov    $0x0,%eax
  800778:	eb 03                	jmp    80077d <strlen+0x10>
		n++;
  80077a:	83 c0 01             	add    $0x1,%eax
int
strlen(const char *s)
{
	int n;

	for (n = 0; *s != '\0'; s++)
  80077d:	80 3c 02 00          	cmpb   $0x0,(%edx,%eax,1)
  800781:	75 f7                	jne    80077a <strlen+0xd>
		n++;
	return n;
}
  800783:	5d                   	pop    %ebp
  800784:	c3                   	ret    

00800785 <strnlen>:

int
strnlen(const char *s, size_t size)
{
  800785:	55                   	push   %ebp
  800786:	89 e5                	mov    %esp,%ebp
  800788:	8b 4d 08             	mov    0x8(%ebp),%ecx
  80078b:	8b 45 0c             	mov    0xc(%ebp),%eax
	int n;

	for (n = 0; size > 0 && *s != '\0'; s++, size--)
  80078e:	ba 00 00 00 00       	mov    $0x0,%edx
  800793:	eb 03                	jmp    800798 <strnlen+0x13>
		n++;
  800795:	83 c2 01             	add    $0x1,%edx
int
strnlen(const char *s, size_t size)
{
	int n;

	for (n = 0; size > 0 && *s != '\0'; s++, size--)
  800798:	39 c2                	cmp    %eax,%edx
  80079a:	74 08                	je     8007a4 <strnlen+0x1f>
  80079c:	80 3c 11 00          	cmpb   $0x0,(%ecx,%edx,1)
  8007a0:	75 f3                	jne    800795 <strnlen+0x10>
  8007a2:	89 d0                	mov    %edx,%eax
		n++;
	return n;
}
  8007a4:	5d                   	pop    %ebp
  8007a5:	c3                   	ret    

008007a6 <strcpy>:

char *
strcpy(char *dst, const char *src)
{
  8007a6:	55                   	push   %ebp
  8007a7:	89 e5                	mov    %esp,%ebp
  8007a9:	53                   	push   %ebx
  8007aa:	8b 45 08             	mov    0x8(%ebp),%eax
  8007ad:	8b 4d 0c             	mov    0xc(%ebp),%ecx
	char *ret;

	ret = dst;
	while ((*dst++ = *src++) != '\0')
  8007b0:	89 c2                	mov    %eax,%edx
  8007b2:	83 c2 01             	add    $0x1,%edx
  8007b5:	83 c1 01             	add    $0x1,%ecx
  8007b8:	0f b6 59 ff          	movzbl -0x1(%ecx),%ebx
  8007bc:	88 5a ff             	mov    %bl,-0x1(%edx)
  8007bf:	84 db                	test   %bl,%bl
  8007c1:	75 ef                	jne    8007b2 <strcpy+0xc>
		/* do nothing */;
	return ret;
}
  8007c3:	5b                   	pop    %ebx
  8007c4:	5d                   	pop    %ebp
  8007c5:	c3                   	ret    

008007c6 <strcat>:

char *
strcat(char *dst, const char *src)
{
  8007c6:	55                   	push   %ebp
  8007c7:	89 e5                	mov    %esp,%ebp
  8007c9:	53                   	push   %ebx
  8007ca:	8b 5d 08             	mov    0x8(%ebp),%ebx
	int len = strlen(dst);
  8007cd:	53                   	push   %ebx
  8007ce:	e8 9a ff ff ff       	call   80076d <strlen>
  8007d3:	83 c4 04             	add    $0x4,%esp
	strcpy(dst + len, src);
  8007d6:	ff 75 0c             	pushl  0xc(%ebp)
  8007d9:	01 d8                	add    %ebx,%eax
  8007db:	50                   	push   %eax
  8007dc:	e8 c5 ff ff ff       	call   8007a6 <strcpy>
	return dst;
}
  8007e1:	89 d8                	mov    %ebx,%eax
  8007e3:	8b 5d fc             	mov    -0x4(%ebp),%ebx
  8007e6:	c9                   	leave  
  8007e7:	c3                   	ret    

008007e8 <strncpy>:

char *
strncpy(char *dst, const char *src, size_t size) {
  8007e8:	55                   	push   %ebp
  8007e9:	89 e5                	mov    %esp,%ebp
  8007eb:	56                   	push   %esi
  8007ec:	53                   	push   %ebx
  8007ed:	8b 75 08             	mov    0x8(%ebp),%esi
  8007f0:	8b 4d 0c             	mov    0xc(%ebp),%ecx
  8007f3:	89 f3                	mov    %esi,%ebx
  8007f5:	03 5d 10             	add    0x10(%ebp),%ebx
	size_t i;
	char *ret;

	ret = dst;
	for (i = 0; i < size; i++) {
  8007f8:	89 f2                	mov    %esi,%edx
  8007fa:	eb 0f                	jmp    80080b <strncpy+0x23>
		*dst++ = *src;
  8007fc:	83 c2 01             	add    $0x1,%edx
  8007ff:	0f b6 01             	movzbl (%ecx),%eax
  800802:	88 42 ff             	mov    %al,-0x1(%edx)
		// If strlen(src) < size, null-pad 'dst' out to 'size' chars
		if (*src != '\0')
			src++;
  800805:	80 39 01             	cmpb   $0x1,(%ecx)
  800808:	83 d9 ff             	sbb    $0xffffffff,%ecx
strncpy(char *dst, const char *src, size_t size) {
	size_t i;
	char *ret;

	ret = dst;
	for (i = 0; i < size; i++) {
  80080b:	39 da                	cmp    %ebx,%edx
  80080d:	75 ed                	jne    8007fc <strncpy+0x14>
		// If strlen(src) < size, null-pad 'dst' out to 'size' chars
		if (*src != '\0')
			src++;
	}
	return ret;
}
  80080f:	89 f0                	mov    %esi,%eax
  800811:	5b                   	pop    %ebx
  800812:	5e                   	pop    %esi
  800813:	5d                   	pop    %ebp
  800814:	c3                   	ret    

00800815 <strlcpy>:

size_t
strlcpy(char *dst, const char *src, size_t size)
{
  800815:	55                   	push   %ebp
  800816:	89 e5                	mov    %esp,%ebp
  800818:	56                   	push   %esi
  800819:	53                   	push   %ebx
  80081a:	8b 75 08             	mov    0x8(%ebp),%esi
  80081d:	8b 4d 0c             	mov    0xc(%ebp),%ecx
  800820:	8b 55 10             	mov    0x10(%ebp),%edx
  800823:	89 f0                	mov    %esi,%eax
	char *dst_in;

	dst_in = dst;
	if (size > 0) {
  800825:	85 d2                	test   %edx,%edx
  800827:	74 21                	je     80084a <strlcpy+0x35>
  800829:	8d 44 16 ff          	lea    -0x1(%esi,%edx,1),%eax
  80082d:	89 f2                	mov    %esi,%edx
  80082f:	eb 09                	jmp    80083a <strlcpy+0x25>
		while (--size > 0 && *src != '\0')
			*dst++ = *src++;
  800831:	83 c2 01             	add    $0x1,%edx
  800834:	83 c1 01             	add    $0x1,%ecx
  800837:	88 5a ff             	mov    %bl,-0x1(%edx)
{
	char *dst_in;

	dst_in = dst;
	if (size > 0) {
		while (--size > 0 && *src != '\0')
  80083a:	39 c2                	cmp    %eax,%edx
  80083c:	74 09                	je     800847 <strlcpy+0x32>
  80083e:	0f b6 19             	movzbl (%ecx),%ebx
  800841:	84 db                	test   %bl,%bl
  800843:	75 ec                	jne    800831 <strlcpy+0x1c>
  800845:	89 d0                	mov    %edx,%eax
			*dst++ = *src++;
		*dst = '\0';
  800847:	c6 00 00             	movb   $0x0,(%eax)
	}
	return dst - dst_in;
  80084a:	29 f0                	sub    %esi,%eax
}
  80084c:	5b                   	pop    %ebx
  80084d:	5e                   	pop    %esi
  80084e:	5d                   	pop    %ebp
  80084f:	c3                   	ret    

00800850 <strcmp>:

int
strcmp(const char *p, const char *q)
{
  800850:	55                   	push   %ebp
  800851:	89 e5                	mov    %esp,%ebp
  800853:	8b 4d 08             	mov    0x8(%ebp),%ecx
  800856:	8b 55 0c             	mov    0xc(%ebp),%edx
	while (*p && *p == *q)
  800859:	eb 06                	jmp    800861 <strcmp+0x11>
		p++, q++;
  80085b:	83 c1 01             	add    $0x1,%ecx
  80085e:	83 c2 01             	add    $0x1,%edx
}

int
strcmp(const char *p, const char *q)
{
	while (*p && *p == *q)
  800861:	0f b6 01             	movzbl (%ecx),%eax
  800864:	84 c0                	test   %al,%al
  800866:	74 04                	je     80086c <strcmp+0x1c>
  800868:	3a 02                	cmp    (%edx),%al
  80086a:	74 ef                	je     80085b <strcmp+0xb>
		p++, q++;
	return (int) ((unsigned char) *p - (unsigned char) *q);
  80086c:	0f b6 c0             	movzbl %al,%eax
  80086f:	0f b6 12             	movzbl (%edx),%edx
  800872:	29 d0                	sub    %edx,%eax
}
  800874:	5d                   	pop    %ebp
  800875:	c3                   	ret    

00800876 <strncmp>:

int
strncmp(const char *p, const char *q, size_t n)
{
  800876:	55                   	push   %ebp
  800877:	89 e5                	mov    %esp,%ebp
  800879:	53                   	push   %ebx
  80087a:	8b 45 08             	mov    0x8(%ebp),%eax
  80087d:	8b 55 0c             	mov    0xc(%ebp),%edx
  800880:	89 c3                	mov    %eax,%ebx
  800882:	03 5d 10             	add    0x10(%ebp),%ebx
	while (n > 0 && *p && *p == *q)
  800885:	eb 06                	jmp    80088d <strncmp+0x17>
		n--, p++, q++;
  800887:	83 c0 01             	add    $0x1,%eax
  80088a:	83 c2 01             	add    $0x1,%edx
}

int
strncmp(const char *p, const char *q, size_t n)
{
	while (n > 0 && *p && *p == *q)
  80088d:	39 d8                	cmp    %ebx,%eax
  80088f:	74 15                	je     8008a6 <strncmp+0x30>
  800891:	0f b6 08             	movzbl (%eax),%ecx
  800894:	84 c9                	test   %cl,%cl
  800896:	74 04                	je     80089c <strncmp+0x26>
  800898:	3a 0a                	cmp    (%edx),%cl
  80089a:	74 eb                	je     800887 <strncmp+0x11>
		n--, p++, q++;
	if (n == 0)
		return 0;
	else
		return (int) ((unsigned char) *p - (unsigned char) *q);
  80089c:	0f b6 00             	movzbl (%eax),%eax
  80089f:	0f b6 12             	movzbl (%edx),%edx
  8008a2:	29 d0                	sub    %edx,%eax
  8008a4:	eb 05                	jmp    8008ab <strncmp+0x35>
strncmp(const char *p, const char *q, size_t n)
{
	while (n > 0 && *p && *p == *q)
		n--, p++, q++;
	if (n == 0)
		return 0;
  8008a6:	b8 00 00 00 00       	mov    $0x0,%eax
	else
		return (int) ((unsigned char) *p - (unsigned char) *q);
}
  8008ab:	5b                   	pop    %ebx
  8008ac:	5d                   	pop    %ebp
  8008ad:	c3                   	ret    

008008ae <strchr>:

// Return a pointer to the first occurrence of 'c' in 's',
// or a null pointer if the string has no 'c'.
char *
strchr(const char *s, char c)
{
  8008ae:	55                   	push   %ebp
  8008af:	89 e5                	mov    %esp,%ebp
  8008b1:	8b 45 08             	mov    0x8(%ebp),%eax
  8008b4:	0f b6 4d 0c          	movzbl 0xc(%ebp),%ecx
	for (; *s; s++)
  8008b8:	eb 07                	jmp    8008c1 <strchr+0x13>
		if (*s == c)
  8008ba:	38 ca                	cmp    %cl,%dl
  8008bc:	74 0f                	je     8008cd <strchr+0x1f>
// Return a pointer to the first occurrence of 'c' in 's',
// or a null pointer if the string has no 'c'.
char *
strchr(const char *s, char c)
{
	for (; *s; s++)
  8008be:	83 c0 01             	add    $0x1,%eax
  8008c1:	0f b6 10             	movzbl (%eax),%edx
  8008c4:	84 d2                	test   %dl,%dl
  8008c6:	75 f2                	jne    8008ba <strchr+0xc>
		if (*s == c)
			return (char *) s;
	return 0;
  8008c8:	b8 00 00 00 00       	mov    $0x0,%eax
}
  8008cd:	5d                   	pop    %ebp
  8008ce:	c3                   	ret    

008008cf <strfind>:

// Return a pointer to the first occurrence of 'c' in 's',
// or a pointer to the string-ending null character if the string has no 'c'.
char *
strfind(const char *s, char c)
{
  8008cf:	55                   	push   %ebp
  8008d0:	89 e5                	mov    %esp,%ebp
  8008d2:	8b 45 08             	mov    0x8(%ebp),%eax
  8008d5:	0f b6 4d 0c          	movzbl 0xc(%ebp),%ecx
	for (; *s; s++)
  8008d9:	eb 03                	jmp    8008de <strfind+0xf>
  8008db:	83 c0 01             	add    $0x1,%eax
  8008de:	0f b6 10             	movzbl (%eax),%edx
		if (*s == c)
  8008e1:	38 ca                	cmp    %cl,%dl
  8008e3:	74 04                	je     8008e9 <strfind+0x1a>
  8008e5:	84 d2                	test   %dl,%dl
  8008e7:	75 f2                	jne    8008db <strfind+0xc>
			break;
	return (char *) s;
}
  8008e9:	5d                   	pop    %ebp
  8008ea:	c3                   	ret    

008008eb <memset>:

#if ASM
void *
memset(void *v, int c, size_t n)
{
  8008eb:	55                   	push   %ebp
  8008ec:	89 e5                	mov    %esp,%ebp
  8008ee:	57                   	push   %edi
  8008ef:	56                   	push   %esi
  8008f0:	53                   	push   %ebx
  8008f1:	8b 55 08             	mov    0x8(%ebp),%edx
  8008f4:	8b 4d 10             	mov    0x10(%ebp),%ecx
	char *p = v;

	if (n == 0)
  8008f7:	85 c9                	test   %ecx,%ecx
  8008f9:	74 37                	je     800932 <memset+0x47>
		return v;
	if ((int)v%4 == 0 && n%4 == 0) {
  8008fb:	f6 c2 03             	test   $0x3,%dl
  8008fe:	75 2a                	jne    80092a <memset+0x3f>
  800900:	f6 c1 03             	test   $0x3,%cl
  800903:	75 25                	jne    80092a <memset+0x3f>
		c &= 0xFF;
  800905:	0f b6 5d 0c          	movzbl 0xc(%ebp),%ebx
		c = (c<<24)|(c<<16)|(c<<8)|c;
  800909:	89 df                	mov    %ebx,%edi
  80090b:	c1 e7 08             	shl    $0x8,%edi
  80090e:	89 de                	mov    %ebx,%esi
  800910:	c1 e6 18             	shl    $0x18,%esi
  800913:	89 d8                	mov    %ebx,%eax
  800915:	c1 e0 10             	shl    $0x10,%eax
  800918:	09 f0                	or     %esi,%eax
  80091a:	09 c3                	or     %eax,%ebx
		asm volatile("cld; rep stosl\n"
			: "=D" (p), "=c" (n)
			: "D" (p), "a" (c), "c" (n/4)
  80091c:	c1 e9 02             	shr    $0x2,%ecx
	if (n == 0)
		return v;
	if ((int)v%4 == 0 && n%4 == 0) {
		c &= 0xFF;
		c = (c<<24)|(c<<16)|(c<<8)|c;
		asm volatile("cld; rep stosl\n"
  80091f:	89 f8                	mov    %edi,%eax
  800921:	09 d8                	or     %ebx,%eax
  800923:	89 d7                	mov    %edx,%edi
  800925:	fc                   	cld    
  800926:	f3 ab                	rep stos %eax,%es:(%edi)
  800928:	eb 08                	jmp    800932 <memset+0x47>
			: "=D" (p), "=c" (n)
			: "D" (p), "a" (c), "c" (n/4)
			: "cc", "memory");
	} else
		asm volatile("cld; rep stosb\n"
  80092a:	89 d7                	mov    %edx,%edi
  80092c:	8b 45 0c             	mov    0xc(%ebp),%eax
  80092f:	fc                   	cld    
  800930:	f3 aa                	rep stos %al,%es:(%edi)
			: "=D" (p), "=c" (n)
			: "0" (p), "a" (c), "1" (n)
			: "cc", "memory");
	return v;
}
  800932:	89 d0                	mov    %edx,%eax
  800934:	5b                   	pop    %ebx
  800935:	5e                   	pop    %esi
  800936:	5f                   	pop    %edi
  800937:	5d                   	pop    %ebp
  800938:	c3                   	ret    

00800939 <memmove>:

void *
memmove(void *dst, const void *src, size_t n)
{
  800939:	55                   	push   %ebp
  80093a:	89 e5                	mov    %esp,%ebp
  80093c:	57                   	push   %edi
  80093d:	56                   	push   %esi
  80093e:	8b 45 08             	mov    0x8(%ebp),%eax
  800941:	8b 75 0c             	mov    0xc(%ebp),%esi
  800944:	8b 4d 10             	mov    0x10(%ebp),%ecx
	const char *s;
	char *d;

	s = src;
	d = dst;
	if (s < d && s + n > d) {
  800947:	39 c6                	cmp    %eax,%esi
  800949:	73 35                	jae    800980 <memmove+0x47>
  80094b:	8d 14 0e             	lea    (%esi,%ecx,1),%edx
  80094e:	39 d0                	cmp    %edx,%eax
  800950:	73 2e                	jae    800980 <memmove+0x47>
		s += n;
		d += n;
  800952:	8d 3c 08             	lea    (%eax,%ecx,1),%edi
		if ((int)s%4 == 0 && (int)d%4 == 0 && n%4 == 0)
  800955:	89 d6                	mov    %edx,%esi
  800957:	09 fe                	or     %edi,%esi
  800959:	f7 c6 03 00 00 00    	test   $0x3,%esi
  80095f:	75 13                	jne    800974 <memmove+0x3b>
  800961:	f6 c1 03             	test   $0x3,%cl
  800964:	75 0e                	jne    800974 <memmove+0x3b>
			asm volatile("std; rep movsl\n"
  800966:	83 ef 04             	sub    $0x4,%edi
  800969:	8d 72 fc             	lea    -0x4(%edx),%esi
  80096c:	c1 e9 02             	shr    $0x2,%ecx
  80096f:	fd                   	std    
  800970:	f3 a5                	rep movsl %ds:(%esi),%es:(%edi)
  800972:	eb 09                	jmp    80097d <memmove+0x44>
				:: "D" (d-4), "S" (s-4), "c" (n/4) : "cc", "memory");
		else
			asm volatile("std; rep movsb\n"
  800974:	83 ef 01             	sub    $0x1,%edi
  800977:	8d 72 ff             	lea    -0x1(%edx),%esi
  80097a:	fd                   	std    
  80097b:	f3 a4                	rep movsb %ds:(%esi),%es:(%edi)
				:: "D" (d-1), "S" (s-1), "c" (n) : "cc", "memory");
		// Some versions of GCC rely on DF being clear
		asm volatile("cld" ::: "cc");
  80097d:	fc                   	cld    
  80097e:	eb 1d                	jmp    80099d <memmove+0x64>
	} else {
		if ((int)s%4 == 0 && (int)d%4 == 0 && n%4 == 0)
  800980:	89 f2                	mov    %esi,%edx
  800982:	09 c2                	or     %eax,%edx
  800984:	f6 c2 03             	test   $0x3,%dl
  800987:	75 0f                	jne    800998 <memmove+0x5f>
  800989:	f6 c1 03             	test   $0x3,%cl
  80098c:	75 0a                	jne    800998 <memmove+0x5f>
			asm volatile("cld; rep movsl\n"
  80098e:	c1 e9 02             	shr    $0x2,%ecx
  800991:	89 c7                	mov    %eax,%edi
  800993:	fc                   	cld    
  800994:	f3 a5                	rep movsl %ds:(%esi),%es:(%edi)
  800996:	eb 05                	jmp    80099d <memmove+0x64>
				:: "D" (d), "S" (s), "c" (n/4) : "cc", "memory");
		else
			asm volatile("cld; rep movsb\n"
  800998:	89 c7                	mov    %eax,%edi
  80099a:	fc                   	cld    
  80099b:	f3 a4                	rep movsb %ds:(%esi),%es:(%edi)
				:: "D" (d), "S" (s), "c" (n) : "cc", "memory");
	}
	return dst;
}
  80099d:	5e                   	pop    %esi
  80099e:	5f                   	pop    %edi
  80099f:	5d                   	pop    %ebp
  8009a0:	c3                   	ret    

008009a1 <memcpy>:
}
#endif

void *
memcpy(void *dst, const void *src, size_t n)
{
  8009a1:	55                   	push   %ebp
  8009a2:	89 e5                	mov    %esp,%ebp
	return memmove(dst, src, n);
  8009a4:	ff 75 10             	pushl  0x10(%ebp)
  8009a7:	ff 75 0c             	pushl  0xc(%ebp)
  8009aa:	ff 75 08             	pushl  0x8(%ebp)
  8009ad:	e8 87 ff ff ff       	call   800939 <memmove>
}
  8009b2:	c9                   	leave  
  8009b3:	c3                   	ret    

008009b4 <memcmp>:

int
memcmp(const void *v1, const void *v2, size_t n)
{
  8009b4:	55                   	push   %ebp
  8009b5:	89 e5                	mov    %esp,%ebp
  8009b7:	56                   	push   %esi
  8009b8:	53                   	push   %ebx
  8009b9:	8b 45 08             	mov    0x8(%ebp),%eax
  8009bc:	8b 55 0c             	mov    0xc(%ebp),%edx
  8009bf:	89 c6                	mov    %eax,%esi
  8009c1:	03 75 10             	add    0x10(%ebp),%esi
	const uint8_t *s1 = (const uint8_t *) v1;
	const uint8_t *s2 = (const uint8_t *) v2;

	while (n-- > 0) {
  8009c4:	eb 1a                	jmp    8009e0 <memcmp+0x2c>
		if (*s1 != *s2)
  8009c6:	0f b6 08             	movzbl (%eax),%ecx
  8009c9:	0f b6 1a             	movzbl (%edx),%ebx
  8009cc:	38 d9                	cmp    %bl,%cl
  8009ce:	74 0a                	je     8009da <memcmp+0x26>
			return (int) *s1 - (int) *s2;
  8009d0:	0f b6 c1             	movzbl %cl,%eax
  8009d3:	0f b6 db             	movzbl %bl,%ebx
  8009d6:	29 d8                	sub    %ebx,%eax
  8009d8:	eb 0f                	jmp    8009e9 <memcmp+0x35>
		s1++, s2++;
  8009da:	83 c0 01             	add    $0x1,%eax
  8009dd:	83 c2 01             	add    $0x1,%edx
memcmp(const void *v1, const void *v2, size_t n)
{
	const uint8_t *s1 = (const uint8_t *) v1;
	const uint8_t *s2 = (const uint8_t *) v2;

	while (n-- > 0) {
  8009e0:	39 f0                	cmp    %esi,%eax
  8009e2:	75 e2                	jne    8009c6 <memcmp+0x12>
		if (*s1 != *s2)
			return (int) *s1 - (int) *s2;
		s1++, s2++;
	}

	return 0;
  8009e4:	b8 00 00 00 00       	mov    $0x0,%eax
}
  8009e9:	5b                   	pop    %ebx
  8009ea:	5e                   	pop    %esi
  8009eb:	5d                   	pop    %ebp
  8009ec:	c3                   	ret    

008009ed <memfind>:

void *
memfind(const void *s, int c, size_t n)
{
  8009ed:	55                   	push   %ebp
  8009ee:	89 e5                	mov    %esp,%ebp
  8009f0:	8b 45 08             	mov    0x8(%ebp),%eax
  8009f3:	8b 4d 0c             	mov    0xc(%ebp),%ecx
	const void *ends = (const char *) s + n;
  8009f6:	89 c2                	mov    %eax,%edx
  8009f8:	03 55 10             	add    0x10(%ebp),%edx
	for (; s < ends; s++)
  8009fb:	eb 07                	jmp    800a04 <memfind+0x17>
		if (*(const unsigned char *) s == (unsigned char) c)
  8009fd:	38 08                	cmp    %cl,(%eax)
  8009ff:	74 07                	je     800a08 <memfind+0x1b>

void *
memfind(const void *s, int c, size_t n)
{
	const void *ends = (const char *) s + n;
	for (; s < ends; s++)
  800a01:	83 c0 01             	add    $0x1,%eax
  800a04:	39 d0                	cmp    %edx,%eax
  800a06:	72 f5                	jb     8009fd <memfind+0x10>
		if (*(const unsigned char *) s == (unsigned char) c)
			break;
	return (void *) s;
}
  800a08:	5d                   	pop    %ebp
  800a09:	c3                   	ret    

00800a0a <strtol>:

long
strtol(const char *s, char **endptr, int base)
{
  800a0a:	55                   	push   %ebp
  800a0b:	89 e5                	mov    %esp,%ebp
  800a0d:	57                   	push   %edi
  800a0e:	56                   	push   %esi
  800a0f:	53                   	push   %ebx
  800a10:	8b 4d 08             	mov    0x8(%ebp),%ecx
  800a13:	8b 5d 10             	mov    0x10(%ebp),%ebx
	int neg = 0;
	long val = 0;

	// gobble initial whitespace
	while (*s == ' ' || *s == '\t')
  800a16:	eb 03                	jmp    800a1b <strtol+0x11>
		s++;
  800a18:	83 c1 01             	add    $0x1,%ecx
{
	int neg = 0;
	long val = 0;

	// gobble initial whitespace
	while (*s == ' ' || *s == '\t')
  800a1b:	0f b6 01             	movzbl (%ecx),%eax
  800a1e:	3c 20                	cmp    $0x20,%al
  800a20:	74 f6                	je     800a18 <strtol+0xe>
  800a22:	3c 09                	cmp    $0x9,%al
  800a24:	74 f2                	je     800a18 <strtol+0xe>
		s++;

	// plus/minus sign
	if (*s == '+')
  800a26:	3c 2b                	cmp    $0x2b,%al
  800a28:	75 0a                	jne    800a34 <strtol+0x2a>
		s++;
  800a2a:	83 c1 01             	add    $0x1,%ecx
}

long
strtol(const char *s, char **endptr, int base)
{
	int neg = 0;
  800a2d:	bf 00 00 00 00       	mov    $0x0,%edi
  800a32:	eb 11                	jmp    800a45 <strtol+0x3b>
  800a34:	bf 00 00 00 00       	mov    $0x0,%edi
		s++;

	// plus/minus sign
	if (*s == '+')
		s++;
	else if (*s == '-')
  800a39:	3c 2d                	cmp    $0x2d,%al
  800a3b:	75 08                	jne    800a45 <strtol+0x3b>
		s++, neg = 1;
  800a3d:	83 c1 01             	add    $0x1,%ecx
  800a40:	bf 01 00 00 00       	mov    $0x1,%edi

	// hex or octal base prefix
	if ((base == 0 || base == 16) && (s[0] == '0' && s[1] == 'x'))
  800a45:	f7 c3 ef ff ff ff    	test   $0xffffffef,%ebx
  800a4b:	75 15                	jne    800a62 <strtol+0x58>
  800a4d:	80 39 30             	cmpb   $0x30,(%ecx)
  800a50:	75 10                	jne    800a62 <strtol+0x58>
  800a52:	80 79 01 78          	cmpb   $0x78,0x1(%ecx)
  800a56:	75 7c                	jne    800ad4 <strtol+0xca>
		s += 2, base = 16;
  800a58:	83 c1 02             	add    $0x2,%ecx
  800a5b:	bb 10 00 00 00       	mov    $0x10,%ebx
  800a60:	eb 16                	jmp    800a78 <strtol+0x6e>
	else if (base == 0 && s[0] == '0')
  800a62:	85 db                	test   %ebx,%ebx
  800a64:	75 12                	jne    800a78 <strtol+0x6e>
		s++, base = 8;
	else if (base == 0)
		base = 10;
  800a66:	bb 0a 00 00 00       	mov    $0xa,%ebx
		s++, neg = 1;

	// hex or octal base prefix
	if ((base == 0 || base == 16) && (s[0] == '0' && s[1] == 'x'))
		s += 2, base = 16;
	else if (base == 0 && s[0] == '0')
  800a6b:	80 39 30             	cmpb   $0x30,(%ecx)
  800a6e:	75 08                	jne    800a78 <strtol+0x6e>
		s++, base = 8;
  800a70:	83 c1 01             	add    $0x1,%ecx
  800a73:	bb 08 00 00 00       	mov    $0x8,%ebx
	else if (base == 0)
		base = 10;
  800a78:	b8 00 00 00 00       	mov    $0x0,%eax
  800a7d:	89 5d 10             	mov    %ebx,0x10(%ebp)

	// digits
	while (1) {
		int dig;

		if (*s >= '0' && *s <= '9')
  800a80:	0f b6 11             	movzbl (%ecx),%edx
  800a83:	8d 72 d0             	lea    -0x30(%edx),%esi
  800a86:	89 f3                	mov    %esi,%ebx
  800a88:	80 fb 09             	cmp    $0x9,%bl
  800a8b:	77 08                	ja     800a95 <strtol+0x8b>
			dig = *s - '0';
  800a8d:	0f be d2             	movsbl %dl,%edx
  800a90:	83 ea 30             	sub    $0x30,%edx
  800a93:	eb 22                	jmp    800ab7 <strtol+0xad>
		else if (*s >= 'a' && *s <= 'z')
  800a95:	8d 72 9f             	lea    -0x61(%edx),%esi
  800a98:	89 f3                	mov    %esi,%ebx
  800a9a:	80 fb 19             	cmp    $0x19,%bl
  800a9d:	77 08                	ja     800aa7 <strtol+0x9d>
			dig = *s - 'a' + 10;
  800a9f:	0f be d2             	movsbl %dl,%edx
  800aa2:	83 ea 57             	sub    $0x57,%edx
  800aa5:	eb 10                	jmp    800ab7 <strtol+0xad>
		else if (*s >= 'A' && *s <= 'Z')
  800aa7:	8d 72 bf             	lea    -0x41(%edx),%esi
  800aaa:	89 f3                	mov    %esi,%ebx
  800aac:	80 fb 19             	cmp    $0x19,%bl
  800aaf:	77 16                	ja     800ac7 <strtol+0xbd>
			dig = *s - 'A' + 10;
  800ab1:	0f be d2             	movsbl %dl,%edx
  800ab4:	83 ea 37             	sub    $0x37,%edx
		else
			break;
		if (dig >= base)
  800ab7:	3b 55 10             	cmp    0x10(%ebp),%edx
  800aba:	7d 0b                	jge    800ac7 <strtol+0xbd>
			break;
		s++, val = (val * base) + dig;
  800abc:	83 c1 01             	add    $0x1,%ecx
  800abf:	0f af 45 10          	imul   0x10(%ebp),%eax
  800ac3:	01 d0                	add    %edx,%eax
		// we don't properly detect overflow!
	}
  800ac5:	eb b9                	jmp    800a80 <strtol+0x76>

	if (endptr)
  800ac7:	83 7d 0c 00          	cmpl   $0x0,0xc(%ebp)
  800acb:	74 0d                	je     800ada <strtol+0xd0>
		*endptr = (char *) s;
  800acd:	8b 75 0c             	mov    0xc(%ebp),%esi
  800ad0:	89 0e                	mov    %ecx,(%esi)
  800ad2:	eb 06                	jmp    800ada <strtol+0xd0>
		s++, neg = 1;

	// hex or octal base prefix
	if ((base == 0 || base == 16) && (s[0] == '0' && s[1] == 'x'))
		s += 2, base = 16;
	else if (base == 0 && s[0] == '0')
  800ad4:	85 db                	test   %ebx,%ebx
  800ad6:	74 98                	je     800a70 <strtol+0x66>
  800ad8:	eb 9e                	jmp    800a78 <strtol+0x6e>
		// we don't properly detect overflow!
	}

	if (endptr)
		*endptr = (char *) s;
	return (neg ? -val : val);
  800ada:	89 c2                	mov    %eax,%edx
  800adc:	f7 da                	neg    %edx
  800ade:	85 ff                	test   %edi,%edi
  800ae0:	0f 45 c2             	cmovne %edx,%eax
}
  800ae3:	5b                   	pop    %ebx
  800ae4:	5e                   	pop    %esi
  800ae5:	5f                   	pop    %edi
  800ae6:	5d                   	pop    %ebp
  800ae7:	c3                   	ret    
  800ae8:	66 90                	xchg   %ax,%ax
  800aea:	66 90                	xchg   %ax,%ax
  800aec:	66 90                	xchg   %ax,%ax
  800aee:	66 90                	xchg   %ax,%ax

00800af0 <__udivdi3>:
  800af0:	55                   	push   %ebp
  800af1:	57                   	push   %edi
  800af2:	56                   	push   %esi
  800af3:	53                   	push   %ebx
  800af4:	83 ec 1c             	sub    $0x1c,%esp
  800af7:	8b 74 24 3c          	mov    0x3c(%esp),%esi
  800afb:	8b 5c 24 30          	mov    0x30(%esp),%ebx
  800aff:	8b 4c 24 34          	mov    0x34(%esp),%ecx
  800b03:	8b 7c 24 38          	mov    0x38(%esp),%edi
  800b07:	85 f6                	test   %esi,%esi
  800b09:	89 5c 24 08          	mov    %ebx,0x8(%esp)
  800b0d:	89 ca                	mov    %ecx,%edx
  800b0f:	89 f8                	mov    %edi,%eax
  800b11:	75 3d                	jne    800b50 <__udivdi3+0x60>
  800b13:	39 cf                	cmp    %ecx,%edi
  800b15:	0f 87 c5 00 00 00    	ja     800be0 <__udivdi3+0xf0>
  800b1b:	85 ff                	test   %edi,%edi
  800b1d:	89 fd                	mov    %edi,%ebp
  800b1f:	75 0b                	jne    800b2c <__udivdi3+0x3c>
  800b21:	b8 01 00 00 00       	mov    $0x1,%eax
  800b26:	31 d2                	xor    %edx,%edx
  800b28:	f7 f7                	div    %edi
  800b2a:	89 c5                	mov    %eax,%ebp
  800b2c:	89 c8                	mov    %ecx,%eax
  800b2e:	31 d2                	xor    %edx,%edx
  800b30:	f7 f5                	div    %ebp
  800b32:	89 c1                	mov    %eax,%ecx
  800b34:	89 d8                	mov    %ebx,%eax
  800b36:	89 cf                	mov    %ecx,%edi
  800b38:	f7 f5                	div    %ebp
  800b3a:	89 c3                	mov    %eax,%ebx
  800b3c:	89 d8                	mov    %ebx,%eax
  800b3e:	89 fa                	mov    %edi,%edx
  800b40:	83 c4 1c             	add    $0x1c,%esp
  800b43:	5b                   	pop    %ebx
  800b44:	5e                   	pop    %esi
  800b45:	5f                   	pop    %edi
  800b46:	5d                   	pop    %ebp
  800b47:	c3                   	ret    
  800b48:	90                   	nop
  800b49:	8d b4 26 00 00 00 00 	lea    0x0(%esi,%eiz,1),%esi
  800b50:	39 ce                	cmp    %ecx,%esi
  800b52:	77 74                	ja     800bc8 <__udivdi3+0xd8>
  800b54:	0f bd fe             	bsr    %esi,%edi
  800b57:	83 f7 1f             	xor    $0x1f,%edi
  800b5a:	0f 84 98 00 00 00    	je     800bf8 <__udivdi3+0x108>
  800b60:	bb 20 00 00 00       	mov    $0x20,%ebx
  800b65:	89 f9                	mov    %edi,%ecx
  800b67:	89 c5                	mov    %eax,%ebp
  800b69:	29 fb                	sub    %edi,%ebx
  800b6b:	d3 e6                	shl    %cl,%esi
  800b6d:	89 d9                	mov    %ebx,%ecx
  800b6f:	d3 ed                	shr    %cl,%ebp
  800b71:	89 f9                	mov    %edi,%ecx
  800b73:	d3 e0                	shl    %cl,%eax
  800b75:	09 ee                	or     %ebp,%esi
  800b77:	89 d9                	mov    %ebx,%ecx
  800b79:	89 44 24 0c          	mov    %eax,0xc(%esp)
  800b7d:	89 d5                	mov    %edx,%ebp
  800b7f:	8b 44 24 08          	mov    0x8(%esp),%eax
  800b83:	d3 ed                	shr    %cl,%ebp
  800b85:	89 f9                	mov    %edi,%ecx
  800b87:	d3 e2                	shl    %cl,%edx
  800b89:	89 d9                	mov    %ebx,%ecx
  800b8b:	d3 e8                	shr    %cl,%eax
  800b8d:	09 c2                	or     %eax,%edx
  800b8f:	89 d0                	mov    %edx,%eax
  800b91:	89 ea                	mov    %ebp,%edx
  800b93:	f7 f6                	div    %esi
  800b95:	89 d5                	mov    %edx,%ebp
  800b97:	89 c3                	mov    %eax,%ebx
  800b99:	f7 64 24 0c          	mull   0xc(%esp)
  800b9d:	39 d5                	cmp    %edx,%ebp
  800b9f:	72 10                	jb     800bb1 <__udivdi3+0xc1>
  800ba1:	8b 74 24 08          	mov    0x8(%esp),%esi
  800ba5:	89 f9                	mov    %edi,%ecx
  800ba7:	d3 e6                	shl    %cl,%esi
  800ba9:	39 c6                	cmp    %eax,%esi
  800bab:	73 07                	jae    800bb4 <__udivdi3+0xc4>
  800bad:	39 d5                	cmp    %edx,%ebp
  800baf:	75 03                	jne    800bb4 <__udivdi3+0xc4>
  800bb1:	83 eb 01             	sub    $0x1,%ebx
  800bb4:	31 ff                	xor    %edi,%edi
  800bb6:	89 d8                	mov    %ebx,%eax
  800bb8:	89 fa                	mov    %edi,%edx
  800bba:	83 c4 1c             	add    $0x1c,%esp
  800bbd:	5b                   	pop    %ebx
  800bbe:	5e                   	pop    %esi
  800bbf:	5f                   	pop    %edi
  800bc0:	5d                   	pop    %ebp
  800bc1:	c3                   	ret    
  800bc2:	8d b6 00 00 00 00    	lea    0x0(%esi),%esi
  800bc8:	31 ff                	xor    %edi,%edi
  800bca:	31 db                	xor    %ebx,%ebx
  800bcc:	89 d8                	mov    %ebx,%eax
  800bce:	89 fa                	mov    %edi,%edx
  800bd0:	83 c4 1c             	add    $0x1c,%esp
  800bd3:	5b                   	pop    %ebx
  800bd4:	5e                   	pop    %esi
  800bd5:	5f                   	pop    %edi
  800bd6:	5d                   	pop    %ebp
  800bd7:	c3                   	ret    
  800bd8:	90                   	nop
  800bd9:	8d b4 26 00 00 00 00 	lea    0x0(%esi,%eiz,1),%esi
  800be0:	89 d8                	mov    %ebx,%eax
  800be2:	f7 f7                	div    %edi
  800be4:	31 ff                	xor    %edi,%edi
  800be6:	89 c3                	mov    %eax,%ebx
  800be8:	89 d8                	mov    %ebx,%eax
  800bea:	89 fa                	mov    %edi,%edx
  800bec:	83 c4 1c             	add    $0x1c,%esp
  800bef:	5b                   	pop    %ebx
  800bf0:	5e                   	pop    %esi
  800bf1:	5f                   	pop    %edi
  800bf2:	5d                   	pop    %ebp
  800bf3:	c3                   	ret    
  800bf4:	8d 74 26 00          	lea    0x0(%esi,%eiz,1),%esi
  800bf8:	39 ce                	cmp    %ecx,%esi
  800bfa:	72 0c                	jb     800c08 <__udivdi3+0x118>
  800bfc:	31 db                	xor    %ebx,%ebx
  800bfe:	3b 44 24 08          	cmp    0x8(%esp),%eax
  800c02:	0f 87 34 ff ff ff    	ja     800b3c <__udivdi3+0x4c>
  800c08:	bb 01 00 00 00       	mov    $0x1,%ebx
  800c0d:	e9 2a ff ff ff       	jmp    800b3c <__udivdi3+0x4c>
  800c12:	66 90                	xchg   %ax,%ax
  800c14:	66 90                	xchg   %ax,%ax
  800c16:	66 90                	xchg   %ax,%ax
  800c18:	66 90                	xchg   %ax,%ax
  800c1a:	66 90                	xchg   %ax,%ax
  800c1c:	66 90                	xchg   %ax,%ax
  800c1e:	66 90                	xchg   %ax,%ax

00800c20 <__umoddi3>:
  800c20:	55                   	push   %ebp
  800c21:	57                   	push   %edi
  800c22:	56                   	push   %esi
  800c23:	53                   	push   %ebx
  800c24:	83 ec 1c             	sub    $0x1c,%esp
  800c27:	8b 54 24 3c          	mov    0x3c(%esp),%edx
  800c2b:	8b 4c 24 30          	mov    0x30(%esp),%ecx
  800c2f:	8b 74 24 34          	mov    0x34(%esp),%esi
  800c33:	8b 7c 24 38          	mov    0x38(%esp),%edi
  800c37:	85 d2                	test   %edx,%edx
  800c39:	89 4c 24 0c          	mov    %ecx,0xc(%esp)
  800c3d:	89 4c 24 08          	mov    %ecx,0x8(%esp)
  800c41:	89 f3                	mov    %esi,%ebx
  800c43:	89 3c 24             	mov    %edi,(%esp)
  800c46:	89 74 24 04          	mov    %esi,0x4(%esp)
  800c4a:	75 1c                	jne    800c68 <__umoddi3+0x48>
  800c4c:	39 f7                	cmp    %esi,%edi
  800c4e:	76 50                	jbe    800ca0 <__umoddi3+0x80>
  800c50:	89 c8                	mov    %ecx,%eax
  800c52:	89 f2                	mov    %esi,%edx
  800c54:	f7 f7                	div    %edi
  800c56:	89 d0                	mov    %edx,%eax
  800c58:	31 d2                	xor    %edx,%edx
  800c5a:	83 c4 1c             	add    $0x1c,%esp
  800c5d:	5b                   	pop    %ebx
  800c5e:	5e                   	pop    %esi
  800c5f:	5f                   	pop    %edi
  800c60:	5d                   	pop    %ebp
  800c61:	c3                   	ret    
  800c62:	8d b6 00 00 00 00    	lea    0x0(%esi),%esi
  800c68:	39 f2                	cmp    %esi,%edx
  800c6a:	89 d0                	mov    %edx,%eax
  800c6c:	77 52                	ja     800cc0 <__umoddi3+0xa0>
  800c6e:	0f bd ea             	bsr    %edx,%ebp
  800c71:	83 f5 1f             	xor    $0x1f,%ebp
  800c74:	75 5a                	jne    800cd0 <__umoddi3+0xb0>
  800c76:	3b 54 24 04          	cmp    0x4(%esp),%edx
  800c7a:	0f 82 e0 00 00 00    	jb     800d60 <__umoddi3+0x140>
  800c80:	39 0c 24             	cmp    %ecx,(%esp)
  800c83:	0f 86 d7 00 00 00    	jbe    800d60 <__umoddi3+0x140>
  800c89:	8b 44 24 08          	mov    0x8(%esp),%eax
  800c8d:	8b 54 24 04          	mov    0x4(%esp),%edx
  800c91:	83 c4 1c             	add    $0x1c,%esp
  800c94:	5b                   	pop    %ebx
  800c95:	5e                   	pop    %esi
  800c96:	5f                   	pop    %edi
  800c97:	5d                   	pop    %ebp
  800c98:	c3                   	ret    
  800c99:	8d b4 26 00 00 00 00 	lea    0x0(%esi,%eiz,1),%esi
  800ca0:	85 ff                	test   %edi,%edi
  800ca2:	89 fd                	mov    %edi,%ebp
  800ca4:	75 0b                	jne    800cb1 <__umoddi3+0x91>
  800ca6:	b8 01 00 00 00       	mov    $0x1,%eax
  800cab:	31 d2                	xor    %edx,%edx
  800cad:	f7 f7                	div    %edi
  800caf:	89 c5                	mov    %eax,%ebp
  800cb1:	89 f0                	mov    %esi,%eax
  800cb3:	31 d2                	xor    %edx,%edx
  800cb5:	f7 f5                	div    %ebp
  800cb7:	89 c8                	mov    %ecx,%eax
  800cb9:	f7 f5                	div    %ebp
  800cbb:	89 d0                	mov    %edx,%eax
  800cbd:	eb 99                	jmp    800c58 <__umoddi3+0x38>
  800cbf:	90                   	nop
  800cc0:	89 c8                	mov    %ecx,%eax
  800cc2:	89 f2                	mov    %esi,%edx
  800cc4:	83 c4 1c             	add    $0x1c,%esp
  800cc7:	5b                   	pop    %ebx
  800cc8:	5e                   	pop    %esi
  800cc9:	5f                   	pop    %edi
  800cca:	5d                   	pop    %ebp
  800ccb:	c3                   	ret    
  800ccc:	8d 74 26 00          	lea    0x0(%esi,%eiz,1),%esi
  800cd0:	8b 34 24             	mov    (%esp),%esi
  800cd3:	bf 20 00 00 00       	mov    $0x20,%edi
  800cd8:	89 e9                	mov    %ebp,%ecx
  800cda:	29 ef                	sub    %ebp,%edi
  800cdc:	d3 e0                	shl    %cl,%eax
  800cde:	89 f9                	mov    %edi,%ecx
  800ce0:	89 f2                	mov    %esi,%edx
  800ce2:	d3 ea                	shr    %cl,%edx
  800ce4:	89 e9                	mov    %ebp,%ecx
  800ce6:	09 c2                	or     %eax,%edx
  800ce8:	89 d8                	mov    %ebx,%eax
  800cea:	89 14 24             	mov    %edx,(%esp)
  800ced:	89 f2                	mov    %esi,%edx
  800cef:	d3 e2                	shl    %cl,%edx
  800cf1:	89 f9                	mov    %edi,%ecx
  800cf3:	89 54 24 04          	mov    %edx,0x4(%esp)
  800cf7:	8b 54 24 0c          	mov    0xc(%esp),%edx
  800cfb:	d3 e8                	shr    %cl,%eax
  800cfd:	89 e9                	mov    %ebp,%ecx
  800cff:	89 c6                	mov    %eax,%esi
  800d01:	d3 e3                	shl    %cl,%ebx
  800d03:	89 f9                	mov    %edi,%ecx
  800d05:	89 d0                	mov    %edx,%eax
  800d07:	d3 e8                	shr    %cl,%eax
  800d09:	89 e9                	mov    %ebp,%ecx
  800d0b:	09 d8                	or     %ebx,%eax
  800d0d:	89 d3                	mov    %edx,%ebx
  800d0f:	89 f2                	mov    %esi,%edx
  800d11:	f7 34 24             	divl   (%esp)
  800d14:	89 d6                	mov    %edx,%esi
  800d16:	d3 e3                	shl    %cl,%ebx
  800d18:	f7 64 24 04          	mull   0x4(%esp)
  800d1c:	39 d6                	cmp    %edx,%esi
  800d1e:	89 5c 24 08          	mov    %ebx,0x8(%esp)
  800d22:	89 d1                	mov    %edx,%ecx
  800d24:	89 c3                	mov    %eax,%ebx
  800d26:	72 08                	jb     800d30 <__umoddi3+0x110>
  800d28:	75 11                	jne    800d3b <__umoddi3+0x11b>
  800d2a:	39 44 24 08          	cmp    %eax,0x8(%esp)
  800d2e:	73 0b                	jae    800d3b <__umoddi3+0x11b>
  800d30:	2b 44 24 04          	sub    0x4(%esp),%eax
  800d34:	1b 14 24             	sbb    (%esp),%edx
  800d37:	89 d1                	mov    %edx,%ecx
  800d39:	89 c3                	mov    %eax,%ebx
  800d3b:	8b 54 24 08          	mov    0x8(%esp),%edx
  800d3f:	29 da                	sub    %ebx,%edx
  800d41:	19 ce                	sbb    %ecx,%esi
  800d43:	89 f9                	mov    %edi,%ecx
  800d45:	89 f0                	mov    %esi,%eax
  800d47:	d3 e0                	shl    %cl,%eax
  800d49:	89 e9                	mov    %ebp,%ecx
  800d4b:	d3 ea                	shr    %cl,%edx
  800d4d:	89 e9                	mov    %ebp,%ecx
  800d4f:	d3 ee                	shr    %cl,%esi
  800d51:	09 d0                	or     %edx,%eax
  800d53:	89 f2                	mov    %esi,%edx
  800d55:	83 c4 1c             	add    $0x1c,%esp
  800d58:	5b                   	pop    %ebx
  800d59:	5e                   	pop    %esi
  800d5a:	5f                   	pop    %edi
  800d5b:	5d                   	pop    %ebp
  800d5c:	c3                   	ret    
  800d5d:	8d 76 00             	lea    0x0(%esi),%esi
  800d60:	29 f9                	sub    %edi,%ecx
  800d62:	19 d6                	sbb    %edx,%esi
  800d64:	89 74 24 04          	mov    %esi,0x4(%esp)
  800d68:	89 4c 24 08          	mov    %ecx,0x8(%esp)
  800d6c:	e9 18 ff ff ff       	jmp    800c89 <__umoddi3+0x69>
