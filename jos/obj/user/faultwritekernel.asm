
obj/user/faultwritekernel:     file format elf32-i386


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
  80002c:	e8 11 00 00 00       	call   800042 <libmain>
1:	jmp 1b
  800031:	eb fe                	jmp    800031 <args_exist+0x5>

00800033 <umain>:

#include <inc/lib.h>

void
umain(int argc, char **argv)
{
  800033:	55                   	push   %ebp
  800034:	89 e5                	mov    %esp,%ebp
	*(unsigned*)0xf0100000 = 0;
  800036:	c7 05 00 00 10 f0 00 	movl   $0x0,0xf0100000
  80003d:	00 00 00 
}
  800040:	5d                   	pop    %ebp
  800041:	c3                   	ret    

00800042 <libmain>:
const volatile struct Env *thisenv;
const char *binaryname = "<unknown>";

void
libmain(int argc, char **argv)
{
  800042:	55                   	push   %ebp
  800043:	89 e5                	mov    %esp,%ebp
  800045:	83 ec 08             	sub    $0x8,%esp
  800048:	8b 45 08             	mov    0x8(%ebp),%eax
  80004b:	8b 55 0c             	mov    0xc(%ebp),%edx
	// set thisenv to point at our Env structure in envs[].
	// LAB 3: Your code here.
	thisenv = 0;
  80004e:	c7 05 04 10 80 00 00 	movl   $0x0,0x801004
  800055:	00 00 00 

	// save the name of the program so that panic() can use it
	if (argc > 0)
  800058:	85 c0                	test   %eax,%eax
  80005a:	7e 08                	jle    800064 <libmain+0x22>
		binaryname = argv[0];
  80005c:	8b 0a                	mov    (%edx),%ecx
  80005e:	89 0d 00 10 80 00    	mov    %ecx,0x801000

	// call user main routine
	umain(argc, argv);
  800064:	83 ec 08             	sub    $0x8,%esp
  800067:	52                   	push   %edx
  800068:	50                   	push   %eax
  800069:	e8 c5 ff ff ff       	call   800033 <umain>

	// exit gracefully
	exit();
  80006e:	e8 05 00 00 00       	call   800078 <exit>
}
  800073:	83 c4 10             	add    $0x10,%esp
  800076:	c9                   	leave  
  800077:	c3                   	ret    

00800078 <exit>:

#include <inc/lib.h>

void
exit(void)
{
  800078:	55                   	push   %ebp
  800079:	89 e5                	mov    %esp,%ebp
  80007b:	83 ec 14             	sub    $0x14,%esp
	sys_env_destroy(0);
  80007e:	6a 00                	push   $0x0
  800080:	e8 99 00 00 00       	call   80011e <sys_env_destroy>
}
  800085:	83 c4 10             	add    $0x10,%esp
  800088:	c9                   	leave  
  800089:	c3                   	ret    

0080008a <syscall>:
#include <inc/syscall.h>
#include <inc/lib.h>

static inline int32_t
syscall(int num, int check, uint32_t a1, uint32_t a2, uint32_t a3, uint32_t a4, uint32_t a5)
{
  80008a:	55                   	push   %ebp
  80008b:	89 e5                	mov    %esp,%ebp
  80008d:	57                   	push   %edi
  80008e:	56                   	push   %esi
  80008f:	53                   	push   %ebx
  800090:	83 ec 1c             	sub    $0x1c,%esp
  800093:	89 45 e0             	mov    %eax,-0x20(%ebp)
  800096:	89 55 e4             	mov    %edx,-0x1c(%ebp)
  800099:	89 ca                	mov    %ecx,%edx
	//
	// The last clause tells the assembler that this can
	// potentially change the condition codes and arbitrary
	// memory locations.

	asm volatile("int %1\n"
  80009b:	8b 4d 08             	mov    0x8(%ebp),%ecx
  80009e:	8b 5d 0c             	mov    0xc(%ebp),%ebx
  8000a1:	8b 7d 10             	mov    0x10(%ebp),%edi
  8000a4:	8b 75 14             	mov    0x14(%ebp),%esi
  8000a7:	cd 30                	int    $0x30
		       "b" (a3),
		       "D" (a4),
		       "S" (a5)
		     : "cc", "memory");

	if(check && ret > 0)
  8000a9:	83 7d e4 00          	cmpl   $0x0,-0x1c(%ebp)
  8000ad:	74 1d                	je     8000cc <syscall+0x42>
  8000af:	85 c0                	test   %eax,%eax
  8000b1:	7e 19                	jle    8000cc <syscall+0x42>
  8000b3:	8b 55 e0             	mov    -0x20(%ebp),%edx
		panic("syscall %d returned %d (> 0)", num, ret);
  8000b6:	83 ec 0c             	sub    $0xc,%esp
  8000b9:	50                   	push   %eax
  8000ba:	52                   	push   %edx
  8000bb:	68 8e 0d 80 00       	push   $0x800d8e
  8000c0:	6a 23                	push   $0x23
  8000c2:	68 ab 0d 80 00       	push   $0x800dab
  8000c7:	e8 98 00 00 00       	call   800164 <_panic>

	return ret;
}
  8000cc:	8d 65 f4             	lea    -0xc(%ebp),%esp
  8000cf:	5b                   	pop    %ebx
  8000d0:	5e                   	pop    %esi
  8000d1:	5f                   	pop    %edi
  8000d2:	5d                   	pop    %ebp
  8000d3:	c3                   	ret    

008000d4 <sys_cputs>:

void
sys_cputs(const char *s, size_t len)
{
  8000d4:	55                   	push   %ebp
  8000d5:	89 e5                	mov    %esp,%ebp
  8000d7:	83 ec 08             	sub    $0x8,%esp
	syscall(SYS_cputs, 0, (uint32_t)s, len, 0, 0, 0);
  8000da:	6a 00                	push   $0x0
  8000dc:	6a 00                	push   $0x0
  8000de:	6a 00                	push   $0x0
  8000e0:	ff 75 0c             	pushl  0xc(%ebp)
  8000e3:	8b 4d 08             	mov    0x8(%ebp),%ecx
  8000e6:	ba 00 00 00 00       	mov    $0x0,%edx
  8000eb:	b8 00 00 00 00       	mov    $0x0,%eax
  8000f0:	e8 95 ff ff ff       	call   80008a <syscall>
}
  8000f5:	83 c4 10             	add    $0x10,%esp
  8000f8:	c9                   	leave  
  8000f9:	c3                   	ret    

008000fa <sys_cgetc>:

int
sys_cgetc(void)
{
  8000fa:	55                   	push   %ebp
  8000fb:	89 e5                	mov    %esp,%ebp
  8000fd:	83 ec 08             	sub    $0x8,%esp
	return syscall(SYS_cgetc, 0, 0, 0, 0, 0, 0);
  800100:	6a 00                	push   $0x0
  800102:	6a 00                	push   $0x0
  800104:	6a 00                	push   $0x0
  800106:	6a 00                	push   $0x0
  800108:	b9 00 00 00 00       	mov    $0x0,%ecx
  80010d:	ba 00 00 00 00       	mov    $0x0,%edx
  800112:	b8 01 00 00 00       	mov    $0x1,%eax
  800117:	e8 6e ff ff ff       	call   80008a <syscall>
}
  80011c:	c9                   	leave  
  80011d:	c3                   	ret    

0080011e <sys_env_destroy>:

int
sys_env_destroy(envid_t envid)
{
  80011e:	55                   	push   %ebp
  80011f:	89 e5                	mov    %esp,%ebp
  800121:	83 ec 08             	sub    $0x8,%esp
	return syscall(SYS_env_destroy, 1, envid, 0, 0, 0, 0);
  800124:	6a 00                	push   $0x0
  800126:	6a 00                	push   $0x0
  800128:	6a 00                	push   $0x0
  80012a:	6a 00                	push   $0x0
  80012c:	8b 4d 08             	mov    0x8(%ebp),%ecx
  80012f:	ba 01 00 00 00       	mov    $0x1,%edx
  800134:	b8 03 00 00 00       	mov    $0x3,%eax
  800139:	e8 4c ff ff ff       	call   80008a <syscall>
}
  80013e:	c9                   	leave  
  80013f:	c3                   	ret    

00800140 <sys_getenvid>:

envid_t
sys_getenvid(void)
{
  800140:	55                   	push   %ebp
  800141:	89 e5                	mov    %esp,%ebp
  800143:	83 ec 08             	sub    $0x8,%esp
	 return syscall(SYS_getenvid, 0, 0, 0, 0, 0, 0);
  800146:	6a 00                	push   $0x0
  800148:	6a 00                	push   $0x0
  80014a:	6a 00                	push   $0x0
  80014c:	6a 00                	push   $0x0
  80014e:	b9 00 00 00 00       	mov    $0x0,%ecx
  800153:	ba 00 00 00 00       	mov    $0x0,%edx
  800158:	b8 02 00 00 00       	mov    $0x2,%eax
  80015d:	e8 28 ff ff ff       	call   80008a <syscall>
}
  800162:	c9                   	leave  
  800163:	c3                   	ret    

00800164 <_panic>:
 * It prints "panic: <message>", then causes a breakpoint exception,
 * which causes JOS to enter the JOS kernel monitor.
 */
void
_panic(const char *file, int line, const char *fmt, ...)
{
  800164:	55                   	push   %ebp
  800165:	89 e5                	mov    %esp,%ebp
  800167:	56                   	push   %esi
  800168:	53                   	push   %ebx
	va_list ap;

	va_start(ap, fmt);
  800169:	8d 5d 14             	lea    0x14(%ebp),%ebx

	// Print the panic message
	cprintf("[%08x] user panic in %s at %s:%d: ",
  80016c:	8b 35 00 10 80 00    	mov    0x801000,%esi
  800172:	e8 c9 ff ff ff       	call   800140 <sys_getenvid>
  800177:	83 ec 0c             	sub    $0xc,%esp
  80017a:	ff 75 0c             	pushl  0xc(%ebp)
  80017d:	ff 75 08             	pushl  0x8(%ebp)
  800180:	56                   	push   %esi
  800181:	50                   	push   %eax
  800182:	68 bc 0d 80 00       	push   $0x800dbc
  800187:	e8 b1 00 00 00       	call   80023d <cprintf>
		sys_getenvid(), binaryname, file, line);
	vcprintf(fmt, ap);
  80018c:	83 c4 18             	add    $0x18,%esp
  80018f:	53                   	push   %ebx
  800190:	ff 75 10             	pushl  0x10(%ebp)
  800193:	e8 54 00 00 00       	call   8001ec <vcprintf>
	cprintf("\n");
  800198:	c7 04 24 e0 0d 80 00 	movl   $0x800de0,(%esp)
  80019f:	e8 99 00 00 00       	call   80023d <cprintf>
  8001a4:	83 c4 10             	add    $0x10,%esp

	// Cause a breakpoint exception
	while (1)
		asm volatile("int3");
  8001a7:	cc                   	int3   
  8001a8:	eb fd                	jmp    8001a7 <_panic+0x43>

008001aa <putch>:
};


