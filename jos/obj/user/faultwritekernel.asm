
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
  800045:	56                   	push   %esi
  800046:	53                   	push   %ebx
  800047:	8b 5d 08             	mov    0x8(%ebp),%ebx
  80004a:	8b 75 0c             	mov    0xc(%ebp),%esi
	// set thisenv to point at our Env structure in envs[].
	// LAB 3: Your code here.
	envid_t id = sys_getenvid();
  80004d:	e8 02 01 00 00       	call   800154 <sys_getenvid>
	if (id >= 0)
  800052:	85 c0                	test   %eax,%eax
  800054:	78 12                	js     800068 <libmain+0x26>
		thisenv = &envs[ENVX(id)];
  800056:	25 ff 03 00 00       	and    $0x3ff,%eax
  80005b:	6b c0 7c             	imul   $0x7c,%eax,%eax
  80005e:	05 00 00 c0 ee       	add    $0xeec00000,%eax
  800063:	a3 04 20 80 00       	mov    %eax,0x802004

	// save the name of the program so that panic() can use it
	if (argc > 0)
  800068:	85 db                	test   %ebx,%ebx
  80006a:	7e 07                	jle    800073 <libmain+0x31>
		binaryname = argv[0];
  80006c:	8b 06                	mov    (%esi),%eax
  80006e:	a3 00 20 80 00       	mov    %eax,0x802000

	// call user main routine
	umain(argc, argv);
  800073:	83 ec 08             	sub    $0x8,%esp
  800076:	56                   	push   %esi
  800077:	53                   	push   %ebx
  800078:	e8 b6 ff ff ff       	call   800033 <umain>

	// exit gracefully
	exit();
  80007d:	e8 0a 00 00 00       	call   80008c <exit>
}
  800082:	83 c4 10             	add    $0x10,%esp
  800085:	8d 65 f8             	lea    -0x8(%ebp),%esp
  800088:	5b                   	pop    %ebx
  800089:	5e                   	pop    %esi
  80008a:	5d                   	pop    %ebp
  80008b:	c3                   	ret    

0080008c <exit>:

#include <inc/lib.h>

void
exit(void)
{
  80008c:	55                   	push   %ebp
  80008d:	89 e5                	mov    %esp,%ebp
  80008f:	83 ec 14             	sub    $0x14,%esp
	sys_env_destroy(0);
  800092:	6a 00                	push   $0x0
  800094:	e8 99 00 00 00       	call   800132 <sys_env_destroy>
}
  800099:	83 c4 10             	add    $0x10,%esp
  80009c:	c9                   	leave  
  80009d:	c3                   	ret    

0080009e <syscall>:
#include <inc/syscall.h>
#include <inc/lib.h>

static inline int32_t
syscall(int num, int check, uint32_t a1, uint32_t a2, uint32_t a3, uint32_t a4, uint32_t a5)
{
  80009e:	55                   	push   %ebp
  80009f:	89 e5                	mov    %esp,%ebp
  8000a1:	57                   	push   %edi
  8000a2:	56                   	push   %esi
  8000a3:	53                   	push   %ebx
  8000a4:	83 ec 1c             	sub    $0x1c,%esp
  8000a7:	89 45 e0             	mov    %eax,-0x20(%ebp)
  8000aa:	89 55 e4             	mov    %edx,-0x1c(%ebp)
  8000ad:	89 ca                	mov    %ecx,%edx
	//
	// The last clause tells the assembler that this can
	// potentially change the condition codes and arbitrary
	// memory locations.

	asm volatile("int %1\n"
  8000af:	8b 4d 08             	mov    0x8(%ebp),%ecx
  8000b2:	8b 5d 0c             	mov    0xc(%ebp),%ebx
  8000b5:	8b 7d 10             	mov    0x10(%ebp),%edi
  8000b8:	8b 75 14             	mov    0x14(%ebp),%esi
  8000bb:	cd 30                	int    $0x30
		       "b" (a3),
		       "D" (a4),
		       "S" (a5)
		     : "cc", "memory");

	if(check && ret > 0)
  8000bd:	83 7d e4 00          	cmpl   $0x0,-0x1c(%ebp)
  8000c1:	74 1d                	je     8000e0 <syscall+0x42>
  8000c3:	85 c0                	test   %eax,%eax
  8000c5:	7e 19                	jle    8000e0 <syscall+0x42>
  8000c7:	8b 55 e0             	mov    -0x20(%ebp),%edx
		panic("syscall %d returned %d (> 0)", num, ret);
  8000ca:	83 ec 0c             	sub    $0xc,%esp
  8000cd:	50                   	push   %eax
  8000ce:	52                   	push   %edx
  8000cf:	68 ca 0e 80 00       	push   $0x800eca
  8000d4:	6a 23                	push   $0x23
  8000d6:	68 e7 0e 80 00       	push   $0x800ee7
  8000db:	e8 b9 01 00 00       	call   800299 <_panic>

	return ret;
}
  8000e0:	8d 65 f4             	lea    -0xc(%ebp),%esp
  8000e3:	5b                   	pop    %ebx
  8000e4:	5e                   	pop    %esi
  8000e5:	5f                   	pop    %edi
  8000e6:	5d                   	pop    %ebp
  8000e7:	c3                   	ret    

008000e8 <sys_cputs>:

void
sys_cputs(const char *s, size_t len)
{
  8000e8:	55                   	push   %ebp
  8000e9:	89 e5                	mov    %esp,%ebp
  8000eb:	83 ec 08             	sub    $0x8,%esp
	syscall(SYS_cputs, 0, (uint32_t)s, len, 0, 0, 0);
  8000ee:	6a 00                	push   $0x0
  8000f0:	6a 00                	push   $0x0
  8000f2:	6a 00                	push   $0x0
  8000f4:	ff 75 0c             	pushl  0xc(%ebp)
  8000f7:	8b 4d 08             	mov    0x8(%ebp),%ecx
  8000fa:	ba 00 00 00 00       	mov    $0x0,%edx
  8000ff:	b8 00 00 00 00       	mov    $0x0,%eax
  800104:	e8 95 ff ff ff       	call   80009e <syscall>
}
  800109:	83 c4 10             	add    $0x10,%esp
  80010c:	c9                   	leave  
  80010d:	c3                   	ret    

0080010e <sys_cgetc>:

int
sys_cgetc(void)
{
  80010e:	55                   	push   %ebp
  80010f:	89 e5                	mov    %esp,%ebp
  800111:	83 ec 08             	sub    $0x8,%esp
	return syscall(SYS_cgetc, 0, 0, 0, 0, 0, 0);
  800114:	6a 00                	push   $0x0
  800116:	6a 00                	push   $0x0
  800118:	6a 00                	push   $0x0
  80011a:	6a 00                	push   $0x0
  80011c:	b9 00 00 00 00       	mov    $0x0,%ecx
  800121:	ba 00 00 00 00       	mov    $0x0,%edx
  800126:	b8 01 00 00 00       	mov    $0x1,%eax
  80012b:	e8 6e ff ff ff       	call   80009e <syscall>
}
  800130:	c9                   	leave  
  800131:	c3                   	ret    

00800132 <sys_env_destroy>:

int
sys_env_destroy(envid_t envid)
{
  800132:	55                   	push   %ebp
  800133:	89 e5                	mov    %esp,%ebp
  800135:	83 ec 08             	sub    $0x8,%esp
	return syscall(SYS_env_destroy, 1, envid, 0, 0, 0, 0);
  800138:	6a 00                	push   $0x0
  80013a:	6a 00                	push   $0x0
  80013c:	6a 00                	push   $0x0
  80013e:	6a 00                	push   $0x0
  800140:	8b 4d 08             	mov    0x8(%ebp),%ecx
  800143:	ba 01 00 00 00       	mov    $0x1,%edx
  800148:	b8 03 00 00 00       	mov    $0x3,%eax
  80014d:	e8 4c ff ff ff       	call   80009e <syscall>
}
  800152:	c9                   	leave  
  800153:	c3                   	ret    

00800154 <sys_getenvid>:

envid_t
sys_getenvid(void)
{
  800154:	55                   	push   %ebp
  800155:	89 e5                	mov    %esp,%ebp
  800157:	83 ec 08             	sub    $0x8,%esp
	 return syscall(SYS_getenvid, 0, 0, 0, 0, 0, 0);
  80015a:	6a 00                	push   $0x0
  80015c:	6a 00                	push   $0x0
  80015e:	6a 00                	push   $0x0
  800160:	6a 00                	push   $0x0
  800162:	b9 00 00 00 00       	mov    $0x0,%ecx
  800167:	ba 00 00 00 00       	mov    $0x0,%edx
  80016c:	b8 02 00 00 00       	mov    $0x2,%eax
  800171:	e8 28 ff ff ff       	call   80009e <syscall>
}
  800176:	c9                   	leave  
  800177:	c3                   	ret    

00800178 <sys_yield>:

void
sys_yield(void)
{
  800178:	55                   	push   %ebp
  800179:	89 e5                	mov    %esp,%ebp
  80017b:	83 ec 08             	sub    $0x8,%esp
	syscall(SYS_yield, 0, 0, 0, 0, 0, 0);
  80017e:	6a 00                	push   $0x0
  800180:	6a 00                	push   $0x0
  800182:	6a 00                	push   $0x0
  800184:	6a 00                	push   $0x0
  800186:	b9 00 00 00 00       	mov    $0x0,%ecx
  80018b:	ba 00 00 00 00       	mov    $0x0,%edx
  800190:	b8 0a 00 00 00       	mov    $0xa,%eax
  800195:	e8 04 ff ff ff       	call   80009e <syscall>
}
  80019a:	83 c4 10             	add    $0x10,%esp
  80019d:	c9                   	leave  
  80019e:	c3                   	ret    

0080019f <sys_page_alloc>:

int
sys_page_alloc(envid_t envid, void *va, int perm)
{
  80019f:	55                   	push   %ebp
  8001a0:	89 e5                	mov    %esp,%ebp
  8001a2:	83 ec 08             	sub    $0x8,%esp
	return syscall(SYS_page_alloc, 1, envid, (uint32_t) va, perm, 0, 0);
  8001a5:	6a 00                	push   $0x0
  8001a7:	6a 00                	push   $0x0
  8001a9:	ff 75 10             	pushl  0x10(%ebp)
  8001ac:	ff 75 0c             	pushl  0xc(%ebp)
  8001af:	8b 4d 08             	mov    0x8(%ebp),%ecx
  8001b2:	ba 01 00 00 00       	mov    $0x1,%edx
  8001b7:	b8 04 00 00 00       	mov    $0x4,%eax
  8001bc:	e8 dd fe ff ff       	call   80009e <syscall>
}
  8001c1:	c9                   	leave  
  8001c2:	c3                   	ret    

008001c3 <sys_page_map>:

int
sys_page_map(envid_t srcenv, void *srcva, envid_t dstenv, void *dstva, int perm)
{
  8001c3:	55                   	push   %ebp
  8001c4:	89 e5                	mov    %esp,%ebp
  8001c6:	83 ec 08             	sub    $0x8,%esp
	return syscall(SYS_page_map, 1, srcenv, (uint32_t) srcva, dstenv, (uint32_t) dstva, perm);
  8001c9:	ff 75 18             	pushl  0x18(%ebp)
  8001cc:	ff 75 14             	pushl  0x14(%ebp)
  8001cf:	ff 75 10             	pushl  0x10(%ebp)
  8001d2:	ff 75 0c             	pushl  0xc(%ebp)
  8001d5:	8b 4d 08             	mov    0x8(%ebp),%ecx
  8001d8:	ba 01 00 00 00       	mov    $0x1,%edx
  8001dd:	b8 05 00 00 00       	mov    $0x5,%eax
  8001e2:	e8 b7 fe ff ff       	call   80009e <syscall>
}
  8001e7:	c9                   	leave  
  8001e8:	c3                   	ret    

008001e9 <sys_page_unmap>:

int
sys_page_unmap(envid_t envid, void *va)
{
  8001e9:	55                   	push   %ebp
  8001ea:	89 e5                	mov    %esp,%ebp
  8001ec:	83 ec 08             	sub    $0x8,%esp
	return syscall(SYS_page_unmap, 1, envid, (uint32_t) va, 0, 0, 0);
  8001ef:	6a 00                	push   $0x0
  8001f1:	6a 00                	push   $0x0
  8001f3:	6a 00                	push   $0x0
  8001f5:	ff 75 0c             	pushl  0xc(%ebp)
  8001f8:	8b 4d 08             	mov    0x8(%ebp),%ecx
  8001fb:	ba 01 00 00 00       	mov    $0x1,%edx
  800200:	b8 06 00 00 00       	mov    $0x6,%eax
  800205:	e8 94 fe ff ff       	call   80009e <syscall>
}
  80020a:	c9                   	leave  
  80020b:	c3                   	ret    

