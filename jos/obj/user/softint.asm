
obj/user/softint:     file format elf32-i386


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
  80002c:	e8 09 00 00 00       	call   80003a <libmain>
1:	jmp 1b
  800031:	eb fe                	jmp    800031 <args_exist+0x5>

00800033 <umain>:

#include <inc/lib.h>

void
umain(int argc, char **argv)
{
  800033:	55                   	push   %ebp
  800034:	89 e5                	mov    %esp,%ebp
	asm volatile("int $14");	// page fault
  800036:	cd 0e                	int    $0xe
}
  800038:	5d                   	pop    %ebp
  800039:	c3                   	ret    

0080003a <libmain>:
const volatile struct Env *thisenv;
const char *binaryname = "<unknown>";

void
libmain(int argc, char **argv)
{
  80003a:	55                   	push   %ebp
  80003b:	89 e5                	mov    %esp,%ebp
  80003d:	56                   	push   %esi
  80003e:	53                   	push   %ebx
  80003f:	8b 5d 08             	mov    0x8(%ebp),%ebx
  800042:	8b 75 0c             	mov    0xc(%ebp),%esi
	// set thisenv to point at our Env structure in envs[].
	// LAB 3: Your code here.
	envid_t id = sys_getenvid();
  800045:	e8 02 01 00 00       	call   80014c <sys_getenvid>
	if (id >= 0)
  80004a:	85 c0                	test   %eax,%eax
  80004c:	78 12                	js     800060 <libmain+0x26>
		thisenv = &envs[ENVX(id)];
  80004e:	25 ff 03 00 00       	and    $0x3ff,%eax
  800053:	6b c0 7c             	imul   $0x7c,%eax,%eax
  800056:	05 00 00 c0 ee       	add    $0xeec00000,%eax
  80005b:	a3 04 20 80 00       	mov    %eax,0x802004

	// save the name of the program so that panic() can use it
	if (argc > 0)
  800060:	85 db                	test   %ebx,%ebx
  800062:	7e 07                	jle    80006b <libmain+0x31>
		binaryname = argv[0];
  800064:	8b 06                	mov    (%esi),%eax
  800066:	a3 00 20 80 00       	mov    %eax,0x802000

	// call user main routine
	umain(argc, argv);
  80006b:	83 ec 08             	sub    $0x8,%esp
  80006e:	56                   	push   %esi
  80006f:	53                   	push   %ebx
  800070:	e8 be ff ff ff       	call   800033 <umain>

	// exit gracefully
	exit();
  800075:	e8 0a 00 00 00       	call   800084 <exit>
}
  80007a:	83 c4 10             	add    $0x10,%esp
  80007d:	8d 65 f8             	lea    -0x8(%ebp),%esp
  800080:	5b                   	pop    %ebx
  800081:	5e                   	pop    %esi
  800082:	5d                   	pop    %ebp
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
  8000c7:	68 ca 0e 80 00       	push   $0x800eca
  8000cc:	6a 23                	push   $0x23
  8000ce:	68 e7 0e 80 00       	push   $0x800ee7
  8000d3:	e8 b9 01 00 00       	call   800291 <_panic>

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

00800170 <sys_yield>:

void
sys_yield(void)
{
  800170:	55                   	push   %ebp
  800171:	89 e5                	mov    %esp,%ebp
  800173:	83 ec 08             	sub    $0x8,%esp
	syscall(SYS_yield, 0, 0, 0, 0, 0, 0);
  800176:	6a 00                	push   $0x0
  800178:	6a 00                	push   $0x0
  80017a:	6a 00                	push   $0x0
  80017c:	6a 00                	push   $0x0
  80017e:	b9 00 00 00 00       	mov    $0x0,%ecx
  800183:	ba 00 00 00 00       	mov    $0x0,%edx
  800188:	b8 0a 00 00 00       	mov    $0xa,%eax
  80018d:	e8 04 ff ff ff       	call   800096 <syscall>
}
  800192:	83 c4 10             	add    $0x10,%esp
  800195:	c9                   	leave  
  800196:	c3                   	ret    

00800197 <sys_page_alloc>:

int
sys_page_alloc(envid_t envid, void *va, int perm)
{
  800197:	55                   	push   %ebp
  800198:	89 e5                	mov    %esp,%ebp
  80019a:	83 ec 08             	sub    $0x8,%esp
	return syscall(SYS_page_alloc, 1, envid, (uint32_t) va, perm, 0, 0);
  80019d:	6a 00                	push   $0x0
  80019f:	6a 00                	push   $0x0
  8001a1:	ff 75 10             	pushl  0x10(%ebp)
  8001a4:	ff 75 0c             	pushl  0xc(%ebp)
  8001a7:	8b 4d 08             	mov    0x8(%ebp),%ecx
  8001aa:	ba 01 00 00 00       	mov    $0x1,%edx
  8001af:	b8 04 00 00 00       	mov    $0x4,%eax
  8001b4:	e8 dd fe ff ff       	call   800096 <syscall>
}
  8001b9:	c9                   	leave  
  8001ba:	c3                   	ret    

008001bb <sys_page_map>:

int
sys_page_map(envid_t srcenv, void *srcva, envid_t dstenv, void *dstva, int perm)
{
  8001bb:	55                   	push   %ebp
  8001bc:	89 e5                	mov    %esp,%ebp
  8001be:	83 ec 08             	sub    $0x8,%esp
	return syscall(SYS_page_map, 1, srcenv, (uint32_t) srcva, dstenv, (uint32_t) dstva, perm);
  8001c1:	ff 75 18             	pushl  0x18(%ebp)
  8001c4:	ff 75 14             	pushl  0x14(%ebp)
  8001c7:	ff 75 10             	pushl  0x10(%ebp)
  8001ca:	ff 75 0c             	pushl  0xc(%ebp)
  8001cd:	8b 4d 08             	mov    0x8(%ebp),%ecx
  8001d0:	ba 01 00 00 00       	mov    $0x1,%edx
  8001d5:	b8 05 00 00 00       	mov    $0x5,%eax
  8001da:	e8 b7 fe ff ff       	call   800096 <syscall>
}
  8001df:	c9                   	leave  
  8001e0:	c3                   	ret    

008001e1 <sys_page_unmap>:

int
sys_page_unmap(envid_t envid, void *va)
{
  8001e1:	55                   	push   %ebp
  8001e2:	89 e5                	mov    %esp,%ebp
  8001e4:	83 ec 08             	sub    $0x8,%esp
	return syscall(SYS_page_unmap, 1, envid, (uint32_t) va, 0, 0, 0);
  8001e7:	6a 00                	push   $0x0
  8001e9:	6a 00                	push   $0x0
  8001eb:	6a 00                	push   $0x0
  8001ed:	ff 75 0c             	pushl  0xc(%ebp)
  8001f0:	8b 4d 08             	mov    0x8(%ebp),%ecx
  8001f3:	ba 01 00 00 00       	mov    $0x1,%edx
  8001f8:	b8 06 00 00 00       	mov    $0x6,%eax
  8001fd:	e8 94 fe ff ff       	call   800096 <syscall>
}
  800202:	c9                   	leave  
  800203:	c3                   	ret    

00800204 <sys_env_set_status>:

// sys_exofork is inlined in lib.h

int
sys_env_set_status(envid_t envid, int status)
{
  800204:	55                   	push   %ebp
  800205:	89 e5                	mov    %esp,%ebp
  800207:	83 ec 08             	sub    $0x8,%esp
	return syscall(SYS_env_set_status, 1, envid, status, 0, 0, 0);
  80020a:	6a 00                	push   $0x0
  80020c:	6a 00                	push   $0x0
  80020e:	6a 00                	push   $0x0
  800210:	ff 75 0c             	pushl  0xc(%ebp)
  800213:	8b 4d 08             	mov    0x8(%ebp),%ecx
  800216:	ba 01 00 00 00       	mov    $0x1,%edx
  80021b:	b8 08 00 00 00       	mov    $0x8,%eax
  800220:	e8 71 fe ff ff       	call   800096 <syscall>
}
  800225:	c9                   	leave  
  800226:	c3                   	ret    

00800227 <sys_env_set_pgfault_upcall>:

int
sys_env_set_pgfault_upcall(envid_t envid, void *upcall)
{
  800227:	55                   	push   %ebp
  800228:	89 e5                	mov    %esp,%ebp
  80022a:	83 ec 08             	sub    $0x8,%esp
	return syscall(SYS_env_set_pgfault_upcall, 1, envid, (uint32_t) upcall, 0, 0, 0);
  80022d:	6a 00                	push   $0x0
  80022f:	6a 00                	push   $0x0
  800231:	6a 00                	push   $0x0
  800233:	ff 75 0c             	pushl  0xc(%ebp)
  800236:	8b 4d 08             	mov    0x8(%ebp),%ecx
  800239:	ba 01 00 00 00       	mov    $0x1,%edx
  80023e:	b8 09 00 00 00       	mov    $0x9,%eax
  800243:	e8 4e fe ff ff       	call   800096 <syscall>
}
  800248:	c9                   	leave  
  800249:	c3                   	ret    

0080024a <sys_ipc_try_send>:

int
sys_ipc_try_send(envid_t envid, uint32_t value, void *srcva, int perm)
{
  80024a:	55                   	push   %ebp
  80024b:	89 e5                	mov    %esp,%ebp
  80024d:	83 ec 08             	sub    $0x8,%esp
	return syscall(SYS_ipc_try_send, 0, envid, value, (uint32_t) srcva, perm, 0);
  800250:	6a 00                	push   $0x0
  800252:	ff 75 14             	pushl  0x14(%ebp)
  800255:	ff 75 10             	pushl  0x10(%ebp)
  800258:	ff 75 0c             	pushl  0xc(%ebp)
  80025b:	8b 4d 08             	mov    0x8(%ebp),%ecx
  80025e:	ba 00 00 00 00       	mov    $0x0,%edx
  800263:	b8 0b 00 00 00       	mov    $0xb,%eax
  800268:	e8 29 fe ff ff       	call   800096 <syscall>
}
  80026d:	c9                   	leave  
  80026e:	c3                   	ret    

0080026f <sys_ipc_recv>:

int
sys_ipc_recv(void *dstva)
{
  80026f:	55                   	push   %ebp
  800270:	89 e5                	mov    %esp,%ebp
  800272:	83 ec 08             	sub    $0x8,%esp
	return syscall(SYS_ipc_recv, 1, (uint32_t)dstva, 0, 0, 0, 0);
  800275:	6a 00                	push   $0x0
  800277:	6a 00                	push   $0x0
  800279:	6a 00                	push   $0x0
  80027b:	6a 00                	push   $0x0
  80027d:	8b 4d 08             	mov    0x8(%ebp),%ecx
  800280:	ba 01 00 00 00       	mov    $0x1,%edx
  800285:	b8 0c 00 00 00       	mov    $0xc,%eax
  80028a:	e8 07 fe ff ff       	call   800096 <syscall>
}
  80028f:	c9                   	leave  
  800290:	c3                   	ret    

00800291 <_panic>:
 * It prints "panic: <message>", then causes a breakpoint exception,
 * which causes JOS to enter the JOS kernel monitor.
 */
