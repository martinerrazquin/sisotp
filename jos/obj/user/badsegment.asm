
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
  800041:	56                   	push   %esi
  800042:	53                   	push   %ebx
  800043:	8b 5d 08             	mov    0x8(%ebp),%ebx
  800046:	8b 75 0c             	mov    0xc(%ebp),%esi
	// set thisenv to point at our Env structure in envs[].
	// LAB 3: Your code here.
	envid_t id = sys_getenvid();
  800049:	e8 02 01 00 00       	call   800150 <sys_getenvid>
	if (id >= 0)
  80004e:	85 c0                	test   %eax,%eax
  800050:	78 12                	js     800064 <libmain+0x26>
		thisenv = &envs[ENVX(id)];
  800052:	25 ff 03 00 00       	and    $0x3ff,%eax
  800057:	6b c0 7c             	imul   $0x7c,%eax,%eax
  80005a:	05 00 00 c0 ee       	add    $0xeec00000,%eax
  80005f:	a3 04 20 80 00       	mov    %eax,0x802004

	// save the name of the program so that panic() can use it
	if (argc > 0)
  800064:	85 db                	test   %ebx,%ebx
  800066:	7e 07                	jle    80006f <libmain+0x31>
		binaryname = argv[0];
  800068:	8b 06                	mov    (%esi),%eax
  80006a:	a3 00 20 80 00       	mov    %eax,0x802000

	// call user main routine
	umain(argc, argv);
  80006f:	83 ec 08             	sub    $0x8,%esp
  800072:	56                   	push   %esi
  800073:	53                   	push   %ebx
  800074:	e8 ba ff ff ff       	call   800033 <umain>

	// exit gracefully
	exit();
  800079:	e8 0a 00 00 00       	call   800088 <exit>
}
  80007e:	83 c4 10             	add    $0x10,%esp
  800081:	8d 65 f8             	lea    -0x8(%ebp),%esp
  800084:	5b                   	pop    %ebx
  800085:	5e                   	pop    %esi
  800086:	5d                   	pop    %ebp
  800087:	c3                   	ret    

00800088 <exit>:

#include <inc/lib.h>

void
exit(void)
{
  800088:	55                   	push   %ebp
  800089:	89 e5                	mov    %esp,%ebp
  80008b:	83 ec 14             	sub    $0x14,%esp
	sys_env_destroy(0);
  80008e:	6a 00                	push   $0x0
  800090:	e8 99 00 00 00       	call   80012e <sys_env_destroy>
}
  800095:	83 c4 10             	add    $0x10,%esp
  800098:	c9                   	leave  
  800099:	c3                   	ret    

0080009a <syscall>:
#include <inc/syscall.h>
#include <inc/lib.h>

static inline int32_t
syscall(int num, int check, uint32_t a1, uint32_t a2, uint32_t a3, uint32_t a4, uint32_t a5)
{
  80009a:	55                   	push   %ebp
  80009b:	89 e5                	mov    %esp,%ebp
  80009d:	57                   	push   %edi
  80009e:	56                   	push   %esi
  80009f:	53                   	push   %ebx
  8000a0:	83 ec 1c             	sub    $0x1c,%esp
  8000a3:	89 45 e0             	mov    %eax,-0x20(%ebp)
  8000a6:	89 55 e4             	mov    %edx,-0x1c(%ebp)
  8000a9:	89 ca                	mov    %ecx,%edx
	//
	// The last clause tells the assembler that this can
	// potentially change the condition codes and arbitrary
	// memory locations.

	asm volatile("int %1\n"
  8000ab:	8b 4d 08             	mov    0x8(%ebp),%ecx
  8000ae:	8b 5d 0c             	mov    0xc(%ebp),%ebx
  8000b1:	8b 7d 10             	mov    0x10(%ebp),%edi
  8000b4:	8b 75 14             	mov    0x14(%ebp),%esi
  8000b7:	cd 30                	int    $0x30
		       "b" (a3),
		       "D" (a4),
		       "S" (a5)
		     : "cc", "memory");

	if(check && ret > 0)
  8000b9:	83 7d e4 00          	cmpl   $0x0,-0x1c(%ebp)
  8000bd:	74 1d                	je     8000dc <syscall+0x42>
  8000bf:	85 c0                	test   %eax,%eax
  8000c1:	7e 19                	jle    8000dc <syscall+0x42>
  8000c3:	8b 55 e0             	mov    -0x20(%ebp),%edx
		panic("syscall %d returned %d (> 0)", num, ret);
  8000c6:	83 ec 0c             	sub    $0xc,%esp
  8000c9:	50                   	push   %eax
  8000ca:	52                   	push   %edx
  8000cb:	68 ca 0e 80 00       	push   $0x800eca
  8000d0:	6a 23                	push   $0x23
  8000d2:	68 e7 0e 80 00       	push   $0x800ee7
  8000d7:	e8 b9 01 00 00       	call   800295 <_panic>

	return ret;
}
  8000dc:	8d 65 f4             	lea    -0xc(%ebp),%esp
  8000df:	5b                   	pop    %ebx
  8000e0:	5e                   	pop    %esi
  8000e1:	5f                   	pop    %edi
  8000e2:	5d                   	pop    %ebp
  8000e3:	c3                   	ret    

008000e4 <sys_cputs>:

void
sys_cputs(const char *s, size_t len)
{
  8000e4:	55                   	push   %ebp
  8000e5:	89 e5                	mov    %esp,%ebp
  8000e7:	83 ec 08             	sub    $0x8,%esp
	syscall(SYS_cputs, 0, (uint32_t)s, len, 0, 0, 0);
  8000ea:	6a 00                	push   $0x0
  8000ec:	6a 00                	push   $0x0
  8000ee:	6a 00                	push   $0x0
  8000f0:	ff 75 0c             	pushl  0xc(%ebp)
  8000f3:	8b 4d 08             	mov    0x8(%ebp),%ecx
  8000f6:	ba 00 00 00 00       	mov    $0x0,%edx
  8000fb:	b8 00 00 00 00       	mov    $0x0,%eax
  800100:	e8 95 ff ff ff       	call   80009a <syscall>
}
  800105:	83 c4 10             	add    $0x10,%esp
  800108:	c9                   	leave  
  800109:	c3                   	ret    

0080010a <sys_cgetc>:

int
sys_cgetc(void)
{
  80010a:	55                   	push   %ebp
  80010b:	89 e5                	mov    %esp,%ebp
  80010d:	83 ec 08             	sub    $0x8,%esp
	return syscall(SYS_cgetc, 0, 0, 0, 0, 0, 0);
  800110:	6a 00                	push   $0x0
  800112:	6a 00                	push   $0x0
  800114:	6a 00                	push   $0x0
  800116:	6a 00                	push   $0x0
  800118:	b9 00 00 00 00       	mov    $0x0,%ecx
  80011d:	ba 00 00 00 00       	mov    $0x0,%edx
  800122:	b8 01 00 00 00       	mov    $0x1,%eax
  800127:	e8 6e ff ff ff       	call   80009a <syscall>
}
  80012c:	c9                   	leave  
  80012d:	c3                   	ret    

0080012e <sys_env_destroy>:

int
sys_env_destroy(envid_t envid)
{
  80012e:	55                   	push   %ebp
  80012f:	89 e5                	mov    %esp,%ebp
  800131:	83 ec 08             	sub    $0x8,%esp
	return syscall(SYS_env_destroy, 1, envid, 0, 0, 0, 0);
  800134:	6a 00                	push   $0x0
  800136:	6a 00                	push   $0x0
  800138:	6a 00                	push   $0x0
  80013a:	6a 00                	push   $0x0
  80013c:	8b 4d 08             	mov    0x8(%ebp),%ecx
  80013f:	ba 01 00 00 00       	mov    $0x1,%edx
  800144:	b8 03 00 00 00       	mov    $0x3,%eax
  800149:	e8 4c ff ff ff       	call   80009a <syscall>
}
  80014e:	c9                   	leave  
  80014f:	c3                   	ret    

00800150 <sys_getenvid>:

envid_t
sys_getenvid(void)
{
  800150:	55                   	push   %ebp
  800151:	89 e5                	mov    %esp,%ebp
  800153:	83 ec 08             	sub    $0x8,%esp
	 return syscall(SYS_getenvid, 0, 0, 0, 0, 0, 0);
  800156:	6a 00                	push   $0x0
  800158:	6a 00                	push   $0x0
  80015a:	6a 00                	push   $0x0
  80015c:	6a 00                	push   $0x0
  80015e:	b9 00 00 00 00       	mov    $0x0,%ecx
  800163:	ba 00 00 00 00       	mov    $0x0,%edx
  800168:	b8 02 00 00 00       	mov    $0x2,%eax
  80016d:	e8 28 ff ff ff       	call   80009a <syscall>
}
  800172:	c9                   	leave  
  800173:	c3                   	ret    

00800174 <sys_yield>:

void
sys_yield(void)
{
  800174:	55                   	push   %ebp
  800175:	89 e5                	mov    %esp,%ebp
  800177:	83 ec 08             	sub    $0x8,%esp
	syscall(SYS_yield, 0, 0, 0, 0, 0, 0);
  80017a:	6a 00                	push   $0x0
  80017c:	6a 00                	push   $0x0
  80017e:	6a 00                	push   $0x0
  800180:	6a 00                	push   $0x0
  800182:	b9 00 00 00 00       	mov    $0x0,%ecx
  800187:	ba 00 00 00 00       	mov    $0x0,%edx
  80018c:	b8 0a 00 00 00       	mov    $0xa,%eax
  800191:	e8 04 ff ff ff       	call   80009a <syscall>
}
  800196:	83 c4 10             	add    $0x10,%esp
  800199:	c9                   	leave  
  80019a:	c3                   	ret    

0080019b <sys_page_alloc>:

int
sys_page_alloc(envid_t envid, void *va, int perm)
{
  80019b:	55                   	push   %ebp
  80019c:	89 e5                	mov    %esp,%ebp
  80019e:	83 ec 08             	sub    $0x8,%esp
	return syscall(SYS_page_alloc, 1, envid, (uint32_t) va, perm, 0, 0);
  8001a1:	6a 00                	push   $0x0
  8001a3:	6a 00                	push   $0x0
  8001a5:	ff 75 10             	pushl  0x10(%ebp)
  8001a8:	ff 75 0c             	pushl  0xc(%ebp)
  8001ab:	8b 4d 08             	mov    0x8(%ebp),%ecx
  8001ae:	ba 01 00 00 00       	mov    $0x1,%edx
  8001b3:	b8 04 00 00 00       	mov    $0x4,%eax
  8001b8:	e8 dd fe ff ff       	call   80009a <syscall>
}
  8001bd:	c9                   	leave  
  8001be:	c3                   	ret    

008001bf <sys_page_map>:

int
sys_page_map(envid_t srcenv, void *srcva, envid_t dstenv, void *dstva, int perm)
{
  8001bf:	55                   	push   %ebp
  8001c0:	89 e5                	mov    %esp,%ebp
  8001c2:	83 ec 08             	sub    $0x8,%esp
	return syscall(SYS_page_map, 1, srcenv, (uint32_t) srcva, dstenv, (uint32_t) dstva, perm);
  8001c5:	ff 75 18             	pushl  0x18(%ebp)
  8001c8:	ff 75 14             	pushl  0x14(%ebp)
  8001cb:	ff 75 10             	pushl  0x10(%ebp)
  8001ce:	ff 75 0c             	pushl  0xc(%ebp)
  8001d1:	8b 4d 08             	mov    0x8(%ebp),%ecx
  8001d4:	ba 01 00 00 00       	mov    $0x1,%edx
  8001d9:	b8 05 00 00 00       	mov    $0x5,%eax
  8001de:	e8 b7 fe ff ff       	call   80009a <syscall>
}
  8001e3:	c9                   	leave  
  8001e4:	c3                   	ret    

008001e5 <sys_page_unmap>:

