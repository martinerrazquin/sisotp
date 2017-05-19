
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
  80003e:	ff 35 00 10 80 00    	pushl  0x801000
  800044:	e8 97 00 00 00       	call   8000e0 <sys_cputs>
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
  800051:	83 ec 08             	sub    $0x8,%esp
  800054:	8b 45 08             	mov    0x8(%ebp),%eax
  800057:	8b 55 0c             	mov    0xc(%ebp),%edx
	// set thisenv to point at our Env structure in envs[].
	// LAB 3: Your code here.
	thisenv = 0;
  80005a:	c7 05 08 10 80 00 00 	movl   $0x0,0x801008
  800061:	00 00 00 

	// save the name of the program so that panic() can use it
	if (argc > 0)
  800064:	85 c0                	test   %eax,%eax
  800066:	7e 08                	jle    800070 <libmain+0x22>
		binaryname = argv[0];
  800068:	8b 0a                	mov    (%edx),%ecx
  80006a:	89 0d 04 10 80 00    	mov    %ecx,0x801004

	// call user main routine
	umain(argc, argv);
  800070:	83 ec 08             	sub    $0x8,%esp
  800073:	52                   	push   %edx
  800074:	50                   	push   %eax
  800075:	e8 b9 ff ff ff       	call   800033 <umain>

	// exit gracefully
	exit();
  80007a:	e8 05 00 00 00       	call   800084 <exit>
}
  80007f:	83 c4 10             	add    $0x10,%esp
  800082:	c9                   	leave  
  800083:	c3                   	ret    

00800084 <exit>:

#include <inc/lib.h>

void
exit(void)
{
  800084:	55                   	push   %ebp
  800085:	89 e5                	mov    %esp,%ebp
  800087:	83 ec 14             	sub    $0x14,%esp
	sys_env_destroy(0);
  80008a:	6a 00                	push   $0x0
  80008c:	e8 99 00 00 00       	call   80012a <sys_env_destroy>
}
  800091:	83 c4 10             	add    $0x10,%esp
  800094:	c9                   	leave  
  800095:	c3                   	ret    

00800096 <syscall>:
#include <inc/syscall.h>
#include <inc/lib.h>

static inline int32_t
syscall(int num, int check, uint32_t a1, uint32_t a2, uint32_t a3, uint32_t a4, uint32_t a5)
{
  800096:	55                   	push   %ebp
  800097:	89 e5                	mov    %esp,%ebp
  800099:	57                   	push   %edi
  80009a:	56                   	push   %esi
  80009b:	53                   	push   %ebx
  80009c:	83 ec 1c             	sub    $0x1c,%esp
  80009f:	89 45 e0             	mov    %eax,-0x20(%ebp)
  8000a2:	89 55 e4             	mov    %edx,-0x1c(%ebp)
  8000a5:	89 ca                	mov    %ecx,%edx
	//
	// The last clause tells the assembler that this can
	// potentially change the condition codes and arbitrary
	// memory locations.

	asm volatile("int %1\n"
  8000a7:	8b 4d 08             	mov    0x8(%ebp),%ecx
  8000aa:	8b 5d 0c             	mov    0xc(%ebp),%ebx
  8000ad:	8b 7d 10             	mov    0x10(%ebp),%edi
  8000b0:	8b 75 14             	mov    0x14(%ebp),%esi
  8000b3:	cd 30                	int    $0x30
		       "b" (a3),
		       "D" (a4),
		       "S" (a5)
		     : "cc", "memory");

	if(check && ret > 0)
  8000b5:	83 7d e4 00          	cmpl   $0x0,-0x1c(%ebp)
  8000b9:	74 1d                	je     8000d8 <syscall+0x42>
  8000bb:	85 c0                	test   %eax,%eax
  8000bd:	7e 19                	jle    8000d8 <syscall+0x42>
  8000bf:	8b 55 e0             	mov    -0x20(%ebp),%edx
		panic("syscall %d returned %d (> 0)", num, ret);
  8000c2:	83 ec 0c             	sub    $0xc,%esp
  8000c5:	50                   	push   %eax
  8000c6:	52                   	push   %edx
  8000c7:	68 9c 0d 80 00       	push   $0x800d9c
  8000cc:	6a 23                	push   $0x23
  8000ce:	68 b9 0d 80 00       	push   $0x800db9
  8000d3:	e8 98 00 00 00       	call   800170 <_panic>

	return ret;
}
  8000d8:	8d 65 f4             	lea    -0xc(%ebp),%esp
  8000db:	5b                   	pop    %ebx
  8000dc:	5e                   	pop    %esi
  8000dd:	5f                   	pop    %edi
  8000de:	5d                   	pop    %ebp
  8000df:	c3                   	ret    

008000e0 <sys_cputs>:

void
sys_cputs(const char *s, size_t len)
{
  8000e0:	55                   	push   %ebp
  8000e1:	89 e5                	mov    %esp,%ebp
  8000e3:	83 ec 08             	sub    $0x8,%esp
	syscall(SYS_cputs, 0, (uint32_t)s, len, 0, 0, 0);
  8000e6:	6a 00                	push   $0x0
  8000e8:	6a 00                	push   $0x0
  8000ea:	6a 00                	push   $0x0
  8000ec:	ff 75 0c             	pushl  0xc(%ebp)
  8000ef:	8b 4d 08             	mov    0x8(%ebp),%ecx
  8000f2:	ba 00 00 00 00       	mov    $0x0,%edx
  8000f7:	b8 00 00 00 00       	mov    $0x0,%eax
  8000fc:	e8 95 ff ff ff       	call   800096 <syscall>
}
  800101:	83 c4 10             	add    $0x10,%esp
  800104:	c9                   	leave  
  800105:	c3                   	ret    

00800106 <sys_cgetc>:

int
sys_cgetc(void)
{
  800106:	55                   	push   %ebp
  800107:	89 e5                	mov    %esp,%ebp
  800109:	83 ec 08             	sub    $0x8,%esp
	return syscall(SYS_cgetc, 0, 0, 0, 0, 0, 0);
  80010c:	6a 00                	push   $0x0
  80010e:	6a 00                	push   $0x0
  800110:	6a 00                	push   $0x0
  800112:	6a 00                	push   $0x0
  800114:	b9 00 00 00 00       	mov    $0x0,%ecx
  800119:	ba 00 00 00 00       	mov    $0x0,%edx
  80011e:	b8 01 00 00 00       	mov    $0x1,%eax
  800123:	e8 6e ff ff ff       	call   800096 <syscall>
}
  800128:	c9                   	leave  
  800129:	c3                   	ret    

0080012a <sys_env_destroy>:

int
sys_env_destroy(envid_t envid)
{
  80012a:	55                   	push   %ebp
  80012b:	89 e5                	mov    %esp,%ebp
  80012d:	83 ec 08             	sub    $0x8,%esp
	return syscall(SYS_env_destroy, 1, envid, 0, 0, 0, 0);
  800130:	6a 00                	push   $0x0
  800132:	6a 00                	push   $0x0
  800134:	6a 00                	push   $0x0
  800136:	6a 00                	push   $0x0
  800138:	8b 4d 08             	mov    0x8(%ebp),%ecx
  80013b:	ba 01 00 00 00       	mov    $0x1,%edx
  800140:	b8 03 00 00 00       	mov    $0x3,%eax
  800145:	e8 4c ff ff ff       	call   800096 <syscall>
}
  80014a:	c9                   	leave  
  80014b:	c3                   	ret    

0080014c <sys_getenvid>:

envid_t
sys_getenvid(void)
{
  80014c:	55                   	push   %ebp
  80014d:	89 e5                	mov    %esp,%ebp
  80014f:	83 ec 08             	sub    $0x8,%esp
	 return syscall(SYS_getenvid, 0, 0, 0, 0, 0, 0);
  800152:	6a 00                	push   $0x0
  800154:	6a 00                	push   $0x0
  800156:	6a 00                	push   $0x0
  800158:	6a 00                	push   $0x0
  80015a:	b9 00 00 00 00       	mov    $0x0,%ecx
  80015f:	ba 00 00 00 00       	mov    $0x0,%edx
  800164:	b8 02 00 00 00       	mov    $0x2,%eax
  800169:	e8 28 ff ff ff       	call   800096 <syscall>
}
  80016e:	c9                   	leave  
  80016f:	c3                   	ret    

00800170 <_panic>:
 * It prints "panic: <message>", then causes a breakpoint exception,
 * which causes JOS to enter the JOS kernel monitor.
 */
void
_panic(const char *file, int line, const char *fmt, ...)
{
  800170:	55                   	push   %ebp
  800171:	89 e5                	mov    %esp,%ebp
  800173:	56                   	push   %esi
  800174:	53                   	push   %ebx
	va_list ap;

	va_start(ap, fmt);
  800175:	8d 5d 14             	lea    0x14(%ebp),%ebx

	// Print the panic message
	cprintf("[%08x] user panic in %s at %s:%d: ",
  800178:	8b 35 04 10 80 00    	mov    0x801004,%esi
  80017e:	e8 c9 ff ff ff       	call   80014c <sys_getenvid>
  800183:	83 ec 0c             	sub    $0xc,%esp
  800186:	ff 75 0c             	pushl  0xc(%ebp)
  800189:	ff 75 08             	pushl  0x8(%ebp)
  80018c:	56                   	push   %esi
  80018d:	50                   	push   %eax
  80018e:	68 c8 0d 80 00       	push   $0x800dc8
  800193:	e8 b1 00 00 00       	call   800249 <cprintf>
		sys_getenvid(), binaryname, file, line);
	vcprintf(fmt, ap);
  800198:	83 c4 18             	add    $0x18,%esp
  80019b:	53                   	push   %ebx
  80019c:	ff 75 10             	pushl  0x10(%ebp)
  80019f:	e8 54 00 00 00       	call   8001f8 <vcprintf>
	cprintf("\n");
  8001a4:	c7 04 24 90 0d 80 00 	movl   $0x800d90,(%esp)
  8001ab:	e8 99 00 00 00       	call   800249 <cprintf>
  8001b0:	83 c4 10             	add    $0x10,%esp

	// Cause a breakpoint exception
	while (1)
		asm volatile("int3");
  8001b3:	cc                   	int3   
  8001b4:	eb fd                	jmp    8001b3 <_panic+0x43>

008001b6 <putch>:
};


static void
putch(int ch, struct printbuf *b)
{
  8001b6:	55                   	push   %ebp
  8001b7:	89 e5                	mov    %esp,%ebp
  8001b9:	53                   	push   %ebx
  8001ba:	83 ec 04             	sub    $0x4,%esp
  8001bd:	8b 5d 0c             	mov    0xc(%ebp),%ebx
	b->buf[b->idx++] = ch;
  8001c0:	8b 13                	mov    (%ebx),%edx
  8001c2:	8d 42 01             	lea    0x1(%edx),%eax
  8001c5:	89 03                	mov    %eax,(%ebx)
  8001c7:	8b 4d 08             	mov    0x8(%ebp),%ecx
  8001ca:	88 4c 13 08          	mov    %cl,0x8(%ebx,%edx,1)
	if (b->idx == 256-1) {
  8001ce:	3d ff 00 00 00       	cmp    $0xff,%eax
  8001d3:	75 1a                	jne    8001ef <putch+0x39>
		sys_cputs(b->buf, b->idx);
  8001d5:	83 ec 08             	sub    $0x8,%esp
  8001d8:	68 ff 00 00 00       	push   $0xff
  8001dd:	8d 43 08             	lea    0x8(%ebx),%eax
  8001e0:	50                   	push   %eax
  8001e1:	e8 fa fe ff ff       	call   8000e0 <sys_cputs>
		b->idx = 0;
  8001e6:	c7 03 00 00 00 00    	movl   $0x0,(%ebx)
  8001ec:	83 c4 10             	add    $0x10,%esp
	}
	b->cnt++;
  8001ef:	83 43 04 01          	addl   $0x1,0x4(%ebx)
}
  8001f3:	8b 5d fc             	mov    -0x4(%ebp),%ebx
  8001f6:	c9                   	leave  
  8001f7:	c3                   	ret    

