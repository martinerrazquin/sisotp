
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
  800044:	e8 ab 00 00 00       	call   8000f4 <sys_cputs>
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
  800051:	56                   	push   %esi
  800052:	53                   	push   %ebx
  800053:	8b 5d 08             	mov    0x8(%ebp),%ebx
  800056:	8b 75 0c             	mov    0xc(%ebp),%esi
	// set thisenv to point at our Env structure in envs[].
	// LAB 3: Your code here.
	envid_t id = sys_getenvid();
  800059:	e8 02 01 00 00       	call   800160 <sys_getenvid>
	if (id >= 0)
  80005e:	85 c0                	test   %eax,%eax
  800060:	78 12                	js     800074 <libmain+0x26>
		thisenv = &envs[ENVX(id)];
  800062:	25 ff 03 00 00       	and    $0x3ff,%eax
  800067:	6b c0 7c             	imul   $0x7c,%eax,%eax
  80006a:	05 00 00 c0 ee       	add    $0xeec00000,%eax
  80006f:	a3 08 20 80 00       	mov    %eax,0x802008

	// save the name of the program so that panic() can use it
	if (argc > 0)
  800074:	85 db                	test   %ebx,%ebx
  800076:	7e 07                	jle    80007f <libmain+0x31>
		binaryname = argv[0];
  800078:	8b 06                	mov    (%esi),%eax
  80007a:	a3 04 20 80 00       	mov    %eax,0x802004

	// call user main routine
	umain(argc, argv);
  80007f:	83 ec 08             	sub    $0x8,%esp
  800082:	56                   	push   %esi
  800083:	53                   	push   %ebx
  800084:	e8 aa ff ff ff       	call   800033 <umain>

	// exit gracefully
	exit();
  800089:	e8 0a 00 00 00       	call   800098 <exit>
}
  80008e:	83 c4 10             	add    $0x10,%esp
  800091:	8d 65 f8             	lea    -0x8(%ebp),%esp
  800094:	5b                   	pop    %ebx
  800095:	5e                   	pop    %esi
  800096:	5d                   	pop    %ebp
  800097:	c3                   	ret    

00800098 <exit>:

#include <inc/lib.h>

void
exit(void)
{
  800098:	55                   	push   %ebp
  800099:	89 e5                	mov    %esp,%ebp
  80009b:	83 ec 14             	sub    $0x14,%esp
	sys_env_destroy(0);
  80009e:	6a 00                	push   $0x0
  8000a0:	e8 99 00 00 00       	call   80013e <sys_env_destroy>
}
  8000a5:	83 c4 10             	add    $0x10,%esp
  8000a8:	c9                   	leave  
  8000a9:	c3                   	ret    

008000aa <syscall>:
#include <inc/syscall.h>
#include <inc/lib.h>

static inline int32_t
syscall(int num, int check, uint32_t a1, uint32_t a2, uint32_t a3, uint32_t a4, uint32_t a5)
{
  8000aa:	55                   	push   %ebp
  8000ab:	89 e5                	mov    %esp,%ebp
  8000ad:	57                   	push   %edi
  8000ae:	56                   	push   %esi
  8000af:	53                   	push   %ebx
  8000b0:	83 ec 1c             	sub    $0x1c,%esp
  8000b3:	89 45 e0             	mov    %eax,-0x20(%ebp)
  8000b6:	89 55 e4             	mov    %edx,-0x1c(%ebp)
  8000b9:	89 ca                	mov    %ecx,%edx
	//
	// The last clause tells the assembler that this can
	// potentially change the condition codes and arbitrary
	// memory locations.

	asm volatile("int %1\n"
  8000bb:	8b 4d 08             	mov    0x8(%ebp),%ecx
  8000be:	8b 5d 0c             	mov    0xc(%ebp),%ebx
  8000c1:	8b 7d 10             	mov    0x10(%ebp),%edi
  8000c4:	8b 75 14             	mov    0x14(%ebp),%esi
  8000c7:	cd 30                	int    $0x30
		       "b" (a3),
		       "D" (a4),
		       "S" (a5)
		     : "cc", "memory");

	if(check && ret > 0)
  8000c9:	83 7d e4 00          	cmpl   $0x0,-0x1c(%ebp)
  8000cd:	74 1d                	je     8000ec <syscall+0x42>
  8000cf:	85 c0                	test   %eax,%eax
  8000d1:	7e 19                	jle    8000ec <syscall+0x42>
  8000d3:	8b 55 e0             	mov    -0x20(%ebp),%edx
		panic("syscall %d returned %d (> 0)", num, ret);
  8000d6:	83 ec 0c             	sub    $0xc,%esp
  8000d9:	50                   	push   %eax
  8000da:	52                   	push   %edx
  8000db:	68 f8 0e 80 00       	push   $0x800ef8
  8000e0:	6a 23                	push   $0x23
  8000e2:	68 15 0f 80 00       	push   $0x800f15
  8000e7:	e8 b9 01 00 00       	call   8002a5 <_panic>

	return ret;
}
  8000ec:	8d 65 f4             	lea    -0xc(%ebp),%esp
  8000ef:	5b                   	pop    %ebx
  8000f0:	5e                   	pop    %esi
  8000f1:	5f                   	pop    %edi
  8000f2:	5d                   	pop    %ebp
  8000f3:	c3                   	ret    

008000f4 <sys_cputs>:

void
sys_cputs(const char *s, size_t len)
{
  8000f4:	55                   	push   %ebp
  8000f5:	89 e5                	mov    %esp,%ebp
  8000f7:	83 ec 08             	sub    $0x8,%esp
	syscall(SYS_cputs, 0, (uint32_t)s, len, 0, 0, 0);
  8000fa:	6a 00                	push   $0x0
  8000fc:	6a 00                	push   $0x0
  8000fe:	6a 00                	push   $0x0
  800100:	ff 75 0c             	pushl  0xc(%ebp)
  800103:	8b 4d 08             	mov    0x8(%ebp),%ecx
  800106:	ba 00 00 00 00       	mov    $0x0,%edx
  80010b:	b8 00 00 00 00       	mov    $0x0,%eax
  800110:	e8 95 ff ff ff       	call   8000aa <syscall>
}
  800115:	83 c4 10             	add    $0x10,%esp
  800118:	c9                   	leave  
  800119:	c3                   	ret    

0080011a <sys_cgetc>:

int
sys_cgetc(void)
{
  80011a:	55                   	push   %ebp
  80011b:	89 e5                	mov    %esp,%ebp
  80011d:	83 ec 08             	sub    $0x8,%esp
	return syscall(SYS_cgetc, 0, 0, 0, 0, 0, 0);
  800120:	6a 00                	push   $0x0
  800122:	6a 00                	push   $0x0
  800124:	6a 00                	push   $0x0
  800126:	6a 00                	push   $0x0
  800128:	b9 00 00 00 00       	mov    $0x0,%ecx
  80012d:	ba 00 00 00 00       	mov    $0x0,%edx
  800132:	b8 01 00 00 00       	mov    $0x1,%eax
  800137:	e8 6e ff ff ff       	call   8000aa <syscall>
}
  80013c:	c9                   	leave  
  80013d:	c3                   	ret    

0080013e <sys_env_destroy>:

int
sys_env_destroy(envid_t envid)
{
  80013e:	55                   	push   %ebp
  80013f:	89 e5                	mov    %esp,%ebp
  800141:	83 ec 08             	sub    $0x8,%esp
	return syscall(SYS_env_destroy, 1, envid, 0, 0, 0, 0);
  800144:	6a 00                	push   $0x0
  800146:	6a 00                	push   $0x0
  800148:	6a 00                	push   $0x0
  80014a:	6a 00                	push   $0x0
  80014c:	8b 4d 08             	mov    0x8(%ebp),%ecx
  80014f:	ba 01 00 00 00       	mov    $0x1,%edx
  800154:	b8 03 00 00 00       	mov    $0x3,%eax
  800159:	e8 4c ff ff ff       	call   8000aa <syscall>
}
  80015e:	c9                   	leave  
  80015f:	c3                   	ret    

00800160 <sys_getenvid>:

envid_t
sys_getenvid(void)
{
  800160:	55                   	push   %ebp
  800161:	89 e5                	mov    %esp,%ebp
  800163:	83 ec 08             	sub    $0x8,%esp
	 return syscall(SYS_getenvid, 0, 0, 0, 0, 0, 0);
  800166:	6a 00                	push   $0x0
  800168:	6a 00                	push   $0x0
  80016a:	6a 00                	push   $0x0
  80016c:	6a 00                	push   $0x0
  80016e:	b9 00 00 00 00       	mov    $0x0,%ecx
  800173:	ba 00 00 00 00       	mov    $0x0,%edx
  800178:	b8 02 00 00 00       	mov    $0x2,%eax
  80017d:	e8 28 ff ff ff       	call   8000aa <syscall>
}
  800182:	c9                   	leave  
  800183:	c3                   	ret    

00800184 <sys_yield>:

void
sys_yield(void)
{
  800184:	55                   	push   %ebp
  800185:	89 e5                	mov    %esp,%ebp
  800187:	83 ec 08             	sub    $0x8,%esp
	syscall(SYS_yield, 0, 0, 0, 0, 0, 0);
  80018a:	6a 00                	push   $0x0
  80018c:	6a 00                	push   $0x0
  80018e:	6a 00                	push   $0x0
  800190:	6a 00                	push   $0x0
  800192:	b9 00 00 00 00       	mov    $0x0,%ecx
  800197:	ba 00 00 00 00       	mov    $0x0,%edx
  80019c:	b8 0a 00 00 00       	mov    $0xa,%eax
  8001a1:	e8 04 ff ff ff       	call   8000aa <syscall>
}
  8001a6:	83 c4 10             	add    $0x10,%esp
  8001a9:	c9                   	leave  
  8001aa:	c3                   	ret    

008001ab <sys_page_alloc>:

int
sys_page_alloc(envid_t envid, void *va, int perm)
{
  8001ab:	55                   	push   %ebp
  8001ac:	89 e5                	mov    %esp,%ebp
  8001ae:	83 ec 08             	sub    $0x8,%esp
	return syscall(SYS_page_alloc, 1, envid, (uint32_t) va, perm, 0, 0);
  8001b1:	6a 00                	push   $0x0
  8001b3:	6a 00                	push   $0x0
  8001b5:	ff 75 10             	pushl  0x10(%ebp)
  8001b8:	ff 75 0c             	pushl  0xc(%ebp)
  8001bb:	8b 4d 08             	mov    0x8(%ebp),%ecx
  8001be:	ba 01 00 00 00       	mov    $0x1,%edx
  8001c3:	b8 04 00 00 00       	mov    $0x4,%eax
  8001c8:	e8 dd fe ff ff       	call   8000aa <syscall>
}
  8001cd:	c9                   	leave  
  8001ce:	c3                   	ret    

008001cf <sys_page_map>:

int
sys_page_map(envid_t srcenv, void *srcva, envid_t dstenv, void *dstva, int perm)
{
  8001cf:	55                   	push   %ebp
  8001d0:	89 e5                	mov    %esp,%ebp
  8001d2:	83 ec 08             	sub    $0x8,%esp
	return syscall(SYS_page_map, 1, srcenv, (uint32_t) srcva, dstenv, (uint32_t) dstva, perm);
  8001d5:	ff 75 18             	pushl  0x18(%ebp)
  8001d8:	ff 75 14             	pushl  0x14(%ebp)
  8001db:	ff 75 10             	pushl  0x10(%ebp)
  8001de:	ff 75 0c             	pushl  0xc(%ebp)
  8001e1:	8b 4d 08             	mov    0x8(%ebp),%ecx
  8001e4:	ba 01 00 00 00       	mov    $0x1,%edx
  8001e9:	b8 05 00 00 00       	mov    $0x5,%eax
  8001ee:	e8 b7 fe ff ff       	call   8000aa <syscall>
}
  8001f3:	c9                   	leave  
  8001f4:	c3                   	ret    

008001f5 <sys_page_unmap>:

int
sys_page_unmap(envid_t envid, void *va)
{
  8001f5:	55                   	push   %ebp
  8001f6:	89 e5                	mov    %esp,%ebp
  8001f8:	83 ec 08             	sub    $0x8,%esp
	return syscall(SYS_page_unmap, 1, envid, (uint32_t) va, 0, 0, 0);
  8001fb:	6a 00                	push   $0x0
  8001fd:	6a 00                	push   $0x0
  8001ff:	6a 00                	push   $0x0
  800201:	ff 75 0c             	pushl  0xc(%ebp)
  800204:	8b 4d 08             	mov    0x8(%ebp),%ecx
  800207:	ba 01 00 00 00       	mov    $0x1,%edx
  80020c:	b8 06 00 00 00       	mov    $0x6,%eax
  800211:	e8 94 fe ff ff       	call   8000aa <syscall>
}
  800216:	c9                   	leave  
  800217:	c3                   	ret    

00800218 <sys_env_set_status>:

// sys_exofork is inlined in lib.h

int
sys_env_set_status(envid_t envid, int status)
{
  800218:	55                   	push   %ebp
  800219:	89 e5                	mov    %esp,%ebp
  80021b:	83 ec 08             	sub    $0x8,%esp
	return syscall(SYS_env_set_status, 1, envid, status, 0, 0, 0);
  80021e:	6a 00                	push   $0x0
  800220:	6a 00                	push   $0x0
  800222:	6a 00                	push   $0x0
  800224:	ff 75 0c             	pushl  0xc(%ebp)
  800227:	8b 4d 08             	mov    0x8(%ebp),%ecx
  80022a:	ba 01 00 00 00       	mov    $0x1,%edx
  80022f:	b8 08 00 00 00       	mov    $0x8,%eax
  800234:	e8 71 fe ff ff       	call   8000aa <syscall>
}
  800239:	c9                   	leave  
  80023a:	c3                   	ret    

0080023b <sys_env_set_pgfault_upcall>:

int
sys_env_set_pgfault_upcall(envid_t envid, void *upcall)
{
  80023b:	55                   	push   %ebp
  80023c:	89 e5                	mov    %esp,%ebp
  80023e:	83 ec 08             	sub    $0x8,%esp
	return syscall(SYS_env_set_pgfault_upcall, 1, envid, (uint32_t) upcall, 0, 0, 0);
  800241:	6a 00                	push   $0x0
  800243:	6a 00                	push   $0x0
  800245:	6a 00                	push   $0x0
  800247:	ff 75 0c             	pushl  0xc(%ebp)
  80024a:	8b 4d 08             	mov    0x8(%ebp),%ecx
  80024d:	ba 01 00 00 00       	mov    $0x1,%edx
  800252:	b8 09 00 00 00       	mov    $0x9,%eax
  800257:	e8 4e fe ff ff       	call   8000aa <syscall>
}
  80025c:	c9                   	leave  
  80025d:	c3                   	ret    

