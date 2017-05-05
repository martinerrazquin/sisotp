
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
  80003c:	83 ec 18             	sub    $0x18,%esp
  80003f:	8b 45 08             	mov    0x8(%ebp),%eax
  800042:	8b 55 0c             	mov    0xc(%ebp),%edx
	// set thisenv to point at our Env structure in envs[].
	// LAB 3: Your code here.
	thisenv = 0;
  800045:	c7 05 04 20 80 00 00 	movl   $0x0,0x802004
  80004c:	00 00 00 

	// save the name of the program so that panic() can use it
	if (argc > 0)
  80004f:	85 c0                	test   %eax,%eax
  800051:	7e 08                	jle    80005b <libmain+0x22>
		binaryname = argv[0];
  800053:	8b 0a                	mov    (%edx),%ecx
  800055:	89 0d 00 20 80 00    	mov    %ecx,0x802000

	// call user main routine
	umain(argc, argv);
  80005b:	89 54 24 04          	mov    %edx,0x4(%esp)
  80005f:	89 04 24             	mov    %eax,(%esp)
  800062:	e8 cc ff ff ff       	call   800033 <umain>

	// exit gracefully
	exit();
  800067:	e8 02 00 00 00       	call   80006e <exit>
}
  80006c:	c9                   	leave  
  80006d:	c3                   	ret    

0080006e <exit>:

#include <inc/lib.h>

void
exit(void)
{
  80006e:	55                   	push   %ebp
  80006f:	89 e5                	mov    %esp,%ebp
  800071:	83 ec 18             	sub    $0x18,%esp
	sys_env_destroy(0);
  800074:	c7 04 24 00 00 00 00 	movl   $0x0,(%esp)
  80007b:	e8 cd 00 00 00       	call   80014d <sys_env_destroy>
}
  800080:	c9                   	leave  
  800081:	c3                   	ret    

00800082 <syscall>:
#include <inc/syscall.h>
#include <inc/lib.h>

static inline int32_t
syscall(int num, int check, uint32_t a1, uint32_t a2, uint32_t a3, uint32_t a4, uint32_t a5)
{
  800082:	55                   	push   %ebp
  800083:	89 e5                	mov    %esp,%ebp
  800085:	57                   	push   %edi
  800086:	56                   	push   %esi
  800087:	53                   	push   %ebx
  800088:	83 ec 2c             	sub    $0x2c,%esp
  80008b:	89 45 e4             	mov    %eax,-0x1c(%ebp)
  80008e:	89 55 e0             	mov    %edx,-0x20(%ebp)
  800091:	89 ca                	mov    %ecx,%edx
	//
	// The last clause tells the assembler that this can
	// potentially change the condition codes and arbitrary
	// memory locations.

	asm volatile("int %1\n"
  800093:	8b 4d 08             	mov    0x8(%ebp),%ecx
  800096:	8b 5d 0c             	mov    0xc(%ebp),%ebx
  800099:	8b 7d 10             	mov    0x10(%ebp),%edi
  80009c:	8b 75 14             	mov    0x14(%ebp),%esi
  80009f:	cd 30                	int    $0x30
		       "b" (a3),
		       "D" (a4),
		       "S" (a5)
		     : "cc", "memory");

	if(check && ret > 0)
  8000a1:	85 c0                	test   %eax,%eax
  8000a3:	7e 2d                	jle    8000d2 <syscall+0x50>
  8000a5:	83 7d e0 00          	cmpl   $0x0,-0x20(%ebp)
  8000a9:	74 27                	je     8000d2 <syscall+0x50>
		panic("syscall %d returned %d (> 0)", num, ret);
  8000ab:	89 44 24 10          	mov    %eax,0x10(%esp)
  8000af:	8b 45 e4             	mov    -0x1c(%ebp),%eax
  8000b2:	89 44 24 0c          	mov    %eax,0xc(%esp)
  8000b6:	c7 44 24 08 ae 0e 80 	movl   $0x800eae,0x8(%esp)
  8000bd:	00 
  8000be:	c7 44 24 04 23 00 00 	movl   $0x23,0x4(%esp)
  8000c5:	00 
  8000c6:	c7 04 24 cb 0e 80 00 	movl   $0x800ecb,(%esp)
  8000cd:	e8 ef 00 00 00       	call   8001c1 <_panic>

	return ret;
}
  8000d2:	83 c4 2c             	add    $0x2c,%esp
  8000d5:	5b                   	pop    %ebx
  8000d6:	5e                   	pop    %esi
  8000d7:	5f                   	pop    %edi
  8000d8:	5d                   	pop    %ebp
  8000d9:	c3                   	ret    

008000da <sys_cputs>:

void
sys_cputs(const char *s, size_t len)
{
  8000da:	55                   	push   %ebp
  8000db:	89 e5                	mov    %esp,%ebp
  8000dd:	83 ec 18             	sub    $0x18,%esp
	syscall(SYS_cputs, 0, (uint32_t)s, len, 0, 0, 0);
  8000e0:	c7 44 24 0c 00 00 00 	movl   $0x0,0xc(%esp)
  8000e7:	00 
  8000e8:	c7 44 24 08 00 00 00 	movl   $0x0,0x8(%esp)
  8000ef:	00 
  8000f0:	c7 44 24 04 00 00 00 	movl   $0x0,0x4(%esp)
  8000f7:	00 
  8000f8:	8b 45 0c             	mov    0xc(%ebp),%eax
  8000fb:	89 04 24             	mov    %eax,(%esp)
  8000fe:	8b 4d 08             	mov    0x8(%ebp),%ecx
  800101:	ba 00 00 00 00       	mov    $0x0,%edx
  800106:	b8 00 00 00 00       	mov    $0x0,%eax
  80010b:	e8 72 ff ff ff       	call   800082 <syscall>
}
  800110:	c9                   	leave  
  800111:	c3                   	ret    

00800112 <sys_cgetc>:

int
sys_cgetc(void)
{
  800112:	55                   	push   %ebp
  800113:	89 e5                	mov    %esp,%ebp
  800115:	83 ec 18             	sub    $0x18,%esp
	return syscall(SYS_cgetc, 0, 0, 0, 0, 0, 0);
  800118:	c7 44 24 0c 00 00 00 	movl   $0x0,0xc(%esp)
  80011f:	00 
  800120:	c7 44 24 08 00 00 00 	movl   $0x0,0x8(%esp)
  800127:	00 
  800128:	c7 44 24 04 00 00 00 	movl   $0x0,0x4(%esp)
  80012f:	00 
  800130:	c7 04 24 00 00 00 00 	movl   $0x0,(%esp)
  800137:	b9 00 00 00 00       	mov    $0x0,%ecx
  80013c:	ba 00 00 00 00       	mov    $0x0,%edx
  800141:	b8 01 00 00 00       	mov    $0x1,%eax
  800146:	e8 37 ff ff ff       	call   800082 <syscall>
}
  80014b:	c9                   	leave  
  80014c:	c3                   	ret    

0080014d <sys_env_destroy>:

int
sys_env_destroy(envid_t envid)
{
  80014d:	55                   	push   %ebp
  80014e:	89 e5                	mov    %esp,%ebp
  800150:	83 ec 18             	sub    $0x18,%esp
	return syscall(SYS_env_destroy, 1, envid, 0, 0, 0, 0);
  800153:	c7 44 24 0c 00 00 00 	movl   $0x0,0xc(%esp)
  80015a:	00 
  80015b:	c7 44 24 08 00 00 00 	movl   $0x0,0x8(%esp)
  800162:	00 
  800163:	c7 44 24 04 00 00 00 	movl   $0x0,0x4(%esp)
  80016a:	00 
  80016b:	c7 04 24 00 00 00 00 	movl   $0x0,(%esp)
  800172:	8b 4d 08             	mov    0x8(%ebp),%ecx
  800175:	ba 01 00 00 00       	mov    $0x1,%edx
  80017a:	b8 03 00 00 00       	mov    $0x3,%eax
  80017f:	e8 fe fe ff ff       	call   800082 <syscall>
}
  800184:	c9                   	leave  
  800185:	c3                   	ret    

00800186 <sys_getenvid>:

envid_t
sys_getenvid(void)
{
  800186:	55                   	push   %ebp
  800187:	89 e5                	mov    %esp,%ebp
  800189:	83 ec 18             	sub    $0x18,%esp
	 return syscall(SYS_getenvid, 0, 0, 0, 0, 0, 0);
  80018c:	c7 44 24 0c 00 00 00 	movl   $0x0,0xc(%esp)
  800193:	00 
  800194:	c7 44 24 08 00 00 00 	movl   $0x0,0x8(%esp)
  80019b:	00 
  80019c:	c7 44 24 04 00 00 00 	movl   $0x0,0x4(%esp)
  8001a3:	00 
  8001a4:	c7 04 24 00 00 00 00 	movl   $0x0,(%esp)
  8001ab:	b9 00 00 00 00       	mov    $0x0,%ecx
  8001b0:	ba 00 00 00 00       	mov    $0x0,%edx
  8001b5:	b8 02 00 00 00       	mov    $0x2,%eax
  8001ba:	e8 c3 fe ff ff       	call   800082 <syscall>
}
  8001bf:	c9                   	leave  
  8001c0:	c3                   	ret    

008001c1 <_panic>:
 * It prints "panic: <message>", then causes a breakpoint exception,
 * which causes JOS to enter the JOS kernel monitor.
 */
void
_panic(const char *file, int line, const char *fmt, ...)
{
  8001c1:	55                   	push   %ebp
  8001c2:	89 e5                	mov    %esp,%ebp
  8001c4:	56                   	push   %esi
  8001c5:	53                   	push   %ebx
  8001c6:	83 ec 20             	sub    $0x20,%esp
	va_list ap;

	va_start(ap, fmt);
  8001c9:	8d 5d 14             	lea    0x14(%ebp),%ebx

	// Print the panic message
	cprintf("[%08x] user panic in %s at %s:%d: ",
  8001cc:	8b 35 00 20 80 00    	mov    0x802000,%esi
  8001d2:	e8 af ff ff ff       	call   800186 <sys_getenvid>
  8001d7:	8b 55 0c             	mov    0xc(%ebp),%edx
  8001da:	89 54 24 10          	mov    %edx,0x10(%esp)
  8001de:	8b 55 08             	mov    0x8(%ebp),%edx
  8001e1:	89 54 24 0c          	mov    %edx,0xc(%esp)
  8001e5:	89 74 24 08          	mov    %esi,0x8(%esp)
  8001e9:	89 44 24 04          	mov    %eax,0x4(%esp)
  8001ed:	c7 04 24 dc 0e 80 00 	movl   $0x800edc,(%esp)
  8001f4:	e8 c1 00 00 00       	call   8002ba <cprintf>
		sys_getenvid(), binaryname, file, line);
	vcprintf(fmt, ap);
  8001f9:	89 5c 24 04          	mov    %ebx,0x4(%esp)
  8001fd:	8b 45 10             	mov    0x10(%ebp),%eax
  800200:	89 04 24             	mov    %eax,(%esp)
  800203:	e8 51 00 00 00       	call   800259 <vcprintf>
	cprintf("\n");
  800208:	c7 04 24 00 0f 80 00 	movl   $0x800f00,(%esp)
  80020f:	e8 a6 00 00 00       	call   8002ba <cprintf>

	// Cause a breakpoint exception
	while (1)
		asm volatile("int3");
  800214:	cc                   	int3   
  800215:	eb fd                	jmp    800214 <_panic+0x53>

00800217 <putch>:
};


static void
putch(int ch, struct printbuf *b)
{
  800217:	55                   	push   %ebp
  800218:	89 e5                	mov    %esp,%ebp
  80021a:	53                   	push   %ebx
  80021b:	83 ec 14             	sub    $0x14,%esp
  80021e:	8b 5d 0c             	mov    0xc(%ebp),%ebx
	b->buf[b->idx++] = ch;
  800221:	8b 13                	mov    (%ebx),%edx
  800223:	8d 42 01             	lea    0x1(%edx),%eax
  800226:	89 03                	mov    %eax,(%ebx)
  800228:	8b 4d 08             	mov    0x8(%ebp),%ecx
  80022b:	88 4c 13 08          	mov    %cl,0x8(%ebx,%edx,1)
	if (b->idx == 256-1) {
  80022f:	3d ff 00 00 00       	cmp    $0xff,%eax
  800234:	75 19                	jne    80024f <putch+0x38>
		sys_cputs(b->buf, b->idx);
  800236:	c7 44 24 04 ff 00 00 	movl   $0xff,0x4(%esp)
  80023d:	00 
  80023e:	8d 43 08             	lea    0x8(%ebx),%eax
  800241:	89 04 24             	mov    %eax,(%esp)
  800244:	e8 91 fe ff ff       	call   8000da <sys_cputs>
		b->idx = 0;
  800249:	c7 03 00 00 00 00    	movl   $0x0,(%ebx)
	}
	b->cnt++;
  80024f:	83 43 04 01          	addl   $0x1,0x4(%ebx)
}
  800253:	83 c4 14             	add    $0x14,%esp
  800256:	5b                   	pop    %ebx
  800257:	5d                   	pop    %ebp
  800258:	c3                   	ret    

00800259 <vcprintf>:

int
vcprintf(const char *fmt, va_list ap)
{
  800259:	55                   	push   %ebp
  80025a:	89 e5                	mov    %esp,%ebp
  80025c:	81 ec 28 01 00 00    	sub    $0x128,%esp
	struct printbuf b;

	b.idx = 0;
  800262:	c7 85 f0 fe ff ff 00 	movl   $0x0,-0x110(%ebp)
  800269:	00 00 00 
	b.cnt = 0;
  80026c:	c7 85 f4 fe ff ff 00 	movl   $0x0,-0x10c(%ebp)
  800273:	00 00 00 
	vprintfmt((void*)putch, &b, fmt, ap);
  800276:	8b 45 0c             	mov    0xc(%ebp),%eax
  800279:	89 44 24 0c          	mov    %eax,0xc(%esp)
  80027d:	8b 45 08             	mov    0x8(%ebp),%eax
  800280:	89 44 24 08          	mov    %eax,0x8(%esp)
  800284:	8d 85 f0 fe ff ff    	lea    -0x110(%ebp),%eax
  80028a:	89 44 24 04          	mov    %eax,0x4(%esp)
  80028e:	c7 04 24 17 02 80 00 	movl   $0x800217,(%esp)
  800295:	e8 e6 01 00 00       	call   800480 <vprintfmt>
	sys_cputs(b.buf, b.idx);
  80029a:	8b 85 f0 fe ff ff    	mov    -0x110(%ebp),%eax
  8002a0:	89 44 24 04          	mov    %eax,0x4(%esp)
  8002a4:	8d 85 f8 fe ff ff    	lea    -0x108(%ebp),%eax
  8002aa:	89 04 24             	mov    %eax,(%esp)
  8002ad:	e8 28 fe ff ff       	call   8000da <sys_cputs>

	return b.cnt;
}
  8002b2:	8b 85 f4 fe ff ff    	mov    -0x10c(%ebp),%eax
  8002b8:	c9                   	leave  
  8002b9:	c3                   	ret    

008002ba <cprintf>:

int
cprintf(const char *fmt, ...)
{
  8002ba:	55                   	push   %ebp
  8002bb:	89 e5                	mov    %esp,%ebp
  8002bd:	83 ec 18             	sub    $0x18,%esp
	va_list ap;
	int cnt;

	va_start(ap, fmt);
  8002c0:	8d 45 0c             	lea    0xc(%ebp),%eax
	cnt = vcprintf(fmt, ap);
  8002c3:	89 44 24 04          	mov    %eax,0x4(%esp)
  8002c7:	8b 45 08             	mov    0x8(%ebp),%eax
  8002ca:	89 04 24             	mov    %eax,(%esp)
  8002cd:	e8 87 ff ff ff       	call   800259 <vcprintf>
	va_end(ap);

	return cnt;
}
  8002d2:	c9                   	leave  
  8002d3:	c3                   	ret    
  8002d4:	66 90                	xchg   %ax,%ax
  8002d6:	66 90                	xchg   %ax,%ax
  8002d8:	66 90                	xchg   %ax,%ax
  8002da:	66 90                	xchg   %ax,%ax
  8002dc:	66 90                	xchg   %ax,%ax
  8002de:	66 90                	xchg   %ax,%ax

008002e0 <printnum>:
 * using specified putch function and associated pointer putdat.
 */
static void
printnum(void (*putch)(int, void*), void *putdat,
	 unsigned long long num, unsigned base, int width, int padc)
{
  8002e0:	55                   	push   %ebp
  8002e1:	89 e5                	mov    %esp,%ebp
  8002e3:	57                   	push   %edi
  8002e4:	56                   	push   %esi
  8002e5:	53                   	push   %ebx
  8002e6:	83 ec 3c             	sub    $0x3c,%esp
  8002e9:	89 45 e4             	mov    %eax,-0x1c(%ebp)
  8002ec:	89 d7                	mov    %edx,%edi
  8002ee:	8b 45 08             	mov    0x8(%ebp),%eax
  8002f1:	89 45 e0             	mov    %eax,-0x20(%ebp)
  8002f4:	8b 45 0c             	mov    0xc(%ebp),%eax
  8002f7:	89 c3                	mov    %eax,%ebx
  8002f9:	89 45 d4             	mov    %eax,-0x2c(%ebp)
  8002fc:	8b 45 10             	mov    0x10(%ebp),%eax
  8002ff:	8b 75 14             	mov    0x14(%ebp),%esi
	// first recursively print all preceding (more significant) digits
	if (num >= base) {
  800302:	b9 00 00 00 00       	mov    $0x0,%ecx
  800307:	89 45 d8             	mov    %eax,-0x28(%ebp)
  80030a:	89 4d dc             	mov    %ecx,-0x24(%ebp)
  80030d:	39 d9                	cmp    %ebx,%ecx
  80030f:	72 05                	jb     800316 <printnum+0x36>
  800311:	3b 45 e0             	cmp    -0x20(%ebp),%eax
  800314:	77 69                	ja     80037f <printnum+0x9f>
		printnum(putch, putdat, num / base, base, width - 1, padc);
  800316:	8b 4d 18             	mov    0x18(%ebp),%ecx
  800319:	89 4c 24 10          	mov    %ecx,0x10(%esp)
  80031d:	83 ee 01             	sub    $0x1,%esi
  800320:	89 74 24 0c          	mov    %esi,0xc(%esp)
  800324:	89 44 24 08          	mov    %eax,0x8(%esp)
  800328:	8b 44 24 08          	mov    0x8(%esp),%eax
  80032c:	8b 54 24 0c          	mov    0xc(%esp),%edx
  800330:	89 c3                	mov    %eax,%ebx
  800332:	89 d6                	mov    %edx,%esi
  800334:	8b 55 d8             	mov    -0x28(%ebp),%edx
  800337:	8b 4d dc             	mov    -0x24(%ebp),%ecx
  80033a:	89 54 24 08          	mov    %edx,0x8(%esp)
  80033e:	89 4c 24 0c          	mov    %ecx,0xc(%esp)
  800342:	8b 45 e0             	mov    -0x20(%ebp),%eax
  800345:	89 04 24             	mov    %eax,(%esp)
  800348:	8b 45 d4             	mov    -0x2c(%ebp),%eax
  80034b:	89 44 24 04          	mov    %eax,0x4(%esp)
  80034f:	e8 cc 08 00 00       	call   800c20 <__udivdi3>
  800354:	89 d9                	mov    %ebx,%ecx
  800356:	89 4c 24 08          	mov    %ecx,0x8(%esp)
  80035a:	89 74 24 0c          	mov    %esi,0xc(%esp)
  80035e:	89 04 24             	mov    %eax,(%esp)
  800361:	89 54 24 04          	mov    %edx,0x4(%esp)
  800365:	89 fa                	mov    %edi,%edx
  800367:	8b 45 e4             	mov    -0x1c(%ebp),%eax
  80036a:	e8 71 ff ff ff       	call   8002e0 <printnum>
  80036f:	eb 1b                	jmp    80038c <printnum+0xac>
	} else {
		// print any needed pad characters before first digit
		while (--width > 0)
			putch(padc, putdat);
  800371:	89 7c 24 04          	mov    %edi,0x4(%esp)
  800375:	8b 45 18             	mov    0x18(%ebp),%eax
  800378:	89 04 24             	mov    %eax,(%esp)
  80037b:	ff d3                	call   *%ebx
  80037d:	eb 03                	jmp    800382 <printnum+0xa2>
  80037f:	8b 5d e4             	mov    -0x1c(%ebp),%ebx
	// first recursively print all preceding (more significant) digits
	if (num >= base) {
		printnum(putch, putdat, num / base, base, width - 1, padc);
	} else {
		// print any needed pad characters before first digit
		while (--width > 0)
  800382:	83 ee 01             	sub    $0x1,%esi
  800385:	85 f6                	test   %esi,%esi
  800387:	7f e8                	jg     800371 <printnum+0x91>
  800389:	89 5d e4             	mov    %ebx,-0x1c(%ebp)
			putch(padc, putdat);
	}

	// then print this (the least significant) digit
	putch("0123456789abcdef"[num % base], putdat);
  80038c:	89 7c 24 04          	mov    %edi,0x4(%esp)
  800390:	8b 7c 24 04          	mov    0x4(%esp),%edi
  800394:	8b 45 d8             	mov    -0x28(%ebp),%eax
  800397:	8b 55 dc             	mov    -0x24(%ebp),%edx
  80039a:	89 44 24 08          	mov    %eax,0x8(%esp)
  80039e:	89 54 24 0c          	mov    %edx,0xc(%esp)
  8003a2:	8b 45 e0             	mov    -0x20(%ebp),%eax
  8003a5:	89 04 24             	mov    %eax,(%esp)
  8003a8:	8b 45 d4             	mov    -0x2c(%ebp),%eax
  8003ab:	89 44 24 04          	mov    %eax,0x4(%esp)
  8003af:	e8 9c 09 00 00       	call   800d50 <__umoddi3>
  8003b4:	89 7c 24 04          	mov    %edi,0x4(%esp)
  8003b8:	0f be 80 02 0f 80 00 	movsbl 0x800f02(%eax),%eax
  8003bf:	89 04 24             	mov    %eax,(%esp)
  8003c2:	8b 45 e4             	mov    -0x1c(%ebp),%eax
  8003c5:	ff d0                	call   *%eax
}
  8003c7:	83 c4 3c             	add    $0x3c,%esp
  8003ca:	5b                   	pop    %ebx
  8003cb:	5e                   	pop    %esi
  8003cc:	5f                   	pop    %edi
  8003cd:	5d                   	pop    %ebp
  8003ce:	c3                   	ret    

008003cf <getuint>:

// Get an unsigned int of various possible sizes from a varargs list,
// depending on the lflag parameter.
static unsigned long long
getuint(va_list *ap, int lflag)
{
  8003cf:	55                   	push   %ebp
  8003d0:	89 e5                	mov    %esp,%ebp
	if (lflag >= 2)
  8003d2:	83 fa 01             	cmp    $0x1,%edx
  8003d5:	7e 0e                	jle    8003e5 <getuint+0x16>
		return va_arg(*ap, unsigned long long);
  8003d7:	8b 10                	mov    (%eax),%edx
  8003d9:	8d 4a 08             	lea    0x8(%edx),%ecx
  8003dc:	89 08                	mov    %ecx,(%eax)
  8003de:	8b 02                	mov    (%edx),%eax
  8003e0:	8b 52 04             	mov    0x4(%edx),%edx
  8003e3:	eb 22                	jmp    800407 <getuint+0x38>
	else if (lflag)
  8003e5:	85 d2                	test   %edx,%edx
  8003e7:	74 10                	je     8003f9 <getuint+0x2a>
		return va_arg(*ap, unsigned long);
  8003e9:	8b 10                	mov    (%eax),%edx
  8003eb:	8d 4a 04             	lea    0x4(%edx),%ecx
  8003ee:	89 08                	mov    %ecx,(%eax)
  8003f0:	8b 02                	mov    (%edx),%eax
  8003f2:	ba 00 00 00 00       	mov    $0x0,%edx
  8003f7:	eb 0e                	jmp    800407 <getuint+0x38>
	else
		return va_arg(*ap, unsigned int);
  8003f9:	8b 10                	mov    (%eax),%edx
  8003fb:	8d 4a 04             	lea    0x4(%edx),%ecx
  8003fe:	89 08                	mov    %ecx,(%eax)
  800400:	8b 02                	mov    (%edx),%eax
  800402:	ba 00 00 00 00       	mov    $0x0,%edx
}
  800407:	5d                   	pop    %ebp
  800408:	c3                   	ret    

00800409 <getint>:

// Same as getuint but signed - can't use getuint
// because of sign extension
static long long
getint(va_list *ap, int lflag)
{
  800409:	55                   	push   %ebp
  80040a:	89 e5                	mov    %esp,%ebp
	if (lflag >= 2)
  80040c:	83 fa 01             	cmp    $0x1,%edx
  80040f:	7e 0e                	jle    80041f <getint+0x16>
		return va_arg(*ap, long long);
  800411:	8b 10                	mov    (%eax),%edx
  800413:	8d 4a 08             	lea    0x8(%edx),%ecx
  800416:	89 08                	mov    %ecx,(%eax)
  800418:	8b 02                	mov    (%edx),%eax
  80041a:	8b 52 04             	mov    0x4(%edx),%edx
  80041d:	eb 1a                	jmp    800439 <getint+0x30>
	else if (lflag)
  80041f:	85 d2                	test   %edx,%edx
  800421:	74 0c                	je     80042f <getint+0x26>
		return va_arg(*ap, long);
  800423:	8b 10                	mov    (%eax),%edx
  800425:	8d 4a 04             	lea    0x4(%edx),%ecx
  800428:	89 08                	mov    %ecx,(%eax)
  80042a:	8b 02                	mov    (%edx),%eax
  80042c:	99                   	cltd   
  80042d:	eb 0a                	jmp    800439 <getint+0x30>
	else
		return va_arg(*ap, int);
  80042f:	8b 10                	mov    (%eax),%edx
  800431:	8d 4a 04             	lea    0x4(%edx),%ecx
  800434:	89 08                	mov    %ecx,(%eax)
  800436:	8b 02                	mov    (%edx),%eax
  800438:	99                   	cltd   
}
  800439:	5d                   	pop    %ebp
  80043a:	c3                   	ret    

0080043b <sprintputch>:
	int cnt;
};

static void
sprintputch(int ch, struct sprintbuf *b)
{
  80043b:	55                   	push   %ebp
  80043c:	89 e5                	mov    %esp,%ebp
  80043e:	8b 45 0c             	mov    0xc(%ebp),%eax
	b->cnt++;
  800441:	83 40 08 01          	addl   $0x1,0x8(%eax)
	if (b->buf < b->ebuf)
  800445:	8b 10                	mov    (%eax),%edx
  800447:	3b 50 04             	cmp    0x4(%eax),%edx
  80044a:	73 0a                	jae    800456 <sprintputch+0x1b>
		*b->buf++ = ch;
  80044c:	8d 4a 01             	lea    0x1(%edx),%ecx
  80044f:	89 08                	mov    %ecx,(%eax)
  800451:	8b 45 08             	mov    0x8(%ebp),%eax
  800454:	88 02                	mov    %al,(%edx)
}
  800456:	5d                   	pop    %ebp
  800457:	c3                   	ret    

00800458 <printfmt>:
	}
}

void
printfmt(void (*putch)(int, void*), void *putdat, const char *fmt, ...)
{
  800458:	55                   	push   %ebp
  800459:	89 e5                	mov    %esp,%ebp
  80045b:	83 ec 18             	sub    $0x18,%esp
	va_list ap;

	va_start(ap, fmt);
  80045e:	8d 45 14             	lea    0x14(%ebp),%eax
	vprintfmt(putch, putdat, fmt, ap);
  800461:	89 44 24 0c          	mov    %eax,0xc(%esp)
  800465:	8b 45 10             	mov    0x10(%ebp),%eax
  800468:	89 44 24 08          	mov    %eax,0x8(%esp)
  80046c:	8b 45 0c             	mov    0xc(%ebp),%eax
  80046f:	89 44 24 04          	mov    %eax,0x4(%esp)
  800473:	8b 45 08             	mov    0x8(%ebp),%eax
  800476:	89 04 24             	mov    %eax,(%esp)
  800479:	e8 02 00 00 00       	call   800480 <vprintfmt>
	va_end(ap);
}
  80047e:	c9                   	leave  
  80047f:	c3                   	ret    

