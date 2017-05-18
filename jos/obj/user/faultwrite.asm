
obj/user/faultwrite:     file format elf32-i386


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
	*(unsigned*)0 = 0;
  800036:	c7 05 00 00 00 00 00 	movl   $0x0,0x0
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
  800045:	83 ec 18             	sub    $0x18,%esp
  800048:	8b 45 08             	mov    0x8(%ebp),%eax
  80004b:	8b 55 0c             	mov    0xc(%ebp),%edx
	// set thisenv to point at our Env structure in envs[].
	// LAB 3: Your code here.
	thisenv = 0;
  80004e:	c7 05 04 20 80 00 00 	movl   $0x0,0x802004
  800055:	00 00 00 

	// save the name of the program so that panic() can use it
	if (argc > 0)
  800058:	85 c0                	test   %eax,%eax
  80005a:	7e 08                	jle    800064 <libmain+0x22>
		binaryname = argv[0];
  80005c:	8b 0a                	mov    (%edx),%ecx
  80005e:	89 0d 00 20 80 00    	mov    %ecx,0x802000

	// call user main routine
	umain(argc, argv);
  800064:	89 54 24 04          	mov    %edx,0x4(%esp)
  800068:	89 04 24             	mov    %eax,(%esp)
  80006b:	e8 c3 ff ff ff       	call   800033 <umain>

	// exit gracefully
	exit();
  800070:	e8 02 00 00 00       	call   800077 <exit>
}
  800075:	c9                   	leave  
  800076:	c3                   	ret    

00800077 <exit>:

#include <inc/lib.h>

void
exit(void)
{
  800077:	55                   	push   %ebp
  800078:	89 e5                	mov    %esp,%ebp
  80007a:	83 ec 18             	sub    $0x18,%esp
	sys_env_destroy(0);
  80007d:	c7 04 24 00 00 00 00 	movl   $0x0,(%esp)
  800084:	e8 cd 00 00 00       	call   800156 <sys_env_destroy>
}
  800089:	c9                   	leave  
  80008a:	c3                   	ret    

0080008b <syscall>:
#include <inc/syscall.h>
#include <inc/lib.h>

static inline int32_t
syscall(int num, int check, uint32_t a1, uint32_t a2, uint32_t a3, uint32_t a4, uint32_t a5)
{
  80008b:	55                   	push   %ebp
  80008c:	89 e5                	mov    %esp,%ebp
  80008e:	57                   	push   %edi
  80008f:	56                   	push   %esi
  800090:	53                   	push   %ebx
  800091:	83 ec 2c             	sub    $0x2c,%esp
  800094:	89 45 e4             	mov    %eax,-0x1c(%ebp)
  800097:	89 55 e0             	mov    %edx,-0x20(%ebp)
  80009a:	89 ca                	mov    %ecx,%edx
	//
	// The last clause tells the assembler that this can
	// potentially change the condition codes and arbitrary
	// memory locations.

	asm volatile("int %1\n"
  80009c:	8b 4d 08             	mov    0x8(%ebp),%ecx
  80009f:	8b 5d 0c             	mov    0xc(%ebp),%ebx
  8000a2:	8b 7d 10             	mov    0x10(%ebp),%edi
  8000a5:	8b 75 14             	mov    0x14(%ebp),%esi
  8000a8:	cd 30                	int    $0x30
		       "b" (a3),
		       "D" (a4),
		       "S" (a5)
		     : "cc", "memory");

	if(check && ret > 0)
  8000aa:	85 c0                	test   %eax,%eax
  8000ac:	7e 2d                	jle    8000db <syscall+0x50>
  8000ae:	83 7d e0 00          	cmpl   $0x0,-0x20(%ebp)
  8000b2:	74 27                	je     8000db <syscall+0x50>
		panic("syscall %d returned %d (> 0)", num, ret);
  8000b4:	89 44 24 10          	mov    %eax,0x10(%esp)
  8000b8:	8b 45 e4             	mov    -0x1c(%ebp),%eax
  8000bb:	89 44 24 0c          	mov    %eax,0xc(%esp)
  8000bf:	c7 44 24 08 b2 0e 80 	movl   $0x800eb2,0x8(%esp)
  8000c6:	00 
  8000c7:	c7 44 24 04 23 00 00 	movl   $0x23,0x4(%esp)
  8000ce:	00 
  8000cf:	c7 04 24 cf 0e 80 00 	movl   $0x800ecf,(%esp)
  8000d6:	e8 ef 00 00 00       	call   8001ca <_panic>

	return ret;
}
  8000db:	83 c4 2c             	add    $0x2c,%esp
  8000de:	5b                   	pop    %ebx
  8000df:	5e                   	pop    %esi
  8000e0:	5f                   	pop    %edi
  8000e1:	5d                   	pop    %ebp
  8000e2:	c3                   	ret    