008001f8 <vcprintf>:

int
vcprintf(const char *fmt, va_list ap)
{
  8001f8:	55                   	push   %ebp
  8001f9:	89 e5                	mov    %esp,%ebp
  8001fb:	81 ec 18 01 00 00    	sub    $0x118,%esp
	struct printbuf b;

	b.idx = 0;
  800201:	c7 85 f0 fe ff ff 00 	movl   $0x0,-0x110(%ebp)
  800208:	00 00 00 
	b.cnt = 0;
  80020b:	c7 85 f4 fe ff ff 00 	movl   $0x0,-0x10c(%ebp)
  800212:	00 00 00 
	vprintfmt((void*)putch, &b, fmt, ap);
  800215:	ff 75 0c             	pushl  0xc(%ebp)
  800218:	ff 75 08             	pushl  0x8(%ebp)
  80021b:	8d 85 f0 fe ff ff    	lea    -0x110(%ebp),%eax
  800221:	50                   	push   %eax
  800222:	68 b6 01 80 00       	push   $0x8001b6
  800227:	e8 86 01 00 00       	call   8003b2 <vprintfmt>
	sys_cputs(b.buf, b.idx);
  80022c:	83 c4 08             	add    $0x8,%esp
  80022f:	ff b5 f0 fe ff ff    	pushl  -0x110(%ebp)
  800235:	8d 85 f8 fe ff ff    	lea    -0x108(%ebp),%eax
  80023b:	50                   	push   %eax
  80023c:	e8 9f fe ff ff       	call   8000e0 <sys_cputs>

	return b.cnt;
}
  800241:	8b 85 f4 fe ff ff    	mov    -0x10c(%ebp),%eax
  800247:	c9                   	leave  
  800248:	c3                   	ret    

00800249 <cprintf>:

int
cprintf(const char *fmt, ...)
{
  800249:	55                   	push   %ebp
  80024a:	89 e5                	mov    %esp,%ebp
  80024c:	83 ec 10             	sub    $0x10,%esp
	va_list ap;
	int cnt;

	va_start(ap, fmt);
  80024f:	8d 45 0c             	lea    0xc(%ebp),%eax
	cnt = vcprintf(fmt, ap);
  800252:	50                   	push   %eax
  800253:	ff 75 08             	pushl  0x8(%ebp)
  800256:	e8 9d ff ff ff       	call   8001f8 <vcprintf>
	va_end(ap);

	return cnt;
}
  80025b:	c9                   	leave  
  80025c:	c3                   	ret    

0080025d <printnum>:
 * using specified putch function and associated pointer putdat.
 */
static void
printnum(void (*putch)(int, void*), void *putdat,
	 unsigned long long num, unsigned base, int width, int padc)
{
  80025d:	55                   	push   %ebp
  80025e:	89 e5                	mov    %esp,%ebp
  800260:	57                   	push   %edi
  800261:	56                   	push   %esi
  800262:	53                   	push   %ebx
  800263:	83 ec 1c             	sub    $0x1c,%esp
  800266:	89 c7                	mov    %eax,%edi
  800268:	89 d6                	mov    %edx,%esi
  80026a:	8b 45 08             	mov    0x8(%ebp),%eax
  80026d:	8b 55 0c             	mov    0xc(%ebp),%edx
  800270:	89 45 d8             	mov    %eax,-0x28(%ebp)
  800273:	89 55 dc             	mov    %edx,-0x24(%ebp)
	// first recursively print all preceding (more significant) digits
	if (num >= base) {
  800276:	8b 4d 10             	mov    0x10(%ebp),%ecx
  800279:	bb 00 00 00 00       	mov    $0x0,%ebx
  80027e:	89 4d e0             	mov    %ecx,-0x20(%ebp)
  800281:	89 5d e4             	mov    %ebx,-0x1c(%ebp)
  800284:	39 d3                	cmp    %edx,%ebx
  800286:	72 05                	jb     80028d <printnum+0x30>
  800288:	39 45 10             	cmp    %eax,0x10(%ebp)
  80028b:	77 45                	ja     8002d2 <printnum+0x75>
		printnum(putch, putdat, num / base, base, width - 1, padc);
  80028d:	83 ec 0c             	sub    $0xc,%esp
  800290:	ff 75 18             	pushl  0x18(%ebp)
  800293:	8b 45 14             	mov    0x14(%ebp),%eax
  800296:	8d 58 ff             	lea    -0x1(%eax),%ebx
  800299:	53                   	push   %ebx
  80029a:	ff 75 10             	pushl  0x10(%ebp)
  80029d:	83 ec 08             	sub    $0x8,%esp
  8002a0:	ff 75 e4             	pushl  -0x1c(%ebp)
  8002a3:	ff 75 e0             	pushl  -0x20(%ebp)
  8002a6:	ff 75 dc             	pushl  -0x24(%ebp)
  8002a9:	ff 75 d8             	pushl  -0x28(%ebp)
  8002ac:	e8 4f 08 00 00       	call   800b00 <__udivdi3>
  8002b1:	83 c4 18             	add    $0x18,%esp
  8002b4:	52                   	push   %edx
  8002b5:	50                   	push   %eax
  8002b6:	89 f2                	mov    %esi,%edx
  8002b8:	89 f8                	mov    %edi,%eax
  8002ba:	e8 9e ff ff ff       	call   80025d <printnum>
  8002bf:	83 c4 20             	add    $0x20,%esp
  8002c2:	eb 18                	jmp    8002dc <printnum+0x7f>
	} else {
		// print any needed pad characters before first digit
		while (--width > 0)
			putch(padc, putdat);
  8002c4:	83 ec 08             	sub    $0x8,%esp
  8002c7:	56                   	push   %esi
  8002c8:	ff 75 18             	pushl  0x18(%ebp)
  8002cb:	ff d7                	call   *%edi
  8002cd:	83 c4 10             	add    $0x10,%esp
  8002d0:	eb 03                	jmp    8002d5 <printnum+0x78>
  8002d2:	8b 5d 14             	mov    0x14(%ebp),%ebx
	// first recursively print all preceding (more significant) digits
	if (num >= base) {
		printnum(putch, putdat, num / base, base, width - 1, padc);
	} else {
		// print any needed pad characters before first digit
		while (--width > 0)
  8002d5:	83 eb 01             	sub    $0x1,%ebx
  8002d8:	85 db                	test   %ebx,%ebx
  8002da:	7f e8                	jg     8002c4 <printnum+0x67>
			putch(padc, putdat);
	}

	// then print this (the least significant) digit
	putch("0123456789abcdef"[num % base], putdat);
  8002dc:	83 ec 08             	sub    $0x8,%esp
  8002df:	56                   	push   %esi
  8002e0:	83 ec 04             	sub    $0x4,%esp
  8002e3:	ff 75 e4             	pushl  -0x1c(%ebp)
  8002e6:	ff 75 e0             	pushl  -0x20(%ebp)
  8002e9:	ff 75 dc             	pushl  -0x24(%ebp)
  8002ec:	ff 75 d8             	pushl  -0x28(%ebp)
  8002ef:	e8 3c 09 00 00       	call   800c30 <__umoddi3>
  8002f4:	83 c4 14             	add    $0x14,%esp
  8002f7:	0f be 80 ec 0d 80 00 	movsbl 0x800dec(%eax),%eax
  8002fe:	50                   	push   %eax
  8002ff:	ff d7                	call   *%edi
}
  800301:	83 c4 10             	add    $0x10,%esp
  800304:	8d 65 f4             	lea    -0xc(%ebp),%esp
  800307:	5b                   	pop    %ebx
  800308:	5e                   	pop    %esi
  800309:	5f                   	pop    %edi
  80030a:	5d                   	pop    %ebp
  80030b:	c3                   	ret    

0080030c <getuint>:

// Get an unsigned int of various possible sizes from a varargs list,
// depending on the lflag parameter.
static unsigned long long
getuint(va_list *ap, int lflag)
{
  80030c:	55                   	push   %ebp
  80030d:	89 e5                	mov    %esp,%ebp
	if (lflag >= 2)
  80030f:	83 fa 01             	cmp    $0x1,%edx
  800312:	7e 0e                	jle    800322 <getuint+0x16>
		return va_arg(*ap, unsigned long long);
  800314:	8b 10                	mov    (%eax),%edx
  800316:	8d 4a 08             	lea    0x8(%edx),%ecx
  800319:	89 08                	mov    %ecx,(%eax)
  80031b:	8b 02                	mov    (%edx),%eax
  80031d:	8b 52 04             	mov    0x4(%edx),%edx
  800320:	eb 22                	jmp    800344 <getuint+0x38>
	else if (lflag)
  800322:	85 d2                	test   %edx,%edx
  800324:	74 10                	je     800336 <getuint+0x2a>
		return va_arg(*ap, unsigned long);
  800326:	8b 10                	mov    (%eax),%edx
  800328:	8d 4a 04             	lea    0x4(%edx),%ecx
  80032b:	89 08                	mov    %ecx,(%eax)
  80032d:	8b 02                	mov    (%edx),%eax
  80032f:	ba 00 00 00 00       	mov    $0x0,%edx
  800334:	eb 0e                	jmp    800344 <getuint+0x38>
	else
		return va_arg(*ap, unsigned int);
  800336:	8b 10                	mov    (%eax),%edx
  800338:	8d 4a 04             	lea    0x4(%edx),%ecx
  80033b:	89 08                	mov    %ecx,(%eax)
  80033d:	8b 02                	mov    (%edx),%eax
  80033f:	ba 00 00 00 00       	mov    $0x0,%edx
}
  800344:	5d                   	pop    %ebp
  800345:	c3                   	ret    

00800346 <getint>:

// Same as getuint but signed - can't use getuint
// because of sign extension
static long long
getint(va_list *ap, int lflag)
{
  800346:	55                   	push   %ebp
  800347:	89 e5                	mov    %esp,%ebp
	if (lflag >= 2)
  800349:	83 fa 01             	cmp    $0x1,%edx
  80034c:	7e 0e                	jle    80035c <getint+0x16>
		return va_arg(*ap, long long);
  80034e:	8b 10                	mov    (%eax),%edx
  800350:	8d 4a 08             	lea    0x8(%edx),%ecx
  800353:	89 08                	mov    %ecx,(%eax)
  800355:	8b 02                	mov    (%edx),%eax
  800357:	8b 52 04             	mov    0x4(%edx),%edx
  80035a:	eb 1a                	jmp    800376 <getint+0x30>
	else if (lflag)
  80035c:	85 d2                	test   %edx,%edx
  80035e:	74 0c                	je     80036c <getint+0x26>
		return va_arg(*ap, long);
  800360:	8b 10                	mov    (%eax),%edx
  800362:	8d 4a 04             	lea    0x4(%edx),%ecx
  800365:	89 08                	mov    %ecx,(%eax)
  800367:	8b 02                	mov    (%edx),%eax
  800369:	99                   	cltd   
  80036a:	eb 0a                	jmp    800376 <getint+0x30>
	else
		return va_arg(*ap, int);
  80036c:	8b 10                	mov    (%eax),%edx
  80036e:	8d 4a 04             	lea    0x4(%edx),%ecx
  800371:	89 08                	mov    %ecx,(%eax)
  800373:	8b 02                	mov    (%edx),%eax
  800375:	99                   	cltd   
}
  800376:	5d                   	pop    %ebp
  800377:	c3                   	ret    

00800378 <sprintputch>:
	int cnt;
};

