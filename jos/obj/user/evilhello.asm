
obj/user/evilhello:     file format elf32-i386


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
  80002c:	e8 19 00 00 00       	call   80004a <libmain>
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
	// try to print the kernel entry point as a string!  mua ha ha!
	sys_cputs((char*)0xf010000c, 100);
  800039:	6a 64                	push   $0x64
  80003b:	68 0c 00 10 f0       	push   $0xf010000c
  800040:	e8 97 00 00 00       	call   8000dc <sys_cputs>
}
  800045:	83 c4 10             	add    $0x10,%esp
  800048:	c9                   	leave  
  800049:	c3                   	ret    

0080004a <libmain>:
const volatile struct Env *thisenv;
const char *binaryname = "<unknown>";

void
libmain(int argc, char **argv)
{
  80004a:	55                   	push   %ebp
  80004b:	89 e5                	mov    %esp,%ebp
  80004d:	83 ec 08             	sub    $0x8,%esp
  800050:	8b 45 08             	mov    0x8(%ebp),%eax
  800053:	8b 55 0c             	mov    0xc(%ebp),%edx
	// set thisenv to point at our Env structure in envs[].
	// LAB 3: Your code here.
	thisenv = 0;
  800056:	c7 05 04 10 80 00 00 	movl   $0x0,0x801004
  80005d:	00 00 00 

	// save the name of the program so that panic() can use it
	if (argc > 0)
  800060:	85 c0                	test   %eax,%eax
  800062:	7e 08                	jle    80006c <libmain+0x22>
		binaryname = argv[0];
  800064:	8b 0a                	mov    (%edx),%ecx
  800066:	89 0d 00 10 80 00    	mov    %ecx,0x801000

	// call user main routine
	umain(argc, argv);
  80006c:	83 ec 08             	sub    $0x8,%esp
  80006f:	52                   	push   %edx
  800070:	50                   	push   %eax
  800071:	e8 bd ff ff ff       	call   800033 <umain>

	// exit gracefully
	exit();
  800076:	e8 05 00 00 00       	call   800080 <exit>
}
  80007b:	83 c4 10             	add    $0x10,%esp
  80007e:	c9                   	leave  
  80007f:	c3                   	ret    

00800080 <exit>:

#include <inc/lib.h>

void
exit(void)
{
  800080:	55                   	push   %ebp
  800081:	89 e5                	mov    %esp,%ebp
  800083:	83 ec 14             	sub    $0x14,%esp
	sys_env_destroy(0);
  800086:	6a 00                	push   $0x0
  800088:	e8 99 00 00 00       	call   800126 <sys_env_destroy>
}
  80008d:	83 c4 10             	add    $0x10,%esp
  800090:	c9                   	leave  
  800091:	c3                   	ret    

00800092 <syscall>:
#include <inc/syscall.h>
#include <inc/lib.h>

static inline int32_t
syscall(int num, int check, uint32_t a1, uint32_t a2, uint32_t a3, uint32_t a4, uint32_t a5)
{
  800092:	55                   	push   %ebp
  800093:	89 e5                	mov    %esp,%ebp
  800095:	57                   	push   %edi
  800096:	56                   	push   %esi
  800097:	53                   	push   %ebx
  800098:	83 ec 1c             	sub    $0x1c,%esp
  80009b:	89 45 e0             	mov    %eax,-0x20(%ebp)
  80009e:	89 55 e4             	mov    %edx,-0x1c(%ebp)
  8000a1:	89 ca                	mov    %ecx,%edx
	//
	// The last clause tells the assembler that this can
	// potentially change the condition codes and arbitrary
	// memory locations.

	asm volatile("int %1\n"
  8000a3:	8b 4d 08             	mov    0x8(%ebp),%ecx
  8000a6:	8b 5d 0c             	mov    0xc(%ebp),%ebx
  8000a9:	8b 7d 10             	mov    0x10(%ebp),%edi
  8000ac:	8b 75 14             	mov    0x14(%ebp),%esi
  8000af:	cd 30                	int    $0x30
		       "b" (a3),
		       "D" (a4),
		       "S" (a5)
		     : "cc", "memory");

	if(check && ret > 0)
  8000b1:	83 7d e4 00          	cmpl   $0x0,-0x1c(%ebp)
  8000b5:	74 1d                	je     8000d4 <syscall+0x42>
  8000b7:	85 c0                	test   %eax,%eax
  8000b9:	7e 19                	jle    8000d4 <syscall+0x42>
  8000bb:	8b 55 e0             	mov    -0x20(%ebp),%edx
		panic("syscall %d returned %d (> 0)", num, ret);
  8000be:	83 ec 0c             	sub    $0xc,%esp
  8000c1:	50                   	push   %eax
  8000c2:	52                   	push   %edx
  8000c3:	68 8e 0d 80 00       	push   $0x800d8e
  8000c8:	6a 23                	push   $0x23
  8000ca:	68 ab 0d 80 00       	push   $0x800dab
  8000cf:	e8 98 00 00 00       	call   80016c <_panic>

	return ret;
}
  8000d4:	8d 65 f4             	lea    -0xc(%ebp),%esp
  8000d7:	5b                   	pop    %ebx
  8000d8:	5e                   	pop    %esi
  8000d9:	5f                   	pop    %edi
  8000da:	5d                   	pop    %ebp
  8000db:	c3                   	ret    

008000dc <sys_cputs>:

void
sys_cputs(const char *s, size_t len)
{
  8000dc:	55                   	push   %ebp
  8000dd:	89 e5                	mov    %esp,%ebp
  8000df:	83 ec 08             	sub    $0x8,%esp
	syscall(SYS_cputs, 0, (uint32_t)s, len, 0, 0, 0);
  8000e2:	6a 00                	push   $0x0
  8000e4:	6a 00                	push   $0x0
  8000e6:	6a 00                	push   $0x0
  8000e8:	ff 75 0c             	pushl  0xc(%ebp)
  8000eb:	8b 4d 08             	mov    0x8(%ebp),%ecx
  8000ee:	ba 00 00 00 00       	mov    $0x0,%edx
  8000f3:	b8 00 00 00 00       	mov    $0x0,%eax
  8000f8:	e8 95 ff ff ff       	call   800092 <syscall>
}
  8000fd:	83 c4 10             	add    $0x10,%esp
  800100:	c9                   	leave  
  800101:	c3                   	ret    

00800102 <sys_cgetc>:

int
sys_cgetc(void)
{
  800102:	55                   	push   %ebp
  800103:	89 e5                	mov    %esp,%ebp
  800105:	83 ec 08             	sub    $0x8,%esp
	return syscall(SYS_cgetc, 0, 0, 0, 0, 0, 0);
  800108:	6a 00                	push   $0x0
  80010a:	6a 00                	push   $0x0
  80010c:	6a 00                	push   $0x0
  80010e:	6a 00                	push   $0x0
  800110:	b9 00 00 00 00       	mov    $0x0,%ecx
  800115:	ba 00 00 00 00       	mov    $0x0,%edx
  80011a:	b8 01 00 00 00       	mov    $0x1,%eax
  80011f:	e8 6e ff ff ff       	call   800092 <syscall>
}
  800124:	c9                   	leave  
  800125:	c3                   	ret    

00800126 <sys_env_destroy>:

int
sys_env_destroy(envid_t envid)
{
  800126:	55                   	push   %ebp
  800127:	89 e5                	mov    %esp,%ebp
  800129:	83 ec 08             	sub    $0x8,%esp
	return syscall(SYS_env_destroy, 1, envid, 0, 0, 0, 0);
  80012c:	6a 00                	push   $0x0
  80012e:	6a 00                	push   $0x0
  800130:	6a 00                	push   $0x0
  800132:	6a 00                	push   $0x0
  800134:	8b 4d 08             	mov    0x8(%ebp),%ecx
  800137:	ba 01 00 00 00       	mov    $0x1,%edx
  80013c:	b8 03 00 00 00       	mov    $0x3,%eax
  800141:	e8 4c ff ff ff       	call   800092 <syscall>
}
  800146:	c9                   	leave  
  800147:	c3                   	ret    

00800148 <sys_getenvid>:

envid_t
sys_getenvid(void)
{
  800148:	55                   	push   %ebp
  800149:	89 e5                	mov    %esp,%ebp
  80014b:	83 ec 08             	sub    $0x8,%esp
	 return syscall(SYS_getenvid, 0, 0, 0, 0, 0, 0);
  80014e:	6a 00                	push   $0x0
  800150:	6a 00                	push   $0x0
  800152:	6a 00                	push   $0x0
  800154:	6a 00                	push   $0x0
  800156:	b9 00 00 00 00       	mov    $0x0,%ecx
  80015b:	ba 00 00 00 00       	mov    $0x0,%edx
  800160:	b8 02 00 00 00       	mov    $0x2,%eax
  800165:	e8 28 ff ff ff       	call   800092 <syscall>
}
  80016a:	c9                   	leave  
  80016b:	c3                   	ret    

0080016c <_panic>:
 * It prints "panic: <message>", then causes a breakpoint exception,
 * which causes JOS to enter the JOS kernel monitor.
 */
void
_panic(const char *file, int line, const char *fmt, ...)
{
  80016c:	55                   	push   %ebp
  80016d:	89 e5                	mov    %esp,%ebp
  80016f:	56                   	push   %esi
  800170:	53                   	push   %ebx
	va_list ap;

	va_start(ap, fmt);
  800171:	8d 5d 14             	lea    0x14(%ebp),%ebx

	// Print the panic message
	cprintf("[%08x] user panic in %s at %s:%d: ",
  800174:	8b 35 00 10 80 00    	mov    0x801000,%esi
  80017a:	e8 c9 ff ff ff       	call   800148 <sys_getenvid>
  80017f:	83 ec 0c             	sub    $0xc,%esp
  800182:	ff 75 0c             	pushl  0xc(%ebp)
  800185:	ff 75 08             	pushl  0x8(%ebp)
  800188:	56                   	push   %esi
  800189:	50                   	push   %eax
  80018a:	68 bc 0d 80 00       	push   $0x800dbc
  80018f:	e8 b1 00 00 00       	call   800245 <cprintf>
		sys_getenvid(), binaryname, file, line);
	vcprintf(fmt, ap);
  800194:	83 c4 18             	add    $0x18,%esp
  800197:	53                   	push   %ebx
  800198:	ff 75 10             	pushl  0x10(%ebp)
  80019b:	e8 54 00 00 00       	call   8001f4 <vcprintf>
	cprintf("\n");
  8001a0:	c7 04 24 e0 0d 80 00 	movl   $0x800de0,(%esp)
  8001a7:	e8 99 00 00 00       	call   800245 <cprintf>
  8001ac:	83 c4 10             	add    $0x10,%esp

	// Cause a breakpoint exception
	while (1)
		asm volatile("int3");
  8001af:	cc                   	int3   
  8001b0:	eb fd                	jmp    8001af <_panic+0x43>

008001b2 <putch>:
};