int
sys_page_unmap(envid_t envid, void *va)
{
  8001e5:	55                   	push   %ebp
  8001e6:	89 e5                	mov    %esp,%ebp
  8001e8:	83 ec 08             	sub    $0x8,%esp
	return syscall(SYS_page_unmap, 1, envid, (uint32_t) va, 0, 0, 0);
  8001eb:	6a 00                	push   $0x0
  8001ed:	6a 00                	push   $0x0
  8001ef:	6a 00                	push   $0x0
  8001f1:	ff 75 0c             	pushl  0xc(%ebp)
  8001f4:	8b 4d 08             	mov    0x8(%ebp),%ecx
  8001f7:	ba 01 00 00 00       	mov    $0x1,%edx
  8001fc:	b8 06 00 00 00       	mov    $0x6,%eax
  800201:	e8 94 fe ff ff       	call   80009a <syscall>
}
  800206:	c9                   	leave  
  800207:	c3                   	ret    

00800208 <sys_env_set_status>:

// sys_exofork is inlined in lib.h

int
sys_env_set_status(envid_t envid, int status)
{
  800208:	55                   	push   %ebp
  800209:	89 e5                	mov    %esp,%ebp
  80020b:	83 ec 08             	sub    $0x8,%esp
	return syscall(SYS_env_set_status, 1, envid, status, 0, 0, 0);
  80020e:	6a 00                	push   $0x0
  800210:	6a 00                	push   $0x0
  800212:	6a 00                	push   $0x0
  800214:	ff 75 0c             	pushl  0xc(%ebp)
  800217:	8b 4d 08             	mov    0x8(%ebp),%ecx
  80021a:	ba 01 00 00 00       	mov    $0x1,%edx
  80021f:	b8 08 00 00 00       	mov    $0x8,%eax
  800224:	e8 71 fe ff ff       	call   80009a <syscall>
}
  800229:	c9                   	leave  
  80022a:	c3                   	ret    

0080022b <sys_env_set_pgfault_upcall>:

int
sys_env_set_pgfault_upcall(envid_t envid, void *upcall)
{
  80022b:	55                   	push   %ebp
  80022c:	89 e5                	mov    %esp,%ebp
  80022e:	83 ec 08             	sub    $0x8,%esp
	return syscall(SYS_env_set_pgfault_upcall, 1, envid, (uint32_t) upcall, 0, 0, 0);
  800231:	6a 00                	push   $0x0
  800233:	6a 00                	push   $0x0
  800235:	6a 00                	push   $0x0
  800237:	ff 75 0c             	pushl  0xc(%ebp)
  80023a:	8b 4d 08             	mov    0x8(%ebp),%ecx
  80023d:	ba 01 00 00 00       	mov    $0x1,%edx
  800242:	b8 09 00 00 00       	mov    $0x9,%eax
  800247:	e8 4e fe ff ff       	call   80009a <syscall>
}
  80024c:	c9                   	leave  
  80024d:	c3                   	ret    

0080024e <sys_ipc_try_send>:

int
sys_ipc_try_send(envid_t envid, uint32_t value, void *srcva, int perm)
{
  80024e:	55                   	push   %ebp
  80024f:	89 e5                	mov    %esp,%ebp
  800251:	83 ec 08             	sub    $0x8,%esp
	return syscall(SYS_ipc_try_send, 0, envid, value, (uint32_t) srcva, perm, 0);
  800254:	6a 00                	push   $0x0
  800256:	ff 75 14             	pushl  0x14(%ebp)
  800259:	ff 75 10             	pushl  0x10(%ebp)
  80025c:	ff 75 0c             	pushl  0xc(%ebp)
  80025f:	8b 4d 08             	mov    0x8(%ebp),%ecx
  800262:	ba 00 00 00 00       	mov    $0x0,%edx
  800267:	b8 0b 00 00 00       	mov    $0xb,%eax
  80026c:	e8 29 fe ff ff       	call   80009a <syscall>
}
  800271:	c9                   	leave  
  800272:	c3                   	ret    

00800273 <sys_ipc_recv>:

int
sys_ipc_recv(void *dstva)
{
  800273:	55                   	push   %ebp
  800274:	89 e5                	mov    %esp,%ebp
  800276:	83 ec 08             	sub    $0x8,%esp
	return syscall(SYS_ipc_recv, 1, (uint32_t)dstva, 0, 0, 0, 0);
  800279:	6a 00                	push   $0x0
  80027b:	6a 00                	push   $0x0
  80027d:	6a 00                	push   $0x0
  80027f:	6a 00                	push   $0x0
  800281:	8b 4d 08             	mov    0x8(%ebp),%ecx
  800284:	ba 01 00 00 00       	mov    $0x1,%edx
  800289:	b8 0c 00 00 00       	mov    $0xc,%eax
  80028e:	e8 07 fe ff ff       	call   80009a <syscall>
}
  800293:	c9                   	leave  
  800294:	c3                   	ret    

00800295 <_panic>:
 * It prints "panic: <message>", then causes a breakpoint exception,
 * which causes JOS to enter the JOS kernel monitor.
 */
void
_panic(const char *file, int line, const char *fmt, ...)
{
  800295:	55                   	push   %ebp
  800296:	89 e5                	mov    %esp,%ebp
  800298:	56                   	push   %esi
  800299:	53                   	push   %ebx
	va_list ap;

	va_start(ap, fmt);
  80029a:	8d 5d 14             	lea    0x14(%ebp),%ebx

	// Print the panic message
	cprintf("[%08x] user panic in %s at %s:%d: ",
  80029d:	8b 35 00 20 80 00    	mov    0x802000,%esi
  8002a3:	e8 a8 fe ff ff       	call   800150 <sys_getenvid>
  8002a8:	83 ec 0c             	sub    $0xc,%esp
  8002ab:	ff 75 0c             	pushl  0xc(%ebp)
  8002ae:	ff 75 08             	pushl  0x8(%ebp)
  8002b1:	56                   	push   %esi
  8002b2:	50                   	push   %eax
  8002b3:	68 f8 0e 80 00       	push   $0x800ef8
  8002b8:	e8 b1 00 00 00       	call   80036e <cprintf>
		sys_getenvid(), binaryname, file, line);
	vcprintf(fmt, ap);
  8002bd:	83 c4 18             	add    $0x18,%esp
  8002c0:	53                   	push   %ebx
  8002c1:	ff 75 10             	pushl  0x10(%ebp)
  8002c4:	e8 54 00 00 00       	call   80031d <vcprintf>
	cprintf("\n");
  8002c9:	c7 04 24 1c 0f 80 00 	movl   $0x800f1c,(%esp)
  8002d0:	e8 99 00 00 00       	call   80036e <cprintf>
  8002d5:	83 c4 10             	add    $0x10,%esp

	// Cause a breakpoint exception
	while (1)
		asm volatile("int3");
  8002d8:	cc                   	int3   
  8002d9:	eb fd                	jmp    8002d8 <_panic+0x43>

008002db <putch>:
};


static void
putch(int ch, struct printbuf *b)
{
  8002db:	55                   	push   %ebp
  8002dc:	89 e5                	mov    %esp,%ebp
  8002de:	53                   	push   %ebx
  8002df:	83 ec 04             	sub    $0x4,%esp
  8002e2:	8b 5d 0c             	mov    0xc(%ebp),%ebx
	b->buf[b->idx++] = ch;
  8002e5:	8b 13                	mov    (%ebx),%edx
  8002e7:	8d 42 01             	lea    0x1(%edx),%eax
  8002ea:	89 03                	mov    %eax,(%ebx)
  8002ec:	8b 4d 08             	mov    0x8(%ebp),%ecx
  8002ef:	88 4c 13 08          	mov    %cl,0x8(%ebx,%edx,1)
	if (b->idx == 256-1) {
  8002f3:	3d ff 00 00 00       	cmp    $0xff,%eax
  8002f8:	75 1a                	jne    800314 <putch+0x39>
		sys_cputs(b->buf, b->idx);
  8002fa:	83 ec 08             	sub    $0x8,%esp
  8002fd:	68 ff 00 00 00       	push   $0xff
  800302:	8d 43 08             	lea    0x8(%ebx),%eax
  800305:	50                   	push   %eax
  800306:	e8 d9 fd ff ff       	call   8000e4 <sys_cputs>
		b->idx = 0;
  80030b:	c7 03 00 00 00 00    	movl   $0x0,(%ebx)
  800311:	83 c4 10             	add    $0x10,%esp
	}
	b->cnt++;
  800314:	83 43 04 01          	addl   $0x1,0x4(%ebx)
}
  800318:	8b 5d fc             	mov    -0x4(%ebp),%ebx
  80031b:	c9                   	leave  
  80031c:	c3                   	ret    

0080031d <vcprintf>:

int
vcprintf(const char *fmt, va_list ap)
{
  80031d:	55                   	push   %ebp
  80031e:	89 e5                	mov    %esp,%ebp
  800320:	81 ec 18 01 00 00    	sub    $0x118,%esp
	struct printbuf b;

	b.idx = 0;
  800326:	c7 85 f0 fe ff ff 00 	movl   $0x0,-0x110(%ebp)
  80032d:	00 00 00 
	b.cnt = 0;
  800330:	c7 85 f4 fe ff ff 00 	movl   $0x0,-0x10c(%ebp)
  800337:	00 00 00 
	vprintfmt((void*)putch, &b, fmt, ap);
  80033a:	ff 75 0c             	pushl  0xc(%ebp)
  80033d:	ff 75 08             	pushl  0x8(%ebp)
  800340:	8d 85 f0 fe ff ff    	lea    -0x110(%ebp),%eax
  800346:	50                   	push   %eax
  800347:	68 db 02 80 00       	push   $0x8002db
  80034c:	e8 86 01 00 00       	call   8004d7 <vprintfmt>
	sys_cputs(b.buf, b.idx);
  800351:	83 c4 08             	add    $0x8,%esp
  800354:	ff b5 f0 fe ff ff    	pushl  -0x110(%ebp)
  80035a:	8d 85 f8 fe ff ff    	lea    -0x108(%ebp),%eax
  800360:	50                   	push   %eax
  800361:	e8 7e fd ff ff       	call   8000e4 <sys_cputs>

	return b.cnt;
}
  800366:	8b 85 f4 fe ff ff    	mov    -0x10c(%ebp),%eax
  80036c:	c9                   	leave  
  80036d:	c3                   	ret    

0080036e <cprintf>:

int
cprintf(const char *fmt, ...)
{
  80036e:	55                   	push   %ebp
  80036f:	89 e5                	mov    %esp,%ebp
  800371:	83 ec 10             	sub    $0x10,%esp
	va_list ap;
	int cnt;

	va_start(ap, fmt);
  800374:	8d 45 0c             	lea    0xc(%ebp),%eax
	cnt = vcprintf(fmt, ap);
  800377:	50                   	push   %eax
  800378:	ff 75 08             	pushl  0x8(%ebp)
  80037b:	e8 9d ff ff ff       	call   80031d <vcprintf>
	va_end(ap);

	return cnt;
}
  800380:	c9                   	leave  
  800381:	c3                   	ret    

00800382 <printnum>:
 * using specified putch function and associated pointer putdat.
 */
