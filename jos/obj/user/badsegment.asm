
obj/user/badsegment:     file format elf32-i386


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
  80002c:	e8 0d 00 00 00       	call   80003e <libmain>
1:	jmp 1b
  800031:	eb fe                	jmp    800031 <args_exist+0x5>

00800033 <umain>:

#include <inc/lib.h>

void
umain(int argc, char **argv)
{
  800033:	55                   	push   %ebp
  800034:	89 e5                	mov    %esp,%ebp
	// Try to load the kernel's TSS selector into the DS register.
	asm volatile("movw $0x28,%ax; movw %ax,%ds");
  800036:	66 b8 28 00          	mov    $0x28,%ax
  80003a:	8e d8                	mov    %eax,%ds
}
  80003c:	5d                   	pop    %ebp
  80003d:	c3                   	ret    

0080003e <libmain>:
const volatile struct Env *thisenv;
const char *binaryname = "<unknown>";

void
libmain(int argc, char **argv)
{
  80003e:	55                   	push   %ebp
  80003f:	89 e5                	mov    %esp,%ebp
  800041:	83 ec 08             	sub    $0x8,%esp
  800044:	8b 45 08             	mov    0x8(%ebp),%eax
  800047:	8b 55 0c             	mov    0xc(%ebp),%edx
	// set thisenv to point at our Env structure in envs[].
	// LAB 3: Your code here.
	thisenv = 0;
  80004a:	c7 05 04 10 80 00 00 	movl   $0x0,0x801004
  800051:	00 00 00 

	// save the name of the program so that panic() can use it
	if (argc > 0)
  800054:	85 c0                	test   %eax,%eax
  800056:	7e 08                	jle    800060 <libmain+0x22>
		binaryname = argv[0];
  800058:	8b 0a                	mov    (%edx),%ecx
  80005a:	89 0d 00 10 80 00    	mov    %ecx,0x801000

	// call user main routine
	umain(argc, argv);
  800060:	83 ec 08             	sub    $0x8,%esp
  800063:	52                   	push   %edx
  800064:	50                   	push   %eax
  800065:	e8 c9 ff ff ff       	call   800033 <umain>

	// exit gracefully
	exit();
  80006a:	e8 05 00 00 00       	call   800074 <exit>
}
  80006f:	83 c4 10             	add    $0x10,%esp
  800072:	c9                   	leave  
  800073:	c3                   	ret    

00800074 <exit>:

#include <inc/lib.h>

void
exit(void)
{
  800074:	55                   	push   %ebp
  800075:	89 e5                	mov    %esp,%ebp
  800077:	83 ec 14             	sub    $0x14,%esp
	sys_env_destroy(0);
  80007a:	6a 00                	push   $0x0
  80007c:	e8 99 00 00 00       	call   80011a <sys_env_destroy>
}
  800081:	83 c4 10             	add    $0x10,%esp
  800084:	c9                   	leave  
  800085:	c3                   	ret    

00800086 <syscall>:
#include <inc/syscall.h>
#include <inc/lib.h>

static inline int32_t
syscall(int num, int check, uint32_t a1, uint32_t a2, uint32_t a3, uint32_t a4, uint32_t a5)
{
  800086:	55                   	push   %ebp
  800087:	89 e5                	mov    %esp,%ebp
  800089:	57                   	push   %edi
  80008a:	56                   	push   %esi
  80008b:	53                   	push   %ebx
  80008c:	83 ec 1c             	sub    $0x1c,%esp
  80008f:	89 45 e0             	mov    %eax,-0x20(%ebp)
  800092:	89 55 e4             	mov    %edx,-0x1c(%ebp)
  800095:	89 ca                	mov    %ecx,%edx
	//
	// The last clause tells the assembler that this can
	// potentially change the condition codes and arbitrary
	// memory locations.

	asm volatile("int %1\n"
  800097:	8b 4d 08             	mov    0x8(%ebp),%ecx
  80009a:	8b 5d 0c             	mov    0xc(%ebp),%ebx
  80009d:	8b 7d 10             	mov    0x10(%ebp),%edi
  8000a0:	8b 75 14             	mov    0x14(%ebp),%esi
  8000a3:	cd 30                	int    $0x30
		       "b" (a3),
		       "D" (a4),
		       "S" (a5)
		     : "cc", "memory");

	if(check && ret > 0)
  8000a5:	83 7d e4 00          	cmpl   $0x0,-0x1c(%ebp)
  8000a9:	74 1d                	je     8000c8 <syscall+0x42>
  8000ab:	85 c0                	test   %eax,%eax
  8000ad:	7e 19                	jle    8000c8 <syscall+0x42>
  8000af:	8b 55 e0             	mov    -0x20(%ebp),%edx
		panic("syscall %d returned %d (> 0)", num, ret);
  8000b2:	83 ec 0c             	sub    $0xc,%esp
  8000b5:	50                   	push   %eax
  8000b6:	52                   	push   %edx
  8000b7:	68 8e 0d 80 00       	push   $0x800d8e
  8000bc:	6a 23                	push   $0x23
  8000be:	68 ab 0d 80 00       	push   $0x800dab
  8000c3:	e8 98 00 00 00       	call   800160 <_panic>

	return ret;
}
  8000c8:	8d 65 f4             	lea    -0xc(%ebp),%esp
  8000cb:	5b                   	pop    %ebx
  8000cc:	5e                   	pop    %esi
  8000cd:	5f                   	pop    %edi
  8000ce:	5d                   	pop    %ebp
  8000cf:	c3                   	ret    

008000d0 <sys_cputs>:

void
sys_cputs(const char *s, size_t len)
{
  8000d0:	55                   	push   %ebp
  8000d1:	89 e5                	mov    %esp,%ebp
  8000d3:	83 ec 08             	sub    $0x8,%esp
	syscall(SYS_cputs, 0, (uint32_t)s, len, 0, 0, 0);
  8000d6:	6a 00                	push   $0x0
  8000d8:	6a 00                	push   $0x0
  8000da:	6a 00                	push   $0x0
  8000dc:	ff 75 0c             	pushl  0xc(%ebp)
  8000df:	8b 4d 08             	mov    0x8(%ebp),%ecx
  8000e2:	ba 00 00 00 00       	mov    $0x0,%edx
  8000e7:	b8 00 00 00 00       	mov    $0x0,%eax
  8000ec:	e8 95 ff ff ff       	call   800086 <syscall>
}
  8000f1:	83 c4 10             	add    $0x10,%esp
  8000f4:	c9                   	leave  
  8000f5:	c3                   	ret    

008000f6 <sys_cgetc>:

int
sys_cgetc(void)
{
  8000f6:	55                   	push   %ebp
  8000f7:	89 e5                	mov    %esp,%ebp
  8000f9:	83 ec 08             	sub    $0x8,%esp
	return syscall(SYS_cgetc, 0, 0, 0, 0, 0, 0);
  8000fc:	6a 00                	push   $0x0
  8000fe:	6a 00                	push   $0x0
  800100:	6a 00                	push   $0x0
  800102:	6a 00                	push   $0x0
  800104:	b9 00 00 00 00       	mov    $0x0,%ecx
  800109:	ba 00 00 00 00       	mov    $0x0,%edx
  80010e:	b8 01 00 00 00       	mov    $0x1,%eax
  800113:	e8 6e ff ff ff       	call   800086 <syscall>
}
  800118:	c9                   	leave  
  800119:	c3                   	ret    

0080011a <sys_env_destroy>:

int
sys_env_destroy(envid_t envid)
{
  80011a:	55                   	push   %ebp
  80011b:	89 e5                	mov    %esp,%ebp
  80011d:	83 ec 08             	sub    $0x8,%esp
	return syscall(SYS_env_destroy, 1, envid, 0, 0, 0, 0);
  800120:	6a 00                	push   $0x0
  800122:	6a 00                	push   $0x0
  800124:	6a 00                	push   $0x0
  800126:	6a 00                	push   $0x0
  800128:	8b 4d 08             	mov    0x8(%ebp),%ecx
  80012b:	ba 01 00 00 00       	mov    $0x1,%edx
  800130:	b8 03 00 00 00       	mov    $0x3,%eax
  800135:	e8 4c ff ff ff       	call   800086 <syscall>
}
  80013a:	c9                   	leave  
  80013b:	c3                   	ret    

0080013c <sys_getenvid>:

envid_t
sys_getenvid(void)
{
  80013c:	55                   	push   %ebp
  80013d:	89 e5                	mov    %esp,%ebp
  80013f:	83 ec 08             	sub    $0x8,%esp
	 return syscall(SYS_getenvid, 0, 0, 0, 0, 0, 0);
  800142:	6a 00                	push   $0x0
  800144:	6a 00                	push   $0x0
  800146:	6a 00                	push   $0x0
  800148:	6a 00                	push   $0x0
  80014a:	b9 00 00 00 00       	mov    $0x0,%ecx
  80014f:	ba 00 00 00 00       	mov    $0x0,%edx
  800154:	b8 02 00 00 00       	mov    $0x2,%eax
  800159:	e8 28 ff ff ff       	call   800086 <syscall>
}
  80015e:	c9                   	leave  
  80015f:	c3                   	ret    

00800160 <_panic>:
 * It prints "panic: <message>", then causes a breakpoint exception,
 * which causes JOS to enter the JOS kernel monitor.
 */
void
_panic(const char *file, int line, const char *fmt, ...)
{
  800160:	55                   	push   %ebp
  800161:	89 e5                	mov    %esp,%ebp
  800163:	56                   	push   %esi
  800164:	53                   	push   %ebx
	va_list ap;

	va_start(ap, fmt);
  800165:	8d 5d 14             	lea    0x14(%ebp),%ebx

	// Print the panic message
	cprintf("[%08x] user panic in %s at %s:%d: ",
  800168:	8b 35 00 10 80 00    	mov    0x801000,%esi
  80016e:	e8 c9 ff ff ff       	call   80013c <sys_getenvid>
  800173:	83 ec 0c             	sub    $0xc,%esp
  800176:	ff 75 0c             	pushl  0xc(%ebp)
  800179:	ff 75 08             	pushl  0x8(%ebp)
  80017c:	56                   	push   %esi
  80017d:	50                   	push   %eax
  80017e:	68 bc 0d 80 00       	push   $0x800dbc
  800183:	e8 b1 00 00 00       	call   800239 <cprintf>
		sys_getenvid(), binaryname, file, line);
	vcprintf(fmt, ap);
  800188:	83 c4 18             	add    $0x18,%esp
  80018b:	53                   	push   %ebx
  80018c:	ff 75 10             	pushl  0x10(%ebp)
  80018f:	e8 54 00 00 00       	call   8001e8 <vcprintf>
	cprintf("\n");
  800194:	c7 04 24 e0 0d 80 00 	movl   $0x800de0,(%esp)
  80019b:	e8 99 00 00 00       	call   800239 <cprintf>
  8001a0:	83 c4 10             	add    $0x10,%esp

	// Cause a breakpoint exception
	while (1)
		asm volatile("int3");
  8001a3:	cc                   	int3   
  8001a4:	eb fd                	jmp    8001a3 <_panic+0x43>

008001a6 <putch>:
};