008000e3 <sys_cputs>:

void
sys_cputs(const char *s, size_t len)
{
  8000e3:	55                   	push   %ebp
  8000e4:	89 e5                	mov    %esp,%ebp
  8000e6:	83 ec 18             	sub    $0x18,%esp
	syscall(SYS_cputs, 0, (uint32_t)s, len, 0, 0, 0);
  8000e9:	c7 44 24 0c 00 00 00 	movl   $0x0,0xc(%esp)
  8000f0:	00 
  8000f1:	c7 44 24 08 00 00 00 	movl   $0x0,0x8(%esp)
  8000f8:	00 
  8000f9:	c7 44 24 04 00 00 00 	movl   $0x0,0x4(%esp)
  800100:	00 
  800101:	8b 45 0c             	mov    0xc(%ebp),%eax
  800104:	89 04 24             	mov    %eax,(%esp)
  800107:	8b 4d 08             	mov    0x8(%ebp),%ecx
  80010a:	ba 00 00 00 00       	mov    $0x0,%edx
  80010f:	b8 00 00 00 00       	mov    $0x0,%eax
  800114:	e8 72 ff ff ff       	call   80008b <syscall>
}
  800119:	c9                   	leave  
  80011a:	c3                   	ret    

0080011b <sys_cgetc>:

int
sys_cgetc(void)
{
  80011b:	55                   	push   %ebp
  80011c:	89 e5                	mov    %esp,%ebp
  80011e:	83 ec 18             	sub    $0x18,%esp
	return syscall(SYS_cgetc, 0, 0, 0, 0, 0, 0);
  800121:	c7 44 24 0c 00 00 00 	movl   $0x0,0xc(%esp)
  800128:	00 
  800129:	c7 44 24 08 00 00 00 	movl   $0x0,0x8(%esp)
  800130:	00 
  800131:	c7 44 24 04 00 00 00 	movl   $0x0,0x4(%esp)
  800138:	00 
  800139:	c7 04 24 00 00 00 00 	movl   $0x0,(%esp)
  800140:	b9 00 00 00 00       	mov    $0x0,%ecx
  800145:	ba 00 00 00 00       	mov    $0x0,%edx
  80014a:	b8 01 00 00 00       	mov    $0x1,%eax
  80014f:	e8 37 ff ff ff       	call   80008b <syscall>
}
  800154:	c9                   	leave  
  800155:	c3                   	ret    

00800156 <sys_env_destroy>:

int
sys_env_destroy(envid_t envid)
{
  800156:	55                   	push   %ebp
  800157:	89 e5                	mov    %esp,%ebp
  800159:	83 ec 18             	sub    $0x18,%esp
	return syscall(SYS_env_destroy, 1, envid, 0, 0, 0, 0);
  80015c:	c7 44 24 0c 00 00 00 	movl   $0x0,0xc(%esp)
  800163:	00 
  800164:	c7 44 24 08 00 00 00 	movl   $0x0,0x8(%esp)
  80016b:	00 
  80016c:	c7 44 24 04 00 00 00 	movl   $0x0,0x4(%esp)
  800173:	00 
  800174:	c7 04 24 00 00 00 00 	movl   $0x0,(%esp)
  80017b:	8b 4d 08             	mov    0x8(%ebp),%ecx
  80017e:	ba 01 00 00 00       	mov    $0x1,%edx
  800183:	b8 03 00 00 00       	mov    $0x3,%eax
  800188:	e8 fe fe ff ff       	call   80008b <syscall>
}
  80018d:	c9                   	leave  
  80018e:	c3                   	ret    

0080018f <sys_getenvid>:

