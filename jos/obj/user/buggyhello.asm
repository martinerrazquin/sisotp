
obj/user/buggyhello:     file format elf32-i386


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
  80002c:	e8 16 00 00 00       	call   800047 <libmain>
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
	sys_cputs((char*)1, 1);
  800039:	6a 01                	push   $0x1
  80003b:	6a 01                	push   $0x1
  80003d:	e8 97 00 00 00       	call   8000d9 <sys_cputs>
}
  800042:	83 c4 10             	add    $0x10,%esp
  800045:	c9                   	leave  
  800046:	c3                   	ret    

00800047 <libmain>:
const volatile struct Env *thisenv;
const char *binaryname = "<unknown>";

void
libmain(int argc, char **argv)
{
  800047:	55                   	push   %ebp
  800048:	89 e5                	mov    %esp,%ebp
  80004a:	83 ec 08             	sub    $0x8,%esp
  80004d:	8b 45 08             	mov    0x8(%ebp),%eax
  800050:	8b 55 0c             	mov    0xc(%ebp),%edx
	// set thisenv to point at our Env structure in envs[].
	// LAB 3: Your code here.
	thisenv = 0;
  800053:	c7 05 04 10 80 00 00 	movl   $0x0,0x801004
  80005a:	00 00 00 

	// save the name of the program so that panic() can use it
	if (argc > 0)
  80005d:	85 c0                	test   %eax,%eax
  80005f:	7e 08                	jle    800069 <libmain+0x22>
		binaryname = argv[0];
  800061:	8b 0a                	mov    (%edx),%ecx
  800063:	89 0d 00 10 80 00    	mov    %ecx,0x801000

	// call user main routine
	umain(argc, argv);
  800069:	83 ec 08             	sub    $0x8,%esp
  80006c:	52                   	push   %edx
  80006d:	50                   	push   %eax
  80006e:	e8 c0 ff ff ff       	call   800033 <umain>

	// exit gracefully
	exit();
  800073:	e8 05 00 00 00       	call   80007d <exit>
}
  800078:	83 c4 10             	add    $0x10,%esp
  80007b:	c9                   	leave  
  80007c:	c3                   	ret    

0080007d <exit>:

#include <inc/lib.h>

void
exit(void)
{
  80007d:	55                   	push   %ebp
  80007e:	89 e5                	mov    %esp,%ebp
  800080:	83 ec 14             	sub    $0x14,%esp
	sys_env_destroy(0);
  800083:	6a 00                	push   $0x0
  800085:	e8 99 00 00 00       	call   800123 <sys_env_destroy>
}
  80008a:	83 c4 10             	add    $0x10,%esp
  80008d:	c9                   	leave  
  80008e:	c3                   	ret    

0080008f <syscall>:
#include <inc/syscall.h>
#include <inc/lib.h>

static inline int32_t
syscall(int num, int check, uint32_t a1, uint32_t a2, uint32_t a3, uint32_t a4, uint32_t a5)
{
  80008f:	55                   	push   %ebp
  800090:	89 e5                	mov    %esp,%ebp
  800092:	57                   	push   %edi
  800093:	56                   	push   %esi
  800094:	53                   	push   %ebx
  800095:	83 ec 1c             	sub    $0x1c,%esp
  800098:	89 45 e0             	mov    %eax,-0x20(%ebp)
  80009b:	89 55 e4             	mov    %edx,-0x1c(%ebp)
  80009e:	89 ca                	mov    %ecx,%edx
	//
	// The last clause tells the assembler that this can
	// potentially change the condition codes and arbitrary
	// memory locations.

	asm volatile("int %1\n"
  8000a0:	8b 4d 08             	mov    0x8(%ebp),%ecx
  8000a3:	8b 5d 0c             	mov    0xc(%ebp),%ebx
  8000a6:	8b 7d 10             	mov    0x10(%ebp),%edi
  8000a9:	8b 75 14             	mov    0x14(%ebp),%esi
  8000ac:	cd 30                	int    $0x30
		       "b" (a3),
		       "D" (a4),
		       "S" (a5)
		     : "cc", "memory");

	if(check && ret > 0)
  8000ae:	83 7d e4 00          	cmpl   $0x0,-0x1c(%ebp)
  8000b2:	74 1d                	je     8000d1 <syscall+0x42>
  8000b4:	85 c0                	test   %eax,%eax
  8000b6:	7e 19                	jle    8000d1 <syscall+0x42>
  8000b8:	8b 55 e0             	mov    -0x20(%ebp),%edx
		panic("syscall %d returned %d (> 0)", num, ret);
  8000bb:	83 ec 0c             	sub    $0xc,%esp
  8000be:	50                   	push   %eax
  8000bf:	52                   	push   %edx
  8000c0:	68 8e 0d 80 00       	push   $0x800d8e
  8000c5:	6a 23                	push   $0x23
  8000c7:	68 ab 0d 80 00       	push   $0x800dab
  8000cc:	e8 98 00 00 00       	call   800169 <_panic>

	return ret;
}
  8000d1:	8d 65 f4             	lea    -0xc(%ebp),%esp
  8000d4:	5b                   	pop    %ebx
  8000d5:	5e                   	pop    %esi
  8000d6:	5f                   	pop    %edi
  8000d7:	5d                   	pop    %ebp
  8000d8:	c3                   	ret    

008000d9 <sys_cputs>:

void
sys_cputs(const char *s, size_t len)
{
  8000d9:	55                   	push   %ebp
  8000da:	89 e5                	mov    %esp,%ebp
  8000dc:	83 ec 08             	sub    $0x8,%esp
	syscall(SYS_cputs, 0, (uint32_t)s, len, 0, 0, 0);
  8000df:	6a 00                	push   $0x0
  8000e1:	6a 00                	push   $0x0
  8000e3:	6a 00                	push   $0x0
  8000e5:	ff 75 0c             	pushl  0xc(%ebp)
  8000e8:	8b 4d 08             	mov    0x8(%ebp),%ecx
  8000eb:	ba 00 00 00 00       	mov    $0x0,%edx
  8000f0:	b8 00 00 00 00       	mov    $0x0,%eax
  8000f5:	e8 95 ff ff ff       	call   80008f <syscall>
}
  8000fa:	83 c4 10             	add    $0x10,%esp
  8000fd:	c9                   	leave  
  8000fe:	c3                   	ret    

008000ff <sys_cgetc>:

int
sys_cgetc(void)
{
  8000ff:	55                   	push   %ebp
  800100:	89 e5                	mov    %esp,%ebp
  800102:	83 ec 08             	sub    $0x8,%esp
	return syscall(SYS_cgetc, 0, 0, 0, 0, 0, 0);
  800105:	6a 00                	push   $0x0
  800107:	6a 00                	push   $0x0
  800109:	6a 00                	push   $0x0
  80010b:	6a 00                	push   $0x0
  80010d:	b9 00 00 00 00       	mov    $0x0,%ecx
  800112:	ba 00 00 00 00       	mov    $0x0,%edx
  800117:	b8 01 00 00 00       	mov    $0x1,%eax
  80011c:	e8 6e ff ff ff       	call   80008f <syscall>
}
  800121:	c9                   	leave  
  800122:	c3                   	ret    

00800123 <sys_env_destroy>:

int
sys_env_destroy(envid_t envid)
{
  800123:	55                   	push   %ebp
  800124:	89 e5                	mov    %esp,%ebp
  800126:	83 ec 08             	sub    $0x8,%esp
	return syscall(SYS_env_destroy, 1, envid, 0, 0, 0, 0);
  800129:	6a 00                	push   $0x0
  80012b:	6a 00                	push   $0x0
  80012d:	6a 00                	push   $0x0
  80012f:	6a 00                	push   $0x0
  800131:	8b 4d 08             	mov    0x8(%ebp),%ecx
  800134:	ba 01 00 00 00       	mov    $0x1,%edx
  800139:	b8 03 00 00 00       	mov    $0x3,%eax
  80013e:	e8 4c ff ff ff       	call   80008f <syscall>
}
  800143:	c9                   	leave  
  800144:	c3                   	ret    

00800145 <sys_getenvid>:

envid_t
sys_getenvid(void)
{
  800145:	55                   	push   %ebp
  800146:	89 e5                	mov    %esp,%ebp
  800148:	83 ec 08             	sub    $0x8,%esp
	 return syscall(SYS_getenvid, 0, 0, 0, 0, 0, 0);
  80014b:	6a 00                	push   $0x0
  80014d:	6a 00                	push   $0x0
  80014f:	6a 00                	push   $0x0
  800151:	6a 00                	push   $0x0
  800153:	b9 00 00 00 00       	mov    $0x0,%ecx
  800158:	ba 00 00 00 00       	mov    $0x0,%edx
  80015d:	b8 02 00 00 00       	mov    $0x2,%eax
  800162:	e8 28 ff ff ff       	call   80008f <syscall>
}
  800167:	c9                   	leave  
  800168:	c3                   	ret    

00800169 <_panic>:
 * It prints "panic: <message>", then causes a breakpoint exception,
 * which causes JOS to enter the JOS kernel monitor.
 */
void
_panic(const char *file, int line, const char *fmt, ...)
{
  800169:	55                   	push   %ebp
  80016a:	89 e5                	mov    %esp,%ebp
  80016c:	56                   	push   %esi
  80016d:	53                   	push   %ebx
	va_list ap;

	va_start(ap, fmt);
  80016e:	8d 5d 14             	lea    0x14(%ebp),%ebx

	// Print the panic message
	cprintf("[%08x] user panic in %s at %s:%d: ",
  800171:	8b 35 00 10 80 00    	mov    0x801000,%esi
  800177:	e8 c9 ff ff ff       	call   800145 <sys_getenvid>
  80017c:	83 ec 0c             	sub    $0xc,%esp
  80017f:	ff 75 0c             	pushl  0xc(%ebp)
  800182:	ff 75 08             	pushl  0x8(%ebp)
  800185:	56                   	push   %esi
  800186:	50                   	push   %eax
  800187:	68 bc 0d 80 00       	push   $0x800dbc
  80018c:	e8 b1 00 00 00       	call   800242 <cprintf>
		sys_getenvid(), binaryname, file, line);
	vcprintf(fmt, ap);
  800191:	83 c4 18             	add    $0x18,%esp
  800194:	53                   	push   %ebx
  800195:	ff 75 10             	pushl  0x10(%ebp)
  800198:	e8 54 00 00 00       	call   8001f1 <vcprintf>
	cprintf("\n");
  80019d:	c7 04 24 e0 0d 80 00 	movl   $0x800de0,(%esp)
  8001a4:	e8 99 00 00 00       	call   800242 <cprintf>
  8001a9:	83 c4 10             	add    $0x10,%esp

	// Cause a breakpoint exception
	while (1)
		asm volatile("int3");
  8001ac:	cc                   	int3   
  8001ad:	eb fd                	jmp    8001ac <_panic+0x43>

008001af <putch>:
};


