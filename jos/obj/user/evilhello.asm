
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
  800040:	e8 ab 00 00 00       	call   8000f0 <sys_cputs>
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
  80004d:	56                   	push   %esi
  80004e:	53                   	push   %ebx
  80004f:	8b 5d 08             	mov    0x8(%ebp),%ebx
  800052:	8b 75 0c             	mov    0xc(%ebp),%esi
	// set thisenv to point at our Env structure in envs[].
	// LAB 3: Your code here.
	envid_t id = sys_getenvid();
  800055:	e8 02 01 00 00       	call   80015c <sys_getenvid>
	if (id >= 0)
  80005a:	85 c0                	test   %eax,%eax
  80005c:	78 12                	js     800070 <libmain+0x26>
		thisenv = &envs[ENVX(id)];
  80005e:	25 ff 03 00 00       	and    $0x3ff,%eax
  800063:	6b c0 7c             	imul   $0x7c,%eax,%eax
  800066:	05 00 00 c0 ee       	add    $0xeec00000,%eax
  80006b:	a3 04 20 80 00       	mov    %eax,0x802004

	// save the name of the program so that panic() can use it
	if (argc > 0)
  800070:	85 db                	test   %ebx,%ebx
  800072:	7e 07                	jle    80007b <libmain+0x31>
		binaryname = argv[0];
  800074:	8b 06                	mov    (%esi),%eax
  800076:	a3 00 20 80 00       	mov    %eax,0x802000

	// call user main routine
	umain(argc, argv);
  80007b:	83 ec 08             	sub    $0x8,%esp
  80007e:	56                   	push   %esi
  80007f:	53                   	push   %ebx
  800080:	e8 ae ff ff ff       	call   800033 <umain>

	// exit gracefully
	exit();
  800085:	e8 0a 00 00 00       	call   800094 <exit>
}
  80008a:	83 c4 10             	add    $0x10,%esp
  80008d:	8d 65 f8             	lea    -0x8(%ebp),%esp
  800090:	5b                   	pop    %ebx
  800091:	5e                   	pop    %esi
  800092:	5d                   	pop    %ebp
  800093:	c3                   	ret    

00800094 <exit>:

#include <inc/lib.h>

void
exit(void)
{
  800094:	55                   	push   %ebp
  800095:	89 e5                	mov    %esp,%ebp
  800097:	83 ec 14             	sub    $0x14,%esp
	sys_env_destroy(0);
  80009a:	6a 00                	push   $0x0
  80009c:	e8 99 00 00 00       	call   80013a <sys_env_destroy>
}
  8000a1:	83 c4 10             	add    $0x10,%esp
  8000a4:	c9                   	leave  
  8000a5:	c3                   	ret    

008000a6 <syscall>:
#include <inc/syscall.h>
#include <inc/lib.h>

static inline int32_t
syscall(int num, int check, uint32_t a1, uint32_t a2, uint32_t a3, uint32_t a4, uint32_t a5)
{
  8000a6:	55                   	push   %ebp
  8000a7:	89 e5                	mov    %esp,%ebp
  8000a9:	57                   	push   %edi
  8000aa:	56                   	push   %esi
  8000ab:	53                   	push   %ebx
  8000ac:	83 ec 1c             	sub    $0x1c,%esp
  8000af:	89 45 e0             	mov    %eax,-0x20(%ebp)
  8000b2:	89 55 e4             	mov    %edx,-0x1c(%ebp)
  8000b5:	89 ca                	mov    %ecx,%edx
	//
	// The last clause tells the assembler that this can
	// potentially change the condition codes and arbitrary
	// memory locations.

	asm volatile("int %1\n"
  8000b7:	8b 4d 08             	mov    0x8(%ebp),%ecx
  8000ba:	8b 5d 0c             	mov    0xc(%ebp),%ebx
  8000bd:	8b 7d 10             	mov    0x10(%ebp),%edi
  8000c0:	8b 75 14             	mov    0x14(%ebp),%esi
  8000c3:	cd 30                	int    $0x30
		       "b" (a3),
		       "D" (a4),
		       "S" (a5)
		     : "cc", "memory");

	if(check && ret > 0)
  8000c5:	83 7d e4 00          	cmpl   $0x0,-0x1c(%ebp)
  8000c9:	74 1d                	je     8000e8 <syscall+0x42>
  8000cb:	85 c0                	test   %eax,%eax
  8000cd:	7e 19                	jle    8000e8 <syscall+0x42>
  8000cf:	8b 55 e0             	mov    -0x20(%ebp),%edx
		panic("syscall %d returned %d (> 0)", num, ret);
  8000d2:	83 ec 0c             	sub    $0xc,%esp
  8000d5:	50                   	push   %eax
  8000d6:	52                   	push   %edx
  8000d7:	68 ca 0e 80 00       	push   $0x800eca
  8000dc:	6a 23                	push   $0x23
  8000de:	68 e7 0e 80 00       	push   $0x800ee7
  8000e3:	e8 b9 01 00 00       	call   8002a1 <_panic>

	return ret;
}
  8000e8:	8d 65 f4             	lea    -0xc(%ebp),%esp
  8000eb:	5b                   	pop    %ebx
  8000ec:	5e                   	pop    %esi
  8000ed:	5f                   	pop    %edi
  8000ee:	5d                   	pop    %ebp
  8000ef:	c3                   	ret    

008000f0 <sys_cputs>:

void
sys_cputs(const char *s, size_t len)
{
  8000f0:	55                   	push   %ebp
  8000f1:	89 e5                	mov    %esp,%ebp
  8000f3:	83 ec 08             	sub    $0x8,%esp
	syscall(SYS_cputs, 0, (uint32_t)s, len, 0, 0, 0);
  8000f6:	6a 00                	push   $0x0
  8000f8:	6a 00                	push   $0x0
  8000fa:	6a 00                	push   $0x0
  8000fc:	ff 75 0c             	pushl  0xc(%ebp)
  8000ff:	8b 4d 08             	mov    0x8(%ebp),%ecx
  800102:	ba 00 00 00 00       	mov    $0x0,%edx
  800107:	b8 00 00 00 00       	mov    $0x0,%eax
  80010c:	e8 95 ff ff ff       	call   8000a6 <syscall>
}
  800111:	83 c4 10             	add    $0x10,%esp
  800114:	c9                   	leave  
  800115:	c3                   	ret    

00800116 <sys_cgetc>:

int
sys_cgetc(void)
{
  800116:	55                   	push   %ebp
  800117:	89 e5                	mov    %esp,%ebp
  800119:	83 ec 08             	sub    $0x8,%esp
	return syscall(SYS_cgetc, 0, 0, 0, 0, 0, 0);
  80011c:	6a 00                	push   $0x0
  80011e:	6a 00                	push   $0x0
  800120:	6a 00                	push   $0x0
  800122:	6a 00                	push   $0x0
  800124:	b9 00 00 00 00       	mov    $0x0,%ecx
  800129:	ba 00 00 00 00       	mov    $0x0,%edx
  80012e:	b8 01 00 00 00       	mov    $0x1,%eax
  800133:	e8 6e ff ff ff       	call   8000a6 <syscall>
}
  800138:	c9                   	leave  
  800139:	c3                   	ret    

0080013a <sys_env_destroy>:

int
sys_env_destroy(envid_t envid)
{
  80013a:	55                   	push   %ebp
  80013b:	89 e5                	mov    %esp,%ebp
  80013d:	83 ec 08             	sub    $0x8,%esp
	return syscall(SYS_env_destroy, 1, envid, 0, 0, 0, 0);
  800140:	6a 00                	push   $0x0
  800142:	6a 00                	push   $0x0
  800144:	6a 00                	push   $0x0
  800146:	6a 00                	push   $0x0
  800148:	8b 4d 08             	mov    0x8(%ebp),%ecx
  80014b:	ba 01 00 00 00       	mov    $0x1,%edx
  800150:	b8 03 00 00 00       	mov    $0x3,%eax
  800155:	e8 4c ff ff ff       	call   8000a6 <syscall>
}
  80015a:	c9                   	leave  
  80015b:	c3                   	ret    

0080015c <sys_getenvid>:

envid_t
sys_getenvid(void)
{
  80015c:	55                   	push   %ebp
  80015d:	89 e5                	mov    %esp,%ebp
  80015f:	83 ec 08             	sub    $0x8,%esp
	 return syscall(SYS_getenvid, 0, 0, 0, 0, 0, 0);
  800162:	6a 00                	push   $0x0
  800164:	6a 00                	push   $0x0
  800166:	6a 00                	push   $0x0
  800168:	6a 00                	push   $0x0
  80016a:	b9 00 00 00 00       	mov    $0x0,%ecx
  80016f:	ba 00 00 00 00       	mov    $0x0,%edx
  800174:	b8 02 00 00 00       	mov    $0x2,%eax
  800179:	e8 28 ff ff ff       	call   8000a6 <syscall>
}
  80017e:	c9                   	leave  
  80017f:	c3                   	ret    

00800180 <sys_yield>:

void
sys_yield(void)
{
  800180:	55                   	push   %ebp
  800181:	89 e5                	mov    %esp,%ebp
  800183:	83 ec 08             	sub    $0x8,%esp
	syscall(SYS_yield, 0, 0, 0, 0, 0, 0);
  800186:	6a 00                	push   $0x0
  800188:	6a 00                	push   $0x0
  80018a:	6a 00                	push   $0x0
  80018c:	6a 00                	push   $0x0
  80018e:	b9 00 00 00 00       	mov    $0x0,%ecx
  800193:	ba 00 00 00 00       	mov    $0x0,%edx
  800198:	b8 0a 00 00 00       	mov    $0xa,%eax
  80019d:	e8 04 ff ff ff       	call   8000a6 <syscall>
}
  8001a2:	83 c4 10             	add    $0x10,%esp
  8001a5:	c9                   	leave  
  8001a6:	c3                   	ret    

008001a7 <sys_page_alloc>:

int
sys_page_alloc(envid_t envid, void *va, int perm)
{
  8001a7:	55                   	push   %ebp
  8001a8:	89 e5                	mov    %esp,%ebp
  8001aa:	83 ec 08             	sub    $0x8,%esp
	return syscall(SYS_page_alloc, 1, envid, (uint32_t) va, perm, 0, 0);
  8001ad:	6a 00                	push   $0x0
  8001af:	6a 00                	push   $0x0
  8001b1:	ff 75 10             	pushl  0x10(%ebp)
  8001b4:	ff 75 0c             	pushl  0xc(%ebp)
  8001b7:	8b 4d 08             	mov    0x8(%ebp),%ecx
  8001ba:	ba 01 00 00 00       	mov    $0x1,%edx
  8001bf:	b8 04 00 00 00       	mov    $0x4,%eax
  8001c4:	e8 dd fe ff ff       	call   8000a6 <syscall>
}
  8001c9:	c9                   	leave  
  8001ca:	c3                   	ret    

008001cb <sys_page_map>:

int
sys_page_map(envid_t srcenv, void *srcva, envid_t dstenv, void *dstva, int perm)
{
  8001cb:	55                   	push   %ebp
  8001cc:	89 e5                	mov    %esp,%ebp
  8001ce:	83 ec 08             	sub    $0x8,%esp
	return syscall(SYS_page_map, 1, srcenv, (uint32_t) srcva, dstenv, (uint32_t) dstva, perm);
  8001d1:	ff 75 18             	pushl  0x18(%ebp)
  8001d4:	ff 75 14             	pushl  0x14(%ebp)
  8001d7:	ff 75 10             	pushl  0x10(%ebp)
  8001da:	ff 75 0c             	pushl  0xc(%ebp)
  8001dd:	8b 4d 08             	mov    0x8(%ebp),%ecx
  8001e0:	ba 01 00 00 00       	mov    $0x1,%edx
  8001e5:	b8 05 00 00 00       	mov    $0x5,%eax
  8001ea:	e8 b7 fe ff ff       	call   8000a6 <syscall>
}
  8001ef:	c9                   	leave  
  8001f0:	c3                   	ret    

008001f1 <sys_page_unmap>:

int
sys_page_unmap(envid_t envid, void *va)
{
  8001f1:	55                   	push   %ebp
  8001f2:	89 e5                	mov    %esp,%ebp
  8001f4:	83 ec 08             	sub    $0x8,%esp
	return syscall(SYS_page_unmap, 1, envid, (uint32_t) va, 0, 0, 0);
  8001f7:	6a 00                	push   $0x0
  8001f9:	6a 00                	push   $0x0
  8001fb:	6a 00                	push   $0x0
  8001fd:	ff 75 0c             	pushl  0xc(%ebp)
  800200:	8b 4d 08             	mov    0x8(%ebp),%ecx
  800203:	ba 01 00 00 00       	mov    $0x1,%edx
  800208:	b8 06 00 00 00       	mov    $0x6,%eax
  80020d:	e8 94 fe ff ff       	call   8000a6 <syscall>
}
  800212:	c9                   	leave  
  800213:	c3                   	ret    