envid_t
sys_getenvid(void)
{
  80018f:	55                   	push   %ebp
  800190:	89 e5                	mov    %esp,%ebp
  800192:	83 ec 18             	sub    $0x18,%esp
	 return syscall(SYS_getenvid, 0, 0, 0, 0, 0, 0);
  800195:	c7 44 24 0c 00 00 00 	movl   $0x0,0xc(%esp)
  80019c:	00 
  80019d:	c7 44 24 08 00 00 00 	movl   $0x0,0x8(%esp)
  8001a4:	00 
  8001a5:	c7 44 24 04 00 00 00 	movl   $0x0,0x4(%esp)
  8001ac:	00 
  8001ad:	c7 04 24 00 00 00 00 	movl   $0x0,(%esp)
  8001b4:	b9 00 00 00 00       	mov    $0x0,%ecx
  8001b9:	ba 00 00 00 00       	mov    $0x0,%edx
  8001be:	b8 02 00 00 00       	mov    $0x2,%eax
  8001c3:	e8 c3 fe ff ff       	call   80008b <syscall>
}
  8001c8:	c9                   	leave  
  8001c9:	c3                   	ret    

008001ca <_panic>:
 * It prints "panic: <message>", then causes a breakpoint exception,
 * which causes JOS to enter the JOS kernel monitor.
 */
void
_panic(const char *file, int line, const char *fmt, ...)
{
  8001ca:	55                   	push   %ebp
  8001cb:	89 e5                	mov    %esp,%ebp
  8001cd:	56                   	push   %esi
  8001ce:	53                   	push   %ebx
  8001cf:	83 ec 20             	sub    $0x20,%esp
	va_list ap;

	va_start(ap, fmt);
  8001d2:	8d 5d 14             	lea    0x14(%ebp),%ebx

	// Print the panic message
	cprintf("[%08x] user panic in %s at %s:%d: ",
  8001d5:	8b 35 00 20 80 00    	mov    0x802000,%esi
  8001db:	e8 af ff ff ff       	call   80018f <sys_getenvid>
  8001e0:	8b 55 0c             	mov    0xc(%ebp),%edx
  8001e3:	89 54 24 10          	mov    %edx,0x10(%esp)
  8001e7:	8b 55 08             	mov    0x8(%ebp),%edx
  8001ea:	89 54 24 0c          	mov    %edx,0xc(%esp)
  8001ee:	89 74 24 08          	mov    %esi,0x8(%esp)
  8001f2:	89 44 24 04          	mov    %eax,0x4(%esp)
  8001f6:	c7 04 24 e0 0e 80 00 	movl   $0x800ee0,(%esp)
  8001fd:	e8 c1 00 00 00       	call   8002c3 <cprintf>
		sys_getenvid(), binaryname, file, line);
	vcprintf(fmt, ap);
  800202:	89 5c 24 04          	mov    %ebx,0x4(%esp)
  800206:	8b 45 10             	mov    0x10(%ebp),%eax
  800209:	89 04 24             	mov    %eax,(%esp)
  80020c:	e8 51 00 00 00       	call   800262 <vcprintf>
	cprintf("\n");
  800211:	c7 04 24 04 0f 80 00 	movl   $0x800f04,(%esp)
  800218:	e8 a6 00 00 00       	call   8002c3 <cprintf>

	// Cause a breakpoint exception
	while (1)
		asm volatile("int3");
  80021d:	cc                   	int3   
  80021e:	eb fd                	jmp    80021d <_panic+0x53>

00800220 <putch>:
};


static void
putch(int ch, struct printbuf *b)
{
  800220:	55                   	push   %ebp
  800221:	89 e5                	mov    %esp,%ebp
  800223:	53                   	push   %ebx
  800224:	83 ec 14             	sub    $0x14,%esp
  800227:	8b 5d 0c             	mov    0xc(%ebp),%ebx
	b->buf[b->idx++] = ch;
  80022a:	8b 13                	mov    (%ebx),%edx
  80022c:	8d 42 01             	lea    0x1(%edx),%eax
  80022f:	89 03                	mov    %eax,(%ebx)
  800231:	8b 4d 08             	mov    0x8(%ebp),%ecx
  800234:	88 4c 13 08          	mov    %cl,0x8(%ebx,%edx,1)
	if (b->idx == 256-1) {
  800238:	3d ff 00 00 00       	cmp    $0xff,%eax
  80023d:	75 19                	jne    800258 <putch+0x38>
		sys_cputs(b->buf, b->idx);
  80023f:	c7 44 24 04 ff 00 00 	movl   $0xff,0x4(%esp)
  800246:	00 
  800247:	8d 43 08             	lea    0x8(%ebx),%eax
  80024a:	89 04 24             	mov    %eax,(%esp)
  80024d:	e8 91 fe ff ff       	call   8000e3 <sys_cputs>
		b->idx = 0;
  800252:	c7 03 00 00 00 00    	movl   $0x0,(%ebx)
	}
	b->cnt++;
  800258:	83 43 04 01          	addl   $0x1,0x4(%ebx)
}
  80025c:	83 c4 14             	add    $0x14,%esp
  80025f:	5b                   	pop    %ebx
  800260:	5d                   	pop    %ebp
  800261:	c3                   	ret    

