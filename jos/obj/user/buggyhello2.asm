
obj/user/buggyhello2:     file format elf32-i386


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

const char *hello = "hello, world\n";

void
umain(int argc, char **argv)
{
  800033:	55                   	push   %ebp
  800034:	89 e5                	mov    %esp,%ebp
  800036:	83 ec 10             	sub    $0x10,%esp
	sys_cputs(hello, 1024*1024);
  800039:	68 00 00 10 00       	push   $0x100000
  80003e:	ff 35 00 20 80 00    	pushl  0x802000
  800044:	e8 a6 00 00 00       	call   8000ef <sys_cputs>
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
  800051:	83 ec 18             	sub    $0x18,%esp
  800054:	8b 45 08             	mov    0x8(%ebp),%eax
  800057:	8b 55 0c             	mov    0xc(%ebp),%edx
	// set thisenv to point at our Env structure in envs[].
	// LAB 3: Your code here.
	thisenv = 0;
  80005a:	c7 05 08 20 80 00 00 	movl   $0x0,0x802008
  800061:	00 00 00 

	// save the name of the program so that panic() can use it
	if (argc > 0)
  800064:	85 c0                	test   %eax,%eax
  800066:	7e 08                	jle    800070 <libmain+0x22>
		binaryname = argv[0];
  800068:	8b 0a                	mov    (%edx),%ecx
  80006a:	89 0d 04 20 80 00    	mov    %ecx,0x802004

	// call user main routine
	umain(argc, argv);
  800070:	89 54 24 04          	mov    %edx,0x4(%esp)
  800074:	89 04 24             	mov    %eax,(%esp)
  800077:	e8 b7 ff ff ff       	call   800033 <umain>

	// exit gracefully
	exit();
  80007c:	e8 02 00 00 00       	call   800083 <exit>
}
  800081:	c9                   	leave  
  800082:	c3                   	ret    

00800083 <exit>:

#include <inc/lib.h>

void
exit(void)
{
  800083:	55                   	push   %ebp
  800084:	89 e5                	mov    %esp,%ebp
  800086:	83 ec 18             	sub    $0x18,%esp
	sys_env_destroy(0);
  800089:	c7 04 24 00 00 00 00 	movl   $0x0,(%esp)
  800090:	e8 cd 00 00 00       	call   800162 <sys_env_destroy>
}
  800095:	c9                   	leave  
  800096:	c3                   	ret    

00800097 <syscall>:
#include <inc/syscall.h>
#include <inc/lib.h>

static inline int32_t
syscall(int num, int check, uint32_t a1, uint32_t a2, uint32_t a3, uint32_t a4, uint32_t a5)
{
  800097:	55                   	push   %ebp
  800098:	89 e5                	mov    %esp,%ebp
  80009a:	57                   	push   %edi
  80009b:	56                   	push   %esi
  80009c:	53                   	push   %ebx
  80009d:	83 ec 2c             	sub    $0x2c,%esp
  8000a0:	89 45 e4             	mov    %eax,-0x1c(%ebp)
  8000a3:	89 55 e0             	mov    %edx,-0x20(%ebp)
  8000a6:	89 ca                	mov    %ecx,%edx
	//
	// The last clause tells the assembler that this can
	// potentially change the condition codes and arbitrary
	// memory locations.

	asm volatile("int %1\n"
  8000a8:	8b 4d 08             	mov    0x8(%ebp),%ecx
  8000ab:	8b 5d 0c             	mov    0xc(%ebp),%ebx
  8000ae:	8b 7d 10             	mov    0x10(%ebp),%edi
  8000b1:	8b 75 14             	mov    0x14(%ebp),%esi
  8000b4:	cd 30                	int    $0x30
		       "b" (a3),
		       "D" (a4),
		       "S" (a5)
		     : "cc", "memory");

	if(check && ret > 0)
  8000b6:	85 c0                	test   %eax,%eax
  8000b8:	7e 2d                	jle    8000e7 <syscall+0x50>
  8000ba:	83 7d e0 00          	cmpl   $0x0,-0x20(%ebp)
  8000be:	74 27                	je     8000e7 <syscall+0x50>
		panic("syscall %d returned %d (> 0)", num, ret);
  8000c0:	89 44 24 10          	mov    %eax,0x10(%esp)
  8000c4:	8b 45 e4             	mov    -0x1c(%ebp),%eax
  8000c7:	89 44 24 0c          	mov    %eax,0xc(%esp)
  8000cb:	c7 44 24 08 cc 0e 80 	movl   $0x800ecc,0x8(%esp)
  8000d2:	00 
  8000d3:	c7 44 24 04 23 00 00 	movl   $0x23,0x4(%esp)
  8000da:	00 
  8000db:	c7 04 24 e9 0e 80 00 	movl   $0x800ee9,(%esp)
  8000e2:	e8 ef 00 00 00       	call   8001d6 <_panic>

	return ret;
}
  8000e7:	83 c4 2c             	add    $0x2c,%esp
  8000ea:	5b                   	pop    %ebx
  8000eb:	5e                   	pop    %esi
  8000ec:	5f                   	pop    %edi
  8000ed:	5d                   	pop    %ebp
  8000ee:	c3                   	ret    

008000ef <sys_cputs>:

void
sys_cputs(const char *s, size_t len)
{
  8000ef:	55                   	push   %ebp
  8000f0:	89 e5                	mov    %esp,%ebp
  8000f2:	83 ec 18             	sub    $0x18,%esp
	syscall(SYS_cputs, 0, (uint32_t)s, len, 0, 0, 0);
  8000f5:	c7 44 24 0c 00 00 00 	movl   $0x0,0xc(%esp)
  8000fc:	00 
  8000fd:	c7 44 24 08 00 00 00 	movl   $0x0,0x8(%esp)
  800104:	00 
  800105:	c7 44 24 04 00 00 00 	movl   $0x0,0x4(%esp)
  80010c:	00 
  80010d:	8b 45 0c             	mov    0xc(%ebp),%eax
  800110:	89 04 24             	mov    %eax,(%esp)
  800113:	8b 4d 08             	mov    0x8(%ebp),%ecx
  800116:	ba 00 00 00 00       	mov    $0x0,%edx
  80011b:	b8 00 00 00 00       	mov    $0x0,%eax
  800120:	e8 72 ff ff ff       	call   800097 <syscall>
}
  800125:	c9                   	leave  
  800126:	c3                   	ret    

00800127 <sys_cgetc>:

int
sys_cgetc(void)
{
  800127:	55                   	push   %ebp
  800128:	89 e5                	mov    %esp,%ebp
  80012a:	83 ec 18             	sub    $0x18,%esp
	return syscall(SYS_cgetc, 0, 0, 0, 0, 0, 0);
  80012d:	c7 44 24 0c 00 00 00 	movl   $0x0,0xc(%esp)
  800134:	00 
  800135:	c7 44 24 08 00 00 00 	movl   $0x0,0x8(%esp)
  80013c:	00 
  80013d:	c7 44 24 04 00 00 00 	movl   $0x0,0x4(%esp)
  800144:	00 
  800145:	c7 04 24 00 00 00 00 	movl   $0x0,(%esp)
  80014c:	b9 00 00 00 00       	mov    $0x0,%ecx
  800151:	ba 00 00 00 00       	mov    $0x0,%edx
  800156:	b8 01 00 00 00       	mov    $0x1,%eax
  80015b:	e8 37 ff ff ff       	call   800097 <syscall>
}
  800160:	c9                   	leave  
  800161:	c3                   	ret    

00800162 <sys_env_destroy>:

int
sys_env_destroy(envid_t envid)
{
  800162:	55                   	push   %ebp
  800163:	89 e5                	mov    %esp,%ebp
  800165:	83 ec 18             	sub    $0x18,%esp
	return syscall(SYS_env_destroy, 1, envid, 0, 0, 0, 0);
  800168:	c7 44 24 0c 00 00 00 	movl   $0x0,0xc(%esp)
  80016f:	00 
  800170:	c7 44 24 08 00 00 00 	movl   $0x0,0x8(%esp)
  800177:	00 
  800178:	c7 44 24 04 00 00 00 	movl   $0x0,0x4(%esp)
  80017f:	00 
  800180:	c7 04 24 00 00 00 00 	movl   $0x0,(%esp)
  800187:	8b 4d 08             	mov    0x8(%ebp),%ecx
  80018a:	ba 01 00 00 00       	mov    $0x1,%edx
  80018f:	b8 03 00 00 00       	mov    $0x3,%eax
  800194:	e8 fe fe ff ff       	call   800097 <syscall>
}
  800199:	c9                   	leave  
  80019a:	c3                   	ret    

0080019b <sys_getenvid>:

envid_t
sys_getenvid(void)
{
  80019b:	55                   	push   %ebp
  80019c:	89 e5                	mov    %esp,%ebp
  80019e:	83 ec 18             	sub    $0x18,%esp
	 return syscall(SYS_getenvid, 0, 0, 0, 0, 0, 0);
  8001a1:	c7 44 24 0c 00 00 00 	movl   $0x0,0xc(%esp)
  8001a8:	00 
  8001a9:	c7 44 24 08 00 00 00 	movl   $0x0,0x8(%esp)
  8001b0:	00 
  8001b1:	c7 44 24 04 00 00 00 	movl   $0x0,0x4(%esp)
  8001b8:	00 
  8001b9:	c7 04 24 00 00 00 00 	movl   $0x0,(%esp)
  8001c0:	b9 00 00 00 00       	mov    $0x0,%ecx
  8001c5:	ba 00 00 00 00       	mov    $0x0,%edx
  8001ca:	b8 02 00 00 00       	mov    $0x2,%eax
  8001cf:	e8 c3 fe ff ff       	call   800097 <syscall>
}
  8001d4:	c9                   	leave  
  8001d5:	c3                   	ret    

008001d6 <_panic>:
 * It prints "panic: <message>", then causes a breakpoint exception,
 * which causes JOS to enter the JOS kernel monitor.
 */
void
_panic(const char *file, int line, const char *fmt, ...)
{
  8001d6:	55                   	push   %ebp
  8001d7:	89 e5                	mov    %esp,%ebp
  8001d9:	56                   	push   %esi
  8001da:	53                   	push   %ebx
  8001db:	83 ec 20             	sub    $0x20,%esp
	va_list ap;

	va_start(ap, fmt);
  8001de:	8d 5d 14             	lea    0x14(%ebp),%ebx

	// Print the panic message
	cprintf("[%08x] user panic in %s at %s:%d: ",
  8001e1:	8b 35 04 20 80 00    	mov    0x802004,%esi
  8001e7:	e8 af ff ff ff       	call   80019b <sys_getenvid>
  8001ec:	8b 55 0c             	mov    0xc(%ebp),%edx
  8001ef:	89 54 24 10          	mov    %edx,0x10(%esp)
  8001f3:	8b 55 08             	mov    0x8(%ebp),%edx
  8001f6:	89 54 24 0c          	mov    %edx,0xc(%esp)
  8001fa:	89 74 24 08          	mov    %esi,0x8(%esp)
  8001fe:	89 44 24 04          	mov    %eax,0x4(%esp)
  800202:	c7 04 24 f8 0e 80 00 	movl   $0x800ef8,(%esp)
  800209:	e8 c1 00 00 00       	call   8002cf <cprintf>
		sys_getenvid(), binaryname, file, line);
	vcprintf(fmt, ap);
  80020e:	89 5c 24 04          	mov    %ebx,0x4(%esp)
  800212:	8b 45 10             	mov    0x10(%ebp),%eax
  800215:	89 04 24             	mov    %eax,(%esp)
  800218:	e8 51 00 00 00       	call   80026e <vcprintf>
	cprintf("\n");
  80021d:	c7 04 24 c0 0e 80 00 	movl   $0x800ec0,(%esp)
  800224:	e8 a6 00 00 00       	call   8002cf <cprintf>

	// Cause a breakpoint exception
	while (1)
		asm volatile("int3");
  800229:	cc                   	int3   
  80022a:	eb fd                	jmp    800229 <_panic+0x53>

0080022c <putch>:
};


static void
putch(int ch, struct printbuf *b)
{
  80022c:	55                   	push   %ebp
  80022d:	89 e5                	mov    %esp,%ebp
  80022f:	53                   	push   %ebx
  800230:	83 ec 14             	sub    $0x14,%esp
  800233:	8b 5d 0c             	mov    0xc(%ebp),%ebx
	b->buf[b->idx++] = ch;
  800236:	8b 13                	mov    (%ebx),%edx
  800238:	8d 42 01             	lea    0x1(%edx),%eax
  80023b:	89 03                	mov    %eax,(%ebx)
  80023d:	8b 4d 08             	mov    0x8(%ebp),%ecx
  800240:	88 4c 13 08          	mov    %cl,0x8(%ebx,%edx,1)
	if (b->idx == 256-1) {
  800244:	3d ff 00 00 00       	cmp    $0xff,%eax
  800249:	75 19                	jne    800264 <putch+0x38>
		sys_cputs(b->buf, b->idx);
  80024b:	c7 44 24 04 ff 00 00 	movl   $0xff,0x4(%esp)
  800252:	00 
  800253:	8d 43 08             	lea    0x8(%ebx),%eax
  800256:	89 04 24             	mov    %eax,(%esp)
  800259:	e8 91 fe ff ff       	call   8000ef <sys_cputs>
		b->idx = 0;
  80025e:	c7 03 00 00 00 00    	movl   $0x0,(%ebx)
	}
	b->cnt++;
  800264:	83 43 04 01          	addl   $0x1,0x4(%ebx)
}
  800268:	83 c4 14             	add    $0x14,%esp
  80026b:	5b                   	pop    %ebx
  80026c:	5d                   	pop    %ebp
  80026d:	c3                   	ret    

0080026e <vcprintf>:

