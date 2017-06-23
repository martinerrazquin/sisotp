
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
  80003c:	56                   	push   %esi
  80003d:	53                   	push   %ebx
  80003e:	8b 5d 08             	mov    0x8(%ebp),%ebx
  800041:	8b 75 0c             	mov    0xc(%ebp),%esi
	// set thisenv to point at our Env structure in envs[].
	// LAB 3: Your code here.
	envid_t id = sys_getenvid();
  800044:	e8 02 01 00 00       	call   80014b <sys_getenvid>
	if (id >= 0)
  800049:	85 c0                	test   %eax,%eax
  80004b:	78 12                	js     80005f <libmain+0x26>
		thisenv = &envs[ENVX(id)];
  80004d:	25 ff 03 00 00       	and    $0x3ff,%eax
  800052:	6b c0 7c             	imul   $0x7c,%eax,%eax
  800055:	05 00 00 c0 ee       	add    $0xeec00000,%eax
  80005a:	a3 04 20 80 00       	mov    %eax,0x802004

	// save the name of the program so that panic() can use it
	if (argc > 0)
  80005f:	85 db                	test   %ebx,%ebx
  800061:	7e 07                	jle    80006a <libmain+0x31>
		binaryname = argv[0];
  800063:	8b 06                	mov    (%esi),%eax
  800065:	a3 00 20 80 00       	mov    %eax,0x802000

	// call user main routine
	umain(argc, argv);
  80006a:	83 ec 08             	sub    $0x8,%esp
  80006d:	56                   	push   %esi
  80006e:	53                   	push   %ebx
  80006f:	e8 bf ff ff ff       	call   800033 <umain>

	// exit gracefully
	exit();
  800074:	e8 0a 00 00 00       	call   800083 <exit>
}
  800079:	83 c4 10             	add    $0x10,%esp
  80007c:	8d 65 f8             	lea    -0x8(%ebp),%esp
  80007f:	5b                   	pop    %ebx
  800080:	5e                   	pop    %esi
  800081:	5d                   	pop    %ebp
  800082:	c3                   	ret    

00800083 <exit>:

#include <inc/lib.h>

void
exit(void)
{
  800083:	55                   	push   %ebp
  800084:	89 e5                	mov    %esp,%ebp
  800086:	83 ec 14             	sub    $0x14,%esp
	sys_env_destroy(0);
  800089:	6a 00                	push   $0x0
  80008b:	e8 99 00 00 00       	call   800129 <sys_env_destroy>
}
  800090:	83 c4 10             	add    $0x10,%esp
  800093:	c9                   	leave  
  800094:	c3                   	ret    

00800095 <syscall>:
#include <inc/syscall.h>
#include <inc/lib.h>

static inline int32_t
syscall(int num, int check, uint32_t a1, uint32_t a2, uint32_t a3, uint32_t a4, uint32_t a5)
{
  800095:	55                   	push   %ebp
  800096:	89 e5                	mov    %esp,%ebp
  800098:	57                   	push   %edi
  800099:	56                   	push   %esi
  80009a:	53                   	push   %ebx
  80009b:	83 ec 1c             	sub    $0x1c,%esp
  80009e:	89 45 e0             	mov    %eax,-0x20(%ebp)
  8000a1:	89 55 e4             	mov    %edx,-0x1c(%ebp)
  8000a4:	89 ca                	mov    %ecx,%edx
	//
	// The last clause tells the assembler that this can
	// potentially change the condition codes and arbitrary
	// memory locations.

	asm volatile("int %1\n"
  8000a6:	8b 4d 08             	mov    0x8(%ebp),%ecx
  8000a9:	8b 5d 0c             	mov    0xc(%ebp),%ebx
  8000ac:	8b 7d 10             	mov    0x10(%ebp),%edi
  8000af:	8b 75 14             	mov    0x14(%ebp),%esi
  8000b2:	cd 30                	int    $0x30
		       "b" (a3),
		       "D" (a4),
		       "S" (a5)
		     : "cc", "memory");

	if(check && ret > 0)
  8000b4:	83 7d e4 00          	cmpl   $0x0,-0x1c(%ebp)
  8000b8:	74 1d                	je     8000d7 <syscall+0x42>
  8000ba:	85 c0                	test   %eax,%eax
  8000bc:	7e 19                	jle    8000d7 <syscall+0x42>
  8000be:	8b 55 e0             	mov    -0x20(%ebp),%edx
		panic("syscall %d returned %d (> 0)", num, ret);
  8000c1:	83 ec 0c             	sub    $0xc,%esp
  8000c4:	50                   	push   %eax
  8000c5:	52                   	push   %edx
  8000c6:	68 ca 0e 80 00       	push   $0x800eca
  8000cb:	6a 23                	push   $0x23
  8000cd:	68 e7 0e 80 00       	push   $0x800ee7
  8000d2:	e8 b9 01 00 00       	call   800290 <_panic>

	return ret;
}
  8000d7:	8d 65 f4             	lea    -0xc(%ebp),%esp
  8000da:	5b                   	pop    %ebx
  8000db:	5e                   	pop    %esi
  8000dc:	5f                   	pop    %edi
  8000dd:	5d                   	pop    %ebp
  8000de:	c3                   	ret    

008000df <sys_cputs>:

void
sys_cputs(const char *s, size_t len)
{
  8000df:	55                   	push   %ebp
  8000e0:	89 e5                	mov    %esp,%ebp
  8000e2:	83 ec 08             	sub    $0x8,%esp
	syscall(SYS_cputs, 0, (uint32_t)s, len, 0, 0, 0);
  8000e5:	6a 00                	push   $0x0
  8000e7:	6a 00                	push   $0x0
  8000e9:	6a 00                	push   $0x0
  8000eb:	ff 75 0c             	pushl  0xc(%ebp)
  8000ee:	8b 4d 08             	mov    0x8(%ebp),%ecx
  8000f1:	ba 00 00 00 00       	mov    $0x0,%edx
  8000f6:	b8 00 00 00 00       	mov    $0x0,%eax
  8000fb:	e8 95 ff ff ff       	call   800095 <syscall>
}
  800100:	83 c4 10             	add    $0x10,%esp
  800103:	c9                   	leave  
  800104:	c3                   	ret    

00800105 <sys_cgetc>:

int
sys_cgetc(void)
{
  800105:	55                   	push   %ebp
  800106:	89 e5                	mov    %esp,%ebp
  800108:	83 ec 08             	sub    $0x8,%esp
	return syscall(SYS_cgetc, 0, 0, 0, 0, 0, 0);
  80010b:	6a 00                	push   $0x0
  80010d:	6a 00                	push   $0x0
  80010f:	6a 00                	push   $0x0
  800111:	6a 00                	push   $0x0
  800113:	b9 00 00 00 00       	mov    $0x0,%ecx
  800118:	ba 00 00 00 00       	mov    $0x0,%edx
  80011d:	b8 01 00 00 00       	mov    $0x1,%eax
  800122:	e8 6e ff ff ff       	call   800095 <syscall>
}
  800127:	c9                   	leave  
  800128:	c3                   	ret    

00800129 <sys_env_destroy>:

int
sys_env_destroy(envid_t envid)
{
  800129:	55                   	push   %ebp
  80012a:	89 e5                	mov    %esp,%ebp
  80012c:	83 ec 08             	sub    $0x8,%esp
	return syscall(SYS_env_destroy, 1, envid, 0, 0, 0, 0);
  80012f:	6a 00                	push   $0x0
  800131:	6a 00                	push   $0x0
  800133:	6a 00                	push   $0x0
  800135:	6a 00                	push   $0x0
  800137:	8b 4d 08             	mov    0x8(%ebp),%ecx
  80013a:	ba 01 00 00 00       	mov    $0x1,%edx
  80013f:	b8 03 00 00 00       	mov    $0x3,%eax
  800144:	e8 4c ff ff ff       	call   800095 <syscall>
}
  800149:	c9                   	leave  
  80014a:	c3                   	ret    

0080014b <sys_getenvid>:

envid_t
sys_getenvid(void)
{
  80014b:	55                   	push   %ebp
  80014c:	89 e5                	mov    %esp,%ebp
  80014e:	83 ec 08             	sub    $0x8,%esp
	 return syscall(SYS_getenvid, 0, 0, 0, 0, 0, 0);
  800151:	6a 00                	push   $0x0
  800153:	6a 00                	push   $0x0
  800155:	6a 00                	push   $0x0
  800157:	6a 00                	push   $0x0
  800159:	b9 00 00 00 00       	mov    $0x0,%ecx
  80015e:	ba 00 00 00 00       	mov    $0x0,%edx
  800163:	b8 02 00 00 00       	mov    $0x2,%eax
  800168:	e8 28 ff ff ff       	call   800095 <syscall>
}
  80016d:	c9                   	leave  
  80016e:	c3                   	ret    

0080016f <sys_yield>:

void
sys_yield(void)
{
  80016f:	55                   	push   %ebp
  800170:	89 e5                	mov    %esp,%ebp
  800172:	83 ec 08             	sub    $0x8,%esp
	syscall(SYS_yield, 0, 0, 0, 0, 0, 0);
  800175:	6a 00                	push   $0x0
  800177:	6a 00                	push   $0x0
  800179:	6a 00                	push   $0x0
  80017b:	6a 00                	push   $0x0
  80017d:	b9 00 00 00 00       	mov    $0x0,%ecx
  800182:	ba 00 00 00 00       	mov    $0x0,%edx
  800187:	b8 0a 00 00 00       	mov    $0xa,%eax
  80018c:	e8 04 ff ff ff       	call   800095 <syscall>
}
  800191:	83 c4 10             	add    $0x10,%esp
  800194:	c9                   	leave  
  800195:	c3                   	ret    

00800196 <sys_page_alloc>:

int
sys_page_alloc(envid_t envid, void *va, int perm)
{
  800196:	55                   	push   %ebp
  800197:	89 e5                	mov    %esp,%ebp
  800199:	83 ec 08             	sub    $0x8,%esp
	return syscall(SYS_page_alloc, 1, envid, (uint32_t) va, perm, 0, 0);
  80019c:	6a 00                	push   $0x0
  80019e:	6a 00                	push   $0x0
  8001a0:	ff 75 10             	pushl  0x10(%ebp)
  8001a3:	ff 75 0c             	pushl  0xc(%ebp)
  8001a6:	8b 4d 08             	mov    0x8(%ebp),%ecx
  8001a9:	ba 01 00 00 00       	mov    $0x1,%edx
  8001ae:	b8 04 00 00 00       	mov    $0x4,%eax
  8001b3:	e8 dd fe ff ff       	call   800095 <syscall>
}
  8001b8:	c9                   	leave  
  8001b9:	c3                   	ret    

008001ba <sys_page_map>:

int
sys_page_map(envid_t srcenv, void *srcva, envid_t dstenv, void *dstva, int perm)
{
  8001ba:	55                   	push   %ebp
  8001bb:	89 e5                	mov    %esp,%ebp
  8001bd:	83 ec 08             	sub    $0x8,%esp
	return syscall(SYS_page_map, 1, srcenv, (uint32_t) srcva, dstenv, (uint32_t) dstva, perm);
  8001c0:	ff 75 18             	pushl  0x18(%ebp)
  8001c3:	ff 75 14             	pushl  0x14(%ebp)
  8001c6:	ff 75 10             	pushl  0x10(%ebp)
  8001c9:	ff 75 0c             	pushl  0xc(%ebp)
  8001cc:	8b 4d 08             	mov    0x8(%ebp),%ecx
  8001cf:	ba 01 00 00 00       	mov    $0x1,%edx
  8001d4:	b8 05 00 00 00       	mov    $0x5,%eax
  8001d9:	e8 b7 fe ff ff       	call   800095 <syscall>
}
  8001de:	c9                   	leave  
  8001df:	c3                   	ret    

008001e0 <sys_page_unmap>:

int
sys_page_unmap(envid_t envid, void *va)
{
  8001e0:	55                   	push   %ebp
  8001e1:	89 e5                	mov    %esp,%ebp
  8001e3:	83 ec 08             	sub    $0x8,%esp
	return syscall(SYS_page_unmap, 1, envid, (uint32_t) va, 0, 0, 0);
  8001e6:	6a 00                	push   $0x0
  8001e8:	6a 00                	push   $0x0
  8001ea:	6a 00                	push   $0x0
  8001ec:	ff 75 0c             	pushl  0xc(%ebp)
  8001ef:	8b 4d 08             	mov    0x8(%ebp),%ecx
  8001f2:	ba 01 00 00 00       	mov    $0x1,%edx
  8001f7:	b8 06 00 00 00       	mov    $0x6,%eax
  8001fc:	e8 94 fe ff ff       	call   800095 <syscall>
}
  800201:	c9                   	leave  
  800202:	c3                   	ret    