0080025e <sys_ipc_try_send>:

int
sys_ipc_try_send(envid_t envid, uint32_t value, void *srcva, int perm)
{
  80025e:	55                   	push   %ebp
  80025f:	89 e5                	mov    %esp,%ebp
  800261:	83 ec 08             	sub    $0x8,%esp
	return syscall(SYS_ipc_try_send, 0, envid, value, (uint32_t) srcva, perm, 0);
  800264:	6a 00                	push   $0x0
  800266:	ff 75 14             	pushl  0x14(%ebp)
  800269:	ff 75 10             	pushl  0x10(%ebp)
  80026c:	ff 75 0c             	pushl  0xc(%ebp)
  80026f:	8b 4d 08             	mov    0x8(%ebp),%ecx
  800272:	ba 00 00 00 00       	mov    $0x0,%edx
  800277:	b8 0b 00 00 00       	mov    $0xb,%eax
  80027c:	e8 29 fe ff ff       	call   8000aa <syscall>
}
  800281:	c9                   	leave  
  800282:	c3                   	ret    

00800283 <sys_ipc_recv>:

int
sys_ipc_recv(void *dstva)
{
  800283:	55                   	push   %ebp
  800284:	89 e5                	mov    %esp,%ebp
  800286:	83 ec 08             	sub    $0x8,%esp
	return syscall(SYS_ipc_recv, 1, (uint32_t)dstva, 0, 0, 0, 0);
  800289:	6a 00                	push   $0x0
  80028b:	6a 00                	push   $0x0
  80028d:	6a 00                	push   $0x0
  80028f:	6a 00                	push   $0x0
  800291:	8b 4d 08             	mov    0x8(%ebp),%ecx
  800294:	ba 01 00 00 00       	mov    $0x1,%edx
  800299:	b8 0c 00 00 00       	mov    $0xc,%eax
  80029e:	e8 07 fe ff ff       	call   8000aa <syscall>
}
  8002a3:	c9                   	leave  
  8002a4:	c3                   	ret    

008002a5 <_panic>:
 * It prints "panic: <message>", then causes a breakpoint exception,
 * which causes JOS to enter the JOS kernel monitor.
 */
void
_panic(const char *file, int line, const char *fmt, ...)
{
  8002a5:	55                   	push   %ebp
  8002a6:	89 e5                	mov    %esp,%ebp
  8002a8:	56                   	push   %esi
  8002a9:	53                   	push   %ebx
	va_list ap;

	va_start(ap, fmt);
  8002aa:	8d 5d 14             	lea    0x14(%ebp),%ebx

	// Print the panic message
	cprintf("[%08x] user panic in %s at %s:%d: ",
  8002ad:	8b 35 04 20 80 00    	mov    0x802004,%esi
  8002b3:	e8 a8 fe ff ff       	call   800160 <sys_getenvid>
  8002b8:	83 ec 0c             	sub    $0xc,%esp
  8002bb:	ff 75 0c             	pushl  0xc(%ebp)
  8002be:	ff 75 08             	pushl  0x8(%ebp)
  8002c1:	56                   	push   %esi
  8002c2:	50                   	push   %eax
  8002c3:	68 24 0f 80 00       	push   $0x800f24
  8002c8:	e8 b1 00 00 00       	call   80037e <cprintf>
		sys_getenvid(), binaryname, file, line);
	vcprintf(fmt, ap);
  8002cd:	83 c4 18             	add    $0x18,%esp
  8002d0:	53                   	push   %ebx
  8002d1:	ff 75 10             	pushl  0x10(%ebp)
  8002d4:	e8 54 00 00 00       	call   80032d <vcprintf>
	cprintf("\n");
  8002d9:	c7 04 24 ec 0e 80 00 	movl   $0x800eec,(%esp)
  8002e0:	e8 99 00 00 00       	call   80037e <cprintf>
  8002e5:	83 c4 10             	add    $0x10,%esp

	// Cause a breakpoint exception
	while (1)
		asm volatile("int3");
  8002e8:	cc                   	int3   
  8002e9:	eb fd                	jmp    8002e8 <_panic+0x43>

008002eb <putch>:
};


static void
putch(int ch, struct printbuf *b)
{
  8002eb:	55                   	push   %ebp
  8002ec:	89 e5                	mov    %esp,%ebp
  8002ee:	53                   	push   %ebx
  8002ef:	83 ec 04             	sub    $0x4,%esp
  8002f2:	8b 5d 0c             	mov    0xc(%ebp),%ebx
	b->buf[b->idx++] = ch;
  8002f5:	8b 13                	mov    (%ebx),%edx
  8002f7:	8d 42 01             	lea    0x1(%edx),%eax
  8002fa:	89 03                	mov    %eax,(%ebx)
  8002fc:	8b 4d 08             	mov    0x8(%ebp),%ecx
  8002ff:	88 4c 13 08          	mov    %cl,0x8(%ebx,%edx,1)
	if (b->idx == 256-1) {
  800303:	3d ff 00 00 00       	cmp    $0xff,%eax
  800308:	75 1a                	jne    800324 <putch+0x39>
		sys_cputs(b->buf, b->idx);
  80030a:	83 ec 08             	sub    $0x8,%esp
  80030d:	68 ff 00 00 00       	push   $0xff
  800312:	8d 43 08             	lea    0x8(%ebx),%eax
  800315:	50                   	push   %eax
  800316:	e8 d9 fd ff ff       	call   8000f4 <sys_cputs>
		b->idx = 0;
  80031b:	c7 03 00 00 00 00    	movl   $0x0,(%ebx)
  800321:	83 c4 10             	add    $0x10,%esp
	}
	b->cnt++;
  800324:	83 43 04 01          	addl   $0x1,0x4(%ebx)
}
  800328:	8b 5d fc             	mov    -0x4(%ebp),%ebx
  80032b:	c9                   	leave  
  80032c:	c3                   	ret    

0080032d <vcprintf>:

int
vcprintf(const char *fmt, va_list ap)
{
  80032d:	55                   	push   %ebp
  80032e:	89 e5                	mov    %esp,%ebp
  800330:	81 ec 18 01 00 00    	sub    $0x118,%esp
	struct printbuf b;

	b.idx = 0;
  800336:	c7 85 f0 fe ff ff 00 	movl   $0x0,-0x110(%ebp)
  80033d:	00 00 00 
	b.cnt = 0;
  800340:	c7 85 f4 fe ff ff 00 	movl   $0x0,-0x10c(%ebp)
  800347:	00 00 00 
	vprintfmt((void*)putch, &b, fmt, ap);
  80034a:	ff 75 0c             	pushl  0xc(%ebp)
  80034d:	ff 75 08             	pushl  0x8(%ebp)
  800350:	8d 85 f0 fe ff ff    	lea    -0x110(%ebp),%eax
  800356:	50                   	push   %eax
  800357:	68 eb 02 80 00       	push   $0x8002eb
  80035c:	e8 86 01 00 00       	call   8004e7 <vprintfmt>
	sys_cputs(b.buf, b.idx);
  800361:	83 c4 08             	add    $0x8,%esp
  800364:	ff b5 f0 fe ff ff    	pushl  -0x110(%ebp)
  80036a:	8d 85 f8 fe ff ff    	lea    -0x108(%ebp),%eax
  800370:	50                   	push   %eax
  800371:	e8 7e fd ff ff       	call   8000f4 <sys_cputs>

	return b.cnt;
}
  800376:	8b 85 f4 fe ff ff    	mov    -0x10c(%ebp),%eax
  80037c:	c9                   	leave  
  80037d:	c3                   	ret    

0080037e <cprintf>:

int
cprintf(const char *fmt, ...)
{
  80037e:	55                   	push   %ebp
  80037f:	89 e5                	mov    %esp,%ebp
  800381:	83 ec 10             	sub    $0x10,%esp
	va_list ap;
	int cnt;

	va_start(ap, fmt);
  800384:	8d 45 0c             	lea    0xc(%ebp),%eax
	cnt = vcprintf(fmt, ap);
  800387:	50                   	push   %eax
  800388:	ff 75 08             	pushl  0x8(%ebp)
  80038b:	e8 9d ff ff ff       	call   80032d <vcprintf>
	va_end(ap);

	return cnt;
}
  800390:	c9                   	leave  
  800391:	c3                   	ret    

00800392 <printnum>:
 * using specified putch function and associated pointer putdat.
 */
static void
printnum(void (*putch)(int, void*), void *putdat,
	 unsigned long long num, unsigned base, int width, int padc)
{
  800392:	55                   	push   %ebp
  800393:	89 e5                	mov    %esp,%ebp
  800395:	57                   	push   %edi
  800396:	56                   	push   %esi
  800397:	53                   	push   %ebx
  800398:	83 ec 1c             	sub    $0x1c,%esp
  80039b:	89 c7                	mov    %eax,%edi
  80039d:	89 d6                	mov    %edx,%esi
  80039f:	8b 45 08             	mov    0x8(%ebp),%eax
  8003a2:	8b 55 0c             	mov    0xc(%ebp),%edx
  8003a5:	89 45 d8             	mov    %eax,-0x28(%ebp)
  8003a8:	89 55 dc             	mov    %edx,-0x24(%ebp)
	// first recursively print all preceding (more significant) digits
	if (num >= base) {
  8003ab:	8b 4d 10             	mov    0x10(%ebp),%ecx
  8003ae:	bb 00 00 00 00       	mov    $0x0,%ebx
  8003b3:	89 4d e0             	mov    %ecx,-0x20(%ebp)
  8003b6:	89 5d e4             	mov    %ebx,-0x1c(%ebp)
  8003b9:	39 d3                	cmp    %edx,%ebx
  8003bb:	72 05                	jb     8003c2 <printnum+0x30>
  8003bd:	39 45 10             	cmp    %eax,0x10(%ebp)
  8003c0:	77 45                	ja     800407 <printnum+0x75>
		printnum(putch, putdat, num / base, base, width - 1, padc);
  8003c2:	83 ec 0c             	sub    $0xc,%esp
  8003c5:	ff 75 18             	pushl  0x18(%ebp)
  8003c8:	8b 45 14             	mov    0x14(%ebp),%eax
  8003cb:	8d 58 ff             	lea    -0x1(%eax),%ebx
  8003ce:	53                   	push   %ebx
  8003cf:	ff 75 10             	pushl  0x10(%ebp)
  8003d2:	83 ec 08             	sub    $0x8,%esp
  8003d5:	ff 75 e4             	pushl  -0x1c(%ebp)
  8003d8:	ff 75 e0             	pushl  -0x20(%ebp)
  8003db:	ff 75 dc             	pushl  -0x24(%ebp)
  8003de:	ff 75 d8             	pushl  -0x28(%ebp)
  8003e1:	e8 5a 08 00 00       	call   800c40 <__udivdi3>
  8003e6:	83 c4 18             	add    $0x18,%esp
  8003e9:	52                   	push   %edx
  8003ea:	50                   	push   %eax
  8003eb:	89 f2                	mov    %esi,%edx
  8003ed:	89 f8                	mov    %edi,%eax
  8003ef:	e8 9e ff ff ff       	call   800392 <printnum>
  8003f4:	83 c4 20             	add    $0x20,%esp
  8003f7:	eb 18                	jmp    800411 <printnum+0x7f>
	} else {
		// print any needed pad characters before first digit
		while (--width > 0)
			putch(padc, putdat);
  8003f9:	83 ec 08             	sub    $0x8,%esp
  8003fc:	56                   	push   %esi
  8003fd:	ff 75 18             	pushl  0x18(%ebp)
  800400:	ff d7                	call   *%edi
  800402:	83 c4 10             	add    $0x10,%esp
  800405:	eb 03                	jmp    80040a <printnum+0x78>
  800407:	8b 5d 14             	mov    0x14(%ebp),%ebx
	// first recursively print all preceding (more significant) digits
	if (num >= base) {
		printnum(putch, putdat, num / base, base, width - 1, padc);
	} else {
		// print any needed pad characters before first digit
		while (--width > 0)
  80040a:	83 eb 01             	sub    $0x1,%ebx
  80040d:	85 db                	test   %ebx,%ebx
  80040f:	7f e8                	jg     8003f9 <printnum+0x67>
			putch(padc, putdat);
	}

	// then print this (the least significant) digit
	putch("0123456789abcdef"[num % base], putdat);
  800411:	83 ec 08             	sub    $0x8,%esp
  800414:	56                   	push   %esi
  800415:	83 ec 04             	sub    $0x4,%esp
  800418:	ff 75 e4             	pushl  -0x1c(%ebp)
  80041b:	ff 75 e0             	pushl  -0x20(%ebp)
  80041e:	ff 75 dc             	pushl  -0x24(%ebp)
  800421:	ff 75 d8             	pushl  -0x28(%ebp)
  800424:	e8 47 09 00 00       	call   800d70 <__umoddi3>
  800429:	83 c4 14             	add    $0x14,%esp
  80042c:	0f be 80 48 0f 80 00 	movsbl 0x800f48(%eax),%eax
  800433:	50                   	push   %eax
  800434:	ff d7                	call   *%edi
}
  800436:	83 c4 10             	add    $0x10,%esp
  800439:	8d 65 f4             	lea    -0xc(%ebp),%esp
  80043c:	5b                   	pop    %ebx
  80043d:	5e                   	pop    %esi
  80043e:	5f                   	pop    %edi
  80043f:	5d                   	pop    %ebp
  800440:	c3                   	ret    

00800441 <getuint>:

// Get an unsigned int of various possible sizes from a varargs list,
// depending on the lflag parameter.
static unsigned long long
getuint(va_list *ap, int lflag)
{
  800441:	55                   	push   %ebp
  800442:	89 e5                	mov    %esp,%ebp
	if (lflag >= 2)
  800444:	83 fa 01             	cmp    $0x1,%edx
  800447:	7e 0e                	jle    800457 <getuint+0x16>
		return va_arg(*ap, unsigned long long);
  800449:	8b 10                	mov    (%eax),%edx
  80044b:	8d 4a 08             	lea    0x8(%edx),%ecx
  80044e:	89 08                	mov    %ecx,(%eax)
  800450:	8b 02                	mov    (%edx),%eax
  800452:	8b 52 04             	mov    0x4(%edx),%edx
  800455:	eb 22                	jmp    800479 <getuint+0x38>
	else if (lflag)
  800457:	85 d2                	test   %edx,%edx
  800459:	74 10                	je     80046b <getuint+0x2a>
		return va_arg(*ap, unsigned long);
  80045b:	8b 10                	mov    (%eax),%edx
  80045d:	8d 4a 04             	lea    0x4(%edx),%ecx
  800460:	89 08                	mov    %ecx,(%eax)
  800462:	8b 02                	mov    (%edx),%eax
  800464:	ba 00 00 00 00       	mov    $0x0,%edx
  800469:	eb 0e                	jmp    800479 <getuint+0x38>
	else
		return va_arg(*ap, unsigned int);
  80046b:	8b 10                	mov    (%eax),%edx
  80046d:	8d 4a 04             	lea    0x4(%edx),%ecx
  800470:	89 08                	mov    %ecx,(%eax)
  800472:	8b 02                	mov    (%edx),%eax
  800474:	ba 00 00 00 00       	mov    $0x0,%edx
}
  800479:	5d                   	pop    %ebp
  80047a:	c3                   	ret    

0080047b <getint>:

// Same as getuint but signed - can't use getuint
// because of sign extension
static long long
getint(va_list *ap, int lflag)
{
  80047b:	55                   	push   %ebp
  80047c:	89 e5                	mov    %esp,%ebp
	if (lflag >= 2)
  80047e:	83 fa 01             	cmp    $0x1,%edx
  800481:	7e 0e                	jle    800491 <getint+0x16>
		return va_arg(*ap, long long);
  800483:	8b 10                	mov    (%eax),%edx
  800485:	8d 4a 08             	lea    0x8(%edx),%ecx
  800488:	89 08                	mov    %ecx,(%eax)
  80048a:	8b 02                	mov    (%edx),%eax
  80048c:	8b 52 04             	mov    0x4(%edx),%edx
  80048f:	eb 1a                	jmp    8004ab <getint+0x30>
	else if (lflag)
  800491:	85 d2                	test   %edx,%edx
  800493:	74 0c                	je     8004a1 <getint+0x26>
		return va_arg(*ap, long);
  800495:	8b 10                	mov    (%eax),%edx
  800497:	8d 4a 04             	lea    0x4(%edx),%ecx
  80049a:	89 08                	mov    %ecx,(%eax)
  80049c:	8b 02                	mov    (%edx),%eax
  80049e:	99                   	cltd   
  80049f:	eb 0a                	jmp    8004ab <getint+0x30>
	else
		return va_arg(*ap, int);
  8004a1:	8b 10                	mov    (%eax),%edx
  8004a3:	8d 4a 04             	lea    0x4(%edx),%ecx
  8004a6:	89 08                	mov    %ecx,(%eax)
  8004a8:	8b 02                	mov    (%edx),%eax
  8004aa:	99                   	cltd   
}
  8004ab:	5d                   	pop    %ebp
  8004ac:	c3                   	ret    

008004ad <sprintputch>:
	int cnt;
};