00800214 <sys_env_set_status>:

// sys_exofork is inlined in lib.h

int
sys_env_set_status(envid_t envid, int status)
{
  800214:	55                   	push   %ebp
  800215:	89 e5                	mov    %esp,%ebp
  800217:	83 ec 08             	sub    $0x8,%esp
	return syscall(SYS_env_set_status, 1, envid, status, 0, 0, 0);
  80021a:	6a 00                	push   $0x0
  80021c:	6a 00                	push   $0x0
  80021e:	6a 00                	push   $0x0
  800220:	ff 75 0c             	pushl  0xc(%ebp)
  800223:	8b 4d 08             	mov    0x8(%ebp),%ecx
  800226:	ba 01 00 00 00       	mov    $0x1,%edx
  80022b:	b8 08 00 00 00       	mov    $0x8,%eax
  800230:	e8 71 fe ff ff       	call   8000a6 <syscall>
}
  800235:	c9                   	leave  
  800236:	c3                   	ret    

00800237 <sys_env_set_pgfault_upcall>:

int
sys_env_set_pgfault_upcall(envid_t envid, void *upcall)
{
  800237:	55                   	push   %ebp
  800238:	89 e5                	mov    %esp,%ebp
  80023a:	83 ec 08             	sub    $0x8,%esp
	return syscall(SYS_env_set_pgfault_upcall, 1, envid, (uint32_t) upcall, 0, 0, 0);
  80023d:	6a 00                	push   $0x0
  80023f:	6a 00                	push   $0x0
  800241:	6a 00                	push   $0x0
  800243:	ff 75 0c             	pushl  0xc(%ebp)
  800246:	8b 4d 08             	mov    0x8(%ebp),%ecx
  800249:	ba 01 00 00 00       	mov    $0x1,%edx
  80024e:	b8 09 00 00 00       	mov    $0x9,%eax
  800253:	e8 4e fe ff ff       	call   8000a6 <syscall>
}
  800258:	c9                   	leave  
  800259:	c3                   	ret    

0080025a <sys_ipc_try_send>:

int
sys_ipc_try_send(envid_t envid, uint32_t value, void *srcva, int perm)
{
  80025a:	55                   	push   %ebp
  80025b:	89 e5                	mov    %esp,%ebp
  80025d:	83 ec 08             	sub    $0x8,%esp
	return syscall(SYS_ipc_try_send, 0, envid, value, (uint32_t) srcva, perm, 0);
  800260:	6a 00                	push   $0x0
  800262:	ff 75 14             	pushl  0x14(%ebp)
  800265:	ff 75 10             	pushl  0x10(%ebp)
  800268:	ff 75 0c             	pushl  0xc(%ebp)
  80026b:	8b 4d 08             	mov    0x8(%ebp),%ecx
  80026e:	ba 00 00 00 00       	mov    $0x0,%edx
  800273:	b8 0b 00 00 00       	mov    $0xb,%eax
  800278:	e8 29 fe ff ff       	call   8000a6 <syscall>
}
  80027d:	c9                   	leave  
  80027e:	c3                   	ret    

0080027f <sys_ipc_recv>:

int
sys_ipc_recv(void *dstva)
{
  80027f:	55                   	push   %ebp
  800280:	89 e5                	mov    %esp,%ebp
  800282:	83 ec 08             	sub    $0x8,%esp
	return syscall(SYS_ipc_recv, 1, (uint32_t)dstva, 0, 0, 0, 0);
  800285:	6a 00                	push   $0x0
  800287:	6a 00                	push   $0x0
  800289:	6a 00                	push   $0x0
  80028b:	6a 00                	push   $0x0
  80028d:	8b 4d 08             	mov    0x8(%ebp),%ecx
  800290:	ba 01 00 00 00       	mov    $0x1,%edx
  800295:	b8 0c 00 00 00       	mov    $0xc,%eax
  80029a:	e8 07 fe ff ff       	call   8000a6 <syscall>
}
  80029f:	c9                   	leave  
  8002a0:	c3                   	ret    

008002a1 <_panic>:
 * It prints "panic: <message>", then causes a breakpoint exception,
 * which causes JOS to enter the JOS kernel monitor.
 */
void
_panic(const char *file, int line, const char *fmt, ...)
{
  8002a1:	55                   	push   %ebp
  8002a2:	89 e5                	mov    %esp,%ebp
  8002a4:	56                   	push   %esi
  8002a5:	53                   	push   %ebx
	va_list ap;

	va_start(ap, fmt);
  8002a6:	8d 5d 14             	lea    0x14(%ebp),%ebx

	// Print the panic message
	cprintf("[%08x] user panic in %s at %s:%d: ",
  8002a9:	8b 35 00 20 80 00    	mov    0x802000,%esi
  8002af:	e8 a8 fe ff ff       	call   80015c <sys_getenvid>
  8002b4:	83 ec 0c             	sub    $0xc,%esp
  8002b7:	ff 75 0c             	pushl  0xc(%ebp)
  8002ba:	ff 75 08             	pushl  0x8(%ebp)
  8002bd:	56                   	push   %esi
  8002be:	50                   	push   %eax
  8002bf:	68 f8 0e 80 00       	push   $0x800ef8
  8002c4:	e8 b1 00 00 00       	call   80037a <cprintf>
		sys_getenvid(), binaryname, file, line);
	vcprintf(fmt, ap);
  8002c9:	83 c4 18             	add    $0x18,%esp
  8002cc:	53                   	push   %ebx
  8002cd:	ff 75 10             	pushl  0x10(%ebp)
  8002d0:	e8 54 00 00 00       	call   800329 <vcprintf>
	cprintf("\n");
  8002d5:	c7 04 24 1c 0f 80 00 	movl   $0x800f1c,(%esp)
  8002dc:	e8 99 00 00 00       	call   80037a <cprintf>
  8002e1:	83 c4 10             	add    $0x10,%esp

	// Cause a breakpoint exception
	while (1)
		asm volatile("int3");
  8002e4:	cc                   	int3   
  8002e5:	eb fd                	jmp    8002e4 <_panic+0x43>

008002e7 <putch>:
};


static void
putch(int ch, struct printbuf *b)
{
  8002e7:	55                   	push   %ebp
  8002e8:	89 e5                	mov    %esp,%ebp
  8002ea:	53                   	push   %ebx
  8002eb:	83 ec 04             	sub    $0x4,%esp
  8002ee:	8b 5d 0c             	mov    0xc(%ebp),%ebx
	b->buf[b->idx++] = ch;
  8002f1:	8b 13                	mov    (%ebx),%edx
  8002f3:	8d 42 01             	lea    0x1(%edx),%eax
  8002f6:	89 03                	mov    %eax,(%ebx)
  8002f8:	8b 4d 08             	mov    0x8(%ebp),%ecx
  8002fb:	88 4c 13 08          	mov    %cl,0x8(%ebx,%edx,1)
	if (b->idx == 256-1) {
  8002ff:	3d ff 00 00 00       	cmp    $0xff,%eax
  800304:	75 1a                	jne    800320 <putch+0x39>
		sys_cputs(b->buf, b->idx);
  800306:	83 ec 08             	sub    $0x8,%esp
  800309:	68 ff 00 00 00       	push   $0xff
  80030e:	8d 43 08             	lea    0x8(%ebx),%eax
  800311:	50                   	push   %eax
  800312:	e8 d9 fd ff ff       	call   8000f0 <sys_cputs>
		b->idx = 0;
  800317:	c7 03 00 00 00 00    	movl   $0x0,(%ebx)
  80031d:	83 c4 10             	add    $0x10,%esp
	}
	b->cnt++;
  800320:	83 43 04 01          	addl   $0x1,0x4(%ebx)
}
  800324:	8b 5d fc             	mov    -0x4(%ebp),%ebx
  800327:	c9                   	leave  
  800328:	c3                   	ret    

00800329 <vcprintf>:

int
vcprintf(const char *fmt, va_list ap)
{
  800329:	55                   	push   %ebp
  80032a:	89 e5                	mov    %esp,%ebp
  80032c:	81 ec 18 01 00 00    	sub    $0x118,%esp
	struct printbuf b;

	b.idx = 0;
  800332:	c7 85 f0 fe ff ff 00 	movl   $0x0,-0x110(%ebp)
  800339:	00 00 00 
	b.cnt = 0;
  80033c:	c7 85 f4 fe ff ff 00 	movl   $0x0,-0x10c(%ebp)
  800343:	00 00 00 
	vprintfmt((void*)putch, &b, fmt, ap);
  800346:	ff 75 0c             	pushl  0xc(%ebp)
  800349:	ff 75 08             	pushl  0x8(%ebp)
  80034c:	8d 85 f0 fe ff ff    	lea    -0x110(%ebp),%eax
  800352:	50                   	push   %eax
  800353:	68 e7 02 80 00       	push   $0x8002e7
  800358:	e8 86 01 00 00       	call   8004e3 <vprintfmt>
	sys_cputs(b.buf, b.idx);
  80035d:	83 c4 08             	add    $0x8,%esp
  800360:	ff b5 f0 fe ff ff    	pushl  -0x110(%ebp)
  800366:	8d 85 f8 fe ff ff    	lea    -0x108(%ebp),%eax
  80036c:	50                   	push   %eax
  80036d:	e8 7e fd ff ff       	call   8000f0 <sys_cputs>

	return b.cnt;
}
  800372:	8b 85 f4 fe ff ff    	mov    -0x10c(%ebp),%eax
  800378:	c9                   	leave  
  800379:	c3                   	ret    

0080037a <cprintf>:

int
cprintf(const char *fmt, ...)
{
  80037a:	55                   	push   %ebp
  80037b:	89 e5                	mov    %esp,%ebp
  80037d:	83 ec 10             	sub    $0x10,%esp
	va_list ap;
	int cnt;

	va_start(ap, fmt);
  800380:	8d 45 0c             	lea    0xc(%ebp),%eax
	cnt = vcprintf(fmt, ap);
  800383:	50                   	push   %eax
  800384:	ff 75 08             	pushl  0x8(%ebp)
  800387:	e8 9d ff ff ff       	call   800329 <vcprintf>
	va_end(ap);

	return cnt;
}
  80038c:	c9                   	leave  
  80038d:	c3                   	ret    

0080038e <printnum>:
 * using specified putch function and associated pointer putdat.
 */