00800203 <sys_env_set_status>:

// sys_exofork is inlined in lib.h

int
sys_env_set_status(envid_t envid, int status)
{
  800203:	55                   	push   %ebp
  800204:	89 e5                	mov    %esp,%ebp
  800206:	83 ec 08             	sub    $0x8,%esp
	return syscall(SYS_env_set_status, 1, envid, status, 0, 0, 0);
  800209:	6a 00                	push   $0x0
  80020b:	6a 00                	push   $0x0
  80020d:	6a 00                	push   $0x0
  80020f:	ff 75 0c             	pushl  0xc(%ebp)
  800212:	8b 4d 08             	mov    0x8(%ebp),%ecx
  800215:	ba 01 00 00 00       	mov    $0x1,%edx
  80021a:	b8 08 00 00 00       	mov    $0x8,%eax
  80021f:	e8 71 fe ff ff       	call   800095 <syscall>
}
  800224:	c9                   	leave  
  800225:	c3                   	ret    

00800226 <sys_env_set_pgfault_upcall>:

int
sys_env_set_pgfault_upcall(envid_t envid, void *upcall)
{
  800226:	55                   	push   %ebp
  800227:	89 e5                	mov    %esp,%ebp
  800229:	83 ec 08             	sub    $0x8,%esp
	return syscall(SYS_env_set_pgfault_upcall, 1, envid, (uint32_t) upcall, 0, 0, 0);
  80022c:	6a 00                	push   $0x0
  80022e:	6a 00                	push   $0x0
  800230:	6a 00                	push   $0x0
  800232:	ff 75 0c             	pushl  0xc(%ebp)
  800235:	8b 4d 08             	mov    0x8(%ebp),%ecx
  800238:	ba 01 00 00 00       	mov    $0x1,%edx
  80023d:	b8 09 00 00 00       	mov    $0x9,%eax
  800242:	e8 4e fe ff ff       	call   800095 <syscall>
}
  800247:	c9                   	leave  
  800248:	c3                   	ret    

00800249 <sys_ipc_try_send>:

int
sys_ipc_try_send(envid_t envid, uint32_t value, void *srcva, int perm)
{
  800249:	55                   	push   %ebp
  80024a:	89 e5                	mov    %esp,%ebp
  80024c:	83 ec 08             	sub    $0x8,%esp
	return syscall(SYS_ipc_try_send, 0, envid, value, (uint32_t) srcva, perm, 0);
  80024f:	6a 00                	push   $0x0
  800251:	ff 75 14             	pushl  0x14(%ebp)
  800254:	ff 75 10             	pushl  0x10(%ebp)
  800257:	ff 75 0c             	pushl  0xc(%ebp)
  80025a:	8b 4d 08             	mov    0x8(%ebp),%ecx
  80025d:	ba 00 00 00 00       	mov    $0x0,%edx
  800262:	b8 0b 00 00 00       	mov    $0xb,%eax
  800267:	e8 29 fe ff ff       	call   800095 <syscall>
}
  80026c:	c9                   	leave  
  80026d:	c3                   	ret    

0080026e <sys_ipc_recv>:

int
sys_ipc_recv(void *dstva)
{
  80026e:	55                   	push   %ebp
  80026f:	89 e5                	mov    %esp,%ebp
  800271:	83 ec 08             	sub    $0x8,%esp
	return syscall(SYS_ipc_recv, 1, (uint32_t)dstva, 0, 0, 0, 0);
  800274:	6a 00                	push   $0x0
  800276:	6a 00                	push   $0x0
  800278:	6a 00                	push   $0x0
  80027a:	6a 00                	push   $0x0
  80027c:	8b 4d 08             	mov    0x8(%ebp),%ecx
  80027f:	ba 01 00 00 00       	mov    $0x1,%edx
  800284:	b8 0c 00 00 00       	mov    $0xc,%eax
  800289:	e8 07 fe ff ff       	call   800095 <syscall>
}
  80028e:	c9                   	leave  
  80028f:	c3                   	ret    

00800290 <_panic>:
 * It prints "panic: <message>", then causes a breakpoint exception,
 * which causes JOS to enter the JOS kernel monitor.
 */
void
_panic(const char *file, int line, const char *fmt, ...)
{
  800290:	55                   	push   %ebp
  800291:	89 e5                	mov    %esp,%ebp
  800293:	56                   	push   %esi
  800294:	53                   	push   %ebx
	va_list ap;

	va_start(ap, fmt);
  800295:	8d 5d 14             	lea    0x14(%ebp),%ebx

	// Print the panic message
	cprintf("[%08x] user panic in %s at %s:%d: ",
  800298:	8b 35 00 20 80 00    	mov    0x802000,%esi
  80029e:	e8 a8 fe ff ff       	call   80014b <sys_getenvid>
  8002a3:	83 ec 0c             	sub    $0xc,%esp
  8002a6:	ff 75 0c             	pushl  0xc(%ebp)
  8002a9:	ff 75 08             	pushl  0x8(%ebp)
  8002ac:	56                   	push   %esi
  8002ad:	50                   	push   %eax
  8002ae:	68 f8 0e 80 00       	push   $0x800ef8
  8002b3:	e8 b1 00 00 00       	call   800369 <cprintf>
		sys_getenvid(), binaryname, file, line);
	vcprintf(fmt, ap);
  8002b8:	83 c4 18             	add    $0x18,%esp
  8002bb:	53                   	push   %ebx
  8002bc:	ff 75 10             	pushl  0x10(%ebp)
  8002bf:	e8 54 00 00 00       	call   800318 <vcprintf>
	cprintf("\n");
  8002c4:	c7 04 24 1c 0f 80 00 	movl   $0x800f1c,(%esp)
  8002cb:	e8 99 00 00 00       	call   800369 <cprintf>
  8002d0:	83 c4 10             	add    $0x10,%esp

	// Cause a breakpoint exception
	while (1)
		asm volatile("int3");
  8002d3:	cc                   	int3   
  8002d4:	eb fd                	jmp    8002d3 <_panic+0x43>

008002d6 <putch>:
};


static void
putch(int ch, struct printbuf *b)
{
  8002d6:	55                   	push   %ebp
  8002d7:	89 e5                	mov    %esp,%ebp
  8002d9:	53                   	push   %ebx
  8002da:	83 ec 04             	sub    $0x4,%esp
  8002dd:	8b 5d 0c             	mov    0xc(%ebp),%ebx
	b->buf[b->idx++] = ch;
  8002e0:	8b 13                	mov    (%ebx),%edx
  8002e2:	8d 42 01             	lea    0x1(%edx),%eax
  8002e5:	89 03                	mov    %eax,(%ebx)
  8002e7:	8b 4d 08             	mov    0x8(%ebp),%ecx
  8002ea:	88 4c 13 08          	mov    %cl,0x8(%ebx,%edx,1)
	if (b->idx == 256-1) {
  8002ee:	3d ff 00 00 00       	cmp    $0xff,%eax
  8002f3:	75 1a                	jne    80030f <putch+0x39>
		sys_cputs(b->buf, b->idx);
  8002f5:	83 ec 08             	sub    $0x8,%esp
  8002f8:	68 ff 00 00 00       	push   $0xff
  8002fd:	8d 43 08             	lea    0x8(%ebx),%eax
  800300:	50                   	push   %eax
  800301:	e8 d9 fd ff ff       	call   8000df <sys_cputs>
		b->idx = 0;
  800306:	c7 03 00 00 00 00    	movl   $0x0,(%ebx)
  80030c:	83 c4 10             	add    $0x10,%esp
	}
	b->cnt++;
  80030f:	83 43 04 01          	addl   $0x1,0x4(%ebx)
}
  800313:	8b 5d fc             	mov    -0x4(%ebp),%ebx
  800316:	c9                   	leave  
  800317:	c3                   	ret    

00800318 <vcprintf>:

int
vcprintf(const char *fmt, va_list ap)
{
  800318:	55                   	push   %ebp
  800319:	89 e5                	mov    %esp,%ebp
  80031b:	81 ec 18 01 00 00    	sub    $0x118,%esp
	struct printbuf b;

	b.idx = 0;
  800321:	c7 85 f0 fe ff ff 00 	movl   $0x0,-0x110(%ebp)
  800328:	00 00 00 
	b.cnt = 0;
  80032b:	c7 85 f4 fe ff ff 00 	movl   $0x0,-0x10c(%ebp)
  800332:	00 00 00 
	vprintfmt((void*)putch, &b, fmt, ap);
  800335:	ff 75 0c             	pushl  0xc(%ebp)
  800338:	ff 75 08             	pushl  0x8(%ebp)
  80033b:	8d 85 f0 fe ff ff    	lea    -0x110(%ebp),%eax
  800341:	50                   	push   %eax
  800342:	68 d6 02 80 00       	push   $0x8002d6
  800347:	e8 86 01 00 00       	call   8004d2 <vprintfmt>
	sys_cputs(b.buf, b.idx);
  80034c:	83 c4 08             	add    $0x8,%esp
  80034f:	ff b5 f0 fe ff ff    	pushl  -0x110(%ebp)
  800355:	8d 85 f8 fe ff ff    	lea    -0x108(%ebp),%eax
  80035b:	50                   	push   %eax
  80035c:	e8 7e fd ff ff       	call   8000df <sys_cputs>

	return b.cnt;
}
  800361:	8b 85 f4 fe ff ff    	mov    -0x10c(%ebp),%eax
  800367:	c9                   	leave  
  800368:	c3                   	ret    

00800369 <cprintf>:

int
cprintf(const char *fmt, ...)
{
  800369:	55                   	push   %ebp
  80036a:	89 e5                	mov    %esp,%ebp
  80036c:	83 ec 10             	sub    $0x10,%esp
	va_list ap;
	int cnt;

	va_start(ap, fmt);
  80036f:	8d 45 0c             	lea    0xc(%ebp),%eax
	cnt = vcprintf(fmt, ap);
  800372:	50                   	push   %eax
  800373:	ff 75 08             	pushl  0x8(%ebp)
  800376:	e8 9d ff ff ff       	call   800318 <vcprintf>
	va_end(ap);

	return cnt;
}
  80037b:	c9                   	leave  
  80037c:	c3                   	ret    

0080037d <printnum>:
 * using specified putch function and associated pointer putdat.
 */