static void
putch(int ch, struct printbuf *b)
{
  8001a6:	55                   	push   %ebp
  8001a7:	89 e5                	mov    %esp,%ebp
  8001a9:	53                   	push   %ebx
  8001aa:	83 ec 04             	sub    $0x4,%esp
  8001ad:	8b 5d 0c             	mov    0xc(%ebp),%ebx
	b->buf[b->idx++] = ch;
  8001b0:	8b 13                	mov    (%ebx),%edx
  8001b2:	8d 42 01             	lea    0x1(%edx),%eax
  8001b5:	89 03                	mov    %eax,(%ebx)
  8001b7:	8b 4d 08             	mov    0x8(%ebp),%ecx
  8001ba:	88 4c 13 08          	mov    %cl,0x8(%ebx,%edx,1)
	if (b->idx == 256-1) {
  8001be:	3d ff 00 00 00       	cmp    $0xff,%eax
  8001c3:	75 1a                	jne    8001df <putch+0x39>
		sys_cputs(b->buf, b->idx);
  8001c5:	83 ec 08             	sub    $0x8,%esp
  8001c8:	68 ff 00 00 00       	push   $0xff
  8001cd:	8d 43 08             	lea    0x8(%ebx),%eax
  8001d0:	50                   	push   %eax
  8001d1:	e8 fa fe ff ff       	call   8000d0 <sys_cputs>
		b->idx = 0;
  8001d6:	c7 03 00 00 00 00    	movl   $0x0,(%ebx)
  8001dc:	83 c4 10             	add    $0x10,%esp
	}
	b->cnt++;
  8001df:	83 43 04 01          	addl   $0x1,0x4(%ebx)
}
  8001e3:	8b 5d fc             	mov    -0x4(%ebp),%ebx
  8001e6:	c9                   	leave  
  8001e7:	c3                   	ret    

008001e8 <vcprintf>:

int
vcprintf(const char *fmt, va_list ap)
{
  8001e8:	55                   	push   %ebp
  8001e9:	89 e5                	mov    %esp,%ebp
  8001eb:	81 ec 18 01 00 00    	sub    $0x118,%esp
	struct printbuf b;

	b.idx = 0;
  8001f1:	c7 85 f0 fe ff ff 00 	movl   $0x0,-0x110(%ebp)
  8001f8:	00 00 00 
	b.cnt = 0;
  8001fb:	c7 85 f4 fe ff ff 00 	movl   $0x0,-0x10c(%ebp)
  800202:	00 00 00 
	vprintfmt((void*)putch, &b, fmt, ap);
  800205:	ff 75 0c             	pushl  0xc(%ebp)
  800208:	ff 75 08             	pushl  0x8(%ebp)
  80020b:	8d 85 f0 fe ff ff    	lea    -0x110(%ebp),%eax
  800211:	50                   	push   %eax
  800212:	68 a6 01 80 00       	push   $0x8001a6
  800217:	e8 86 01 00 00       	call   8003a2 <vprintfmt>
	sys_cputs(b.buf, b.idx);
  80021c:	83 c4 08             	add    $0x8,%esp
  80021f:	ff b5 f0 fe ff ff    	pushl  -0x110(%ebp)
  800225:	8d 85 f8 fe ff ff    	lea    -0x108(%ebp),%eax
  80022b:	50                   	push   %eax
  80022c:	e8 9f fe ff ff       	call   8000d0 <sys_cputs>

	return b.cnt;
}
  800231:	8b 85 f4 fe ff ff    	mov    -0x10c(%ebp),%eax
  800237:	c9                   	leave  
  800238:	c3                   	ret    

00800239 <cprintf>:

int
cprintf(const char *fmt, ...)
{
  800239:	55                   	push   %ebp
  80023a:	89 e5                	mov    %esp,%ebp
  80023c:	83 ec 10             	sub    $0x10,%esp
	va_list ap;
	int cnt;

	va_start(ap, fmt);
  80023f:	8d 45 0c             	lea    0xc(%ebp),%eax
	cnt = vcprintf(fmt, ap);
  800242:	50                   	push   %eax
  800243:	ff 75 08             	pushl  0x8(%ebp)
  800246:	e8 9d ff ff ff       	call   8001e8 <vcprintf>
	va_end(ap);

	return cnt;
}
  80024b:	c9                   	leave  
  80024c:	c3                   	ret    

0080024d <printnum>:
 * using specified putch function and associated pointer putdat.
 */
static void
printnum(void (*putch)(int, void*), void *putdat,
	 unsigned long long num, unsigned base, int width, int padc)
{
  80024d:	55                   	push   %ebp
  80024e:	89 e5                	mov    %esp,%ebp
  800250:	57                   	push   %edi
  800251:	56                   	push   %esi
  800252:	53                   	push   %ebx
  800253:	83 ec 1c             	sub    $0x1c,%esp
  800256:	89 c7                	mov    %eax,%edi
  800258:	89 d6                	mov    %edx,%esi
  80025a:	8b 45 08             	mov    0x8(%ebp),%eax
  80025d:	8b 55 0c             	mov    0xc(%ebp),%edx
  800260:	89 45 d8             	mov    %eax,-0x28(%ebp)
  800263:	89 55 dc             	mov    %edx,-0x24(%ebp)
	// first recursively print all preceding (more significant) digits
	if (num >= base) {
  800266:	8b 4d 10             	mov    0x10(%ebp),%ecx
  800269:	bb 00 00 00 00       	mov    $0x0,%ebx
  80026e:	89 4d e0             	mov    %ecx,-0x20(%ebp)
  800271:	89 5d e4             	mov    %ebx,-0x1c(%ebp)
  800274:	39 d3                	cmp    %edx,%ebx
  800276:	72 05                	jb     80027d <printnum+0x30>
  800278:	39 45 10             	cmp    %eax,0x10(%ebp)
  80027b:	77 45                	ja     8002c2 <printnum+0x75>
		printnum(putch, putdat, num / base, base, width - 1, padc);
  80027d:	83 ec 0c             	sub    $0xc,%esp
  800280:	ff 75 18             	pushl  0x18(%ebp)
  800283:	8b 45 14             	mov    0x14(%ebp),%eax
  800286:	8d 58 ff             	lea    -0x1(%eax),%ebx
  800289:	53                   	push   %ebx
  80028a:	ff 75 10             	pushl  0x10(%ebp)
  80028d:	83 ec 08             	sub    $0x8,%esp
  800290:	ff 75 e4             	pushl  -0x1c(%ebp)
  800293:	ff 75 e0             	pushl  -0x20(%ebp)
  800296:	ff 75 dc             	pushl  -0x24(%ebp)
  800299:	ff 75 d8             	pushl  -0x28(%ebp)
  80029c:	e8 5f 08 00 00       	call   800b00 <__udivdi3>
  8002a1:	83 c4 18             	add    $0x18,%esp
  8002a4:	52                   	push   %edx
  8002a5:	50                   	push   %eax
  8002a6:	89 f2                	mov    %esi,%edx
  8002a8:	89 f8                	mov    %edi,%eax
  8002aa:	e8 9e ff ff ff       	call   80024d <printnum>
  8002af:	83 c4 20             	add    $0x20,%esp
  8002b2:	eb 18                	jmp    8002cc <printnum+0x7f>
	} else {
		// print any needed pad characters before first digit
		while (--width > 0)
			putch(padc, putdat);
  8002b4:	83 ec 08             	sub    $0x8,%esp
  8002b7:	56                   	push   %esi
  8002b8:	ff 75 18             	pushl  0x18(%ebp)
  8002bb:	ff d7                	call   *%edi
  8002bd:	83 c4 10             	add    $0x10,%esp
  8002c0:	eb 03                	jmp    8002c5 <printnum+0x78>
  8002c2:	8b 5d 14             	mov    0x14(%ebp),%ebx
	// first recursively print all preceding (more significant) digits
	if (num >= base) {
		printnum(putch, putdat, num / base, base, width - 1, padc);
	} else {
		// print any needed pad characters before first digit
		while (--width > 0)
  8002c5:	83 eb 01             	sub    $0x1,%ebx
  8002c8:	85 db                	test   %ebx,%ebx
  8002ca:	7f e8                	jg     8002b4 <printnum+0x67>
			putch(padc, putdat);
	}

	// then print this (the least significant) digit
	putch("0123456789abcdef"[num % base], putdat);
  8002cc:	83 ec 08             	sub    $0x8,%esp
  8002cf:	56                   	push   %esi
  8002d0:	83 ec 04             	sub    $0x4,%esp
  8002d3:	ff 75 e4             	pushl  -0x1c(%ebp)
  8002d6:	ff 75 e0             	pushl  -0x20(%ebp)
  8002d9:	ff 75 dc             	pushl  -0x24(%ebp)
  8002dc:	ff 75 d8             	pushl  -0x28(%ebp)
  8002df:	e8 4c 09 00 00       	call   800c30 <__umoddi3>
  8002e4:	83 c4 14             	add    $0x14,%esp
  8002e7:	0f be 80 e2 0d 80 00 	movsbl 0x800de2(%eax),%eax
  8002ee:	50                   	push   %eax
  8002ef:	ff d7                	call   *%edi
}
  8002f1:	83 c4 10             	add    $0x10,%esp
  8002f4:	8d 65 f4             	lea    -0xc(%ebp),%esp
  8002f7:	5b                   	pop    %ebx
  8002f8:	5e                   	pop    %esi
  8002f9:	5f                   	pop    %edi
  8002fa:	5d                   	pop    %ebp
  8002fb:	c3                   	ret    

008002fc <getuint>:

// Get an unsigned int of various possible sizes from a varargs list,
// depending on the lflag parameter.
static unsigned long long
getuint(va_list *ap, int lflag)
{
  8002fc:	55                   	push   %ebp
  8002fd:	89 e5                	mov    %esp,%ebp
	if (lflag >= 2)
  8002ff:	83 fa 01             	cmp    $0x1,%edx
  800302:	7e 0e                	jle    800312 <getuint+0x16>
		return va_arg(*ap, unsigned long long);
  800304:	8b 10                	mov    (%eax),%edx
  800306:	8d 4a 08             	lea    0x8(%edx),%ecx
  800309:	89 08                	mov    %ecx,(%eax)
  80030b:	8b 02                	mov    (%edx),%eax
  80030d:	8b 52 04             	mov    0x4(%edx),%edx
  800310:	eb 22                	jmp    800334 <getuint+0x38>
	else if (lflag)
  800312:	85 d2                	test   %edx,%edx
  800314:	74 10                	je     800326 <getuint+0x2a>
		return va_arg(*ap, unsigned long);
  800316:	8b 10                	mov    (%eax),%edx
  800318:	8d 4a 04             	lea    0x4(%edx),%ecx
  80031b:	89 08                	mov    %ecx,(%eax)
  80031d:	8b 02                	mov    (%edx),%eax
  80031f:	ba 00 00 00 00       	mov    $0x0,%edx
  800324:	eb 0e                	jmp    800334 <getuint+0x38>
	else
		return va_arg(*ap, unsigned int);
  800326:	8b 10                	mov    (%eax),%edx
  800328:	8d 4a 04             	lea    0x4(%edx),%ecx
  80032b:	89 08                	mov    %ecx,(%eax)
  80032d:	8b 02                	mov    (%edx),%eax
  80032f:	ba 00 00 00 00       	mov    $0x0,%edx
}
  800334:	5d                   	pop    %ebp
  800335:	c3                   	ret    

00800336 <getint>:

// Same as getuint but signed - can't use getuint
// because of sign extension
static long long
getint(va_list *ap, int lflag)
{
  800336:	55                   	push   %ebp
  800337:	89 e5                	mov    %esp,%ebp
	if (lflag >= 2)
  800339:	83 fa 01             	cmp    $0x1,%edx
  80033c:	7e 0e                	jle    80034c <getint+0x16>
		return va_arg(*ap, long long);
  80033e:	8b 10                	mov    (%eax),%edx
  800340:	8d 4a 08             	lea    0x8(%edx),%ecx
  800343:	89 08                	mov    %ecx,(%eax)
  800345:	8b 02                	mov    (%edx),%eax
  800347:	8b 52 04             	mov    0x4(%edx),%edx
  80034a:	eb 1a                	jmp    800366 <getint+0x30>
	else if (lflag)
  80034c:	85 d2                	test   %edx,%edx
  80034e:	74 0c                	je     80035c <getint+0x26>
		return va_arg(*ap, long);
  800350:	8b 10                	mov    (%eax),%edx
  800352:	8d 4a 04             	lea    0x4(%edx),%ecx
  800355:	89 08                	mov    %ecx,(%eax)
  800357:	8b 02                	mov    (%edx),%eax
  800359:	99                   	cltd   
  80035a:	eb 0a                	jmp    800366 <getint+0x30>
	else
		return va_arg(*ap, int);
  80035c:	8b 10                	mov    (%eax),%edx
  80035e:	8d 4a 04             	lea    0x4(%edx),%ecx
  800361:	89 08                	mov    %ecx,(%eax)
  800363:	8b 02                	mov    (%edx),%eax
  800365:	99                   	cltd   
}
  800366:	5d                   	pop    %ebp
  800367:	c3                   	ret    

00800368 <sprintputch>:
	int cnt;
};