static void
sprintputch(int ch, struct sprintbuf *b)
{
  8004ad:	55                   	push   %ebp
  8004ae:	89 e5                	mov    %esp,%ebp
  8004b0:	8b 45 0c             	mov    0xc(%ebp),%eax
	b->cnt++;
  8004b3:	83 40 08 01          	addl   $0x1,0x8(%eax)
	if (b->buf < b->ebuf)
  8004b7:	8b 10                	mov    (%eax),%edx
  8004b9:	3b 50 04             	cmp    0x4(%eax),%edx
  8004bc:	73 0a                	jae    8004c8 <sprintputch+0x1b>
		*b->buf++ = ch;
  8004be:	8d 4a 01             	lea    0x1(%edx),%ecx
  8004c1:	89 08                	mov    %ecx,(%eax)
  8004c3:	8b 45 08             	mov    0x8(%ebp),%eax
  8004c6:	88 02                	mov    %al,(%edx)
}
  8004c8:	5d                   	pop    %ebp
  8004c9:	c3                   	ret    

008004ca <printfmt>:
	}
}

void
printfmt(void (*putch)(int, void*), void *putdat, const char *fmt, ...)
{
  8004ca:	55                   	push   %ebp
  8004cb:	89 e5                	mov    %esp,%ebp
  8004cd:	83 ec 08             	sub    $0x8,%esp
	va_list ap;

	va_start(ap, fmt);
  8004d0:	8d 45 14             	lea    0x14(%ebp),%eax
	vprintfmt(putch, putdat, fmt, ap);
  8004d3:	50                   	push   %eax
  8004d4:	ff 75 10             	pushl  0x10(%ebp)
  8004d7:	ff 75 0c             	pushl  0xc(%ebp)
  8004da:	ff 75 08             	pushl  0x8(%ebp)
  8004dd:	e8 05 00 00 00       	call   8004e7 <vprintfmt>
	va_end(ap);
}
  8004e2:	83 c4 10             	add    $0x10,%esp
  8004e5:	c9                   	leave  
  8004e6:	c3                   	ret    

008004e7 <vprintfmt>:
// Main function to format and print a string.
void printfmt(void (*putch)(int, void*), void *putdat, const char *fmt, ...);