static void
printnum(void (*putch)(int, void*), void *putdat,
	 unsigned long long num, unsigned base, int width, int padc)
{
  80037d:	55                   	push   %ebp
  80037e:	89 e5                	mov    %esp,%ebp
  800380:	57                   	push   %edi
  800381:	56                   	push   %esi
  800382:	53                   	push   %ebx
  800383:	83 ec 1c             	sub    $0x1c,%esp
  800386:	89 c7                	mov    %eax,%edi
  800388:	89 d6                	mov    %edx,%esi
  80038a:	8b 45 08             	mov    0x8(%ebp),%eax
  80038d:	8b 55 0c             	mov    0xc(%ebp),%edx
  800390:	89 45 d8             	mov    %eax,-0x28(%ebp)
  800393:	89 55 dc             	mov    %edx,-0x24(%ebp)
	// first recursively print all preceding (more significant) digits
	if (num >= base) {
  800396:	8b 4d 10             	mov    0x10(%ebp),%ecx
  800399:	bb 00 00 00 00       	mov    $0x0,%ebx
  80039e:	89 4d e0             	mov    %ecx,-0x20(%ebp)
  8003a1:	89 5d e4             	mov    %ebx,-0x1c(%ebp)
  8003a4:	39 d3                	cmp    %edx,%ebx
  8003a6:	72 05                	jb     8003ad <printnum+0x30>
  8003a8:	39 45 10             	cmp    %eax,0x10(%ebp)
  8003ab:	77 45                	ja     8003f2 <printnum+0x75>
		printnum(putch, putdat, num / base, base, width - 1, padc);
  8003ad:	83 ec 0c             	sub    $0xc,%esp
  8003b0:	ff 75 18             	pushl  0x18(%ebp)
  8003b3:	8b 45 14             	mov    0x14(%ebp),%eax
  8003b6:	8d 58 ff             	lea    -0x1(%eax),%ebx
  8003b9:	53                   	push   %ebx
  8003ba:	ff 75 10             	pushl  0x10(%ebp)
  8003bd:	83 ec 08             	sub    $0x8,%esp
  8003c0:	ff 75 e4             	pushl  -0x1c(%ebp)
  8003c3:	ff 75 e0             	pushl  -0x20(%ebp)
  8003c6:	ff 75 dc             	pushl  -0x24(%ebp)
  8003c9:	ff 75 d8             	pushl  -0x28(%ebp)
  8003cc:	e8 4f 08 00 00       	call   800c20 <__udivdi3>
  8003d1:	83 c4 18             	add    $0x18,%esp
  8003d4:	52                   	push   %edx
  8003d5:	50                   	push   %eax
  8003d6:	89 f2                	mov    %esi,%edx
  8003d8:	89 f8                	mov    %edi,%eax
  8003da:	e8 9e ff ff ff       	call   80037d <printnum>
  8003df:	83 c4 20             	add    $0x20,%esp
  8003e2:	eb 18                	jmp    8003fc <printnum+0x7f>
	} else {
		// print any needed pad characters before first digit
		while (--width > 0)
			putch(padc, putdat);
  8003e4:	83 ec 08             	sub    $0x8,%esp
  8003e7:	56                   	push   %esi
  8003e8:	ff 75 18             	pushl  0x18(%ebp)
  8003eb:	ff d7                	call   *%edi
  8003ed:	83 c4 10             	add    $0x10,%esp
  8003f0:	eb 03                	jmp    8003f5 <printnum+0x78>
  8003f2:	8b 5d 14             	mov    0x14(%ebp),%ebx
	// first recursively print all preceding (more significant) digits
	if (num >= base) {
		printnum(putch, putdat, num / base, base, width - 1, padc);
	} else {
		// print any needed pad characters before first digit
		while (--width > 0)
  8003f5:	83 eb 01             	sub    $0x1,%ebx
  8003f8:	85 db                	test   %ebx,%ebx
  8003fa:	7f e8                	jg     8003e4 <printnum+0x67>
			putch(padc, putdat);
	}

	// then print this (the least significant) digit
	putch("0123456789abcdef"[num % base], putdat);
  8003fc:	83 ec 08             	sub    $0x8,%esp
  8003ff:	56                   	push   %esi
  800400:	83 ec 04             	sub    $0x4,%esp
  800403:	ff 75 e4             	pushl  -0x1c(%ebp)
  800406:	ff 75 e0             	pushl  -0x20(%ebp)
  800409:	ff 75 dc             	pushl  -0x24(%ebp)
  80040c:	ff 75 d8             	pushl  -0x28(%ebp)
  80040f:	e8 3c 09 00 00       	call   800d50 <__umoddi3>
  800414:	83 c4 14             	add    $0x14,%esp
  800417:	0f be 80 1e 0f 80 00 	movsbl 0x800f1e(%eax),%eax
  80041e:	50                   	push   %eax
  80041f:	ff d7                	call   *%edi
}
  800421:	83 c4 10             	add    $0x10,%esp
  800424:	8d 65 f4             	lea    -0xc(%ebp),%esp
  800427:	5b                   	pop    %ebx
  800428:	5e                   	pop    %esi
  800429:	5f                   	pop    %edi
  80042a:	5d                   	pop    %ebp
  80042b:	c3                   	ret    

0080042c <getuint>:

// Get an unsigned int of various possible sizes from a varargs list,
// depending on the lflag parameter.
static unsigned long long
getuint(va_list *ap, int lflag)
{
  80042c:	55                   	push   %ebp
  80042d:	89 e5                	mov    %esp,%ebp
	if (lflag >= 2)
  80042f:	83 fa 01             	cmp    $0x1,%edx
  800432:	7e 0e                	jle    800442 <getuint+0x16>
		return va_arg(*ap, unsigned long long);
  800434:	8b 10                	mov    (%eax),%edx
  800436:	8d 4a 08             	lea    0x8(%edx),%ecx
  800439:	89 08                	mov    %ecx,(%eax)
  80043b:	8b 02                	mov    (%edx),%eax
  80043d:	8b 52 04             	mov    0x4(%edx),%edx
  800440:	eb 22                	jmp    800464 <getuint+0x38>
	else if (lflag)
  800442:	85 d2                	test   %edx,%edx
  800444:	74 10                	je     800456 <getuint+0x2a>
		return va_arg(*ap, unsigned long);
  800446:	8b 10                	mov    (%eax),%edx
  800448:	8d 4a 04             	lea    0x4(%edx),%ecx
  80044b:	89 08                	mov    %ecx,(%eax)
  80044d:	8b 02                	mov    (%edx),%eax
  80044f:	ba 00 00 00 00       	mov    $0x0,%edx
  800454:	eb 0e                	jmp    800464 <getuint+0x38>
	else
		return va_arg(*ap, unsigned int);
  800456:	8b 10                	mov    (%eax),%edx
  800458:	8d 4a 04             	lea    0x4(%edx),%ecx
  80045b:	89 08                	mov    %ecx,(%eax)
  80045d:	8b 02                	mov    (%edx),%eax
  80045f:	ba 00 00 00 00       	mov    $0x0,%edx
}
  800464:	5d                   	pop    %ebp
  800465:	c3                   	ret    

00800466 <getint>:

// Same as getuint but signed - can't use getuint
// because of sign extension
static long long
getint(va_list *ap, int lflag)
{
  800466:	55                   	push   %ebp
  800467:	89 e5                	mov    %esp,%ebp
	if (lflag >= 2)
  800469:	83 fa 01             	cmp    $0x1,%edx
  80046c:	7e 0e                	jle    80047c <getint+0x16>
		return va_arg(*ap, long long);
  80046e:	8b 10                	mov    (%eax),%edx
  800470:	8d 4a 08             	lea    0x8(%edx),%ecx
  800473:	89 08                	mov    %ecx,(%eax)
  800475:	8b 02                	mov    (%edx),%eax
  800477:	8b 52 04             	mov    0x4(%edx),%edx
  80047a:	eb 1a                	jmp    800496 <getint+0x30>
	else if (lflag)
  80047c:	85 d2                	test   %edx,%edx
  80047e:	74 0c                	je     80048c <getint+0x26>
		return va_arg(*ap, long);
  800480:	8b 10                	mov    (%eax),%edx
  800482:	8d 4a 04             	lea    0x4(%edx),%ecx
  800485:	89 08                	mov    %ecx,(%eax)
  800487:	8b 02                	mov    (%edx),%eax
  800489:	99                   	cltd   
  80048a:	eb 0a                	jmp    800496 <getint+0x30>
	else
		return va_arg(*ap, int);
  80048c:	8b 10                	mov    (%eax),%edx
  80048e:	8d 4a 04             	lea    0x4(%edx),%ecx
  800491:	89 08                	mov    %ecx,(%eax)
  800493:	8b 02                	mov    (%edx),%eax
  800495:	99                   	cltd   
}
  800496:	5d                   	pop    %ebp
  800497:	c3                   	ret    

00800498 <sprintputch>:
	int cnt;
};

static void
sprintputch(int ch, struct sprintbuf *b)
{
  800498:	55                   	push   %ebp
  800499:	89 e5                	mov    %esp,%ebp
  80049b:	8b 45 0c             	mov    0xc(%ebp),%eax
	b->cnt++;
  80049e:	83 40 08 01          	addl   $0x1,0x8(%eax)
	if (b->buf < b->ebuf)
  8004a2:	8b 10                	mov    (%eax),%edx
  8004a4:	3b 50 04             	cmp    0x4(%eax),%edx
  8004a7:	73 0a                	jae    8004b3 <sprintputch+0x1b>
		*b->buf++ = ch;
  8004a9:	8d 4a 01             	lea    0x1(%edx),%ecx
  8004ac:	89 08                	mov    %ecx,(%eax)
  8004ae:	8b 45 08             	mov    0x8(%ebp),%eax
  8004b1:	88 02                	mov    %al,(%edx)
}
  8004b3:	5d                   	pop    %ebp
  8004b4:	c3                   	ret    

008004b5 <printfmt>:
	}
}

void
printfmt(void (*putch)(int, void*), void *putdat, const char *fmt, ...)
{
  8004b5:	55                   	push   %ebp
  8004b6:	89 e5                	mov    %esp,%ebp
  8004b8:	83 ec 08             	sub    $0x8,%esp
	va_list ap;

	va_start(ap, fmt);
  8004bb:	8d 45 14             	lea    0x14(%ebp),%eax
	vprintfmt(putch, putdat, fmt, ap);
  8004be:	50                   	push   %eax
  8004bf:	ff 75 10             	pushl  0x10(%ebp)
  8004c2:	ff 75 0c             	pushl  0xc(%ebp)
  8004c5:	ff 75 08             	pushl  0x8(%ebp)
  8004c8:	e8 05 00 00 00       	call   8004d2 <vprintfmt>
	va_end(ap);
}
  8004cd:	83 c4 10             	add    $0x10,%esp
  8004d0:	c9                   	leave  
  8004d1:	c3                   	ret    

008004d2 <vprintfmt>:
// Main function to format and print a string.
void printfmt(void (*putch)(int, void*), void *putdat, const char *fmt, ...);