static void
sprintputch(int ch, struct sprintbuf *b)
{
  800368:	55                   	push   %ebp
  800369:	89 e5                	mov    %esp,%ebp
  80036b:	8b 45 0c             	mov    0xc(%ebp),%eax
	b->cnt++;
  80036e:	83 40 08 01          	addl   $0x1,0x8(%eax)
	if (b->buf < b->ebuf)
  800372:	8b 10                	mov    (%eax),%edx
  800374:	3b 50 04             	cmp    0x4(%eax),%edx
  800377:	73 0a                	jae    800383 <sprintputch+0x1b>
		*b->buf++ = ch;
  800379:	8d 4a 01             	lea    0x1(%edx),%ecx
  80037c:	89 08                	mov    %ecx,(%eax)
  80037e:	8b 45 08             	mov    0x8(%ebp),%eax
  800381:	88 02                	mov    %al,(%edx)
}
  800383:	5d                   	pop    %ebp
  800384:	c3                   	ret    

00800385 <printfmt>:
	}
}

void
printfmt(void (*putch)(int, void*), void *putdat, const char *fmt, ...)
{
  800385:	55                   	push   %ebp
  800386:	89 e5                	mov    %esp,%ebp
  800388:	83 ec 08             	sub    $0x8,%esp
	va_list ap;

	va_start(ap, fmt);
  80038b:	8d 45 14             	lea    0x14(%ebp),%eax
	vprintfmt(putch, putdat, fmt, ap);
  80038e:	50                   	push   %eax
  80038f:	ff 75 10             	pushl  0x10(%ebp)
  800392:	ff 75 0c             	pushl  0xc(%ebp)
  800395:	ff 75 08             	pushl  0x8(%ebp)
  800398:	e8 05 00 00 00       	call   8003a2 <vprintfmt>
	va_end(ap);
}
  80039d:	83 c4 10             	add    $0x10,%esp
  8003a0:	c9                   	leave  
  8003a1:	c3                   	ret    

008003a2 <vprintfmt>:
// Main function to format and print a string.
void printfmt(void (*putch)(int, void*), void *putdat, const char *fmt, ...);