static void
printnum(void (*putch)(int, void*), void *putdat,
	 unsigned long long num, unsigned base, int width, int padc)
{
  80038e:	55                   	push   %ebp
  80038f:	89 e5                	mov    %esp,%ebp
  800391:	57                   	push   %edi
  800392:	56                   	push   %esi
  800393:	53                   	push   %ebx
  800394:	83 ec 1c             	sub    $0x1c,%esp
  800397:	89 c7                	mov    %eax,%edi
  800399:	89 d6                	mov    %edx,%esi
  80039b:	8b 45 08             	mov    0x8(%ebp),%eax
  80039e:	8b 55 0c             	mov    0xc(%ebp),%edx
  8003a1:	89 45 d8             	mov    %eax,-0x28(%ebp)
  8003a4:	89 55 dc             	mov    %edx,-0x24(%ebp)
	// first recursively print all preceding (more significant) digits
	if (num >= base) {
  8003a7:	8b 4d 10             	mov    0x10(%ebp),%ecx
  8003aa:	bb 00 00 00 00       	mov    $0x0,%ebx
  8003af:	89 4d e0             	mov    %ecx,-0x20(%ebp)
  8003b2:	89 5d e4             	mov    %ebx,-0x1c(%ebp)
  8003b5:	39 d3                	cmp    %edx,%ebx
  8003b7:	72 05                	jb     8003be <printnum+0x30>
  8003b9:	39 45 10             	cmp    %eax,0x10(%ebp)
  8003bc:	77 45                	ja     800403 <printnum+0x75>
		printnum(putch, putdat, num / base, base, width - 1, padc);
  8003be:	83 ec 0c             	sub    $0xc,%esp
  8003c1:	ff 75 18             	pushl  0x18(%ebp)
  8003c4:	8b 45 14             	mov    0x14(%ebp),%eax
  8003c7:	8d 58 ff             	lea    -0x1(%eax),%ebx
  8003ca:	53                   	push   %ebx
  8003cb:	ff 75 10             	pushl  0x10(%ebp)
  8003ce:	83 ec 08             	sub    $0x8,%esp
  8003d1:	ff 75 e4             	pushl  -0x1c(%ebp)
  8003d4:	ff 75 e0             	pushl  -0x20(%ebp)
  8003d7:	ff 75 dc             	pushl  -0x24(%ebp)
  8003da:	ff 75 d8             	pushl  -0x28(%ebp)
  8003dd:	e8 4e 08 00 00       	call   800c30 <__udivdi3>
  8003e2:	83 c4 18             	add    $0x18,%esp
  8003e5:	52                   	push   %edx
  8003e6:	50                   	push   %eax
  8003e7:	89 f2                	mov    %esi,%edx
  8003e9:	89 f8                	mov    %edi,%eax
  8003eb:	e8 9e ff ff ff       	call   80038e <printnum>
  8003f0:	83 c4 20             	add    $0x20,%esp
  8003f3:	eb 18                	jmp    80040d <printnum+0x7f>
	} else {
		// print any needed pad characters before first digit
		while (--width > 0)
			putch(padc, putdat);
  8003f5:	83 ec 08             	sub    $0x8,%esp
  8003f8:	56                   	push   %esi
  8003f9:	ff 75 18             	pushl  0x18(%ebp)
  8003fc:	ff d7                	call   *%edi
  8003fe:	83 c4 10             	add    $0x10,%esp
  800401:	eb 03                	jmp    800406 <printnum+0x78>
  800403:	8b 5d 14             	mov    0x14(%ebp),%ebx
	// first recursively print all preceding (more significant) digits
	if (num >= base) {
		printnum(putch, putdat, num / base, base, width - 1, padc);
	} else {
		// print any needed pad characters before first digit
		while (--width > 0)
  800406:	83 eb 01             	sub    $0x1,%ebx
  800409:	85 db                	test   %ebx,%ebx
  80040b:	7f e8                	jg     8003f5 <printnum+0x67>
			putch(padc, putdat);
	}

	// then print this (the least significant) digit
	putch("0123456789abcdef"[num % base], putdat);
  80040d:	83 ec 08             	sub    $0x8,%esp
  800410:	56                   	push   %esi
  800411:	83 ec 04             	sub    $0x4,%esp
  800414:	ff 75 e4             	pushl  -0x1c(%ebp)
  800417:	ff 75 e0             	pushl  -0x20(%ebp)
  80041a:	ff 75 dc             	pushl  -0x24(%ebp)
  80041d:	ff 75 d8             	pushl  -0x28(%ebp)
  800420:	e8 3b 09 00 00       	call   800d60 <__umoddi3>
  800425:	83 c4 14             	add    $0x14,%esp
  800428:	0f be 80 1e 0f 80 00 	movsbl 0x800f1e(%eax),%eax
  80042f:	50                   	push   %eax
  800430:	ff d7                	call   *%edi
}
  800432:	83 c4 10             	add    $0x10,%esp
  800435:	8d 65 f4             	lea    -0xc(%ebp),%esp
  800438:	5b                   	pop    %ebx
  800439:	5e                   	pop    %esi
  80043a:	5f                   	pop    %edi
  80043b:	5d                   	pop    %ebp
  80043c:	c3                   	ret    

0080043d <getuint>:

// Get an unsigned int of various possible sizes from a varargs list,
// depending on the lflag parameter.
static unsigned long long
getuint(va_list *ap, int lflag)
{
  80043d:	55                   	push   %ebp
  80043e:	89 e5                	mov    %esp,%ebp
	if (lflag >= 2)
  800440:	83 fa 01             	cmp    $0x1,%edx
  800443:	7e 0e                	jle    800453 <getuint+0x16>
		return va_arg(*ap, unsigned long long);
  800445:	8b 10                	mov    (%eax),%edx
  800447:	8d 4a 08             	lea    0x8(%edx),%ecx
  80044a:	89 08                	mov    %ecx,(%eax)
  80044c:	8b 02                	mov    (%edx),%eax
  80044e:	8b 52 04             	mov    0x4(%edx),%edx
  800451:	eb 22                	jmp    800475 <getuint+0x38>
	else if (lflag)
  800453:	85 d2                	test   %edx,%edx
  800455:	74 10                	je     800467 <getuint+0x2a>
		return va_arg(*ap, unsigned long);
  800457:	8b 10                	mov    (%eax),%edx
  800459:	8d 4a 04             	lea    0x4(%edx),%ecx
  80045c:	89 08                	mov    %ecx,(%eax)
  80045e:	8b 02                	mov    (%edx),%eax
  800460:	ba 00 00 00 00       	mov    $0x0,%edx
  800465:	eb 0e                	jmp    800475 <getuint+0x38>
	else
		return va_arg(*ap, unsigned int);
  800467:	8b 10                	mov    (%eax),%edx
  800469:	8d 4a 04             	lea    0x4(%edx),%ecx
  80046c:	89 08                	mov    %ecx,(%eax)
  80046e:	8b 02                	mov    (%edx),%eax
  800470:	ba 00 00 00 00       	mov    $0x0,%edx
}
  800475:	5d                   	pop    %ebp
  800476:	c3                   	ret    

00800477 <getint>:

// Same as getuint but signed - can't use getuint
// because of sign extension
static long long
getint(va_list *ap, int lflag)
{
  800477:	55                   	push   %ebp
  800478:	89 e5                	mov    %esp,%ebp
	if (lflag >= 2)
  80047a:	83 fa 01             	cmp    $0x1,%edx
  80047d:	7e 0e                	jle    80048d <getint+0x16>
		return va_arg(*ap, long long);
  80047f:	8b 10                	mov    (%eax),%edx
  800481:	8d 4a 08             	lea    0x8(%edx),%ecx
  800484:	89 08                	mov    %ecx,(%eax)
  800486:	8b 02                	mov    (%edx),%eax
  800488:	8b 52 04             	mov    0x4(%edx),%edx
  80048b:	eb 1a                	jmp    8004a7 <getint+0x30>
	else if (lflag)
  80048d:	85 d2                	test   %edx,%edx
  80048f:	74 0c                	je     80049d <getint+0x26>
		return va_arg(*ap, long);
  800491:	8b 10                	mov    (%eax),%edx
  800493:	8d 4a 04             	lea    0x4(%edx),%ecx
  800496:	89 08                	mov    %ecx,(%eax)
  800498:	8b 02                	mov    (%edx),%eax
  80049a:	99                   	cltd   
  80049b:	eb 0a                	jmp    8004a7 <getint+0x30>
	else
		return va_arg(*ap, int);
  80049d:	8b 10                	mov    (%eax),%edx
  80049f:	8d 4a 04             	lea    0x4(%edx),%ecx
  8004a2:	89 08                	mov    %ecx,(%eax)
  8004a4:	8b 02                	mov    (%edx),%eax
  8004a6:	99                   	cltd   
}
  8004a7:	5d                   	pop    %ebp
  8004a8:	c3                   	ret    

008004a9 <sprintputch>:
	int cnt;
};

static void
sprintputch(int ch, struct sprintbuf *b)
{
  8004a9:	55                   	push   %ebp
  8004aa:	89 e5                	mov    %esp,%ebp
  8004ac:	8b 45 0c             	mov    0xc(%ebp),%eax
	b->cnt++;
  8004af:	83 40 08 01          	addl   $0x1,0x8(%eax)
	if (b->buf < b->ebuf)
  8004b3:	8b 10                	mov    (%eax),%edx
  8004b5:	3b 50 04             	cmp    0x4(%eax),%edx
  8004b8:	73 0a                	jae    8004c4 <sprintputch+0x1b>
		*b->buf++ = ch;
  8004ba:	8d 4a 01             	lea    0x1(%edx),%ecx
  8004bd:	89 08                	mov    %ecx,(%eax)
  8004bf:	8b 45 08             	mov    0x8(%ebp),%eax
  8004c2:	88 02                	mov    %al,(%edx)
}
  8004c4:	5d                   	pop    %ebp
  8004c5:	c3                   	ret    

008004c6 <printfmt>:
	}
}

void
printfmt(void (*putch)(int, void*), void *putdat, const char *fmt, ...)
{
  8004c6:	55                   	push   %ebp
  8004c7:	89 e5                	mov    %esp,%ebp
  8004c9:	83 ec 08             	sub    $0x8,%esp
	va_list ap;

	va_start(ap, fmt);
  8004cc:	8d 45 14             	lea    0x14(%ebp),%eax
	vprintfmt(putch, putdat, fmt, ap);
  8004cf:	50                   	push   %eax
  8004d0:	ff 75 10             	pushl  0x10(%ebp)
  8004d3:	ff 75 0c             	pushl  0xc(%ebp)
  8004d6:	ff 75 08             	pushl  0x8(%ebp)
  8004d9:	e8 05 00 00 00       	call   8004e3 <vprintfmt>
	va_end(ap);
}
  8004de:	83 c4 10             	add    $0x10,%esp
  8004e1:	c9                   	leave  
  8004e2:	c3                   	ret    

008004e3 <vprintfmt>:
// Main function to format and print a string.
void printfmt(void (*putch)(int, void*), void *putdat, const char *fmt, ...);