void
vprintfmt(void (*putch)(int, void*), void *putdat, const char *fmt, va_list ap)
{
  8004d2:	55                   	push   %ebp
  8004d3:	89 e5                	mov    %esp,%ebp
  8004d5:	57                   	push   %edi
  8004d6:	56                   	push   %esi
  8004d7:	53                   	push   %ebx
  8004d8:	83 ec 2c             	sub    $0x2c,%esp
  8004db:	8b 75 08             	mov    0x8(%ebp),%esi
  8004de:	8b 5d 0c             	mov    0xc(%ebp),%ebx
  8004e1:	8b 7d 10             	mov    0x10(%ebp),%edi
  8004e4:	eb 12                	jmp    8004f8 <vprintfmt+0x26>
	int base, lflag, width, precision, altflag;
	char padc;

	while (1) {
		while ((ch = *(unsigned char *) fmt++) != '%') {
			if (ch == '\0')
  8004e6:	85 c0                	test   %eax,%eax
  8004e8:	0f 84 44 03 00 00    	je     800832 <vprintfmt+0x360>
				return;
			putch(ch, putdat);
  8004ee:	83 ec 08             	sub    $0x8,%esp
  8004f1:	53                   	push   %ebx
  8004f2:	50                   	push   %eax
  8004f3:	ff d6                	call   *%esi
  8004f5:	83 c4 10             	add    $0x10,%esp
	unsigned long long num;
	int base, lflag, width, precision, altflag;
	char padc;

	while (1) {
		while ((ch = *(unsigned char *) fmt++) != '%') {
  8004f8:	83 c7 01             	add    $0x1,%edi
  8004fb:	0f b6 47 ff          	movzbl -0x1(%edi),%eax
  8004ff:	83 f8 25             	cmp    $0x25,%eax
  800502:	75 e2                	jne    8004e6 <vprintfmt+0x14>
  800504:	c6 45 d4 20          	movb   $0x20,-0x2c(%ebp)
  800508:	c7 45 d8 00 00 00 00 	movl   $0x0,-0x28(%ebp)
  80050f:	c7 45 d0 ff ff ff ff 	movl   $0xffffffff,-0x30(%ebp)
  800516:	c7 45 e0 ff ff ff ff 	movl   $0xffffffff,-0x20(%ebp)
  80051d:	ba 00 00 00 00       	mov    $0x0,%edx
  800522:	eb 07                	jmp    80052b <vprintfmt+0x59>
		width = -1;
		precision = -1;
		lflag = 0;
		altflag = 0;
	reswitch:
		switch (ch = *(unsigned char *) fmt++) {
  800524:	8b 7d e4             	mov    -0x1c(%ebp),%edi

		// flag to pad on the right
		case '-':
			padc = '-';
  800527:	c6 45 d4 2d          	movb   $0x2d,-0x2c(%ebp)
		width = -1;
		precision = -1;
		lflag = 0;
		altflag = 0;
	reswitch:
		switch (ch = *(unsigned char *) fmt++) {
  80052b:	8d 47 01             	lea    0x1(%edi),%eax
  80052e:	89 45 e4             	mov    %eax,-0x1c(%ebp)
  800531:	0f b6 07             	movzbl (%edi),%eax
  800534:	0f b6 c8             	movzbl %al,%ecx
  800537:	83 e8 23             	sub    $0x23,%eax
  80053a:	3c 55                	cmp    $0x55,%al
  80053c:	0f 87 d5 02 00 00    	ja     800817 <vprintfmt+0x345>
  800542:	0f b6 c0             	movzbl %al,%eax
  800545:	ff 24 85 e0 0f 80 00 	jmp    *0x800fe0(,%eax,4)
  80054c:	8b 7d e4             	mov    -0x1c(%ebp),%edi
			padc = '-';
			goto reswitch;

		// flag to pad with 0's instead of spaces
		case '0':
			padc = '0';
  80054f:	c6 45 d4 30          	movb   $0x30,-0x2c(%ebp)
  800553:	eb d6                	jmp    80052b <vprintfmt+0x59>
		width = -1;
		precision = -1;
		lflag = 0;
		altflag = 0;
	reswitch:
		switch (ch = *(unsigned char *) fmt++) {
  800555:	8b 7d e4             	mov    -0x1c(%ebp),%edi
  800558:	b8 00 00 00 00       	mov    $0x0,%eax
  80055d:	89 55 e4             	mov    %edx,-0x1c(%ebp)
		case '6':
		case '7':
		case '8':
		case '9':
			for (precision = 0; ; ++fmt) {
				precision = precision * 10 + ch - '0';
  800560:	8d 04 80             	lea    (%eax,%eax,4),%eax
  800563:	8d 44 41 d0          	lea    -0x30(%ecx,%eax,2),%eax
				ch = *fmt;
  800567:	0f be 0f             	movsbl (%edi),%ecx
				if (ch < '0' || ch > '9')
  80056a:	8d 51 d0             	lea    -0x30(%ecx),%edx
  80056d:	83 fa 09             	cmp    $0x9,%edx
  800570:	77 39                	ja     8005ab <vprintfmt+0xd9>
		case '5':
		case '6':
		case '7':
		case '8':
		case '9':
			for (precision = 0; ; ++fmt) {
  800572:	83 c7 01             	add    $0x1,%edi
				precision = precision * 10 + ch - '0';
				ch = *fmt;
				if (ch < '0' || ch > '9')
					break;
			}
  800575:	eb e9                	jmp    800560 <vprintfmt+0x8e>
			goto process_precision;

		case '*':
			precision = va_arg(ap, int);
  800577:	8b 45 14             	mov    0x14(%ebp),%eax
  80057a:	8d 48 04             	lea    0x4(%eax),%ecx
  80057d:	89 4d 14             	mov    %ecx,0x14(%ebp)
  800580:	8b 00                	mov    (%eax),%eax
  800582:	89 45 d0             	mov    %eax,-0x30(%ebp)
		width = -1;
		precision = -1;
		lflag = 0;
		altflag = 0;
	reswitch:
		switch (ch = *(unsigned char *) fmt++) {
  800585:	8b 7d e4             	mov    -0x1c(%ebp),%edi
			}
			goto process_precision;

		case '*':
			precision = va_arg(ap, int);
			goto process_precision;
  800588:	eb 27                	jmp    8005b1 <vprintfmt+0xdf>
  80058a:	8b 45 e0             	mov    -0x20(%ebp),%eax
  80058d:	85 c0                	test   %eax,%eax
  80058f:	b9 00 00 00 00       	mov    $0x0,%ecx
  800594:	0f 49 c8             	cmovns %eax,%ecx
  800597:	89 4d e0             	mov    %ecx,-0x20(%ebp)
		width = -1;
		precision = -1;
		lflag = 0;
		altflag = 0;
	reswitch:
		switch (ch = *(unsigned char *) fmt++) {
  80059a:	8b 7d e4             	mov    -0x1c(%ebp),%edi
  80059d:	eb 8c                	jmp    80052b <vprintfmt+0x59>
  80059f:	8b 7d e4             	mov    -0x1c(%ebp),%edi
			if (width < 0)
				width = 0;
			goto reswitch;

		case '#':
			altflag = 1;
  8005a2:	c7 45 d8 01 00 00 00 	movl   $0x1,-0x28(%ebp)
			goto reswitch;
  8005a9:	eb 80                	jmp    80052b <vprintfmt+0x59>
  8005ab:	8b 55 e4             	mov    -0x1c(%ebp),%edx
  8005ae:	89 45 d0             	mov    %eax,-0x30(%ebp)

		process_precision:
			if (width < 0)
  8005b1:	83 7d e0 00          	cmpl   $0x0,-0x20(%ebp)
  8005b5:	0f 89 70 ff ff ff    	jns    80052b <vprintfmt+0x59>
				width = precision, precision = -1;
  8005bb:	8b 45 d0             	mov    -0x30(%ebp),%eax
  8005be:	89 45 e0             	mov    %eax,-0x20(%ebp)
  8005c1:	c7 45 d0 ff ff ff ff 	movl   $0xffffffff,-0x30(%ebp)
  8005c8:	e9 5e ff ff ff       	jmp    80052b <vprintfmt+0x59>
			goto reswitch;

		// long flag (doubled for long long)
		case 'l':
			lflag++;
  8005cd:	83 c2 01             	add    $0x1,%edx
		width = -1;
		precision = -1;
		lflag = 0;
		altflag = 0;
	reswitch:
		switch (ch = *(unsigned char *) fmt++) {
  8005d0:	8b 7d e4             	mov    -0x1c(%ebp),%edi
			goto reswitch;

		// long flag (doubled for long long)
		case 'l':
			lflag++;
			goto reswitch;
  8005d3:	e9 53 ff ff ff       	jmp    80052b <vprintfmt+0x59>

		// character
		case 'c':
			putch(va_arg(ap, int), putdat);
  8005d8:	8b 45 14             	mov    0x14(%ebp),%eax
  8005db:	8d 50 04             	lea    0x4(%eax),%edx
  8005de:	89 55 14             	mov    %edx,0x14(%ebp)
  8005e1:	83 ec 08             	sub    $0x8,%esp
  8005e4:	53                   	push   %ebx
  8005e5:	ff 30                	pushl  (%eax)
  8005e7:	ff d6                	call   *%esi
			break;
  8005e9:	83 c4 10             	add    $0x10,%esp
		width = -1;
		precision = -1;
		lflag = 0;
		altflag = 0;
	reswitch:
		switch (ch = *(unsigned char *) fmt++) {
  8005ec:	8b 7d e4             	mov    -0x1c(%ebp),%edi
			goto reswitch;

		// character
		case 'c':
			putch(va_arg(ap, int), putdat);
			break;
  8005ef:	e9 04 ff ff ff       	jmp    8004f8 <vprintfmt+0x26>

		// error message
		case 'e':
			err = va_arg(ap, int);
  8005f4:	8b 45 14             	mov    0x14(%ebp),%eax
  8005f7:	8d 50 04             	lea    0x4(%eax),%edx
  8005fa:	89 55 14             	mov    %edx,0x14(%ebp)
  8005fd:	8b 00                	mov    (%eax),%eax
  8005ff:	99                   	cltd   
  800600:	31 d0                	xor    %edx,%eax
  800602:	29 d0                	sub    %edx,%eax
			if (err < 0)
				err = -err;
			if (err >= MAXERROR || (p = error_string[err]) == NULL)
  800604:	83 f8 08             	cmp    $0x8,%eax
  800607:	7f 0b                	jg     800614 <vprintfmt+0x142>
  800609:	8b 14 85 40 11 80 00 	mov    0x801140(,%eax,4),%edx
  800610:	85 d2                	test   %edx,%edx
  800612:	75 18                	jne    80062c <vprintfmt+0x15a>
				printfmt(putch, putdat, "error %d", err);
  800614:	50                   	push   %eax
  800615:	68 36 0f 80 00       	push   $0x800f36
  80061a:	53                   	push   %ebx
  80061b:	56                   	push   %esi
  80061c:	e8 94 fe ff ff       	call   8004b5 <printfmt>
  800621:	83 c4 10             	add    $0x10,%esp
		width = -1;
		precision = -1;
		lflag = 0;
		altflag = 0;
	reswitch:
		switch (ch = *(unsigned char *) fmt++) {
  800624:	8b 7d e4             	mov    -0x1c(%ebp),%edi
		case 'e':
			err = va_arg(ap, int);
			if (err < 0)
				err = -err;
			if (err >= MAXERROR || (p = error_string[err]) == NULL)
				printfmt(putch, putdat, "error %d", err);
  800627:	e9 cc fe ff ff       	jmp    8004f8 <vprintfmt+0x26>
			else
				printfmt(putch, putdat, "%s", p);
  80062c:	52                   	push   %edx
  80062d:	68 3f 0f 80 00       	push   $0x800f3f
  800632:	53                   	push   %ebx
  800633:	56                   	push   %esi
  800634:	e8 7c fe ff ff       	call   8004b5 <printfmt>
  800639:	83 c4 10             	add    $0x10,%esp
		width = -1;
		precision = -1;
		lflag = 0;
		altflag = 0;
	reswitch:
		switch (ch = *(unsigned char *) fmt++) {
  80063c:	8b 7d e4             	mov    -0x1c(%ebp),%edi
  80063f:	e9 b4 fe ff ff       	jmp    8004f8 <vprintfmt+0x26>
				printfmt(putch, putdat, "%s", p);
			break;

		// string
		case 's':
			if ((p = va_arg(ap, char *)) == NULL)
  800644:	8b 45 14             	mov    0x14(%ebp),%eax
  800647:	8d 50 04             	lea    0x4(%eax),%edx
  80064a:	89 55 14             	mov    %edx,0x14(%ebp)
  80064d:	8b 38                	mov    (%eax),%edi
				p = "(null)";
  80064f:	85 ff                	test   %edi,%edi
  800651:	b8 2f 0f 80 00       	mov    $0x800f2f,%eax
  800656:	0f 44 f8             	cmove  %eax,%edi
			if (width > 0 && padc != '-')
  800659:	83 7d e0 00          	cmpl   $0x0,-0x20(%ebp)
  80065d:	0f 8e 94 00 00 00    	jle    8006f7 <vprintfmt+0x225>
  800663:	80 7d d4 2d          	cmpb   $0x2d,-0x2c(%ebp)
  800667:	0f 84 98 00 00 00    	je     800705 <vprintfmt+0x233>
				for (width -= strnlen(p, precision); width > 0; width--)
  80066d:	83 ec 08             	sub    $0x8,%esp
  800670:	ff 75 d0             	pushl  -0x30(%ebp)
  800673:	57                   	push   %edi
  800674:	e8 41 02 00 00       	call   8008ba <strnlen>
  800679:	8b 4d e0             	mov    -0x20(%ebp),%ecx
  80067c:	29 c1                	sub    %eax,%ecx
  80067e:	89 4d cc             	mov    %ecx,-0x34(%ebp)
  800681:	83 c4 10             	add    $0x10,%esp
					putch(padc, putdat);
  800684:	0f be 45 d4          	movsbl -0x2c(%ebp),%eax
  800688:	89 45 e0             	mov    %eax,-0x20(%ebp)
  80068b:	89 7d d4             	mov    %edi,-0x2c(%ebp)
  80068e:	89 cf                	mov    %ecx,%edi
		// string
		case 's':
			if ((p = va_arg(ap, char *)) == NULL)
				p = "(null)";
			if (width > 0 && padc != '-')
				for (width -= strnlen(p, precision); width > 0; width--)
  800690:	eb 0f                	jmp    8006a1 <vprintfmt+0x1cf>
					putch(padc, putdat);
  800692:	83 ec 08             	sub    $0x8,%esp
  800695:	53                   	push   %ebx
  800696:	ff 75 e0             	pushl  -0x20(%ebp)
  800699:	ff d6                	call   *%esi
		// string
		case 's':
			if ((p = va_arg(ap, char *)) == NULL)
				p = "(null)";
			if (width > 0 && padc != '-')
				for (width -= strnlen(p, precision); width > 0; width--)
  80069b:	83 ef 01             	sub    $0x1,%edi
  80069e:	83 c4 10             	add    $0x10,%esp
  8006a1:	85 ff                	test   %edi,%edi
  8006a3:	7f ed                	jg     800692 <vprintfmt+0x1c0>
  8006a5:	8b 7d d4             	mov    -0x2c(%ebp),%edi
  8006a8:	8b 4d cc             	mov    -0x34(%ebp),%ecx
  8006ab:	85 c9                	test   %ecx,%ecx
  8006ad:	b8 00 00 00 00       	mov    $0x0,%eax
  8006b2:	0f 49 c1             	cmovns %ecx,%eax
  8006b5:	29 c1                	sub    %eax,%ecx
  8006b7:	89 75 08             	mov    %esi,0x8(%ebp)
  8006ba:	8b 75 d0             	mov    -0x30(%ebp),%esi
  8006bd:	89 5d 0c             	mov    %ebx,0xc(%ebp)
  8006c0:	89 cb                	mov    %ecx,%ebx
  8006c2:	eb 4d                	jmp    800711 <vprintfmt+0x23f>
					putch(padc, putdat);
			for (; (ch = *p++) != '\0' && (precision < 0 || --precision >= 0); width--)
				if (altflag && (ch < ' ' || ch > '~'))
  8006c4:	83 7d d8 00          	cmpl   $0x0,-0x28(%ebp)
  8006c8:	74 1b                	je     8006e5 <vprintfmt+0x213>
  8006ca:	0f be c0             	movsbl %al,%eax
  8006cd:	83 e8 20             	sub    $0x20,%eax
  8006d0:	83 f8 5e             	cmp    $0x5e,%eax
  8006d3:	76 10                	jbe    8006e5 <vprintfmt+0x213>
					putch('?', putdat);
  8006d5:	83 ec 08             	sub    $0x8,%esp
  8006d8:	ff 75 0c             	pushl  0xc(%ebp)
  8006db:	6a 3f                	push   $0x3f
  8006dd:	ff 55 08             	call   *0x8(%ebp)
  8006e0:	83 c4 10             	add    $0x10,%esp
  8006e3:	eb 0d                	jmp    8006f2 <vprintfmt+0x220>
				else
					putch(ch, putdat);
  8006e5:	83 ec 08             	sub    $0x8,%esp
  8006e8:	ff 75 0c             	pushl  0xc(%ebp)
  8006eb:	52                   	push   %edx
  8006ec:	ff 55 08             	call   *0x8(%ebp)
  8006ef:	83 c4 10             	add    $0x10,%esp
			if ((p = va_arg(ap, char *)) == NULL)
				p = "(null)";
			if (width > 0 && padc != '-')
				for (width -= strnlen(p, precision); width > 0; width--)
					putch(padc, putdat);
			for (; (ch = *p++) != '\0' && (precision < 0 || --precision >= 0); width--)
  8006f2:	83 eb 01             	sub    $0x1,%ebx
  8006f5:	eb 1a                	jmp    800711 <vprintfmt+0x23f>
  8006f7:	89 75 08             	mov    %esi,0x8(%ebp)
  8006fa:	8b 75 d0             	mov    -0x30(%ebp),%esi
  8006fd:	89 5d 0c             	mov    %ebx,0xc(%ebp)
  800700:	8b 5d e0             	mov    -0x20(%ebp),%ebx
  800703:	eb 0c                	jmp    800711 <vprintfmt+0x23f>
  800705:	89 75 08             	mov    %esi,0x8(%ebp)
  800708:	8b 75 d0             	mov    -0x30(%ebp),%esi
  80070b:	89 5d 0c             	mov    %ebx,0xc(%ebp)
  80070e:	8b 5d e0             	mov    -0x20(%ebp),%ebx
  800711:	83 c7 01             	add    $0x1,%edi
  800714:	0f b6 47 ff          	movzbl -0x1(%edi),%eax
  800718:	0f be d0             	movsbl %al,%edx
  80071b:	85 d2                	test   %edx,%edx
  80071d:	74 23                	je     800742 <vprintfmt+0x270>
  80071f:	85 f6                	test   %esi,%esi
  800721:	78 a1                	js     8006c4 <vprintfmt+0x1f2>
  800723:	83 ee 01             	sub    $0x1,%esi
  800726:	79 9c                	jns    8006c4 <vprintfmt+0x1f2>
  800728:	89 df                	mov    %ebx,%edi
  80072a:	8b 75 08             	mov    0x8(%ebp),%esi
  80072d:	8b 5d 0c             	mov    0xc(%ebp),%ebx
  800730:	eb 18                	jmp    80074a <vprintfmt+0x278>
				if (altflag && (ch < ' ' || ch > '~'))
					putch('?', putdat);
				else
					putch(ch, putdat);
			for (; width > 0; width--)
				putch(' ', putdat);
  800732:	83 ec 08             	sub    $0x8,%esp
  800735:	53                   	push   %ebx
  800736:	6a 20                	push   $0x20
  800738:	ff d6                	call   *%esi
			for (; (ch = *p++) != '\0' && (precision < 0 || --precision >= 0); width--)
				if (altflag && (ch < ' ' || ch > '~'))
					putch('?', putdat);
				else
					putch(ch, putdat);
			for (; width > 0; width--)
  80073a:	83 ef 01             	sub    $0x1,%edi
  80073d:	83 c4 10             	add    $0x10,%esp
  800740:	eb 08                	jmp    80074a <vprintfmt+0x278>
  800742:	89 df                	mov    %ebx,%edi
  800744:	8b 75 08             	mov    0x8(%ebp),%esi
  800747:	8b 5d 0c             	mov    0xc(%ebp),%ebx
  80074a:	85 ff                	test   %edi,%edi
  80074c:	7f e4                	jg     800732 <vprintfmt+0x260>
		width = -1;
		precision = -1;
		lflag = 0;
		altflag = 0;
	reswitch:
		switch (ch = *(unsigned char *) fmt++) {
  80074e:	8b 7d e4             	mov    -0x1c(%ebp),%edi
  800751:	e9 a2 fd ff ff       	jmp    8004f8 <vprintfmt+0x26>
				putch(' ', putdat);
			break;

		// (signed) decimal
		case 'd':
			num = getint(&ap, lflag);
  800756:	8d 45 14             	lea    0x14(%ebp),%eax
  800759:	e8 08 fd ff ff       	call   800466 <getint>
  80075e:	89 45 d8             	mov    %eax,-0x28(%ebp)
  800761:	89 55 dc             	mov    %edx,-0x24(%ebp)
			if ((long long) num < 0) {
				putch('-', putdat);
				num = -(long long) num;
			}
			base = 10;
  800764:	b9 0a 00 00 00       	mov    $0xa,%ecx
			break;

		// (signed) decimal
		case 'd':
			num = getint(&ap, lflag);
			if ((long long) num < 0) {
  800769:	83 7d dc 00          	cmpl   $0x0,-0x24(%ebp)
  80076d:	79 74                	jns    8007e3 <vprintfmt+0x311>
				putch('-', putdat);
  80076f:	83 ec 08             	sub    $0x8,%esp
  800772:	53                   	push   %ebx
  800773:	6a 2d                	push   $0x2d
  800775:	ff d6                	call   *%esi
				num = -(long long) num;
  800777:	8b 45 d8             	mov    -0x28(%ebp),%eax
  80077a:	8b 55 dc             	mov    -0x24(%ebp),%edx
  80077d:	f7 d8                	neg    %eax
  80077f:	83 d2 00             	adc    $0x0,%edx
  800782:	f7 da                	neg    %edx
  800784:	83 c4 10             	add    $0x10,%esp
			}
			base = 10;
  800787:	b9 0a 00 00 00       	mov    $0xa,%ecx
  80078c:	eb 55                	jmp    8007e3 <vprintfmt+0x311>
			goto number;

		// unsigned decimal
		case 'u':
			num = getuint(&ap, lflag);
  80078e:	8d 45 14             	lea    0x14(%ebp),%eax
  800791:	e8 96 fc ff ff       	call   80042c <getuint>
			base = 10;
  800796:	b9 0a 00 00 00       	mov    $0xa,%ecx
			goto number;
  80079b:	eb 46                	jmp    8007e3 <vprintfmt+0x311>

		// (unsigned) octal
		case 'o':
			num = getuint(&ap, lflag);
  80079d:	8d 45 14             	lea    0x14(%ebp),%eax
  8007a0:	e8 87 fc ff ff       	call   80042c <getuint>
			base = 8;
  8007a5:	b9 08 00 00 00       	mov    $0x8,%ecx
			goto number;
  8007aa:	eb 37                	jmp    8007e3 <vprintfmt+0x311>

		// pointer
		case 'p':
			putch('0', putdat);
  8007ac:	83 ec 08             	sub    $0x8,%esp
  8007af:	53                   	push   %ebx
  8007b0:	6a 30                	push   $0x30
  8007b2:	ff d6                	call   *%esi
			putch('x', putdat);
  8007b4:	83 c4 08             	add    $0x8,%esp
  8007b7:	53                   	push   %ebx
  8007b8:	6a 78                	push   $0x78
  8007ba:	ff d6                	call   *%esi
			num = (unsigned long long)
				(uintptr_t) va_arg(ap, void *);
  8007bc:	8b 45 14             	mov    0x14(%ebp),%eax
  8007bf:	8d 50 04             	lea    0x4(%eax),%edx
  8007c2:	89 55 14             	mov    %edx,0x14(%ebp)

		// pointer
		case 'p':
			putch('0', putdat);
			putch('x', putdat);
			num = (unsigned long long)
  8007c5:	8b 00                	mov    (%eax),%eax
  8007c7:	ba 00 00 00 00       	mov    $0x0,%edx
				(uintptr_t) va_arg(ap, void *);
			base = 16;
			goto number;
  8007cc:	83 c4 10             	add    $0x10,%esp
		case 'p':
			putch('0', putdat);
			putch('x', putdat);
			num = (unsigned long long)
				(uintptr_t) va_arg(ap, void *);
			base = 16;
  8007cf:	b9 10 00 00 00       	mov    $0x10,%ecx
			goto number;
  8007d4:	eb 0d                	jmp    8007e3 <vprintfmt+0x311>

		// (unsigned) hexadecimal
		case 'x':
			num = getuint(&ap, lflag);
  8007d6:	8d 45 14             	lea    0x14(%ebp),%eax
  8007d9:	e8 4e fc ff ff       	call   80042c <getuint>
			base = 16;
  8007de:	b9 10 00 00 00       	mov    $0x10,%ecx
		number:
			printnum(putch, putdat, num, base, width, padc);
  8007e3:	83 ec 0c             	sub    $0xc,%esp
  8007e6:	0f be 7d d4          	movsbl -0x2c(%ebp),%edi
  8007ea:	57                   	push   %edi
  8007eb:	ff 75 e0             	pushl  -0x20(%ebp)
  8007ee:	51                   	push   %ecx
  8007ef:	52                   	push   %edx
  8007f0:	50                   	push   %eax
  8007f1:	89 da                	mov    %ebx,%edx
  8007f3:	89 f0                	mov    %esi,%eax
  8007f5:	e8 83 fb ff ff       	call   80037d <printnum>
			break;
  8007fa:	83 c4 20             	add    $0x20,%esp
  8007fd:	8b 7d e4             	mov    -0x1c(%ebp),%edi
  800800:	e9 f3 fc ff ff       	jmp    8004f8 <vprintfmt+0x26>

		// escaped '%' character
		case '%':
			putch(ch, putdat);
  800805:	83 ec 08             	sub    $0x8,%esp
  800808:	53                   	push   %ebx
  800809:	51                   	push   %ecx
  80080a:	ff d6                	call   *%esi
			break;
  80080c:	83 c4 10             	add    $0x10,%esp
		width = -1;
		precision = -1;
		lflag = 0;
		altflag = 0;
	reswitch:
		switch (ch = *(unsigned char *) fmt++) {
  80080f:	8b 7d e4             	mov    -0x1c(%ebp),%edi
			break;

		// escaped '%' character
		case '%':
			putch(ch, putdat);
			break;
  800812:	e9 e1 fc ff ff       	jmp    8004f8 <vprintfmt+0x26>

		// unrecognized escape sequence - just print it literally
		default:
			putch('%', putdat);
  800817:	83 ec 08             	sub    $0x8,%esp
  80081a:	53                   	push   %ebx
  80081b:	6a 25                	push   $0x25
  80081d:	ff d6                	call   *%esi
			for (fmt--; fmt[-1] != '%'; fmt--)
  80081f:	83 c4 10             	add    $0x10,%esp
  800822:	eb 03                	jmp    800827 <vprintfmt+0x355>
  800824:	83 ef 01             	sub    $0x1,%edi
  800827:	80 7f ff 25          	cmpb   $0x25,-0x1(%edi)
  80082b:	75 f7                	jne    800824 <vprintfmt+0x352>
  80082d:	e9 c6 fc ff ff       	jmp    8004f8 <vprintfmt+0x26>
				/* do nothing */;
			break;
		}
	}
}
  800832:	8d 65 f4             	lea    -0xc(%ebp),%esp
  800835:	5b                   	pop    %ebx
  800836:	5e                   	pop    %esi
  800837:	5f                   	pop    %edi
  800838:	5d                   	pop    %ebp
  800839:	c3                   	ret    

0080083a <vsnprintf>:
		*b->buf++ = ch;
}

int
vsnprintf(char *buf, int n, const char *fmt, va_list ap)
{
  80083a:	55                   	push   %ebp
  80083b:	89 e5                	mov    %esp,%ebp
  80083d:	83 ec 18             	sub    $0x18,%esp
  800840:	8b 45 08             	mov    0x8(%ebp),%eax
  800843:	8b 55 0c             	mov    0xc(%ebp),%edx
	struct sprintbuf b = {buf, buf+n-1, 0};
  800846:	89 45 ec             	mov    %eax,-0x14(%ebp)
  800849:	8d 4c 10 ff          	lea    -0x1(%eax,%edx,1),%ecx
  80084d:	89 4d f0             	mov    %ecx,-0x10(%ebp)
  800850:	c7 45 f4 00 00 00 00 	movl   $0x0,-0xc(%ebp)

	if (buf == NULL || n < 1)
  800857:	85 c0                	test   %eax,%eax
  800859:	74 26                	je     800881 <vsnprintf+0x47>
  80085b:	85 d2                	test   %edx,%edx
  80085d:	7e 22                	jle    800881 <vsnprintf+0x47>
		return -E_INVAL;

	// print the string to the buffer
	vprintfmt((void*)sprintputch, &b, fmt, ap);
  80085f:	ff 75 14             	pushl  0x14(%ebp)
  800862:	ff 75 10             	pushl  0x10(%ebp)
  800865:	8d 45 ec             	lea    -0x14(%ebp),%eax
  800868:	50                   	push   %eax
  800869:	68 98 04 80 00       	push   $0x800498
  80086e:	e8 5f fc ff ff       	call   8004d2 <vprintfmt>

	// null terminate the buffer
	*b.buf = '\0';
  800873:	8b 45 ec             	mov    -0x14(%ebp),%eax
  800876:	c6 00 00             	movb   $0x0,(%eax)

	return b.cnt;
  800879:	8b 45 f4             	mov    -0xc(%ebp),%eax
  80087c:	83 c4 10             	add    $0x10,%esp
  80087f:	eb 05                	jmp    800886 <vsnprintf+0x4c>
vsnprintf(char *buf, int n, const char *fmt, va_list ap)
{
	struct sprintbuf b = {buf, buf+n-1, 0};

	if (buf == NULL || n < 1)
		return -E_INVAL;
  800881:	b8 fd ff ff ff       	mov    $0xfffffffd,%eax

	// null terminate the buffer
	*b.buf = '\0';

	return b.cnt;
}
  800886:	c9                   	leave  
  800887:	c3                   	ret    

00800888 <snprintf>:

int
snprintf(char *buf, int n, const char *fmt, ...)
{
  800888:	55                   	push   %ebp
  800889:	89 e5                	mov    %esp,%ebp
  80088b:	83 ec 08             	sub    $0x8,%esp
	va_list ap;
	int rc;

	va_start(ap, fmt);
  80088e:	8d 45 14             	lea    0x14(%ebp),%eax
	rc = vsnprintf(buf, n, fmt, ap);
  800891:	50                   	push   %eax
  800892:	ff 75 10             	pushl  0x10(%ebp)
  800895:	ff 75 0c             	pushl  0xc(%ebp)
  800898:	ff 75 08             	pushl  0x8(%ebp)
  80089b:	e8 9a ff ff ff       	call   80083a <vsnprintf>
	va_end(ap);

	return rc;
}
  8008a0:	c9                   	leave  
  8008a1:	c3                   	ret    

008008a2 <strlen>:
// Primespipe runs 3x faster this way.
#define ASM 1

int
strlen(const char *s)
{
  8008a2:	55                   	push   %ebp
  8008a3:	89 e5                	mov    %esp,%ebp
  8008a5:	8b 55 08             	mov    0x8(%ebp),%edx
	int n;

	for (n = 0; *s != '\0'; s++)
  8008a8:	b8 00 00 00 00       	mov    $0x0,%eax
  8008ad:	eb 03                	jmp    8008b2 <strlen+0x10>
		n++;
  8008af:	83 c0 01             	add    $0x1,%eax
int
strlen(const char *s)
{
	int n;

	for (n = 0; *s != '\0'; s++)
  8008b2:	80 3c 02 00          	cmpb   $0x0,(%edx,%eax,1)
  8008b6:	75 f7                	jne    8008af <strlen+0xd>
		n++;
	return n;
}
  8008b8:	5d                   	pop    %ebp
  8008b9:	c3                   	ret    

008008ba <strnlen>:

int
strnlen(const char *s, size_t size)
{
  8008ba:	55                   	push   %ebp
  8008bb:	89 e5                	mov    %esp,%ebp
  8008bd:	8b 4d 08             	mov    0x8(%ebp),%ecx
  8008c0:	8b 45 0c             	mov    0xc(%ebp),%eax
	int n;

	for (n = 0; size > 0 && *s != '\0'; s++, size--)
  8008c3:	ba 00 00 00 00       	mov    $0x0,%edx
  8008c8:	eb 03                	jmp    8008cd <strnlen+0x13>
		n++;
  8008ca:	83 c2 01             	add    $0x1,%edx
int
strnlen(const char *s, size_t size)
{
	int n;

	for (n = 0; size > 0 && *s != '\0'; s++, size--)
  8008cd:	39 c2                	cmp    %eax,%edx
  8008cf:	74 08                	je     8008d9 <strnlen+0x1f>
  8008d1:	80 3c 11 00          	cmpb   $0x0,(%ecx,%edx,1)
  8008d5:	75 f3                	jne    8008ca <strnlen+0x10>
  8008d7:	89 d0                	mov    %edx,%eax
		n++;
	return n;
}
  8008d9:	5d                   	pop    %ebp
  8008da:	c3                   	ret    

008008db <strcpy>:

char *
strcpy(char *dst, const char *src)
{
  8008db:	55                   	push   %ebp
  8008dc:	89 e5                	mov    %esp,%ebp
  8008de:	53                   	push   %ebx
  8008df:	8b 45 08             	mov    0x8(%ebp),%eax
  8008e2:	8b 4d 0c             	mov    0xc(%ebp),%ecx
	char *ret;

	ret = dst;
	while ((*dst++ = *src++) != '\0')
  8008e5:	89 c2                	mov    %eax,%edx
  8008e7:	83 c2 01             	add    $0x1,%edx
  8008ea:	83 c1 01             	add    $0x1,%ecx
  8008ed:	0f b6 59 ff          	movzbl -0x1(%ecx),%ebx
  8008f1:	88 5a ff             	mov    %bl,-0x1(%edx)
  8008f4:	84 db                	test   %bl,%bl
  8008f6:	75 ef                	jne    8008e7 <strcpy+0xc>
		/* do nothing */;
	return ret;
}
  8008f8:	5b                   	pop    %ebx
  8008f9:	5d                   	pop    %ebp
  8008fa:	c3                   	ret    

008008fb <strcat>:

char *
strcat(char *dst, const char *src)
{
  8008fb:	55                   	push   %ebp
  8008fc:	89 e5                	mov    %esp,%ebp
  8008fe:	53                   	push   %ebx
  8008ff:	8b 5d 08             	mov    0x8(%ebp),%ebx
	int len = strlen(dst);
  800902:	53                   	push   %ebx
  800903:	e8 9a ff ff ff       	call   8008a2 <strlen>
  800908:	83 c4 04             	add    $0x4,%esp
	strcpy(dst + len, src);
  80090b:	ff 75 0c             	pushl  0xc(%ebp)
  80090e:	01 d8                	add    %ebx,%eax
  800910:	50                   	push   %eax
  800911:	e8 c5 ff ff ff       	call   8008db <strcpy>
	return dst;
}
  800916:	89 d8                	mov    %ebx,%eax
  800918:	8b 5d fc             	mov    -0x4(%ebp),%ebx
  80091b:	c9                   	leave  
  80091c:	c3                   	ret    

0080091d <strncpy>:

char *
strncpy(char *dst, const char *src, size_t size) {
  80091d:	55                   	push   %ebp
  80091e:	89 e5                	mov    %esp,%ebp
  800920:	56                   	push   %esi
  800921:	53                   	push   %ebx
  800922:	8b 75 08             	mov    0x8(%ebp),%esi
  800925:	8b 4d 0c             	mov    0xc(%ebp),%ecx
  800928:	89 f3                	mov    %esi,%ebx
  80092a:	03 5d 10             	add    0x10(%ebp),%ebx
	size_t i;
	char *ret;

	ret = dst;
	for (i = 0; i < size; i++) {
  80092d:	89 f2                	mov    %esi,%edx
  80092f:	eb 0f                	jmp    800940 <strncpy+0x23>
		*dst++ = *src;
  800931:	83 c2 01             	add    $0x1,%edx
  800934:	0f b6 01             	movzbl (%ecx),%eax
  800937:	88 42 ff             	mov    %al,-0x1(%edx)
		// If strlen(src) < size, null-pad 'dst' out to 'size' chars
		if (*src != '\0')
			src++;
  80093a:	80 39 01             	cmpb   $0x1,(%ecx)
  80093d:	83 d9 ff             	sbb    $0xffffffff,%ecx
strncpy(char *dst, const char *src, size_t size) {
	size_t i;
	char *ret;

	ret = dst;
	for (i = 0; i < size; i++) {
  800940:	39 da                	cmp    %ebx,%edx
  800942:	75 ed                	jne    800931 <strncpy+0x14>
		// If strlen(src) < size, null-pad 'dst' out to 'size' chars
		if (*src != '\0')
			src++;
	}
	return ret;
}
  800944:	89 f0                	mov    %esi,%eax
  800946:	5b                   	pop    %ebx
  800947:	5e                   	pop    %esi
  800948:	5d                   	pop    %ebp
  800949:	c3                   	ret    

0080094a <strlcpy>:

size_t
strlcpy(char *dst, const char *src, size_t size)
{
  80094a:	55                   	push   %ebp
  80094b:	89 e5                	mov    %esp,%ebp
  80094d:	56                   	push   %esi
  80094e:	53                   	push   %ebx
  80094f:	8b 75 08             	mov    0x8(%ebp),%esi
  800952:	8b 4d 0c             	mov    0xc(%ebp),%ecx
  800955:	8b 55 10             	mov    0x10(%ebp),%edx
  800958:	89 f0                	mov    %esi,%eax
	char *dst_in;

	dst_in = dst;
	if (size > 0) {
  80095a:	85 d2                	test   %edx,%edx
  80095c:	74 21                	je     80097f <strlcpy+0x35>
  80095e:	8d 44 16 ff          	lea    -0x1(%esi,%edx,1),%eax
  800962:	89 f2                	mov    %esi,%edx
  800964:	eb 09                	jmp    80096f <strlcpy+0x25>
		while (--size > 0 && *src != '\0')
			*dst++ = *src++;
  800966:	83 c2 01             	add    $0x1,%edx
  800969:	83 c1 01             	add    $0x1,%ecx
  80096c:	88 5a ff             	mov    %bl,-0x1(%edx)
{
	char *dst_in;

	dst_in = dst;
	if (size > 0) {
		while (--size > 0 && *src != '\0')
  80096f:	39 c2                	cmp    %eax,%edx
  800971:	74 09                	je     80097c <strlcpy+0x32>
  800973:	0f b6 19             	movzbl (%ecx),%ebx
  800976:	84 db                	test   %bl,%bl
  800978:	75 ec                	jne    800966 <strlcpy+0x1c>
  80097a:	89 d0                	mov    %edx,%eax
			*dst++ = *src++;
		*dst = '\0';
  80097c:	c6 00 00             	movb   $0x0,(%eax)
	}
	return dst - dst_in;
  80097f:	29 f0                	sub    %esi,%eax
}
  800981:	5b                   	pop    %ebx
  800982:	5e                   	pop    %esi
  800983:	5d                   	pop    %ebp
  800984:	c3                   	ret    

00800985 <strcmp>:

int
strcmp(const char *p, const char *q)
{
  800985:	55                   	push   %ebp
  800986:	89 e5                	mov    %esp,%ebp
  800988:	8b 4d 08             	mov    0x8(%ebp),%ecx
  80098b:	8b 55 0c             	mov    0xc(%ebp),%edx
	while (*p && *p == *q)
  80098e:	eb 06                	jmp    800996 <strcmp+0x11>
		p++, q++;
  800990:	83 c1 01             	add    $0x1,%ecx
  800993:	83 c2 01             	add    $0x1,%edx
}

int
strcmp(const char *p, const char *q)
{
	while (*p && *p == *q)
  800996:	0f b6 01             	movzbl (%ecx),%eax
  800999:	84 c0                	test   %al,%al
  80099b:	74 04                	je     8009a1 <strcmp+0x1c>
  80099d:	3a 02                	cmp    (%edx),%al
  80099f:	74 ef                	je     800990 <strcmp+0xb>
		p++, q++;
	return (int) ((unsigned char) *p - (unsigned char) *q);
  8009a1:	0f b6 c0             	movzbl %al,%eax
  8009a4:	0f b6 12             	movzbl (%edx),%edx
  8009a7:	29 d0                	sub    %edx,%eax
}
  8009a9:	5d                   	pop    %ebp
  8009aa:	c3                   	ret    

008009ab <strncmp>:

int
strncmp(const char *p, const char *q, size_t n)
{
  8009ab:	55                   	push   %ebp
  8009ac:	89 e5                	mov    %esp,%ebp
  8009ae:	53                   	push   %ebx
  8009af:	8b 45 08             	mov    0x8(%ebp),%eax
  8009b2:	8b 55 0c             	mov    0xc(%ebp),%edx
  8009b5:	89 c3                	mov    %eax,%ebx
  8009b7:	03 5d 10             	add    0x10(%ebp),%ebx
	while (n > 0 && *p && *p == *q)
  8009ba:	eb 06                	jmp    8009c2 <strncmp+0x17>
		n--, p++, q++;
  8009bc:	83 c0 01             	add    $0x1,%eax
  8009bf:	83 c2 01             	add    $0x1,%edx
}

int
strncmp(const char *p, const char *q, size_t n)
{
	while (n > 0 && *p && *p == *q)
  8009c2:	39 d8                	cmp    %ebx,%eax
  8009c4:	74 15                	je     8009db <strncmp+0x30>
  8009c6:	0f b6 08             	movzbl (%eax),%ecx
  8009c9:	84 c9                	test   %cl,%cl
  8009cb:	74 04                	je     8009d1 <strncmp+0x26>
  8009cd:	3a 0a                	cmp    (%edx),%cl
  8009cf:	74 eb                	je     8009bc <strncmp+0x11>
		n--, p++, q++;
	if (n == 0)
		return 0;
	else
		return (int) ((unsigned char) *p - (unsigned char) *q);
  8009d1:	0f b6 00             	movzbl (%eax),%eax
  8009d4:	0f b6 12             	movzbl (%edx),%edx
  8009d7:	29 d0                	sub    %edx,%eax
  8009d9:	eb 05                	jmp    8009e0 <strncmp+0x35>
strncmp(const char *p, const char *q, size_t n)
{
	while (n > 0 && *p && *p == *q)
		n--, p++, q++;
	if (n == 0)
		return 0;
  8009db:	b8 00 00 00 00       	mov    $0x0,%eax
	else
		return (int) ((unsigned char) *p - (unsigned char) *q);
}
  8009e0:	5b                   	pop    %ebx
  8009e1:	5d                   	pop    %ebp
  8009e2:	c3                   	ret    

008009e3 <strchr>:

// Return a pointer to the first occurrence of 'c' in 's',
// or a null pointer if the string has no 'c'.
char *
strchr(const char *s, char c)
{
  8009e3:	55                   	push   %ebp
  8009e4:	89 e5                	mov    %esp,%ebp
  8009e6:	8b 45 08             	mov    0x8(%ebp),%eax
  8009e9:	0f b6 4d 0c          	movzbl 0xc(%ebp),%ecx
	for (; *s; s++)
  8009ed:	eb 07                	jmp    8009f6 <strchr+0x13>
		if (*s == c)
  8009ef:	38 ca                	cmp    %cl,%dl
  8009f1:	74 0f                	je     800a02 <strchr+0x1f>
// Return a pointer to the first occurrence of 'c' in 's',
// or a null pointer if the string has no 'c'.
char *
strchr(const char *s, char c)
{
	for (; *s; s++)
  8009f3:	83 c0 01             	add    $0x1,%eax
  8009f6:	0f b6 10             	movzbl (%eax),%edx
  8009f9:	84 d2                	test   %dl,%dl
  8009fb:	75 f2                	jne    8009ef <strchr+0xc>
		if (*s == c)
			return (char *) s;
	return 0;
  8009fd:	b8 00 00 00 00       	mov    $0x0,%eax
}
  800a02:	5d                   	pop    %ebp
  800a03:	c3                   	ret    

00800a04 <strfind>:

// Return a pointer to the first occurrence of 'c' in 's',
// or a pointer to the string-ending null character if the string has no 'c'.
char *
strfind(const char *s, char c)
{
  800a04:	55                   	push   %ebp
  800a05:	89 e5                	mov    %esp,%ebp
  800a07:	8b 45 08             	mov    0x8(%ebp),%eax
  800a0a:	0f b6 4d 0c          	movzbl 0xc(%ebp),%ecx
	for (; *s; s++)
  800a0e:	eb 03                	jmp    800a13 <strfind+0xf>
  800a10:	83 c0 01             	add    $0x1,%eax
  800a13:	0f b6 10             	movzbl (%eax),%edx
		if (*s == c)
  800a16:	38 ca                	cmp    %cl,%dl
  800a18:	74 04                	je     800a1e <strfind+0x1a>
  800a1a:	84 d2                	test   %dl,%dl
  800a1c:	75 f2                	jne    800a10 <strfind+0xc>
			break;
	return (char *) s;
}
  800a1e:	5d                   	pop    %ebp
  800a1f:	c3                   	ret    

00800a20 <memset>:

#if ASM
void *
memset(void *v, int c, size_t n)
{
  800a20:	55                   	push   %ebp
  800a21:	89 e5                	mov    %esp,%ebp
  800a23:	57                   	push   %edi
  800a24:	56                   	push   %esi
  800a25:	53                   	push   %ebx
  800a26:	8b 55 08             	mov    0x8(%ebp),%edx
  800a29:	8b 4d 10             	mov    0x10(%ebp),%ecx
	char *p = v;

	if (n == 0)
  800a2c:	85 c9                	test   %ecx,%ecx
  800a2e:	74 37                	je     800a67 <memset+0x47>
		return v;
	if ((int)v%4 == 0 && n%4 == 0) {
  800a30:	f6 c2 03             	test   $0x3,%dl
  800a33:	75 2a                	jne    800a5f <memset+0x3f>
  800a35:	f6 c1 03             	test   $0x3,%cl
  800a38:	75 25                	jne    800a5f <memset+0x3f>
		c &= 0xFF;
  800a3a:	0f b6 5d 0c          	movzbl 0xc(%ebp),%ebx
		c = (c<<24)|(c<<16)|(c<<8)|c;
  800a3e:	89 df                	mov    %ebx,%edi
  800a40:	c1 e7 08             	shl    $0x8,%edi
  800a43:	89 de                	mov    %ebx,%esi
  800a45:	c1 e6 18             	shl    $0x18,%esi
  800a48:	89 d8                	mov    %ebx,%eax
  800a4a:	c1 e0 10             	shl    $0x10,%eax
  800a4d:	09 f0                	or     %esi,%eax
  800a4f:	09 c3                	or     %eax,%ebx
		asm volatile("cld; rep stosl\n"
			: "=D" (p), "=c" (n)
			: "D" (p), "a" (c), "c" (n/4)
  800a51:	c1 e9 02             	shr    $0x2,%ecx
	if (n == 0)
		return v;
	if ((int)v%4 == 0 && n%4 == 0) {
		c &= 0xFF;
		c = (c<<24)|(c<<16)|(c<<8)|c;
		asm volatile("cld; rep stosl\n"
  800a54:	89 f8                	mov    %edi,%eax
  800a56:	09 d8                	or     %ebx,%eax
  800a58:	89 d7                	mov    %edx,%edi
  800a5a:	fc                   	cld    
  800a5b:	f3 ab                	rep stos %eax,%es:(%edi)
  800a5d:	eb 08                	jmp    800a67 <memset+0x47>
			: "=D" (p), "=c" (n)
			: "D" (p), "a" (c), "c" (n/4)
			: "cc", "memory");
	} else
		asm volatile("cld; rep stosb\n"
  800a5f:	89 d7                	mov    %edx,%edi
  800a61:	8b 45 0c             	mov    0xc(%ebp),%eax
  800a64:	fc                   	cld    
  800a65:	f3 aa                	rep stos %al,%es:(%edi)
			: "=D" (p), "=c" (n)
			: "0" (p), "a" (c), "1" (n)
			: "cc", "memory");
	return v;
}
  800a67:	89 d0                	mov    %edx,%eax
  800a69:	5b                   	pop    %ebx
  800a6a:	5e                   	pop    %esi
  800a6b:	5f                   	pop    %edi
  800a6c:	5d                   	pop    %ebp
  800a6d:	c3                   	ret    

00800a6e <memmove>:

void *
memmove(void *dst, const void *src, size_t n)
{
  800a6e:	55                   	push   %ebp
  800a6f:	89 e5                	mov    %esp,%ebp
  800a71:	57                   	push   %edi
  800a72:	56                   	push   %esi
  800a73:	8b 45 08             	mov    0x8(%ebp),%eax
  800a76:	8b 75 0c             	mov    0xc(%ebp),%esi
  800a79:	8b 4d 10             	mov    0x10(%ebp),%ecx
	const char *s;
	char *d;

	s = src;
	d = dst;
	if (s < d && s + n > d) {
  800a7c:	39 c6                	cmp    %eax,%esi
  800a7e:	73 35                	jae    800ab5 <memmove+0x47>
  800a80:	8d 14 0e             	lea    (%esi,%ecx,1),%edx
  800a83:	39 d0                	cmp    %edx,%eax
  800a85:	73 2e                	jae    800ab5 <memmove+0x47>
		s += n;
		d += n;
  800a87:	8d 3c 08             	lea    (%eax,%ecx,1),%edi
		if ((int)s%4 == 0 && (int)d%4 == 0 && n%4 == 0)
  800a8a:	89 d6                	mov    %edx,%esi
  800a8c:	09 fe                	or     %edi,%esi
  800a8e:	f7 c6 03 00 00 00    	test   $0x3,%esi
  800a94:	75 13                	jne    800aa9 <memmove+0x3b>
  800a96:	f6 c1 03             	test   $0x3,%cl
  800a99:	75 0e                	jne    800aa9 <memmove+0x3b>
			asm volatile("std; rep movsl\n"
  800a9b:	83 ef 04             	sub    $0x4,%edi
  800a9e:	8d 72 fc             	lea    -0x4(%edx),%esi
  800aa1:	c1 e9 02             	shr    $0x2,%ecx
  800aa4:	fd                   	std    
  800aa5:	f3 a5                	rep movsl %ds:(%esi),%es:(%edi)
  800aa7:	eb 09                	jmp    800ab2 <memmove+0x44>
				:: "D" (d-4), "S" (s-4), "c" (n/4) : "cc", "memory");
		else
			asm volatile("std; rep movsb\n"
  800aa9:	83 ef 01             	sub    $0x1,%edi
  800aac:	8d 72 ff             	lea    -0x1(%edx),%esi
  800aaf:	fd                   	std    
  800ab0:	f3 a4                	rep movsb %ds:(%esi),%es:(%edi)
				:: "D" (d-1), "S" (s-1), "c" (n) : "cc", "memory");
		// Some versions of GCC rely on DF being clear
		asm volatile("cld" ::: "cc");
  800ab2:	fc                   	cld    
  800ab3:	eb 1d                	jmp    800ad2 <memmove+0x64>
	} else {
		if ((int)s%4 == 0 && (int)d%4 == 0 && n%4 == 0)
  800ab5:	89 f2                	mov    %esi,%edx
  800ab7:	09 c2                	or     %eax,%edx
  800ab9:	f6 c2 03             	test   $0x3,%dl
  800abc:	75 0f                	jne    800acd <memmove+0x5f>
  800abe:	f6 c1 03             	test   $0x3,%cl
  800ac1:	75 0a                	jne    800acd <memmove+0x5f>
			asm volatile("cld; rep movsl\n"
  800ac3:	c1 e9 02             	shr    $0x2,%ecx
  800ac6:	89 c7                	mov    %eax,%edi
  800ac8:	fc                   	cld    
  800ac9:	f3 a5                	rep movsl %ds:(%esi),%es:(%edi)
  800acb:	eb 05                	jmp    800ad2 <memmove+0x64>
				:: "D" (d), "S" (s), "c" (n/4) : "cc", "memory");
		else
			asm volatile("cld; rep movsb\n"
  800acd:	89 c7                	mov    %eax,%edi
  800acf:	fc                   	cld    
  800ad0:	f3 a4                	rep movsb %ds:(%esi),%es:(%edi)
				:: "D" (d), "S" (s), "c" (n) : "cc", "memory");
	}
	return dst;
}
  800ad2:	5e                   	pop    %esi
  800ad3:	5f                   	pop    %edi
  800ad4:	5d                   	pop    %ebp
  800ad5:	c3                   	ret    

00800ad6 <memcpy>:
}
#endif

void *
memcpy(void *dst, const void *src, size_t n)
{
  800ad6:	55                   	push   %ebp
  800ad7:	89 e5                	mov    %esp,%ebp
	return memmove(dst, src, n);
  800ad9:	ff 75 10             	pushl  0x10(%ebp)
  800adc:	ff 75 0c             	pushl  0xc(%ebp)
  800adf:	ff 75 08             	pushl  0x8(%ebp)
  800ae2:	e8 87 ff ff ff       	call   800a6e <memmove>
}
  800ae7:	c9                   	leave  
  800ae8:	c3                   	ret    

00800ae9 <memcmp>:

int
memcmp(const void *v1, const void *v2, size_t n)
{
  800ae9:	55                   	push   %ebp
  800aea:	89 e5                	mov    %esp,%ebp
  800aec:	56                   	push   %esi
  800aed:	53                   	push   %ebx
  800aee:	8b 45 08             	mov    0x8(%ebp),%eax
  800af1:	8b 55 0c             	mov    0xc(%ebp),%edx
  800af4:	89 c6                	mov    %eax,%esi
  800af6:	03 75 10             	add    0x10(%ebp),%esi
	const uint8_t *s1 = (const uint8_t *) v1;
	const uint8_t *s2 = (const uint8_t *) v2;

	while (n-- > 0) {
  800af9:	eb 1a                	jmp    800b15 <memcmp+0x2c>
		if (*s1 != *s2)
  800afb:	0f b6 08             	movzbl (%eax),%ecx
  800afe:	0f b6 1a             	movzbl (%edx),%ebx
  800b01:	38 d9                	cmp    %bl,%cl
  800b03:	74 0a                	je     800b0f <memcmp+0x26>
			return (int) *s1 - (int) *s2;
  800b05:	0f b6 c1             	movzbl %cl,%eax
  800b08:	0f b6 db             	movzbl %bl,%ebx
  800b0b:	29 d8                	sub    %ebx,%eax
  800b0d:	eb 0f                	jmp    800b1e <memcmp+0x35>
		s1++, s2++;
  800b0f:	83 c0 01             	add    $0x1,%eax
  800b12:	83 c2 01             	add    $0x1,%edx
memcmp(const void *v1, const void *v2, size_t n)
{
	const uint8_t *s1 = (const uint8_t *) v1;
	const uint8_t *s2 = (const uint8_t *) v2;

	while (n-- > 0) {
  800b15:	39 f0                	cmp    %esi,%eax
  800b17:	75 e2                	jne    800afb <memcmp+0x12>
		if (*s1 != *s2)
			return (int) *s1 - (int) *s2;
		s1++, s2++;
	}

	return 0;
  800b19:	b8 00 00 00 00       	mov    $0x0,%eax
}
  800b1e:	5b                   	pop    %ebx
  800b1f:	5e                   	pop    %esi
  800b20:	5d                   	pop    %ebp
  800b21:	c3                   	ret    

00800b22 <memfind>:

void *
memfind(const void *s, int c, size_t n)
{
  800b22:	55                   	push   %ebp
  800b23:	89 e5                	mov    %esp,%ebp
  800b25:	8b 45 08             	mov    0x8(%ebp),%eax
  800b28:	8b 4d 0c             	mov    0xc(%ebp),%ecx
	const void *ends = (const char *) s + n;
  800b2b:	89 c2                	mov    %eax,%edx
  800b2d:	03 55 10             	add    0x10(%ebp),%edx
	for (; s < ends; s++)
  800b30:	eb 07                	jmp    800b39 <memfind+0x17>
		if (*(const unsigned char *) s == (unsigned char) c)
  800b32:	38 08                	cmp    %cl,(%eax)
  800b34:	74 07                	je     800b3d <memfind+0x1b>

void *
memfind(const void *s, int c, size_t n)
{
	const void *ends = (const char *) s + n;
	for (; s < ends; s++)
  800b36:	83 c0 01             	add    $0x1,%eax
  800b39:	39 d0                	cmp    %edx,%eax
  800b3b:	72 f5                	jb     800b32 <memfind+0x10>
		if (*(const unsigned char *) s == (unsigned char) c)
			break;
	return (void *) s;
}
  800b3d:	5d                   	pop    %ebp
  800b3e:	c3                   	ret    

00800b3f <strtol>:

long
strtol(const char *s, char **endptr, int base)
{
  800b3f:	55                   	push   %ebp
  800b40:	89 e5                	mov    %esp,%ebp
  800b42:	57                   	push   %edi
  800b43:	56                   	push   %esi
  800b44:	53                   	push   %ebx
  800b45:	8b 4d 08             	mov    0x8(%ebp),%ecx
  800b48:	8b 5d 10             	mov    0x10(%ebp),%ebx
	int neg = 0;
	long val = 0;

	// gobble initial whitespace
	while (*s == ' ' || *s == '\t')
  800b4b:	eb 03                	jmp    800b50 <strtol+0x11>
		s++;
  800b4d:	83 c1 01             	add    $0x1,%ecx
{
	int neg = 0;
	long val = 0;

	// gobble initial whitespace
	while (*s == ' ' || *s == '\t')
  800b50:	0f b6 01             	movzbl (%ecx),%eax
  800b53:	3c 20                	cmp    $0x20,%al
  800b55:	74 f6                	je     800b4d <strtol+0xe>
  800b57:	3c 09                	cmp    $0x9,%al
  800b59:	74 f2                	je     800b4d <strtol+0xe>
		s++;

	// plus/minus sign
	if (*s == '+')
  800b5b:	3c 2b                	cmp    $0x2b,%al
  800b5d:	75 0a                	jne    800b69 <strtol+0x2a>
		s++;
  800b5f:	83 c1 01             	add    $0x1,%ecx
}

long
strtol(const char *s, char **endptr, int base)
{
	int neg = 0;
  800b62:	bf 00 00 00 00       	mov    $0x0,%edi
  800b67:	eb 11                	jmp    800b7a <strtol+0x3b>
  800b69:	bf 00 00 00 00       	mov    $0x0,%edi
		s++;

	// plus/minus sign
	if (*s == '+')
		s++;
	else if (*s == '-')
  800b6e:	3c 2d                	cmp    $0x2d,%al
  800b70:	75 08                	jne    800b7a <strtol+0x3b>
		s++, neg = 1;
  800b72:	83 c1 01             	add    $0x1,%ecx
  800b75:	bf 01 00 00 00       	mov    $0x1,%edi

	// hex or octal base prefix
	if ((base == 0 || base == 16) && (s[0] == '0' && s[1] == 'x'))
  800b7a:	f7 c3 ef ff ff ff    	test   $0xffffffef,%ebx
  800b80:	75 15                	jne    800b97 <strtol+0x58>
  800b82:	80 39 30             	cmpb   $0x30,(%ecx)
  800b85:	75 10                	jne    800b97 <strtol+0x58>
  800b87:	80 79 01 78          	cmpb   $0x78,0x1(%ecx)
  800b8b:	75 7c                	jne    800c09 <strtol+0xca>
		s += 2, base = 16;
  800b8d:	83 c1 02             	add    $0x2,%ecx
  800b90:	bb 10 00 00 00       	mov    $0x10,%ebx
  800b95:	eb 16                	jmp    800bad <strtol+0x6e>
	else if (base == 0 && s[0] == '0')
  800b97:	85 db                	test   %ebx,%ebx
  800b99:	75 12                	jne    800bad <strtol+0x6e>
		s++, base = 8;
	else if (base == 0)
		base = 10;
  800b9b:	bb 0a 00 00 00       	mov    $0xa,%ebx
		s++, neg = 1;

	// hex or octal base prefix
	if ((base == 0 || base == 16) && (s[0] == '0' && s[1] == 'x'))
		s += 2, base = 16;
	else if (base == 0 && s[0] == '0')
  800ba0:	80 39 30             	cmpb   $0x30,(%ecx)
  800ba3:	75 08                	jne    800bad <strtol+0x6e>
		s++, base = 8;
  800ba5:	83 c1 01             	add    $0x1,%ecx
  800ba8:	bb 08 00 00 00       	mov    $0x8,%ebx
	else if (base == 0)
		base = 10;
  800bad:	b8 00 00 00 00       	mov    $0x0,%eax
  800bb2:	89 5d 10             	mov    %ebx,0x10(%ebp)

	// digits
	while (1) {
		int dig;

		if (*s >= '0' && *s <= '9')
  800bb5:	0f b6 11             	movzbl (%ecx),%edx
  800bb8:	8d 72 d0             	lea    -0x30(%edx),%esi
  800bbb:	89 f3                	mov    %esi,%ebx
  800bbd:	80 fb 09             	cmp    $0x9,%bl
  800bc0:	77 08                	ja     800bca <strtol+0x8b>
			dig = *s - '0';
  800bc2:	0f be d2             	movsbl %dl,%edx
  800bc5:	83 ea 30             	sub    $0x30,%edx
  800bc8:	eb 22                	jmp    800bec <strtol+0xad>
		else if (*s >= 'a' && *s <= 'z')
  800bca:	8d 72 9f             	lea    -0x61(%edx),%esi
  800bcd:	89 f3                	mov    %esi,%ebx
  800bcf:	80 fb 19             	cmp    $0x19,%bl
  800bd2:	77 08                	ja     800bdc <strtol+0x9d>
			dig = *s - 'a' + 10;
  800bd4:	0f be d2             	movsbl %dl,%edx
  800bd7:	83 ea 57             	sub    $0x57,%edx
  800bda:	eb 10                	jmp    800bec <strtol+0xad>
		else if (*s >= 'A' && *s <= 'Z')
  800bdc:	8d 72 bf             	lea    -0x41(%edx),%esi
  800bdf:	89 f3                	mov    %esi,%ebx
  800be1:	80 fb 19             	cmp    $0x19,%bl
  800be4:	77 16                	ja     800bfc <strtol+0xbd>
			dig = *s - 'A' + 10;
  800be6:	0f be d2             	movsbl %dl,%edx
  800be9:	83 ea 37             	sub    $0x37,%edx
		else
			break;
		if (dig >= base)
  800bec:	3b 55 10             	cmp    0x10(%ebp),%edx
  800bef:	7d 0b                	jge    800bfc <strtol+0xbd>
			break;
		s++, val = (val * base) + dig;
  800bf1:	83 c1 01             	add    $0x1,%ecx
  800bf4:	0f af 45 10          	imul   0x10(%ebp),%eax
  800bf8:	01 d0                	add    %edx,%eax
		// we don't properly detect overflow!
	}
  800bfa:	eb b9                	jmp    800bb5 <strtol+0x76>

	if (endptr)
  800bfc:	83 7d 0c 00          	cmpl   $0x0,0xc(%ebp)
  800c00:	74 0d                	je     800c0f <strtol+0xd0>
		*endptr = (char *) s;
  800c02:	8b 75 0c             	mov    0xc(%ebp),%esi
  800c05:	89 0e                	mov    %ecx,(%esi)
  800c07:	eb 06                	jmp    800c0f <strtol+0xd0>
		s++, neg = 1;

	// hex or octal base prefix
	if ((base == 0 || base == 16) && (s[0] == '0' && s[1] == 'x'))
		s += 2, base = 16;
	else if (base == 0 && s[0] == '0')
  800c09:	85 db                	test   %ebx,%ebx
  800c0b:	74 98                	je     800ba5 <strtol+0x66>
  800c0d:	eb 9e                	jmp    800bad <strtol+0x6e>
		// we don't properly detect overflow!
	}

	if (endptr)
		*endptr = (char *) s;
	return (neg ? -val : val);
  800c0f:	89 c2                	mov    %eax,%edx
  800c11:	f7 da                	neg    %edx
  800c13:	85 ff                	test   %edi,%edi
  800c15:	0f 45 c2             	cmovne %edx,%eax
}
  800c18:	5b                   	pop    %ebx
  800c19:	5e                   	pop    %esi
  800c1a:	5f                   	pop    %edi
  800c1b:	5d                   	pop    %ebp
  800c1c:	c3                   	ret    
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