static void
putch(int ch, struct printbuf *b)
{
  8001af:	55                   	push   %ebp
  8001b0:	89 e5                	mov    %esp,%ebp
  8001b2:	53                   	push   %ebx
  8001b3:	83 ec 04             	sub    $0x4,%esp
  8001b6:	8b 5d 0c             	mov    0xc(%ebp),%ebx
	b->buf[b->idx++] = ch;
  8001b9:	8b 13                	mov    (%ebx),%edx
  8001bb:	8d 42 01             	lea    0x1(%edx),%eax
  8001be:	89 03                	mov    %eax,(%ebx)
  8001c0:	8b 4d 08             	mov    0x8(%ebp),%ecx
  8001c3:	88 4c 13 08          	mov    %cl,0x8(%ebx,%edx,1)
	if (b->idx == 256-1) {
  8001c7:	3d ff 00 00 00       	cmp    $0xff,%eax
  8001cc:	75 1a                	jne    8001e8 <putch+0x39>
		sys_cputs(b->buf, b->idx);
  8001ce:	83 ec 08             	sub    $0x8,%esp
  8001d1:	68 ff 00 00 00       	push   $0xff
  8001d6:	8d 43 08             	lea    0x8(%ebx),%eax
  8001d9:	50                   	push   %eax
  8001da:	e8 fa fe ff ff       	call   8000d9 <sys_cputs>
		b->idx = 0;
  8001df:	c7 03 00 00 00 00    	movl   $0x0,(%ebx)
  8001e5:	83 c4 10             	add    $0x10,%esp
	}
	b->cnt++;
  8001e8:	83 43 04 01          	addl   $0x1,0x4(%ebx)
}
  8001ec:	8b 5d fc             	mov    -0x4(%ebp),%ebx
  8001ef:	c9                   	leave  
  8001f0:	c3                   	ret    

008001f1 <vcprintf>:

int
vcprintf(const char *fmt, va_list ap)
{
  8001f1:	55                   	push   %ebp
  8001f2:	89 e5                	mov    %esp,%ebp
  8001f4:	81 ec 18 01 00 00    	sub    $0x118,%esp
	struct printbuf b;

	b.idx = 0;
  8001fa:	c7 85 f0 fe ff ff 00 	movl   $0x0,-0x110(%ebp)
  800201:	00 00 00 
	b.cnt = 0;
  800204:	c7 85 f4 fe ff ff 00 	movl   $0x0,-0x10c(%ebp)
  80020b:	00 00 00 
	vprintfmt((void*)putch, &b, fmt, ap);
  80020e:	ff 75 0c             	pushl  0xc(%ebp)
  800211:	ff 75 08             	pushl  0x8(%ebp)
  800214:	8d 85 f0 fe ff ff    	lea    -0x110(%ebp),%eax
  80021a:	50                   	push   %eax
  80021b:	68 af 01 80 00       	push   $0x8001af
  800220:	e8 86 01 00 00       	call   8003ab <vprintfmt>
	sys_cputs(b.buf, b.idx);
  800225:	83 c4 08             	add    $0x8,%esp
  800228:	ff b5 f0 fe ff ff    	pushl  -0x110(%ebp)
  80022e:	8d 85 f8 fe ff ff    	lea    -0x108(%ebp),%eax
  800234:	50                   	push   %eax
  800235:	e8 9f fe ff ff       	call   8000d9 <sys_cputs>

	return b.cnt;
}
  80023a:	8b 85 f4 fe ff ff    	mov    -0x10c(%ebp),%eax
  800240:	c9                   	leave  
  800241:	c3                   	ret    

00800242 <cprintf>:

int
cprintf(const char *fmt, ...)
{
  800242:	55                   	push   %ebp
  800243:	89 e5                	mov    %esp,%ebp
  800245:	83 ec 10             	sub    $0x10,%esp
	va_list ap;
	int cnt;

	va_start(ap, fmt);
  800248:	8d 45 0c             	lea    0xc(%ebp),%eax
	cnt = vcprintf(fmt, ap);
  80024b:	50                   	push   %eax
  80024c:	ff 75 08             	pushl  0x8(%ebp)
  80024f:	e8 9d ff ff ff       	call   8001f1 <vcprintf>
	va_end(ap);

	return cnt;
}
  800254:	c9                   	leave  
  800255:	c3                   	ret    

00800256 <printnum>:
 * using specified putch function and associated pointer putdat.
 */
static void
printnum(void (*putch)(int, void*), void *putdat,
	 unsigned long long num, unsigned base, int width, int padc)
{
  800256:	55                   	push   %ebp
  800257:	89 e5                	mov    %esp,%ebp
  800259:	57                   	push   %edi
  80025a:	56                   	push   %esi
  80025b:	53                   	push   %ebx
  80025c:	83 ec 1c             	sub    $0x1c,%esp
  80025f:	89 c7                	mov    %eax,%edi
  800261:	89 d6                	mov    %edx,%esi
  800263:	8b 45 08             	mov    0x8(%ebp),%eax
  800266:	8b 55 0c             	mov    0xc(%ebp),%edx
  800269:	89 45 d8             	mov    %eax,-0x28(%ebp)
  80026c:	89 55 dc             	mov    %edx,-0x24(%ebp)
	// first recursively print all preceding (more significant) digits
	if (num >= base) {
  80026f:	8b 4d 10             	mov    0x10(%ebp),%ecx
  800272:	bb 00 00 00 00       	mov    $0x0,%ebx
  800277:	89 4d e0             	mov    %ecx,-0x20(%ebp)
  80027a:	89 5d e4             	mov    %ebx,-0x1c(%ebp)
  80027d:	39 d3                	cmp    %edx,%ebx
  80027f:	72 05                	jb     800286 <printnum+0x30>
  800281:	39 45 10             	cmp    %eax,0x10(%ebp)
  800284:	77 45                	ja     8002cb <printnum+0x75>
		printnum(putch, putdat, num / base, base, width - 1, padc);
  800286:	83 ec 0c             	sub    $0xc,%esp
  800289:	ff 75 18             	pushl  0x18(%ebp)
  80028c:	8b 45 14             	mov    0x14(%ebp),%eax
  80028f:	8d 58 ff             	lea    -0x1(%eax),%ebx
  800292:	53                   	push   %ebx
  800293:	ff 75 10             	pushl  0x10(%ebp)
  800296:	83 ec 08             	sub    $0x8,%esp
  800299:	ff 75 e4             	pushl  -0x1c(%ebp)
  80029c:	ff 75 e0             	pushl  -0x20(%ebp)
  80029f:	ff 75 dc             	pushl  -0x24(%ebp)
  8002a2:	ff 75 d8             	pushl  -0x28(%ebp)
  8002a5:	e8 56 08 00 00       	call   800b00 <__udivdi3>
  8002aa:	83 c4 18             	add    $0x18,%esp
  8002ad:	52                   	push   %edx
  8002ae:	50                   	push   %eax
  8002af:	89 f2                	mov    %esi,%edx
  8002b1:	89 f8                	mov    %edi,%eax
  8002b3:	e8 9e ff ff ff       	call   800256 <printnum>
  8002b8:	83 c4 20             	add    $0x20,%esp
  8002bb:	eb 18                	jmp    8002d5 <printnum+0x7f>
	} else {
		// print any needed pad characters before first digit
		while (--width > 0)
			putch(padc, putdat);
  8002bd:	83 ec 08             	sub    $0x8,%esp
  8002c0:	56                   	push   %esi
  8002c1:	ff 75 18             	pushl  0x18(%ebp)
  8002c4:	ff d7                	call   *%edi
  8002c6:	83 c4 10             	add    $0x10,%esp
  8002c9:	eb 03                	jmp    8002ce <printnum+0x78>
  8002cb:	8b 5d 14             	mov    0x14(%ebp),%ebx
	// first recursively print all preceding (more significant) digits
	if (num >= base) {
		printnum(putch, putdat, num / base, base, width - 1, padc);
	} else {
		// print any needed pad characters before first digit
		while (--width > 0)
  8002ce:	83 eb 01             	sub    $0x1,%ebx
  8002d1:	85 db                	test   %ebx,%ebx
  8002d3:	7f e8                	jg     8002bd <printnum+0x67>
			putch(padc, putdat);
	}

	// then print this (the least significant) digit
	putch("0123456789abcdef"[num % base], putdat);
  8002d5:	83 ec 08             	sub    $0x8,%esp
  8002d8:	56                   	push   %esi
  8002d9:	83 ec 04             	sub    $0x4,%esp
  8002dc:	ff 75 e4             	pushl  -0x1c(%ebp)
  8002df:	ff 75 e0             	pushl  -0x20(%ebp)
  8002e2:	ff 75 dc             	pushl  -0x24(%ebp)
  8002e5:	ff 75 d8             	pushl  -0x28(%ebp)
  8002e8:	e8 43 09 00 00       	call   800c30 <__umoddi3>
  8002ed:	83 c4 14             	add    $0x14,%esp
  8002f0:	0f be 80 e2 0d 80 00 	movsbl 0x800de2(%eax),%eax
  8002f7:	50                   	push   %eax
  8002f8:	ff d7                	call   *%edi
}
  8002fa:	83 c4 10             	add    $0x10,%esp
  8002fd:	8d 65 f4             	lea    -0xc(%ebp),%esp
  800300:	5b                   	pop    %ebx
  800301:	5e                   	pop    %esi
  800302:	5f                   	pop    %edi
  800303:	5d                   	pop    %ebp
  800304:	c3                   	ret    

00800305 <getuint>:

// Get an unsigned int of various possible sizes from a varargs list,
// depending on the lflag parameter.
static unsigned long long
getuint(va_list *ap, int lflag)
{
  800305:	55                   	push   %ebp
  800306:	89 e5                	mov    %esp,%ebp
	if (lflag >= 2)
  800308:	83 fa 01             	cmp    $0x1,%edx
  80030b:	7e 0e                	jle    80031b <getuint+0x16>
		return va_arg(*ap, unsigned long long);
  80030d:	8b 10                	mov    (%eax),%edx
  80030f:	8d 4a 08             	lea    0x8(%edx),%ecx
  800312:	89 08                	mov    %ecx,(%eax)
  800314:	8b 02                	mov    (%edx),%eax
  800316:	8b 52 04             	mov    0x4(%edx),%edx
  800319:	eb 22                	jmp    80033d <getuint+0x38>
	else if (lflag)
  80031b:	85 d2                	test   %edx,%edx
  80031d:	74 10                	je     80032f <getuint+0x2a>
		return va_arg(*ap, unsigned long);
  80031f:	8b 10                	mov    (%eax),%edx
  800321:	8d 4a 04             	lea    0x4(%edx),%ecx
  800324:	89 08                	mov    %ecx,(%eax)
  800326:	8b 02                	mov    (%edx),%eax
  800328:	ba 00 00 00 00       	mov    $0x0,%edx
  80032d:	eb 0e                	jmp    80033d <getuint+0x38>
	else
		return va_arg(*ap, unsigned int);
  80032f:	8b 10                	mov    (%eax),%edx
  800331:	8d 4a 04             	lea    0x4(%edx),%ecx
  800334:	89 08                	mov    %ecx,(%eax)
  800336:	8b 02                	mov    (%edx),%eax
  800338:	ba 00 00 00 00       	mov    $0x0,%edx
}
  80033d:	5d                   	pop    %ebp
  80033e:	c3                   	ret    

0080033f <getint>:

// Same as getuint but signed - can't use getuint
// because of sign extension
static long long
getint(va_list *ap, int lflag)
{
  80033f:	55                   	push   %ebp
  800340:	89 e5                	mov    %esp,%ebp
	if (lflag >= 2)
  800342:	83 fa 01             	cmp    $0x1,%edx
  800345:	7e 0e                	jle    800355 <getint+0x16>
		return va_arg(*ap, long long);
  800347:	8b 10                	mov    (%eax),%edx
  800349:	8d 4a 08             	lea    0x8(%edx),%ecx
  80034c:	89 08                	mov    %ecx,(%eax)
  80034e:	8b 02                	mov    (%edx),%eax
  800350:	8b 52 04             	mov    0x4(%edx),%edx
  800353:	eb 1a                	jmp    80036f <getint+0x30>
	else if (lflag)
  800355:	85 d2                	test   %edx,%edx
  800357:	74 0c                	je     800365 <getint+0x26>
		return va_arg(*ap, long);
  800359:	8b 10                	mov    (%eax),%edx
  80035b:	8d 4a 04             	lea    0x4(%edx),%ecx
  80035e:	89 08                	mov    %ecx,(%eax)
  800360:	8b 02                	mov    (%edx),%eax
  800362:	99                   	cltd   
  800363:	eb 0a                	jmp    80036f <getint+0x30>
	else
		return va_arg(*ap, int);
  800365:	8b 10                	mov    (%eax),%edx
  800367:	8d 4a 04             	lea    0x4(%edx),%ecx
  80036a:	89 08                	mov    %ecx,(%eax)
  80036c:	8b 02                	mov    (%edx),%eax
  80036e:	99                   	cltd   
}
  80036f:	5d                   	pop    %ebp
  800370:	c3                   	ret    

00800371 <sprintputch>:
	int cnt;
};