static void
printnum(void (*putch)(int, void*), void *putdat,
	 unsigned long long num, unsigned base, int width, int padc)
{
  800382:	55                   	push   %ebp
  800383:	89 e5                	mov    %esp,%ebp
  800385:	57                   	push   %edi
  800386:	56                   	push   %esi
  800387:	53                   	push   %ebx
  800388:	83 ec 1c             	sub    $0x1c,%esp
  80038b:	89 c7                	mov    %eax,%edi
  80038d:	89 d6                	mov    %edx,%esi
  80038f:	8b 45 08             	mov    0x8(%ebp),%eax
  800392:	8b 55 0c             	mov    0xc(%ebp),%edx
  800395:	89 45 d8             	mov    %eax,-0x28(%ebp)
  800398:	89 55 dc             	mov    %edx,-0x24(%ebp)
	// first recursively print all preceding (more significant) digits
	if (num >= base) {
  80039b:	8b 4d 10             	mov    0x10(%ebp),%ecx
  80039e:	bb 00 00 00 00       	mov    $0x0,%ebx
  8003a3:	89 4d e0             	mov    %ecx,-0x20(%ebp)
  8003a6:	89 5d e4             	mov    %ebx,-0x1c(%ebp)
  8003a9:	39 d3                	cmp    %edx,%ebx
  8003ab:	72 05                	jb     8003b2 <printnum+0x30>
  8003ad:	39 45 10             	cmp    %eax,0x10(%ebp)
  8003b0:	77 45                	ja     8003f7 <printnum+0x75>
		printnum(putch, putdat, num / base, base, width - 1, padc);
  8003b2:	83 ec 0c             	sub    $0xc,%esp
  8003b5:	ff 75 18             	pushl  0x18(%ebp)
  8003b8:	8b 45 14             	mov    0x14(%ebp),%eax
  8003bb:	8d 58 ff             	lea    -0x1(%eax),%ebx
  8003be:	53                   	push   %ebx
  8003bf:	ff 75 10             	pushl  0x10(%ebp)
  8003c2:	83 ec 08             	sub    $0x8,%esp
  8003c5:	ff 75 e4             	pushl  -0x1c(%ebp)
  8003c8:	ff 75 e0             	pushl  -0x20(%ebp)
  8003cb:	ff 75 dc             	pushl  -0x24(%ebp)
  8003ce:	ff 75 d8             	pushl  -0x28(%ebp)
  8003d1:	e8 5a 08 00 00       	call   800c30 <__udivdi3>
  8003d6:	83 c4 18             	add    $0x18,%esp
  8003d9:	52                   	push   %edx
  8003da:	50                   	push   %eax
  8003db:	89 f2                	mov    %esi,%edx
  8003dd:	89 f8                	mov    %edi,%eax
  8003df:	e8 9e ff ff ff       	call   800382 <printnum>
  8003e4:	83 c4 20             	add    $0x20,%esp
  8003e7:	eb 18                	jmp    800401 <printnum+0x7f>
	} else {
		// print any needed pad characters before first digit
		while (--width > 0)
			putch(padc, putdat);
  8003e9:	83 ec 08             	sub    $0x8,%esp
  8003ec:	56                   	push   %esi
  8003ed:	ff 75 18             	pushl  0x18(%ebp)
  8003f0:	ff d7                	call   *%edi
  8003f2:	83 c4 10             	add    $0x10,%esp
  8003f5:	eb 03                	jmp    8003fa <printnum+0x78>
  8003f7:	8b 5d 14             	mov    0x14(%ebp),%ebx
	// first recursively print all preceding (more significant) digits
	if (num >= base) {
		printnum(putch, putdat, num / base, base, width - 1, padc);
	} else {
		// print any needed pad characters before first digit
		while (--width > 0)
  8003fa:	83 eb 01             	sub    $0x1,%ebx
  8003fd:	85 db                	test   %ebx,%ebx
  8003ff:	7f e8                	jg     8003e9 <printnum+0x67>
			putch(padc, putdat);
	}

	// then print this (the least significant) digit
	putch("0123456789abcdef"[num % base], putdat);
  800401:	83 ec 08             	sub    $0x8,%esp
  800404:	56                   	push   %esi
  800405:	83 ec 04             	sub    $0x4,%esp
  800408:	ff 75 e4             	pushl  -0x1c(%ebp)
  80040b:	ff 75 e0             	pushl  -0x20(%ebp)
  80040e:	ff 75 dc             	pushl  -0x24(%ebp)
  800411:	ff 75 d8             	pushl  -0x28(%ebp)
  800414:	e8 47 09 00 00       	call   800d60 <__umoddi3>
  800419:	83 c4 14             	add    $0x14,%esp
  80041c:	0f be 80 1e 0f 80 00 	movsbl 0x800f1e(%eax),%eax
  800423:	50                   	push   %eax
  800424:	ff d7                	call   *%edi
}
  800426:	83 c4 10             	add    $0x10,%esp
  800429:	8d 65 f4             	lea    -0xc(%ebp),%esp
  80042c:	5b                   	pop    %ebx
  80042d:	5e                   	pop    %esi
  80042e:	5f                   	pop    %edi
  80042f:	5d                   	pop    %ebp
  800430:	c3                   	ret    

00800431 <getuint>:

// Get an unsigned int of various possible sizes from a varargs list,
// depending on the lflag parameter.
static unsigned long long
getuint(va_list *ap, int lflag)
{
  800431:	55                   	push   %ebp
  800432:	89 e5                	mov    %esp,%ebp
	if (lflag >= 2)
  800434:	83 fa 01             	cmp    $0x1,%edx
  800437:	7e 0e                	jle    800447 <getuint+0x16>
		return va_arg(*ap, unsigned long long);
  800439:	8b 10                	mov    (%eax),%edx
  80043b:	8d 4a 08             	lea    0x8(%edx),%ecx
  80043e:	89 08                	mov    %ecx,(%eax)
  800440:	8b 02                	mov    (%edx),%eax
  800442:	8b 52 04             	mov    0x4(%edx),%edx
  800445:	eb 22                	jmp    800469 <getuint+0x38>
	else if (lflag)
  800447:	85 d2                	test   %edx,%edx
  800449:	74 10                	je     80045b <getuint+0x2a>
		return va_arg(*ap, unsigned long);
  80044b:	8b 10                	mov    (%eax),%edx
  80044d:	8d 4a 04             	lea    0x4(%edx),%ecx
  800450:	89 08                	mov    %ecx,(%eax)
  800452:	8b 02                	mov    (%edx),%eax
  800454:	ba 00 00 00 00       	mov    $0x0,%edx
  800459:	eb 0e                	jmp    800469 <getuint+0x38>
	else
		return va_arg(*ap, unsigned int);
  80045b:	8b 10                	mov    (%eax),%edx
  80045d:	8d 4a 04             	lea    0x4(%edx),%ecx
  800460:	89 08                	mov    %ecx,(%eax)
  800462:	8b 02                	mov    (%edx),%eax
  800464:	ba 00 00 00 00       	mov    $0x0,%edx
}
  800469:	5d                   	pop    %ebp
  80046a:	c3                   	ret    

0080046b <getint>:

// Same as getuint but signed - can't use getuint
// because of sign extension
static long long
getint(va_list *ap, int lflag)
{
  80046b:	55                   	push   %ebp
  80046c:	89 e5                	mov    %esp,%ebp
	if (lflag >= 2)
  80046e:	83 fa 01             	cmp    $0x1,%edx
  800471:	7e 0e                	jle    800481 <getint+0x16>
		return va_arg(*ap, long long);
  800473:	8b 10                	mov    (%eax),%edx
  800475:	8d 4a 08             	lea    0x8(%edx),%ecx
  800478:	89 08                	mov    %ecx,(%eax)
  80047a:	8b 02                	mov    (%edx),%eax
  80047c:	8b 52 04             	mov    0x4(%edx),%edx
  80047f:	eb 1a                	jmp    80049b <getint+0x30>
	else if (lflag)
  800481:	85 d2                	test   %edx,%edx
  800483:	74 0c                	je     800491 <getint+0x26>
		return va_arg(*ap, long);
  800485:	8b 10                	mov    (%eax),%edx
  800487:	8d 4a 04             	lea    0x4(%edx),%ecx
  80048a:	89 08                	mov    %ecx,(%eax)
  80048c:	8b 02                	mov    (%edx),%eax
  80048e:	99                   	cltd   
  80048f:	eb 0a                	jmp    80049b <getint+0x30>
	else
		return va_arg(*ap, int);
  800491:	8b 10                	mov    (%eax),%edx
  800493:	8d 4a 04             	lea    0x4(%edx),%ecx
  800496:	89 08                	mov    %ecx,(%eax)
  800498:	8b 02                	mov    (%edx),%eax
  80049a:	99                   	cltd   
}
  80049b:	5d                   	pop    %ebp
  80049c:	c3                   	ret    

0080049d <sprintputch>:
	int cnt;
};

static void
sprintputch(int ch, struct sprintbuf *b)
{
  80049d:	55                   	push   %ebp
  80049e:	89 e5                	mov    %esp,%ebp
  8004a0:	8b 45 0c             	mov    0xc(%ebp),%eax
	b->cnt++;
  8004a3:	83 40 08 01          	addl   $0x1,0x8(%eax)
	if (b->buf < b->ebuf)
  8004a7:	8b 10                	mov    (%eax),%edx
  8004a9:	3b 50 04             	cmp    0x4(%eax),%edx
  8004ac:	73 0a                	jae    8004b8 <sprintputch+0x1b>
		*b->buf++ = ch;
  8004ae:	8d 4a 01             	lea    0x1(%edx),%ecx
  8004b1:	89 08                	mov    %ecx,(%eax)
  8004b3:	8b 45 08             	mov    0x8(%ebp),%eax
  8004b6:	88 02                	mov    %al,(%edx)
}
  8004b8:	5d                   	pop    %ebp
  8004b9:	c3                   	ret    

008004ba <printfmt>:
	}
}

void
printfmt(void (*putch)(int, void*), void *putdat, const char *fmt, ...)
{
  8004ba:	55                   	push   %ebp
  8004bb:	89 e5                	mov    %esp,%ebp
  8004bd:	83 ec 08             	sub    $0x8,%esp
	va_list ap;

	va_start(ap, fmt);
  8004c0:	8d 45 14             	lea    0x14(%ebp),%eax
	vprintfmt(putch, putdat, fmt, ap);
  8004c3:	50                   	push   %eax
  8004c4:	ff 75 10             	pushl  0x10(%ebp)
  8004c7:	ff 75 0c             	pushl  0xc(%ebp)
  8004ca:	ff 75 08             	pushl  0x8(%ebp)
  8004cd:	e8 05 00 00 00       	call   8004d7 <vprintfmt>
	va_end(ap);
}
  8004d2:	83 c4 10             	add    $0x10,%esp
  8004d5:	c9                   	leave  
  8004d6:	c3                   	ret    

008004d7 <vprintfmt>:
// Main function to format and print a string.
void printfmt(void (*putch)(int, void*), void *putdat, const char *fmt, ...);