void
_panic(const char *file, int line, const char *fmt, ...)
{
  800291:	55                   	push   %ebp
  800292:	89 e5                	mov    %esp,%ebp
  800294:	56                   	push   %esi
  800295:	53                   	push   %ebx
	va_list ap;

	va_start(ap, fmt);
  800296:	8d 5d 14             	lea    0x14(%ebp),%ebx

	// Print the panic message
	cprintf("[%08x] user panic in %s at %s:%d: ",
  800299:	8b 35 00 20 80 00    	mov    0x802000,%esi
  80029f:	e8 a8 fe ff ff       	call   80014c <sys_getenvid>
  8002a4:	83 ec 0c             	sub    $0xc,%esp
  8002a7:	ff 75 0c             	pushl  0xc(%ebp)
  8002aa:	ff 75 08             	pushl  0x8(%ebp)
  8002ad:	56                   	push   %esi
  8002ae:	50                   	push   %eax
  8002af:	68 f8 0e 80 00       	push   $0x800ef8
  8002b4:	e8 b1 00 00 00       	call   80036a <cprintf>
		sys_getenvid(), binaryname, file, line);
	vcprintf(fmt, ap);
  8002b9:	83 c4 18             	add    $0x18,%esp
  8002bc:	53                   	push   %ebx
  8002bd:	ff 75 10             	pushl  0x10(%ebp)
  8002c0:	e8 54 00 00 00       	call   800319 <vcprintf>
	cprintf("\n");
  8002c5:	c7 04 24 1c 0f 80 00 	movl   $0x800f1c,(%esp)
  8002cc:	e8 99 00 00 00       	call   80036a <cprintf>
  8002d1:	83 c4 10             	add    $0x10,%esp

	// Cause a breakpoint exception
	while (1)
		asm volatile("int3");
  8002d4:	cc                   	int3   
  8002d5:	eb fd                	jmp    8002d4 <_panic+0x43>

008002d7 <putch>:
};


static void
putch(int ch, struct printbuf *b)
{
  8002d7:	55                   	push   %ebp
  8002d8:	89 e5                	mov    %esp,%ebp
  8002da:	53                   	push   %ebx
  8002db:	83 ec 04             	sub    $0x4,%esp
  8002de:	8b 5d 0c             	mov    0xc(%ebp),%ebx
	b->buf[b->idx++] = ch;
  8002e1:	8b 13                	mov    (%ebx),%edx
  8002e3:	8d 42 01             	lea    0x1(%edx),%eax
  8002e6:	89 03                	mov    %eax,(%ebx)
  8002e8:	8b 4d 08             	mov    0x8(%ebp),%ecx
  8002eb:	88 4c 13 08          	mov    %cl,0x8(%ebx,%edx,1)
	if (b->idx == 256-1) {
  8002ef:	3d ff 00 00 00       	cmp    $0xff,%eax
  8002f4:	75 1a                	jne    800310 <putch+0x39>
		sys_cputs(b->buf, b->idx);
  8002f6:	83 ec 08             	sub    $0x8,%esp
  8002f9:	68 ff 00 00 00       	push   $0xff
  8002fe:	8d 43 08             	lea    0x8(%ebx),%eax
  800301:	50                   	push   %eax
  800302:	e8 d9 fd ff ff       	call   8000e0 <sys_cputs>
		b->idx = 0;
  800307:	c7 03 00 00 00 00    	movl   $0x0,(%ebx)
  80030d:	83 c4 10             	add    $0x10,%esp
	}
	b->cnt++;
  800310:	83 43 04 01          	addl   $0x1,0x4(%ebx)
}
  800314:	8b 5d fc             	mov    -0x4(%ebp),%ebx
  800317:	c9                   	leave  
  800318:	c3                   	ret    

00800319 <vcprintf>:

int
vcprintf(const char *fmt, va_list ap)
{
  800319:	55                   	push   %ebp
  80031a:	89 e5                	mov    %esp,%ebp
  80031c:	81 ec 18 01 00 00    	sub    $0x118,%esp
	struct printbuf b;

	b.idx = 0;
  800322:	c7 85 f0 fe ff ff 00 	movl   $0x0,-0x110(%ebp)
  800329:	00 00 00 
	b.cnt = 0;
  80032c:	c7 85 f4 fe ff ff 00 	movl   $0x0,-0x10c(%ebp)
  800333:	00 00 00 
	vprintfmt((void*)putch, &b, fmt, ap);
  800336:	ff 75 0c             	pushl  0xc(%ebp)
  800339:	ff 75 08             	pushl  0x8(%ebp)
  80033c:	8d 85 f0 fe ff ff    	lea    -0x110(%ebp),%eax
  800342:	50                   	push   %eax
  800343:	68 d7 02 80 00       	push   $0x8002d7
  800348:	e8 86 01 00 00       	call   8004d3 <vprintfmt>
	sys_cputs(b.buf, b.idx);
  80034d:	83 c4 08             	add    $0x8,%esp
  800350:	ff b5 f0 fe ff ff    	pushl  -0x110(%ebp)
  800356:	8d 85 f8 fe ff ff    	lea    -0x108(%ebp),%eax
  80035c:	50                   	push   %eax
  80035d:	e8 7e fd ff ff       	call   8000e0 <sys_cputs>

	return b.cnt;
}
  800362:	8b 85 f4 fe ff ff    	mov    -0x10c(%ebp),%eax
  800368:	c9                   	leave  
  800369:	c3                   	ret    

0080036a <cprintf>:

int
cprintf(const char *fmt, ...)
{
  80036a:	55                   	push   %ebp
  80036b:	89 e5                	mov    %esp,%ebp
  80036d:	83 ec 10             	sub    $0x10,%esp
	va_list ap;
	int cnt;

	va_start(ap, fmt);
  800370:	8d 45 0c             	lea    0xc(%ebp),%eax
	cnt = vcprintf(fmt, ap);
  800373:	50                   	push   %eax
  800374:	ff 75 08             	pushl  0x8(%ebp)
  800377:	e8 9d ff ff ff       	call   800319 <vcprintf>
	va_end(ap);

	return cnt;
}
  80037c:	c9                   	leave  
  80037d:	c3                   	ret    

0080037e <printnum>:
 * using specified putch function and associated pointer putdat.
 */
static void
printnum(void (*putch)(int, void*), void *putdat,
	 unsigned long long num, unsigned base, int width, int padc)
{
  80037e:	55                   	push   %ebp
  80037f:	89 e5                	mov    %esp,%ebp
  800381:	57                   	push   %edi
  800382:	56                   	push   %esi
  800383:	53                   	push   %ebx
  800384:	83 ec 1c             	sub    $0x1c,%esp
  800387:	89 c7                	mov    %eax,%edi
  800389:	89 d6                	mov    %edx,%esi
  80038b:	8b 45 08             	mov    0x8(%ebp),%eax
  80038e:	8b 55 0c             	mov    0xc(%ebp),%edx
  800391:	89 45 d8             	mov    %eax,-0x28(%ebp)
  800394:	89 55 dc             	mov    %edx,-0x24(%ebp)
	// first recursively print all preceding (more significant) digits
	if (num >= base) {
  800397:	8b 4d 10             	mov    0x10(%ebp),%ecx
  80039a:	bb 00 00 00 00       	mov    $0x0,%ebx
  80039f:	89 4d e0             	mov    %ecx,-0x20(%ebp)
  8003a2:	89 5d e4             	mov    %ebx,-0x1c(%ebp)
  8003a5:	39 d3                	cmp    %edx,%ebx
  8003a7:	72 05                	jb     8003ae <printnum+0x30>
  8003a9:	39 45 10             	cmp    %eax,0x10(%ebp)
  8003ac:	77 45                	ja     8003f3 <printnum+0x75>
		printnum(putch, putdat, num / base, base, width - 1, padc);
  8003ae:	83 ec 0c             	sub    $0xc,%esp
  8003b1:	ff 75 18             	pushl  0x18(%ebp)
  8003b4:	8b 45 14             	mov    0x14(%ebp),%eax
  8003b7:	8d 58 ff             	lea    -0x1(%eax),%ebx
  8003ba:	53                   	push   %ebx
  8003bb:	ff 75 10             	pushl  0x10(%ebp)
  8003be:	83 ec 08             	sub    $0x8,%esp
  8003c1:	ff 75 e4             	pushl  -0x1c(%ebp)
  8003c4:	ff 75 e0             	pushl  -0x20(%ebp)
  8003c7:	ff 75 dc             	pushl  -0x24(%ebp)
  8003ca:	ff 75 d8             	pushl  -0x28(%ebp)
  8003cd:	e8 4e 08 00 00       	call   800c20 <__udivdi3>
  8003d2:	83 c4 18             	add    $0x18,%esp
  8003d5:	52                   	push   %edx
  8003d6:	50                   	push   %eax
  8003d7:	89 f2                	mov    %esi,%edx
  8003d9:	89 f8                	mov    %edi,%eax
  8003db:	e8 9e ff ff ff       	call   80037e <printnum>
  8003e0:	83 c4 20             	add    $0x20,%esp
  8003e3:	eb 18                	jmp    8003fd <printnum+0x7f>
	} else {
		// print any needed pad characters before first digit
		while (--width > 0)
			putch(padc, putdat);
  8003e5:	83 ec 08             	sub    $0x8,%esp
  8003e8:	56                   	push   %esi
  8003e9:	ff 75 18             	pushl  0x18(%ebp)
  8003ec:	ff d7                	call   *%edi
  8003ee:	83 c4 10             	add    $0x10,%esp
  8003f1:	eb 03                	jmp    8003f6 <printnum+0x78>
  8003f3:	8b 5d 14             	mov    0x14(%ebp),%ebx
	// first recursively print all preceding (more significant) digits
	if (num >= base) {
		printnum(putch, putdat, num / base, base, width - 1, padc);
	} else {
		// print any needed pad characters before first digit
		while (--width > 0)
  8003f6:	83 eb 01             	sub    $0x1,%ebx
  8003f9:	85 db                	test   %ebx,%ebx
  8003fb:	7f e8                	jg     8003e5 <printnum+0x67>
			putch(padc, putdat);
	}

	// then print this (the least significant) digit
	putch("0123456789abcdef"[num % base], putdat);
  8003fd:	83 ec 08             	sub    $0x8,%esp
  800400:	56                   	push   %esi
  800401:	83 ec 04             	sub    $0x4,%esp
  800404:	ff 75 e4             	pushl  -0x1c(%ebp)
  800407:	ff 75 e0             	pushl  -0x20(%ebp)
  80040a:	ff 75 dc             	pushl  -0x24(%ebp)
  80040d:	ff 75 d8             	pushl  -0x28(%ebp)
  800410:	e8 3b 09 00 00       	call   800d50 <__umoddi3>
  800415:	83 c4 14             	add    $0x14,%esp
  800418:	0f be 80 1e 0f 80 00 	movsbl 0x800f1e(%eax),%eax
  80041f:	50                   	push   %eax
  800420:	ff d7                	call   *%edi
}
  800422:	83 c4 10             	add    $0x10,%esp
  800425:	8d 65 f4             	lea    -0xc(%ebp),%esp
  800428:	5b                   	pop    %ebx
  800429:	5e                   	pop    %esi
  80042a:	5f                   	pop    %edi
  80042b:	5d                   	pop    %ebp
  80042c:	c3                   	ret    

0080042d <getuint>:

// Get an unsigned int of various possible sizes from a varargs list,
// depending on the lflag parameter.
static unsigned long long
getuint(va_list *ap, int lflag)
{
  80042d:	55                   	push   %ebp
  80042e:	89 e5                	mov    %esp,%ebp
	if (lflag >= 2)
  800430:	83 fa 01             	cmp    $0x1,%edx
  800433:	7e 0e                	jle    800443 <getuint+0x16>
		return va_arg(*ap, unsigned long long);
  800435:	8b 10                	mov    (%eax),%edx
  800437:	8d 4a 08             	lea    0x8(%edx),%ecx
  80043a:	89 08                	mov    %ecx,(%eax)
  80043c:	8b 02                	mov    (%edx),%eax
  80043e:	8b 52 04             	mov    0x4(%edx),%edx
  800441:	eb 22                	jmp    800465 <getuint+0x38>
	else if (lflag)
  800443:	85 d2                	test   %edx,%edx
  800445:	74 10                	je     800457 <getuint+0x2a>
		return va_arg(*ap, unsigned long);
  800447:	8b 10                	mov    (%eax),%edx
  800449:	8d 4a 04             	lea    0x4(%edx),%ecx
  80044c:	89 08                	mov    %ecx,(%eax)
  80044e:	8b 02                	mov    (%edx),%eax
  800450:	ba 00 00 00 00       	mov    $0x0,%edx
  800455:	eb 0e                	jmp    800465 <getuint+0x38>
	else
		return va_arg(*ap, unsigned int);
  800457:	8b 10                	mov    (%eax),%edx
  800459:	8d 4a 04             	lea    0x4(%edx),%ecx
  80045c:	89 08                	mov    %ecx,(%eax)
  80045e:	8b 02                	mov    (%edx),%eax
  800460:	ba 00 00 00 00       	mov    $0x0,%edx
}
  800465:	5d                   	pop    %ebp
  800466:	c3                   	ret    

00800467 <getint>:

// Same as getuint but signed - can't use getuint
// because of sign extension
static long long
getint(va_list *ap, int lflag)
{
  800467:	55                   	push   %ebp
  800468:	89 e5                	mov    %esp,%ebp
	if (lflag >= 2)
  80046a:	83 fa 01             	cmp    $0x1,%edx
  80046d:	7e 0e                	jle    80047d <getint+0x16>
		return va_arg(*ap, long long);
  80046f:	8b 10                	mov    (%eax),%edx
  800471:	8d 4a 08             	lea    0x8(%edx),%ecx
  800474:	89 08                	mov    %ecx,(%eax)
  800476:	8b 02                	mov    (%edx),%eax
  800478:	8b 52 04             	mov    0x4(%edx),%edx
  80047b:	eb 1a                	jmp    800497 <getint+0x30>
	else if (lflag)
  80047d:	85 d2                	test   %edx,%edx
  80047f:	74 0c                	je     80048d <getint+0x26>
		return va_arg(*ap, long);
  800481:	8b 10                	mov    (%eax),%edx
  800483:	8d 4a 04             	lea    0x4(%edx),%ecx
  800486:	89 08                	mov    %ecx,(%eax)
  800488:	8b 02                	mov    (%edx),%eax
  80048a:	99                   	cltd   
  80048b:	eb 0a                	jmp    800497 <getint+0x30>
	else
		return va_arg(*ap, int);
  80048d:	8b 10                	mov    (%eax),%edx
  80048f:	8d 4a 04             	lea    0x4(%edx),%ecx
  800492:	89 08                	mov    %ecx,(%eax)
  800494:	8b 02                	mov    (%edx),%eax
  800496:	99                   	cltd   
}
  800497:	5d                   	pop    %ebp
  800498:	c3                   	ret    

00800499 <sprintputch>:
	int cnt;
};