static void
sprintputch(int ch, struct sprintbuf *b)
{
  800371:	55                   	push   %ebp
  800372:	89 e5                	mov    %esp,%ebp
  800374:	8b 45 0c             	mov    0xc(%ebp),%eax
	b->cnt++;
  800377:	83 40 08 01          	addl   $0x1,0x8(%eax)
	if (b->buf < b->ebuf)
  80037b:	8b 10                	mov    (%eax),%edx
  80037d:	3b 50 04             	cmp    0x4(%eax),%edx
  800380:	73 0a                	jae    80038c <sprintputch+0x1b>
		*b->buf++ = ch;
  800382:	8d 4a 01             	lea    0x1(%edx),%ecx
  800385:	89 08                	mov    %ecx,(%eax)
  800387:	8b 45 08             	mov    0x8(%ebp),%eax
  80038a:	88 02                	mov    %al,(%edx)
}
  80038c:	5d                   	pop    %ebp
  80038d:	c3                   	ret    

0080038e <printfmt>:
	}
}

void
printfmt(void (*putch)(int, void*), void *putdat, const char *fmt, ...)
{
  80038e:	55                   	push   %ebp
  80038f:	89 e5                	mov    %esp,%ebp
  800391:	83 ec 08             	sub    $0x8,%esp
	va_list ap;

	va_start(ap, fmt);
  800394:	8d 45 14             	lea    0x14(%ebp),%eax
	vprintfmt(putch, putdat, fmt, ap);
  800397:	50                   	push   %eax
  800398:	ff 75 10             	pushl  0x10(%ebp)
  80039b:	ff 75 0c             	pushl  0xc(%ebp)
  80039e:	ff 75 08             	pushl  0x8(%ebp)
  8003a1:	e8 05 00 00 00       	call   8003ab <vprintfmt>
	va_end(ap);
}
  8003a6:	83 c4 10             	add    $0x10,%esp
  8003a9:	c9                   	leave  
  8003aa:	c3                   	ret    

008003ab <vprintfmt>:
// Main function to format and print a string.
void printfmt(void (*putch)(int, void*), void *putdat, const char *fmt, ...);