0080020c <sys_env_set_status>:

// sys_exofork is inlined in lib.h

int
sys_env_set_status(envid_t envid, int status)
{
  80020c:	55                   	push   %ebp
  80020d:	89 e5                	mov    %esp,%ebp
  80020f:	83 ec 08             	sub    $0x8,%esp
	return syscall(SYS_env_set_status, 1, envid, status, 0, 0, 0);
  800212:	6a 00                	push   $0x0
  800214:	6a 00                	push   $0x0
  800216:	6a 00                	push   $0x0
  800218:	ff 75 0c             	pushl  0xc(%ebp)
  80021b:	8b 4d 08             	mov    0x8(%ebp),%ecx
  80021e:	ba 01 00 00 00       	mov    $0x1,%edx
  800223:	b8 08 00 00 00       	mov    $0x8,%eax
  800228:	e8 71 fe ff ff       	call   80009e <syscall>
}
  80022d:	c9                   	leave  
  80022e:	c3                   	ret    

0080022f <sys_env_set_pgfault_upcall>:

int
sys_env_set_pgfault_upcall(envid_t envid, void *upcall)
{
  80022f:	55                   	push   %ebp
  800230:	89 e5                	mov    %esp,%ebp
  800232:	83 ec 08             	sub    $0x8,%esp
	return syscall(SYS_env_set_pgfault_upcall, 1, envid, (uint32_t) upcall, 0, 0, 0);
  800235:	6a 00                	push   $0x0
  800237:	6a 00                	push   $0x0
  800239:	6a 00                	push   $0x0
  80023b:	ff 75 0c             	pushl  0xc(%ebp)
  80023e:	8b 4d 08             	mov    0x8(%ebp),%ecx
  800241:	ba 01 00 00 00       	mov    $0x1,%edx
  800246:	b8 09 00 00 00       	mov    $0x9,%eax
  80024b:	e8 4e fe ff ff       	call   80009e <syscall>
}
  800250:	c9                   	leave  
  800251:	c3                   	ret    

00800252 <sys_ipc_try_send>:

int
sys_ipc_try_send(envid_t envid, uint32_t value, void *srcva, int perm)
{
  800252:	55                   	push   %ebp
  800253:	89 e5                	mov    %esp,%ebp
  800255:	83 ec 08             	sub    $0x8,%esp
	return syscall(SYS_ipc_try_send, 0, envid, value, (uint32_t) srcva, perm, 0);
  800258:	6a 00                	push   $0x0
  80025a:	ff 75 14             	pushl  0x14(%ebp)
  80025d:	ff 75 10             	pushl  0x10(%ebp)
  800260:	ff 75 0c             	pushl  0xc(%ebp)
  800263:	8b 4d 08             	mov    0x8(%ebp),%ecx
  800266:	ba 00 00 00 00       	mov    $0x0,%edx
  80026b:	b8 0b 00 00 00       	mov    $0xb,%eax
  800270:	e8 29 fe ff ff       	call   80009e <syscall>
}
  800275:	c9                   	leave  
  800276:	c3                   	ret    

00800277 <sys_ipc_recv>:

int
sys_ipc_recv(void *dstva)
{
  800277:	55                   	push   %ebp
  800278:	89 e5                	mov    %esp,%ebp
  80027a:	83 ec 08             	sub    $0x8,%esp
	return syscall(SYS_ipc_recv, 1, (uint32_t)dstva, 0, 0, 0, 0);
  80027d:	6a 00                	push   $0x0
  80027f:	6a 00                	push   $0x0
  800281:	6a 00                	push   $0x0
  800283:	6a 00                	push   $0x0
  800285:	8b 4d 08             	mov    0x8(%ebp),%ecx
  800288:	ba 01 00 00 00       	mov    $0x1,%edx
  80028d:	b8 0c 00 00 00       	mov    $0xc,%eax
  800292:	e8 07 fe ff ff       	call   80009e <syscall>
}
  800297:	c9                   	leave  
  800298:	c3                   	ret    

00800299 <_panic>:
 * It prints "panic: <message>", then causes a breakpoint exception,
 * which causes JOS to enter the JOS kernel monitor.
 */
void
_panic(const char *file, int line, const char *fmt, ...)
{
  800299:	55                   	push   %ebp
  80029a:	89 e5                	mov    %esp,%ebp
  80029c:	56                   	push   %esi
  80029d:	53                   	push   %ebx
	va_list ap;

	va_start(ap, fmt);
  80029e:	8d 5d 14             	lea    0x14(%ebp),%ebx

	// Print the panic message
	cprintf("[%08x] user panic in %s at %s:%d: ",
  8002a1:	8b 35 00 20 80 00    	mov    0x802000,%esi
  8002a7:	e8 a8 fe ff ff       	call   800154 <sys_getenvid>
  8002ac:	83 ec 0c             	sub    $0xc,%esp
  8002af:	ff 75 0c             	pushl  0xc(%ebp)
  8002b2:	ff 75 08             	pushl  0x8(%ebp)
  8002b5:	56                   	push   %esi
  8002b6:	50                   	push   %eax
  8002b7:	68 f8 0e 80 00       	push   $0x800ef8
  8002bc:	e8 b1 00 00 00       	call   800372 <cprintf>
		sys_getenvid(), binaryname, file, line);
	vcprintf(fmt, ap);
  8002c1:	83 c4 18             	add    $0x18,%esp
  8002c4:	53                   	push   %ebx
  8002c5:	ff 75 10             	pushl  0x10(%ebp)
  8002c8:	e8 54 00 00 00       	call   800321 <vcprintf>
	cprintf("\n");
  8002cd:	c7 04 24 1c 0f 80 00 	movl   $0x800f1c,(%esp)
  8002d4:	e8 99 00 00 00       	call   800372 <cprintf>
  8002d9:	83 c4 10             	add    $0x10,%esp

	// Cause a breakpoint exception
	while (1)
		asm volatile("int3");
  8002dc:	cc                   	int3   
  8002dd:	eb fd                	jmp    8002dc <_panic+0x43>

008002df <putch>:
};


static void
putch(int ch, struct printbuf *b)
{
  8002df:	55                   	push   %ebp
  8002e0:	89 e5                	mov    %esp,%ebp
  8002e2:	53                   	push   %ebx
  8002e3:	83 ec 04             	sub    $0x4,%esp
  8002e6:	8b 5d 0c             	mov    0xc(%ebp),%ebx
	b->buf[b->idx++] = ch;
  8002e9:	8b 13                	mov    (%ebx),%edx
  8002eb:	8d 42 01             	lea    0x1(%edx),%eax
  8002ee:	89 03                	mov    %eax,(%ebx)
  8002f0:	8b 4d 08             	mov    0x8(%ebp),%ecx
  8002f3:	88 4c 13 08          	mov    %cl,0x8(%ebx,%edx,1)
	if (b->idx == 256-1) {
  8002f7:	3d ff 00 00 00       	cmp    $0xff,%eax
  8002fc:	75 1a                	jne    800318 <putch+0x39>
		sys_cputs(b->buf, b->idx);
  8002fe:	83 ec 08             	sub    $0x8,%esp
  800301:	68 ff 00 00 00       	push   $0xff
  800306:	8d 43 08             	lea    0x8(%ebx),%eax
  800309:	50                   	push   %eax
  80030a:	e8 d9 fd ff ff       	call   8000e8 <sys_cputs>
		b->idx = 0;
  80030f:	c7 03 00 00 00 00    	movl   $0x0,(%ebx)
  800315:	83 c4 10             	add    $0x10,%esp
	}
	b->cnt++;
  800318:	83 43 04 01          	addl   $0x1,0x4(%ebx)
}
  80031c:	8b 5d fc             	mov    -0x4(%ebp),%ebx
  80031f:	c9                   	leave  
  800320:	c3                   	ret    

00800321 <vcprintf>:

int
vcprintf(const char *fmt, va_list ap)
{
  800321:	55                   	push   %ebp
  800322:	89 e5                	mov    %esp,%ebp
  800324:	81 ec 18 01 00 00    	sub    $0x118,%esp
	struct printbuf b;

	b.idx = 0;
  80032a:	c7 85 f0 fe ff ff 00 	movl   $0x0,-0x110(%ebp)
  800331:	00 00 00 
	b.cnt = 0;
  800334:	c7 85 f4 fe ff ff 00 	movl   $0x0,-0x10c(%ebp)
  80033b:	00 00 00 
	vprintfmt((void*)putch, &b, fmt, ap);
  80033e:	ff 75 0c             	pushl  0xc(%ebp)
  800341:	ff 75 08             	pushl  0x8(%ebp)
  800344:	8d 85 f0 fe ff ff    	lea    -0x110(%ebp),%eax
  80034a:	50                   	push   %eax
  80034b:	68 df 02 80 00       	push   $0x8002df
  800350:	e8 86 01 00 00       	call   8004db <vprintfmt>
	sys_cputs(b.buf, b.idx);
  800355:	83 c4 08             	add    $0x8,%esp
  800358:	ff b5 f0 fe ff ff    	pushl  -0x110(%ebp)
  80035e:	8d 85 f8 fe ff ff    	lea    -0x108(%ebp),%eax
  800364:	50                   	push   %eax
  800365:	e8 7e fd ff ff       	call   8000e8 <sys_cputs>

	return b.cnt;
}
  80036a:	8b 85 f4 fe ff ff    	mov    -0x10c(%ebp),%eax
  800370:	c9                   	leave  
  800371:	c3                   	ret    

00800372 <cprintf>:

int
cprintf(const char *fmt, ...)
{
  800372:	55                   	push   %ebp
  800373:	89 e5                	mov    %esp,%ebp
  800375:	83 ec 10             	sub    $0x10,%esp
	va_list ap;
	int cnt;

	va_start(ap, fmt);
  800378:	8d 45 0c             	lea    0xc(%ebp),%eax
	cnt = vcprintf(fmt, ap);
  80037b:	50                   	push   %eax
  80037c:	ff 75 08             	pushl  0x8(%ebp)
  80037f:	e8 9d ff ff ff       	call   800321 <vcprintf>
	va_end(ap);

	return cnt;
}
  800384:	c9                   	leave  
  800385:	c3                   	ret    

00800386 <printnum>:
 * using specified putch function and associated pointer putdat.
 */