00800262 <vcprintf>:

int
vcprintf(const char *fmt, va_list ap)
{
  800262:	55                   	push   %ebp
  800263:	89 e5                	mov    %esp,%ebp
  800265:	81 ec 28 01 00 00    	sub    $0x128,%esp
	struct printbuf b;

	b.idx = 0;
  80026b:	c7 85 f0 fe ff ff 00 	movl   $0x0,-0x110(%ebp)
  800272:	00 00 00 
	b.cnt = 0;
  800275:	c7 85 f4 fe ff ff 00 	movl   $0x0,-0x10c(%ebp)
  80027c:	00 00 00 
	vprintfmt((void*)putch, &b, fmt, ap);
  80027f:	8b 45 0c             	mov    0xc(%ebp),%eax
  800282:	89 44 24 0c          	mov    %eax,0xc(%esp)
  800286:	8b 45 08             	mov    0x8(%ebp),%eax
  800289:	89 44 24 08          	mov    %eax,0x8(%esp)
  80028d:	8d 85 f0 fe ff ff    	lea    -0x110(%ebp),%eax
  800293:	89 44 24 04          	mov    %eax,0x4(%esp)
  800297:	c7 04 24 20 02 80 00 	movl   $0x800220,(%esp)
  80029e:	e8 dd 01 00 00       	call   800480 <vprintfmt>
	sys_cputs(b.buf, b.idx);
  8002a3:	8b 85 f0 fe ff ff    	mov    -0x110(%ebp),%eax
  8002a9:	89 44 24 04          	mov    %eax,0x4(%esp)
  8002ad:	8d 85 f8 fe ff ff    	lea    -0x108(%ebp),%eax
  8002b3:	89 04 24             	mov    %eax,(%esp)
  8002b6:	e8 28 fe ff ff       	call   8000e3 <sys_cputs>

	return b.cnt;
}
  8002bb:	8b 85 f4 fe ff ff    	mov    -0x10c(%ebp),%eax
  8002c1:	c9                   	leave  
  8002c2:	c3                   	ret    

008002c3 <cprintf>:

int
cprintf(const char *fmt, ...)
{
  8002c3:	55                   	push   %ebp
  8002c4:	89 e5                	mov    %esp,%ebp
  8002c6:	83 ec 18             	sub    $0x18,%esp
	va_list ap;
	int cnt;

	va_start(ap, fmt);
  8002c9:	8d 45 0c             	lea    0xc(%ebp),%eax
	cnt = vcprintf(fmt, ap);
  8002cc:	89 44 24 04          	mov    %eax,0x4(%esp)
  8002d0:	8b 45 08             	mov    0x8(%ebp),%eax
  8002d3:	89 04 24             	mov    %eax,(%esp)
  8002d6:	e8 87 ff ff ff       	call   800262 <vcprintf>
	va_end(ap);

	return cnt;
}
  8002db:	c9                   	leave  
  8002dc:	c3                   	ret    
  8002dd:	66 90                	xchg   %ax,%ax
  8002df:	90                   	nop

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
  8003b8:	0f be 80 06 0f 80 00 	movsbl 0x800f06(%eax),%eax
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
  800505:	ff 24 8d 94 0f 80 00 	jmp    *0x800f94(,%ecx,4)
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
  8005a2:	8b 14 85 ec 10 80 00 	mov    0x8010ec(,%eax,4),%edx
  8005a9:	85 d2                	test   %edx,%edx
  8005ab:	75 20                	jne    8005cd <vprintfmt+0x14d>
				printfmt(putch, putdat, "error %d", err);
  8005ad:	89 44 24 0c          	mov    %eax,0xc(%esp)
  8005b1:	c7 44 24 08 1e 0f 80 	movl   $0x800f1e,0x8(%esp)
  8005b8:	00 
  8005b9:	89 74 24 04          	mov    %esi,0x4(%esp)
  8005bd:	8b 45 08             	mov    0x8(%ebp),%eax
  8005c0:	89 04 24             	mov    %eax,(%esp)
  8005c3:	e8 90 fe ff ff       	call   800458 <printfmt>
  8005c8:	e9 d8 fe ff ff       	jmp    8004a5 <vprintfmt+0x25>
			else
				printfmt(putch, putdat, "%s", p);
  8005cd:	89 54 24 0c          	mov    %edx,0xc(%esp)
  8005d1:	c7 44 24 08 27 0f 80 	movl   $0x800f27,0x8(%esp)
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
  800603:	b8 17 0f 80 00       	mov    $0x800f17,%eax
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
  800c23:	83 ec 0c             	sub    $0xc,%esp
  800c26:	8b 44 24 28          	mov    0x28(%esp),%eax
  800c2a:	8b 7c 24 1c          	mov    0x1c(%esp),%edi
  800c2e:	8b 6c 24 20          	mov    0x20(%esp),%ebp
  800c32:	8b 4c 24 24          	mov    0x24(%esp),%ecx
  800c36:	85 c0                	test   %eax,%eax
  800c38:	89 7c 24 04          	mov    %edi,0x4(%esp)
  800c3c:	89 ea                	mov    %ebp,%edx
  800c3e:	89 0c 24             	mov    %ecx,(%esp)
  800c41:	75 2d                	jne    800c70 <__udivdi3+0x50>
  800c43:	39 e9                	cmp    %ebp,%ecx
  800c45:	77 61                	ja     800ca8 <__udivdi3+0x88>
  800c47:	85 c9                	test   %ecx,%ecx
  800c49:	89 ce                	mov    %ecx,%esi
  800c4b:	75 0b                	jne    800c58 <__udivdi3+0x38>
  800c4d:	b8 01 00 00 00       	mov    $0x1,%eax
  800c52:	31 d2                	xor    %edx,%edx
  800c54:	f7 f1                	div    %ecx
  800c56:	89 c6                	mov    %eax,%esi
  800c58:	31 d2                	xor    %edx,%edx
  800c5a:	89 e8                	mov    %ebp,%eax
  800c5c:	f7 f6                	div    %esi
  800c5e:	89 c5                	mov    %eax,%ebp
  800c60:	89 f8                	mov    %edi,%eax
  800c62:	f7 f6                	div    %esi
  800c64:	89 ea                	mov    %ebp,%edx
  800c66:	83 c4 0c             	add    $0xc,%esp
  800c69:	5e                   	pop    %esi
  800c6a:	5f                   	pop    %edi
  800c6b:	5d                   	pop    %ebp
  800c6c:	c3                   	ret    
  800c6d:	8d 76 00             	lea    0x0(%esi),%esi
  800c70:	39 e8                	cmp    %ebp,%eax
  800c72:	77 24                	ja     800c98 <__udivdi3+0x78>
  800c74:	0f bd e8             	bsr    %eax,%ebp
  800c77:	83 f5 1f             	xor    $0x1f,%ebp
  800c7a:	75 3c                	jne    800cb8 <__udivdi3+0x98>
  800c7c:	8b 74 24 04          	mov    0x4(%esp),%esi
  800c80:	39 34 24             	cmp    %esi,(%esp)
  800c83:	0f 86 9f 00 00 00    	jbe    800d28 <__udivdi3+0x108>
  800c89:	39 d0                	cmp    %edx,%eax
  800c8b:	0f 82 97 00 00 00    	jb     800d28 <__udivdi3+0x108>
  800c91:	8d b4 26 00 00 00 00 	lea    0x0(%esi,%eiz,1),%esi
  800c98:	31 d2                	xor    %edx,%edx
  800c9a:	31 c0                	xor    %eax,%eax
  800c9c:	83 c4 0c             	add    $0xc,%esp
  800c9f:	5e                   	pop    %esi
  800ca0:	5f                   	pop    %edi
  800ca1:	5d                   	pop    %ebp
  800ca2:	c3                   	ret    
  800ca3:	90                   	nop
  800ca4:	8d 74 26 00          	lea    0x0(%esi,%eiz,1),%esi
  800ca8:	89 f8                	mov    %edi,%eax
  800caa:	f7 f1                	div    %ecx
  800cac:	31 d2                	xor    %edx,%edx
  800cae:	83 c4 0c             	add    $0xc,%esp
  800cb1:	5e                   	pop    %esi
  800cb2:	5f                   	pop    %edi
  800cb3:	5d                   	pop    %ebp
  800cb4:	c3                   	ret    
  800cb5:	8d 76 00             	lea    0x0(%esi),%esi
  800cb8:	89 e9                	mov    %ebp,%ecx
  800cba:	8b 3c 24             	mov    (%esp),%edi
  800cbd:	d3 e0                	shl    %cl,%eax
  800cbf:	89 c6                	mov    %eax,%esi
  800cc1:	b8 20 00 00 00       	mov    $0x20,%eax
  800cc6:	29 e8                	sub    %ebp,%eax
  800cc8:	89 c1                	mov    %eax,%ecx
  800cca:	d3 ef                	shr    %cl,%edi
  800ccc:	89 e9                	mov    %ebp,%ecx
  800cce:	89 7c 24 08          	mov    %edi,0x8(%esp)
  800cd2:	8b 3c 24             	mov    (%esp),%edi
  800cd5:	09 74 24 08          	or     %esi,0x8(%esp)
  800cd9:	89 d6                	mov    %edx,%esi
  800cdb:	d3 e7                	shl    %cl,%edi
  800cdd:	89 c1                	mov    %eax,%ecx
  800cdf:	89 3c 24             	mov    %edi,(%esp)
  800ce2:	8b 7c 24 04          	mov    0x4(%esp),%edi
  800ce6:	d3 ee                	shr    %cl,%esi
  800ce8:	89 e9                	mov    %ebp,%ecx
  800cea:	d3 e2                	shl    %cl,%edx
  800cec:	89 c1                	mov    %eax,%ecx
  800cee:	d3 ef                	shr    %cl,%edi
  800cf0:	09 d7                	or     %edx,%edi
  800cf2:	89 f2                	mov    %esi,%edx
  800cf4:	89 f8                	mov    %edi,%eax
  800cf6:	f7 74 24 08          	divl   0x8(%esp)
  800cfa:	89 d6                	mov    %edx,%esi
  800cfc:	89 c7                	mov    %eax,%edi
  800cfe:	f7 24 24             	mull   (%esp)
  800d01:	39 d6                	cmp    %edx,%esi
  800d03:	89 14 24             	mov    %edx,(%esp)
  800d06:	72 30                	jb     800d38 <__udivdi3+0x118>
  800d08:	8b 54 24 04          	mov    0x4(%esp),%edx
  800d0c:	89 e9                	mov    %ebp,%ecx
  800d0e:	d3 e2                	shl    %cl,%edx
  800d10:	39 c2                	cmp    %eax,%edx
  800d12:	73 05                	jae    800d19 <__udivdi3+0xf9>
  800d14:	3b 34 24             	cmp    (%esp),%esi
  800d17:	74 1f                	je     800d38 <__udivdi3+0x118>
  800d19:	89 f8                	mov    %edi,%eax
  800d1b:	31 d2                	xor    %edx,%edx
  800d1d:	e9 7a ff ff ff       	jmp    800c9c <__udivdi3+0x7c>
  800d22:	8d b6 00 00 00 00    	lea    0x0(%esi),%esi
  800d28:	31 d2                	xor    %edx,%edx
  800d2a:	b8 01 00 00 00       	mov    $0x1,%eax
  800d2f:	e9 68 ff ff ff       	jmp    800c9c <__udivdi3+0x7c>
  800d34:	8d 74 26 00          	lea    0x0(%esi,%eiz,1),%esi
  800d38:	8d 47 ff             	lea    -0x1(%edi),%eax
  800d3b:	31 d2                	xor    %edx,%edx
  800d3d:	83 c4 0c             	add    $0xc,%esp
  800d40:	5e                   	pop    %esi
  800d41:	5f                   	pop    %edi
  800d42:	5d                   	pop    %ebp
  800d43:	c3                   	ret    
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
  800d53:	83 ec 14             	sub    $0x14,%esp
  800d56:	8b 44 24 28          	mov    0x28(%esp),%eax
  800d5a:	8b 4c 24 24          	mov    0x24(%esp),%ecx
  800d5e:	8b 74 24 2c          	mov    0x2c(%esp),%esi
  800d62:	89 c7                	mov    %eax,%edi
  800d64:	89 44 24 04          	mov    %eax,0x4(%esp)
  800d68:	8b 44 24 30          	mov    0x30(%esp),%eax
  800d6c:	89 4c 24 10          	mov    %ecx,0x10(%esp)
  800d70:	89 34 24             	mov    %esi,(%esp)
  800d73:	89 4c 24 08          	mov    %ecx,0x8(%esp)
  800d77:	85 c0                	test   %eax,%eax
  800d79:	89 c2                	mov    %eax,%edx
  800d7b:	89 7c 24 0c          	mov    %edi,0xc(%esp)
  800d7f:	75 17                	jne    800d98 <__umoddi3+0x48>
  800d81:	39 fe                	cmp    %edi,%esi
  800d83:	76 4b                	jbe    800dd0 <__umoddi3+0x80>
  800d85:	89 c8                	mov    %ecx,%eax
  800d87:	89 fa                	mov    %edi,%edx
  800d89:	f7 f6                	div    %esi
  800d8b:	89 d0                	mov    %edx,%eax
  800d8d:	31 d2                	xor    %edx,%edx
  800d8f:	83 c4 14             	add    $0x14,%esp
  800d92:	5e                   	pop    %esi
  800d93:	5f                   	pop    %edi
  800d94:	5d                   	pop    %ebp
  800d95:	c3                   	ret    
  800d96:	66 90                	xchg   %ax,%ax
  800d98:	39 f8                	cmp    %edi,%eax
  800d9a:	77 54                	ja     800df0 <__umoddi3+0xa0>
  800d9c:	0f bd e8             	bsr    %eax,%ebp
  800d9f:	83 f5 1f             	xor    $0x1f,%ebp
  800da2:	75 5c                	jne    800e00 <__umoddi3+0xb0>
  800da4:	8b 7c 24 08          	mov    0x8(%esp),%edi
  800da8:	39 3c 24             	cmp    %edi,(%esp)
  800dab:	0f 87 e7 00 00 00    	ja     800e98 <__umoddi3+0x148>
  800db1:	8b 7c 24 04          	mov    0x4(%esp),%edi
  800db5:	29 f1                	sub    %esi,%ecx
  800db7:	19 c7                	sbb    %eax,%edi
  800db9:	89 4c 24 08          	mov    %ecx,0x8(%esp)
  800dbd:	89 7c 24 0c          	mov    %edi,0xc(%esp)
  800dc1:	8b 44 24 08          	mov    0x8(%esp),%eax
  800dc5:	8b 54 24 0c          	mov    0xc(%esp),%edx
  800dc9:	83 c4 14             	add    $0x14,%esp
  800dcc:	5e                   	pop    %esi
  800dcd:	5f                   	pop    %edi
  800dce:	5d                   	pop    %ebp
  800dcf:	c3                   	ret    
  800dd0:	85 f6                	test   %esi,%esi
  800dd2:	89 f5                	mov    %esi,%ebp
  800dd4:	75 0b                	jne    800de1 <__umoddi3+0x91>
  800dd6:	b8 01 00 00 00       	mov    $0x1,%eax
  800ddb:	31 d2                	xor    %edx,%edx
  800ddd:	f7 f6                	div    %esi
  800ddf:	89 c5                	mov    %eax,%ebp
  800de1:	8b 44 24 04          	mov    0x4(%esp),%eax
  800de5:	31 d2                	xor    %edx,%edx
  800de7:	f7 f5                	div    %ebp
  800de9:	89 c8                	mov    %ecx,%eax
  800deb:	f7 f5                	div    %ebp
  800ded:	eb 9c                	jmp    800d8b <__umoddi3+0x3b>
  800def:	90                   	nop
  800df0:	89 c8                	mov    %ecx,%eax
  800df2:	89 fa                	mov    %edi,%edx
  800df4:	83 c4 14             	add    $0x14,%esp
  800df7:	5e                   	pop    %esi
  800df8:	5f                   	pop    %edi
  800df9:	5d                   	pop    %ebp
  800dfa:	c3                   	ret    
  800dfb:	90                   	nop
  800dfc:	8d 74 26 00          	lea    0x0(%esi,%eiz,1),%esi
  800e00:	8b 04 24             	mov    (%esp),%eax
  800e03:	be 20 00 00 00       	mov    $0x20,%esi
  800e08:	89 e9                	mov    %ebp,%ecx
  800e0a:	29 ee                	sub    %ebp,%esi
  800e0c:	d3 e2                	shl    %cl,%edx
  800e0e:	89 f1                	mov    %esi,%ecx
  800e10:	d3 e8                	shr    %cl,%eax
  800e12:	89 e9                	mov    %ebp,%ecx
  800e14:	89 44 24 04          	mov    %eax,0x4(%esp)
  800e18:	8b 04 24             	mov    (%esp),%eax
  800e1b:	09 54 24 04          	or     %edx,0x4(%esp)
  800e1f:	89 fa                	mov    %edi,%edx
  800e21:	d3 e0                	shl    %cl,%eax
  800e23:	89 f1                	mov    %esi,%ecx
  800e25:	89 44 24 08          	mov    %eax,0x8(%esp)
  800e29:	8b 44 24 10          	mov    0x10(%esp),%eax
  800e2d:	d3 ea                	shr    %cl,%edx
  800e2f:	89 e9                	mov    %ebp,%ecx
  800e31:	d3 e7                	shl    %cl,%edi
  800e33:	89 f1                	mov    %esi,%ecx
  800e35:	d3 e8                	shr    %cl,%eax
  800e37:	89 e9                	mov    %ebp,%ecx
  800e39:	09 f8                	or     %edi,%eax
  800e3b:	8b 7c 24 10          	mov    0x10(%esp),%edi
  800e3f:	f7 74 24 04          	divl   0x4(%esp)
  800e43:	d3 e7                	shl    %cl,%edi
  800e45:	89 7c 24 0c          	mov    %edi,0xc(%esp)
  800e49:	89 d7                	mov    %edx,%edi
  800e4b:	f7 64 24 08          	mull   0x8(%esp)
  800e4f:	39 d7                	cmp    %edx,%edi
  800e51:	89 c1                	mov    %eax,%ecx
  800e53:	89 14 24             	mov    %edx,(%esp)
  800e56:	72 2c                	jb     800e84 <__umoddi3+0x134>
  800e58:	39 44 24 0c          	cmp    %eax,0xc(%esp)
  800e5c:	72 22                	jb     800e80 <__umoddi3+0x130>
  800e5e:	8b 44 24 0c          	mov    0xc(%esp),%eax
  800e62:	29 c8                	sub    %ecx,%eax
  800e64:	19 d7                	sbb    %edx,%edi
  800e66:	89 e9                	mov    %ebp,%ecx
  800e68:	89 fa                	mov    %edi,%edx
  800e6a:	d3 e8                	shr    %cl,%eax
  800e6c:	89 f1                	mov    %esi,%ecx
  800e6e:	d3 e2                	shl    %cl,%edx
  800e70:	89 e9                	mov    %ebp,%ecx
  800e72:	d3 ef                	shr    %cl,%edi
  800e74:	09 d0                	or     %edx,%eax
  800e76:	89 fa                	mov    %edi,%edx
  800e78:	83 c4 14             	add    $0x14,%esp
  800e7b:	5e                   	pop    %esi
  800e7c:	5f                   	pop    %edi
  800e7d:	5d                   	pop    %ebp
  800e7e:	c3                   	ret    
  800e7f:	90                   	nop
  800e80:	39 d7                	cmp    %edx,%edi
  800e82:	75 da                	jne    800e5e <__umoddi3+0x10e>
  800e84:	8b 14 24             	mov    (%esp),%edx
  800e87:	89 c1                	mov    %eax,%ecx
  800e89:	2b 4c 24 08          	sub    0x8(%esp),%ecx
  800e8d:	1b 54 24 04          	sbb    0x4(%esp),%edx
  800e91:	eb cb                	jmp    800e5e <__umoddi3+0x10e>
  800e93:	90                   	nop
  800e94:	8d 74 26 00          	lea    0x0(%esi,%eiz,1),%esi
  800e98:	3b 44 24 0c          	cmp    0xc(%esp),%eax
  800e9c:	0f 82 0f ff ff ff    	jb     800db1 <__umoddi3+0x61>
  800ea2:	e9 1a ff ff ff       	jmp    800dc1 <__umoddi3+0x71>