int
vcprintf(const char *fmt, va_list ap)
{
  80026e:	55                   	push   %ebp
  80026f:	89 e5                	mov    %esp,%ebp
  800271:	81 ec 28 01 00 00    	sub    $0x128,%esp
	struct printbuf b;

	b.idx = 0;
  800277:	c7 85 f0 fe ff ff 00 	movl   $0x0,-0x110(%ebp)
  80027e:	00 00 00 
	b.cnt = 0;
  800281:	c7 85 f4 fe ff ff 00 	movl   $0x0,-0x10c(%ebp)
  800288:	00 00 00 
	vprintfmt((void*)putch, &b, fmt, ap);
  80028b:	8b 45 0c             	mov    0xc(%ebp),%eax
  80028e:	89 44 24 0c          	mov    %eax,0xc(%esp)
  800292:	8b 45 08             	mov    0x8(%ebp),%eax
  800295:	89 44 24 08          	mov    %eax,0x8(%esp)
  800299:	8d 85 f0 fe ff ff    	lea    -0x110(%ebp),%eax
  80029f:	89 44 24 04          	mov    %eax,0x4(%esp)
  8002a3:	c7 04 24 2c 02 80 00 	movl   $0x80022c,(%esp)
  8002aa:	e8 e1 01 00 00       	call   800490 <vprintfmt>
	sys_cputs(b.buf, b.idx);
  8002af:	8b 85 f0 fe ff ff    	mov    -0x110(%ebp),%eax
  8002b5:	89 44 24 04          	mov    %eax,0x4(%esp)
  8002b9:	8d 85 f8 fe ff ff    	lea    -0x108(%ebp),%eax
  8002bf:	89 04 24             	mov    %eax,(%esp)
  8002c2:	e8 28 fe ff ff       	call   8000ef <sys_cputs>

	return b.cnt;
}
  8002c7:	8b 85 f4 fe ff ff    	mov    -0x10c(%ebp),%eax
  8002cd:	c9                   	leave  
  8002ce:	c3                   	ret    

008002cf <cprintf>:

int
cprintf(const char *fmt, ...)
{
  8002cf:	55                   	push   %ebp
  8002d0:	89 e5                	mov    %esp,%ebp
  8002d2:	83 ec 18             	sub    $0x18,%esp
	va_list ap;
	int cnt;

	va_start(ap, fmt);
  8002d5:	8d 45 0c             	lea    0xc(%ebp),%eax
	cnt = vcprintf(fmt, ap);
  8002d8:	89 44 24 04          	mov    %eax,0x4(%esp)
  8002dc:	8b 45 08             	mov    0x8(%ebp),%eax
  8002df:	89 04 24             	mov    %eax,(%esp)
  8002e2:	e8 87 ff ff ff       	call   80026e <vcprintf>
	va_end(ap);

	return cnt;
}
  8002e7:	c9                   	leave  
  8002e8:	c3                   	ret    
  8002e9:	66 90                	xchg   %ax,%ax
  8002eb:	66 90                	xchg   %ax,%ax
  8002ed:	66 90                	xchg   %ax,%ax
  8002ef:	90                   	nop

008002f0 <printnum>:
 * using specified putch function and associated pointer putdat.
 */
static void
printnum(void (*putch)(int, void*), void *putdat,
	 unsigned long long num, unsigned base, int width, int padc)
{
  8002f0:	55                   	push   %ebp
  8002f1:	89 e5                	mov    %esp,%ebp
  8002f3:	57                   	push   %edi
  8002f4:	56                   	push   %esi
  8002f5:	53                   	push   %ebx
  8002f6:	83 ec 3c             	sub    $0x3c,%esp
  8002f9:	89 45 e4             	mov    %eax,-0x1c(%ebp)
  8002fc:	89 d7                	mov    %edx,%edi
  8002fe:	8b 45 08             	mov    0x8(%ebp),%eax
  800301:	89 45 e0             	mov    %eax,-0x20(%ebp)
  800304:	8b 45 0c             	mov    0xc(%ebp),%eax
  800307:	89 c3                	mov    %eax,%ebx
  800309:	89 45 d4             	mov    %eax,-0x2c(%ebp)
  80030c:	8b 45 10             	mov    0x10(%ebp),%eax
  80030f:	8b 75 14             	mov    0x14(%ebp),%esi
	// first recursively print all preceding (more significant) digits
	if (num >= base) {
  800312:	b9 00 00 00 00       	mov    $0x0,%ecx
  800317:	89 45 d8             	mov    %eax,-0x28(%ebp)
  80031a:	89 4d dc             	mov    %ecx,-0x24(%ebp)
  80031d:	39 d9                	cmp    %ebx,%ecx
  80031f:	72 05                	jb     800326 <printnum+0x36>
  800321:	3b 45 e0             	cmp    -0x20(%ebp),%eax
  800324:	77 69                	ja     80038f <printnum+0x9f>
		printnum(putch, putdat, num / base, base, width - 1, padc);
  800326:	8b 4d 18             	mov    0x18(%ebp),%ecx
  800329:	89 4c 24 10          	mov    %ecx,0x10(%esp)
  80032d:	83 ee 01             	sub    $0x1,%esi
  800330:	89 74 24 0c          	mov    %esi,0xc(%esp)
  800334:	89 44 24 08          	mov    %eax,0x8(%esp)
  800338:	8b 44 24 08          	mov    0x8(%esp),%eax
  80033c:	8b 54 24 0c          	mov    0xc(%esp),%edx
  800340:	89 c3                	mov    %eax,%ebx
  800342:	89 d6                	mov    %edx,%esi
  800344:	8b 55 d8             	mov    -0x28(%ebp),%edx
  800347:	8b 4d dc             	mov    -0x24(%ebp),%ecx
  80034a:	89 54 24 08          	mov    %edx,0x8(%esp)
  80034e:	89 4c 24 0c          	mov    %ecx,0xc(%esp)
  800352:	8b 45 e0             	mov    -0x20(%ebp),%eax
  800355:	89 04 24             	mov    %eax,(%esp)
  800358:	8b 45 d4             	mov    -0x2c(%ebp),%eax
  80035b:	89 44 24 04          	mov    %eax,0x4(%esp)
  80035f:	e8 cc 08 00 00       	call   800c30 <__udivdi3>
  800364:	89 d9                	mov    %ebx,%ecx
  800366:	89 4c 24 08          	mov    %ecx,0x8(%esp)
  80036a:	89 74 24 0c          	mov    %esi,0xc(%esp)
  80036e:	89 04 24             	mov    %eax,(%esp)
  800371:	89 54 24 04          	mov    %edx,0x4(%esp)
  800375:	89 fa                	mov    %edi,%edx
  800377:	8b 45 e4             	mov    -0x1c(%ebp),%eax
  80037a:	e8 71 ff ff ff       	call   8002f0 <printnum>
  80037f:	eb 1b                	jmp    80039c <printnum+0xac>
	} else {
		// print any needed pad characters before first digit
		while (--width > 0)
			putch(padc, putdat);
  800381:	89 7c 24 04          	mov    %edi,0x4(%esp)
  800385:	8b 45 18             	mov    0x18(%ebp),%eax
  800388:	89 04 24             	mov    %eax,(%esp)
  80038b:	ff d3                	call   *%ebx
  80038d:	eb 03                	jmp    800392 <printnum+0xa2>
  80038f:	8b 5d e4             	mov    -0x1c(%ebp),%ebx
	// first recursively print all preceding (more significant) digits
	if (num >= base) {
		printnum(putch, putdat, num / base, base, width - 1, padc);
	} else {
		// print any needed pad characters before first digit
		while (--width > 0)
  800392:	83 ee 01             	sub    $0x1,%esi
  800395:	85 f6                	test   %esi,%esi
  800397:	7f e8                	jg     800381 <printnum+0x91>
  800399:	89 5d e4             	mov    %ebx,-0x1c(%ebp)
			putch(padc, putdat);
	}

	// then print this (the least significant) digit
	putch("0123456789abcdef"[num % base], putdat);
  80039c:	89 7c 24 04          	mov    %edi,0x4(%esp)
  8003a0:	8b 7c 24 04          	mov    0x4(%esp),%edi
  8003a4:	8b 45 d8             	mov    -0x28(%ebp),%eax
  8003a7:	8b 55 dc             	mov    -0x24(%ebp),%edx
  8003aa:	89 44 24 08          	mov    %eax,0x8(%esp)
  8003ae:	89 54 24 0c          	mov    %edx,0xc(%esp)
  8003b2:	8b 45 e0             	mov    -0x20(%ebp),%eax
  8003b5:	89 04 24             	mov    %eax,(%esp)
  8003b8:	8b 45 d4             	mov    -0x2c(%ebp),%eax
  8003bb:	89 44 24 04          	mov    %eax,0x4(%esp)
  8003bf:	e8 9c 09 00 00       	call   800d60 <__umoddi3>
  8003c4:	89 7c 24 04          	mov    %edi,0x4(%esp)
  8003c8:	0f be 80 1c 0f 80 00 	movsbl 0x800f1c(%eax),%eax
  8003cf:	89 04 24             	mov    %eax,(%esp)
  8003d2:	8b 45 e4             	mov    -0x1c(%ebp),%eax
  8003d5:	ff d0                	call   *%eax
}
  8003d7:	83 c4 3c             	add    $0x3c,%esp
  8003da:	5b                   	pop    %ebx
  8003db:	5e                   	pop    %esi
  8003dc:	5f                   	pop    %edi
  8003dd:	5d                   	pop    %ebp
  8003de:	c3                   	ret    

008003df <getuint>:

// Get an unsigned int of various possible sizes from a varargs list,
// depending on the lflag parameter.
static unsigned long long
getuint(va_list *ap, int lflag)
{
  8003df:	55                   	push   %ebp
  8003e0:	89 e5                	mov    %esp,%ebp
	if (lflag >= 2)
  8003e2:	83 fa 01             	cmp    $0x1,%edx
  8003e5:	7e 0e                	jle    8003f5 <getuint+0x16>
		return va_arg(*ap, unsigned long long);
  8003e7:	8b 10                	mov    (%eax),%edx
  8003e9:	8d 4a 08             	lea    0x8(%edx),%ecx
  8003ec:	89 08                	mov    %ecx,(%eax)
  8003ee:	8b 02                	mov    (%edx),%eax
  8003f0:	8b 52 04             	mov    0x4(%edx),%edx
  8003f3:	eb 22                	jmp    800417 <getuint+0x38>
	else if (lflag)
  8003f5:	85 d2                	test   %edx,%edx
  8003f7:	74 10                	je     800409 <getuint+0x2a>
		return va_arg(*ap, unsigned long);
  8003f9:	8b 10                	mov    (%eax),%edx
  8003fb:	8d 4a 04             	lea    0x4(%edx),%ecx
  8003fe:	89 08                	mov    %ecx,(%eax)
  800400:	8b 02                	mov    (%edx),%eax
  800402:	ba 00 00 00 00       	mov    $0x0,%edx
  800407:	eb 0e                	jmp    800417 <getuint+0x38>
	else
		return va_arg(*ap, unsigned int);
  800409:	8b 10                	mov    (%eax),%edx
  80040b:	8d 4a 04             	lea    0x4(%edx),%ecx
  80040e:	89 08                	mov    %ecx,(%eax)
  800410:	8b 02                	mov    (%edx),%eax
  800412:	ba 00 00 00 00       	mov    $0x0,%edx
}
  800417:	5d                   	pop    %ebp
  800418:	c3                   	ret    

00800419 <getint>:

// Same as getuint but signed - can't use getuint
// because of sign extension
static long long
getint(va_list *ap, int lflag)
{
  800419:	55                   	push   %ebp
  80041a:	89 e5                	mov    %esp,%ebp
	if (lflag >= 2)
  80041c:	83 fa 01             	cmp    $0x1,%edx
  80041f:	7e 0e                	jle    80042f <getint+0x16>
		return va_arg(*ap, long long);
  800421:	8b 10                	mov    (%eax),%edx
  800423:	8d 4a 08             	lea    0x8(%edx),%ecx
  800426:	89 08                	mov    %ecx,(%eax)
  800428:	8b 02                	mov    (%edx),%eax
  80042a:	8b 52 04             	mov    0x4(%edx),%edx
  80042d:	eb 1a                	jmp    800449 <getint+0x30>
	else if (lflag)
  80042f:	85 d2                	test   %edx,%edx
  800431:	74 0c                	je     80043f <getint+0x26>
		return va_arg(*ap, long);
  800433:	8b 10                	mov    (%eax),%edx
  800435:	8d 4a 04             	lea    0x4(%edx),%ecx
  800438:	89 08                	mov    %ecx,(%eax)
  80043a:	8b 02                	mov    (%edx),%eax
  80043c:	99                   	cltd   
  80043d:	eb 0a                	jmp    800449 <getint+0x30>
	else
		return va_arg(*ap, int);
  80043f:	8b 10                	mov    (%eax),%edx
  800441:	8d 4a 04             	lea    0x4(%edx),%ecx
  800444:	89 08                	mov    %ecx,(%eax)
  800446:	8b 02                	mov    (%edx),%eax
  800448:	99                   	cltd   
}
  800449:	5d                   	pop    %ebp
  80044a:	c3                   	ret    

0080044b <sprintputch>:
	int cnt;
};

static void
sprintputch(int ch, struct sprintbuf *b)
{
  80044b:	55                   	push   %ebp
  80044c:	89 e5                	mov    %esp,%ebp
  80044e:	8b 45 0c             	mov    0xc(%ebp),%eax
	b->cnt++;
  800451:	83 40 08 01          	addl   $0x1,0x8(%eax)
	if (b->buf < b->ebuf)
  800455:	8b 10                	mov    (%eax),%edx
  800457:	3b 50 04             	cmp    0x4(%eax),%edx
  80045a:	73 0a                	jae    800466 <sprintputch+0x1b>
		*b->buf++ = ch;
  80045c:	8d 4a 01             	lea    0x1(%edx),%ecx
  80045f:	89 08                	mov    %ecx,(%eax)
  800461:	8b 45 08             	mov    0x8(%ebp),%eax
  800464:	88 02                	mov    %al,(%edx)
}
  800466:	5d                   	pop    %ebp
  800467:	c3                   	ret    

00800468 <printfmt>:
	}
}