static void
sprintputch(int ch, struct sprintbuf *b)
{
  800499:	55                   	push   %ebp
  80049a:	89 e5                	mov    %esp,%ebp
  80049c:	8b 45 0c             	mov    0xc(%ebp),%eax
	b->cnt++;
  80049f:	83 40 08 01          	addl   $0x1,0x8(%eax)
	if (b->buf < b->ebuf)
  8004a3:	8b 10                	mov    (%eax),%edx
  8004a5:	3b 50 04             	cmp    0x4(%eax),%edx
  8004a8:	73 0a                	jae    8004b4 <sprintputch+0x1b>
		*b->buf++ = ch;
  8004aa:	8d 4a 01             	lea    0x1(%edx),%ecx
  8004ad:	89 08                	mov    %ecx,(%eax)
  8004af:	8b 45 08             	mov    0x8(%ebp),%eax
  8004b2:	88 02                	mov    %al,(%edx)
}
  8004b4:	5d                   	pop    %ebp
  8004b5:	c3                   	ret    

008004b6 <printfmt>:
	}
}

void
printfmt(void (*putch)(int, void*), void *putdat, const char *fmt, ...)
{
  8004b6:	55                   	push   %ebp
  8004b7:	89 e5                	mov    %esp,%ebp
  8004b9:	83 ec 08             	sub    $0x8,%esp
	va_list ap;

	va_start(ap, fmt);
  8004bc:	8d 45 14             	lea    0x14(%ebp),%eax
	vprintfmt(putch, putdat, fmt, ap);
  8004bf:	50                   	push   %eax
  8004c0:	ff 75 10             	pushl  0x10(%ebp)
  8004c3:	ff 75 0c             	pushl  0xc(%ebp)
  8004c6:	ff 75 08             	pushl  0x8(%ebp)
  8004c9:	e8 05 00 00 00       	call   8004d3 <vprintfmt>
	va_end(ap);
}
  8004ce:	83 c4 10             	add    $0x10,%esp
  8004d1:	c9                   	leave  
  8004d2:	c3                   	ret    

008004d3 <vprintfmt>:
// Main function to format and print a string.
void printfmt(void (*putch)(int, void*), void *putdat, const char *fmt, ...);