static void
putch(int ch, struct printbuf *b)
{
  8001b2:	55                   	push   %ebp
  8001b3:	89 e5                	mov    %esp,%ebp
  8001b5:	53                   	push   %ebx
  8001b6:	83 ec 04             	sub    $0x4,%esp
  8001b9:	8b 5d 0c             	mov    0xc(%ebp),%ebx
	b->buf[b->idx++] = ch;
  8001bc:	8b 13                	mov    (%ebx),%edx
  8001be:	8d 42 01             	lea    0x1(%edx),%eax
  8001c1:	89 03                	mov    %eax,(%ebx)
  8001c3:	8b 4d 08             	mov    0x8(%ebp),%ecx
  8001c6:	88 4c 13 08          	mov    %cl,0x8(%ebx,%edx,1)
	if (b->idx == 256-1) {
  8001ca:	3d ff 00 00 00       	cmp    $0xff,%eax
  8001cf:	75 1a                	jne    8001eb <putch+0x39>
		sys_cputs(b->buf, b->idx);
  8001d1:	83 ec 08             	sub    $0x8,%esp
  8001d4:	68 ff 00 00 00       	push   $0xff
  8001d9:	8d 43 08             	lea    0x8(%ebx),%eax
  8001dc:	50                   	push   %eax
  8001dd:	e8 fa fe ff ff       	call   8000dc <sys_cputs>
		b->idx = 0;
  8001e2:	c7 03 00 00 00 00    	movl   $0x0,(%ebx)
  8001e8:	83 c4 10             	add    $0x10,%esp
	}
	b->cnt++;
  8001eb:	83 43 04 01          	addl   $0x1,0x4(%ebx)
}
  8001ef:	8b 5d fc             	mov    -0x4(%ebp),%ebx
  8001f2:	c9                   	leave  
  8001f3:	c3                   	ret    

008001f4 <vcprintf>:

int
vcprintf(const char *fmt, va_list ap)
{
  8001f4:	55                   	push   %ebp
  8001f5:	89 e5                	mov    %esp,%ebp
  8001f7:	81 ec 18 01 00 00    	sub    $0x118,%esp
	struct printbuf b;

	b.idx = 0;
  8001fd:	c7 85 f0 fe ff ff 00 	movl   $0x0,-0x110(%ebp)
  800204:	00 00 00 
	b.cnt = 0;
  800207:	c7 85 f4 fe ff ff 00 	movl   $0x0,-0x10c(%ebp)
  80020e:	00 00 00 
	vprintfmt((void*)putch, &b, fmt, ap);
  800211:	ff 75 0c             	pushl  0xc(%ebp)
  800214:	ff 75 08             	pushl  0x8(%ebp)
  800217:	8d 85 f0 fe ff ff    	lea    -0x110(%ebp),%eax
  80021d:	50                   	push   %eax
  80021e:	68 b2 01 80 00       	push   $0x8001b2
  800223:	e8 86 01 00 00       	call   8003ae <vprintfmt>
	sys_cputs(b.buf, b.idx);
  800228:	83 c4 08             	add    $0x8,%esp
  80022b:	ff b5 f0 fe ff ff    	pushl  -0x110(%ebp)
  800231:	8d 85 f8 fe ff ff    	lea    -0x108(%ebp),%eax
  800237:	50                   	push   %eax
  800238:	e8 9f fe ff ff       	call   8000dc <sys_cputs>

	return b.cnt;
}
  80023d:	8b 85 f4 fe ff ff    	mov    -0x10c(%ebp),%eax
  800243:	c9                   	leave  
  800244:	c3                   	ret    

00800245 <cprintf>:

int
cprintf(const char *fmt, ...)
{
  800245:	55                   	push   %ebp
  800246:	89 e5                	mov    %esp,%ebp
  800248:	83 ec 10             	sub    $0x10,%esp
	va_list ap;
	int cnt;

	va_start(ap, fmt);
  80024b:	8d 45 0c             	lea    0xc(%ebp),%eax
	cnt = vcprintf(fmt, ap);
  80024e:	50                   	push   %eax
  80024f:	ff 75 08             	pushl  0x8(%ebp)
  800252:	e8 9d ff ff ff       	call   8001f4 <vcprintf>
	va_end(ap);

	return cnt;
}
  800257:	c9                   	leave  
  800258:	c3                   	ret    

00800259 <printnum>:
 * using specified putch function and associated pointer putdat.
 */
static void
printnum(void (*putch)(int, void*), void *putdat,
	 unsigned long long num, unsigned base, int width, int padc)
{
  800259:	55                   	push   %ebp
  80025a:	89 e5                	mov    %esp,%ebp
  80025c:	57                   	push   %edi
  80025d:	56                   	push   %esi
  80025e:	53                   	push   %ebx
  80025f:	83 ec 1c             	sub    $0x1c,%esp
  800262:	89 c7                	mov    %eax,%edi
  800264:	89 d6                	mov    %edx,%esi
  800266:	8b 45 08             	mov    0x8(%ebp),%eax
  800269:	8b 55 0c             	mov    0xc(%ebp),%edx
  80026c:	89 45 d8             	mov    %eax,-0x28(%ebp)
  80026f:	89 55 dc             	mov    %edx,-0x24(%ebp)
	// first recursively print all preceding (more significant) digits
	if (num >= base) {
  800272:	8b 4d 10             	mov    0x10(%ebp),%ecx
  800275:	bb 00 00 00 00       	mov    $0x0,%ebx
  80027a:	89 4d e0             	mov    %ecx,-0x20(%ebp)
  80027d:	89 5d e4             	mov    %ebx,-0x1c(%ebp)
  800280:	39 d3                	cmp    %edx,%ebx
  800282:	72 05                	jb     800289 <printnum+0x30>
  800284:	39 45 10             	cmp    %eax,0x10(%ebp)
  800287:	77 45                	ja     8002ce <printnum+0x75>
		printnum(putch, putdat, num / base, base, width - 1, padc);
  800289:	83 ec 0c             	sub    $0xc,%esp
  80028c:	ff 75 18             	pushl  0x18(%ebp)
  80028f:	8b 45 14             	mov    0x14(%ebp),%eax
  800292:	8d 58 ff             	lea    -0x1(%eax),%ebx
  800295:	53                   	push   %ebx
  800296:	ff 75 10             	pushl  0x10(%ebp)
  800299:	83 ec 08             	sub    $0x8,%esp
  80029c:	ff 75 e4             	pushl  -0x1c(%ebp)
  80029f:	ff 75 e0             	pushl  -0x20(%ebp)
  8002a2:	ff 75 dc             	pushl  -0x24(%ebp)
  8002a5:	ff 75 d8             	pushl  -0x28(%ebp)
  8002a8:	e8 53 08 00 00       	call   800b00 <__udivdi3>
  8002ad:	83 c4 18             	add    $0x18,%esp
  8002b0:	52                   	push   %edx
  8002b1:	50                   	push   %eax
  8002b2:	89 f2                	mov    %esi,%edx
  8002b4:	89 f8                	mov    %edi,%eax
  8002b6:	e8 9e ff ff ff       	call   800259 <printnum>
  8002bb:	83 c4 20             	add    $0x20,%esp
  8002be:	eb 18                	jmp    8002d8 <printnum+0x7f>
	} else {
		// print any needed pad characters before first digit
		while (--width > 0)
			putch(padc, putdat);
  8002c0:	83 ec 08             	sub    $0x8,%esp
  8002c3:	56                   	push   %esi
  8002c4:	ff 75 18             	pushl  0x18(%ebp)
  8002c7:	ff d7                	call   *%edi
  8002c9:	83 c4 10             	add    $0x10,%esp
  8002cc:	eb 03                	jmp    8002d1 <printnum+0x78>
  8002ce:	8b 5d 14             	mov    0x14(%ebp),%ebx
	// first recursively print all preceding (more significant) digits
	if (num >= base) {
		printnum(putch, putdat, num / base, base, width - 1, padc);
	} else {
		// print any needed pad characters before first digit
		while (--width > 0)
  8002d1:	83 eb 01             	sub    $0x1,%ebx
  8002d4:	85 db                	test   %ebx,%ebx
  8002d6:	7f e8                	jg     8002c0 <printnum+0x67>
			putch(padc, putdat);
	}

	// then print this (the least significant) digit
	putch("0123456789abcdef"[num % base], putdat);
  8002d8:	83 ec 08             	sub    $0x8,%esp
  8002db:	56                   	push   %esi
  8002dc:	83 ec 04             	sub    $0x4,%esp
  8002df:	ff 75 e4             	pushl  -0x1c(%ebp)
  8002e2:	ff 75 e0             	pushl  -0x20(%ebp)
  8002e5:	ff 75 dc             	pushl  -0x24(%ebp)
  8002e8:	ff 75 d8             	pushl  -0x28(%ebp)
  8002eb:	e8 40 09 00 00       	call   800c30 <__umoddi3>
  8002f0:	83 c4 14             	add    $0x14,%esp
  8002f3:	0f be 80 e2 0d 80 00 	movsbl 0x800de2(%eax),%eax
  8002fa:	50                   	push   %eax
  8002fb:	ff d7                	call   *%edi
}
  8002fd:	83 c4 10             	add    $0x10,%esp
  800300:	8d 65 f4             	lea    -0xc(%ebp),%esp
  800303:	5b                   	pop    %ebx
  800304:	5e                   	pop    %esi
  800305:	5f                   	pop    %edi
  800306:	5d                   	pop    %ebp
  800307:	c3                   	ret    

00800308 <getuint>:

// Get an unsigned int of various possible sizes from a varargs list,
// depending on the lflag parameter.
static unsigned long long
getuint(va_list *ap, int lflag)
{
  800308:	55                   	push   %ebp
  800309:	89 e5                	mov    %esp,%ebp
	if (lflag >= 2)
  80030b:	83 fa 01             	cmp    $0x1,%edx
  80030e:	7e 0e                	jle    80031e <getuint+0x16>
		return va_arg(*ap, unsigned long long);
  800310:	8b 10                	mov    (%eax),%edx
  800312:	8d 4a 08             	lea    0x8(%edx),%ecx
  800315:	89 08                	mov    %ecx,(%eax)
  800317:	8b 02                	mov    (%edx),%eax
  800319:	8b 52 04             	mov    0x4(%edx),%edx
  80031c:	eb 22                	jmp    800340 <getuint+0x38>
	else if (lflag)
  80031e:	85 d2                	test   %edx,%edx
  800320:	74 10                	je     800332 <getuint+0x2a>
		return va_arg(*ap, unsigned long);
  800322:	8b 10                	mov    (%eax),%edx
  800324:	8d 4a 04             	lea    0x4(%edx),%ecx
  800327:	89 08                	mov    %ecx,(%eax)
  800329:	8b 02                	mov    (%edx),%eax
  80032b:	ba 00 00 00 00       	mov    $0x0,%edx
  800330:	eb 0e                	jmp    800340 <getuint+0x38>
	else
		return va_arg(*ap, unsigned int);
  800332:	8b 10                	mov    (%eax),%edx
  800334:	8d 4a 04             	lea    0x4(%edx),%ecx
  800337:	89 08                	mov    %ecx,(%eax)
  800339:	8b 02                	mov    (%edx),%eax
  80033b:	ba 00 00 00 00       	mov    $0x0,%edx
}
  800340:	5d                   	pop    %ebp
  800341:	c3                   	ret    

00800342 <getint>:

// Same as getuint but signed - can't use getuint
// because of sign extension
static long long
getint(va_list *ap, int lflag)
{
  800342:	55                   	push   %ebp
  800343:	89 e5                	mov    %esp,%ebp
	if (lflag >= 2)
  800345:	83 fa 01             	cmp    $0x1,%edx
  800348:	7e 0e                	jle    800358 <getint+0x16>
		return va_arg(*ap, long long);
  80034a:	8b 10                	mov    (%eax),%edx
  80034c:	8d 4a 08             	lea    0x8(%edx),%ecx
  80034f:	89 08                	mov    %ecx,(%eax)
  800351:	8b 02                	mov    (%edx),%eax
  800353:	8b 52 04             	mov    0x4(%edx),%edx
  800356:	eb 1a                	jmp    800372 <getint+0x30>
	else if (lflag)
  800358:	85 d2                	test   %edx,%edx
  80035a:	74 0c                	je     800368 <getint+0x26>
		return va_arg(*ap, long);
  80035c:	8b 10                	mov    (%eax),%edx
  80035e:	8d 4a 04             	lea    0x4(%edx),%ecx
  800361:	89 08                	mov    %ecx,(%eax)
  800363:	8b 02                	mov    (%edx),%eax
  800365:	99                   	cltd   
  800366:	eb 0a                	jmp    800372 <getint+0x30>
	else
		return va_arg(*ap, int);
  800368:	8b 10                	mov    (%eax),%edx
  80036a:	8d 4a 04             	lea    0x4(%edx),%ecx
  80036d:	89 08                	mov    %ecx,(%eax)
  80036f:	8b 02                	mov    (%edx),%eax
  800371:	99                   	cltd   
}
  800372:	5d                   	pop    %ebp
  800373:	c3                   	ret    

00800374 <sprintputch>:
	int cnt;
};