void
vprintfmt(void (*putch)(int, void*), void *putdat, const char *fmt, va_list ap)
{
  8004d7:	55                   	push   %ebp
  8004d8:	89 e5                	mov    %esp,%ebp
  8004da:	57                   	push   %edi
  8004db:	56                   	push   %esi
  8004dc:	53                   	push   %ebx
  8004dd:	83 ec 2c             	sub    $0x2c,%esp
  8004e0:	8b 75 08             	mov    0x8(%ebp),%esi
  8004e3:	8b 5d 0c             	mov    0xc(%ebp),%ebx
  8004e6:	8b 7d 10             	mov    0x10(%ebp),%edi
  8004e9:	eb 12                	jmp    8004fd <vprintfmt+0x26>
	int base, lflag, width, precision, altflag;
	char padc;

	while (1) {
		while ((ch = *(unsigned char *) fmt++) != '%') {
			if (ch == '\0')
  8004eb:	85 c0                	test   %eax,%eax
  8004ed:	0f 84 44 03 00 00    	je     800837 <vprintfmt+0x360>
				return;
			putch(ch, putdat);
  8004f3:	83 ec 08             	sub    $0x8,%esp
  8004f6:	53                   	push   %ebx
  8004f7:	50                   	push   %eax
  8004f8:	ff d6                	call   *%esi
  8004fa:	83 c4 10             	add    $0x10,%esp
	unsigned long long num;
	int base, lflag, width, precision, altflag;
	char padc;

	while (1) {
		while ((ch = *(unsigned char *) fmt++) != '%') {
  8004fd:	83 c7 01             	add    $0x1,%edi
  800500:	0f b6 47 ff          	movzbl -0x1(%edi),%eax
  800504:	83 f8 25             	cmp    $0x25,%eax
  800507:	75 e2                	jne    8004eb <vprintfmt+0x14>
  800509:	c6 45 d4 20          	movb   $0x20,-0x2c(%ebp)
  80050d:	c7 45 d8 00 00 00 00 	movl   $0x0,-0x28(%ebp)
  800514:	c7 45 d0 ff ff ff ff 	movl   $0xffffffff,-0x30(%ebp)
  80051b:	c7 45 e0 ff ff ff ff 	movl   $0xffffffff,-0x20(%ebp)
  800522:	ba 00 00 00 00       	mov    $0x0,%edx
  800527:	eb 07                	jmp    800530 <vprintfmt+0x59>
		width = -1;
		precision = -1;
		lflag = 0;
		altflag = 0;
	reswitch:
		switch (ch = *(unsigned char *) fmt++) {
  800529:	8b 7d e4             	mov    -0x1c(%ebp),%edi

		// flag to pad on the right
		case '-':
			padc = '-';
  80052c:	c6 45 d4 2d          	movb   $0x2d,-0x2c(%ebp)
		width = -1;
		precision = -1;
		lflag = 0;
		altflag = 0;
	reswitch:
		switch (ch = *(unsigned char *) fmt++) {
  800530:	8d 47 01             	lea    0x1(%edi),%eax
  800533:	89 45 e4             	mov    %eax,-0x1c(%ebp)
  800536:	0f b6 07             	movzbl (%edi),%eax
  800539:	0f b6 c8             	movzbl %al,%ecx
  80053c:	83 e8 23             	sub    $0x23,%eax
  80053f:	3c 55                	cmp    $0x55,%al
  800541:	0f 87 d5 02 00 00    	ja     80081c <vprintfmt+0x345>
  800547:	0f b6 c0             	movzbl %al,%eax
  80054a:	ff 24 85 e0 0f 80 00 	jmp    *0x800fe0(,%eax,4)
  800551:	8b 7d e4             	mov    -0x1c(%ebp),%edi
			padc = '-';
			goto reswitch;

		// flag to pad with 0's instead of spaces
		case '0':
			padc = '0';
  800554:	c6 45 d4 30          	movb   $0x30,-0x2c(%ebp)
  800558:	eb d6                	jmp    800530 <vprintfmt+0x59>
		width = -1;
		precision = -1;
		lflag = 0;
		altflag = 0;
	reswitch:
		switch (ch = *(unsigned char *) fmt++) {
  80055a:	8b 7d e4             	mov    -0x1c(%ebp),%edi
  80055d:	b8 00 00 00 00       	mov    $0x0,%eax
  800562:	89 55 e4             	mov    %edx,-0x1c(%ebp)
		case '6':
		case '7':
		case '8':
		case '9':
			for (precision = 0; ; ++fmt) {
				precision = precision * 10 + ch - '0';
  800565:	8d 04 80             	lea    (%eax,%eax,4),%eax
  800568:	8d 44 41 d0          	lea    -0x30(%ecx,%eax,2),%eax
				ch = *fmt;
  80056c:	0f be 0f             	movsbl (%edi),%ecx
				if (ch < '0' || ch > '9')
  80056f:	8d 51 d0             	lea    -0x30(%ecx),%edx
  800572:	83 fa 09             	cmp    $0x9,%edx
  800575:	77 39                	ja     8005b0 <vprintfmt+0xd9>
		case '5':
		case '6':
		case '7':
		case '8':
		case '9':
			for (precision = 0; ; ++fmt) {
  800577:	83 c7 01             	add    $0x1,%edi
				precision = precision * 10 + ch - '0';
				ch = *fmt;
				if (ch < '0' || ch > '9')
					break;
			}
  80057a:	eb e9                	jmp    800565 <vprintfmt+0x8e>
			goto process_precision;

		case '*':
			precision = va_arg(ap, int);
  80057c:	8b 45 14             	mov    0x14(%ebp),%eax
  80057f:	8d 48 04             	lea    0x4(%eax),%ecx
  800582:	89 4d 14             	mov    %ecx,0x14(%ebp)
  800585:	8b 00                	mov    (%eax),%eax
  800587:	89 45 d0             	mov    %eax,-0x30(%ebp)
		width = -1;
		precision = -1;
		lflag = 0;
		altflag = 0;
	reswitch:
		switch (ch = *(unsigned char *) fmt++) {
  80058a:	8b 7d e4             	mov    -0x1c(%ebp),%edi
			}
			goto process_precision;

		case '*':
			precision = va_arg(ap, int);
			goto process_precision;
  80058d:	eb 27                	jmp    8005b6 <vprintfmt+0xdf>
  80058f:	8b 45 e0             	mov    -0x20(%ebp),%eax
  800592:	85 c0                	test   %eax,%eax
  800594:	b9 00 00 00 00       	mov    $0x0,%ecx
  800599:	0f 49 c8             	cmovns %eax,%ecx
  80059c:	89 4d e0             	mov    %ecx,-0x20(%ebp)
		width = -1;
		precision = -1;
		lflag = 0;
		altflag = 0;
	reswitch:
		switch (ch = *(unsigned char *) fmt++) {
  80059f:	8b 7d e4             	mov    -0x1c(%ebp),%edi
  8005a2:	eb 8c                	jmp    800530 <vprintfmt+0x59>
  8005a4:	8b 7d e4             	mov    -0x1c(%ebp),%edi
			if (width < 0)
				width = 0;
			goto reswitch;

		case '#':
			altflag = 1;
  8005a7:	c7 45 d8 01 00 00 00 	movl   $0x1,-0x28(%ebp)
			goto reswitch;
  8005ae:	eb 80                	jmp    800530 <vprintfmt+0x59>
  8005b0:	8b 55 e4             	mov    -0x1c(%ebp),%edx
  8005b3:	89 45 d0             	mov    %eax,-0x30(%ebp)

		process_precision:
			if (width < 0)
  8005b6:	83 7d e0 00          	cmpl   $0x0,-0x20(%ebp)
  8005ba:	0f 89 70 ff ff ff    	jns    800530 <vprintfmt+0x59>
				width = precision, precision = -1;
  8005c0:	8b 45 d0             	mov    -0x30(%ebp),%eax
  8005c3:	89 45 e0             	mov    %eax,-0x20(%ebp)
  8005c6:	c7 45 d0 ff ff ff ff 	movl   $0xffffffff,-0x30(%ebp)
  8005cd:	e9 5e ff ff ff       	jmp    800530 <vprintfmt+0x59>
			goto reswitch;

		// long flag (doubled for long long)
		case 'l':
			lflag++;
  8005d2:	83 c2 01             	add    $0x1,%edx
		width = -1;
		precision = -1;
		lflag = 0;
		altflag = 0;
	reswitch:
		switch (ch = *(unsigned char *) fmt++) {
  8005d5:	8b 7d e4             	mov    -0x1c(%ebp),%edi
			goto reswitch;

		// long flag (doubled for long long)
		case 'l':
			lflag++;
			goto reswitch;
  8005d8:	e9 53 ff ff ff       	jmp    800530 <vprintfmt+0x59>

		// character
		case 'c':
			putch(va_arg(ap, int), putdat);
  8005dd:	8b 45 14             	mov    0x14(%ebp),%eax
  8005e0:	8d 50 04             	lea    0x4(%eax),%edx
  8005e3:	89 55 14             	mov    %edx,0x14(%ebp)
  8005e6:	83 ec 08             	sub    $0x8,%esp
  8005e9:	53                   	push   %ebx
  8005ea:	ff 30                	pushl  (%eax)
  8005ec:	ff d6                	call   *%esi
			break;
  8005ee:	83 c4 10             	add    $0x10,%esp
		width = -1;
		precision = -1;
		lflag = 0;
		altflag = 0;
	reswitch:
		switch (ch = *(unsigned char *) fmt++) {
  8005f1:	8b 7d e4             	mov    -0x1c(%ebp),%edi
			goto reswitch;

		// character
		case 'c':
			putch(va_arg(ap, int), putdat);
			break;
  8005f4:	e9 04 ff ff ff       	jmp    8004fd <vprintfmt+0x26>

		// error message
		case 'e':
			err = va_arg(ap, int);
  8005f9:	8b 45 14             	mov    0x14(%ebp),%eax
  8005fc:	8d 50 04             	lea    0x4(%eax),%edx
  8005ff:	89 55 14             	mov    %edx,0x14(%ebp)
  800602:	8b 00                	mov    (%eax),%eax
  800604:	99                   	cltd   
  800605:	31 d0                	xor    %edx,%eax
  800607:	29 d0                	sub    %edx,%eax
			if (err < 0)
				err = -err;
			if (err >= MAXERROR || (p = error_string[err]) == NULL)
  800609:	83 f8 08             	cmp    $0x8,%eax
  80060c:	7f 0b                	jg     800619 <vprintfmt+0x142>
  80060e:	8b 14 85 40 11 80 00 	mov    0x801140(,%eax,4),%edx
  800615:	85 d2                	test   %edx,%edx
  800617:	75 18                	jne    800631 <vprintfmt+0x15a>
				printfmt(putch, putdat, "error %d", err);
  800619:	50                   	push   %eax
  80061a:	68 36 0f 80 00       	push   $0x800f36
  80061f:	53                   	push   %ebx
  800620:	56                   	push   %esi
  800621:	e8 94 fe ff ff       	call   8004ba <printfmt>
  800626:	83 c4 10             	add    $0x10,%esp
		width = -1;
		precision = -1;
		lflag = 0;
		altflag = 0;
	reswitch:
		switch (ch = *(unsigned char *) fmt++) {
  800629:	8b 7d e4             	mov    -0x1c(%ebp),%edi
		case 'e':
			err = va_arg(ap, int);
			if (err < 0)
				err = -err;
			if (err >= MAXERROR || (p = error_string[err]) == NULL)
				printfmt(putch, putdat, "error %d", err);
  80062c:	e9 cc fe ff ff       	jmp    8004fd <vprintfmt+0x26>
			else
				printfmt(putch, putdat, "%s", p);
  800631:	52                   	push   %edx
  800632:	68 3f 0f 80 00       	push   $0x800f3f
  800637:	53                   	push   %ebx
  800638:	56                   	push   %esi
  800639:	e8 7c fe ff ff       	call   8004ba <printfmt>
  80063e:	83 c4 10             	add    $0x10,%esp
		width = -1;
		precision = -1;
		lflag = 0;
		altflag = 0;
	reswitch:
		switch (ch = *(unsigned char *) fmt++) {
  800641:	8b 7d e4             	mov    -0x1c(%ebp),%edi
  800644:	e9 b4 fe ff ff       	jmp    8004fd <vprintfmt+0x26>
				printfmt(putch, putdat, "%s", p);
			break;

		// string
		case 's':
			if ((p = va_arg(ap, char *)) == NULL)
  800649:	8b 45 14             	mov    0x14(%ebp),%eax
  80064c:	8d 50 04             	lea    0x4(%eax),%edx
  80064f:	89 55 14             	mov    %edx,0x14(%ebp)
  800652:	8b 38                	mov    (%eax),%edi
				p = "(null)";
  800654:	85 ff                	test   %edi,%edi
  800656:	b8 2f 0f 80 00       	mov    $0x800f2f,%eax
  80065b:	0f 44 f8             	cmove  %eax,%edi
			if (width > 0 && padc != '-')
  80065e:	83 7d e0 00          	cmpl   $0x0,-0x20(%ebp)
  800662:	0f 8e 94 00 00 00    	jle    8006fc <vprintfmt+0x225>
  800668:	80 7d d4 2d          	cmpb   $0x2d,-0x2c(%ebp)
  80066c:	0f 84 98 00 00 00    	je     80070a <vprintfmt+0x233>
				for (width -= strnlen(p, precision); width > 0; width--)
  800672:	83 ec 08             	sub    $0x8,%esp
  800675:	ff 75 d0             	pushl  -0x30(%ebp)
  800678:	57                   	push   %edi
  800679:	e8 41 02 00 00       	call   8008bf <strnlen>
  80067e:	8b 4d e0             	mov    -0x20(%ebp),%ecx
  800681:	29 c1                	sub    %eax,%ecx
  800683:	89 4d cc             	mov    %ecx,-0x34(%ebp)
  800686:	83 c4 10             	add    $0x10,%esp
					putch(padc, putdat);
  800689:	0f be 45 d4          	movsbl -0x2c(%ebp),%eax
  80068d:	89 45 e0             	mov    %eax,-0x20(%ebp)
  800690:	89 7d d4             	mov    %edi,-0x2c(%ebp)
  800693:	89 cf                	mov    %ecx,%edi
		// string
		case 's':
			if ((p = va_arg(ap, char *)) == NULL)
				p = "(null)";
			if (width > 0 && padc != '-')
				for (width -= strnlen(p, precision); width > 0; width--)
  800695:	eb 0f                	jmp    8006a6 <vprintfmt+0x1cf>
					putch(padc, putdat);
  800697:	83 ec 08             	sub    $0x8,%esp
  80069a:	53                   	push   %ebx
  80069b:	ff 75 e0             	pushl  -0x20(%ebp)
  80069e:	ff d6                	call   *%esi
		// string
		case 's':
			if ((p = va_arg(ap, char *)) == NULL)
				p = "(null)";
			if (width > 0 && padc != '-')
				for (width -= strnlen(p, precision); width > 0; width--)
  8006a0:	83 ef 01             	sub    $0x1,%edi
  8006a3:	83 c4 10             	add    $0x10,%esp
  8006a6:	85 ff                	test   %edi,%edi
  8006a8:	7f ed                	jg     800697 <vprintfmt+0x1c0>
  8006aa:	8b 7d d4             	mov    -0x2c(%ebp),%edi
  8006ad:	8b 4d cc             	mov    -0x34(%ebp),%ecx
  8006b0:	85 c9                	test   %ecx,%ecx
  8006b2:	b8 00 00 00 00       	mov    $0x0,%eax
  8006b7:	0f 49 c1             	cmovns %ecx,%eax
  8006ba:	29 c1                	sub    %eax,%ecx
  8006bc:	89 75 08             	mov    %esi,0x8(%ebp)
  8006bf:	8b 75 d0             	mov    -0x30(%ebp),%esi
  8006c2:	89 5d 0c             	mov    %ebx,0xc(%ebp)
  8006c5:	89 cb                	mov    %ecx,%ebx
  8006c7:	eb 4d                	jmp    800716 <vprintfmt+0x23f>
					putch(padc, putdat);
			for (; (ch = *p++) != '\0' && (precision < 0 || --precision >= 0); width--)
				if (altflag && (ch < ' ' || ch > '~'))
  8006c9:	83 7d d8 00          	cmpl   $0x0,-0x28(%ebp)
  8006cd:	74 1b                	je     8006ea <vprintfmt+0x213>
  8006cf:	0f be c0             	movsbl %al,%eax
  8006d2:	83 e8 20             	sub    $0x20,%eax
  8006d5:	83 f8 5e             	cmp    $0x5e,%eax
  8006d8:	76 10                	jbe    8006ea <vprintfmt+0x213>
					putch('?', putdat);
  8006da:	83 ec 08             	sub    $0x8,%esp
  8006dd:	ff 75 0c             	pushl  0xc(%ebp)
  8006e0:	6a 3f                	push   $0x3f
  8006e2:	ff 55 08             	call   *0x8(%ebp)
  8006e5:	83 c4 10             	add    $0x10,%esp
  8006e8:	eb 0d                	jmp    8006f7 <vprintfmt+0x220>
				else
					putch(ch, putdat);
  8006ea:	83 ec 08             	sub    $0x8,%esp
  8006ed:	ff 75 0c             	pushl  0xc(%ebp)
  8006f0:	52                   	push   %edx
  8006f1:	ff 55 08             	call   *0x8(%ebp)
  8006f4:	83 c4 10             	add    $0x10,%esp
			if ((p = va_arg(ap, char *)) == NULL)
				p = "(null)";
			if (width > 0 && padc != '-')
				for (width -= strnlen(p, precision); width > 0; width--)
					putch(padc, putdat);
			for (; (ch = *p++) != '\0' && (precision < 0 || --precision >= 0); width--)
  8006f7:	83 eb 01             	sub    $0x1,%ebx
  8006fa:	eb 1a                	jmp    800716 <vprintfmt+0x23f>
  8006fc:	89 75 08             	mov    %esi,0x8(%ebp)
  8006ff:	8b 75 d0             	mov    -0x30(%ebp),%esi
  800702:	89 5d 0c             	mov    %ebx,0xc(%ebp)
  800705:	8b 5d e0             	mov    -0x20(%ebp),%ebx
  800708:	eb 0c                	jmp    800716 <vprintfmt+0x23f>
  80070a:	89 75 08             	mov    %esi,0x8(%ebp)
  80070d:	8b 75 d0             	mov    -0x30(%ebp),%esi
  800710:	89 5d 0c             	mov    %ebx,0xc(%ebp)
  800713:	8b 5d e0             	mov    -0x20(%ebp),%ebx
  800716:	83 c7 01             	add    $0x1,%edi
  800719:	0f b6 47 ff          	movzbl -0x1(%edi),%eax
  80071d:	0f be d0             	movsbl %al,%edx
  800720:	85 d2                	test   %edx,%edx
  800722:	74 23                	je     800747 <vprintfmt+0x270>
  800724:	85 f6                	test   %esi,%esi
  800726:	78 a1                	js     8006c9 <vprintfmt+0x1f2>
  800728:	83 ee 01             	sub    $0x1,%esi
  80072b:	79 9c                	jns    8006c9 <vprintfmt+0x1f2>
  80072d:	89 df                	mov    %ebx,%edi
  80072f:	8b 75 08             	mov    0x8(%ebp),%esi
  800732:	8b 5d 0c             	mov    0xc(%ebp),%ebx
  800735:	eb 18                	jmp    80074f <vprintfmt+0x278>
				if (altflag && (ch < ' ' || ch > '~'))
					putch('?', putdat);
				else
					putch(ch, putdat);
			for (; width > 0; width--)
				putch(' ', putdat);
  800737:	83 ec 08             	sub    $0x8,%esp
  80073a:	53                   	push   %ebx
  80073b:	6a 20                	push   $0x20
  80073d:	ff d6                	call   *%esi
			for (; (ch = *p++) != '\0' && (precision < 0 || --precision >= 0); width--)
				if (altflag && (ch < ' ' || ch > '~'))
					putch('?', putdat);
				else
					putch(ch, putdat);
			for (; width > 0; width--)
  80073f:	83 ef 01             	sub    $0x1,%edi
  800742:	83 c4 10             	add    $0x10,%esp
  800745:	eb 08                	jmp    80074f <vprintfmt+0x278>
  800747:	89 df                	mov    %ebx,%edi
  800749:	8b 75 08             	mov    0x8(%ebp),%esi
  80074c:	8b 5d 0c             	mov    0xc(%ebp),%ebx
  80074f:	85 ff                	test   %edi,%edi
  800751:	7f e4                	jg     800737 <vprintfmt+0x260>
		width = -1;
		precision = -1;
		lflag = 0;
		altflag = 0;
	reswitch:
		switch (ch = *(unsigned char *) fmt++) {
  800753:	8b 7d e4             	mov    -0x1c(%ebp),%edi
  800756:	e9 a2 fd ff ff       	jmp    8004fd <vprintfmt+0x26>
				putch(' ', putdat);
			break;

		// (signed) decimal
		case 'd':
			num = getint(&ap, lflag);
  80075b:	8d 45 14             	lea    0x14(%ebp),%eax
  80075e:	e8 08 fd ff ff       	call   80046b <getint>
  800763:	89 45 d8             	mov    %eax,-0x28(%ebp)
  800766:	89 55 dc             	mov    %edx,-0x24(%ebp)
			if ((long long) num < 0) {
				putch('-', putdat);
				num = -(long long) num;
			}
			base = 10;
  800769:	b9 0a 00 00 00       	mov    $0xa,%ecx
			break;

		// (signed) decimal
		case 'd':
			num = getint(&ap, lflag);
			if ((long long) num < 0) {
  80076e:	83 7d dc 00          	cmpl   $0x0,-0x24(%ebp)
  800772:	79 74                	jns    8007e8 <vprintfmt+0x311>
				putch('-', putdat);
  800774:	83 ec 08             	sub    $0x8,%esp
  800777:	53                   	push   %ebx
  800778:	6a 2d                	push   $0x2d
  80077a:	ff d6                	call   *%esi
				num = -(long long) num;
  80077c:	8b 45 d8             	mov    -0x28(%ebp),%eax
  80077f:	8b 55 dc             	mov    -0x24(%ebp),%edx
  800782:	f7 d8                	neg    %eax
  800784:	83 d2 00             	adc    $0x0,%edx
  800787:	f7 da                	neg    %edx
  800789:	83 c4 10             	add    $0x10,%esp
			}
			base = 10;
  80078c:	b9 0a 00 00 00       	mov    $0xa,%ecx
  800791:	eb 55                	jmp    8007e8 <vprintfmt+0x311>
			goto number;

		// unsigned decimal
		case 'u':
			num = getuint(&ap, lflag);
  800793:	8d 45 14             	lea    0x14(%ebp),%eax
  800796:	e8 96 fc ff ff       	call   800431 <getuint>
			base = 10;
  80079b:	b9 0a 00 00 00       	mov    $0xa,%ecx
			goto number;
  8007a0:	eb 46                	jmp    8007e8 <vprintfmt+0x311>

		// (unsigned) octal
		case 'o':
			num = getuint(&ap, lflag);
  8007a2:	8d 45 14             	lea    0x14(%ebp),%eax
  8007a5:	e8 87 fc ff ff       	call   800431 <getuint>
			base = 8;
  8007aa:	b9 08 00 00 00       	mov    $0x8,%ecx
			goto number;
  8007af:	eb 37                	jmp    8007e8 <vprintfmt+0x311>

		// pointer
		case 'p':
			putch('0', putdat);
  8007b1:	83 ec 08             	sub    $0x8,%esp
  8007b4:	53                   	push   %ebx
  8007b5:	6a 30                	push   $0x30
  8007b7:	ff d6                	call   *%esi
			putch('x', putdat);
  8007b9:	83 c4 08             	add    $0x8,%esp
  8007bc:	53                   	push   %ebx
  8007bd:	6a 78                	push   $0x78
  8007bf:	ff d6                	call   *%esi
			num = (unsigned long long)
				(uintptr_t) va_arg(ap, void *);
  8007c1:	8b 45 14             	mov    0x14(%ebp),%eax
  8007c4:	8d 50 04             	lea    0x4(%eax),%edx
  8007c7:	89 55 14             	mov    %edx,0x14(%ebp)

		// pointer
		case 'p':
			putch('0', putdat);
			putch('x', putdat);
			num = (unsigned long long)
  8007ca:	8b 00                	mov    (%eax),%eax
  8007cc:	ba 00 00 00 00       	mov    $0x0,%edx
				(uintptr_t) va_arg(ap, void *);
			base = 16;
			goto number;
  8007d1:	83 c4 10             	add    $0x10,%esp
		case 'p':
			putch('0', putdat);
			putch('x', putdat);
			num = (unsigned long long)
				(uintptr_t) va_arg(ap, void *);
			base = 16;
  8007d4:	b9 10 00 00 00       	mov    $0x10,%ecx
			goto number;
  8007d9:	eb 0d                	jmp    8007e8 <vprintfmt+0x311>

		// (unsigned) hexadecimal
		case 'x':
			num = getuint(&ap, lflag);
  8007db:	8d 45 14             	lea    0x14(%ebp),%eax
  8007de:	e8 4e fc ff ff       	call   800431 <getuint>
			base = 16;
  8007e3:	b9 10 00 00 00       	mov    $0x10,%ecx
		number:
			printnum(putch, putdat, num, base, width, padc);
  8007e8:	83 ec 0c             	sub    $0xc,%esp
  8007eb:	0f be 7d d4          	movsbl -0x2c(%ebp),%edi
  8007ef:	57                   	push   %edi
  8007f0:	ff 75 e0             	pushl  -0x20(%ebp)
  8007f3:	51                   	push   %ecx
  8007f4:	52                   	push   %edx
  8007f5:	50                   	push   %eax
  8007f6:	89 da                	mov    %ebx,%edx
  8007f8:	89 f0                	mov    %esi,%eax
  8007fa:	e8 83 fb ff ff       	call   800382 <printnum>
			break;
  8007ff:	83 c4 20             	add    $0x20,%esp
  800802:	8b 7d e4             	mov    -0x1c(%ebp),%edi
  800805:	e9 f3 fc ff ff       	jmp    8004fd <vprintfmt+0x26>

		// escaped '%' character
		case '%':
			putch(ch, putdat);
  80080a:	83 ec 08             	sub    $0x8,%esp
  80080d:	53                   	push   %ebx
  80080e:	51                   	push   %ecx
  80080f:	ff d6                	call   *%esi
			break;
  800811:	83 c4 10             	add    $0x10,%esp
		width = -1;
		precision = -1;
		lflag = 0;
		altflag = 0;
	reswitch:
		switch (ch = *(unsigned char *) fmt++) {
  800814:	8b 7d e4             	mov    -0x1c(%ebp),%edi
			break;

		// escaped '%' character
		case '%':
			putch(ch, putdat);
			break;
  800817:	e9 e1 fc ff ff       	jmp    8004fd <vprintfmt+0x26>

		// unrecognized escape sequence - just print it literally
		default:
			putch('%', putdat);
  80081c:	83 ec 08             	sub    $0x8,%esp
  80081f:	53                   	push   %ebx
  800820:	6a 25                	push   $0x25
  800822:	ff d6                	call   *%esi
			for (fmt--; fmt[-1] != '%'; fmt--)
  800824:	83 c4 10             	add    $0x10,%esp
  800827:	eb 03                	jmp    80082c <vprintfmt+0x355>
  800829:	83 ef 01             	sub    $0x1,%edi
  80082c:	80 7f ff 25          	cmpb   $0x25,-0x1(%edi)
  800830:	75 f7                	jne    800829 <vprintfmt+0x352>
  800832:	e9 c6 fc ff ff       	jmp    8004fd <vprintfmt+0x26>
				/* do nothing */;
			break;
		}
	}
}
  800837:	8d 65 f4             	lea    -0xc(%ebp),%esp
  80083a:	5b                   	pop    %ebx
  80083b:	5e                   	pop    %esi
  80083c:	5f                   	pop    %edi
  80083d:	5d                   	pop    %ebp
  80083e:	c3                   	ret    

0080083f <vsnprintf>:
		*b->buf++ = ch;
}

int
vsnprintf(char *buf, int n, const char *fmt, va_list ap)
{
  80083f:	55                   	push   %ebp
  800840:	89 e5                	mov    %esp,%ebp
  800842:	83 ec 18             	sub    $0x18,%esp
  800845:	8b 45 08             	mov    0x8(%ebp),%eax
  800848:	8b 55 0c             	mov    0xc(%ebp),%edx
	struct sprintbuf b = {buf, buf+n-1, 0};
  80084b:	89 45 ec             	mov    %eax,-0x14(%ebp)
  80084e:	8d 4c 10 ff          	lea    -0x1(%eax,%edx,1),%ecx
  800852:	89 4d f0             	mov    %ecx,-0x10(%ebp)
  800855:	c7 45 f4 00 00 00 00 	movl   $0x0,-0xc(%ebp)

	if (buf == NULL || n < 1)
  80085c:	85 c0                	test   %eax,%eax
  80085e:	74 26                	je     800886 <vsnprintf+0x47>
  800860:	85 d2                	test   %edx,%edx
  800862:	7e 22                	jle    800886 <vsnprintf+0x47>
		return -E_INVAL;

	// print the string to the buffer
	vprintfmt((void*)sprintputch, &b, fmt, ap);
  800864:	ff 75 14             	pushl  0x14(%ebp)
  800867:	ff 75 10             	pushl  0x10(%ebp)
  80086a:	8d 45 ec             	lea    -0x14(%ebp),%eax
  80086d:	50                   	push   %eax
  80086e:	68 9d 04 80 00       	push   $0x80049d
  800873:	e8 5f fc ff ff       	call   8004d7 <vprintfmt>

	// null terminate the buffer
	*b.buf = '\0';
  800878:	8b 45 ec             	mov    -0x14(%ebp),%eax
  80087b:	c6 00 00             	movb   $0x0,(%eax)

	return b.cnt;
  80087e:	8b 45 f4             	mov    -0xc(%ebp),%eax
  800881:	83 c4 10             	add    $0x10,%esp
  800884:	eb 05                	jmp    80088b <vsnprintf+0x4c>
vsnprintf(char *buf, int n, const char *fmt, va_list ap)
{
	struct sprintbuf b = {buf, buf+n-1, 0};

	if (buf == NULL || n < 1)
		return -E_INVAL;
  800886:	b8 fd ff ff ff       	mov    $0xfffffffd,%eax

	// null terminate the buffer
	*b.buf = '\0';

	return b.cnt;
}
  80088b:	c9                   	leave  
  80088c:	c3                   	ret    

0080088d <snprintf>:

int
snprintf(char *buf, int n, const char *fmt, ...)
{
  80088d:	55                   	push   %ebp
  80088e:	89 e5                	mov    %esp,%ebp
  800890:	83 ec 08             	sub    $0x8,%esp
	va_list ap;
	int rc;

	va_start(ap, fmt);
  800893:	8d 45 14             	lea    0x14(%ebp),%eax
	rc = vsnprintf(buf, n, fmt, ap);
  800896:	50                   	push   %eax
  800897:	ff 75 10             	pushl  0x10(%ebp)
  80089a:	ff 75 0c             	pushl  0xc(%ebp)
  80089d:	ff 75 08             	pushl  0x8(%ebp)
  8008a0:	e8 9a ff ff ff       	call   80083f <vsnprintf>
	va_end(ap);

	return rc;
}
  8008a5:	c9                   	leave  
  8008a6:	c3                   	ret    

008008a7 <strlen>:
// Primespipe runs 3x faster this way.
#define ASM 1

int
strlen(const char *s)
{
  8008a7:	55                   	push   %ebp
  8008a8:	89 e5                	mov    %esp,%ebp
  8008aa:	8b 55 08             	mov    0x8(%ebp),%edx
	int n;

	for (n = 0; *s != '\0'; s++)
  8008ad:	b8 00 00 00 00       	mov    $0x0,%eax
  8008b2:	eb 03                	jmp    8008b7 <strlen+0x10>
		n++;
  8008b4:	83 c0 01             	add    $0x1,%eax
int
strlen(const char *s)
{
	int n;

	for (n = 0; *s != '\0'; s++)
  8008b7:	80 3c 02 00          	cmpb   $0x0,(%edx,%eax,1)
  8008bb:	75 f7                	jne    8008b4 <strlen+0xd>
		n++;
	return n;
}
  8008bd:	5d                   	pop    %ebp
  8008be:	c3                   	ret    

008008bf <strnlen>:

int
strnlen(const char *s, size_t size)
{
  8008bf:	55                   	push   %ebp
  8008c0:	89 e5                	mov    %esp,%ebp
  8008c2:	8b 4d 08             	mov    0x8(%ebp),%ecx
  8008c5:	8b 45 0c             	mov    0xc(%ebp),%eax
	int n;

	for (n = 0; size > 0 && *s != '\0'; s++, size--)
  8008c8:	ba 00 00 00 00       	mov    $0x0,%edx
  8008cd:	eb 03                	jmp    8008d2 <strnlen+0x13>
		n++;
  8008cf:	83 c2 01             	add    $0x1,%edx
int
strnlen(const char *s, size_t size)
{
	int n;

	for (n = 0; size > 0 && *s != '\0'; s++, size--)
  8008d2:	39 c2                	cmp    %eax,%edx
  8008d4:	74 08                	je     8008de <strnlen+0x1f>
  8008d6:	80 3c 11 00          	cmpb   $0x0,(%ecx,%edx,1)
  8008da:	75 f3                	jne    8008cf <strnlen+0x10>
  8008dc:	89 d0                	mov    %edx,%eax
		n++;
	return n;
}
  8008de:	5d                   	pop    %ebp
  8008df:	c3                   	ret    

008008e0 <strcpy>:

char *
strcpy(char *dst, const char *src)
{
  8008e0:	55                   	push   %ebp
  8008e1:	89 e5                	mov    %esp,%ebp
  8008e3:	53                   	push   %ebx
  8008e4:	8b 45 08             	mov    0x8(%ebp),%eax
  8008e7:	8b 4d 0c             	mov    0xc(%ebp),%ecx
	char *ret;

	ret = dst;
	while ((*dst++ = *src++) != '\0')
  8008ea:	89 c2                	mov    %eax,%edx
  8008ec:	83 c2 01             	add    $0x1,%edx
  8008ef:	83 c1 01             	add    $0x1,%ecx
  8008f2:	0f b6 59 ff          	movzbl -0x1(%ecx),%ebx
  8008f6:	88 5a ff             	mov    %bl,-0x1(%edx)
  8008f9:	84 db                	test   %bl,%bl
  8008fb:	75 ef                	jne    8008ec <strcpy+0xc>
		/* do nothing */;
	return ret;
}
  8008fd:	5b                   	pop    %ebx
  8008fe:	5d                   	pop    %ebp
  8008ff:	c3                   	ret    

00800900 <strcat>:

char *
strcat(char *dst, const char *src)
{
  800900:	55                   	push   %ebp
  800901:	89 e5                	mov    %esp,%ebp
  800903:	53                   	push   %ebx
  800904:	8b 5d 08             	mov    0x8(%ebp),%ebx
	int len = strlen(dst);
  800907:	53                   	push   %ebx
  800908:	e8 9a ff ff ff       	call   8008a7 <strlen>
  80090d:	83 c4 04             	add    $0x4,%esp
	strcpy(dst + len, src);
  800910:	ff 75 0c             	pushl  0xc(%ebp)
  800913:	01 d8                	add    %ebx,%eax
  800915:	50                   	push   %eax
  800916:	e8 c5 ff ff ff       	call   8008e0 <strcpy>
	return dst;
}
  80091b:	89 d8                	mov    %ebx,%eax
  80091d:	8b 5d fc             	mov    -0x4(%ebp),%ebx
  800920:	c9                   	leave  
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
  800957:	8b 4d 0c             	mov    0xc(%ebp),%ecx
  80095a:	8b 55 10             	mov    0x10(%ebp),%edx
  80095d:	89 f0                	mov    %esi,%eax
	char *dst_in;

	dst_in = dst;
	if (size > 0) {
  80095f:	85 d2                	test   %edx,%edx
  800961:	74 21                	je     800984 <strlcpy+0x35>
  800963:	8d 44 16 ff          	lea    -0x1(%esi,%edx,1),%eax
  800967:	89 f2                	mov    %esi,%edx
  800969:	eb 09                	jmp    800974 <strlcpy+0x25>
		while (--size > 0 && *src != '\0')
			*dst++ = *src++;
  80096b:	83 c2 01             	add    $0x1,%edx
  80096e:	83 c1 01             	add    $0x1,%ecx
  800971:	88 5a ff             	mov    %bl,-0x1(%edx)
{
	char *dst_in;

	dst_in = dst;
	if (size > 0) {
		while (--size > 0 && *src != '\0')
  800974:	39 c2                	cmp    %eax,%edx
  800976:	74 09                	je     800981 <strlcpy+0x32>
  800978:	0f b6 19             	movzbl (%ecx),%ebx
  80097b:	84 db                	test   %bl,%bl
  80097d:	75 ec                	jne    80096b <strlcpy+0x1c>
  80097f:	89 d0                	mov    %edx,%eax
			*dst++ = *src++;
		*dst = '\0';
  800981:	c6 00 00             	movb   $0x0,(%eax)
	}
	return dst - dst_in;
  800984:	29 f0                	sub    %esi,%eax
}
  800986:	5b                   	pop    %ebx
  800987:	5e                   	pop    %esi
  800988:	5d                   	pop    %ebp
  800989:	c3                   	ret    

0080098a <strcmp>:

int
strcmp(const char *p, const char *q)
{
  80098a:	55                   	push   %ebp
  80098b:	89 e5                	mov    %esp,%ebp
  80098d:	8b 4d 08             	mov    0x8(%ebp),%ecx
  800990:	8b 55 0c             	mov    0xc(%ebp),%edx
	while (*p && *p == *q)
  800993:	eb 06                	jmp    80099b <strcmp+0x11>
		p++, q++;
  800995:	83 c1 01             	add    $0x1,%ecx
  800998:	83 c2 01             	add    $0x1,%edx
}

int
strcmp(const char *p, const char *q)
{
	while (*p && *p == *q)
  80099b:	0f b6 01             	movzbl (%ecx),%eax
  80099e:	84 c0                	test   %al,%al
  8009a0:	74 04                	je     8009a6 <strcmp+0x1c>
  8009a2:	3a 02                	cmp    (%edx),%al
  8009a4:	74 ef                	je     800995 <strcmp+0xb>
		p++, q++;
	return (int) ((unsigned char) *p - (unsigned char) *q);
  8009a6:	0f b6 c0             	movzbl %al,%eax
  8009a9:	0f b6 12             	movzbl (%edx),%edx
  8009ac:	29 d0                	sub    %edx,%eax
}
  8009ae:	5d                   	pop    %ebp
  8009af:	c3                   	ret    

008009b0 <strncmp>:

int
strncmp(const char *p, const char *q, size_t n)
{
  8009b0:	55                   	push   %ebp
  8009b1:	89 e5                	mov    %esp,%ebp
  8009b3:	53                   	push   %ebx
  8009b4:	8b 45 08             	mov    0x8(%ebp),%eax
  8009b7:	8b 55 0c             	mov    0xc(%ebp),%edx
  8009ba:	89 c3                	mov    %eax,%ebx
  8009bc:	03 5d 10             	add    0x10(%ebp),%ebx
	while (n > 0 && *p && *p == *q)
  8009bf:	eb 06                	jmp    8009c7 <strncmp+0x17>
		n--, p++, q++;
  8009c1:	83 c0 01             	add    $0x1,%eax
  8009c4:	83 c2 01             	add    $0x1,%edx
}

int
strncmp(const char *p, const char *q, size_t n)
{
	while (n > 0 && *p && *p == *q)
  8009c7:	39 d8                	cmp    %ebx,%eax
  8009c9:	74 15                	je     8009e0 <strncmp+0x30>
  8009cb:	0f b6 08             	movzbl (%eax),%ecx
  8009ce:	84 c9                	test   %cl,%cl
  8009d0:	74 04                	je     8009d6 <strncmp+0x26>
  8009d2:	3a 0a                	cmp    (%edx),%cl
  8009d4:	74 eb                	je     8009c1 <strncmp+0x11>
		n--, p++, q++;
	if (n == 0)
		return 0;
	else
		return (int) ((unsigned char) *p - (unsigned char) *q);
  8009d6:	0f b6 00             	movzbl (%eax),%eax
  8009d9:	0f b6 12             	movzbl (%edx),%edx
  8009dc:	29 d0                	sub    %edx,%eax
  8009de:	eb 05                	jmp    8009e5 <strncmp+0x35>
strncmp(const char *p, const char *q, size_t n)
{
	while (n > 0 && *p && *p == *q)
		n--, p++, q++;
	if (n == 0)
		return 0;
  8009e0:	b8 00 00 00 00       	mov    $0x0,%eax
	else
		return (int) ((unsigned char) *p - (unsigned char) *q);
}
  8009e5:	5b                   	pop    %ebx
  8009e6:	5d                   	pop    %ebp
  8009e7:	c3                   	ret    

008009e8 <strchr>:

// Return a pointer to the first occurrence of 'c' in 's',
// or a null pointer if the string has no 'c'.
char *
strchr(const char *s, char c)
{
  8009e8:	55                   	push   %ebp
  8009e9:	89 e5                	mov    %esp,%ebp
  8009eb:	8b 45 08             	mov    0x8(%ebp),%eax
  8009ee:	0f b6 4d 0c          	movzbl 0xc(%ebp),%ecx
	for (; *s; s++)
  8009f2:	eb 07                	jmp    8009fb <strchr+0x13>
		if (*s == c)
  8009f4:	38 ca                	cmp    %cl,%dl
  8009f6:	74 0f                	je     800a07 <strchr+0x1f>
// Return a pointer to the first occurrence of 'c' in 's',
// or a null pointer if the string has no 'c'.
char *
strchr(const char *s, char c)
{
	for (; *s; s++)
  8009f8:	83 c0 01             	add    $0x1,%eax
  8009fb:	0f b6 10             	movzbl (%eax),%edx
  8009fe:	84 d2                	test   %dl,%dl
  800a00:	75 f2                	jne    8009f4 <strchr+0xc>
		if (*s == c)
			return (char *) s;
	return 0;
  800a02:	b8 00 00 00 00       	mov    $0x0,%eax
}
  800a07:	5d                   	pop    %ebp
  800a08:	c3                   	ret    

00800a09 <strfind>:

// Return a pointer to the first occurrence of 'c' in 's',
// or a pointer to the string-ending null character if the string has no 'c'.
char *
strfind(const char *s, char c)
{
  800a09:	55                   	push   %ebp
  800a0a:	89 e5                	mov    %esp,%ebp
  800a0c:	8b 45 08             	mov    0x8(%ebp),%eax
  800a0f:	0f b6 4d 0c          	movzbl 0xc(%ebp),%ecx
	for (; *s; s++)
  800a13:	eb 03                	jmp    800a18 <strfind+0xf>
  800a15:	83 c0 01             	add    $0x1,%eax
  800a18:	0f b6 10             	movzbl (%eax),%edx
		if (*s == c)
  800a1b:	38 ca                	cmp    %cl,%dl
  800a1d:	74 04                	je     800a23 <strfind+0x1a>
  800a1f:	84 d2                	test   %dl,%dl
  800a21:	75 f2                	jne    800a15 <strfind+0xc>
			break;
	return (char *) s;
}
  800a23:	5d                   	pop    %ebp
  800a24:	c3                   	ret    

00800a25 <memset>:

#if ASM
void *
memset(void *v, int c, size_t n)
{
  800a25:	55                   	push   %ebp
  800a26:	89 e5                	mov    %esp,%ebp
  800a28:	57                   	push   %edi
  800a29:	56                   	push   %esi
  800a2a:	53                   	push   %ebx
  800a2b:	8b 55 08             	mov    0x8(%ebp),%edx
  800a2e:	8b 4d 10             	mov    0x10(%ebp),%ecx
	char *p = v;

	if (n == 0)
  800a31:	85 c9                	test   %ecx,%ecx
  800a33:	74 37                	je     800a6c <memset+0x47>
		return v;
	if ((int)v%4 == 0 && n%4 == 0) {
  800a35:	f6 c2 03             	test   $0x3,%dl
  800a38:	75 2a                	jne    800a64 <memset+0x3f>
  800a3a:	f6 c1 03             	test   $0x3,%cl
  800a3d:	75 25                	jne    800a64 <memset+0x3f>
		c &= 0xFF;
  800a3f:	0f b6 5d 0c          	movzbl 0xc(%ebp),%ebx
		c = (c<<24)|(c<<16)|(c<<8)|c;
  800a43:	89 df                	mov    %ebx,%edi
  800a45:	c1 e7 08             	shl    $0x8,%edi
  800a48:	89 de                	mov    %ebx,%esi
  800a4a:	c1 e6 18             	shl    $0x18,%esi
  800a4d:	89 d8                	mov    %ebx,%eax
  800a4f:	c1 e0 10             	shl    $0x10,%eax
  800a52:	09 f0                	or     %esi,%eax
  800a54:	09 c3                	or     %eax,%ebx
		asm volatile("cld; rep stosl\n"
			: "=D" (p), "=c" (n)
			: "D" (p), "a" (c), "c" (n/4)
  800a56:	c1 e9 02             	shr    $0x2,%ecx
	if (n == 0)
		return v;
	if ((int)v%4 == 0 && n%4 == 0) {
		c &= 0xFF;
		c = (c<<24)|(c<<16)|(c<<8)|c;
		asm volatile("cld; rep stosl\n"
  800a59:	89 f8                	mov    %edi,%eax
  800a5b:	09 d8                	or     %ebx,%eax
  800a5d:	89 d7                	mov    %edx,%edi
  800a5f:	fc                   	cld    
  800a60:	f3 ab                	rep stos %eax,%es:(%edi)
  800a62:	eb 08                	jmp    800a6c <memset+0x47>
			: "=D" (p), "=c" (n)
			: "D" (p), "a" (c), "c" (n/4)
			: "cc", "memory");
	} else
		asm volatile("cld; rep stosb\n"
  800a64:	89 d7                	mov    %edx,%edi
  800a66:	8b 45 0c             	mov    0xc(%ebp),%eax
  800a69:	fc                   	cld    
  800a6a:	f3 aa                	rep stos %al,%es:(%edi)
			: "=D" (p), "=c" (n)
			: "0" (p), "a" (c), "1" (n)
			: "cc", "memory");
	return v;
}
  800a6c:	89 d0                	mov    %edx,%eax
  800a6e:	5b                   	pop    %ebx
  800a6f:	5e                   	pop    %esi
  800a70:	5f                   	pop    %edi
  800a71:	5d                   	pop    %ebp
  800a72:	c3                   	ret    

00800a73 <memmove>:

void *
memmove(void *dst, const void *src, size_t n)
{
  800a73:	55                   	push   %ebp
  800a74:	89 e5                	mov    %esp,%ebp
  800a76:	57                   	push   %edi
  800a77:	56                   	push   %esi
  800a78:	8b 45 08             	mov    0x8(%ebp),%eax
  800a7b:	8b 75 0c             	mov    0xc(%ebp),%esi
  800a7e:	8b 4d 10             	mov    0x10(%ebp),%ecx
	const char *s;
	char *d;

	s = src;
	d = dst;
	if (s < d && s + n > d) {
  800a81:	39 c6                	cmp    %eax,%esi
  800a83:	73 35                	jae    800aba <memmove+0x47>
  800a85:	8d 14 0e             	lea    (%esi,%ecx,1),%edx
  800a88:	39 d0                	cmp    %edx,%eax
  800a8a:	73 2e                	jae    800aba <memmove+0x47>
		s += n;
		d += n;
  800a8c:	8d 3c 08             	lea    (%eax,%ecx,1),%edi
		if ((int)s%4 == 0 && (int)d%4 == 0 && n%4 == 0)
  800a8f:	89 d6                	mov    %edx,%esi
  800a91:	09 fe                	or     %edi,%esi
  800a93:	f7 c6 03 00 00 00    	test   $0x3,%esi
  800a99:	75 13                	jne    800aae <memmove+0x3b>
  800a9b:	f6 c1 03             	test   $0x3,%cl
  800a9e:	75 0e                	jne    800aae <memmove+0x3b>
			asm volatile("std; rep movsl\n"
  800aa0:	83 ef 04             	sub    $0x4,%edi
  800aa3:	8d 72 fc             	lea    -0x4(%edx),%esi
  800aa6:	c1 e9 02             	shr    $0x2,%ecx
  800aa9:	fd                   	std    
  800aaa:	f3 a5                	rep movsl %ds:(%esi),%es:(%edi)
  800aac:	eb 09                	jmp    800ab7 <memmove+0x44>
				:: "D" (d-4), "S" (s-4), "c" (n/4) : "cc", "memory");
		else
			asm volatile("std; rep movsb\n"
  800aae:	83 ef 01             	sub    $0x1,%edi
  800ab1:	8d 72 ff             	lea    -0x1(%edx),%esi
  800ab4:	fd                   	std    
  800ab5:	f3 a4                	rep movsb %ds:(%esi),%es:(%edi)
				:: "D" (d-1), "S" (s-1), "c" (n) : "cc", "memory");
		// Some versions of GCC rely on DF being clear
		asm volatile("cld" ::: "cc");
  800ab7:	fc                   	cld    
  800ab8:	eb 1d                	jmp    800ad7 <memmove+0x64>
	} else {
		if ((int)s%4 == 0 && (int)d%4 == 0 && n%4 == 0)
  800aba:	89 f2                	mov    %esi,%edx
  800abc:	09 c2                	or     %eax,%edx
  800abe:	f6 c2 03             	test   $0x3,%dl
  800ac1:	75 0f                	jne    800ad2 <memmove+0x5f>
  800ac3:	f6 c1 03             	test   $0x3,%cl
  800ac6:	75 0a                	jne    800ad2 <memmove+0x5f>
			asm volatile("cld; rep movsl\n"
  800ac8:	c1 e9 02             	shr    $0x2,%ecx
  800acb:	89 c7                	mov    %eax,%edi
  800acd:	fc                   	cld    
  800ace:	f3 a5                	rep movsl %ds:(%esi),%es:(%edi)
  800ad0:	eb 05                	jmp    800ad7 <memmove+0x64>
				:: "D" (d), "S" (s), "c" (n/4) : "cc", "memory");
		else
			asm volatile("cld; rep movsb\n"
  800ad2:	89 c7                	mov    %eax,%edi
  800ad4:	fc                   	cld    
  800ad5:	f3 a4                	rep movsb %ds:(%esi),%es:(%edi)
				:: "D" (d), "S" (s), "c" (n) : "cc", "memory");
	}
	return dst;
}
  800ad7:	5e                   	pop    %esi
  800ad8:	5f                   	pop    %edi
  800ad9:	5d                   	pop    %ebp
  800ada:	c3                   	ret    

00800adb <memcpy>:
}
#endif

void *
memcpy(void *dst, const void *src, size_t n)
{
  800adb:	55                   	push   %ebp
  800adc:	89 e5                	mov    %esp,%ebp
	return memmove(dst, src, n);
  800ade:	ff 75 10             	pushl  0x10(%ebp)
  800ae1:	ff 75 0c             	pushl  0xc(%ebp)
  800ae4:	ff 75 08             	pushl  0x8(%ebp)
  800ae7:	e8 87 ff ff ff       	call   800a73 <memmove>
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
  800af3:	8b 45 08             	mov    0x8(%ebp),%eax
  800af6:	8b 55 0c             	mov    0xc(%ebp),%edx
  800af9:	89 c6                	mov    %eax,%esi
  800afb:	03 75 10             	add    0x10(%ebp),%esi
	const uint8_t *s1 = (const uint8_t *) v1;
	const uint8_t *s2 = (const uint8_t *) v2;

	while (n-- > 0) {
  800afe:	eb 1a                	jmp    800b1a <memcmp+0x2c>
		if (*s1 != *s2)
  800b00:	0f b6 08             	movzbl (%eax),%ecx
  800b03:	0f b6 1a             	movzbl (%edx),%ebx
  800b06:	38 d9                	cmp    %bl,%cl
  800b08:	74 0a                	je     800b14 <memcmp+0x26>
			return (int) *s1 - (int) *s2;
  800b0a:	0f b6 c1             	movzbl %cl,%eax
  800b0d:	0f b6 db             	movzbl %bl,%ebx
  800b10:	29 d8                	sub    %ebx,%eax
  800b12:	eb 0f                	jmp    800b23 <memcmp+0x35>
		s1++, s2++;
  800b14:	83 c0 01             	add    $0x1,%eax
  800b17:	83 c2 01             	add    $0x1,%edx
memcmp(const void *v1, const void *v2, size_t n)
{
	const uint8_t *s1 = (const uint8_t *) v1;
	const uint8_t *s2 = (const uint8_t *) v2;

	while (n-- > 0) {
  800b1a:	39 f0                	cmp    %esi,%eax
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
  800b4a:	8b 4d 08             	mov    0x8(%ebp),%ecx
  800b4d:	8b 5d 10             	mov    0x10(%ebp),%ebx
	int neg = 0;
	long val = 0;

	// gobble initial whitespace
	while (*s == ' ' || *s == '\t')
  800b50:	eb 03                	jmp    800b55 <strtol+0x11>
		s++;
  800b52:	83 c1 01             	add    $0x1,%ecx
{
	int neg = 0;
	long val = 0;

	// gobble initial whitespace
	while (*s == ' ' || *s == '\t')
  800b55:	0f b6 01             	movzbl (%ecx),%eax
  800b58:	3c 20                	cmp    $0x20,%al
  800b5a:	74 f6                	je     800b52 <strtol+0xe>
  800b5c:	3c 09                	cmp    $0x9,%al
  800b5e:	74 f2                	je     800b52 <strtol+0xe>
		s++;

	// plus/minus sign
	if (*s == '+')
  800b60:	3c 2b                	cmp    $0x2b,%al
  800b62:	75 0a                	jne    800b6e <strtol+0x2a>
		s++;
  800b64:	83 c1 01             	add    $0x1,%ecx
}

long
strtol(const char *s, char **endptr, int base)
{
	int neg = 0;
  800b67:	bf 00 00 00 00       	mov    $0x0,%edi
  800b6c:	eb 11                	jmp    800b7f <strtol+0x3b>
  800b6e:	bf 00 00 00 00       	mov    $0x0,%edi
		s++;

	// plus/minus sign
	if (*s == '+')
		s++;
	else if (*s == '-')
  800b73:	3c 2d                	cmp    $0x2d,%al
  800b75:	75 08                	jne    800b7f <strtol+0x3b>
		s++, neg = 1;
  800b77:	83 c1 01             	add    $0x1,%ecx
  800b7a:	bf 01 00 00 00       	mov    $0x1,%edi

	// hex or octal base prefix
	if ((base == 0 || base == 16) && (s[0] == '0' && s[1] == 'x'))
  800b7f:	f7 c3 ef ff ff ff    	test   $0xffffffef,%ebx
  800b85:	75 15                	jne    800b9c <strtol+0x58>
  800b87:	80 39 30             	cmpb   $0x30,(%ecx)
  800b8a:	75 10                	jne    800b9c <strtol+0x58>
  800b8c:	80 79 01 78          	cmpb   $0x78,0x1(%ecx)
  800b90:	75 7c                	jne    800c0e <strtol+0xca>
		s += 2, base = 16;
  800b92:	83 c1 02             	add    $0x2,%ecx
  800b95:	bb 10 00 00 00       	mov    $0x10,%ebx
  800b9a:	eb 16                	jmp    800bb2 <strtol+0x6e>
	else if (base == 0 && s[0] == '0')
  800b9c:	85 db                	test   %ebx,%ebx
  800b9e:	75 12                	jne    800bb2 <strtol+0x6e>
		s++, base = 8;
	else if (base == 0)
		base = 10;
  800ba0:	bb 0a 00 00 00       	mov    $0xa,%ebx
		s++, neg = 1;

	// hex or octal base prefix
	if ((base == 0 || base == 16) && (s[0] == '0' && s[1] == 'x'))
		s += 2, base = 16;
	else if (base == 0 && s[0] == '0')
  800ba5:	80 39 30             	cmpb   $0x30,(%ecx)
  800ba8:	75 08                	jne    800bb2 <strtol+0x6e>
		s++, base = 8;
  800baa:	83 c1 01             	add    $0x1,%ecx
  800bad:	bb 08 00 00 00       	mov    $0x8,%ebx
	else if (base == 0)
		base = 10;
  800bb2:	b8 00 00 00 00       	mov    $0x0,%eax
  800bb7:	89 5d 10             	mov    %ebx,0x10(%ebp)

	// digits
	while (1) {
		int dig;

		if (*s >= '0' && *s <= '9')
  800bba:	0f b6 11             	movzbl (%ecx),%edx
  800bbd:	8d 72 d0             	lea    -0x30(%edx),%esi
  800bc0:	89 f3                	mov    %esi,%ebx
  800bc2:	80 fb 09             	cmp    $0x9,%bl
  800bc5:	77 08                	ja     800bcf <strtol+0x8b>
			dig = *s - '0';
  800bc7:	0f be d2             	movsbl %dl,%edx
  800bca:	83 ea 30             	sub    $0x30,%edx
  800bcd:	eb 22                	jmp    800bf1 <strtol+0xad>
		else if (*s >= 'a' && *s <= 'z')
  800bcf:	8d 72 9f             	lea    -0x61(%edx),%esi
  800bd2:	89 f3                	mov    %esi,%ebx
  800bd4:	80 fb 19             	cmp    $0x19,%bl
  800bd7:	77 08                	ja     800be1 <strtol+0x9d>
			dig = *s - 'a' + 10;
  800bd9:	0f be d2             	movsbl %dl,%edx
  800bdc:	83 ea 57             	sub    $0x57,%edx
  800bdf:	eb 10                	jmp    800bf1 <strtol+0xad>
		else if (*s >= 'A' && *s <= 'Z')
  800be1:	8d 72 bf             	lea    -0x41(%edx),%esi
  800be4:	89 f3                	mov    %esi,%ebx
  800be6:	80 fb 19             	cmp    $0x19,%bl
  800be9:	77 16                	ja     800c01 <strtol+0xbd>
			dig = *s - 'A' + 10;
  800beb:	0f be d2             	movsbl %dl,%edx
  800bee:	83 ea 37             	sub    $0x37,%edx
		else
			break;
		if (dig >= base)
  800bf1:	3b 55 10             	cmp    0x10(%ebp),%edx
  800bf4:	7d 0b                	jge    800c01 <strtol+0xbd>
			break;
		s++, val = (val * base) + dig;
  800bf6:	83 c1 01             	add    $0x1,%ecx
  800bf9:	0f af 45 10          	imul   0x10(%ebp),%eax
  800bfd:	01 d0                	add    %edx,%eax
		// we don't properly detect overflow!
	}
  800bff:	eb b9                	jmp    800bba <strtol+0x76>

	if (endptr)
  800c01:	83 7d 0c 00          	cmpl   $0x0,0xc(%ebp)
  800c05:	74 0d                	je     800c14 <strtol+0xd0>
		*endptr = (char *) s;
  800c07:	8b 75 0c             	mov    0xc(%ebp),%esi
  800c0a:	89 0e                	mov    %ecx,(%esi)
  800c0c:	eb 06                	jmp    800c14 <strtol+0xd0>
		s++, neg = 1;

	// hex or octal base prefix
	if ((base == 0 || base == 16) && (s[0] == '0' && s[1] == 'x'))
		s += 2, base = 16;
	else if (base == 0 && s[0] == '0')
  800c0e:	85 db                	test   %ebx,%ebx
  800c10:	74 98                	je     800baa <strtol+0x66>
  800c12:	eb 9e                	jmp    800bb2 <strtol+0x6e>
		// we don't properly detect overflow!
	}

	if (endptr)
		*endptr = (char *) s;
	return (neg ? -val : val);
  800c14:	89 c2                	mov    %eax,%edx
  800c16:	f7 da                	neg    %edx
  800c18:	85 ff                	test   %edi,%edi
  800c1a:	0f 45 c2             	cmovne %edx,%eax
}
  800c1d:	5b                   	pop    %ebx
  800c1e:	5e                   	pop    %esi
  800c1f:	5f                   	pop    %edi
  800c20:	5d                   	pop    %ebp
  800c21:	c3                   	ret    
  800c22:	66 90                	xchg   %ax,%ax
  800c24:	66 90                	xchg   %ax,%ax
  800c26:	66 90                	xchg   %ax,%ax
  800c28:	66 90                	xchg   %ax,%ax
  800c2a:	66 90                	xchg   %ax,%ax
  800c2c:	66 90                	xchg   %ax,%ax
  800c2e:	66 90                	xchg   %ax,%ax

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