void
vprintfmt(void (*putch)(int, void*), void *putdat, const char *fmt, va_list ap)
{
  8004d3:	55                   	push   %ebp
  8004d4:	89 e5                	mov    %esp,%ebp
  8004d6:	57                   	push   %edi
  8004d7:	56                   	push   %esi
  8004d8:	53                   	push   %ebx
  8004d9:	83 ec 2c             	sub    $0x2c,%esp
  8004dc:	8b 75 08             	mov    0x8(%ebp),%esi
  8004df:	8b 5d 0c             	mov    0xc(%ebp),%ebx
  8004e2:	8b 7d 10             	mov    0x10(%ebp),%edi
  8004e5:	eb 12                	jmp    8004f9 <vprintfmt+0x26>
	int base, lflag, width, precision, altflag;
	char padc;

	while (1) {
		while ((ch = *(unsigned char *) fmt++) != '%') {
			if (ch == '\0')
  8004e7:	85 c0                	test   %eax,%eax
  8004e9:	0f 84 44 03 00 00    	je     800833 <vprintfmt+0x360>
				return;
			putch(ch, putdat);
  8004ef:	83 ec 08             	sub    $0x8,%esp
  8004f2:	53                   	push   %ebx
  8004f3:	50                   	push   %eax
  8004f4:	ff d6                	call   *%esi
  8004f6:	83 c4 10             	add    $0x10,%esp
	unsigned long long num;
	int base, lflag, width, precision, altflag;
	char padc;

	while (1) {
		while ((ch = *(unsigned char *) fmt++) != '%') {
  8004f9:	83 c7 01             	add    $0x1,%edi
  8004fc:	0f b6 47 ff          	movzbl -0x1(%edi),%eax
  800500:	83 f8 25             	cmp    $0x25,%eax
  800503:	75 e2                	jne    8004e7 <vprintfmt+0x14>
  800505:	c6 45 d4 20          	movb   $0x20,-0x2c(%ebp)
  800509:	c7 45 d8 00 00 00 00 	movl   $0x0,-0x28(%ebp)
  800510:	c7 45 d0 ff ff ff ff 	movl   $0xffffffff,-0x30(%ebp)
  800517:	c7 45 e0 ff ff ff ff 	movl   $0xffffffff,-0x20(%ebp)
  80051e:	ba 00 00 00 00       	mov    $0x0,%edx
  800523:	eb 07                	jmp    80052c <vprintfmt+0x59>
		width = -1;
		precision = -1;
		lflag = 0;
		altflag = 0;
	reswitch:
		switch (ch = *(unsigned char *) fmt++) {
  800525:	8b 7d e4             	mov    -0x1c(%ebp),%edi

		// flag to pad on the right
		case '-':
			padc = '-';
  800528:	c6 45 d4 2d          	movb   $0x2d,-0x2c(%ebp)
		width = -1;
		precision = -1;
		lflag = 0;
		altflag = 0;
	reswitch:
		switch (ch = *(unsigned char *) fmt++) {
  80052c:	8d 47 01             	lea    0x1(%edi),%eax
  80052f:	89 45 e4             	mov    %eax,-0x1c(%ebp)
  800532:	0f b6 07             	movzbl (%edi),%eax
  800535:	0f b6 c8             	movzbl %al,%ecx
  800538:	83 e8 23             	sub    $0x23,%eax
  80053b:	3c 55                	cmp    $0x55,%al
  80053d:	0f 87 d5 02 00 00    	ja     800818 <vprintfmt+0x345>
  800543:	0f b6 c0             	movzbl %al,%eax
  800546:	ff 24 85 e0 0f 80 00 	jmp    *0x800fe0(,%eax,4)
  80054d:	8b 7d e4             	mov    -0x1c(%ebp),%edi
			padc = '-';
			goto reswitch;

		// flag to pad with 0's instead of spaces
		case '0':
			padc = '0';
  800550:	c6 45 d4 30          	movb   $0x30,-0x2c(%ebp)
  800554:	eb d6                	jmp    80052c <vprintfmt+0x59>
		width = -1;
		precision = -1;
		lflag = 0;
		altflag = 0;
	reswitch:
		switch (ch = *(unsigned char *) fmt++) {
  800556:	8b 7d e4             	mov    -0x1c(%ebp),%edi
  800559:	b8 00 00 00 00       	mov    $0x0,%eax
  80055e:	89 55 e4             	mov    %edx,-0x1c(%ebp)
		case '6':
		case '7':
		case '8':
		case '9':
			for (precision = 0; ; ++fmt) {
				precision = precision * 10 + ch - '0';
  800561:	8d 04 80             	lea    (%eax,%eax,4),%eax
  800564:	8d 44 41 d0          	lea    -0x30(%ecx,%eax,2),%eax
				ch = *fmt;
  800568:	0f be 0f             	movsbl (%edi),%ecx
				if (ch < '0' || ch > '9')
  80056b:	8d 51 d0             	lea    -0x30(%ecx),%edx
  80056e:	83 fa 09             	cmp    $0x9,%edx
  800571:	77 39                	ja     8005ac <vprintfmt+0xd9>
		case '5':
		case '6':
		case '7':
		case '8':
		case '9':
			for (precision = 0; ; ++fmt) {
  800573:	83 c7 01             	add    $0x1,%edi
				precision = precision * 10 + ch - '0';
				ch = *fmt;
				if (ch < '0' || ch > '9')
					break;
			}
  800576:	eb e9                	jmp    800561 <vprintfmt+0x8e>
			goto process_precision;

		case '*':
			precision = va_arg(ap, int);
  800578:	8b 45 14             	mov    0x14(%ebp),%eax
  80057b:	8d 48 04             	lea    0x4(%eax),%ecx
  80057e:	89 4d 14             	mov    %ecx,0x14(%ebp)
  800581:	8b 00                	mov    (%eax),%eax
  800583:	89 45 d0             	mov    %eax,-0x30(%ebp)
		width = -1;
		precision = -1;
		lflag = 0;
		altflag = 0;
	reswitch:
		switch (ch = *(unsigned char *) fmt++) {
  800586:	8b 7d e4             	mov    -0x1c(%ebp),%edi
			}
			goto process_precision;

		case '*':
			precision = va_arg(ap, int);
			goto process_precision;
  800589:	eb 27                	jmp    8005b2 <vprintfmt+0xdf>
  80058b:	8b 45 e0             	mov    -0x20(%ebp),%eax
  80058e:	85 c0                	test   %eax,%eax
  800590:	b9 00 00 00 00       	mov    $0x0,%ecx
  800595:	0f 49 c8             	cmovns %eax,%ecx
  800598:	89 4d e0             	mov    %ecx,-0x20(%ebp)
		width = -1;
		precision = -1;
		lflag = 0;
		altflag = 0;
	reswitch:
		switch (ch = *(unsigned char *) fmt++) {
  80059b:	8b 7d e4             	mov    -0x1c(%ebp),%edi
  80059e:	eb 8c                	jmp    80052c <vprintfmt+0x59>
  8005a0:	8b 7d e4             	mov    -0x1c(%ebp),%edi
			if (width < 0)
				width = 0;
			goto reswitch;

		case '#':
			altflag = 1;
  8005a3:	c7 45 d8 01 00 00 00 	movl   $0x1,-0x28(%ebp)
			goto reswitch;
  8005aa:	eb 80                	jmp    80052c <vprintfmt+0x59>
  8005ac:	8b 55 e4             	mov    -0x1c(%ebp),%edx
  8005af:	89 45 d0             	mov    %eax,-0x30(%ebp)

		process_precision:
			if (width < 0)
  8005b2:	83 7d e0 00          	cmpl   $0x0,-0x20(%ebp)
  8005b6:	0f 89 70 ff ff ff    	jns    80052c <vprintfmt+0x59>
				width = precision, precision = -1;
  8005bc:	8b 45 d0             	mov    -0x30(%ebp),%eax
  8005bf:	89 45 e0             	mov    %eax,-0x20(%ebp)
  8005c2:	c7 45 d0 ff ff ff ff 	movl   $0xffffffff,-0x30(%ebp)
  8005c9:	e9 5e ff ff ff       	jmp    80052c <vprintfmt+0x59>
			goto reswitch;

		// long flag (doubled for long long)
		case 'l':
			lflag++;
  8005ce:	83 c2 01             	add    $0x1,%edx
		width = -1;
		precision = -1;
		lflag = 0;
		altflag = 0;
	reswitch:
		switch (ch = *(unsigned char *) fmt++) {
  8005d1:	8b 7d e4             	mov    -0x1c(%ebp),%edi
			goto reswitch;

		// long flag (doubled for long long)
		case 'l':
			lflag++;
			goto reswitch;
  8005d4:	e9 53 ff ff ff       	jmp    80052c <vprintfmt+0x59>

		// character
		case 'c':
			putch(va_arg(ap, int), putdat);
  8005d9:	8b 45 14             	mov    0x14(%ebp),%eax
  8005dc:	8d 50 04             	lea    0x4(%eax),%edx
  8005df:	89 55 14             	mov    %edx,0x14(%ebp)
  8005e2:	83 ec 08             	sub    $0x8,%esp
  8005e5:	53                   	push   %ebx
  8005e6:	ff 30                	pushl  (%eax)
  8005e8:	ff d6                	call   *%esi
			break;
  8005ea:	83 c4 10             	add    $0x10,%esp
		width = -1;
		precision = -1;
		lflag = 0;
		altflag = 0;
	reswitch:
		switch (ch = *(unsigned char *) fmt++) {
  8005ed:	8b 7d e4             	mov    -0x1c(%ebp),%edi
			goto reswitch;

		// character
		case 'c':
			putch(va_arg(ap, int), putdat);
			break;
  8005f0:	e9 04 ff ff ff       	jmp    8004f9 <vprintfmt+0x26>

		// error message
		case 'e':
			err = va_arg(ap, int);
  8005f5:	8b 45 14             	mov    0x14(%ebp),%eax
  8005f8:	8d 50 04             	lea    0x4(%eax),%edx
  8005fb:	89 55 14             	mov    %edx,0x14(%ebp)
  8005fe:	8b 00                	mov    (%eax),%eax
  800600:	99                   	cltd   
  800601:	31 d0                	xor    %edx,%eax
  800603:	29 d0                	sub    %edx,%eax
			if (err < 0)
				err = -err;
			if (err >= MAXERROR || (p = error_string[err]) == NULL)
  800605:	83 f8 08             	cmp    $0x8,%eax
  800608:	7f 0b                	jg     800615 <vprintfmt+0x142>
  80060a:	8b 14 85 40 11 80 00 	mov    0x801140(,%eax,4),%edx
  800611:	85 d2                	test   %edx,%edx
  800613:	75 18                	jne    80062d <vprintfmt+0x15a>
				printfmt(putch, putdat, "error %d", err);
  800615:	50                   	push   %eax
  800616:	68 36 0f 80 00       	push   $0x800f36
  80061b:	53                   	push   %ebx
  80061c:	56                   	push   %esi
  80061d:	e8 94 fe ff ff       	call   8004b6 <printfmt>
  800622:	83 c4 10             	add    $0x10,%esp
		width = -1;
		precision = -1;
		lflag = 0;
		altflag = 0;
	reswitch:
		switch (ch = *(unsigned char *) fmt++) {
  800625:	8b 7d e4             	mov    -0x1c(%ebp),%edi
		case 'e':
			err = va_arg(ap, int);
			if (err < 0)
				err = -err;
			if (err >= MAXERROR || (p = error_string[err]) == NULL)
				printfmt(putch, putdat, "error %d", err);
  800628:	e9 cc fe ff ff       	jmp    8004f9 <vprintfmt+0x26>
			else
				printfmt(putch, putdat, "%s", p);
  80062d:	52                   	push   %edx
  80062e:	68 3f 0f 80 00       	push   $0x800f3f
  800633:	53                   	push   %ebx
  800634:	56                   	push   %esi
  800635:	e8 7c fe ff ff       	call   8004b6 <printfmt>
  80063a:	83 c4 10             	add    $0x10,%esp
		width = -1;
		precision = -1;
		lflag = 0;
		altflag = 0;
	reswitch:
		switch (ch = *(unsigned char *) fmt++) {
  80063d:	8b 7d e4             	mov    -0x1c(%ebp),%edi
  800640:	e9 b4 fe ff ff       	jmp    8004f9 <vprintfmt+0x26>
				printfmt(putch, putdat, "%s", p);
			break;

		// string
		case 's':
			if ((p = va_arg(ap, char *)) == NULL)
  800645:	8b 45 14             	mov    0x14(%ebp),%eax
  800648:	8d 50 04             	lea    0x4(%eax),%edx
  80064b:	89 55 14             	mov    %edx,0x14(%ebp)
  80064e:	8b 38                	mov    (%eax),%edi
				p = "(null)";
  800650:	85 ff                	test   %edi,%edi
  800652:	b8 2f 0f 80 00       	mov    $0x800f2f,%eax
  800657:	0f 44 f8             	cmove  %eax,%edi
			if (width > 0 && padc != '-')
  80065a:	83 7d e0 00          	cmpl   $0x0,-0x20(%ebp)
  80065e:	0f 8e 94 00 00 00    	jle    8006f8 <vprintfmt+0x225>
  800664:	80 7d d4 2d          	cmpb   $0x2d,-0x2c(%ebp)
  800668:	0f 84 98 00 00 00    	je     800706 <vprintfmt+0x233>
				for (width -= strnlen(p, precision); width > 0; width--)
  80066e:	83 ec 08             	sub    $0x8,%esp
  800671:	ff 75 d0             	pushl  -0x30(%ebp)
  800674:	57                   	push   %edi
  800675:	e8 41 02 00 00       	call   8008bb <strnlen>
  80067a:	8b 4d e0             	mov    -0x20(%ebp),%ecx
  80067d:	29 c1                	sub    %eax,%ecx
  80067f:	89 4d cc             	mov    %ecx,-0x34(%ebp)
  800682:	83 c4 10             	add    $0x10,%esp
					putch(padc, putdat);
  800685:	0f be 45 d4          	movsbl -0x2c(%ebp),%eax
  800689:	89 45 e0             	mov    %eax,-0x20(%ebp)
  80068c:	89 7d d4             	mov    %edi,-0x2c(%ebp)
  80068f:	89 cf                	mov    %ecx,%edi
		// string
		case 's':
			if ((p = va_arg(ap, char *)) == NULL)
				p = "(null)";
			if (width > 0 && padc != '-')
				for (width -= strnlen(p, precision); width > 0; width--)
  800691:	eb 0f                	jmp    8006a2 <vprintfmt+0x1cf>
					putch(padc, putdat);
  800693:	83 ec 08             	sub    $0x8,%esp
  800696:	53                   	push   %ebx
  800697:	ff 75 e0             	pushl  -0x20(%ebp)
  80069a:	ff d6                	call   *%esi
		// string
		case 's':
			if ((p = va_arg(ap, char *)) == NULL)
				p = "(null)";
			if (width > 0 && padc != '-')
				for (width -= strnlen(p, precision); width > 0; width--)
  80069c:	83 ef 01             	sub    $0x1,%edi
  80069f:	83 c4 10             	add    $0x10,%esp
  8006a2:	85 ff                	test   %edi,%edi
  8006a4:	7f ed                	jg     800693 <vprintfmt+0x1c0>
  8006a6:	8b 7d d4             	mov    -0x2c(%ebp),%edi
  8006a9:	8b 4d cc             	mov    -0x34(%ebp),%ecx
  8006ac:	85 c9                	test   %ecx,%ecx
  8006ae:	b8 00 00 00 00       	mov    $0x0,%eax
  8006b3:	0f 49 c1             	cmovns %ecx,%eax
  8006b6:	29 c1                	sub    %eax,%ecx
  8006b8:	89 75 08             	mov    %esi,0x8(%ebp)
  8006bb:	8b 75 d0             	mov    -0x30(%ebp),%esi
  8006be:	89 5d 0c             	mov    %ebx,0xc(%ebp)
  8006c1:	89 cb                	mov    %ecx,%ebx
  8006c3:	eb 4d                	jmp    800712 <vprintfmt+0x23f>
					putch(padc, putdat);
			for (; (ch = *p++) != '\0' && (precision < 0 || --precision >= 0); width--)
				if (altflag && (ch < ' ' || ch > '~'))
  8006c5:	83 7d d8 00          	cmpl   $0x0,-0x28(%ebp)
  8006c9:	74 1b                	je     8006e6 <vprintfmt+0x213>
  8006cb:	0f be c0             	movsbl %al,%eax
  8006ce:	83 e8 20             	sub    $0x20,%eax
  8006d1:	83 f8 5e             	cmp    $0x5e,%eax
  8006d4:	76 10                	jbe    8006e6 <vprintfmt+0x213>
					putch('?', putdat);
  8006d6:	83 ec 08             	sub    $0x8,%esp
  8006d9:	ff 75 0c             	pushl  0xc(%ebp)
  8006dc:	6a 3f                	push   $0x3f
  8006de:	ff 55 08             	call   *0x8(%ebp)
  8006e1:	83 c4 10             	add    $0x10,%esp
  8006e4:	eb 0d                	jmp    8006f3 <vprintfmt+0x220>
				else
					putch(ch, putdat);
  8006e6:	83 ec 08             	sub    $0x8,%esp
  8006e9:	ff 75 0c             	pushl  0xc(%ebp)
  8006ec:	52                   	push   %edx
  8006ed:	ff 55 08             	call   *0x8(%ebp)
  8006f0:	83 c4 10             	add    $0x10,%esp
			if ((p = va_arg(ap, char *)) == NULL)
				p = "(null)";
			if (width > 0 && padc != '-')
				for (width -= strnlen(p, precision); width > 0; width--)
					putch(padc, putdat);
			for (; (ch = *p++) != '\0' && (precision < 0 || --precision >= 0); width--)
  8006f3:	83 eb 01             	sub    $0x1,%ebx
  8006f6:	eb 1a                	jmp    800712 <vprintfmt+0x23f>
  8006f8:	89 75 08             	mov    %esi,0x8(%ebp)
  8006fb:	8b 75 d0             	mov    -0x30(%ebp),%esi
  8006fe:	89 5d 0c             	mov    %ebx,0xc(%ebp)
  800701:	8b 5d e0             	mov    -0x20(%ebp),%ebx
  800704:	eb 0c                	jmp    800712 <vprintfmt+0x23f>
  800706:	89 75 08             	mov    %esi,0x8(%ebp)
  800709:	8b 75 d0             	mov    -0x30(%ebp),%esi
  80070c:	89 5d 0c             	mov    %ebx,0xc(%ebp)
  80070f:	8b 5d e0             	mov    -0x20(%ebp),%ebx
  800712:	83 c7 01             	add    $0x1,%edi
  800715:	0f b6 47 ff          	movzbl -0x1(%edi),%eax
  800719:	0f be d0             	movsbl %al,%edx
  80071c:	85 d2                	test   %edx,%edx
  80071e:	74 23                	je     800743 <vprintfmt+0x270>
  800720:	85 f6                	test   %esi,%esi
  800722:	78 a1                	js     8006c5 <vprintfmt+0x1f2>
  800724:	83 ee 01             	sub    $0x1,%esi
  800727:	79 9c                	jns    8006c5 <vprintfmt+0x1f2>
  800729:	89 df                	mov    %ebx,%edi
  80072b:	8b 75 08             	mov    0x8(%ebp),%esi
  80072e:	8b 5d 0c             	mov    0xc(%ebp),%ebx
  800731:	eb 18                	jmp    80074b <vprintfmt+0x278>
				if (altflag && (ch < ' ' || ch > '~'))
					putch('?', putdat);
				else
					putch(ch, putdat);
			for (; width > 0; width--)
				putch(' ', putdat);
  800733:	83 ec 08             	sub    $0x8,%esp
  800736:	53                   	push   %ebx
  800737:	6a 20                	push   $0x20
  800739:	ff d6                	call   *%esi
			for (; (ch = *p++) != '\0' && (precision < 0 || --precision >= 0); width--)
				if (altflag && (ch < ' ' || ch > '~'))
					putch('?', putdat);
				else
					putch(ch, putdat);
			for (; width > 0; width--)
  80073b:	83 ef 01             	sub    $0x1,%edi
  80073e:	83 c4 10             	add    $0x10,%esp
  800741:	eb 08                	jmp    80074b <vprintfmt+0x278>
  800743:	89 df                	mov    %ebx,%edi
  800745:	8b 75 08             	mov    0x8(%ebp),%esi
  800748:	8b 5d 0c             	mov    0xc(%ebp),%ebx
  80074b:	85 ff                	test   %edi,%edi
  80074d:	7f e4                	jg     800733 <vprintfmt+0x260>
		width = -1;
		precision = -1;
		lflag = 0;
		altflag = 0;
	reswitch:
		switch (ch = *(unsigned char *) fmt++) {
  80074f:	8b 7d e4             	mov    -0x1c(%ebp),%edi
  800752:	e9 a2 fd ff ff       	jmp    8004f9 <vprintfmt+0x26>
				putch(' ', putdat);
			break;

		// (signed) decimal
		case 'd':
			num = getint(&ap, lflag);
  800757:	8d 45 14             	lea    0x14(%ebp),%eax
  80075a:	e8 08 fd ff ff       	call   800467 <getint>
  80075f:	89 45 d8             	mov    %eax,-0x28(%ebp)
  800762:	89 55 dc             	mov    %edx,-0x24(%ebp)
			if ((long long) num < 0) {
				putch('-', putdat);
				num = -(long long) num;
			}
			base = 10;
  800765:	b9 0a 00 00 00       	mov    $0xa,%ecx
			break;

		// (signed) decimal
		case 'd':
			num = getint(&ap, lflag);
			if ((long long) num < 0) {
  80076a:	83 7d dc 00          	cmpl   $0x0,-0x24(%ebp)
  80076e:	79 74                	jns    8007e4 <vprintfmt+0x311>
				putch('-', putdat);
  800770:	83 ec 08             	sub    $0x8,%esp
  800773:	53                   	push   %ebx
  800774:	6a 2d                	push   $0x2d
  800776:	ff d6                	call   *%esi
				num = -(long long) num;
  800778:	8b 45 d8             	mov    -0x28(%ebp),%eax
  80077b:	8b 55 dc             	mov    -0x24(%ebp),%edx
  80077e:	f7 d8                	neg    %eax
  800780:	83 d2 00             	adc    $0x0,%edx
  800783:	f7 da                	neg    %edx
  800785:	83 c4 10             	add    $0x10,%esp
			}
			base = 10;
  800788:	b9 0a 00 00 00       	mov    $0xa,%ecx
  80078d:	eb 55                	jmp    8007e4 <vprintfmt+0x311>
			goto number;

		// unsigned decimal
		case 'u':
			num = getuint(&ap, lflag);
  80078f:	8d 45 14             	lea    0x14(%ebp),%eax
  800792:	e8 96 fc ff ff       	call   80042d <getuint>
			base = 10;
  800797:	b9 0a 00 00 00       	mov    $0xa,%ecx
			goto number;
  80079c:	eb 46                	jmp    8007e4 <vprintfmt+0x311>

		// (unsigned) octal
		case 'o':
			num = getuint(&ap, lflag);
  80079e:	8d 45 14             	lea    0x14(%ebp),%eax
  8007a1:	e8 87 fc ff ff       	call   80042d <getuint>
			base = 8;
  8007a6:	b9 08 00 00 00       	mov    $0x8,%ecx
			goto number;
  8007ab:	eb 37                	jmp    8007e4 <vprintfmt+0x311>

		// pointer
		case 'p':
			putch('0', putdat);
  8007ad:	83 ec 08             	sub    $0x8,%esp
  8007b0:	53                   	push   %ebx
  8007b1:	6a 30                	push   $0x30
  8007b3:	ff d6                	call   *%esi
			putch('x', putdat);
  8007b5:	83 c4 08             	add    $0x8,%esp
  8007b8:	53                   	push   %ebx
  8007b9:	6a 78                	push   $0x78
  8007bb:	ff d6                	call   *%esi
			num = (unsigned long long)
				(uintptr_t) va_arg(ap, void *);
  8007bd:	8b 45 14             	mov    0x14(%ebp),%eax
  8007c0:	8d 50 04             	lea    0x4(%eax),%edx
  8007c3:	89 55 14             	mov    %edx,0x14(%ebp)

		// pointer
		case 'p':
			putch('0', putdat);
			putch('x', putdat);
			num = (unsigned long long)
  8007c6:	8b 00                	mov    (%eax),%eax
  8007c8:	ba 00 00 00 00       	mov    $0x0,%edx
				(uintptr_t) va_arg(ap, void *);
			base = 16;
			goto number;
  8007cd:	83 c4 10             	add    $0x10,%esp
		case 'p':
			putch('0', putdat);
			putch('x', putdat);
			num = (unsigned long long)
				(uintptr_t) va_arg(ap, void *);
			base = 16;
  8007d0:	b9 10 00 00 00       	mov    $0x10,%ecx
			goto number;
  8007d5:	eb 0d                	jmp    8007e4 <vprintfmt+0x311>

		// (unsigned) hexadecimal
		case 'x':
			num = getuint(&ap, lflag);
  8007d7:	8d 45 14             	lea    0x14(%ebp),%eax
  8007da:	e8 4e fc ff ff       	call   80042d <getuint>
			base = 16;
  8007df:	b9 10 00 00 00       	mov    $0x10,%ecx
		number:
			printnum(putch, putdat, num, base, width, padc);
  8007e4:	83 ec 0c             	sub    $0xc,%esp
  8007e7:	0f be 7d d4          	movsbl -0x2c(%ebp),%edi
  8007eb:	57                   	push   %edi
  8007ec:	ff 75 e0             	pushl  -0x20(%ebp)
  8007ef:	51                   	push   %ecx
  8007f0:	52                   	push   %edx
  8007f1:	50                   	push   %eax
  8007f2:	89 da                	mov    %ebx,%edx
  8007f4:	89 f0                	mov    %esi,%eax
  8007f6:	e8 83 fb ff ff       	call   80037e <printnum>
			break;
  8007fb:	83 c4 20             	add    $0x20,%esp
  8007fe:	8b 7d e4             	mov    -0x1c(%ebp),%edi
  800801:	e9 f3 fc ff ff       	jmp    8004f9 <vprintfmt+0x26>

		// escaped '%' character
		case '%':
			putch(ch, putdat);
  800806:	83 ec 08             	sub    $0x8,%esp
  800809:	53                   	push   %ebx
  80080a:	51                   	push   %ecx
  80080b:	ff d6                	call   *%esi
			break;
  80080d:	83 c4 10             	add    $0x10,%esp
		width = -1;
		precision = -1;
		lflag = 0;
		altflag = 0;
	reswitch:
		switch (ch = *(unsigned char *) fmt++) {
  800810:	8b 7d e4             	mov    -0x1c(%ebp),%edi
			break;

		// escaped '%' character
		case '%':
			putch(ch, putdat);
			break;
  800813:	e9 e1 fc ff ff       	jmp    8004f9 <vprintfmt+0x26>

		// unrecognized escape sequence - just print it literally
		default:
			putch('%', putdat);
  800818:	83 ec 08             	sub    $0x8,%esp
  80081b:	53                   	push   %ebx
  80081c:	6a 25                	push   $0x25
  80081e:	ff d6                	call   *%esi
			for (fmt--; fmt[-1] != '%'; fmt--)
  800820:	83 c4 10             	add    $0x10,%esp
  800823:	eb 03                	jmp    800828 <vprintfmt+0x355>
  800825:	83 ef 01             	sub    $0x1,%edi
  800828:	80 7f ff 25          	cmpb   $0x25,-0x1(%edi)
  80082c:	75 f7                	jne    800825 <vprintfmt+0x352>
  80082e:	e9 c6 fc ff ff       	jmp    8004f9 <vprintfmt+0x26>
				/* do nothing */;
			break;
		}
	}
}
  800833:	8d 65 f4             	lea    -0xc(%ebp),%esp
  800836:	5b                   	pop    %ebx
  800837:	5e                   	pop    %esi
  800838:	5f                   	pop    %edi
  800839:	5d                   	pop    %ebp
  80083a:	c3                   	ret    

0080083b <vsnprintf>:
		*b->buf++ = ch;
}

int
vsnprintf(char *buf, int n, const char *fmt, va_list ap)
{
  80083b:	55                   	push   %ebp
  80083c:	89 e5                	mov    %esp,%ebp
  80083e:	83 ec 18             	sub    $0x18,%esp
  800841:	8b 45 08             	mov    0x8(%ebp),%eax
  800844:	8b 55 0c             	mov    0xc(%ebp),%edx
	struct sprintbuf b = {buf, buf+n-1, 0};
  800847:	89 45 ec             	mov    %eax,-0x14(%ebp)
  80084a:	8d 4c 10 ff          	lea    -0x1(%eax,%edx,1),%ecx
  80084e:	89 4d f0             	mov    %ecx,-0x10(%ebp)
  800851:	c7 45 f4 00 00 00 00 	movl   $0x0,-0xc(%ebp)

	if (buf == NULL || n < 1)
  800858:	85 c0                	test   %eax,%eax
  80085a:	74 26                	je     800882 <vsnprintf+0x47>
  80085c:	85 d2                	test   %edx,%edx
  80085e:	7e 22                	jle    800882 <vsnprintf+0x47>
		return -E_INVAL;

	// print the string to the buffer
	vprintfmt((void*)sprintputch, &b, fmt, ap);
  800860:	ff 75 14             	pushl  0x14(%ebp)
  800863:	ff 75 10             	pushl  0x10(%ebp)
  800866:	8d 45 ec             	lea    -0x14(%ebp),%eax
  800869:	50                   	push   %eax
  80086a:	68 99 04 80 00       	push   $0x800499
  80086f:	e8 5f fc ff ff       	call   8004d3 <vprintfmt>

	// null terminate the buffer
	*b.buf = '\0';
  800874:	8b 45 ec             	mov    -0x14(%ebp),%eax
  800877:	c6 00 00             	movb   $0x0,(%eax)

	return b.cnt;
  80087a:	8b 45 f4             	mov    -0xc(%ebp),%eax
  80087d:	83 c4 10             	add    $0x10,%esp
  800880:	eb 05                	jmp    800887 <vsnprintf+0x4c>
vsnprintf(char *buf, int n, const char *fmt, va_list ap)
{
	struct sprintbuf b = {buf, buf+n-1, 0};

	if (buf == NULL || n < 1)
		return -E_INVAL;
  800882:	b8 fd ff ff ff       	mov    $0xfffffffd,%eax

	// null terminate the buffer
	*b.buf = '\0';

	return b.cnt;
}
  800887:	c9                   	leave  
  800888:	c3                   	ret    

00800889 <snprintf>:

int
snprintf(char *buf, int n, const char *fmt, ...)
{
  800889:	55                   	push   %ebp
  80088a:	89 e5                	mov    %esp,%ebp
  80088c:	83 ec 08             	sub    $0x8,%esp
	va_list ap;
	int rc;

	va_start(ap, fmt);
  80088f:	8d 45 14             	lea    0x14(%ebp),%eax
	rc = vsnprintf(buf, n, fmt, ap);
  800892:	50                   	push   %eax
  800893:	ff 75 10             	pushl  0x10(%ebp)
  800896:	ff 75 0c             	pushl  0xc(%ebp)
  800899:	ff 75 08             	pushl  0x8(%ebp)
  80089c:	e8 9a ff ff ff       	call   80083b <vsnprintf>
	va_end(ap);

	return rc;
}
  8008a1:	c9                   	leave  
  8008a2:	c3                   	ret    

008008a3 <strlen>:
// Primespipe runs 3x faster this way.
#define ASM 1

int
strlen(const char *s)
{
  8008a3:	55                   	push   %ebp
  8008a4:	89 e5                	mov    %esp,%ebp
  8008a6:	8b 55 08             	mov    0x8(%ebp),%edx
	int n;

	for (n = 0; *s != '\0'; s++)
  8008a9:	b8 00 00 00 00       	mov    $0x0,%eax
  8008ae:	eb 03                	jmp    8008b3 <strlen+0x10>
		n++;
  8008b0:	83 c0 01             	add    $0x1,%eax
int
strlen(const char *s)
{
	int n;

	for (n = 0; *s != '\0'; s++)
  8008b3:	80 3c 02 00          	cmpb   $0x0,(%edx,%eax,1)
  8008b7:	75 f7                	jne    8008b0 <strlen+0xd>
		n++;
	return n;
}
  8008b9:	5d                   	pop    %ebp
  8008ba:	c3                   	ret    

008008bb <strnlen>:

int
strnlen(const char *s, size_t size)
{
  8008bb:	55                   	push   %ebp
  8008bc:	89 e5                	mov    %esp,%ebp
  8008be:	8b 4d 08             	mov    0x8(%ebp),%ecx
  8008c1:	8b 45 0c             	mov    0xc(%ebp),%eax
	int n;

	for (n = 0; size > 0 && *s != '\0'; s++, size--)
  8008c4:	ba 00 00 00 00       	mov    $0x0,%edx
  8008c9:	eb 03                	jmp    8008ce <strnlen+0x13>
		n++;
  8008cb:	83 c2 01             	add    $0x1,%edx
int
strnlen(const char *s, size_t size)
{
	int n;

	for (n = 0; size > 0 && *s != '\0'; s++, size--)
  8008ce:	39 c2                	cmp    %eax,%edx
  8008d0:	74 08                	je     8008da <strnlen+0x1f>
  8008d2:	80 3c 11 00          	cmpb   $0x0,(%ecx,%edx,1)
  8008d6:	75 f3                	jne    8008cb <strnlen+0x10>
  8008d8:	89 d0                	mov    %edx,%eax
		n++;
	return n;
}
  8008da:	5d                   	pop    %ebp
  8008db:	c3                   	ret    

008008dc <strcpy>:

char *
strcpy(char *dst, const char *src)
{
  8008dc:	55                   	push   %ebp
  8008dd:	89 e5                	mov    %esp,%ebp
  8008df:	53                   	push   %ebx
  8008e0:	8b 45 08             	mov    0x8(%ebp),%eax
  8008e3:	8b 4d 0c             	mov    0xc(%ebp),%ecx
	char *ret;

	ret = dst;
	while ((*dst++ = *src++) != '\0')
  8008e6:	89 c2                	mov    %eax,%edx
  8008e8:	83 c2 01             	add    $0x1,%edx
  8008eb:	83 c1 01             	add    $0x1,%ecx
  8008ee:	0f b6 59 ff          	movzbl -0x1(%ecx),%ebx
  8008f2:	88 5a ff             	mov    %bl,-0x1(%edx)
  8008f5:	84 db                	test   %bl,%bl
  8008f7:	75 ef                	jne    8008e8 <strcpy+0xc>
		/* do nothing */;
	return ret;
}
  8008f9:	5b                   	pop    %ebx
  8008fa:	5d                   	pop    %ebp
  8008fb:	c3                   	ret    

008008fc <strcat>:

char *
strcat(char *dst, const char *src)
{
  8008fc:	55                   	push   %ebp
  8008fd:	89 e5                	mov    %esp,%ebp
  8008ff:	53                   	push   %ebx
  800900:	8b 5d 08             	mov    0x8(%ebp),%ebx
	int len = strlen(dst);
  800903:	53                   	push   %ebx
  800904:	e8 9a ff ff ff       	call   8008a3 <strlen>
  800909:	83 c4 04             	add    $0x4,%esp
	strcpy(dst + len, src);
  80090c:	ff 75 0c             	pushl  0xc(%ebp)
  80090f:	01 d8                	add    %ebx,%eax
  800911:	50                   	push   %eax
  800912:	e8 c5 ff ff ff       	call   8008dc <strcpy>
	return dst;
}
  800917:	89 d8                	mov    %ebx,%eax
  800919:	8b 5d fc             	mov    -0x4(%ebp),%ebx
  80091c:	c9                   	leave  
  80091d:	c3                   	ret    

0080091e <strncpy>:

char *
strncpy(char *dst, const char *src, size_t size) {
  80091e:	55                   	push   %ebp
  80091f:	89 e5                	mov    %esp,%ebp
  800921:	56                   	push   %esi
  800922:	53                   	push   %ebx
  800923:	8b 75 08             	mov    0x8(%ebp),%esi
  800926:	8b 4d 0c             	mov    0xc(%ebp),%ecx
  800929:	89 f3                	mov    %esi,%ebx
  80092b:	03 5d 10             	add    0x10(%ebp),%ebx
	size_t i;
	char *ret;

	ret = dst;
	for (i = 0; i < size; i++) {
  80092e:	89 f2                	mov    %esi,%edx
  800930:	eb 0f                	jmp    800941 <strncpy+0x23>
		*dst++ = *src;
  800932:	83 c2 01             	add    $0x1,%edx
  800935:	0f b6 01             	movzbl (%ecx),%eax
  800938:	88 42 ff             	mov    %al,-0x1(%edx)
		// If strlen(src) < size, null-pad 'dst' out to 'size' chars
		if (*src != '\0')
			src++;
  80093b:	80 39 01             	cmpb   $0x1,(%ecx)
  80093e:	83 d9 ff             	sbb    $0xffffffff,%ecx
strncpy(char *dst, const char *src, size_t size) {
	size_t i;
	char *ret;

	ret = dst;
	for (i = 0; i < size; i++) {
  800941:	39 da                	cmp    %ebx,%edx
  800943:	75 ed                	jne    800932 <strncpy+0x14>
		// If strlen(src) < size, null-pad 'dst' out to 'size' chars
		if (*src != '\0')
			src++;
	}
	return ret;
}
  800945:	89 f0                	mov    %esi,%eax
  800947:	5b                   	pop    %ebx
  800948:	5e                   	pop    %esi
  800949:	5d                   	pop    %ebp
  80094a:	c3                   	ret    

0080094b <strlcpy>:

size_t
strlcpy(char *dst, const char *src, size_t size)
{
  80094b:	55                   	push   %ebp
  80094c:	89 e5                	mov    %esp,%ebp
  80094e:	56                   	push   %esi
  80094f:	53                   	push   %ebx
  800950:	8b 75 08             	mov    0x8(%ebp),%esi
  800953:	8b 4d 0c             	mov    0xc(%ebp),%ecx
  800956:	8b 55 10             	mov    0x10(%ebp),%edx
  800959:	89 f0                	mov    %esi,%eax
	char *dst_in;

	dst_in = dst;
	if (size > 0) {
  80095b:	85 d2                	test   %edx,%edx
  80095d:	74 21                	je     800980 <strlcpy+0x35>
  80095f:	8d 44 16 ff          	lea    -0x1(%esi,%edx,1),%eax
  800963:	89 f2                	mov    %esi,%edx
  800965:	eb 09                	jmp    800970 <strlcpy+0x25>
		while (--size > 0 && *src != '\0')
			*dst++ = *src++;
  800967:	83 c2 01             	add    $0x1,%edx
  80096a:	83 c1 01             	add    $0x1,%ecx
  80096d:	88 5a ff             	mov    %bl,-0x1(%edx)
{
	char *dst_in;

	dst_in = dst;
	if (size > 0) {
		while (--size > 0 && *src != '\0')
  800970:	39 c2                	cmp    %eax,%edx
  800972:	74 09                	je     80097d <strlcpy+0x32>
  800974:	0f b6 19             	movzbl (%ecx),%ebx
  800977:	84 db                	test   %bl,%bl
  800979:	75 ec                	jne    800967 <strlcpy+0x1c>
  80097b:	89 d0                	mov    %edx,%eax
			*dst++ = *src++;
		*dst = '\0';
  80097d:	c6 00 00             	movb   $0x0,(%eax)
	}
	return dst - dst_in;
  800980:	29 f0                	sub    %esi,%eax
}
  800982:	5b                   	pop    %ebx
  800983:	5e                   	pop    %esi
  800984:	5d                   	pop    %ebp
  800985:	c3                   	ret    

00800986 <strcmp>:

int
strcmp(const char *p, const char *q)
{
  800986:	55                   	push   %ebp
  800987:	89 e5                	mov    %esp,%ebp
  800989:	8b 4d 08             	mov    0x8(%ebp),%ecx
  80098c:	8b 55 0c             	mov    0xc(%ebp),%edx
	while (*p && *p == *q)
  80098f:	eb 06                	jmp    800997 <strcmp+0x11>
		p++, q++;
  800991:	83 c1 01             	add    $0x1,%ecx
  800994:	83 c2 01             	add    $0x1,%edx
}

int
strcmp(const char *p, const char *q)
{
	while (*p && *p == *q)
  800997:	0f b6 01             	movzbl (%ecx),%eax
  80099a:	84 c0                	test   %al,%al
  80099c:	74 04                	je     8009a2 <strcmp+0x1c>
  80099e:	3a 02                	cmp    (%edx),%al
  8009a0:	74 ef                	je     800991 <strcmp+0xb>
		p++, q++;
	return (int) ((unsigned char) *p - (unsigned char) *q);
  8009a2:	0f b6 c0             	movzbl %al,%eax
  8009a5:	0f b6 12             	movzbl (%edx),%edx
  8009a8:	29 d0                	sub    %edx,%eax
}
  8009aa:	5d                   	pop    %ebp
  8009ab:	c3                   	ret    

008009ac <strncmp>:

int
strncmp(const char *p, const char *q, size_t n)
{
  8009ac:	55                   	push   %ebp
  8009ad:	89 e5                	mov    %esp,%ebp
  8009af:	53                   	push   %ebx
  8009b0:	8b 45 08             	mov    0x8(%ebp),%eax
  8009b3:	8b 55 0c             	mov    0xc(%ebp),%edx
  8009b6:	89 c3                	mov    %eax,%ebx
  8009b8:	03 5d 10             	add    0x10(%ebp),%ebx
	while (n > 0 && *p && *p == *q)
  8009bb:	eb 06                	jmp    8009c3 <strncmp+0x17>
		n--, p++, q++;
  8009bd:	83 c0 01             	add    $0x1,%eax
  8009c0:	83 c2 01             	add    $0x1,%edx
}

int
strncmp(const char *p, const char *q, size_t n)
{
	while (n > 0 && *p && *p == *q)
  8009c3:	39 d8                	cmp    %ebx,%eax
  8009c5:	74 15                	je     8009dc <strncmp+0x30>
  8009c7:	0f b6 08             	movzbl (%eax),%ecx
  8009ca:	84 c9                	test   %cl,%cl
  8009cc:	74 04                	je     8009d2 <strncmp+0x26>
  8009ce:	3a 0a                	cmp    (%edx),%cl
  8009d0:	74 eb                	je     8009bd <strncmp+0x11>
		n--, p++, q++;
	if (n == 0)
		return 0;
	else
		return (int) ((unsigned char) *p - (unsigned char) *q);
  8009d2:	0f b6 00             	movzbl (%eax),%eax
  8009d5:	0f b6 12             	movzbl (%edx),%edx
  8009d8:	29 d0                	sub    %edx,%eax
  8009da:	eb 05                	jmp    8009e1 <strncmp+0x35>
strncmp(const char *p, const char *q, size_t n)
{
	while (n > 0 && *p && *p == *q)
		n--, p++, q++;
	if (n == 0)
		return 0;
  8009dc:	b8 00 00 00 00       	mov    $0x0,%eax
	else
		return (int) ((unsigned char) *p - (unsigned char) *q);
}
  8009e1:	5b                   	pop    %ebx
  8009e2:	5d                   	pop    %ebp
  8009e3:	c3                   	ret    

008009e4 <strchr>:

// Return a pointer to the first occurrence of 'c' in 's',
// or a null pointer if the string has no 'c'.
char *
strchr(const char *s, char c)
{
  8009e4:	55                   	push   %ebp
  8009e5:	89 e5                	mov    %esp,%ebp
  8009e7:	8b 45 08             	mov    0x8(%ebp),%eax
  8009ea:	0f b6 4d 0c          	movzbl 0xc(%ebp),%ecx
	for (; *s; s++)
  8009ee:	eb 07                	jmp    8009f7 <strchr+0x13>
		if (*s == c)
  8009f0:	38 ca                	cmp    %cl,%dl
  8009f2:	74 0f                	je     800a03 <strchr+0x1f>
// Return a pointer to the first occurrence of 'c' in 's',
// or a null pointer if the string has no 'c'.
char *
strchr(const char *s, char c)
{
	for (; *s; s++)
  8009f4:	83 c0 01             	add    $0x1,%eax
  8009f7:	0f b6 10             	movzbl (%eax),%edx
  8009fa:	84 d2                	test   %dl,%dl
  8009fc:	75 f2                	jne    8009f0 <strchr+0xc>
		if (*s == c)
			return (char *) s;
	return 0;
  8009fe:	b8 00 00 00 00       	mov    $0x0,%eax
}
  800a03:	5d                   	pop    %ebp
  800a04:	c3                   	ret    

00800a05 <strfind>:

// Return a pointer to the first occurrence of 'c' in 's',
// or a pointer to the string-ending null character if the string has no 'c'.
char *
strfind(const char *s, char c)
{
  800a05:	55                   	push   %ebp
  800a06:	89 e5                	mov    %esp,%ebp
  800a08:	8b 45 08             	mov    0x8(%ebp),%eax
  800a0b:	0f b6 4d 0c          	movzbl 0xc(%ebp),%ecx
	for (; *s; s++)
  800a0f:	eb 03                	jmp    800a14 <strfind+0xf>
  800a11:	83 c0 01             	add    $0x1,%eax
  800a14:	0f b6 10             	movzbl (%eax),%edx
		if (*s == c)
  800a17:	38 ca                	cmp    %cl,%dl
  800a19:	74 04                	je     800a1f <strfind+0x1a>
  800a1b:	84 d2                	test   %dl,%dl
  800a1d:	75 f2                	jne    800a11 <strfind+0xc>
			break;
	return (char *) s;
}
  800a1f:	5d                   	pop    %ebp
  800a20:	c3                   	ret    

00800a21 <memset>:

#if ASM
void *
memset(void *v, int c, size_t n)
{
  800a21:	55                   	push   %ebp
  800a22:	89 e5                	mov    %esp,%ebp
  800a24:	57                   	push   %edi
  800a25:	56                   	push   %esi
  800a26:	53                   	push   %ebx
  800a27:	8b 55 08             	mov    0x8(%ebp),%edx
  800a2a:	8b 4d 10             	mov    0x10(%ebp),%ecx
	char *p = v;

	if (n == 0)
  800a2d:	85 c9                	test   %ecx,%ecx
  800a2f:	74 37                	je     800a68 <memset+0x47>
		return v;
	if ((int)v%4 == 0 && n%4 == 0) {
  800a31:	f6 c2 03             	test   $0x3,%dl
  800a34:	75 2a                	jne    800a60 <memset+0x3f>
  800a36:	f6 c1 03             	test   $0x3,%cl
  800a39:	75 25                	jne    800a60 <memset+0x3f>
		c &= 0xFF;
  800a3b:	0f b6 5d 0c          	movzbl 0xc(%ebp),%ebx
		c = (c<<24)|(c<<16)|(c<<8)|c;
  800a3f:	89 df                	mov    %ebx,%edi
  800a41:	c1 e7 08             	shl    $0x8,%edi
  800a44:	89 de                	mov    %ebx,%esi
  800a46:	c1 e6 18             	shl    $0x18,%esi
  800a49:	89 d8                	mov    %ebx,%eax
  800a4b:	c1 e0 10             	shl    $0x10,%eax
  800a4e:	09 f0                	or     %esi,%eax
  800a50:	09 c3                	or     %eax,%ebx
		asm volatile("cld; rep stosl\n"
			: "=D" (p), "=c" (n)
			: "D" (p), "a" (c), "c" (n/4)
  800a52:	c1 e9 02             	shr    $0x2,%ecx
	if (n == 0)
		return v;
	if ((int)v%4 == 0 && n%4 == 0) {
		c &= 0xFF;
		c = (c<<24)|(c<<16)|(c<<8)|c;
		asm volatile("cld; rep stosl\n"
  800a55:	89 f8                	mov    %edi,%eax
  800a57:	09 d8                	or     %ebx,%eax
  800a59:	89 d7                	mov    %edx,%edi
  800a5b:	fc                   	cld    
  800a5c:	f3 ab                	rep stos %eax,%es:(%edi)
  800a5e:	eb 08                	jmp    800a68 <memset+0x47>
			: "=D" (p), "=c" (n)
			: "D" (p), "a" (c), "c" (n/4)
			: "cc", "memory");
	} else
		asm volatile("cld; rep stosb\n"
  800a60:	89 d7                	mov    %edx,%edi
  800a62:	8b 45 0c             	mov    0xc(%ebp),%eax
  800a65:	fc                   	cld    
  800a66:	f3 aa                	rep stos %al,%es:(%edi)
			: "=D" (p), "=c" (n)
			: "0" (p), "a" (c), "1" (n)
			: "cc", "memory");
	return v;
}
  800a68:	89 d0                	mov    %edx,%eax
  800a6a:	5b                   	pop    %ebx
  800a6b:	5e                   	pop    %esi
  800a6c:	5f                   	pop    %edi
  800a6d:	5d                   	pop    %ebp
  800a6e:	c3                   	ret    

00800a6f <memmove>:

void *
memmove(void *dst, const void *src, size_t n)
{
  800a6f:	55                   	push   %ebp
  800a70:	89 e5                	mov    %esp,%ebp
  800a72:	57                   	push   %edi
  800a73:	56                   	push   %esi
  800a74:	8b 45 08             	mov    0x8(%ebp),%eax
  800a77:	8b 75 0c             	mov    0xc(%ebp),%esi
  800a7a:	8b 4d 10             	mov    0x10(%ebp),%ecx
	const char *s;
	char *d;

	s = src;
	d = dst;
	if (s < d && s + n > d) {
  800a7d:	39 c6                	cmp    %eax,%esi
  800a7f:	73 35                	jae    800ab6 <memmove+0x47>
  800a81:	8d 14 0e             	lea    (%esi,%ecx,1),%edx
  800a84:	39 d0                	cmp    %edx,%eax
  800a86:	73 2e                	jae    800ab6 <memmove+0x47>
		s += n;
		d += n;
  800a88:	8d 3c 08             	lea    (%eax,%ecx,1),%edi
		if ((int)s%4 == 0 && (int)d%4 == 0 && n%4 == 0)
  800a8b:	89 d6                	mov    %edx,%esi
  800a8d:	09 fe                	or     %edi,%esi
  800a8f:	f7 c6 03 00 00 00    	test   $0x3,%esi
  800a95:	75 13                	jne    800aaa <memmove+0x3b>
  800a97:	f6 c1 03             	test   $0x3,%cl
  800a9a:	75 0e                	jne    800aaa <memmove+0x3b>
			asm volatile("std; rep movsl\n"
  800a9c:	83 ef 04             	sub    $0x4,%edi
  800a9f:	8d 72 fc             	lea    -0x4(%edx),%esi
  800aa2:	c1 e9 02             	shr    $0x2,%ecx
  800aa5:	fd                   	std    
  800aa6:	f3 a5                	rep movsl %ds:(%esi),%es:(%edi)
  800aa8:	eb 09                	jmp    800ab3 <memmove+0x44>
				:: "D" (d-4), "S" (s-4), "c" (n/4) : "cc", "memory");
		else
			asm volatile("std; rep movsb\n"
  800aaa:	83 ef 01             	sub    $0x1,%edi
  800aad:	8d 72 ff             	lea    -0x1(%edx),%esi
  800ab0:	fd                   	std    
  800ab1:	f3 a4                	rep movsb %ds:(%esi),%es:(%edi)
				:: "D" (d-1), "S" (s-1), "c" (n) : "cc", "memory");
		// Some versions of GCC rely on DF being clear
		asm volatile("cld" ::: "cc");
  800ab3:	fc                   	cld    
  800ab4:	eb 1d                	jmp    800ad3 <memmove+0x64>
	} else {
		if ((int)s%4 == 0 && (int)d%4 == 0 && n%4 == 0)
  800ab6:	89 f2                	mov    %esi,%edx
  800ab8:	09 c2                	or     %eax,%edx
  800aba:	f6 c2 03             	test   $0x3,%dl
  800abd:	75 0f                	jne    800ace <memmove+0x5f>
  800abf:	f6 c1 03             	test   $0x3,%cl
  800ac2:	75 0a                	jne    800ace <memmove+0x5f>
			asm volatile("cld; rep movsl\n"
  800ac4:	c1 e9 02             	shr    $0x2,%ecx
  800ac7:	89 c7                	mov    %eax,%edi
  800ac9:	fc                   	cld    
  800aca:	f3 a5                	rep movsl %ds:(%esi),%es:(%edi)
  800acc:	eb 05                	jmp    800ad3 <memmove+0x64>
				:: "D" (d), "S" (s), "c" (n/4) : "cc", "memory");
		else
			asm volatile("cld; rep movsb\n"
  800ace:	89 c7                	mov    %eax,%edi
  800ad0:	fc                   	cld    
  800ad1:	f3 a4                	rep movsb %ds:(%esi),%es:(%edi)
				:: "D" (d), "S" (s), "c" (n) : "cc", "memory");
	}
	return dst;
}
  800ad3:	5e                   	pop    %esi
  800ad4:	5f                   	pop    %edi
  800ad5:	5d                   	pop    %ebp
  800ad6:	c3                   	ret    

00800ad7 <memcpy>:
}
#endif

void *
memcpy(void *dst, const void *src, size_t n)
{
  800ad7:	55                   	push   %ebp
  800ad8:	89 e5                	mov    %esp,%ebp
	return memmove(dst, src, n);
  800ada:	ff 75 10             	pushl  0x10(%ebp)
  800add:	ff 75 0c             	pushl  0xc(%ebp)
  800ae0:	ff 75 08             	pushl  0x8(%ebp)
  800ae3:	e8 87 ff ff ff       	call   800a6f <memmove>
}
  800ae8:	c9                   	leave  
  800ae9:	c3                   	ret    

00800aea <memcmp>:

int
memcmp(const void *v1, const void *v2, size_t n)
{
  800aea:	55                   	push   %ebp
  800aeb:	89 e5                	mov    %esp,%ebp
  800aed:	56                   	push   %esi
  800aee:	53                   	push   %ebx
  800aef:	8b 45 08             	mov    0x8(%ebp),%eax
  800af2:	8b 55 0c             	mov    0xc(%ebp),%edx
  800af5:	89 c6                	mov    %eax,%esi
  800af7:	03 75 10             	add    0x10(%ebp),%esi
	const uint8_t *s1 = (const uint8_t *) v1;
	const uint8_t *s2 = (const uint8_t *) v2;

	while (n-- > 0) {
  800afa:	eb 1a                	jmp    800b16 <memcmp+0x2c>
		if (*s1 != *s2)
  800afc:	0f b6 08             	movzbl (%eax),%ecx
  800aff:	0f b6 1a             	movzbl (%edx),%ebx
  800b02:	38 d9                	cmp    %bl,%cl
  800b04:	74 0a                	je     800b10 <memcmp+0x26>
			return (int) *s1 - (int) *s2;
  800b06:	0f b6 c1             	movzbl %cl,%eax
  800b09:	0f b6 db             	movzbl %bl,%ebx
  800b0c:	29 d8                	sub    %ebx,%eax
  800b0e:	eb 0f                	jmp    800b1f <memcmp+0x35>
		s1++, s2++;
  800b10:	83 c0 01             	add    $0x1,%eax
  800b13:	83 c2 01             	add    $0x1,%edx
memcmp(const void *v1, const void *v2, size_t n)
{
	const uint8_t *s1 = (const uint8_t *) v1;
	const uint8_t *s2 = (const uint8_t *) v2;

	while (n-- > 0) {
  800b16:	39 f0                	cmp    %esi,%eax
  800b18:	75 e2                	jne    800afc <memcmp+0x12>
		if (*s1 != *s2)
			return (int) *s1 - (int) *s2;
		s1++, s2++;
	}

	return 0;
  800b1a:	b8 00 00 00 00       	mov    $0x0,%eax
}
  800b1f:	5b                   	pop    %ebx
  800b20:	5e                   	pop    %esi
  800b21:	5d                   	pop    %ebp
  800b22:	c3                   	ret    

00800b23 <memfind>:

void *
memfind(const void *s, int c, size_t n)
{
  800b23:	55                   	push   %ebp
  800b24:	89 e5                	mov    %esp,%ebp
  800b26:	8b 45 08             	mov    0x8(%ebp),%eax
  800b29:	8b 4d 0c             	mov    0xc(%ebp),%ecx
	const void *ends = (const char *) s + n;
  800b2c:	89 c2                	mov    %eax,%edx
  800b2e:	03 55 10             	add    0x10(%ebp),%edx
	for (; s < ends; s++)
  800b31:	eb 07                	jmp    800b3a <memfind+0x17>
		if (*(const unsigned char *) s == (unsigned char) c)
  800b33:	38 08                	cmp    %cl,(%eax)
  800b35:	74 07                	je     800b3e <memfind+0x1b>

void *
memfind(const void *s, int c, size_t n)
{
	const void *ends = (const char *) s + n;
	for (; s < ends; s++)
  800b37:	83 c0 01             	add    $0x1,%eax
  800b3a:	39 d0                	cmp    %edx,%eax
  800b3c:	72 f5                	jb     800b33 <memfind+0x10>
		if (*(const unsigned char *) s == (unsigned char) c)
			break;
	return (void *) s;
}
  800b3e:	5d                   	pop    %ebp
  800b3f:	c3                   	ret    

00800b40 <strtol>:

long
strtol(const char *s, char **endptr, int base)
{
  800b40:	55                   	push   %ebp
  800b41:	89 e5                	mov    %esp,%ebp
  800b43:	57                   	push   %edi
  800b44:	56                   	push   %esi
  800b45:	53                   	push   %ebx
  800b46:	8b 4d 08             	mov    0x8(%ebp),%ecx
  800b49:	8b 5d 10             	mov    0x10(%ebp),%ebx
	int neg = 0;
	long val = 0;

	// gobble initial whitespace
	while (*s == ' ' || *s == '\t')
  800b4c:	eb 03                	jmp    800b51 <strtol+0x11>
		s++;
  800b4e:	83 c1 01             	add    $0x1,%ecx
{
	int neg = 0;
	long val = 0;

	// gobble initial whitespace
	while (*s == ' ' || *s == '\t')
  800b51:	0f b6 01             	movzbl (%ecx),%eax
  800b54:	3c 20                	cmp    $0x20,%al
  800b56:	74 f6                	je     800b4e <strtol+0xe>
  800b58:	3c 09                	cmp    $0x9,%al
  800b5a:	74 f2                	je     800b4e <strtol+0xe>
		s++;

	// plus/minus sign
	if (*s == '+')
  800b5c:	3c 2b                	cmp    $0x2b,%al
  800b5e:	75 0a                	jne    800b6a <strtol+0x2a>
		s++;
  800b60:	83 c1 01             	add    $0x1,%ecx
}

long
strtol(const char *s, char **endptr, int base)
{
	int neg = 0;
  800b63:	bf 00 00 00 00       	mov    $0x0,%edi
  800b68:	eb 11                	jmp    800b7b <strtol+0x3b>
  800b6a:	bf 00 00 00 00       	mov    $0x0,%edi
		s++;

	// plus/minus sign
	if (*s == '+')
		s++;
	else if (*s == '-')
  800b6f:	3c 2d                	cmp    $0x2d,%al
  800b71:	75 08                	jne    800b7b <strtol+0x3b>
		s++, neg = 1;
  800b73:	83 c1 01             	add    $0x1,%ecx
  800b76:	bf 01 00 00 00       	mov    $0x1,%edi

	// hex or octal base prefix
	if ((base == 0 || base == 16) && (s[0] == '0' && s[1] == 'x'))
  800b7b:	f7 c3 ef ff ff ff    	test   $0xffffffef,%ebx
  800b81:	75 15                	jne    800b98 <strtol+0x58>
  800b83:	80 39 30             	cmpb   $0x30,(%ecx)
  800b86:	75 10                	jne    800b98 <strtol+0x58>
  800b88:	80 79 01 78          	cmpb   $0x78,0x1(%ecx)
  800b8c:	75 7c                	jne    800c0a <strtol+0xca>
		s += 2, base = 16;
  800b8e:	83 c1 02             	add    $0x2,%ecx
  800b91:	bb 10 00 00 00       	mov    $0x10,%ebx
  800b96:	eb 16                	jmp    800bae <strtol+0x6e>
	else if (base == 0 && s[0] == '0')
  800b98:	85 db                	test   %ebx,%ebx
  800b9a:	75 12                	jne    800bae <strtol+0x6e>
		s++, base = 8;
	else if (base == 0)
		base = 10;
  800b9c:	bb 0a 00 00 00       	mov    $0xa,%ebx
		s++, neg = 1;

	// hex or octal base prefix
	if ((base == 0 || base == 16) && (s[0] == '0' && s[1] == 'x'))
		s += 2, base = 16;
	else if (base == 0 && s[0] == '0')
  800ba1:	80 39 30             	cmpb   $0x30,(%ecx)
  800ba4:	75 08                	jne    800bae <strtol+0x6e>
		s++, base = 8;
  800ba6:	83 c1 01             	add    $0x1,%ecx
  800ba9:	bb 08 00 00 00       	mov    $0x8,%ebx
	else if (base == 0)
		base = 10;
  800bae:	b8 00 00 00 00       	mov    $0x0,%eax
  800bb3:	89 5d 10             	mov    %ebx,0x10(%ebp)

	// digits
	while (1) {
		int dig;

		if (*s >= '0' && *s <= '9')
  800bb6:	0f b6 11             	movzbl (%ecx),%edx
  800bb9:	8d 72 d0             	lea    -0x30(%edx),%esi
  800bbc:	89 f3                	mov    %esi,%ebx
  800bbe:	80 fb 09             	cmp    $0x9,%bl
  800bc1:	77 08                	ja     800bcb <strtol+0x8b>
			dig = *s - '0';
  800bc3:	0f be d2             	movsbl %dl,%edx
  800bc6:	83 ea 30             	sub    $0x30,%edx
  800bc9:	eb 22                	jmp    800bed <strtol+0xad>
		else if (*s >= 'a' && *s <= 'z')
  800bcb:	8d 72 9f             	lea    -0x61(%edx),%esi
  800bce:	89 f3                	mov    %esi,%ebx
  800bd0:	80 fb 19             	cmp    $0x19,%bl
  800bd3:	77 08                	ja     800bdd <strtol+0x9d>
			dig = *s - 'a' + 10;
  800bd5:	0f be d2             	movsbl %dl,%edx
  800bd8:	83 ea 57             	sub    $0x57,%edx
  800bdb:	eb 10                	jmp    800bed <strtol+0xad>
		else if (*s >= 'A' && *s <= 'Z')
  800bdd:	8d 72 bf             	lea    -0x41(%edx),%esi
  800be0:	89 f3                	mov    %esi,%ebx
  800be2:	80 fb 19             	cmp    $0x19,%bl
  800be5:	77 16                	ja     800bfd <strtol+0xbd>
			dig = *s - 'A' + 10;
  800be7:	0f be d2             	movsbl %dl,%edx
  800bea:	83 ea 37             	sub    $0x37,%edx
		else
			break;
		if (dig >= base)
  800bed:	3b 55 10             	cmp    0x10(%ebp),%edx
  800bf0:	7d 0b                	jge    800bfd <strtol+0xbd>
			break;
		s++, val = (val * base) + dig;
  800bf2:	83 c1 01             	add    $0x1,%ecx
  800bf5:	0f af 45 10          	imul   0x10(%ebp),%eax
  800bf9:	01 d0                	add    %edx,%eax
		// we don't properly detect overflow!
	}
  800bfb:	eb b9                	jmp    800bb6 <strtol+0x76>

	if (endptr)
  800bfd:	83 7d 0c 00          	cmpl   $0x0,0xc(%ebp)
  800c01:	74 0d                	je     800c10 <strtol+0xd0>
		*endptr = (char *) s;
  800c03:	8b 75 0c             	mov    0xc(%ebp),%esi
  800c06:	89 0e                	mov    %ecx,(%esi)
  800c08:	eb 06                	jmp    800c10 <strtol+0xd0>
		s++, neg = 1;

	// hex or octal base prefix
	if ((base == 0 || base == 16) && (s[0] == '0' && s[1] == 'x'))
		s += 2, base = 16;
	else if (base == 0 && s[0] == '0')
  800c0a:	85 db                	test   %ebx,%ebx
  800c0c:	74 98                	je     800ba6 <strtol+0x66>
  800c0e:	eb 9e                	jmp    800bae <strtol+0x6e>
		// we don't properly detect overflow!
	}

	if (endptr)
		*endptr = (char *) s;
	return (neg ? -val : val);
  800c10:	89 c2                	mov    %eax,%edx
  800c12:	f7 da                	neg    %edx
  800c14:	85 ff                	test   %edi,%edi
  800c16:	0f 45 c2             	cmovne %edx,%eax
}
  800c19:	5b                   	pop    %ebx
  800c1a:	5e                   	pop    %esi
  800c1b:	5f                   	pop    %edi
  800c1c:	5d                   	pop    %ebp
  800c1d:	c3                   	ret    
  800c1e:	66 90                	xchg   %ax,%ax

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