00800480 <vprintfmt>:
// Main function to format and print a string.
void printfmt(void (*putch)(int, void*), void *putdat, const char *fmt, ...);

void
vprintfmt(void (*putch)(int, void*), void *putdat, const char *fmt, va_list ap)
{
  800480:	55                   	push   %ebp
  800481:	89 e5                	mov    %esp,%ebp
  800483:	57                   	push   %edi
  800484:	56                   	push   %esi
  800485:	53                   	push   %ebx
  800486:	83 ec 3c             	sub    $0x3c,%esp
  800489:	8b 75 0c             	mov    0xc(%ebp),%esi
  80048c:	8b 7d 10             	mov    0x10(%ebp),%edi
  80048f:	eb 14                	jmp    8004a5 <vprintfmt+0x25>
	int base, lflag, width, precision, altflag;
	char padc;

	while (1) {
		while ((ch = *(unsigned char *) fmt++) != '%') {
			if (ch == '\0')
  800491:	85 c0                	test   %eax,%eax
  800493:	0f 84 63 03 00 00    	je     8007fc <vprintfmt+0x37c>
				return;
			putch(ch, putdat);
  800499:	89 74 24 04          	mov    %esi,0x4(%esp)
  80049d:	89 04 24             	mov    %eax,(%esp)
  8004a0:	ff 55 08             	call   *0x8(%ebp)
	unsigned long long num;
	int base, lflag, width, precision, altflag;
	char padc;

	while (1) {
		while ((ch = *(unsigned char *) fmt++) != '%') {
  8004a3:	89 df                	mov    %ebx,%edi
  8004a5:	8d 5f 01             	lea    0x1(%edi),%ebx
  8004a8:	0f b6 07             	movzbl (%edi),%eax
  8004ab:	83 f8 25             	cmp    $0x25,%eax
  8004ae:	75 e1                	jne    800491 <vprintfmt+0x11>
  8004b0:	c6 45 d8 20          	movb   $0x20,-0x28(%ebp)
  8004b4:	c7 45 e0 00 00 00 00 	movl   $0x0,-0x20(%ebp)
  8004bb:	c7 45 d4 ff ff ff ff 	movl   $0xffffffff,-0x2c(%ebp)
  8004c2:	c7 45 dc ff ff ff ff 	movl   $0xffffffff,-0x24(%ebp)
  8004c9:	ba 00 00 00 00       	mov    $0x0,%edx
  8004ce:	eb 1d                	jmp    8004ed <vprintfmt+0x6d>
		width = -1;
		precision = -1;
		lflag = 0;
		altflag = 0;
	reswitch:
		switch (ch = *(unsigned char *) fmt++) {
  8004d0:	89 fb                	mov    %edi,%ebx

		// flag to pad on the right
		case '-':
			padc = '-';
  8004d2:	c6 45 d8 2d          	movb   $0x2d,-0x28(%ebp)
  8004d6:	eb 15                	jmp    8004ed <vprintfmt+0x6d>
		width = -1;
		precision = -1;
		lflag = 0;
		altflag = 0;
	reswitch:
		switch (ch = *(unsigned char *) fmt++) {
  8004d8:	89 fb                	mov    %edi,%ebx
			padc = '-';
			goto reswitch;

		// flag to pad with 0's instead of spaces
		case '0':
			padc = '0';
  8004da:	c6 45 d8 30          	movb   $0x30,-0x28(%ebp)
  8004de:	eb 0d                	jmp    8004ed <vprintfmt+0x6d>
			altflag = 1;
			goto reswitch;

		process_precision:
			if (width < 0)
				width = precision, precision = -1;
  8004e0:	8b 45 d4             	mov    -0x2c(%ebp),%eax
  8004e3:	89 45 dc             	mov    %eax,-0x24(%ebp)
  8004e6:	c7 45 d4 ff ff ff ff 	movl   $0xffffffff,-0x2c(%ebp)
		width = -1;
		precision = -1;
		lflag = 0;
		altflag = 0;
	reswitch:
		switch (ch = *(unsigned char *) fmt++) {
  8004ed:	8d 7b 01             	lea    0x1(%ebx),%edi
  8004f0:	0f b6 0b             	movzbl (%ebx),%ecx
  8004f3:	0f b6 c1             	movzbl %cl,%eax
  8004f6:	83 e9 23             	sub    $0x23,%ecx
  8004f9:	80 f9 55             	cmp    $0x55,%cl
  8004fc:	0f 87 da 02 00 00    	ja     8007dc <vprintfmt+0x35c>
  800502:	0f b6 c9             	movzbl %cl,%ecx
  800505:	ff 24 8d 90 0f 80 00 	jmp    *0x800f90(,%ecx,4)
  80050c:	89 fb                	mov    %edi,%ebx
  80050e:	b9 00 00 00 00       	mov    $0x0,%ecx
		case '6':
		case '7':
		case '8':
		case '9':
			for (precision = 0; ; ++fmt) {
				precision = precision * 10 + ch - '0';
  800513:	8d 0c 89             	lea    (%ecx,%ecx,4),%ecx
  800516:	8d 4c 48 d0          	lea    -0x30(%eax,%ecx,2),%ecx
				ch = *fmt;
  80051a:	0f be 03             	movsbl (%ebx),%eax
				if (ch < '0' || ch > '9')
  80051d:	8d 78 d0             	lea    -0x30(%eax),%edi
  800520:	83 ff 09             	cmp    $0x9,%edi
  800523:	77 36                	ja     80055b <vprintfmt+0xdb>
		case '5':
		case '6':
		case '7':
		case '8':
		case '9':
			for (precision = 0; ; ++fmt) {
  800525:	83 c3 01             	add    $0x1,%ebx
				precision = precision * 10 + ch - '0';
				ch = *fmt;
				if (ch < '0' || ch > '9')
					break;
			}
  800528:	eb e9                	jmp    800513 <vprintfmt+0x93>
			goto process_precision;

		case '*':
			precision = va_arg(ap, int);
  80052a:	8b 45 14             	mov    0x14(%ebp),%eax
  80052d:	8d 48 04             	lea    0x4(%eax),%ecx
  800530:	89 4d 14             	mov    %ecx,0x14(%ebp)
  800533:	8b 00                	mov    (%eax),%eax
  800535:	89 45 d4             	mov    %eax,-0x2c(%ebp)
		width = -1;
		precision = -1;
		lflag = 0;
		altflag = 0;
	reswitch:
		switch (ch = *(unsigned char *) fmt++) {
  800538:	89 fb                	mov    %edi,%ebx
			}
			goto process_precision;

		case '*':
			precision = va_arg(ap, int);
			goto process_precision;
  80053a:	eb 22                	jmp    80055e <vprintfmt+0xde>
  80053c:	8b 4d dc             	mov    -0x24(%ebp),%ecx
  80053f:	85 c9                	test   %ecx,%ecx
  800541:	b8 00 00 00 00       	mov    $0x0,%eax
  800546:	0f 49 c1             	cmovns %ecx,%eax
  800549:	89 45 dc             	mov    %eax,-0x24(%ebp)
		width = -1;
		precision = -1;
		lflag = 0;
		altflag = 0;
	reswitch:
		switch (ch = *(unsigned char *) fmt++) {
  80054c:	89 fb                	mov    %edi,%ebx
  80054e:	eb 9d                	jmp    8004ed <vprintfmt+0x6d>
  800550:	89 fb                	mov    %edi,%ebx
			if (width < 0)
				width = 0;
			goto reswitch;

		case '#':
			altflag = 1;
  800552:	c7 45 e0 01 00 00 00 	movl   $0x1,-0x20(%ebp)
			goto reswitch;
  800559:	eb 92                	jmp    8004ed <vprintfmt+0x6d>
  80055b:	89 4d d4             	mov    %ecx,-0x2c(%ebp)

		process_precision:
			if (width < 0)
  80055e:	83 7d dc 00          	cmpl   $0x0,-0x24(%ebp)
  800562:	79 89                	jns    8004ed <vprintfmt+0x6d>
  800564:	e9 77 ff ff ff       	jmp    8004e0 <vprintfmt+0x60>
				width = precision, precision = -1;
			goto reswitch;

		// long flag (doubled for long long)
		case 'l':
			lflag++;
  800569:	83 c2 01             	add    $0x1,%edx
		width = -1;
		precision = -1;
		lflag = 0;
		altflag = 0;
	reswitch:
		switch (ch = *(unsigned char *) fmt++) {
  80056c:	89 fb                	mov    %edi,%ebx
			goto reswitch;

		// long flag (doubled for long long)
		case 'l':
			lflag++;
			goto reswitch;
  80056e:	e9 7a ff ff ff       	jmp    8004ed <vprintfmt+0x6d>

		// character
		case 'c':
			putch(va_arg(ap, int), putdat);
  800573:	8b 45 14             	mov    0x14(%ebp),%eax
  800576:	8d 50 04             	lea    0x4(%eax),%edx
  800579:	89 55 14             	mov    %edx,0x14(%ebp)
  80057c:	89 74 24 04          	mov    %esi,0x4(%esp)
  800580:	8b 00                	mov    (%eax),%eax
  800582:	89 04 24             	mov    %eax,(%esp)
  800585:	ff 55 08             	call   *0x8(%ebp)
			break;
  800588:	e9 18 ff ff ff       	jmp    8004a5 <vprintfmt+0x25>

		// error message
		case 'e':
			err = va_arg(ap, int);
  80058d:	8b 45 14             	mov    0x14(%ebp),%eax
  800590:	8d 50 04             	lea    0x4(%eax),%edx
  800593:	89 55 14             	mov    %edx,0x14(%ebp)
  800596:	8b 00                	mov    (%eax),%eax
  800598:	99                   	cltd   
  800599:	31 d0                	xor    %edx,%eax
  80059b:	29 d0                	sub    %edx,%eax
			if (err < 0)
				err = -err;
			if (err >= MAXERROR || (p = error_string[err]) == NULL)
  80059d:	83 f8 06             	cmp    $0x6,%eax
  8005a0:	7f 0b                	jg     8005ad <vprintfmt+0x12d>
  8005a2:	8b 14 85 e8 10 80 00 	mov    0x8010e8(,%eax,4),%edx
  8005a9:	85 d2                	test   %edx,%edx
  8005ab:	75 20                	jne    8005cd <vprintfmt+0x14d>
				printfmt(putch, putdat, "error %d", err);
  8005ad:	89 44 24 0c          	mov    %eax,0xc(%esp)
  8005b1:	c7 44 24 08 1a 0f 80 	movl   $0x800f1a,0x8(%esp)
  8005b8:	00 
  8005b9:	89 74 24 04          	mov    %esi,0x4(%esp)
  8005bd:	8b 45 08             	mov    0x8(%ebp),%eax
  8005c0:	89 04 24             	mov    %eax,(%esp)
  8005c3:	e8 90 fe ff ff       	call   800458 <printfmt>
  8005c8:	e9 d8 fe ff ff       	jmp    8004a5 <vprintfmt+0x25>
			else
				printfmt(putch, putdat, "%s", p);
  8005cd:	89 54 24 0c          	mov    %edx,0xc(%esp)
  8005d1:	c7 44 24 08 23 0f 80 	movl   $0x800f23,0x8(%esp)
  8005d8:	00 
  8005d9:	89 74 24 04          	mov    %esi,0x4(%esp)
  8005dd:	8b 45 08             	mov    0x8(%ebp),%eax
  8005e0:	89 04 24             	mov    %eax,(%esp)
  8005e3:	e8 70 fe ff ff       	call   800458 <printfmt>
  8005e8:	e9 b8 fe ff ff       	jmp    8004a5 <vprintfmt+0x25>
		width = -1;
		precision = -1;
		lflag = 0;
		altflag = 0;
	reswitch:
		switch (ch = *(unsigned char *) fmt++) {
  8005ed:	8b 4d d4             	mov    -0x2c(%ebp),%ecx
  8005f0:	8b 45 dc             	mov    -0x24(%ebp),%eax
  8005f3:	89 45 d0             	mov    %eax,-0x30(%ebp)
				printfmt(putch, putdat, "%s", p);
			break;

		// string
		case 's':
			if ((p = va_arg(ap, char *)) == NULL)
  8005f6:	8b 45 14             	mov    0x14(%ebp),%eax
  8005f9:	8d 50 04             	lea    0x4(%eax),%edx
  8005fc:	89 55 14             	mov    %edx,0x14(%ebp)
  8005ff:	8b 18                	mov    (%eax),%ebx
				p = "(null)";
  800601:	85 db                	test   %ebx,%ebx
  800603:	b8 13 0f 80 00       	mov    $0x800f13,%eax
  800608:	0f 44 d8             	cmove  %eax,%ebx
			if (width > 0 && padc != '-')
  80060b:	80 7d d8 2d          	cmpb   $0x2d,-0x28(%ebp)
  80060f:	0f 84 97 00 00 00    	je     8006ac <vprintfmt+0x22c>
  800615:	83 7d d0 00          	cmpl   $0x0,-0x30(%ebp)
  800619:	0f 8e 9b 00 00 00    	jle    8006ba <vprintfmt+0x23a>
				for (width -= strnlen(p, precision); width > 0; width--)
  80061f:	89 4c 24 04          	mov    %ecx,0x4(%esp)
  800623:	89 1c 24             	mov    %ebx,(%esp)
  800626:	e8 7d 02 00 00       	call   8008a8 <strnlen>
  80062b:	8b 55 d0             	mov    -0x30(%ebp),%edx
  80062e:	29 c2                	sub    %eax,%edx
  800630:	89 55 d0             	mov    %edx,-0x30(%ebp)
					putch(padc, putdat);
  800633:	0f be 45 d8          	movsbl -0x28(%ebp),%eax
  800637:	89 45 dc             	mov    %eax,-0x24(%ebp)
  80063a:	89 5d d8             	mov    %ebx,-0x28(%ebp)
  80063d:	89 d3                	mov    %edx,%ebx
  80063f:	89 7d 10             	mov    %edi,0x10(%ebp)
  800642:	8b 7d 08             	mov    0x8(%ebp),%edi
		// string
		case 's':
			if ((p = va_arg(ap, char *)) == NULL)
				p = "(null)";
			if (width > 0 && padc != '-')
				for (width -= strnlen(p, precision); width > 0; width--)
  800645:	eb 0f                	jmp    800656 <vprintfmt+0x1d6>
					putch(padc, putdat);
  800647:	89 74 24 04          	mov    %esi,0x4(%esp)
  80064b:	8b 45 dc             	mov    -0x24(%ebp),%eax
  80064e:	89 04 24             	mov    %eax,(%esp)
  800651:	ff d7                	call   *%edi
		// string
		case 's':
			if ((p = va_arg(ap, char *)) == NULL)
				p = "(null)";
			if (width > 0 && padc != '-')
				for (width -= strnlen(p, precision); width > 0; width--)
  800653:	83 eb 01             	sub    $0x1,%ebx
  800656:	85 db                	test   %ebx,%ebx
  800658:	7f ed                	jg     800647 <vprintfmt+0x1c7>
  80065a:	8b 5d d8             	mov    -0x28(%ebp),%ebx
  80065d:	8b 55 d0             	mov    -0x30(%ebp),%edx
  800660:	85 d2                	test   %edx,%edx
  800662:	b8 00 00 00 00       	mov    $0x0,%eax
  800667:	0f 49 c2             	cmovns %edx,%eax
  80066a:	29 c2                	sub    %eax,%edx
  80066c:	89 75 0c             	mov    %esi,0xc(%ebp)
  80066f:	89 d6                	mov    %edx,%esi
  800671:	8b 7d d4             	mov    -0x2c(%ebp),%edi
  800674:	eb 50                	jmp    8006c6 <vprintfmt+0x246>
					putch(padc, putdat);
			for (; (ch = *p++) != '\0' && (precision < 0 || --precision >= 0); width--)
				if (altflag && (ch < ' ' || ch > '~'))
  800676:	83 7d e0 00          	cmpl   $0x0,-0x20(%ebp)
  80067a:	74 1e                	je     80069a <vprintfmt+0x21a>
  80067c:	0f be d2             	movsbl %dl,%edx
  80067f:	83 ea 20             	sub    $0x20,%edx
  800682:	83 fa 5e             	cmp    $0x5e,%edx
  800685:	76 13                	jbe    80069a <vprintfmt+0x21a>
					putch('?', putdat);
  800687:	8b 45 0c             	mov    0xc(%ebp),%eax
  80068a:	89 44 24 04          	mov    %eax,0x4(%esp)
  80068e:	c7 04 24 3f 00 00 00 	movl   $0x3f,(%esp)
  800695:	ff 55 08             	call   *0x8(%ebp)
  800698:	eb 0d                	jmp    8006a7 <vprintfmt+0x227>
				else
					putch(ch, putdat);
  80069a:	8b 55 0c             	mov    0xc(%ebp),%edx
  80069d:	89 54 24 04          	mov    %edx,0x4(%esp)
  8006a1:	89 04 24             	mov    %eax,(%esp)
  8006a4:	ff 55 08             	call   *0x8(%ebp)
			if ((p = va_arg(ap, char *)) == NULL)
				p = "(null)";
			if (width > 0 && padc != '-')
				for (width -= strnlen(p, precision); width > 0; width--)
					putch(padc, putdat);
			for (; (ch = *p++) != '\0' && (precision < 0 || --precision >= 0); width--)
  8006a7:	83 ee 01             	sub    $0x1,%esi
  8006aa:	eb 1a                	jmp    8006c6 <vprintfmt+0x246>
  8006ac:	89 75 0c             	mov    %esi,0xc(%ebp)
  8006af:	8b 75 dc             	mov    -0x24(%ebp),%esi
  8006b2:	89 7d 10             	mov    %edi,0x10(%ebp)
  8006b5:	8b 7d d4             	mov    -0x2c(%ebp),%edi
  8006b8:	eb 0c                	jmp    8006c6 <vprintfmt+0x246>
  8006ba:	89 75 0c             	mov    %esi,0xc(%ebp)
  8006bd:	8b 75 dc             	mov    -0x24(%ebp),%esi
  8006c0:	89 7d 10             	mov    %edi,0x10(%ebp)
  8006c3:	8b 7d d4             	mov    -0x2c(%ebp),%edi
  8006c6:	83 c3 01             	add    $0x1,%ebx
  8006c9:	0f b6 53 ff          	movzbl -0x1(%ebx),%edx
  8006cd:	0f be c2             	movsbl %dl,%eax
  8006d0:	85 c0                	test   %eax,%eax
  8006d2:	74 25                	je     8006f9 <vprintfmt+0x279>
  8006d4:	85 ff                	test   %edi,%edi
  8006d6:	78 9e                	js     800676 <vprintfmt+0x1f6>
  8006d8:	83 ef 01             	sub    $0x1,%edi
  8006db:	79 99                	jns    800676 <vprintfmt+0x1f6>
  8006dd:	89 f3                	mov    %esi,%ebx
  8006df:	8b 75 0c             	mov    0xc(%ebp),%esi
  8006e2:	8b 7d 08             	mov    0x8(%ebp),%edi
  8006e5:	eb 1a                	jmp    800701 <vprintfmt+0x281>
				if (altflag && (ch < ' ' || ch > '~'))
					putch('?', putdat);
				else
					putch(ch, putdat);
			for (; width > 0; width--)
				putch(' ', putdat);
  8006e7:	89 74 24 04          	mov    %esi,0x4(%esp)
  8006eb:	c7 04 24 20 00 00 00 	movl   $0x20,(%esp)
  8006f2:	ff d7                	call   *%edi
			for (; (ch = *p++) != '\0' && (precision < 0 || --precision >= 0); width--)
				if (altflag && (ch < ' ' || ch > '~'))
					putch('?', putdat);
				else
					putch(ch, putdat);
			for (; width > 0; width--)
  8006f4:	83 eb 01             	sub    $0x1,%ebx
  8006f7:	eb 08                	jmp    800701 <vprintfmt+0x281>
  8006f9:	89 f3                	mov    %esi,%ebx
  8006fb:	8b 7d 08             	mov    0x8(%ebp),%edi
  8006fe:	8b 75 0c             	mov    0xc(%ebp),%esi
  800701:	85 db                	test   %ebx,%ebx
  800703:	7f e2                	jg     8006e7 <vprintfmt+0x267>
  800705:	89 7d 08             	mov    %edi,0x8(%ebp)
  800708:	8b 7d 10             	mov    0x10(%ebp),%edi
  80070b:	e9 95 fd ff ff       	jmp    8004a5 <vprintfmt+0x25>
				putch(' ', putdat);
			break;

		// (signed) decimal
		case 'd':
			num = getint(&ap, lflag);
  800710:	8d 45 14             	lea    0x14(%ebp),%eax
  800713:	e8 f1 fc ff ff       	call   800409 <getint>
  800718:	89 45 e0             	mov    %eax,-0x20(%ebp)
  80071b:	89 55 e4             	mov    %edx,-0x1c(%ebp)
			if ((long long) num < 0) {
				putch('-', putdat);
				num = -(long long) num;
			}
			base = 10;
  80071e:	bb 0a 00 00 00       	mov    $0xa,%ebx
			break;

		// (signed) decimal
		case 'd':
			num = getint(&ap, lflag);
			if ((long long) num < 0) {
  800723:	83 7d e4 00          	cmpl   $0x0,-0x1c(%ebp)
  800727:	79 7b                	jns    8007a4 <vprintfmt+0x324>
				putch('-', putdat);
  800729:	89 74 24 04          	mov    %esi,0x4(%esp)
  80072d:	c7 04 24 2d 00 00 00 	movl   $0x2d,(%esp)
  800734:	ff 55 08             	call   *0x8(%ebp)
				num = -(long long) num;
  800737:	8b 45 e0             	mov    -0x20(%ebp),%eax
  80073a:	8b 55 e4             	mov    -0x1c(%ebp),%edx
  80073d:	f7 d8                	neg    %eax
  80073f:	83 d2 00             	adc    $0x0,%edx
  800742:	f7 da                	neg    %edx
  800744:	eb 5e                	jmp    8007a4 <vprintfmt+0x324>
			base = 10;
			goto number;

		// unsigned decimal
		case 'u':
			num = getuint(&ap, lflag);
  800746:	8d 45 14             	lea    0x14(%ebp),%eax
  800749:	e8 81 fc ff ff       	call   8003cf <getuint>
			base = 10;
  80074e:	bb 0a 00 00 00       	mov    $0xa,%ebx
			goto number;
  800753:	eb 4f                	jmp    8007a4 <vprintfmt+0x324>

		// (unsigned) octal
		case 'o':
			num = getuint(&ap, lflag);
  800755:	8d 45 14             	lea    0x14(%ebp),%eax
  800758:	e8 72 fc ff ff       	call   8003cf <getuint>
			base = 8;
  80075d:	bb 08 00 00 00       	mov    $0x8,%ebx
			goto number;
  800762:	eb 40                	jmp    8007a4 <vprintfmt+0x324>

		// pointer
		case 'p':
			putch('0', putdat);
  800764:	89 74 24 04          	mov    %esi,0x4(%esp)
  800768:	c7 04 24 30 00 00 00 	movl   $0x30,(%esp)
  80076f:	ff 55 08             	call   *0x8(%ebp)
			putch('x', putdat);
  800772:	89 74 24 04          	mov    %esi,0x4(%esp)
  800776:	c7 04 24 78 00 00 00 	movl   $0x78,(%esp)
  80077d:	ff 55 08             	call   *0x8(%ebp)
			num = (unsigned long long)
				(uintptr_t) va_arg(ap, void *);
  800780:	8b 45 14             	mov    0x14(%ebp),%eax
  800783:	8d 50 04             	lea    0x4(%eax),%edx
  800786:	89 55 14             	mov    %edx,0x14(%ebp)

		// pointer
		case 'p':
			putch('0', putdat);
			putch('x', putdat);
			num = (unsigned long long)
  800789:	8b 00                	mov    (%eax),%eax
  80078b:	ba 00 00 00 00       	mov    $0x0,%edx
				(uintptr_t) va_arg(ap, void *);
			base = 16;
  800790:	bb 10 00 00 00       	mov    $0x10,%ebx
			goto number;
  800795:	eb 0d                	jmp    8007a4 <vprintfmt+0x324>

		// (unsigned) hexadecimal
		case 'x':
			num = getuint(&ap, lflag);
  800797:	8d 45 14             	lea    0x14(%ebp),%eax
  80079a:	e8 30 fc ff ff       	call   8003cf <getuint>
			base = 16;
  80079f:	bb 10 00 00 00       	mov    $0x10,%ebx
		number:
			printnum(putch, putdat, num, base, width, padc);
  8007a4:	0f be 4d d8          	movsbl -0x28(%ebp),%ecx
  8007a8:	89 4c 24 10          	mov    %ecx,0x10(%esp)
  8007ac:	8b 4d dc             	mov    -0x24(%ebp),%ecx
  8007af:	89 4c 24 0c          	mov    %ecx,0xc(%esp)
  8007b3:	89 5c 24 08          	mov    %ebx,0x8(%esp)
  8007b7:	89 04 24             	mov    %eax,(%esp)
  8007ba:	89 54 24 04          	mov    %edx,0x4(%esp)
  8007be:	89 f2                	mov    %esi,%edx
  8007c0:	8b 45 08             	mov    0x8(%ebp),%eax
  8007c3:	e8 18 fb ff ff       	call   8002e0 <printnum>
			break;
  8007c8:	e9 d8 fc ff ff       	jmp    8004a5 <vprintfmt+0x25>

		// escaped '%' character
		case '%':
			putch(ch, putdat);
  8007cd:	89 74 24 04          	mov    %esi,0x4(%esp)
  8007d1:	89 04 24             	mov    %eax,(%esp)
  8007d4:	ff 55 08             	call   *0x8(%ebp)
			break;
  8007d7:	e9 c9 fc ff ff       	jmp    8004a5 <vprintfmt+0x25>

		// unrecognized escape sequence - just print it literally
		default:
			putch('%', putdat);
  8007dc:	89 74 24 04          	mov    %esi,0x4(%esp)
  8007e0:	c7 04 24 25 00 00 00 	movl   $0x25,(%esp)
  8007e7:	ff 55 08             	call   *0x8(%ebp)
			for (fmt--; fmt[-1] != '%'; fmt--)
  8007ea:	89 df                	mov    %ebx,%edi
  8007ec:	eb 03                	jmp    8007f1 <vprintfmt+0x371>
  8007ee:	83 ef 01             	sub    $0x1,%edi
  8007f1:	80 7f ff 25          	cmpb   $0x25,-0x1(%edi)
  8007f5:	75 f7                	jne    8007ee <vprintfmt+0x36e>
  8007f7:	e9 a9 fc ff ff       	jmp    8004a5 <vprintfmt+0x25>
				/* do nothing */;
			break;
		}
	}
}
  8007fc:	83 c4 3c             	add    $0x3c,%esp
  8007ff:	5b                   	pop    %ebx
  800800:	5e                   	pop    %esi
  800801:	5f                   	pop    %edi
  800802:	5d                   	pop    %ebp
  800803:	c3                   	ret    

00800804 <vsnprintf>:
		*b->buf++ = ch;
}

int
vsnprintf(char *buf, int n, const char *fmt, va_list ap)
{
  800804:	55                   	push   %ebp
  800805:	89 e5                	mov    %esp,%ebp
  800807:	83 ec 28             	sub    $0x28,%esp
  80080a:	8b 45 08             	mov    0x8(%ebp),%eax
  80080d:	8b 55 0c             	mov    0xc(%ebp),%edx
	struct sprintbuf b = {buf, buf+n-1, 0};
  800810:	89 45 ec             	mov    %eax,-0x14(%ebp)
  800813:	8d 4c 10 ff          	lea    -0x1(%eax,%edx,1),%ecx
  800817:	89 4d f0             	mov    %ecx,-0x10(%ebp)
  80081a:	c7 45 f4 00 00 00 00 	movl   $0x0,-0xc(%ebp)

	if (buf == NULL || n < 1)
  800821:	85 c0                	test   %eax,%eax
  800823:	74 30                	je     800855 <vsnprintf+0x51>
  800825:	85 d2                	test   %edx,%edx
  800827:	7e 2c                	jle    800855 <vsnprintf+0x51>
		return -E_INVAL;

	// print the string to the buffer
	vprintfmt((void*)sprintputch, &b, fmt, ap);
  800829:	8b 45 14             	mov    0x14(%ebp),%eax
  80082c:	89 44 24 0c          	mov    %eax,0xc(%esp)
  800830:	8b 45 10             	mov    0x10(%ebp),%eax
  800833:	89 44 24 08          	mov    %eax,0x8(%esp)
  800837:	8d 45 ec             	lea    -0x14(%ebp),%eax
  80083a:	89 44 24 04          	mov    %eax,0x4(%esp)
  80083e:	c7 04 24 3b 04 80 00 	movl   $0x80043b,(%esp)
  800845:	e8 36 fc ff ff       	call   800480 <vprintfmt>

	// null terminate the buffer
	*b.buf = '\0';
  80084a:	8b 45 ec             	mov    -0x14(%ebp),%eax
  80084d:	c6 00 00             	movb   $0x0,(%eax)

	return b.cnt;
  800850:	8b 45 f4             	mov    -0xc(%ebp),%eax
  800853:	eb 05                	jmp    80085a <vsnprintf+0x56>
vsnprintf(char *buf, int n, const char *fmt, va_list ap)
{
	struct sprintbuf b = {buf, buf+n-1, 0};

	if (buf == NULL || n < 1)
		return -E_INVAL;
  800855:	b8 fd ff ff ff       	mov    $0xfffffffd,%eax

	// null terminate the buffer
	*b.buf = '\0';

	return b.cnt;
}
  80085a:	c9                   	leave  
  80085b:	c3                   	ret    

0080085c <snprintf>:

int
snprintf(char *buf, int n, const char *fmt, ...)
{
  80085c:	55                   	push   %ebp
  80085d:	89 e5                	mov    %esp,%ebp
  80085f:	83 ec 18             	sub    $0x18,%esp
	va_list ap;
	int rc;

	va_start(ap, fmt);
  800862:	8d 45 14             	lea    0x14(%ebp),%eax
	rc = vsnprintf(buf, n, fmt, ap);
  800865:	89 44 24 0c          	mov    %eax,0xc(%esp)
  800869:	8b 45 10             	mov    0x10(%ebp),%eax
  80086c:	89 44 24 08          	mov    %eax,0x8(%esp)
  800870:	8b 45 0c             	mov    0xc(%ebp),%eax
  800873:	89 44 24 04          	mov    %eax,0x4(%esp)
  800877:	8b 45 08             	mov    0x8(%ebp),%eax
  80087a:	89 04 24             	mov    %eax,(%esp)
  80087d:	e8 82 ff ff ff       	call   800804 <vsnprintf>
	va_end(ap);

	return rc;
}
  800882:	c9                   	leave  
  800883:	c3                   	ret    
  800884:	66 90                	xchg   %ax,%ax
  800886:	66 90                	xchg   %ax,%ax
  800888:	66 90                	xchg   %ax,%ax
  80088a:	66 90                	xchg   %ax,%ax
  80088c:	66 90                	xchg   %ax,%ax
  80088e:	66 90                	xchg   %ax,%ax

00800890 <strlen>:
// Primespipe runs 3x faster this way.
#define ASM 1

int
strlen(const char *s)
{
  800890:	55                   	push   %ebp
  800891:	89 e5                	mov    %esp,%ebp
  800893:	8b 55 08             	mov    0x8(%ebp),%edx
	int n;

	for (n = 0; *s != '\0'; s++)
  800896:	b8 00 00 00 00       	mov    $0x0,%eax
  80089b:	eb 03                	jmp    8008a0 <strlen+0x10>
		n++;
  80089d:	83 c0 01             	add    $0x1,%eax
int
strlen(const char *s)
{
	int n;

	for (n = 0; *s != '\0'; s++)
  8008a0:	80 3c 02 00          	cmpb   $0x0,(%edx,%eax,1)
  8008a4:	75 f7                	jne    80089d <strlen+0xd>
		n++;
	return n;
}
  8008a6:	5d                   	pop    %ebp
  8008a7:	c3                   	ret    

008008a8 <strnlen>:

int
strnlen(const char *s, size_t size)
{
  8008a8:	55                   	push   %ebp
  8008a9:	89 e5                	mov    %esp,%ebp
  8008ab:	8b 4d 08             	mov    0x8(%ebp),%ecx
  8008ae:	8b 55 0c             	mov    0xc(%ebp),%edx
	int n;

	for (n = 0; size > 0 && *s != '\0'; s++, size--)
  8008b1:	b8 00 00 00 00       	mov    $0x0,%eax
  8008b6:	eb 03                	jmp    8008bb <strnlen+0x13>
		n++;
  8008b8:	83 c0 01             	add    $0x1,%eax
int
strnlen(const char *s, size_t size)
{
	int n;

	for (n = 0; size > 0 && *s != '\0'; s++, size--)
  8008bb:	39 d0                	cmp    %edx,%eax
  8008bd:	74 06                	je     8008c5 <strnlen+0x1d>
  8008bf:	80 3c 01 00          	cmpb   $0x0,(%ecx,%eax,1)
  8008c3:	75 f3                	jne    8008b8 <strnlen+0x10>
		n++;
	return n;
}
  8008c5:	5d                   	pop    %ebp
  8008c6:	c3                   	ret    

008008c7 <strcpy>:

char *
strcpy(char *dst, const char *src)
{
  8008c7:	55                   	push   %ebp
  8008c8:	89 e5                	mov    %esp,%ebp
  8008ca:	53                   	push   %ebx
  8008cb:	8b 45 08             	mov    0x8(%ebp),%eax
  8008ce:	8b 4d 0c             	mov    0xc(%ebp),%ecx
	char *ret;

	ret = dst;
	while ((*dst++ = *src++) != '\0')
  8008d1:	89 c2                	mov    %eax,%edx
  8008d3:	83 c2 01             	add    $0x1,%edx
  8008d6:	83 c1 01             	add    $0x1,%ecx
  8008d9:	0f b6 59 ff          	movzbl -0x1(%ecx),%ebx
  8008dd:	88 5a ff             	mov    %bl,-0x1(%edx)
  8008e0:	84 db                	test   %bl,%bl
  8008e2:	75 ef                	jne    8008d3 <strcpy+0xc>
		/* do nothing */;
	return ret;
}
  8008e4:	5b                   	pop    %ebx
  8008e5:	5d                   	pop    %ebp
  8008e6:	c3                   	ret    

008008e7 <strcat>:

char *
strcat(char *dst, const char *src)
{
  8008e7:	55                   	push   %ebp
  8008e8:	89 e5                	mov    %esp,%ebp
  8008ea:	53                   	push   %ebx
  8008eb:	83 ec 08             	sub    $0x8,%esp
  8008ee:	8b 5d 08             	mov    0x8(%ebp),%ebx
	int len = strlen(dst);
  8008f1:	89 1c 24             	mov    %ebx,(%esp)
  8008f4:	e8 97 ff ff ff       	call   800890 <strlen>
	strcpy(dst + len, src);
  8008f9:	8b 55 0c             	mov    0xc(%ebp),%edx
  8008fc:	89 54 24 04          	mov    %edx,0x4(%esp)
  800900:	01 d8                	add    %ebx,%eax
  800902:	89 04 24             	mov    %eax,(%esp)
  800905:	e8 bd ff ff ff       	call   8008c7 <strcpy>
	return dst;
}
  80090a:	89 d8                	mov    %ebx,%eax
  80090c:	83 c4 08             	add    $0x8,%esp
  80090f:	5b                   	pop    %ebx
  800910:	5d                   	pop    %ebp
  800911:	c3                   	ret    

00800912 <strncpy>:

char *
strncpy(char *dst, const char *src, size_t size) {
  800912:	55                   	push   %ebp
  800913:	89 e5                	mov    %esp,%ebp
  800915:	56                   	push   %esi
  800916:	53                   	push   %ebx
  800917:	8b 75 08             	mov    0x8(%ebp),%esi
  80091a:	8b 4d 0c             	mov    0xc(%ebp),%ecx
  80091d:	89 f3                	mov    %esi,%ebx
  80091f:	03 5d 10             	add    0x10(%ebp),%ebx
	size_t i;
	char *ret;

	ret = dst;
	for (i = 0; i < size; i++) {
  800922:	89 f2                	mov    %esi,%edx
  800924:	eb 0f                	jmp    800935 <strncpy+0x23>
		*dst++ = *src;
  800926:	83 c2 01             	add    $0x1,%edx
  800929:	0f b6 01             	movzbl (%ecx),%eax
  80092c:	88 42 ff             	mov    %al,-0x1(%edx)
		// If strlen(src) < size, null-pad 'dst' out to 'size' chars
		if (*src != '\0')
			src++;
  80092f:	80 39 01             	cmpb   $0x1,(%ecx)
  800932:	83 d9 ff             	sbb    $0xffffffff,%ecx
strncpy(char *dst, const char *src, size_t size) {
	size_t i;
	char *ret;

	ret = dst;
	for (i = 0; i < size; i++) {
  800935:	39 da                	cmp    %ebx,%edx
  800937:	75 ed                	jne    800926 <strncpy+0x14>
		// If strlen(src) < size, null-pad 'dst' out to 'size' chars
		if (*src != '\0')
			src++;
	}
	return ret;
}
  800939:	89 f0                	mov    %esi,%eax
  80093b:	5b                   	pop    %ebx
  80093c:	5e                   	pop    %esi
  80093d:	5d                   	pop    %ebp
  80093e:	c3                   	ret    

0080093f <strlcpy>:

size_t
strlcpy(char *dst, const char *src, size_t size)
{
  80093f:	55                   	push   %ebp
  800940:	89 e5                	mov    %esp,%ebp
  800942:	56                   	push   %esi
  800943:	53                   	push   %ebx
  800944:	8b 75 08             	mov    0x8(%ebp),%esi
  800947:	8b 55 0c             	mov    0xc(%ebp),%edx
  80094a:	8b 4d 10             	mov    0x10(%ebp),%ecx
  80094d:	89 f0                	mov    %esi,%eax
  80094f:	8d 5c 0e ff          	lea    -0x1(%esi,%ecx,1),%ebx
	char *dst_in;

	dst_in = dst;
	if (size > 0) {
  800953:	85 c9                	test   %ecx,%ecx
  800955:	75 0b                	jne    800962 <strlcpy+0x23>
  800957:	eb 1d                	jmp    800976 <strlcpy+0x37>
		while (--size > 0 && *src != '\0')
			*dst++ = *src++;
  800959:	83 c0 01             	add    $0x1,%eax
  80095c:	83 c2 01             	add    $0x1,%edx
  80095f:	88 48 ff             	mov    %cl,-0x1(%eax)
{
	char *dst_in;

	dst_in = dst;
	if (size > 0) {
		while (--size > 0 && *src != '\0')
  800962:	39 d8                	cmp    %ebx,%eax
  800964:	74 0b                	je     800971 <strlcpy+0x32>
  800966:	0f b6 0a             	movzbl (%edx),%ecx
  800969:	84 c9                	test   %cl,%cl
  80096b:	75 ec                	jne    800959 <strlcpy+0x1a>
  80096d:	89 c2                	mov    %eax,%edx
  80096f:	eb 02                	jmp    800973 <strlcpy+0x34>
  800971:	89 c2                	mov    %eax,%edx
			*dst++ = *src++;
		*dst = '\0';
  800973:	c6 02 00             	movb   $0x0,(%edx)
	}
	return dst - dst_in;
  800976:	29 f0                	sub    %esi,%eax
}
  800978:	5b                   	pop    %ebx
  800979:	5e                   	pop    %esi
  80097a:	5d                   	pop    %ebp
  80097b:	c3                   	ret    

0080097c <strcmp>:

int
strcmp(const char *p, const char *q)
{
  80097c:	55                   	push   %ebp
  80097d:	89 e5                	mov    %esp,%ebp
  80097f:	8b 4d 08             	mov    0x8(%ebp),%ecx
  800982:	8b 55 0c             	mov    0xc(%ebp),%edx
	while (*p && *p == *q)
  800985:	eb 06                	jmp    80098d <strcmp+0x11>
		p++, q++;
  800987:	83 c1 01             	add    $0x1,%ecx
  80098a:	83 c2 01             	add    $0x1,%edx
}

int
strcmp(const char *p, const char *q)
{
	while (*p && *p == *q)
  80098d:	0f b6 01             	movzbl (%ecx),%eax
  800990:	84 c0                	test   %al,%al
  800992:	74 04                	je     800998 <strcmp+0x1c>
  800994:	3a 02                	cmp    (%edx),%al
  800996:	74 ef                	je     800987 <strcmp+0xb>
		p++, q++;
	return (int) ((unsigned char) *p - (unsigned char) *q);
  800998:	0f b6 c0             	movzbl %al,%eax
  80099b:	0f b6 12             	movzbl (%edx),%edx
  80099e:	29 d0                	sub    %edx,%eax
}
  8009a0:	5d                   	pop    %ebp
  8009a1:	c3                   	ret    

008009a2 <strncmp>:

int
strncmp(const char *p, const char *q, size_t n)
{
  8009a2:	55                   	push   %ebp
  8009a3:	89 e5                	mov    %esp,%ebp
  8009a5:	53                   	push   %ebx
  8009a6:	8b 45 08             	mov    0x8(%ebp),%eax
  8009a9:	8b 55 0c             	mov    0xc(%ebp),%edx
  8009ac:	89 c3                	mov    %eax,%ebx
  8009ae:	03 5d 10             	add    0x10(%ebp),%ebx
	while (n > 0 && *p && *p == *q)
  8009b1:	eb 06                	jmp    8009b9 <strncmp+0x17>
		n--, p++, q++;
  8009b3:	83 c0 01             	add    $0x1,%eax
  8009b6:	83 c2 01             	add    $0x1,%edx
}

int
strncmp(const char *p, const char *q, size_t n)
{
	while (n > 0 && *p && *p == *q)
  8009b9:	39 d8                	cmp    %ebx,%eax
  8009bb:	74 15                	je     8009d2 <strncmp+0x30>
  8009bd:	0f b6 08             	movzbl (%eax),%ecx
  8009c0:	84 c9                	test   %cl,%cl
  8009c2:	74 04                	je     8009c8 <strncmp+0x26>
  8009c4:	3a 0a                	cmp    (%edx),%cl
  8009c6:	74 eb                	je     8009b3 <strncmp+0x11>
		n--, p++, q++;
	if (n == 0)
		return 0;
	else
		return (int) ((unsigned char) *p - (unsigned char) *q);
  8009c8:	0f b6 00             	movzbl (%eax),%eax
  8009cb:	0f b6 12             	movzbl (%edx),%edx
  8009ce:	29 d0                	sub    %edx,%eax
  8009d0:	eb 05                	jmp    8009d7 <strncmp+0x35>
strncmp(const char *p, const char *q, size_t n)
{
	while (n > 0 && *p && *p == *q)
		n--, p++, q++;
	if (n == 0)
		return 0;
  8009d2:	b8 00 00 00 00       	mov    $0x0,%eax
	else
		return (int) ((unsigned char) *p - (unsigned char) *q);
}
  8009d7:	5b                   	pop    %ebx
  8009d8:	5d                   	pop    %ebp
  8009d9:	c3                   	ret    

008009da <strchr>:

// Return a pointer to the first occurrence of 'c' in 's',
// or a null pointer if the string has no 'c'.
char *
strchr(const char *s, char c)
{
  8009da:	55                   	push   %ebp
  8009db:	89 e5                	mov    %esp,%ebp
  8009dd:	8b 45 08             	mov    0x8(%ebp),%eax
  8009e0:	0f b6 4d 0c          	movzbl 0xc(%ebp),%ecx
	for (; *s; s++)
  8009e4:	eb 07                	jmp    8009ed <strchr+0x13>
		if (*s == c)
  8009e6:	38 ca                	cmp    %cl,%dl
  8009e8:	74 0f                	je     8009f9 <strchr+0x1f>
// Return a pointer to the first occurrence of 'c' in 's',
// or a null pointer if the string has no 'c'.
char *
strchr(const char *s, char c)
{
	for (; *s; s++)
  8009ea:	83 c0 01             	add    $0x1,%eax
  8009ed:	0f b6 10             	movzbl (%eax),%edx
  8009f0:	84 d2                	test   %dl,%dl
  8009f2:	75 f2                	jne    8009e6 <strchr+0xc>
		if (*s == c)
			return (char *) s;
	return 0;
  8009f4:	b8 00 00 00 00       	mov    $0x0,%eax
}
  8009f9:	5d                   	pop    %ebp
  8009fa:	c3                   	ret    

008009fb <strfind>:

// Return a pointer to the first occurrence of 'c' in 's',
// or a pointer to the string-ending null character if the string has no 'c'.
char *
strfind(const char *s, char c)
{
  8009fb:	55                   	push   %ebp
  8009fc:	89 e5                	mov    %esp,%ebp
  8009fe:	8b 45 08             	mov    0x8(%ebp),%eax
  800a01:	0f b6 4d 0c          	movzbl 0xc(%ebp),%ecx
	for (; *s; s++)
  800a05:	eb 07                	jmp    800a0e <strfind+0x13>
		if (*s == c)
  800a07:	38 ca                	cmp    %cl,%dl
  800a09:	74 0a                	je     800a15 <strfind+0x1a>
// Return a pointer to the first occurrence of 'c' in 's',
// or a pointer to the string-ending null character if the string has no 'c'.
char *
strfind(const char *s, char c)
{
	for (; *s; s++)
  800a0b:	83 c0 01             	add    $0x1,%eax
  800a0e:	0f b6 10             	movzbl (%eax),%edx
  800a11:	84 d2                	test   %dl,%dl
  800a13:	75 f2                	jne    800a07 <strfind+0xc>
		if (*s == c)
			break;
	return (char *) s;
}
  800a15:	5d                   	pop    %ebp
  800a16:	c3                   	ret    

00800a17 <memset>:

#if ASM
void *
memset(void *v, int c, size_t n)
{
  800a17:	55                   	push   %ebp
  800a18:	89 e5                	mov    %esp,%ebp
  800a1a:	57                   	push   %edi
  800a1b:	56                   	push   %esi
  800a1c:	53                   	push   %ebx
  800a1d:	8b 55 08             	mov    0x8(%ebp),%edx
  800a20:	8b 4d 10             	mov    0x10(%ebp),%ecx
	char *p = v;

	if (n == 0)
  800a23:	85 c9                	test   %ecx,%ecx
  800a25:	74 37                	je     800a5e <memset+0x47>
		return v;
	if ((int)v%4 == 0 && n%4 == 0) {
  800a27:	f6 c2 03             	test   $0x3,%dl
  800a2a:	75 2a                	jne    800a56 <memset+0x3f>
  800a2c:	f6 c1 03             	test   $0x3,%cl
  800a2f:	75 25                	jne    800a56 <memset+0x3f>
		c &= 0xFF;
  800a31:	0f b6 7d 0c          	movzbl 0xc(%ebp),%edi
		c = (c<<24)|(c<<16)|(c<<8)|c;
  800a35:	89 fb                	mov    %edi,%ebx
  800a37:	c1 e3 08             	shl    $0x8,%ebx
  800a3a:	89 fe                	mov    %edi,%esi
  800a3c:	c1 e6 18             	shl    $0x18,%esi
  800a3f:	89 f8                	mov    %edi,%eax
  800a41:	c1 e0 10             	shl    $0x10,%eax
  800a44:	09 f0                	or     %esi,%eax
  800a46:	09 c7                	or     %eax,%edi
		asm volatile("cld; rep stosl\n"
			: "=D" (p), "=c" (n)
			: "D" (p), "a" (c), "c" (n/4)
  800a48:	c1 e9 02             	shr    $0x2,%ecx

	if (n == 0)
		return v;
	if ((int)v%4 == 0 && n%4 == 0) {
		c &= 0xFF;
		c = (c<<24)|(c<<16)|(c<<8)|c;
  800a4b:	89 f8                	mov    %edi,%eax
  800a4d:	09 d8                	or     %ebx,%eax
		asm volatile("cld; rep stosl\n"
  800a4f:	89 d7                	mov    %edx,%edi
  800a51:	fc                   	cld    
  800a52:	f3 ab                	rep stos %eax,%es:(%edi)
  800a54:	eb 08                	jmp    800a5e <memset+0x47>
			: "=D" (p), "=c" (n)
			: "D" (p), "a" (c), "c" (n/4)
			: "cc", "memory");
	} else
		asm volatile("cld; rep stosb\n"
  800a56:	89 d7                	mov    %edx,%edi
  800a58:	8b 45 0c             	mov    0xc(%ebp),%eax
  800a5b:	fc                   	cld    
  800a5c:	f3 aa                	rep stos %al,%es:(%edi)
			: "=D" (p), "=c" (n)
			: "0" (p), "a" (c), "1" (n)
			: "cc", "memory");
	return v;
}
  800a5e:	89 d0                	mov    %edx,%eax
  800a60:	5b                   	pop    %ebx
  800a61:	5e                   	pop    %esi
  800a62:	5f                   	pop    %edi
  800a63:	5d                   	pop    %ebp
  800a64:	c3                   	ret    

00800a65 <memmove>:

void *
memmove(void *dst, const void *src, size_t n)
{
  800a65:	55                   	push   %ebp
  800a66:	89 e5                	mov    %esp,%ebp
  800a68:	57                   	push   %edi
  800a69:	56                   	push   %esi
  800a6a:	8b 45 08             	mov    0x8(%ebp),%eax
  800a6d:	8b 75 0c             	mov    0xc(%ebp),%esi
  800a70:	8b 4d 10             	mov    0x10(%ebp),%ecx
	const char *s;
	char *d;

	s = src;
	d = dst;
	if (s < d && s + n > d) {
  800a73:	39 c6                	cmp    %eax,%esi
  800a75:	73 35                	jae    800aac <memmove+0x47>
  800a77:	8d 14 0e             	lea    (%esi,%ecx,1),%edx
  800a7a:	39 d0                	cmp    %edx,%eax
  800a7c:	73 2e                	jae    800aac <memmove+0x47>
		s += n;
		d += n;
  800a7e:	8d 3c 08             	lea    (%eax,%ecx,1),%edi
  800a81:	89 d6                	mov    %edx,%esi
  800a83:	09 fe                	or     %edi,%esi
		if ((int)s%4 == 0 && (int)d%4 == 0 && n%4 == 0)
  800a85:	f7 c6 03 00 00 00    	test   $0x3,%esi
  800a8b:	75 13                	jne    800aa0 <memmove+0x3b>
  800a8d:	f6 c1 03             	test   $0x3,%cl
  800a90:	75 0e                	jne    800aa0 <memmove+0x3b>
			asm volatile("std; rep movsl\n"
				:: "D" (d-4), "S" (s-4), "c" (n/4) : "cc", "memory");
  800a92:	83 ef 04             	sub    $0x4,%edi
  800a95:	8d 72 fc             	lea    -0x4(%edx),%esi
  800a98:	c1 e9 02             	shr    $0x2,%ecx
	d = dst;
	if (s < d && s + n > d) {
		s += n;
		d += n;
		if ((int)s%4 == 0 && (int)d%4 == 0 && n%4 == 0)
			asm volatile("std; rep movsl\n"
  800a9b:	fd                   	std    
  800a9c:	f3 a5                	rep movsl %ds:(%esi),%es:(%edi)
  800a9e:	eb 09                	jmp    800aa9 <memmove+0x44>
				:: "D" (d-4), "S" (s-4), "c" (n/4) : "cc", "memory");
		else
			asm volatile("std; rep movsb\n"
				:: "D" (d-1), "S" (s-1), "c" (n) : "cc", "memory");
  800aa0:	83 ef 01             	sub    $0x1,%edi
  800aa3:	8d 72 ff             	lea    -0x1(%edx),%esi
		d += n;
		if ((int)s%4 == 0 && (int)d%4 == 0 && n%4 == 0)
			asm volatile("std; rep movsl\n"
				:: "D" (d-4), "S" (s-4), "c" (n/4) : "cc", "memory");
		else
			asm volatile("std; rep movsb\n"
  800aa6:	fd                   	std    
  800aa7:	f3 a4                	rep movsb %ds:(%esi),%es:(%edi)
				:: "D" (d-1), "S" (s-1), "c" (n) : "cc", "memory");
		// Some versions of GCC rely on DF being clear
		asm volatile("cld" ::: "cc");
  800aa9:	fc                   	cld    
  800aaa:	eb 1d                	jmp    800ac9 <memmove+0x64>
  800aac:	89 f2                	mov    %esi,%edx
  800aae:	09 c2                	or     %eax,%edx
	} else {
		if ((int)s%4 == 0 && (int)d%4 == 0 && n%4 == 0)
  800ab0:	f6 c2 03             	test   $0x3,%dl
  800ab3:	75 0f                	jne    800ac4 <memmove+0x5f>
  800ab5:	f6 c1 03             	test   $0x3,%cl
  800ab8:	75 0a                	jne    800ac4 <memmove+0x5f>
			asm volatile("cld; rep movsl\n"
				:: "D" (d), "S" (s), "c" (n/4) : "cc", "memory");
  800aba:	c1 e9 02             	shr    $0x2,%ecx
				:: "D" (d-1), "S" (s-1), "c" (n) : "cc", "memory");
		// Some versions of GCC rely on DF being clear
		asm volatile("cld" ::: "cc");
	} else {
		if ((int)s%4 == 0 && (int)d%4 == 0 && n%4 == 0)
			asm volatile("cld; rep movsl\n"
  800abd:	89 c7                	mov    %eax,%edi
  800abf:	fc                   	cld    
  800ac0:	f3 a5                	rep movsl %ds:(%esi),%es:(%edi)
  800ac2:	eb 05                	jmp    800ac9 <memmove+0x64>
				:: "D" (d), "S" (s), "c" (n/4) : "cc", "memory");
		else
			asm volatile("cld; rep movsb\n"
  800ac4:	89 c7                	mov    %eax,%edi
  800ac6:	fc                   	cld    
  800ac7:	f3 a4                	rep movsb %ds:(%esi),%es:(%edi)
				:: "D" (d), "S" (s), "c" (n) : "cc", "memory");
	}
	return dst;
}
  800ac9:	5e                   	pop    %esi
  800aca:	5f                   	pop    %edi
  800acb:	5d                   	pop    %ebp
  800acc:	c3                   	ret    

00800acd <memcpy>:
}
#endif

void *
memcpy(void *dst, const void *src, size_t n)
{
  800acd:	55                   	push   %ebp
  800ace:	89 e5                	mov    %esp,%ebp
  800ad0:	83 ec 0c             	sub    $0xc,%esp
	return memmove(dst, src, n);
  800ad3:	8b 45 10             	mov    0x10(%ebp),%eax
  800ad6:	89 44 24 08          	mov    %eax,0x8(%esp)
  800ada:	8b 45 0c             	mov    0xc(%ebp),%eax
  800add:	89 44 24 04          	mov    %eax,0x4(%esp)
  800ae1:	8b 45 08             	mov    0x8(%ebp),%eax
  800ae4:	89 04 24             	mov    %eax,(%esp)
  800ae7:	e8 79 ff ff ff       	call   800a65 <memmove>
}
  800aec:	c9                   	leave  
  800aed:	c3                   	ret    

00800aee <memcmp>:

int
memcmp(const void *v1, const void *v2, size_t n)
{
  800aee:	55                   	push   %ebp
  800aef:	89 e5                	mov    %esp,%ebp
  800af1:	56                   	push   %esi
  800af2:	53                   	push   %ebx
  800af3:	8b 55 08             	mov    0x8(%ebp),%edx
  800af6:	8b 4d 0c             	mov    0xc(%ebp),%ecx
  800af9:	89 d6                	mov    %edx,%esi
  800afb:	03 75 10             	add    0x10(%ebp),%esi
	const uint8_t *s1 = (const uint8_t *) v1;
	const uint8_t *s2 = (const uint8_t *) v2;

	while (n-- > 0) {
  800afe:	eb 1a                	jmp    800b1a <memcmp+0x2c>
		if (*s1 != *s2)
  800b00:	0f b6 02             	movzbl (%edx),%eax
  800b03:	0f b6 19             	movzbl (%ecx),%ebx
  800b06:	38 d8                	cmp    %bl,%al
  800b08:	74 0a                	je     800b14 <memcmp+0x26>
			return (int) *s1 - (int) *s2;
  800b0a:	0f b6 c0             	movzbl %al,%eax
  800b0d:	0f b6 db             	movzbl %bl,%ebx
  800b10:	29 d8                	sub    %ebx,%eax
  800b12:	eb 0f                	jmp    800b23 <memcmp+0x35>
		s1++, s2++;
  800b14:	83 c2 01             	add    $0x1,%edx
  800b17:	83 c1 01             	add    $0x1,%ecx
memcmp(const void *v1, const void *v2, size_t n)
{
	const uint8_t *s1 = (const uint8_t *) v1;
	const uint8_t *s2 = (const uint8_t *) v2;

	while (n-- > 0) {
  800b1a:	39 f2                	cmp    %esi,%edx
  800b1c:	75 e2                	jne    800b00 <memcmp+0x12>
		if (*s1 != *s2)
			return (int) *s1 - (int) *s2;
		s1++, s2++;
	}

	return 0;
  800b1e:	b8 00 00 00 00       	mov    $0x0,%eax
}
  800b23:	5b                   	pop    %ebx
  800b24:	5e                   	pop    %esi
  800b25:	5d                   	pop    %ebp
  800b26:	c3                   	ret    

00800b27 <memfind>:

void *
memfind(const void *s, int c, size_t n)
{
  800b27:	55                   	push   %ebp
  800b28:	89 e5                	mov    %esp,%ebp
  800b2a:	8b 45 08             	mov    0x8(%ebp),%eax
  800b2d:	8b 4d 0c             	mov    0xc(%ebp),%ecx
	const void *ends = (const char *) s + n;
  800b30:	89 c2                	mov    %eax,%edx
  800b32:	03 55 10             	add    0x10(%ebp),%edx
	for (; s < ends; s++)
  800b35:	eb 07                	jmp    800b3e <memfind+0x17>
		if (*(const unsigned char *) s == (unsigned char) c)
  800b37:	38 08                	cmp    %cl,(%eax)
  800b39:	74 07                	je     800b42 <memfind+0x1b>

void *
memfind(const void *s, int c, size_t n)
{
	const void *ends = (const char *) s + n;
	for (; s < ends; s++)
  800b3b:	83 c0 01             	add    $0x1,%eax
  800b3e:	39 d0                	cmp    %edx,%eax
  800b40:	72 f5                	jb     800b37 <memfind+0x10>
		if (*(const unsigned char *) s == (unsigned char) c)
			break;
	return (void *) s;
}
  800b42:	5d                   	pop    %ebp
  800b43:	c3                   	ret    

00800b44 <strtol>:

long
strtol(const char *s, char **endptr, int base)
{
  800b44:	55                   	push   %ebp
  800b45:	89 e5                	mov    %esp,%ebp
  800b47:	57                   	push   %edi
  800b48:	56                   	push   %esi
  800b49:	53                   	push   %ebx
  800b4a:	8b 55 08             	mov    0x8(%ebp),%edx
  800b4d:	8b 45 10             	mov    0x10(%ebp),%eax
	int neg = 0;
	long val = 0;

	// gobble initial whitespace
	while (*s == ' ' || *s == '\t')
  800b50:	eb 03                	jmp    800b55 <strtol+0x11>
		s++;
  800b52:	83 c2 01             	add    $0x1,%edx
{
	int neg = 0;
	long val = 0;

	// gobble initial whitespace
	while (*s == ' ' || *s == '\t')
  800b55:	0f b6 0a             	movzbl (%edx),%ecx
  800b58:	80 f9 09             	cmp    $0x9,%cl
  800b5b:	74 f5                	je     800b52 <strtol+0xe>
  800b5d:	80 f9 20             	cmp    $0x20,%cl
  800b60:	74 f0                	je     800b52 <strtol+0xe>
		s++;

	// plus/minus sign
	if (*s == '+')
  800b62:	80 f9 2b             	cmp    $0x2b,%cl
  800b65:	75 0a                	jne    800b71 <strtol+0x2d>
		s++;
  800b67:	83 c2 01             	add    $0x1,%edx
}

long
strtol(const char *s, char **endptr, int base)
{
	int neg = 0;
  800b6a:	bf 00 00 00 00       	mov    $0x0,%edi
  800b6f:	eb 11                	jmp    800b82 <strtol+0x3e>
  800b71:	bf 00 00 00 00       	mov    $0x0,%edi
		s++;

	// plus/minus sign
	if (*s == '+')
		s++;
	else if (*s == '-')
  800b76:	80 f9 2d             	cmp    $0x2d,%cl
  800b79:	75 07                	jne    800b82 <strtol+0x3e>
		s++, neg = 1;
  800b7b:	8d 52 01             	lea    0x1(%edx),%edx
  800b7e:	66 bf 01 00          	mov    $0x1,%di

	// hex or octal base prefix
	if ((base == 0 || base == 16) && (s[0] == '0' && s[1] == 'x'))
  800b82:	a9 ef ff ff ff       	test   $0xffffffef,%eax
  800b87:	75 15                	jne    800b9e <strtol+0x5a>
  800b89:	80 3a 30             	cmpb   $0x30,(%edx)
  800b8c:	75 10                	jne    800b9e <strtol+0x5a>
  800b8e:	80 7a 01 78          	cmpb   $0x78,0x1(%edx)
  800b92:	75 0a                	jne    800b9e <strtol+0x5a>
		s += 2, base = 16;
  800b94:	83 c2 02             	add    $0x2,%edx
  800b97:	b8 10 00 00 00       	mov    $0x10,%eax
  800b9c:	eb 10                	jmp    800bae <strtol+0x6a>
	else if (base == 0 && s[0] == '0')
  800b9e:	85 c0                	test   %eax,%eax
  800ba0:	75 0c                	jne    800bae <strtol+0x6a>
		s++, base = 8;
	else if (base == 0)
		base = 10;
  800ba2:	b0 0a                	mov    $0xa,%al
		s++, neg = 1;

	// hex or octal base prefix
	if ((base == 0 || base == 16) && (s[0] == '0' && s[1] == 'x'))
		s += 2, base = 16;
	else if (base == 0 && s[0] == '0')
  800ba4:	80 3a 30             	cmpb   $0x30,(%edx)
  800ba7:	75 05                	jne    800bae <strtol+0x6a>
		s++, base = 8;
  800ba9:	83 c2 01             	add    $0x1,%edx
  800bac:	b0 08                	mov    $0x8,%al
	else if (base == 0)
		base = 10;
  800bae:	bb 00 00 00 00       	mov    $0x0,%ebx
  800bb3:	89 45 10             	mov    %eax,0x10(%ebp)

	// digits
	while (1) {
		int dig;

		if (*s >= '0' && *s <= '9')
  800bb6:	0f b6 0a             	movzbl (%edx),%ecx
  800bb9:	8d 71 d0             	lea    -0x30(%ecx),%esi
  800bbc:	89 f0                	mov    %esi,%eax
  800bbe:	3c 09                	cmp    $0x9,%al
  800bc0:	77 08                	ja     800bca <strtol+0x86>
			dig = *s - '0';
  800bc2:	0f be c9             	movsbl %cl,%ecx
  800bc5:	83 e9 30             	sub    $0x30,%ecx
  800bc8:	eb 20                	jmp    800bea <strtol+0xa6>
		else if (*s >= 'a' && *s <= 'z')
  800bca:	8d 71 9f             	lea    -0x61(%ecx),%esi
  800bcd:	89 f0                	mov    %esi,%eax
  800bcf:	3c 19                	cmp    $0x19,%al
  800bd1:	77 08                	ja     800bdb <strtol+0x97>
			dig = *s - 'a' + 10;
  800bd3:	0f be c9             	movsbl %cl,%ecx
  800bd6:	83 e9 57             	sub    $0x57,%ecx
  800bd9:	eb 0f                	jmp    800bea <strtol+0xa6>
		else if (*s >= 'A' && *s <= 'Z')
  800bdb:	8d 71 bf             	lea    -0x41(%ecx),%esi
  800bde:	89 f0                	mov    %esi,%eax
  800be0:	3c 19                	cmp    $0x19,%al
  800be2:	77 16                	ja     800bfa <strtol+0xb6>
			dig = *s - 'A' + 10;
  800be4:	0f be c9             	movsbl %cl,%ecx
  800be7:	83 e9 37             	sub    $0x37,%ecx
		else
			break;
		if (dig >= base)
  800bea:	3b 4d 10             	cmp    0x10(%ebp),%ecx
  800bed:	7d 0f                	jge    800bfe <strtol+0xba>
			break;
		s++, val = (val * base) + dig;
  800bef:	83 c2 01             	add    $0x1,%edx
  800bf2:	0f af 5d 10          	imul   0x10(%ebp),%ebx
  800bf6:	01 cb                	add    %ecx,%ebx
		// we don't properly detect overflow!
	}
  800bf8:	eb bc                	jmp    800bb6 <strtol+0x72>
  800bfa:	89 d8                	mov    %ebx,%eax
  800bfc:	eb 02                	jmp    800c00 <strtol+0xbc>
  800bfe:	89 d8                	mov    %ebx,%eax

	if (endptr)
  800c00:	83 7d 0c 00          	cmpl   $0x0,0xc(%ebp)
  800c04:	74 05                	je     800c0b <strtol+0xc7>
		*endptr = (char *) s;
  800c06:	8b 75 0c             	mov    0xc(%ebp),%esi
  800c09:	89 16                	mov    %edx,(%esi)
	return (neg ? -val : val);
  800c0b:	f7 d8                	neg    %eax
  800c0d:	85 ff                	test   %edi,%edi
  800c0f:	0f 44 c3             	cmove  %ebx,%eax
}
  800c12:	5b                   	pop    %ebx
  800c13:	5e                   	pop    %esi
  800c14:	5f                   	pop    %edi
  800c15:	5d                   	pop    %ebp
  800c16:	c3                   	ret    
  800c17:	66 90                	xchg   %ax,%ax
  800c19:	66 90                	xchg   %ax,%ax
  800c1b:	66 90                	xchg   %ax,%ax
  800c1d:	66 90                	xchg   %ax,%ax
  800c1f:	90                   	nop

00800c20 <__udivdi3>:
  800c20:	55                   	push   %ebp
  800c21:	57                   	push   %edi
  800c22:	56                   	push   %esi
  800c23:	53                   	push   %ebx
  800c24:	83 ec 1c             	sub    $0x1c,%esp
  800c27:	8b 74 24 3c          	mov    0x3c(%esp),%esi
  800c2b:	8b 5c 24 30          	mov    0x30(%esp),%ebx
  800c2f:	8b 4c 24 34          	mov    0x34(%esp),%ecx
  800c33:	8b 7c 24 38          	mov    0x38(%esp),%edi
  800c37:	85 f6                	test   %esi,%esi
  800c39:	89 5c 24 08          	mov    %ebx,0x8(%esp)
  800c3d:	89 ca                	mov    %ecx,%edx
  800c3f:	89 f8                	mov    %edi,%eax
  800c41:	75 3d                	jne    800c80 <__udivdi3+0x60>
  800c43:	39 cf                	cmp    %ecx,%edi
  800c45:	0f 87 c5 00 00 00    	ja     800d10 <__udivdi3+0xf0>
  800c4b:	85 ff                	test   %edi,%edi
  800c4d:	89 fd                	mov    %edi,%ebp
  800c4f:	75 0b                	jne    800c5c <__udivdi3+0x3c>
  800c51:	b8 01 00 00 00       	mov    $0x1,%eax
  800c56:	31 d2                	xor    %edx,%edx
  800c58:	f7 f7                	div    %edi
  800c5a:	89 c5                	mov    %eax,%ebp
  800c5c:	89 c8                	mov    %ecx,%eax
  800c5e:	31 d2                	xor    %edx,%edx
  800c60:	f7 f5                	div    %ebp
  800c62:	89 c1                	mov    %eax,%ecx
  800c64:	89 d8                	mov    %ebx,%eax
  800c66:	89 cf                	mov    %ecx,%edi
  800c68:	f7 f5                	div    %ebp
  800c6a:	89 c3                	mov    %eax,%ebx
  800c6c:	89 d8                	mov    %ebx,%eax
  800c6e:	89 fa                	mov    %edi,%edx
  800c70:	83 c4 1c             	add    $0x1c,%esp
  800c73:	5b                   	pop    %ebx
  800c74:	5e                   	pop    %esi
  800c75:	5f                   	pop    %edi
  800c76:	5d                   	pop    %ebp
  800c77:	c3                   	ret    
  800c78:	90                   	nop
  800c79:	8d b4 26 00 00 00 00 	lea    0x0(%esi,%eiz,1),%esi
  800c80:	39 ce                	cmp    %ecx,%esi
  800c82:	77 74                	ja     800cf8 <__udivdi3+0xd8>
  800c84:	0f bd fe             	bsr    %esi,%edi
  800c87:	83 f7 1f             	xor    $0x1f,%edi
  800c8a:	0f 84 98 00 00 00    	je     800d28 <__udivdi3+0x108>
  800c90:	bb 20 00 00 00       	mov    $0x20,%ebx
  800c95:	89 f9                	mov    %edi,%ecx
  800c97:	89 c5                	mov    %eax,%ebp
  800c99:	29 fb                	sub    %edi,%ebx
  800c9b:	d3 e6                	shl    %cl,%esi
  800c9d:	89 d9                	mov    %ebx,%ecx
  800c9f:	d3 ed                	shr    %cl,%ebp
  800ca1:	89 f9                	mov    %edi,%ecx
  800ca3:	d3 e0                	shl    %cl,%eax
  800ca5:	09 ee                	or     %ebp,%esi
  800ca7:	89 d9                	mov    %ebx,%ecx
  800ca9:	89 44 24 0c          	mov    %eax,0xc(%esp)
  800cad:	89 d5                	mov    %edx,%ebp
  800caf:	8b 44 24 08          	mov    0x8(%esp),%eax
  800cb3:	d3 ed                	shr    %cl,%ebp
  800cb5:	89 f9                	mov    %edi,%ecx
  800cb7:	d3 e2                	shl    %cl,%edx
  800cb9:	89 d9                	mov    %ebx,%ecx
  800cbb:	d3 e8                	shr    %cl,%eax
  800cbd:	09 c2                	or     %eax,%edx
  800cbf:	89 d0                	mov    %edx,%eax
  800cc1:	89 ea                	mov    %ebp,%edx
  800cc3:	f7 f6                	div    %esi
  800cc5:	89 d5                	mov    %edx,%ebp
  800cc7:	89 c3                	mov    %eax,%ebx
  800cc9:	f7 64 24 0c          	mull   0xc(%esp)
  800ccd:	39 d5                	cmp    %edx,%ebp
  800ccf:	72 10                	jb     800ce1 <__udivdi3+0xc1>
  800cd1:	8b 74 24 08          	mov    0x8(%esp),%esi
  800cd5:	89 f9                	mov    %edi,%ecx
  800cd7:	d3 e6                	shl    %cl,%esi
  800cd9:	39 c6                	cmp    %eax,%esi
  800cdb:	73 07                	jae    800ce4 <__udivdi3+0xc4>
  800cdd:	39 d5                	cmp    %edx,%ebp
  800cdf:	75 03                	jne    800ce4 <__udivdi3+0xc4>
  800ce1:	83 eb 01             	sub    $0x1,%ebx
  800ce4:	31 ff                	xor    %edi,%edi
  800ce6:	89 d8                	mov    %ebx,%eax
  800ce8:	89 fa                	mov    %edi,%edx
  800cea:	83 c4 1c             	add    $0x1c,%esp
  800ced:	5b                   	pop    %ebx
  800cee:	5e                   	pop    %esi
  800cef:	5f                   	pop    %edi
  800cf0:	5d                   	pop    %ebp
  800cf1:	c3                   	ret    
  800cf2:	8d b6 00 00 00 00    	lea    0x0(%esi),%esi
  800cf8:	31 ff                	xor    %edi,%edi
  800cfa:	31 db                	xor    %ebx,%ebx
  800cfc:	89 d8                	mov    %ebx,%eax
  800cfe:	89 fa                	mov    %edi,%edx
  800d00:	83 c4 1c             	add    $0x1c,%esp
  800d03:	5b                   	pop    %ebx
  800d04:	5e                   	pop    %esi
  800d05:	5f                   	pop    %edi
  800d06:	5d                   	pop    %ebp
  800d07:	c3                   	ret    
  800d08:	90                   	nop
  800d09:	8d b4 26 00 00 00 00 	lea    0x0(%esi,%eiz,1),%esi
  800d10:	89 d8                	mov    %ebx,%eax
  800d12:	f7 f7                	div    %edi
  800d14:	31 ff                	xor    %edi,%edi
  800d16:	89 c3                	mov    %eax,%ebx
  800d18:	89 d8                	mov    %ebx,%eax
  800d1a:	89 fa                	mov    %edi,%edx
  800d1c:	83 c4 1c             	add    $0x1c,%esp
  800d1f:	5b                   	pop    %ebx
  800d20:	5e                   	pop    %esi
  800d21:	5f                   	pop    %edi
  800d22:	5d                   	pop    %ebp
  800d23:	c3                   	ret    
  800d24:	8d 74 26 00          	lea    0x0(%esi,%eiz,1),%esi
  800d28:	39 ce                	cmp    %ecx,%esi
  800d2a:	72 0c                	jb     800d38 <__udivdi3+0x118>
  800d2c:	31 db                	xor    %ebx,%ebx
  800d2e:	3b 44 24 08          	cmp    0x8(%esp),%eax
  800d32:	0f 87 34 ff ff ff    	ja     800c6c <__udivdi3+0x4c>
  800d38:	bb 01 00 00 00       	mov    $0x1,%ebx
  800d3d:	e9 2a ff ff ff       	jmp    800c6c <__udivdi3+0x4c>
  800d42:	66 90                	xchg   %ax,%ax
  800d44:	66 90                	xchg   %ax,%ax
  800d46:	66 90                	xchg   %ax,%ax
  800d48:	66 90                	xchg   %ax,%ax
  800d4a:	66 90                	xchg   %ax,%ax
  800d4c:	66 90                	xchg   %ax,%ax
  800d4e:	66 90                	xchg   %ax,%ax

00800d50 <__umoddi3>:
  800d50:	55                   	push   %ebp
  800d51:	57                   	push   %edi
  800d52:	56                   	push   %esi
  800d53:	53                   	push   %ebx
  800d54:	83 ec 1c             	sub    $0x1c,%esp
  800d57:	8b 54 24 3c          	mov    0x3c(%esp),%edx
  800d5b:	8b 4c 24 30          	mov    0x30(%esp),%ecx
  800d5f:	8b 74 24 34          	mov    0x34(%esp),%esi
  800d63:	8b 7c 24 38          	mov    0x38(%esp),%edi
  800d67:	85 d2                	test   %edx,%edx
  800d69:	89 4c 24 0c          	mov    %ecx,0xc(%esp)
  800d6d:	89 4c 24 08          	mov    %ecx,0x8(%esp)
  800d71:	89 f3                	mov    %esi,%ebx
  800d73:	89 3c 24             	mov    %edi,(%esp)
  800d76:	89 74 24 04          	mov    %esi,0x4(%esp)
  800d7a:	75 1c                	jne    800d98 <__umoddi3+0x48>
  800d7c:	39 f7                	cmp    %esi,%edi
  800d7e:	76 50                	jbe    800dd0 <__umoddi3+0x80>
  800d80:	89 c8                	mov    %ecx,%eax
  800d82:	89 f2                	mov    %esi,%edx
  800d84:	f7 f7                	div    %edi
  800d86:	89 d0                	mov    %edx,%eax
  800d88:	31 d2                	xor    %edx,%edx
  800d8a:	83 c4 1c             	add    $0x1c,%esp
  800d8d:	5b                   	pop    %ebx
  800d8e:	5e                   	pop    %esi
  800d8f:	5f                   	pop    %edi
  800d90:	5d                   	pop    %ebp
  800d91:	c3                   	ret    
  800d92:	8d b6 00 00 00 00    	lea    0x0(%esi),%esi
  800d98:	39 f2                	cmp    %esi,%edx
  800d9a:	89 d0                	mov    %edx,%eax
  800d9c:	77 52                	ja     800df0 <__umoddi3+0xa0>
  800d9e:	0f bd ea             	bsr    %edx,%ebp
  800da1:	83 f5 1f             	xor    $0x1f,%ebp
  800da4:	75 5a                	jne    800e00 <__umoddi3+0xb0>
  800da6:	3b 54 24 04          	cmp    0x4(%esp),%edx
  800daa:	0f 82 e0 00 00 00    	jb     800e90 <__umoddi3+0x140>
  800db0:	39 0c 24             	cmp    %ecx,(%esp)
  800db3:	0f 86 d7 00 00 00    	jbe    800e90 <__umoddi3+0x140>
  800db9:	8b 44 24 08          	mov    0x8(%esp),%eax
  800dbd:	8b 54 24 04          	mov    0x4(%esp),%edx
  800dc1:	83 c4 1c             	add    $0x1c,%esp
  800dc4:	5b                   	pop    %ebx
  800dc5:	5e                   	pop    %esi
  800dc6:	5f                   	pop    %edi
  800dc7:	5d                   	pop    %ebp
  800dc8:	c3                   	ret    
  800dc9:	8d b4 26 00 00 00 00 	lea    0x0(%esi,%eiz,1),%esi
  800dd0:	85 ff                	test   %edi,%edi
  800dd2:	89 fd                	mov    %edi,%ebp
  800dd4:	75 0b                	jne    800de1 <__umoddi3+0x91>
  800dd6:	b8 01 00 00 00       	mov    $0x1,%eax
  800ddb:	31 d2                	xor    %edx,%edx
  800ddd:	f7 f7                	div    %edi
  800ddf:	89 c5                	mov    %eax,%ebp
  800de1:	89 f0                	mov    %esi,%eax
  800de3:	31 d2                	xor    %edx,%edx
  800de5:	f7 f5                	div    %ebp
  800de7:	89 c8                	mov    %ecx,%eax
  800de9:	f7 f5                	div    %ebp
  800deb:	89 d0                	mov    %edx,%eax
  800ded:	eb 99                	jmp    800d88 <__umoddi3+0x38>
  800def:	90                   	nop
  800df0:	89 c8                	mov    %ecx,%eax
  800df2:	89 f2                	mov    %esi,%edx
  800df4:	83 c4 1c             	add    $0x1c,%esp
  800df7:	5b                   	pop    %ebx
  800df8:	5e                   	pop    %esi
  800df9:	5f                   	pop    %edi
  800dfa:	5d                   	pop    %ebp
  800dfb:	c3                   	ret    
  800dfc:	8d 74 26 00          	lea    0x0(%esi,%eiz,1),%esi
  800e00:	8b 34 24             	mov    (%esp),%esi
  800e03:	bf 20 00 00 00       	mov    $0x20,%edi
  800e08:	89 e9                	mov    %ebp,%ecx
  800e0a:	29 ef                	sub    %ebp,%edi
  800e0c:	d3 e0                	shl    %cl,%eax
  800e0e:	89 f9                	mov    %edi,%ecx
  800e10:	89 f2                	mov    %esi,%edx
  800e12:	d3 ea                	shr    %cl,%edx
  800e14:	89 e9                	mov    %ebp,%ecx
  800e16:	09 c2                	or     %eax,%edx
  800e18:	89 d8                	mov    %ebx,%eax
  800e1a:	89 14 24             	mov    %edx,(%esp)
  800e1d:	89 f2                	mov    %esi,%edx
  800e1f:	d3 e2                	shl    %cl,%edx
  800e21:	89 f9                	mov    %edi,%ecx
  800e23:	89 54 24 04          	mov    %edx,0x4(%esp)
  800e27:	8b 54 24 0c          	mov    0xc(%esp),%edx
  800e2b:	d3 e8                	shr    %cl,%eax
  800e2d:	89 e9                	mov    %ebp,%ecx
  800e2f:	89 c6                	mov    %eax,%esi
  800e31:	d3 e3                	shl    %cl,%ebx
  800e33:	89 f9                	mov    %edi,%ecx
  800e35:	89 d0                	mov    %edx,%eax
  800e37:	d3 e8                	shr    %cl,%eax
  800e39:	89 e9                	mov    %ebp,%ecx
  800e3b:	09 d8                	or     %ebx,%eax
  800e3d:	89 d3                	mov    %edx,%ebx
  800e3f:	89 f2                	mov    %esi,%edx
  800e41:	f7 34 24             	divl   (%esp)
  800e44:	89 d6                	mov    %edx,%esi
  800e46:	d3 e3                	shl    %cl,%ebx
  800e48:	f7 64 24 04          	mull   0x4(%esp)
  800e4c:	39 d6                	cmp    %edx,%esi
  800e4e:	89 5c 24 08          	mov    %ebx,0x8(%esp)
  800e52:	89 d1                	mov    %edx,%ecx
  800e54:	89 c3                	mov    %eax,%ebx
  800e56:	72 08                	jb     800e60 <__umoddi3+0x110>
  800e58:	75 11                	jne    800e6b <__umoddi3+0x11b>
  800e5a:	39 44 24 08          	cmp    %eax,0x8(%esp)
  800e5e:	73 0b                	jae    800e6b <__umoddi3+0x11b>
  800e60:	2b 44 24 04          	sub    0x4(%esp),%eax
  800e64:	1b 14 24             	sbb    (%esp),%edx
  800e67:	89 d1                	mov    %edx,%ecx
  800e69:	89 c3                	mov    %eax,%ebx
  800e6b:	8b 54 24 08          	mov    0x8(%esp),%edx
  800e6f:	29 da                	sub    %ebx,%edx
  800e71:	19 ce                	sbb    %ecx,%esi
  800e73:	89 f9                	mov    %edi,%ecx
  800e75:	89 f0                	mov    %esi,%eax
  800e77:	d3 e0                	shl    %cl,%eax
  800e79:	89 e9                	mov    %ebp,%ecx
  800e7b:	d3 ea                	shr    %cl,%edx
  800e7d:	89 e9                	mov    %ebp,%ecx
  800e7f:	d3 ee                	shr    %cl,%esi
  800e81:	09 d0                	or     %edx,%eax
  800e83:	89 f2                	mov    %esi,%edx
  800e85:	83 c4 1c             	add    $0x1c,%esp
  800e88:	5b                   	pop    %ebx
  800e89:	5e                   	pop    %esi
  800e8a:	5f                   	pop    %edi
  800e8b:	5d                   	pop    %ebp
  800e8c:	c3                   	ret    
  800e8d:	8d 76 00             	lea    0x0(%esi),%esi
  800e90:	29 f9                	sub    %edi,%ecx
  800e92:	19 d6                	sbb    %edx,%esi
  800e94:	89 74 24 04          	mov    %esi,0x4(%esp)
  800e98:	89 4c 24 08          	mov    %ecx,0x8(%esp)
  800e9c:	e9 18 ff ff ff       	jmp    800db9 <__umoddi3+0x69>