void
vprintfmt(void (*putch)(int, void*), void *putdat, const char *fmt, va_list ap)
{
  8004e7:	55                   	push   %ebp
  8004e8:	89 e5                	mov    %esp,%ebp
  8004ea:	57                   	push   %edi
  8004eb:	56                   	push   %esi
  8004ec:	53                   	push   %ebx
  8004ed:	83 ec 2c             	sub    $0x2c,%esp
  8004f0:	8b 75 08             	mov    0x8(%ebp),%esi
  8004f3:	8b 5d 0c             	mov    0xc(%ebp),%ebx
  8004f6:	8b 7d 10             	mov    0x10(%ebp),%edi
  8004f9:	eb 12                	jmp    80050d <vprintfmt+0x26>
	int base, lflag, width, precision, altflag;
	char padc;

	while (1) {
		while ((ch = *(unsigned char *) fmt++) != '%') {
			if (ch == '\0')
  8004fb:	85 c0                	test   %eax,%eax
  8004fd:	0f 84 44 03 00 00    	je     800847 <vprintfmt+0x360>
				return;
			putch(ch, putdat);
  800503:	83 ec 08             	sub    $0x8,%esp
  800506:	53                   	push   %ebx
  800507:	50                   	push   %eax
  800508:	ff d6                	call   *%esi
  80050a:	83 c4 10             	add    $0x10,%esp
	unsigned long long num;
	int base, lflag, width, precision, altflag;
	char padc;

	while (1) {
		while ((ch = *(unsigned char *) fmt++) != '%') {
  80050d:	83 c7 01             	add    $0x1,%edi
  800510:	0f b6 47 ff          	movzbl -0x1(%edi),%eax
  800514:	83 f8 25             	cmp    $0x25,%eax
  800517:	75 e2                	jne    8004fb <vprintfmt+0x14>
  800519:	c6 45 d4 20          	movb   $0x20,-0x2c(%ebp)
  80051d:	c7 45 d8 00 00 00 00 	movl   $0x0,-0x28(%ebp)
  800524:	c7 45 d0 ff ff ff ff 	movl   $0xffffffff,-0x30(%ebp)
  80052b:	c7 45 e0 ff ff ff ff 	movl   $0xffffffff,-0x20(%ebp)
  800532:	ba 00 00 00 00       	mov    $0x0,%edx
  800537:	eb 07                	jmp    800540 <vprintfmt+0x59>
		width = -1;
		precision = -1;
		lflag = 0;
		altflag = 0;
	reswitch:
		switch (ch = *(unsigned char *) fmt++) {
  800539:	8b 7d e4             	mov    -0x1c(%ebp),%edi

		// flag to pad on the right
		case '-':
			padc = '-';
  80053c:	c6 45 d4 2d          	movb   $0x2d,-0x2c(%ebp)
		width = -1;
		precision = -1;
		lflag = 0;
		altflag = 0;
	reswitch:
		switch (ch = *(unsigned char *) fmt++) {
  800540:	8d 47 01             	lea    0x1(%edi),%eax
  800543:	89 45 e4             	mov    %eax,-0x1c(%ebp)
  800546:	0f b6 07             	movzbl (%edi),%eax
  800549:	0f b6 c8             	movzbl %al,%ecx
  80054c:	83 e8 23             	sub    $0x23,%eax
  80054f:	3c 55                	cmp    $0x55,%al
  800551:	0f 87 d5 02 00 00    	ja     80082c <vprintfmt+0x345>
  800557:	0f b6 c0             	movzbl %al,%eax
  80055a:	ff 24 85 00 10 80 00 	jmp    *0x801000(,%eax,4)
  800561:	8b 7d e4             	mov    -0x1c(%ebp),%edi
			padc = '-';
			goto reswitch;

		// flag to pad with 0's instead of spaces
		case '0':
			padc = '0';
  800564:	c6 45 d4 30          	movb   $0x30,-0x2c(%ebp)
  800568:	eb d6                	jmp    800540 <vprintfmt+0x59>
		width = -1;
		precision = -1;
		lflag = 0;
		altflag = 0;
	reswitch:
		switch (ch = *(unsigned char *) fmt++) {
  80056a:	8b 7d e4             	mov    -0x1c(%ebp),%edi
  80056d:	b8 00 00 00 00       	mov    $0x0,%eax
  800572:	89 55 e4             	mov    %edx,-0x1c(%ebp)
		case '6':
		case '7':
		case '8':
		case '9':
			for (precision = 0; ; ++fmt) {
				precision = precision * 10 + ch - '0';
  800575:	8d 04 80             	lea    (%eax,%eax,4),%eax
  800578:	8d 44 41 d0          	lea    -0x30(%ecx,%eax,2),%eax
				ch = *fmt;
  80057c:	0f be 0f             	movsbl (%edi),%ecx
				if (ch < '0' || ch > '9')
  80057f:	8d 51 d0             	lea    -0x30(%ecx),%edx
  800582:	83 fa 09             	cmp    $0x9,%edx
  800585:	77 39                	ja     8005c0 <vprintfmt+0xd9>
		case '5':
		case '6':
		case '7':
		case '8':
		case '9':
			for (precision = 0; ; ++fmt) {
  800587:	83 c7 01             	add    $0x1,%edi
				precision = precision * 10 + ch - '0';
				ch = *fmt;
				if (ch < '0' || ch > '9')
					break;
			}
  80058a:	eb e9                	jmp    800575 <vprintfmt+0x8e>
			goto process_precision;

		case '*':
			precision = va_arg(ap, int);
  80058c:	8b 45 14             	mov    0x14(%ebp),%eax
  80058f:	8d 48 04             	lea    0x4(%eax),%ecx
  800592:	89 4d 14             	mov    %ecx,0x14(%ebp)
  800595:	8b 00                	mov    (%eax),%eax
  800597:	89 45 d0             	mov    %eax,-0x30(%ebp)
		width = -1;
		precision = -1;
		lflag = 0;
		altflag = 0;
	reswitch:
		switch (ch = *(unsigned char *) fmt++) {
  80059a:	8b 7d e4             	mov    -0x1c(%ebp),%edi
			}
			goto process_precision;

		case '*':
			precision = va_arg(ap, int);
			goto process_precision;
  80059d:	eb 27                	jmp    8005c6 <vprintfmt+0xdf>
  80059f:	8b 45 e0             	mov    -0x20(%ebp),%eax
  8005a2:	85 c0                	test   %eax,%eax
  8005a4:	b9 00 00 00 00       	mov    $0x0,%ecx
  8005a9:	0f 49 c8             	cmovns %eax,%ecx
  8005ac:	89 4d e0             	mov    %ecx,-0x20(%ebp)
		width = -1;
		precision = -1;
		lflag = 0;
		altflag = 0;
	reswitch:
		switch (ch = *(unsigned char *) fmt++) {
  8005af:	8b 7d e4             	mov    -0x1c(%ebp),%edi
  8005b2:	eb 8c                	jmp    800540 <vprintfmt+0x59>
  8005b4:	8b 7d e4             	mov    -0x1c(%ebp),%edi
			if (width < 0)
				width = 0;
			goto reswitch;

		case '#':
			altflag = 1;
  8005b7:	c7 45 d8 01 00 00 00 	movl   $0x1,-0x28(%ebp)
			goto reswitch;
  8005be:	eb 80                	jmp    800540 <vprintfmt+0x59>
  8005c0:	8b 55 e4             	mov    -0x1c(%ebp),%edx
  8005c3:	89 45 d0             	mov    %eax,-0x30(%ebp)

		process_precision:
			if (width < 0)
  8005c6:	83 7d e0 00          	cmpl   $0x0,-0x20(%ebp)
  8005ca:	0f 89 70 ff ff ff    	jns    800540 <vprintfmt+0x59>
				width = precision, precision = -1;
  8005d0:	8b 45 d0             	mov    -0x30(%ebp),%eax
  8005d3:	89 45 e0             	mov    %eax,-0x20(%ebp)
  8005d6:	c7 45 d0 ff ff ff ff 	movl   $0xffffffff,-0x30(%ebp)
  8005dd:	e9 5e ff ff ff       	jmp    800540 <vprintfmt+0x59>
			goto reswitch;

		// long flag (doubled for long long)
		case 'l':
			lflag++;
  8005e2:	83 c2 01             	add    $0x1,%edx
		width = -1;
		precision = -1;
		lflag = 0;
		altflag = 0;
	reswitch:
		switch (ch = *(unsigned char *) fmt++) {
  8005e5:	8b 7d e4             	mov    -0x1c(%ebp),%edi
			goto reswitch;

		// long flag (doubled for long long)
		case 'l':
			lflag++;
			goto reswitch;
  8005e8:	e9 53 ff ff ff       	jmp    800540 <vprintfmt+0x59>

		// character
		case 'c':
			putch(va_arg(ap, int), putdat);
  8005ed:	8b 45 14             	mov    0x14(%ebp),%eax
  8005f0:	8d 50 04             	lea    0x4(%eax),%edx
  8005f3:	89 55 14             	mov    %edx,0x14(%ebp)
  8005f6:	83 ec 08             	sub    $0x8,%esp
  8005f9:	53                   	push   %ebx
  8005fa:	ff 30                	pushl  (%eax)
  8005fc:	ff d6                	call   *%esi
			break;
  8005fe:	83 c4 10             	add    $0x10,%esp
		width = -1;
		precision = -1;
		lflag = 0;
		altflag = 0;
	reswitch:
		switch (ch = *(unsigned char *) fmt++) {
  800601:	8b 7d e4             	mov    -0x1c(%ebp),%edi
			goto reswitch;

		// character
		case 'c':
			putch(va_arg(ap, int), putdat);
			break;
  800604:	e9 04 ff ff ff       	jmp    80050d <vprintfmt+0x26>

		// error message
		case 'e':
			err = va_arg(ap, int);
  800609:	8b 45 14             	mov    0x14(%ebp),%eax
  80060c:	8d 50 04             	lea    0x4(%eax),%edx
  80060f:	89 55 14             	mov    %edx,0x14(%ebp)
  800612:	8b 00                	mov    (%eax),%eax
  800614:	99                   	cltd   
  800615:	31 d0                	xor    %edx,%eax
  800617:	29 d0                	sub    %edx,%eax
			if (err < 0)
				err = -err;
			if (err >= MAXERROR || (p = error_string[err]) == NULL)
  800619:	83 f8 08             	cmp    $0x8,%eax
  80061c:	7f 0b                	jg     800629 <vprintfmt+0x142>
  80061e:	8b 14 85 60 11 80 00 	mov    0x801160(,%eax,4),%edx
  800625:	85 d2                	test   %edx,%edx
  800627:	75 18                	jne    800641 <vprintfmt+0x15a>
				printfmt(putch, putdat, "error %d", err);
  800629:	50                   	push   %eax
  80062a:	68 60 0f 80 00       	push   $0x800f60
  80062f:	53                   	push   %ebx
  800630:	56                   	push   %esi
  800631:	e8 94 fe ff ff       	call   8004ca <printfmt>
  800636:	83 c4 10             	add    $0x10,%esp
		width = -1;
		precision = -1;
		lflag = 0;
		altflag = 0;
	reswitch:
		switch (ch = *(unsigned char *) fmt++) {
  800639:	8b 7d e4             	mov    -0x1c(%ebp),%edi
		case 'e':
			err = va_arg(ap, int);
			if (err < 0)
				err = -err;
			if (err >= MAXERROR || (p = error_string[err]) == NULL)
				printfmt(putch, putdat, "error %d", err);
  80063c:	e9 cc fe ff ff       	jmp    80050d <vprintfmt+0x26>
			else
				printfmt(putch, putdat, "%s", p);
  800641:	52                   	push   %edx
  800642:	68 69 0f 80 00       	push   $0x800f69
  800647:	53                   	push   %ebx
  800648:	56                   	push   %esi
  800649:	e8 7c fe ff ff       	call   8004ca <printfmt>
  80064e:	83 c4 10             	add    $0x10,%esp
		width = -1;
		precision = -1;
		lflag = 0;
		altflag = 0;
	reswitch:
		switch (ch = *(unsigned char *) fmt++) {
  800651:	8b 7d e4             	mov    -0x1c(%ebp),%edi
  800654:	e9 b4 fe ff ff       	jmp    80050d <vprintfmt+0x26>
				printfmt(putch, putdat, "%s", p);
			break;

		// string
		case 's':
			if ((p = va_arg(ap, char *)) == NULL)
  800659:	8b 45 14             	mov    0x14(%ebp),%eax
  80065c:	8d 50 04             	lea    0x4(%eax),%edx
  80065f:	89 55 14             	mov    %edx,0x14(%ebp)
  800662:	8b 38                	mov    (%eax),%edi
				p = "(null)";
  800664:	85 ff                	test   %edi,%edi
  800666:	b8 59 0f 80 00       	mov    $0x800f59,%eax
  80066b:	0f 44 f8             	cmove  %eax,%edi
			if (width > 0 && padc != '-')
  80066e:	83 7d e0 00          	cmpl   $0x0,-0x20(%ebp)
  800672:	0f 8e 94 00 00 00    	jle    80070c <vprintfmt+0x225>
  800678:	80 7d d4 2d          	cmpb   $0x2d,-0x2c(%ebp)
  80067c:	0f 84 98 00 00 00    	je     80071a <vprintfmt+0x233>
				for (width -= strnlen(p, precision); width > 0; width--)
  800682:	83 ec 08             	sub    $0x8,%esp
  800685:	ff 75 d0             	pushl  -0x30(%ebp)
  800688:	57                   	push   %edi
  800689:	e8 41 02 00 00       	call   8008cf <strnlen>
  80068e:	8b 4d e0             	mov    -0x20(%ebp),%ecx
  800691:	29 c1                	sub    %eax,%ecx
  800693:	89 4d cc             	mov    %ecx,-0x34(%ebp)
  800696:	83 c4 10             	add    $0x10,%esp
					putch(padc, putdat);
  800699:	0f be 45 d4          	movsbl -0x2c(%ebp),%eax
  80069d:	89 45 e0             	mov    %eax,-0x20(%ebp)
  8006a0:	89 7d d4             	mov    %edi,-0x2c(%ebp)
  8006a3:	89 cf                	mov    %ecx,%edi
		// string
		case 's':
			if ((p = va_arg(ap, char *)) == NULL)
				p = "(null)";
			if (width > 0 && padc != '-')
				for (width -= strnlen(p, precision); width > 0; width--)
  8006a5:	eb 0f                	jmp    8006b6 <vprintfmt+0x1cf>
					putch(padc, putdat);
  8006a7:	83 ec 08             	sub    $0x8,%esp
  8006aa:	53                   	push   %ebx
  8006ab:	ff 75 e0             	pushl  -0x20(%ebp)
  8006ae:	ff d6                	call   *%esi
		// string
		case 's':
			if ((p = va_arg(ap, char *)) == NULL)
				p = "(null)";
			if (width > 0 && padc != '-')
				for (width -= strnlen(p, precision); width > 0; width--)
  8006b0:	83 ef 01             	sub    $0x1,%edi
  8006b3:	83 c4 10             	add    $0x10,%esp
  8006b6:	85 ff                	test   %edi,%edi
  8006b8:	7f ed                	jg     8006a7 <vprintfmt+0x1c0>
  8006ba:	8b 7d d4             	mov    -0x2c(%ebp),%edi
  8006bd:	8b 4d cc             	mov    -0x34(%ebp),%ecx
  8006c0:	85 c9                	test   %ecx,%ecx
  8006c2:	b8 00 00 00 00       	mov    $0x0,%eax
  8006c7:	0f 49 c1             	cmovns %ecx,%eax
  8006ca:	29 c1                	sub    %eax,%ecx
  8006cc:	89 75 08             	mov    %esi,0x8(%ebp)
  8006cf:	8b 75 d0             	mov    -0x30(%ebp),%esi
  8006d2:	89 5d 0c             	mov    %ebx,0xc(%ebp)
  8006d5:	89 cb                	mov    %ecx,%ebx
  8006d7:	eb 4d                	jmp    800726 <vprintfmt+0x23f>
					putch(padc, putdat);
			for (; (ch = *p++) != '\0' && (precision < 0 || --precision >= 0); width--)
				if (altflag && (ch < ' ' || ch > '~'))
  8006d9:	83 7d d8 00          	cmpl   $0x0,-0x28(%ebp)
  8006dd:	74 1b                	je     8006fa <vprintfmt+0x213>
  8006df:	0f be c0             	movsbl %al,%eax
  8006e2:	83 e8 20             	sub    $0x20,%eax
  8006e5:	83 f8 5e             	cmp    $0x5e,%eax
  8006e8:	76 10                	jbe    8006fa <vprintfmt+0x213>
					putch('?', putdat);
  8006ea:	83 ec 08             	sub    $0x8,%esp
  8006ed:	ff 75 0c             	pushl  0xc(%ebp)
  8006f0:	6a 3f                	push   $0x3f
  8006f2:	ff 55 08             	call   *0x8(%ebp)
  8006f5:	83 c4 10             	add    $0x10,%esp
  8006f8:	eb 0d                	jmp    800707 <vprintfmt+0x220>
				else
					putch(ch, putdat);
  8006fa:	83 ec 08             	sub    $0x8,%esp
  8006fd:	ff 75 0c             	pushl  0xc(%ebp)
  800700:	52                   	push   %edx
  800701:	ff 55 08             	call   *0x8(%ebp)
  800704:	83 c4 10             	add    $0x10,%esp
			if ((p = va_arg(ap, char *)) == NULL)
				p = "(null)";
			if (width > 0 && padc != '-')
				for (width -= strnlen(p, precision); width > 0; width--)
					putch(padc, putdat);
			for (; (ch = *p++) != '\0' && (precision < 0 || --precision >= 0); width--)
  800707:	83 eb 01             	sub    $0x1,%ebx
  80070a:	eb 1a                	jmp    800726 <vprintfmt+0x23f>
  80070c:	89 75 08             	mov    %esi,0x8(%ebp)
  80070f:	8b 75 d0             	mov    -0x30(%ebp),%esi
  800712:	89 5d 0c             	mov    %ebx,0xc(%ebp)
  800715:	8b 5d e0             	mov    -0x20(%ebp),%ebx
  800718:	eb 0c                	jmp    800726 <vprintfmt+0x23f>
  80071a:	89 75 08             	mov    %esi,0x8(%ebp)
  80071d:	8b 75 d0             	mov    -0x30(%ebp),%esi
  800720:	89 5d 0c             	mov    %ebx,0xc(%ebp)
  800723:	8b 5d e0             	mov    -0x20(%ebp),%ebx
  800726:	83 c7 01             	add    $0x1,%edi
  800729:	0f b6 47 ff          	movzbl -0x1(%edi),%eax
  80072d:	0f be d0             	movsbl %al,%edx
  800730:	85 d2                	test   %edx,%edx
  800732:	74 23                	je     800757 <vprintfmt+0x270>
  800734:	85 f6                	test   %esi,%esi
  800736:	78 a1                	js     8006d9 <vprintfmt+0x1f2>
  800738:	83 ee 01             	sub    $0x1,%esi
  80073b:	79 9c                	jns    8006d9 <vprintfmt+0x1f2>
  80073d:	89 df                	mov    %ebx,%edi
  80073f:	8b 75 08             	mov    0x8(%ebp),%esi
  800742:	8b 5d 0c             	mov    0xc(%ebp),%ebx
  800745:	eb 18                	jmp    80075f <vprintfmt+0x278>
				if (altflag && (ch < ' ' || ch > '~'))
					putch('?', putdat);
				else
					putch(ch, putdat);
			for (; width > 0; width--)
				putch(' ', putdat);
  800747:	83 ec 08             	sub    $0x8,%esp
  80074a:	53                   	push   %ebx
  80074b:	6a 20                	push   $0x20
  80074d:	ff d6                	call   *%esi
			for (; (ch = *p++) != '\0' && (precision < 0 || --precision >= 0); width--)
				if (altflag && (ch < ' ' || ch > '~'))
					putch('?', putdat);
				else
					putch(ch, putdat);
			for (; width > 0; width--)
  80074f:	83 ef 01             	sub    $0x1,%edi
  800752:	83 c4 10             	add    $0x10,%esp
  800755:	eb 08                	jmp    80075f <vprintfmt+0x278>
  800757:	89 df                	mov    %ebx,%edi
  800759:	8b 75 08             	mov    0x8(%ebp),%esi
  80075c:	8b 5d 0c             	mov    0xc(%ebp),%ebx
  80075f:	85 ff                	test   %edi,%edi
  800761:	7f e4                	jg     800747 <vprintfmt+0x260>
		width = -1;
		precision = -1;
		lflag = 0;
		altflag = 0;
	reswitch:
		switch (ch = *(unsigned char *) fmt++) {
  800763:	8b 7d e4             	mov    -0x1c(%ebp),%edi
  800766:	e9 a2 fd ff ff       	jmp    80050d <vprintfmt+0x26>
				putch(' ', putdat);
			break;

		// (signed) decimal
		case 'd':
			num = getint(&ap, lflag);
  80076b:	8d 45 14             	lea    0x14(%ebp),%eax
  80076e:	e8 08 fd ff ff       	call   80047b <getint>
  800773:	89 45 d8             	mov    %eax,-0x28(%ebp)
  800776:	89 55 dc             	mov    %edx,-0x24(%ebp)
			if ((long long) num < 0) {
				putch('-', putdat);
				num = -(long long) num;
			}
			base = 10;
  800779:	b9 0a 00 00 00       	mov    $0xa,%ecx
			break;

		// (signed) decimal
		case 'd':
			num = getint(&ap, lflag);
			if ((long long) num < 0) {
  80077e:	83 7d dc 00          	cmpl   $0x0,-0x24(%ebp)
  800782:	79 74                	jns    8007f8 <vprintfmt+0x311>
				putch('-', putdat);
  800784:	83 ec 08             	sub    $0x8,%esp
  800787:	53                   	push   %ebx
  800788:	6a 2d                	push   $0x2d
  80078a:	ff d6                	call   *%esi
				num = -(long long) num;
  80078c:	8b 45 d8             	mov    -0x28(%ebp),%eax
  80078f:	8b 55 dc             	mov    -0x24(%ebp),%edx
  800792:	f7 d8                	neg    %eax
  800794:	83 d2 00             	adc    $0x0,%edx
  800797:	f7 da                	neg    %edx
  800799:	83 c4 10             	add    $0x10,%esp
			}
			base = 10;
  80079c:	b9 0a 00 00 00       	mov    $0xa,%ecx
  8007a1:	eb 55                	jmp    8007f8 <vprintfmt+0x311>
			goto number;

		// unsigned decimal
		case 'u':
			num = getuint(&ap, lflag);
  8007a3:	8d 45 14             	lea    0x14(%ebp),%eax
  8007a6:	e8 96 fc ff ff       	call   800441 <getuint>
			base = 10;
  8007ab:	b9 0a 00 00 00       	mov    $0xa,%ecx
			goto number;
  8007b0:	eb 46                	jmp    8007f8 <vprintfmt+0x311>

		// (unsigned) octal
		case 'o':
			num = getuint(&ap, lflag);
  8007b2:	8d 45 14             	lea    0x14(%ebp),%eax
  8007b5:	e8 87 fc ff ff       	call   800441 <getuint>
			base = 8;
  8007ba:	b9 08 00 00 00       	mov    $0x8,%ecx
			goto number;
  8007bf:	eb 37                	jmp    8007f8 <vprintfmt+0x311>

		// pointer
		case 'p':
			putch('0', putdat);
  8007c1:	83 ec 08             	sub    $0x8,%esp
  8007c4:	53                   	push   %ebx
  8007c5:	6a 30                	push   $0x30
  8007c7:	ff d6                	call   *%esi
			putch('x', putdat);
  8007c9:	83 c4 08             	add    $0x8,%esp
  8007cc:	53                   	push   %ebx
  8007cd:	6a 78                	push   $0x78
  8007cf:	ff d6                	call   *%esi
			num = (unsigned long long)
				(uintptr_t) va_arg(ap, void *);
  8007d1:	8b 45 14             	mov    0x14(%ebp),%eax
  8007d4:	8d 50 04             	lea    0x4(%eax),%edx
  8007d7:	89 55 14             	mov    %edx,0x14(%ebp)

		// pointer
		case 'p':
			putch('0', putdat);
			putch('x', putdat);
			num = (unsigned long long)
  8007da:	8b 00                	mov    (%eax),%eax
  8007dc:	ba 00 00 00 00       	mov    $0x0,%edx
				(uintptr_t) va_arg(ap, void *);
			base = 16;
			goto number;
  8007e1:	83 c4 10             	add    $0x10,%esp
		case 'p':
			putch('0', putdat);
			putch('x', putdat);
			num = (unsigned long long)
				(uintptr_t) va_arg(ap, void *);
			base = 16;
  8007e4:	b9 10 00 00 00       	mov    $0x10,%ecx
			goto number;
  8007e9:	eb 0d                	jmp    8007f8 <vprintfmt+0x311>

		// (unsigned) hexadecimal
		case 'x':
			num = getuint(&ap, lflag);
  8007eb:	8d 45 14             	lea    0x14(%ebp),%eax
  8007ee:	e8 4e fc ff ff       	call   800441 <getuint>
			base = 16;
  8007f3:	b9 10 00 00 00       	mov    $0x10,%ecx
		number:
			printnum(putch, putdat, num, base, width, padc);
  8007f8:	83 ec 0c             	sub    $0xc,%esp
  8007fb:	0f be 7d d4          	movsbl -0x2c(%ebp),%edi
  8007ff:	57                   	push   %edi
  800800:	ff 75 e0             	pushl  -0x20(%ebp)
  800803:	51                   	push   %ecx
  800804:	52                   	push   %edx
  800805:	50                   	push   %eax
  800806:	89 da                	mov    %ebx,%edx
  800808:	89 f0                	mov    %esi,%eax
  80080a:	e8 83 fb ff ff       	call   800392 <printnum>
			break;
  80080f:	83 c4 20             	add    $0x20,%esp
  800812:	8b 7d e4             	mov    -0x1c(%ebp),%edi
  800815:	e9 f3 fc ff ff       	jmp    80050d <vprintfmt+0x26>

		// escaped '%' character
		case '%':
			putch(ch, putdat);
  80081a:	83 ec 08             	sub    $0x8,%esp
  80081d:	53                   	push   %ebx
  80081e:	51                   	push   %ecx
  80081f:	ff d6                	call   *%esi
			break;
  800821:	83 c4 10             	add    $0x10,%esp
		width = -1;
		precision = -1;
		lflag = 0;
		altflag = 0;
	reswitch:
		switch (ch = *(unsigned char *) fmt++) {
  800824:	8b 7d e4             	mov    -0x1c(%ebp),%edi
			break;

		// escaped '%' character
		case '%':
			putch(ch, putdat);
			break;
  800827:	e9 e1 fc ff ff       	jmp    80050d <vprintfmt+0x26>

		// unrecognized escape sequence - just print it literally
		default:
			putch('%', putdat);
  80082c:	83 ec 08             	sub    $0x8,%esp
  80082f:	53                   	push   %ebx
  800830:	6a 25                	push   $0x25
  800832:	ff d6                	call   *%esi
			for (fmt--; fmt[-1] != '%'; fmt--)
  800834:	83 c4 10             	add    $0x10,%esp
  800837:	eb 03                	jmp    80083c <vprintfmt+0x355>
  800839:	83 ef 01             	sub    $0x1,%edi
  80083c:	80 7f ff 25          	cmpb   $0x25,-0x1(%edi)
  800840:	75 f7                	jne    800839 <vprintfmt+0x352>
  800842:	e9 c6 fc ff ff       	jmp    80050d <vprintfmt+0x26>
				/* do nothing */;
			break;
		}
	}
}
  800847:	8d 65 f4             	lea    -0xc(%ebp),%esp
  80084a:	5b                   	pop    %ebx
  80084b:	5e                   	pop    %esi
  80084c:	5f                   	pop    %edi
  80084d:	5d                   	pop    %ebp
  80084e:	c3                   	ret    

0080084f <vsnprintf>:
		*b->buf++ = ch;
}

int
vsnprintf(char *buf, int n, const char *fmt, va_list ap)
{
  80084f:	55                   	push   %ebp
  800850:	89 e5                	mov    %esp,%ebp
  800852:	83 ec 18             	sub    $0x18,%esp
  800855:	8b 45 08             	mov    0x8(%ebp),%eax
  800858:	8b 55 0c             	mov    0xc(%ebp),%edx
	struct sprintbuf b = {buf, buf+n-1, 0};
  80085b:	89 45 ec             	mov    %eax,-0x14(%ebp)
  80085e:	8d 4c 10 ff          	lea    -0x1(%eax,%edx,1),%ecx
  800862:	89 4d f0             	mov    %ecx,-0x10(%ebp)
  800865:	c7 45 f4 00 00 00 00 	movl   $0x0,-0xc(%ebp)

	if (buf == NULL || n < 1)
  80086c:	85 c0                	test   %eax,%eax
  80086e:	74 26                	je     800896 <vsnprintf+0x47>
  800870:	85 d2                	test   %edx,%edx
  800872:	7e 22                	jle    800896 <vsnprintf+0x47>
		return -E_INVAL;

	// print the string to the buffer
	vprintfmt((void*)sprintputch, &b, fmt, ap);
  800874:	ff 75 14             	pushl  0x14(%ebp)
  800877:	ff 75 10             	pushl  0x10(%ebp)
  80087a:	8d 45 ec             	lea    -0x14(%ebp),%eax
  80087d:	50                   	push   %eax
  80087e:	68 ad 04 80 00       	push   $0x8004ad
  800883:	e8 5f fc ff ff       	call   8004e7 <vprintfmt>

	// null terminate the buffer
	*b.buf = '\0';
  800888:	8b 45 ec             	mov    -0x14(%ebp),%eax
  80088b:	c6 00 00             	movb   $0x0,(%eax)

	return b.cnt;
  80088e:	8b 45 f4             	mov    -0xc(%ebp),%eax
  800891:	83 c4 10             	add    $0x10,%esp
  800894:	eb 05                	jmp    80089b <vsnprintf+0x4c>
vsnprintf(char *buf, int n, const char *fmt, va_list ap)
{
	struct sprintbuf b = {buf, buf+n-1, 0};

	if (buf == NULL || n < 1)
		return -E_INVAL;
  800896:	b8 fd ff ff ff       	mov    $0xfffffffd,%eax

	// null terminate the buffer
	*b.buf = '\0';

	return b.cnt;
}
  80089b:	c9                   	leave  
  80089c:	c3                   	ret    

0080089d <snprintf>:

int
snprintf(char *buf, int n, const char *fmt, ...)
{
  80089d:	55                   	push   %ebp
  80089e:	89 e5                	mov    %esp,%ebp
  8008a0:	83 ec 08             	sub    $0x8,%esp
	va_list ap;
	int rc;

	va_start(ap, fmt);
  8008a3:	8d 45 14             	lea    0x14(%ebp),%eax
	rc = vsnprintf(buf, n, fmt, ap);
  8008a6:	50                   	push   %eax
  8008a7:	ff 75 10             	pushl  0x10(%ebp)
  8008aa:	ff 75 0c             	pushl  0xc(%ebp)
  8008ad:	ff 75 08             	pushl  0x8(%ebp)
  8008b0:	e8 9a ff ff ff       	call   80084f <vsnprintf>
	va_end(ap);

	return rc;
}
  8008b5:	c9                   	leave  
  8008b6:	c3                   	ret    

008008b7 <strlen>:
// Primespipe runs 3x faster this way.
#define ASM 1

int
strlen(const char *s)
{
  8008b7:	55                   	push   %ebp
  8008b8:	89 e5                	mov    %esp,%ebp
  8008ba:	8b 55 08             	mov    0x8(%ebp),%edx
	int n;

	for (n = 0; *s != '\0'; s++)
  8008bd:	b8 00 00 00 00       	mov    $0x0,%eax
  8008c2:	eb 03                	jmp    8008c7 <strlen+0x10>
		n++;
  8008c4:	83 c0 01             	add    $0x1,%eax
int
strlen(const char *s)
{
	int n;

	for (n = 0; *s != '\0'; s++)
  8008c7:	80 3c 02 00          	cmpb   $0x0,(%edx,%eax,1)
  8008cb:	75 f7                	jne    8008c4 <strlen+0xd>
		n++;
	return n;
}
  8008cd:	5d                   	pop    %ebp
  8008ce:	c3                   	ret    

008008cf <strnlen>:

int
strnlen(const char *s, size_t size)
{
  8008cf:	55                   	push   %ebp
  8008d0:	89 e5                	mov    %esp,%ebp
  8008d2:	8b 4d 08             	mov    0x8(%ebp),%ecx
  8008d5:	8b 45 0c             	mov    0xc(%ebp),%eax
	int n;

	for (n = 0; size > 0 && *s != '\0'; s++, size--)
  8008d8:	ba 00 00 00 00       	mov    $0x0,%edx
  8008dd:	eb 03                	jmp    8008e2 <strnlen+0x13>
		n++;
  8008df:	83 c2 01             	add    $0x1,%edx
int
strnlen(const char *s, size_t size)
{
	int n;

	for (n = 0; size > 0 && *s != '\0'; s++, size--)
  8008e2:	39 c2                	cmp    %eax,%edx
  8008e4:	74 08                	je     8008ee <strnlen+0x1f>
  8008e6:	80 3c 11 00          	cmpb   $0x0,(%ecx,%edx,1)
  8008ea:	75 f3                	jne    8008df <strnlen+0x10>
  8008ec:	89 d0                	mov    %edx,%eax
		n++;
	return n;
}
  8008ee:	5d                   	pop    %ebp
  8008ef:	c3                   	ret    

008008f0 <strcpy>:

char *
strcpy(char *dst, const char *src)
{
  8008f0:	55                   	push   %ebp
  8008f1:	89 e5                	mov    %esp,%ebp
  8008f3:	53                   	push   %ebx
  8008f4:	8b 45 08             	mov    0x8(%ebp),%eax
  8008f7:	8b 4d 0c             	mov    0xc(%ebp),%ecx
	char *ret;

	ret = dst;
	while ((*dst++ = *src++) != '\0')
  8008fa:	89 c2                	mov    %eax,%edx
  8008fc:	83 c2 01             	add    $0x1,%edx
  8008ff:	83 c1 01             	add    $0x1,%ecx
  800902:	0f b6 59 ff          	movzbl -0x1(%ecx),%ebx
  800906:	88 5a ff             	mov    %bl,-0x1(%edx)
  800909:	84 db                	test   %bl,%bl
  80090b:	75 ef                	jne    8008fc <strcpy+0xc>
		/* do nothing */;
	return ret;
}
  80090d:	5b                   	pop    %ebx
  80090e:	5d                   	pop    %ebp
  80090f:	c3                   	ret    

00800910 <strcat>:

char *
strcat(char *dst, const char *src)
{
  800910:	55                   	push   %ebp
  800911:	89 e5                	mov    %esp,%ebp
  800913:	53                   	push   %ebx
  800914:	8b 5d 08             	mov    0x8(%ebp),%ebx
	int len = strlen(dst);
  800917:	53                   	push   %ebx
  800918:	e8 9a ff ff ff       	call   8008b7 <strlen>
  80091d:	83 c4 04             	add    $0x4,%esp
	strcpy(dst + len, src);
  800920:	ff 75 0c             	pushl  0xc(%ebp)
  800923:	01 d8                	add    %ebx,%eax
  800925:	50                   	push   %eax
  800926:	e8 c5 ff ff ff       	call   8008f0 <strcpy>
	return dst;
}
  80092b:	89 d8                	mov    %ebx,%eax
  80092d:	8b 5d fc             	mov    -0x4(%ebp),%ebx
  800930:	c9                   	leave  
  800931:	c3                   	ret    

00800932 <strncpy>:

char *
strncpy(char *dst, const char *src, size_t size) {
  800932:	55                   	push   %ebp
  800933:	89 e5                	mov    %esp,%ebp
  800935:	56                   	push   %esi
  800936:	53                   	push   %ebx
  800937:	8b 75 08             	mov    0x8(%ebp),%esi
  80093a:	8b 4d 0c             	mov    0xc(%ebp),%ecx
  80093d:	89 f3                	mov    %esi,%ebx
  80093f:	03 5d 10             	add    0x10(%ebp),%ebx
	size_t i;
	char *ret;

	ret = dst;
	for (i = 0; i < size; i++) {
  800942:	89 f2                	mov    %esi,%edx
  800944:	eb 0f                	jmp    800955 <strncpy+0x23>
		*dst++ = *src;
  800946:	83 c2 01             	add    $0x1,%edx
  800949:	0f b6 01             	movzbl (%ecx),%eax
  80094c:	88 42 ff             	mov    %al,-0x1(%edx)
		// If strlen(src) < size, null-pad 'dst' out to 'size' chars
		if (*src != '\0')
			src++;
  80094f:	80 39 01             	cmpb   $0x1,(%ecx)
  800952:	83 d9 ff             	sbb    $0xffffffff,%ecx
strncpy(char *dst, const char *src, size_t size) {
	size_t i;
	char *ret;

	ret = dst;
	for (i = 0; i < size; i++) {
  800955:	39 da                	cmp    %ebx,%edx
  800957:	75 ed                	jne    800946 <strncpy+0x14>
		// If strlen(src) < size, null-pad 'dst' out to 'size' chars
		if (*src != '\0')
			src++;
	}
	return ret;
}
  800959:	89 f0                	mov    %esi,%eax
  80095b:	5b                   	pop    %ebx
  80095c:	5e                   	pop    %esi
  80095d:	5d                   	pop    %ebp
  80095e:	c3                   	ret    

0080095f <strlcpy>:

size_t
strlcpy(char *dst, const char *src, size_t size)
{
  80095f:	55                   	push   %ebp
  800960:	89 e5                	mov    %esp,%ebp
  800962:	56                   	push   %esi
  800963:	53                   	push   %ebx
  800964:	8b 75 08             	mov    0x8(%ebp),%esi
  800967:	8b 4d 0c             	mov    0xc(%ebp),%ecx
  80096a:	8b 55 10             	mov    0x10(%ebp),%edx
  80096d:	89 f0                	mov    %esi,%eax
	char *dst_in;

	dst_in = dst;
	if (size > 0) {
  80096f:	85 d2                	test   %edx,%edx
  800971:	74 21                	je     800994 <strlcpy+0x35>
  800973:	8d 44 16 ff          	lea    -0x1(%esi,%edx,1),%eax
  800977:	89 f2                	mov    %esi,%edx
  800979:	eb 09                	jmp    800984 <strlcpy+0x25>
		while (--size > 0 && *src != '\0')
			*dst++ = *src++;
  80097b:	83 c2 01             	add    $0x1,%edx
  80097e:	83 c1 01             	add    $0x1,%ecx
  800981:	88 5a ff             	mov    %bl,-0x1(%edx)
{
	char *dst_in;

	dst_in = dst;
	if (size > 0) {
		while (--size > 0 && *src != '\0')
  800984:	39 c2                	cmp    %eax,%edx
  800986:	74 09                	je     800991 <strlcpy+0x32>
  800988:	0f b6 19             	movzbl (%ecx),%ebx
  80098b:	84 db                	test   %bl,%bl
  80098d:	75 ec                	jne    80097b <strlcpy+0x1c>
  80098f:	89 d0                	mov    %edx,%eax
			*dst++ = *src++;
		*dst = '\0';
  800991:	c6 00 00             	movb   $0x0,(%eax)
	}
	return dst - dst_in;
  800994:	29 f0                	sub    %esi,%eax
}
  800996:	5b                   	pop    %ebx
  800997:	5e                   	pop    %esi
  800998:	5d                   	pop    %ebp
  800999:	c3                   	ret    

0080099a <strcmp>:

int
strcmp(const char *p, const char *q)
{
  80099a:	55                   	push   %ebp
  80099b:	89 e5                	mov    %esp,%ebp
  80099d:	8b 4d 08             	mov    0x8(%ebp),%ecx
  8009a0:	8b 55 0c             	mov    0xc(%ebp),%edx
	while (*p && *p == *q)
  8009a3:	eb 06                	jmp    8009ab <strcmp+0x11>
		p++, q++;
  8009a5:	83 c1 01             	add    $0x1,%ecx
  8009a8:	83 c2 01             	add    $0x1,%edx
}

int
strcmp(const char *p, const char *q)
{
	while (*p && *p == *q)
  8009ab:	0f b6 01             	movzbl (%ecx),%eax
  8009ae:	84 c0                	test   %al,%al
  8009b0:	74 04                	je     8009b6 <strcmp+0x1c>
  8009b2:	3a 02                	cmp    (%edx),%al
  8009b4:	74 ef                	je     8009a5 <strcmp+0xb>
		p++, q++;
	return (int) ((unsigned char) *p - (unsigned char) *q);
  8009b6:	0f b6 c0             	movzbl %al,%eax
  8009b9:	0f b6 12             	movzbl (%edx),%edx
  8009bc:	29 d0                	sub    %edx,%eax
}
  8009be:	5d                   	pop    %ebp
  8009bf:	c3                   	ret    

008009c0 <strncmp>:

int
strncmp(const char *p, const char *q, size_t n)
{
  8009c0:	55                   	push   %ebp
  8009c1:	89 e5                	mov    %esp,%ebp
  8009c3:	53                   	push   %ebx
  8009c4:	8b 45 08             	mov    0x8(%ebp),%eax
  8009c7:	8b 55 0c             	mov    0xc(%ebp),%edx
  8009ca:	89 c3                	mov    %eax,%ebx
  8009cc:	03 5d 10             	add    0x10(%ebp),%ebx
	while (n > 0 && *p && *p == *q)
  8009cf:	eb 06                	jmp    8009d7 <strncmp+0x17>
		n--, p++, q++;
  8009d1:	83 c0 01             	add    $0x1,%eax
  8009d4:	83 c2 01             	add    $0x1,%edx
}

int
strncmp(const char *p, const char *q, size_t n)
{
	while (n > 0 && *p && *p == *q)
  8009d7:	39 d8                	cmp    %ebx,%eax
  8009d9:	74 15                	je     8009f0 <strncmp+0x30>
  8009db:	0f b6 08             	movzbl (%eax),%ecx
  8009de:	84 c9                	test   %cl,%cl
  8009e0:	74 04                	je     8009e6 <strncmp+0x26>
  8009e2:	3a 0a                	cmp    (%edx),%cl
  8009e4:	74 eb                	je     8009d1 <strncmp+0x11>
		n--, p++, q++;
	if (n == 0)
		return 0;
	else
		return (int) ((unsigned char) *p - (unsigned char) *q);
  8009e6:	0f b6 00             	movzbl (%eax),%eax
  8009e9:	0f b6 12             	movzbl (%edx),%edx
  8009ec:	29 d0                	sub    %edx,%eax
  8009ee:	eb 05                	jmp    8009f5 <strncmp+0x35>
strncmp(const char *p, const char *q, size_t n)
{
	while (n > 0 && *p && *p == *q)
		n--, p++, q++;
	if (n == 0)
		return 0;
  8009f0:	b8 00 00 00 00       	mov    $0x0,%eax
	else
		return (int) ((unsigned char) *p - (unsigned char) *q);
}
  8009f5:	5b                   	pop    %ebx
  8009f6:	5d                   	pop    %ebp
  8009f7:	c3                   	ret    

008009f8 <strchr>:

// Return a pointer to the first occurrence of 'c' in 's',
// or a null pointer if the string has no 'c'.
char *
strchr(const char *s, char c)
{
  8009f8:	55                   	push   %ebp
  8009f9:	89 e5                	mov    %esp,%ebp
  8009fb:	8b 45 08             	mov    0x8(%ebp),%eax
  8009fe:	0f b6 4d 0c          	movzbl 0xc(%ebp),%ecx
	for (; *s; s++)
  800a02:	eb 07                	jmp    800a0b <strchr+0x13>
		if (*s == c)
  800a04:	38 ca                	cmp    %cl,%dl
  800a06:	74 0f                	je     800a17 <strchr+0x1f>
// Return a pointer to the first occurrence of 'c' in 's',
// or a null pointer if the string has no 'c'.
char *
strchr(const char *s, char c)
{
	for (; *s; s++)
  800a08:	83 c0 01             	add    $0x1,%eax
  800a0b:	0f b6 10             	movzbl (%eax),%edx
  800a0e:	84 d2                	test   %dl,%dl
  800a10:	75 f2                	jne    800a04 <strchr+0xc>
		if (*s == c)
			return (char *) s;
	return 0;
  800a12:	b8 00 00 00 00       	mov    $0x0,%eax
}
  800a17:	5d                   	pop    %ebp
  800a18:	c3                   	ret    

00800a19 <strfind>:

// Return a pointer to the first occurrence of 'c' in 's',
// or a pointer to the string-ending null character if the string has no 'c'.
char *
strfind(const char *s, char c)
{
  800a19:	55                   	push   %ebp
  800a1a:	89 e5                	mov    %esp,%ebp
  800a1c:	8b 45 08             	mov    0x8(%ebp),%eax
  800a1f:	0f b6 4d 0c          	movzbl 0xc(%ebp),%ecx
	for (; *s; s++)
  800a23:	eb 03                	jmp    800a28 <strfind+0xf>
  800a25:	83 c0 01             	add    $0x1,%eax
  800a28:	0f b6 10             	movzbl (%eax),%edx
		if (*s == c)
  800a2b:	38 ca                	cmp    %cl,%dl
  800a2d:	74 04                	je     800a33 <strfind+0x1a>
  800a2f:	84 d2                	test   %dl,%dl
  800a31:	75 f2                	jne    800a25 <strfind+0xc>
			break;
	return (char *) s;
}
  800a33:	5d                   	pop    %ebp
  800a34:	c3                   	ret    

00800a35 <memset>:

#if ASM
void *
memset(void *v, int c, size_t n)
{
  800a35:	55                   	push   %ebp
  800a36:	89 e5                	mov    %esp,%ebp
  800a38:	57                   	push   %edi
  800a39:	56                   	push   %esi
  800a3a:	53                   	push   %ebx
  800a3b:	8b 55 08             	mov    0x8(%ebp),%edx
  800a3e:	8b 4d 10             	mov    0x10(%ebp),%ecx
	char *p = v;

	if (n == 0)
  800a41:	85 c9                	test   %ecx,%ecx
  800a43:	74 37                	je     800a7c <memset+0x47>
		return v;
	if ((int)v%4 == 0 && n%4 == 0) {
  800a45:	f6 c2 03             	test   $0x3,%dl
  800a48:	75 2a                	jne    800a74 <memset+0x3f>
  800a4a:	f6 c1 03             	test   $0x3,%cl
  800a4d:	75 25                	jne    800a74 <memset+0x3f>
		c &= 0xFF;
  800a4f:	0f b6 5d 0c          	movzbl 0xc(%ebp),%ebx
		c = (c<<24)|(c<<16)|(c<<8)|c;
  800a53:	89 df                	mov    %ebx,%edi
  800a55:	c1 e7 08             	shl    $0x8,%edi
  800a58:	89 de                	mov    %ebx,%esi
  800a5a:	c1 e6 18             	shl    $0x18,%esi
  800a5d:	89 d8                	mov    %ebx,%eax
  800a5f:	c1 e0 10             	shl    $0x10,%eax
  800a62:	09 f0                	or     %esi,%eax
  800a64:	09 c3                	or     %eax,%ebx
		asm volatile("cld; rep stosl\n"
			: "=D" (p), "=c" (n)
			: "D" (p), "a" (c), "c" (n/4)
  800a66:	c1 e9 02             	shr    $0x2,%ecx
	if (n == 0)
		return v;
	if ((int)v%4 == 0 && n%4 == 0) {
		c &= 0xFF;
		c = (c<<24)|(c<<16)|(c<<8)|c;
		asm volatile("cld; rep stosl\n"
  800a69:	89 f8                	mov    %edi,%eax
  800a6b:	09 d8                	or     %ebx,%eax
  800a6d:	89 d7                	mov    %edx,%edi
  800a6f:	fc                   	cld    
  800a70:	f3 ab                	rep stos %eax,%es:(%edi)
  800a72:	eb 08                	jmp    800a7c <memset+0x47>
			: "=D" (p), "=c" (n)
			: "D" (p), "a" (c), "c" (n/4)
			: "cc", "memory");
	} else
		asm volatile("cld; rep stosb\n"
  800a74:	89 d7                	mov    %edx,%edi
  800a76:	8b 45 0c             	mov    0xc(%ebp),%eax
  800a79:	fc                   	cld    
  800a7a:	f3 aa                	rep stos %al,%es:(%edi)
			: "=D" (p), "=c" (n)
			: "0" (p), "a" (c), "1" (n)
			: "cc", "memory");
	return v;
}
  800a7c:	89 d0                	mov    %edx,%eax
  800a7e:	5b                   	pop    %ebx
  800a7f:	5e                   	pop    %esi
  800a80:	5f                   	pop    %edi
  800a81:	5d                   	pop    %ebp
  800a82:	c3                   	ret    

00800a83 <memmove>:

void *
memmove(void *dst, const void *src, size_t n)
{
  800a83:	55                   	push   %ebp
  800a84:	89 e5                	mov    %esp,%ebp
  800a86:	57                   	push   %edi
  800a87:	56                   	push   %esi
  800a88:	8b 45 08             	mov    0x8(%ebp),%eax
  800a8b:	8b 75 0c             	mov    0xc(%ebp),%esi
  800a8e:	8b 4d 10             	mov    0x10(%ebp),%ecx
	const char *s;
	char *d;

	s = src;
	d = dst;
	if (s < d && s + n > d) {
  800a91:	39 c6                	cmp    %eax,%esi
  800a93:	73 35                	jae    800aca <memmove+0x47>
  800a95:	8d 14 0e             	lea    (%esi,%ecx,1),%edx
  800a98:	39 d0                	cmp    %edx,%eax
  800a9a:	73 2e                	jae    800aca <memmove+0x47>
		s += n;
		d += n;
  800a9c:	8d 3c 08             	lea    (%eax,%ecx,1),%edi
		if ((int)s%4 == 0 && (int)d%4 == 0 && n%4 == 0)
  800a9f:	89 d6                	mov    %edx,%esi
  800aa1:	09 fe                	or     %edi,%esi
  800aa3:	f7 c6 03 00 00 00    	test   $0x3,%esi
  800aa9:	75 13                	jne    800abe <memmove+0x3b>
  800aab:	f6 c1 03             	test   $0x3,%cl
  800aae:	75 0e                	jne    800abe <memmove+0x3b>
			asm volatile("std; rep movsl\n"
  800ab0:	83 ef 04             	sub    $0x4,%edi
  800ab3:	8d 72 fc             	lea    -0x4(%edx),%esi
  800ab6:	c1 e9 02             	shr    $0x2,%ecx
  800ab9:	fd                   	std    
  800aba:	f3 a5                	rep movsl %ds:(%esi),%es:(%edi)
  800abc:	eb 09                	jmp    800ac7 <memmove+0x44>
				:: "D" (d-4), "S" (s-4), "c" (n/4) : "cc", "memory");
		else
			asm volatile("std; rep movsb\n"
  800abe:	83 ef 01             	sub    $0x1,%edi
  800ac1:	8d 72 ff             	lea    -0x1(%edx),%esi
  800ac4:	fd                   	std    
  800ac5:	f3 a4                	rep movsb %ds:(%esi),%es:(%edi)
				:: "D" (d-1), "S" (s-1), "c" (n) : "cc", "memory");
		// Some versions of GCC rely on DF being clear
		asm volatile("cld" ::: "cc");
  800ac7:	fc                   	cld    
  800ac8:	eb 1d                	jmp    800ae7 <memmove+0x64>
	} else {
		if ((int)s%4 == 0 && (int)d%4 == 0 && n%4 == 0)
  800aca:	89 f2                	mov    %esi,%edx
  800acc:	09 c2                	or     %eax,%edx
  800ace:	f6 c2 03             	test   $0x3,%dl
  800ad1:	75 0f                	jne    800ae2 <memmove+0x5f>
  800ad3:	f6 c1 03             	test   $0x3,%cl
  800ad6:	75 0a                	jne    800ae2 <memmove+0x5f>
			asm volatile("cld; rep movsl\n"
  800ad8:	c1 e9 02             	shr    $0x2,%ecx
  800adb:	89 c7                	mov    %eax,%edi
  800add:	fc                   	cld    
  800ade:	f3 a5                	rep movsl %ds:(%esi),%es:(%edi)
  800ae0:	eb 05                	jmp    800ae7 <memmove+0x64>
				:: "D" (d), "S" (s), "c" (n/4) : "cc", "memory");
		else
			asm volatile("cld; rep movsb\n"
  800ae2:	89 c7                	mov    %eax,%edi
  800ae4:	fc                   	cld    
  800ae5:	f3 a4                	rep movsb %ds:(%esi),%es:(%edi)
				:: "D" (d), "S" (s), "c" (n) : "cc", "memory");
	}
	return dst;
}
  800ae7:	5e                   	pop    %esi
  800ae8:	5f                   	pop    %edi
  800ae9:	5d                   	pop    %ebp
  800aea:	c3                   	ret    

00800aeb <memcpy>:
}
#endif

void *
memcpy(void *dst, const void *src, size_t n)
{
  800aeb:	55                   	push   %ebp
  800aec:	89 e5                	mov    %esp,%ebp
	return memmove(dst, src, n);
  800aee:	ff 75 10             	pushl  0x10(%ebp)
  800af1:	ff 75 0c             	pushl  0xc(%ebp)
  800af4:	ff 75 08             	pushl  0x8(%ebp)
  800af7:	e8 87 ff ff ff       	call   800a83 <memmove>
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
  800b03:	8b 45 08             	mov    0x8(%ebp),%eax
  800b06:	8b 55 0c             	mov    0xc(%ebp),%edx
  800b09:	89 c6                	mov    %eax,%esi
  800b0b:	03 75 10             	add    0x10(%ebp),%esi
	const uint8_t *s1 = (const uint8_t *) v1;
	const uint8_t *s2 = (const uint8_t *) v2;

	while (n-- > 0) {
  800b0e:	eb 1a                	jmp    800b2a <memcmp+0x2c>
		if (*s1 != *s2)
  800b10:	0f b6 08             	movzbl (%eax),%ecx
  800b13:	0f b6 1a             	movzbl (%edx),%ebx
  800b16:	38 d9                	cmp    %bl,%cl
  800b18:	74 0a                	je     800b24 <memcmp+0x26>
			return (int) *s1 - (int) *s2;
  800b1a:	0f b6 c1             	movzbl %cl,%eax
  800b1d:	0f b6 db             	movzbl %bl,%ebx
  800b20:	29 d8                	sub    %ebx,%eax
  800b22:	eb 0f                	jmp    800b33 <memcmp+0x35>
		s1++, s2++;
  800b24:	83 c0 01             	add    $0x1,%eax
  800b27:	83 c2 01             	add    $0x1,%edx
memcmp(const void *v1, const void *v2, size_t n)
{
	const uint8_t *s1 = (const uint8_t *) v1;
	const uint8_t *s2 = (const uint8_t *) v2;

	while (n-- > 0) {
  800b2a:	39 f0                	cmp    %esi,%eax
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
  800b5a:	8b 4d 08             	mov    0x8(%ebp),%ecx
  800b5d:	8b 5d 10             	mov    0x10(%ebp),%ebx
	int neg = 0;
	long val = 0;

	// gobble initial whitespace
	while (*s == ' ' || *s == '\t')
  800b60:	eb 03                	jmp    800b65 <strtol+0x11>
		s++;
  800b62:	83 c1 01             	add    $0x1,%ecx
{
	int neg = 0;
	long val = 0;

	// gobble initial whitespace
	while (*s == ' ' || *s == '\t')
  800b65:	0f b6 01             	movzbl (%ecx),%eax
  800b68:	3c 20                	cmp    $0x20,%al
  800b6a:	74 f6                	je     800b62 <strtol+0xe>
  800b6c:	3c 09                	cmp    $0x9,%al
  800b6e:	74 f2                	je     800b62 <strtol+0xe>
		s++;

	// plus/minus sign
	if (*s == '+')
  800b70:	3c 2b                	cmp    $0x2b,%al
  800b72:	75 0a                	jne    800b7e <strtol+0x2a>
		s++;
  800b74:	83 c1 01             	add    $0x1,%ecx
}

long
strtol(const char *s, char **endptr, int base)
{
	int neg = 0;
  800b77:	bf 00 00 00 00       	mov    $0x0,%edi
  800b7c:	eb 11                	jmp    800b8f <strtol+0x3b>
  800b7e:	bf 00 00 00 00       	mov    $0x0,%edi
		s++;

	// plus/minus sign
	if (*s == '+')
		s++;
	else if (*s == '-')
  800b83:	3c 2d                	cmp    $0x2d,%al
  800b85:	75 08                	jne    800b8f <strtol+0x3b>
		s++, neg = 1;
  800b87:	83 c1 01             	add    $0x1,%ecx
  800b8a:	bf 01 00 00 00       	mov    $0x1,%edi

	// hex or octal base prefix
	if ((base == 0 || base == 16) && (s[0] == '0' && s[1] == 'x'))
  800b8f:	f7 c3 ef ff ff ff    	test   $0xffffffef,%ebx
  800b95:	75 15                	jne    800bac <strtol+0x58>
  800b97:	80 39 30             	cmpb   $0x30,(%ecx)
  800b9a:	75 10                	jne    800bac <strtol+0x58>
  800b9c:	80 79 01 78          	cmpb   $0x78,0x1(%ecx)
  800ba0:	75 7c                	jne    800c1e <strtol+0xca>
		s += 2, base = 16;
  800ba2:	83 c1 02             	add    $0x2,%ecx
  800ba5:	bb 10 00 00 00       	mov    $0x10,%ebx
  800baa:	eb 16                	jmp    800bc2 <strtol+0x6e>
	else if (base == 0 && s[0] == '0')
  800bac:	85 db                	test   %ebx,%ebx
  800bae:	75 12                	jne    800bc2 <strtol+0x6e>
		s++, base = 8;
	else if (base == 0)
		base = 10;
  800bb0:	bb 0a 00 00 00       	mov    $0xa,%ebx
		s++, neg = 1;

	// hex or octal base prefix
	if ((base == 0 || base == 16) && (s[0] == '0' && s[1] == 'x'))
		s += 2, base = 16;
	else if (base == 0 && s[0] == '0')
  800bb5:	80 39 30             	cmpb   $0x30,(%ecx)
  800bb8:	75 08                	jne    800bc2 <strtol+0x6e>
		s++, base = 8;
  800bba:	83 c1 01             	add    $0x1,%ecx
  800bbd:	bb 08 00 00 00       	mov    $0x8,%ebx
	else if (base == 0)
		base = 10;
  800bc2:	b8 00 00 00 00       	mov    $0x0,%eax
  800bc7:	89 5d 10             	mov    %ebx,0x10(%ebp)

	// digits
	while (1) {
		int dig;

		if (*s >= '0' && *s <= '9')
  800bca:	0f b6 11             	movzbl (%ecx),%edx
  800bcd:	8d 72 d0             	lea    -0x30(%edx),%esi
  800bd0:	89 f3                	mov    %esi,%ebx
  800bd2:	80 fb 09             	cmp    $0x9,%bl
  800bd5:	77 08                	ja     800bdf <strtol+0x8b>
			dig = *s - '0';
  800bd7:	0f be d2             	movsbl %dl,%edx
  800bda:	83 ea 30             	sub    $0x30,%edx
  800bdd:	eb 22                	jmp    800c01 <strtol+0xad>
		else if (*s >= 'a' && *s <= 'z')
  800bdf:	8d 72 9f             	lea    -0x61(%edx),%esi
  800be2:	89 f3                	mov    %esi,%ebx
  800be4:	80 fb 19             	cmp    $0x19,%bl
  800be7:	77 08                	ja     800bf1 <strtol+0x9d>
			dig = *s - 'a' + 10;
  800be9:	0f be d2             	movsbl %dl,%edx
  800bec:	83 ea 57             	sub    $0x57,%edx
  800bef:	eb 10                	jmp    800c01 <strtol+0xad>
		else if (*s >= 'A' && *s <= 'Z')
  800bf1:	8d 72 bf             	lea    -0x41(%edx),%esi
  800bf4:	89 f3                	mov    %esi,%ebx
  800bf6:	80 fb 19             	cmp    $0x19,%bl
  800bf9:	77 16                	ja     800c11 <strtol+0xbd>
			dig = *s - 'A' + 10;
  800bfb:	0f be d2             	movsbl %dl,%edx
  800bfe:	83 ea 37             	sub    $0x37,%edx
		else
			break;
		if (dig >= base)
  800c01:	3b 55 10             	cmp    0x10(%ebp),%edx
  800c04:	7d 0b                	jge    800c11 <strtol+0xbd>
			break;
		s++, val = (val * base) + dig;
  800c06:	83 c1 01             	add    $0x1,%ecx
  800c09:	0f af 45 10          	imul   0x10(%ebp),%eax
  800c0d:	01 d0                	add    %edx,%eax
		// we don't properly detect overflow!
	}
  800c0f:	eb b9                	jmp    800bca <strtol+0x76>

	if (endptr)
  800c11:	83 7d 0c 00          	cmpl   $0x0,0xc(%ebp)
  800c15:	74 0d                	je     800c24 <strtol+0xd0>
		*endptr = (char *) s;
  800c17:	8b 75 0c             	mov    0xc(%ebp),%esi
  800c1a:	89 0e                	mov    %ecx,(%esi)
  800c1c:	eb 06                	jmp    800c24 <strtol+0xd0>
		s++, neg = 1;

	// hex or octal base prefix
	if ((base == 0 || base == 16) && (s[0] == '0' && s[1] == 'x'))
		s += 2, base = 16;
	else if (base == 0 && s[0] == '0')
  800c1e:	85 db                	test   %ebx,%ebx
  800c20:	74 98                	je     800bba <strtol+0x66>
  800c22:	eb 9e                	jmp    800bc2 <strtol+0x6e>
		// we don't properly detect overflow!
	}

	if (endptr)
		*endptr = (char *) s;
	return (neg ? -val : val);
  800c24:	89 c2                	mov    %eax,%edx
  800c26:	f7 da                	neg    %edx
  800c28:	85 ff                	test   %edi,%edi
  800c2a:	0f 45 c2             	cmovne %edx,%eax
}
  800c2d:	5b                   	pop    %ebx
  800c2e:	5e                   	pop    %esi
  800c2f:	5f                   	pop    %edi
  800c30:	5d                   	pop    %ebp
  800c31:	c3                   	ret    
  800c32:	66 90                	xchg   %ax,%ax
  800c34:	66 90                	xchg   %ax,%ax
  800c36:	66 90                	xchg   %ax,%ax
  800c38:	66 90                	xchg   %ax,%ax
  800c3a:	66 90                	xchg   %ax,%ax
  800c3c:	66 90                	xchg   %ax,%ax
  800c3e:	66 90                	xchg   %ax,%ax

00800c40 <__udivdi3>:
  800c40:	55                   	push   %ebp
  800c41:	57                   	push   %edi
  800c42:	56                   	push   %esi
  800c43:	53                   	push   %ebx
  800c44:	83 ec 1c             	sub    $0x1c,%esp
  800c47:	8b 74 24 3c          	mov    0x3c(%esp),%esi
  800c4b:	8b 5c 24 30          	mov    0x30(%esp),%ebx
  800c4f:	8b 4c 24 34          	mov    0x34(%esp),%ecx
  800c53:	8b 7c 24 38          	mov    0x38(%esp),%edi
  800c57:	85 f6                	test   %esi,%esi
  800c59:	89 5c 24 08          	mov    %ebx,0x8(%esp)
  800c5d:	89 ca                	mov    %ecx,%edx
  800c5f:	89 f8                	mov    %edi,%eax
  800c61:	75 3d                	jne    800ca0 <__udivdi3+0x60>
  800c63:	39 cf                	cmp    %ecx,%edi
  800c65:	0f 87 c5 00 00 00    	ja     800d30 <__udivdi3+0xf0>
  800c6b:	85 ff                	test   %edi,%edi
  800c6d:	89 fd                	mov    %edi,%ebp
  800c6f:	75 0b                	jne    800c7c <__udivdi3+0x3c>
  800c71:	b8 01 00 00 00       	mov    $0x1,%eax
  800c76:	31 d2                	xor    %edx,%edx
  800c78:	f7 f7                	div    %edi
  800c7a:	89 c5                	mov    %eax,%ebp
  800c7c:	89 c8                	mov    %ecx,%eax
  800c7e:	31 d2                	xor    %edx,%edx
  800c80:	f7 f5                	div    %ebp
  800c82:	89 c1                	mov    %eax,%ecx
  800c84:	89 d8                	mov    %ebx,%eax
  800c86:	89 cf                	mov    %ecx,%edi
  800c88:	f7 f5                	div    %ebp
  800c8a:	89 c3                	mov    %eax,%ebx
  800c8c:	89 d8                	mov    %ebx,%eax
  800c8e:	89 fa                	mov    %edi,%edx
  800c90:	83 c4 1c             	add    $0x1c,%esp
  800c93:	5b                   	pop    %ebx
  800c94:	5e                   	pop    %esi
  800c95:	5f                   	pop    %edi
  800c96:	5d                   	pop    %ebp
  800c97:	c3                   	ret    
  800c98:	90                   	nop
  800c99:	8d b4 26 00 00 00 00 	lea    0x0(%esi,%eiz,1),%esi
  800ca0:	39 ce                	cmp    %ecx,%esi
  800ca2:	77 74                	ja     800d18 <__udivdi3+0xd8>
  800ca4:	0f bd fe             	bsr    %esi,%edi
  800ca7:	83 f7 1f             	xor    $0x1f,%edi
  800caa:	0f 84 98 00 00 00    	je     800d48 <__udivdi3+0x108>
  800cb0:	bb 20 00 00 00       	mov    $0x20,%ebx
  800cb5:	89 f9                	mov    %edi,%ecx
  800cb7:	89 c5                	mov    %eax,%ebp
  800cb9:	29 fb                	sub    %edi,%ebx
  800cbb:	d3 e6                	shl    %cl,%esi
  800cbd:	89 d9                	mov    %ebx,%ecx
  800cbf:	d3 ed                	shr    %cl,%ebp
  800cc1:	89 f9                	mov    %edi,%ecx
  800cc3:	d3 e0                	shl    %cl,%eax
  800cc5:	09 ee                	or     %ebp,%esi
  800cc7:	89 d9                	mov    %ebx,%ecx
  800cc9:	89 44 24 0c          	mov    %eax,0xc(%esp)
  800ccd:	89 d5                	mov    %edx,%ebp
  800ccf:	8b 44 24 08          	mov    0x8(%esp),%eax
  800cd3:	d3 ed                	shr    %cl,%ebp
  800cd5:	89 f9                	mov    %edi,%ecx
  800cd7:	d3 e2                	shl    %cl,%edx
  800cd9:	89 d9                	mov    %ebx,%ecx
  800cdb:	d3 e8                	shr    %cl,%eax
  800cdd:	09 c2                	or     %eax,%edx
  800cdf:	89 d0                	mov    %edx,%eax
  800ce1:	89 ea                	mov    %ebp,%edx
  800ce3:	f7 f6                	div    %esi
  800ce5:	89 d5                	mov    %edx,%ebp
  800ce7:	89 c3                	mov    %eax,%ebx
  800ce9:	f7 64 24 0c          	mull   0xc(%esp)
  800ced:	39 d5                	cmp    %edx,%ebp
  800cef:	72 10                	jb     800d01 <__udivdi3+0xc1>
  800cf1:	8b 74 24 08          	mov    0x8(%esp),%esi
  800cf5:	89 f9                	mov    %edi,%ecx
  800cf7:	d3 e6                	shl    %cl,%esi
  800cf9:	39 c6                	cmp    %eax,%esi
  800cfb:	73 07                	jae    800d04 <__udivdi3+0xc4>
  800cfd:	39 d5                	cmp    %edx,%ebp
  800cff:	75 03                	jne    800d04 <__udivdi3+0xc4>
  800d01:	83 eb 01             	sub    $0x1,%ebx
  800d04:	31 ff                	xor    %edi,%edi
  800d06:	89 d8                	mov    %ebx,%eax
  800d08:	89 fa                	mov    %edi,%edx
  800d0a:	83 c4 1c             	add    $0x1c,%esp
  800d0d:	5b                   	pop    %ebx
  800d0e:	5e                   	pop    %esi
  800d0f:	5f                   	pop    %edi
  800d10:	5d                   	pop    %ebp
  800d11:	c3                   	ret    
  800d12:	8d b6 00 00 00 00    	lea    0x0(%esi),%esi
  800d18:	31 ff                	xor    %edi,%edi
  800d1a:	31 db                	xor    %ebx,%ebx
  800d1c:	89 d8                	mov    %ebx,%eax
  800d1e:	89 fa                	mov    %edi,%edx
  800d20:	83 c4 1c             	add    $0x1c,%esp
  800d23:	5b                   	pop    %ebx
  800d24:	5e                   	pop    %esi
  800d25:	5f                   	pop    %edi
  800d26:	5d                   	pop    %ebp
  800d27:	c3                   	ret    
  800d28:	90                   	nop
  800d29:	8d b4 26 00 00 00 00 	lea    0x0(%esi,%eiz,1),%esi
  800d30:	89 d8                	mov    %ebx,%eax
  800d32:	f7 f7                	div    %edi
  800d34:	31 ff                	xor    %edi,%edi
  800d36:	89 c3                	mov    %eax,%ebx
  800d38:	89 d8                	mov    %ebx,%eax
  800d3a:	89 fa                	mov    %edi,%edx
  800d3c:	83 c4 1c             	add    $0x1c,%esp
  800d3f:	5b                   	pop    %ebx
  800d40:	5e                   	pop    %esi
  800d41:	5f                   	pop    %edi
  800d42:	5d                   	pop    %ebp
  800d43:	c3                   	ret    
  800d44:	8d 74 26 00          	lea    0x0(%esi,%eiz,1),%esi
  800d48:	39 ce                	cmp    %ecx,%esi
  800d4a:	72 0c                	jb     800d58 <__udivdi3+0x118>
  800d4c:	31 db                	xor    %ebx,%ebx
  800d4e:	3b 44 24 08          	cmp    0x8(%esp),%eax
  800d52:	0f 87 34 ff ff ff    	ja     800c8c <__udivdi3+0x4c>
  800d58:	bb 01 00 00 00       	mov    $0x1,%ebx
  800d5d:	e9 2a ff ff ff       	jmp    800c8c <__udivdi3+0x4c>
  800d62:	66 90                	xchg   %ax,%ax
  800d64:	66 90                	xchg   %ax,%ax
  800d66:	66 90                	xchg   %ax,%ax
  800d68:	66 90                	xchg   %ax,%ax
  800d6a:	66 90                	xchg   %ax,%ax
  800d6c:	66 90                	xchg   %ax,%ax
  800d6e:	66 90                	xchg   %ax,%ax

00800d70 <__umoddi3>:
  800d70:	55                   	push   %ebp
  800d71:	57                   	push   %edi
  800d72:	56                   	push   %esi
  800d73:	53                   	push   %ebx
  800d74:	83 ec 1c             	sub    $0x1c,%esp
  800d77:	8b 54 24 3c          	mov    0x3c(%esp),%edx
  800d7b:	8b 4c 24 30          	mov    0x30(%esp),%ecx
  800d7f:	8b 74 24 34          	mov    0x34(%esp),%esi
  800d83:	8b 7c 24 38          	mov    0x38(%esp),%edi
  800d87:	85 d2                	test   %edx,%edx
  800d89:	89 4c 24 0c          	mov    %ecx,0xc(%esp)
  800d8d:	89 4c 24 08          	mov    %ecx,0x8(%esp)
  800d91:	89 f3                	mov    %esi,%ebx
  800d93:	89 3c 24             	mov    %edi,(%esp)
  800d96:	89 74 24 04          	mov    %esi,0x4(%esp)
  800d9a:	75 1c                	jne    800db8 <__umoddi3+0x48>
  800d9c:	39 f7                	cmp    %esi,%edi
  800d9e:	76 50                	jbe    800df0 <__umoddi3+0x80>
  800da0:	89 c8                	mov    %ecx,%eax
  800da2:	89 f2                	mov    %esi,%edx
  800da4:	f7 f7                	div    %edi
  800da6:	89 d0                	mov    %edx,%eax
  800da8:	31 d2                	xor    %edx,%edx
  800daa:	83 c4 1c             	add    $0x1c,%esp
  800dad:	5b                   	pop    %ebx
  800dae:	5e                   	pop    %esi
  800daf:	5f                   	pop    %edi
  800db0:	5d                   	pop    %ebp
  800db1:	c3                   	ret    
  800db2:	8d b6 00 00 00 00    	lea    0x0(%esi),%esi
  800db8:	39 f2                	cmp    %esi,%edx
  800dba:	89 d0                	mov    %edx,%eax
  800dbc:	77 52                	ja     800e10 <__umoddi3+0xa0>
  800dbe:	0f bd ea             	bsr    %edx,%ebp
  800dc1:	83 f5 1f             	xor    $0x1f,%ebp
  800dc4:	75 5a                	jne    800e20 <__umoddi3+0xb0>
  800dc6:	3b 54 24 04          	cmp    0x4(%esp),%edx
  800dca:	0f 82 e0 00 00 00    	jb     800eb0 <__umoddi3+0x140>
  800dd0:	39 0c 24             	cmp    %ecx,(%esp)
  800dd3:	0f 86 d7 00 00 00    	jbe    800eb0 <__umoddi3+0x140>
  800dd9:	8b 44 24 08          	mov    0x8(%esp),%eax
  800ddd:	8b 54 24 04          	mov    0x4(%esp),%edx
  800de1:	83 c4 1c             	add    $0x1c,%esp
  800de4:	5b                   	pop    %ebx
  800de5:	5e                   	pop    %esi
  800de6:	5f                   	pop    %edi
  800de7:	5d                   	pop    %ebp
  800de8:	c3                   	ret    
  800de9:	8d b4 26 00 00 00 00 	lea    0x0(%esi,%eiz,1),%esi
  800df0:	85 ff                	test   %edi,%edi
  800df2:	89 fd                	mov    %edi,%ebp
  800df4:	75 0b                	jne    800e01 <__umoddi3+0x91>
  800df6:	b8 01 00 00 00       	mov    $0x1,%eax
  800dfb:	31 d2                	xor    %edx,%edx
  800dfd:	f7 f7                	div    %edi
  800dff:	89 c5                	mov    %eax,%ebp
  800e01:	89 f0                	mov    %esi,%eax
  800e03:	31 d2                	xor    %edx,%edx
  800e05:	f7 f5                	div    %ebp
  800e07:	89 c8                	mov    %ecx,%eax
  800e09:	f7 f5                	div    %ebp
  800e0b:	89 d0                	mov    %edx,%eax
  800e0d:	eb 99                	jmp    800da8 <__umoddi3+0x38>
  800e0f:	90                   	nop
  800e10:	89 c8                	mov    %ecx,%eax
  800e12:	89 f2                	mov    %esi,%edx
  800e14:	83 c4 1c             	add    $0x1c,%esp
  800e17:	5b                   	pop    %ebx
  800e18:	5e                   	pop    %esi
  800e19:	5f                   	pop    %edi
  800e1a:	5d                   	pop    %ebp
  800e1b:	c3                   	ret    
  800e1c:	8d 74 26 00          	lea    0x0(%esi,%eiz,1),%esi
  800e20:	8b 34 24             	mov    (%esp),%esi
  800e23:	bf 20 00 00 00       	mov    $0x20,%edi
  800e28:	89 e9                	mov    %ebp,%ecx
  800e2a:	29 ef                	sub    %ebp,%edi
  800e2c:	d3 e0                	shl    %cl,%eax
  800e2e:	89 f9                	mov    %edi,%ecx
  800e30:	89 f2                	mov    %esi,%edx
  800e32:	d3 ea                	shr    %cl,%edx
  800e34:	89 e9                	mov    %ebp,%ecx
  800e36:	09 c2                	or     %eax,%edx
  800e38:	89 d8                	mov    %ebx,%eax
  800e3a:	89 14 24             	mov    %edx,(%esp)
  800e3d:	89 f2                	mov    %esi,%edx
  800e3f:	d3 e2                	shl    %cl,%edx
  800e41:	89 f9                	mov    %edi,%ecx
  800e43:	89 54 24 04          	mov    %edx,0x4(%esp)
  800e47:	8b 54 24 0c          	mov    0xc(%esp),%edx
  800e4b:	d3 e8                	shr    %cl,%eax
  800e4d:	89 e9                	mov    %ebp,%ecx
  800e4f:	89 c6                	mov    %eax,%esi
  800e51:	d3 e3                	shl    %cl,%ebx
  800e53:	89 f9                	mov    %edi,%ecx
  800e55:	89 d0                	mov    %edx,%eax
  800e57:	d3 e8                	shr    %cl,%eax
  800e59:	89 e9                	mov    %ebp,%ecx
  800e5b:	09 d8                	or     %ebx,%eax
  800e5d:	89 d3                	mov    %edx,%ebx
  800e5f:	89 f2                	mov    %esi,%edx
  800e61:	f7 34 24             	divl   (%esp)
  800e64:	89 d6                	mov    %edx,%esi
  800e66:	d3 e3                	shl    %cl,%ebx
  800e68:	f7 64 24 04          	mull   0x4(%esp)
  800e6c:	39 d6                	cmp    %edx,%esi
  800e6e:	89 5c 24 08          	mov    %ebx,0x8(%esp)
  800e72:	89 d1                	mov    %edx,%ecx
  800e74:	89 c3                	mov    %eax,%ebx
  800e76:	72 08                	jb     800e80 <__umoddi3+0x110>
  800e78:	75 11                	jne    800e8b <__umoddi3+0x11b>
  800e7a:	39 44 24 08          	cmp    %eax,0x8(%esp)
  800e7e:	73 0b                	jae    800e8b <__umoddi3+0x11b>
  800e80:	2b 44 24 04          	sub    0x4(%esp),%eax
  800e84:	1b 14 24             	sbb    (%esp),%edx
  800e87:	89 d1                	mov    %edx,%ecx
  800e89:	89 c3                	mov    %eax,%ebx
  800e8b:	8b 54 24 08          	mov    0x8(%esp),%edx
  800e8f:	29 da                	sub    %ebx,%edx
  800e91:	19 ce                	sbb    %ecx,%esi
  800e93:	89 f9                	mov    %edi,%ecx
  800e95:	89 f0                	mov    %esi,%eax
  800e97:	d3 e0                	shl    %cl,%eax
  800e99:	89 e9                	mov    %ebp,%ecx
  800e9b:	d3 ea                	shr    %cl,%edx
  800e9d:	89 e9                	mov    %ebp,%ecx
  800e9f:	d3 ee                	shr    %cl,%esi
  800ea1:	09 d0                	or     %edx,%eax
  800ea3:	89 f2                	mov    %esi,%edx
  800ea5:	83 c4 1c             	add    $0x1c,%esp
  800ea8:	5b                   	pop    %ebx
  800ea9:	5e                   	pop    %esi
  800eaa:	5f                   	pop    %edi
  800eab:	5d                   	pop    %ebp
  800eac:	c3                   	ret    
  800ead:	8d 76 00             	lea    0x0(%esi),%esi
  800eb0:	29 f9                	sub    %edi,%ecx
  800eb2:	19 d6                	sbb    %edx,%esi
  800eb4:	89 74 24 04          	mov    %esi,0x4(%esp)
  800eb8:	89 4c 24 08          	mov    %ecx,0x8(%esp)
  800ebc:	e9 18 ff ff ff       	jmp    800dd9 <__umoddi3+0x69>