static void
printnum(void (*putch)(int, void*), void *putdat,
	 unsigned long long num, unsigned base, int width, int padc)
{
  800386:	55                   	push   %ebp
  800387:	89 e5                	mov    %esp,%ebp
  800389:	57                   	push   %edi
  80038a:	56                   	push   %esi
  80038b:	53                   	push   %ebx
  80038c:	83 ec 1c             	sub    $0x1c,%esp
  80038f:	89 c7                	mov    %eax,%edi
  800391:	89 d6                	mov    %edx,%esi
  800393:	8b 45 08             	mov    0x8(%ebp),%eax
  800396:	8b 55 0c             	mov    0xc(%ebp),%edx
  800399:	89 45 d8             	mov    %eax,-0x28(%ebp)
  80039c:	89 55 dc             	mov    %edx,-0x24(%ebp)
	// first recursively print all preceding (more significant) digits
	if (num >= base) {
  80039f:	8b 4d 10             	mov    0x10(%ebp),%ecx
  8003a2:	bb 00 00 00 00       	mov    $0x0,%ebx
  8003a7:	89 4d e0             	mov    %ecx,-0x20(%ebp)
  8003aa:	89 5d e4             	mov    %ebx,-0x1c(%ebp)
  8003ad:	39 d3                	cmp    %edx,%ebx
  8003af:	72 05                	jb     8003b6 <printnum+0x30>
  8003b1:	39 45 10             	cmp    %eax,0x10(%ebp)
  8003b4:	77 45                	ja     8003fb <printnum+0x75>
		printnum(putch, putdat, num / base, base, width - 1, padc);
  8003b6:	83 ec 0c             	sub    $0xc,%esp
  8003b9:	ff 75 18             	pushl  0x18(%ebp)
  8003bc:	8b 45 14             	mov    0x14(%ebp),%eax
  8003bf:	8d 58 ff             	lea    -0x1(%eax),%ebx
  8003c2:	53                   	push   %ebx
  8003c3:	ff 75 10             	pushl  0x10(%ebp)
  8003c6:	83 ec 08             	sub    $0x8,%esp
  8003c9:	ff 75 e4             	pushl  -0x1c(%ebp)
  8003cc:	ff 75 e0             	pushl  -0x20(%ebp)
  8003cf:	ff 75 dc             	pushl  -0x24(%ebp)
  8003d2:	ff 75 d8             	pushl  -0x28(%ebp)
  8003d5:	e8 56 08 00 00       	call   800c30 <__udivdi3>
  8003da:	83 c4 18             	add    $0x18,%esp
  8003dd:	52                   	push   %edx
  8003de:	50                   	push   %eax
  8003df:	89 f2                	mov    %esi,%edx
  8003e1:	89 f8                	mov    %edi,%eax
  8003e3:	e8 9e ff ff ff       	call   800386 <printnum>
  8003e8:	83 c4 20             	add    $0x20,%esp
  8003eb:	eb 18                	jmp    800405 <printnum+0x7f>
	} else {
		// print any needed pad characters before first digit
		while (--width > 0)
			putch(padc, putdat);
  8003ed:	83 ec 08             	sub    $0x8,%esp
  8003f0:	56                   	push   %esi
  8003f1:	ff 75 18             	pushl  0x18(%ebp)
  8003f4:	ff d7                	call   *%edi
  8003f6:	83 c4 10             	add    $0x10,%esp
  8003f9:	eb 03                	jmp    8003fe <printnum+0x78>
  8003fb:	8b 5d 14             	mov    0x14(%ebp),%ebx
	// first recursively print all preceding (more significant) digits
	if (num >= base) {
		printnum(putch, putdat, num / base, base, width - 1, padc);
	} else {
		// print any needed pad characters before first digit
		while (--width > 0)
  8003fe:	83 eb 01             	sub    $0x1,%ebx
  800401:	85 db                	test   %ebx,%ebx
  800403:	7f e8                	jg     8003ed <printnum+0x67>
			putch(padc, putdat);
	}

	// then print this (the least significant) digit
	putch("0123456789abcdef"[num % base], putdat);
  800405:	83 ec 08             	sub    $0x8,%esp
  800408:	56                   	push   %esi
  800409:	83 ec 04             	sub    $0x4,%esp
  80040c:	ff 75 e4             	pushl  -0x1c(%ebp)
  80040f:	ff 75 e0             	pushl  -0x20(%ebp)
  800412:	ff 75 dc             	pushl  -0x24(%ebp)
  800415:	ff 75 d8             	pushl  -0x28(%ebp)
  800418:	e8 43 09 00 00       	call   800d60 <__umoddi3>
  80041d:	83 c4 14             	add    $0x14,%esp
  800420:	0f be 80 1e 0f 80 00 	movsbl 0x800f1e(%eax),%eax
  800427:	50                   	push   %eax
  800428:	ff d7                	call   *%edi
}
  80042a:	83 c4 10             	add    $0x10,%esp
  80042d:	8d 65 f4             	lea    -0xc(%ebp),%esp
  800430:	5b                   	pop    %ebx
  800431:	5e                   	pop    %esi
  800432:	5f                   	pop    %edi
  800433:	5d                   	pop    %ebp
  800434:	c3                   	ret    

00800435 <getuint>:

// Get an unsigned int of various possible sizes from a varargs list,
// depending on the lflag parameter.
static unsigned long long
getuint(va_list *ap, int lflag)
{
  800435:	55                   	push   %ebp
  800436:	89 e5                	mov    %esp,%ebp
	if (lflag >= 2)
  800438:	83 fa 01             	cmp    $0x1,%edx
  80043b:	7e 0e                	jle    80044b <getuint+0x16>
		return va_arg(*ap, unsigned long long);
  80043d:	8b 10                	mov    (%eax),%edx
  80043f:	8d 4a 08             	lea    0x8(%edx),%ecx
  800442:	89 08                	mov    %ecx,(%eax)
  800444:	8b 02                	mov    (%edx),%eax
  800446:	8b 52 04             	mov    0x4(%edx),%edx
  800449:	eb 22                	jmp    80046d <getuint+0x38>
	else if (lflag)
  80044b:	85 d2                	test   %edx,%edx
  80044d:	74 10                	je     80045f <getuint+0x2a>
		return va_arg(*ap, unsigned long);
  80044f:	8b 10                	mov    (%eax),%edx
  800451:	8d 4a 04             	lea    0x4(%edx),%ecx
  800454:	89 08                	mov    %ecx,(%eax)
  800456:	8b 02                	mov    (%edx),%eax
  800458:	ba 00 00 00 00       	mov    $0x0,%edx
  80045d:	eb 0e                	jmp    80046d <getuint+0x38>
	else
		return va_arg(*ap, unsigned int);
  80045f:	8b 10                	mov    (%eax),%edx
  800461:	8d 4a 04             	lea    0x4(%edx),%ecx
  800464:	89 08                	mov    %ecx,(%eax)
  800466:	8b 02                	mov    (%edx),%eax
  800468:	ba 00 00 00 00       	mov    $0x0,%edx
}
  80046d:	5d                   	pop    %ebp
  80046e:	c3                   	ret    

0080046f <getint>:

// Same as getuint but signed - can't use getuint
// because of sign extension
static long long
getint(va_list *ap, int lflag)
{
  80046f:	55                   	push   %ebp
  800470:	89 e5                	mov    %esp,%ebp
	if (lflag >= 2)
  800472:	83 fa 01             	cmp    $0x1,%edx
  800475:	7e 0e                	jle    800485 <getint+0x16>
		return va_arg(*ap, long long);
  800477:	8b 10                	mov    (%eax),%edx
  800479:	8d 4a 08             	lea    0x8(%edx),%ecx
  80047c:	89 08                	mov    %ecx,(%eax)
  80047e:	8b 02                	mov    (%edx),%eax
  800480:	8b 52 04             	mov    0x4(%edx),%edx
  800483:	eb 1a                	jmp    80049f <getint+0x30>
	else if (lflag)
  800485:	85 d2                	test   %edx,%edx
  800487:	74 0c                	je     800495 <getint+0x26>
		return va_arg(*ap, long);
  800489:	8b 10                	mov    (%eax),%edx
  80048b:	8d 4a 04             	lea    0x4(%edx),%ecx
  80048e:	89 08                	mov    %ecx,(%eax)
  800490:	8b 02                	mov    (%edx),%eax
  800492:	99                   	cltd   
  800493:	eb 0a                	jmp    80049f <getint+0x30>
	else
		return va_arg(*ap, int);
  800495:	8b 10                	mov    (%eax),%edx
  800497:	8d 4a 04             	lea    0x4(%edx),%ecx
  80049a:	89 08                	mov    %ecx,(%eax)
  80049c:	8b 02                	mov    (%edx),%eax
  80049e:	99                   	cltd   
}
  80049f:	5d                   	pop    %ebp
  8004a0:	c3                   	ret    

008004a1 <sprintputch>:
	int cnt;
};

static void
sprintputch(int ch, struct sprintbuf *b)
{
  8004a1:	55                   	push   %ebp
  8004a2:	89 e5                	mov    %esp,%ebp
  8004a4:	8b 45 0c             	mov    0xc(%ebp),%eax
	b->cnt++;
  8004a7:	83 40 08 01          	addl   $0x1,0x8(%eax)
	if (b->buf < b->ebuf)
  8004ab:	8b 10                	mov    (%eax),%edx
  8004ad:	3b 50 04             	cmp    0x4(%eax),%edx
  8004b0:	73 0a                	jae    8004bc <sprintputch+0x1b>
		*b->buf++ = ch;
  8004b2:	8d 4a 01             	lea    0x1(%edx),%ecx
  8004b5:	89 08                	mov    %ecx,(%eax)
  8004b7:	8b 45 08             	mov    0x8(%ebp),%eax
  8004ba:	88 02                	mov    %al,(%edx)
}
  8004bc:	5d                   	pop    %ebp
  8004bd:	c3                   	ret    

008004be <printfmt>:
	}
}

void
printfmt(void (*putch)(int, void*), void *putdat, const char *fmt, ...)
{
  8004be:	55                   	push   %ebp
  8004bf:	89 e5                	mov    %esp,%ebp
  8004c1:	83 ec 08             	sub    $0x8,%esp
	va_list ap;

	va_start(ap, fmt);
  8004c4:	8d 45 14             	lea    0x14(%ebp),%eax
	vprintfmt(putch, putdat, fmt, ap);
  8004c7:	50                   	push   %eax
  8004c8:	ff 75 10             	pushl  0x10(%ebp)
  8004cb:	ff 75 0c             	pushl  0xc(%ebp)
  8004ce:	ff 75 08             	pushl  0x8(%ebp)
  8004d1:	e8 05 00 00 00       	call   8004db <vprintfmt>
	va_end(ap);
}
  8004d6:	83 c4 10             	add    $0x10,%esp
  8004d9:	c9                   	leave  
  8004da:	c3                   	ret    

008004db <vprintfmt>:
// Main function to format and print a string.
void printfmt(void (*putch)(int, void*), void *putdat, const char *fmt, ...);