void
vprintfmt(void (*putch)(int, void*), void *putdat, const char *fmt, va_list ap)
{
  8003ab:	55                   	push   %ebp
  8003ac:	89 e5                	mov    %esp,%ebp
  8003ae:	57                   	push   %edi
  8003af:	56                   	push   %esi
  8003b0:	53                   	push   %ebx
  8003b1:	83 ec 2c             	sub    $0x2c,%esp
  8003b4:	8b 75 08             	mov    0x8(%ebp),%esi
  8003b7:	8b 5d 0c             	mov    0xc(%ebp),%ebx
  8003ba:	8b 7d 10             	mov    0x10(%ebp),%edi
  8003bd:	eb 12                	jmp    8003d1 <vprintfmt+0x26>
	int base, lflag, width, precision, altflag;
	char padc;

	while (1) {
		while ((ch = *(unsigned char *) fmt++) != '%') {
			if (ch == '\0')
  8003bf:	85 c0                	test   %eax,%eax
  8003c1:	0f 84 44 03 00 00    	je     80070b <vprintfmt+0x360>
				return;
			putch(ch, putdat);
  8003c7:	83 ec 08             	sub    $0x8,%esp
  8003ca:	53                   	push   %ebx
  8003cb:	50                   	push   %eax
  8003cc:	ff d6                	call   *%esi
  8003ce:	83 c4 10             	add    $0x10,%esp
	unsigned long long num;
	int base, lflag, width, precision, altflag;
	char padc;

	while (1) {
		while ((ch = *(unsigned char *) fmt++) != '%') {
  8003d1:	83 c7 01             	add    $0x1,%edi
  8003d4:	0f b6 47 ff          	movzbl -0x1(%edi),%eax
  8003d8:	83 f8 25             	cmp    $0x25,%eax
  8003db:	75 e2                	jne    8003bf <vprintfmt+0x14>
  8003dd:	c6 45 d4 20          	movb   $0x20,-0x2c(%ebp)
  8003e1:	c7 45 d8 00 00 00 00 	movl   $0x0,-0x28(%ebp)
  8003e8:	c7 45 d0 ff ff ff ff 	movl   $0xffffffff,-0x30(%ebp)
  8003ef:	c7 45 e0 ff ff ff ff 	movl   $0xffffffff,-0x20(%ebp)
  8003f6:	ba 00 00 00 00       	mov    $0x0,%edx
  8003fb:	eb 07                	jmp    800404 <vprintfmt+0x59>
		width = -1;
		precision = -1;
		lflag = 0;
		altflag = 0;
	reswitch:
		switch (ch = *(unsigned char *) fmt++) {
  8003fd:	8b 7d e4             	mov    -0x1c(%ebp),%edi

		// flag to pad on the right
		case '-':
			padc = '-';
  800400:	c6 45 d4 2d          	movb   $0x2d,-0x2c(%ebp)
		width = -1;
		precision = -1;
		lflag = 0;
		altflag = 0;
	reswitch:
		switch (ch = *(unsigned char *) fmt++) {
  800404:	8d 47 01             	lea    0x1(%edi),%eax
  800407:	89 45 e4             	mov    %eax,-0x1c(%ebp)
  80040a:	0f b6 07             	movzbl (%edi),%eax
  80040d:	0f b6 c8             	movzbl %al,%ecx
  800410:	83 e8 23             	sub    $0x23,%eax
  800413:	3c 55                	cmp    $0x55,%al
  800415:	0f 87 d5 02 00 00    	ja     8006f0 <vprintfmt+0x345>
  80041b:	0f b6 c0             	movzbl %al,%eax
  80041e:	ff 24 85 70 0e 80 00 	jmp    *0x800e70(,%eax,4)
  800425:	8b 7d e4             	mov    -0x1c(%ebp),%edi
			padc = '-';
			goto reswitch;

		// flag to pad with 0's instead of spaces
		case '0':
			padc = '0';
  800428:	c6 45 d4 30          	movb   $0x30,-0x2c(%ebp)
  80042c:	eb d6                	jmp    800404 <vprintfmt+0x59>
		width = -1;
		precision = -1;
		lflag = 0;
		altflag = 0;
	reswitch:
		switch (ch = *(unsigned char *) fmt++) {
  80042e:	8b 7d e4             	mov    -0x1c(%ebp),%edi
  800431:	b8 00 00 00 00       	mov    $0x0,%eax
  800436:	89 55 e4             	mov    %edx,-0x1c(%ebp)
		case '6':
		case '7':
		case '8':
		case '9':
			for (precision = 0; ; ++fmt) {
				precision = precision * 10 + ch - '0';
  800439:	8d 04 80             	lea    (%eax,%eax,4),%eax
  80043c:	8d 44 41 d0          	lea    -0x30(%ecx,%eax,2),%eax
				ch = *fmt;
  800440:	0f be 0f             	movsbl (%edi),%ecx
				if (ch < '0' || ch > '9')
  800443:	8d 51 d0             	lea    -0x30(%ecx),%edx
  800446:	83 fa 09             	cmp    $0x9,%edx
  800449:	77 39                	ja     800484 <vprintfmt+0xd9>
		case '5':
		case '6':
		case '7':
		case '8':
		case '9':
			for (precision = 0; ; ++fmt) {
  80044b:	83 c7 01             	add    $0x1,%edi
				precision = precision * 10 + ch - '0';
				ch = *fmt;
				if (ch < '0' || ch > '9')
					break;
			}
  80044e:	eb e9                	jmp    800439 <vprintfmt+0x8e>
			goto process_precision;

		case '*':
			precision = va_arg(ap, int);
  800450:	8b 45 14             	mov    0x14(%ebp),%eax
  800453:	8d 48 04             	lea    0x4(%eax),%ecx
  800456:	89 4d 14             	mov    %ecx,0x14(%ebp)
  800459:	8b 00                	mov    (%eax),%eax
  80045b:	89 45 d0             	mov    %eax,-0x30(%ebp)
		width = -1;
		precision = -1;
		lflag = 0;
		altflag = 0;
	reswitch:
		switch (ch = *(unsigned char *) fmt++) {
  80045e:	8b 7d e4             	mov    -0x1c(%ebp),%edi
			}
			goto process_precision;

		case '*':
			precision = va_arg(ap, int);
			goto process_precision;
  800461:	eb 27                	jmp    80048a <vprintfmt+0xdf>
  800463:	8b 45 e0             	mov    -0x20(%ebp),%eax
  800466:	85 c0                	test   %eax,%eax
  800468:	b9 00 00 00 00       	mov    $0x0,%ecx
  80046d:	0f 49 c8             	cmovns %eax,%ecx
  800470:	89 4d e0             	mov    %ecx,-0x20(%ebp)
		width = -1;
		precision = -1;
		lflag = 0;
		altflag = 0;
	reswitch:
		switch (ch = *(unsigned char *) fmt++) {
  800473:	8b 7d e4             	mov    -0x1c(%ebp),%edi
  800476:	eb 8c                	jmp    800404 <vprintfmt+0x59>
  800478:	8b 7d e4             	mov    -0x1c(%ebp),%edi
			if (width < 0)
				width = 0;
			goto reswitch;

		case '#':
			altflag = 1;
  80047b:	c7 45 d8 01 00 00 00 	movl   $0x1,-0x28(%ebp)
			goto reswitch;
  800482:	eb 80                	jmp    800404 <vprintfmt+0x59>
  800484:	8b 55 e4             	mov    -0x1c(%ebp),%edx
  800487:	89 45 d0             	mov    %eax,-0x30(%ebp)

		process_precision:
			if (width < 0)
  80048a:	83 7d e0 00          	cmpl   $0x0,-0x20(%ebp)
  80048e:	0f 89 70 ff ff ff    	jns    800404 <vprintfmt+0x59>
				width = precision, precision = -1;
  800494:	8b 45 d0             	mov    -0x30(%ebp),%eax
  800497:	89 45 e0             	mov    %eax,-0x20(%ebp)
  80049a:	c7 45 d0 ff ff ff ff 	movl   $0xffffffff,-0x30(%ebp)
  8004a1:	e9 5e ff ff ff       	jmp    800404 <vprintfmt+0x59>
			goto reswitch;

		// long flag (doubled for long long)
		case 'l':
			lflag++;
  8004a6:	83 c2 01             	add    $0x1,%edx
		width = -1;
		precision = -1;
		lflag = 0;
		altflag = 0;
	reswitch:
		switch (ch = *(unsigned char *) fmt++) {
  8004a9:	8b 7d e4             	mov    -0x1c(%ebp),%edi
			goto reswitch;

		// long flag (doubled for long long)
		case 'l':
			lflag++;
			goto reswitch;
  8004ac:	e9 53 ff ff ff       	jmp    800404 <vprintfmt+0x59>

		// character
		case 'c':
			putch(va_arg(ap, int), putdat);
  8004b1:	8b 45 14             	mov    0x14(%ebp),%eax
  8004b4:	8d 50 04             	lea    0x4(%eax),%edx
  8004b7:	89 55 14             	mov    %edx,0x14(%ebp)
  8004ba:	83 ec 08             	sub    $0x8,%esp
  8004bd:	53                   	push   %ebx
  8004be:	ff 30                	pushl  (%eax)
  8004c0:	ff d6                	call   *%esi
			break;
  8004c2:	83 c4 10             	add    $0x10,%esp
		width = -1;
		precision = -1;
		lflag = 0;
		altflag = 0;
	reswitch:
		switch (ch = *(unsigned char *) fmt++) {
  8004c5:	8b 7d e4             	mov    -0x1c(%ebp),%edi
			goto reswitch;

		// character
		case 'c':
			putch(va_arg(ap, int), putdat);
			break;
  8004c8:	e9 04 ff ff ff       	jmp    8003d1 <vprintfmt+0x26>

		// error message
		case 'e':
			err = va_arg(ap, int);
  8004cd:	8b 45 14             	mov    0x14(%ebp),%eax
  8004d0:	8d 50 04             	lea    0x4(%eax),%edx
  8004d3:	89 55 14             	mov    %edx,0x14(%ebp)
  8004d6:	8b 00                	mov    (%eax),%eax
  8004d8:	99                   	cltd   
  8004d9:	31 d0                	xor    %edx,%eax
  8004db:	29 d0                	sub    %edx,%eax
			if (err < 0)
				err = -err;
			if (err >= MAXERROR || (p = error_string[err]) == NULL)
  8004dd:	83 f8 06             	cmp    $0x6,%eax
  8004e0:	7f 0b                	jg     8004ed <vprintfmt+0x142>
  8004e2:	8b 14 85 c8 0f 80 00 	mov    0x800fc8(,%eax,4),%edx
  8004e9:	85 d2                	test   %edx,%edx
  8004eb:	75 18                	jne    800505 <vprintfmt+0x15a>
				printfmt(putch, putdat, "error %d", err);
  8004ed:	50                   	push   %eax
  8004ee:	68 fa 0d 80 00       	push   $0x800dfa
  8004f3:	53                   	push   %ebx
  8004f4:	56                   	push   %esi
  8004f5:	e8 94 fe ff ff       	call   80038e <printfmt>
  8004fa:	83 c4 10             	add    $0x10,%esp
		width = -1;
		precision = -1;
		lflag = 0;
		altflag = 0;
	reswitch:
		switch (ch = *(unsigned char *) fmt++) {
  8004fd:	8b 7d e4             	mov    -0x1c(%ebp),%edi
		case 'e':
			err = va_arg(ap, int);
			if (err < 0)
				err = -err;
			if (err >= MAXERROR || (p = error_string[err]) == NULL)
				printfmt(putch, putdat, "error %d", err);
  800500:	e9 cc fe ff ff       	jmp    8003d1 <vprintfmt+0x26>
			else
				printfmt(putch, putdat, "%s", p);
  800505:	52                   	push   %edx
  800506:	68 03 0e 80 00       	push   $0x800e03
  80050b:	53                   	push   %ebx
  80050c:	56                   	push   %esi
  80050d:	e8 7c fe ff ff       	call   80038e <printfmt>
  800512:	83 c4 10             	add    $0x10,%esp
		width = -1;
		precision = -1;
		lflag = 0;
		altflag = 0;
	reswitch:
		switch (ch = *(unsigned char *) fmt++) {
  800515:	8b 7d e4             	mov    -0x1c(%ebp),%edi
  800518:	e9 b4 fe ff ff       	jmp    8003d1 <vprintfmt+0x26>
				printfmt(putch, putdat, "%s", p);
			break;

		// string
		case 's':
			if ((p = va_arg(ap, char *)) == NULL)
  80051d:	8b 45 14             	mov    0x14(%ebp),%eax
  800520:	8d 50 04             	lea    0x4(%eax),%edx
  800523:	89 55 14             	mov    %edx,0x14(%ebp)
  800526:	8b 38                	mov    (%eax),%edi
				p = "(null)";
  800528:	85 ff                	test   %edi,%edi
  80052a:	b8 f3 0d 80 00       	mov    $0x800df3,%eax
  80052f:	0f 44 f8             	cmove  %eax,%edi
			if (width > 0 && padc != '-')
  800532:	83 7d e0 00          	cmpl   $0x0,-0x20(%ebp)
  800536:	0f 8e 94 00 00 00    	jle    8005d0 <vprintfmt+0x225>
  80053c:	80 7d d4 2d          	cmpb   $0x2d,-0x2c(%ebp)
  800540:	0f 84 98 00 00 00    	je     8005de <vprintfmt+0x233>
				for (width -= strnlen(p, precision); width > 0; width--)
  800546:	83 ec 08             	sub    $0x8,%esp
  800549:	ff 75 d0             	pushl  -0x30(%ebp)
  80054c:	57                   	push   %edi
  80054d:	e8 41 02 00 00       	call   800793 <strnlen>
  800552:	8b 4d e0             	mov    -0x20(%ebp),%ecx
  800555:	29 c1                	sub    %eax,%ecx
  800557:	89 4d cc             	mov    %ecx,-0x34(%ebp)
  80055a:	83 c4 10             	add    $0x10,%esp
					putch(padc, putdat);
  80055d:	0f be 45 d4          	movsbl -0x2c(%ebp),%eax
  800561:	89 45 e0             	mov    %eax,-0x20(%ebp)
  800564:	89 7d d4             	mov    %edi,-0x2c(%ebp)
  800567:	89 cf                	mov    %ecx,%edi
		// string
		case 's':
			if ((p = va_arg(ap, char *)) == NULL)
				p = "(null)";
			if (width > 0 && padc != '-')
				for (width -= strnlen(p, precision); width > 0; width--)
  800569:	eb 0f                	jmp    80057a <vprintfmt+0x1cf>
					putch(padc, putdat);
  80056b:	83 ec 08             	sub    $0x8,%esp
  80056e:	53                   	push   %ebx
  80056f:	ff 75 e0             	pushl  -0x20(%ebp)
  800572:	ff d6                	call   *%esi
		// string
		case 's':
			if ((p = va_arg(ap, char *)) == NULL)
				p = "(null)";
			if (width > 0 && padc != '-')
				for (width -= strnlen(p, precision); width > 0; width--)
  800574:	83 ef 01             	sub    $0x1,%edi
  800577:	83 c4 10             	add    $0x10,%esp
  80057a:	85 ff                	test   %edi,%edi
  80057c:	7f ed                	jg     80056b <vprintfmt+0x1c0>
  80057e:	8b 7d d4             	mov    -0x2c(%ebp),%edi
  800581:	8b 4d cc             	mov    -0x34(%ebp),%ecx
  800584:	85 c9                	test   %ecx,%ecx
  800586:	b8 00 00 00 00       	mov    $0x0,%eax
  80058b:	0f 49 c1             	cmovns %ecx,%eax
  80058e:	29 c1                	sub    %eax,%ecx
  800590:	89 75 08             	mov    %esi,0x8(%ebp)
  800593:	8b 75 d0             	mov    -0x30(%ebp),%esi
  800596:	89 5d 0c             	mov    %ebx,0xc(%ebp)
  800599:	89 cb                	mov    %ecx,%ebx
  80059b:	eb 4d                	jmp    8005ea <vprintfmt+0x23f>
					putch(padc, putdat);
			for (; (ch = *p++) != '\0' && (precision < 0 || --precision >= 0); width--)
				if (altflag && (ch < ' ' || ch > '~'))
  80059d:	83 7d d8 00          	cmpl   $0x0,-0x28(%ebp)
  8005a1:	74 1b                	je     8005be <vprintfmt+0x213>
  8005a3:	0f be c0             	movsbl %al,%eax
  8005a6:	83 e8 20             	sub    $0x20,%eax
  8005a9:	83 f8 5e             	cmp    $0x5e,%eax
  8005ac:	76 10                	jbe    8005be <vprintfmt+0x213>
					putch('?', putdat);
  8005ae:	83 ec 08             	sub    $0x8,%esp
  8005b1:	ff 75 0c             	pushl  0xc(%ebp)
  8005b4:	6a 3f                	push   $0x3f
  8005b6:	ff 55 08             	call   *0x8(%ebp)
  8005b9:	83 c4 10             	add    $0x10,%esp
  8005bc:	eb 0d                	jmp    8005cb <vprintfmt+0x220>
				else
					putch(ch, putdat);
  8005be:	83 ec 08             	sub    $0x8,%esp
  8005c1:	ff 75 0c             	pushl  0xc(%ebp)
  8005c4:	52                   	push   %edx
  8005c5:	ff 55 08             	call   *0x8(%ebp)
  8005c8:	83 c4 10             	add    $0x10,%esp
			if ((p = va_arg(ap, char *)) == NULL)
				p = "(null)";
			if (width > 0 && padc != '-')
				for (width -= strnlen(p, precision); width > 0; width--)
					putch(padc, putdat);
			for (; (ch = *p++) != '\0' && (precision < 0 || --precision >= 0); width--)
  8005cb:	83 eb 01             	sub    $0x1,%ebx
  8005ce:	eb 1a                	jmp    8005ea <vprintfmt+0x23f>
  8005d0:	89 75 08             	mov    %esi,0x8(%ebp)
  8005d3:	8b 75 d0             	mov    -0x30(%ebp),%esi
  8005d6:	89 5d 0c             	mov    %ebx,0xc(%ebp)
  8005d9:	8b 5d e0             	mov    -0x20(%ebp),%ebx
  8005dc:	eb 0c                	jmp    8005ea <vprintfmt+0x23f>
  8005de:	89 75 08             	mov    %esi,0x8(%ebp)
  8005e1:	8b 75 d0             	mov    -0x30(%ebp),%esi
  8005e4:	89 5d 0c             	mov    %ebx,0xc(%ebp)
  8005e7:	8b 5d e0             	mov    -0x20(%ebp),%ebx
  8005ea:	83 c7 01             	add    $0x1,%edi
  8005ed:	0f b6 47 ff          	movzbl -0x1(%edi),%eax
  8005f1:	0f be d0             	movsbl %al,%edx
  8005f4:	85 d2                	test   %edx,%edx
  8005f6:	74 23                	je     80061b <vprintfmt+0x270>
  8005f8:	85 f6                	test   %esi,%esi
  8005fa:	78 a1                	js     80059d <vprintfmt+0x1f2>
  8005fc:	83 ee 01             	sub    $0x1,%esi
  8005ff:	79 9c                	jns    80059d <vprintfmt+0x1f2>
  800601:	89 df                	mov    %ebx,%edi
  800603:	8b 75 08             	mov    0x8(%ebp),%esi
  800606:	8b 5d 0c             	mov    0xc(%ebp),%ebx
  800609:	eb 18                	jmp    800623 <vprintfmt+0x278>
				if (altflag && (ch < ' ' || ch > '~'))
					putch('?', putdat);
				else
					putch(ch, putdat);
			for (; width > 0; width--)
				putch(' ', putdat);
  80060b:	83 ec 08             	sub    $0x8,%esp
  80060e:	53                   	push   %ebx
  80060f:	6a 20                	push   $0x20
  800611:	ff d6                	call   *%esi
			for (; (ch = *p++) != '\0' && (precision < 0 || --precision >= 0); width--)
				if (altflag && (ch < ' ' || ch > '~'))
					putch('?', putdat);
				else
					putch(ch, putdat);
			for (; width > 0; width--)
  800613:	83 ef 01             	sub    $0x1,%edi
  800616:	83 c4 10             	add    $0x10,%esp
  800619:	eb 08                	jmp    800623 <vprintfmt+0x278>
  80061b:	89 df                	mov    %ebx,%edi
  80061d:	8b 75 08             	mov    0x8(%ebp),%esi
  800620:	8b 5d 0c             	mov    0xc(%ebp),%ebx
  800623:	85 ff                	test   %edi,%edi
  800625:	7f e4                	jg     80060b <vprintfmt+0x260>
		width = -1;
		precision = -1;
		lflag = 0;
		altflag = 0;
	reswitch:
		switch (ch = *(unsigned char *) fmt++) {
  800627:	8b 7d e4             	mov    -0x1c(%ebp),%edi
  80062a:	e9 a2 fd ff ff       	jmp    8003d1 <vprintfmt+0x26>
				putch(' ', putdat);
			break;

		// (signed) decimal
		case 'd':
			num = getint(&ap, lflag);
  80062f:	8d 45 14             	lea    0x14(%ebp),%eax
  800632:	e8 08 fd ff ff       	call   80033f <getint>
  800637:	89 45 d8             	mov    %eax,-0x28(%ebp)
  80063a:	89 55 dc             	mov    %edx,-0x24(%ebp)
			if ((long long) num < 0) {
				putch('-', putdat);
				num = -(long long) num;
			}
			base = 10;
  80063d:	b9 0a 00 00 00       	mov    $0xa,%ecx
			break;

		// (signed) decimal
		case 'd':
			num = getint(&ap, lflag);
			if ((long long) num < 0) {
  800642:	83 7d dc 00          	cmpl   $0x0,-0x24(%ebp)
  800646:	79 74                	jns    8006bc <vprintfmt+0x311>
				putch('-', putdat);
  800648:	83 ec 08             	sub    $0x8,%esp
  80064b:	53                   	push   %ebx
  80064c:	6a 2d                	push   $0x2d
  80064e:	ff d6                	call   *%esi
				num = -(long long) num;
  800650:	8b 45 d8             	mov    -0x28(%ebp),%eax
  800653:	8b 55 dc             	mov    -0x24(%ebp),%edx
  800656:	f7 d8                	neg    %eax
  800658:	83 d2 00             	adc    $0x0,%edx
  80065b:	f7 da                	neg    %edx
  80065d:	83 c4 10             	add    $0x10,%esp
			}
			base = 10;
  800660:	b9 0a 00 00 00       	mov    $0xa,%ecx
  800665:	eb 55                	jmp    8006bc <vprintfmt+0x311>
			goto number;

		// unsigned decimal
		case 'u':
			num = getuint(&ap, lflag);
  800667:	8d 45 14             	lea    0x14(%ebp),%eax
  80066a:	e8 96 fc ff ff       	call   800305 <getuint>
			base = 10;
  80066f:	b9 0a 00 00 00       	mov    $0xa,%ecx
			goto number;
  800674:	eb 46                	jmp    8006bc <vprintfmt+0x311>

		// (unsigned) octal
		case 'o':
			num = getuint(&ap, lflag);
  800676:	8d 45 14             	lea    0x14(%ebp),%eax
  800679:	e8 87 fc ff ff       	call   800305 <getuint>
			base = 8;
  80067e:	b9 08 00 00 00       	mov    $0x8,%ecx
			goto number;
  800683:	eb 37                	jmp    8006bc <vprintfmt+0x311>

		// pointer
		case 'p':
			putch('0', putdat);
  800685:	83 ec 08             	sub    $0x8,%esp
  800688:	53                   	push   %ebx
  800689:	6a 30                	push   $0x30
  80068b:	ff d6                	call   *%esi
			putch('x', putdat);
  80068d:	83 c4 08             	add    $0x8,%esp
  800690:	53                   	push   %ebx
  800691:	6a 78                	push   $0x78
  800693:	ff d6                	call   *%esi
			num = (unsigned long long)
				(uintptr_t) va_arg(ap, void *);
  800695:	8b 45 14             	mov    0x14(%ebp),%eax
  800698:	8d 50 04             	lea    0x4(%eax),%edx
  80069b:	89 55 14             	mov    %edx,0x14(%ebp)

		// pointer
		case 'p':
			putch('0', putdat);
			putch('x', putdat);
			num = (unsigned long long)
  80069e:	8b 00                	mov    (%eax),%eax
  8006a0:	ba 00 00 00 00       	mov    $0x0,%edx
				(uintptr_t) va_arg(ap, void *);
			base = 16;
			goto number;
  8006a5:	83 c4 10             	add    $0x10,%esp
		case 'p':
			putch('0', putdat);
			putch('x', putdat);
			num = (unsigned long long)
				(uintptr_t) va_arg(ap, void *);
			base = 16;
  8006a8:	b9 10 00 00 00       	mov    $0x10,%ecx
			goto number;
  8006ad:	eb 0d                	jmp    8006bc <vprintfmt+0x311>

		// (unsigned) hexadecimal
		case 'x':
			num = getuint(&ap, lflag);
  8006af:	8d 45 14             	lea    0x14(%ebp),%eax
  8006b2:	e8 4e fc ff ff       	call   800305 <getuint>
			base = 16;
  8006b7:	b9 10 00 00 00       	mov    $0x10,%ecx
		number:
			printnum(putch, putdat, num, base, width, padc);
  8006bc:	83 ec 0c             	sub    $0xc,%esp
  8006bf:	0f be 7d d4          	movsbl -0x2c(%ebp),%edi
  8006c3:	57                   	push   %edi
  8006c4:	ff 75 e0             	pushl  -0x20(%ebp)
  8006c7:	51                   	push   %ecx
  8006c8:	52                   	push   %edx
  8006c9:	50                   	push   %eax
  8006ca:	89 da                	mov    %ebx,%edx
  8006cc:	89 f0                	mov    %esi,%eax
  8006ce:	e8 83 fb ff ff       	call   800256 <printnum>
			break;
  8006d3:	83 c4 20             	add    $0x20,%esp
  8006d6:	8b 7d e4             	mov    -0x1c(%ebp),%edi
  8006d9:	e9 f3 fc ff ff       	jmp    8003d1 <vprintfmt+0x26>

		// escaped '%' character
		case '%':
			putch(ch, putdat);
  8006de:	83 ec 08             	sub    $0x8,%esp
  8006e1:	53                   	push   %ebx
  8006e2:	51                   	push   %ecx
  8006e3:	ff d6                	call   *%esi
			break;
  8006e5:	83 c4 10             	add    $0x10,%esp
		width = -1;
		precision = -1;
		lflag = 0;
		altflag = 0;
	reswitch:
		switch (ch = *(unsigned char *) fmt++) {
  8006e8:	8b 7d e4             	mov    -0x1c(%ebp),%edi
			break;

		// escaped '%' character
		case '%':
			putch(ch, putdat);
			break;
  8006eb:	e9 e1 fc ff ff       	jmp    8003d1 <vprintfmt+0x26>

		// unrecognized escape sequence - just print it literally
		default:
			putch('%', putdat);
  8006f0:	83 ec 08             	sub    $0x8,%esp
  8006f3:	53                   	push   %ebx
  8006f4:	6a 25                	push   $0x25
  8006f6:	ff d6                	call   *%esi
			for (fmt--; fmt[-1] != '%'; fmt--)
  8006f8:	83 c4 10             	add    $0x10,%esp
  8006fb:	eb 03                	jmp    800700 <vprintfmt+0x355>
  8006fd:	83 ef 01             	sub    $0x1,%edi
  800700:	80 7f ff 25          	cmpb   $0x25,-0x1(%edi)
  800704:	75 f7                	jne    8006fd <vprintfmt+0x352>
  800706:	e9 c6 fc ff ff       	jmp    8003d1 <vprintfmt+0x26>
				/* do nothing */;
			break;
		}
	}
}
  80070b:	8d 65 f4             	lea    -0xc(%ebp),%esp
  80070e:	5b                   	pop    %ebx
  80070f:	5e                   	pop    %esi
  800710:	5f                   	pop    %edi
  800711:	5d                   	pop    %ebp
  800712:	c3                   	ret    

00800713 <vsnprintf>:
		*b->buf++ = ch;
}

int
vsnprintf(char *buf, int n, const char *fmt, va_list ap)
{
  800713:	55                   	push   %ebp
  800714:	89 e5                	mov    %esp,%ebp
  800716:	83 ec 18             	sub    $0x18,%esp
  800719:	8b 45 08             	mov    0x8(%ebp),%eax
  80071c:	8b 55 0c             	mov    0xc(%ebp),%edx
	struct sprintbuf b = {buf, buf+n-1, 0};
  80071f:	89 45 ec             	mov    %eax,-0x14(%ebp)
  800722:	8d 4c 10 ff          	lea    -0x1(%eax,%edx,1),%ecx
  800726:	89 4d f0             	mov    %ecx,-0x10(%ebp)
  800729:	c7 45 f4 00 00 00 00 	movl   $0x0,-0xc(%ebp)

	if (buf == NULL || n < 1)
  800730:	85 c0                	test   %eax,%eax
  800732:	74 26                	je     80075a <vsnprintf+0x47>
  800734:	85 d2                	test   %edx,%edx
  800736:	7e 22                	jle    80075a <vsnprintf+0x47>
		return -E_INVAL;

	// print the string to the buffer
	vprintfmt((void*)sprintputch, &b, fmt, ap);
  800738:	ff 75 14             	pushl  0x14(%ebp)
  80073b:	ff 75 10             	pushl  0x10(%ebp)
  80073e:	8d 45 ec             	lea    -0x14(%ebp),%eax
  800741:	50                   	push   %eax
  800742:	68 71 03 80 00       	push   $0x800371
  800747:	e8 5f fc ff ff       	call   8003ab <vprintfmt>

	// null terminate the buffer
	*b.buf = '\0';
  80074c:	8b 45 ec             	mov    -0x14(%ebp),%eax
  80074f:	c6 00 00             	movb   $0x0,(%eax)

	return b.cnt;
  800752:	8b 45 f4             	mov    -0xc(%ebp),%eax
  800755:	83 c4 10             	add    $0x10,%esp
  800758:	eb 05                	jmp    80075f <vsnprintf+0x4c>
vsnprintf(char *buf, int n, const char *fmt, va_list ap)
{
	struct sprintbuf b = {buf, buf+n-1, 0};

	if (buf == NULL || n < 1)
		return -E_INVAL;
  80075a:	b8 fd ff ff ff       	mov    $0xfffffffd,%eax

	// null terminate the buffer
	*b.buf = '\0';

	return b.cnt;
}
  80075f:	c9                   	leave  
  800760:	c3                   	ret    

00800761 <snprintf>:

int
snprintf(char *buf, int n, const char *fmt, ...)
{
  800761:	55                   	push   %ebp
  800762:	89 e5                	mov    %esp,%ebp
  800764:	83 ec 08             	sub    $0x8,%esp
	va_list ap;
	int rc;

	va_start(ap, fmt);
  800767:	8d 45 14             	lea    0x14(%ebp),%eax
	rc = vsnprintf(buf, n, fmt, ap);
  80076a:	50                   	push   %eax
  80076b:	ff 75 10             	pushl  0x10(%ebp)
  80076e:	ff 75 0c             	pushl  0xc(%ebp)
  800771:	ff 75 08             	pushl  0x8(%ebp)
  800774:	e8 9a ff ff ff       	call   800713 <vsnprintf>
	va_end(ap);

	return rc;
}
  800779:	c9                   	leave  
  80077a:	c3                   	ret    

0080077b <strlen>:
// Primespipe runs 3x faster this way.
#define ASM 1

int
strlen(const char *s)
{
  80077b:	55                   	push   %ebp
  80077c:	89 e5                	mov    %esp,%ebp
  80077e:	8b 55 08             	mov    0x8(%ebp),%edx
	int n;

	for (n = 0; *s != '\0'; s++)
  800781:	b8 00 00 00 00       	mov    $0x0,%eax
  800786:	eb 03                	jmp    80078b <strlen+0x10>
		n++;
  800788:	83 c0 01             	add    $0x1,%eax
int
strlen(const char *s)
{
	int n;

	for (n = 0; *s != '\0'; s++)
  80078b:	80 3c 02 00          	cmpb   $0x0,(%edx,%eax,1)
  80078f:	75 f7                	jne    800788 <strlen+0xd>
		n++;
	return n;
}
  800791:	5d                   	pop    %ebp
  800792:	c3                   	ret    

00800793 <strnlen>:

int
strnlen(const char *s, size_t size)
{
  800793:	55                   	push   %ebp
  800794:	89 e5                	mov    %esp,%ebp
  800796:	8b 4d 08             	mov    0x8(%ebp),%ecx
  800799:	8b 45 0c             	mov    0xc(%ebp),%eax
	int n;

	for (n = 0; size > 0 && *s != '\0'; s++, size--)
  80079c:	ba 00 00 00 00       	mov    $0x0,%edx
  8007a1:	eb 03                	jmp    8007a6 <strnlen+0x13>
		n++;
  8007a3:	83 c2 01             	add    $0x1,%edx
int
strnlen(const char *s, size_t size)
{
	int n;

	for (n = 0; size > 0 && *s != '\0'; s++, size--)
  8007a6:	39 c2                	cmp    %eax,%edx
  8007a8:	74 08                	je     8007b2 <strnlen+0x1f>
  8007aa:	80 3c 11 00          	cmpb   $0x0,(%ecx,%edx,1)
  8007ae:	75 f3                	jne    8007a3 <strnlen+0x10>
  8007b0:	89 d0                	mov    %edx,%eax
		n++;
	return n;
}
  8007b2:	5d                   	pop    %ebp
  8007b3:	c3                   	ret    

008007b4 <strcpy>:

char *
strcpy(char *dst, const char *src)
{
  8007b4:	55                   	push   %ebp
  8007b5:	89 e5                	mov    %esp,%ebp
  8007b7:	53                   	push   %ebx
  8007b8:	8b 45 08             	mov    0x8(%ebp),%eax
  8007bb:	8b 4d 0c             	mov    0xc(%ebp),%ecx
	char *ret;

	ret = dst;
	while ((*dst++ = *src++) != '\0')
  8007be:	89 c2                	mov    %eax,%edx
  8007c0:	83 c2 01             	add    $0x1,%edx
  8007c3:	83 c1 01             	add    $0x1,%ecx
  8007c6:	0f b6 59 ff          	movzbl -0x1(%ecx),%ebx
  8007ca:	88 5a ff             	mov    %bl,-0x1(%edx)
  8007cd:	84 db                	test   %bl,%bl
  8007cf:	75 ef                	jne    8007c0 <strcpy+0xc>
		/* do nothing */;
	return ret;
}
  8007d1:	5b                   	pop    %ebx
  8007d2:	5d                   	pop    %ebp
  8007d3:	c3                   	ret    

008007d4 <strcat>:

char *
strcat(char *dst, const char *src)
{
  8007d4:	55                   	push   %ebp
  8007d5:	89 e5                	mov    %esp,%ebp
  8007d7:	53                   	push   %ebx
  8007d8:	8b 5d 08             	mov    0x8(%ebp),%ebx
	int len = strlen(dst);
  8007db:	53                   	push   %ebx
  8007dc:	e8 9a ff ff ff       	call   80077b <strlen>
  8007e1:	83 c4 04             	add    $0x4,%esp
	strcpy(dst + len, src);
  8007e4:	ff 75 0c             	pushl  0xc(%ebp)
  8007e7:	01 d8                	add    %ebx,%eax
  8007e9:	50                   	push   %eax
  8007ea:	e8 c5 ff ff ff       	call   8007b4 <strcpy>
	return dst;
}
  8007ef:	89 d8                	mov    %ebx,%eax
  8007f1:	8b 5d fc             	mov    -0x4(%ebp),%ebx
  8007f4:	c9                   	leave  
  8007f5:	c3                   	ret    

008007f6 <strncpy>:

char *
strncpy(char *dst, const char *src, size_t size) {
  8007f6:	55                   	push   %ebp
  8007f7:	89 e5                	mov    %esp,%ebp
  8007f9:	56                   	push   %esi
  8007fa:	53                   	push   %ebx
  8007fb:	8b 75 08             	mov    0x8(%ebp),%esi
  8007fe:	8b 4d 0c             	mov    0xc(%ebp),%ecx
  800801:	89 f3                	mov    %esi,%ebx
  800803:	03 5d 10             	add    0x10(%ebp),%ebx
	size_t i;
	char *ret;

	ret = dst;
	for (i = 0; i < size; i++) {
  800806:	89 f2                	mov    %esi,%edx
  800808:	eb 0f                	jmp    800819 <strncpy+0x23>
		*dst++ = *src;
  80080a:	83 c2 01             	add    $0x1,%edx
  80080d:	0f b6 01             	movzbl (%ecx),%eax
  800810:	88 42 ff             	mov    %al,-0x1(%edx)
		// If strlen(src) < size, null-pad 'dst' out to 'size' chars
		if (*src != '\0')
			src++;
  800813:	80 39 01             	cmpb   $0x1,(%ecx)
  800816:	83 d9 ff             	sbb    $0xffffffff,%ecx
strncpy(char *dst, const char *src, size_t size) {
	size_t i;
	char *ret;

	ret = dst;
	for (i = 0; i < size; i++) {
  800819:	39 da                	cmp    %ebx,%edx
  80081b:	75 ed                	jne    80080a <strncpy+0x14>
		// If strlen(src) < size, null-pad 'dst' out to 'size' chars
		if (*src != '\0')
			src++;
	}
	return ret;
}
  80081d:	89 f0                	mov    %esi,%eax
  80081f:	5b                   	pop    %ebx
  800820:	5e                   	pop    %esi
  800821:	5d                   	pop    %ebp
  800822:	c3                   	ret    

00800823 <strlcpy>:

size_t
strlcpy(char *dst, const char *src, size_t size)
{
  800823:	55                   	push   %ebp
  800824:	89 e5                	mov    %esp,%ebp
  800826:	56                   	push   %esi
  800827:	53                   	push   %ebx
  800828:	8b 75 08             	mov    0x8(%ebp),%esi
  80082b:	8b 4d 0c             	mov    0xc(%ebp),%ecx
  80082e:	8b 55 10             	mov    0x10(%ebp),%edx
  800831:	89 f0                	mov    %esi,%eax
	char *dst_in;

	dst_in = dst;
	if (size > 0) {
  800833:	85 d2                	test   %edx,%edx
  800835:	74 21                	je     800858 <strlcpy+0x35>
  800837:	8d 44 16 ff          	lea    -0x1(%esi,%edx,1),%eax
  80083b:	89 f2                	mov    %esi,%edx
  80083d:	eb 09                	jmp    800848 <strlcpy+0x25>
		while (--size > 0 && *src != '\0')
			*dst++ = *src++;
  80083f:	83 c2 01             	add    $0x1,%edx
  800842:	83 c1 01             	add    $0x1,%ecx
  800845:	88 5a ff             	mov    %bl,-0x1(%edx)
{
	char *dst_in;

	dst_in = dst;
	if (size > 0) {
		while (--size > 0 && *src != '\0')
  800848:	39 c2                	cmp    %eax,%edx
  80084a:	74 09                	je     800855 <strlcpy+0x32>
  80084c:	0f b6 19             	movzbl (%ecx),%ebx
  80084f:	84 db                	test   %bl,%bl
  800851:	75 ec                	jne    80083f <strlcpy+0x1c>
  800853:	89 d0                	mov    %edx,%eax
			*dst++ = *src++;
		*dst = '\0';
  800855:	c6 00 00             	movb   $0x0,(%eax)
	}
	return dst - dst_in;
  800858:	29 f0                	sub    %esi,%eax
}
  80085a:	5b                   	pop    %ebx
  80085b:	5e                   	pop    %esi
  80085c:	5d                   	pop    %ebp
  80085d:	c3                   	ret    

0080085e <strcmp>:

int
strcmp(const char *p, const char *q)
{
  80085e:	55                   	push   %ebp
  80085f:	89 e5                	mov    %esp,%ebp
  800861:	8b 4d 08             	mov    0x8(%ebp),%ecx
  800864:	8b 55 0c             	mov    0xc(%ebp),%edx
	while (*p && *p == *q)
  800867:	eb 06                	jmp    80086f <strcmp+0x11>
		p++, q++;
  800869:	83 c1 01             	add    $0x1,%ecx
  80086c:	83 c2 01             	add    $0x1,%edx
}

int
strcmp(const char *p, const char *q)
{
	while (*p && *p == *q)
  80086f:	0f b6 01             	movzbl (%ecx),%eax
  800872:	84 c0                	test   %al,%al
  800874:	74 04                	je     80087a <strcmp+0x1c>
  800876:	3a 02                	cmp    (%edx),%al
  800878:	74 ef                	je     800869 <strcmp+0xb>
		p++, q++;
	return (int) ((unsigned char) *p - (unsigned char) *q);
  80087a:	0f b6 c0             	movzbl %al,%eax
  80087d:	0f b6 12             	movzbl (%edx),%edx
  800880:	29 d0                	sub    %edx,%eax
}
  800882:	5d                   	pop    %ebp
  800883:	c3                   	ret    

00800884 <strncmp>:

int
strncmp(const char *p, const char *q, size_t n)
{
  800884:	55                   	push   %ebp
  800885:	89 e5                	mov    %esp,%ebp
  800887:	53                   	push   %ebx
  800888:	8b 45 08             	mov    0x8(%ebp),%eax
  80088b:	8b 55 0c             	mov    0xc(%ebp),%edx
  80088e:	89 c3                	mov    %eax,%ebx
  800890:	03 5d 10             	add    0x10(%ebp),%ebx
	while (n > 0 && *p && *p == *q)
  800893:	eb 06                	jmp    80089b <strncmp+0x17>
		n--, p++, q++;
  800895:	83 c0 01             	add    $0x1,%eax
  800898:	83 c2 01             	add    $0x1,%edx
}

int
strncmp(const char *p, const char *q, size_t n)
{
	while (n > 0 && *p && *p == *q)
  80089b:	39 d8                	cmp    %ebx,%eax
  80089d:	74 15                	je     8008b4 <strncmp+0x30>
  80089f:	0f b6 08             	movzbl (%eax),%ecx
  8008a2:	84 c9                	test   %cl,%cl
  8008a4:	74 04                	je     8008aa <strncmp+0x26>
  8008a6:	3a 0a                	cmp    (%edx),%cl
  8008a8:	74 eb                	je     800895 <strncmp+0x11>
		n--, p++, q++;
	if (n == 0)
		return 0;
	else
		return (int) ((unsigned char) *p - (unsigned char) *q);
  8008aa:	0f b6 00             	movzbl (%eax),%eax
  8008ad:	0f b6 12             	movzbl (%edx),%edx
  8008b0:	29 d0                	sub    %edx,%eax
  8008b2:	eb 05                	jmp    8008b9 <strncmp+0x35>
strncmp(const char *p, const char *q, size_t n)
{
	while (n > 0 && *p && *p == *q)
		n--, p++, q++;
	if (n == 0)
		return 0;
  8008b4:	b8 00 00 00 00       	mov    $0x0,%eax
	else
		return (int) ((unsigned char) *p - (unsigned char) *q);
}
  8008b9:	5b                   	pop    %ebx
  8008ba:	5d                   	pop    %ebp
  8008bb:	c3                   	ret    

008008bc <strchr>:

// Return a pointer to the first occurrence of 'c' in 's',
// or a null pointer if the string has no 'c'.
char *
strchr(const char *s, char c)
{
  8008bc:	55                   	push   %ebp
  8008bd:	89 e5                	mov    %esp,%ebp
  8008bf:	8b 45 08             	mov    0x8(%ebp),%eax
  8008c2:	0f b6 4d 0c          	movzbl 0xc(%ebp),%ecx
	for (; *s; s++)
  8008c6:	eb 07                	jmp    8008cf <strchr+0x13>
		if (*s == c)
  8008c8:	38 ca                	cmp    %cl,%dl
  8008ca:	74 0f                	je     8008db <strchr+0x1f>
// Return a pointer to the first occurrence of 'c' in 's',
// or a null pointer if the string has no 'c'.
char *
strchr(const char *s, char c)
{
	for (; *s; s++)
  8008cc:	83 c0 01             	add    $0x1,%eax
  8008cf:	0f b6 10             	movzbl (%eax),%edx
  8008d2:	84 d2                	test   %dl,%dl
  8008d4:	75 f2                	jne    8008c8 <strchr+0xc>
		if (*s == c)
			return (char *) s;
	return 0;
  8008d6:	b8 00 00 00 00       	mov    $0x0,%eax
}
  8008db:	5d                   	pop    %ebp
  8008dc:	c3                   	ret    

008008dd <strfind>:

// Return a pointer to the first occurrence of 'c' in 's',
// or a pointer to the string-ending null character if the string has no 'c'.
char *
strfind(const char *s, char c)
{
  8008dd:	55                   	push   %ebp
  8008de:	89 e5                	mov    %esp,%ebp
  8008e0:	8b 45 08             	mov    0x8(%ebp),%eax
  8008e3:	0f b6 4d 0c          	movzbl 0xc(%ebp),%ecx
	for (; *s; s++)
  8008e7:	eb 03                	jmp    8008ec <strfind+0xf>
  8008e9:	83 c0 01             	add    $0x1,%eax
  8008ec:	0f b6 10             	movzbl (%eax),%edx
		if (*s == c)
  8008ef:	38 ca                	cmp    %cl,%dl
  8008f1:	74 04                	je     8008f7 <strfind+0x1a>
  8008f3:	84 d2                	test   %dl,%dl
  8008f5:	75 f2                	jne    8008e9 <strfind+0xc>
			break;
	return (char *) s;
}
  8008f7:	5d                   	pop    %ebp
  8008f8:	c3                   	ret    

008008f9 <memset>:

#if ASM
void *
memset(void *v, int c, size_t n)
{
  8008f9:	55                   	push   %ebp
  8008fa:	89 e5                	mov    %esp,%ebp
  8008fc:	57                   	push   %edi
  8008fd:	56                   	push   %esi
  8008fe:	53                   	push   %ebx
  8008ff:	8b 55 08             	mov    0x8(%ebp),%edx
  800902:	8b 4d 10             	mov    0x10(%ebp),%ecx
	char *p = v;

	if (n == 0)
  800905:	85 c9                	test   %ecx,%ecx
  800907:	74 37                	je     800940 <memset+0x47>
		return v;
	if ((int)v%4 == 0 && n%4 == 0) {
  800909:	f6 c2 03             	test   $0x3,%dl
  80090c:	75 2a                	jne    800938 <memset+0x3f>
  80090e:	f6 c1 03             	test   $0x3,%cl
  800911:	75 25                	jne    800938 <memset+0x3f>
		c &= 0xFF;
  800913:	0f b6 5d 0c          	movzbl 0xc(%ebp),%ebx
		c = (c<<24)|(c<<16)|(c<<8)|c;
  800917:	89 df                	mov    %ebx,%edi
  800919:	c1 e7 08             	shl    $0x8,%edi
  80091c:	89 de                	mov    %ebx,%esi
  80091e:	c1 e6 18             	shl    $0x18,%esi
  800921:	89 d8                	mov    %ebx,%eax
  800923:	c1 e0 10             	shl    $0x10,%eax
  800926:	09 f0                	or     %esi,%eax
  800928:	09 c3                	or     %eax,%ebx
		asm volatile("cld; rep stosl\n"
			: "=D" (p), "=c" (n)
			: "D" (p), "a" (c), "c" (n/4)
  80092a:	c1 e9 02             	shr    $0x2,%ecx
	if (n == 0)
		return v;
	if ((int)v%4 == 0 && n%4 == 0) {
		c &= 0xFF;
		c = (c<<24)|(c<<16)|(c<<8)|c;
		asm volatile("cld; rep stosl\n"
  80092d:	89 f8                	mov    %edi,%eax
  80092f:	09 d8                	or     %ebx,%eax
  800931:	89 d7                	mov    %edx,%edi
  800933:	fc                   	cld    
  800934:	f3 ab                	rep stos %eax,%es:(%edi)
  800936:	eb 08                	jmp    800940 <memset+0x47>
			: "=D" (p), "=c" (n)
			: "D" (p), "a" (c), "c" (n/4)
			: "cc", "memory");
	} else
		asm volatile("cld; rep stosb\n"
  800938:	89 d7                	mov    %edx,%edi
  80093a:	8b 45 0c             	mov    0xc(%ebp),%eax
  80093d:	fc                   	cld    
  80093e:	f3 aa                	rep stos %al,%es:(%edi)
			: "=D" (p), "=c" (n)
			: "0" (p), "a" (c), "1" (n)
			: "cc", "memory");
	return v;
}
  800940:	89 d0                	mov    %edx,%eax
  800942:	5b                   	pop    %ebx
  800943:	5e                   	pop    %esi
  800944:	5f                   	pop    %edi
  800945:	5d                   	pop    %ebp
  800946:	c3                   	ret    

00800947 <memmove>:

void *
memmove(void *dst, const void *src, size_t n)
{
  800947:	55                   	push   %ebp
  800948:	89 e5                	mov    %esp,%ebp
  80094a:	57                   	push   %edi
  80094b:	56                   	push   %esi
  80094c:	8b 45 08             	mov    0x8(%ebp),%eax
  80094f:	8b 75 0c             	mov    0xc(%ebp),%esi
  800952:	8b 4d 10             	mov    0x10(%ebp),%ecx
	const char *s;
	char *d;

	s = src;
	d = dst;
	if (s < d && s + n > d) {
  800955:	39 c6                	cmp    %eax,%esi
  800957:	73 35                	jae    80098e <memmove+0x47>
  800959:	8d 14 0e             	lea    (%esi,%ecx,1),%edx
  80095c:	39 d0                	cmp    %edx,%eax
  80095e:	73 2e                	jae    80098e <memmove+0x47>
		s += n;
		d += n;
  800960:	8d 3c 08             	lea    (%eax,%ecx,1),%edi
		if ((int)s%4 == 0 && (int)d%4 == 0 && n%4 == 0)
  800963:	89 d6                	mov    %edx,%esi
  800965:	09 fe                	or     %edi,%esi
  800967:	f7 c6 03 00 00 00    	test   $0x3,%esi
  80096d:	75 13                	jne    800982 <memmove+0x3b>
  80096f:	f6 c1 03             	test   $0x3,%cl
  800972:	75 0e                	jne    800982 <memmove+0x3b>
			asm volatile("std; rep movsl\n"
  800974:	83 ef 04             	sub    $0x4,%edi
  800977:	8d 72 fc             	lea    -0x4(%edx),%esi
  80097a:	c1 e9 02             	shr    $0x2,%ecx
  80097d:	fd                   	std    
  80097e:	f3 a5                	rep movsl %ds:(%esi),%es:(%edi)
  800980:	eb 09                	jmp    80098b <memmove+0x44>
				:: "D" (d-4), "S" (s-4), "c" (n/4) : "cc", "memory");
		else
			asm volatile("std; rep movsb\n"
  800982:	83 ef 01             	sub    $0x1,%edi
  800985:	8d 72 ff             	lea    -0x1(%edx),%esi
  800988:	fd                   	std    
  800989:	f3 a4                	rep movsb %ds:(%esi),%es:(%edi)
				:: "D" (d-1), "S" (s-1), "c" (n) : "cc", "memory");
		// Some versions of GCC rely on DF being clear
		asm volatile("cld" ::: "cc");
  80098b:	fc                   	cld    
  80098c:	eb 1d                	jmp    8009ab <memmove+0x64>
	} else {
		if ((int)s%4 == 0 && (int)d%4 == 0 && n%4 == 0)
  80098e:	89 f2                	mov    %esi,%edx
  800990:	09 c2                	or     %eax,%edx
  800992:	f6 c2 03             	test   $0x3,%dl
  800995:	75 0f                	jne    8009a6 <memmove+0x5f>
  800997:	f6 c1 03             	test   $0x3,%cl
  80099a:	75 0a                	jne    8009a6 <memmove+0x5f>
			asm volatile("cld; rep movsl\n"
  80099c:	c1 e9 02             	shr    $0x2,%ecx
  80099f:	89 c7                	mov    %eax,%edi
  8009a1:	fc                   	cld    
  8009a2:	f3 a5                	rep movsl %ds:(%esi),%es:(%edi)
  8009a4:	eb 05                	jmp    8009ab <memmove+0x64>
				:: "D" (d), "S" (s), "c" (n/4) : "cc", "memory");
		else
			asm volatile("cld; rep movsb\n"
  8009a6:	89 c7                	mov    %eax,%edi
  8009a8:	fc                   	cld    
  8009a9:	f3 a4                	rep movsb %ds:(%esi),%es:(%edi)
				:: "D" (d), "S" (s), "c" (n) : "cc", "memory");
	}
	return dst;
}
  8009ab:	5e                   	pop    %esi
  8009ac:	5f                   	pop    %edi
  8009ad:	5d                   	pop    %ebp
  8009ae:	c3                   	ret    

008009af <memcpy>:
}
#endif

void *
memcpy(void *dst, const void *src, size_t n)
{
  8009af:	55                   	push   %ebp
  8009b0:	89 e5                	mov    %esp,%ebp
	return memmove(dst, src, n);
  8009b2:	ff 75 10             	pushl  0x10(%ebp)
  8009b5:	ff 75 0c             	pushl  0xc(%ebp)
  8009b8:	ff 75 08             	pushl  0x8(%ebp)
  8009bb:	e8 87 ff ff ff       	call   800947 <memmove>
}
  8009c0:	c9                   	leave  
  8009c1:	c3                   	ret    

008009c2 <memcmp>:

int
memcmp(const void *v1, const void *v2, size_t n)
{
  8009c2:	55                   	push   %ebp
  8009c3:	89 e5                	mov    %esp,%ebp
  8009c5:	56                   	push   %esi
  8009c6:	53                   	push   %ebx
  8009c7:	8b 45 08             	mov    0x8(%ebp),%eax
  8009ca:	8b 55 0c             	mov    0xc(%ebp),%edx
  8009cd:	89 c6                	mov    %eax,%esi
  8009cf:	03 75 10             	add    0x10(%ebp),%esi
	const uint8_t *s1 = (const uint8_t *) v1;
	const uint8_t *s2 = (const uint8_t *) v2;

	while (n-- > 0) {
  8009d2:	eb 1a                	jmp    8009ee <memcmp+0x2c>
		if (*s1 != *s2)
  8009d4:	0f b6 08             	movzbl (%eax),%ecx
  8009d7:	0f b6 1a             	movzbl (%edx),%ebx
  8009da:	38 d9                	cmp    %bl,%cl
  8009dc:	74 0a                	je     8009e8 <memcmp+0x26>
			return (int) *s1 - (int) *s2;
  8009de:	0f b6 c1             	movzbl %cl,%eax
  8009e1:	0f b6 db             	movzbl %bl,%ebx
  8009e4:	29 d8                	sub    %ebx,%eax
  8009e6:	eb 0f                	jmp    8009f7 <memcmp+0x35>
		s1++, s2++;
  8009e8:	83 c0 01             	add    $0x1,%eax
  8009eb:	83 c2 01             	add    $0x1,%edx
memcmp(const void *v1, const void *v2, size_t n)
{
	const uint8_t *s1 = (const uint8_t *) v1;
	const uint8_t *s2 = (const uint8_t *) v2;

	while (n-- > 0) {
  8009ee:	39 f0                	cmp    %esi,%eax
  8009f0:	75 e2                	jne    8009d4 <memcmp+0x12>
		if (*s1 != *s2)
			return (int) *s1 - (int) *s2;
		s1++, s2++;
	}

	return 0;
  8009f2:	b8 00 00 00 00       	mov    $0x0,%eax
}
  8009f7:	5b                   	pop    %ebx
  8009f8:	5e                   	pop    %esi
  8009f9:	5d                   	pop    %ebp
  8009fa:	c3                   	ret    

008009fb <memfind>:

void *
memfind(const void *s, int c, size_t n)
{
  8009fb:	55                   	push   %ebp
  8009fc:	89 e5                	mov    %esp,%ebp
  8009fe:	53                   	push   %ebx
  8009ff:	8b 45 08             	mov    0x8(%ebp),%eax
	const void *ends = (const char *) s + n;
  800a02:	89 c1                	mov    %eax,%ecx
  800a04:	03 4d 10             	add    0x10(%ebp),%ecx
	for (; s < ends; s++)
		if (*(const unsigned char *) s == (unsigned char) c)
  800a07:	0f b6 5d 0c          	movzbl 0xc(%ebp),%ebx

void *
memfind(const void *s, int c, size_t n)
{
	const void *ends = (const char *) s + n;
	for (; s < ends; s++)
  800a0b:	eb 0a                	jmp    800a17 <memfind+0x1c>
		if (*(const unsigned char *) s == (unsigned char) c)
  800a0d:	0f b6 10             	movzbl (%eax),%edx
  800a10:	39 da                	cmp    %ebx,%edx
  800a12:	74 07                	je     800a1b <memfind+0x20>

void *
memfind(const void *s, int c, size_t n)
{
	const void *ends = (const char *) s + n;
	for (; s < ends; s++)
  800a14:	83 c0 01             	add    $0x1,%eax
  800a17:	39 c8                	cmp    %ecx,%eax
  800a19:	72 f2                	jb     800a0d <memfind+0x12>
		if (*(const unsigned char *) s == (unsigned char) c)
			break;
	return (void *) s;
}
  800a1b:	5b                   	pop    %ebx
  800a1c:	5d                   	pop    %ebp
  800a1d:	c3                   	ret    

00800a1e <strtol>:

long
strtol(const char *s, char **endptr, int base)
{
  800a1e:	55                   	push   %ebp
  800a1f:	89 e5                	mov    %esp,%ebp
  800a21:	57                   	push   %edi
  800a22:	56                   	push   %esi
  800a23:	53                   	push   %ebx
  800a24:	8b 4d 08             	mov    0x8(%ebp),%ecx
  800a27:	8b 5d 10             	mov    0x10(%ebp),%ebx
	int neg = 0;
	long val = 0;

	// gobble initial whitespace
	while (*s == ' ' || *s == '\t')
  800a2a:	eb 03                	jmp    800a2f <strtol+0x11>
		s++;
  800a2c:	83 c1 01             	add    $0x1,%ecx
{
	int neg = 0;
	long val = 0;

	// gobble initial whitespace
	while (*s == ' ' || *s == '\t')
  800a2f:	0f b6 01             	movzbl (%ecx),%eax
  800a32:	3c 20                	cmp    $0x20,%al
  800a34:	74 f6                	je     800a2c <strtol+0xe>
  800a36:	3c 09                	cmp    $0x9,%al
  800a38:	74 f2                	je     800a2c <strtol+0xe>
		s++;

	// plus/minus sign
	if (*s == '+')
  800a3a:	3c 2b                	cmp    $0x2b,%al
  800a3c:	75 0a                	jne    800a48 <strtol+0x2a>
		s++;
  800a3e:	83 c1 01             	add    $0x1,%ecx
}

long
strtol(const char *s, char **endptr, int base)
{
	int neg = 0;
  800a41:	bf 00 00 00 00       	mov    $0x0,%edi
  800a46:	eb 11                	jmp    800a59 <strtol+0x3b>
  800a48:	bf 00 00 00 00       	mov    $0x0,%edi
		s++;

	// plus/minus sign
	if (*s == '+')
		s++;
	else if (*s == '-')
  800a4d:	3c 2d                	cmp    $0x2d,%al
  800a4f:	75 08                	jne    800a59 <strtol+0x3b>
		s++, neg = 1;
  800a51:	83 c1 01             	add    $0x1,%ecx
  800a54:	bf 01 00 00 00       	mov    $0x1,%edi

	// hex or octal base prefix
	if ((base == 0 || base == 16) && (s[0] == '0' && s[1] == 'x'))
  800a59:	f7 c3 ef ff ff ff    	test   $0xffffffef,%ebx
  800a5f:	75 15                	jne    800a76 <strtol+0x58>
  800a61:	80 39 30             	cmpb   $0x30,(%ecx)
  800a64:	75 10                	jne    800a76 <strtol+0x58>
  800a66:	80 79 01 78          	cmpb   $0x78,0x1(%ecx)
  800a6a:	75 7c                	jne    800ae8 <strtol+0xca>
		s += 2, base = 16;
  800a6c:	83 c1 02             	add    $0x2,%ecx
  800a6f:	bb 10 00 00 00       	mov    $0x10,%ebx
  800a74:	eb 16                	jmp    800a8c <strtol+0x6e>
	else if (base == 0 && s[0] == '0')
  800a76:	85 db                	test   %ebx,%ebx
  800a78:	75 12                	jne    800a8c <strtol+0x6e>
		s++, base = 8;
	else if (base == 0)
		base = 10;
  800a7a:	bb 0a 00 00 00       	mov    $0xa,%ebx
		s++, neg = 1;

	// hex or octal base prefix
	if ((base == 0 || base == 16) && (s[0] == '0' && s[1] == 'x'))
		s += 2, base = 16;
	else if (base == 0 && s[0] == '0')
  800a7f:	80 39 30             	cmpb   $0x30,(%ecx)
  800a82:	75 08                	jne    800a8c <strtol+0x6e>
		s++, base = 8;
  800a84:	83 c1 01             	add    $0x1,%ecx
  800a87:	bb 08 00 00 00       	mov    $0x8,%ebx
	else if (base == 0)
		base = 10;
  800a8c:	b8 00 00 00 00       	mov    $0x0,%eax
  800a91:	89 5d 10             	mov    %ebx,0x10(%ebp)

	// digits
	while (1) {
		int dig;

		if (*s >= '0' && *s <= '9')
  800a94:	0f b6 11             	movzbl (%ecx),%edx
  800a97:	8d 72 d0             	lea    -0x30(%edx),%esi
  800a9a:	89 f3                	mov    %esi,%ebx
  800a9c:	80 fb 09             	cmp    $0x9,%bl
  800a9f:	77 08                	ja     800aa9 <strtol+0x8b>
			dig = *s - '0';
  800aa1:	0f be d2             	movsbl %dl,%edx
  800aa4:	83 ea 30             	sub    $0x30,%edx
  800aa7:	eb 22                	jmp    800acb <strtol+0xad>
		else if (*s >= 'a' && *s <= 'z')
  800aa9:	8d 72 9f             	lea    -0x61(%edx),%esi
  800aac:	89 f3                	mov    %esi,%ebx
  800aae:	80 fb 19             	cmp    $0x19,%bl
  800ab1:	77 08                	ja     800abb <strtol+0x9d>
			dig = *s - 'a' + 10;
  800ab3:	0f be d2             	movsbl %dl,%edx
  800ab6:	83 ea 57             	sub    $0x57,%edx
  800ab9:	eb 10                	jmp    800acb <strtol+0xad>
		else if (*s >= 'A' && *s <= 'Z')
  800abb:	8d 72 bf             	lea    -0x41(%edx),%esi
  800abe:	89 f3                	mov    %esi,%ebx
  800ac0:	80 fb 19             	cmp    $0x19,%bl
  800ac3:	77 16                	ja     800adb <strtol+0xbd>
			dig = *s - 'A' + 10;
  800ac5:	0f be d2             	movsbl %dl,%edx
  800ac8:	83 ea 37             	sub    $0x37,%edx
		else
			break;
		if (dig >= base)
  800acb:	3b 55 10             	cmp    0x10(%ebp),%edx
  800ace:	7d 0b                	jge    800adb <strtol+0xbd>
			break;
		s++, val = (val * base) + dig;
  800ad0:	83 c1 01             	add    $0x1,%ecx
  800ad3:	0f af 45 10          	imul   0x10(%ebp),%eax
  800ad7:	01 d0                	add    %edx,%eax
		// we don't properly detect overflow!
	}
  800ad9:	eb b9                	jmp    800a94 <strtol+0x76>

	if (endptr)
  800adb:	83 7d 0c 00          	cmpl   $0x0,0xc(%ebp)
  800adf:	74 0d                	je     800aee <strtol+0xd0>
		*endptr = (char *) s;
  800ae1:	8b 75 0c             	mov    0xc(%ebp),%esi
  800ae4:	89 0e                	mov    %ecx,(%esi)
  800ae6:	eb 06                	jmp    800aee <strtol+0xd0>
		s++, neg = 1;

	// hex or octal base prefix
	if ((base == 0 || base == 16) && (s[0] == '0' && s[1] == 'x'))
		s += 2, base = 16;
	else if (base == 0 && s[0] == '0')
  800ae8:	85 db                	test   %ebx,%ebx
  800aea:	74 98                	je     800a84 <strtol+0x66>
  800aec:	eb 9e                	jmp    800a8c <strtol+0x6e>
		// we don't properly detect overflow!
	}

	if (endptr)
		*endptr = (char *) s;
	return (neg ? -val : val);
  800aee:	89 c2                	mov    %eax,%edx
  800af0:	f7 da                	neg    %edx
  800af2:	85 ff                	test   %edi,%edi
  800af4:	0f 45 c2             	cmovne %edx,%eax
}
  800af7:	5b                   	pop    %ebx
  800af8:	5e                   	pop    %esi
  800af9:	5f                   	pop    %edi
  800afa:	5d                   	pop    %ebp
  800afb:	c3                   	ret    
  800afc:	66 90                	xchg   %ax,%ax
  800afe:	66 90                	xchg   %ax,%ax

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