void
printfmt(void (*putch)(int, void*), void *putdat, const char *fmt, ...)
{
  800468:	55                   	push   %ebp
  800469:	89 e5                	mov    %esp,%ebp
  80046b:	83 ec 18             	sub    $0x18,%esp
	va_list ap;

	va_start(ap, fmt);
  80046e:	8d 45 14             	lea    0x14(%ebp),%eax
	vprintfmt(putch, putdat, fmt, ap);
  800471:	89 44 24 0c          	mov    %eax,0xc(%esp)
  800475:	8b 45 10             	mov    0x10(%ebp),%eax
  800478:	89 44 24 08          	mov    %eax,0x8(%esp)
  80047c:	8b 45 0c             	mov    0xc(%ebp),%eax
  80047f:	89 44 24 04          	mov    %eax,0x4(%esp)
  800483:	8b 45 08             	mov    0x8(%ebp),%eax
  800486:	89 04 24             	mov    %eax,(%esp)
  800489:	e8 02 00 00 00       	call   800490 <vprintfmt>
	va_end(ap);
}
  80048e:	c9                   	leave  
  80048f:	c3                   	ret    

00800490 <vprintfmt>:
// Main function to format and print a string.
void printfmt(void (*putch)(int, void*), void *putdat, const char *fmt, ...);