static void
sprintputch(int ch, struct sprintbuf *b)
{
  800374:	55                   	push   %ebp
  800375:	89 e5                	mov    %esp,%ebp
  800377:	8b 45 0c             	mov    0xc(%ebp),%eax
	b->cnt++;
  80037a:	83 40 08 01          	addl   $0x1,0x8(%eax)
	if (b->buf < b->ebuf)
  80037e:	8b 10                	mov    (%eax),%edx
  800380:	3b 50 04             	cmp    0x4(%eax),%edx
  800383:	73 0a                	jae    80038f <sprintputch+0x1b>
		*b->buf++ = ch;
  800385:	8d 4a 01             	lea    0x1(%edx),%ecx
  800388:	89 08                	mov    %ecx,(%eax)
  80038a:	8b 45 08             	mov    0x8(%ebp),%eax
  80038d:	88 02                	mov    %al,(%edx)
}
  80038f:	5d                   	pop    %ebp
  800390:	c3                   	ret    

00800391 <printfmt>:
	}
}

void
printfmt(void (*putch)(int, void*), void *putdat, const char *fmt, ...)
{
  800391:	55                   	push   %ebp
  800392:	89 e5                	mov    %esp,%ebp
  800394:	83 ec 08             	sub    $0x8,%esp
	va_list ap;

	va_start(ap, fmt);
  800397:	8d 45 14             	lea    0x14(%ebp),%eax
	vprintfmt(putch, putdat, fmt, ap);
  80039a:	50                   	push   %eax
  80039b:	ff 75 10             	pushl  0x10(%ebp)
  80039e:	ff 75 0c             	pushl  0xc(%ebp)
  8003a1:	ff 75 08             	pushl  0x8(%ebp)
  8003a4:	e8 05 00 00 00       	call   8003ae <vprintfmt>
	va_end(ap);
}
  8003a9:	83 c4 10             	add    $0x10,%esp
  8003ac:	c9                   	leave  
  8003ad:	c3                   	ret    

008003ae <vprintfmt>:
// Main function to format and print a string.
void printfmt(void (*putch)(int, void*), void *putdat, const char *fmt, ...);