void
vprintfmt(void (*putch)(int, void*), void *putdat, const char *fmt, va_list ap)
{
  8004e3:	55                   	push   %ebp
  8004e4:	89 e5                	mov    %esp,%ebp
  8004e6:	57                   	push   %edi
  8004e7:	56                   	push   %esi
  8004e8:	53                   	push   %ebx
  8004e9:	83 ec 2c             	sub    $0x2c,%esp
  8004ec:	8b 75 08             	mov    0x8(%ebp),%esi
  8004ef:	8b 5d 0c             	mov    0xc(%ebp),%ebx
  8004f2:	8b 7d 10             	mov    0x10(%ebp),%edi
  8004f5:	eb 12                	jmp    800509 <vprintfmt+0x26>
	int base, lflag, width, precision, altflag;
	char padc;

	while (1) {
		while ((ch = *(unsigned char *) fmt++) != '%') {
			if (ch == '\0')
  8004f7:	85 c0                	test   %eax,%eax
  8004f9:	0f 84 44 03 00 00    	je     800843 <vprintfmt+0x360>
				return;
			putch(ch, putdat);
  8004ff:	83 ec 08             	sub    $0x8,%esp
  800502:	53                   	push   %ebx
  800503:	50                   	push   %eax
  800504:	ff d6                	call   *%esi
  800506:	83 c4 10             	add    $0x10,%esp
	unsigned long long num;
	int base, lflag, width, precision, altflag;
	char padc;

	while (1) {
		while ((ch = *(unsigned char *) fmt++) != '%') {
  800509:	83 c7 01             	add    $0x1,%edi
  80050c:	0f b6 47 ff          	movzbl -0x1(%edi),%eax
  800510:	83 f8 25             	cmp    $0x25,%eax
  800513:	75 e2                	jne    8004f7 <vprintfmt+0x14>
  800515:	c6 45 d4 20          	movb   $0x20,-0x2c(%ebp)
  800519:	c7 45 d8 00 00 00 00 	movl   $0x0,-0x28(%ebp)
  800520:	c7 45 d0 ff ff ff ff 	movl   $0xffffffff,-0x30(%ebp)
  800527:	c7 45 e0 ff ff ff ff 	movl   $0xffffffff,-0x20(%ebp)
  80052e:	ba 00 00 00 00       	mov    $0x0,%edx
  800533:	eb 07                	jmp    80053c <vprintfmt+0x59>
		width = -1;
		precision = -1;
		lflag = 0;
		altflag = 0;
	reswitch:
		switch (ch = *(unsigned char *) fmt++) {
  800535:	8b 7d e4             	mov    -0x1c(%ebp),%edi

		// flag to pad on the right
		case '-':
			padc = '-';
  800538:	c6 45 d4 2d          	movb   $0x2d,-0x2c(%ebp)
		width = -1;
		precision = -1;
		lflag = 0;
		altflag = 0;
	reswitch:
		switch (ch = *(unsigned char *) fmt++) {
  80053c:	8d 47 01             	lea    0x1(%edi),%eax
  80053f:	89 45 e4             	mov    %eax,-0x1c(%ebp)
  800542:	0f b6 07             	movzbl (%edi),%eax
  800545:	0f b6 c8             	movzbl %al,%ecx
  800548:	83 e8 23             	sub    $0x23,%eax
  80054b:	3c 55                	cmp    $0x55,%al
  80054d:	0f 87 d5 02 00 00    	ja     800828 <vprintfmt+0x345>
  800553:	0f b6 c0             	movzbl %al,%eax
  800556:	ff 24 85 e0 0f 80 00 	jmp    *0x800fe0(,%eax,4)
  80055d:	8b 7d e4             	mov    -0x1c(%ebp),%edi
			padc = '-';
			goto reswitch;

		// flag to pad with 0's instead of spaces
		case '0':
			padc = '0';
  800560:	c6 45 d4 30          	movb   $0x30,-0x2c(%ebp)
  800564:	eb d6                	jmp    80053c <vprintfmt+0x59>
		width = -1;
		precision = -1;
		lflag = 0;
		altflag = 0;
	reswitch:
		switch (ch = *(unsigned char *) fmt++) {
  800566:	8b 7d e4             	mov    -0x1c(%ebp),%edi
  800569:	b8 00 00 00 00       	mov    $0x0,%eax
  80056e:	89 55 e4             	mov    %edx,-0x1c(%ebp)
		case '6':
		case '7':
		case '8':
		case '9':
			for (precision = 0; ; ++fmt) {
				precision = precision * 10 + ch - '0';
  800571:	8d 04 80             	lea    (%eax,%eax,4),%eax
  800574:	8d 44 41 d0          	lea    -0x30(%ecx,%eax,2),%eax
				ch = *fmt;
  800578:	0f be 0f             	movsbl (%edi),%ecx
				if (ch < '0' || ch > '9')
  80057b:	8d 51 d0             	lea    -0x30(%ecx),%edx
  80057e:	83 fa 09             	cmp    $0x9,%edx
  800581:	77 39                	ja     8005bc <vprintfmt+0xd9>
		case '5':
		case '6':
		case '7':
		case '8':
		case '9':
			for (precision = 0; ; ++fmt) {
  800583:	83 c7 01             	add    $0x1,%edi
				precision = precision * 10 + ch - '0';
				ch = *fmt;
				if (ch < '0' || ch > '9')
					break;
			}
  800586:	eb e9                	jmp    800571 <vprintfmt+0x8e>
			goto process_precision;

		case '*':
			precision = va_arg(ap, int);
  800588:	8b 45 14             	mov    0x14(%ebp),%eax
  80058b:	8d 48 04             	lea    0x4(%eax),%ecx
  80058e:	89 4d 14             	mov    %ecx,0x14(%ebp)
  800591:	8b 00                	mov    (%eax),%eax
  800593:	89 45 d0             	mov    %eax,-0x30(%ebp)
		width = -1;
		precision = -1;
		lflag = 0;
		altflag = 0;
	reswitch:
		switch (ch = *(unsigned char *) fmt++) {
  800596:	8b 7d e4             	mov    -0x1c(%ebp),%edi
			}
			goto process_precision;

		case '*':
			precision = va_arg(ap, int);
			goto process_precision;
  800599:	eb 27                	jmp    8005c2 <vprintfmt+0xdf>
  80059b:	8b 45 e0             	mov    -0x20(%ebp),%eax
  80059e:	85 c0                	test   %eax,%eax
  8005a0:	b9 00 00 00 00       	mov    $0x0,%ecx
  8005a5:	0f 49 c8             	cmovns %eax,%ecx
  8005a8:	89 4d e0             	mov    %ecx,-0x20(%ebp)
		width = -1;
		precision = -1;
		lflag = 0;
		altflag = 0;
	reswitch:
		switch (ch = *(unsigned char *) fmt++) {
  8005ab:	8b 7d e4             	mov    -0x1c(%ebp),%edi
  8005ae:	eb 8c                	jmp    80053c <vprintfmt+0x59>
  8005b0:	8b 7d e4             	mov    -0x1c(%ebp),%edi
			if (width < 0)
				width = 0;
			goto reswitch;

		case '#':
			altflag = 1;
  8005b3:	c7 45 d8 01 00 00 00 	movl   $0x1,-0x28(%ebp)
			goto reswitch;
  8005ba:	eb 80                	jmp    80053c <vprintfmt+0x59>
  8005bc:	8b 55 e4             	mov    -0x1c(%ebp),%edx
  8005bf:	89 45 d0             	mov    %eax,-0x30(%ebp)

		process_precision:
			if (width < 0)
  8005c2:	83 7d e0 00          	cmpl   $0x0,-0x20(%ebp)
  8005c6:	0f 89 70 ff ff ff    	jns    80053c <vprintfmt+0x59>
				width = precision, precision = -1;
  8005cc:	8b 45 d0             	mov    -0x30(%ebp),%eax
  8005cf:	89 45 e0             	mov    %eax,-0x20(%ebp)
  8005d2:	c7 45 d0 ff ff ff ff 	movl   $0xffffffff,-0x30(%ebp)
  8005d9:	e9 5e ff ff ff       	jmp    80053c <vprintfmt+0x59>
			goto reswitch;

		// long flag (doubled for long long)
		case 'l':
			lflag++;
  8005de:	83 c2 01             	add    $0x1,%edx
		width = -1;
		precision = -1;
		lflag = 0;
		altflag = 0;
	reswitch:
		switch (ch = *(unsigned char *) fmt++) {
  8005e1:	8b 7d e4             	mov    -0x1c(%ebp),%edi
			goto reswitch;

		// long flag (doubled for long long)
		case 'l':
			lflag++;
			goto reswitch;
  8005e4:	e9 53 ff ff ff       	jmp    80053c <vprintfmt+0x59>

		// character
		case 'c':
			putch(va_arg(ap, int), putdat);
  8005e9:	8b 45 14             	mov    0x14(%ebp),%eax
  8005ec:	8d 50 04             	lea    0x4(%eax),%edx
  8005ef:	89 55 14             	mov    %edx,0x14(%ebp)
  8005f2:	83 ec 08             	sub    $0x8,%esp
  8005f5:	53                   	push   %ebx
  8005f6:	ff 30                	pushl  (%eax)
  8005f8:	ff d6                	call   *%esi
			break;
  8005fa:	83 c4 10             	add    $0x10,%esp
		width = -1;
		precision = -1;
		lflag = 0;
		altflag = 0;
	reswitch:
		switch (ch = *(unsigned char *) fmt++) {
  8005fd:	8b 7d e4             	mov    -0x1c(%ebp),%edi
			goto reswitch;

		// character
		case 'c':
			putch(va_arg(ap, int), putdat);
			break;
  800600:	e9 04 ff ff ff       	jmp    800509 <vprintfmt+0x26>

		// error message
		case 'e':
			err = va_arg(ap, int);
  800605:	8b 45 14             	mov    0x14(%ebp),%eax
  800608:	8d 50 04             	lea    0x4(%eax),%edx
  80060b:	89 55 14             	mov    %edx,0x14(%ebp)
  80060e:	8b 00                	mov    (%eax),%eax
  800610:	99                   	cltd   
  800611:	31 d0                	xor    %edx,%eax
  800613:	29 d0                	sub    %edx,%eax
			if (err < 0)
				err = -err;
			if (err >= MAXERROR || (p = error_string[err]) == NULL)
  800615:	83 f8 08             	cmp    $0x8,%eax
  800618:	7f 0b                	jg     800625 <vprintfmt+0x142>
  80061a:	8b 14 85 40 11 80 00 	mov    0x801140(,%eax,4),%edx
  800621:	85 d2                	test   %edx,%edx
  800623:	75 18                	jne    80063d <vprintfmt+0x15a>
				printfmt(putch, putdat, "error %d", err);
  800625:	50                   	push   %eax
  800626:	68 36 0f 80 00       	push   $0x800f36
  80062b:	53                   	push   %ebx
  80062c:	56                   	push   %esi
  80062d:	e8 94 fe ff ff       	call   8004c6 <printfmt>
  800632:	83 c4 10             	add    $0x10,%esp
		width = -1;
		precision = -1;
		lflag = 0;
		altflag = 0;
	reswitch:
		switch (ch = *(unsigned char *) fmt++) {
  800635:	8b 7d e4             	mov    -0x1c(%ebp),%edi
		case 'e':
			err = va_arg(ap, int);
			if (err < 0)
				err = -err;
			if (err >= MAXERROR || (p = error_string[err]) == NULL)
				printfmt(putch, putdat, "error %d", err);
  800638:	e9 cc fe ff ff       	jmp    800509 <vprintfmt+0x26>
			else
				printfmt(putch, putdat, "%s", p);
  80063d:	52                   	push   %edx
  80063e:	68 3f 0f 80 00       	push   $0x800f3f
  800643:	53                   	push   %ebx
  800644:	56                   	push   %esi
  800645:	e8 7c fe ff ff       	call   8004c6 <printfmt>
  80064a:	83 c4 10             	add    $0x10,%esp
		width = -1;
		precision = -1;
		lflag = 0;
		altflag = 0;
	reswitch:
		switch (ch = *(unsigned char *) fmt++) {
  80064d:	8b 7d e4             	mov    -0x1c(%ebp),%edi
  800650:	e9 b4 fe ff ff       	jmp    800509 <vprintfmt+0x26>
				printfmt(putch, putdat, "%s", p);
			break;

		// string
		case 's':
			if ((p = va_arg(ap, char *)) == NULL)
  800655:	8b 45 14             	mov    0x14(%ebp),%eax
  800658:	8d 50 04             	lea    0x4(%eax),%edx
  80065b:	89 55 14             	mov    %edx,0x14(%ebp)
  80065e:	8b 38                	mov    (%eax),%edi
				p = "(null)";
  800660:	85 ff                	test   %edi,%edi
  800662:	b8 2f 0f 80 00       	mov    $0x800f2f,%eax
  800667:	0f 44 f8             	cmove  %eax,%edi
			if (width > 0 && padc != '-')
  80066a:	83 7d e0 00          	cmpl   $0x0,-0x20(%ebp)
  80066e:	0f 8e 94 00 00 00    	jle    800708 <vprintfmt+0x225>
  800674:	80 7d d4 2d          	cmpb   $0x2d,-0x2c(%ebp)
  800678:	0f 84 98 00 00 00    	je     800716 <vprintfmt+0x233>
				for (width -= strnlen(p, precision); width > 0; width--)
  80067e:	83 ec 08             	sub    $0x8,%esp
  800681:	ff 75 d0             	pushl  -0x30(%ebp)
  800684:	57                   	push   %edi
  800685:	e8 41 02 00 00       	call   8008cb <strnlen>
  80068a:	8b 4d e0             	mov    -0x20(%ebp),%ecx
  80068d:	29 c1                	sub    %eax,%ecx
  80068f:	89 4d cc             	mov    %ecx,-0x34(%ebp)
  800692:	83 c4 10             	add    $0x10,%esp
					putch(padc, putdat);
  800695:	0f be 45 d4          	movsbl -0x2c(%ebp),%eax
  800699:	89 45 e0             	mov    %eax,-0x20(%ebp)
  80069c:	89 7d d4             	mov    %edi,-0x2c(%ebp)
  80069f:	89 cf                	mov    %ecx,%edi
		// string
		case 's':
			if ((p = va_arg(ap, char *)) == NULL)
				p = "(null)";
			if (width > 0 && padc != '-')
				for (width -= strnlen(p, precision); width > 0; width--)
  8006a1:	eb 0f                	jmp    8006b2 <vprintfmt+0x1cf>
					putch(padc, putdat);
  8006a3:	83 ec 08             	sub    $0x8,%esp
  8006a6:	53                   	push   %ebx
  8006a7:	ff 75 e0             	pushl  -0x20(%ebp)
  8006aa:	ff d6                	call   *%esi
		// string
		case 's':
			if ((p = va_arg(ap, char *)) == NULL)
				p = "(null)";
			if (width > 0 && padc != '-')
				for (width -= strnlen(p, precision); width > 0; width--)
  8006ac:	83 ef 01             	sub    $0x1,%edi
  8006af:	83 c4 10             	add    $0x10,%esp
  8006b2:	85 ff                	test   %edi,%edi
  8006b4:	7f ed                	jg     8006a3 <vprintfmt+0x1c0>
  8006b6:	8b 7d d4             	mov    -0x2c(%ebp),%edi
  8006b9:	8b 4d cc             	mov    -0x34(%ebp),%ecx
  8006bc:	85 c9                	test   %ecx,%ecx
  8006be:	b8 00 00 00 00       	mov    $0x0,%eax
  8006c3:	0f 49 c1             	cmovns %ecx,%eax
  8006c6:	29 c1                	sub    %eax,%ecx
  8006c8:	89 75 08             	mov    %esi,0x8(%ebp)
  8006cb:	8b 75 d0             	mov    -0x30(%ebp),%esi
  8006ce:	89 5d 0c             	mov    %ebx,0xc(%ebp)
  8006d1:	89 cb                	mov    %ecx,%ebx
  8006d3:	eb 4d                	jmp    800722 <vprintfmt+0x23f>
					putch(padc, putdat);
			for (; (ch = *p++) != '\0' && (precision < 0 || --precision >= 0); width--)
				if (altflag && (ch < ' ' || ch > '~'))
  8006d5:	83 7d d8 00          	cmpl   $0x0,-0x28(%ebp)
  8006d9:	74 1b                	je     8006f6 <vprintfmt+0x213>
  8006db:	0f be c0             	movsbl %al,%eax
  8006de:	83 e8 20             	sub    $0x20,%eax
  8006e1:	83 f8 5e             	cmp    $0x5e,%eax
  8006e4:	76 10                	jbe    8006f6 <vprintfmt+0x213>
					putch('?', putdat);
  8006e6:	83 ec 08             	sub    $0x8,%esp
  8006e9:	ff 75 0c             	pushl  0xc(%ebp)
  8006ec:	6a 3f                	push   $0x3f
  8006ee:	ff 55 08             	call   *0x8(%ebp)
  8006f1:	83 c4 10             	add    $0x10,%esp
  8006f4:	eb 0d                	jmp    800703 <vprintfmt+0x220>
				else
					putch(ch, putdat);
  8006f6:	83 ec 08             	sub    $0x8,%esp
  8006f9:	ff 75 0c             	pushl  0xc(%ebp)
  8006fc:	52                   	push   %edx
  8006fd:	ff 55 08             	call   *0x8(%ebp)
  800700:	83 c4 10             	add    $0x10,%esp
			if ((p = va_arg(ap, char *)) == NULL)
				p = "(null)";
			if (width > 0 && padc != '-')
				for (width -= strnlen(p, precision); width > 0; width--)
					putch(padc, putdat);
			for (; (ch = *p++) != '\0' && (precision < 0 || --precision >= 0); width--)
  800703:	83 eb 01             	sub    $0x1,%ebx
  800706:	eb 1a                	jmp    800722 <vprintfmt+0x23f>
  800708:	89 75 08             	mov    %esi,0x8(%ebp)
  80070b:	8b 75 d0             	mov    -0x30(%ebp),%esi
  80070e:	89 5d 0c             	mov    %ebx,0xc(%ebp)
  800711:	8b 5d e0             	mov    -0x20(%ebp),%ebx
  800714:	eb 0c                	jmp    800722 <vprintfmt+0x23f>
  800716:	89 75 08             	mov    %esi,0x8(%ebp)
  800719:	8b 75 d0             	mov    -0x30(%ebp),%esi
  80071c:	89 5d 0c             	mov    %ebx,0xc(%ebp)
  80071f:	8b 5d e0             	mov    -0x20(%ebp),%ebx
  800722:	83 c7 01             	add    $0x1,%edi
  800725:	0f b6 47 ff          	movzbl -0x1(%edi),%eax
  800729:	0f be d0             	movsbl %al,%edx
  80072c:	85 d2                	test   %edx,%edx
  80072e:	74 23                	je     800753 <vprintfmt+0x270>
  800730:	85 f6                	test   %esi,%esi
  800732:	78 a1                	js     8006d5 <vprintfmt+0x1f2>
  800734:	83 ee 01             	sub    $0x1,%esi
  800737:	79 9c                	jns    8006d5 <vprintfmt+0x1f2>
  800739:	89 df                	mov    %ebx,%edi
  80073b:	8b 75 08             	mov    0x8(%ebp),%esi
  80073e:	8b 5d 0c             	mov    0xc(%ebp),%ebx
  800741:	eb 18                	jmp    80075b <vprintfmt+0x278>
				if (altflag && (ch < ' ' || ch > '~'))
					putch('?', putdat);
				else
					putch(ch, putdat);
			for (; width > 0; width--)
				putch(' ', putdat);
  800743:	83 ec 08             	sub    $0x8,%esp
  800746:	53                   	push   %ebx
  800747:	6a 20                	push   $0x20
  800749:	ff d6                	call   *%esi
			for (; (ch = *p++) != '\0' && (precision < 0 || --precision >= 0); width--)
				if (altflag && (ch < ' ' || ch > '~'))
					putch('?', putdat);
				else
					putch(ch, putdat);
			for (; width > 0; width--)
  80074b:	83 ef 01             	sub    $0x1,%edi
  80074e:	83 c4 10             	add    $0x10,%esp
  800751:	eb 08                	jmp    80075b <vprintfmt+0x278>
  800753:	89 df                	mov    %ebx,%edi
  800755:	8b 75 08             	mov    0x8(%ebp),%esi
  800758:	8b 5d 0c             	mov    0xc(%ebp),%ebx
  80075b:	85 ff                	test   %edi,%edi
  80075d:	7f e4                	jg     800743 <vprintfmt+0x260>
		width = -1;
		precision = -1;
		lflag = 0;
		altflag = 0;
	reswitch:
		switch (ch = *(unsigned char *) fmt++) {
  80075f:	8b 7d e4             	mov    -0x1c(%ebp),%edi
  800762:	e9 a2 fd ff ff       	jmp    800509 <vprintfmt+0x26>
				putch(' ', putdat);
			break;

		// (signed) decimal
		case 'd':
			num = getint(&ap, lflag);
  800767:	8d 45 14             	lea    0x14(%ebp),%eax
  80076a:	e8 08 fd ff ff       	call   800477 <getint>
  80076f:	89 45 d8             	mov    %eax,-0x28(%ebp)
  800772:	89 55 dc             	mov    %edx,-0x24(%ebp)
			if ((long long) num < 0) {
				putch('-', putdat);
				num = -(long long) num;
			}
			base = 10;
  800775:	b9 0a 00 00 00       	mov    $0xa,%ecx
			break;

		// (signed) decimal
		case 'd':
			num = getint(&ap, lflag);
			if ((long long) num < 0) {
  80077a:	83 7d dc 00          	cmpl   $0x0,-0x24(%ebp)
  80077e:	79 74                	jns    8007f4 <vprintfmt+0x311>
				putch('-', putdat);
  800780:	83 ec 08             	sub    $0x8,%esp
  800783:	53                   	push   %ebx
  800784:	6a 2d                	push   $0x2d
  800786:	ff d6                	call   *%esi
				num = -(long long) num;
  800788:	8b 45 d8             	mov    -0x28(%ebp),%eax
  80078b:	8b 55 dc             	mov    -0x24(%ebp),%edx
  80078e:	f7 d8                	neg    %eax
  800790:	83 d2 00             	adc    $0x0,%edx
  800793:	f7 da                	neg    %edx
  800795:	83 c4 10             	add    $0x10,%esp
			}
			base = 10;
  800798:	b9 0a 00 00 00       	mov    $0xa,%ecx
  80079d:	eb 55                	jmp    8007f4 <vprintfmt+0x311>
			goto number;

		// unsigned decimal
		case 'u':
			num = getuint(&ap, lflag);
  80079f:	8d 45 14             	lea    0x14(%ebp),%eax
  8007a2:	e8 96 fc ff ff       	call   80043d <getuint>
			base = 10;
  8007a7:	b9 0a 00 00 00       	mov    $0xa,%ecx
			goto number;
  8007ac:	eb 46                	jmp    8007f4 <vprintfmt+0x311>

		// (unsigned) octal
		case 'o':
			num = getuint(&ap, lflag);
  8007ae:	8d 45 14             	lea    0x14(%ebp),%eax
  8007b1:	e8 87 fc ff ff       	call   80043d <getuint>
			base = 8;
  8007b6:	b9 08 00 00 00       	mov    $0x8,%ecx
			goto number;
  8007bb:	eb 37                	jmp    8007f4 <vprintfmt+0x311>

		// pointer
		case 'p':
			putch('0', putdat);
  8007bd:	83 ec 08             	sub    $0x8,%esp
  8007c0:	53                   	push   %ebx
  8007c1:	6a 30                	push   $0x30
  8007c3:	ff d6                	call   *%esi
			putch('x', putdat);
  8007c5:	83 c4 08             	add    $0x8,%esp
  8007c8:	53                   	push   %ebx
  8007c9:	6a 78                	push   $0x78
  8007cb:	ff d6                	call   *%esi
			num = (unsigned long long)
				(uintptr_t) va_arg(ap, void *);
  8007cd:	8b 45 14             	mov    0x14(%ebp),%eax
  8007d0:	8d 50 04             	lea    0x4(%eax),%edx
  8007d3:	89 55 14             	mov    %edx,0x14(%ebp)

		// pointer
		case 'p':
			putch('0', putdat);
			putch('x', putdat);
			num = (unsigned long long)
  8007d6:	8b 00                	mov    (%eax),%eax
  8007d8:	ba 00 00 00 00       	mov    $0x0,%edx
				(uintptr_t) va_arg(ap, void *);
			base = 16;
			goto number;
  8007dd:	83 c4 10             	add    $0x10,%esp
		case 'p':
			putch('0', putdat);
			putch('x', putdat);
			num = (unsigned long long)
				(uintptr_t) va_arg(ap, void *);
			base = 16;
  8007e0:	b9 10 00 00 00       	mov    $0x10,%ecx
			goto number;
  8007e5:	eb 0d                	jmp    8007f4 <vprintfmt+0x311>

		// (unsigned) hexadecimal
		case 'x':
			num = getuint(&ap, lflag);
  8007e7:	8d 45 14             	lea    0x14(%ebp),%eax
  8007ea:	e8 4e fc ff ff       	call   80043d <getuint>
			base = 16;
  8007ef:	b9 10 00 00 00       	mov    $0x10,%ecx
		number:
			printnum(putch, putdat, num, base, width, padc);
  8007f4:	83 ec 0c             	sub    $0xc,%esp
  8007f7:	0f be 7d d4          	movsbl -0x2c(%ebp),%edi
  8007fb:	57                   	push   %edi
  8007fc:	ff 75 e0             	pushl  -0x20(%ebp)
  8007ff:	51                   	push   %ecx
  800800:	52                   	push   %edx
  800801:	50                   	push   %eax
  800802:	89 da                	mov    %ebx,%edx
  800804:	89 f0                	mov    %esi,%eax
  800806:	e8 83 fb ff ff       	call   80038e <printnum>
			break;
  80080b:	83 c4 20             	add    $0x20,%esp
  80080e:	8b 7d e4             	mov    -0x1c(%ebp),%edi
  800811:	e9 f3 fc ff ff       	jmp    800509 <vprintfmt+0x26>

		// escaped '%' character
		case '%':
			putch(ch, putdat);
  800816:	83 ec 08             	sub    $0x8,%esp
  800819:	53                   	push   %ebx
  80081a:	51                   	push   %ecx
  80081b:	ff d6                	call   *%esi
			break;
  80081d:	83 c4 10             	add    $0x10,%esp
		width = -1;
		precision = -1;
		lflag = 0;
		altflag = 0;
	reswitch:
		switch (ch = *(unsigned char *) fmt++) {
  800820:	8b 7d e4             	mov    -0x1c(%ebp),%edi
			break;

		// escaped '%' character
		case '%':
			putch(ch, putdat);
			break;
  800823:	e9 e1 fc ff ff       	jmp    800509 <vprintfmt+0x26>

		// unrecognized escape sequence - just print it literally
		default:
			putch('%', putdat);
  800828:	83 ec 08             	sub    $0x8,%esp
  80082b:	53                   	push   %ebx
  80082c:	6a 25                	push   $0x25
  80082e:	ff d6                	call   *%esi
			for (fmt--; fmt[-1] != '%'; fmt--)
  800830:	83 c4 10             	add    $0x10,%esp
  800833:	eb 03                	jmp    800838 <vprintfmt+0x355>
  800835:	83 ef 01             	sub    $0x1,%edi
  800838:	80 7f ff 25          	cmpb   $0x25,-0x1(%edi)
  80083c:	75 f7                	jne    800835 <vprintfmt+0x352>
  80083e:	e9 c6 fc ff ff       	jmp    800509 <vprintfmt+0x26>
				/* do nothing */;
			break;
		}
	}
}
  800843:	8d 65 f4             	lea    -0xc(%ebp),%esp
  800846:	5b                   	pop    %ebx
  800847:	5e                   	pop    %esi
  800848:	5f                   	pop    %edi
  800849:	5d                   	pop    %ebp
  80084a:	c3                   	ret    

0080084b <vsnprintf>:
		*b->buf++ = ch;
}

int
vsnprintf(char *buf, int n, const char *fmt, va_list ap)
{
  80084b:	55                   	push   %ebp
  80084c:	89 e5                	mov    %esp,%ebp
  80084e:	83 ec 18             	sub    $0x18,%esp
  800851:	8b 45 08             	mov    0x8(%ebp),%eax
  800854:	8b 55 0c             	mov    0xc(%ebp),%edx
	struct sprintbuf b = {buf, buf+n-1, 0};
  800857:	89 45 ec             	mov    %eax,-0x14(%ebp)
  80085a:	8d 4c 10 ff          	lea    -0x1(%eax,%edx,1),%ecx
  80085e:	89 4d f0             	mov    %ecx,-0x10(%ebp)
  800861:	c7 45 f4 00 00 00 00 	movl   $0x0,-0xc(%ebp)

	if (buf == NULL || n < 1)
  800868:	85 c0                	test   %eax,%eax
  80086a:	74 26                	je     800892 <vsnprintf+0x47>
  80086c:	85 d2                	test   %edx,%edx
  80086e:	7e 22                	jle    800892 <vsnprintf+0x47>
		return -E_INVAL;

	// print the string to the buffer
	vprintfmt((void*)sprintputch, &b, fmt, ap);
  800870:	ff 75 14             	pushl  0x14(%ebp)
  800873:	ff 75 10             	pushl  0x10(%ebp)
  800876:	8d 45 ec             	lea    -0x14(%ebp),%eax
  800879:	50                   	push   %eax
  80087a:	68 a9 04 80 00       	push   $0x8004a9
  80087f:	e8 5f fc ff ff       	call   8004e3 <vprintfmt>

	// null terminate the buffer
	*b.buf = '\0';
  800884:	8b 45 ec             	mov    -0x14(%ebp),%eax
  800887:	c6 00 00             	movb   $0x0,(%eax)

	return b.cnt;
  80088a:	8b 45 f4             	mov    -0xc(%ebp),%eax
  80088d:	83 c4 10             	add    $0x10,%esp
  800890:	eb 05                	jmp    800897 <vsnprintf+0x4c>
vsnprintf(char *buf, int n, const char *fmt, va_list ap)
{
	struct sprintbuf b = {buf, buf+n-1, 0};

	if (buf == NULL || n < 1)
		return -E_INVAL;
  800892:	b8 fd ff ff ff       	mov    $0xfffffffd,%eax

	// null terminate the buffer
	*b.buf = '\0';

	return b.cnt;
}
  800897:	c9                   	leave  
  800898:	c3                   	ret    

00800899 <snprintf>:

int
snprintf(char *buf, int n, const char *fmt, ...)
{
  800899:	55                   	push   %ebp
  80089a:	89 e5                	mov    %esp,%ebp
  80089c:	83 ec 08             	sub    $0x8,%esp
	va_list ap;
	int rc;

	va_start(ap, fmt);
  80089f:	8d 45 14             	lea    0x14(%ebp),%eax
	rc = vsnprintf(buf, n, fmt, ap);
  8008a2:	50                   	push   %eax
  8008a3:	ff 75 10             	pushl  0x10(%ebp)
  8008a6:	ff 75 0c             	pushl  0xc(%ebp)
  8008a9:	ff 75 08             	pushl  0x8(%ebp)
  8008ac:	e8 9a ff ff ff       	call   80084b <vsnprintf>
	va_end(ap);

	return rc;
}
  8008b1:	c9                   	leave  
  8008b2:	c3                   	ret    

008008b3 <strlen>:
// Primespipe runs 3x faster this way.
#define ASM 1

int
strlen(const char *s)
{
  8008b3:	55                   	push   %ebp
  8008b4:	89 e5                	mov    %esp,%ebp
  8008b6:	8b 55 08             	mov    0x8(%ebp),%edx
	int n;

	for (n = 0; *s != '\0'; s++)
  8008b9:	b8 00 00 00 00       	mov    $0x0,%eax
  8008be:	eb 03                	jmp    8008c3 <strlen+0x10>
		n++;
  8008c0:	83 c0 01             	add    $0x1,%eax
int
strlen(const char *s)
{
	int n;

	for (n = 0; *s != '\0'; s++)
  8008c3:	80 3c 02 00          	cmpb   $0x0,(%edx,%eax,1)
  8008c7:	75 f7                	jne    8008c0 <strlen+0xd>
		n++;
	return n;
}
  8008c9:	5d                   	pop    %ebp
  8008ca:	c3                   	ret    

008008cb <strnlen>:

int
strnlen(const char *s, size_t size)
{
  8008cb:	55                   	push   %ebp
  8008cc:	89 e5                	mov    %esp,%ebp
  8008ce:	8b 4d 08             	mov    0x8(%ebp),%ecx
  8008d1:	8b 45 0c             	mov    0xc(%ebp),%eax
	int n;

	for (n = 0; size > 0 && *s != '\0'; s++, size--)
  8008d4:	ba 00 00 00 00       	mov    $0x0,%edx
  8008d9:	eb 03                	jmp    8008de <strnlen+0x13>
		n++;
  8008db:	83 c2 01             	add    $0x1,%edx
int
strnlen(const char *s, size_t size)
{
	int n;

	for (n = 0; size > 0 && *s != '\0'; s++, size--)
  8008de:	39 c2                	cmp    %eax,%edx
  8008e0:	74 08                	je     8008ea <strnlen+0x1f>
  8008e2:	80 3c 11 00          	cmpb   $0x0,(%ecx,%edx,1)
  8008e6:	75 f3                	jne    8008db <strnlen+0x10>
  8008e8:	89 d0                	mov    %edx,%eax
		n++;
	return n;
}
  8008ea:	5d                   	pop    %ebp
  8008eb:	c3                   	ret    

008008ec <strcpy>:

char *
strcpy(char *dst, const char *src)
{
  8008ec:	55                   	push   %ebp
  8008ed:	89 e5                	mov    %esp,%ebp
  8008ef:	53                   	push   %ebx
  8008f0:	8b 45 08             	mov    0x8(%ebp),%eax
  8008f3:	8b 4d 0c             	mov    0xc(%ebp),%ecx
	char *ret;

	ret = dst;
	while ((*dst++ = *src++) != '\0')
  8008f6:	89 c2                	mov    %eax,%edx
  8008f8:	83 c2 01             	add    $0x1,%edx
  8008fb:	83 c1 01             	add    $0x1,%ecx
  8008fe:	0f b6 59 ff          	movzbl -0x1(%ecx),%ebx
  800902:	88 5a ff             	mov    %bl,-0x1(%edx)
  800905:	84 db                	test   %bl,%bl
  800907:	75 ef                	jne    8008f8 <strcpy+0xc>
		/* do nothing */;
	return ret;
}
  800909:	5b                   	pop    %ebx
  80090a:	5d                   	pop    %ebp
  80090b:	c3                   	ret    

0080090c <strcat>:

char *
strcat(char *dst, const char *src)
{
  80090c:	55                   	push   %ebp
  80090d:	89 e5                	mov    %esp,%ebp
  80090f:	53                   	push   %ebx
  800910:	8b 5d 08             	mov    0x8(%ebp),%ebx
	int len = strlen(dst);
  800913:	53                   	push   %ebx
  800914:	e8 9a ff ff ff       	call   8008b3 <strlen>
  800919:	83 c4 04             	add    $0x4,%esp
	strcpy(dst + len, src);
  80091c:	ff 75 0c             	pushl  0xc(%ebp)
  80091f:	01 d8                	add    %ebx,%eax
  800921:	50                   	push   %eax
  800922:	e8 c5 ff ff ff       	call   8008ec <strcpy>
	return dst;
}
  800927:	89 d8                	mov    %ebx,%eax
  800929:	8b 5d fc             	mov    -0x4(%ebp),%ebx
  80092c:	c9                   	leave  
  80092d:	c3                   	ret    

0080092e <strncpy>:

char *
strncpy(char *dst, const char *src, size_t size) {
  80092e:	55                   	push   %ebp
  80092f:	89 e5                	mov    %esp,%ebp
  800931:	56                   	push   %esi
  800932:	53                   	push   %ebx
  800933:	8b 75 08             	mov    0x8(%ebp),%esi
  800936:	8b 4d 0c             	mov    0xc(%ebp),%ecx
  800939:	89 f3                	mov    %esi,%ebx
  80093b:	03 5d 10             	add    0x10(%ebp),%ebx
	size_t i;
	char *ret;

	ret = dst;
	for (i = 0; i < size; i++) {
  80093e:	89 f2                	mov    %esi,%edx
  800940:	eb 0f                	jmp    800951 <strncpy+0x23>
		*dst++ = *src;
  800942:	83 c2 01             	add    $0x1,%edx
  800945:	0f b6 01             	movzbl (%ecx),%eax
  800948:	88 42 ff             	mov    %al,-0x1(%edx)
		// If strlen(src) < size, null-pad 'dst' out to 'size' chars
		if (*src != '\0')
			src++;
  80094b:	80 39 01             	cmpb   $0x1,(%ecx)
  80094e:	83 d9 ff             	sbb    $0xffffffff,%ecx
strncpy(char *dst, const char *src, size_t size) {
	size_t i;
	char *ret;

	ret = dst;
	for (i = 0; i < size; i++) {
  800951:	39 da                	cmp    %ebx,%edx
  800953:	75 ed                	jne    800942 <strncpy+0x14>
		// If strlen(src) < size, null-pad 'dst' out to 'size' chars
		if (*src != '\0')
			src++;
	}
	return ret;
}
  800955:	89 f0                	mov    %esi,%eax
  800957:	5b                   	pop    %ebx
  800958:	5e                   	pop    %esi
  800959:	5d                   	pop    %ebp
  80095a:	c3                   	ret    

0080095b <strlcpy>:

size_t
strlcpy(char *dst, const char *src, size_t size)
{
  80095b:	55                   	push   %ebp
  80095c:	89 e5                	mov    %esp,%ebp
  80095e:	56                   	push   %esi
  80095f:	53                   	push   %ebx
  800960:	8b 75 08             	mov    0x8(%ebp),%esi
  800963:	8b 4d 0c             	mov    0xc(%ebp),%ecx
  800966:	8b 55 10             	mov    0x10(%ebp),%edx
  800969:	89 f0                	mov    %esi,%eax
	char *dst_in;

	dst_in = dst;
	if (size > 0) {
  80096b:	85 d2                	test   %edx,%edx
  80096d:	74 21                	je     800990 <strlcpy+0x35>
  80096f:	8d 44 16 ff          	lea    -0x1(%esi,%edx,1),%eax
  800973:	89 f2                	mov    %esi,%edx
  800975:	eb 09                	jmp    800980 <strlcpy+0x25>
		while (--size > 0 && *src != '\0')
			*dst++ = *src++;
  800977:	83 c2 01             	add    $0x1,%edx
  80097a:	83 c1 01             	add    $0x1,%ecx
  80097d:	88 5a ff             	mov    %bl,-0x1(%edx)
{
	char *dst_in;

	dst_in = dst;
	if (size > 0) {
		while (--size > 0 && *src != '\0')
  800980:	39 c2                	cmp    %eax,%edx
  800982:	74 09                	je     80098d <strlcpy+0x32>
  800984:	0f b6 19             	movzbl (%ecx),%ebx
  800987:	84 db                	test   %bl,%bl
  800989:	75 ec                	jne    800977 <strlcpy+0x1c>
  80098b:	89 d0                	mov    %edx,%eax
			*dst++ = *src++;
		*dst = '\0';
  80098d:	c6 00 00             	movb   $0x0,(%eax)
	}
	return dst - dst_in;
  800990:	29 f0                	sub    %esi,%eax
}
  800992:	5b                   	pop    %ebx
  800993:	5e                   	pop    %esi
  800994:	5d                   	pop    %ebp
  800995:	c3                   	ret    

00800996 <strcmp>:

int
strcmp(const char *p, const char *q)
{
  800996:	55                   	push   %ebp
  800997:	89 e5                	mov    %esp,%ebp
  800999:	8b 4d 08             	mov    0x8(%ebp),%ecx
  80099c:	8b 55 0c             	mov    0xc(%ebp),%edx
	while (*p && *p == *q)
  80099f:	eb 06                	jmp    8009a7 <strcmp+0x11>
		p++, q++;
  8009a1:	83 c1 01             	add    $0x1,%ecx
  8009a4:	83 c2 01             	add    $0x1,%edx
}

int
strcmp(const char *p, const char *q)
{
	while (*p && *p == *q)
  8009a7:	0f b6 01             	movzbl (%ecx),%eax
  8009aa:	84 c0                	test   %al,%al
  8009ac:	74 04                	je     8009b2 <strcmp+0x1c>
  8009ae:	3a 02                	cmp    (%edx),%al
  8009b0:	74 ef                	je     8009a1 <strcmp+0xb>
		p++, q++;
	return (int) ((unsigned char) *p - (unsigned char) *q);
  8009b2:	0f b6 c0             	movzbl %al,%eax
  8009b5:	0f b6 12             	movzbl (%edx),%edx
  8009b8:	29 d0                	sub    %edx,%eax
}
  8009ba:	5d                   	pop    %ebp
  8009bb:	c3                   	ret    

008009bc <strncmp>:

int
strncmp(const char *p, const char *q, size_t n)
{
  8009bc:	55                   	push   %ebp
  8009bd:	89 e5                	mov    %esp,%ebp
  8009bf:	53                   	push   %ebx
  8009c0:	8b 45 08             	mov    0x8(%ebp),%eax
  8009c3:	8b 55 0c             	mov    0xc(%ebp),%edx
  8009c6:	89 c3                	mov    %eax,%ebx
  8009c8:	03 5d 10             	add    0x10(%ebp),%ebx
	while (n > 0 && *p && *p == *q)
  8009cb:	eb 06                	jmp    8009d3 <strncmp+0x17>
		n--, p++, q++;
  8009cd:	83 c0 01             	add    $0x1,%eax
  8009d0:	83 c2 01             	add    $0x1,%edx
}

int
strncmp(const char *p, const char *q, size_t n)
{
	while (n > 0 && *p && *p == *q)
  8009d3:	39 d8                	cmp    %ebx,%eax
  8009d5:	74 15                	je     8009ec <strncmp+0x30>
  8009d7:	0f b6 08             	movzbl (%eax),%ecx
  8009da:	84 c9                	test   %cl,%cl
  8009dc:	74 04                	je     8009e2 <strncmp+0x26>
  8009de:	3a 0a                	cmp    (%edx),%cl
  8009e0:	74 eb                	je     8009cd <strncmp+0x11>
		n--, p++, q++;
	if (n == 0)
		return 0;
	else
		return (int) ((unsigned char) *p - (unsigned char) *q);
  8009e2:	0f b6 00             	movzbl (%eax),%eax
  8009e5:	0f b6 12             	movzbl (%edx),%edx
  8009e8:	29 d0                	sub    %edx,%eax
  8009ea:	eb 05                	jmp    8009f1 <strncmp+0x35>
strncmp(const char *p, const char *q, size_t n)
{
	while (n > 0 && *p && *p == *q)
		n--, p++, q++;
	if (n == 0)
		return 0;
  8009ec:	b8 00 00 00 00       	mov    $0x0,%eax
	else
		return (int) ((unsigned char) *p - (unsigned char) *q);
}
  8009f1:	5b                   	pop    %ebx
  8009f2:	5d                   	pop    %ebp
  8009f3:	c3                   	ret    

008009f4 <strchr>:

// Return a pointer to the first occurrence of 'c' in 's',
// or a null pointer if the string has no 'c'.
char *
strchr(const char *s, char c)
{
  8009f4:	55                   	push   %ebp
  8009f5:	89 e5                	mov    %esp,%ebp
  8009f7:	8b 45 08             	mov    0x8(%ebp),%eax
  8009fa:	0f b6 4d 0c          	movzbl 0xc(%ebp),%ecx
	for (; *s; s++)
  8009fe:	eb 07                	jmp    800a07 <strchr+0x13>
		if (*s == c)
  800a00:	38 ca                	cmp    %cl,%dl
  800a02:	74 0f                	je     800a13 <strchr+0x1f>
// Return a pointer to the first occurrence of 'c' in 's',
// or a null pointer if the string has no 'c'.
char *
strchr(const char *s, char c)
{
	for (; *s; s++)
  800a04:	83 c0 01             	add    $0x1,%eax
  800a07:	0f b6 10             	movzbl (%eax),%edx
  800a0a:	84 d2                	test   %dl,%dl
  800a0c:	75 f2                	jne    800a00 <strchr+0xc>
		if (*s == c)
			return (char *) s;
	return 0;
  800a0e:	b8 00 00 00 00       	mov    $0x0,%eax
}
  800a13:	5d                   	pop    %ebp
  800a14:	c3                   	ret    

00800a15 <strfind>:

// Return a pointer to the first occurrence of 'c' in 's',
// or a pointer to the string-ending null character if the string has no 'c'.
char *
strfind(const char *s, char c)
{
  800a15:	55                   	push   %ebp
  800a16:	89 e5                	mov    %esp,%ebp
  800a18:	8b 45 08             	mov    0x8(%ebp),%eax
  800a1b:	0f b6 4d 0c          	movzbl 0xc(%ebp),%ecx
	for (; *s; s++)
  800a1f:	eb 03                	jmp    800a24 <strfind+0xf>
  800a21:	83 c0 01             	add    $0x1,%eax
  800a24:	0f b6 10             	movzbl (%eax),%edx
		if (*s == c)
  800a27:	38 ca                	cmp    %cl,%dl
  800a29:	74 04                	je     800a2f <strfind+0x1a>
  800a2b:	84 d2                	test   %dl,%dl
  800a2d:	75 f2                	jne    800a21 <strfind+0xc>
			break;
	return (char *) s;
}
  800a2f:	5d                   	pop    %ebp
  800a30:	c3                   	ret    

00800a31 <memset>:

#if ASM
void *
memset(void *v, int c, size_t n)
{
  800a31:	55                   	push   %ebp
  800a32:	89 e5                	mov    %esp,%ebp
  800a34:	57                   	push   %edi
  800a35:	56                   	push   %esi
  800a36:	53                   	push   %ebx
  800a37:	8b 55 08             	mov    0x8(%ebp),%edx
  800a3a:	8b 4d 10             	mov    0x10(%ebp),%ecx
	char *p = v;

	if (n == 0)
  800a3d:	85 c9                	test   %ecx,%ecx
  800a3f:	74 37                	je     800a78 <memset+0x47>
		return v;
	if ((int)v%4 == 0 && n%4 == 0) {
  800a41:	f6 c2 03             	test   $0x3,%dl
  800a44:	75 2a                	jne    800a70 <memset+0x3f>
  800a46:	f6 c1 03             	test   $0x3,%cl
  800a49:	75 25                	jne    800a70 <memset+0x3f>
		c &= 0xFF;
  800a4b:	0f b6 5d 0c          	movzbl 0xc(%ebp),%ebx
		c = (c<<24)|(c<<16)|(c<<8)|c;
  800a4f:	89 df                	mov    %ebx,%edi
  800a51:	c1 e7 08             	shl    $0x8,%edi
  800a54:	89 de                	mov    %ebx,%esi
  800a56:	c1 e6 18             	shl    $0x18,%esi
  800a59:	89 d8                	mov    %ebx,%eax
  800a5b:	c1 e0 10             	shl    $0x10,%eax
  800a5e:	09 f0                	or     %esi,%eax
  800a60:	09 c3                	or     %eax,%ebx
		asm volatile("cld; rep stosl\n"
			: "=D" (p), "=c" (n)
			: "D" (p), "a" (c), "c" (n/4)
  800a62:	c1 e9 02             	shr    $0x2,%ecx
	if (n == 0)
		return v;
	if ((int)v%4 == 0 && n%4 == 0) {
		c &= 0xFF;
		c = (c<<24)|(c<<16)|(c<<8)|c;
		asm volatile("cld; rep stosl\n"
  800a65:	89 f8                	mov    %edi,%eax
  800a67:	09 d8                	or     %ebx,%eax
  800a69:	89 d7                	mov    %edx,%edi
  800a6b:	fc                   	cld    
  800a6c:	f3 ab                	rep stos %eax,%es:(%edi)
  800a6e:	eb 08                	jmp    800a78 <memset+0x47>
			: "=D" (p), "=c" (n)
			: "D" (p), "a" (c), "c" (n/4)
			: "cc", "memory");
	} else
		asm volatile("cld; rep stosb\n"
  800a70:	89 d7                	mov    %edx,%edi
  800a72:	8b 45 0c             	mov    0xc(%ebp),%eax
  800a75:	fc                   	cld    
  800a76:	f3 aa                	rep stos %al,%es:(%edi)
			: "=D" (p), "=c" (n)
			: "0" (p), "a" (c), "1" (n)
			: "cc", "memory");
	return v;
}
  800a78:	89 d0                	mov    %edx,%eax
  800a7a:	5b                   	pop    %ebx
  800a7b:	5e                   	pop    %esi
  800a7c:	5f                   	pop    %edi
  800a7d:	5d                   	pop    %ebp
  800a7e:	c3                   	ret    

00800a7f <memmove>:

void *
memmove(void *dst, const void *src, size_t n)
{
  800a7f:	55                   	push   %ebp
  800a80:	89 e5                	mov    %esp,%ebp
  800a82:	57                   	push   %edi
  800a83:	56                   	push   %esi
  800a84:	8b 45 08             	mov    0x8(%ebp),%eax
  800a87:	8b 75 0c             	mov    0xc(%ebp),%esi
  800a8a:	8b 4d 10             	mov    0x10(%ebp),%ecx
	const char *s;
	char *d;

	s = src;
	d = dst;
	if (s < d && s + n > d) {
  800a8d:	39 c6                	cmp    %eax,%esi
  800a8f:	73 35                	jae    800ac6 <memmove+0x47>
  800a91:	8d 14 0e             	lea    (%esi,%ecx,1),%edx
  800a94:	39 d0                	cmp    %edx,%eax
  800a96:	73 2e                	jae    800ac6 <memmove+0x47>
		s += n;
		d += n;
  800a98:	8d 3c 08             	lea    (%eax,%ecx,1),%edi
		if ((int)s%4 == 0 && (int)d%4 == 0 && n%4 == 0)
  800a9b:	89 d6                	mov    %edx,%esi
  800a9d:	09 fe                	or     %edi,%esi
  800a9f:	f7 c6 03 00 00 00    	test   $0x3,%esi
  800aa5:	75 13                	jne    800aba <memmove+0x3b>
  800aa7:	f6 c1 03             	test   $0x3,%cl
  800aaa:	75 0e                	jne    800aba <memmove+0x3b>
			asm volatile("std; rep movsl\n"
  800aac:	83 ef 04             	sub    $0x4,%edi
  800aaf:	8d 72 fc             	lea    -0x4(%edx),%esi
  800ab2:	c1 e9 02             	shr    $0x2,%ecx
  800ab5:	fd                   	std    
  800ab6:	f3 a5                	rep movsl %ds:(%esi),%es:(%edi)
  800ab8:	eb 09                	jmp    800ac3 <memmove+0x44>
				:: "D" (d-4), "S" (s-4), "c" (n/4) : "cc", "memory");
		else
			asm volatile("std; rep movsb\n"
  800aba:	83 ef 01             	sub    $0x1,%edi
  800abd:	8d 72 ff             	lea    -0x1(%edx),%esi
  800ac0:	fd                   	std    
  800ac1:	f3 a4                	rep movsb %ds:(%esi),%es:(%edi)
				:: "D" (d-1), "S" (s-1), "c" (n) : "cc", "memory");
		// Some versions of GCC rely on DF being clear
		asm volatile("cld" ::: "cc");
  800ac3:	fc                   	cld    
  800ac4:	eb 1d                	jmp    800ae3 <memmove+0x64>
	} else {
		if ((int)s%4 == 0 && (int)d%4 == 0 && n%4 == 0)
  800ac6:	89 f2                	mov    %esi,%edx
  800ac8:	09 c2                	or     %eax,%edx
  800aca:	f6 c2 03             	test   $0x3,%dl
  800acd:	75 0f                	jne    800ade <memmove+0x5f>
  800acf:	f6 c1 03             	test   $0x3,%cl
  800ad2:	75 0a                	jne    800ade <memmove+0x5f>
			asm volatile("cld; rep movsl\n"
  800ad4:	c1 e9 02             	shr    $0x2,%ecx
  800ad7:	89 c7                	mov    %eax,%edi
  800ad9:	fc                   	cld    
  800ada:	f3 a5                	rep movsl %ds:(%esi),%es:(%edi)
  800adc:	eb 05                	jmp    800ae3 <memmove+0x64>
				:: "D" (d), "S" (s), "c" (n/4) : "cc", "memory");
		else
			asm volatile("cld; rep movsb\n"
  800ade:	89 c7                	mov    %eax,%edi
  800ae0:	fc                   	cld    
  800ae1:	f3 a4                	rep movsb %ds:(%esi),%es:(%edi)
				:: "D" (d), "S" (s), "c" (n) : "cc", "memory");
	}
	return dst;
}
  800ae3:	5e                   	pop    %esi
  800ae4:	5f                   	pop    %edi
  800ae5:	5d                   	pop    %ebp
  800ae6:	c3                   	ret    

00800ae7 <memcpy>:
}
#endif

void *
memcpy(void *dst, const void *src, size_t n)
{
  800ae7:	55                   	push   %ebp
  800ae8:	89 e5                	mov    %esp,%ebp
	return memmove(dst, src, n);
  800aea:	ff 75 10             	pushl  0x10(%ebp)
  800aed:	ff 75 0c             	pushl  0xc(%ebp)
  800af0:	ff 75 08             	pushl  0x8(%ebp)
  800af3:	e8 87 ff ff ff       	call   800a7f <memmove>
}
  800af8:	c9                   	leave  
  800af9:	c3                   	ret    

00800afa <memcmp>:

int
memcmp(const void *v1, const void *v2, size_t n)
{
  800afa:	55                   	push   %ebp
  800afb:	89 e5                	mov    %esp,%ebp
  800afd:	56                   	push   %esi
  800afe:	53                   	push   %ebx
  800aff:	8b 45 08             	mov    0x8(%ebp),%eax
  800b02:	8b 55 0c             	mov    0xc(%ebp),%edx
  800b05:	89 c6                	mov    %eax,%esi
  800b07:	03 75 10             	add    0x10(%ebp),%esi
	const uint8_t *s1 = (const uint8_t *) v1;
	const uint8_t *s2 = (const uint8_t *) v2;

	while (n-- > 0) {
  800b0a:	eb 1a                	jmp    800b26 <memcmp+0x2c>
		if (*s1 != *s2)
  800b0c:	0f b6 08             	movzbl (%eax),%ecx
  800b0f:	0f b6 1a             	movzbl (%edx),%ebx
  800b12:	38 d9                	cmp    %bl,%cl
  800b14:	74 0a                	je     800b20 <memcmp+0x26>
			return (int) *s1 - (int) *s2;
  800b16:	0f b6 c1             	movzbl %cl,%eax
  800b19:	0f b6 db             	movzbl %bl,%ebx
  800b1c:	29 d8                	sub    %ebx,%eax
  800b1e:	eb 0f                	jmp    800b2f <memcmp+0x35>
		s1++, s2++;
  800b20:	83 c0 01             	add    $0x1,%eax
  800b23:	83 c2 01             	add    $0x1,%edx
memcmp(const void *v1, const void *v2, size_t n)
{
	const uint8_t *s1 = (const uint8_t *) v1;
	const uint8_t *s2 = (const uint8_t *) v2;

	while (n-- > 0) {
  800b26:	39 f0                	cmp    %esi,%eax
  800b28:	75 e2                	jne    800b0c <memcmp+0x12>
		if (*s1 != *s2)
			return (int) *s1 - (int) *s2;
		s1++, s2++;
	}

	return 0;
  800b2a:	b8 00 00 00 00       	mov    $0x0,%eax
}
  800b2f:	5b                   	pop    %ebx
  800b30:	5e                   	pop    %esi
  800b31:	5d                   	pop    %ebp
  800b32:	c3                   	ret    

00800b33 <memfind>:

void *
memfind(const void *s, int c, size_t n)
{
  800b33:	55                   	push   %ebp
  800b34:	89 e5                	mov    %esp,%ebp
  800b36:	8b 45 08             	mov    0x8(%ebp),%eax
  800b39:	8b 4d 0c             	mov    0xc(%ebp),%ecx
	const void *ends = (const char *) s + n;
  800b3c:	89 c2                	mov    %eax,%edx
  800b3e:	03 55 10             	add    0x10(%ebp),%edx
	for (; s < ends; s++)
  800b41:	eb 07                	jmp    800b4a <memfind+0x17>
		if (*(const unsigned char *) s == (unsigned char) c)
  800b43:	38 08                	cmp    %cl,(%eax)
  800b45:	74 07                	je     800b4e <memfind+0x1b>

void *
memfind(const void *s, int c, size_t n)
{
	const void *ends = (const char *) s + n;
	for (; s < ends; s++)
  800b47:	83 c0 01             	add    $0x1,%eax
  800b4a:	39 d0                	cmp    %edx,%eax
  800b4c:	72 f5                	jb     800b43 <memfind+0x10>
		if (*(const unsigned char *) s == (unsigned char) c)
			break;
	return (void *) s;
}
  800b4e:	5d                   	pop    %ebp
  800b4f:	c3                   	ret    

00800b50 <strtol>:

long
strtol(const char *s, char **endptr, int base)
{
  800b50:	55                   	push   %ebp
  800b51:	89 e5                	mov    %esp,%ebp
  800b53:	57                   	push   %edi
  800b54:	56                   	push   %esi
  800b55:	53                   	push   %ebx
  800b56:	8b 4d 08             	mov    0x8(%ebp),%ecx
  800b59:	8b 5d 10             	mov    0x10(%ebp),%ebx
	int neg = 0;
	long val = 0;

	// gobble initial whitespace
	while (*s == ' ' || *s == '\t')
  800b5c:	eb 03                	jmp    800b61 <strtol+0x11>
		s++;
  800b5e:	83 c1 01             	add    $0x1,%ecx
{
	int neg = 0;
	long val = 0;

	// gobble initial whitespace
	while (*s == ' ' || *s == '\t')
  800b61:	0f b6 01             	movzbl (%ecx),%eax
  800b64:	3c 20                	cmp    $0x20,%al
  800b66:	74 f6                	je     800b5e <strtol+0xe>
  800b68:	3c 09                	cmp    $0x9,%al
  800b6a:	74 f2                	je     800b5e <strtol+0xe>
		s++;

	// plus/minus sign
	if (*s == '+')
  800b6c:	3c 2b                	cmp    $0x2b,%al
  800b6e:	75 0a                	jne    800b7a <strtol+0x2a>
		s++;
  800b70:	83 c1 01             	add    $0x1,%ecx
}

long
strtol(const char *s, char **endptr, int base)
{
	int neg = 0;
  800b73:	bf 00 00 00 00       	mov    $0x0,%edi
  800b78:	eb 11                	jmp    800b8b <strtol+0x3b>
  800b7a:	bf 00 00 00 00       	mov    $0x0,%edi
		s++;

	// plus/minus sign
	if (*s == '+')
		s++;
	else if (*s == '-')
  800b7f:	3c 2d                	cmp    $0x2d,%al
  800b81:	75 08                	jne    800b8b <strtol+0x3b>
		s++, neg = 1;
  800b83:	83 c1 01             	add    $0x1,%ecx
  800b86:	bf 01 00 00 00       	mov    $0x1,%edi

	// hex or octal base prefix
	if ((base == 0 || base == 16) && (s[0] == '0' && s[1] == 'x'))
  800b8b:	f7 c3 ef ff ff ff    	test   $0xffffffef,%ebx
  800b91:	75 15                	jne    800ba8 <strtol+0x58>
  800b93:	80 39 30             	cmpb   $0x30,(%ecx)
  800b96:	75 10                	jne    800ba8 <strtol+0x58>
  800b98:	80 79 01 78          	cmpb   $0x78,0x1(%ecx)
  800b9c:	75 7c                	jne    800c1a <strtol+0xca>
		s += 2, base = 16;
  800b9e:	83 c1 02             	add    $0x2,%ecx
  800ba1:	bb 10 00 00 00       	mov    $0x10,%ebx
  800ba6:	eb 16                	jmp    800bbe <strtol+0x6e>
	else if (base == 0 && s[0] == '0')
  800ba8:	85 db                	test   %ebx,%ebx
  800baa:	75 12                	jne    800bbe <strtol+0x6e>
		s++, base = 8;
	else if (base == 0)
		base = 10;
  800bac:	bb 0a 00 00 00       	mov    $0xa,%ebx
		s++, neg = 1;

	// hex or octal base prefix
	if ((base == 0 || base == 16) && (s[0] == '0' && s[1] == 'x'))
		s += 2, base = 16;
	else if (base == 0 && s[0] == '0')
  800bb1:	80 39 30             	cmpb   $0x30,(%ecx)
  800bb4:	75 08                	jne    800bbe <strtol+0x6e>
		s++, base = 8;
  800bb6:	83 c1 01             	add    $0x1,%ecx
  800bb9:	bb 08 00 00 00       	mov    $0x8,%ebx
	else if (base == 0)
		base = 10;
  800bbe:	b8 00 00 00 00       	mov    $0x0,%eax
  800bc3:	89 5d 10             	mov    %ebx,0x10(%ebp)

	// digits
	while (1) {
		int dig;

		if (*s >= '0' && *s <= '9')
  800bc6:	0f b6 11             	movzbl (%ecx),%edx
  800bc9:	8d 72 d0             	lea    -0x30(%edx),%esi
  800bcc:	89 f3                	mov    %esi,%ebx
  800bce:	80 fb 09             	cmp    $0x9,%bl
  800bd1:	77 08                	ja     800bdb <strtol+0x8b>
			dig = *s - '0';
  800bd3:	0f be d2             	movsbl %dl,%edx
  800bd6:	83 ea 30             	sub    $0x30,%edx
  800bd9:	eb 22                	jmp    800bfd <strtol+0xad>
		else if (*s >= 'a' && *s <= 'z')
  800bdb:	8d 72 9f             	lea    -0x61(%edx),%esi
  800bde:	89 f3                	mov    %esi,%ebx
  800be0:	80 fb 19             	cmp    $0x19,%bl
  800be3:	77 08                	ja     800bed <strtol+0x9d>
			dig = *s - 'a' + 10;
  800be5:	0f be d2             	movsbl %dl,%edx
  800be8:	83 ea 57             	sub    $0x57,%edx
  800beb:	eb 10                	jmp    800bfd <strtol+0xad>
		else if (*s >= 'A' && *s <= 'Z')
  800bed:	8d 72 bf             	lea    -0x41(%edx),%esi
  800bf0:	89 f3                	mov    %esi,%ebx
  800bf2:	80 fb 19             	cmp    $0x19,%bl
  800bf5:	77 16                	ja     800c0d <strtol+0xbd>
			dig = *s - 'A' + 10;
  800bf7:	0f be d2             	movsbl %dl,%edx
  800bfa:	83 ea 37             	sub    $0x37,%edx
		else
			break;
		if (dig >= base)
  800bfd:	3b 55 10             	cmp    0x10(%ebp),%edx
  800c00:	7d 0b                	jge    800c0d <strtol+0xbd>
			break;
		s++, val = (val * base) + dig;
  800c02:	83 c1 01             	add    $0x1,%ecx
  800c05:	0f af 45 10          	imul   0x10(%ebp),%eax
  800c09:	01 d0                	add    %edx,%eax
		// we don't properly detect overflow!
	}
  800c0b:	eb b9                	jmp    800bc6 <strtol+0x76>

	if (endptr)
  800c0d:	83 7d 0c 00          	cmpl   $0x0,0xc(%ebp)
  800c11:	74 0d                	je     800c20 <strtol+0xd0>
		*endptr = (char *) s;
  800c13:	8b 75 0c             	mov    0xc(%ebp),%esi
  800c16:	89 0e                	mov    %ecx,(%esi)
  800c18:	eb 06                	jmp    800c20 <strtol+0xd0>
		s++, neg = 1;

	// hex or octal base prefix
	if ((base == 0 || base == 16) && (s[0] == '0' && s[1] == 'x'))
		s += 2, base = 16;
	else if (base == 0 && s[0] == '0')
  800c1a:	85 db                	test   %ebx,%ebx
  800c1c:	74 98                	je     800bb6 <strtol+0x66>
  800c1e:	eb 9e                	jmp    800bbe <strtol+0x6e>
		// we don't properly detect overflow!
	}

	if (endptr)
		*endptr = (char *) s;
	return (neg ? -val : val);
  800c20:	89 c2                	mov    %eax,%edx
  800c22:	f7 da                	neg    %edx
  800c24:	85 ff                	test   %edi,%edi
  800c26:	0f 45 c2             	cmovne %edx,%eax
}
  800c29:	5b                   	pop    %ebx
  800c2a:	5e                   	pop    %esi
  800c2b:	5f                   	pop    %edi
  800c2c:	5d                   	pop    %ebp
  800c2d:	c3                   	ret    
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