static void
sprintputch(int ch, struct sprintbuf *b)
{
  800378:	55                   	push   %ebp
  800379:	89 e5                	mov    %esp,%ebp
  80037b:	8b 45 0c             	mov    0xc(%ebp),%eax
	b->cnt++;
  80037e:	83 40 08 01          	addl   $0x1,0x8(%eax)
	if (b->buf < b->ebuf)
  800382:	8b 10                	mov    (%eax),%edx
  800384:	3b 50 04             	cmp    0x4(%eax),%edx
  800387:	73 0a                	jae    800393 <sprintputch+0x1b>
		*b->buf++ = ch;
  800389:	8d 4a 01             	lea    0x1(%edx),%ecx
  80038c:	89 08                	mov    %ecx,(%eax)
  80038e:	8b 45 08             	mov    0x8(%ebp),%eax
  800391:	88 02                	mov    %al,(%edx)
}
  800393:	5d                   	pop    %ebp
  800394:	c3                   	ret    

00800395 <printfmt>:
	}
}

void
printfmt(void (*putch)(int, void*), void *putdat, const char *fmt, ...)
{
  800395:	55                   	push   %ebp
  800396:	89 e5                	mov    %esp,%ebp
  800398:	83 ec 08             	sub    $0x8,%esp
	va_list ap;

	va_start(ap, fmt);
  80039b:	8d 45 14             	lea    0x14(%ebp),%eax
	vprintfmt(putch, putdat, fmt, ap);
  80039e:	50                   	push   %eax
  80039f:	ff 75 10             	pushl  0x10(%ebp)
  8003a2:	ff 75 0c             	pushl  0xc(%ebp)
  8003a5:	ff 75 08             	pushl  0x8(%ebp)
  8003a8:	e8 05 00 00 00       	call   8003b2 <vprintfmt>
	va_end(ap);
}
  8003ad:	83 c4 10             	add    $0x10,%esp
  8003b0:	c9                   	leave  
  8003b1:	c3                   	ret    

008003b2 <vprintfmt>:
// Main function to format and print a string.
void printfmt(void (*putch)(int, void*), void *putdat, const char *fmt, ...);