static void
putch(int ch, struct printbuf *b)
{
  8001aa:	55                   	push   %ebp
  8001ab:	89 e5                	mov    %esp,%ebp
  8001ad:	53                   	push   %ebx
  8001ae:	83 ec 04             	sub    $0x4,%esp
  8001b1:	8b 5d 0c             	mov    0xc(%ebp),%ebx
	b->buf[b->idx++] = ch;
  8001b4:	8b 13                	mov    (%ebx),%edx
  8001b6:	8d 42 01             	lea    0x1(%edx),%eax
  8001b9:	89 03                	mov    %eax,(%ebx)
  8001bb:	8b 4d 08             	mov    0x8(%ebp),%ecx
  8001be:	88 4c 13 08          	mov    %cl,0x8(%ebx,%edx,1)
	if (b->idx == 256-1) {
  8001c2:	3d ff 00 00 00       	cmp    $0xff,%eax
  8001c7:	75 1a                	jne    8001e3 <putch+0x39>
		sys_cputs(b->buf, b->idx);
  8001c9:	83 ec 08             	sub    $0x8,%esp
  8001cc:	68 ff 00 00 00       	push   $0xff
  8001d1:	8d 43 08             	lea    0x8(%ebx),%eax
  8001d4:	50                   	push   %eax
  8001d5:	e8 fa fe ff ff       	call   8000d4 <sys_cputs>
		b->idx = 0;
  8001da:	c7 03 00 00 00 00    	movl   $0x0,(%ebx)
  8001e0:	83 c4 10             	add    $0x10,%esp
	}
	b->cnt++;
  8001e3:	83 43 04 01          	addl   $0x1,0x4(%ebx)
}
  8001e7:	8b 5d fc             	mov    -0x4(%ebp),%ebx
  8001ea:	c9                   	leave  
  8001eb:	c3                   	ret    

008001ec <vcprintf>:

int
vcprintf(const char *fmt, va_list ap)
{
  8001ec:	55                   	push   %ebp
  8001ed:	89 e5                	mov    %esp,%ebp
  8001ef:	81 ec 18 01 00 00    	sub    $0x118,%esp
	struct printbuf b;

	b.idx = 0;
  8001f5:	c7 85 f0 fe ff ff 00 	movl   $0x0,-0x110(%ebp)
  8001fc:	00 00 00 
	b.cnt = 0;
  8001ff:	c7 85 f4 fe ff ff 00 	movl   $0x0,-0x10c(%ebp)
  800206:	00 00 00 
	vprintfmt((void*)putch, &b, fmt, ap);
  800209:	ff 75 0c             	pushl  0xc(%ebp)
  80020c:	ff 75 08             	pushl  0x8(%ebp)
  80020f:	8d 85 f0 fe ff ff    	lea    -0x110(%ebp),%eax
  800215:	50                   	push   %eax
  800216:	68 aa 01 80 00       	push   $0x8001aa
  80021b:	e8 86 01 00 00       	call   8003a6 <vprintfmt>
	sys_cputs(b.buf, b.idx);
  800220:	83 c4 08             	add    $0x8,%esp
  800223:	ff b5 f0 fe ff ff    	pushl  -0x110(%ebp)
  800229:	8d 85 f8 fe ff ff    	lea    -0x108(%ebp),%eax
  80022f:	50                   	push   %eax
  800230:	e8 9f fe ff ff       	call   8000d4 <sys_cputs>

	return b.cnt;
}
  800235:	8b 85 f4 fe ff ff    	mov    -0x10c(%ebp),%eax
  80023b:	c9                   	leave  
  80023c:	c3                   	ret    

0080023d <cprintf>:

int
cprintf(const char *fmt, ...)
{
  80023d:	55                   	push   %ebp
  80023e:	89 e5                	mov    %esp,%ebp
  800240:	83 ec 10             	sub    $0x10,%esp
	va_list ap;
	int cnt;

	va_start(ap, fmt);
  800243:	8d 45 0c             	lea    0xc(%ebp),%eax
	cnt = vcprintf(fmt, ap);
  800246:	50                   	push   %eax
  800247:	ff 75 08             	pushl  0x8(%ebp)
  80024a:	e8 9d ff ff ff       	call   8001ec <vcprintf>
	va_end(ap);

	return cnt;
}
  80024f:	c9                   	leave  
  800250:	c3                   	ret    

00800251 <printnum>:
 * using specified putch function and associated pointer putdat.
 */
static void
printnum(void (*putch)(int, void*), void *putdat,
	 unsigned long long num, unsigned base, int width, int padc)
{
  800251:	55                   	push   %ebp
  800252:	89 e5                	mov    %esp,%ebp
  800254:	57                   	push   %edi
  800255:	56                   	push   %esi
  800256:	53                   	push   %ebx
  800257:	83 ec 1c             	sub    $0x1c,%esp
  80025a:	89 c7                	mov    %eax,%edi
  80025c:	89 d6                	mov    %edx,%esi
  80025e:	8b 45 08             	mov    0x8(%ebp),%eax
  800261:	8b 55 0c             	mov    0xc(%ebp),%edx
  800264:	89 45 d8             	mov    %eax,-0x28(%ebp)
  800267:	89 55 dc             	mov    %edx,-0x24(%ebp)
	// first recursively print all preceding (more significant) digits
	if (num >= base) {
  80026a:	8b 4d 10             	mov    0x10(%ebp),%ecx
  80026d:	bb 00 00 00 00       	mov    $0x0,%ebx
  800272:	89 4d e0             	mov    %ecx,-0x20(%ebp)
  800275:	89 5d e4             	mov    %ebx,-0x1c(%ebp)
  800278:	39 d3                	cmp    %edx,%ebx
  80027a:	72 05                	jb     800281 <printnum+0x30>
  80027c:	39 45 10             	cmp    %eax,0x10(%ebp)
  80027f:	77 45                	ja     8002c6 <printnum+0x75>
		printnum(putch, putdat, num / base, base, width - 1, padc);
  800281:	83 ec 0c             	sub    $0xc,%esp
  800284:	ff 75 18             	pushl  0x18(%ebp)
  800287:	8b 45 14             	mov    0x14(%ebp),%eax
  80028a:	8d 58 ff             	lea    -0x1(%eax),%ebx
  80028d:	53                   	push   %ebx
  80028e:	ff 75 10             	pushl  0x10(%ebp)
  800291:	83 ec 08             	sub    $0x8,%esp
  800294:	ff 75 e4             	pushl  -0x1c(%ebp)
  800297:	ff 75 e0             	pushl  -0x20(%ebp)
  80029a:	ff 75 dc             	pushl  -0x24(%ebp)
  80029d:	ff 75 d8             	pushl  -0x28(%ebp)
  8002a0:	e8 5b 08 00 00       	call   800b00 <__udivdi3>
  8002a5:	83 c4 18             	add    $0x18,%esp
  8002a8:	52                   	push   %edx
  8002a9:	50                   	push   %eax
  8002aa:	89 f2                	mov    %esi,%edx
  8002ac:	89 f8                	mov    %edi,%eax
  8002ae:	e8 9e ff ff ff       	call   800251 <printnum>
  8002b3:	83 c4 20             	add    $0x20,%esp
  8002b6:	eb 18                	jmp    8002d0 <printnum+0x7f>
	} else {
		// print any needed pad characters before first digit
		while (--width > 0)
			putch(padc, putdat);
  8002b8:	83 ec 08             	sub    $0x8,%esp
  8002bb:	56                   	push   %esi
  8002bc:	ff 75 18             	pushl  0x18(%ebp)
  8002bf:	ff d7                	call   *%edi
  8002c1:	83 c4 10             	add    $0x10,%esp
  8002c4:	eb 03                	jmp    8002c9 <printnum+0x78>
  8002c6:	8b 5d 14             	mov    0x14(%ebp),%ebx
	// first recursively print all preceding (more significant) digits
	if (num >= base) {
		printnum(putch, putdat, num / base, base, width - 1, padc);
	} else {
		// print any needed pad characters before first digit
		while (--width > 0)
  8002c9:	83 eb 01             	sub    $0x1,%ebx
  8002cc:	85 db                	test   %ebx,%ebx
  8002ce:	7f e8                	jg     8002b8 <printnum+0x67>
			putch(padc, putdat);
	}

	// then print this (the least significant) digit
	putch("0123456789abcdef"[num % base], putdat);
  8002d0:	83 ec 08             	sub    $0x8,%esp
  8002d3:	56                   	push   %esi
  8002d4:	83 ec 04             	sub    $0x4,%esp
  8002d7:	ff 75 e4             	pushl  -0x1c(%ebp)
  8002da:	ff 75 e0             	pushl  -0x20(%ebp)
  8002dd:	ff 75 dc             	pushl  -0x24(%ebp)
  8002e0:	ff 75 d8             	pushl  -0x28(%ebp)
  8002e3:	e8 48 09 00 00       	call   800c30 <__umoddi3>
  8002e8:	83 c4 14             	add    $0x14,%esp
  8002eb:	0f be 80 e2 0d 80 00 	movsbl 0x800de2(%eax),%eax
  8002f2:	50                   	push   %eax
  8002f3:	ff d7                	call   *%edi
}
  8002f5:	83 c4 10             	add    $0x10,%esp
  8002f8:	8d 65 f4             	lea    -0xc(%ebp),%esp
  8002fb:	5b                   	pop    %ebx
  8002fc:	5e                   	pop    %esi
  8002fd:	5f                   	pop    %edi
  8002fe:	5d                   	pop    %ebp
  8002ff:	c3                   	ret    

00800300 <getuint>:

// Get an unsigned int of various possible sizes from a varargs list,
// depending on the lflag parameter.
static unsigned long long
getuint(va_list *ap, int lflag)
{
  800300:	55                   	push   %ebp
  800301:	89 e5                	mov    %esp,%ebp
	if (lflag >= 2)
  800303:	83 fa 01             	cmp    $0x1,%edx
  800306:	7e 0e                	jle    800316 <getuint+0x16>
		return va_arg(*ap, unsigned long long);
  800308:	8b 10                	mov    (%eax),%edx
  80030a:	8d 4a 08             	lea    0x8(%edx),%ecx
  80030d:	89 08                	mov    %ecx,(%eax)
  80030f:	8b 02                	mov    (%edx),%eax
  800311:	8b 52 04             	mov    0x4(%edx),%edx
  800314:	eb 22                	jmp    800338 <getuint+0x38>
	else if (lflag)
  800316:	85 d2                	test   %edx,%edx
  800318:	74 10                	je     80032a <getuint+0x2a>
		return va_arg(*ap, unsigned long);
  80031a:	8b 10                	mov    (%eax),%edx
  80031c:	8d 4a 04             	lea    0x4(%edx),%ecx
  80031f:	89 08                	mov    %ecx,(%eax)
  800321:	8b 02                	mov    (%edx),%eax
  800323:	ba 00 00 00 00       	mov    $0x0,%edx
  800328:	eb 0e                	jmp    800338 <getuint+0x38>
	else
		return va_arg(*ap, unsigned int);
  80032a:	8b 10                	mov    (%eax),%edx
  80032c:	8d 4a 04             	lea    0x4(%edx),%ecx
  80032f:	89 08                	mov    %ecx,(%eax)
  800331:	8b 02                	mov    (%edx),%eax
  800333:	ba 00 00 00 00       	mov    $0x0,%edx
}
  800338:	5d                   	pop    %ebp
  800339:	c3                   	ret    

0080033a <getint>:

// Same as getuint but signed - can't use getuint
// because of sign extension
static long long
getint(va_list *ap, int lflag)
{
  80033a:	55                   	push   %ebp
  80033b:	89 e5                	mov    %esp,%ebp
	if (lflag >= 2)
  80033d:	83 fa 01             	cmp    $0x1,%edx
  800340:	7e 0e                	jle    800350 <getint+0x16>
		return va_arg(*ap, long long);
  800342:	8b 10                	mov    (%eax),%edx
  800344:	8d 4a 08             	lea    0x8(%edx),%ecx
  800347:	89 08                	mov    %ecx,(%eax)
  800349:	8b 02                	mov    (%edx),%eax
  80034b:	8b 52 04             	mov    0x4(%edx),%edx
  80034e:	eb 1a                	jmp    80036a <getint+0x30>
	else if (lflag)
  800350:	85 d2                	test   %edx,%edx
  800352:	74 0c                	je     800360 <getint+0x26>
		return va_arg(*ap, long);
  800354:	8b 10                	mov    (%eax),%edx
  800356:	8d 4a 04             	lea    0x4(%edx),%ecx
  800359:	89 08                	mov    %ecx,(%eax)
  80035b:	8b 02                	mov    (%edx),%eax
  80035d:	99                   	cltd   
  80035e:	eb 0a                	jmp    80036a <getint+0x30>
	else
		return va_arg(*ap, int);
  800360:	8b 10                	mov    (%eax),%edx
  800362:	8d 4a 04             	lea    0x4(%edx),%ecx
  800365:	89 08                	mov    %ecx,(%eax)
  800367:	8b 02                	mov    (%edx),%eax
  800369:	99                   	cltd   
}
  80036a:	5d                   	pop    %ebp
  80036b:	c3                   	ret    

0080036c <sprintputch>:
	int cnt;
};