void
vprintfmt(void (*putch)(int, void*), void *putdat, const char *fmt, va_list ap)
{
  800490:	55                   	push   %ebp
  800491:	89 e5                	mov    %esp,%ebp
  800493:	57                   	push   %edi
  800494:	56                   	push   %esi
  800495:	53                   	push   %ebx
  800496:	83 ec 3c             	sub    $0x3c,%esp
  800499:	8b 75 0c             	mov    0xc(%ebp),%esi
  80049c:	8b 7d 10             	mov    0x10(%ebp),%edi
  80049f:	eb 14                	jmp    8004b5 <vprintfmt+0x25>
	int base, lflag, width, precision, altflag;
	char padc;

	while (1) {
		while ((ch = *(unsigned char *) fmt++) != '%') {
			if (ch == '\0')
  8004a1:	85 c0                	test   %eax,%eax
  8004a3:	0f 84 63 03 00 00    	je     80080c <vprintfmt+0x37c>
				return;
			putch(ch, putdat);
  8004a9:	89 74 24 04          	mov    %esi,0x4(%esp)
  8004ad:	89 04 24             	mov    %eax,(%esp)
  8004b0:	ff 55 08             	call   *0x8(%ebp)
	unsigned long long num;
	int base, lflag, width, precision, altflag;
	char padc;

	while (1) {
		while ((ch = *(unsigned char *) fmt++) != '%') {
  8004b3:	89 df                	mov    %ebx,%edi
  8004b5:	8d 5f 01             	lea    0x1(%edi),%ebx
  8004b8:	0f b6 07             	movzbl (%edi),%eax
  8004bb:	83 f8 25             	cmp    $0x25,%eax
  8004be:	75 e1                	jne    8004a1 <vprintfmt+0x11>
  8004c0:	c6 45 d8 20          	movb   $0x20,-0x28(%ebp)
  8004c4:	c7 45 e0 00 00 00 00 	movl   $0x0,-0x20(%ebp)
  8004cb:	c7 45 d4 ff ff ff ff 	movl   $0xffffffff,-0x2c(%ebp)
  8004d2:	c7 45 dc ff ff ff ff 	movl   $0xffffffff,-0x24(%ebp)
  8004d9:	ba 00 00 00 00       	mov    $0x0,%edx
  8004de:	eb 1d                	jmp    8004fd <vprintfmt+0x6d>
		width = -1;
		precision = -1;
		lflag = 0;
		altflag = 0;
	reswitch:
		switch (ch = *(unsigned char *) fmt++) {
  8004e0:	89 fb                	mov    %edi,%ebx

		// flag to pad on the right
		case '-':
			padc = '-';
  8004e2:	c6 45 d8 2d          	movb   $0x2d,-0x28(%ebp)
  8004e6:	eb 15                	jmp    8004fd <vprintfmt+0x6d>
		width = -1;
		precision = -1;
		lflag = 0;
		altflag = 0;
	reswitch:
		switch (ch = *(unsigned char *) fmt++) {
  8004e8:	89 fb                	mov    %edi,%ebx
			padc = '-';
			goto reswitch;

		// flag to pad with 0's instead of spaces
		case '0':
			padc = '0';
  8004ea:	c6 45 d8 30          	movb   $0x30,-0x28(%ebp)
  8004ee:	eb 0d                	jmp    8004fd <vprintfmt+0x6d>
			altflag = 1;
			goto reswitch;

		process_precision:
			if (width < 0)
				width = precision, precision = -1;
  8004f0:	8b 45 d4             	mov    -0x2c(%ebp),%eax
  8004f3:	89 45 dc             	mov    %eax,-0x24(%ebp)
  8004f6:	c7 45 d4 ff ff ff ff 	movl   $0xffffffff,-0x2c(%ebp)
		width = -1;
		precision = -1;
		lflag = 0;
		altflag = 0;
	reswitch:
		switch (ch = *(unsigned char *) fmt++) {
  8004fd:	8d 7b 01             	lea    0x1(%ebx),%edi
  800500:	0f b6 0b             	movzbl (%ebx),%ecx
  800503:	0f b6 c1             	movzbl %cl,%eax
  800506:	83 e9 23             	sub    $0x23,%ecx
  800509:	80 f9 55             	cmp    $0x55,%cl
  80050c:	0f 87 da 02 00 00    	ja     8007ec <vprintfmt+0x35c>
  800512:	0f b6 c9             	movzbl %cl,%ecx
  800515:	ff 24 8d ac 0f 80 00 	jmp    *0x800fac(,%ecx,4)
  80051c:	89 fb                	mov    %edi,%ebx
  80051e:	b9 00 00 00 00       	mov    $0x0,%ecx
		case '6':
		case '7':
		case '8':
		case '9':
			for (precision = 0; ; ++fmt) {
				precision = precision * 10 + ch - '0';
  800523:	8d 0c 89             	lea    (%ecx,%ecx,4),%ecx
  800526:	8d 4c 48 d0          	lea    -0x30(%eax,%ecx,2),%ecx
				ch = *fmt;
  80052a:	0f be 03             	movsbl (%ebx),%eax
				if (ch < '0' || ch > '9')
  80052d:	8d 78 d0             	lea    -0x30(%eax),%edi
  800530:	83 ff 09             	cmp    $0x9,%edi
  800533:	77 36                	ja     80056b <vprintfmt+0xdb>
		case '5':
		case '6':
		case '7':
		case '8':
		case '9':
			for (precision = 0; ; ++fmt) {
  800535:	83 c3 01             	add    $0x1,%ebx
				precision = precision * 10 + ch - '0';
				ch = *fmt;
				if (ch < '0' || ch > '9')
					break;
			}
  800538:	eb e9                	jmp    800523 <vprintfmt+0x93>
			goto process_precision;

		case '*':
			precision = va_arg(ap, int);
  80053a:	8b 45 14             	mov    0x14(%ebp),%eax
  80053d:	8d 48 04             	lea    0x4(%eax),%ecx
  800540:	89 4d 14             	mov    %ecx,0x14(%ebp)
  800543:	8b 00                	mov    (%eax),%eax
  800545:	89 45 d4             	mov    %eax,-0x2c(%ebp)
		width = -1;
		precision = -1;
		lflag = 0;
		altflag = 0;
	reswitch:
		switch (ch = *(unsigned char *) fmt++) {
  800548:	89 fb                	mov    %edi,%ebx
			}
			goto process_precision;

		case '*':
			precision = va_arg(ap, int);
			goto process_precision;
  80054a:	eb 22                	jmp    80056e <vprintfmt+0xde>
  80054c:	8b 4d dc             	mov    -0x24(%ebp),%ecx
  80054f:	85 c9                	test   %ecx,%ecx
  800551:	b8 00 00 00 00       	mov    $0x0,%eax
  800556:	0f 49 c1             	cmovns %ecx,%eax
  800559:	89 45 dc             	mov    %eax,-0x24(%ebp)
		width = -1;
		precision = -1;
		lflag = 0;
		altflag = 0;
	reswitch:
		switch (ch = *(unsigned char *) fmt++) {
  80055c:	89 fb                	mov    %edi,%ebx
  80055e:	eb 9d                	jmp    8004fd <vprintfmt+0x6d>
  800560:	89 fb                	mov    %edi,%ebx
			if (width < 0)
				width = 0;
			goto reswitch;

		case '#':
			altflag = 1;
  800562:	c7 45 e0 01 00 00 00 	movl   $0x1,-0x20(%ebp)
			goto reswitch;
  800569:	eb 92                	jmp    8004fd <vprintfmt+0x6d>
  80056b:	89 4d d4             	mov    %ecx,-0x2c(%ebp)

		process_precision:
			if (width < 0)
  80056e:	83 7d dc 00          	cmpl   $0x0,-0x24(%ebp)
  800572:	79 89                	jns    8004fd <vprintfmt+0x6d>
  800574:	e9 77 ff ff ff       	jmp    8004f0 <vprintfmt+0x60>
				width = precision, precision = -1;
			goto reswitch;

		// long flag (doubled for long long)
		case 'l':
			lflag++;
  800579:	83 c2 01             	add    $0x1,%edx
		width = -1;
		precision = -1;
		lflag = 0;
		altflag = 0;
	reswitch:
		switch (ch = *(unsigned char *) fmt++) {
  80057c:	89 fb                	mov    %edi,%ebx
			goto reswitch;

		// long flag (doubled for long long)
		case 'l':
			lflag++;
			goto reswitch;
  80057e:	e9 7a ff ff ff       	jmp    8004fd <vprintfmt+0x6d>

		// character
		case 'c':
			putch(va_arg(ap, int), putdat);
  800583:	8b 45 14             	mov    0x14(%ebp),%eax
  800586:	8d 50 04             	lea    0x4(%eax),%edx
  800589:	89 55 14             	mov    %edx,0x14(%ebp)
  80058c:	89 74 24 04          	mov    %esi,0x4(%esp)
  800590:	8b 00                	mov    (%eax),%eax
  800592:	89 04 24             	mov    %eax,(%esp)
  800595:	ff 55 08             	call   *0x8(%ebp)
			break;
  800598:	e9 18 ff ff ff       	jmp    8004b5 <vprintfmt+0x25>

		// error message
		case 'e':
			err = va_arg(ap, int);
  80059d:	8b 45 14             	mov    0x14(%ebp),%eax
  8005a0:	8d 50 04             	lea    0x4(%eax),%edx
  8005a3:	89 55 14             	mov    %edx,0x14(%ebp)
  8005a6:	8b 00                	mov    (%eax),%eax
  8005a8:	99                   	cltd   
  8005a9:	31 d0                	xor    %edx,%eax
  8005ab:	29 d0                	sub    %edx,%eax
			if (err < 0)
				err = -err;
			if (err >= MAXERROR || (p = error_string[err]) == NULL)
  8005ad:	83 f8 06             	cmp    $0x6,%eax
  8005b0:	7f 0b                	jg     8005bd <vprintfmt+0x12d>
  8005b2:	8b 14 85 04 11 80 00 	mov    0x801104(,%eax,4),%edx
  8005b9:	85 d2                	test   %edx,%edx
  8005bb:	75 20                	jne    8005dd <vprintfmt+0x14d>
				printfmt(putch, putdat, "error %d", err);
  8005bd:	89 44 24 0c          	mov    %eax,0xc(%esp)
  8005c1:	c7 44 24 08 34 0f 80 	movl   $0x800f34,0x8(%esp)
  8005c8:	00 
  8005c9:	89 74 24 04          	mov    %esi,0x4(%esp)
  8005cd:	8b 45 08             	mov    0x8(%ebp),%eax
  8005d0:	89 04 24             	mov    %eax,(%esp)
  8005d3:	e8 90 fe ff ff       	call   800468 <printfmt>
  8005d8:	e9 d8 fe ff ff       	jmp    8004b5 <vprintfmt+0x25>
			else
				printfmt(putch, putdat, "%s", p);
  8005dd:	89 54 24 0c          	mov    %edx,0xc(%esp)
  8005e1:	c7 44 24 08 3d 0f 80 	movl   $0x800f3d,0x8(%esp)
  8005e8:	00 
  8005e9:	89 74 24 04          	mov    %esi,0x4(%esp)
  8005ed:	8b 45 08             	mov    0x8(%ebp),%eax
  8005f0:	89 04 24             	mov    %eax,(%esp)
  8005f3:	e8 70 fe ff ff       	call   800468 <printfmt>
  8005f8:	e9 b8 fe ff ff       	jmp    8004b5 <vprintfmt+0x25>
		width = -1;
		precision = -1;
		lflag = 0;
		altflag = 0;
	reswitch:
		switch (ch = *(unsigned char *) fmt++) {
  8005fd:	8b 4d d4             	mov    -0x2c(%ebp),%ecx
  800600:	8b 45 dc             	mov    -0x24(%ebp),%eax
  800603:	89 45 d0             	mov    %eax,-0x30(%ebp)
				printfmt(putch, putdat, "%s", p);
			break;

		// string
		case 's':
			if ((p = va_arg(ap, char *)) == NULL)
  800606:	8b 45 14             	mov    0x14(%ebp),%eax
  800609:	8d 50 04             	lea    0x4(%eax),%edx
  80060c:	89 55 14             	mov    %edx,0x14(%ebp)
  80060f:	8b 18                	mov    (%eax),%ebx
				p = "(null)";
  800611:	85 db                	test   %ebx,%ebx
  800613:	b8 2d 0f 80 00       	mov    $0x800f2d,%eax
  800618:	0f 44 d8             	cmove  %eax,%ebx
			if (width > 0 && padc != '-')
  80061b:	80 7d d8 2d          	cmpb   $0x2d,-0x28(%ebp)
  80061f:	0f 84 97 00 00 00    	je     8006bc <vprintfmt+0x22c>
  800625:	83 7d d0 00          	cmpl   $0x0,-0x30(%ebp)
  800629:	0f 8e 9b 00 00 00    	jle    8006ca <vprintfmt+0x23a>
				for (width -= strnlen(p, precision); width > 0; width--)
  80062f:	89 4c 24 04          	mov    %ecx,0x4(%esp)
  800633:	89 1c 24             	mov    %ebx,(%esp)
  800636:	e8 7d 02 00 00       	call   8008b8 <strnlen>
  80063b:	8b 55 d0             	mov    -0x30(%ebp),%edx
  80063e:	29 c2                	sub    %eax,%edx
  800640:	89 55 d0             	mov    %edx,-0x30(%ebp)
					putch(padc, putdat);
  800643:	0f be 45 d8          	movsbl -0x28(%ebp),%eax
  800647:	89 45 dc             	mov    %eax,-0x24(%ebp)
  80064a:	89 5d d8             	mov    %ebx,-0x28(%ebp)
  80064d:	89 d3                	mov    %edx,%ebx
  80064f:	89 7d 10             	mov    %edi,0x10(%ebp)
  800652:	8b 7d 08             	mov    0x8(%ebp),%edi
		// string
		case 's':
			if ((p = va_arg(ap, char *)) == NULL)
				p = "(null)";
			if (width > 0 && padc != '-')
				for (width -= strnlen(p, precision); width > 0; width--)
  800655:	eb 0f                	jmp    800666 <vprintfmt+0x1d6>
					putch(padc, putdat);
  800657:	89 74 24 04          	mov    %esi,0x4(%esp)
  80065b:	8b 45 dc             	mov    -0x24(%ebp),%eax
  80065e:	89 04 24             	mov    %eax,(%esp)
  800661:	ff d7                	call   *%edi
		// string
		case 's':
			if ((p = va_arg(ap, char *)) == NULL)
				p = "(null)";
			if (width > 0 && padc != '-')
				for (width -= strnlen(p, precision); width > 0; width--)
  800663:	83 eb 01             	sub    $0x1,%ebx
  800666:	85 db                	test   %ebx,%ebx
  800668:	7f ed                	jg     800657 <vprintfmt+0x1c7>
  80066a:	8b 5d d8             	mov    -0x28(%ebp),%ebx
  80066d:	8b 55 d0             	mov    -0x30(%ebp),%edx
  800670:	85 d2                	test   %edx,%edx
  800672:	b8 00 00 00 00       	mov    $0x0,%eax
  800677:	0f 49 c2             	cmovns %edx,%eax
  80067a:	29 c2                	sub    %eax,%edx
  80067c:	89 75 0c             	mov    %esi,0xc(%ebp)
  80067f:	89 d6                	mov    %edx,%esi
  800681:	8b 7d d4             	mov    -0x2c(%ebp),%edi
  800684:	eb 50                	jmp    8006d6 <vprintfmt+0x246>
					putch(padc, putdat);
			for (; (ch = *p++) != '\0' && (precision < 0 || --precision >= 0); width--)
				if (altflag && (ch < ' ' || ch > '~'))
  800686:	83 7d e0 00          	cmpl   $0x0,-0x20(%ebp)
  80068a:	74 1e                	je     8006aa <vprintfmt+0x21a>
  80068c:	0f be d2             	movsbl %dl,%edx
  80068f:	83 ea 20             	sub    $0x20,%edx
  800692:	83 fa 5e             	cmp    $0x5e,%edx
  800695:	76 13                	jbe    8006aa <vprintfmt+0x21a>
					putch('?', putdat);
  800697:	8b 45 0c             	mov    0xc(%ebp),%eax
  80069a:	89 44 24 04          	mov    %eax,0x4(%esp)
  80069e:	c7 04 24 3f 00 00 00 	movl   $0x3f,(%esp)
  8006a5:	ff 55 08             	call   *0x8(%ebp)
  8006a8:	eb 0d                	jmp    8006b7 <vprintfmt+0x227>
				else
					putch(ch, putdat);
  8006aa:	8b 55 0c             	mov    0xc(%ebp),%edx
  8006ad:	89 54 24 04          	mov    %edx,0x4(%esp)
  8006b1:	89 04 24             	mov    %eax,(%esp)
  8006b4:	ff 55 08             	call   *0x8(%ebp)
			if ((p = va_arg(ap, char *)) == NULL)
				p = "(null)";
			if (width > 0 && padc != '-')
				for (width -= strnlen(p, precision); width > 0; width--)
					putch(padc, putdat);
			for (; (ch = *p++) != '\0' && (precision < 0 || --precision >= 0); width--)
  8006b7:	83 ee 01             	sub    $0x1,%esi
  8006ba:	eb 1a                	jmp    8006d6 <vprintfmt+0x246>
  8006bc:	89 75 0c             	mov    %esi,0xc(%ebp)
  8006bf:	8b 75 dc             	mov    -0x24(%ebp),%esi
  8006c2:	89 7d 10             	mov    %edi,0x10(%ebp)
  8006c5:	8b 7d d4             	mov    -0x2c(%ebp),%edi
  8006c8:	eb 0c                	jmp    8006d6 <vprintfmt+0x246>
  8006ca:	89 75 0c             	mov    %esi,0xc(%ebp)
  8006cd:	8b 75 dc             	mov    -0x24(%ebp),%esi
  8006d0:	89 7d 10             	mov    %edi,0x10(%ebp)
  8006d3:	8b 7d d4             	mov    -0x2c(%ebp),%edi
  8006d6:	83 c3 01             	add    $0x1,%ebx
  8006d9:	0f b6 53 ff          	movzbl -0x1(%ebx),%edx
  8006dd:	0f be c2             	movsbl %dl,%eax
  8006e0:	85 c0                	test   %eax,%eax
  8006e2:	74 25                	je     800709 <vprintfmt+0x279>
  8006e4:	85 ff                	test   %edi,%edi
  8006e6:	78 9e                	js     800686 <vprintfmt+0x1f6>
  8006e8:	83 ef 01             	sub    $0x1,%edi
  8006eb:	79 99                	jns    800686 <vprintfmt+0x1f6>
  8006ed:	89 f3                	mov    %esi,%ebx
  8006ef:	8b 75 0c             	mov    0xc(%ebp),%esi
  8006f2:	8b 7d 08             	mov    0x8(%ebp),%edi
  8006f5:	eb 1a                	jmp    800711 <vprintfmt+0x281>
				if (altflag && (ch < ' ' || ch > '~'))
					putch('?', putdat);
				else
					putch(ch, putdat);
			for (; width > 0; width--)
				putch(' ', putdat);
  8006f7:	89 74 24 04          	mov    %esi,0x4(%esp)
  8006fb:	c7 04 24 20 00 00 00 	movl   $0x20,(%esp)
  800702:	ff d7                	call   *%edi
			for (; (ch = *p++) != '\0' && (precision < 0 || --precision >= 0); width--)
				if (altflag && (ch < ' ' || ch > '~'))
					putch('?', putdat);
				else
					putch(ch, putdat);
			for (; width > 0; width--)
  800704:	83 eb 01             	sub    $0x1,%ebx
  800707:	eb 08                	jmp    800711 <vprintfmt+0x281>
  800709:	89 f3                	mov    %esi,%ebx
  80070b:	8b 7d 08             	mov    0x8(%ebp),%edi
  80070e:	8b 75 0c             	mov    0xc(%ebp),%esi
  800711:	85 db                	test   %ebx,%ebx
  800713:	7f e2                	jg     8006f7 <vprintfmt+0x267>
  800715:	89 7d 08             	mov    %edi,0x8(%ebp)
  800718:	8b 7d 10             	mov    0x10(%ebp),%edi
  80071b:	e9 95 fd ff ff       	jmp    8004b5 <vprintfmt+0x25>
				putch(' ', putdat);
			break;

		// (signed) decimal
		case 'd':
			num = getint(&ap, lflag);
  800720:	8d 45 14             	lea    0x14(%ebp),%eax
  800723:	e8 f1 fc ff ff       	call   800419 <getint>
  800728:	89 45 e0             	mov    %eax,-0x20(%ebp)
  80072b:	89 55 e4             	mov    %edx,-0x1c(%ebp)
			if ((long long) num < 0) {
				putch('-', putdat);
				num = -(long long) num;
			}
			base = 10;
  80072e:	bb 0a 00 00 00       	mov    $0xa,%ebx
			break;

		// (signed) decimal
		case 'd':
			num = getint(&ap, lflag);
			if ((long long) num < 0) {
  800733:	83 7d e4 00          	cmpl   $0x0,-0x1c(%ebp)
  800737:	79 7b                	jns    8007b4 <vprintfmt+0x324>
				putch('-', putdat);
  800739:	89 74 24 04          	mov    %esi,0x4(%esp)
  80073d:	c7 04 24 2d 00 00 00 	movl   $0x2d,(%esp)
  800744:	ff 55 08             	call   *0x8(%ebp)
				num = -(long long) num;
  800747:	8b 45 e0             	mov    -0x20(%ebp),%eax
  80074a:	8b 55 e4             	mov    -0x1c(%ebp),%edx
  80074d:	f7 d8                	neg    %eax
  80074f:	83 d2 00             	adc    $0x0,%edx
  800752:	f7 da                	neg    %edx
  800754:	eb 5e                	jmp    8007b4 <vprintfmt+0x324>
			base = 10;
			goto number;

		// unsigned decimal
		case 'u':
			num = getuint(&ap, lflag);
  800756:	8d 45 14             	lea    0x14(%ebp),%eax
  800759:	e8 81 fc ff ff       	call   8003df <getuint>
			base = 10;
  80075e:	bb 0a 00 00 00       	mov    $0xa,%ebx
			goto number;
  800763:	eb 4f                	jmp    8007b4 <vprintfmt+0x324>

		// (unsigned) octal
		case 'o':
			num = getuint(&ap, lflag);
  800765:	8d 45 14             	lea    0x14(%ebp),%eax
  800768:	e8 72 fc ff ff       	call   8003df <getuint>
			base = 8;
  80076d:	bb 08 00 00 00       	mov    $0x8,%ebx
			goto number;
  800772:	eb 40                	jmp    8007b4 <vprintfmt+0x324>

		// pointer
		case 'p':
			putch('0', putdat);
  800774:	89 74 24 04          	mov    %esi,0x4(%esp)
  800778:	c7 04 24 30 00 00 00 	movl   $0x30,(%esp)
  80077f:	ff 55 08             	call   *0x8(%ebp)
			putch('x', putdat);
  800782:	89 74 24 04          	mov    %esi,0x4(%esp)
  800786:	c7 04 24 78 00 00 00 	movl   $0x78,(%esp)
  80078d:	ff 55 08             	call   *0x8(%ebp)
			num = (unsigned long long)
				(uintptr_t) va_arg(ap, void *);
  800790:	8b 45 14             	mov    0x14(%ebp),%eax
  800793:	8d 50 04             	lea    0x4(%eax),%edx
  800796:	89 55 14             	mov    %edx,0x14(%ebp)

		// pointer
		case 'p':
			putch('0', putdat);
			putch('x', putdat);
			num = (unsigned long long)
  800799:	8b 00                	mov    (%eax),%eax
  80079b:	ba 00 00 00 00       	mov    $0x0,%edx
				(uintptr_t) va_arg(ap, void *);
			base = 16;
  8007a0:	bb 10 00 00 00       	mov    $0x10,%ebx
			goto number;
  8007a5:	eb 0d                	jmp    8007b4 <vprintfmt+0x324>

		// (unsigned) hexadecimal
		case 'x':
			num = getuint(&ap, lflag);
  8007a7:	8d 45 14             	lea    0x14(%ebp),%eax
  8007aa:	e8 30 fc ff ff       	call   8003df <getuint>
			base = 16;
  8007af:	bb 10 00 00 00       	mov    $0x10,%ebx
		number:
			printnum(putch, putdat, num, base, width, padc);
  8007b4:	0f be 4d d8          	movsbl -0x28(%ebp),%ecx
  8007b8:	89 4c 24 10          	mov    %ecx,0x10(%esp)
  8007bc:	8b 4d dc             	mov    -0x24(%ebp),%ecx
  8007bf:	89 4c 24 0c          	mov    %ecx,0xc(%esp)
  8007c3:	89 5c 24 08          	mov    %ebx,0x8(%esp)
  8007c7:	89 04 24             	mov    %eax,(%esp)
  8007ca:	89 54 24 04          	mov    %edx,0x4(%esp)
  8007ce:	89 f2                	mov    %esi,%edx
  8007d0:	8b 45 08             	mov    0x8(%ebp),%eax
  8007d3:	e8 18 fb ff ff       	call   8002f0 <printnum>
			break;
  8007d8:	e9 d8 fc ff ff       	jmp    8004b5 <vprintfmt+0x25>

		// escaped '%' character
		case '%':
			putch(ch, putdat);
  8007dd:	89 74 24 04          	mov    %esi,0x4(%esp)
  8007e1:	89 04 24             	mov    %eax,(%esp)
  8007e4:	ff 55 08             	call   *0x8(%ebp)
			break;
  8007e7:	e9 c9 fc ff ff       	jmp    8004b5 <vprintfmt+0x25>

		// unrecognized escape sequence - just print it literally
		default:
			putch('%', putdat);
  8007ec:	89 74 24 04          	mov    %esi,0x4(%esp)
  8007f0:	c7 04 24 25 00 00 00 	movl   $0x25,(%esp)
  8007f7:	ff 55 08             	call   *0x8(%ebp)
			for (fmt--; fmt[-1] != '%'; fmt--)
  8007fa:	89 df                	mov    %ebx,%edi
  8007fc:	eb 03                	jmp    800801 <vprintfmt+0x371>
  8007fe:	83 ef 01             	sub    $0x1,%edi
  800801:	80 7f ff 25          	cmpb   $0x25,-0x1(%edi)
  800805:	75 f7                	jne    8007fe <vprintfmt+0x36e>
  800807:	e9 a9 fc ff ff       	jmp    8004b5 <vprintfmt+0x25>
				/* do nothing */;
			break;
		}
	}
}
  80080c:	83 c4 3c             	add    $0x3c,%esp
  80080f:	5b                   	pop    %ebx
  800810:	5e                   	pop    %esi
  800811:	5f                   	pop    %edi
  800812:	5d                   	pop    %ebp
  800813:	c3                   	ret    

00800814 <vsnprintf>:
		*b->buf++ = ch;
}

int
vsnprintf(char *buf, int n, const char *fmt, va_list ap)
{
  800814:	55                   	push   %ebp
  800815:	89 e5                	mov    %esp,%ebp
  800817:	83 ec 28             	sub    $0x28,%esp
  80081a:	8b 45 08             	mov    0x8(%ebp),%eax
  80081d:	8b 55 0c             	mov    0xc(%ebp),%edx
	struct sprintbuf b = {buf, buf+n-1, 0};
  800820:	89 45 ec             	mov    %eax,-0x14(%ebp)
  800823:	8d 4c 10 ff          	lea    -0x1(%eax,%edx,1),%ecx
  800827:	89 4d f0             	mov    %ecx,-0x10(%ebp)
  80082a:	c7 45 f4 00 00 00 00 	movl   $0x0,-0xc(%ebp)

	if (buf == NULL || n < 1)
  800831:	85 c0                	test   %eax,%eax
  800833:	74 30                	je     800865 <vsnprintf+0x51>
  800835:	85 d2                	test   %edx,%edx
  800837:	7e 2c                	jle    800865 <vsnprintf+0x51>
		return -E_INVAL;

	// print the string to the buffer
	vprintfmt((void*)sprintputch, &b, fmt, ap);
  800839:	8b 45 14             	mov    0x14(%ebp),%eax
  80083c:	89 44 24 0c          	mov    %eax,0xc(%esp)
  800840:	8b 45 10             	mov    0x10(%ebp),%eax
  800843:	89 44 24 08          	mov    %eax,0x8(%esp)
  800847:	8d 45 ec             	lea    -0x14(%ebp),%eax
  80084a:	89 44 24 04          	mov    %eax,0x4(%esp)
  80084e:	c7 04 24 4b 04 80 00 	movl   $0x80044b,(%esp)
  800855:	e8 36 fc ff ff       	call   800490 <vprintfmt>

	// null terminate the buffer
	*b.buf = '\0';
  80085a:	8b 45 ec             	mov    -0x14(%ebp),%eax
  80085d:	c6 00 00             	movb   $0x0,(%eax)

	return b.cnt;
  800860:	8b 45 f4             	mov    -0xc(%ebp),%eax
  800863:	eb 05                	jmp    80086a <vsnprintf+0x56>
vsnprintf(char *buf, int n, const char *fmt, va_list ap)
{
	struct sprintbuf b = {buf, buf+n-1, 0};

	if (buf == NULL || n < 1)
		return -E_INVAL;
  800865:	b8 fd ff ff ff       	mov    $0xfffffffd,%eax

	// null terminate the buffer
	*b.buf = '\0';

	return b.cnt;
}
  80086a:	c9                   	leave  
  80086b:	c3                   	ret    

0080086c <snprintf>:

int
snprintf(char *buf, int n, const char *fmt, ...)
{
  80086c:	55                   	push   %ebp
  80086d:	89 e5                	mov    %esp,%ebp
  80086f:	83 ec 18             	sub    $0x18,%esp
	va_list ap;
	int rc;

	va_start(ap, fmt);
  800872:	8d 45 14             	lea    0x14(%ebp),%eax
	rc = vsnprintf(buf, n, fmt, ap);
  800875:	89 44 24 0c          	mov    %eax,0xc(%esp)
  800879:	8b 45 10             	mov    0x10(%ebp),%eax
  80087c:	89 44 24 08          	mov    %eax,0x8(%esp)
  800880:	8b 45 0c             	mov    0xc(%ebp),%eax
  800883:	89 44 24 04          	mov    %eax,0x4(%esp)
  800887:	8b 45 08             	mov    0x8(%ebp),%eax
  80088a:	89 04 24             	mov    %eax,(%esp)
  80088d:	e8 82 ff ff ff       	call   800814 <vsnprintf>
	va_end(ap);

	return rc;
}
  800892:	c9                   	leave  
  800893:	c3                   	ret    
  800894:	66 90                	xchg   %ax,%ax
  800896:	66 90                	xchg   %ax,%ax
  800898:	66 90                	xchg   %ax,%ax
  80089a:	66 90                	xchg   %ax,%ax
  80089c:	66 90                	xchg   %ax,%ax
  80089e:	66 90                	xchg   %ax,%ax

008008a0 <strlen>:
// Primespipe runs 3x faster this way.
#define ASM 1

int
strlen(const char *s)
{
  8008a0:	55                   	push   %ebp
  8008a1:	89 e5                	mov    %esp,%ebp
  8008a3:	8b 55 08             	mov    0x8(%ebp),%edx
	int n;

	for (n = 0; *s != '\0'; s++)
  8008a6:	b8 00 00 00 00       	mov    $0x0,%eax
  8008ab:	eb 03                	jmp    8008b0 <strlen+0x10>
		n++;
  8008ad:	83 c0 01             	add    $0x1,%eax
int
strlen(const char *s)
{
	int n;

	for (n = 0; *s != '\0'; s++)
  8008b0:	80 3c 02 00          	cmpb   $0x0,(%edx,%eax,1)
  8008b4:	75 f7                	jne    8008ad <strlen+0xd>
		n++;
	return n;
}
  8008b6:	5d                   	pop    %ebp
  8008b7:	c3                   	ret    

008008b8 <strnlen>:

int
strnlen(const char *s, size_t size)
{
  8008b8:	55                   	push   %ebp
  8008b9:	89 e5                	mov    %esp,%ebp
  8008bb:	8b 4d 08             	mov    0x8(%ebp),%ecx
  8008be:	8b 55 0c             	mov    0xc(%ebp),%edx
	int n;

	for (n = 0; size > 0 && *s != '\0'; s++, size--)
  8008c1:	b8 00 00 00 00       	mov    $0x0,%eax
  8008c6:	eb 03                	jmp    8008cb <strnlen+0x13>
		n++;
  8008c8:	83 c0 01             	add    $0x1,%eax
int
strnlen(const char *s, size_t size)
{
	int n;

	for (n = 0; size > 0 && *s != '\0'; s++, size--)
  8008cb:	39 d0                	cmp    %edx,%eax
  8008cd:	74 06                	je     8008d5 <strnlen+0x1d>
  8008cf:	80 3c 01 00          	cmpb   $0x0,(%ecx,%eax,1)
  8008d3:	75 f3                	jne    8008c8 <strnlen+0x10>
		n++;
	return n;
}
  8008d5:	5d                   	pop    %ebp
  8008d6:	c3                   	ret    

008008d7 <strcpy>:

char *
strcpy(char *dst, const char *src)
{
  8008d7:	55                   	push   %ebp
  8008d8:	89 e5                	mov    %esp,%ebp
  8008da:	53                   	push   %ebx
  8008db:	8b 45 08             	mov    0x8(%ebp),%eax
  8008de:	8b 4d 0c             	mov    0xc(%ebp),%ecx
	char *ret;

	ret = dst;
	while ((*dst++ = *src++) != '\0')
  8008e1:	89 c2                	mov    %eax,%edx
  8008e3:	83 c2 01             	add    $0x1,%edx
  8008e6:	83 c1 01             	add    $0x1,%ecx
  8008e9:	0f b6 59 ff          	movzbl -0x1(%ecx),%ebx
  8008ed:	88 5a ff             	mov    %bl,-0x1(%edx)
  8008f0:	84 db                	test   %bl,%bl
  8008f2:	75 ef                	jne    8008e3 <strcpy+0xc>
		/* do nothing */;
	return ret;
}
  8008f4:	5b                   	pop    %ebx
  8008f5:	5d                   	pop    %ebp
  8008f6:	c3                   	ret    

008008f7 <strcat>:

char *
strcat(char *dst, const char *src)
{
  8008f7:	55                   	push   %ebp
  8008f8:	89 e5                	mov    %esp,%ebp
  8008fa:	53                   	push   %ebx
  8008fb:	83 ec 08             	sub    $0x8,%esp
  8008fe:	8b 5d 08             	mov    0x8(%ebp),%ebx
	int len = strlen(dst);
  800901:	89 1c 24             	mov    %ebx,(%esp)
  800904:	e8 97 ff ff ff       	call   8008a0 <strlen>
	strcpy(dst + len, src);
  800909:	8b 55 0c             	mov    0xc(%ebp),%edx
  80090c:	89 54 24 04          	mov    %edx,0x4(%esp)
  800910:	01 d8                	add    %ebx,%eax
  800912:	89 04 24             	mov    %eax,(%esp)
  800915:	e8 bd ff ff ff       	call   8008d7 <strcpy>
	return dst;
}
  80091a:	89 d8                	mov    %ebx,%eax
  80091c:	83 c4 08             	add    $0x8,%esp
  80091f:	5b                   	pop    %ebx
  800920:	5d                   	pop    %ebp
  800921:	c3                   	ret    

00800922 <strncpy>:

char *
strncpy(char *dst, const char *src, size_t size) {
  800922:	55                   	push   %ebp
  800923:	89 e5                	mov    %esp,%ebp
  800925:	56                   	push   %esi
  800926:	53                   	push   %ebx
  800927:	8b 75 08             	mov    0x8(%ebp),%esi
  80092a:	8b 4d 0c             	mov    0xc(%ebp),%ecx
  80092d:	89 f3                	mov    %esi,%ebx
  80092f:	03 5d 10             	add    0x10(%ebp),%ebx
	size_t i;
	char *ret;

	ret = dst;
	for (i = 0; i < size; i++) {
  800932:	89 f2                	mov    %esi,%edx
  800934:	eb 0f                	jmp    800945 <strncpy+0x23>
		*dst++ = *src;
  800936:	83 c2 01             	add    $0x1,%edx
  800939:	0f b6 01             	movzbl (%ecx),%eax
  80093c:	88 42 ff             	mov    %al,-0x1(%edx)
		// If strlen(src) < size, null-pad 'dst' out to 'size' chars
		if (*src != '\0')
			src++;
  80093f:	80 39 01             	cmpb   $0x1,(%ecx)
  800942:	83 d9 ff             	sbb    $0xffffffff,%ecx
strncpy(char *dst, const char *src, size_t size) {
	size_t i;
	char *ret;

	ret = dst;
	for (i = 0; i < size; i++) {
  800945:	39 da                	cmp    %ebx,%edx
  800947:	75 ed                	jne    800936 <strncpy+0x14>
		// If strlen(src) < size, null-pad 'dst' out to 'size' chars
		if (*src != '\0')
			src++;
	}
	return ret;
}
  800949:	89 f0                	mov    %esi,%eax
  80094b:	5b                   	pop    %ebx
  80094c:	5e                   	pop    %esi
  80094d:	5d                   	pop    %ebp
  80094e:	c3                   	ret    

0080094f <strlcpy>:

size_t
strlcpy(char *dst, const char *src, size_t size)
{
  80094f:	55                   	push   %ebp
  800950:	89 e5                	mov    %esp,%ebp
  800952:	56                   	push   %esi
  800953:	53                   	push   %ebx
  800954:	8b 75 08             	mov    0x8(%ebp),%esi
  800957:	8b 55 0c             	mov    0xc(%ebp),%edx
  80095a:	8b 4d 10             	mov    0x10(%ebp),%ecx
  80095d:	89 f0                	mov    %esi,%eax
  80095f:	8d 5c 0e ff          	lea    -0x1(%esi,%ecx,1),%ebx
	char *dst_in;

	dst_in = dst;
	if (size > 0) {
  800963:	85 c9                	test   %ecx,%ecx
  800965:	75 0b                	jne    800972 <strlcpy+0x23>
  800967:	eb 1d                	jmp    800986 <strlcpy+0x37>
		while (--size > 0 && *src != '\0')
			*dst++ = *src++;
  800969:	83 c0 01             	add    $0x1,%eax
  80096c:	83 c2 01             	add    $0x1,%edx
  80096f:	88 48 ff             	mov    %cl,-0x1(%eax)
{
	char *dst_in;

	dst_in = dst;
	if (size > 0) {
		while (--size > 0 && *src != '\0')
  800972:	39 d8                	cmp    %ebx,%eax
  800974:	74 0b                	je     800981 <strlcpy+0x32>
  800976:	0f b6 0a             	movzbl (%edx),%ecx
  800979:	84 c9                	test   %cl,%cl
  80097b:	75 ec                	jne    800969 <strlcpy+0x1a>
  80097d:	89 c2                	mov    %eax,%edx
  80097f:	eb 02                	jmp    800983 <strlcpy+0x34>
  800981:	89 c2                	mov    %eax,%edx
			*dst++ = *src++;
		*dst = '\0';
  800983:	c6 02 00             	movb   $0x0,(%edx)
	}
	return dst - dst_in;
  800986:	29 f0                	sub    %esi,%eax
}
  800988:	5b                   	pop    %ebx
  800989:	5e                   	pop    %esi
  80098a:	5d                   	pop    %ebp
  80098b:	c3                   	ret    

0080098c <strcmp>:

int
strcmp(const char *p, const char *q)
{
  80098c:	55                   	push   %ebp
  80098d:	89 e5                	mov    %esp,%ebp
  80098f:	8b 4d 08             	mov    0x8(%ebp),%ecx
  800992:	8b 55 0c             	mov    0xc(%ebp),%edx
	while (*p && *p == *q)
  800995:	eb 06                	jmp    80099d <strcmp+0x11>
		p++, q++;
  800997:	83 c1 01             	add    $0x1,%ecx
  80099a:	83 c2 01             	add    $0x1,%edx
}

int
strcmp(const char *p, const char *q)
{
	while (*p && *p == *q)
  80099d:	0f b6 01             	movzbl (%ecx),%eax
  8009a0:	84 c0                	test   %al,%al
  8009a2:	74 04                	je     8009a8 <strcmp+0x1c>
  8009a4:	3a 02                	cmp    (%edx),%al
  8009a6:	74 ef                	je     800997 <strcmp+0xb>
		p++, q++;
	return (int) ((unsigned char) *p - (unsigned char) *q);
  8009a8:	0f b6 c0             	movzbl %al,%eax
  8009ab:	0f b6 12             	movzbl (%edx),%edx
  8009ae:	29 d0                	sub    %edx,%eax
}
  8009b0:	5d                   	pop    %ebp
  8009b1:	c3                   	ret    

008009b2 <strncmp>:

int
strncmp(const char *p, const char *q, size_t n)
{
  8009b2:	55                   	push   %ebp
  8009b3:	89 e5                	mov    %esp,%ebp
  8009b5:	53                   	push   %ebx
  8009b6:	8b 45 08             	mov    0x8(%ebp),%eax
  8009b9:	8b 55 0c             	mov    0xc(%ebp),%edx
  8009bc:	89 c3                	mov    %eax,%ebx
  8009be:	03 5d 10             	add    0x10(%ebp),%ebx
	while (n > 0 && *p && *p == *q)
  8009c1:	eb 06                	jmp    8009c9 <strncmp+0x17>
		n--, p++, q++;
  8009c3:	83 c0 01             	add    $0x1,%eax
  8009c6:	83 c2 01             	add    $0x1,%edx
}

int
strncmp(const char *p, const char *q, size_t n)
{
	while (n > 0 && *p && *p == *q)
  8009c9:	39 d8                	cmp    %ebx,%eax
  8009cb:	74 15                	je     8009e2 <strncmp+0x30>
  8009cd:	0f b6 08             	movzbl (%eax),%ecx
  8009d0:	84 c9                	test   %cl,%cl
  8009d2:	74 04                	je     8009d8 <strncmp+0x26>
  8009d4:	3a 0a                	cmp    (%edx),%cl
  8009d6:	74 eb                	je     8009c3 <strncmp+0x11>
		n--, p++, q++;
	if (n == 0)
		return 0;
	else
		return (int) ((unsigned char) *p - (unsigned char) *q);
  8009d8:	0f b6 00             	movzbl (%eax),%eax
  8009db:	0f b6 12             	movzbl (%edx),%edx
  8009de:	29 d0                	sub    %edx,%eax
  8009e0:	eb 05                	jmp    8009e7 <strncmp+0x35>
strncmp(const char *p, const char *q, size_t n)
{
	while (n > 0 && *p && *p == *q)
		n--, p++, q++;
	if (n == 0)
		return 0;
  8009e2:	b8 00 00 00 00       	mov    $0x0,%eax
	else
		return (int) ((unsigned char) *p - (unsigned char) *q);
}
  8009e7:	5b                   	pop    %ebx
  8009e8:	5d                   	pop    %ebp
  8009e9:	c3                   	ret    

008009ea <strchr>:

// Return a pointer to the first occurrence of 'c' in 's',
// or a null pointer if the string has no 'c'.
char *
strchr(const char *s, char c)
{
  8009ea:	55                   	push   %ebp
  8009eb:	89 e5                	mov    %esp,%ebp
  8009ed:	8b 45 08             	mov    0x8(%ebp),%eax
  8009f0:	0f b6 4d 0c          	movzbl 0xc(%ebp),%ecx
	for (; *s; s++)
  8009f4:	eb 07                	jmp    8009fd <strchr+0x13>
		if (*s == c)
  8009f6:	38 ca                	cmp    %cl,%dl
  8009f8:	74 0f                	je     800a09 <strchr+0x1f>
// Return a pointer to the first occurrence of 'c' in 's',
// or a null pointer if the string has no 'c'.
char *
strchr(const char *s, char c)
{
	for (; *s; s++)
  8009fa:	83 c0 01             	add    $0x1,%eax
  8009fd:	0f b6 10             	movzbl (%eax),%edx
  800a00:	84 d2                	test   %dl,%dl
  800a02:	75 f2                	jne    8009f6 <strchr+0xc>
		if (*s == c)
			return (char *) s;
	return 0;
  800a04:	b8 00 00 00 00       	mov    $0x0,%eax
}
  800a09:	5d                   	pop    %ebp
  800a0a:	c3                   	ret    

00800a0b <strfind>:

// Return a pointer to the first occurrence of 'c' in 's',
// or a pointer to the string-ending null character if the string has no 'c'.
char *
strfind(const char *s, char c)
{
  800a0b:	55                   	push   %ebp
  800a0c:	89 e5                	mov    %esp,%ebp
  800a0e:	8b 45 08             	mov    0x8(%ebp),%eax
  800a11:	0f b6 4d 0c          	movzbl 0xc(%ebp),%ecx
	for (; *s; s++)
  800a15:	eb 07                	jmp    800a1e <strfind+0x13>
		if (*s == c)
  800a17:	38 ca                	cmp    %cl,%dl
  800a19:	74 0a                	je     800a25 <strfind+0x1a>
// Return a pointer to the first occurrence of 'c' in 's',
// or a pointer to the string-ending null character if the string has no 'c'.
char *
strfind(const char *s, char c)
{
	for (; *s; s++)
  800a1b:	83 c0 01             	add    $0x1,%eax
  800a1e:	0f b6 10             	movzbl (%eax),%edx
  800a21:	84 d2                	test   %dl,%dl
  800a23:	75 f2                	jne    800a17 <strfind+0xc>
		if (*s == c)
			break;
	return (char *) s;
}
  800a25:	5d                   	pop    %ebp
  800a26:	c3                   	ret    

00800a27 <memset>:

#if ASM
void *
memset(void *v, int c, size_t n)
{
  800a27:	55                   	push   %ebp
  800a28:	89 e5                	mov    %esp,%ebp
  800a2a:	57                   	push   %edi
  800a2b:	56                   	push   %esi
  800a2c:	53                   	push   %ebx
  800a2d:	8b 55 08             	mov    0x8(%ebp),%edx
  800a30:	8b 4d 10             	mov    0x10(%ebp),%ecx
	char *p = v;

	if (n == 0)
  800a33:	85 c9                	test   %ecx,%ecx
  800a35:	74 37                	je     800a6e <memset+0x47>
		return v;
	if ((int)v%4 == 0 && n%4 == 0) {
  800a37:	f6 c2 03             	test   $0x3,%dl
  800a3a:	75 2a                	jne    800a66 <memset+0x3f>
  800a3c:	f6 c1 03             	test   $0x3,%cl
  800a3f:	75 25                	jne    800a66 <memset+0x3f>
		c &= 0xFF;
  800a41:	0f b6 7d 0c          	movzbl 0xc(%ebp),%edi
		c = (c<<24)|(c<<16)|(c<<8)|c;
  800a45:	89 fb                	mov    %edi,%ebx
  800a47:	c1 e3 08             	shl    $0x8,%ebx
  800a4a:	89 fe                	mov    %edi,%esi
  800a4c:	c1 e6 18             	shl    $0x18,%esi
  800a4f:	89 f8                	mov    %edi,%eax
  800a51:	c1 e0 10             	shl    $0x10,%eax
  800a54:	09 f0                	or     %esi,%eax
  800a56:	09 c7                	or     %eax,%edi
		asm volatile("cld; rep stosl\n"
			: "=D" (p), "=c" (n)
			: "D" (p), "a" (c), "c" (n/4)
  800a58:	c1 e9 02             	shr    $0x2,%ecx

	if (n == 0)
		return v;
	if ((int)v%4 == 0 && n%4 == 0) {
		c &= 0xFF;
		c = (c<<24)|(c<<16)|(c<<8)|c;
  800a5b:	89 f8                	mov    %edi,%eax
  800a5d:	09 d8                	or     %ebx,%eax
		asm volatile("cld; rep stosl\n"
  800a5f:	89 d7                	mov    %edx,%edi
  800a61:	fc                   	cld    
  800a62:	f3 ab                	rep stos %eax,%es:(%edi)
  800a64:	eb 08                	jmp    800a6e <memset+0x47>
			: "=D" (p), "=c" (n)
			: "D" (p), "a" (c), "c" (n/4)
			: "cc", "memory");
	} else
		asm volatile("cld; rep stosb\n"
  800a66:	89 d7                	mov    %edx,%edi
  800a68:	8b 45 0c             	mov    0xc(%ebp),%eax
  800a6b:	fc                   	cld    
  800a6c:	f3 aa                	rep stos %al,%es:(%edi)
			: "=D" (p), "=c" (n)
			: "0" (p), "a" (c), "1" (n)
			: "cc", "memory");
	return v;
}
  800a6e:	89 d0                	mov    %edx,%eax
  800a70:	5b                   	pop    %ebx
  800a71:	5e                   	pop    %esi
  800a72:	5f                   	pop    %edi
  800a73:	5d                   	pop    %ebp
  800a74:	c3                   	ret    

00800a75 <memmove>:

void *
memmove(void *dst, const void *src, size_t n)
{
  800a75:	55                   	push   %ebp
  800a76:	89 e5                	mov    %esp,%ebp
  800a78:	57                   	push   %edi
  800a79:	56                   	push   %esi
  800a7a:	8b 45 08             	mov    0x8(%ebp),%eax
  800a7d:	8b 75 0c             	mov    0xc(%ebp),%esi
  800a80:	8b 4d 10             	mov    0x10(%ebp),%ecx
	const char *s;
	char *d;

	s = src;
	d = dst;
	if (s < d && s + n > d) {
  800a83:	39 c6                	cmp    %eax,%esi
  800a85:	73 35                	jae    800abc <memmove+0x47>
  800a87:	8d 14 0e             	lea    (%esi,%ecx,1),%edx
  800a8a:	39 d0                	cmp    %edx,%eax
  800a8c:	73 2e                	jae    800abc <memmove+0x47>
		s += n;
		d += n;
  800a8e:	8d 3c 08             	lea    (%eax,%ecx,1),%edi
  800a91:	89 d6                	mov    %edx,%esi
  800a93:	09 fe                	or     %edi,%esi
		if ((int)s%4 == 0 && (int)d%4 == 0 && n%4 == 0)
  800a95:	f7 c6 03 00 00 00    	test   $0x3,%esi
  800a9b:	75 13                	jne    800ab0 <memmove+0x3b>
  800a9d:	f6 c1 03             	test   $0x3,%cl
  800aa0:	75 0e                	jne    800ab0 <memmove+0x3b>
			asm volatile("std; rep movsl\n"
				:: "D" (d-4), "S" (s-4), "c" (n/4) : "cc", "memory");
  800aa2:	83 ef 04             	sub    $0x4,%edi
  800aa5:	8d 72 fc             	lea    -0x4(%edx),%esi
  800aa8:	c1 e9 02             	shr    $0x2,%ecx
	d = dst;
	if (s < d && s + n > d) {
		s += n;
		d += n;
		if ((int)s%4 == 0 && (int)d%4 == 0 && n%4 == 0)
			asm volatile("std; rep movsl\n"
  800aab:	fd                   	std    
  800aac:	f3 a5                	rep movsl %ds:(%esi),%es:(%edi)
  800aae:	eb 09                	jmp    800ab9 <memmove+0x44>
				:: "D" (d-4), "S" (s-4), "c" (n/4) : "cc", "memory");
		else
			asm volatile("std; rep movsb\n"
				:: "D" (d-1), "S" (s-1), "c" (n) : "cc", "memory");
  800ab0:	83 ef 01             	sub    $0x1,%edi
  800ab3:	8d 72 ff             	lea    -0x1(%edx),%esi
		d += n;
		if ((int)s%4 == 0 && (int)d%4 == 0 && n%4 == 0)
			asm volatile("std; rep movsl\n"
				:: "D" (d-4), "S" (s-4), "c" (n/4) : "cc", "memory");
		else
			asm volatile("std; rep movsb\n"
  800ab6:	fd                   	std    
  800ab7:	f3 a4                	rep movsb %ds:(%esi),%es:(%edi)
				:: "D" (d-1), "S" (s-1), "c" (n) : "cc", "memory");
		// Some versions of GCC rely on DF being clear
		asm volatile("cld" ::: "cc");
  800ab9:	fc                   	cld    
  800aba:	eb 1d                	jmp    800ad9 <memmove+0x64>
  800abc:	89 f2                	mov    %esi,%edx
  800abe:	09 c2                	or     %eax,%edx
	} else {
		if ((int)s%4 == 0 && (int)d%4 == 0 && n%4 == 0)
  800ac0:	f6 c2 03             	test   $0x3,%dl
  800ac3:	75 0f                	jne    800ad4 <memmove+0x5f>
  800ac5:	f6 c1 03             	test   $0x3,%cl
  800ac8:	75 0a                	jne    800ad4 <memmove+0x5f>
			asm volatile("cld; rep movsl\n"
				:: "D" (d), "S" (s), "c" (n/4) : "cc", "memory");
  800aca:	c1 e9 02             	shr    $0x2,%ecx
				:: "D" (d-1), "S" (s-1), "c" (n) : "cc", "memory");
		// Some versions of GCC rely on DF being clear
		asm volatile("cld" ::: "cc");
	} else {
		if ((int)s%4 == 0 && (int)d%4 == 0 && n%4 == 0)
			asm volatile("cld; rep movsl\n"
  800acd:	89 c7                	mov    %eax,%edi
  800acf:	fc                   	cld    
  800ad0:	f3 a5                	rep movsl %ds:(%esi),%es:(%edi)
  800ad2:	eb 05                	jmp    800ad9 <memmove+0x64>
				:: "D" (d), "S" (s), "c" (n/4) : "cc", "memory");
		else
			asm volatile("cld; rep movsb\n"
  800ad4:	89 c7                	mov    %eax,%edi
  800ad6:	fc                   	cld    
  800ad7:	f3 a4                	rep movsb %ds:(%esi),%es:(%edi)
				:: "D" (d), "S" (s), "c" (n) : "cc", "memory");
	}
	return dst;
}
  800ad9:	5e                   	pop    %esi
  800ada:	5f                   	pop    %edi
  800adb:	5d                   	pop    %ebp
  800adc:	c3                   	ret    

00800add <memcpy>:
}
#endif

void *
memcpy(void *dst, const void *src, size_t n)
{
  800add:	55                   	push   %ebp
  800ade:	89 e5                	mov    %esp,%ebp
  800ae0:	83 ec 0c             	sub    $0xc,%esp
	return memmove(dst, src, n);
  800ae3:	8b 45 10             	mov    0x10(%ebp),%eax
  800ae6:	89 44 24 08          	mov    %eax,0x8(%esp)
  800aea:	8b 45 0c             	mov    0xc(%ebp),%eax
  800aed:	89 44 24 04          	mov    %eax,0x4(%esp)
  800af1:	8b 45 08             	mov    0x8(%ebp),%eax
  800af4:	89 04 24             	mov    %eax,(%esp)
  800af7:	e8 79 ff ff ff       	call   800a75 <memmove>
}
  800afc:	c9                   	leave  
  800afd:	c3                   	ret    

00800afe <memcmp>:

int
memcmp(const void *v1, const void *v2, size_t n)
{
  800afe:	55                   	push   %ebp
  800aff:	89 e5                	mov    %esp,%ebp
  800b01:	56                   	push   %esi
  800b02:	53                   	push   %ebx
  800b03:	8b 55 08             	mov    0x8(%ebp),%edx
  800b06:	8b 4d 0c             	mov    0xc(%ebp),%ecx
  800b09:	89 d6                	mov    %edx,%esi
  800b0b:	03 75 10             	add    0x10(%ebp),%esi
	const uint8_t *s1 = (const uint8_t *) v1;
	const uint8_t *s2 = (const uint8_t *) v2;

	while (n-- > 0) {
  800b0e:	eb 1a                	jmp    800b2a <memcmp+0x2c>
		if (*s1 != *s2)
  800b10:	0f b6 02             	movzbl (%edx),%eax
  800b13:	0f b6 19             	movzbl (%ecx),%ebx
  800b16:	38 d8                	cmp    %bl,%al
  800b18:	74 0a                	je     800b24 <memcmp+0x26>
			return (int) *s1 - (int) *s2;
  800b1a:	0f b6 c0             	movzbl %al,%eax
  800b1d:	0f b6 db             	movzbl %bl,%ebx
  800b20:	29 d8                	sub    %ebx,%eax
  800b22:	eb 0f                	jmp    800b33 <memcmp+0x35>
		s1++, s2++;
  800b24:	83 c2 01             	add    $0x1,%edx
  800b27:	83 c1 01             	add    $0x1,%ecx
memcmp(const void *v1, const void *v2, size_t n)
{
	const uint8_t *s1 = (const uint8_t *) v1;
	const uint8_t *s2 = (const uint8_t *) v2;

	while (n-- > 0) {
  800b2a:	39 f2                	cmp    %esi,%edx
  800b2c:	75 e2                	jne    800b10 <memcmp+0x12>
		if (*s1 != *s2)
			return (int) *s1 - (int) *s2;
		s1++, s2++;
	}

	return 0;
  800b2e:	b8 00 00 00 00       	mov    $0x0,%eax
}
  800b33:	5b                   	pop    %ebx
  800b34:	5e                   	pop    %esi
  800b35:	5d                   	pop    %ebp
  800b36:	c3                   	ret    

00800b37 <memfind>:

void *
memfind(const void *s, int c, size_t n)
{
  800b37:	55                   	push   %ebp
  800b38:	89 e5                	mov    %esp,%ebp
  800b3a:	8b 45 08             	mov    0x8(%ebp),%eax
  800b3d:	8b 4d 0c             	mov    0xc(%ebp),%ecx
	const void *ends = (const char *) s + n;
  800b40:	89 c2                	mov    %eax,%edx
  800b42:	03 55 10             	add    0x10(%ebp),%edx
	for (; s < ends; s++)
  800b45:	eb 07                	jmp    800b4e <memfind+0x17>
		if (*(const unsigned char *) s == (unsigned char) c)
  800b47:	38 08                	cmp    %cl,(%eax)
  800b49:	74 07                	je     800b52 <memfind+0x1b>

void *
memfind(const void *s, int c, size_t n)
{
	const void *ends = (const char *) s + n;
	for (; s < ends; s++)
  800b4b:	83 c0 01             	add    $0x1,%eax
  800b4e:	39 d0                	cmp    %edx,%eax
  800b50:	72 f5                	jb     800b47 <memfind+0x10>
		if (*(const unsigned char *) s == (unsigned char) c)
			break;
	return (void *) s;
}
  800b52:	5d                   	pop    %ebp
  800b53:	c3                   	ret    

00800b54 <strtol>:

long
strtol(const char *s, char **endptr, int base)
{
  800b54:	55                   	push   %ebp
  800b55:	89 e5                	mov    %esp,%ebp
  800b57:	57                   	push   %edi
  800b58:	56                   	push   %esi
  800b59:	53                   	push   %ebx
  800b5a:	8b 55 08             	mov    0x8(%ebp),%edx
  800b5d:	8b 45 10             	mov    0x10(%ebp),%eax
	int neg = 0;
	long val = 0;

	// gobble initial whitespace
	while (*s == ' ' || *s == '\t')
  800b60:	eb 03                	jmp    800b65 <strtol+0x11>
		s++;
  800b62:	83 c2 01             	add    $0x1,%edx
{
	int neg = 0;
	long val = 0;

	// gobble initial whitespace
	while (*s == ' ' || *s == '\t')
  800b65:	0f b6 0a             	movzbl (%edx),%ecx
  800b68:	80 f9 09             	cmp    $0x9,%cl
  800b6b:	74 f5                	je     800b62 <strtol+0xe>
  800b6d:	80 f9 20             	cmp    $0x20,%cl
  800b70:	74 f0                	je     800b62 <strtol+0xe>
		s++;

	// plus/minus sign
	if (*s == '+')
  800b72:	80 f9 2b             	cmp    $0x2b,%cl
  800b75:	75 0a                	jne    800b81 <strtol+0x2d>
		s++;
  800b77:	83 c2 01             	add    $0x1,%edx
}

long
strtol(const char *s, char **endptr, int base)
{
	int neg = 0;
  800b7a:	bf 00 00 00 00       	mov    $0x0,%edi
  800b7f:	eb 11                	jmp    800b92 <strtol+0x3e>
  800b81:	bf 00 00 00 00       	mov    $0x0,%edi
		s++;

	// plus/minus sign
	if (*s == '+')
		s++;
	else if (*s == '-')
  800b86:	80 f9 2d             	cmp    $0x2d,%cl
  800b89:	75 07                	jne    800b92 <strtol+0x3e>
		s++, neg = 1;
  800b8b:	8d 52 01             	lea    0x1(%edx),%edx
  800b8e:	66 bf 01 00          	mov    $0x1,%di

	// hex or octal base prefix
	if ((base == 0 || base == 16) && (s[0] == '0' && s[1] == 'x'))
  800b92:	a9 ef ff ff ff       	test   $0xffffffef,%eax
  800b97:	75 15                	jne    800bae <strtol+0x5a>
  800b99:	80 3a 30             	cmpb   $0x30,(%edx)
  800b9c:	75 10                	jne    800bae <strtol+0x5a>
  800b9e:	80 7a 01 78          	cmpb   $0x78,0x1(%edx)
  800ba2:	75 0a                	jne    800bae <strtol+0x5a>
		s += 2, base = 16;
  800ba4:	83 c2 02             	add    $0x2,%edx
  800ba7:	b8 10 00 00 00       	mov    $0x10,%eax
  800bac:	eb 10                	jmp    800bbe <strtol+0x6a>
	else if (base == 0 && s[0] == '0')
  800bae:	85 c0                	test   %eax,%eax
  800bb0:	75 0c                	jne    800bbe <strtol+0x6a>
		s++, base = 8;
	else if (base == 0)
		base = 10;
  800bb2:	b0 0a                	mov    $0xa,%al
		s++, neg = 1;

	// hex or octal base prefix
	if ((base == 0 || base == 16) && (s[0] == '0' && s[1] == 'x'))
		s += 2, base = 16;
	else if (base == 0 && s[0] == '0')
  800bb4:	80 3a 30             	cmpb   $0x30,(%edx)
  800bb7:	75 05                	jne    800bbe <strtol+0x6a>
		s++, base = 8;
  800bb9:	83 c2 01             	add    $0x1,%edx
  800bbc:	b0 08                	mov    $0x8,%al
	else if (base == 0)
		base = 10;
  800bbe:	bb 00 00 00 00       	mov    $0x0,%ebx
  800bc3:	89 45 10             	mov    %eax,0x10(%ebp)

	// digits
	while (1) {
		int dig;

		if (*s >= '0' && *s <= '9')
  800bc6:	0f b6 0a             	movzbl (%edx),%ecx
  800bc9:	8d 71 d0             	lea    -0x30(%ecx),%esi
  800bcc:	89 f0                	mov    %esi,%eax
  800bce:	3c 09                	cmp    $0x9,%al
  800bd0:	77 08                	ja     800bda <strtol+0x86>
			dig = *s - '0';
  800bd2:	0f be c9             	movsbl %cl,%ecx
  800bd5:	83 e9 30             	sub    $0x30,%ecx
  800bd8:	eb 20                	jmp    800bfa <strtol+0xa6>
		else if (*s >= 'a' && *s <= 'z')
  800bda:	8d 71 9f             	lea    -0x61(%ecx),%esi
  800bdd:	89 f0                	mov    %esi,%eax
  800bdf:	3c 19                	cmp    $0x19,%al
  800be1:	77 08                	ja     800beb <strtol+0x97>
			dig = *s - 'a' + 10;
  800be3:	0f be c9             	movsbl %cl,%ecx
  800be6:	83 e9 57             	sub    $0x57,%ecx
  800be9:	eb 0f                	jmp    800bfa <strtol+0xa6>
		else if (*s >= 'A' && *s <= 'Z')
  800beb:	8d 71 bf             	lea    -0x41(%ecx),%esi
  800bee:	89 f0                	mov    %esi,%eax
  800bf0:	3c 19                	cmp    $0x19,%al
  800bf2:	77 16                	ja     800c0a <strtol+0xb6>
			dig = *s - 'A' + 10;
  800bf4:	0f be c9             	movsbl %cl,%ecx
  800bf7:	83 e9 37             	sub    $0x37,%ecx
		else
			break;
		if (dig >= base)
  800bfa:	3b 4d 10             	cmp    0x10(%ebp),%ecx
  800bfd:	7d 0f                	jge    800c0e <strtol+0xba>
			break;
		s++, val = (val * base) + dig;
  800bff:	83 c2 01             	add    $0x1,%edx
  800c02:	0f af 5d 10          	imul   0x10(%ebp),%ebx
  800c06:	01 cb                	add    %ecx,%ebx
		// we don't properly detect overflow!
	}
  800c08:	eb bc                	jmp    800bc6 <strtol+0x72>
  800c0a:	89 d8                	mov    %ebx,%eax
  800c0c:	eb 02                	jmp    800c10 <strtol+0xbc>
  800c0e:	89 d8                	mov    %ebx,%eax

	if (endptr)
  800c10:	83 7d 0c 00          	cmpl   $0x0,0xc(%ebp)
  800c14:	74 05                	je     800c1b <strtol+0xc7>
		*endptr = (char *) s;
  800c16:	8b 75 0c             	mov    0xc(%ebp),%esi
  800c19:	89 16                	mov    %edx,(%esi)
	return (neg ? -val : val);
  800c1b:	f7 d8                	neg    %eax
  800c1d:	85 ff                	test   %edi,%edi
  800c1f:	0f 44 c3             	cmove  %ebx,%eax
}
  800c22:	5b                   	pop    %ebx
  800c23:	5e                   	pop    %esi
  800c24:	5f                   	pop    %edi
  800c25:	5d                   	pop    %ebp
  800c26:	c3                   	ret    
  800c27:	66 90                	xchg   %ax,%ax
  800c29:	66 90                	xchg   %ax,%ax
  800c2b:	66 90                	xchg   %ax,%ax
  800c2d:	66 90                	xchg   %ax,%ax
  800c2f:	90                   	nop

00800c30 <__udivdi3>:
  800c30:	55                   	push   %ebp
  800c31:	57                   	push   %edi
  800c32:	56                   	push   %esi
  800c33:	53                   	push   %ebx
  800c34:	83 ec 1c             	sub    $0x1c,%esp
  800c37:	8b 74 24 3c          	mov    0x3c(%esp),%esi
  800c3b:	8b 5c 24 30          	mov    0x30(%esp),%ebx
  800c3f:	8b 4c 24 34          	mov    0x34(%esp),%ecx
  800c43:	8b 7c 24 38          	mov    0x38(%esp),%edi
  800c47:	85 f6                	test   %esi,%esi
  800c49:	89 5c 24 08          	mov    %ebx,0x8(%esp)
  800c4d:	89 ca                	mov    %ecx,%edx
  800c4f:	89 f8                	mov    %edi,%eax
  800c51:	75 3d                	jne    800c90 <__udivdi3+0x60>
  800c53:	39 cf                	cmp    %ecx,%edi
  800c55:	0f 87 c5 00 00 00    	ja     800d20 <__udivdi3+0xf0>
  800c5b:	85 ff                	test   %edi,%edi
  800c5d:	89 fd                	mov    %edi,%ebp
  800c5f:	75 0b                	jne    800c6c <__udivdi3+0x3c>
  800c61:	b8 01 00 00 00       	mov    $0x1,%eax
  800c66:	31 d2                	xor    %edx,%edx
  800c68:	f7 f7                	div    %edi
  800c6a:	89 c5                	mov    %eax,%ebp
  800c6c:	89 c8                	mov    %ecx,%eax
  800c6e:	31 d2                	xor    %edx,%edx
  800c70:	f7 f5                	div    %ebp
  800c72:	89 c1                	mov    %eax,%ecx
  800c74:	89 d8                	mov    %ebx,%eax
  800c76:	89 cf                	mov    %ecx,%edi
  800c78:	f7 f5                	div    %ebp
  800c7a:	89 c3                	mov    %eax,%ebx
  800c7c:	89 d8                	mov    %ebx,%eax
  800c7e:	89 fa                	mov    %edi,%edx
  800c80:	83 c4 1c             	add    $0x1c,%esp
  800c83:	5b                   	pop    %ebx
  800c84:	5e                   	pop    %esi
  800c85:	5f                   	pop    %edi
  800c86:	5d                   	pop    %ebp
  800c87:	c3                   	ret    
  800c88:	90                   	nop
  800c89:	8d b4 26 00 00 00 00 	lea    0x0(%esi,%eiz,1),%esi
  800c90:	39 ce                	cmp    %ecx,%esi
  800c92:	77 74                	ja     800d08 <__udivdi3+0xd8>
  800c94:	0f bd fe             	bsr    %esi,%edi
  800c97:	83 f7 1f             	xor    $0x1f,%edi
  800c9a:	0f 84 98 00 00 00    	je     800d38 <__udivdi3+0x108>
  800ca0:	bb 20 00 00 00       	mov    $0x20,%ebx
  800ca5:	89 f9                	mov    %edi,%ecx
  800ca7:	89 c5                	mov    %eax,%ebp
  800ca9:	29 fb                	sub    %edi,%ebx
  800cab:	d3 e6                	shl    %cl,%esi
  800cad:	89 d9                	mov    %ebx,%ecx
  800caf:	d3 ed                	shr    %cl,%ebp
  800cb1:	89 f9                	mov    %edi,%ecx
  800cb3:	d3 e0                	shl    %cl,%eax
  800cb5:	09 ee                	or     %ebp,%esi
  800cb7:	89 d9                	mov    %ebx,%ecx
  800cb9:	89 44 24 0c          	mov    %eax,0xc(%esp)
  800cbd:	89 d5                	mov    %edx,%ebp
  800cbf:	8b 44 24 08          	mov    0x8(%esp),%eax
  800cc3:	d3 ed                	shr    %cl,%ebp
  800cc5:	89 f9                	mov    %edi,%ecx
  800cc7:	d3 e2                	shl    %cl,%edx
  800cc9:	89 d9                	mov    %ebx,%ecx
  800ccb:	d3 e8                	shr    %cl,%eax
  800ccd:	09 c2                	or     %eax,%edx
  800ccf:	89 d0                	mov    %edx,%eax
  800cd1:	89 ea                	mov    %ebp,%edx
  800cd3:	f7 f6                	div    %esi
  800cd5:	89 d5                	mov    %edx,%ebp
  800cd7:	89 c3                	mov    %eax,%ebx
  800cd9:	f7 64 24 0c          	mull   0xc(%esp)
  800cdd:	39 d5                	cmp    %edx,%ebp
  800cdf:	72 10                	jb     800cf1 <__udivdi3+0xc1>
  800ce1:	8b 74 24 08          	mov    0x8(%esp),%esi
  800ce5:	89 f9                	mov    %edi,%ecx
  800ce7:	d3 e6                	shl    %cl,%esi
  800ce9:	39 c6                	cmp    %eax,%esi
  800ceb:	73 07                	jae    800cf4 <__udivdi3+0xc4>
  800ced:	39 d5                	cmp    %edx,%ebp
  800cef:	75 03                	jne    800cf4 <__udivdi3+0xc4>
  800cf1:	83 eb 01             	sub    $0x1,%ebx
  800cf4:	31 ff                	xor    %edi,%edi
  800cf6:	89 d8                	mov    %ebx,%eax
  800cf8:	89 fa                	mov    %edi,%edx
  800cfa:	83 c4 1c             	add    $0x1c,%esp
  800cfd:	5b                   	pop    %ebx
  800cfe:	5e                   	pop    %esi
  800cff:	5f                   	pop    %edi
  800d00:	5d                   	pop    %ebp
  800d01:	c3                   	ret    
  800d02:	8d b6 00 00 00 00    	lea    0x0(%esi),%esi
  800d08:	31 ff                	xor    %edi,%edi
  800d0a:	31 db                	xor    %ebx,%ebx
  800d0c:	89 d8                	mov    %ebx,%eax
  800d0e:	89 fa                	mov    %edi,%edx
  800d10:	83 c4 1c             	add    $0x1c,%esp
  800d13:	5b                   	pop    %ebx
  800d14:	5e                   	pop    %esi
  800d15:	5f                   	pop    %edi
  800d16:	5d                   	pop    %ebp
  800d17:	c3                   	ret    
  800d18:	90                   	nop
  800d19:	8d b4 26 00 00 00 00 	lea    0x0(%esi,%eiz,1),%esi
  800d20:	89 d8                	mov    %ebx,%eax
  800d22:	f7 f7                	div    %edi
  800d24:	31 ff                	xor    %edi,%edi
  800d26:	89 c3                	mov    %eax,%ebx
  800d28:	89 d8                	mov    %ebx,%eax
  800d2a:	89 fa                	mov    %edi,%edx
  800d2c:	83 c4 1c             	add    $0x1c,%esp
  800d2f:	5b                   	pop    %ebx
  800d30:	5e                   	pop    %esi
  800d31:	5f                   	pop    %edi
  800d32:	5d                   	pop    %ebp
  800d33:	c3                   	ret    
  800d34:	8d 74 26 00          	lea    0x0(%esi,%eiz,1),%esi
  800d38:	39 ce                	cmp    %ecx,%esi
  800d3a:	72 0c                	jb     800d48 <__udivdi3+0x118>
  800d3c:	31 db                	xor    %ebx,%ebx
  800d3e:	3b 44 24 08          	cmp    0x8(%esp),%eax
  800d42:	0f 87 34 ff ff ff    	ja     800c7c <__udivdi3+0x4c>
  800d48:	bb 01 00 00 00       	mov    $0x1,%ebx
  800d4d:	e9 2a ff ff ff       	jmp    800c7c <__udivdi3+0x4c>
  800d52:	66 90                	xchg   %ax,%ax
  800d54:	66 90                	xchg   %ax,%ax
  800d56:	66 90                	xchg   %ax,%ax
  800d58:	66 90                	xchg   %ax,%ax
  800d5a:	66 90                	xchg   %ax,%ax
  800d5c:	66 90                	xchg   %ax,%ax
  800d5e:	66 90                	xchg   %ax,%ax

00800d60 <__umoddi3>:
  800d60:	55                   	push   %ebp
  800d61:	57                   	push   %edi
  800d62:	56                   	push   %esi
  800d63:	53                   	push   %ebx
  800d64:	83 ec 1c             	sub    $0x1c,%esp
  800d67:	8b 54 24 3c          	mov    0x3c(%esp),%edx
  800d6b:	8b 4c 24 30          	mov    0x30(%esp),%ecx
  800d6f:	8b 74 24 34          	mov    0x34(%esp),%esi
  800d73:	8b 7c 24 38          	mov    0x38(%esp),%edi
  800d77:	85 d2                	test   %edx,%edx
  800d79:	89 4c 24 0c          	mov    %ecx,0xc(%esp)
  800d7d:	89 4c 24 08          	mov    %ecx,0x8(%esp)
  800d81:	89 f3                	mov    %esi,%ebx
  800d83:	89 3c 24             	mov    %edi,(%esp)
  800d86:	89 74 24 04          	mov    %esi,0x4(%esp)
  800d8a:	75 1c                	jne    800da8 <__umoddi3+0x48>
  800d8c:	39 f7                	cmp    %esi,%edi
  800d8e:	76 50                	jbe    800de0 <__umoddi3+0x80>
  800d90:	89 c8                	mov    %ecx,%eax
  800d92:	89 f2                	mov    %esi,%edx
  800d94:	f7 f7                	div    %edi
  800d96:	89 d0                	mov    %edx,%eax
  800d98:	31 d2                	xor    %edx,%edx
  800d9a:	83 c4 1c             	add    $0x1c,%esp
  800d9d:	5b                   	pop    %ebx
  800d9e:	5e                   	pop    %esi
  800d9f:	5f                   	pop    %edi
  800da0:	5d                   	pop    %ebp
  800da1:	c3                   	ret    
  800da2:	8d b6 00 00 00 00    	lea    0x0(%esi),%esi
  800da8:	39 f2                	cmp    %esi,%edx
  800daa:	89 d0                	mov    %edx,%eax
  800dac:	77 52                	ja     800e00 <__umoddi3+0xa0>
  800dae:	0f bd ea             	bsr    %edx,%ebp
  800db1:	83 f5 1f             	xor    $0x1f,%ebp
  800db4:	75 5a                	jne    800e10 <__umoddi3+0xb0>
  800db6:	3b 54 24 04          	cmp    0x4(%esp),%edx
  800dba:	0f 82 e0 00 00 00    	jb     800ea0 <__umoddi3+0x140>
  800dc0:	39 0c 24             	cmp    %ecx,(%esp)
  800dc3:	0f 86 d7 00 00 00    	jbe    800ea0 <__umoddi3+0x140>
  800dc9:	8b 44 24 08          	mov    0x8(%esp),%eax
  800dcd:	8b 54 24 04          	mov    0x4(%esp),%edx
  800dd1:	83 c4 1c             	add    $0x1c,%esp
  800dd4:	5b                   	pop    %ebx
  800dd5:	5e                   	pop    %esi
  800dd6:	5f                   	pop    %edi
  800dd7:	5d                   	pop    %ebp
  800dd8:	c3                   	ret    
  800dd9:	8d b4 26 00 00 00 00 	lea    0x0(%esi,%eiz,1),%esi
  800de0:	85 ff                	test   %edi,%edi
  800de2:	89 fd                	mov    %edi,%ebp
  800de4:	75 0b                	jne    800df1 <__umoddi3+0x91>
  800de6:	b8 01 00 00 00       	mov    $0x1,%eax
  800deb:	31 d2                	xor    %edx,%edx
  800ded:	f7 f7                	div    %edi
  800def:	89 c5                	mov    %eax,%ebp
  800df1:	89 f0                	mov    %esi,%eax
  800df3:	31 d2                	xor    %edx,%edx
  800df5:	f7 f5                	div    %ebp
  800df7:	89 c8                	mov    %ecx,%eax
  800df9:	f7 f5                	div    %ebp
  800dfb:	89 d0                	mov    %edx,%eax
  800dfd:	eb 99                	jmp    800d98 <__umoddi3+0x38>
  800dff:	90                   	nop
  800e00:	89 c8                	mov    %ecx,%eax
  800e02:	89 f2                	mov    %esi,%edx
  800e04:	83 c4 1c             	add    $0x1c,%esp
  800e07:	5b                   	pop    %ebx
  800e08:	5e                   	pop    %esi
  800e09:	5f                   	pop    %edi
  800e0a:	5d                   	pop    %ebp
  800e0b:	c3                   	ret    
  800e0c:	8d 74 26 00          	lea    0x0(%esi,%eiz,1),%esi
  800e10:	8b 34 24             	mov    (%esp),%esi
  800e13:	bf 20 00 00 00       	mov    $0x20,%edi
  800e18:	89 e9                	mov    %ebp,%ecx
  800e1a:	29 ef                	sub    %ebp,%edi
  800e1c:	d3 e0                	shl    %cl,%eax
  800e1e:	89 f9                	mov    %edi,%ecx
  800e20:	89 f2                	mov    %esi,%edx
  800e22:	d3 ea                	shr    %cl,%edx
  800e24:	89 e9                	mov    %ebp,%ecx
  800e26:	09 c2                	or     %eax,%edx
  800e28:	89 d8                	mov    %ebx,%eax
  800e2a:	89 14 24             	mov    %edx,(%esp)
  800e2d:	89 f2                	mov    %esi,%edx
  800e2f:	d3 e2                	shl    %cl,%edx
  800e31:	89 f9                	mov    %edi,%ecx
  800e33:	89 54 24 04          	mov    %edx,0x4(%esp)
  800e37:	8b 54 24 0c          	mov    0xc(%esp),%edx
  800e3b:	d3 e8                	shr    %cl,%eax
  800e3d:	89 e9                	mov    %ebp,%ecx
  800e3f:	89 c6                	mov    %eax,%esi
  800e41:	d3 e3                	shl    %cl,%ebx
  800e43:	89 f9                	mov    %edi,%ecx
  800e45:	89 d0                	mov    %edx,%eax
  800e47:	d3 e8                	shr    %cl,%eax
  800e49:	89 e9                	mov    %ebp,%ecx
  800e4b:	09 d8                	or     %ebx,%eax
  800e4d:	89 d3                	mov    %edx,%ebx
  800e4f:	89 f2                	mov    %esi,%edx
  800e51:	f7 34 24             	divl   (%esp)
  800e54:	89 d6                	mov    %edx,%esi
  800e56:	d3 e3                	shl    %cl,%ebx
  800e58:	f7 64 24 04          	mull   0x4(%esp)
  800e5c:	39 d6                	cmp    %edx,%esi
  800e5e:	89 5c 24 08          	mov    %ebx,0x8(%esp)
  800e62:	89 d1                	mov    %edx,%ecx
  800e64:	89 c3                	mov    %eax,%ebx
  800e66:	72 08                	jb     800e70 <__umoddi3+0x110>
  800e68:	75 11                	jne    800e7b <__umoddi3+0x11b>
  800e6a:	39 44 24 08          	cmp    %eax,0x8(%esp)
  800e6e:	73 0b                	jae    800e7b <__umoddi3+0x11b>
  800e70:	2b 44 24 04          	sub    0x4(%esp),%eax
  800e74:	1b 14 24             	sbb    (%esp),%edx
  800e77:	89 d1                	mov    %edx,%ecx
  800e79:	89 c3                	mov    %eax,%ebx
  800e7b:	8b 54 24 08          	mov    0x8(%esp),%edx
  800e7f:	29 da                	sub    %ebx,%edx
  800e81:	19 ce                	sbb    %ecx,%esi
  800e83:	89 f9                	mov    %edi,%ecx
  800e85:	89 f0                	mov    %esi,%eax
  800e87:	d3 e0                	shl    %cl,%eax
  800e89:	89 e9                	mov    %ebp,%ecx
  800e8b:	d3 ea                	shr    %cl,%edx
  800e8d:	89 e9                	mov    %ebp,%ecx
  800e8f:	d3 ee                	shr    %cl,%esi
  800e91:	09 d0                	or     %edx,%eax
  800e93:	89 f2                	mov    %esi,%edx
  800e95:	83 c4 1c             	add    $0x1c,%esp
  800e98:	5b                   	pop    %ebx
  800e99:	5e                   	pop    %esi
  800e9a:	5f                   	pop    %edi
  800e9b:	5d                   	pop    %ebp
  800e9c:	c3                   	ret    
  800e9d:	8d 76 00             	lea    0x0(%esi),%esi
  800ea0:	29 f9                	sub    %edi,%ecx
  800ea2:	19 d6                	sbb    %edx,%esi
  800ea4:	89 74 24 04          	mov    %esi,0x4(%esp)
  800ea8:	89 4c 24 08          	mov    %ecx,0x8(%esp)
  800eac:	e9 18 ff ff ff       	jmp    800dc9 <__umoddi3+0x69>