void
vprintfmt(void (*putch)(int, void*), void *putdat, const char *fmt, va_list ap)
{
  8004db:	55                   	push   %ebp
  8004dc:	89 e5                	mov    %esp,%ebp
  8004de:	57                   	push   %edi
  8004df:	56                   	push   %esi
  8004e0:	53                   	push   %ebx
  8004e1:	83 ec 2c             	sub    $0x2c,%esp
  8004e4:	8b 75 08             	mov    0x8(%ebp),%esi
  8004e7:	8b 5d 0c             	mov    0xc(%ebp),%ebx
  8004ea:	8b 7d 10             	mov    0x10(%ebp),%edi
  8004ed:	eb 12                	jmp    800501 <vprintfmt+0x26>
	int base, lflag, width, precision, altflag;
	char padc;

	while (1) {
		while ((ch = *(unsigned char *) fmt++) != '%') {
			if (ch == '\0')
  8004ef:	85 c0                	test   %eax,%eax
  8004f1:	0f 84 44 03 00 00    	je     80083b <vprintfmt+0x360>
				return;
			putch(ch, putdat);
  8004f7:	83 ec 08             	sub    $0x8,%esp
  8004fa:	53                   	push   %ebx
  8004fb:	50                   	push   %eax
  8004fc:	ff d6                	call   *%esi
  8004fe:	83 c4 10             	add    $0x10,%esp
	unsigned long long num;
	int base, lflag, width, precision, altflag;
	char padc;

	while (1) {
		while ((ch = *(unsigned char *) fmt++) != '%') {
  800501:	83 c7 01             	add    $0x1,%edi
  800504:	0f b6 47 ff          	movzbl -0x1(%edi),%eax
  800508:	83 f8 25             	cmp    $0x25,%eax
  80050b:	75 e2                	jne    8004ef <vprintfmt+0x14>
  80050d:	c6 45 d4 20          	movb   $0x20,-0x2c(%ebp)
  800511:	c7 45 d8 00 00 00 00 	movl   $0x0,-0x28(%ebp)
  800518:	c7 45 d0 ff ff ff ff 	movl   $0xffffffff,-0x30(%ebp)
  80051f:	c7 45 e0 ff ff ff ff 	movl   $0xffffffff,-0x20(%ebp)
  800526:	ba 00 00 00 00       	mov    $0x0,%edx
  80052b:	eb 07                	jmp    800534 <vprintfmt+0x59>
		width = -1;
		precision = -1;
		lflag = 0;
		altflag = 0;
	reswitch:
		switch (ch = *(unsigned char *) fmt++) {
  80052d:	8b 7d e4             	mov    -0x1c(%ebp),%edi

		// flag to pad on the right
		case '-':
			padc = '-';
  800530:	c6 45 d4 2d          	movb   $0x2d,-0x2c(%ebp)
		width = -1;
		precision = -1;
		lflag = 0;
		altflag = 0;
	reswitch:
		switch (ch = *(unsigned char *) fmt++) {
  800534:	8d 47 01             	lea    0x1(%edi),%eax
  800537:	89 45 e4             	mov    %eax,-0x1c(%ebp)
  80053a:	0f b6 07             	movzbl (%edi),%eax
  80053d:	0f b6 c8             	movzbl %al,%ecx
  800540:	83 e8 23             	sub    $0x23,%eax
  800543:	3c 55                	cmp    $0x55,%al
  800545:	0f 87 d5 02 00 00    	ja     800820 <vprintfmt+0x345>
  80054b:	0f b6 c0             	movzbl %al,%eax
  80054e:	ff 24 85 e0 0f 80 00 	jmp    *0x800fe0(,%eax,4)
  800555:	8b 7d e4             	mov    -0x1c(%ebp),%edi
			padc = '-';
			goto reswitch;

		// flag to pad with 0's instead of spaces
		case '0':
			padc = '0';
  800558:	c6 45 d4 30          	movb   $0x30,-0x2c(%ebp)
  80055c:	eb d6                	jmp    800534 <vprintfmt+0x59>
		width = -1;
		precision = -1;
		lflag = 0;
		altflag = 0;
	reswitch:
		switch (ch = *(unsigned char *) fmt++) {
  80055e:	8b 7d e4             	mov    -0x1c(%ebp),%edi
  800561:	b8 00 00 00 00       	mov    $0x0,%eax
  800566:	89 55 e4             	mov    %edx,-0x1c(%ebp)
		case '6':
		case '7':
		case '8':
		case '9':
			for (precision = 0; ; ++fmt) {
				precision = precision * 10 + ch - '0';
  800569:	8d 04 80             	lea    (%eax,%eax,4),%eax
  80056c:	8d 44 41 d0          	lea    -0x30(%ecx,%eax,2),%eax
				ch = *fmt;
  800570:	0f be 0f             	movsbl (%edi),%ecx
				if (ch < '0' || ch > '9')
  800573:	8d 51 d0             	lea    -0x30(%ecx),%edx
  800576:	83 fa 09             	cmp    $0x9,%edx
  800579:	77 39                	ja     8005b4 <vprintfmt+0xd9>
		case '5':
		case '6':
		case '7':
		case '8':
		case '9':
			for (precision = 0; ; ++fmt) {
  80057b:	83 c7 01             	add    $0x1,%edi
				precision = precision * 10 + ch - '0';
				ch = *fmt;
				if (ch < '0' || ch > '9')
					break;
			}
  80057e:	eb e9                	jmp    800569 <vprintfmt+0x8e>
			goto process_precision;

		case '*':
			precision = va_arg(ap, int);
  800580:	8b 45 14             	mov    0x14(%ebp),%eax
  800583:	8d 48 04             	lea    0x4(%eax),%ecx
  800586:	89 4d 14             	mov    %ecx,0x14(%ebp)
  800589:	8b 00                	mov    (%eax),%eax
  80058b:	89 45 d0             	mov    %eax,-0x30(%ebp)
		width = -1;
		precision = -1;
		lflag = 0;
		altflag = 0;
	reswitch:
		switch (ch = *(unsigned char *) fmt++) {
  80058e:	8b 7d e4             	mov    -0x1c(%ebp),%edi
			}
			goto process_precision;

		case '*':
			precision = va_arg(ap, int);
			goto process_precision;
  800591:	eb 27                	jmp    8005ba <vprintfmt+0xdf>
  800593:	8b 45 e0             	mov    -0x20(%ebp),%eax
  800596:	85 c0                	test   %eax,%eax
  800598:	b9 00 00 00 00       	mov    $0x0,%ecx
  80059d:	0f 49 c8             	cmovns %eax,%ecx
  8005a0:	89 4d e0             	mov    %ecx,-0x20(%ebp)
		width = -1;
		precision = -1;
		lflag = 0;
		altflag = 0;
	reswitch:
		switch (ch = *(unsigned char *) fmt++) {
  8005a3:	8b 7d e4             	mov    -0x1c(%ebp),%edi
  8005a6:	eb 8c                	jmp    800534 <vprintfmt+0x59>
  8005a8:	8b 7d e4             	mov    -0x1c(%ebp),%edi
			if (width < 0)
				width = 0;
			goto reswitch;

		case '#':
			altflag = 1;
  8005ab:	c7 45 d8 01 00 00 00 	movl   $0x1,-0x28(%ebp)
			goto reswitch;
  8005b2:	eb 80                	jmp    800534 <vprintfmt+0x59>
  8005b4:	8b 55 e4             	mov    -0x1c(%ebp),%edx
  8005b7:	89 45 d0             	mov    %eax,-0x30(%ebp)

		process_precision:
			if (width < 0)
  8005ba:	83 7d e0 00          	cmpl   $0x0,-0x20(%ebp)
  8005be:	0f 89 70 ff ff ff    	jns    800534 <vprintfmt+0x59>
				width = precision, precision = -1;
  8005c4:	8b 45 d0             	mov    -0x30(%ebp),%eax
  8005c7:	89 45 e0             	mov    %eax,-0x20(%ebp)
  8005ca:	c7 45 d0 ff ff ff ff 	movl   $0xffffffff,-0x30(%ebp)
  8005d1:	e9 5e ff ff ff       	jmp    800534 <vprintfmt+0x59>
			goto reswitch;

		// long flag (doubled for long long)
		case 'l':
			lflag++;
  8005d6:	83 c2 01             	add    $0x1,%edx
		width = -1;
		precision = -1;
		lflag = 0;
		altflag = 0;
	reswitch:
		switch (ch = *(unsigned char *) fmt++) {
  8005d9:	8b 7d e4             	mov    -0x1c(%ebp),%edi
			goto reswitch;

		// long flag (doubled for long long)
		case 'l':
			lflag++;
			goto reswitch;
  8005dc:	e9 53 ff ff ff       	jmp    800534 <vprintfmt+0x59>

		// character
		case 'c':
			putch(va_arg(ap, int), putdat);
  8005e1:	8b 45 14             	mov    0x14(%ebp),%eax
  8005e4:	8d 50 04             	lea    0x4(%eax),%edx
  8005e7:	89 55 14             	mov    %edx,0x14(%ebp)
  8005ea:	83 ec 08             	sub    $0x8,%esp
  8005ed:	53                   	push   %ebx
  8005ee:	ff 30                	pushl  (%eax)
  8005f0:	ff d6                	call   *%esi
			break;
  8005f2:	83 c4 10             	add    $0x10,%esp
		width = -1;
		precision = -1;
		lflag = 0;
		altflag = 0;
	reswitch:
		switch (ch = *(unsigned char *) fmt++) {
  8005f5:	8b 7d e4             	mov    -0x1c(%ebp),%edi
			goto reswitch;

		// character
		case 'c':
			putch(va_arg(ap, int), putdat);
			break;
  8005f8:	e9 04 ff ff ff       	jmp    800501 <vprintfmt+0x26>

		// error message
		case 'e':
			err = va_arg(ap, int);
  8005fd:	8b 45 14             	mov    0x14(%ebp),%eax
  800600:	8d 50 04             	lea    0x4(%eax),%edx
  800603:	89 55 14             	mov    %edx,0x14(%ebp)
  800606:	8b 00                	mov    (%eax),%eax
  800608:	99                   	cltd   
  800609:	31 d0                	xor    %edx,%eax
  80060b:	29 d0                	sub    %edx,%eax
			if (err < 0)
				err = -err;
			if (err >= MAXERROR || (p = error_string[err]) == NULL)
  80060d:	83 f8 08             	cmp    $0x8,%eax
  800610:	7f 0b                	jg     80061d <vprintfmt+0x142>
  800612:	8b 14 85 40 11 80 00 	mov    0x801140(,%eax,4),%edx
  800619:	85 d2                	test   %edx,%edx
  80061b:	75 18                	jne    800635 <vprintfmt+0x15a>
				printfmt(putch, putdat, "error %d", err);
  80061d:	50                   	push   %eax
  80061e:	68 36 0f 80 00       	push   $0x800f36
  800623:	53                   	push   %ebx
  800624:	56                   	push   %esi
  800625:	e8 94 fe ff ff       	call   8004be <printfmt>
  80062a:	83 c4 10             	add    $0x10,%esp
		width = -1;
		precision = -1;
		lflag = 0;
		altflag = 0;
	reswitch:
		switch (ch = *(unsigned char *) fmt++) {
  80062d:	8b 7d e4             	mov    -0x1c(%ebp),%edi
		case 'e':
			err = va_arg(ap, int);
			if (err < 0)
				err = -err;
			if (err >= MAXERROR || (p = error_string[err]) == NULL)
				printfmt(putch, putdat, "error %d", err);
  800630:	e9 cc fe ff ff       	jmp    800501 <vprintfmt+0x26>
			else
				printfmt(putch, putdat, "%s", p);
  800635:	52                   	push   %edx
  800636:	68 3f 0f 80 00       	push   $0x800f3f
  80063b:	53                   	push   %ebx
  80063c:	56                   	push   %esi
  80063d:	e8 7c fe ff ff       	call   8004be <printfmt>
  800642:	83 c4 10             	add    $0x10,%esp
		width = -1;
		precision = -1;
		lflag = 0;
		altflag = 0;
	reswitch:
		switch (ch = *(unsigned char *) fmt++) {
  800645:	8b 7d e4             	mov    -0x1c(%ebp),%edi
  800648:	e9 b4 fe ff ff       	jmp    800501 <vprintfmt+0x26>
				printfmt(putch, putdat, "%s", p);
			break;

		// string
		case 's':
			if ((p = va_arg(ap, char *)) == NULL)
  80064d:	8b 45 14             	mov    0x14(%ebp),%eax
  800650:	8d 50 04             	lea    0x4(%eax),%edx
  800653:	89 55 14             	mov    %edx,0x14(%ebp)
  800656:	8b 38                	mov    (%eax),%edi
				p = "(null)";
  800658:	85 ff                	test   %edi,%edi
  80065a:	b8 2f 0f 80 00       	mov    $0x800f2f,%eax
  80065f:	0f 44 f8             	cmove  %eax,%edi
			if (width > 0 && padc != '-')
  800662:	83 7d e0 00          	cmpl   $0x0,-0x20(%ebp)
  800666:	0f 8e 94 00 00 00    	jle    800700 <vprintfmt+0x225>
  80066c:	80 7d d4 2d          	cmpb   $0x2d,-0x2c(%ebp)
  800670:	0f 84 98 00 00 00    	je     80070e <vprintfmt+0x233>
				for (width -= strnlen(p, precision); width > 0; width--)
  800676:	83 ec 08             	sub    $0x8,%esp
  800679:	ff 75 d0             	pushl  -0x30(%ebp)
  80067c:	57                   	push   %edi
  80067d:	e8 41 02 00 00       	call   8008c3 <strnlen>
  800682:	8b 4d e0             	mov    -0x20(%ebp),%ecx
  800685:	29 c1                	sub    %eax,%ecx
  800687:	89 4d cc             	mov    %ecx,-0x34(%ebp)
  80068a:	83 c4 10             	add    $0x10,%esp
					putch(padc, putdat);
  80068d:	0f be 45 d4          	movsbl -0x2c(%ebp),%eax
  800691:	89 45 e0             	mov    %eax,-0x20(%ebp)
  800694:	89 7d d4             	mov    %edi,-0x2c(%ebp)
  800697:	89 cf                	mov    %ecx,%edi
		// string
		case 's':
			if ((p = va_arg(ap, char *)) == NULL)
				p = "(null)";
			if (width > 0 && padc != '-')
				for (width -= strnlen(p, precision); width > 0; width--)
  800699:	eb 0f                	jmp    8006aa <vprintfmt+0x1cf>
					putch(padc, putdat);
  80069b:	83 ec 08             	sub    $0x8,%esp
  80069e:	53                   	push   %ebx
  80069f:	ff 75 e0             	pushl  -0x20(%ebp)
  8006a2:	ff d6                	call   *%esi
		// string
		case 's':
			if ((p = va_arg(ap, char *)) == NULL)
				p = "(null)";
			if (width > 0 && padc != '-')
				for (width -= strnlen(p, precision); width > 0; width--)
  8006a4:	83 ef 01             	sub    $0x1,%edi
  8006a7:	83 c4 10             	add    $0x10,%esp
  8006aa:	85 ff                	test   %edi,%edi
  8006ac:	7f ed                	jg     80069b <vprintfmt+0x1c0>
  8006ae:	8b 7d d4             	mov    -0x2c(%ebp),%edi
  8006b1:	8b 4d cc             	mov    -0x34(%ebp),%ecx
  8006b4:	85 c9                	test   %ecx,%ecx
  8006b6:	b8 00 00 00 00       	mov    $0x0,%eax
  8006bb:	0f 49 c1             	cmovns %ecx,%eax
  8006be:	29 c1                	sub    %eax,%ecx
  8006c0:	89 75 08             	mov    %esi,0x8(%ebp)
  8006c3:	8b 75 d0             	mov    -0x30(%ebp),%esi
  8006c6:	89 5d 0c             	mov    %ebx,0xc(%ebp)
  8006c9:	89 cb                	mov    %ecx,%ebx
  8006cb:	eb 4d                	jmp    80071a <vprintfmt+0x23f>
					putch(padc, putdat);
			for (; (ch = *p++) != '\0' && (precision < 0 || --precision >= 0); width--)
				if (altflag && (ch < ' ' || ch > '~'))
  8006cd:	83 7d d8 00          	cmpl   $0x0,-0x28(%ebp)
  8006d1:	74 1b                	je     8006ee <vprintfmt+0x213>
  8006d3:	0f be c0             	movsbl %al,%eax
  8006d6:	83 e8 20             	sub    $0x20,%eax
  8006d9:	83 f8 5e             	cmp    $0x5e,%eax
  8006dc:	76 10                	jbe    8006ee <vprintfmt+0x213>
					putch('?', putdat);
  8006de:	83 ec 08             	sub    $0x8,%esp
  8006e1:	ff 75 0c             	pushl  0xc(%ebp)
  8006e4:	6a 3f                	push   $0x3f
  8006e6:	ff 55 08             	call   *0x8(%ebp)
  8006e9:	83 c4 10             	add    $0x10,%esp
  8006ec:	eb 0d                	jmp    8006fb <vprintfmt+0x220>
				else
					putch(ch, putdat);
  8006ee:	83 ec 08             	sub    $0x8,%esp
  8006f1:	ff 75 0c             	pushl  0xc(%ebp)
  8006f4:	52                   	push   %edx
  8006f5:	ff 55 08             	call   *0x8(%ebp)
  8006f8:	83 c4 10             	add    $0x10,%esp
			if ((p = va_arg(ap, char *)) == NULL)
				p = "(null)";
			if (width > 0 && padc != '-')
				for (width -= strnlen(p, precision); width > 0; width--)
					putch(padc, putdat);
			for (; (ch = *p++) != '\0' && (precision < 0 || --precision >= 0); width--)
  8006fb:	83 eb 01             	sub    $0x1,%ebx
  8006fe:	eb 1a                	jmp    80071a <vprintfmt+0x23f>
  800700:	89 75 08             	mov    %esi,0x8(%ebp)
  800703:	8b 75 d0             	mov    -0x30(%ebp),%esi
  800706:	89 5d 0c             	mov    %ebx,0xc(%ebp)
  800709:	8b 5d e0             	mov    -0x20(%ebp),%ebx
  80070c:	eb 0c                	jmp    80071a <vprintfmt+0x23f>
  80070e:	89 75 08             	mov    %esi,0x8(%ebp)
  800711:	8b 75 d0             	mov    -0x30(%ebp),%esi
  800714:	89 5d 0c             	mov    %ebx,0xc(%ebp)
  800717:	8b 5d e0             	mov    -0x20(%ebp),%ebx
  80071a:	83 c7 01             	add    $0x1,%edi
  80071d:	0f b6 47 ff          	movzbl -0x1(%edi),%eax
  800721:	0f be d0             	movsbl %al,%edx
  800724:	85 d2                	test   %edx,%edx
  800726:	74 23                	je     80074b <vprintfmt+0x270>
  800728:	85 f6                	test   %esi,%esi
  80072a:	78 a1                	js     8006cd <vprintfmt+0x1f2>
  80072c:	83 ee 01             	sub    $0x1,%esi
  80072f:	79 9c                	jns    8006cd <vprintfmt+0x1f2>
  800731:	89 df                	mov    %ebx,%edi
  800733:	8b 75 08             	mov    0x8(%ebp),%esi
  800736:	8b 5d 0c             	mov    0xc(%ebp),%ebx
  800739:	eb 18                	jmp    800753 <vprintfmt+0x278>
				if (altflag && (ch < ' ' || ch > '~'))
					putch('?', putdat);
				else
					putch(ch, putdat);
			for (; width > 0; width--)
				putch(' ', putdat);
  80073b:	83 ec 08             	sub    $0x8,%esp
  80073e:	53                   	push   %ebx
  80073f:	6a 20                	push   $0x20
  800741:	ff d6                	call   *%esi
			for (; (ch = *p++) != '\0' && (precision < 0 || --precision >= 0); width--)
				if (altflag && (ch < ' ' || ch > '~'))
					putch('?', putdat);
				else
					putch(ch, putdat);
			for (; width > 0; width--)
  800743:	83 ef 01             	sub    $0x1,%edi
  800746:	83 c4 10             	add    $0x10,%esp
  800749:	eb 08                	jmp    800753 <vprintfmt+0x278>
  80074b:	89 df                	mov    %ebx,%edi
  80074d:	8b 75 08             	mov    0x8(%ebp),%esi
  800750:	8b 5d 0c             	mov    0xc(%ebp),%ebx
  800753:	85 ff                	test   %edi,%edi
  800755:	7f e4                	jg     80073b <vprintfmt+0x260>
		width = -1;
		precision = -1;
		lflag = 0;
		altflag = 0;
	reswitch:
		switch (ch = *(unsigned char *) fmt++) {
  800757:	8b 7d e4             	mov    -0x1c(%ebp),%edi
  80075a:	e9 a2 fd ff ff       	jmp    800501 <vprintfmt+0x26>
				putch(' ', putdat);
			break;

		// (signed) decimal
		case 'd':
			num = getint(&ap, lflag);
  80075f:	8d 45 14             	lea    0x14(%ebp),%eax
  800762:	e8 08 fd ff ff       	call   80046f <getint>
  800767:	89 45 d8             	mov    %eax,-0x28(%ebp)
  80076a:	89 55 dc             	mov    %edx,-0x24(%ebp)
			if ((long long) num < 0) {
				putch('-', putdat);
				num = -(long long) num;
			}
			base = 10;
  80076d:	b9 0a 00 00 00       	mov    $0xa,%ecx
			break;

		// (signed) decimal
		case 'd':
			num = getint(&ap, lflag);
			if ((long long) num < 0) {
  800772:	83 7d dc 00          	cmpl   $0x0,-0x24(%ebp)
  800776:	79 74                	jns    8007ec <vprintfmt+0x311>
				putch('-', putdat);
  800778:	83 ec 08             	sub    $0x8,%esp
  80077b:	53                   	push   %ebx
  80077c:	6a 2d                	push   $0x2d
  80077e:	ff d6                	call   *%esi
				num = -(long long) num;
  800780:	8b 45 d8             	mov    -0x28(%ebp),%eax
  800783:	8b 55 dc             	mov    -0x24(%ebp),%edx
  800786:	f7 d8                	neg    %eax
  800788:	83 d2 00             	adc    $0x0,%edx
  80078b:	f7 da                	neg    %edx
  80078d:	83 c4 10             	add    $0x10,%esp
			}
			base = 10;
  800790:	b9 0a 00 00 00       	mov    $0xa,%ecx
  800795:	eb 55                	jmp    8007ec <vprintfmt+0x311>
			goto number;

		// unsigned decimal
		case 'u':
			num = getuint(&ap, lflag);
  800797:	8d 45 14             	lea    0x14(%ebp),%eax
  80079a:	e8 96 fc ff ff       	call   800435 <getuint>
			base = 10;
  80079f:	b9 0a 00 00 00       	mov    $0xa,%ecx
			goto number;
  8007a4:	eb 46                	jmp    8007ec <vprintfmt+0x311>

		// (unsigned) octal
		case 'o':
			num = getuint(&ap, lflag);
  8007a6:	8d 45 14             	lea    0x14(%ebp),%eax
  8007a9:	e8 87 fc ff ff       	call   800435 <getuint>
			base = 8;
  8007ae:	b9 08 00 00 00       	mov    $0x8,%ecx
			goto number;
  8007b3:	eb 37                	jmp    8007ec <vprintfmt+0x311>

		// pointer
		case 'p':
			putch('0', putdat);
  8007b5:	83 ec 08             	sub    $0x8,%esp
  8007b8:	53                   	push   %ebx
  8007b9:	6a 30                	push   $0x30
  8007bb:	ff d6                	call   *%esi
			putch('x', putdat);
  8007bd:	83 c4 08             	add    $0x8,%esp
  8007c0:	53                   	push   %ebx
  8007c1:	6a 78                	push   $0x78
  8007c3:	ff d6                	call   *%esi
			num = (unsigned long long)
				(uintptr_t) va_arg(ap, void *);
  8007c5:	8b 45 14             	mov    0x14(%ebp),%eax
  8007c8:	8d 50 04             	lea    0x4(%eax),%edx
  8007cb:	89 55 14             	mov    %edx,0x14(%ebp)

		// pointer
		case 'p':
			putch('0', putdat);
			putch('x', putdat);
			num = (unsigned long long)
  8007ce:	8b 00                	mov    (%eax),%eax
  8007d0:	ba 00 00 00 00       	mov    $0x0,%edx
				(uintptr_t) va_arg(ap, void *);
			base = 16;
			goto number;
  8007d5:	83 c4 10             	add    $0x10,%esp
		case 'p':
			putch('0', putdat);
			putch('x', putdat);
			num = (unsigned long long)
				(uintptr_t) va_arg(ap, void *);
			base = 16;
  8007d8:	b9 10 00 00 00       	mov    $0x10,%ecx
			goto number;
  8007dd:	eb 0d                	jmp    8007ec <vprintfmt+0x311>

		// (unsigned) hexadecimal
		case 'x':
			num = getuint(&ap, lflag);
  8007df:	8d 45 14             	lea    0x14(%ebp),%eax
  8007e2:	e8 4e fc ff ff       	call   800435 <getuint>
			base = 16;
  8007e7:	b9 10 00 00 00       	mov    $0x10,%ecx
		number:
			printnum(putch, putdat, num, base, width, padc);
  8007ec:	83 ec 0c             	sub    $0xc,%esp
  8007ef:	0f be 7d d4          	movsbl -0x2c(%ebp),%edi
  8007f3:	57                   	push   %edi
  8007f4:	ff 75 e0             	pushl  -0x20(%ebp)
  8007f7:	51                   	push   %ecx
  8007f8:	52                   	push   %edx
  8007f9:	50                   	push   %eax
  8007fa:	89 da                	mov    %ebx,%edx
  8007fc:	89 f0                	mov    %esi,%eax
  8007fe:	e8 83 fb ff ff       	call   800386 <printnum>
			break;
  800803:	83 c4 20             	add    $0x20,%esp
  800806:	8b 7d e4             	mov    -0x1c(%ebp),%edi
  800809:	e9 f3 fc ff ff       	jmp    800501 <vprintfmt+0x26>

		// escaped '%' character
		case '%':
			putch(ch, putdat);
  80080e:	83 ec 08             	sub    $0x8,%esp
  800811:	53                   	push   %ebx
  800812:	51                   	push   %ecx
  800813:	ff d6                	call   *%esi
			break;
  800815:	83 c4 10             	add    $0x10,%esp
		width = -1;
		precision = -1;
		lflag = 0;
		altflag = 0;
	reswitch:
		switch (ch = *(unsigned char *) fmt++) {
  800818:	8b 7d e4             	mov    -0x1c(%ebp),%edi
			break;

		// escaped '%' character
		case '%':
			putch(ch, putdat);
			break;
  80081b:	e9 e1 fc ff ff       	jmp    800501 <vprintfmt+0x26>

		// unrecognized escape sequence - just print it literally
		default:
			putch('%', putdat);
  800820:	83 ec 08             	sub    $0x8,%esp
  800823:	53                   	push   %ebx
  800824:	6a 25                	push   $0x25
  800826:	ff d6                	call   *%esi
			for (fmt--; fmt[-1] != '%'; fmt--)
  800828:	83 c4 10             	add    $0x10,%esp
  80082b:	eb 03                	jmp    800830 <vprintfmt+0x355>
  80082d:	83 ef 01             	sub    $0x1,%edi
  800830:	80 7f ff 25          	cmpb   $0x25,-0x1(%edi)
  800834:	75 f7                	jne    80082d <vprintfmt+0x352>
  800836:	e9 c6 fc ff ff       	jmp    800501 <vprintfmt+0x26>
				/* do nothing */;
			break;
		}
	}
}
  80083b:	8d 65 f4             	lea    -0xc(%ebp),%esp
  80083e:	5b                   	pop    %ebx
  80083f:	5e                   	pop    %esi
  800840:	5f                   	pop    %edi
  800841:	5d                   	pop    %ebp
  800842:	c3                   	ret    

00800843 <vsnprintf>:
		*b->buf++ = ch;
}

int
vsnprintf(char *buf, int n, const char *fmt, va_list ap)
{
  800843:	55                   	push   %ebp
  800844:	89 e5                	mov    %esp,%ebp
  800846:	83 ec 18             	sub    $0x18,%esp
  800849:	8b 45 08             	mov    0x8(%ebp),%eax
  80084c:	8b 55 0c             	mov    0xc(%ebp),%edx
	struct sprintbuf b = {buf, buf+n-1, 0};
  80084f:	89 45 ec             	mov    %eax,-0x14(%ebp)
  800852:	8d 4c 10 ff          	lea    -0x1(%eax,%edx,1),%ecx
  800856:	89 4d f0             	mov    %ecx,-0x10(%ebp)
  800859:	c7 45 f4 00 00 00 00 	movl   $0x0,-0xc(%ebp)

	if (buf == NULL || n < 1)
  800860:	85 c0                	test   %eax,%eax
  800862:	74 26                	je     80088a <vsnprintf+0x47>
  800864:	85 d2                	test   %edx,%edx
  800866:	7e 22                	jle    80088a <vsnprintf+0x47>
		return -E_INVAL;

	// print the string to the buffer
	vprintfmt((void*)sprintputch, &b, fmt, ap);
  800868:	ff 75 14             	pushl  0x14(%ebp)
  80086b:	ff 75 10             	pushl  0x10(%ebp)
  80086e:	8d 45 ec             	lea    -0x14(%ebp),%eax
  800871:	50                   	push   %eax
  800872:	68 a1 04 80 00       	push   $0x8004a1
  800877:	e8 5f fc ff ff       	call   8004db <vprintfmt>

	// null terminate the buffer
	*b.buf = '\0';
  80087c:	8b 45 ec             	mov    -0x14(%ebp),%eax
  80087f:	c6 00 00             	movb   $0x0,(%eax)

	return b.cnt;
  800882:	8b 45 f4             	mov    -0xc(%ebp),%eax
  800885:	83 c4 10             	add    $0x10,%esp
  800888:	eb 05                	jmp    80088f <vsnprintf+0x4c>
vsnprintf(char *buf, int n, const char *fmt, va_list ap)
{
	struct sprintbuf b = {buf, buf+n-1, 0};

	if (buf == NULL || n < 1)
		return -E_INVAL;
  80088a:	b8 fd ff ff ff       	mov    $0xfffffffd,%eax

	// null terminate the buffer
	*b.buf = '\0';

	return b.cnt;
}
  80088f:	c9                   	leave  
  800890:	c3                   	ret    

00800891 <snprintf>:

int
snprintf(char *buf, int n, const char *fmt, ...)
{
  800891:	55                   	push   %ebp
  800892:	89 e5                	mov    %esp,%ebp
  800894:	83 ec 08             	sub    $0x8,%esp
	va_list ap;
	int rc;

	va_start(ap, fmt);
  800897:	8d 45 14             	lea    0x14(%ebp),%eax
	rc = vsnprintf(buf, n, fmt, ap);
  80089a:	50                   	push   %eax
  80089b:	ff 75 10             	pushl  0x10(%ebp)
  80089e:	ff 75 0c             	pushl  0xc(%ebp)
  8008a1:	ff 75 08             	pushl  0x8(%ebp)
  8008a4:	e8 9a ff ff ff       	call   800843 <vsnprintf>
	va_end(ap);

	return rc;
}
  8008a9:	c9                   	leave  
  8008aa:	c3                   	ret    

008008ab <strlen>:
// Primespipe runs 3x faster this way.
#define ASM 1

int
strlen(const char *s)
{
  8008ab:	55                   	push   %ebp
  8008ac:	89 e5                	mov    %esp,%ebp
  8008ae:	8b 55 08             	mov    0x8(%ebp),%edx
	int n;

	for (n = 0; *s != '\0'; s++)
  8008b1:	b8 00 00 00 00       	mov    $0x0,%eax
  8008b6:	eb 03                	jmp    8008bb <strlen+0x10>
		n++;
  8008b8:	83 c0 01             	add    $0x1,%eax
int
strlen(const char *s)
{
	int n;

	for (n = 0; *s != '\0'; s++)
  8008bb:	80 3c 02 00          	cmpb   $0x0,(%edx,%eax,1)
  8008bf:	75 f7                	jne    8008b8 <strlen+0xd>
		n++;
	return n;
}
  8008c1:	5d                   	pop    %ebp
  8008c2:	c3                   	ret    

008008c3 <strnlen>:

int
strnlen(const char *s, size_t size)
{
  8008c3:	55                   	push   %ebp
  8008c4:	89 e5                	mov    %esp,%ebp
  8008c6:	8b 4d 08             	mov    0x8(%ebp),%ecx
  8008c9:	8b 45 0c             	mov    0xc(%ebp),%eax
	int n;

	for (n = 0; size > 0 && *s != '\0'; s++, size--)
  8008cc:	ba 00 00 00 00       	mov    $0x0,%edx
  8008d1:	eb 03                	jmp    8008d6 <strnlen+0x13>
		n++;
  8008d3:	83 c2 01             	add    $0x1,%edx
int
strnlen(const char *s, size_t size)
{
	int n;

	for (n = 0; size > 0 && *s != '\0'; s++, size--)
  8008d6:	39 c2                	cmp    %eax,%edx
  8008d8:	74 08                	je     8008e2 <strnlen+0x1f>
  8008da:	80 3c 11 00          	cmpb   $0x0,(%ecx,%edx,1)
  8008de:	75 f3                	jne    8008d3 <strnlen+0x10>
  8008e0:	89 d0                	mov    %edx,%eax
		n++;
	return n;
}
  8008e2:	5d                   	pop    %ebp
  8008e3:	c3                   	ret    

008008e4 <strcpy>:

char *
strcpy(char *dst, const char *src)
{
  8008e4:	55                   	push   %ebp
  8008e5:	89 e5                	mov    %esp,%ebp
  8008e7:	53                   	push   %ebx
  8008e8:	8b 45 08             	mov    0x8(%ebp),%eax
  8008eb:	8b 4d 0c             	mov    0xc(%ebp),%ecx
	char *ret;

	ret = dst;
	while ((*dst++ = *src++) != '\0')
  8008ee:	89 c2                	mov    %eax,%edx
  8008f0:	83 c2 01             	add    $0x1,%edx
  8008f3:	83 c1 01             	add    $0x1,%ecx
  8008f6:	0f b6 59 ff          	movzbl -0x1(%ecx),%ebx
  8008fa:	88 5a ff             	mov    %bl,-0x1(%edx)
  8008fd:	84 db                	test   %bl,%bl
  8008ff:	75 ef                	jne    8008f0 <strcpy+0xc>
		/* do nothing */;
	return ret;
}
  800901:	5b                   	pop    %ebx
  800902:	5d                   	pop    %ebp
  800903:	c3                   	ret    

00800904 <strcat>:

char *
strcat(char *dst, const char *src)
{
  800904:	55                   	push   %ebp
  800905:	89 e5                	mov    %esp,%ebp
  800907:	53                   	push   %ebx
  800908:	8b 5d 08             	mov    0x8(%ebp),%ebx
	int len = strlen(dst);
  80090b:	53                   	push   %ebx
  80090c:	e8 9a ff ff ff       	call   8008ab <strlen>
  800911:	83 c4 04             	add    $0x4,%esp
	strcpy(dst + len, src);
  800914:	ff 75 0c             	pushl  0xc(%ebp)
  800917:	01 d8                	add    %ebx,%eax
  800919:	50                   	push   %eax
  80091a:	e8 c5 ff ff ff       	call   8008e4 <strcpy>
	return dst;
}
  80091f:	89 d8                	mov    %ebx,%eax
  800921:	8b 5d fc             	mov    -0x4(%ebp),%ebx
  800924:	c9                   	leave  
  800925:	c3                   	ret    

00800926 <strncpy>:

char *
strncpy(char *dst, const char *src, size_t size) {
  800926:	55                   	push   %ebp
  800927:	89 e5                	mov    %esp,%ebp
  800929:	56                   	push   %esi
  80092a:	53                   	push   %ebx
  80092b:	8b 75 08             	mov    0x8(%ebp),%esi
  80092e:	8b 4d 0c             	mov    0xc(%ebp),%ecx
  800931:	89 f3                	mov    %esi,%ebx
  800933:	03 5d 10             	add    0x10(%ebp),%ebx
	size_t i;
	char *ret;

	ret = dst;
	for (i = 0; i < size; i++) {
  800936:	89 f2                	mov    %esi,%edx
  800938:	eb 0f                	jmp    800949 <strncpy+0x23>
		*dst++ = *src;
  80093a:	83 c2 01             	add    $0x1,%edx
  80093d:	0f b6 01             	movzbl (%ecx),%eax
  800940:	88 42 ff             	mov    %al,-0x1(%edx)
		// If strlen(src) < size, null-pad 'dst' out to 'size' chars
		if (*src != '\0')
			src++;
  800943:	80 39 01             	cmpb   $0x1,(%ecx)
  800946:	83 d9 ff             	sbb    $0xffffffff,%ecx
strncpy(char *dst, const char *src, size_t size) {
	size_t i;
	char *ret;

	ret = dst;
	for (i = 0; i < size; i++) {
  800949:	39 da                	cmp    %ebx,%edx
  80094b:	75 ed                	jne    80093a <strncpy+0x14>
		// If strlen(src) < size, null-pad 'dst' out to 'size' chars
		if (*src != '\0')
			src++;
	}
	return ret;
}
  80094d:	89 f0                	mov    %esi,%eax
  80094f:	5b                   	pop    %ebx
  800950:	5e                   	pop    %esi
  800951:	5d                   	pop    %ebp
  800952:	c3                   	ret    

00800953 <strlcpy>:

size_t
strlcpy(char *dst, const char *src, size_t size)
{
  800953:	55                   	push   %ebp
  800954:	89 e5                	mov    %esp,%ebp
  800956:	56                   	push   %esi
  800957:	53                   	push   %ebx
  800958:	8b 75 08             	mov    0x8(%ebp),%esi
  80095b:	8b 4d 0c             	mov    0xc(%ebp),%ecx
  80095e:	8b 55 10             	mov    0x10(%ebp),%edx
  800961:	89 f0                	mov    %esi,%eax
	char *dst_in;

	dst_in = dst;
	if (size > 0) {
  800963:	85 d2                	test   %edx,%edx
  800965:	74 21                	je     800988 <strlcpy+0x35>
  800967:	8d 44 16 ff          	lea    -0x1(%esi,%edx,1),%eax
  80096b:	89 f2                	mov    %esi,%edx
  80096d:	eb 09                	jmp    800978 <strlcpy+0x25>
		while (--size > 0 && *src != '\0')
			*dst++ = *src++;
  80096f:	83 c2 01             	add    $0x1,%edx
  800972:	83 c1 01             	add    $0x1,%ecx
  800975:	88 5a ff             	mov    %bl,-0x1(%edx)
{
	char *dst_in;

	dst_in = dst;
	if (size > 0) {
		while (--size > 0 && *src != '\0')
  800978:	39 c2                	cmp    %eax,%edx
  80097a:	74 09                	je     800985 <strlcpy+0x32>
  80097c:	0f b6 19             	movzbl (%ecx),%ebx
  80097f:	84 db                	test   %bl,%bl
  800981:	75 ec                	jne    80096f <strlcpy+0x1c>
  800983:	89 d0                	mov    %edx,%eax
			*dst++ = *src++;
		*dst = '\0';
  800985:	c6 00 00             	movb   $0x0,(%eax)
	}
	return dst - dst_in;
  800988:	29 f0                	sub    %esi,%eax
}
  80098a:	5b                   	pop    %ebx
  80098b:	5e                   	pop    %esi
  80098c:	5d                   	pop    %ebp
  80098d:	c3                   	ret    

0080098e <strcmp>:

int
strcmp(const char *p, const char *q)
{
  80098e:	55                   	push   %ebp
  80098f:	89 e5                	mov    %esp,%ebp
  800991:	8b 4d 08             	mov    0x8(%ebp),%ecx
  800994:	8b 55 0c             	mov    0xc(%ebp),%edx
	while (*p && *p == *q)
  800997:	eb 06                	jmp    80099f <strcmp+0x11>
		p++, q++;
  800999:	83 c1 01             	add    $0x1,%ecx
  80099c:	83 c2 01             	add    $0x1,%edx
}

int
strcmp(const char *p, const char *q)
{
	while (*p && *p == *q)
  80099f:	0f b6 01             	movzbl (%ecx),%eax
  8009a2:	84 c0                	test   %al,%al
  8009a4:	74 04                	je     8009aa <strcmp+0x1c>
  8009a6:	3a 02                	cmp    (%edx),%al
  8009a8:	74 ef                	je     800999 <strcmp+0xb>
		p++, q++;
	return (int) ((unsigned char) *p - (unsigned char) *q);
  8009aa:	0f b6 c0             	movzbl %al,%eax
  8009ad:	0f b6 12             	movzbl (%edx),%edx
  8009b0:	29 d0                	sub    %edx,%eax
}
  8009b2:	5d                   	pop    %ebp
  8009b3:	c3                   	ret    

008009b4 <strncmp>:

int
strncmp(const char *p, const char *q, size_t n)
{
  8009b4:	55                   	push   %ebp
  8009b5:	89 e5                	mov    %esp,%ebp
  8009b7:	53                   	push   %ebx
  8009b8:	8b 45 08             	mov    0x8(%ebp),%eax
  8009bb:	8b 55 0c             	mov    0xc(%ebp),%edx
  8009be:	89 c3                	mov    %eax,%ebx
  8009c0:	03 5d 10             	add    0x10(%ebp),%ebx
	while (n > 0 && *p && *p == *q)
  8009c3:	eb 06                	jmp    8009cb <strncmp+0x17>
		n--, p++, q++;
  8009c5:	83 c0 01             	add    $0x1,%eax
  8009c8:	83 c2 01             	add    $0x1,%edx
}

int
strncmp(const char *p, const char *q, size_t n)
{
	while (n > 0 && *p && *p == *q)
  8009cb:	39 d8                	cmp    %ebx,%eax
  8009cd:	74 15                	je     8009e4 <strncmp+0x30>
  8009cf:	0f b6 08             	movzbl (%eax),%ecx
  8009d2:	84 c9                	test   %cl,%cl
  8009d4:	74 04                	je     8009da <strncmp+0x26>
  8009d6:	3a 0a                	cmp    (%edx),%cl
  8009d8:	74 eb                	je     8009c5 <strncmp+0x11>
		n--, p++, q++;
	if (n == 0)
		return 0;
	else
		return (int) ((unsigned char) *p - (unsigned char) *q);
  8009da:	0f b6 00             	movzbl (%eax),%eax
  8009dd:	0f b6 12             	movzbl (%edx),%edx
  8009e0:	29 d0                	sub    %edx,%eax
  8009e2:	eb 05                	jmp    8009e9 <strncmp+0x35>
strncmp(const char *p, const char *q, size_t n)
{
	while (n > 0 && *p && *p == *q)
		n--, p++, q++;
	if (n == 0)
		return 0;
  8009e4:	b8 00 00 00 00       	mov    $0x0,%eax
	else
		return (int) ((unsigned char) *p - (unsigned char) *q);
}
  8009e9:	5b                   	pop    %ebx
  8009ea:	5d                   	pop    %ebp
  8009eb:	c3                   	ret    

008009ec <strchr>:

// Return a pointer to the first occurrence of 'c' in 's',
// or a null pointer if the string has no 'c'.
char *
strchr(const char *s, char c)
{
  8009ec:	55                   	push   %ebp
  8009ed:	89 e5                	mov    %esp,%ebp
  8009ef:	8b 45 08             	mov    0x8(%ebp),%eax
  8009f2:	0f b6 4d 0c          	movzbl 0xc(%ebp),%ecx
	for (; *s; s++)
  8009f6:	eb 07                	jmp    8009ff <strchr+0x13>
		if (*s == c)
  8009f8:	38 ca                	cmp    %cl,%dl
  8009fa:	74 0f                	je     800a0b <strchr+0x1f>
// Return a pointer to the first occurrence of 'c' in 's',
// or a null pointer if the string has no 'c'.
char *
strchr(const char *s, char c)
{
	for (; *s; s++)
  8009fc:	83 c0 01             	add    $0x1,%eax
  8009ff:	0f b6 10             	movzbl (%eax),%edx
  800a02:	84 d2                	test   %dl,%dl
  800a04:	75 f2                	jne    8009f8 <strchr+0xc>
		if (*s == c)
			return (char *) s;
	return 0;
  800a06:	b8 00 00 00 00       	mov    $0x0,%eax
}
  800a0b:	5d                   	pop    %ebp
  800a0c:	c3                   	ret    

00800a0d <strfind>:

// Return a pointer to the first occurrence of 'c' in 's',
// or a pointer to the string-ending null character if the string has no 'c'.
char *
strfind(const char *s, char c)
{
  800a0d:	55                   	push   %ebp
  800a0e:	89 e5                	mov    %esp,%ebp
  800a10:	8b 45 08             	mov    0x8(%ebp),%eax
  800a13:	0f b6 4d 0c          	movzbl 0xc(%ebp),%ecx
	for (; *s; s++)
  800a17:	eb 03                	jmp    800a1c <strfind+0xf>
  800a19:	83 c0 01             	add    $0x1,%eax
  800a1c:	0f b6 10             	movzbl (%eax),%edx
		if (*s == c)
  800a1f:	38 ca                	cmp    %cl,%dl
  800a21:	74 04                	je     800a27 <strfind+0x1a>
  800a23:	84 d2                	test   %dl,%dl
  800a25:	75 f2                	jne    800a19 <strfind+0xc>
			break;
	return (char *) s;
}
  800a27:	5d                   	pop    %ebp
  800a28:	c3                   	ret    

00800a29 <memset>:

#if ASM
void *
memset(void *v, int c, size_t n)
{
  800a29:	55                   	push   %ebp
  800a2a:	89 e5                	mov    %esp,%ebp
  800a2c:	57                   	push   %edi
  800a2d:	56                   	push   %esi
  800a2e:	53                   	push   %ebx
  800a2f:	8b 55 08             	mov    0x8(%ebp),%edx
  800a32:	8b 4d 10             	mov    0x10(%ebp),%ecx
	char *p = v;

	if (n == 0)
  800a35:	85 c9                	test   %ecx,%ecx
  800a37:	74 37                	je     800a70 <memset+0x47>
		return v;
	if ((int)v%4 == 0 && n%4 == 0) {
  800a39:	f6 c2 03             	test   $0x3,%dl
  800a3c:	75 2a                	jne    800a68 <memset+0x3f>
  800a3e:	f6 c1 03             	test   $0x3,%cl
  800a41:	75 25                	jne    800a68 <memset+0x3f>
		c &= 0xFF;
  800a43:	0f b6 5d 0c          	movzbl 0xc(%ebp),%ebx
		c = (c<<24)|(c<<16)|(c<<8)|c;
  800a47:	89 df                	mov    %ebx,%edi
  800a49:	c1 e7 08             	shl    $0x8,%edi
  800a4c:	89 de                	mov    %ebx,%esi
  800a4e:	c1 e6 18             	shl    $0x18,%esi
  800a51:	89 d8                	mov    %ebx,%eax
  800a53:	c1 e0 10             	shl    $0x10,%eax
  800a56:	09 f0                	or     %esi,%eax
  800a58:	09 c3                	or     %eax,%ebx
		asm volatile("cld; rep stosl\n"
			: "=D" (p), "=c" (n)
			: "D" (p), "a" (c), "c" (n/4)
  800a5a:	c1 e9 02             	shr    $0x2,%ecx
	if (n == 0)
		return v;
	if ((int)v%4 == 0 && n%4 == 0) {
		c &= 0xFF;
		c = (c<<24)|(c<<16)|(c<<8)|c;
		asm volatile("cld; rep stosl\n"
  800a5d:	89 f8                	mov    %edi,%eax
  800a5f:	09 d8                	or     %ebx,%eax
  800a61:	89 d7                	mov    %edx,%edi
  800a63:	fc                   	cld    
  800a64:	f3 ab                	rep stos %eax,%es:(%edi)
  800a66:	eb 08                	jmp    800a70 <memset+0x47>
			: "=D" (p), "=c" (n)
			: "D" (p), "a" (c), "c" (n/4)
			: "cc", "memory");
	} else
		asm volatile("cld; rep stosb\n"
  800a68:	89 d7                	mov    %edx,%edi
  800a6a:	8b 45 0c             	mov    0xc(%ebp),%eax
  800a6d:	fc                   	cld    
  800a6e:	f3 aa                	rep stos %al,%es:(%edi)
			: "=D" (p), "=c" (n)
			: "0" (p), "a" (c), "1" (n)
			: "cc", "memory");
	return v;
}
  800a70:	89 d0                	mov    %edx,%eax
  800a72:	5b                   	pop    %ebx
  800a73:	5e                   	pop    %esi
  800a74:	5f                   	pop    %edi
  800a75:	5d                   	pop    %ebp
  800a76:	c3                   	ret    

00800a77 <memmove>:

void *
memmove(void *dst, const void *src, size_t n)
{
  800a77:	55                   	push   %ebp
  800a78:	89 e5                	mov    %esp,%ebp
  800a7a:	57                   	push   %edi
  800a7b:	56                   	push   %esi
  800a7c:	8b 45 08             	mov    0x8(%ebp),%eax
  800a7f:	8b 75 0c             	mov    0xc(%ebp),%esi
  800a82:	8b 4d 10             	mov    0x10(%ebp),%ecx
	const char *s;
	char *d;

	s = src;
	d = dst;
	if (s < d && s + n > d) {
  800a85:	39 c6                	cmp    %eax,%esi
  800a87:	73 35                	jae    800abe <memmove+0x47>
  800a89:	8d 14 0e             	lea    (%esi,%ecx,1),%edx
  800a8c:	39 d0                	cmp    %edx,%eax
  800a8e:	73 2e                	jae    800abe <memmove+0x47>
		s += n;
		d += n;
  800a90:	8d 3c 08             	lea    (%eax,%ecx,1),%edi
		if ((int)s%4 == 0 && (int)d%4 == 0 && n%4 == 0)
  800a93:	89 d6                	mov    %edx,%esi
  800a95:	09 fe                	or     %edi,%esi
  800a97:	f7 c6 03 00 00 00    	test   $0x3,%esi
  800a9d:	75 13                	jne    800ab2 <memmove+0x3b>
  800a9f:	f6 c1 03             	test   $0x3,%cl
  800aa2:	75 0e                	jne    800ab2 <memmove+0x3b>
			asm volatile("std; rep movsl\n"
  800aa4:	83 ef 04             	sub    $0x4,%edi
  800aa7:	8d 72 fc             	lea    -0x4(%edx),%esi
  800aaa:	c1 e9 02             	shr    $0x2,%ecx
  800aad:	fd                   	std    
  800aae:	f3 a5                	rep movsl %ds:(%esi),%es:(%edi)
  800ab0:	eb 09                	jmp    800abb <memmove+0x44>
				:: "D" (d-4), "S" (s-4), "c" (n/4) : "cc", "memory");
		else
			asm volatile("std; rep movsb\n"
  800ab2:	83 ef 01             	sub    $0x1,%edi
  800ab5:	8d 72 ff             	lea    -0x1(%edx),%esi
  800ab8:	fd                   	std    
  800ab9:	f3 a4                	rep movsb %ds:(%esi),%es:(%edi)
				:: "D" (d-1), "S" (s-1), "c" (n) : "cc", "memory");
		// Some versions of GCC rely on DF being clear
		asm volatile("cld" ::: "cc");
  800abb:	fc                   	cld    
  800abc:	eb 1d                	jmp    800adb <memmove+0x64>
	} else {
		if ((int)s%4 == 0 && (int)d%4 == 0 && n%4 == 0)
  800abe:	89 f2                	mov    %esi,%edx
  800ac0:	09 c2                	or     %eax,%edx
  800ac2:	f6 c2 03             	test   $0x3,%dl
  800ac5:	75 0f                	jne    800ad6 <memmove+0x5f>
  800ac7:	f6 c1 03             	test   $0x3,%cl
  800aca:	75 0a                	jne    800ad6 <memmove+0x5f>
			asm volatile("cld; rep movsl\n"
  800acc:	c1 e9 02             	shr    $0x2,%ecx
  800acf:	89 c7                	mov    %eax,%edi
  800ad1:	fc                   	cld    
  800ad2:	f3 a5                	rep movsl %ds:(%esi),%es:(%edi)
  800ad4:	eb 05                	jmp    800adb <memmove+0x64>
				:: "D" (d), "S" (s), "c" (n/4) : "cc", "memory");
		else
			asm volatile("cld; rep movsb\n"
  800ad6:	89 c7                	mov    %eax,%edi
  800ad8:	fc                   	cld    
  800ad9:	f3 a4                	rep movsb %ds:(%esi),%es:(%edi)
				:: "D" (d), "S" (s), "c" (n) : "cc", "memory");
	}
	return dst;
}
  800adb:	5e                   	pop    %esi
  800adc:	5f                   	pop    %edi
  800add:	5d                   	pop    %ebp
  800ade:	c3                   	ret    

00800adf <memcpy>:
}
#endif

void *
memcpy(void *dst, const void *src, size_t n)
{
  800adf:	55                   	push   %ebp
  800ae0:	89 e5                	mov    %esp,%ebp
	return memmove(dst, src, n);
  800ae2:	ff 75 10             	pushl  0x10(%ebp)
  800ae5:	ff 75 0c             	pushl  0xc(%ebp)
  800ae8:	ff 75 08             	pushl  0x8(%ebp)
  800aeb:	e8 87 ff ff ff       	call   800a77 <memmove>
}
  800af0:	c9                   	leave  
  800af1:	c3                   	ret    

00800af2 <memcmp>:

int
memcmp(const void *v1, const void *v2, size_t n)
{
  800af2:	55                   	push   %ebp
  800af3:	89 e5                	mov    %esp,%ebp
  800af5:	56                   	push   %esi
  800af6:	53                   	push   %ebx
  800af7:	8b 45 08             	mov    0x8(%ebp),%eax
  800afa:	8b 55 0c             	mov    0xc(%ebp),%edx
  800afd:	89 c6                	mov    %eax,%esi
  800aff:	03 75 10             	add    0x10(%ebp),%esi
	const uint8_t *s1 = (const uint8_t *) v1;
	const uint8_t *s2 = (const uint8_t *) v2;

	while (n-- > 0) {
  800b02:	eb 1a                	jmp    800b1e <memcmp+0x2c>
		if (*s1 != *s2)
  800b04:	0f b6 08             	movzbl (%eax),%ecx
  800b07:	0f b6 1a             	movzbl (%edx),%ebx
  800b0a:	38 d9                	cmp    %bl,%cl
  800b0c:	74 0a                	je     800b18 <memcmp+0x26>
			return (int) *s1 - (int) *s2;
  800b0e:	0f b6 c1             	movzbl %cl,%eax
  800b11:	0f b6 db             	movzbl %bl,%ebx
  800b14:	29 d8                	sub    %ebx,%eax
  800b16:	eb 0f                	jmp    800b27 <memcmp+0x35>
		s1++, s2++;
  800b18:	83 c0 01             	add    $0x1,%eax
  800b1b:	83 c2 01             	add    $0x1,%edx
memcmp(const void *v1, const void *v2, size_t n)
{
	const uint8_t *s1 = (const uint8_t *) v1;
	const uint8_t *s2 = (const uint8_t *) v2;

	while (n-- > 0) {
  800b1e:	39 f0                	cmp    %esi,%eax
  800b20:	75 e2                	jne    800b04 <memcmp+0x12>
		if (*s1 != *s2)
			return (int) *s1 - (int) *s2;
		s1++, s2++;
	}

	return 0;
  800b22:	b8 00 00 00 00       	mov    $0x0,%eax
}
  800b27:	5b                   	pop    %ebx
  800b28:	5e                   	pop    %esi
  800b29:	5d                   	pop    %ebp
  800b2a:	c3                   	ret    

00800b2b <memfind>:

void *
memfind(const void *s, int c, size_t n)
{
  800b2b:	55                   	push   %ebp
  800b2c:	89 e5                	mov    %esp,%ebp
  800b2e:	8b 45 08             	mov    0x8(%ebp),%eax
  800b31:	8b 4d 0c             	mov    0xc(%ebp),%ecx
	const void *ends = (const char *) s + n;
  800b34:	89 c2                	mov    %eax,%edx
  800b36:	03 55 10             	add    0x10(%ebp),%edx
	for (; s < ends; s++)
  800b39:	eb 07                	jmp    800b42 <memfind+0x17>
		if (*(const unsigned char *) s == (unsigned char) c)
  800b3b:	38 08                	cmp    %cl,(%eax)
  800b3d:	74 07                	je     800b46 <memfind+0x1b>

void *
memfind(const void *s, int c, size_t n)
{
	const void *ends = (const char *) s + n;
	for (; s < ends; s++)
  800b3f:	83 c0 01             	add    $0x1,%eax
  800b42:	39 d0                	cmp    %edx,%eax
  800b44:	72 f5                	jb     800b3b <memfind+0x10>
		if (*(const unsigned char *) s == (unsigned char) c)
			break;
	return (void *) s;
}
  800b46:	5d                   	pop    %ebp
  800b47:	c3                   	ret    

00800b48 <strtol>:

long
strtol(const char *s, char **endptr, int base)
{
  800b48:	55                   	push   %ebp
  800b49:	89 e5                	mov    %esp,%ebp
  800b4b:	57                   	push   %edi
  800b4c:	56                   	push   %esi
  800b4d:	53                   	push   %ebx
  800b4e:	8b 4d 08             	mov    0x8(%ebp),%ecx
  800b51:	8b 5d 10             	mov    0x10(%ebp),%ebx
	int neg = 0;
	long val = 0;

	// gobble initial whitespace
	while (*s == ' ' || *s == '\t')
  800b54:	eb 03                	jmp    800b59 <strtol+0x11>
		s++;
  800b56:	83 c1 01             	add    $0x1,%ecx
{
	int neg = 0;
	long val = 0;

	// gobble initial whitespace
	while (*s == ' ' || *s == '\t')
  800b59:	0f b6 01             	movzbl (%ecx),%eax
  800b5c:	3c 20                	cmp    $0x20,%al
  800b5e:	74 f6                	je     800b56 <strtol+0xe>
  800b60:	3c 09                	cmp    $0x9,%al
  800b62:	74 f2                	je     800b56 <strtol+0xe>
		s++;

	// plus/minus sign
	if (*s == '+')
  800b64:	3c 2b                	cmp    $0x2b,%al
  800b66:	75 0a                	jne    800b72 <strtol+0x2a>
		s++;
  800b68:	83 c1 01             	add    $0x1,%ecx
}

long
strtol(const char *s, char **endptr, int base)
{
	int neg = 0;
  800b6b:	bf 00 00 00 00       	mov    $0x0,%edi
  800b70:	eb 11                	jmp    800b83 <strtol+0x3b>
  800b72:	bf 00 00 00 00       	mov    $0x0,%edi
		s++;

	// plus/minus sign
	if (*s == '+')
		s++;
	else if (*s == '-')
  800b77:	3c 2d                	cmp    $0x2d,%al
  800b79:	75 08                	jne    800b83 <strtol+0x3b>
		s++, neg = 1;
  800b7b:	83 c1 01             	add    $0x1,%ecx
  800b7e:	bf 01 00 00 00       	mov    $0x1,%edi

	// hex or octal base prefix
	if ((base == 0 || base == 16) && (s[0] == '0' && s[1] == 'x'))
  800b83:	f7 c3 ef ff ff ff    	test   $0xffffffef,%ebx
  800b89:	75 15                	jne    800ba0 <strtol+0x58>
  800b8b:	80 39 30             	cmpb   $0x30,(%ecx)
  800b8e:	75 10                	jne    800ba0 <strtol+0x58>
  800b90:	80 79 01 78          	cmpb   $0x78,0x1(%ecx)
  800b94:	75 7c                	jne    800c12 <strtol+0xca>
		s += 2, base = 16;
  800b96:	83 c1 02             	add    $0x2,%ecx
  800b99:	bb 10 00 00 00       	mov    $0x10,%ebx
  800b9e:	eb 16                	jmp    800bb6 <strtol+0x6e>
	else if (base == 0 && s[0] == '0')
  800ba0:	85 db                	test   %ebx,%ebx
  800ba2:	75 12                	jne    800bb6 <strtol+0x6e>
		s++, base = 8;
	else if (base == 0)
		base = 10;
  800ba4:	bb 0a 00 00 00       	mov    $0xa,%ebx
		s++, neg = 1;

	// hex or octal base prefix
	if ((base == 0 || base == 16) && (s[0] == '0' && s[1] == 'x'))
		s += 2, base = 16;
	else if (base == 0 && s[0] == '0')
  800ba9:	80 39 30             	cmpb   $0x30,(%ecx)
  800bac:	75 08                	jne    800bb6 <strtol+0x6e>
		s++, base = 8;
  800bae:	83 c1 01             	add    $0x1,%ecx
  800bb1:	bb 08 00 00 00       	mov    $0x8,%ebx
	else if (base == 0)
		base = 10;
  800bb6:	b8 00 00 00 00       	mov    $0x0,%eax
  800bbb:	89 5d 10             	mov    %ebx,0x10(%ebp)

	// digits
	while (1) {
		int dig;

		if (*s >= '0' && *s <= '9')
  800bbe:	0f b6 11             	movzbl (%ecx),%edx
  800bc1:	8d 72 d0             	lea    -0x30(%edx),%esi
  800bc4:	89 f3                	mov    %esi,%ebx
  800bc6:	80 fb 09             	cmp    $0x9,%bl
  800bc9:	77 08                	ja     800bd3 <strtol+0x8b>
			dig = *s - '0';
  800bcb:	0f be d2             	movsbl %dl,%edx
  800bce:	83 ea 30             	sub    $0x30,%edx
  800bd1:	eb 22                	jmp    800bf5 <strtol+0xad>
		else if (*s >= 'a' && *s <= 'z')
  800bd3:	8d 72 9f             	lea    -0x61(%edx),%esi
  800bd6:	89 f3                	mov    %esi,%ebx
  800bd8:	80 fb 19             	cmp    $0x19,%bl
  800bdb:	77 08                	ja     800be5 <strtol+0x9d>
			dig = *s - 'a' + 10;
  800bdd:	0f be d2             	movsbl %dl,%edx
  800be0:	83 ea 57             	sub    $0x57,%edx
  800be3:	eb 10                	jmp    800bf5 <strtol+0xad>
		else if (*s >= 'A' && *s <= 'Z')
  800be5:	8d 72 bf             	lea    -0x41(%edx),%esi
  800be8:	89 f3                	mov    %esi,%ebx
  800bea:	80 fb 19             	cmp    $0x19,%bl
  800bed:	77 16                	ja     800c05 <strtol+0xbd>
			dig = *s - 'A' + 10;
  800bef:	0f be d2             	movsbl %dl,%edx
  800bf2:	83 ea 37             	sub    $0x37,%edx
		else
			break;
		if (dig >= base)
  800bf5:	3b 55 10             	cmp    0x10(%ebp),%edx
  800bf8:	7d 0b                	jge    800c05 <strtol+0xbd>
			break;
		s++, val = (val * base) + dig;
  800bfa:	83 c1 01             	add    $0x1,%ecx
  800bfd:	0f af 45 10          	imul   0x10(%ebp),%eax
  800c01:	01 d0                	add    %edx,%eax
		// we don't properly detect overflow!
	}
  800c03:	eb b9                	jmp    800bbe <strtol+0x76>

	if (endptr)
  800c05:	83 7d 0c 00          	cmpl   $0x0,0xc(%ebp)
  800c09:	74 0d                	je     800c18 <strtol+0xd0>
		*endptr = (char *) s;
  800c0b:	8b 75 0c             	mov    0xc(%ebp),%esi
  800c0e:	89 0e                	mov    %ecx,(%esi)
  800c10:	eb 06                	jmp    800c18 <strtol+0xd0>
		s++, neg = 1;

	// hex or octal base prefix
	if ((base == 0 || base == 16) && (s[0] == '0' && s[1] == 'x'))
		s += 2, base = 16;
	else if (base == 0 && s[0] == '0')
  800c12:	85 db                	test   %ebx,%ebx
  800c14:	74 98                	je     800bae <strtol+0x66>
  800c16:	eb 9e                	jmp    800bb6 <strtol+0x6e>
		// we don't properly detect overflow!
	}

	if (endptr)
		*endptr = (char *) s;
	return (neg ? -val : val);
  800c18:	89 c2                	mov    %eax,%edx
  800c1a:	f7 da                	neg    %edx
  800c1c:	85 ff                	test   %edi,%edi
  800c1e:	0f 45 c2             	cmovne %edx,%eax
}
  800c21:	5b                   	pop    %ebx
  800c22:	5e                   	pop    %esi
  800c23:	5f                   	pop    %edi
  800c24:	5d                   	pop    %ebp
  800c25:	c3                   	ret    
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