void
vprintfmt(void (*putch)(int, void*), void *putdat, const char *fmt, va_list ap)
{
  8003ae:	55                   	push   %ebp
  8003af:	89 e5                	mov    %esp,%ebp
  8003b1:	57                   	push   %edi
  8003b2:	56                   	push   %esi
  8003b3:	53                   	push   %ebx
  8003b4:	83 ec 2c             	sub    $0x2c,%esp
  8003b7:	8b 75 08             	mov    0x8(%ebp),%esi
  8003ba:	8b 5d 0c             	mov    0xc(%ebp),%ebx
  8003bd:	8b 7d 10             	mov    0x10(%ebp),%edi
  8003c0:	eb 12                	jmp    8003d4 <vprintfmt+0x26>
	int base, lflag, width, precision, altflag;
	char padc;

	while (1) {
		while ((ch = *(unsigned char *) fmt++) != '%') {
			if (ch == '\0')
  8003c2:	85 c0                	test   %eax,%eax
  8003c4:	0f 84 44 03 00 00    	je     80070e <vprintfmt+0x360>
				return;
			putch(ch, putdat);
  8003ca:	83 ec 08             	sub    $0x8,%esp
  8003cd:	53                   	push   %ebx
  8003ce:	50                   	push   %eax
  8003cf:	ff d6                	call   *%esi
  8003d1:	83 c4 10             	add    $0x10,%esp
	unsigned long long num;
	int base, lflag, width, precision, altflag;
	char padc;

	while (1) {
		while ((ch = *(unsigned char *) fmt++) != '%') {
  8003d4:	83 c7 01             	add    $0x1,%edi
  8003d7:	0f b6 47 ff          	movzbl -0x1(%edi),%eax
  8003db:	83 f8 25             	cmp    $0x25,%eax
  8003de:	75 e2                	jne    8003c2 <vprintfmt+0x14>
  8003e0:	c6 45 d4 20          	movb   $0x20,-0x2c(%ebp)
  8003e4:	c7 45 d8 00 00 00 00 	movl   $0x0,-0x28(%ebp)
  8003eb:	c7 45 d0 ff ff ff ff 	movl   $0xffffffff,-0x30(%ebp)
  8003f2:	c7 45 e0 ff ff ff ff 	movl   $0xffffffff,-0x20(%ebp)
  8003f9:	ba 00 00 00 00       	mov    $0x0,%edx
  8003fe:	eb 07                	jmp    800407 <vprintfmt+0x59>
		width = -1;
		precision = -1;
		lflag = 0;
		altflag = 0;
	reswitch:
		switch (ch = *(unsigned char *) fmt++) {
  800400:	8b 7d e4             	mov    -0x1c(%ebp),%edi

		// flag to pad on the right
		case '-':
			padc = '-';
  800403:	c6 45 d4 2d          	movb   $0x2d,-0x2c(%ebp)
		width = -1;
		precision = -1;
		lflag = 0;
		altflag = 0;
	reswitch:
		switch (ch = *(unsigned char *) fmt++) {
  800407:	8d 47 01             	lea    0x1(%edi),%eax
  80040a:	89 45 e4             	mov    %eax,-0x1c(%ebp)
  80040d:	0f b6 07             	movzbl (%edi),%eax
  800410:	0f b6 c8             	movzbl %al,%ecx
  800413:	83 e8 23             	sub    $0x23,%eax
  800416:	3c 55                	cmp    $0x55,%al
  800418:	0f 87 d5 02 00 00    	ja     8006f3 <vprintfmt+0x345>
  80041e:	0f b6 c0             	movzbl %al,%eax
  800421:	ff 24 85 70 0e 80 00 	jmp    *0x800e70(,%eax,4)
  800428:	8b 7d e4             	mov    -0x1c(%ebp),%edi
			padc = '-';
			goto reswitch;

		// flag to pad with 0's instead of spaces
		case '0':
			padc = '0';
  80042b:	c6 45 d4 30          	movb   $0x30,-0x2c(%ebp)
  80042f:	eb d6                	jmp    800407 <vprintfmt+0x59>
		width = -1;
		precision = -1;
		lflag = 0;
		altflag = 0;
	reswitch:
		switch (ch = *(unsigned char *) fmt++) {
  800431:	8b 7d e4             	mov    -0x1c(%ebp),%edi
  800434:	b8 00 00 00 00       	mov    $0x0,%eax
  800439:	89 55 e4             	mov    %edx,-0x1c(%ebp)
		case '6':
		case '7':
		case '8':
		case '9':
			for (precision = 0; ; ++fmt) {
				precision = precision * 10 + ch - '0';
  80043c:	8d 04 80             	lea    (%eax,%eax,4),%eax
  80043f:	8d 44 41 d0          	lea    -0x30(%ecx,%eax,2),%eax
				ch = *fmt;
  800443:	0f be 0f             	movsbl (%edi),%ecx
				if (ch < '0' || ch > '9')
  800446:	8d 51 d0             	lea    -0x30(%ecx),%edx
  800449:	83 fa 09             	cmp    $0x9,%edx
  80044c:	77 39                	ja     800487 <vprintfmt+0xd9>
		case '5':
		case '6':
		case '7':
		case '8':
		case '9':
			for (precision = 0; ; ++fmt) {
  80044e:	83 c7 01             	add    $0x1,%edi
				precision = precision * 10 + ch - '0';
				ch = *fmt;
				if (ch < '0' || ch > '9')
					break;
			}
  800451:	eb e9                	jmp    80043c <vprintfmt+0x8e>
			goto process_precision;

		case '*':
			precision = va_arg(ap, int);
  800453:	8b 45 14             	mov    0x14(%ebp),%eax
  800456:	8d 48 04             	lea    0x4(%eax),%ecx
  800459:	89 4d 14             	mov    %ecx,0x14(%ebp)
  80045c:	8b 00                	mov    (%eax),%eax
  80045e:	89 45 d0             	mov    %eax,-0x30(%ebp)
		width = -1;
		precision = -1;
		lflag = 0;
		altflag = 0;
	reswitch:
		switch (ch = *(unsigned char *) fmt++) {
  800461:	8b 7d e4             	mov    -0x1c(%ebp),%edi
			}
			goto process_precision;

		case '*':
			precision = va_arg(ap, int);
			goto process_precision;
  800464:	eb 27                	jmp    80048d <vprintfmt+0xdf>
  800466:	8b 45 e0             	mov    -0x20(%ebp),%eax
  800469:	85 c0                	test   %eax,%eax
  80046b:	b9 00 00 00 00       	mov    $0x0,%ecx
  800470:	0f 49 c8             	cmovns %eax,%ecx
  800473:	89 4d e0             	mov    %ecx,-0x20(%ebp)
		width = -1;
		precision = -1;
		lflag = 0;
		altflag = 0;
	reswitch:
		switch (ch = *(unsigned char *) fmt++) {
  800476:	8b 7d e4             	mov    -0x1c(%ebp),%edi
  800479:	eb 8c                	jmp    800407 <vprintfmt+0x59>
  80047b:	8b 7d e4             	mov    -0x1c(%ebp),%edi
			if (width < 0)
				width = 0;
			goto reswitch;

		case '#':
			altflag = 1;
  80047e:	c7 45 d8 01 00 00 00 	movl   $0x1,-0x28(%ebp)
			goto reswitch;
  800485:	eb 80                	jmp    800407 <vprintfmt+0x59>
  800487:	8b 55 e4             	mov    -0x1c(%ebp),%edx
  80048a:	89 45 d0             	mov    %eax,-0x30(%ebp)

		process_precision:
			if (width < 0)
  80048d:	83 7d e0 00          	cmpl   $0x0,-0x20(%ebp)
  800491:	0f 89 70 ff ff ff    	jns    800407 <vprintfmt+0x59>
				width = precision, precision = -1;
  800497:	8b 45 d0             	mov    -0x30(%ebp),%eax
  80049a:	89 45 e0             	mov    %eax,-0x20(%ebp)
  80049d:	c7 45 d0 ff ff ff ff 	movl   $0xffffffff,-0x30(%ebp)
  8004a4:	e9 5e ff ff ff       	jmp    800407 <vprintfmt+0x59>
			goto reswitch;

		// long flag (doubled for long long)
		case 'l':
			lflag++;
  8004a9:	83 c2 01             	add    $0x1,%edx
		width = -1;
		precision = -1;
		lflag = 0;
		altflag = 0;
	reswitch:
		switch (ch = *(unsigned char *) fmt++) {
  8004ac:	8b 7d e4             	mov    -0x1c(%ebp),%edi
			goto reswitch;

		// long flag (doubled for long long)
		case 'l':
			lflag++;
			goto reswitch;
  8004af:	e9 53 ff ff ff       	jmp    800407 <vprintfmt+0x59>

		// character
		case 'c':
			putch(va_arg(ap, int), putdat);
  8004b4:	8b 45 14             	mov    0x14(%ebp),%eax
  8004b7:	8d 50 04             	lea    0x4(%eax),%edx
  8004ba:	89 55 14             	mov    %edx,0x14(%ebp)
  8004bd:	83 ec 08             	sub    $0x8,%esp
  8004c0:	53                   	push   %ebx
  8004c1:	ff 30                	pushl  (%eax)
  8004c3:	ff d6                	call   *%esi
			break;
  8004c5:	83 c4 10             	add    $0x10,%esp
		width = -1;
		precision = -1;
		lflag = 0;
		altflag = 0;
	reswitch:
		switch (ch = *(unsigned char *) fmt++) {
  8004c8:	8b 7d e4             	mov    -0x1c(%ebp),%edi
			goto reswitch;

		// character
		case 'c':
			putch(va_arg(ap, int), putdat);
			break;
  8004cb:	e9 04 ff ff ff       	jmp    8003d4 <vprintfmt+0x26>

		// error message
		case 'e':
			err = va_arg(ap, int);
  8004d0:	8b 45 14             	mov    0x14(%ebp),%eax
  8004d3:	8d 50 04             	lea    0x4(%eax),%edx
  8004d6:	89 55 14             	mov    %edx,0x14(%ebp)
  8004d9:	8b 00                	mov    (%eax),%eax
  8004db:	99                   	cltd   
  8004dc:	31 d0                	xor    %edx,%eax
  8004de:	29 d0                	sub    %edx,%eax
			if (err < 0)
				err = -err;
			if (err >= MAXERROR || (p = error_string[err]) == NULL)
  8004e0:	83 f8 06             	cmp    $0x6,%eax
  8004e3:	7f 0b                	jg     8004f0 <vprintfmt+0x142>
  8004e5:	8b 14 85 c8 0f 80 00 	mov    0x800fc8(,%eax,4),%edx
  8004ec:	85 d2                	test   %edx,%edx
  8004ee:	75 18                	jne    800508 <vprintfmt+0x15a>
				printfmt(putch, putdat, "error %d", err);
  8004f0:	50                   	push   %eax
  8004f1:	68 fa 0d 80 00       	push   $0x800dfa
  8004f6:	53                   	push   %ebx
  8004f7:	56                   	push   %esi
  8004f8:	e8 94 fe ff ff       	call   800391 <printfmt>
  8004fd:	83 c4 10             	add    $0x10,%esp
		width = -1;
		precision = -1;
		lflag = 0;
		altflag = 0;
	reswitch:
		switch (ch = *(unsigned char *) fmt++) {
  800500:	8b 7d e4             	mov    -0x1c(%ebp),%edi
		case 'e':
			err = va_arg(ap, int);
			if (err < 0)
				err = -err;
			if (err >= MAXERROR || (p = error_string[err]) == NULL)
				printfmt(putch, putdat, "error %d", err);
  800503:	e9 cc fe ff ff       	jmp    8003d4 <vprintfmt+0x26>
			else
				printfmt(putch, putdat, "%s", p);
  800508:	52                   	push   %edx
  800509:	68 03 0e 80 00       	push   $0x800e03
  80050e:	53                   	push   %ebx
  80050f:	56                   	push   %esi
  800510:	e8 7c fe ff ff       	call   800391 <printfmt>
  800515:	83 c4 10             	add    $0x10,%esp
		width = -1;
		precision = -1;
		lflag = 0;
		altflag = 0;
	reswitch:
		switch (ch = *(unsigned char *) fmt++) {
  800518:	8b 7d e4             	mov    -0x1c(%ebp),%edi
  80051b:	e9 b4 fe ff ff       	jmp    8003d4 <vprintfmt+0x26>
				printfmt(putch, putdat, "%s", p);
			break;

		// string
		case 's':
			if ((p = va_arg(ap, char *)) == NULL)
  800520:	8b 45 14             	mov    0x14(%ebp),%eax
  800523:	8d 50 04             	lea    0x4(%eax),%edx
  800526:	89 55 14             	mov    %edx,0x14(%ebp)
  800529:	8b 38                	mov    (%eax),%edi
				p = "(null)";
  80052b:	85 ff                	test   %edi,%edi
  80052d:	b8 f3 0d 80 00       	mov    $0x800df3,%eax
  800532:	0f 44 f8             	cmove  %eax,%edi
			if (width > 0 && padc != '-')
  800535:	83 7d e0 00          	cmpl   $0x0,-0x20(%ebp)
  800539:	0f 8e 94 00 00 00    	jle    8005d3 <vprintfmt+0x225>
  80053f:	80 7d d4 2d          	cmpb   $0x2d,-0x2c(%ebp)
  800543:	0f 84 98 00 00 00    	je     8005e1 <vprintfmt+0x233>
				for (width -= strnlen(p, precision); width > 0; width--)
  800549:	83 ec 08             	sub    $0x8,%esp
  80054c:	ff 75 d0             	pushl  -0x30(%ebp)
  80054f:	57                   	push   %edi
  800550:	e8 41 02 00 00       	call   800796 <strnlen>
  800555:	8b 4d e0             	mov    -0x20(%ebp),%ecx
  800558:	29 c1                	sub    %eax,%ecx
  80055a:	89 4d cc             	mov    %ecx,-0x34(%ebp)
  80055d:	83 c4 10             	add    $0x10,%esp
					putch(padc, putdat);
  800560:	0f be 45 d4          	movsbl -0x2c(%ebp),%eax
  800564:	89 45 e0             	mov    %eax,-0x20(%ebp)
  800567:	89 7d d4             	mov    %edi,-0x2c(%ebp)
  80056a:	89 cf                	mov    %ecx,%edi
		// string
		case 's':
			if ((p = va_arg(ap, char *)) == NULL)
				p = "(null)";
			if (width > 0 && padc != '-')
				for (width -= strnlen(p, precision); width > 0; width--)
  80056c:	eb 0f                	jmp    80057d <vprintfmt+0x1cf>
					putch(padc, putdat);
  80056e:	83 ec 08             	sub    $0x8,%esp
  800571:	53                   	push   %ebx
  800572:	ff 75 e0             	pushl  -0x20(%ebp)
  800575:	ff d6                	call   *%esi
		// string
		case 's':
			if ((p = va_arg(ap, char *)) == NULL)
				p = "(null)";
			if (width > 0 && padc != '-')
				for (width -= strnlen(p, precision); width > 0; width--)
  800577:	83 ef 01             	sub    $0x1,%edi
  80057a:	83 c4 10             	add    $0x10,%esp
  80057d:	85 ff                	test   %edi,%edi
  80057f:	7f ed                	jg     80056e <vprintfmt+0x1c0>
  800581:	8b 7d d4             	mov    -0x2c(%ebp),%edi
  800584:	8b 4d cc             	mov    -0x34(%ebp),%ecx
  800587:	85 c9                	test   %ecx,%ecx
  800589:	b8 00 00 00 00       	mov    $0x0,%eax
  80058e:	0f 49 c1             	cmovns %ecx,%eax
  800591:	29 c1                	sub    %eax,%ecx
  800593:	89 75 08             	mov    %esi,0x8(%ebp)
  800596:	8b 75 d0             	mov    -0x30(%ebp),%esi
  800599:	89 5d 0c             	mov    %ebx,0xc(%ebp)
  80059c:	89 cb                	mov    %ecx,%ebx
  80059e:	eb 4d                	jmp    8005ed <vprintfmt+0x23f>
					putch(padc, putdat);
			for (; (ch = *p++) != '\0' && (precision < 0 || --precision >= 0); width--)
				if (altflag && (ch < ' ' || ch > '~'))
  8005a0:	83 7d d8 00          	cmpl   $0x0,-0x28(%ebp)
  8005a4:	74 1b                	je     8005c1 <vprintfmt+0x213>
  8005a6:	0f be c0             	movsbl %al,%eax
  8005a9:	83 e8 20             	sub    $0x20,%eax
  8005ac:	83 f8 5e             	cmp    $0x5e,%eax
  8005af:	76 10                	jbe    8005c1 <vprintfmt+0x213>
					putch('?', putdat);
  8005b1:	83 ec 08             	sub    $0x8,%esp
  8005b4:	ff 75 0c             	pushl  0xc(%ebp)
  8005b7:	6a 3f                	push   $0x3f
  8005b9:	ff 55 08             	call   *0x8(%ebp)
  8005bc:	83 c4 10             	add    $0x10,%esp
  8005bf:	eb 0d                	jmp    8005ce <vprintfmt+0x220>
				else
					putch(ch, putdat);
  8005c1:	83 ec 08             	sub    $0x8,%esp
  8005c4:	ff 75 0c             	pushl  0xc(%ebp)
  8005c7:	52                   	push   %edx
  8005c8:	ff 55 08             	call   *0x8(%ebp)
  8005cb:	83 c4 10             	add    $0x10,%esp
			if ((p = va_arg(ap, char *)) == NULL)
				p = "(null)";
			if (width > 0 && padc != '-')
				for (width -= strnlen(p, precision); width > 0; width--)
					putch(padc, putdat);
			for (; (ch = *p++) != '\0' && (precision < 0 || --precision >= 0); width--)
  8005ce:	83 eb 01             	sub    $0x1,%ebx
  8005d1:	eb 1a                	jmp    8005ed <vprintfmt+0x23f>
  8005d3:	89 75 08             	mov    %esi,0x8(%ebp)
  8005d6:	8b 75 d0             	mov    -0x30(%ebp),%esi
  8005d9:	89 5d 0c             	mov    %ebx,0xc(%ebp)
  8005dc:	8b 5d e0             	mov    -0x20(%ebp),%ebx
  8005df:	eb 0c                	jmp    8005ed <vprintfmt+0x23f>
  8005e1:	89 75 08             	mov    %esi,0x8(%ebp)
  8005e4:	8b 75 d0             	mov    -0x30(%ebp),%esi
  8005e7:	89 5d 0c             	mov    %ebx,0xc(%ebp)
  8005ea:	8b 5d e0             	mov    -0x20(%ebp),%ebx
  8005ed:	83 c7 01             	add    $0x1,%edi
  8005f0:	0f b6 47 ff          	movzbl -0x1(%edi),%eax
  8005f4:	0f be d0             	movsbl %al,%edx
  8005f7:	85 d2                	test   %edx,%edx
  8005f9:	74 23                	je     80061e <vprintfmt+0x270>
  8005fb:	85 f6                	test   %esi,%esi
  8005fd:	78 a1                	js     8005a0 <vprintfmt+0x1f2>
  8005ff:	83 ee 01             	sub    $0x1,%esi
  800602:	79 9c                	jns    8005a0 <vprintfmt+0x1f2>
  800604:	89 df                	mov    %ebx,%edi
  800606:	8b 75 08             	mov    0x8(%ebp),%esi
  800609:	8b 5d 0c             	mov    0xc(%ebp),%ebx
  80060c:	eb 18                	jmp    800626 <vprintfmt+0x278>
				if (altflag && (ch < ' ' || ch > '~'))
					putch('?', putdat);
				else
					putch(ch, putdat);
			for (; width > 0; width--)
				putch(' ', putdat);
  80060e:	83 ec 08             	sub    $0x8,%esp
  800611:	53                   	push   %ebx
  800612:	6a 20                	push   $0x20
  800614:	ff d6                	call   *%esi
			for (; (ch = *p++) != '\0' && (precision < 0 || --precision >= 0); width--)
				if (altflag && (ch < ' ' || ch > '~'))
					putch('?', putdat);
				else
					putch(ch, putdat);
			for (; width > 0; width--)
  800616:	83 ef 01             	sub    $0x1,%edi
  800619:	83 c4 10             	add    $0x10,%esp
  80061c:	eb 08                	jmp    800626 <vprintfmt+0x278>
  80061e:	89 df                	mov    %ebx,%edi
  800620:	8b 75 08             	mov    0x8(%ebp),%esi
  800623:	8b 5d 0c             	mov    0xc(%ebp),%ebx
  800626:	85 ff                	test   %edi,%edi
  800628:	7f e4                	jg     80060e <vprintfmt+0x260>
		width = -1;
		precision = -1;
		lflag = 0;
		altflag = 0;
	reswitch:
		switch (ch = *(unsigned char *) fmt++) {
  80062a:	8b 7d e4             	mov    -0x1c(%ebp),%edi
  80062d:	e9 a2 fd ff ff       	jmp    8003d4 <vprintfmt+0x26>
				putch(' ', putdat);
			break;

		// (signed) decimal
		case 'd':
			num = getint(&ap, lflag);
  800632:	8d 45 14             	lea    0x14(%ebp),%eax
  800635:	e8 08 fd ff ff       	call   800342 <getint>
  80063a:	89 45 d8             	mov    %eax,-0x28(%ebp)
  80063d:	89 55 dc             	mov    %edx,-0x24(%ebp)
			if ((long long) num < 0) {
				putch('-', putdat);
				num = -(long long) num;
			}
			base = 10;
  800640:	b9 0a 00 00 00       	mov    $0xa,%ecx
			break;

		// (signed) decimal
		case 'd':
			num = getint(&ap, lflag);
			if ((long long) num < 0) {
  800645:	83 7d dc 00          	cmpl   $0x0,-0x24(%ebp)
  800649:	79 74                	jns    8006bf <vprintfmt+0x311>
				putch('-', putdat);
  80064b:	83 ec 08             	sub    $0x8,%esp
  80064e:	53                   	push   %ebx
  80064f:	6a 2d                	push   $0x2d
  800651:	ff d6                	call   *%esi
				num = -(long long) num;
  800653:	8b 45 d8             	mov    -0x28(%ebp),%eax
  800656:	8b 55 dc             	mov    -0x24(%ebp),%edx
  800659:	f7 d8                	neg    %eax
  80065b:	83 d2 00             	adc    $0x0,%edx
  80065e:	f7 da                	neg    %edx
  800660:	83 c4 10             	add    $0x10,%esp
			}
			base = 10;
  800663:	b9 0a 00 00 00       	mov    $0xa,%ecx
  800668:	eb 55                	jmp    8006bf <vprintfmt+0x311>
			goto number;

		// unsigned decimal
		case 'u':
			num = getuint(&ap, lflag);
  80066a:	8d 45 14             	lea    0x14(%ebp),%eax
  80066d:	e8 96 fc ff ff       	call   800308 <getuint>
			base = 10;
  800672:	b9 0a 00 00 00       	mov    $0xa,%ecx
			goto number;
  800677:	eb 46                	jmp    8006bf <vprintfmt+0x311>

		// (unsigned) octal
		case 'o':
			num = getuint(&ap, lflag);
  800679:	8d 45 14             	lea    0x14(%ebp),%eax
  80067c:	e8 87 fc ff ff       	call   800308 <getuint>
			base = 8;
  800681:	b9 08 00 00 00       	mov    $0x8,%ecx
			goto number;
  800686:	eb 37                	jmp    8006bf <vprintfmt+0x311>

		// pointer
		case 'p':
			putch('0', putdat);
  800688:	83 ec 08             	sub    $0x8,%esp
  80068b:	53                   	push   %ebx
  80068c:	6a 30                	push   $0x30
  80068e:	ff d6                	call   *%esi
			putch('x', putdat);
  800690:	83 c4 08             	add    $0x8,%esp
  800693:	53                   	push   %ebx
  800694:	6a 78                	push   $0x78
  800696:	ff d6                	call   *%esi
			num = (unsigned long long)
				(uintptr_t) va_arg(ap, void *);
  800698:	8b 45 14             	mov    0x14(%ebp),%eax
  80069b:	8d 50 04             	lea    0x4(%eax),%edx
  80069e:	89 55 14             	mov    %edx,0x14(%ebp)

		// pointer
		case 'p':
			putch('0', putdat);
			putch('x', putdat);
			num = (unsigned long long)
  8006a1:	8b 00                	mov    (%eax),%eax
  8006a3:	ba 00 00 00 00       	mov    $0x0,%edx
				(uintptr_t) va_arg(ap, void *);
			base = 16;
			goto number;
  8006a8:	83 c4 10             	add    $0x10,%esp
		case 'p':
			putch('0', putdat);
			putch('x', putdat);
			num = (unsigned long long)
				(uintptr_t) va_arg(ap, void *);
			base = 16;
  8006ab:	b9 10 00 00 00       	mov    $0x10,%ecx
			goto number;
  8006b0:	eb 0d                	jmp    8006bf <vprintfmt+0x311>

		// (unsigned) hexadecimal
		case 'x':
			num = getuint(&ap, lflag);
  8006b2:	8d 45 14             	lea    0x14(%ebp),%eax
  8006b5:	e8 4e fc ff ff       	call   800308 <getuint>
			base = 16;
  8006ba:	b9 10 00 00 00       	mov    $0x10,%ecx
		number:
			printnum(putch, putdat, num, base, width, padc);
  8006bf:	83 ec 0c             	sub    $0xc,%esp
  8006c2:	0f be 7d d4          	movsbl -0x2c(%ebp),%edi
  8006c6:	57                   	push   %edi
  8006c7:	ff 75 e0             	pushl  -0x20(%ebp)
  8006ca:	51                   	push   %ecx
  8006cb:	52                   	push   %edx
  8006cc:	50                   	push   %eax
  8006cd:	89 da                	mov    %ebx,%edx
  8006cf:	89 f0                	mov    %esi,%eax
  8006d1:	e8 83 fb ff ff       	call   800259 <printnum>
			break;
  8006d6:	83 c4 20             	add    $0x20,%esp
  8006d9:	8b 7d e4             	mov    -0x1c(%ebp),%edi
  8006dc:	e9 f3 fc ff ff       	jmp    8003d4 <vprintfmt+0x26>

		// escaped '%' character
		case '%':
			putch(ch, putdat);
  8006e1:	83 ec 08             	sub    $0x8,%esp
  8006e4:	53                   	push   %ebx
  8006e5:	51                   	push   %ecx
  8006e6:	ff d6                	call   *%esi
			break;
  8006e8:	83 c4 10             	add    $0x10,%esp
		width = -1;
		precision = -1;
		lflag = 0;
		altflag = 0;
	reswitch:
		switch (ch = *(unsigned char *) fmt++) {
  8006eb:	8b 7d e4             	mov    -0x1c(%ebp),%edi
			break;

		// escaped '%' character
		case '%':
			putch(ch, putdat);
			break;
  8006ee:	e9 e1 fc ff ff       	jmp    8003d4 <vprintfmt+0x26>

		// unrecognized escape sequence - just print it literally
		default:
			putch('%', putdat);
  8006f3:	83 ec 08             	sub    $0x8,%esp
  8006f6:	53                   	push   %ebx
  8006f7:	6a 25                	push   $0x25
  8006f9:	ff d6                	call   *%esi
			for (fmt--; fmt[-1] != '%'; fmt--)
  8006fb:	83 c4 10             	add    $0x10,%esp
  8006fe:	eb 03                	jmp    800703 <vprintfmt+0x355>
  800700:	83 ef 01             	sub    $0x1,%edi
  800703:	80 7f ff 25          	cmpb   $0x25,-0x1(%edi)
  800707:	75 f7                	jne    800700 <vprintfmt+0x352>
  800709:	e9 c6 fc ff ff       	jmp    8003d4 <vprintfmt+0x26>
				/* do nothing */;
			break;
		}
	}
}
  80070e:	8d 65 f4             	lea    -0xc(%ebp),%esp
  800711:	5b                   	pop    %ebx
  800712:	5e                   	pop    %esi
  800713:	5f                   	pop    %edi
  800714:	5d                   	pop    %ebp
  800715:	c3                   	ret    

00800716 <vsnprintf>:
		*b->buf++ = ch;
}

int
vsnprintf(char *buf, int n, const char *fmt, va_list ap)
{
  800716:	55                   	push   %ebp
  800717:	89 e5                	mov    %esp,%ebp
  800719:	83 ec 18             	sub    $0x18,%esp
  80071c:	8b 45 08             	mov    0x8(%ebp),%eax
  80071f:	8b 55 0c             	mov    0xc(%ebp),%edx
	struct sprintbuf b = {buf, buf+n-1, 0};
  800722:	89 45 ec             	mov    %eax,-0x14(%ebp)
  800725:	8d 4c 10 ff          	lea    -0x1(%eax,%edx,1),%ecx
  800729:	89 4d f0             	mov    %ecx,-0x10(%ebp)
  80072c:	c7 45 f4 00 00 00 00 	movl   $0x0,-0xc(%ebp)

	if (buf == NULL || n < 1)
  800733:	85 c0                	test   %eax,%eax
  800735:	74 26                	je     80075d <vsnprintf+0x47>
  800737:	85 d2                	test   %edx,%edx
  800739:	7e 22                	jle    80075d <vsnprintf+0x47>
		return -E_INVAL;

	// print the string to the buffer
	vprintfmt((void*)sprintputch, &b, fmt, ap);
  80073b:	ff 75 14             	pushl  0x14(%ebp)
  80073e:	ff 75 10             	pushl  0x10(%ebp)
  800741:	8d 45 ec             	lea    -0x14(%ebp),%eax
  800744:	50                   	push   %eax
  800745:	68 74 03 80 00       	push   $0x800374
  80074a:	e8 5f fc ff ff       	call   8003ae <vprintfmt>

	// null terminate the buffer
	*b.buf = '\0';
  80074f:	8b 45 ec             	mov    -0x14(%ebp),%eax
  800752:	c6 00 00             	movb   $0x0,(%eax)

	return b.cnt;
  800755:	8b 45 f4             	mov    -0xc(%ebp),%eax
  800758:	83 c4 10             	add    $0x10,%esp
  80075b:	eb 05                	jmp    800762 <vsnprintf+0x4c>
vsnprintf(char *buf, int n, const char *fmt, va_list ap)
{
	struct sprintbuf b = {buf, buf+n-1, 0};

	if (buf == NULL || n < 1)
		return -E_INVAL;
  80075d:	b8 fd ff ff ff       	mov    $0xfffffffd,%eax

	// null terminate the buffer
	*b.buf = '\0';

	return b.cnt;
}
  800762:	c9                   	leave  
  800763:	c3                   	ret    

00800764 <snprintf>:

int
snprintf(char *buf, int n, const char *fmt, ...)
{
  800764:	55                   	push   %ebp
  800765:	89 e5                	mov    %esp,%ebp
  800767:	83 ec 08             	sub    $0x8,%esp
	va_list ap;
	int rc;

	va_start(ap, fmt);
  80076a:	8d 45 14             	lea    0x14(%ebp),%eax
	rc = vsnprintf(buf, n, fmt, ap);
  80076d:	50                   	push   %eax
  80076e:	ff 75 10             	pushl  0x10(%ebp)
  800771:	ff 75 0c             	pushl  0xc(%ebp)
  800774:	ff 75 08             	pushl  0x8(%ebp)
  800777:	e8 9a ff ff ff       	call   800716 <vsnprintf>
	va_end(ap);

	return rc;
}
  80077c:	c9                   	leave  
  80077d:	c3                   	ret    

0080077e <strlen>:
// Primespipe runs 3x faster this way.
#define ASM 1

int
strlen(const char *s)
{
  80077e:	55                   	push   %ebp
  80077f:	89 e5                	mov    %esp,%ebp
  800781:	8b 55 08             	mov    0x8(%ebp),%edx
	int n;

	for (n = 0; *s != '\0'; s++)
  800784:	b8 00 00 00 00       	mov    $0x0,%eax
  800789:	eb 03                	jmp    80078e <strlen+0x10>
		n++;
  80078b:	83 c0 01             	add    $0x1,%eax
int
strlen(const char *s)
{
	int n;

	for (n = 0; *s != '\0'; s++)
  80078e:	80 3c 02 00          	cmpb   $0x0,(%edx,%eax,1)
  800792:	75 f7                	jne    80078b <strlen+0xd>
		n++;
	return n;
}
  800794:	5d                   	pop    %ebp
  800795:	c3                   	ret    

00800796 <strnlen>:

int
strnlen(const char *s, size_t size)
{
  800796:	55                   	push   %ebp
  800797:	89 e5                	mov    %esp,%ebp
  800799:	8b 4d 08             	mov    0x8(%ebp),%ecx
  80079c:	8b 45 0c             	mov    0xc(%ebp),%eax
	int n;

	for (n = 0; size > 0 && *s != '\0'; s++, size--)
  80079f:	ba 00 00 00 00       	mov    $0x0,%edx
  8007a4:	eb 03                	jmp    8007a9 <strnlen+0x13>
		n++;
  8007a6:	83 c2 01             	add    $0x1,%edx
int
strnlen(const char *s, size_t size)
{
	int n;

	for (n = 0; size > 0 && *s != '\0'; s++, size--)
  8007a9:	39 c2                	cmp    %eax,%edx
  8007ab:	74 08                	je     8007b5 <strnlen+0x1f>
  8007ad:	80 3c 11 00          	cmpb   $0x0,(%ecx,%edx,1)
  8007b1:	75 f3                	jne    8007a6 <strnlen+0x10>
  8007b3:	89 d0                	mov    %edx,%eax
		n++;
	return n;
}
  8007b5:	5d                   	pop    %ebp
  8007b6:	c3                   	ret    

008007b7 <strcpy>:

char *
strcpy(char *dst, const char *src)
{
  8007b7:	55                   	push   %ebp
  8007b8:	89 e5                	mov    %esp,%ebp
  8007ba:	53                   	push   %ebx
  8007bb:	8b 45 08             	mov    0x8(%ebp),%eax
  8007be:	8b 4d 0c             	mov    0xc(%ebp),%ecx
	char *ret;

	ret = dst;
	while ((*dst++ = *src++) != '\0')
  8007c1:	89 c2                	mov    %eax,%edx
  8007c3:	83 c2 01             	add    $0x1,%edx
  8007c6:	83 c1 01             	add    $0x1,%ecx
  8007c9:	0f b6 59 ff          	movzbl -0x1(%ecx),%ebx
  8007cd:	88 5a ff             	mov    %bl,-0x1(%edx)
  8007d0:	84 db                	test   %bl,%bl
  8007d2:	75 ef                	jne    8007c3 <strcpy+0xc>
		/* do nothing */;
	return ret;
}
  8007d4:	5b                   	pop    %ebx
  8007d5:	5d                   	pop    %ebp
  8007d6:	c3                   	ret    

008007d7 <strcat>:

char *
strcat(char *dst, const char *src)
{
  8007d7:	55                   	push   %ebp
  8007d8:	89 e5                	mov    %esp,%ebp
  8007da:	53                   	push   %ebx
  8007db:	8b 5d 08             	mov    0x8(%ebp),%ebx
	int len = strlen(dst);
  8007de:	53                   	push   %ebx
  8007df:	e8 9a ff ff ff       	call   80077e <strlen>
  8007e4:	83 c4 04             	add    $0x4,%esp
	strcpy(dst + len, src);
  8007e7:	ff 75 0c             	pushl  0xc(%ebp)
  8007ea:	01 d8                	add    %ebx,%eax
  8007ec:	50                   	push   %eax
  8007ed:	e8 c5 ff ff ff       	call   8007b7 <strcpy>
	return dst;
}
  8007f2:	89 d8                	mov    %ebx,%eax
  8007f4:	8b 5d fc             	mov    -0x4(%ebp),%ebx
  8007f7:	c9                   	leave  
  8007f8:	c3                   	ret    

008007f9 <strncpy>:

char *
strncpy(char *dst, const char *src, size_t size) {
  8007f9:	55                   	push   %ebp
  8007fa:	89 e5                	mov    %esp,%ebp
  8007fc:	56                   	push   %esi
  8007fd:	53                   	push   %ebx
  8007fe:	8b 75 08             	mov    0x8(%ebp),%esi
  800801:	8b 4d 0c             	mov    0xc(%ebp),%ecx
  800804:	89 f3                	mov    %esi,%ebx
  800806:	03 5d 10             	add    0x10(%ebp),%ebx
	size_t i;
	char *ret;

	ret = dst;
	for (i = 0; i < size; i++) {
  800809:	89 f2                	mov    %esi,%edx
  80080b:	eb 0f                	jmp    80081c <strncpy+0x23>
		*dst++ = *src;
  80080d:	83 c2 01             	add    $0x1,%edx
  800810:	0f b6 01             	movzbl (%ecx),%eax
  800813:	88 42 ff             	mov    %al,-0x1(%edx)
		// If strlen(src) < size, null-pad 'dst' out to 'size' chars
		if (*src != '\0')
			src++;
  800816:	80 39 01             	cmpb   $0x1,(%ecx)
  800819:	83 d9 ff             	sbb    $0xffffffff,%ecx
strncpy(char *dst, const char *src, size_t size) {
	size_t i;
	char *ret;

	ret = dst;
	for (i = 0; i < size; i++) {
  80081c:	39 da                	cmp    %ebx,%edx
  80081e:	75 ed                	jne    80080d <strncpy+0x14>
		// If strlen(src) < size, null-pad 'dst' out to 'size' chars
		if (*src != '\0')
			src++;
	}
	return ret;
}
  800820:	89 f0                	mov    %esi,%eax
  800822:	5b                   	pop    %ebx
  800823:	5e                   	pop    %esi
  800824:	5d                   	pop    %ebp
  800825:	c3                   	ret    

00800826 <strlcpy>:

size_t
strlcpy(char *dst, const char *src, size_t size)
{
  800826:	55                   	push   %ebp
  800827:	89 e5                	mov    %esp,%ebp
  800829:	56                   	push   %esi
  80082a:	53                   	push   %ebx
  80082b:	8b 75 08             	mov    0x8(%ebp),%esi
  80082e:	8b 4d 0c             	mov    0xc(%ebp),%ecx
  800831:	8b 55 10             	mov    0x10(%ebp),%edx
  800834:	89 f0                	mov    %esi,%eax
	char *dst_in;

	dst_in = dst;
	if (size > 0) {
  800836:	85 d2                	test   %edx,%edx
  800838:	74 21                	je     80085b <strlcpy+0x35>
  80083a:	8d 44 16 ff          	lea    -0x1(%esi,%edx,1),%eax
  80083e:	89 f2                	mov    %esi,%edx
  800840:	eb 09                	jmp    80084b <strlcpy+0x25>
		while (--size > 0 && *src != '\0')
			*dst++ = *src++;
  800842:	83 c2 01             	add    $0x1,%edx
  800845:	83 c1 01             	add    $0x1,%ecx
  800848:	88 5a ff             	mov    %bl,-0x1(%edx)
{
	char *dst_in;

	dst_in = dst;
	if (size > 0) {
		while (--size > 0 && *src != '\0')
  80084b:	39 c2                	cmp    %eax,%edx
  80084d:	74 09                	je     800858 <strlcpy+0x32>
  80084f:	0f b6 19             	movzbl (%ecx),%ebx
  800852:	84 db                	test   %bl,%bl
  800854:	75 ec                	jne    800842 <strlcpy+0x1c>
  800856:	89 d0                	mov    %edx,%eax
			*dst++ = *src++;
		*dst = '\0';
  800858:	c6 00 00             	movb   $0x0,(%eax)
	}
	return dst - dst_in;
  80085b:	29 f0                	sub    %esi,%eax
}
  80085d:	5b                   	pop    %ebx
  80085e:	5e                   	pop    %esi
  80085f:	5d                   	pop    %ebp
  800860:	c3                   	ret    

00800861 <strcmp>:

int
strcmp(const char *p, const char *q)
{
  800861:	55                   	push   %ebp
  800862:	89 e5                	mov    %esp,%ebp
  800864:	8b 4d 08             	mov    0x8(%ebp),%ecx
  800867:	8b 55 0c             	mov    0xc(%ebp),%edx
	while (*p && *p == *q)
  80086a:	eb 06                	jmp    800872 <strcmp+0x11>
		p++, q++;
  80086c:	83 c1 01             	add    $0x1,%ecx
  80086f:	83 c2 01             	add    $0x1,%edx
}

int
strcmp(const char *p, const char *q)
{
	while (*p && *p == *q)
  800872:	0f b6 01             	movzbl (%ecx),%eax
  800875:	84 c0                	test   %al,%al
  800877:	74 04                	je     80087d <strcmp+0x1c>
  800879:	3a 02                	cmp    (%edx),%al
  80087b:	74 ef                	je     80086c <strcmp+0xb>
		p++, q++;
	return (int) ((unsigned char) *p - (unsigned char) *q);
  80087d:	0f b6 c0             	movzbl %al,%eax
  800880:	0f b6 12             	movzbl (%edx),%edx
  800883:	29 d0                	sub    %edx,%eax
}
  800885:	5d                   	pop    %ebp
  800886:	c3                   	ret    

00800887 <strncmp>:

int
strncmp(const char *p, const char *q, size_t n)
{
  800887:	55                   	push   %ebp
  800888:	89 e5                	mov    %esp,%ebp
  80088a:	53                   	push   %ebx
  80088b:	8b 45 08             	mov    0x8(%ebp),%eax
  80088e:	8b 55 0c             	mov    0xc(%ebp),%edx
  800891:	89 c3                	mov    %eax,%ebx
  800893:	03 5d 10             	add    0x10(%ebp),%ebx
	while (n > 0 && *p && *p == *q)
  800896:	eb 06                	jmp    80089e <strncmp+0x17>
		n--, p++, q++;
  800898:	83 c0 01             	add    $0x1,%eax
  80089b:	83 c2 01             	add    $0x1,%edx
}

int
strncmp(const char *p, const char *q, size_t n)
{
	while (n > 0 && *p && *p == *q)
  80089e:	39 d8                	cmp    %ebx,%eax
  8008a0:	74 15                	je     8008b7 <strncmp+0x30>
  8008a2:	0f b6 08             	movzbl (%eax),%ecx
  8008a5:	84 c9                	test   %cl,%cl
  8008a7:	74 04                	je     8008ad <strncmp+0x26>
  8008a9:	3a 0a                	cmp    (%edx),%cl
  8008ab:	74 eb                	je     800898 <strncmp+0x11>
		n--, p++, q++;
	if (n == 0)
		return 0;
	else
		return (int) ((unsigned char) *p - (unsigned char) *q);
  8008ad:	0f b6 00             	movzbl (%eax),%eax
  8008b0:	0f b6 12             	movzbl (%edx),%edx
  8008b3:	29 d0                	sub    %edx,%eax
  8008b5:	eb 05                	jmp    8008bc <strncmp+0x35>
strncmp(const char *p, const char *q, size_t n)
{
	while (n > 0 && *p && *p == *q)
		n--, p++, q++;
	if (n == 0)
		return 0;
  8008b7:	b8 00 00 00 00       	mov    $0x0,%eax
	else
		return (int) ((unsigned char) *p - (unsigned char) *q);
}
  8008bc:	5b                   	pop    %ebx
  8008bd:	5d                   	pop    %ebp
  8008be:	c3                   	ret    

008008bf <strchr>:

// Return a pointer to the first occurrence of 'c' in 's',
// or a null pointer if the string has no 'c'.
char *
strchr(const char *s, char c)
{
  8008bf:	55                   	push   %ebp
  8008c0:	89 e5                	mov    %esp,%ebp
  8008c2:	8b 45 08             	mov    0x8(%ebp),%eax
  8008c5:	0f b6 4d 0c          	movzbl 0xc(%ebp),%ecx
	for (; *s; s++)
  8008c9:	eb 07                	jmp    8008d2 <strchr+0x13>
		if (*s == c)
  8008cb:	38 ca                	cmp    %cl,%dl
  8008cd:	74 0f                	je     8008de <strchr+0x1f>
// Return a pointer to the first occurrence of 'c' in 's',
// or a null pointer if the string has no 'c'.
char *
strchr(const char *s, char c)
{
	for (; *s; s++)
  8008cf:	83 c0 01             	add    $0x1,%eax
  8008d2:	0f b6 10             	movzbl (%eax),%edx
  8008d5:	84 d2                	test   %dl,%dl
  8008d7:	75 f2                	jne    8008cb <strchr+0xc>
		if (*s == c)
			return (char *) s;
	return 0;
  8008d9:	b8 00 00 00 00       	mov    $0x0,%eax
}
  8008de:	5d                   	pop    %ebp
  8008df:	c3                   	ret    

008008e0 <strfind>:

// Return a pointer to the first occurrence of 'c' in 's',
// or a pointer to the string-ending null character if the string has no 'c'.
char *
strfind(const char *s, char c)
{
  8008e0:	55                   	push   %ebp
  8008e1:	89 e5                	mov    %esp,%ebp
  8008e3:	8b 45 08             	mov    0x8(%ebp),%eax
  8008e6:	0f b6 4d 0c          	movzbl 0xc(%ebp),%ecx
	for (; *s; s++)
  8008ea:	eb 03                	jmp    8008ef <strfind+0xf>
  8008ec:	83 c0 01             	add    $0x1,%eax
  8008ef:	0f b6 10             	movzbl (%eax),%edx
		if (*s == c)
  8008f2:	38 ca                	cmp    %cl,%dl
  8008f4:	74 04                	je     8008fa <strfind+0x1a>
  8008f6:	84 d2                	test   %dl,%dl
  8008f8:	75 f2                	jne    8008ec <strfind+0xc>
			break;
	return (char *) s;
}
  8008fa:	5d                   	pop    %ebp
  8008fb:	c3                   	ret    

008008fc <memset>:

#if ASM
void *
memset(void *v, int c, size_t n)
{
  8008fc:	55                   	push   %ebp
  8008fd:	89 e5                	mov    %esp,%ebp
  8008ff:	57                   	push   %edi
  800900:	56                   	push   %esi
  800901:	53                   	push   %ebx
  800902:	8b 55 08             	mov    0x8(%ebp),%edx
  800905:	8b 4d 10             	mov    0x10(%ebp),%ecx
	char *p = v;

	if (n == 0)
  800908:	85 c9                	test   %ecx,%ecx
  80090a:	74 37                	je     800943 <memset+0x47>
		return v;
	if ((int)v%4 == 0 && n%4 == 0) {
  80090c:	f6 c2 03             	test   $0x3,%dl
  80090f:	75 2a                	jne    80093b <memset+0x3f>
  800911:	f6 c1 03             	test   $0x3,%cl
  800914:	75 25                	jne    80093b <memset+0x3f>
		c &= 0xFF;
  800916:	0f b6 5d 0c          	movzbl 0xc(%ebp),%ebx
		c = (c<<24)|(c<<16)|(c<<8)|c;
  80091a:	89 df                	mov    %ebx,%edi
  80091c:	c1 e7 08             	shl    $0x8,%edi
  80091f:	89 de                	mov    %ebx,%esi
  800921:	c1 e6 18             	shl    $0x18,%esi
  800924:	89 d8                	mov    %ebx,%eax
  800926:	c1 e0 10             	shl    $0x10,%eax
  800929:	09 f0                	or     %esi,%eax
  80092b:	09 c3                	or     %eax,%ebx
		asm volatile("cld; rep stosl\n"
			: "=D" (p), "=c" (n)
			: "D" (p), "a" (c), "c" (n/4)
  80092d:	c1 e9 02             	shr    $0x2,%ecx
	if (n == 0)
		return v;
	if ((int)v%4 == 0 && n%4 == 0) {
		c &= 0xFF;
		c = (c<<24)|(c<<16)|(c<<8)|c;
		asm volatile("cld; rep stosl\n"
  800930:	89 f8                	mov    %edi,%eax
  800932:	09 d8                	or     %ebx,%eax
  800934:	89 d7                	mov    %edx,%edi
  800936:	fc                   	cld    
  800937:	f3 ab                	rep stos %eax,%es:(%edi)
  800939:	eb 08                	jmp    800943 <memset+0x47>
			: "=D" (p), "=c" (n)
			: "D" (p), "a" (c), "c" (n/4)
			: "cc", "memory");
	} else
		asm volatile("cld; rep stosb\n"
  80093b:	89 d7                	mov    %edx,%edi
  80093d:	8b 45 0c             	mov    0xc(%ebp),%eax
  800940:	fc                   	cld    
  800941:	f3 aa                	rep stos %al,%es:(%edi)
			: "=D" (p), "=c" (n)
			: "0" (p), "a" (c), "1" (n)
			: "cc", "memory");
	return v;
}
  800943:	89 d0                	mov    %edx,%eax
  800945:	5b                   	pop    %ebx
  800946:	5e                   	pop    %esi
  800947:	5f                   	pop    %edi
  800948:	5d                   	pop    %ebp
  800949:	c3                   	ret    

0080094a <memmove>:

void *
memmove(void *dst, const void *src, size_t n)
{
  80094a:	55                   	push   %ebp
  80094b:	89 e5                	mov    %esp,%ebp
  80094d:	57                   	push   %edi
  80094e:	56                   	push   %esi
  80094f:	8b 45 08             	mov    0x8(%ebp),%eax
  800952:	8b 75 0c             	mov    0xc(%ebp),%esi
  800955:	8b 4d 10             	mov    0x10(%ebp),%ecx
	const char *s;
	char *d;

	s = src;
	d = dst;
	if (s < d && s + n > d) {
  800958:	39 c6                	cmp    %eax,%esi
  80095a:	73 35                	jae    800991 <memmove+0x47>
  80095c:	8d 14 0e             	lea    (%esi,%ecx,1),%edx
  80095f:	39 d0                	cmp    %edx,%eax
  800961:	73 2e                	jae    800991 <memmove+0x47>
		s += n;
		d += n;
  800963:	8d 3c 08             	lea    (%eax,%ecx,1),%edi
		if ((int)s%4 == 0 && (int)d%4 == 0 && n%4 == 0)
  800966:	89 d6                	mov    %edx,%esi
  800968:	09 fe                	or     %edi,%esi
  80096a:	f7 c6 03 00 00 00    	test   $0x3,%esi
  800970:	75 13                	jne    800985 <memmove+0x3b>
  800972:	f6 c1 03             	test   $0x3,%cl
  800975:	75 0e                	jne    800985 <memmove+0x3b>
			asm volatile("std; rep movsl\n"
  800977:	83 ef 04             	sub    $0x4,%edi
  80097a:	8d 72 fc             	lea    -0x4(%edx),%esi
  80097d:	c1 e9 02             	shr    $0x2,%ecx
  800980:	fd                   	std    
  800981:	f3 a5                	rep movsl %ds:(%esi),%es:(%edi)
  800983:	eb 09                	jmp    80098e <memmove+0x44>
				:: "D" (d-4), "S" (s-4), "c" (n/4) : "cc", "memory");
		else
			asm volatile("std; rep movsb\n"
  800985:	83 ef 01             	sub    $0x1,%edi
  800988:	8d 72 ff             	lea    -0x1(%edx),%esi
  80098b:	fd                   	std    
  80098c:	f3 a4                	rep movsb %ds:(%esi),%es:(%edi)
				:: "D" (d-1), "S" (s-1), "c" (n) : "cc", "memory");
		// Some versions of GCC rely on DF being clear
		asm volatile("cld" ::: "cc");
  80098e:	fc                   	cld    
  80098f:	eb 1d                	jmp    8009ae <memmove+0x64>
	} else {
		if ((int)s%4 == 0 && (int)d%4 == 0 && n%4 == 0)
  800991:	89 f2                	mov    %esi,%edx
  800993:	09 c2                	or     %eax,%edx
  800995:	f6 c2 03             	test   $0x3,%dl
  800998:	75 0f                	jne    8009a9 <memmove+0x5f>
  80099a:	f6 c1 03             	test   $0x3,%cl
  80099d:	75 0a                	jne    8009a9 <memmove+0x5f>
			asm volatile("cld; rep movsl\n"
  80099f:	c1 e9 02             	shr    $0x2,%ecx
  8009a2:	89 c7                	mov    %eax,%edi
  8009a4:	fc                   	cld    
  8009a5:	f3 a5                	rep movsl %ds:(%esi),%es:(%edi)
  8009a7:	eb 05                	jmp    8009ae <memmove+0x64>
				:: "D" (d), "S" (s), "c" (n/4) : "cc", "memory");
		else
			asm volatile("cld; rep movsb\n"
  8009a9:	89 c7                	mov    %eax,%edi
  8009ab:	fc                   	cld    
  8009ac:	f3 a4                	rep movsb %ds:(%esi),%es:(%edi)
				:: "D" (d), "S" (s), "c" (n) : "cc", "memory");
	}
	return dst;
}
  8009ae:	5e                   	pop    %esi
  8009af:	5f                   	pop    %edi
  8009b0:	5d                   	pop    %ebp
  8009b1:	c3                   	ret    

008009b2 <memcpy>:
}
#endif

void *
memcpy(void *dst, const void *src, size_t n)
{
  8009b2:	55                   	push   %ebp
  8009b3:	89 e5                	mov    %esp,%ebp
	return memmove(dst, src, n);
  8009b5:	ff 75 10             	pushl  0x10(%ebp)
  8009b8:	ff 75 0c             	pushl  0xc(%ebp)
  8009bb:	ff 75 08             	pushl  0x8(%ebp)
  8009be:	e8 87 ff ff ff       	call   80094a <memmove>
}
  8009c3:	c9                   	leave  
  8009c4:	c3                   	ret    

008009c5 <memcmp>:

int
memcmp(const void *v1, const void *v2, size_t n)
{
  8009c5:	55                   	push   %ebp
  8009c6:	89 e5                	mov    %esp,%ebp
  8009c8:	56                   	push   %esi
  8009c9:	53                   	push   %ebx
  8009ca:	8b 45 08             	mov    0x8(%ebp),%eax
  8009cd:	8b 55 0c             	mov    0xc(%ebp),%edx
  8009d0:	89 c6                	mov    %eax,%esi
  8009d2:	03 75 10             	add    0x10(%ebp),%esi
	const uint8_t *s1 = (const uint8_t *) v1;
	const uint8_t *s2 = (const uint8_t *) v2;

	while (n-- > 0) {
  8009d5:	eb 1a                	jmp    8009f1 <memcmp+0x2c>
		if (*s1 != *s2)
  8009d7:	0f b6 08             	movzbl (%eax),%ecx
  8009da:	0f b6 1a             	movzbl (%edx),%ebx
  8009dd:	38 d9                	cmp    %bl,%cl
  8009df:	74 0a                	je     8009eb <memcmp+0x26>
			return (int) *s1 - (int) *s2;
  8009e1:	0f b6 c1             	movzbl %cl,%eax
  8009e4:	0f b6 db             	movzbl %bl,%ebx
  8009e7:	29 d8                	sub    %ebx,%eax
  8009e9:	eb 0f                	jmp    8009fa <memcmp+0x35>
		s1++, s2++;
  8009eb:	83 c0 01             	add    $0x1,%eax
  8009ee:	83 c2 01             	add    $0x1,%edx
memcmp(const void *v1, const void *v2, size_t n)
{
	const uint8_t *s1 = (const uint8_t *) v1;
	const uint8_t *s2 = (const uint8_t *) v2;

	while (n-- > 0) {
  8009f1:	39 f0                	cmp    %esi,%eax
  8009f3:	75 e2                	jne    8009d7 <memcmp+0x12>
		if (*s1 != *s2)
			return (int) *s1 - (int) *s2;
		s1++, s2++;
	}

	return 0;
  8009f5:	b8 00 00 00 00       	mov    $0x0,%eax
}
  8009fa:	5b                   	pop    %ebx
  8009fb:	5e                   	pop    %esi
  8009fc:	5d                   	pop    %ebp
  8009fd:	c3                   	ret    

008009fe <memfind>:

void *
memfind(const void *s, int c, size_t n)
{
  8009fe:	55                   	push   %ebp
  8009ff:	89 e5                	mov    %esp,%ebp
  800a01:	8b 45 08             	mov    0x8(%ebp),%eax
  800a04:	8b 4d 0c             	mov    0xc(%ebp),%ecx
	const void *ends = (const char *) s + n;
  800a07:	89 c2                	mov    %eax,%edx
  800a09:	03 55 10             	add    0x10(%ebp),%edx
	for (; s < ends; s++)
  800a0c:	eb 07                	jmp    800a15 <memfind+0x17>
		if (*(const unsigned char *) s == (unsigned char) c)
  800a0e:	38 08                	cmp    %cl,(%eax)
  800a10:	74 07                	je     800a19 <memfind+0x1b>

void *
memfind(const void *s, int c, size_t n)
{
	const void *ends = (const char *) s + n;
	for (; s < ends; s++)
  800a12:	83 c0 01             	add    $0x1,%eax
  800a15:	39 d0                	cmp    %edx,%eax
  800a17:	72 f5                	jb     800a0e <memfind+0x10>
		if (*(const unsigned char *) s == (unsigned char) c)
			break;
	return (void *) s;
}
  800a19:	5d                   	pop    %ebp
  800a1a:	c3                   	ret    

00800a1b <strtol>:

long
strtol(const char *s, char **endptr, int base)
{
  800a1b:	55                   	push   %ebp
  800a1c:	89 e5                	mov    %esp,%ebp
  800a1e:	57                   	push   %edi
  800a1f:	56                   	push   %esi
  800a20:	53                   	push   %ebx
  800a21:	8b 4d 08             	mov    0x8(%ebp),%ecx
  800a24:	8b 5d 10             	mov    0x10(%ebp),%ebx
	int neg = 0;
	long val = 0;

	// gobble initial whitespace
	while (*s == ' ' || *s == '\t')
  800a27:	eb 03                	jmp    800a2c <strtol+0x11>
		s++;
  800a29:	83 c1 01             	add    $0x1,%ecx
{
	int neg = 0;
	long val = 0;

	// gobble initial whitespace
	while (*s == ' ' || *s == '\t')
  800a2c:	0f b6 01             	movzbl (%ecx),%eax
  800a2f:	3c 20                	cmp    $0x20,%al
  800a31:	74 f6                	je     800a29 <strtol+0xe>
  800a33:	3c 09                	cmp    $0x9,%al
  800a35:	74 f2                	je     800a29 <strtol+0xe>
		s++;

	// plus/minus sign
	if (*s == '+')
  800a37:	3c 2b                	cmp    $0x2b,%al
  800a39:	75 0a                	jne    800a45 <strtol+0x2a>
		s++;
  800a3b:	83 c1 01             	add    $0x1,%ecx
}

long
strtol(const char *s, char **endptr, int base)
{
	int neg = 0;
  800a3e:	bf 00 00 00 00       	mov    $0x0,%edi
  800a43:	eb 11                	jmp    800a56 <strtol+0x3b>
  800a45:	bf 00 00 00 00       	mov    $0x0,%edi
		s++;

	// plus/minus sign
	if (*s == '+')
		s++;
	else if (*s == '-')
  800a4a:	3c 2d                	cmp    $0x2d,%al
  800a4c:	75 08                	jne    800a56 <strtol+0x3b>
		s++, neg = 1;
  800a4e:	83 c1 01             	add    $0x1,%ecx
  800a51:	bf 01 00 00 00       	mov    $0x1,%edi

	// hex or octal base prefix
	if ((base == 0 || base == 16) && (s[0] == '0' && s[1] == 'x'))
  800a56:	f7 c3 ef ff ff ff    	test   $0xffffffef,%ebx
  800a5c:	75 15                	jne    800a73 <strtol+0x58>
  800a5e:	80 39 30             	cmpb   $0x30,(%ecx)
  800a61:	75 10                	jne    800a73 <strtol+0x58>
  800a63:	80 79 01 78          	cmpb   $0x78,0x1(%ecx)
  800a67:	75 7c                	jne    800ae5 <strtol+0xca>
		s += 2, base = 16;
  800a69:	83 c1 02             	add    $0x2,%ecx
  800a6c:	bb 10 00 00 00       	mov    $0x10,%ebx
  800a71:	eb 16                	jmp    800a89 <strtol+0x6e>
	else if (base == 0 && s[0] == '0')
  800a73:	85 db                	test   %ebx,%ebx
  800a75:	75 12                	jne    800a89 <strtol+0x6e>
		s++, base = 8;
	else if (base == 0)
		base = 10;
  800a77:	bb 0a 00 00 00       	mov    $0xa,%ebx
		s++, neg = 1;

	// hex or octal base prefix
	if ((base == 0 || base == 16) && (s[0] == '0' && s[1] == 'x'))
		s += 2, base = 16;
	else if (base == 0 && s[0] == '0')
  800a7c:	80 39 30             	cmpb   $0x30,(%ecx)
  800a7f:	75 08                	jne    800a89 <strtol+0x6e>
		s++, base = 8;
  800a81:	83 c1 01             	add    $0x1,%ecx
  800a84:	bb 08 00 00 00       	mov    $0x8,%ebx
	else if (base == 0)
		base = 10;
  800a89:	b8 00 00 00 00       	mov    $0x0,%eax
  800a8e:	89 5d 10             	mov    %ebx,0x10(%ebp)

	// digits
	while (1) {
		int dig;

		if (*s >= '0' && *s <= '9')
  800a91:	0f b6 11             	movzbl (%ecx),%edx
  800a94:	8d 72 d0             	lea    -0x30(%edx),%esi
  800a97:	89 f3                	mov    %esi,%ebx
  800a99:	80 fb 09             	cmp    $0x9,%bl
  800a9c:	77 08                	ja     800aa6 <strtol+0x8b>
			dig = *s - '0';
  800a9e:	0f be d2             	movsbl %dl,%edx
  800aa1:	83 ea 30             	sub    $0x30,%edx
  800aa4:	eb 22                	jmp    800ac8 <strtol+0xad>
		else if (*s >= 'a' && *s <= 'z')
  800aa6:	8d 72 9f             	lea    -0x61(%edx),%esi
  800aa9:	89 f3                	mov    %esi,%ebx
  800aab:	80 fb 19             	cmp    $0x19,%bl
  800aae:	77 08                	ja     800ab8 <strtol+0x9d>
			dig = *s - 'a' + 10;
  800ab0:	0f be d2             	movsbl %dl,%edx
  800ab3:	83 ea 57             	sub    $0x57,%edx
  800ab6:	eb 10                	jmp    800ac8 <strtol+0xad>
		else if (*s >= 'A' && *s <= 'Z')
  800ab8:	8d 72 bf             	lea    -0x41(%edx),%esi
  800abb:	89 f3                	mov    %esi,%ebx
  800abd:	80 fb 19             	cmp    $0x19,%bl
  800ac0:	77 16                	ja     800ad8 <strtol+0xbd>
			dig = *s - 'A' + 10;
  800ac2:	0f be d2             	movsbl %dl,%edx
  800ac5:	83 ea 37             	sub    $0x37,%edx
		else
			break;
		if (dig >= base)
  800ac8:	3b 55 10             	cmp    0x10(%ebp),%edx
  800acb:	7d 0b                	jge    800ad8 <strtol+0xbd>
			break;
		s++, val = (val * base) + dig;
  800acd:	83 c1 01             	add    $0x1,%ecx
  800ad0:	0f af 45 10          	imul   0x10(%ebp),%eax
  800ad4:	01 d0                	add    %edx,%eax
		// we don't properly detect overflow!
	}
  800ad6:	eb b9                	jmp    800a91 <strtol+0x76>

	if (endptr)
  800ad8:	83 7d 0c 00          	cmpl   $0x0,0xc(%ebp)
  800adc:	74 0d                	je     800aeb <strtol+0xd0>
		*endptr = (char *) s;
  800ade:	8b 75 0c             	mov    0xc(%ebp),%esi
  800ae1:	89 0e                	mov    %ecx,(%esi)
  800ae3:	eb 06                	jmp    800aeb <strtol+0xd0>
		s++, neg = 1;

	// hex or octal base prefix
	if ((base == 0 || base == 16) && (s[0] == '0' && s[1] == 'x'))
		s += 2, base = 16;
	else if (base == 0 && s[0] == '0')
  800ae5:	85 db                	test   %ebx,%ebx
  800ae7:	74 98                	je     800a81 <strtol+0x66>
  800ae9:	eb 9e                	jmp    800a89 <strtol+0x6e>
		// we don't properly detect overflow!
	}

	if (endptr)
		*endptr = (char *) s;
	return (neg ? -val : val);
  800aeb:	89 c2                	mov    %eax,%edx
  800aed:	f7 da                	neg    %edx
  800aef:	85 ff                	test   %edi,%edi
  800af1:	0f 45 c2             	cmovne %edx,%eax
}
  800af4:	5b                   	pop    %ebx
  800af5:	5e                   	pop    %esi
  800af6:	5f                   	pop    %edi
  800af7:	5d                   	pop    %ebp
  800af8:	c3                   	ret    
  800af9:	66 90                	xchg   %ax,%ax
  800afb:	66 90                	xchg   %ax,%ax
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