static void
sprintputch(int ch, struct sprintbuf *b)
{
  80036c:	55                   	push   %ebp
  80036d:	89 e5                	mov    %esp,%ebp
  80036f:	8b 45 0c             	mov    0xc(%ebp),%eax
	b->cnt++;
  800372:	83 40 08 01          	addl   $0x1,0x8(%eax)
	if (b->buf < b->ebuf)
  800376:	8b 10                	mov    (%eax),%edx
  800378:	3b 50 04             	cmp    0x4(%eax),%edx
  80037b:	73 0a                	jae    800387 <sprintputch+0x1b>
		*b->buf++ = ch;
  80037d:	8d 4a 01             	lea    0x1(%edx),%ecx
  800380:	89 08                	mov    %ecx,(%eax)
  800382:	8b 45 08             	mov    0x8(%ebp),%eax
  800385:	88 02                	mov    %al,(%edx)
}
  800387:	5d                   	pop    %ebp
  800388:	c3                   	ret    

00800389 <printfmt>:
	}
}

void
printfmt(void (*putch)(int, void*), void *putdat, const char *fmt, ...)
{
  800389:	55                   	push   %ebp
  80038a:	89 e5                	mov    %esp,%ebp
  80038c:	83 ec 08             	sub    $0x8,%esp
	va_list ap;

	va_start(ap, fmt);
  80038f:	8d 45 14             	lea    0x14(%ebp),%eax
	vprintfmt(putch, putdat, fmt, ap);
  800392:	50                   	push   %eax
  800393:	ff 75 10             	pushl  0x10(%ebp)
  800396:	ff 75 0c             	pushl  0xc(%ebp)
  800399:	ff 75 08             	pushl  0x8(%ebp)
  80039c:	e8 05 00 00 00       	call   8003a6 <vprintfmt>
	va_end(ap);
}
  8003a1:	83 c4 10             	add    $0x10,%esp
  8003a4:	c9                   	leave  
  8003a5:	c3                   	ret    

008003a6 <vprintfmt>:
// Main function to format and print a string.
void printfmt(void (*putch)(int, void*), void *putdat, const char *fmt, ...);