void
vprintfmt(void (*putch)(int, void*), void *putdat, const char *fmt, va_list ap)
{
  8003b2:	55                   	push   %ebp
  8003b3:	89 e5                	mov    %esp,%ebp
  8003b5:	57                   	push   %edi
  8003b6:	56                   	push   %esi
  8003b7:	53                   	push   %ebx
  8003b8:	83 ec 2c             	sub    $0x2c,%esp
  8003bb:	8b 75 08             	mov    0x8(%ebp),%esi
  8003be:	8b 5d 0c             	mov    0xc(%ebp),%ebx
  8003c1:	8b 7d 10             	mov    0x10(%ebp),%edi
  8003c4:	eb 12                	jmp    8003d8 <vprintfmt+0x26>
	int base, lflag, width, precision, altflag;
	char padc;

	while (1) {
		while ((ch = *(unsigned char *) fmt++) != '%') {
			if (ch == '\0')
  8003c6:	85 c0                	test   %eax,%eax
  8003c8:	0f 84 44 03 00 00    	je     800712 <vprintfmt+0x360>
				return;
			putch(ch, putdat);
  8003ce:	83 ec 08             	sub    $0x8,%esp
  8003d1:	53                   	push   %ebx
  8003d2:	50                   	push   %eax
  8003d3:	ff d6                	call   *%esi
  8003d5:	83 c4 10             	add    $0x10,%esp
	unsigned long long num;
	int base, lflag, width, precision, altflag;
	char padc;

	while (1) {
		while ((ch = *(unsigned char *) fmt++) != '%') {
  8003d8:	83 c7 01             	add    $0x1,%edi
  8003db:	0f b6 47 ff          	movzbl -0x1(%edi),%eax
  8003df:	83 f8 25             	cmp    $0x25,%eax
  8003e2:	75 e2                	jne    8003c6 <vprintfmt+0x14>
  8003e4:	c6 45 d4 20          	movb   $0x20,-0x2c(%ebp)
  8003e8:	c7 45 d8 00 00 00 00 	movl   $0x0,-0x28(%ebp)
  8003ef:	c7 45 d0 ff ff ff ff 	movl   $0xffffffff,-0x30(%ebp)
  8003f6:	c7 45 e0 ff ff ff ff 	movl   $0xffffffff,-0x20(%ebp)
  8003fd:	ba 00 00 00 00       	mov    $0x0,%edx
  800402:	eb 07                	jmp    80040b <vprintfmt+0x59>
		width = -1;
		precision = -1;
		lflag = 0;
		altflag = 0;
	reswitch:
		switch (ch = *(unsigned char *) fmt++) {
  800404:	8b 7d e4             	mov    -0x1c(%ebp),%edi

		// flag to pad on the right
		case '-':
			padc = '-';
  800407:	c6 45 d4 2d          	movb   $0x2d,-0x2c(%ebp)
		width = -1;
		precision = -1;
		lflag = 0;
		altflag = 0;
	reswitch:
		switch (ch = *(unsigned char *) fmt++) {
  80040b:	8d 47 01             	lea    0x1(%edi),%eax
  80040e:	89 45 e4             	mov    %eax,-0x1c(%ebp)
  800411:	0f b6 07             	movzbl (%edi),%eax
  800414:	0f b6 c8             	movzbl %al,%ecx
  800417:	83 e8 23             	sub    $0x23,%eax
  80041a:	3c 55                	cmp    $0x55,%al
  80041c:	0f 87 d5 02 00 00    	ja     8006f7 <vprintfmt+0x345>
  800422:	0f b6 c0             	movzbl %al,%eax
  800425:	ff 24 85 7c 0e 80 00 	jmp    *0x800e7c(,%eax,4)
  80042c:	8b 7d e4             	mov    -0x1c(%ebp),%edi
			padc = '-';
			goto reswitch;

		// flag to pad with 0's instead of spaces
		case '0':
			padc = '0';
  80042f:	c6 45 d4 30          	movb   $0x30,-0x2c(%ebp)
  800433:	eb d6                	jmp    80040b <vprintfmt+0x59>
		width = -1;
		precision = -1;
		lflag = 0;
		altflag = 0;
	reswitch:
		switch (ch = *(unsigned char *) fmt++) {
  800435:	8b 7d e4             	mov    -0x1c(%ebp),%edi
  800438:	b8 00 00 00 00       	mov    $0x0,%eax
  80043d:	89 55 e4             	mov    %edx,-0x1c(%ebp)
		case '6':
		case '7':
		case '8':
		case '9':
			for (precision = 0; ; ++fmt) {
				precision = precision * 10 + ch - '0';
  800440:	8d 04 80             	lea    (%eax,%eax,4),%eax
  800443:	8d 44 41 d0          	lea    -0x30(%ecx,%eax,2),%eax
				ch = *fmt;
  800447:	0f be 0f             	movsbl (%edi),%ecx
				if (ch < '0' || ch > '9')
  80044a:	8d 51 d0             	lea    -0x30(%ecx),%edx
  80044d:	83 fa 09             	cmp    $0x9,%edx
  800450:	77 39                	ja     80048b <vprintfmt+0xd9>
		case '5':
		case '6':
		case '7':
		case '8':
		case '9':
			for (precision = 0; ; ++fmt) {
  800452:	83 c7 01             	add    $0x1,%edi
				precision = precision * 10 + ch - '0';
				ch = *fmt;
				if (ch < '0' || ch > '9')
					break;
			}
  800455:	eb e9                	jmp    800440 <vprintfmt+0x8e>
			goto process_precision;

		case '*':
			precision = va_arg(ap, int);
  800457:	8b 45 14             	mov    0x14(%ebp),%eax
  80045a:	8d 48 04             	lea    0x4(%eax),%ecx
  80045d:	89 4d 14             	mov    %ecx,0x14(%ebp)
  800460:	8b 00                	mov    (%eax),%eax
  800462:	89 45 d0             	mov    %eax,-0x30(%ebp)
		width = -1;
		precision = -1;
		lflag = 0;
		altflag = 0;
	reswitch:
		switch (ch = *(unsigned char *) fmt++) {
  800465:	8b 7d e4             	mov    -0x1c(%ebp),%edi
			}
			goto process_precision;

		case '*':
			precision = va_arg(ap, int);
			goto process_precision;
  800468:	eb 27                	jmp    800491 <vprintfmt+0xdf>
  80046a:	8b 45 e0             	mov    -0x20(%ebp),%eax
  80046d:	85 c0                	test   %eax,%eax
  80046f:	b9 00 00 00 00       	mov    $0x0,%ecx
  800474:	0f 49 c8             	cmovns %eax,%ecx
  800477:	89 4d e0             	mov    %ecx,-0x20(%ebp)
		width = -1;
		precision = -1;
		lflag = 0;
		altflag = 0;
	reswitch:
		switch (ch = *(unsigned char *) fmt++) {
  80047a:	8b 7d e4             	mov    -0x1c(%ebp),%edi
  80047d:	eb 8c                	jmp    80040b <vprintfmt+0x59>
  80047f:	8b 7d e4             	mov    -0x1c(%ebp),%edi
			if (width < 0)
				width = 0;
			goto reswitch;

		case '#':
			altflag = 1;
  800482:	c7 45 d8 01 00 00 00 	movl   $0x1,-0x28(%ebp)
			goto reswitch;
  800489:	eb 80                	jmp    80040b <vprintfmt+0x59>
  80048b:	8b 55 e4             	mov    -0x1c(%ebp),%edx
  80048e:	89 45 d0             	mov    %eax,-0x30(%ebp)

		process_precision:
			if (width < 0)
  800491:	83 7d e0 00          	cmpl   $0x0,-0x20(%ebp)
  800495:	0f 89 70 ff ff ff    	jns    80040b <vprintfmt+0x59>
				width = precision, precision = -1;
  80049b:	8b 45 d0             	mov    -0x30(%ebp),%eax
  80049e:	89 45 e0             	mov    %eax,-0x20(%ebp)
  8004a1:	c7 45 d0 ff ff ff ff 	movl   $0xffffffff,-0x30(%ebp)
  8004a8:	e9 5e ff ff ff       	jmp    80040b <vprintfmt+0x59>
			goto reswitch;

		// long flag (doubled for long long)
		case 'l':
			lflag++;
  8004ad:	83 c2 01             	add    $0x1,%edx
		width = -1;
		precision = -1;
		lflag = 0;
		altflag = 0;
	reswitch:
		switch (ch = *(unsigned char *) fmt++) {
  8004b0:	8b 7d e4             	mov    -0x1c(%ebp),%edi
			goto reswitch;

		// long flag (doubled for long long)
		case 'l':
			lflag++;
			goto reswitch;
  8004b3:	e9 53 ff ff ff       	jmp    80040b <vprintfmt+0x59>

		// character
		case 'c':
			putch(va_arg(ap, int), putdat);
  8004b8:	8b 45 14             	mov    0x14(%ebp),%eax
  8004bb:	8d 50 04             	lea    0x4(%eax),%edx
  8004be:	89 55 14             	mov    %edx,0x14(%ebp)
  8004c1:	83 ec 08             	sub    $0x8,%esp
  8004c4:	53                   	push   %ebx
  8004c5:	ff 30                	pushl  (%eax)
  8004c7:	ff d6                	call   *%esi
			break;
  8004c9:	83 c4 10             	add    $0x10,%esp
		width = -1;
		precision = -1;
		lflag = 0;
		altflag = 0;
	reswitch:
		switch (ch = *(unsigned char *) fmt++) {
  8004cc:	8b 7d e4             	mov    -0x1c(%ebp),%edi
			goto reswitch;

		// character
		case 'c':
			putch(va_arg(ap, int), putdat);
			break;
  8004cf:	e9 04 ff ff ff       	jmp    8003d8 <vprintfmt+0x26>

		// error message
		case 'e':
			err = va_arg(ap, int);
  8004d4:	8b 45 14             	mov    0x14(%ebp),%eax
  8004d7:	8d 50 04             	lea    0x4(%eax),%edx
  8004da:	89 55 14             	mov    %edx,0x14(%ebp)
  8004dd:	8b 00                	mov    (%eax),%eax
  8004df:	99                   	cltd   
  8004e0:	31 d0                	xor    %edx,%eax
  8004e2:	29 d0                	sub    %edx,%eax
			if (err < 0)
				err = -err;
			if (err >= MAXERROR || (p = error_string[err]) == NULL)
  8004e4:	83 f8 06             	cmp    $0x6,%eax
  8004e7:	7f 0b                	jg     8004f4 <vprintfmt+0x142>
  8004e9:	8b 14 85 d4 0f 80 00 	mov    0x800fd4(,%eax,4),%edx
  8004f0:	85 d2                	test   %edx,%edx
  8004f2:	75 18                	jne    80050c <vprintfmt+0x15a>
				printfmt(putch, putdat, "error %d", err);
  8004f4:	50                   	push   %eax
  8004f5:	68 04 0e 80 00       	push   $0x800e04
  8004fa:	53                   	push   %ebx
  8004fb:	56                   	push   %esi
  8004fc:	e8 94 fe ff ff       	call   800395 <printfmt>
  800501:	83 c4 10             	add    $0x10,%esp
		width = -1;
		precision = -1;
		lflag = 0;
		altflag = 0;
	reswitch:
		switch (ch = *(unsigned char *) fmt++) {
  800504:	8b 7d e4             	mov    -0x1c(%ebp),%edi
		case 'e':
			err = va_arg(ap, int);
			if (err < 0)
				err = -err;
			if (err >= MAXERROR || (p = error_string[err]) == NULL)
				printfmt(putch, putdat, "error %d", err);
  800507:	e9 cc fe ff ff       	jmp    8003d8 <vprintfmt+0x26>
			else
				printfmt(putch, putdat, "%s", p);
  80050c:	52                   	push   %edx
  80050d:	68 0d 0e 80 00       	push   $0x800e0d
  800512:	53                   	push   %ebx
  800513:	56                   	push   %esi
  800514:	e8 7c fe ff ff       	call   800395 <printfmt>
  800519:	83 c4 10             	add    $0x10,%esp
		width = -1;
		precision = -1;
		lflag = 0;
		altflag = 0;
	reswitch:
		switch (ch = *(unsigned char *) fmt++) {
  80051c:	8b 7d e4             	mov    -0x1c(%ebp),%edi
  80051f:	e9 b4 fe ff ff       	jmp    8003d8 <vprintfmt+0x26>
				printfmt(putch, putdat, "%s", p);
			break;

		// string
		case 's':
			if ((p = va_arg(ap, char *)) == NULL)
  800524:	8b 45 14             	mov    0x14(%ebp),%eax
  800527:	8d 50 04             	lea    0x4(%eax),%edx
  80052a:	89 55 14             	mov    %edx,0x14(%ebp)
  80052d:	8b 38                	mov    (%eax),%edi
				p = "(null)";
  80052f:	85 ff                	test   %edi,%edi
  800531:	b8 fd 0d 80 00       	mov    $0x800dfd,%eax
  800536:	0f 44 f8             	cmove  %eax,%edi
			if (width > 0 && padc != '-')
  800539:	83 7d e0 00          	cmpl   $0x0,-0x20(%ebp)
  80053d:	0f 8e 94 00 00 00    	jle    8005d7 <vprintfmt+0x225>
  800543:	80 7d d4 2d          	cmpb   $0x2d,-0x2c(%ebp)
  800547:	0f 84 98 00 00 00    	je     8005e5 <vprintfmt+0x233>
				for (width -= strnlen(p, precision); width > 0; width--)
  80054d:	83 ec 08             	sub    $0x8,%esp
  800550:	ff 75 d0             	pushl  -0x30(%ebp)
  800553:	57                   	push   %edi
  800554:	e8 41 02 00 00       	call   80079a <strnlen>
  800559:	8b 4d e0             	mov    -0x20(%ebp),%ecx
  80055c:	29 c1                	sub    %eax,%ecx
  80055e:	89 4d cc             	mov    %ecx,-0x34(%ebp)
  800561:	83 c4 10             	add    $0x10,%esp
					putch(padc, putdat);
  800564:	0f be 45 d4          	movsbl -0x2c(%ebp),%eax
  800568:	89 45 e0             	mov    %eax,-0x20(%ebp)
  80056b:	89 7d d4             	mov    %edi,-0x2c(%ebp)
  80056e:	89 cf                	mov    %ecx,%edi
		// string
		case 's':
			if ((p = va_arg(ap, char *)) == NULL)
				p = "(null)";
			if (width > 0 && padc != '-')
				for (width -= strnlen(p, precision); width > 0; width--)
  800570:	eb 0f                	jmp    800581 <vprintfmt+0x1cf>
					putch(padc, putdat);
  800572:	83 ec 08             	sub    $0x8,%esp
  800575:	53                   	push   %ebx
  800576:	ff 75 e0             	pushl  -0x20(%ebp)
  800579:	ff d6                	call   *%esi
		// string
		case 's':
			if ((p = va_arg(ap, char *)) == NULL)
				p = "(null)";
			if (width > 0 && padc != '-')
				for (width -= strnlen(p, precision); width > 0; width--)
  80057b:	83 ef 01             	sub    $0x1,%edi
  80057e:	83 c4 10             	add    $0x10,%esp
  800581:	85 ff                	test   %edi,%edi
  800583:	7f ed                	jg     800572 <vprintfmt+0x1c0>
  800585:	8b 7d d4             	mov    -0x2c(%ebp),%edi
  800588:	8b 4d cc             	mov    -0x34(%ebp),%ecx
  80058b:	85 c9                	test   %ecx,%ecx
  80058d:	b8 00 00 00 00       	mov    $0x0,%eax
  800592:	0f 49 c1             	cmovns %ecx,%eax
  800595:	29 c1                	sub    %eax,%ecx
  800597:	89 75 08             	mov    %esi,0x8(%ebp)
  80059a:	8b 75 d0             	mov    -0x30(%ebp),%esi
  80059d:	89 5d 0c             	mov    %ebx,0xc(%ebp)
  8005a0:	89 cb                	mov    %ecx,%ebx
  8005a2:	eb 4d                	jmp    8005f1 <vprintfmt+0x23f>
					putch(padc, putdat);
			for (; (ch = *p++) != '\0' && (precision < 0 || --precision >= 0); width--)
				if (altflag && (ch < ' ' || ch > '~'))
  8005a4:	83 7d d8 00          	cmpl   $0x0,-0x28(%ebp)
  8005a8:	74 1b                	je     8005c5 <vprintfmt+0x213>
  8005aa:	0f be c0             	movsbl %al,%eax
  8005ad:	83 e8 20             	sub    $0x20,%eax
  8005b0:	83 f8 5e             	cmp    $0x5e,%eax
  8005b3:	76 10                	jbe    8005c5 <vprintfmt+0x213>
					putch('?', putdat);
  8005b5:	83 ec 08             	sub    $0x8,%esp
  8005b8:	ff 75 0c             	pushl  0xc(%ebp)
  8005bb:	6a 3f                	push   $0x3f
  8005bd:	ff 55 08             	call   *0x8(%ebp)
  8005c0:	83 c4 10             	add    $0x10,%esp
  8005c3:	eb 0d                	jmp    8005d2 <vprintfmt+0x220>
				else
					putch(ch, putdat);
  8005c5:	83 ec 08             	sub    $0x8,%esp
  8005c8:	ff 75 0c             	pushl  0xc(%ebp)
  8005cb:	52                   	push   %edx
  8005cc:	ff 55 08             	call   *0x8(%ebp)
  8005cf:	83 c4 10             	add    $0x10,%esp
			if ((p = va_arg(ap, char *)) == NULL)
				p = "(null)";
			if (width > 0 && padc != '-')
				for (width -= strnlen(p, precision); width > 0; width--)
					putch(padc, putdat);
			for (; (ch = *p++) != '\0' && (precision < 0 || --precision >= 0); width--)
  8005d2:	83 eb 01             	sub    $0x1,%ebx
  8005d5:	eb 1a                	jmp    8005f1 <vprintfmt+0x23f>
  8005d7:	89 75 08             	mov    %esi,0x8(%ebp)
  8005da:	8b 75 d0             	mov    -0x30(%ebp),%esi
  8005dd:	89 5d 0c             	mov    %ebx,0xc(%ebp)
  8005e0:	8b 5d e0             	mov    -0x20(%ebp),%ebx
  8005e3:	eb 0c                	jmp    8005f1 <vprintfmt+0x23f>
  8005e5:	89 75 08             	mov    %esi,0x8(%ebp)
  8005e8:	8b 75 d0             	mov    -0x30(%ebp),%esi
  8005eb:	89 5d 0c             	mov    %ebx,0xc(%ebp)
  8005ee:	8b 5d e0             	mov    -0x20(%ebp),%ebx
  8005f1:	83 c7 01             	add    $0x1,%edi
  8005f4:	0f b6 47 ff          	movzbl -0x1(%edi),%eax
  8005f8:	0f be d0             	movsbl %al,%edx
  8005fb:	85 d2                	test   %edx,%edx
  8005fd:	74 23                	je     800622 <vprintfmt+0x270>
  8005ff:	85 f6                	test   %esi,%esi
  800601:	78 a1                	js     8005a4 <vprintfmt+0x1f2>
  800603:	83 ee 01             	sub    $0x1,%esi
  800606:	79 9c                	jns    8005a4 <vprintfmt+0x1f2>
  800608:	89 df                	mov    %ebx,%edi
  80060a:	8b 75 08             	mov    0x8(%ebp),%esi
  80060d:	8b 5d 0c             	mov    0xc(%ebp),%ebx
  800610:	eb 18                	jmp    80062a <vprintfmt+0x278>
				if (altflag && (ch < ' ' || ch > '~'))
					putch('?', putdat);
				else
					putch(ch, putdat);
			for (; width > 0; width--)
				putch(' ', putdat);
  800612:	83 ec 08             	sub    $0x8,%esp
  800615:	53                   	push   %ebx
  800616:	6a 20                	push   $0x20
  800618:	ff d6                	call   *%esi
			for (; (ch = *p++) != '\0' && (precision < 0 || --precision >= 0); width--)
				if (altflag && (ch < ' ' || ch > '~'))
					putch('?', putdat);
				else
					putch(ch, putdat);
			for (; width > 0; width--)
  80061a:	83 ef 01             	sub    $0x1,%edi
  80061d:	83 c4 10             	add    $0x10,%esp
  800620:	eb 08                	jmp    80062a <vprintfmt+0x278>
  800622:	89 df                	mov    %ebx,%edi
  800624:	8b 75 08             	mov    0x8(%ebp),%esi
  800627:	8b 5d 0c             	mov    0xc(%ebp),%ebx
  80062a:	85 ff                	test   %edi,%edi
  80062c:	7f e4                	jg     800612 <vprintfmt+0x260>
		width = -1;
		precision = -1;
		lflag = 0;
		altflag = 0;
	reswitch:
		switch (ch = *(unsigned char *) fmt++) {
  80062e:	8b 7d e4             	mov    -0x1c(%ebp),%edi
  800631:	e9 a2 fd ff ff       	jmp    8003d8 <vprintfmt+0x26>
				putch(' ', putdat);
			break;

		// (signed) decimal
		case 'd':
			num = getint(&ap, lflag);
  800636:	8d 45 14             	lea    0x14(%ebp),%eax
  800639:	e8 08 fd ff ff       	call   800346 <getint>
  80063e:	89 45 d8             	mov    %eax,-0x28(%ebp)
  800641:	89 55 dc             	mov    %edx,-0x24(%ebp)
			if ((long long) num < 0) {
				putch('-', putdat);
				num = -(long long) num;
			}
			base = 10;
  800644:	b9 0a 00 00 00       	mov    $0xa,%ecx
			break;

		// (signed) decimal
		case 'd':
			num = getint(&ap, lflag);
			if ((long long) num < 0) {
  800649:	83 7d dc 00          	cmpl   $0x0,-0x24(%ebp)
  80064d:	79 74                	jns    8006c3 <vprintfmt+0x311>
				putch('-', putdat);
  80064f:	83 ec 08             	sub    $0x8,%esp
  800652:	53                   	push   %ebx
  800653:	6a 2d                	push   $0x2d
  800655:	ff d6                	call   *%esi
				num = -(long long) num;
  800657:	8b 45 d8             	mov    -0x28(%ebp),%eax
  80065a:	8b 55 dc             	mov    -0x24(%ebp),%edx
  80065d:	f7 d8                	neg    %eax
  80065f:	83 d2 00             	adc    $0x0,%edx
  800662:	f7 da                	neg    %edx
  800664:	83 c4 10             	add    $0x10,%esp
			}
			base = 10;
  800667:	b9 0a 00 00 00       	mov    $0xa,%ecx
  80066c:	eb 55                	jmp    8006c3 <vprintfmt+0x311>
			goto number;

		// unsigned decimal
		case 'u':
			num = getuint(&ap, lflag);
  80066e:	8d 45 14             	lea    0x14(%ebp),%eax
  800671:	e8 96 fc ff ff       	call   80030c <getuint>
			base = 10;
  800676:	b9 0a 00 00 00       	mov    $0xa,%ecx
			goto number;
  80067b:	eb 46                	jmp    8006c3 <vprintfmt+0x311>

		// (unsigned) octal
		case 'o':
			num = getuint(&ap, lflag);
  80067d:	8d 45 14             	lea    0x14(%ebp),%eax
  800680:	e8 87 fc ff ff       	call   80030c <getuint>
			base = 8;
  800685:	b9 08 00 00 00       	mov    $0x8,%ecx
			goto number;
  80068a:	eb 37                	jmp    8006c3 <vprintfmt+0x311>

		// pointer
		case 'p':
			putch('0', putdat);
  80068c:	83 ec 08             	sub    $0x8,%esp
  80068f:	53                   	push   %ebx
  800690:	6a 30                	push   $0x30
  800692:	ff d6                	call   *%esi
			putch('x', putdat);
  800694:	83 c4 08             	add    $0x8,%esp
  800697:	53                   	push   %ebx
  800698:	6a 78                	push   $0x78
  80069a:	ff d6                	call   *%esi
			num = (unsigned long long)
				(uintptr_t) va_arg(ap, void *);
  80069c:	8b 45 14             	mov    0x14(%ebp),%eax
  80069f:	8d 50 04             	lea    0x4(%eax),%edx
  8006a2:	89 55 14             	mov    %edx,0x14(%ebp)

		// pointer
		case 'p':
			putch('0', putdat);
			putch('x', putdat);
			num = (unsigned long long)
  8006a5:	8b 00                	mov    (%eax),%eax
  8006a7:	ba 00 00 00 00       	mov    $0x0,%edx
				(uintptr_t) va_arg(ap, void *);
			base = 16;
			goto number;
  8006ac:	83 c4 10             	add    $0x10,%esp
		case 'p':
			putch('0', putdat);
			putch('x', putdat);
			num = (unsigned long long)
				(uintptr_t) va_arg(ap, void *);
			base = 16;
  8006af:	b9 10 00 00 00       	mov    $0x10,%ecx
			goto number;
  8006b4:	eb 0d                	jmp    8006c3 <vprintfmt+0x311>

		// (unsigned) hexadecimal
		case 'x':
			num = getuint(&ap, lflag);
  8006b6:	8d 45 14             	lea    0x14(%ebp),%eax
  8006b9:	e8 4e fc ff ff       	call   80030c <getuint>
			base = 16;
  8006be:	b9 10 00 00 00       	mov    $0x10,%ecx
		number:
			printnum(putch, putdat, num, base, width, padc);
  8006c3:	83 ec 0c             	sub    $0xc,%esp
  8006c6:	0f be 7d d4          	movsbl -0x2c(%ebp),%edi
  8006ca:	57                   	push   %edi
  8006cb:	ff 75 e0             	pushl  -0x20(%ebp)
  8006ce:	51                   	push   %ecx
  8006cf:	52                   	push   %edx
  8006d0:	50                   	push   %eax
  8006d1:	89 da                	mov    %ebx,%edx
  8006d3:	89 f0                	mov    %esi,%eax
  8006d5:	e8 83 fb ff ff       	call   80025d <printnum>
			break;
  8006da:	83 c4 20             	add    $0x20,%esp
  8006dd:	8b 7d e4             	mov    -0x1c(%ebp),%edi
  8006e0:	e9 f3 fc ff ff       	jmp    8003d8 <vprintfmt+0x26>

		// escaped '%' character
		case '%':
			putch(ch, putdat);
  8006e5:	83 ec 08             	sub    $0x8,%esp
  8006e8:	53                   	push   %ebx
  8006e9:	51                   	push   %ecx
  8006ea:	ff d6                	call   *%esi
			break;
  8006ec:	83 c4 10             	add    $0x10,%esp
		width = -1;
		precision = -1;
		lflag = 0;
		altflag = 0;
	reswitch:
		switch (ch = *(unsigned char *) fmt++) {
  8006ef:	8b 7d e4             	mov    -0x1c(%ebp),%edi
			break;

		// escaped '%' character
		case '%':
			putch(ch, putdat);
			break;
  8006f2:	e9 e1 fc ff ff       	jmp    8003d8 <vprintfmt+0x26>

		// unrecognized escape sequence - just print it literally
		default:
			putch('%', putdat);
  8006f7:	83 ec 08             	sub    $0x8,%esp
  8006fa:	53                   	push   %ebx
  8006fb:	6a 25                	push   $0x25
  8006fd:	ff d6                	call   *%esi
			for (fmt--; fmt[-1] != '%'; fmt--)
  8006ff:	83 c4 10             	add    $0x10,%esp
  800702:	eb 03                	jmp    800707 <vprintfmt+0x355>
  800704:	83 ef 01             	sub    $0x1,%edi
  800707:	80 7f ff 25          	cmpb   $0x25,-0x1(%edi)
  80070b:	75 f7                	jne    800704 <vprintfmt+0x352>
  80070d:	e9 c6 fc ff ff       	jmp    8003d8 <vprintfmt+0x26>
				/* do nothing */;
			break;
		}
	}
}
  800712:	8d 65 f4             	lea    -0xc(%ebp),%esp
  800715:	5b                   	pop    %ebx
  800716:	5e                   	pop    %esi
  800717:	5f                   	pop    %edi
  800718:	5d                   	pop    %ebp
  800719:	c3                   	ret    

0080071a <vsnprintf>:
		*b->buf++ = ch;
}

int
vsnprintf(char *buf, int n, const char *fmt, va_list ap)
{
  80071a:	55                   	push   %ebp
  80071b:	89 e5                	mov    %esp,%ebp
  80071d:	83 ec 18             	sub    $0x18,%esp
  800720:	8b 45 08             	mov    0x8(%ebp),%eax
  800723:	8b 55 0c             	mov    0xc(%ebp),%edx
	struct sprintbuf b = {buf, buf+n-1, 0};
  800726:	89 45 ec             	mov    %eax,-0x14(%ebp)
  800729:	8d 4c 10 ff          	lea    -0x1(%eax,%edx,1),%ecx
  80072d:	89 4d f0             	mov    %ecx,-0x10(%ebp)
  800730:	c7 45 f4 00 00 00 00 	movl   $0x0,-0xc(%ebp)

	if (buf == NULL || n < 1)
  800737:	85 c0                	test   %eax,%eax
  800739:	74 26                	je     800761 <vsnprintf+0x47>
  80073b:	85 d2                	test   %edx,%edx
  80073d:	7e 22                	jle    800761 <vsnprintf+0x47>
		return -E_INVAL;

	// print the string to the buffer
	vprintfmt((void*)sprintputch, &b, fmt, ap);
  80073f:	ff 75 14             	pushl  0x14(%ebp)
  800742:	ff 75 10             	pushl  0x10(%ebp)
  800745:	8d 45 ec             	lea    -0x14(%ebp),%eax
  800748:	50                   	push   %eax
  800749:	68 78 03 80 00       	push   $0x800378
  80074e:	e8 5f fc ff ff       	call   8003b2 <vprintfmt>

	// null terminate the buffer
	*b.buf = '\0';
  800753:	8b 45 ec             	mov    -0x14(%ebp),%eax
  800756:	c6 00 00             	movb   $0x0,(%eax)

	return b.cnt;
  800759:	8b 45 f4             	mov    -0xc(%ebp),%eax
  80075c:	83 c4 10             	add    $0x10,%esp
  80075f:	eb 05                	jmp    800766 <vsnprintf+0x4c>
vsnprintf(char *buf, int n, const char *fmt, va_list ap)
{
	struct sprintbuf b = {buf, buf+n-1, 0};

	if (buf == NULL || n < 1)
		return -E_INVAL;
  800761:	b8 fd ff ff ff       	mov    $0xfffffffd,%eax

	// null terminate the buffer
	*b.buf = '\0';

	return b.cnt;
}
  800766:	c9                   	leave  
  800767:	c3                   	ret    

00800768 <snprintf>:

int
snprintf(char *buf, int n, const char *fmt, ...)
{
  800768:	55                   	push   %ebp
  800769:	89 e5                	mov    %esp,%ebp
  80076b:	83 ec 08             	sub    $0x8,%esp
	va_list ap;
	int rc;

	va_start(ap, fmt);
  80076e:	8d 45 14             	lea    0x14(%ebp),%eax
	rc = vsnprintf(buf, n, fmt, ap);
  800771:	50                   	push   %eax
  800772:	ff 75 10             	pushl  0x10(%ebp)
  800775:	ff 75 0c             	pushl  0xc(%ebp)
  800778:	ff 75 08             	pushl  0x8(%ebp)
  80077b:	e8 9a ff ff ff       	call   80071a <vsnprintf>
	va_end(ap);

	return rc;
}
  800780:	c9                   	leave  
  800781:	c3                   	ret    

00800782 <strlen>:
// Primespipe runs 3x faster this way.
#define ASM 1

int
strlen(const char *s)
{
  800782:	55                   	push   %ebp
  800783:	89 e5                	mov    %esp,%ebp
  800785:	8b 55 08             	mov    0x8(%ebp),%edx
	int n;

	for (n = 0; *s != '\0'; s++)
  800788:	b8 00 00 00 00       	mov    $0x0,%eax
  80078d:	eb 03                	jmp    800792 <strlen+0x10>
		n++;
  80078f:	83 c0 01             	add    $0x1,%eax
int
strlen(const char *s)
{
	int n;

	for (n = 0; *s != '\0'; s++)
  800792:	80 3c 02 00          	cmpb   $0x0,(%edx,%eax,1)
  800796:	75 f7                	jne    80078f <strlen+0xd>
		n++;
	return n;
}
  800798:	5d                   	pop    %ebp
  800799:	c3                   	ret    

0080079a <strnlen>:

int
strnlen(const char *s, size_t size)
{
  80079a:	55                   	push   %ebp
  80079b:	89 e5                	mov    %esp,%ebp
  80079d:	8b 4d 08             	mov    0x8(%ebp),%ecx
  8007a0:	8b 45 0c             	mov    0xc(%ebp),%eax
	int n;

	for (n = 0; size > 0 && *s != '\0'; s++, size--)
  8007a3:	ba 00 00 00 00       	mov    $0x0,%edx
  8007a8:	eb 03                	jmp    8007ad <strnlen+0x13>
		n++;
  8007aa:	83 c2 01             	add    $0x1,%edx
int
strnlen(const char *s, size_t size)
{
	int n;

	for (n = 0; size > 0 && *s != '\0'; s++, size--)
  8007ad:	39 c2                	cmp    %eax,%edx
  8007af:	74 08                	je     8007b9 <strnlen+0x1f>
  8007b1:	80 3c 11 00          	cmpb   $0x0,(%ecx,%edx,1)
  8007b5:	75 f3                	jne    8007aa <strnlen+0x10>
  8007b7:	89 d0                	mov    %edx,%eax
		n++;
	return n;
}
  8007b9:	5d                   	pop    %ebp
  8007ba:	c3                   	ret    

008007bb <strcpy>:

char *
strcpy(char *dst, const char *src)
{
  8007bb:	55                   	push   %ebp
  8007bc:	89 e5                	mov    %esp,%ebp
  8007be:	53                   	push   %ebx
  8007bf:	8b 45 08             	mov    0x8(%ebp),%eax
  8007c2:	8b 4d 0c             	mov    0xc(%ebp),%ecx
	char *ret;

	ret = dst;
	while ((*dst++ = *src++) != '\0')
  8007c5:	89 c2                	mov    %eax,%edx
  8007c7:	83 c2 01             	add    $0x1,%edx
  8007ca:	83 c1 01             	add    $0x1,%ecx
  8007cd:	0f b6 59 ff          	movzbl -0x1(%ecx),%ebx
  8007d1:	88 5a ff             	mov    %bl,-0x1(%edx)
  8007d4:	84 db                	test   %bl,%bl
  8007d6:	75 ef                	jne    8007c7 <strcpy+0xc>
		/* do nothing */;
	return ret;
}
  8007d8:	5b                   	pop    %ebx
  8007d9:	5d                   	pop    %ebp
  8007da:	c3                   	ret    

008007db <strcat>:

char *
strcat(char *dst, const char *src)
{
  8007db:	55                   	push   %ebp
  8007dc:	89 e5                	mov    %esp,%ebp
  8007de:	53                   	push   %ebx
  8007df:	8b 5d 08             	mov    0x8(%ebp),%ebx
	int len = strlen(dst);
  8007e2:	53                   	push   %ebx
  8007e3:	e8 9a ff ff ff       	call   800782 <strlen>
  8007e8:	83 c4 04             	add    $0x4,%esp
	strcpy(dst + len, src);
  8007eb:	ff 75 0c             	pushl  0xc(%ebp)
  8007ee:	01 d8                	add    %ebx,%eax
  8007f0:	50                   	push   %eax
  8007f1:	e8 c5 ff ff ff       	call   8007bb <strcpy>
	return dst;
}
  8007f6:	89 d8                	mov    %ebx,%eax
  8007f8:	8b 5d fc             	mov    -0x4(%ebp),%ebx
  8007fb:	c9                   	leave  
  8007fc:	c3                   	ret    

008007fd <strncpy>:

char *
strncpy(char *dst, const char *src, size_t size) {
  8007fd:	55                   	push   %ebp
  8007fe:	89 e5                	mov    %esp,%ebp
  800800:	56                   	push   %esi
  800801:	53                   	push   %ebx
  800802:	8b 75 08             	mov    0x8(%ebp),%esi
  800805:	8b 4d 0c             	mov    0xc(%ebp),%ecx
  800808:	89 f3                	mov    %esi,%ebx
  80080a:	03 5d 10             	add    0x10(%ebp),%ebx
	size_t i;
	char *ret;

	ret = dst;
	for (i = 0; i < size; i++) {
  80080d:	89 f2                	mov    %esi,%edx
  80080f:	eb 0f                	jmp    800820 <strncpy+0x23>
		*dst++ = *src;
  800811:	83 c2 01             	add    $0x1,%edx
  800814:	0f b6 01             	movzbl (%ecx),%eax
  800817:	88 42 ff             	mov    %al,-0x1(%edx)
		// If strlen(src) < size, null-pad 'dst' out to 'size' chars
		if (*src != '\0')
			src++;
  80081a:	80 39 01             	cmpb   $0x1,(%ecx)
  80081d:	83 d9 ff             	sbb    $0xffffffff,%ecx
strncpy(char *dst, const char *src, size_t size) {
	size_t i;
	char *ret;

	ret = dst;
	for (i = 0; i < size; i++) {
  800820:	39 da                	cmp    %ebx,%edx
  800822:	75 ed                	jne    800811 <strncpy+0x14>
		// If strlen(src) < size, null-pad 'dst' out to 'size' chars
		if (*src != '\0')
			src++;
	}
	return ret;
}
  800824:	89 f0                	mov    %esi,%eax
  800826:	5b                   	pop    %ebx
  800827:	5e                   	pop    %esi
  800828:	5d                   	pop    %ebp
  800829:	c3                   	ret    

0080082a <strlcpy>:

size_t
strlcpy(char *dst, const char *src, size_t size)
{
  80082a:	55                   	push   %ebp
  80082b:	89 e5                	mov    %esp,%ebp
  80082d:	56                   	push   %esi
  80082e:	53                   	push   %ebx
  80082f:	8b 75 08             	mov    0x8(%ebp),%esi
  800832:	8b 4d 0c             	mov    0xc(%ebp),%ecx
  800835:	8b 55 10             	mov    0x10(%ebp),%edx
  800838:	89 f0                	mov    %esi,%eax
	char *dst_in;

	dst_in = dst;
	if (size > 0) {
  80083a:	85 d2                	test   %edx,%edx
  80083c:	74 21                	je     80085f <strlcpy+0x35>
  80083e:	8d 44 16 ff          	lea    -0x1(%esi,%edx,1),%eax
  800842:	89 f2                	mov    %esi,%edx
  800844:	eb 09                	jmp    80084f <strlcpy+0x25>
		while (--size > 0 && *src != '\0')
			*dst++ = *src++;
  800846:	83 c2 01             	add    $0x1,%edx
  800849:	83 c1 01             	add    $0x1,%ecx
  80084c:	88 5a ff             	mov    %bl,-0x1(%edx)
{
	char *dst_in;

	dst_in = dst;
	if (size > 0) {
		while (--size > 0 && *src != '\0')
  80084f:	39 c2                	cmp    %eax,%edx
  800851:	74 09                	je     80085c <strlcpy+0x32>
  800853:	0f b6 19             	movzbl (%ecx),%ebx
  800856:	84 db                	test   %bl,%bl
  800858:	75 ec                	jne    800846 <strlcpy+0x1c>
  80085a:	89 d0                	mov    %edx,%eax
			*dst++ = *src++;
		*dst = '\0';
  80085c:	c6 00 00             	movb   $0x0,(%eax)
	}
	return dst - dst_in;
  80085f:	29 f0                	sub    %esi,%eax
}
  800861:	5b                   	pop    %ebx
  800862:	5e                   	pop    %esi
  800863:	5d                   	pop    %ebp
  800864:	c3                   	ret    

00800865 <strcmp>:

int
strcmp(const char *p, const char *q)
{
  800865:	55                   	push   %ebp
  800866:	89 e5                	mov    %esp,%ebp
  800868:	8b 4d 08             	mov    0x8(%ebp),%ecx
  80086b:	8b 55 0c             	mov    0xc(%ebp),%edx
	while (*p && *p == *q)
  80086e:	eb 06                	jmp    800876 <strcmp+0x11>
		p++, q++;
  800870:	83 c1 01             	add    $0x1,%ecx
  800873:	83 c2 01             	add    $0x1,%edx
}

int
strcmp(const char *p, const char *q)
{
	while (*p && *p == *q)
  800876:	0f b6 01             	movzbl (%ecx),%eax
  800879:	84 c0                	test   %al,%al
  80087b:	74 04                	je     800881 <strcmp+0x1c>
  80087d:	3a 02                	cmp    (%edx),%al
  80087f:	74 ef                	je     800870 <strcmp+0xb>
		p++, q++;
	return (int) ((unsigned char) *p - (unsigned char) *q);
  800881:	0f b6 c0             	movzbl %al,%eax
  800884:	0f b6 12             	movzbl (%edx),%edx
  800887:	29 d0                	sub    %edx,%eax
}
  800889:	5d                   	pop    %ebp
  80088a:	c3                   	ret    

0080088b <strncmp>:

int
strncmp(const char *p, const char *q, size_t n)
{
  80088b:	55                   	push   %ebp
  80088c:	89 e5                	mov    %esp,%ebp
  80088e:	53                   	push   %ebx
  80088f:	8b 45 08             	mov    0x8(%ebp),%eax
  800892:	8b 55 0c             	mov    0xc(%ebp),%edx
  800895:	89 c3                	mov    %eax,%ebx
  800897:	03 5d 10             	add    0x10(%ebp),%ebx
	while (n > 0 && *p && *p == *q)
  80089a:	eb 06                	jmp    8008a2 <strncmp+0x17>
		n--, p++, q++;
  80089c:	83 c0 01             	add    $0x1,%eax
  80089f:	83 c2 01             	add    $0x1,%edx
}

int
strncmp(const char *p, const char *q, size_t n)
{
	while (n > 0 && *p && *p == *q)
  8008a2:	39 d8                	cmp    %ebx,%eax
  8008a4:	74 15                	je     8008bb <strncmp+0x30>
  8008a6:	0f b6 08             	movzbl (%eax),%ecx
  8008a9:	84 c9                	test   %cl,%cl
  8008ab:	74 04                	je     8008b1 <strncmp+0x26>
  8008ad:	3a 0a                	cmp    (%edx),%cl
  8008af:	74 eb                	je     80089c <strncmp+0x11>
		n--, p++, q++;
	if (n == 0)
		return 0;
	else
		return (int) ((unsigned char) *p - (unsigned char) *q);
  8008b1:	0f b6 00             	movzbl (%eax),%eax
  8008b4:	0f b6 12             	movzbl (%edx),%edx
  8008b7:	29 d0                	sub    %edx,%eax
  8008b9:	eb 05                	jmp    8008c0 <strncmp+0x35>
strncmp(const char *p, const char *q, size_t n)
{
	while (n > 0 && *p && *p == *q)
		n--, p++, q++;
	if (n == 0)
		return 0;
  8008bb:	b8 00 00 00 00       	mov    $0x0,%eax
	else
		return (int) ((unsigned char) *p - (unsigned char) *q);
}
  8008c0:	5b                   	pop    %ebx
  8008c1:	5d                   	pop    %ebp
  8008c2:	c3                   	ret    

008008c3 <strchr>:

// Return a pointer to the first occurrence of 'c' in 's',
// or a null pointer if the string has no 'c'.
char *
strchr(const char *s, char c)
{
  8008c3:	55                   	push   %ebp
  8008c4:	89 e5                	mov    %esp,%ebp
  8008c6:	8b 45 08             	mov    0x8(%ebp),%eax
  8008c9:	0f b6 4d 0c          	movzbl 0xc(%ebp),%ecx
	for (; *s; s++)
  8008cd:	eb 07                	jmp    8008d6 <strchr+0x13>
		if (*s == c)
  8008cf:	38 ca                	cmp    %cl,%dl
  8008d1:	74 0f                	je     8008e2 <strchr+0x1f>
// Return a pointer to the first occurrence of 'c' in 's',
// or a null pointer if the string has no 'c'.
char *
strchr(const char *s, char c)
{
	for (; *s; s++)
  8008d3:	83 c0 01             	add    $0x1,%eax
  8008d6:	0f b6 10             	movzbl (%eax),%edx
  8008d9:	84 d2                	test   %dl,%dl
  8008db:	75 f2                	jne    8008cf <strchr+0xc>
		if (*s == c)
			return (char *) s;
	return 0;
  8008dd:	b8 00 00 00 00       	mov    $0x0,%eax
}
  8008e2:	5d                   	pop    %ebp
  8008e3:	c3                   	ret    

008008e4 <strfind>:

// Return a pointer to the first occurrence of 'c' in 's',
// or a pointer to the string-ending null character if the string has no 'c'.
char *
strfind(const char *s, char c)
{
  8008e4:	55                   	push   %ebp
  8008e5:	89 e5                	mov    %esp,%ebp
  8008e7:	8b 45 08             	mov    0x8(%ebp),%eax
  8008ea:	0f b6 4d 0c          	movzbl 0xc(%ebp),%ecx
	for (; *s; s++)
  8008ee:	eb 03                	jmp    8008f3 <strfind+0xf>
  8008f0:	83 c0 01             	add    $0x1,%eax
  8008f3:	0f b6 10             	movzbl (%eax),%edx
		if (*s == c)
  8008f6:	38 ca                	cmp    %cl,%dl
  8008f8:	74 04                	je     8008fe <strfind+0x1a>
  8008fa:	84 d2                	test   %dl,%dl
  8008fc:	75 f2                	jne    8008f0 <strfind+0xc>
			break;
	return (char *) s;
}
  8008fe:	5d                   	pop    %ebp
  8008ff:	c3                   	ret    

00800900 <memset>:

#if ASM
void *
memset(void *v, int c, size_t n)
{
  800900:	55                   	push   %ebp
  800901:	89 e5                	mov    %esp,%ebp
  800903:	57                   	push   %edi
  800904:	56                   	push   %esi
  800905:	53                   	push   %ebx
  800906:	8b 55 08             	mov    0x8(%ebp),%edx
  800909:	8b 4d 10             	mov    0x10(%ebp),%ecx
	char *p = v;

	if (n == 0)
  80090c:	85 c9                	test   %ecx,%ecx
  80090e:	74 37                	je     800947 <memset+0x47>
		return v;
	if ((int)v%4 == 0 && n%4 == 0) {
  800910:	f6 c2 03             	test   $0x3,%dl
  800913:	75 2a                	jne    80093f <memset+0x3f>
  800915:	f6 c1 03             	test   $0x3,%cl
  800918:	75 25                	jne    80093f <memset+0x3f>
		c &= 0xFF;
  80091a:	0f b6 5d 0c          	movzbl 0xc(%ebp),%ebx
		c = (c<<24)|(c<<16)|(c<<8)|c;
  80091e:	89 df                	mov    %ebx,%edi
  800920:	c1 e7 08             	shl    $0x8,%edi
  800923:	89 de                	mov    %ebx,%esi
  800925:	c1 e6 18             	shl    $0x18,%esi
  800928:	89 d8                	mov    %ebx,%eax
  80092a:	c1 e0 10             	shl    $0x10,%eax
  80092d:	09 f0                	or     %esi,%eax
  80092f:	09 c3                	or     %eax,%ebx
		asm volatile("cld; rep stosl\n"
			: "=D" (p), "=c" (n)
			: "D" (p), "a" (c), "c" (n/4)
  800931:	c1 e9 02             	shr    $0x2,%ecx
	if (n == 0)
		return v;
	if ((int)v%4 == 0 && n%4 == 0) {
		c &= 0xFF;
		c = (c<<24)|(c<<16)|(c<<8)|c;
		asm volatile("cld; rep stosl\n"
  800934:	89 f8                	mov    %edi,%eax
  800936:	09 d8                	or     %ebx,%eax
  800938:	89 d7                	mov    %edx,%edi
  80093a:	fc                   	cld    
  80093b:	f3 ab                	rep stos %eax,%es:(%edi)
  80093d:	eb 08                	jmp    800947 <memset+0x47>
			: "=D" (p), "=c" (n)
			: "D" (p), "a" (c), "c" (n/4)
			: "cc", "memory");
	} else
		asm volatile("cld; rep stosb\n"
  80093f:	89 d7                	mov    %edx,%edi
  800941:	8b 45 0c             	mov    0xc(%ebp),%eax
  800944:	fc                   	cld    
  800945:	f3 aa                	rep stos %al,%es:(%edi)
			: "=D" (p), "=c" (n)
			: "0" (p), "a" (c), "1" (n)
			: "cc", "memory");
	return v;
}
  800947:	89 d0                	mov    %edx,%eax
  800949:	5b                   	pop    %ebx
  80094a:	5e                   	pop    %esi
  80094b:	5f                   	pop    %edi
  80094c:	5d                   	pop    %ebp
  80094d:	c3                   	ret    

0080094e <memmove>:

void *
memmove(void *dst, const void *src, size_t n)
{
  80094e:	55                   	push   %ebp
  80094f:	89 e5                	mov    %esp,%ebp
  800951:	57                   	push   %edi
  800952:	56                   	push   %esi
  800953:	8b 45 08             	mov    0x8(%ebp),%eax
  800956:	8b 75 0c             	mov    0xc(%ebp),%esi
  800959:	8b 4d 10             	mov    0x10(%ebp),%ecx
	const char *s;
	char *d;

	s = src;
	d = dst;
	if (s < d && s + n > d) {
  80095c:	39 c6                	cmp    %eax,%esi
  80095e:	73 35                	jae    800995 <memmove+0x47>
  800960:	8d 14 0e             	lea    (%esi,%ecx,1),%edx
  800963:	39 d0                	cmp    %edx,%eax
  800965:	73 2e                	jae    800995 <memmove+0x47>
		s += n;
		d += n;
  800967:	8d 3c 08             	lea    (%eax,%ecx,1),%edi
		if ((int)s%4 == 0 && (int)d%4 == 0 && n%4 == 0)
  80096a:	89 d6                	mov    %edx,%esi
  80096c:	09 fe                	or     %edi,%esi
  80096e:	f7 c6 03 00 00 00    	test   $0x3,%esi
  800974:	75 13                	jne    800989 <memmove+0x3b>
  800976:	f6 c1 03             	test   $0x3,%cl
  800979:	75 0e                	jne    800989 <memmove+0x3b>
			asm volatile("std; rep movsl\n"
  80097b:	83 ef 04             	sub    $0x4,%edi
  80097e:	8d 72 fc             	lea    -0x4(%edx),%esi
  800981:	c1 e9 02             	shr    $0x2,%ecx
  800984:	fd                   	std    
  800985:	f3 a5                	rep movsl %ds:(%esi),%es:(%edi)
  800987:	eb 09                	jmp    800992 <memmove+0x44>
				:: "D" (d-4), "S" (s-4), "c" (n/4) : "cc", "memory");
		else
			asm volatile("std; rep movsb\n"
  800989:	83 ef 01             	sub    $0x1,%edi
  80098c:	8d 72 ff             	lea    -0x1(%edx),%esi
  80098f:	fd                   	std    
  800990:	f3 a4                	rep movsb %ds:(%esi),%es:(%edi)
				:: "D" (d-1), "S" (s-1), "c" (n) : "cc", "memory");
		// Some versions of GCC rely on DF being clear
		asm volatile("cld" ::: "cc");
  800992:	fc                   	cld    
  800993:	eb 1d                	jmp    8009b2 <memmove+0x64>
	} else {
		if ((int)s%4 == 0 && (int)d%4 == 0 && n%4 == 0)
  800995:	89 f2                	mov    %esi,%edx
  800997:	09 c2                	or     %eax,%edx
  800999:	f6 c2 03             	test   $0x3,%dl
  80099c:	75 0f                	jne    8009ad <memmove+0x5f>
  80099e:	f6 c1 03             	test   $0x3,%cl
  8009a1:	75 0a                	jne    8009ad <memmove+0x5f>
			asm volatile("cld; rep movsl\n"
  8009a3:	c1 e9 02             	shr    $0x2,%ecx
  8009a6:	89 c7                	mov    %eax,%edi
  8009a8:	fc                   	cld    
  8009a9:	f3 a5                	rep movsl %ds:(%esi),%es:(%edi)
  8009ab:	eb 05                	jmp    8009b2 <memmove+0x64>
				:: "D" (d), "S" (s), "c" (n/4) : "cc", "memory");
		else
			asm volatile("cld; rep movsb\n"
  8009ad:	89 c7                	mov    %eax,%edi
  8009af:	fc                   	cld    
  8009b0:	f3 a4                	rep movsb %ds:(%esi),%es:(%edi)
				:: "D" (d), "S" (s), "c" (n) : "cc", "memory");
	}
	return dst;
}
  8009b2:	5e                   	pop    %esi
  8009b3:	5f                   	pop    %edi
  8009b4:	5d                   	pop    %ebp
  8009b5:	c3                   	ret    

008009b6 <memcpy>:
}
#endif

void *
memcpy(void *dst, const void *src, size_t n)
{
  8009b6:	55                   	push   %ebp
  8009b7:	89 e5                	mov    %esp,%ebp
	return memmove(dst, src, n);
  8009b9:	ff 75 10             	pushl  0x10(%ebp)
  8009bc:	ff 75 0c             	pushl  0xc(%ebp)
  8009bf:	ff 75 08             	pushl  0x8(%ebp)
  8009c2:	e8 87 ff ff ff       	call   80094e <memmove>
}
  8009c7:	c9                   	leave  
  8009c8:	c3                   	ret    

008009c9 <memcmp>:

int
memcmp(const void *v1, const void *v2, size_t n)
{
  8009c9:	55                   	push   %ebp
  8009ca:	89 e5                	mov    %esp,%ebp
  8009cc:	56                   	push   %esi
  8009cd:	53                   	push   %ebx
  8009ce:	8b 45 08             	mov    0x8(%ebp),%eax
  8009d1:	8b 55 0c             	mov    0xc(%ebp),%edx
  8009d4:	89 c6                	mov    %eax,%esi
  8009d6:	03 75 10             	add    0x10(%ebp),%esi
	const uint8_t *s1 = (const uint8_t *) v1;
	const uint8_t *s2 = (const uint8_t *) v2;

	while (n-- > 0) {
  8009d9:	eb 1a                	jmp    8009f5 <memcmp+0x2c>
		if (*s1 != *s2)
  8009db:	0f b6 08             	movzbl (%eax),%ecx
  8009de:	0f b6 1a             	movzbl (%edx),%ebx
  8009e1:	38 d9                	cmp    %bl,%cl
  8009e3:	74 0a                	je     8009ef <memcmp+0x26>
			return (int) *s1 - (int) *s2;
  8009e5:	0f b6 c1             	movzbl %cl,%eax
  8009e8:	0f b6 db             	movzbl %bl,%ebx
  8009eb:	29 d8                	sub    %ebx,%eax
  8009ed:	eb 0f                	jmp    8009fe <memcmp+0x35>
		s1++, s2++;
  8009ef:	83 c0 01             	add    $0x1,%eax
  8009f2:	83 c2 01             	add    $0x1,%edx
memcmp(const void *v1, const void *v2, size_t n)
{
	const uint8_t *s1 = (const uint8_t *) v1;
	const uint8_t *s2 = (const uint8_t *) v2;

	while (n-- > 0) {
  8009f5:	39 f0                	cmp    %esi,%eax
  8009f7:	75 e2                	jne    8009db <memcmp+0x12>
		if (*s1 != *s2)
			return (int) *s1 - (int) *s2;
		s1++, s2++;
	}

	return 0;
  8009f9:	b8 00 00 00 00       	mov    $0x0,%eax
}
  8009fe:	5b                   	pop    %ebx
  8009ff:	5e                   	pop    %esi
  800a00:	5d                   	pop    %ebp
  800a01:	c3                   	ret    

00800a02 <memfind>:

void *
memfind(const void *s, int c, size_t n)
{
  800a02:	55                   	push   %ebp
  800a03:	89 e5                	mov    %esp,%ebp
  800a05:	8b 45 08             	mov    0x8(%ebp),%eax
  800a08:	8b 4d 0c             	mov    0xc(%ebp),%ecx
	const void *ends = (const char *) s + n;
  800a0b:	89 c2                	mov    %eax,%edx
  800a0d:	03 55 10             	add    0x10(%ebp),%edx
	for (; s < ends; s++)
  800a10:	eb 07                	jmp    800a19 <memfind+0x17>
		if (*(const unsigned char *) s == (unsigned char) c)
  800a12:	38 08                	cmp    %cl,(%eax)
  800a14:	74 07                	je     800a1d <memfind+0x1b>

void *
memfind(const void *s, int c, size_t n)
{
	const void *ends = (const char *) s + n;
	for (; s < ends; s++)
  800a16:	83 c0 01             	add    $0x1,%eax
  800a19:	39 d0                	cmp    %edx,%eax
  800a1b:	72 f5                	jb     800a12 <memfind+0x10>
		if (*(const unsigned char *) s == (unsigned char) c)
			break;
	return (void *) s;
}
  800a1d:	5d                   	pop    %ebp
  800a1e:	c3                   	ret    

00800a1f <strtol>:

long
strtol(const char *s, char **endptr, int base)
{
  800a1f:	55                   	push   %ebp
  800a20:	89 e5                	mov    %esp,%ebp
  800a22:	57                   	push   %edi
  800a23:	56                   	push   %esi
  800a24:	53                   	push   %ebx
  800a25:	8b 4d 08             	mov    0x8(%ebp),%ecx
  800a28:	8b 5d 10             	mov    0x10(%ebp),%ebx
	int neg = 0;
	long val = 0;

	// gobble initial whitespace
	while (*s == ' ' || *s == '\t')
  800a2b:	eb 03                	jmp    800a30 <strtol+0x11>
		s++;
  800a2d:	83 c1 01             	add    $0x1,%ecx
{
	int neg = 0;
	long val = 0;

	// gobble initial whitespace
	while (*s == ' ' || *s == '\t')
  800a30:	0f b6 01             	movzbl (%ecx),%eax
  800a33:	3c 20                	cmp    $0x20,%al
  800a35:	74 f6                	je     800a2d <strtol+0xe>
  800a37:	3c 09                	cmp    $0x9,%al
  800a39:	74 f2                	je     800a2d <strtol+0xe>
		s++;

	// plus/minus sign
	if (*s == '+')
  800a3b:	3c 2b                	cmp    $0x2b,%al
  800a3d:	75 0a                	jne    800a49 <strtol+0x2a>
		s++;
  800a3f:	83 c1 01             	add    $0x1,%ecx
}

long
strtol(const char *s, char **endptr, int base)
{
	int neg = 0;
  800a42:	bf 00 00 00 00       	mov    $0x0,%edi
  800a47:	eb 11                	jmp    800a5a <strtol+0x3b>
  800a49:	bf 00 00 00 00       	mov    $0x0,%edi
		s++;

	// plus/minus sign
	if (*s == '+')
		s++;
	else if (*s == '-')
  800a4e:	3c 2d                	cmp    $0x2d,%al
  800a50:	75 08                	jne    800a5a <strtol+0x3b>
		s++, neg = 1;
  800a52:	83 c1 01             	add    $0x1,%ecx
  800a55:	bf 01 00 00 00       	mov    $0x1,%edi

	// hex or octal base prefix
	if ((base == 0 || base == 16) && (s[0] == '0' && s[1] == 'x'))
  800a5a:	f7 c3 ef ff ff ff    	test   $0xffffffef,%ebx
  800a60:	75 15                	jne    800a77 <strtol+0x58>
  800a62:	80 39 30             	cmpb   $0x30,(%ecx)
  800a65:	75 10                	jne    800a77 <strtol+0x58>
  800a67:	80 79 01 78          	cmpb   $0x78,0x1(%ecx)
  800a6b:	75 7c                	jne    800ae9 <strtol+0xca>
		s += 2, base = 16;
  800a6d:	83 c1 02             	add    $0x2,%ecx
  800a70:	bb 10 00 00 00       	mov    $0x10,%ebx
  800a75:	eb 16                	jmp    800a8d <strtol+0x6e>
	else if (base == 0 && s[0] == '0')
  800a77:	85 db                	test   %ebx,%ebx
  800a79:	75 12                	jne    800a8d <strtol+0x6e>
		s++, base = 8;
	else if (base == 0)
		base = 10;
  800a7b:	bb 0a 00 00 00       	mov    $0xa,%ebx
		s++, neg = 1;

	// hex or octal base prefix
	if ((base == 0 || base == 16) && (s[0] == '0' && s[1] == 'x'))
		s += 2, base = 16;
	else if (base == 0 && s[0] == '0')
  800a80:	80 39 30             	cmpb   $0x30,(%ecx)
  800a83:	75 08                	jne    800a8d <strtol+0x6e>
		s++, base = 8;
  800a85:	83 c1 01             	add    $0x1,%ecx
  800a88:	bb 08 00 00 00       	mov    $0x8,%ebx
	else if (base == 0)
		base = 10;
  800a8d:	b8 00 00 00 00       	mov    $0x0,%eax
  800a92:	89 5d 10             	mov    %ebx,0x10(%ebp)

	// digits
	while (1) {
		int dig;

		if (*s >= '0' && *s <= '9')
  800a95:	0f b6 11             	movzbl (%ecx),%edx
  800a98:	8d 72 d0             	lea    -0x30(%edx),%esi
  800a9b:	89 f3                	mov    %esi,%ebx
  800a9d:	80 fb 09             	cmp    $0x9,%bl
  800aa0:	77 08                	ja     800aaa <strtol+0x8b>
			dig = *s - '0';
  800aa2:	0f be d2             	movsbl %dl,%edx
  800aa5:	83 ea 30             	sub    $0x30,%edx
  800aa8:	eb 22                	jmp    800acc <strtol+0xad>
		else if (*s >= 'a' && *s <= 'z')
  800aaa:	8d 72 9f             	lea    -0x61(%edx),%esi
  800aad:	89 f3                	mov    %esi,%ebx
  800aaf:	80 fb 19             	cmp    $0x19,%bl
  800ab2:	77 08                	ja     800abc <strtol+0x9d>
			dig = *s - 'a' + 10;
  800ab4:	0f be d2             	movsbl %dl,%edx
  800ab7:	83 ea 57             	sub    $0x57,%edx
  800aba:	eb 10                	jmp    800acc <strtol+0xad>
		else if (*s >= 'A' && *s <= 'Z')
  800abc:	8d 72 bf             	lea    -0x41(%edx),%esi
  800abf:	89 f3                	mov    %esi,%ebx
  800ac1:	80 fb 19             	cmp    $0x19,%bl
  800ac4:	77 16                	ja     800adc <strtol+0xbd>
			dig = *s - 'A' + 10;
  800ac6:	0f be d2             	movsbl %dl,%edx
  800ac9:	83 ea 37             	sub    $0x37,%edx
		else
			break;
		if (dig >= base)
  800acc:	3b 55 10             	cmp    0x10(%ebp),%edx
  800acf:	7d 0b                	jge    800adc <strtol+0xbd>
			break;
		s++, val = (val * base) + dig;
  800ad1:	83 c1 01             	add    $0x1,%ecx
  800ad4:	0f af 45 10          	imul   0x10(%ebp),%eax
  800ad8:	01 d0                	add    %edx,%eax
		// we don't properly detect overflow!
	}
  800ada:	eb b9                	jmp    800a95 <strtol+0x76>

	if (endptr)
  800adc:	83 7d 0c 00          	cmpl   $0x0,0xc(%ebp)
  800ae0:	74 0d                	je     800aef <strtol+0xd0>
		*endptr = (char *) s;
  800ae2:	8b 75 0c             	mov    0xc(%ebp),%esi
  800ae5:	89 0e                	mov    %ecx,(%esi)
  800ae7:	eb 06                	jmp    800aef <strtol+0xd0>
		s++, neg = 1;

	// hex or octal base prefix
	if ((base == 0 || base == 16) && (s[0] == '0' && s[1] == 'x'))
		s += 2, base = 16;
	else if (base == 0 && s[0] == '0')
  800ae9:	85 db                	test   %ebx,%ebx
  800aeb:	74 98                	je     800a85 <strtol+0x66>
  800aed:	eb 9e                	jmp    800a8d <strtol+0x6e>
		// we don't properly detect overflow!
	}

	if (endptr)
		*endptr = (char *) s;
	return (neg ? -val : val);
  800aef:	89 c2                	mov    %eax,%edx
  800af1:	f7 da                	neg    %edx
  800af3:	85 ff                	test   %edi,%edi
  800af5:	0f 45 c2             	cmovne %edx,%eax
}
  800af8:	5b                   	pop    %ebx
  800af9:	5e                   	pop    %esi
  800afa:	5f                   	pop    %edi
  800afb:	5d                   	pop    %ebp
  800afc:	c3                   	ret    
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