void
vprintfmt(void (*putch)(int, void*), void *putdat, const char *fmt, va_list ap)
{
  8003a2:	55                   	push   %ebp
  8003a3:	89 e5                	mov    %esp,%ebp
  8003a5:	57                   	push   %edi
  8003a6:	56                   	push   %esi
  8003a7:	53                   	push   %ebx
  8003a8:	83 ec 2c             	sub    $0x2c,%esp
  8003ab:	8b 75 08             	mov    0x8(%ebp),%esi
  8003ae:	8b 5d 0c             	mov    0xc(%ebp),%ebx
  8003b1:	8b 7d 10             	mov    0x10(%ebp),%edi
  8003b4:	eb 12                	jmp    8003c8 <vprintfmt+0x26>
	int base, lflag, width, precision, altflag;
	char padc;

	while (1) {
		while ((ch = *(unsigned char *) fmt++) != '%') {
			if (ch == '\0')
  8003b6:	85 c0                	test   %eax,%eax
  8003b8:	0f 84 44 03 00 00    	je     800702 <vprintfmt+0x360>
				return;
			putch(ch, putdat);
  8003be:	83 ec 08             	sub    $0x8,%esp
  8003c1:	53                   	push   %ebx
  8003c2:	50                   	push   %eax
  8003c3:	ff d6                	call   *%esi
  8003c5:	83 c4 10             	add    $0x10,%esp
	unsigned long long num;
	int base, lflag, width, precision, altflag;
	char padc;

	while (1) {
		while ((ch = *(unsigned char *) fmt++) != '%') {
  8003c8:	83 c7 01             	add    $0x1,%edi
  8003cb:	0f b6 47 ff          	movzbl -0x1(%edi),%eax
  8003cf:	83 f8 25             	cmp    $0x25,%eax
  8003d2:	75 e2                	jne    8003b6 <vprintfmt+0x14>
  8003d4:	c6 45 d4 20          	movb   $0x20,-0x2c(%ebp)
  8003d8:	c7 45 d8 00 00 00 00 	movl   $0x0,-0x28(%ebp)
  8003df:	c7 45 d0 ff ff ff ff 	movl   $0xffffffff,-0x30(%ebp)
  8003e6:	c7 45 e0 ff ff ff ff 	movl   $0xffffffff,-0x20(%ebp)
  8003ed:	ba 00 00 00 00       	mov    $0x0,%edx
  8003f2:	eb 07                	jmp    8003fb <vprintfmt+0x59>
		width = -1;
		precision = -1;
		lflag = 0;
		altflag = 0;
	reswitch:
		switch (ch = *(unsigned char *) fmt++) {
  8003f4:	8b 7d e4             	mov    -0x1c(%ebp),%edi

		// flag to pad on the right
		case '-':
			padc = '-';
  8003f7:	c6 45 d4 2d          	movb   $0x2d,-0x2c(%ebp)
		width = -1;
		precision = -1;
		lflag = 0;
		altflag = 0;
	reswitch:
		switch (ch = *(unsigned char *) fmt++) {
  8003fb:	8d 47 01             	lea    0x1(%edi),%eax
  8003fe:	89 45 e4             	mov    %eax,-0x1c(%ebp)
  800401:	0f b6 07             	movzbl (%edi),%eax
  800404:	0f b6 c8             	movzbl %al,%ecx
  800407:	83 e8 23             	sub    $0x23,%eax
  80040a:	3c 55                	cmp    $0x55,%al
  80040c:	0f 87 d5 02 00 00    	ja     8006e7 <vprintfmt+0x345>
  800412:	0f b6 c0             	movzbl %al,%eax
  800415:	ff 24 85 70 0e 80 00 	jmp    *0x800e70(,%eax,4)
  80041c:	8b 7d e4             	mov    -0x1c(%ebp),%edi
			padc = '-';
			goto reswitch;

		// flag to pad with 0's instead of spaces
		case '0':
			padc = '0';
  80041f:	c6 45 d4 30          	movb   $0x30,-0x2c(%ebp)
  800423:	eb d6                	jmp    8003fb <vprintfmt+0x59>
		width = -1;
		precision = -1;
		lflag = 0;
		altflag = 0;
	reswitch:
		switch (ch = *(unsigned char *) fmt++) {
  800425:	8b 7d e4             	mov    -0x1c(%ebp),%edi
  800428:	b8 00 00 00 00       	mov    $0x0,%eax
  80042d:	89 55 e4             	mov    %edx,-0x1c(%ebp)
		case '6':
		case '7':
		case '8':
		case '9':
			for (precision = 0; ; ++fmt) {
				precision = precision * 10 + ch - '0';
  800430:	8d 04 80             	lea    (%eax,%eax,4),%eax
  800433:	8d 44 41 d0          	lea    -0x30(%ecx,%eax,2),%eax
				ch = *fmt;
  800437:	0f be 0f             	movsbl (%edi),%ecx
				if (ch < '0' || ch > '9')
  80043a:	8d 51 d0             	lea    -0x30(%ecx),%edx
  80043d:	83 fa 09             	cmp    $0x9,%edx
  800440:	77 39                	ja     80047b <vprintfmt+0xd9>
		case '5':
		case '6':
		case '7':
		case '8':
		case '9':
			for (precision = 0; ; ++fmt) {
  800442:	83 c7 01             	add    $0x1,%edi
				precision = precision * 10 + ch - '0';
				ch = *fmt;
				if (ch < '0' || ch > '9')
					break;
			}
  800445:	eb e9                	jmp    800430 <vprintfmt+0x8e>
			goto process_precision;

		case '*':
			precision = va_arg(ap, int);
  800447:	8b 45 14             	mov    0x14(%ebp),%eax
  80044a:	8d 48 04             	lea    0x4(%eax),%ecx
  80044d:	89 4d 14             	mov    %ecx,0x14(%ebp)
  800450:	8b 00                	mov    (%eax),%eax
  800452:	89 45 d0             	mov    %eax,-0x30(%ebp)
		width = -1;
		precision = -1;
		lflag = 0;
		altflag = 0;
	reswitch:
		switch (ch = *(unsigned char *) fmt++) {
  800455:	8b 7d e4             	mov    -0x1c(%ebp),%edi
			}
			goto process_precision;

		case '*':
			precision = va_arg(ap, int);
			goto process_precision;
  800458:	eb 27                	jmp    800481 <vprintfmt+0xdf>
  80045a:	8b 45 e0             	mov    -0x20(%ebp),%eax
  80045d:	85 c0                	test   %eax,%eax
  80045f:	b9 00 00 00 00       	mov    $0x0,%ecx
  800464:	0f 49 c8             	cmovns %eax,%ecx
  800467:	89 4d e0             	mov    %ecx,-0x20(%ebp)
		width = -1;
		precision = -1;
		lflag = 0;
		altflag = 0;
	reswitch:
		switch (ch = *(unsigned char *) fmt++) {
  80046a:	8b 7d e4             	mov    -0x1c(%ebp),%edi
  80046d:	eb 8c                	jmp    8003fb <vprintfmt+0x59>
  80046f:	8b 7d e4             	mov    -0x1c(%ebp),%edi
			if (width < 0)
				width = 0;
			goto reswitch;

		case '#':
			altflag = 1;
  800472:	c7 45 d8 01 00 00 00 	movl   $0x1,-0x28(%ebp)
			goto reswitch;
  800479:	eb 80                	jmp    8003fb <vprintfmt+0x59>
  80047b:	8b 55 e4             	mov    -0x1c(%ebp),%edx
  80047e:	89 45 d0             	mov    %eax,-0x30(%ebp)

		process_precision:
			if (width < 0)
  800481:	83 7d e0 00          	cmpl   $0x0,-0x20(%ebp)
  800485:	0f 89 70 ff ff ff    	jns    8003fb <vprintfmt+0x59>
				width = precision, precision = -1;
  80048b:	8b 45 d0             	mov    -0x30(%ebp),%eax
  80048e:	89 45 e0             	mov    %eax,-0x20(%ebp)
  800491:	c7 45 d0 ff ff ff ff 	movl   $0xffffffff,-0x30(%ebp)
  800498:	e9 5e ff ff ff       	jmp    8003fb <vprintfmt+0x59>
			goto reswitch;

		// long flag (doubled for long long)
		case 'l':
			lflag++;
  80049d:	83 c2 01             	add    $0x1,%edx
		width = -1;
		precision = -1;
		lflag = 0;
		altflag = 0;
	reswitch:
		switch (ch = *(unsigned char *) fmt++) {
  8004a0:	8b 7d e4             	mov    -0x1c(%ebp),%edi
			goto reswitch;

		// long flag (doubled for long long)
		case 'l':
			lflag++;
			goto reswitch;
  8004a3:	e9 53 ff ff ff       	jmp    8003fb <vprintfmt+0x59>

		// character
		case 'c':
			putch(va_arg(ap, int), putdat);
  8004a8:	8b 45 14             	mov    0x14(%ebp),%eax
  8004ab:	8d 50 04             	lea    0x4(%eax),%edx
  8004ae:	89 55 14             	mov    %edx,0x14(%ebp)
  8004b1:	83 ec 08             	sub    $0x8,%esp
  8004b4:	53                   	push   %ebx
  8004b5:	ff 30                	pushl  (%eax)
  8004b7:	ff d6                	call   *%esi
			break;
  8004b9:	83 c4 10             	add    $0x10,%esp
		width = -1;
		precision = -1;
		lflag = 0;
		altflag = 0;
	reswitch:
		switch (ch = *(unsigned char *) fmt++) {
  8004bc:	8b 7d e4             	mov    -0x1c(%ebp),%edi
			goto reswitch;

		// character
		case 'c':
			putch(va_arg(ap, int), putdat);
			break;
  8004bf:	e9 04 ff ff ff       	jmp    8003c8 <vprintfmt+0x26>

		// error message
		case 'e':
			err = va_arg(ap, int);
  8004c4:	8b 45 14             	mov    0x14(%ebp),%eax
  8004c7:	8d 50 04             	lea    0x4(%eax),%edx
  8004ca:	89 55 14             	mov    %edx,0x14(%ebp)
  8004cd:	8b 00                	mov    (%eax),%eax
  8004cf:	99                   	cltd   
  8004d0:	31 d0                	xor    %edx,%eax
  8004d2:	29 d0                	sub    %edx,%eax
			if (err < 0)
				err = -err;
			if (err >= MAXERROR || (p = error_string[err]) == NULL)
  8004d4:	83 f8 06             	cmp    $0x6,%eax
  8004d7:	7f 0b                	jg     8004e4 <vprintfmt+0x142>
  8004d9:	8b 14 85 c8 0f 80 00 	mov    0x800fc8(,%eax,4),%edx
  8004e0:	85 d2                	test   %edx,%edx
  8004e2:	75 18                	jne    8004fc <vprintfmt+0x15a>
				printfmt(putch, putdat, "error %d", err);
  8004e4:	50                   	push   %eax
  8004e5:	68 fa 0d 80 00       	push   $0x800dfa
  8004ea:	53                   	push   %ebx
  8004eb:	56                   	push   %esi
  8004ec:	e8 94 fe ff ff       	call   800385 <printfmt>
  8004f1:	83 c4 10             	add    $0x10,%esp
		width = -1;
		precision = -1;
		lflag = 0;
		altflag = 0;
	reswitch:
		switch (ch = *(unsigned char *) fmt++) {
  8004f4:	8b 7d e4             	mov    -0x1c(%ebp),%edi
		case 'e':
			err = va_arg(ap, int);
			if (err < 0)
				err = -err;
			if (err >= MAXERROR || (p = error_string[err]) == NULL)
				printfmt(putch, putdat, "error %d", err);
  8004f7:	e9 cc fe ff ff       	jmp    8003c8 <vprintfmt+0x26>
			else
				printfmt(putch, putdat, "%s", p);
  8004fc:	52                   	push   %edx
  8004fd:	68 03 0e 80 00       	push   $0x800e03
  800502:	53                   	push   %ebx
  800503:	56                   	push   %esi
  800504:	e8 7c fe ff ff       	call   800385 <printfmt>
  800509:	83 c4 10             	add    $0x10,%esp
		width = -1;
		precision = -1;
		lflag = 0;
		altflag = 0;
	reswitch:
		switch (ch = *(unsigned char *) fmt++) {
  80050c:	8b 7d e4             	mov    -0x1c(%ebp),%edi
  80050f:	e9 b4 fe ff ff       	jmp    8003c8 <vprintfmt+0x26>
				printfmt(putch, putdat, "%s", p);
			break;

		// string
		case 's':
			if ((p = va_arg(ap, char *)) == NULL)
  800514:	8b 45 14             	mov    0x14(%ebp),%eax
  800517:	8d 50 04             	lea    0x4(%eax),%edx
  80051a:	89 55 14             	mov    %edx,0x14(%ebp)
  80051d:	8b 38                	mov    (%eax),%edi
				p = "(null)";
  80051f:	85 ff                	test   %edi,%edi
  800521:	b8 f3 0d 80 00       	mov    $0x800df3,%eax
  800526:	0f 44 f8             	cmove  %eax,%edi
			if (width > 0 && padc != '-')
  800529:	83 7d e0 00          	cmpl   $0x0,-0x20(%ebp)
  80052d:	0f 8e 94 00 00 00    	jle    8005c7 <vprintfmt+0x225>
  800533:	80 7d d4 2d          	cmpb   $0x2d,-0x2c(%ebp)
  800537:	0f 84 98 00 00 00    	je     8005d5 <vprintfmt+0x233>
				for (width -= strnlen(p, precision); width > 0; width--)
  80053d:	83 ec 08             	sub    $0x8,%esp
  800540:	ff 75 d0             	pushl  -0x30(%ebp)
  800543:	57                   	push   %edi
  800544:	e8 41 02 00 00       	call   80078a <strnlen>
  800549:	8b 4d e0             	mov    -0x20(%ebp),%ecx
  80054c:	29 c1                	sub    %eax,%ecx
  80054e:	89 4d cc             	mov    %ecx,-0x34(%ebp)
  800551:	83 c4 10             	add    $0x10,%esp
					putch(padc, putdat);
  800554:	0f be 45 d4          	movsbl -0x2c(%ebp),%eax
  800558:	89 45 e0             	mov    %eax,-0x20(%ebp)
  80055b:	89 7d d4             	mov    %edi,-0x2c(%ebp)
  80055e:	89 cf                	mov    %ecx,%edi
		// string
		case 's':
			if ((p = va_arg(ap, char *)) == NULL)
				p = "(null)";
			if (width > 0 && padc != '-')
				for (width -= strnlen(p, precision); width > 0; width--)
  800560:	eb 0f                	jmp    800571 <vprintfmt+0x1cf>
					putch(padc, putdat);
  800562:	83 ec 08             	sub    $0x8,%esp
  800565:	53                   	push   %ebx
  800566:	ff 75 e0             	pushl  -0x20(%ebp)
  800569:	ff d6                	call   *%esi
		// string
		case 's':
			if ((p = va_arg(ap, char *)) == NULL)
				p = "(null)";
			if (width > 0 && padc != '-')
				for (width -= strnlen(p, precision); width > 0; width--)
  80056b:	83 ef 01             	sub    $0x1,%edi
  80056e:	83 c4 10             	add    $0x10,%esp
  800571:	85 ff                	test   %edi,%edi
  800573:	7f ed                	jg     800562 <vprintfmt+0x1c0>
  800575:	8b 7d d4             	mov    -0x2c(%ebp),%edi
  800578:	8b 4d cc             	mov    -0x34(%ebp),%ecx
  80057b:	85 c9                	test   %ecx,%ecx
  80057d:	b8 00 00 00 00       	mov    $0x0,%eax
  800582:	0f 49 c1             	cmovns %ecx,%eax
  800585:	29 c1                	sub    %eax,%ecx
  800587:	89 75 08             	mov    %esi,0x8(%ebp)
  80058a:	8b 75 d0             	mov    -0x30(%ebp),%esi
  80058d:	89 5d 0c             	mov    %ebx,0xc(%ebp)
  800590:	89 cb                	mov    %ecx,%ebx
  800592:	eb 4d                	jmp    8005e1 <vprintfmt+0x23f>
					putch(padc, putdat);
			for (; (ch = *p++) != '\0' && (precision < 0 || --precision >= 0); width--)
				if (altflag && (ch < ' ' || ch > '~'))
  800594:	83 7d d8 00          	cmpl   $0x0,-0x28(%ebp)
  800598:	74 1b                	je     8005b5 <vprintfmt+0x213>
  80059a:	0f be c0             	movsbl %al,%eax
  80059d:	83 e8 20             	sub    $0x20,%eax
  8005a0:	83 f8 5e             	cmp    $0x5e,%eax
  8005a3:	76 10                	jbe    8005b5 <vprintfmt+0x213>
					putch('?', putdat);
  8005a5:	83 ec 08             	sub    $0x8,%esp
  8005a8:	ff 75 0c             	pushl  0xc(%ebp)
  8005ab:	6a 3f                	push   $0x3f
  8005ad:	ff 55 08             	call   *0x8(%ebp)
  8005b0:	83 c4 10             	add    $0x10,%esp
  8005b3:	eb 0d                	jmp    8005c2 <vprintfmt+0x220>
				else
					putch(ch, putdat);
  8005b5:	83 ec 08             	sub    $0x8,%esp
  8005b8:	ff 75 0c             	pushl  0xc(%ebp)
  8005bb:	52                   	push   %edx
  8005bc:	ff 55 08             	call   *0x8(%ebp)
  8005bf:	83 c4 10             	add    $0x10,%esp
			if ((p = va_arg(ap, char *)) == NULL)
				p = "(null)";
			if (width > 0 && padc != '-')
				for (width -= strnlen(p, precision); width > 0; width--)
					putch(padc, putdat);
			for (; (ch = *p++) != '\0' && (precision < 0 || --precision >= 0); width--)
  8005c2:	83 eb 01             	sub    $0x1,%ebx
  8005c5:	eb 1a                	jmp    8005e1 <vprintfmt+0x23f>
  8005c7:	89 75 08             	mov    %esi,0x8(%ebp)
  8005ca:	8b 75 d0             	mov    -0x30(%ebp),%esi
  8005cd:	89 5d 0c             	mov    %ebx,0xc(%ebp)
  8005d0:	8b 5d e0             	mov    -0x20(%ebp),%ebx
  8005d3:	eb 0c                	jmp    8005e1 <vprintfmt+0x23f>
  8005d5:	89 75 08             	mov    %esi,0x8(%ebp)
  8005d8:	8b 75 d0             	mov    -0x30(%ebp),%esi
  8005db:	89 5d 0c             	mov    %ebx,0xc(%ebp)
  8005de:	8b 5d e0             	mov    -0x20(%ebp),%ebx
  8005e1:	83 c7 01             	add    $0x1,%edi
  8005e4:	0f b6 47 ff          	movzbl -0x1(%edi),%eax
  8005e8:	0f be d0             	movsbl %al,%edx
  8005eb:	85 d2                	test   %edx,%edx
  8005ed:	74 23                	je     800612 <vprintfmt+0x270>
  8005ef:	85 f6                	test   %esi,%esi
  8005f1:	78 a1                	js     800594 <vprintfmt+0x1f2>
  8005f3:	83 ee 01             	sub    $0x1,%esi
  8005f6:	79 9c                	jns    800594 <vprintfmt+0x1f2>
  8005f8:	89 df                	mov    %ebx,%edi
  8005fa:	8b 75 08             	mov    0x8(%ebp),%esi
  8005fd:	8b 5d 0c             	mov    0xc(%ebp),%ebx
  800600:	eb 18                	jmp    80061a <vprintfmt+0x278>
				if (altflag && (ch < ' ' || ch > '~'))
					putch('?', putdat);
				else
					putch(ch, putdat);
			for (; width > 0; width--)
				putch(' ', putdat);
  800602:	83 ec 08             	sub    $0x8,%esp
  800605:	53                   	push   %ebx
  800606:	6a 20                	push   $0x20
  800608:	ff d6                	call   *%esi
			for (; (ch = *p++) != '\0' && (precision < 0 || --precision >= 0); width--)
				if (altflag && (ch < ' ' || ch > '~'))
					putch('?', putdat);
				else
					putch(ch, putdat);
			for (; width > 0; width--)
  80060a:	83 ef 01             	sub    $0x1,%edi
  80060d:	83 c4 10             	add    $0x10,%esp
  800610:	eb 08                	jmp    80061a <vprintfmt+0x278>
  800612:	89 df                	mov    %ebx,%edi
  800614:	8b 75 08             	mov    0x8(%ebp),%esi
  800617:	8b 5d 0c             	mov    0xc(%ebp),%ebx
  80061a:	85 ff                	test   %edi,%edi
  80061c:	7f e4                	jg     800602 <vprintfmt+0x260>
		width = -1;
		precision = -1;
		lflag = 0;
		altflag = 0;
	reswitch:
		switch (ch = *(unsigned char *) fmt++) {
  80061e:	8b 7d e4             	mov    -0x1c(%ebp),%edi
  800621:	e9 a2 fd ff ff       	jmp    8003c8 <vprintfmt+0x26>
				putch(' ', putdat);
			break;

		// (signed) decimal
		case 'd':
			num = getint(&ap, lflag);
  800626:	8d 45 14             	lea    0x14(%ebp),%eax
  800629:	e8 08 fd ff ff       	call   800336 <getint>
  80062e:	89 45 d8             	mov    %eax,-0x28(%ebp)
  800631:	89 55 dc             	mov    %edx,-0x24(%ebp)
			if ((long long) num < 0) {
				putch('-', putdat);
				num = -(long long) num;
			}
			base = 10;
  800634:	b9 0a 00 00 00       	mov    $0xa,%ecx
			break;

		// (signed) decimal
		case 'd':
			num = getint(&ap, lflag);
			if ((long long) num < 0) {
  800639:	83 7d dc 00          	cmpl   $0x0,-0x24(%ebp)
  80063d:	79 74                	jns    8006b3 <vprintfmt+0x311>
				putch('-', putdat);
  80063f:	83 ec 08             	sub    $0x8,%esp
  800642:	53                   	push   %ebx
  800643:	6a 2d                	push   $0x2d
  800645:	ff d6                	call   *%esi
				num = -(long long) num;
  800647:	8b 45 d8             	mov    -0x28(%ebp),%eax
  80064a:	8b 55 dc             	mov    -0x24(%ebp),%edx
  80064d:	f7 d8                	neg    %eax
  80064f:	83 d2 00             	adc    $0x0,%edx
  800652:	f7 da                	neg    %edx
  800654:	83 c4 10             	add    $0x10,%esp
			}
			base = 10;
  800657:	b9 0a 00 00 00       	mov    $0xa,%ecx
  80065c:	eb 55                	jmp    8006b3 <vprintfmt+0x311>
			goto number;

		// unsigned decimal
		case 'u':
			num = getuint(&ap, lflag);
  80065e:	8d 45 14             	lea    0x14(%ebp),%eax
  800661:	e8 96 fc ff ff       	call   8002fc <getuint>
			base = 10;
  800666:	b9 0a 00 00 00       	mov    $0xa,%ecx
			goto number;
  80066b:	eb 46                	jmp    8006b3 <vprintfmt+0x311>

		// (unsigned) octal
		case 'o':
			num = getuint(&ap, lflag);
  80066d:	8d 45 14             	lea    0x14(%ebp),%eax
  800670:	e8 87 fc ff ff       	call   8002fc <getuint>
			base = 8;
  800675:	b9 08 00 00 00       	mov    $0x8,%ecx
			goto number;
  80067a:	eb 37                	jmp    8006b3 <vprintfmt+0x311>

		// pointer
		case 'p':
			putch('0', putdat);
  80067c:	83 ec 08             	sub    $0x8,%esp
  80067f:	53                   	push   %ebx
  800680:	6a 30                	push   $0x30
  800682:	ff d6                	call   *%esi
			putch('x', putdat);
  800684:	83 c4 08             	add    $0x8,%esp
  800687:	53                   	push   %ebx
  800688:	6a 78                	push   $0x78
  80068a:	ff d6                	call   *%esi
			num = (unsigned long long)
				(uintptr_t) va_arg(ap, void *);
  80068c:	8b 45 14             	mov    0x14(%ebp),%eax
  80068f:	8d 50 04             	lea    0x4(%eax),%edx
  800692:	89 55 14             	mov    %edx,0x14(%ebp)

		// pointer
		case 'p':
			putch('0', putdat);
			putch('x', putdat);
			num = (unsigned long long)
  800695:	8b 00                	mov    (%eax),%eax
  800697:	ba 00 00 00 00       	mov    $0x0,%edx
				(uintptr_t) va_arg(ap, void *);
			base = 16;
			goto number;
  80069c:	83 c4 10             	add    $0x10,%esp
		case 'p':
			putch('0', putdat);
			putch('x', putdat);
			num = (unsigned long long)
				(uintptr_t) va_arg(ap, void *);
			base = 16;
  80069f:	b9 10 00 00 00       	mov    $0x10,%ecx
			goto number;
  8006a4:	eb 0d                	jmp    8006b3 <vprintfmt+0x311>

		// (unsigned) hexadecimal
		case 'x':
			num = getuint(&ap, lflag);
  8006a6:	8d 45 14             	lea    0x14(%ebp),%eax
  8006a9:	e8 4e fc ff ff       	call   8002fc <getuint>
			base = 16;
  8006ae:	b9 10 00 00 00       	mov    $0x10,%ecx
		number:
			printnum(putch, putdat, num, base, width, padc);
  8006b3:	83 ec 0c             	sub    $0xc,%esp
  8006b6:	0f be 7d d4          	movsbl -0x2c(%ebp),%edi
  8006ba:	57                   	push   %edi
  8006bb:	ff 75 e0             	pushl  -0x20(%ebp)
  8006be:	51                   	push   %ecx
  8006bf:	52                   	push   %edx
  8006c0:	50                   	push   %eax
  8006c1:	89 da                	mov    %ebx,%edx
  8006c3:	89 f0                	mov    %esi,%eax
  8006c5:	e8 83 fb ff ff       	call   80024d <printnum>
			break;
  8006ca:	83 c4 20             	add    $0x20,%esp
  8006cd:	8b 7d e4             	mov    -0x1c(%ebp),%edi
  8006d0:	e9 f3 fc ff ff       	jmp    8003c8 <vprintfmt+0x26>

		// escaped '%' character
		case '%':
			putch(ch, putdat);
  8006d5:	83 ec 08             	sub    $0x8,%esp
  8006d8:	53                   	push   %ebx
  8006d9:	51                   	push   %ecx
  8006da:	ff d6                	call   *%esi
			break;
  8006dc:	83 c4 10             	add    $0x10,%esp
		width = -1;
		precision = -1;
		lflag = 0;
		altflag = 0;
	reswitch:
		switch (ch = *(unsigned char *) fmt++) {
  8006df:	8b 7d e4             	mov    -0x1c(%ebp),%edi
			break;

		// escaped '%' character
		case '%':
			putch(ch, putdat);
			break;
  8006e2:	e9 e1 fc ff ff       	jmp    8003c8 <vprintfmt+0x26>

		// unrecognized escape sequence - just print it literally
		default:
			putch('%', putdat);
  8006e7:	83 ec 08             	sub    $0x8,%esp
  8006ea:	53                   	push   %ebx
  8006eb:	6a 25                	push   $0x25
  8006ed:	ff d6                	call   *%esi
			for (fmt--; fmt[-1] != '%'; fmt--)
  8006ef:	83 c4 10             	add    $0x10,%esp
  8006f2:	eb 03                	jmp    8006f7 <vprintfmt+0x355>
  8006f4:	83 ef 01             	sub    $0x1,%edi
  8006f7:	80 7f ff 25          	cmpb   $0x25,-0x1(%edi)
  8006fb:	75 f7                	jne    8006f4 <vprintfmt+0x352>
  8006fd:	e9 c6 fc ff ff       	jmp    8003c8 <vprintfmt+0x26>
				/* do nothing */;
			break;
		}
	}
}
  800702:	8d 65 f4             	lea    -0xc(%ebp),%esp
  800705:	5b                   	pop    %ebx
  800706:	5e                   	pop    %esi
  800707:	5f                   	pop    %edi
  800708:	5d                   	pop    %ebp
  800709:	c3                   	ret    

0080070a <vsnprintf>:
		*b->buf++ = ch;
}

int
vsnprintf(char *buf, int n, const char *fmt, va_list ap)
{
  80070a:	55                   	push   %ebp
  80070b:	89 e5                	mov    %esp,%ebp
  80070d:	83 ec 18             	sub    $0x18,%esp
  800710:	8b 45 08             	mov    0x8(%ebp),%eax
  800713:	8b 55 0c             	mov    0xc(%ebp),%edx
	struct sprintbuf b = {buf, buf+n-1, 0};
  800716:	89 45 ec             	mov    %eax,-0x14(%ebp)
  800719:	8d 4c 10 ff          	lea    -0x1(%eax,%edx,1),%ecx
  80071d:	89 4d f0             	mov    %ecx,-0x10(%ebp)
  800720:	c7 45 f4 00 00 00 00 	movl   $0x0,-0xc(%ebp)

	if (buf == NULL || n < 1)
  800727:	85 c0                	test   %eax,%eax
  800729:	74 26                	je     800751 <vsnprintf+0x47>
  80072b:	85 d2                	test   %edx,%edx
  80072d:	7e 22                	jle    800751 <vsnprintf+0x47>
		return -E_INVAL;

	// print the string to the buffer
	vprintfmt((void*)sprintputch, &b, fmt, ap);
  80072f:	ff 75 14             	pushl  0x14(%ebp)
  800732:	ff 75 10             	pushl  0x10(%ebp)
  800735:	8d 45 ec             	lea    -0x14(%ebp),%eax
  800738:	50                   	push   %eax
  800739:	68 68 03 80 00       	push   $0x800368
  80073e:	e8 5f fc ff ff       	call   8003a2 <vprintfmt>

	// null terminate the buffer
	*b.buf = '\0';
  800743:	8b 45 ec             	mov    -0x14(%ebp),%eax
  800746:	c6 00 00             	movb   $0x0,(%eax)

	return b.cnt;
  800749:	8b 45 f4             	mov    -0xc(%ebp),%eax
  80074c:	83 c4 10             	add    $0x10,%esp
  80074f:	eb 05                	jmp    800756 <vsnprintf+0x4c>
vsnprintf(char *buf, int n, const char *fmt, va_list ap)
{
	struct sprintbuf b = {buf, buf+n-1, 0};

	if (buf == NULL || n < 1)
		return -E_INVAL;
  800751:	b8 fd ff ff ff       	mov    $0xfffffffd,%eax

	// null terminate the buffer
	*b.buf = '\0';

	return b.cnt;
}
  800756:	c9                   	leave  
  800757:	c3                   	ret    

00800758 <snprintf>:

int
snprintf(char *buf, int n, const char *fmt, ...)
{
  800758:	55                   	push   %ebp
  800759:	89 e5                	mov    %esp,%ebp
  80075b:	83 ec 08             	sub    $0x8,%esp
	va_list ap;
	int rc;

	va_start(ap, fmt);
  80075e:	8d 45 14             	lea    0x14(%ebp),%eax
	rc = vsnprintf(buf, n, fmt, ap);
  800761:	50                   	push   %eax
  800762:	ff 75 10             	pushl  0x10(%ebp)
  800765:	ff 75 0c             	pushl  0xc(%ebp)
  800768:	ff 75 08             	pushl  0x8(%ebp)
  80076b:	e8 9a ff ff ff       	call   80070a <vsnprintf>
	va_end(ap);

	return rc;
}
  800770:	c9                   	leave  
  800771:	c3                   	ret    

00800772 <strlen>:
// Primespipe runs 3x faster this way.
#define ASM 1

int
strlen(const char *s)
{
  800772:	55                   	push   %ebp
  800773:	89 e5                	mov    %esp,%ebp
  800775:	8b 55 08             	mov    0x8(%ebp),%edx
	int n;

	for (n = 0; *s != '\0'; s++)
  800778:	b8 00 00 00 00       	mov    $0x0,%eax
  80077d:	eb 03                	jmp    800782 <strlen+0x10>
		n++;
  80077f:	83 c0 01             	add    $0x1,%eax
int
strlen(const char *s)
{
	int n;

	for (n = 0; *s != '\0'; s++)
  800782:	80 3c 02 00          	cmpb   $0x0,(%edx,%eax,1)
  800786:	75 f7                	jne    80077f <strlen+0xd>
		n++;
	return n;
}
  800788:	5d                   	pop    %ebp
  800789:	c3                   	ret    

0080078a <strnlen>:

int
strnlen(const char *s, size_t size)
{
  80078a:	55                   	push   %ebp
  80078b:	89 e5                	mov    %esp,%ebp
  80078d:	8b 4d 08             	mov    0x8(%ebp),%ecx
  800790:	8b 45 0c             	mov    0xc(%ebp),%eax
	int n;

	for (n = 0; size > 0 && *s != '\0'; s++, size--)
  800793:	ba 00 00 00 00       	mov    $0x0,%edx
  800798:	eb 03                	jmp    80079d <strnlen+0x13>
		n++;
  80079a:	83 c2 01             	add    $0x1,%edx
int
strnlen(const char *s, size_t size)
{
	int n;

	for (n = 0; size > 0 && *s != '\0'; s++, size--)
  80079d:	39 c2                	cmp    %eax,%edx
  80079f:	74 08                	je     8007a9 <strnlen+0x1f>
  8007a1:	80 3c 11 00          	cmpb   $0x0,(%ecx,%edx,1)
  8007a5:	75 f3                	jne    80079a <strnlen+0x10>
  8007a7:	89 d0                	mov    %edx,%eax
		n++;
	return n;
}
  8007a9:	5d                   	pop    %ebp
  8007aa:	c3                   	ret    

008007ab <strcpy>:

char *
strcpy(char *dst, const char *src)
{
  8007ab:	55                   	push   %ebp
  8007ac:	89 e5                	mov    %esp,%ebp
  8007ae:	53                   	push   %ebx
  8007af:	8b 45 08             	mov    0x8(%ebp),%eax
  8007b2:	8b 4d 0c             	mov    0xc(%ebp),%ecx
	char *ret;

	ret = dst;
	while ((*dst++ = *src++) != '\0')
  8007b5:	89 c2                	mov    %eax,%edx
  8007b7:	83 c2 01             	add    $0x1,%edx
  8007ba:	83 c1 01             	add    $0x1,%ecx
  8007bd:	0f b6 59 ff          	movzbl -0x1(%ecx),%ebx
  8007c1:	88 5a ff             	mov    %bl,-0x1(%edx)
  8007c4:	84 db                	test   %bl,%bl
  8007c6:	75 ef                	jne    8007b7 <strcpy+0xc>
		/* do nothing */;
	return ret;
}
  8007c8:	5b                   	pop    %ebx
  8007c9:	5d                   	pop    %ebp
  8007ca:	c3                   	ret    

008007cb <strcat>:

char *
strcat(char *dst, const char *src)
{
  8007cb:	55                   	push   %ebp
  8007cc:	89 e5                	mov    %esp,%ebp
  8007ce:	53                   	push   %ebx
  8007cf:	8b 5d 08             	mov    0x8(%ebp),%ebx
	int len = strlen(dst);
  8007d2:	53                   	push   %ebx
  8007d3:	e8 9a ff ff ff       	call   800772 <strlen>
  8007d8:	83 c4 04             	add    $0x4,%esp
	strcpy(dst + len, src);
  8007db:	ff 75 0c             	pushl  0xc(%ebp)
  8007de:	01 d8                	add    %ebx,%eax
  8007e0:	50                   	push   %eax
  8007e1:	e8 c5 ff ff ff       	call   8007ab <strcpy>
	return dst;
}
  8007e6:	89 d8                	mov    %ebx,%eax
  8007e8:	8b 5d fc             	mov    -0x4(%ebp),%ebx
  8007eb:	c9                   	leave  
  8007ec:	c3                   	ret    

008007ed <strncpy>:

char *
strncpy(char *dst, const char *src, size_t size) {
  8007ed:	55                   	push   %ebp
  8007ee:	89 e5                	mov    %esp,%ebp
  8007f0:	56                   	push   %esi
  8007f1:	53                   	push   %ebx
  8007f2:	8b 75 08             	mov    0x8(%ebp),%esi
  8007f5:	8b 4d 0c             	mov    0xc(%ebp),%ecx
  8007f8:	89 f3                	mov    %esi,%ebx
  8007fa:	03 5d 10             	add    0x10(%ebp),%ebx
	size_t i;
	char *ret;

	ret = dst;
	for (i = 0; i < size; i++) {
  8007fd:	89 f2                	mov    %esi,%edx
  8007ff:	eb 0f                	jmp    800810 <strncpy+0x23>
		*dst++ = *src;
  800801:	83 c2 01             	add    $0x1,%edx
  800804:	0f b6 01             	movzbl (%ecx),%eax
  800807:	88 42 ff             	mov    %al,-0x1(%edx)
		// If strlen(src) < size, null-pad 'dst' out to 'size' chars
		if (*src != '\0')
			src++;
  80080a:	80 39 01             	cmpb   $0x1,(%ecx)
  80080d:	83 d9 ff             	sbb    $0xffffffff,%ecx
strncpy(char *dst, const char *src, size_t size) {
	size_t i;
	char *ret;

	ret = dst;
	for (i = 0; i < size; i++) {
  800810:	39 da                	cmp    %ebx,%edx
  800812:	75 ed                	jne    800801 <strncpy+0x14>
		// If strlen(src) < size, null-pad 'dst' out to 'size' chars
		if (*src != '\0')
			src++;
	}
	return ret;
}
  800814:	89 f0                	mov    %esi,%eax
  800816:	5b                   	pop    %ebx
  800817:	5e                   	pop    %esi
  800818:	5d                   	pop    %ebp
  800819:	c3                   	ret    

0080081a <strlcpy>:

size_t
strlcpy(char *dst, const char *src, size_t size)
{
  80081a:	55                   	push   %ebp
  80081b:	89 e5                	mov    %esp,%ebp
  80081d:	56                   	push   %esi
  80081e:	53                   	push   %ebx
  80081f:	8b 75 08             	mov    0x8(%ebp),%esi
  800822:	8b 4d 0c             	mov    0xc(%ebp),%ecx
  800825:	8b 55 10             	mov    0x10(%ebp),%edx
  800828:	89 f0                	mov    %esi,%eax
	char *dst_in;

	dst_in = dst;
	if (size > 0) {
  80082a:	85 d2                	test   %edx,%edx
  80082c:	74 21                	je     80084f <strlcpy+0x35>
  80082e:	8d 44 16 ff          	lea    -0x1(%esi,%edx,1),%eax
  800832:	89 f2                	mov    %esi,%edx
  800834:	eb 09                	jmp    80083f <strlcpy+0x25>
		while (--size > 0 && *src != '\0')
			*dst++ = *src++;
  800836:	83 c2 01             	add    $0x1,%edx
  800839:	83 c1 01             	add    $0x1,%ecx
  80083c:	88 5a ff             	mov    %bl,-0x1(%edx)
{
	char *dst_in;

	dst_in = dst;
	if (size > 0) {
		while (--size > 0 && *src != '\0')
  80083f:	39 c2                	cmp    %eax,%edx
  800841:	74 09                	je     80084c <strlcpy+0x32>
  800843:	0f b6 19             	movzbl (%ecx),%ebx
  800846:	84 db                	test   %bl,%bl
  800848:	75 ec                	jne    800836 <strlcpy+0x1c>
  80084a:	89 d0                	mov    %edx,%eax
			*dst++ = *src++;
		*dst = '\0';
  80084c:	c6 00 00             	movb   $0x0,(%eax)
	}
	return dst - dst_in;
  80084f:	29 f0                	sub    %esi,%eax
}
  800851:	5b                   	pop    %ebx
  800852:	5e                   	pop    %esi
  800853:	5d                   	pop    %ebp
  800854:	c3                   	ret    

00800855 <strcmp>:

int
strcmp(const char *p, const char *q)
{
  800855:	55                   	push   %ebp
  800856:	89 e5                	mov    %esp,%ebp
  800858:	8b 4d 08             	mov    0x8(%ebp),%ecx
  80085b:	8b 55 0c             	mov    0xc(%ebp),%edx
	while (*p && *p == *q)
  80085e:	eb 06                	jmp    800866 <strcmp+0x11>
		p++, q++;
  800860:	83 c1 01             	add    $0x1,%ecx
  800863:	83 c2 01             	add    $0x1,%edx
}

int
strcmp(const char *p, const char *q)
{
	while (*p && *p == *q)
  800866:	0f b6 01             	movzbl (%ecx),%eax
  800869:	84 c0                	test   %al,%al
  80086b:	74 04                	je     800871 <strcmp+0x1c>
  80086d:	3a 02                	cmp    (%edx),%al
  80086f:	74 ef                	je     800860 <strcmp+0xb>
		p++, q++;
	return (int) ((unsigned char) *p - (unsigned char) *q);
  800871:	0f b6 c0             	movzbl %al,%eax
  800874:	0f b6 12             	movzbl (%edx),%edx
  800877:	29 d0                	sub    %edx,%eax
}
  800879:	5d                   	pop    %ebp
  80087a:	c3                   	ret    

0080087b <strncmp>:

int
strncmp(const char *p, const char *q, size_t n)
{
  80087b:	55                   	push   %ebp
  80087c:	89 e5                	mov    %esp,%ebp
  80087e:	53                   	push   %ebx
  80087f:	8b 45 08             	mov    0x8(%ebp),%eax
  800882:	8b 55 0c             	mov    0xc(%ebp),%edx
  800885:	89 c3                	mov    %eax,%ebx
  800887:	03 5d 10             	add    0x10(%ebp),%ebx
	while (n > 0 && *p && *p == *q)
  80088a:	eb 06                	jmp    800892 <strncmp+0x17>
		n--, p++, q++;
  80088c:	83 c0 01             	add    $0x1,%eax
  80088f:	83 c2 01             	add    $0x1,%edx
}

int
strncmp(const char *p, const char *q, size_t n)
{
	while (n > 0 && *p && *p == *q)
  800892:	39 d8                	cmp    %ebx,%eax
  800894:	74 15                	je     8008ab <strncmp+0x30>
  800896:	0f b6 08             	movzbl (%eax),%ecx
  800899:	84 c9                	test   %cl,%cl
  80089b:	74 04                	je     8008a1 <strncmp+0x26>
  80089d:	3a 0a                	cmp    (%edx),%cl
  80089f:	74 eb                	je     80088c <strncmp+0x11>
		n--, p++, q++;
	if (n == 0)
		return 0;
	else
		return (int) ((unsigned char) *p - (unsigned char) *q);
  8008a1:	0f b6 00             	movzbl (%eax),%eax
  8008a4:	0f b6 12             	movzbl (%edx),%edx
  8008a7:	29 d0                	sub    %edx,%eax
  8008a9:	eb 05                	jmp    8008b0 <strncmp+0x35>
strncmp(const char *p, const char *q, size_t n)
{
	while (n > 0 && *p && *p == *q)
		n--, p++, q++;
	if (n == 0)
		return 0;
  8008ab:	b8 00 00 00 00       	mov    $0x0,%eax
	else
		return (int) ((unsigned char) *p - (unsigned char) *q);
}
  8008b0:	5b                   	pop    %ebx
  8008b1:	5d                   	pop    %ebp
  8008b2:	c3                   	ret    

008008b3 <strchr>:

// Return a pointer to the first occurrence of 'c' in 's',
// or a null pointer if the string has no 'c'.
char *
strchr(const char *s, char c)
{
  8008b3:	55                   	push   %ebp
  8008b4:	89 e5                	mov    %esp,%ebp
  8008b6:	8b 45 08             	mov    0x8(%ebp),%eax
  8008b9:	0f b6 4d 0c          	movzbl 0xc(%ebp),%ecx
	for (; *s; s++)
  8008bd:	eb 07                	jmp    8008c6 <strchr+0x13>
		if (*s == c)
  8008bf:	38 ca                	cmp    %cl,%dl
  8008c1:	74 0f                	je     8008d2 <strchr+0x1f>
// Return a pointer to the first occurrence of 'c' in 's',
// or a null pointer if the string has no 'c'.
char *
strchr(const char *s, char c)
{
	for (; *s; s++)
  8008c3:	83 c0 01             	add    $0x1,%eax
  8008c6:	0f b6 10             	movzbl (%eax),%edx
  8008c9:	84 d2                	test   %dl,%dl
  8008cb:	75 f2                	jne    8008bf <strchr+0xc>
		if (*s == c)
			return (char *) s;
	return 0;
  8008cd:	b8 00 00 00 00       	mov    $0x0,%eax
}
  8008d2:	5d                   	pop    %ebp
  8008d3:	c3                   	ret    

008008d4 <strfind>:

// Return a pointer to the first occurrence of 'c' in 's',
// or a pointer to the string-ending null character if the string has no 'c'.
char *
strfind(const char *s, char c)
{
  8008d4:	55                   	push   %ebp
  8008d5:	89 e5                	mov    %esp,%ebp
  8008d7:	8b 45 08             	mov    0x8(%ebp),%eax
  8008da:	0f b6 4d 0c          	movzbl 0xc(%ebp),%ecx
	for (; *s; s++)
  8008de:	eb 03                	jmp    8008e3 <strfind+0xf>
  8008e0:	83 c0 01             	add    $0x1,%eax
  8008e3:	0f b6 10             	movzbl (%eax),%edx
		if (*s == c)
  8008e6:	38 ca                	cmp    %cl,%dl
  8008e8:	74 04                	je     8008ee <strfind+0x1a>
  8008ea:	84 d2                	test   %dl,%dl
  8008ec:	75 f2                	jne    8008e0 <strfind+0xc>
			break;
	return (char *) s;
}
  8008ee:	5d                   	pop    %ebp
  8008ef:	c3                   	ret    

008008f0 <memset>:

#if ASM
void *
memset(void *v, int c, size_t n)
{
  8008f0:	55                   	push   %ebp
  8008f1:	89 e5                	mov    %esp,%ebp
  8008f3:	57                   	push   %edi
  8008f4:	56                   	push   %esi
  8008f5:	53                   	push   %ebx
  8008f6:	8b 55 08             	mov    0x8(%ebp),%edx
  8008f9:	8b 4d 10             	mov    0x10(%ebp),%ecx
	char *p = v;

	if (n == 0)
  8008fc:	85 c9                	test   %ecx,%ecx
  8008fe:	74 37                	je     800937 <memset+0x47>
		return v;
	if ((int)v%4 == 0 && n%4 == 0) {
  800900:	f6 c2 03             	test   $0x3,%dl
  800903:	75 2a                	jne    80092f <memset+0x3f>
  800905:	f6 c1 03             	test   $0x3,%cl
  800908:	75 25                	jne    80092f <memset+0x3f>
		c &= 0xFF;
  80090a:	0f b6 5d 0c          	movzbl 0xc(%ebp),%ebx
		c = (c<<24)|(c<<16)|(c<<8)|c;
  80090e:	89 df                	mov    %ebx,%edi
  800910:	c1 e7 08             	shl    $0x8,%edi
  800913:	89 de                	mov    %ebx,%esi
  800915:	c1 e6 18             	shl    $0x18,%esi
  800918:	89 d8                	mov    %ebx,%eax
  80091a:	c1 e0 10             	shl    $0x10,%eax
  80091d:	09 f0                	or     %esi,%eax
  80091f:	09 c3                	or     %eax,%ebx
		asm volatile("cld; rep stosl\n"
			: "=D" (p), "=c" (n)
			: "D" (p), "a" (c), "c" (n/4)
  800921:	c1 e9 02             	shr    $0x2,%ecx
	if (n == 0)
		return v;
	if ((int)v%4 == 0 && n%4 == 0) {
		c &= 0xFF;
		c = (c<<24)|(c<<16)|(c<<8)|c;
		asm volatile("cld; rep stosl\n"
  800924:	89 f8                	mov    %edi,%eax
  800926:	09 d8                	or     %ebx,%eax
  800928:	89 d7                	mov    %edx,%edi
  80092a:	fc                   	cld    
  80092b:	f3 ab                	rep stos %eax,%es:(%edi)
  80092d:	eb 08                	jmp    800937 <memset+0x47>
			: "=D" (p), "=c" (n)
			: "D" (p), "a" (c), "c" (n/4)
			: "cc", "memory");
	} else
		asm volatile("cld; rep stosb\n"
  80092f:	89 d7                	mov    %edx,%edi
  800931:	8b 45 0c             	mov    0xc(%ebp),%eax
  800934:	fc                   	cld    
  800935:	f3 aa                	rep stos %al,%es:(%edi)
			: "=D" (p), "=c" (n)
			: "0" (p), "a" (c), "1" (n)
			: "cc", "memory");
	return v;
}
  800937:	89 d0                	mov    %edx,%eax
  800939:	5b                   	pop    %ebx
  80093a:	5e                   	pop    %esi
  80093b:	5f                   	pop    %edi
  80093c:	5d                   	pop    %ebp
  80093d:	c3                   	ret    

0080093e <memmove>:

void *
memmove(void *dst, const void *src, size_t n)
{
  80093e:	55                   	push   %ebp
  80093f:	89 e5                	mov    %esp,%ebp
  800941:	57                   	push   %edi
  800942:	56                   	push   %esi
  800943:	8b 45 08             	mov    0x8(%ebp),%eax
  800946:	8b 75 0c             	mov    0xc(%ebp),%esi
  800949:	8b 4d 10             	mov    0x10(%ebp),%ecx
	const char *s;
	char *d;

	s = src;
	d = dst;
	if (s < d && s + n > d) {
  80094c:	39 c6                	cmp    %eax,%esi
  80094e:	73 35                	jae    800985 <memmove+0x47>
  800950:	8d 14 0e             	lea    (%esi,%ecx,1),%edx
  800953:	39 d0                	cmp    %edx,%eax
  800955:	73 2e                	jae    800985 <memmove+0x47>
		s += n;
		d += n;
  800957:	8d 3c 08             	lea    (%eax,%ecx,1),%edi
		if ((int)s%4 == 0 && (int)d%4 == 0 && n%4 == 0)
  80095a:	89 d6                	mov    %edx,%esi
  80095c:	09 fe                	or     %edi,%esi
  80095e:	f7 c6 03 00 00 00    	test   $0x3,%esi
  800964:	75 13                	jne    800979 <memmove+0x3b>
  800966:	f6 c1 03             	test   $0x3,%cl
  800969:	75 0e                	jne    800979 <memmove+0x3b>
			asm volatile("std; rep movsl\n"
  80096b:	83 ef 04             	sub    $0x4,%edi
  80096e:	8d 72 fc             	lea    -0x4(%edx),%esi
  800971:	c1 e9 02             	shr    $0x2,%ecx
  800974:	fd                   	std    
  800975:	f3 a5                	rep movsl %ds:(%esi),%es:(%edi)
  800977:	eb 09                	jmp    800982 <memmove+0x44>
				:: "D" (d-4), "S" (s-4), "c" (n/4) : "cc", "memory");
		else
			asm volatile("std; rep movsb\n"
  800979:	83 ef 01             	sub    $0x1,%edi
  80097c:	8d 72 ff             	lea    -0x1(%edx),%esi
  80097f:	fd                   	std    
  800980:	f3 a4                	rep movsb %ds:(%esi),%es:(%edi)
				:: "D" (d-1), "S" (s-1), "c" (n) : "cc", "memory");
		// Some versions of GCC rely on DF being clear
		asm volatile("cld" ::: "cc");
  800982:	fc                   	cld    
  800983:	eb 1d                	jmp    8009a2 <memmove+0x64>
	} else {
		if ((int)s%4 == 0 && (int)d%4 == 0 && n%4 == 0)
  800985:	89 f2                	mov    %esi,%edx
  800987:	09 c2                	or     %eax,%edx
  800989:	f6 c2 03             	test   $0x3,%dl
  80098c:	75 0f                	jne    80099d <memmove+0x5f>
  80098e:	f6 c1 03             	test   $0x3,%cl
  800991:	75 0a                	jne    80099d <memmove+0x5f>
			asm volatile("cld; rep movsl\n"
  800993:	c1 e9 02             	shr    $0x2,%ecx
  800996:	89 c7                	mov    %eax,%edi
  800998:	fc                   	cld    
  800999:	f3 a5                	rep movsl %ds:(%esi),%es:(%edi)
  80099b:	eb 05                	jmp    8009a2 <memmove+0x64>
				:: "D" (d), "S" (s), "c" (n/4) : "cc", "memory");
		else
			asm volatile("cld; rep movsb\n"
  80099d:	89 c7                	mov    %eax,%edi
  80099f:	fc                   	cld    
  8009a0:	f3 a4                	rep movsb %ds:(%esi),%es:(%edi)
				:: "D" (d), "S" (s), "c" (n) : "cc", "memory");
	}
	return dst;
}
  8009a2:	5e                   	pop    %esi
  8009a3:	5f                   	pop    %edi
  8009a4:	5d                   	pop    %ebp
  8009a5:	c3                   	ret    

008009a6 <memcpy>:
}
#endif

void *
memcpy(void *dst, const void *src, size_t n)
{
  8009a6:	55                   	push   %ebp
  8009a7:	89 e5                	mov    %esp,%ebp
	return memmove(dst, src, n);
  8009a9:	ff 75 10             	pushl  0x10(%ebp)
  8009ac:	ff 75 0c             	pushl  0xc(%ebp)
  8009af:	ff 75 08             	pushl  0x8(%ebp)
  8009b2:	e8 87 ff ff ff       	call   80093e <memmove>
}
  8009b7:	c9                   	leave  
  8009b8:	c3                   	ret    

008009b9 <memcmp>:

int
memcmp(const void *v1, const void *v2, size_t n)
{
  8009b9:	55                   	push   %ebp
  8009ba:	89 e5                	mov    %esp,%ebp
  8009bc:	56                   	push   %esi
  8009bd:	53                   	push   %ebx
  8009be:	8b 45 08             	mov    0x8(%ebp),%eax
  8009c1:	8b 55 0c             	mov    0xc(%ebp),%edx
  8009c4:	89 c6                	mov    %eax,%esi
  8009c6:	03 75 10             	add    0x10(%ebp),%esi
	const uint8_t *s1 = (const uint8_t *) v1;
	const uint8_t *s2 = (const uint8_t *) v2;

	while (n-- > 0) {
  8009c9:	eb 1a                	jmp    8009e5 <memcmp+0x2c>
		if (*s1 != *s2)
  8009cb:	0f b6 08             	movzbl (%eax),%ecx
  8009ce:	0f b6 1a             	movzbl (%edx),%ebx
  8009d1:	38 d9                	cmp    %bl,%cl
  8009d3:	74 0a                	je     8009df <memcmp+0x26>
			return (int) *s1 - (int) *s2;
  8009d5:	0f b6 c1             	movzbl %cl,%eax
  8009d8:	0f b6 db             	movzbl %bl,%ebx
  8009db:	29 d8                	sub    %ebx,%eax
  8009dd:	eb 0f                	jmp    8009ee <memcmp+0x35>
		s1++, s2++;
  8009df:	83 c0 01             	add    $0x1,%eax
  8009e2:	83 c2 01             	add    $0x1,%edx
memcmp(const void *v1, const void *v2, size_t n)
{
	const uint8_t *s1 = (const uint8_t *) v1;
	const uint8_t *s2 = (const uint8_t *) v2;

	while (n-- > 0) {
  8009e5:	39 f0                	cmp    %esi,%eax
  8009e7:	75 e2                	jne    8009cb <memcmp+0x12>
		if (*s1 != *s2)
			return (int) *s1 - (int) *s2;
		s1++, s2++;
	}

	return 0;
  8009e9:	b8 00 00 00 00       	mov    $0x0,%eax
}
  8009ee:	5b                   	pop    %ebx
  8009ef:	5e                   	pop    %esi
  8009f0:	5d                   	pop    %ebp
  8009f1:	c3                   	ret    

008009f2 <memfind>:

void *
memfind(const void *s, int c, size_t n)
{
  8009f2:	55                   	push   %ebp
  8009f3:	89 e5                	mov    %esp,%ebp
  8009f5:	53                   	push   %ebx
  8009f6:	8b 45 08             	mov    0x8(%ebp),%eax
	const void *ends = (const char *) s + n;
  8009f9:	89 c1                	mov    %eax,%ecx
  8009fb:	03 4d 10             	add    0x10(%ebp),%ecx
	for (; s < ends; s++)
		if (*(const unsigned char *) s == (unsigned char) c)
  8009fe:	0f b6 5d 0c          	movzbl 0xc(%ebp),%ebx

void *
memfind(const void *s, int c, size_t n)
{
	const void *ends = (const char *) s + n;
	for (; s < ends; s++)
  800a02:	eb 0a                	jmp    800a0e <memfind+0x1c>
		if (*(const unsigned char *) s == (unsigned char) c)
  800a04:	0f b6 10             	movzbl (%eax),%edx
  800a07:	39 da                	cmp    %ebx,%edx
  800a09:	74 07                	je     800a12 <memfind+0x20>

void *
memfind(const void *s, int c, size_t n)
{
	const void *ends = (const char *) s + n;
	for (; s < ends; s++)
  800a0b:	83 c0 01             	add    $0x1,%eax
  800a0e:	39 c8                	cmp    %ecx,%eax
  800a10:	72 f2                	jb     800a04 <memfind+0x12>
		if (*(const unsigned char *) s == (unsigned char) c)
			break;
	return (void *) s;
}
  800a12:	5b                   	pop    %ebx
  800a13:	5d                   	pop    %ebp
  800a14:	c3                   	ret    

00800a15 <strtol>:

long
strtol(const char *s, char **endptr, int base)
{
  800a15:	55                   	push   %ebp
  800a16:	89 e5                	mov    %esp,%ebp
  800a18:	57                   	push   %edi
  800a19:	56                   	push   %esi
  800a1a:	53                   	push   %ebx
  800a1b:	8b 4d 08             	mov    0x8(%ebp),%ecx
  800a1e:	8b 5d 10             	mov    0x10(%ebp),%ebx
	int neg = 0;
	long val = 0;

	// gobble initial whitespace
	while (*s == ' ' || *s == '\t')
  800a21:	eb 03                	jmp    800a26 <strtol+0x11>
		s++;
  800a23:	83 c1 01             	add    $0x1,%ecx
{
	int neg = 0;
	long val = 0;

	// gobble initial whitespace
	while (*s == ' ' || *s == '\t')
  800a26:	0f b6 01             	movzbl (%ecx),%eax
  800a29:	3c 20                	cmp    $0x20,%al
  800a2b:	74 f6                	je     800a23 <strtol+0xe>
  800a2d:	3c 09                	cmp    $0x9,%al
  800a2f:	74 f2                	je     800a23 <strtol+0xe>
		s++;

	// plus/minus sign
	if (*s == '+')
  800a31:	3c 2b                	cmp    $0x2b,%al
  800a33:	75 0a                	jne    800a3f <strtol+0x2a>
		s++;
  800a35:	83 c1 01             	add    $0x1,%ecx
}

long
strtol(const char *s, char **endptr, int base)
{
	int neg = 0;
  800a38:	bf 00 00 00 00       	mov    $0x0,%edi
  800a3d:	eb 11                	jmp    800a50 <strtol+0x3b>
  800a3f:	bf 00 00 00 00       	mov    $0x0,%edi
		s++;

	// plus/minus sign
	if (*s == '+')
		s++;
	else if (*s == '-')
  800a44:	3c 2d                	cmp    $0x2d,%al
  800a46:	75 08                	jne    800a50 <strtol+0x3b>
		s++, neg = 1;
  800a48:	83 c1 01             	add    $0x1,%ecx
  800a4b:	bf 01 00 00 00       	mov    $0x1,%edi

	// hex or octal base prefix
	if ((base == 0 || base == 16) && (s[0] == '0' && s[1] == 'x'))
  800a50:	f7 c3 ef ff ff ff    	test   $0xffffffef,%ebx
  800a56:	75 15                	jne    800a6d <strtol+0x58>
  800a58:	80 39 30             	cmpb   $0x30,(%ecx)
  800a5b:	75 10                	jne    800a6d <strtol+0x58>
  800a5d:	80 79 01 78          	cmpb   $0x78,0x1(%ecx)
  800a61:	75 7c                	jne    800adf <strtol+0xca>
		s += 2, base = 16;
  800a63:	83 c1 02             	add    $0x2,%ecx
  800a66:	bb 10 00 00 00       	mov    $0x10,%ebx
  800a6b:	eb 16                	jmp    800a83 <strtol+0x6e>
	else if (base == 0 && s[0] == '0')
  800a6d:	85 db                	test   %ebx,%ebx
  800a6f:	75 12                	jne    800a83 <strtol+0x6e>
		s++, base = 8;
	else if (base == 0)
		base = 10;
  800a71:	bb 0a 00 00 00       	mov    $0xa,%ebx
		s++, neg = 1;

	// hex or octal base prefix
	if ((base == 0 || base == 16) && (s[0] == '0' && s[1] == 'x'))
		s += 2, base = 16;
	else if (base == 0 && s[0] == '0')
  800a76:	80 39 30             	cmpb   $0x30,(%ecx)
  800a79:	75 08                	jne    800a83 <strtol+0x6e>
		s++, base = 8;
  800a7b:	83 c1 01             	add    $0x1,%ecx
  800a7e:	bb 08 00 00 00       	mov    $0x8,%ebx
	else if (base == 0)
		base = 10;
  800a83:	b8 00 00 00 00       	mov    $0x0,%eax
  800a88:	89 5d 10             	mov    %ebx,0x10(%ebp)

	// digits
	while (1) {
		int dig;

		if (*s >= '0' && *s <= '9')
  800a8b:	0f b6 11             	movzbl (%ecx),%edx
  800a8e:	8d 72 d0             	lea    -0x30(%edx),%esi
  800a91:	89 f3                	mov    %esi,%ebx
  800a93:	80 fb 09             	cmp    $0x9,%bl
  800a96:	77 08                	ja     800aa0 <strtol+0x8b>
			dig = *s - '0';
  800a98:	0f be d2             	movsbl %dl,%edx
  800a9b:	83 ea 30             	sub    $0x30,%edx
  800a9e:	eb 22                	jmp    800ac2 <strtol+0xad>
		else if (*s >= 'a' && *s <= 'z')
  800aa0:	8d 72 9f             	lea    -0x61(%edx),%esi
  800aa3:	89 f3                	mov    %esi,%ebx
  800aa5:	80 fb 19             	cmp    $0x19,%bl
  800aa8:	77 08                	ja     800ab2 <strtol+0x9d>
			dig = *s - 'a' + 10;
  800aaa:	0f be d2             	movsbl %dl,%edx
  800aad:	83 ea 57             	sub    $0x57,%edx
  800ab0:	eb 10                	jmp    800ac2 <strtol+0xad>
		else if (*s >= 'A' && *s <= 'Z')
  800ab2:	8d 72 bf             	lea    -0x41(%edx),%esi
  800ab5:	89 f3                	mov    %esi,%ebx
  800ab7:	80 fb 19             	cmp    $0x19,%bl
  800aba:	77 16                	ja     800ad2 <strtol+0xbd>
			dig = *s - 'A' + 10;
  800abc:	0f be d2             	movsbl %dl,%edx
  800abf:	83 ea 37             	sub    $0x37,%edx
		else
			break;
		if (dig >= base)
  800ac2:	3b 55 10             	cmp    0x10(%ebp),%edx
  800ac5:	7d 0b                	jge    800ad2 <strtol+0xbd>
			break;
		s++, val = (val * base) + dig;
  800ac7:	83 c1 01             	add    $0x1,%ecx
  800aca:	0f af 45 10          	imul   0x10(%ebp),%eax
  800ace:	01 d0                	add    %edx,%eax
		// we don't properly detect overflow!
	}
  800ad0:	eb b9                	jmp    800a8b <strtol+0x76>

	if (endptr)
  800ad2:	83 7d 0c 00          	cmpl   $0x0,0xc(%ebp)
  800ad6:	74 0d                	je     800ae5 <strtol+0xd0>
		*endptr = (char *) s;
  800ad8:	8b 75 0c             	mov    0xc(%ebp),%esi
  800adb:	89 0e                	mov    %ecx,(%esi)
  800add:	eb 06                	jmp    800ae5 <strtol+0xd0>
		s++, neg = 1;

	// hex or octal base prefix
	if ((base == 0 || base == 16) && (s[0] == '0' && s[1] == 'x'))
		s += 2, base = 16;
	else if (base == 0 && s[0] == '0')
  800adf:	85 db                	test   %ebx,%ebx
  800ae1:	74 98                	je     800a7b <strtol+0x66>
  800ae3:	eb 9e                	jmp    800a83 <strtol+0x6e>
		// we don't properly detect overflow!
	}

	if (endptr)
		*endptr = (char *) s;
	return (neg ? -val : val);
  800ae5:	89 c2                	mov    %eax,%edx
  800ae7:	f7 da                	neg    %edx
  800ae9:	85 ff                	test   %edi,%edi
  800aeb:	0f 45 c2             	cmovne %edx,%eax
}
  800aee:	5b                   	pop    %ebx
  800aef:	5e                   	pop    %esi
  800af0:	5f                   	pop    %edi
  800af1:	5d                   	pop    %ebp
  800af2:	c3                   	ret    
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