void
vprintfmt(void (*putch)(int, void*), void *putdat, const char *fmt, va_list ap)
{
  8003a6:	55                   	push   %ebp
  8003a7:	89 e5                	mov    %esp,%ebp
  8003a9:	57                   	push   %edi
  8003aa:	56                   	push   %esi
  8003ab:	53                   	push   %ebx
  8003ac:	83 ec 2c             	sub    $0x2c,%esp
  8003af:	8b 75 08             	mov    0x8(%ebp),%esi
  8003b2:	8b 5d 0c             	mov    0xc(%ebp),%ebx
  8003b5:	8b 7d 10             	mov    0x10(%ebp),%edi
  8003b8:	eb 12                	jmp    8003cc <vprintfmt+0x26>
	int base, lflag, width, precision, altflag;
	char padc;

	while (1) {
		while ((ch = *(unsigned char *) fmt++) != '%') {
			if (ch == '\0')
  8003ba:	85 c0                	test   %eax,%eax
  8003bc:	0f 84 44 03 00 00    	je     800706 <vprintfmt+0x360>
				return;
			putch(ch, putdat);
  8003c2:	83 ec 08             	sub    $0x8,%esp
  8003c5:	53                   	push   %ebx
  8003c6:	50                   	push   %eax
  8003c7:	ff d6                	call   *%esi
  8003c9:	83 c4 10             	add    $0x10,%esp
	unsigned long long num;
	int base, lflag, width, precision, altflag;
	char padc;

	while (1) {
		while ((ch = *(unsigned char *) fmt++) != '%') {
  8003cc:	83 c7 01             	add    $0x1,%edi
  8003cf:	0f b6 47 ff          	movzbl -0x1(%edi),%eax
  8003d3:	83 f8 25             	cmp    $0x25,%eax
  8003d6:	75 e2                	jne    8003ba <vprintfmt+0x14>
  8003d8:	c6 45 d4 20          	movb   $0x20,-0x2c(%ebp)
  8003dc:	c7 45 d8 00 00 00 00 	movl   $0x0,-0x28(%ebp)
  8003e3:	c7 45 d0 ff ff ff ff 	movl   $0xffffffff,-0x30(%ebp)
  8003ea:	c7 45 e0 ff ff ff ff 	movl   $0xffffffff,-0x20(%ebp)
  8003f1:	ba 00 00 00 00       	mov    $0x0,%edx
  8003f6:	eb 07                	jmp    8003ff <vprintfmt+0x59>
		width = -1;
		precision = -1;
		lflag = 0;
		altflag = 0;
	reswitch:
		switch (ch = *(unsigned char *) fmt++) {
  8003f8:	8b 7d e4             	mov    -0x1c(%ebp),%edi

		// flag to pad on the right
		case '-':
			padc = '-';
  8003fb:	c6 45 d4 2d          	movb   $0x2d,-0x2c(%ebp)
		width = -1;
		precision = -1;
		lflag = 0;
		altflag = 0;
	reswitch:
		switch (ch = *(unsigned char *) fmt++) {
  8003ff:	8d 47 01             	lea    0x1(%edi),%eax
  800402:	89 45 e4             	mov    %eax,-0x1c(%ebp)
  800405:	0f b6 07             	movzbl (%edi),%eax
  800408:	0f b6 c8             	movzbl %al,%ecx
  80040b:	83 e8 23             	sub    $0x23,%eax
  80040e:	3c 55                	cmp    $0x55,%al
  800410:	0f 87 d5 02 00 00    	ja     8006eb <vprintfmt+0x345>
  800416:	0f b6 c0             	movzbl %al,%eax
  800419:	ff 24 85 70 0e 80 00 	jmp    *0x800e70(,%eax,4)
  800420:	8b 7d e4             	mov    -0x1c(%ebp),%edi
			padc = '-';
			goto reswitch;

		// flag to pad with 0's instead of spaces
		case '0':
			padc = '0';
  800423:	c6 45 d4 30          	movb   $0x30,-0x2c(%ebp)
  800427:	eb d6                	jmp    8003ff <vprintfmt+0x59>
		width = -1;
		precision = -1;
		lflag = 0;
		altflag = 0;
	reswitch:
		switch (ch = *(unsigned char *) fmt++) {
  800429:	8b 7d e4             	mov    -0x1c(%ebp),%edi
  80042c:	b8 00 00 00 00       	mov    $0x0,%eax
  800431:	89 55 e4             	mov    %edx,-0x1c(%ebp)
		case '6':
		case '7':
		case '8':
		case '9':
			for (precision = 0; ; ++fmt) {
				precision = precision * 10 + ch - '0';
  800434:	8d 04 80             	lea    (%eax,%eax,4),%eax
  800437:	8d 44 41 d0          	lea    -0x30(%ecx,%eax,2),%eax
				ch = *fmt;
  80043b:	0f be 0f             	movsbl (%edi),%ecx
				if (ch < '0' || ch > '9')
  80043e:	8d 51 d0             	lea    -0x30(%ecx),%edx
  800441:	83 fa 09             	cmp    $0x9,%edx
  800444:	77 39                	ja     80047f <vprintfmt+0xd9>
		case '5':
		case '6':
		case '7':
		case '8':
		case '9':
			for (precision = 0; ; ++fmt) {
  800446:	83 c7 01             	add    $0x1,%edi
				precision = precision * 10 + ch - '0';
				ch = *fmt;
				if (ch < '0' || ch > '9')
					break;
			}
  800449:	eb e9                	jmp    800434 <vprintfmt+0x8e>
			goto process_precision;

		case '*':
			precision = va_arg(ap, int);
  80044b:	8b 45 14             	mov    0x14(%ebp),%eax
  80044e:	8d 48 04             	lea    0x4(%eax),%ecx
  800451:	89 4d 14             	mov    %ecx,0x14(%ebp)
  800454:	8b 00                	mov    (%eax),%eax
  800456:	89 45 d0             	mov    %eax,-0x30(%ebp)
		width = -1;
		precision = -1;
		lflag = 0;
		altflag = 0;
	reswitch:
		switch (ch = *(unsigned char *) fmt++) {
  800459:	8b 7d e4             	mov    -0x1c(%ebp),%edi
			}
			goto process_precision;

		case '*':
			precision = va_arg(ap, int);
			goto process_precision;
  80045c:	eb 27                	jmp    800485 <vprintfmt+0xdf>
  80045e:	8b 45 e0             	mov    -0x20(%ebp),%eax
  800461:	85 c0                	test   %eax,%eax
  800463:	b9 00 00 00 00       	mov    $0x0,%ecx
  800468:	0f 49 c8             	cmovns %eax,%ecx
  80046b:	89 4d e0             	mov    %ecx,-0x20(%ebp)
		width = -1;
		precision = -1;
		lflag = 0;
		altflag = 0;
	reswitch:
		switch (ch = *(unsigned char *) fmt++) {
  80046e:	8b 7d e4             	mov    -0x1c(%ebp),%edi
  800471:	eb 8c                	jmp    8003ff <vprintfmt+0x59>
  800473:	8b 7d e4             	mov    -0x1c(%ebp),%edi
			if (width < 0)
				width = 0;
			goto reswitch;

		case '#':
			altflag = 1;
  800476:	c7 45 d8 01 00 00 00 	movl   $0x1,-0x28(%ebp)
			goto reswitch;
  80047d:	eb 80                	jmp    8003ff <vprintfmt+0x59>
  80047f:	8b 55 e4             	mov    -0x1c(%ebp),%edx
  800482:	89 45 d0             	mov    %eax,-0x30(%ebp)

		process_precision:
			if (width < 0)
  800485:	83 7d e0 00          	cmpl   $0x0,-0x20(%ebp)
  800489:	0f 89 70 ff ff ff    	jns    8003ff <vprintfmt+0x59>
				width = precision, precision = -1;
  80048f:	8b 45 d0             	mov    -0x30(%ebp),%eax
  800492:	89 45 e0             	mov    %eax,-0x20(%ebp)
  800495:	c7 45 d0 ff ff ff ff 	movl   $0xffffffff,-0x30(%ebp)
  80049c:	e9 5e ff ff ff       	jmp    8003ff <vprintfmt+0x59>
			goto reswitch;

		// long flag (doubled for long long)
		case 'l':
			lflag++;
  8004a1:	83 c2 01             	add    $0x1,%edx
		width = -1;
		precision = -1;
		lflag = 0;
		altflag = 0;
	reswitch:
		switch (ch = *(unsigned char *) fmt++) {
  8004a4:	8b 7d e4             	mov    -0x1c(%ebp),%edi
			goto reswitch;

		// long flag (doubled for long long)
		case 'l':
			lflag++;
			goto reswitch;
  8004a7:	e9 53 ff ff ff       	jmp    8003ff <vprintfmt+0x59>

		// character
		case 'c':
			putch(va_arg(ap, int), putdat);
  8004ac:	8b 45 14             	mov    0x14(%ebp),%eax
  8004af:	8d 50 04             	lea    0x4(%eax),%edx
  8004b2:	89 55 14             	mov    %edx,0x14(%ebp)
  8004b5:	83 ec 08             	sub    $0x8,%esp
  8004b8:	53                   	push   %ebx
  8004b9:	ff 30                	pushl  (%eax)
  8004bb:	ff d6                	call   *%esi
			break;
  8004bd:	83 c4 10             	add    $0x10,%esp
		width = -1;
		precision = -1;
		lflag = 0;
		altflag = 0;
	reswitch:
		switch (ch = *(unsigned char *) fmt++) {
  8004c0:	8b 7d e4             	mov    -0x1c(%ebp),%edi
			goto reswitch;

		// character
		case 'c':
			putch(va_arg(ap, int), putdat);
			break;
  8004c3:	e9 04 ff ff ff       	jmp    8003cc <vprintfmt+0x26>

		// error message
		case 'e':
			err = va_arg(ap, int);
  8004c8:	8b 45 14             	mov    0x14(%ebp),%eax
  8004cb:	8d 50 04             	lea    0x4(%eax),%edx
  8004ce:	89 55 14             	mov    %edx,0x14(%ebp)
  8004d1:	8b 00                	mov    (%eax),%eax
  8004d3:	99                   	cltd   
  8004d4:	31 d0                	xor    %edx,%eax
  8004d6:	29 d0                	sub    %edx,%eax
			if (err < 0)
				err = -err;
			if (err >= MAXERROR || (p = error_string[err]) == NULL)
  8004d8:	83 f8 06             	cmp    $0x6,%eax
  8004db:	7f 0b                	jg     8004e8 <vprintfmt+0x142>
  8004dd:	8b 14 85 c8 0f 80 00 	mov    0x800fc8(,%eax,4),%edx
  8004e4:	85 d2                	test   %edx,%edx
  8004e6:	75 18                	jne    800500 <vprintfmt+0x15a>
				printfmt(putch, putdat, "error %d", err);
  8004e8:	50                   	push   %eax
  8004e9:	68 fa 0d 80 00       	push   $0x800dfa
  8004ee:	53                   	push   %ebx
  8004ef:	56                   	push   %esi
  8004f0:	e8 94 fe ff ff       	call   800389 <printfmt>
  8004f5:	83 c4 10             	add    $0x10,%esp
		width = -1;
		precision = -1;
		lflag = 0;
		altflag = 0;
	reswitch:
		switch (ch = *(unsigned char *) fmt++) {
  8004f8:	8b 7d e4             	mov    -0x1c(%ebp),%edi
		case 'e':
			err = va_arg(ap, int);
			if (err < 0)
				err = -err;
			if (err >= MAXERROR || (p = error_string[err]) == NULL)
				printfmt(putch, putdat, "error %d", err);
  8004fb:	e9 cc fe ff ff       	jmp    8003cc <vprintfmt+0x26>
			else
				printfmt(putch, putdat, "%s", p);
  800500:	52                   	push   %edx
  800501:	68 03 0e 80 00       	push   $0x800e03
  800506:	53                   	push   %ebx
  800507:	56                   	push   %esi
  800508:	e8 7c fe ff ff       	call   800389 <printfmt>
  80050d:	83 c4 10             	add    $0x10,%esp
		width = -1;
		precision = -1;
		lflag = 0;
		altflag = 0;
	reswitch:
		switch (ch = *(unsigned char *) fmt++) {
  800510:	8b 7d e4             	mov    -0x1c(%ebp),%edi
  800513:	e9 b4 fe ff ff       	jmp    8003cc <vprintfmt+0x26>
				printfmt(putch, putdat, "%s", p);
			break;

		// string
		case 's':
			if ((p = va_arg(ap, char *)) == NULL)
  800518:	8b 45 14             	mov    0x14(%ebp),%eax
  80051b:	8d 50 04             	lea    0x4(%eax),%edx
  80051e:	89 55 14             	mov    %edx,0x14(%ebp)
  800521:	8b 38                	mov    (%eax),%edi
				p = "(null)";
  800523:	85 ff                	test   %edi,%edi
  800525:	b8 f3 0d 80 00       	mov    $0x800df3,%eax
  80052a:	0f 44 f8             	cmove  %eax,%edi
			if (width > 0 && padc != '-')
  80052d:	83 7d e0 00          	cmpl   $0x0,-0x20(%ebp)
  800531:	0f 8e 94 00 00 00    	jle    8005cb <vprintfmt+0x225>
  800537:	80 7d d4 2d          	cmpb   $0x2d,-0x2c(%ebp)
  80053b:	0f 84 98 00 00 00    	je     8005d9 <vprintfmt+0x233>
				for (width -= strnlen(p, precision); width > 0; width--)
  800541:	83 ec 08             	sub    $0x8,%esp
  800544:	ff 75 d0             	pushl  -0x30(%ebp)
  800547:	57                   	push   %edi
  800548:	e8 41 02 00 00       	call   80078e <strnlen>
  80054d:	8b 4d e0             	mov    -0x20(%ebp),%ecx
  800550:	29 c1                	sub    %eax,%ecx
  800552:	89 4d cc             	mov    %ecx,-0x34(%ebp)
  800555:	83 c4 10             	add    $0x10,%esp
					putch(padc, putdat);
  800558:	0f be 45 d4          	movsbl -0x2c(%ebp),%eax
  80055c:	89 45 e0             	mov    %eax,-0x20(%ebp)
  80055f:	89 7d d4             	mov    %edi,-0x2c(%ebp)
  800562:	89 cf                	mov    %ecx,%edi
		// string
		case 's':
			if ((p = va_arg(ap, char *)) == NULL)
				p = "(null)";
			if (width > 0 && padc != '-')
				for (width -= strnlen(p, precision); width > 0; width--)
  800564:	eb 0f                	jmp    800575 <vprintfmt+0x1cf>
					putch(padc, putdat);
  800566:	83 ec 08             	sub    $0x8,%esp
  800569:	53                   	push   %ebx
  80056a:	ff 75 e0             	pushl  -0x20(%ebp)
  80056d:	ff d6                	call   *%esi
		// string
		case 's':
			if ((p = va_arg(ap, char *)) == NULL)
				p = "(null)";
			if (width > 0 && padc != '-')
				for (width -= strnlen(p, precision); width > 0; width--)
  80056f:	83 ef 01             	sub    $0x1,%edi
  800572:	83 c4 10             	add    $0x10,%esp
  800575:	85 ff                	test   %edi,%edi
  800577:	7f ed                	jg     800566 <vprintfmt+0x1c0>
  800579:	8b 7d d4             	mov    -0x2c(%ebp),%edi
  80057c:	8b 4d cc             	mov    -0x34(%ebp),%ecx
  80057f:	85 c9                	test   %ecx,%ecx
  800581:	b8 00 00 00 00       	mov    $0x0,%eax
  800586:	0f 49 c1             	cmovns %ecx,%eax
  800589:	29 c1                	sub    %eax,%ecx
  80058b:	89 75 08             	mov    %esi,0x8(%ebp)
  80058e:	8b 75 d0             	mov    -0x30(%ebp),%esi
  800591:	89 5d 0c             	mov    %ebx,0xc(%ebp)
  800594:	89 cb                	mov    %ecx,%ebx
  800596:	eb 4d                	jmp    8005e5 <vprintfmt+0x23f>
					putch(padc, putdat);
			for (; (ch = *p++) != '\0' && (precision < 0 || --precision >= 0); width--)
				if (altflag && (ch < ' ' || ch > '~'))
  800598:	83 7d d8 00          	cmpl   $0x0,-0x28(%ebp)
  80059c:	74 1b                	je     8005b9 <vprintfmt+0x213>
  80059e:	0f be c0             	movsbl %al,%eax
  8005a1:	83 e8 20             	sub    $0x20,%eax
  8005a4:	83 f8 5e             	cmp    $0x5e,%eax
  8005a7:	76 10                	jbe    8005b9 <vprintfmt+0x213>
					putch('?', putdat);
  8005a9:	83 ec 08             	sub    $0x8,%esp
  8005ac:	ff 75 0c             	pushl  0xc(%ebp)
  8005af:	6a 3f                	push   $0x3f
  8005b1:	ff 55 08             	call   *0x8(%ebp)
  8005b4:	83 c4 10             	add    $0x10,%esp
  8005b7:	eb 0d                	jmp    8005c6 <vprintfmt+0x220>
				else
					putch(ch, putdat);
  8005b9:	83 ec 08             	sub    $0x8,%esp
  8005bc:	ff 75 0c             	pushl  0xc(%ebp)
  8005bf:	52                   	push   %edx
  8005c0:	ff 55 08             	call   *0x8(%ebp)
  8005c3:	83 c4 10             	add    $0x10,%esp
			if ((p = va_arg(ap, char *)) == NULL)
				p = "(null)";
			if (width > 0 && padc != '-')
				for (width -= strnlen(p, precision); width > 0; width--)
					putch(padc, putdat);
			for (; (ch = *p++) != '\0' && (precision < 0 || --precision >= 0); width--)
  8005c6:	83 eb 01             	sub    $0x1,%ebx
  8005c9:	eb 1a                	jmp    8005e5 <vprintfmt+0x23f>
  8005cb:	89 75 08             	mov    %esi,0x8(%ebp)
  8005ce:	8b 75 d0             	mov    -0x30(%ebp),%esi
  8005d1:	89 5d 0c             	mov    %ebx,0xc(%ebp)
  8005d4:	8b 5d e0             	mov    -0x20(%ebp),%ebx
  8005d7:	eb 0c                	jmp    8005e5 <vprintfmt+0x23f>
  8005d9:	89 75 08             	mov    %esi,0x8(%ebp)
  8005dc:	8b 75 d0             	mov    -0x30(%ebp),%esi
  8005df:	89 5d 0c             	mov    %ebx,0xc(%ebp)
  8005e2:	8b 5d e0             	mov    -0x20(%ebp),%ebx
  8005e5:	83 c7 01             	add    $0x1,%edi
  8005e8:	0f b6 47 ff          	movzbl -0x1(%edi),%eax
  8005ec:	0f be d0             	movsbl %al,%edx
  8005ef:	85 d2                	test   %edx,%edx
  8005f1:	74 23                	je     800616 <vprintfmt+0x270>
  8005f3:	85 f6                	test   %esi,%esi
  8005f5:	78 a1                	js     800598 <vprintfmt+0x1f2>
  8005f7:	83 ee 01             	sub    $0x1,%esi
  8005fa:	79 9c                	jns    800598 <vprintfmt+0x1f2>
  8005fc:	89 df                	mov    %ebx,%edi
  8005fe:	8b 75 08             	mov    0x8(%ebp),%esi
  800601:	8b 5d 0c             	mov    0xc(%ebp),%ebx
  800604:	eb 18                	jmp    80061e <vprintfmt+0x278>
				if (altflag && (ch < ' ' || ch > '~'))
					putch('?', putdat);
				else
					putch(ch, putdat);
			for (; width > 0; width--)
				putch(' ', putdat);
  800606:	83 ec 08             	sub    $0x8,%esp
  800609:	53                   	push   %ebx
  80060a:	6a 20                	push   $0x20
  80060c:	ff d6                	call   *%esi
			for (; (ch = *p++) != '\0' && (precision < 0 || --precision >= 0); width--)
				if (altflag && (ch < ' ' || ch > '~'))
					putch('?', putdat);
				else
					putch(ch, putdat);
			for (; width > 0; width--)
  80060e:	83 ef 01             	sub    $0x1,%edi
  800611:	83 c4 10             	add    $0x10,%esp
  800614:	eb 08                	jmp    80061e <vprintfmt+0x278>
  800616:	89 df                	mov    %ebx,%edi
  800618:	8b 75 08             	mov    0x8(%ebp),%esi
  80061b:	8b 5d 0c             	mov    0xc(%ebp),%ebx
  80061e:	85 ff                	test   %edi,%edi
  800620:	7f e4                	jg     800606 <vprintfmt+0x260>
		width = -1;
		precision = -1;
		lflag = 0;
		altflag = 0;
	reswitch:
		switch (ch = *(unsigned char *) fmt++) {
  800622:	8b 7d e4             	mov    -0x1c(%ebp),%edi
  800625:	e9 a2 fd ff ff       	jmp    8003cc <vprintfmt+0x26>
				putch(' ', putdat);
			break;

		// (signed) decimal
		case 'd':
			num = getint(&ap, lflag);
  80062a:	8d 45 14             	lea    0x14(%ebp),%eax
  80062d:	e8 08 fd ff ff       	call   80033a <getint>
  800632:	89 45 d8             	mov    %eax,-0x28(%ebp)
  800635:	89 55 dc             	mov    %edx,-0x24(%ebp)
			if ((long long) num < 0) {
				putch('-', putdat);
				num = -(long long) num;
			}
			base = 10;
  800638:	b9 0a 00 00 00       	mov    $0xa,%ecx
			break;

		// (signed) decimal
		case 'd':
			num = getint(&ap, lflag);
			if ((long long) num < 0) {
  80063d:	83 7d dc 00          	cmpl   $0x0,-0x24(%ebp)
  800641:	79 74                	jns    8006b7 <vprintfmt+0x311>
				putch('-', putdat);
  800643:	83 ec 08             	sub    $0x8,%esp
  800646:	53                   	push   %ebx
  800647:	6a 2d                	push   $0x2d
  800649:	ff d6                	call   *%esi
				num = -(long long) num;
  80064b:	8b 45 d8             	mov    -0x28(%ebp),%eax
  80064e:	8b 55 dc             	mov    -0x24(%ebp),%edx
  800651:	f7 d8                	neg    %eax
  800653:	83 d2 00             	adc    $0x0,%edx
  800656:	f7 da                	neg    %edx
  800658:	83 c4 10             	add    $0x10,%esp
			}
			base = 10;
  80065b:	b9 0a 00 00 00       	mov    $0xa,%ecx
  800660:	eb 55                	jmp    8006b7 <vprintfmt+0x311>
			goto number;

		// unsigned decimal
		case 'u':
			num = getuint(&ap, lflag);
  800662:	8d 45 14             	lea    0x14(%ebp),%eax
  800665:	e8 96 fc ff ff       	call   800300 <getuint>
			base = 10;
  80066a:	b9 0a 00 00 00       	mov    $0xa,%ecx
			goto number;
  80066f:	eb 46                	jmp    8006b7 <vprintfmt+0x311>

		// (unsigned) octal
		case 'o':
			num = getuint(&ap, lflag);
  800671:	8d 45 14             	lea    0x14(%ebp),%eax
  800674:	e8 87 fc ff ff       	call   800300 <getuint>
			base = 8;
  800679:	b9 08 00 00 00       	mov    $0x8,%ecx
			goto number;
  80067e:	eb 37                	jmp    8006b7 <vprintfmt+0x311>

		// pointer
		case 'p':
			putch('0', putdat);
  800680:	83 ec 08             	sub    $0x8,%esp
  800683:	53                   	push   %ebx
  800684:	6a 30                	push   $0x30
  800686:	ff d6                	call   *%esi
			putch('x', putdat);
  800688:	83 c4 08             	add    $0x8,%esp
  80068b:	53                   	push   %ebx
  80068c:	6a 78                	push   $0x78
  80068e:	ff d6                	call   *%esi
			num = (unsigned long long)
				(uintptr_t) va_arg(ap, void *);
  800690:	8b 45 14             	mov    0x14(%ebp),%eax
  800693:	8d 50 04             	lea    0x4(%eax),%edx
  800696:	89 55 14             	mov    %edx,0x14(%ebp)

		// pointer
		case 'p':
			putch('0', putdat);
			putch('x', putdat);
			num = (unsigned long long)
  800699:	8b 00                	mov    (%eax),%eax
  80069b:	ba 00 00 00 00       	mov    $0x0,%edx
				(uintptr_t) va_arg(ap, void *);
			base = 16;
			goto number;
  8006a0:	83 c4 10             	add    $0x10,%esp
		case 'p':
			putch('0', putdat);
			putch('x', putdat);
			num = (unsigned long long)
				(uintptr_t) va_arg(ap, void *);
			base = 16;
  8006a3:	b9 10 00 00 00       	mov    $0x10,%ecx
			goto number;
  8006a8:	eb 0d                	jmp    8006b7 <vprintfmt+0x311>

		// (unsigned) hexadecimal
		case 'x':
			num = getuint(&ap, lflag);
  8006aa:	8d 45 14             	lea    0x14(%ebp),%eax
  8006ad:	e8 4e fc ff ff       	call   800300 <getuint>
			base = 16;
  8006b2:	b9 10 00 00 00       	mov    $0x10,%ecx
		number:
			printnum(putch, putdat, num, base, width, padc);
  8006b7:	83 ec 0c             	sub    $0xc,%esp
  8006ba:	0f be 7d d4          	movsbl -0x2c(%ebp),%edi
  8006be:	57                   	push   %edi
  8006bf:	ff 75 e0             	pushl  -0x20(%ebp)
  8006c2:	51                   	push   %ecx
  8006c3:	52                   	push   %edx
  8006c4:	50                   	push   %eax
  8006c5:	89 da                	mov    %ebx,%edx
  8006c7:	89 f0                	mov    %esi,%eax
  8006c9:	e8 83 fb ff ff       	call   800251 <printnum>
			break;
  8006ce:	83 c4 20             	add    $0x20,%esp
  8006d1:	8b 7d e4             	mov    -0x1c(%ebp),%edi
  8006d4:	e9 f3 fc ff ff       	jmp    8003cc <vprintfmt+0x26>

		// escaped '%' character
		case '%':
			putch(ch, putdat);
  8006d9:	83 ec 08             	sub    $0x8,%esp
  8006dc:	53                   	push   %ebx
  8006dd:	51                   	push   %ecx
  8006de:	ff d6                	call   *%esi
			break;
  8006e0:	83 c4 10             	add    $0x10,%esp
		width = -1;
		precision = -1;
		lflag = 0;
		altflag = 0;
	reswitch:
		switch (ch = *(unsigned char *) fmt++) {
  8006e3:	8b 7d e4             	mov    -0x1c(%ebp),%edi
			break;

		// escaped '%' character
		case '%':
			putch(ch, putdat);
			break;
  8006e6:	e9 e1 fc ff ff       	jmp    8003cc <vprintfmt+0x26>

		// unrecognized escape sequence - just print it literally
		default:
			putch('%', putdat);
  8006eb:	83 ec 08             	sub    $0x8,%esp
  8006ee:	53                   	push   %ebx
  8006ef:	6a 25                	push   $0x25
  8006f1:	ff d6                	call   *%esi
			for (fmt--; fmt[-1] != '%'; fmt--)
  8006f3:	83 c4 10             	add    $0x10,%esp
  8006f6:	eb 03                	jmp    8006fb <vprintfmt+0x355>
  8006f8:	83 ef 01             	sub    $0x1,%edi
  8006fb:	80 7f ff 25          	cmpb   $0x25,-0x1(%edi)
  8006ff:	75 f7                	jne    8006f8 <vprintfmt+0x352>
  800701:	e9 c6 fc ff ff       	jmp    8003cc <vprintfmt+0x26>
				/* do nothing */;
			break;
		}
	}
}
  800706:	8d 65 f4             	lea    -0xc(%ebp),%esp
  800709:	5b                   	pop    %ebx
  80070a:	5e                   	pop    %esi
  80070b:	5f                   	pop    %edi
  80070c:	5d                   	pop    %ebp
  80070d:	c3                   	ret    

0080070e <vsnprintf>:
		*b->buf++ = ch;
}

int
vsnprintf(char *buf, int n, const char *fmt, va_list ap)
{
  80070e:	55                   	push   %ebp
  80070f:	89 e5                	mov    %esp,%ebp
  800711:	83 ec 18             	sub    $0x18,%esp
  800714:	8b 45 08             	mov    0x8(%ebp),%eax
  800717:	8b 55 0c             	mov    0xc(%ebp),%edx
	struct sprintbuf b = {buf, buf+n-1, 0};
  80071a:	89 45 ec             	mov    %eax,-0x14(%ebp)
  80071d:	8d 4c 10 ff          	lea    -0x1(%eax,%edx,1),%ecx
  800721:	89 4d f0             	mov    %ecx,-0x10(%ebp)
  800724:	c7 45 f4 00 00 00 00 	movl   $0x0,-0xc(%ebp)

	if (buf == NULL || n < 1)
  80072b:	85 c0                	test   %eax,%eax
  80072d:	74 26                	je     800755 <vsnprintf+0x47>
  80072f:	85 d2                	test   %edx,%edx
  800731:	7e 22                	jle    800755 <vsnprintf+0x47>
		return -E_INVAL;

	// print the string to the buffer
	vprintfmt((void*)sprintputch, &b, fmt, ap);
  800733:	ff 75 14             	pushl  0x14(%ebp)
  800736:	ff 75 10             	pushl  0x10(%ebp)
  800739:	8d 45 ec             	lea    -0x14(%ebp),%eax
  80073c:	50                   	push   %eax
  80073d:	68 6c 03 80 00       	push   $0x80036c
  800742:	e8 5f fc ff ff       	call   8003a6 <vprintfmt>

	// null terminate the buffer
	*b.buf = '\0';
  800747:	8b 45 ec             	mov    -0x14(%ebp),%eax
  80074a:	c6 00 00             	movb   $0x0,(%eax)

	return b.cnt;
  80074d:	8b 45 f4             	mov    -0xc(%ebp),%eax
  800750:	83 c4 10             	add    $0x10,%esp
  800753:	eb 05                	jmp    80075a <vsnprintf+0x4c>
vsnprintf(char *buf, int n, const char *fmt, va_list ap)
{
	struct sprintbuf b = {buf, buf+n-1, 0};

	if (buf == NULL || n < 1)
		return -E_INVAL;
  800755:	b8 fd ff ff ff       	mov    $0xfffffffd,%eax

	// null terminate the buffer
	*b.buf = '\0';

	return b.cnt;
}
  80075a:	c9                   	leave  
  80075b:	c3                   	ret    

0080075c <snprintf>:

int
snprintf(char *buf, int n, const char *fmt, ...)
{
  80075c:	55                   	push   %ebp
  80075d:	89 e5                	mov    %esp,%ebp
  80075f:	83 ec 08             	sub    $0x8,%esp
	va_list ap;
	int rc;

	va_start(ap, fmt);
  800762:	8d 45 14             	lea    0x14(%ebp),%eax
	rc = vsnprintf(buf, n, fmt, ap);
  800765:	50                   	push   %eax
  800766:	ff 75 10             	pushl  0x10(%ebp)
  800769:	ff 75 0c             	pushl  0xc(%ebp)
  80076c:	ff 75 08             	pushl  0x8(%ebp)
  80076f:	e8 9a ff ff ff       	call   80070e <vsnprintf>
	va_end(ap);

	return rc;
}
  800774:	c9                   	leave  
  800775:	c3                   	ret    

00800776 <strlen>:
// Primespipe runs 3x faster this way.
#define ASM 1

int
strlen(const char *s)
{
  800776:	55                   	push   %ebp
  800777:	89 e5                	mov    %esp,%ebp
  800779:	8b 55 08             	mov    0x8(%ebp),%edx
	int n;

	for (n = 0; *s != '\0'; s++)
  80077c:	b8 00 00 00 00       	mov    $0x0,%eax
  800781:	eb 03                	jmp    800786 <strlen+0x10>
		n++;
  800783:	83 c0 01             	add    $0x1,%eax
int
strlen(const char *s)
{
	int n;

	for (n = 0; *s != '\0'; s++)
  800786:	80 3c 02 00          	cmpb   $0x0,(%edx,%eax,1)
  80078a:	75 f7                	jne    800783 <strlen+0xd>
		n++;
	return n;
}
  80078c:	5d                   	pop    %ebp
  80078d:	c3                   	ret    

0080078e <strnlen>:

int
strnlen(const char *s, size_t size)
{
  80078e:	55                   	push   %ebp
  80078f:	89 e5                	mov    %esp,%ebp
  800791:	8b 4d 08             	mov    0x8(%ebp),%ecx
  800794:	8b 45 0c             	mov    0xc(%ebp),%eax
	int n;

	for (n = 0; size > 0 && *s != '\0'; s++, size--)
  800797:	ba 00 00 00 00       	mov    $0x0,%edx
  80079c:	eb 03                	jmp    8007a1 <strnlen+0x13>
		n++;
  80079e:	83 c2 01             	add    $0x1,%edx
int
strnlen(const char *s, size_t size)
{
	int n;

	for (n = 0; size > 0 && *s != '\0'; s++, size--)
  8007a1:	39 c2                	cmp    %eax,%edx
  8007a3:	74 08                	je     8007ad <strnlen+0x1f>
  8007a5:	80 3c 11 00          	cmpb   $0x0,(%ecx,%edx,1)
  8007a9:	75 f3                	jne    80079e <strnlen+0x10>
  8007ab:	89 d0                	mov    %edx,%eax
		n++;
	return n;
}
  8007ad:	5d                   	pop    %ebp
  8007ae:	c3                   	ret    

008007af <strcpy>:

char *
strcpy(char *dst, const char *src)
{
  8007af:	55                   	push   %ebp
  8007b0:	89 e5                	mov    %esp,%ebp
  8007b2:	53                   	push   %ebx
  8007b3:	8b 45 08             	mov    0x8(%ebp),%eax
  8007b6:	8b 4d 0c             	mov    0xc(%ebp),%ecx
	char *ret;

	ret = dst;
	while ((*dst++ = *src++) != '\0')
  8007b9:	89 c2                	mov    %eax,%edx
  8007bb:	83 c2 01             	add    $0x1,%edx
  8007be:	83 c1 01             	add    $0x1,%ecx
  8007c1:	0f b6 59 ff          	movzbl -0x1(%ecx),%ebx
  8007c5:	88 5a ff             	mov    %bl,-0x1(%edx)
  8007c8:	84 db                	test   %bl,%bl
  8007ca:	75 ef                	jne    8007bb <strcpy+0xc>
		/* do nothing */;
	return ret;
}
  8007cc:	5b                   	pop    %ebx
  8007cd:	5d                   	pop    %ebp
  8007ce:	c3                   	ret    

008007cf <strcat>:

char *
strcat(char *dst, const char *src)
{
  8007cf:	55                   	push   %ebp
  8007d0:	89 e5                	mov    %esp,%ebp
  8007d2:	53                   	push   %ebx
  8007d3:	8b 5d 08             	mov    0x8(%ebp),%ebx
	int len = strlen(dst);
  8007d6:	53                   	push   %ebx
  8007d7:	e8 9a ff ff ff       	call   800776 <strlen>
  8007dc:	83 c4 04             	add    $0x4,%esp
	strcpy(dst + len, src);
  8007df:	ff 75 0c             	pushl  0xc(%ebp)
  8007e2:	01 d8                	add    %ebx,%eax
  8007e4:	50                   	push   %eax
  8007e5:	e8 c5 ff ff ff       	call   8007af <strcpy>
	return dst;
}
  8007ea:	89 d8                	mov    %ebx,%eax
  8007ec:	8b 5d fc             	mov    -0x4(%ebp),%ebx
  8007ef:	c9                   	leave  
  8007f0:	c3                   	ret    

008007f1 <strncpy>:

char *
strncpy(char *dst, const char *src, size_t size) {
  8007f1:	55                   	push   %ebp
  8007f2:	89 e5                	mov    %esp,%ebp
  8007f4:	56                   	push   %esi
  8007f5:	53                   	push   %ebx
  8007f6:	8b 75 08             	mov    0x8(%ebp),%esi
  8007f9:	8b 4d 0c             	mov    0xc(%ebp),%ecx
  8007fc:	89 f3                	mov    %esi,%ebx
  8007fe:	03 5d 10             	add    0x10(%ebp),%ebx
	size_t i;
	char *ret;

	ret = dst;
	for (i = 0; i < size; i++) {
  800801:	89 f2                	mov    %esi,%edx
  800803:	eb 0f                	jmp    800814 <strncpy+0x23>
		*dst++ = *src;
  800805:	83 c2 01             	add    $0x1,%edx
  800808:	0f b6 01             	movzbl (%ecx),%eax
  80080b:	88 42 ff             	mov    %al,-0x1(%edx)
		// If strlen(src) < size, null-pad 'dst' out to 'size' chars
		if (*src != '\0')
			src++;
  80080e:	80 39 01             	cmpb   $0x1,(%ecx)
  800811:	83 d9 ff             	sbb    $0xffffffff,%ecx
strncpy(char *dst, const char *src, size_t size) {
	size_t i;
	char *ret;

	ret = dst;
	for (i = 0; i < size; i++) {
  800814:	39 da                	cmp    %ebx,%edx
  800816:	75 ed                	jne    800805 <strncpy+0x14>
		// If strlen(src) < size, null-pad 'dst' out to 'size' chars
		if (*src != '\0')
			src++;
	}
	return ret;
}
  800818:	89 f0                	mov    %esi,%eax
  80081a:	5b                   	pop    %ebx
  80081b:	5e                   	pop    %esi
  80081c:	5d                   	pop    %ebp
  80081d:	c3                   	ret    

0080081e <strlcpy>:

size_t
strlcpy(char *dst, const char *src, size_t size)
{
  80081e:	55                   	push   %ebp
  80081f:	89 e5                	mov    %esp,%ebp
  800821:	56                   	push   %esi
  800822:	53                   	push   %ebx
  800823:	8b 75 08             	mov    0x8(%ebp),%esi
  800826:	8b 4d 0c             	mov    0xc(%ebp),%ecx
  800829:	8b 55 10             	mov    0x10(%ebp),%edx
  80082c:	89 f0                	mov    %esi,%eax
	char *dst_in;

	dst_in = dst;
	if (size > 0) {
  80082e:	85 d2                	test   %edx,%edx
  800830:	74 21                	je     800853 <strlcpy+0x35>
  800832:	8d 44 16 ff          	lea    -0x1(%esi,%edx,1),%eax
  800836:	89 f2                	mov    %esi,%edx
  800838:	eb 09                	jmp    800843 <strlcpy+0x25>
		while (--size > 0 && *src != '\0')
			*dst++ = *src++;
  80083a:	83 c2 01             	add    $0x1,%edx
  80083d:	83 c1 01             	add    $0x1,%ecx
  800840:	88 5a ff             	mov    %bl,-0x1(%edx)
{
	char *dst_in;

	dst_in = dst;
	if (size > 0) {
		while (--size > 0 && *src != '\0')
  800843:	39 c2                	cmp    %eax,%edx
  800845:	74 09                	je     800850 <strlcpy+0x32>
  800847:	0f b6 19             	movzbl (%ecx),%ebx
  80084a:	84 db                	test   %bl,%bl
  80084c:	75 ec                	jne    80083a <strlcpy+0x1c>
  80084e:	89 d0                	mov    %edx,%eax
			*dst++ = *src++;
		*dst = '\0';
  800850:	c6 00 00             	movb   $0x0,(%eax)
	}
	return dst - dst_in;
  800853:	29 f0                	sub    %esi,%eax
}
  800855:	5b                   	pop    %ebx
  800856:	5e                   	pop    %esi
  800857:	5d                   	pop    %ebp
  800858:	c3                   	ret    

00800859 <strcmp>:

int
strcmp(const char *p, const char *q)
{
  800859:	55                   	push   %ebp
  80085a:	89 e5                	mov    %esp,%ebp
  80085c:	8b 4d 08             	mov    0x8(%ebp),%ecx
  80085f:	8b 55 0c             	mov    0xc(%ebp),%edx
	while (*p && *p == *q)
  800862:	eb 06                	jmp    80086a <strcmp+0x11>
		p++, q++;
  800864:	83 c1 01             	add    $0x1,%ecx
  800867:	83 c2 01             	add    $0x1,%edx
}

int
strcmp(const char *p, const char *q)
{
	while (*p && *p == *q)
  80086a:	0f b6 01             	movzbl (%ecx),%eax
  80086d:	84 c0                	test   %al,%al
  80086f:	74 04                	je     800875 <strcmp+0x1c>
  800871:	3a 02                	cmp    (%edx),%al
  800873:	74 ef                	je     800864 <strcmp+0xb>
		p++, q++;
	return (int) ((unsigned char) *p - (unsigned char) *q);
  800875:	0f b6 c0             	movzbl %al,%eax
  800878:	0f b6 12             	movzbl (%edx),%edx
  80087b:	29 d0                	sub    %edx,%eax
}
  80087d:	5d                   	pop    %ebp
  80087e:	c3                   	ret    

0080087f <strncmp>:

int
strncmp(const char *p, const char *q, size_t n)
{
  80087f:	55                   	push   %ebp
  800880:	89 e5                	mov    %esp,%ebp
  800882:	53                   	push   %ebx
  800883:	8b 45 08             	mov    0x8(%ebp),%eax
  800886:	8b 55 0c             	mov    0xc(%ebp),%edx
  800889:	89 c3                	mov    %eax,%ebx
  80088b:	03 5d 10             	add    0x10(%ebp),%ebx
	while (n > 0 && *p && *p == *q)
  80088e:	eb 06                	jmp    800896 <strncmp+0x17>
		n--, p++, q++;
  800890:	83 c0 01             	add    $0x1,%eax
  800893:	83 c2 01             	add    $0x1,%edx
}

int
strncmp(const char *p, const char *q, size_t n)
{
	while (n > 0 && *p && *p == *q)
  800896:	39 d8                	cmp    %ebx,%eax
  800898:	74 15                	je     8008af <strncmp+0x30>
  80089a:	0f b6 08             	movzbl (%eax),%ecx
  80089d:	84 c9                	test   %cl,%cl
  80089f:	74 04                	je     8008a5 <strncmp+0x26>
  8008a1:	3a 0a                	cmp    (%edx),%cl
  8008a3:	74 eb                	je     800890 <strncmp+0x11>
		n--, p++, q++;
	if (n == 0)
		return 0;
	else
		return (int) ((unsigned char) *p - (unsigned char) *q);
  8008a5:	0f b6 00             	movzbl (%eax),%eax
  8008a8:	0f b6 12             	movzbl (%edx),%edx
  8008ab:	29 d0                	sub    %edx,%eax
  8008ad:	eb 05                	jmp    8008b4 <strncmp+0x35>
strncmp(const char *p, const char *q, size_t n)
{
	while (n > 0 && *p && *p == *q)
		n--, p++, q++;
	if (n == 0)
		return 0;
  8008af:	b8 00 00 00 00       	mov    $0x0,%eax
	else
		return (int) ((unsigned char) *p - (unsigned char) *q);
}
  8008b4:	5b                   	pop    %ebx
  8008b5:	5d                   	pop    %ebp
  8008b6:	c3                   	ret    

008008b7 <strchr>:

// Return a pointer to the first occurrence of 'c' in 's',
// or a null pointer if the string has no 'c'.
char *
strchr(const char *s, char c)
{
  8008b7:	55                   	push   %ebp
  8008b8:	89 e5                	mov    %esp,%ebp
  8008ba:	8b 45 08             	mov    0x8(%ebp),%eax
  8008bd:	0f b6 4d 0c          	movzbl 0xc(%ebp),%ecx
	for (; *s; s++)
  8008c1:	eb 07                	jmp    8008ca <strchr+0x13>
		if (*s == c)
  8008c3:	38 ca                	cmp    %cl,%dl
  8008c5:	74 0f                	je     8008d6 <strchr+0x1f>
// Return a pointer to the first occurrence of 'c' in 's',
// or a null pointer if the string has no 'c'.
char *
strchr(const char *s, char c)
{
	for (; *s; s++)
  8008c7:	83 c0 01             	add    $0x1,%eax
  8008ca:	0f b6 10             	movzbl (%eax),%edx
  8008cd:	84 d2                	test   %dl,%dl
  8008cf:	75 f2                	jne    8008c3 <strchr+0xc>
		if (*s == c)
			return (char *) s;
	return 0;
  8008d1:	b8 00 00 00 00       	mov    $0x0,%eax
}
  8008d6:	5d                   	pop    %ebp
  8008d7:	c3                   	ret    

008008d8 <strfind>:

// Return a pointer to the first occurrence of 'c' in 's',
// or a pointer to the string-ending null character if the string has no 'c'.
char *
strfind(const char *s, char c)
{
  8008d8:	55                   	push   %ebp
  8008d9:	89 e5                	mov    %esp,%ebp
  8008db:	8b 45 08             	mov    0x8(%ebp),%eax
  8008de:	0f b6 4d 0c          	movzbl 0xc(%ebp),%ecx
	for (; *s; s++)
  8008e2:	eb 03                	jmp    8008e7 <strfind+0xf>
  8008e4:	83 c0 01             	add    $0x1,%eax
  8008e7:	0f b6 10             	movzbl (%eax),%edx
		if (*s == c)
  8008ea:	38 ca                	cmp    %cl,%dl
  8008ec:	74 04                	je     8008f2 <strfind+0x1a>
  8008ee:	84 d2                	test   %dl,%dl
  8008f0:	75 f2                	jne    8008e4 <strfind+0xc>
			break;
	return (char *) s;
}
  8008f2:	5d                   	pop    %ebp
  8008f3:	c3                   	ret    

008008f4 <memset>:

#if ASM
void *
memset(void *v, int c, size_t n)
{
  8008f4:	55                   	push   %ebp
  8008f5:	89 e5                	mov    %esp,%ebp
  8008f7:	57                   	push   %edi
  8008f8:	56                   	push   %esi
  8008f9:	53                   	push   %ebx
  8008fa:	8b 55 08             	mov    0x8(%ebp),%edx
  8008fd:	8b 4d 10             	mov    0x10(%ebp),%ecx
	char *p = v;

	if (n == 0)
  800900:	85 c9                	test   %ecx,%ecx
  800902:	74 37                	je     80093b <memset+0x47>
		return v;
	if ((int)v%4 == 0 && n%4 == 0) {
  800904:	f6 c2 03             	test   $0x3,%dl
  800907:	75 2a                	jne    800933 <memset+0x3f>
  800909:	f6 c1 03             	test   $0x3,%cl
  80090c:	75 25                	jne    800933 <memset+0x3f>
		c &= 0xFF;
  80090e:	0f b6 5d 0c          	movzbl 0xc(%ebp),%ebx
		c = (c<<24)|(c<<16)|(c<<8)|c;
  800912:	89 df                	mov    %ebx,%edi
  800914:	c1 e7 08             	shl    $0x8,%edi
  800917:	89 de                	mov    %ebx,%esi
  800919:	c1 e6 18             	shl    $0x18,%esi
  80091c:	89 d8                	mov    %ebx,%eax
  80091e:	c1 e0 10             	shl    $0x10,%eax
  800921:	09 f0                	or     %esi,%eax
  800923:	09 c3                	or     %eax,%ebx
		asm volatile("cld; rep stosl\n"
			: "=D" (p), "=c" (n)
			: "D" (p), "a" (c), "c" (n/4)
  800925:	c1 e9 02             	shr    $0x2,%ecx
	if (n == 0)
		return v;
	if ((int)v%4 == 0 && n%4 == 0) {
		c &= 0xFF;
		c = (c<<24)|(c<<16)|(c<<8)|c;
		asm volatile("cld; rep stosl\n"
  800928:	89 f8                	mov    %edi,%eax
  80092a:	09 d8                	or     %ebx,%eax
  80092c:	89 d7                	mov    %edx,%edi
  80092e:	fc                   	cld    
  80092f:	f3 ab                	rep stos %eax,%es:(%edi)
  800931:	eb 08                	jmp    80093b <memset+0x47>
			: "=D" (p), "=c" (n)
			: "D" (p), "a" (c), "c" (n/4)
			: "cc", "memory");
	} else
		asm volatile("cld; rep stosb\n"
  800933:	89 d7                	mov    %edx,%edi
  800935:	8b 45 0c             	mov    0xc(%ebp),%eax
  800938:	fc                   	cld    
  800939:	f3 aa                	rep stos %al,%es:(%edi)
			: "=D" (p), "=c" (n)
			: "0" (p), "a" (c), "1" (n)
			: "cc", "memory");
	return v;
}
  80093b:	89 d0                	mov    %edx,%eax
  80093d:	5b                   	pop    %ebx
  80093e:	5e                   	pop    %esi
  80093f:	5f                   	pop    %edi
  800940:	5d                   	pop    %ebp
  800941:	c3                   	ret    

00800942 <memmove>:

void *
memmove(void *dst, const void *src, size_t n)
{
  800942:	55                   	push   %ebp
  800943:	89 e5                	mov    %esp,%ebp
  800945:	57                   	push   %edi
  800946:	56                   	push   %esi
  800947:	8b 45 08             	mov    0x8(%ebp),%eax
  80094a:	8b 75 0c             	mov    0xc(%ebp),%esi
  80094d:	8b 4d 10             	mov    0x10(%ebp),%ecx
	const char *s;
	char *d;

	s = src;
	d = dst;
	if (s < d && s + n > d) {
  800950:	39 c6                	cmp    %eax,%esi
  800952:	73 35                	jae    800989 <memmove+0x47>
  800954:	8d 14 0e             	lea    (%esi,%ecx,1),%edx
  800957:	39 d0                	cmp    %edx,%eax
  800959:	73 2e                	jae    800989 <memmove+0x47>
		s += n;
		d += n;
  80095b:	8d 3c 08             	lea    (%eax,%ecx,1),%edi
		if ((int)s%4 == 0 && (int)d%4 == 0 && n%4 == 0)
  80095e:	89 d6                	mov    %edx,%esi
  800960:	09 fe                	or     %edi,%esi
  800962:	f7 c6 03 00 00 00    	test   $0x3,%esi
  800968:	75 13                	jne    80097d <memmove+0x3b>
  80096a:	f6 c1 03             	test   $0x3,%cl
  80096d:	75 0e                	jne    80097d <memmove+0x3b>
			asm volatile("std; rep movsl\n"
  80096f:	83 ef 04             	sub    $0x4,%edi
  800972:	8d 72 fc             	lea    -0x4(%edx),%esi
  800975:	c1 e9 02             	shr    $0x2,%ecx
  800978:	fd                   	std    
  800979:	f3 a5                	rep movsl %ds:(%esi),%es:(%edi)
  80097b:	eb 09                	jmp    800986 <memmove+0x44>
				:: "D" (d-4), "S" (s-4), "c" (n/4) : "cc", "memory");
		else
			asm volatile("std; rep movsb\n"
  80097d:	83 ef 01             	sub    $0x1,%edi
  800980:	8d 72 ff             	lea    -0x1(%edx),%esi
  800983:	fd                   	std    
  800984:	f3 a4                	rep movsb %ds:(%esi),%es:(%edi)
				:: "D" (d-1), "S" (s-1), "c" (n) : "cc", "memory");
		// Some versions of GCC rely on DF being clear
		asm volatile("cld" ::: "cc");
  800986:	fc                   	cld    
  800987:	eb 1d                	jmp    8009a6 <memmove+0x64>
	} else {
		if ((int)s%4 == 0 && (int)d%4 == 0 && n%4 == 0)
  800989:	89 f2                	mov    %esi,%edx
  80098b:	09 c2                	or     %eax,%edx
  80098d:	f6 c2 03             	test   $0x3,%dl
  800990:	75 0f                	jne    8009a1 <memmove+0x5f>
  800992:	f6 c1 03             	test   $0x3,%cl
  800995:	75 0a                	jne    8009a1 <memmove+0x5f>
			asm volatile("cld; rep movsl\n"
  800997:	c1 e9 02             	shr    $0x2,%ecx
  80099a:	89 c7                	mov    %eax,%edi
  80099c:	fc                   	cld    
  80099d:	f3 a5                	rep movsl %ds:(%esi),%es:(%edi)
  80099f:	eb 05                	jmp    8009a6 <memmove+0x64>
				:: "D" (d), "S" (s), "c" (n/4) : "cc", "memory");
		else
			asm volatile("cld; rep movsb\n"
  8009a1:	89 c7                	mov    %eax,%edi
  8009a3:	fc                   	cld    
  8009a4:	f3 a4                	rep movsb %ds:(%esi),%es:(%edi)
				:: "D" (d), "S" (s), "c" (n) : "cc", "memory");
	}
	return dst;
}
  8009a6:	5e                   	pop    %esi
  8009a7:	5f                   	pop    %edi
  8009a8:	5d                   	pop    %ebp
  8009a9:	c3                   	ret    

008009aa <memcpy>:
}
#endif

void *
memcpy(void *dst, const void *src, size_t n)
{
  8009aa:	55                   	push   %ebp
  8009ab:	89 e5                	mov    %esp,%ebp
	return memmove(dst, src, n);
  8009ad:	ff 75 10             	pushl  0x10(%ebp)
  8009b0:	ff 75 0c             	pushl  0xc(%ebp)
  8009b3:	ff 75 08             	pushl  0x8(%ebp)
  8009b6:	e8 87 ff ff ff       	call   800942 <memmove>
}
  8009bb:	c9                   	leave  
  8009bc:	c3                   	ret    

008009bd <memcmp>:

int
memcmp(const void *v1, const void *v2, size_t n)
{
  8009bd:	55                   	push   %ebp
  8009be:	89 e5                	mov    %esp,%ebp
  8009c0:	56                   	push   %esi
  8009c1:	53                   	push   %ebx
  8009c2:	8b 45 08             	mov    0x8(%ebp),%eax
  8009c5:	8b 55 0c             	mov    0xc(%ebp),%edx
  8009c8:	89 c6                	mov    %eax,%esi
  8009ca:	03 75 10             	add    0x10(%ebp),%esi
	const uint8_t *s1 = (const uint8_t *) v1;
	const uint8_t *s2 = (const uint8_t *) v2;

	while (n-- > 0) {
  8009cd:	eb 1a                	jmp    8009e9 <memcmp+0x2c>
		if (*s1 != *s2)
  8009cf:	0f b6 08             	movzbl (%eax),%ecx
  8009d2:	0f b6 1a             	movzbl (%edx),%ebx
  8009d5:	38 d9                	cmp    %bl,%cl
  8009d7:	74 0a                	je     8009e3 <memcmp+0x26>
			return (int) *s1 - (int) *s2;
  8009d9:	0f b6 c1             	movzbl %cl,%eax
  8009dc:	0f b6 db             	movzbl %bl,%ebx
  8009df:	29 d8                	sub    %ebx,%eax
  8009e1:	eb 0f                	jmp    8009f2 <memcmp+0x35>
		s1++, s2++;
  8009e3:	83 c0 01             	add    $0x1,%eax
  8009e6:	83 c2 01             	add    $0x1,%edx
memcmp(const void *v1, const void *v2, size_t n)
{
	const uint8_t *s1 = (const uint8_t *) v1;
	const uint8_t *s2 = (const uint8_t *) v2;

	while (n-- > 0) {
  8009e9:	39 f0                	cmp    %esi,%eax
  8009eb:	75 e2                	jne    8009cf <memcmp+0x12>
		if (*s1 != *s2)
			return (int) *s1 - (int) *s2;
		s1++, s2++;
	}

	return 0;
  8009ed:	b8 00 00 00 00       	mov    $0x0,%eax
}
  8009f2:	5b                   	pop    %ebx
  8009f3:	5e                   	pop    %esi
  8009f4:	5d                   	pop    %ebp
  8009f5:	c3                   	ret    

008009f6 <memfind>:

void *
memfind(const void *s, int c, size_t n)
{
  8009f6:	55                   	push   %ebp
  8009f7:	89 e5                	mov    %esp,%ebp
  8009f9:	8b 45 08             	mov    0x8(%ebp),%eax
  8009fc:	8b 4d 0c             	mov    0xc(%ebp),%ecx
	const void *ends = (const char *) s + n;
  8009ff:	89 c2                	mov    %eax,%edx
  800a01:	03 55 10             	add    0x10(%ebp),%edx
	for (; s < ends; s++)
  800a04:	eb 07                	jmp    800a0d <memfind+0x17>
		if (*(const unsigned char *) s == (unsigned char) c)
  800a06:	38 08                	cmp    %cl,(%eax)
  800a08:	74 07                	je     800a11 <memfind+0x1b>

void *
memfind(const void *s, int c, size_t n)
{
	const void *ends = (const char *) s + n;
	for (; s < ends; s++)
  800a0a:	83 c0 01             	add    $0x1,%eax
  800a0d:	39 d0                	cmp    %edx,%eax
  800a0f:	72 f5                	jb     800a06 <memfind+0x10>
		if (*(const unsigned char *) s == (unsigned char) c)
			break;
	return (void *) s;
}
  800a11:	5d                   	pop    %ebp
  800a12:	c3                   	ret    

00800a13 <strtol>:

long
strtol(const char *s, char **endptr, int base)
{
  800a13:	55                   	push   %ebp
  800a14:	89 e5                	mov    %esp,%ebp
  800a16:	57                   	push   %edi
  800a17:	56                   	push   %esi
  800a18:	53                   	push   %ebx
  800a19:	8b 4d 08             	mov    0x8(%ebp),%ecx
  800a1c:	8b 5d 10             	mov    0x10(%ebp),%ebx
	int neg = 0;
	long val = 0;

	// gobble initial whitespace
	while (*s == ' ' || *s == '\t')
  800a1f:	eb 03                	jmp    800a24 <strtol+0x11>
		s++;
  800a21:	83 c1 01             	add    $0x1,%ecx
{
	int neg = 0;
	long val = 0;

	// gobble initial whitespace
	while (*s == ' ' || *s == '\t')
  800a24:	0f b6 01             	movzbl (%ecx),%eax
  800a27:	3c 20                	cmp    $0x20,%al
  800a29:	74 f6                	je     800a21 <strtol+0xe>
  800a2b:	3c 09                	cmp    $0x9,%al
  800a2d:	74 f2                	je     800a21 <strtol+0xe>
		s++;

	// plus/minus sign
	if (*s == '+')
  800a2f:	3c 2b                	cmp    $0x2b,%al
  800a31:	75 0a                	jne    800a3d <strtol+0x2a>
		s++;
  800a33:	83 c1 01             	add    $0x1,%ecx
}

long
strtol(const char *s, char **endptr, int base)
{
	int neg = 0;
  800a36:	bf 00 00 00 00       	mov    $0x0,%edi
  800a3b:	eb 11                	jmp    800a4e <strtol+0x3b>
  800a3d:	bf 00 00 00 00       	mov    $0x0,%edi
		s++;

	// plus/minus sign
	if (*s == '+')
		s++;
	else if (*s == '-')
  800a42:	3c 2d                	cmp    $0x2d,%al
  800a44:	75 08                	jne    800a4e <strtol+0x3b>
		s++, neg = 1;
  800a46:	83 c1 01             	add    $0x1,%ecx
  800a49:	bf 01 00 00 00       	mov    $0x1,%edi

	// hex or octal base prefix
	if ((base == 0 || base == 16) && (s[0] == '0' && s[1] == 'x'))
  800a4e:	f7 c3 ef ff ff ff    	test   $0xffffffef,%ebx
  800a54:	75 15                	jne    800a6b <strtol+0x58>
  800a56:	80 39 30             	cmpb   $0x30,(%ecx)
  800a59:	75 10                	jne    800a6b <strtol+0x58>
  800a5b:	80 79 01 78          	cmpb   $0x78,0x1(%ecx)
  800a5f:	75 7c                	jne    800add <strtol+0xca>
		s += 2, base = 16;
  800a61:	83 c1 02             	add    $0x2,%ecx
  800a64:	bb 10 00 00 00       	mov    $0x10,%ebx
  800a69:	eb 16                	jmp    800a81 <strtol+0x6e>
	else if (base == 0 && s[0] == '0')
  800a6b:	85 db                	test   %ebx,%ebx
  800a6d:	75 12                	jne    800a81 <strtol+0x6e>
		s++, base = 8;
	else if (base == 0)
		base = 10;
  800a6f:	bb 0a 00 00 00       	mov    $0xa,%ebx
		s++, neg = 1;

	// hex or octal base prefix
	if ((base == 0 || base == 16) && (s[0] == '0' && s[1] == 'x'))
		s += 2, base = 16;
	else if (base == 0 && s[0] == '0')
  800a74:	80 39 30             	cmpb   $0x30,(%ecx)
  800a77:	75 08                	jne    800a81 <strtol+0x6e>
		s++, base = 8;
  800a79:	83 c1 01             	add    $0x1,%ecx
  800a7c:	bb 08 00 00 00       	mov    $0x8,%ebx
	else if (base == 0)
		base = 10;
  800a81:	b8 00 00 00 00       	mov    $0x0,%eax
  800a86:	89 5d 10             	mov    %ebx,0x10(%ebp)

	// digits
	while (1) {
		int dig;

		if (*s >= '0' && *s <= '9')
  800a89:	0f b6 11             	movzbl (%ecx),%edx
  800a8c:	8d 72 d0             	lea    -0x30(%edx),%esi
  800a8f:	89 f3                	mov    %esi,%ebx
  800a91:	80 fb 09             	cmp    $0x9,%bl
  800a94:	77 08                	ja     800a9e <strtol+0x8b>
			dig = *s - '0';
  800a96:	0f be d2             	movsbl %dl,%edx
  800a99:	83 ea 30             	sub    $0x30,%edx
  800a9c:	eb 22                	jmp    800ac0 <strtol+0xad>
		else if (*s >= 'a' && *s <= 'z')
  800a9e:	8d 72 9f             	lea    -0x61(%edx),%esi
  800aa1:	89 f3                	mov    %esi,%ebx
  800aa3:	80 fb 19             	cmp    $0x19,%bl
  800aa6:	77 08                	ja     800ab0 <strtol+0x9d>
			dig = *s - 'a' + 10;
  800aa8:	0f be d2             	movsbl %dl,%edx
  800aab:	83 ea 57             	sub    $0x57,%edx
  800aae:	eb 10                	jmp    800ac0 <strtol+0xad>
		else if (*s >= 'A' && *s <= 'Z')
  800ab0:	8d 72 bf             	lea    -0x41(%edx),%esi
  800ab3:	89 f3                	mov    %esi,%ebx
  800ab5:	80 fb 19             	cmp    $0x19,%bl
  800ab8:	77 16                	ja     800ad0 <strtol+0xbd>
			dig = *s - 'A' + 10;
  800aba:	0f be d2             	movsbl %dl,%edx
  800abd:	83 ea 37             	sub    $0x37,%edx
		else
			break;
		if (dig >= base)
  800ac0:	3b 55 10             	cmp    0x10(%ebp),%edx
  800ac3:	7d 0b                	jge    800ad0 <strtol+0xbd>
			break;
		s++, val = (val * base) + dig;
  800ac5:	83 c1 01             	add    $0x1,%ecx
  800ac8:	0f af 45 10          	imul   0x10(%ebp),%eax
  800acc:	01 d0                	add    %edx,%eax
		// we don't properly detect overflow!
	}
  800ace:	eb b9                	jmp    800a89 <strtol+0x76>

	if (endptr)
  800ad0:	83 7d 0c 00          	cmpl   $0x0,0xc(%ebp)
  800ad4:	74 0d                	je     800ae3 <strtol+0xd0>
		*endptr = (char *) s;
  800ad6:	8b 75 0c             	mov    0xc(%ebp),%esi
  800ad9:	89 0e                	mov    %ecx,(%esi)
  800adb:	eb 06                	jmp    800ae3 <strtol+0xd0>
		s++, neg = 1;

	// hex or octal base prefix
	if ((base == 0 || base == 16) && (s[0] == '0' && s[1] == 'x'))
		s += 2, base = 16;
	else if (base == 0 && s[0] == '0')
  800add:	85 db                	test   %ebx,%ebx
  800adf:	74 98                	je     800a79 <strtol+0x66>
  800ae1:	eb 9e                	jmp    800a81 <strtol+0x6e>
		// we don't properly detect overflow!
	}

	if (endptr)
		*endptr = (char *) s;
	return (neg ? -val : val);
  800ae3:	89 c2                	mov    %eax,%edx
  800ae5:	f7 da                	neg    %edx
  800ae7:	85 ff                	test   %edi,%edi
  800ae9:	0f 45 c2             	cmovne %edx,%eax
}
  800aec:	5b                   	pop    %ebx
  800aed:	5e                   	pop    %esi
  800aee:	5f                   	pop    %edi
  800aef:	5d                   	pop    %ebp
  800af0:	c3                   	ret    
  800af1:	66 90                	xchg   %ax,%ax
  800af3:	66 90                	xchg   %ax,%ax
  800af5:	66 90                	xchg   %ax,%ax
  800af7:	66 90                	xchg   %ax,%ax
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
