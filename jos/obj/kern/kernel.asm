
obj/kern/kernel:     file format elf32-i386


Disassembly of section .text:

f0100000 <_start+0xeffffff4>:
f0100000:	02 b0 ad 1b 00 00    	add    0x1bad(%eax),%dh
f0100006:	00 00                	add    %al,(%eax)
f0100008:	fe 4f 52             	decb   0x52(%edi)
f010000b:	e4 66                	in     $0x66,%al

f010000c <entry>:
.globl		_start
_start = RELOC(entry)

.globl entry
entry:
	movw	$0x1234,0x472			# warm boot
f010000c:	66 c7 05 72 04 00 00 	movw   $0x1234,0x472
f0100013:	34 12 
	# sufficient until we set up our real page table in mem_init
	# in lab 2.

	# Load the physical address of entry_pgdir into cr3.  entry_pgdir
	# is defined in entrypgdir.c.
	movl	$(RELOC(entry_pgdir)), %eax
f0100015:	b8 00 00 11 00       	mov    $0x110000,%eax
	movl	%eax, %cr3
f010001a:	0f 22 d8             	mov    %eax,%cr3
	movl	%cr4,%eax
f010001d:	0f 20 e0             	mov    %cr4,%eax
	orl		$(CR4_PSE),%eax	#Prendo flag del cr4 para Page Size Extension
f0100020:	83 c8 10             	or     $0x10,%eax
	movl	%eax,%cr4	
f0100023:	0f 22 e0             	mov    %eax,%cr4
	# Turn on paging.
	movl	%cr0, %eax
f0100026:	0f 20 c0             	mov    %cr0,%eax
	orl	$(CR0_PE|CR0_PG|CR0_WP), %eax
f0100029:	0d 01 00 01 80       	or     $0x80010001,%eax
	movl	%eax, %cr0
f010002e:	0f 22 c0             	mov    %eax,%cr0

	# Now paging is enabled, but we're still running at a low EIP
	# (why is this okay?).  Jump up above KERNBASE before entering
	# C code.
	mov	$relocated, %eax
f0100031:	b8 38 00 10 f0       	mov    $0xf0100038,%eax
	jmp	*%eax
f0100036:	ff e0                	jmp    *%eax

f0100038 <relocated>:
relocated:

	# Clear the frame pointer register (EBP)
	# so that once we get into debugging C code,
	# stack backtraces will be terminated properly.
	movl	$0x0,%ebp			# nuke frame pointer
f0100038:	bd 00 00 00 00       	mov    $0x0,%ebp

	# Set the stack pointer
	movl	$(bootstacktop),%esp
f010003d:	bc 00 00 11 f0       	mov    $0xf0110000,%esp

	# now to C code
	call	i386_init
f0100042:	e8 6d 01 00 00       	call   f01001b4 <i386_init>

f0100047 <spin>:

	# Should never get here, but in case we do, just spin.
spin:	jmp	spin
f0100047:	eb fe                	jmp    f0100047 <spin>

f0100049 <lcr3>:
	return val;
}

static inline void
lcr3(uint32_t val)
{
f0100049:	55                   	push   %ebp
f010004a:	89 e5                	mov    %esp,%ebp
	asm volatile("movl %0,%%cr3" : : "r" (val));
f010004c:	0f 22 d8             	mov    %eax,%cr3
}
f010004f:	5d                   	pop    %ebp
f0100050:	c3                   	ret    

f0100051 <xchg>:
	return tsc;
}

static inline uint32_t
xchg(volatile uint32_t *addr, uint32_t newval)
{
f0100051:	55                   	push   %ebp
f0100052:	89 e5                	mov    %esp,%ebp
f0100054:	89 c1                	mov    %eax,%ecx
	uint32_t result;

	// The + in "+m" denotes a read-modify-write operand.
	asm volatile("lock; xchgl %0, %1"
f0100056:	89 d0                	mov    %edx,%eax
f0100058:	f0 87 01             	lock xchg %eax,(%ecx)
		     : "+m" (*addr), "=a" (result)
		     : "1" (newval)
		     : "cc");
	return result;
}
f010005b:	5d                   	pop    %ebp
f010005c:	c3                   	ret    

f010005d <_panic>:
 * Panic is called on unresolvable fatal errors.
 * It prints "panic: mesg", and then enters the kernel monitor.
 */
void
_panic(const char *file, int line, const char *fmt,...)
{
f010005d:	55                   	push   %ebp
f010005e:	89 e5                	mov    %esp,%ebp
f0100060:	56                   	push   %esi
f0100061:	53                   	push   %ebx
f0100062:	8b 75 10             	mov    0x10(%ebp),%esi
	va_list ap;

	if (panicstr)
f0100065:	83 3d 00 6f 28 f0 00 	cmpl   $0x0,0xf0286f00
f010006c:	75 3a                	jne    f01000a8 <_panic+0x4b>
		goto dead;
	panicstr = fmt;
f010006e:	89 35 00 6f 28 f0    	mov    %esi,0xf0286f00

	// Be extra sure that the machine is in as reasonable state
	asm volatile("cli; cld");
f0100074:	fa                   	cli    
f0100075:	fc                   	cld    

	va_start(ap, fmt);
f0100076:	8d 5d 14             	lea    0x14(%ebp),%ebx
	cprintf(">>>\n>>> kernel panic on CPU %d at %s:%d: ", cpunum(), file, line);
f0100079:	e8 90 55 00 00       	call   f010560e <cpunum>
f010007e:	ff 75 0c             	pushl  0xc(%ebp)
f0100081:	ff 75 08             	pushl  0x8(%ebp)
f0100084:	50                   	push   %eax
f0100085:	68 c0 5c 10 f0       	push   $0xf0105cc0
f010008a:	e8 e0 37 00 00       	call   f010386f <cprintf>
	vcprintf(fmt, ap);
f010008f:	83 c4 08             	add    $0x8,%esp
f0100092:	53                   	push   %ebx
f0100093:	56                   	push   %esi
f0100094:	e8 b0 37 00 00       	call   f0103849 <vcprintf>
	cprintf("\n>>>\n");
f0100099:	c7 04 24 34 5d 10 f0 	movl   $0xf0105d34,(%esp)
f01000a0:	e8 ca 37 00 00       	call   f010386f <cprintf>
	va_end(ap);
f01000a5:	83 c4 10             	add    $0x10,%esp

dead:
	/* break into the kernel monitor */
	while (1)
		monitor(NULL);
f01000a8:	83 ec 0c             	sub    $0xc,%esp
f01000ab:	6a 00                	push   $0x0
f01000ad:	e8 c4 0a 00 00       	call   f0100b76 <monitor>
f01000b2:	83 c4 10             	add    $0x10,%esp
f01000b5:	eb f1                	jmp    f01000a8 <_panic+0x4b>

f01000b7 <_kaddr>:
 * virtual address.  It panics if you pass an invalid physical address. */
#define KADDR(pa) _kaddr(__FILE__, __LINE__, pa)

static inline void*
_kaddr(const char *file, int line, physaddr_t pa)
{
f01000b7:	55                   	push   %ebp
f01000b8:	89 e5                	mov    %esp,%ebp
f01000ba:	53                   	push   %ebx
f01000bb:	83 ec 04             	sub    $0x4,%esp
	if (PGNUM(pa) >= npages)
f01000be:	89 cb                	mov    %ecx,%ebx
f01000c0:	c1 eb 0c             	shr    $0xc,%ebx
f01000c3:	3b 1d 08 6f 28 f0    	cmp    0xf0286f08,%ebx
f01000c9:	72 0d                	jb     f01000d8 <_kaddr+0x21>
		_panic(file, line, "KADDR called with invalid pa %08lx", pa);
f01000cb:	51                   	push   %ecx
f01000cc:	68 ec 5c 10 f0       	push   $0xf0105cec
f01000d1:	52                   	push   %edx
f01000d2:	50                   	push   %eax
f01000d3:	e8 85 ff ff ff       	call   f010005d <_panic>
	return (void *)(pa + KERNBASE);
f01000d8:	8d 81 00 00 00 f0    	lea    -0x10000000(%ecx),%eax
}
f01000de:	8b 5d fc             	mov    -0x4(%ebp),%ebx
f01000e1:	c9                   	leave  
f01000e2:	c3                   	ret    

f01000e3 <_paddr>:
#define PADDR(kva) _paddr(__FILE__, __LINE__, kva)

static inline physaddr_t
_paddr(const char *file, int line, void *kva)
{
	if ((uint32_t)kva < KERNBASE)
f01000e3:	81 f9 ff ff ff ef    	cmp    $0xefffffff,%ecx
f01000e9:	77 13                	ja     f01000fe <_paddr+0x1b>
 */
#define PADDR(kva) _paddr(__FILE__, __LINE__, kva)

static inline physaddr_t
_paddr(const char *file, int line, void *kva)
{
f01000eb:	55                   	push   %ebp
f01000ec:	89 e5                	mov    %esp,%ebp
f01000ee:	83 ec 08             	sub    $0x8,%esp
	if ((uint32_t)kva < KERNBASE)
		_panic(file, line, "PADDR called with invalid kva %08lx", kva);
f01000f1:	51                   	push   %ecx
f01000f2:	68 10 5d 10 f0       	push   $0xf0105d10
f01000f7:	52                   	push   %edx
f01000f8:	50                   	push   %eax
f01000f9:	e8 5f ff ff ff       	call   f010005d <_panic>
	return (physaddr_t)kva - KERNBASE;
f01000fe:	8d 81 00 00 00 10    	lea    0x10000000(%ecx),%eax
}
f0100104:	c3                   	ret    

f0100105 <boot_aps>:
void *mpentry_kstack;

// Start the non-boot (AP) processors.
static void
boot_aps(void)
{
f0100105:	55                   	push   %ebp
f0100106:	89 e5                	mov    %esp,%ebp
f0100108:	56                   	push   %esi
f0100109:	53                   	push   %ebx
	extern unsigned char mpentry_start[], mpentry_end[];
	void *code;
	struct CpuInfo *c;

	// Write entry code to unused memory at MPENTRY_PADDR
	code = KADDR(MPENTRY_PADDR);
f010010a:	b9 00 70 00 00       	mov    $0x7000,%ecx
f010010f:	ba 61 00 00 00       	mov    $0x61,%edx
f0100114:	b8 3a 5d 10 f0       	mov    $0xf0105d3a,%eax
f0100119:	e8 99 ff ff ff       	call   f01000b7 <_kaddr>
f010011e:	89 c6                	mov    %eax,%esi
	memmove(code, mpentry_start, mpentry_end - mpentry_start);
f0100120:	83 ec 04             	sub    $0x4,%esp
f0100123:	b8 f2 51 10 f0       	mov    $0xf01051f2,%eax
f0100128:	2d 78 51 10 f0       	sub    $0xf0105178,%eax
f010012d:	50                   	push   %eax
f010012e:	68 78 51 10 f0       	push   $0xf0105178
f0100133:	56                   	push   %esi
f0100134:	e8 8e 4e 00 00       	call   f0104fc7 <memmove>

	// Boot each AP one at a time
	for (c = cpus; c < cpus + ncpu; c++) {
f0100139:	83 c4 10             	add    $0x10,%esp
f010013c:	bb 20 70 28 f0       	mov    $0xf0287020,%ebx
f0100141:	eb 5a                	jmp    f010019d <boot_aps+0x98>
		if (c == cpus + cpunum())  // We've started already.
f0100143:	e8 c6 54 00 00       	call   f010560e <cpunum>
f0100148:	6b c0 74             	imul   $0x74,%eax,%eax
f010014b:	05 20 70 28 f0       	add    $0xf0287020,%eax
f0100150:	39 c3                	cmp    %eax,%ebx
f0100152:	74 46                	je     f010019a <boot_aps+0x95>
			continue;

		// Tell mpentry.S what stack to use 
		mpentry_kstack = percpu_kstacks[c - cpus] + KSTKSIZE;
f0100154:	89 d8                	mov    %ebx,%eax
f0100156:	2d 20 70 28 f0       	sub    $0xf0287020,%eax
f010015b:	c1 f8 02             	sar    $0x2,%eax
f010015e:	69 c0 35 c2 72 4f    	imul   $0x4f72c235,%eax,%eax
f0100164:	c1 e0 0f             	shl    $0xf,%eax
f0100167:	05 00 00 29 f0       	add    $0xf0290000,%eax
f010016c:	a3 04 6f 28 f0       	mov    %eax,0xf0286f04
		// Start the CPU at mpentry_start
		lapic_startap(c->cpu_id, PADDR(code));
f0100171:	89 f1                	mov    %esi,%ecx
f0100173:	ba 6c 00 00 00       	mov    $0x6c,%edx
f0100178:	b8 3a 5d 10 f0       	mov    $0xf0105d3a,%eax
f010017d:	e8 61 ff ff ff       	call   f01000e3 <_paddr>
f0100182:	83 ec 08             	sub    $0x8,%esp
f0100185:	50                   	push   %eax
f0100186:	0f b6 03             	movzbl (%ebx),%eax
f0100189:	50                   	push   %eax
f010018a:	e8 e8 55 00 00       	call   f0105777 <lapic_startap>
		// Wait for the CPU to finish some basic setup in mp_main()
		while(c->cpu_status != CPU_STARTED)
f010018f:	83 c4 10             	add    $0x10,%esp
f0100192:	8b 43 04             	mov    0x4(%ebx),%eax
f0100195:	83 f8 01             	cmp    $0x1,%eax
f0100198:	75 f8                	jne    f0100192 <boot_aps+0x8d>
	// Write entry code to unused memory at MPENTRY_PADDR
	code = KADDR(MPENTRY_PADDR);
	memmove(code, mpentry_start, mpentry_end - mpentry_start);

	// Boot each AP one at a time
	for (c = cpus; c < cpus + ncpu; c++) {
f010019a:	83 c3 74             	add    $0x74,%ebx
f010019d:	6b 05 c4 73 28 f0 74 	imul   $0x74,0xf02873c4,%eax
f01001a4:	05 20 70 28 f0       	add    $0xf0287020,%eax
f01001a9:	39 c3                	cmp    %eax,%ebx
f01001ab:	72 96                	jb     f0100143 <boot_aps+0x3e>
		lapic_startap(c->cpu_id, PADDR(code));
		// Wait for the CPU to finish some basic setup in mp_main()
		while(c->cpu_status != CPU_STARTED)
			;
	}
}
f01001ad:	8d 65 f8             	lea    -0x8(%ebp),%esp
f01001b0:	5b                   	pop    %ebx
f01001b1:	5e                   	pop    %esi
f01001b2:	5d                   	pop    %ebp
f01001b3:	c3                   	ret    

f01001b4 <i386_init>:
static void boot_aps(void);


void
i386_init(void)
{
f01001b4:	55                   	push   %ebp
f01001b5:	89 e5                	mov    %esp,%ebp
f01001b7:	83 ec 0c             	sub    $0xc,%esp
	extern char __bss_start[], end[];

	// Before doing anything else, complete the ELF loading process.
	// Clear the uninitialized global data (BSS) section of our program.
	// This ensures that all static/global variables start out zero.
	memset(__bss_start, 0, end - __bss_start);
f01001ba:	b8 08 80 2c f0       	mov    $0xf02c8008,%eax
f01001bf:	2d 00 50 28 f0       	sub    $0xf0285000,%eax
f01001c4:	50                   	push   %eax
f01001c5:	6a 00                	push   $0x0
f01001c7:	68 00 50 28 f0       	push   $0xf0285000
f01001cc:	e8 a8 4d 00 00       	call   f0104f79 <memset>

	// Initialize the console.
	// Can't call cprintf until after we do this!
	cons_init();
f01001d1:	e8 cd 06 00 00       	call   f01008a3 <cons_init>

	cprintf("6828 decimal is %o octal!\n", 6828);
f01001d6:	83 c4 08             	add    $0x8,%esp
f01001d9:	68 ac 1a 00 00       	push   $0x1aac
f01001de:	68 46 5d 10 f0       	push   $0xf0105d46
f01001e3:	e8 87 36 00 00       	call   f010386f <cprintf>

	// Lab 2 memory management initialization functions
	mem_init();
f01001e8:	e8 14 29 00 00       	call   f0102b01 <mem_init>

	// Lab 3 user environment initialization functions
	env_init();
f01001ed:	e8 ba 2f 00 00       	call   f01031ac <env_init>
	trap_init();
f01001f2:	e8 68 37 00 00       	call   f010395f <trap_init>

	// Lab 4 multiprocessor initialization functions
	mp_init();
f01001f7:	e8 4e 52 00 00       	call   f010544a <mp_init>
	lapic_init();
f01001fc:	e8 28 54 00 00       	call   f0105629 <lapic_init>

	// Lab 4 multitasking initialization functions
	pic_init();
f0100201:	e8 33 35 00 00       	call   f0103739 <pic_init>

	// Acquire the big kernel lock before waking up APs
	// Your code here:

	// Starting non-boot CPUs
	boot_aps();
f0100206:	e8 fa fe ff ff       	call   f0100105 <boot_aps>

#if defined(TEST)
	// Don't touch -- used by grading script!
	ENV_CREATE(TEST, ENV_TYPE_USER);
f010020b:	83 c4 08             	add    $0x8,%esp
f010020e:	6a 00                	push   $0x0
f0100210:	68 54 14 11 f0       	push   $0xf0111454
f0100215:	e8 df 30 00 00       	call   f01032f9 <env_create>
	ENV_CREATE(user_hello, ENV_TYPE_USER);
	ENV_CREATE(user_hello, ENV_TYPE_USER);
#endif // TEST*
	// Eliminar esta llamada una vez completada la parte 1
	// e implementado sched_yield().
	env_run(&envs[0]);
f010021a:	83 c4 04             	add    $0x4,%esp
f010021d:	ff 35 44 52 28 f0    	pushl  0xf0285244
f0100223:	e8 0c 33 00 00       	call   f0103534 <env_run>

f0100228 <mp_main>:
}

// Setup code for APs
void
mp_main(void)
{
f0100228:	55                   	push   %ebp
f0100229:	89 e5                	mov    %esp,%ebp
f010022b:	83 ec 08             	sub    $0x8,%esp
	// We are in high EIP now, safe to switch to kern_pgdir 
	lcr3(PADDR(kern_pgdir));
f010022e:	8b 0d 0c 6f 28 f0    	mov    0xf0286f0c,%ecx
f0100234:	ba 78 00 00 00       	mov    $0x78,%edx
f0100239:	b8 3a 5d 10 f0       	mov    $0xf0105d3a,%eax
f010023e:	e8 a0 fe ff ff       	call   f01000e3 <_paddr>
f0100243:	e8 01 fe ff ff       	call   f0100049 <lcr3>
	cprintf("SMP: CPU %d starting\n", cpunum());
f0100248:	e8 c1 53 00 00       	call   f010560e <cpunum>
f010024d:	83 ec 08             	sub    $0x8,%esp
f0100250:	50                   	push   %eax
f0100251:	68 61 5d 10 f0       	push   $0xf0105d61
f0100256:	e8 14 36 00 00       	call   f010386f <cprintf>

	lapic_init();
f010025b:	e8 c9 53 00 00       	call   f0105629 <lapic_init>
	env_init_percpu();
f0100260:	e8 13 2f 00 00       	call   f0103178 <env_init_percpu>
	trap_init_percpu();
f0100265:	e8 8b 36 00 00       	call   f01038f5 <trap_init_percpu>
	xchg(&thiscpu->cpu_status, CPU_STARTED); // tell boot_aps() we're up
f010026a:	e8 9f 53 00 00       	call   f010560e <cpunum>
f010026f:	6b c0 74             	imul   $0x74,%eax,%eax
f0100272:	05 24 70 28 f0       	add    $0xf0287024,%eax
f0100277:	ba 01 00 00 00       	mov    $0x1,%edx
f010027c:	e8 d0 fd ff ff       	call   f0100051 <xchg>
f0100281:	83 c4 10             	add    $0x10,%esp
f0100284:	eb fe                	jmp    f0100284 <mp_main+0x5c>

f0100286 <_warn>:
}

/* like panic, but don't */
void
_warn(const char *file, int line, const char *fmt,...)
{
f0100286:	55                   	push   %ebp
f0100287:	89 e5                	mov    %esp,%ebp
f0100289:	53                   	push   %ebx
f010028a:	83 ec 08             	sub    $0x8,%esp
	va_list ap;

	va_start(ap, fmt);
f010028d:	8d 5d 14             	lea    0x14(%ebp),%ebx
	cprintf("kernel warning at %s:%d: ", file, line);
f0100290:	ff 75 0c             	pushl  0xc(%ebp)
f0100293:	ff 75 08             	pushl  0x8(%ebp)
f0100296:	68 77 5d 10 f0       	push   $0xf0105d77
f010029b:	e8 cf 35 00 00       	call   f010386f <cprintf>
	vcprintf(fmt, ap);
f01002a0:	83 c4 08             	add    $0x8,%esp
f01002a3:	53                   	push   %ebx
f01002a4:	ff 75 10             	pushl  0x10(%ebp)
f01002a7:	e8 9d 35 00 00       	call   f0103849 <vcprintf>
	cprintf("\n");
f01002ac:	c7 04 24 cf 70 10 f0 	movl   $0xf01070cf,(%esp)
f01002b3:	e8 b7 35 00 00       	call   f010386f <cprintf>
	va_end(ap);
}
f01002b8:	83 c4 10             	add    $0x10,%esp
f01002bb:	8b 5d fc             	mov    -0x4(%ebp),%ebx
f01002be:	c9                   	leave  
f01002bf:	c3                   	ret    

f01002c0 <inb>:
	asm volatile("int3");
}

static inline uint8_t
inb(int port)
{
f01002c0:	55                   	push   %ebp
f01002c1:	89 e5                	mov    %esp,%ebp
	uint8_t data;
	asm volatile("inb %w1,%0" : "=a" (data) : "d" (port));
f01002c3:	89 c2                	mov    %eax,%edx
f01002c5:	ec                   	in     (%dx),%al
	return data;
}
f01002c6:	5d                   	pop    %ebp
f01002c7:	c3                   	ret    

f01002c8 <outb>:
		     : "memory", "cc");
}

static inline void
outb(int port, uint8_t data)
{
f01002c8:	55                   	push   %ebp
f01002c9:	89 e5                	mov    %esp,%ebp
f01002cb:	89 c1                	mov    %eax,%ecx
f01002cd:	89 d0                	mov    %edx,%eax
	asm volatile("outb %0,%w1" : : "a" (data), "d" (port));
f01002cf:	89 ca                	mov    %ecx,%edx
f01002d1:	ee                   	out    %al,(%dx)
}
f01002d2:	5d                   	pop    %ebp
f01002d3:	c3                   	ret    

f01002d4 <delay>:
static void cons_putc(int c);

// Stupid I/O delay routine necessitated by historical PC design flaws
static void
delay(void)
{
f01002d4:	55                   	push   %ebp
f01002d5:	89 e5                	mov    %esp,%ebp
	inb(0x84);
f01002d7:	b8 84 00 00 00       	mov    $0x84,%eax
f01002dc:	e8 df ff ff ff       	call   f01002c0 <inb>
	inb(0x84);
f01002e1:	b8 84 00 00 00       	mov    $0x84,%eax
f01002e6:	e8 d5 ff ff ff       	call   f01002c0 <inb>
	inb(0x84);
f01002eb:	b8 84 00 00 00       	mov    $0x84,%eax
f01002f0:	e8 cb ff ff ff       	call   f01002c0 <inb>
	inb(0x84);
f01002f5:	b8 84 00 00 00       	mov    $0x84,%eax
f01002fa:	e8 c1 ff ff ff       	call   f01002c0 <inb>
}
f01002ff:	5d                   	pop    %ebp
f0100300:	c3                   	ret    

f0100301 <serial_proc_data>:

static bool serial_exists;

static int
serial_proc_data(void)
{
f0100301:	55                   	push   %ebp
f0100302:	89 e5                	mov    %esp,%ebp
	if (!(inb(COM1+COM_LSR) & COM_LSR_DATA))
f0100304:	b8 fd 03 00 00       	mov    $0x3fd,%eax
f0100309:	e8 b2 ff ff ff       	call   f01002c0 <inb>
f010030e:	a8 01                	test   $0x1,%al
f0100310:	74 0f                	je     f0100321 <serial_proc_data+0x20>
		return -1;
	return inb(COM1+COM_RX);
f0100312:	b8 f8 03 00 00       	mov    $0x3f8,%eax
f0100317:	e8 a4 ff ff ff       	call   f01002c0 <inb>
f010031c:	0f b6 c0             	movzbl %al,%eax
f010031f:	eb 05                	jmp    f0100326 <serial_proc_data+0x25>

static int
serial_proc_data(void)
{
	if (!(inb(COM1+COM_LSR) & COM_LSR_DATA))
		return -1;
f0100321:	b8 ff ff ff ff       	mov    $0xffffffff,%eax
	return inb(COM1+COM_RX);
}
f0100326:	5d                   	pop    %ebp
f0100327:	c3                   	ret    

f0100328 <serial_putc>:
		cons_intr(serial_proc_data);
}

static void
serial_putc(int c)
{
f0100328:	55                   	push   %ebp
f0100329:	89 e5                	mov    %esp,%ebp
f010032b:	56                   	push   %esi
f010032c:	53                   	push   %ebx
f010032d:	89 c6                	mov    %eax,%esi
	int i;

	for (i = 0;
f010032f:	bb 00 00 00 00       	mov    $0x0,%ebx
f0100334:	eb 08                	jmp    f010033e <serial_putc+0x16>
	     !(inb(COM1 + COM_LSR) & COM_LSR_TXRDY) && i < 12800;
	     i++)
		delay();
f0100336:	e8 99 ff ff ff       	call   f01002d4 <delay>
{
	int i;

	for (i = 0;
	     !(inb(COM1 + COM_LSR) & COM_LSR_TXRDY) && i < 12800;
	     i++)
f010033b:	83 c3 01             	add    $0x1,%ebx
serial_putc(int c)
{
	int i;

	for (i = 0;
	     !(inb(COM1 + COM_LSR) & COM_LSR_TXRDY) && i < 12800;
f010033e:	b8 fd 03 00 00       	mov    $0x3fd,%eax
f0100343:	e8 78 ff ff ff       	call   f01002c0 <inb>
f0100348:	a8 20                	test   $0x20,%al
f010034a:	75 08                	jne    f0100354 <serial_putc+0x2c>
f010034c:	81 fb ff 31 00 00    	cmp    $0x31ff,%ebx
f0100352:	7e e2                	jle    f0100336 <serial_putc+0xe>
	     i++)
		delay();

	outb(COM1 + COM_TX, c);
f0100354:	89 f0                	mov    %esi,%eax
f0100356:	0f b6 d0             	movzbl %al,%edx
f0100359:	b8 f8 03 00 00       	mov    $0x3f8,%eax
f010035e:	e8 65 ff ff ff       	call   f01002c8 <outb>
}
f0100363:	5b                   	pop    %ebx
f0100364:	5e                   	pop    %esi
f0100365:	5d                   	pop    %ebp
f0100366:	c3                   	ret    

f0100367 <serial_init>:

static void
serial_init(void)
{
f0100367:	55                   	push   %ebp
f0100368:	89 e5                	mov    %esp,%ebp
	// Turn off the FIFO
	outb(COM1+COM_FCR, 0);
f010036a:	ba 00 00 00 00       	mov    $0x0,%edx
f010036f:	b8 fa 03 00 00       	mov    $0x3fa,%eax
f0100374:	e8 4f ff ff ff       	call   f01002c8 <outb>

	// Set speed; requires DLAB latch
	outb(COM1+COM_LCR, COM_LCR_DLAB);
f0100379:	ba 80 00 00 00       	mov    $0x80,%edx
f010037e:	b8 fb 03 00 00       	mov    $0x3fb,%eax
f0100383:	e8 40 ff ff ff       	call   f01002c8 <outb>
	outb(COM1+COM_DLL, (uint8_t) (115200 / 9600));
f0100388:	ba 0c 00 00 00       	mov    $0xc,%edx
f010038d:	b8 f8 03 00 00       	mov    $0x3f8,%eax
f0100392:	e8 31 ff ff ff       	call   f01002c8 <outb>
	outb(COM1+COM_DLM, 0);
f0100397:	ba 00 00 00 00       	mov    $0x0,%edx
f010039c:	b8 f9 03 00 00       	mov    $0x3f9,%eax
f01003a1:	e8 22 ff ff ff       	call   f01002c8 <outb>

	// 8 data bits, 1 stop bit, parity off; turn off DLAB latch
	outb(COM1+COM_LCR, COM_LCR_WLEN8 & ~COM_LCR_DLAB);
f01003a6:	ba 03 00 00 00       	mov    $0x3,%edx
f01003ab:	b8 fb 03 00 00       	mov    $0x3fb,%eax
f01003b0:	e8 13 ff ff ff       	call   f01002c8 <outb>

	// No modem controls
	outb(COM1+COM_MCR, 0);
f01003b5:	ba 00 00 00 00       	mov    $0x0,%edx
f01003ba:	b8 fc 03 00 00       	mov    $0x3fc,%eax
f01003bf:	e8 04 ff ff ff       	call   f01002c8 <outb>
	// Enable rcv interrupts
	outb(COM1+COM_IER, COM_IER_RDI);
f01003c4:	ba 01 00 00 00       	mov    $0x1,%edx
f01003c9:	b8 f9 03 00 00       	mov    $0x3f9,%eax
f01003ce:	e8 f5 fe ff ff       	call   f01002c8 <outb>

	// Clear any preexisting overrun indications and interrupts
	// Serial port doesn't exist if COM_LSR returns 0xFF
	serial_exists = (inb(COM1+COM_LSR) != 0xFF);
f01003d3:	b8 fd 03 00 00       	mov    $0x3fd,%eax
f01003d8:	e8 e3 fe ff ff       	call   f01002c0 <inb>
f01003dd:	3c ff                	cmp    $0xff,%al
f01003df:	0f 95 05 34 52 28 f0 	setne  0xf0285234
	(void) inb(COM1+COM_IIR);
f01003e6:	b8 fa 03 00 00       	mov    $0x3fa,%eax
f01003eb:	e8 d0 fe ff ff       	call   f01002c0 <inb>
	(void) inb(COM1+COM_RX);
f01003f0:	b8 f8 03 00 00       	mov    $0x3f8,%eax
f01003f5:	e8 c6 fe ff ff       	call   f01002c0 <inb>

}
f01003fa:	5d                   	pop    %ebp
f01003fb:	c3                   	ret    

f01003fc <lpt_putc>:
// For information on PC parallel port programming, see the class References
// page.

static void
lpt_putc(int c)
{
f01003fc:	55                   	push   %ebp
f01003fd:	89 e5                	mov    %esp,%ebp
f01003ff:	56                   	push   %esi
f0100400:	53                   	push   %ebx
f0100401:	89 c6                	mov    %eax,%esi
	int i;

	for (i = 0; !(inb(0x378+1) & 0x80) && i < 12800; i++)
f0100403:	bb 00 00 00 00       	mov    $0x0,%ebx
f0100408:	eb 08                	jmp    f0100412 <lpt_putc+0x16>
		delay();
f010040a:	e8 c5 fe ff ff       	call   f01002d4 <delay>
static void
lpt_putc(int c)
{
	int i;

	for (i = 0; !(inb(0x378+1) & 0x80) && i < 12800; i++)
f010040f:	83 c3 01             	add    $0x1,%ebx
f0100412:	b8 79 03 00 00       	mov    $0x379,%eax
f0100417:	e8 a4 fe ff ff       	call   f01002c0 <inb>
f010041c:	81 fb ff 31 00 00    	cmp    $0x31ff,%ebx
f0100422:	7f 04                	jg     f0100428 <lpt_putc+0x2c>
f0100424:	84 c0                	test   %al,%al
f0100426:	79 e2                	jns    f010040a <lpt_putc+0xe>
		delay();
	outb(0x378+0, c);
f0100428:	89 f0                	mov    %esi,%eax
f010042a:	0f b6 d0             	movzbl %al,%edx
f010042d:	b8 78 03 00 00       	mov    $0x378,%eax
f0100432:	e8 91 fe ff ff       	call   f01002c8 <outb>
	outb(0x378+2, 0x08|0x04|0x01);
f0100437:	ba 0d 00 00 00       	mov    $0xd,%edx
f010043c:	b8 7a 03 00 00       	mov    $0x37a,%eax
f0100441:	e8 82 fe ff ff       	call   f01002c8 <outb>
	outb(0x378+2, 0x08);
f0100446:	ba 08 00 00 00       	mov    $0x8,%edx
f010044b:	b8 7a 03 00 00       	mov    $0x37a,%eax
f0100450:	e8 73 fe ff ff       	call   f01002c8 <outb>
}
f0100455:	5b                   	pop    %ebx
f0100456:	5e                   	pop    %esi
f0100457:	5d                   	pop    %ebp
f0100458:	c3                   	ret    

f0100459 <cga_init>:
static uint16_t *crt_buf;
static uint16_t crt_pos;

static void
cga_init(void)
{
f0100459:	55                   	push   %ebp
f010045a:	89 e5                	mov    %esp,%ebp
f010045c:	57                   	push   %edi
f010045d:	56                   	push   %esi
f010045e:	53                   	push   %ebx
f010045f:	83 ec 04             	sub    $0x4,%esp
	volatile uint16_t *cp;
	uint16_t was;
	unsigned pos;

	cp = (uint16_t*) (KERNBASE + CGA_BUF);
	was = *cp;
f0100462:	0f b7 15 00 80 0b f0 	movzwl 0xf00b8000,%edx
	*cp = (uint16_t) 0xA55A;
f0100469:	66 c7 05 00 80 0b f0 	movw   $0xa55a,0xf00b8000
f0100470:	5a a5 
	if (*cp != 0xA55A) {
f0100472:	0f b7 05 00 80 0b f0 	movzwl 0xf00b8000,%eax
f0100479:	66 3d 5a a5          	cmp    $0xa55a,%ax
f010047d:	74 13                	je     f0100492 <cga_init+0x39>
		cp = (uint16_t*) (KERNBASE + MONO_BUF);
		addr_6845 = MONO_BASE;
f010047f:	c7 05 30 52 28 f0 b4 	movl   $0x3b4,0xf0285230
f0100486:	03 00 00 

	cp = (uint16_t*) (KERNBASE + CGA_BUF);
	was = *cp;
	*cp = (uint16_t) 0xA55A;
	if (*cp != 0xA55A) {
		cp = (uint16_t*) (KERNBASE + MONO_BUF);
f0100489:	c7 45 f0 00 00 0b f0 	movl   $0xf00b0000,-0x10(%ebp)
f0100490:	eb 18                	jmp    f01004aa <cga_init+0x51>
		addr_6845 = MONO_BASE;
	} else {
		*cp = was;
f0100492:	66 89 15 00 80 0b f0 	mov    %dx,0xf00b8000
		addr_6845 = CGA_BASE;
f0100499:	c7 05 30 52 28 f0 d4 	movl   $0x3d4,0xf0285230
f01004a0:	03 00 00 
{
	volatile uint16_t *cp;
	uint16_t was;
	unsigned pos;

	cp = (uint16_t*) (KERNBASE + CGA_BUF);
f01004a3:	c7 45 f0 00 80 0b f0 	movl   $0xf00b8000,-0x10(%ebp)
		*cp = was;
		addr_6845 = CGA_BASE;
	}

	/* Extract cursor location */
	outb(addr_6845, 14);
f01004aa:	8b 35 30 52 28 f0    	mov    0xf0285230,%esi
f01004b0:	ba 0e 00 00 00       	mov    $0xe,%edx
f01004b5:	89 f0                	mov    %esi,%eax
f01004b7:	e8 0c fe ff ff       	call   f01002c8 <outb>
	pos = inb(addr_6845 + 1) << 8;
f01004bc:	8d 7e 01             	lea    0x1(%esi),%edi
f01004bf:	89 f8                	mov    %edi,%eax
f01004c1:	e8 fa fd ff ff       	call   f01002c0 <inb>
f01004c6:	0f b6 d8             	movzbl %al,%ebx
f01004c9:	c1 e3 08             	shl    $0x8,%ebx
	outb(addr_6845, 15);
f01004cc:	ba 0f 00 00 00       	mov    $0xf,%edx
f01004d1:	89 f0                	mov    %esi,%eax
f01004d3:	e8 f0 fd ff ff       	call   f01002c8 <outb>
	pos |= inb(addr_6845 + 1);
f01004d8:	89 f8                	mov    %edi,%eax
f01004da:	e8 e1 fd ff ff       	call   f01002c0 <inb>

	crt_buf = (uint16_t*) cp;
f01004df:	8b 4d f0             	mov    -0x10(%ebp),%ecx
f01004e2:	89 0d 2c 52 28 f0    	mov    %ecx,0xf028522c
	crt_pos = pos;
f01004e8:	0f b6 c0             	movzbl %al,%eax
f01004eb:	09 c3                	or     %eax,%ebx
f01004ed:	66 89 1d 28 52 28 f0 	mov    %bx,0xf0285228
}
f01004f4:	83 c4 04             	add    $0x4,%esp
f01004f7:	5b                   	pop    %ebx
f01004f8:	5e                   	pop    %esi
f01004f9:	5f                   	pop    %edi
f01004fa:	5d                   	pop    %ebp
f01004fb:	c3                   	ret    

f01004fc <cons_intr>:

// called by device interrupt routines to feed input characters
// into the circular console input buffer.
static void
cons_intr(int (*proc)(void))
{
f01004fc:	55                   	push   %ebp
f01004fd:	89 e5                	mov    %esp,%ebp
f01004ff:	53                   	push   %ebx
f0100500:	83 ec 04             	sub    $0x4,%esp
f0100503:	89 c3                	mov    %eax,%ebx
	int c;

	while ((c = (*proc)()) != -1) {
f0100505:	eb 2b                	jmp    f0100532 <cons_intr+0x36>
		if (c == 0)
f0100507:	85 c0                	test   %eax,%eax
f0100509:	74 27                	je     f0100532 <cons_intr+0x36>
			continue;
		cons.buf[cons.wpos++] = c;
f010050b:	8b 0d 24 52 28 f0    	mov    0xf0285224,%ecx
f0100511:	8d 51 01             	lea    0x1(%ecx),%edx
f0100514:	89 15 24 52 28 f0    	mov    %edx,0xf0285224
f010051a:	88 81 20 50 28 f0    	mov    %al,-0xfd7afe0(%ecx)
		if (cons.wpos == CONSBUFSIZE)
f0100520:	81 fa 00 02 00 00    	cmp    $0x200,%edx
f0100526:	75 0a                	jne    f0100532 <cons_intr+0x36>
			cons.wpos = 0;
f0100528:	c7 05 24 52 28 f0 00 	movl   $0x0,0xf0285224
f010052f:	00 00 00 
static void
cons_intr(int (*proc)(void))
{
	int c;

	while ((c = (*proc)()) != -1) {
f0100532:	ff d3                	call   *%ebx
f0100534:	83 f8 ff             	cmp    $0xffffffff,%eax
f0100537:	75 ce                	jne    f0100507 <cons_intr+0xb>
			continue;
		cons.buf[cons.wpos++] = c;
		if (cons.wpos == CONSBUFSIZE)
			cons.wpos = 0;
	}
}
f0100539:	83 c4 04             	add    $0x4,%esp
f010053c:	5b                   	pop    %ebx
f010053d:	5d                   	pop    %ebp
f010053e:	c3                   	ret    

f010053f <kbd_proc_data>:
 * Get data from the keyboard.  If we finish a character, return it.  Else 0.
 * Return -1 if no data.
 */
static int
kbd_proc_data(void)
{
f010053f:	55                   	push   %ebp
f0100540:	89 e5                	mov    %esp,%ebp
f0100542:	53                   	push   %ebx
f0100543:	83 ec 04             	sub    $0x4,%esp
	int c;
	uint8_t stat, data;
	static uint32_t shift;

	stat = inb(KBSTATP);
f0100546:	b8 64 00 00 00       	mov    $0x64,%eax
f010054b:	e8 70 fd ff ff       	call   f01002c0 <inb>
	if ((stat & KBS_DIB) == 0)
f0100550:	a8 01                	test   $0x1,%al
f0100552:	0f 84 fe 00 00 00    	je     f0100656 <kbd_proc_data+0x117>
		return -1;
	// Ignore data from mouse.
	if (stat & KBS_TERR)
f0100558:	a8 20                	test   $0x20,%al
f010055a:	0f 85 fd 00 00 00    	jne    f010065d <kbd_proc_data+0x11e>
		return -1;

	data = inb(KBDATAP);
f0100560:	b8 60 00 00 00       	mov    $0x60,%eax
f0100565:	e8 56 fd ff ff       	call   f01002c0 <inb>

	if (data == 0xE0) {
f010056a:	3c e0                	cmp    $0xe0,%al
f010056c:	75 11                	jne    f010057f <kbd_proc_data+0x40>
		// E0 escape character
		shift |= E0ESC;
f010056e:	83 0d 00 50 28 f0 40 	orl    $0x40,0xf0285000
		return 0;
f0100575:	b8 00 00 00 00       	mov    $0x0,%eax
f010057a:	e9 e7 00 00 00       	jmp    f0100666 <kbd_proc_data+0x127>
	} else if (data & 0x80) {
f010057f:	84 c0                	test   %al,%al
f0100581:	79 38                	jns    f01005bb <kbd_proc_data+0x7c>
		// Key released
		data = (shift & E0ESC ? data : data & 0x7F);
f0100583:	8b 0d 00 50 28 f0    	mov    0xf0285000,%ecx
f0100589:	89 cb                	mov    %ecx,%ebx
f010058b:	83 e3 40             	and    $0x40,%ebx
f010058e:	89 c2                	mov    %eax,%edx
f0100590:	83 e2 7f             	and    $0x7f,%edx
f0100593:	85 db                	test   %ebx,%ebx
f0100595:	0f 44 c2             	cmove  %edx,%eax
		shift &= ~(shiftcode[data] | E0ESC);
f0100598:	0f b6 c0             	movzbl %al,%eax
f010059b:	0f b6 80 e0 5e 10 f0 	movzbl -0xfefa120(%eax),%eax
f01005a2:	83 c8 40             	or     $0x40,%eax
f01005a5:	0f b6 c0             	movzbl %al,%eax
f01005a8:	f7 d0                	not    %eax
f01005aa:	21 c8                	and    %ecx,%eax
f01005ac:	a3 00 50 28 f0       	mov    %eax,0xf0285000
		return 0;
f01005b1:	b8 00 00 00 00       	mov    $0x0,%eax
f01005b6:	e9 ab 00 00 00       	jmp    f0100666 <kbd_proc_data+0x127>
	} else if (shift & E0ESC) {
f01005bb:	8b 15 00 50 28 f0    	mov    0xf0285000,%edx
f01005c1:	f6 c2 40             	test   $0x40,%dl
f01005c4:	74 0c                	je     f01005d2 <kbd_proc_data+0x93>
		// Last character was an E0 escape; or with 0x80
		data |= 0x80;
f01005c6:	83 c8 80             	or     $0xffffff80,%eax
		shift &= ~E0ESC;
f01005c9:	83 e2 bf             	and    $0xffffffbf,%edx
f01005cc:	89 15 00 50 28 f0    	mov    %edx,0xf0285000
	}

	shift |= shiftcode[data];
f01005d2:	0f b6 c0             	movzbl %al,%eax
	shift ^= togglecode[data];
f01005d5:	0f b6 90 e0 5e 10 f0 	movzbl -0xfefa120(%eax),%edx
f01005dc:	0b 15 00 50 28 f0    	or     0xf0285000,%edx
f01005e2:	0f b6 88 e0 5d 10 f0 	movzbl -0xfefa220(%eax),%ecx
f01005e9:	31 ca                	xor    %ecx,%edx
f01005eb:	89 15 00 50 28 f0    	mov    %edx,0xf0285000

	c = charcode[shift & (CTL | SHIFT)][data];
f01005f1:	89 d1                	mov    %edx,%ecx
f01005f3:	83 e1 03             	and    $0x3,%ecx
f01005f6:	8b 0c 8d c0 5d 10 f0 	mov    -0xfefa240(,%ecx,4),%ecx
f01005fd:	0f b6 04 01          	movzbl (%ecx,%eax,1),%eax
f0100601:	0f b6 d8             	movzbl %al,%ebx
	if (shift & CAPSLOCK) {
f0100604:	f6 c2 08             	test   $0x8,%dl
f0100607:	74 1b                	je     f0100624 <kbd_proc_data+0xe5>
		if ('a' <= c && c <= 'z')
f0100609:	89 d8                	mov    %ebx,%eax
f010060b:	8d 4b 9f             	lea    -0x61(%ebx),%ecx
f010060e:	83 f9 19             	cmp    $0x19,%ecx
f0100611:	77 05                	ja     f0100618 <kbd_proc_data+0xd9>
			c += 'A' - 'a';
f0100613:	83 eb 20             	sub    $0x20,%ebx
f0100616:	eb 0c                	jmp    f0100624 <kbd_proc_data+0xe5>
		else if ('A' <= c && c <= 'Z')
f0100618:	83 e8 41             	sub    $0x41,%eax
			c += 'a' - 'A';
f010061b:	8d 4b 20             	lea    0x20(%ebx),%ecx
f010061e:	83 f8 19             	cmp    $0x19,%eax
f0100621:	0f 46 d9             	cmovbe %ecx,%ebx
	}

	// Process special keys
	// Ctrl-Alt-Del: reboot
	if (!(~shift & (CTL | ALT)) && c == KEY_DEL) {
f0100624:	f7 d2                	not    %edx
f0100626:	f6 c2 06             	test   $0x6,%dl
f0100629:	75 39                	jne    f0100664 <kbd_proc_data+0x125>
f010062b:	81 fb e9 00 00 00    	cmp    $0xe9,%ebx
f0100631:	75 31                	jne    f0100664 <kbd_proc_data+0x125>
		cprintf("Rebooting!\n");
f0100633:	83 ec 0c             	sub    $0xc,%esp
f0100636:	68 91 5d 10 f0       	push   $0xf0105d91
f010063b:	e8 2f 32 00 00       	call   f010386f <cprintf>
		outb(0x92, 0x3); // courtesy of Chris Frost
f0100640:	ba 03 00 00 00       	mov    $0x3,%edx
f0100645:	b8 92 00 00 00       	mov    $0x92,%eax
f010064a:	e8 79 fc ff ff       	call   f01002c8 <outb>
f010064f:	83 c4 10             	add    $0x10,%esp
	}

	return c;
f0100652:	89 d8                	mov    %ebx,%eax
f0100654:	eb 10                	jmp    f0100666 <kbd_proc_data+0x127>
	uint8_t stat, data;
	static uint32_t shift;

	stat = inb(KBSTATP);
	if ((stat & KBS_DIB) == 0)
		return -1;
f0100656:	b8 ff ff ff ff       	mov    $0xffffffff,%eax
f010065b:	eb 09                	jmp    f0100666 <kbd_proc_data+0x127>
	// Ignore data from mouse.
	if (stat & KBS_TERR)
		return -1;
f010065d:	b8 ff ff ff ff       	mov    $0xffffffff,%eax
f0100662:	eb 02                	jmp    f0100666 <kbd_proc_data+0x127>
	if (!(~shift & (CTL | ALT)) && c == KEY_DEL) {
		cprintf("Rebooting!\n");
		outb(0x92, 0x3); // courtesy of Chris Frost
	}

	return c;
f0100664:	89 d8                	mov    %ebx,%eax
}
f0100666:	8b 5d fc             	mov    -0x4(%ebp),%ebx
f0100669:	c9                   	leave  
f010066a:	c3                   	ret    

f010066b <cga_putc>:



static void
cga_putc(int c)
{
f010066b:	55                   	push   %ebp
f010066c:	89 e5                	mov    %esp,%ebp
f010066e:	57                   	push   %edi
f010066f:	56                   	push   %esi
f0100670:	53                   	push   %ebx
f0100671:	83 ec 0c             	sub    $0xc,%esp
	// if no attribute given, then use black on white
	if (!(c & ~0xFF))
f0100674:	89 c1                	mov    %eax,%ecx
f0100676:	81 e1 00 ff ff ff    	and    $0xffffff00,%ecx
		c |= 0x0700;
f010067c:	89 c2                	mov    %eax,%edx
f010067e:	80 ce 07             	or     $0x7,%dh
f0100681:	85 c9                	test   %ecx,%ecx
f0100683:	0f 44 c2             	cmove  %edx,%eax

	switch (c & 0xff) {
f0100686:	0f b6 d0             	movzbl %al,%edx
f0100689:	83 fa 09             	cmp    $0x9,%edx
f010068c:	74 72                	je     f0100700 <cga_putc+0x95>
f010068e:	83 fa 09             	cmp    $0x9,%edx
f0100691:	7f 0a                	jg     f010069d <cga_putc+0x32>
f0100693:	83 fa 08             	cmp    $0x8,%edx
f0100696:	74 14                	je     f01006ac <cga_putc+0x41>
f0100698:	e9 97 00 00 00       	jmp    f0100734 <cga_putc+0xc9>
f010069d:	83 fa 0a             	cmp    $0xa,%edx
f01006a0:	74 38                	je     f01006da <cga_putc+0x6f>
f01006a2:	83 fa 0d             	cmp    $0xd,%edx
f01006a5:	74 3b                	je     f01006e2 <cga_putc+0x77>
f01006a7:	e9 88 00 00 00       	jmp    f0100734 <cga_putc+0xc9>
	case '\b':
		if (crt_pos > 0) {
f01006ac:	0f b7 15 28 52 28 f0 	movzwl 0xf0285228,%edx
f01006b3:	66 85 d2             	test   %dx,%dx
f01006b6:	0f 84 e4 00 00 00    	je     f01007a0 <cga_putc+0x135>
			crt_pos--;
f01006bc:	83 ea 01             	sub    $0x1,%edx
f01006bf:	66 89 15 28 52 28 f0 	mov    %dx,0xf0285228
			crt_buf[crt_pos] = (c & ~0xff) | ' ';
f01006c6:	0f b7 d2             	movzwl %dx,%edx
f01006c9:	b0 00                	mov    $0x0,%al
f01006cb:	83 c8 20             	or     $0x20,%eax
f01006ce:	8b 0d 2c 52 28 f0    	mov    0xf028522c,%ecx
f01006d4:	66 89 04 51          	mov    %ax,(%ecx,%edx,2)
f01006d8:	eb 78                	jmp    f0100752 <cga_putc+0xe7>
		}
		break;
	case '\n':
		crt_pos += CRT_COLS;
f01006da:	66 83 05 28 52 28 f0 	addw   $0x50,0xf0285228
f01006e1:	50 
		/* fallthru */
	case '\r':
		crt_pos -= (crt_pos % CRT_COLS);
f01006e2:	0f b7 05 28 52 28 f0 	movzwl 0xf0285228,%eax
f01006e9:	69 c0 cd cc 00 00    	imul   $0xcccd,%eax,%eax
f01006ef:	c1 e8 16             	shr    $0x16,%eax
f01006f2:	8d 04 80             	lea    (%eax,%eax,4),%eax
f01006f5:	c1 e0 04             	shl    $0x4,%eax
f01006f8:	66 a3 28 52 28 f0    	mov    %ax,0xf0285228
		break;
f01006fe:	eb 52                	jmp    f0100752 <cga_putc+0xe7>
	case '\t':
		cons_putc(' ');
f0100700:	b8 20 00 00 00       	mov    $0x20,%eax
f0100705:	e8 da 00 00 00       	call   f01007e4 <cons_putc>
		cons_putc(' ');
f010070a:	b8 20 00 00 00       	mov    $0x20,%eax
f010070f:	e8 d0 00 00 00       	call   f01007e4 <cons_putc>
		cons_putc(' ');
f0100714:	b8 20 00 00 00       	mov    $0x20,%eax
f0100719:	e8 c6 00 00 00       	call   f01007e4 <cons_putc>
		cons_putc(' ');
f010071e:	b8 20 00 00 00       	mov    $0x20,%eax
f0100723:	e8 bc 00 00 00       	call   f01007e4 <cons_putc>
		cons_putc(' ');
f0100728:	b8 20 00 00 00       	mov    $0x20,%eax
f010072d:	e8 b2 00 00 00       	call   f01007e4 <cons_putc>
		break;
f0100732:	eb 1e                	jmp    f0100752 <cga_putc+0xe7>
	default:
		crt_buf[crt_pos++] = c;		/* write the character */
f0100734:	0f b7 15 28 52 28 f0 	movzwl 0xf0285228,%edx
f010073b:	8d 4a 01             	lea    0x1(%edx),%ecx
f010073e:	66 89 0d 28 52 28 f0 	mov    %cx,0xf0285228
f0100745:	0f b7 d2             	movzwl %dx,%edx
f0100748:	8b 0d 2c 52 28 f0    	mov    0xf028522c,%ecx
f010074e:	66 89 04 51          	mov    %ax,(%ecx,%edx,2)
		break;
	}

	// What is the purpose of this?
	if (crt_pos >= CRT_SIZE) {
f0100752:	66 81 3d 28 52 28 f0 	cmpw   $0x7cf,0xf0285228
f0100759:	cf 07 
f010075b:	76 43                	jbe    f01007a0 <cga_putc+0x135>
		int i;

		memmove(crt_buf, crt_buf + CRT_COLS, (CRT_SIZE - CRT_COLS) * sizeof(uint16_t));
f010075d:	a1 2c 52 28 f0       	mov    0xf028522c,%eax
f0100762:	83 ec 04             	sub    $0x4,%esp
f0100765:	68 00 0f 00 00       	push   $0xf00
f010076a:	8d 90 a0 00 00 00    	lea    0xa0(%eax),%edx
f0100770:	52                   	push   %edx
f0100771:	50                   	push   %eax
f0100772:	e8 50 48 00 00       	call   f0104fc7 <memmove>
		for (i = CRT_SIZE - CRT_COLS; i < CRT_SIZE; i++)
			crt_buf[i] = 0x0700 | ' ';
f0100777:	8b 15 2c 52 28 f0    	mov    0xf028522c,%edx
f010077d:	8d 82 00 0f 00 00    	lea    0xf00(%edx),%eax
f0100783:	81 c2 a0 0f 00 00    	add    $0xfa0,%edx
f0100789:	83 c4 10             	add    $0x10,%esp
f010078c:	66 c7 00 20 07       	movw   $0x720,(%eax)
f0100791:	83 c0 02             	add    $0x2,%eax
	// What is the purpose of this?
	if (crt_pos >= CRT_SIZE) {
		int i;

		memmove(crt_buf, crt_buf + CRT_COLS, (CRT_SIZE - CRT_COLS) * sizeof(uint16_t));
		for (i = CRT_SIZE - CRT_COLS; i < CRT_SIZE; i++)
f0100794:	39 d0                	cmp    %edx,%eax
f0100796:	75 f4                	jne    f010078c <cga_putc+0x121>
			crt_buf[i] = 0x0700 | ' ';
		crt_pos -= CRT_COLS;
f0100798:	66 83 2d 28 52 28 f0 	subw   $0x50,0xf0285228
f010079f:	50 
	}

	/* move that little blinky thing */
	outb(addr_6845, 14);
f01007a0:	8b 3d 30 52 28 f0    	mov    0xf0285230,%edi
f01007a6:	ba 0e 00 00 00       	mov    $0xe,%edx
f01007ab:	89 f8                	mov    %edi,%eax
f01007ad:	e8 16 fb ff ff       	call   f01002c8 <outb>
	outb(addr_6845 + 1, crt_pos >> 8);
f01007b2:	0f b7 1d 28 52 28 f0 	movzwl 0xf0285228,%ebx
f01007b9:	8d 77 01             	lea    0x1(%edi),%esi
f01007bc:	0f b6 d7             	movzbl %bh,%edx
f01007bf:	89 f0                	mov    %esi,%eax
f01007c1:	e8 02 fb ff ff       	call   f01002c8 <outb>
	outb(addr_6845, 15);
f01007c6:	ba 0f 00 00 00       	mov    $0xf,%edx
f01007cb:	89 f8                	mov    %edi,%eax
f01007cd:	e8 f6 fa ff ff       	call   f01002c8 <outb>
	outb(addr_6845 + 1, crt_pos);
f01007d2:	0f b6 d3             	movzbl %bl,%edx
f01007d5:	89 f0                	mov    %esi,%eax
f01007d7:	e8 ec fa ff ff       	call   f01002c8 <outb>
}
f01007dc:	8d 65 f4             	lea    -0xc(%ebp),%esp
f01007df:	5b                   	pop    %ebx
f01007e0:	5e                   	pop    %esi
f01007e1:	5f                   	pop    %edi
f01007e2:	5d                   	pop    %ebp
f01007e3:	c3                   	ret    

f01007e4 <cons_putc>:
}

// output a character to the console
static void
cons_putc(int c)
{
f01007e4:	55                   	push   %ebp
f01007e5:	89 e5                	mov    %esp,%ebp
f01007e7:	53                   	push   %ebx
f01007e8:	83 ec 04             	sub    $0x4,%esp
f01007eb:	89 c3                	mov    %eax,%ebx
	serial_putc(c);
f01007ed:	e8 36 fb ff ff       	call   f0100328 <serial_putc>
	lpt_putc(c);
f01007f2:	89 d8                	mov    %ebx,%eax
f01007f4:	e8 03 fc ff ff       	call   f01003fc <lpt_putc>
	cga_putc(c);
f01007f9:	89 d8                	mov    %ebx,%eax
f01007fb:	e8 6b fe ff ff       	call   f010066b <cga_putc>
}
f0100800:	83 c4 04             	add    $0x4,%esp
f0100803:	5b                   	pop    %ebx
f0100804:	5d                   	pop    %ebp
f0100805:	c3                   	ret    

f0100806 <serial_intr>:
}

void
serial_intr(void)
{
	if (serial_exists)
f0100806:	80 3d 34 52 28 f0 00 	cmpb   $0x0,0xf0285234
f010080d:	74 11                	je     f0100820 <serial_intr+0x1a>
	return inb(COM1+COM_RX);
}

void
serial_intr(void)
{
f010080f:	55                   	push   %ebp
f0100810:	89 e5                	mov    %esp,%ebp
f0100812:	83 ec 08             	sub    $0x8,%esp
	if (serial_exists)
		cons_intr(serial_proc_data);
f0100815:	b8 01 03 10 f0       	mov    $0xf0100301,%eax
f010081a:	e8 dd fc ff ff       	call   f01004fc <cons_intr>
}
f010081f:	c9                   	leave  
f0100820:	f3 c3                	repz ret 

f0100822 <kbd_intr>:
	return c;
}

void
kbd_intr(void)
{
f0100822:	55                   	push   %ebp
f0100823:	89 e5                	mov    %esp,%ebp
f0100825:	83 ec 08             	sub    $0x8,%esp
	cons_intr(kbd_proc_data);
f0100828:	b8 3f 05 10 f0       	mov    $0xf010053f,%eax
f010082d:	e8 ca fc ff ff       	call   f01004fc <cons_intr>
}
f0100832:	c9                   	leave  
f0100833:	c3                   	ret    

f0100834 <kbd_init>:

static void
kbd_init(void)
{
f0100834:	55                   	push   %ebp
f0100835:	89 e5                	mov    %esp,%ebp
f0100837:	83 ec 08             	sub    $0x8,%esp
	// Drain the kbd buffer so that QEMU generates interrupts.
	kbd_intr();
f010083a:	e8 e3 ff ff ff       	call   f0100822 <kbd_intr>
	irq_setmask_8259A(irq_mask_8259A & ~(1<<IRQ_KBD));
f010083f:	83 ec 0c             	sub    $0xc,%esp
f0100842:	0f b7 05 a8 13 11 f0 	movzwl 0xf01113a8,%eax
f0100849:	25 fd ff 00 00       	and    $0xfffd,%eax
f010084e:	50                   	push   %eax
f010084f:	e8 62 2e 00 00       	call   f01036b6 <irq_setmask_8259A>
}
f0100854:	83 c4 10             	add    $0x10,%esp
f0100857:	c9                   	leave  
f0100858:	c3                   	ret    

f0100859 <cons_getc>:
}

// return the next input character from the console, or 0 if none waiting
int
cons_getc(void)
{
f0100859:	55                   	push   %ebp
f010085a:	89 e5                	mov    %esp,%ebp
f010085c:	83 ec 08             	sub    $0x8,%esp
	int c;

	// poll for any pending input characters,
	// so that this function works even when interrupts are disabled
	// (e.g., when called from the kernel monitor).
	serial_intr();
f010085f:	e8 a2 ff ff ff       	call   f0100806 <serial_intr>
	kbd_intr();
f0100864:	e8 b9 ff ff ff       	call   f0100822 <kbd_intr>

	// grab the next character from the input buffer.
	if (cons.rpos != cons.wpos) {
f0100869:	a1 20 52 28 f0       	mov    0xf0285220,%eax
f010086e:	3b 05 24 52 28 f0    	cmp    0xf0285224,%eax
f0100874:	74 26                	je     f010089c <cons_getc+0x43>
		c = cons.buf[cons.rpos++];
f0100876:	8d 50 01             	lea    0x1(%eax),%edx
f0100879:	89 15 20 52 28 f0    	mov    %edx,0xf0285220
f010087f:	0f b6 88 20 50 28 f0 	movzbl -0xfd7afe0(%eax),%ecx
		if (cons.rpos == CONSBUFSIZE)
			cons.rpos = 0;
		return c;
f0100886:	89 c8                	mov    %ecx,%eax
	kbd_intr();

	// grab the next character from the input buffer.
	if (cons.rpos != cons.wpos) {
		c = cons.buf[cons.rpos++];
		if (cons.rpos == CONSBUFSIZE)
f0100888:	81 fa 00 02 00 00    	cmp    $0x200,%edx
f010088e:	75 11                	jne    f01008a1 <cons_getc+0x48>
			cons.rpos = 0;
f0100890:	c7 05 20 52 28 f0 00 	movl   $0x0,0xf0285220
f0100897:	00 00 00 
f010089a:	eb 05                	jmp    f01008a1 <cons_getc+0x48>
		return c;
	}
	return 0;
f010089c:	b8 00 00 00 00       	mov    $0x0,%eax
}
f01008a1:	c9                   	leave  
f01008a2:	c3                   	ret    

f01008a3 <cons_init>:
}

// initialize the console devices
void
cons_init(void)
{
f01008a3:	55                   	push   %ebp
f01008a4:	89 e5                	mov    %esp,%ebp
f01008a6:	83 ec 08             	sub    $0x8,%esp
	cga_init();
f01008a9:	e8 ab fb ff ff       	call   f0100459 <cga_init>
	kbd_init();
f01008ae:	e8 81 ff ff ff       	call   f0100834 <kbd_init>
	serial_init();
f01008b3:	e8 af fa ff ff       	call   f0100367 <serial_init>

	if (!serial_exists)
f01008b8:	80 3d 34 52 28 f0 00 	cmpb   $0x0,0xf0285234
f01008bf:	75 10                	jne    f01008d1 <cons_init+0x2e>
		cprintf("Serial port does not exist!\n");
f01008c1:	83 ec 0c             	sub    $0xc,%esp
f01008c4:	68 9d 5d 10 f0       	push   $0xf0105d9d
f01008c9:	e8 a1 2f 00 00       	call   f010386f <cprintf>
f01008ce:	83 c4 10             	add    $0x10,%esp
}
f01008d1:	c9                   	leave  
f01008d2:	c3                   	ret    

f01008d3 <cputchar>:

// `High'-level console I/O.  Used by readline and cprintf.

void
cputchar(int c)
{
f01008d3:	55                   	push   %ebp
f01008d4:	89 e5                	mov    %esp,%ebp
f01008d6:	83 ec 08             	sub    $0x8,%esp
	cons_putc(c);
f01008d9:	8b 45 08             	mov    0x8(%ebp),%eax
f01008dc:	e8 03 ff ff ff       	call   f01007e4 <cons_putc>
}
f01008e1:	c9                   	leave  
f01008e2:	c3                   	ret    

f01008e3 <getchar>:

int
getchar(void)
{
f01008e3:	55                   	push   %ebp
f01008e4:	89 e5                	mov    %esp,%ebp
f01008e6:	83 ec 08             	sub    $0x8,%esp
	int c;

	while ((c = cons_getc()) == 0)
f01008e9:	e8 6b ff ff ff       	call   f0100859 <cons_getc>
f01008ee:	85 c0                	test   %eax,%eax
f01008f0:	74 f7                	je     f01008e9 <getchar+0x6>
		/* do nothing */;
	return c;
}
f01008f2:	c9                   	leave  
f01008f3:	c3                   	ret    

f01008f4 <iscons>:

int
iscons(int fdnum)
{
f01008f4:	55                   	push   %ebp
f01008f5:	89 e5                	mov    %esp,%ebp
	// used by readline
	return 1;
}
f01008f7:	b8 01 00 00 00       	mov    $0x1,%eax
f01008fc:	5d                   	pop    %ebp
f01008fd:	c3                   	ret    

f01008fe <mon_help>:

/***** Implementations of basic kernel monitor commands *****/

int
mon_help(int argc, char **argv, struct Trapframe *tf)
{
f01008fe:	55                   	push   %ebp
f01008ff:	89 e5                	mov    %esp,%ebp
f0100901:	83 ec 0c             	sub    $0xc,%esp
	int i;

	for (i = 0; i < ARRAY_SIZE(commands); i++)
		cprintf("%s - %s\n", commands[i].name, commands[i].desc);
f0100904:	68 e0 5f 10 f0       	push   $0xf0105fe0
f0100909:	68 fe 5f 10 f0       	push   $0xf0105ffe
f010090e:	68 03 60 10 f0       	push   $0xf0106003
f0100913:	e8 57 2f 00 00       	call   f010386f <cprintf>
f0100918:	83 c4 0c             	add    $0xc,%esp
f010091b:	68 a0 60 10 f0       	push   $0xf01060a0
f0100920:	68 0c 60 10 f0       	push   $0xf010600c
f0100925:	68 03 60 10 f0       	push   $0xf0106003
f010092a:	e8 40 2f 00 00       	call   f010386f <cprintf>
f010092f:	83 c4 0c             	add    $0xc,%esp
f0100932:	68 15 60 10 f0       	push   $0xf0106015
f0100937:	68 29 60 10 f0       	push   $0xf0106029
f010093c:	68 03 60 10 f0       	push   $0xf0106003
f0100941:	e8 29 2f 00 00       	call   f010386f <cprintf>
	return 0;
}
f0100946:	b8 00 00 00 00       	mov    $0x0,%eax
f010094b:	c9                   	leave  
f010094c:	c3                   	ret    

f010094d <mon_kerninfo>:

int
mon_kerninfo(int argc, char **argv, struct Trapframe *tf)
{
f010094d:	55                   	push   %ebp
f010094e:	89 e5                	mov    %esp,%ebp
f0100950:	83 ec 14             	sub    $0x14,%esp
	extern char _start[], entry[], etext[], edata[], end[];

	cprintf("Special kernel symbols:\n");
f0100953:	68 33 60 10 f0       	push   $0xf0106033
f0100958:	e8 12 2f 00 00       	call   f010386f <cprintf>
	cprintf("  _start                  %08x (phys)\n", _start);
f010095d:	83 c4 08             	add    $0x8,%esp
f0100960:	68 0c 00 10 00       	push   $0x10000c
f0100965:	68 c8 60 10 f0       	push   $0xf01060c8
f010096a:	e8 00 2f 00 00       	call   f010386f <cprintf>
	cprintf("  entry  %08x (virt)  %08x (phys)\n", entry, entry - KERNBASE);
f010096f:	83 c4 0c             	add    $0xc,%esp
f0100972:	68 0c 00 10 00       	push   $0x10000c
f0100977:	68 0c 00 10 f0       	push   $0xf010000c
f010097c:	68 f0 60 10 f0       	push   $0xf01060f0
f0100981:	e8 e9 2e 00 00       	call   f010386f <cprintf>
	cprintf("  etext  %08x (virt)  %08x (phys)\n", etext, etext - KERNBASE);
f0100986:	83 c4 0c             	add    $0xc,%esp
f0100989:	68 b1 5c 10 00       	push   $0x105cb1
f010098e:	68 b1 5c 10 f0       	push   $0xf0105cb1
f0100993:	68 14 61 10 f0       	push   $0xf0106114
f0100998:	e8 d2 2e 00 00       	call   f010386f <cprintf>
	cprintf("  edata  %08x (virt)  %08x (phys)\n", edata, edata - KERNBASE);
f010099d:	83 c4 0c             	add    $0xc,%esp
f01009a0:	68 16 41 28 00       	push   $0x284116
f01009a5:	68 16 41 28 f0       	push   $0xf0284116
f01009aa:	68 38 61 10 f0       	push   $0xf0106138
f01009af:	e8 bb 2e 00 00       	call   f010386f <cprintf>
	cprintf("  end    %08x (virt)  %08x (phys)\n", end, end - KERNBASE);
f01009b4:	83 c4 0c             	add    $0xc,%esp
f01009b7:	68 08 80 2c 00       	push   $0x2c8008
f01009bc:	68 08 80 2c f0       	push   $0xf02c8008
f01009c1:	68 5c 61 10 f0       	push   $0xf010615c
f01009c6:	e8 a4 2e 00 00       	call   f010386f <cprintf>
	cprintf("Kernel executable memory footprint: %dKB\n",
		ROUNDUP(end - entry, 1024) / 1024);
f01009cb:	b8 07 84 2c f0       	mov    $0xf02c8407,%eax
f01009d0:	2d 0c 00 10 f0       	sub    $0xf010000c,%eax
	cprintf("  _start                  %08x (phys)\n", _start);
	cprintf("  entry  %08x (virt)  %08x (phys)\n", entry, entry - KERNBASE);
	cprintf("  etext  %08x (virt)  %08x (phys)\n", etext, etext - KERNBASE);
	cprintf("  edata  %08x (virt)  %08x (phys)\n", edata, edata - KERNBASE);
	cprintf("  end    %08x (virt)  %08x (phys)\n", end, end - KERNBASE);
	cprintf("Kernel executable memory footprint: %dKB\n",
f01009d5:	83 c4 08             	add    $0x8,%esp
f01009d8:	25 00 fc ff ff       	and    $0xfffffc00,%eax
f01009dd:	8d 90 ff 03 00 00    	lea    0x3ff(%eax),%edx
f01009e3:	85 c0                	test   %eax,%eax
f01009e5:	0f 48 c2             	cmovs  %edx,%eax
f01009e8:	c1 f8 0a             	sar    $0xa,%eax
f01009eb:	50                   	push   %eax
f01009ec:	68 80 61 10 f0       	push   $0xf0106180
f01009f1:	e8 79 2e 00 00       	call   f010386f <cprintf>
		ROUNDUP(end - entry, 1024) / 1024);
	return 0;
}
f01009f6:	b8 00 00 00 00       	mov    $0x0,%eax
f01009fb:	c9                   	leave  
f01009fc:	c3                   	ret    

f01009fd <mon_backtrace>:

int
mon_backtrace(int argc, char **argv, struct Trapframe *tf)
{
f01009fd:	55                   	push   %ebp
f01009fe:	89 e5                	mov    %esp,%ebp
f0100a00:	57                   	push   %edi
f0100a01:	56                   	push   %esi
f0100a02:	53                   	push   %ebx
f0100a03:	83 ec 2c             	sub    $0x2c,%esp

static inline uint32_t __attribute__((always_inline))
read_ebp(void)
{
	uint32_t ebp;
	asm volatile("movl %%ebp,%0" : "=r" (ebp));
f0100a06:	89 eb                	mov    %ebp,%ebx
	while (ebp != 0x0){
	uint32_t eip=*(uint32_t *)(ebp+4);
	cprintf("  ebp %08x eip %08x args %08x %08x %08x %08x %08x\n", ebp, eip, 
			*(uint32_t *)(ebp+8), *(uint32_t *)(ebp+12), *(uint32_t *)(ebp+16),
			*(uint32_t *)(ebp+20), *(uint32_t *)(ebp+24));
	debuginfo_eip(eip,&dbgi);
f0100a08:	8d 7d d0             	lea    -0x30(%ebp),%edi
int
mon_backtrace(int argc, char **argv, struct Trapframe *tf)
{
	uint32_t ebp = read_ebp();
	struct Eipdebuginfo dbgi;
	while (ebp != 0x0){
f0100a0b:	eb 4a                	jmp    f0100a57 <mon_backtrace+0x5a>
	uint32_t eip=*(uint32_t *)(ebp+4);
f0100a0d:	8b 73 04             	mov    0x4(%ebx),%esi
	cprintf("  ebp %08x eip %08x args %08x %08x %08x %08x %08x\n", ebp, eip, 
f0100a10:	ff 73 18             	pushl  0x18(%ebx)
f0100a13:	ff 73 14             	pushl  0x14(%ebx)
f0100a16:	ff 73 10             	pushl  0x10(%ebx)
f0100a19:	ff 73 0c             	pushl  0xc(%ebx)
f0100a1c:	ff 73 08             	pushl  0x8(%ebx)
f0100a1f:	56                   	push   %esi
f0100a20:	53                   	push   %ebx
f0100a21:	68 ac 61 10 f0       	push   $0xf01061ac
f0100a26:	e8 44 2e 00 00       	call   f010386f <cprintf>
			*(uint32_t *)(ebp+8), *(uint32_t *)(ebp+12), *(uint32_t *)(ebp+16),
			*(uint32_t *)(ebp+20), *(uint32_t *)(ebp+24));
	debuginfo_eip(eip,&dbgi);
f0100a2b:	83 c4 18             	add    $0x18,%esp
f0100a2e:	57                   	push   %edi
f0100a2f:	56                   	push   %esi
f0100a30:	e8 e7 3a 00 00       	call   f010451c <debuginfo_eip>
	cprintf("       %s:%d: %.*s+%d\n", dbgi.eip_file, dbgi.eip_line, dbgi.eip_fn_namelen, 
f0100a35:	83 c4 08             	add    $0x8,%esp
f0100a38:	2b 75 e0             	sub    -0x20(%ebp),%esi
f0100a3b:	56                   	push   %esi
f0100a3c:	ff 75 d8             	pushl  -0x28(%ebp)
f0100a3f:	ff 75 dc             	pushl  -0x24(%ebp)
f0100a42:	ff 75 d4             	pushl  -0x2c(%ebp)
f0100a45:	ff 75 d0             	pushl  -0x30(%ebp)
f0100a48:	68 4c 60 10 f0       	push   $0xf010604c
f0100a4d:	e8 1d 2e 00 00       	call   f010386f <cprintf>
			dbgi.eip_fn_name,((uintptr_t)eip - dbgi.eip_fn_addr));
	ebp = *(uint32_t *)(ebp);
f0100a52:	8b 1b                	mov    (%ebx),%ebx
f0100a54:	83 c4 20             	add    $0x20,%esp
int
mon_backtrace(int argc, char **argv, struct Trapframe *tf)
{
	uint32_t ebp = read_ebp();
	struct Eipdebuginfo dbgi;
	while (ebp != 0x0){
f0100a57:	85 db                	test   %ebx,%ebx
f0100a59:	75 b2                	jne    f0100a0d <mon_backtrace+0x10>
	cprintf("       %s:%d: %.*s+%d\n", dbgi.eip_file, dbgi.eip_line, dbgi.eip_fn_namelen, 
			dbgi.eip_fn_name,((uintptr_t)eip - dbgi.eip_fn_addr));
	ebp = *(uint32_t *)(ebp);
	}
	return 0;
}
f0100a5b:	b8 00 00 00 00       	mov    $0x0,%eax
f0100a60:	8d 65 f4             	lea    -0xc(%ebp),%esp
f0100a63:	5b                   	pop    %ebx
f0100a64:	5e                   	pop    %esi
f0100a65:	5f                   	pop    %edi
f0100a66:	5d                   	pop    %ebp
f0100a67:	c3                   	ret    

f0100a68 <runcmd>:
#define WHITESPACE "\t\r\n "
#define MAXARGS 16

static int
runcmd(char *buf, struct Trapframe *tf)
{
f0100a68:	55                   	push   %ebp
f0100a69:	89 e5                	mov    %esp,%ebp
f0100a6b:	57                   	push   %edi
f0100a6c:	56                   	push   %esi
f0100a6d:	53                   	push   %ebx
f0100a6e:	83 ec 5c             	sub    $0x5c,%esp
f0100a71:	89 c3                	mov    %eax,%ebx
f0100a73:	89 55 a4             	mov    %edx,-0x5c(%ebp)
	char *argv[MAXARGS];
	int i;

	// Parse the command buffer into whitespace-separated arguments
	argc = 0;
	argv[argc] = 0;
f0100a76:	c7 45 a8 00 00 00 00 	movl   $0x0,-0x58(%ebp)
	int argc;
	char *argv[MAXARGS];
	int i;

	// Parse the command buffer into whitespace-separated arguments
	argc = 0;
f0100a7d:	be 00 00 00 00       	mov    $0x0,%esi
f0100a82:	eb 0a                	jmp    f0100a8e <runcmd+0x26>
	argv[argc] = 0;
	while (1) {
		// gobble whitespace
		while (*buf && strchr(WHITESPACE, *buf))
			*buf++ = 0;
f0100a84:	c6 03 00             	movb   $0x0,(%ebx)
f0100a87:	89 f7                	mov    %esi,%edi
f0100a89:	8d 5b 01             	lea    0x1(%ebx),%ebx
f0100a8c:	89 fe                	mov    %edi,%esi
	// Parse the command buffer into whitespace-separated arguments
	argc = 0;
	argv[argc] = 0;
	while (1) {
		// gobble whitespace
		while (*buf && strchr(WHITESPACE, *buf))
f0100a8e:	0f b6 03             	movzbl (%ebx),%eax
f0100a91:	84 c0                	test   %al,%al
f0100a93:	74 6d                	je     f0100b02 <runcmd+0x9a>
f0100a95:	83 ec 08             	sub    $0x8,%esp
f0100a98:	0f be c0             	movsbl %al,%eax
f0100a9b:	50                   	push   %eax
f0100a9c:	68 63 60 10 f0       	push   $0xf0106063
f0100aa1:	e8 96 44 00 00       	call   f0104f3c <strchr>
f0100aa6:	83 c4 10             	add    $0x10,%esp
f0100aa9:	85 c0                	test   %eax,%eax
f0100aab:	75 d7                	jne    f0100a84 <runcmd+0x1c>
			*buf++ = 0;
		if (*buf == 0)
f0100aad:	0f b6 03             	movzbl (%ebx),%eax
f0100ab0:	84 c0                	test   %al,%al
f0100ab2:	74 4e                	je     f0100b02 <runcmd+0x9a>
			break;

		// save and scan past next arg
		if (argc == MAXARGS-1) {
f0100ab4:	83 fe 0f             	cmp    $0xf,%esi
f0100ab7:	75 1c                	jne    f0100ad5 <runcmd+0x6d>
			cprintf("Too many arguments (max %d)\n", MAXARGS);
f0100ab9:	83 ec 08             	sub    $0x8,%esp
f0100abc:	6a 10                	push   $0x10
f0100abe:	68 68 60 10 f0       	push   $0xf0106068
f0100ac3:	e8 a7 2d 00 00       	call   f010386f <cprintf>
			return 0;
f0100ac8:	83 c4 10             	add    $0x10,%esp
f0100acb:	b8 00 00 00 00       	mov    $0x0,%eax
f0100ad0:	e9 99 00 00 00       	jmp    f0100b6e <runcmd+0x106>
		}
		argv[argc++] = buf;
f0100ad5:	8d 7e 01             	lea    0x1(%esi),%edi
f0100ad8:	89 5c b5 a8          	mov    %ebx,-0x58(%ebp,%esi,4)
f0100adc:	eb 0a                	jmp    f0100ae8 <runcmd+0x80>
		while (*buf && !strchr(WHITESPACE, *buf))
			buf++;
f0100ade:	83 c3 01             	add    $0x1,%ebx
		if (argc == MAXARGS-1) {
			cprintf("Too many arguments (max %d)\n", MAXARGS);
			return 0;
		}
		argv[argc++] = buf;
		while (*buf && !strchr(WHITESPACE, *buf))
f0100ae1:	0f b6 03             	movzbl (%ebx),%eax
f0100ae4:	84 c0                	test   %al,%al
f0100ae6:	74 a4                	je     f0100a8c <runcmd+0x24>
f0100ae8:	83 ec 08             	sub    $0x8,%esp
f0100aeb:	0f be c0             	movsbl %al,%eax
f0100aee:	50                   	push   %eax
f0100aef:	68 63 60 10 f0       	push   $0xf0106063
f0100af4:	e8 43 44 00 00       	call   f0104f3c <strchr>
f0100af9:	83 c4 10             	add    $0x10,%esp
f0100afc:	85 c0                	test   %eax,%eax
f0100afe:	74 de                	je     f0100ade <runcmd+0x76>
f0100b00:	eb 8a                	jmp    f0100a8c <runcmd+0x24>
			buf++;
	}
	argv[argc] = 0;
f0100b02:	c7 44 b5 a8 00 00 00 	movl   $0x0,-0x58(%ebp,%esi,4)
f0100b09:	00 

	// Lookup and invoke the command
	if (argc == 0)
		return 0;
f0100b0a:	b8 00 00 00 00       	mov    $0x0,%eax
			buf++;
	}
	argv[argc] = 0;

	// Lookup and invoke the command
	if (argc == 0)
f0100b0f:	85 f6                	test   %esi,%esi
f0100b11:	74 5b                	je     f0100b6e <runcmd+0x106>
f0100b13:	bb 00 00 00 00       	mov    $0x0,%ebx
		return 0;
	for (i = 0; i < ARRAY_SIZE(commands); i++) {
		if (strcmp(argv[0], commands[i].name) == 0)
f0100b18:	83 ec 08             	sub    $0x8,%esp
f0100b1b:	8d 04 5b             	lea    (%ebx,%ebx,2),%eax
f0100b1e:	ff 34 85 40 62 10 f0 	pushl  -0xfef9dc0(,%eax,4)
f0100b25:	ff 75 a8             	pushl  -0x58(%ebp)
f0100b28:	e8 b1 43 00 00       	call   f0104ede <strcmp>
f0100b2d:	83 c4 10             	add    $0x10,%esp
f0100b30:	85 c0                	test   %eax,%eax
f0100b32:	75 1a                	jne    f0100b4e <runcmd+0xe6>
			return commands[i].func(argc, argv, tf);
f0100b34:	83 ec 04             	sub    $0x4,%esp
f0100b37:	8d 04 5b             	lea    (%ebx,%ebx,2),%eax
f0100b3a:	ff 75 a4             	pushl  -0x5c(%ebp)
f0100b3d:	8d 55 a8             	lea    -0x58(%ebp),%edx
f0100b40:	52                   	push   %edx
f0100b41:	56                   	push   %esi
f0100b42:	ff 14 85 48 62 10 f0 	call   *-0xfef9db8(,%eax,4)
f0100b49:	83 c4 10             	add    $0x10,%esp
f0100b4c:	eb 20                	jmp    f0100b6e <runcmd+0x106>
	argv[argc] = 0;

	// Lookup and invoke the command
	if (argc == 0)
		return 0;
	for (i = 0; i < ARRAY_SIZE(commands); i++) {
f0100b4e:	83 c3 01             	add    $0x1,%ebx
f0100b51:	83 fb 03             	cmp    $0x3,%ebx
f0100b54:	75 c2                	jne    f0100b18 <runcmd+0xb0>
		if (strcmp(argv[0], commands[i].name) == 0)
			return commands[i].func(argc, argv, tf);
	}
	cprintf("Unknown command '%s'\n", argv[0]);
f0100b56:	83 ec 08             	sub    $0x8,%esp
f0100b59:	ff 75 a8             	pushl  -0x58(%ebp)
f0100b5c:	68 85 60 10 f0       	push   $0xf0106085
f0100b61:	e8 09 2d 00 00       	call   f010386f <cprintf>
	return 0;
f0100b66:	83 c4 10             	add    $0x10,%esp
f0100b69:	b8 00 00 00 00       	mov    $0x0,%eax
}
f0100b6e:	8d 65 f4             	lea    -0xc(%ebp),%esp
f0100b71:	5b                   	pop    %ebx
f0100b72:	5e                   	pop    %esi
f0100b73:	5f                   	pop    %edi
f0100b74:	5d                   	pop    %ebp
f0100b75:	c3                   	ret    

f0100b76 <monitor>:

void
monitor(struct Trapframe *tf)
{
f0100b76:	55                   	push   %ebp
f0100b77:	89 e5                	mov    %esp,%ebp
f0100b79:	53                   	push   %ebx
f0100b7a:	83 ec 10             	sub    $0x10,%esp
f0100b7d:	8b 5d 08             	mov    0x8(%ebp),%ebx
	char *buf;

	cprintf("Welcome to the JOS kernel monitor!\n");
f0100b80:	68 e0 61 10 f0       	push   $0xf01061e0
f0100b85:	e8 e5 2c 00 00       	call   f010386f <cprintf>
	cprintf("Type 'help' for a list of commands.\n");
f0100b8a:	c7 04 24 04 62 10 f0 	movl   $0xf0106204,(%esp)
f0100b91:	e8 d9 2c 00 00       	call   f010386f <cprintf>

	if (tf != NULL)
f0100b96:	83 c4 10             	add    $0x10,%esp
f0100b99:	85 db                	test   %ebx,%ebx
f0100b9b:	74 0c                	je     f0100ba9 <monitor+0x33>
		print_trapframe(tf);
f0100b9d:	83 ec 0c             	sub    $0xc,%esp
f0100ba0:	53                   	push   %ebx
f0100ba1:	e8 9e 31 00 00       	call   f0103d44 <print_trapframe>
f0100ba6:	83 c4 10             	add    $0x10,%esp

	while (1) {
		buf = readline("K> ");
f0100ba9:	83 ec 0c             	sub    $0xc,%esp
f0100bac:	68 9b 60 10 f0       	push   $0xf010609b
f0100bb1:	e8 6c 41 00 00       	call   f0104d22 <readline>
		if (buf != NULL)
f0100bb6:	83 c4 10             	add    $0x10,%esp
f0100bb9:	85 c0                	test   %eax,%eax
f0100bbb:	74 ec                	je     f0100ba9 <monitor+0x33>
			if (runcmd(buf, tf) < 0)
f0100bbd:	89 da                	mov    %ebx,%edx
f0100bbf:	e8 a4 fe ff ff       	call   f0100a68 <runcmd>
f0100bc4:	85 c0                	test   %eax,%eax
f0100bc6:	79 e1                	jns    f0100ba9 <monitor+0x33>
				break;
	}
}
f0100bc8:	8b 5d fc             	mov    -0x4(%ebp),%ebx
f0100bcb:	c9                   	leave  
f0100bcc:	c3                   	ret    

f0100bcd <invlpg>:
	asm volatile("outl %0,%w1" : : "a" (data), "d" (port));
}

static inline void
invlpg(void *addr)
{
f0100bcd:	55                   	push   %ebp
f0100bce:	89 e5                	mov    %esp,%ebp
	asm volatile("invlpg (%0)" : : "r" (addr) : "memory");
f0100bd0:	0f 01 38             	invlpg (%eax)
}
f0100bd3:	5d                   	pop    %ebp
f0100bd4:	c3                   	ret    

f0100bd5 <lcr0>:
	asm volatile("ltr %0" : : "r" (sel));
}

static inline void
lcr0(uint32_t val)
{
f0100bd5:	55                   	push   %ebp
f0100bd6:	89 e5                	mov    %esp,%ebp
	asm volatile("movl %0,%%cr0" : : "r" (val));
f0100bd8:	0f 22 c0             	mov    %eax,%cr0
}
f0100bdb:	5d                   	pop    %ebp
f0100bdc:	c3                   	ret    

f0100bdd <rcr0>:

static inline uint32_t
rcr0(void)
{
f0100bdd:	55                   	push   %ebp
f0100bde:	89 e5                	mov    %esp,%ebp
	uint32_t val;
	asm volatile("movl %%cr0,%0" : "=r" (val));
f0100be0:	0f 20 c0             	mov    %cr0,%eax
	return val;
}
f0100be3:	5d                   	pop    %ebp
f0100be4:	c3                   	ret    

f0100be5 <lcr3>:
	return val;
}

static inline void
lcr3(uint32_t val)
{
f0100be5:	55                   	push   %ebp
f0100be6:	89 e5                	mov    %esp,%ebp
	asm volatile("movl %0,%%cr3" : : "r" (val));
f0100be8:	0f 22 d8             	mov    %eax,%cr3
}
f0100beb:	5d                   	pop    %ebp
f0100bec:	c3                   	ret    

f0100bed <page2pa>:
int	user_mem_check(struct Env *env, const void *va, size_t len, int perm);
void	user_mem_assert(struct Env *env, const void *va, size_t len, int perm);

static inline physaddr_t
page2pa(struct PageInfo *pp)
{
f0100bed:	55                   	push   %ebp
f0100bee:	89 e5                	mov    %esp,%ebp
	return (pp - pages) << PGSHIFT;
f0100bf0:	2b 05 10 6f 28 f0    	sub    0xf0286f10,%eax
f0100bf6:	c1 f8 03             	sar    $0x3,%eax
f0100bf9:	c1 e0 0c             	shl    $0xc,%eax
}
f0100bfc:	5d                   	pop    %ebp
f0100bfd:	c3                   	ret    

f0100bfe <nvram_read>:
// Detect machine's physical memory setup.
// --------------------------------------------------------------

static int
nvram_read(int r)
{
f0100bfe:	55                   	push   %ebp
f0100bff:	89 e5                	mov    %esp,%ebp
f0100c01:	56                   	push   %esi
f0100c02:	53                   	push   %ebx
f0100c03:	89 c3                	mov    %eax,%ebx
	return mc146818_read(r) | (mc146818_read(r + 1) << 8);
f0100c05:	83 ec 0c             	sub    $0xc,%esp
f0100c08:	50                   	push   %eax
f0100c09:	e8 5b 2a 00 00       	call   f0103669 <mc146818_read>
f0100c0e:	89 c6                	mov    %eax,%esi
f0100c10:	83 c3 01             	add    $0x1,%ebx
f0100c13:	89 1c 24             	mov    %ebx,(%esp)
f0100c16:	e8 4e 2a 00 00       	call   f0103669 <mc146818_read>
f0100c1b:	c1 e0 08             	shl    $0x8,%eax
f0100c1e:	09 f0                	or     %esi,%eax
}
f0100c20:	8d 65 f8             	lea    -0x8(%ebp),%esp
f0100c23:	5b                   	pop    %ebx
f0100c24:	5e                   	pop    %esi
f0100c25:	5d                   	pop    %ebp
f0100c26:	c3                   	ret    

f0100c27 <i386_detect_memory>:

static void
i386_detect_memory(void)
{
f0100c27:	55                   	push   %ebp
f0100c28:	89 e5                	mov    %esp,%ebp
f0100c2a:	56                   	push   %esi
f0100c2b:	53                   	push   %ebx
	size_t basemem, extmem, ext16mem, totalmem;

	// Use CMOS calls to measure available base & extended memory.
	// (CMOS calls return results in kilobytes.)
	basemem = nvram_read(NVRAM_BASELO);
f0100c2c:	b8 15 00 00 00       	mov    $0x15,%eax
f0100c31:	e8 c8 ff ff ff       	call   f0100bfe <nvram_read>
f0100c36:	89 c3                	mov    %eax,%ebx
	extmem = nvram_read(NVRAM_EXTLO);
f0100c38:	b8 17 00 00 00       	mov    $0x17,%eax
f0100c3d:	e8 bc ff ff ff       	call   f0100bfe <nvram_read>
f0100c42:	89 c6                	mov    %eax,%esi
	ext16mem = nvram_read(NVRAM_EXT16LO) * 64;
f0100c44:	b8 34 00 00 00       	mov    $0x34,%eax
f0100c49:	e8 b0 ff ff ff       	call   f0100bfe <nvram_read>
f0100c4e:	c1 e0 06             	shl    $0x6,%eax

	// Calculate the number of physical pages available in both base
	// and extended memory.
	if (ext16mem)
f0100c51:	85 c0                	test   %eax,%eax
f0100c53:	74 07                	je     f0100c5c <i386_detect_memory+0x35>
		totalmem = 16 * 1024 + ext16mem;
f0100c55:	05 00 40 00 00       	add    $0x4000,%eax
f0100c5a:	eb 0b                	jmp    f0100c67 <i386_detect_memory+0x40>
	else if (extmem)
		totalmem = 1 * 1024 + extmem;
f0100c5c:	8d 86 00 04 00 00    	lea    0x400(%esi),%eax
f0100c62:	85 f6                	test   %esi,%esi
f0100c64:	0f 44 c3             	cmove  %ebx,%eax
	else
		totalmem = basemem;

	npages = totalmem / (PGSIZE / 1024);
f0100c67:	89 c2                	mov    %eax,%edx
f0100c69:	c1 ea 02             	shr    $0x2,%edx
f0100c6c:	89 15 08 6f 28 f0    	mov    %edx,0xf0286f08
	npages_basemem = basemem / (PGSIZE / 1024);

	cprintf("Physical memory: %uK available, base = %uK, extended = %uK\n",
f0100c72:	89 c2                	mov    %eax,%edx
f0100c74:	29 da                	sub    %ebx,%edx
f0100c76:	52                   	push   %edx
f0100c77:	53                   	push   %ebx
f0100c78:	50                   	push   %eax
f0100c79:	68 64 62 10 f0       	push   $0xf0106264
f0100c7e:	e8 ec 2b 00 00       	call   f010386f <cprintf>
		totalmem, basemem, totalmem - basemem);
}
f0100c83:	83 c4 10             	add    $0x10,%esp
f0100c86:	8d 65 f8             	lea    -0x8(%ebp),%esp
f0100c89:	5b                   	pop    %ebx
f0100c8a:	5e                   	pop    %esi
f0100c8b:	5d                   	pop    %ebp
f0100c8c:	c3                   	ret    

f0100c8d <_kaddr>:
 * virtual address.  It panics if you pass an invalid physical address. */
#define KADDR(pa) _kaddr(__FILE__, __LINE__, pa)

static inline void*
_kaddr(const char *file, int line, physaddr_t pa)
{
f0100c8d:	55                   	push   %ebp
f0100c8e:	89 e5                	mov    %esp,%ebp
f0100c90:	53                   	push   %ebx
f0100c91:	83 ec 04             	sub    $0x4,%esp
	if (PGNUM(pa) >= npages)
f0100c94:	89 cb                	mov    %ecx,%ebx
f0100c96:	c1 eb 0c             	shr    $0xc,%ebx
f0100c99:	3b 1d 08 6f 28 f0    	cmp    0xf0286f08,%ebx
f0100c9f:	72 0d                	jb     f0100cae <_kaddr+0x21>
		_panic(file, line, "KADDR called with invalid pa %08lx", pa);
f0100ca1:	51                   	push   %ecx
f0100ca2:	68 ec 5c 10 f0       	push   $0xf0105cec
f0100ca7:	52                   	push   %edx
f0100ca8:	50                   	push   %eax
f0100ca9:	e8 af f3 ff ff       	call   f010005d <_panic>
	return (void *)(pa + KERNBASE);
f0100cae:	8d 81 00 00 00 f0    	lea    -0x10000000(%ecx),%eax
}
f0100cb4:	8b 5d fc             	mov    -0x4(%ebp),%ebx
f0100cb7:	c9                   	leave  
f0100cb8:	c3                   	ret    

f0100cb9 <page2kva>:
	return &pages[PGNUM(pa)];
}

static inline void*
page2kva(struct PageInfo *pp)
{
f0100cb9:	55                   	push   %ebp
f0100cba:	89 e5                	mov    %esp,%ebp
f0100cbc:	83 ec 08             	sub    $0x8,%esp
	return KADDR(page2pa(pp));
f0100cbf:	e8 29 ff ff ff       	call   f0100bed <page2pa>
f0100cc4:	89 c1                	mov    %eax,%ecx
f0100cc6:	ba 58 00 00 00       	mov    $0x58,%edx
f0100ccb:	b8 b1 6b 10 f0       	mov    $0xf0106bb1,%eax
f0100cd0:	e8 b8 ff ff ff       	call   f0100c8d <_kaddr>
}
f0100cd5:	c9                   	leave  
f0100cd6:	c3                   	ret    

f0100cd7 <check_va2pa>:
check_va2pa(pde_t *pgdir, uintptr_t va)
{
	pte_t *p;

	pgdir = &pgdir[PDX(va)];
	if (!(*pgdir & PTE_P))
f0100cd7:	89 d1                	mov    %edx,%ecx
f0100cd9:	c1 e9 16             	shr    $0x16,%ecx
f0100cdc:	8b 0c 88             	mov    (%eax,%ecx,4),%ecx
f0100cdf:	f6 c1 01             	test   $0x1,%cl
f0100ce2:	74 57                	je     f0100d3b <check_va2pa+0x64>
		return ~0;
	if (*pgdir & PTE_PS)
f0100ce4:	f6 c1 80             	test   $0x80,%cl
f0100ce7:	74 10                	je     f0100cf9 <check_va2pa+0x22>
		return (physaddr_t) PGADDR(PDX(*pgdir), PTX(va), PGOFF(va));
f0100ce9:	89 d0                	mov    %edx,%eax
f0100ceb:	25 ff ff 3f 00       	and    $0x3fffff,%eax
f0100cf0:	81 e1 00 00 c0 ff    	and    $0xffc00000,%ecx
f0100cf6:	09 c8                	or     %ecx,%eax
f0100cf8:	c3                   	ret    
// this functionality for us!  We define our own version to help check
// the check_kern_pgdir() function; it shouldn't be used elsewhere.

static physaddr_t
check_va2pa(pde_t *pgdir, uintptr_t va)
{
f0100cf9:	55                   	push   %ebp
f0100cfa:	89 e5                	mov    %esp,%ebp
f0100cfc:	53                   	push   %ebx
f0100cfd:	83 ec 04             	sub    $0x4,%esp
f0100d00:	89 d3                	mov    %edx,%ebx
	pgdir = &pgdir[PDX(va)];
	if (!(*pgdir & PTE_P))
		return ~0;
	if (*pgdir & PTE_PS)
		return (physaddr_t) PGADDR(PDX(*pgdir), PTX(va), PGOFF(va));
	p = (pte_t*) KADDR(PTE_ADDR(*pgdir));
f0100d02:	81 e1 00 f0 ff ff    	and    $0xfffff000,%ecx
f0100d08:	ba 91 03 00 00       	mov    $0x391,%edx
f0100d0d:	b8 bf 6b 10 f0       	mov    $0xf0106bbf,%eax
f0100d12:	e8 76 ff ff ff       	call   f0100c8d <_kaddr>
	if (!(p[PTX(va)] & PTE_P))
f0100d17:	c1 eb 0c             	shr    $0xc,%ebx
f0100d1a:	89 da                	mov    %ebx,%edx
f0100d1c:	81 e2 ff 03 00 00    	and    $0x3ff,%edx
f0100d22:	8b 04 90             	mov    (%eax,%edx,4),%eax
f0100d25:	89 c2                	mov    %eax,%edx
f0100d27:	83 e2 01             	and    $0x1,%edx
		return ~0;
	return PTE_ADDR(p[PTX(va)]);
f0100d2a:	25 00 f0 ff ff       	and    $0xfffff000,%eax
f0100d2f:	85 d2                	test   %edx,%edx
f0100d31:	b9 ff ff ff ff       	mov    $0xffffffff,%ecx
f0100d36:	0f 44 c1             	cmove  %ecx,%eax
f0100d39:	eb 06                	jmp    f0100d41 <check_va2pa+0x6a>
{
	pte_t *p;

	pgdir = &pgdir[PDX(va)];
	if (!(*pgdir & PTE_P))
		return ~0;
f0100d3b:	b8 ff ff ff ff       	mov    $0xffffffff,%eax
f0100d40:	c3                   	ret    
		return (physaddr_t) PGADDR(PDX(*pgdir), PTX(va), PGOFF(va));
	p = (pte_t*) KADDR(PTE_ADDR(*pgdir));
	if (!(p[PTX(va)] & PTE_P))
		return ~0;
	return PTE_ADDR(p[PTX(va)]);
}
f0100d41:	83 c4 04             	add    $0x4,%esp
f0100d44:	5b                   	pop    %ebx
f0100d45:	5d                   	pop    %ebp
f0100d46:	c3                   	ret    

f0100d47 <_paddr>:
#define PADDR(kva) _paddr(__FILE__, __LINE__, kva)

static inline physaddr_t
_paddr(const char *file, int line, void *kva)
{
	if ((uint32_t)kva < KERNBASE)
f0100d47:	81 f9 ff ff ff ef    	cmp    $0xefffffff,%ecx
f0100d4d:	77 13                	ja     f0100d62 <_paddr+0x1b>
 */
#define PADDR(kva) _paddr(__FILE__, __LINE__, kva)

static inline physaddr_t
_paddr(const char *file, int line, void *kva)
{
f0100d4f:	55                   	push   %ebp
f0100d50:	89 e5                	mov    %esp,%ebp
f0100d52:	83 ec 08             	sub    $0x8,%esp
	if ((uint32_t)kva < KERNBASE)
		_panic(file, line, "PADDR called with invalid kva %08lx", kva);
f0100d55:	51                   	push   %ecx
f0100d56:	68 10 5d 10 f0       	push   $0xf0105d10
f0100d5b:	52                   	push   %edx
f0100d5c:	50                   	push   %eax
f0100d5d:	e8 fb f2 ff ff       	call   f010005d <_panic>
	return (physaddr_t)kva - KERNBASE;
f0100d62:	8d 81 00 00 00 10    	lea    0x10000000(%ecx),%eax
}
f0100d68:	c3                   	ret    

f0100d69 <boot_alloc>:
	// Initialize nextfree if this is the first time.
	// 'end' is a magic symbol automatically generated by the linker,
	// which points to the end of the kernel's bss segment:
	// the first virtual address that the linker did *not* assign
	// to any kernel code or global variables.
	if (!nextfree) {
f0100d69:	83 3d 38 52 28 f0 00 	cmpl   $0x0,0xf0285238
f0100d70:	75 11                	jne    f0100d83 <boot_alloc+0x1a>
		extern char end[];
		nextfree = ROUNDUP((char *) end, PGSIZE);
f0100d72:	ba 07 90 2c f0       	mov    $0xf02c9007,%edx
f0100d77:	81 e2 00 f0 ff ff    	and    $0xfffff000,%edx
f0100d7d:	89 15 38 52 28 f0    	mov    %edx,0xf0285238
	// Allocate a chunk large enough to hold 'n' bytes, then update
	// nextfree.  Make sure nextfree is kept aligned
	// to a multiple of PGSIZE.
	//
	// LAB 2: Your code here.
	if (n==0) return nextfree;
f0100d83:	85 c0                	test   %eax,%eax
f0100d85:	75 06                	jne    f0100d8d <boot_alloc+0x24>
f0100d87:	a1 38 52 28 f0       	mov    0xf0285238,%eax
	//n>0 (n<0 no deberia ocurrir por precond)
	result = nextfree;
	nextfree += ROUNDUP(n,PGSIZE);
	if (PADDR(nextfree)>npages*PGSIZE) panic("not enough memory\n");
	return (void*) result;
}
f0100d8c:	c3                   	ret    
// If we're out of memory, boot_alloc should panic.
// This function may ONLY be used during initialization,
// before the page_free_list list has been set up.
static void *
boot_alloc(uint32_t n)
{
f0100d8d:	55                   	push   %ebp
f0100d8e:	89 e5                	mov    %esp,%ebp
f0100d90:	53                   	push   %ebx
f0100d91:	83 ec 04             	sub    $0x4,%esp
	// to a multiple of PGSIZE.
	//
	// LAB 2: Your code here.
	if (n==0) return nextfree;
	//n>0 (n<0 no deberia ocurrir por precond)
	result = nextfree;
f0100d94:	8b 1d 38 52 28 f0    	mov    0xf0285238,%ebx
	nextfree += ROUNDUP(n,PGSIZE);
f0100d9a:	8d 88 ff 0f 00 00    	lea    0xfff(%eax),%ecx
f0100da0:	81 e1 00 f0 ff ff    	and    $0xfffff000,%ecx
f0100da6:	01 d9                	add    %ebx,%ecx
f0100da8:	89 0d 38 52 28 f0    	mov    %ecx,0xf0285238
	if (PADDR(nextfree)>npages*PGSIZE) panic("not enough memory\n");
f0100dae:	ba 70 00 00 00       	mov    $0x70,%edx
f0100db3:	b8 bf 6b 10 f0       	mov    $0xf0106bbf,%eax
f0100db8:	e8 8a ff ff ff       	call   f0100d47 <_paddr>
f0100dbd:	8b 15 08 6f 28 f0    	mov    0xf0286f08,%edx
f0100dc3:	c1 e2 0c             	shl    $0xc,%edx
f0100dc6:	39 d0                	cmp    %edx,%eax
f0100dc8:	76 14                	jbe    f0100dde <boot_alloc+0x75>
f0100dca:	83 ec 04             	sub    $0x4,%esp
f0100dcd:	68 cb 6b 10 f0       	push   $0xf0106bcb
f0100dd2:	6a 70                	push   $0x70
f0100dd4:	68 bf 6b 10 f0       	push   $0xf0106bbf
f0100dd9:	e8 7f f2 ff ff       	call   f010005d <_panic>
	return (void*) result;
f0100dde:	89 d8                	mov    %ebx,%eax
}
f0100de0:	8b 5d fc             	mov    -0x4(%ebp),%ebx
f0100de3:	c9                   	leave  
f0100de4:	c3                   	ret    

f0100de5 <check_kern_pgdir>:
// but it is a pretty good sanity check.
//

static void
check_kern_pgdir(void)
{
f0100de5:	55                   	push   %ebp
f0100de6:	89 e5                	mov    %esp,%ebp
f0100de8:	57                   	push   %edi
f0100de9:	56                   	push   %esi
f0100dea:	53                   	push   %ebx
f0100deb:	83 ec 1c             	sub    $0x1c,%esp
	uint32_t i, n;
	pde_t *pgdir;

	pgdir = kern_pgdir;
f0100dee:	8b 3d 0c 6f 28 f0    	mov    0xf0286f0c,%edi

	// check pages array
	n = ROUNDUP(npages*sizeof(struct PageInfo), PGSIZE);
f0100df4:	a1 08 6f 28 f0       	mov    0xf0286f08,%eax
f0100df9:	89 45 dc             	mov    %eax,-0x24(%ebp)
f0100dfc:	8d 04 c5 ff 0f 00 00 	lea    0xfff(,%eax,8),%eax
f0100e03:	25 00 f0 ff ff       	and    $0xfffff000,%eax
f0100e08:	89 45 e4             	mov    %eax,-0x1c(%ebp)
	for (i = 0; i < n; i += PGSIZE)
		assert(check_va2pa(pgdir, UPAGES + i) == PADDR(pages) + i);
f0100e0b:	a1 10 6f 28 f0       	mov    0xf0286f10,%eax
f0100e10:	89 45 e0             	mov    %eax,-0x20(%ebp)

	pgdir = kern_pgdir;

	// check pages array
	n = ROUNDUP(npages*sizeof(struct PageInfo), PGSIZE);
	for (i = 0; i < n; i += PGSIZE)
f0100e13:	bb 00 00 00 00       	mov    $0x0,%ebx
f0100e18:	eb 46                	jmp    f0100e60 <check_kern_pgdir+0x7b>
		assert(check_va2pa(pgdir, UPAGES + i) == PADDR(pages) + i);
f0100e1a:	8d 93 00 00 00 ef    	lea    -0x11000000(%ebx),%edx
f0100e20:	89 f8                	mov    %edi,%eax
f0100e22:	e8 b0 fe ff ff       	call   f0100cd7 <check_va2pa>
f0100e27:	89 c6                	mov    %eax,%esi
f0100e29:	8b 4d e0             	mov    -0x20(%ebp),%ecx
f0100e2c:	ba 4c 03 00 00       	mov    $0x34c,%edx
f0100e31:	b8 bf 6b 10 f0       	mov    $0xf0106bbf,%eax
f0100e36:	e8 0c ff ff ff       	call   f0100d47 <_paddr>
f0100e3b:	01 d8                	add    %ebx,%eax
f0100e3d:	39 c6                	cmp    %eax,%esi
f0100e3f:	74 19                	je     f0100e5a <check_kern_pgdir+0x75>
f0100e41:	68 a0 62 10 f0       	push   $0xf01062a0
f0100e46:	68 de 6b 10 f0       	push   $0xf0106bde
f0100e4b:	68 4c 03 00 00       	push   $0x34c
f0100e50:	68 bf 6b 10 f0       	push   $0xf0106bbf
f0100e55:	e8 03 f2 ff ff       	call   f010005d <_panic>

	pgdir = kern_pgdir;

	// check pages array
	n = ROUNDUP(npages*sizeof(struct PageInfo), PGSIZE);
	for (i = 0; i < n; i += PGSIZE)
f0100e5a:	81 c3 00 10 00 00    	add    $0x1000,%ebx
f0100e60:	3b 5d e4             	cmp    -0x1c(%ebp),%ebx
f0100e63:	72 b5                	jb     f0100e1a <check_kern_pgdir+0x35>
		assert(check_va2pa(pgdir, UPAGES + i) == PADDR(pages) + i);

	// check envs array (new test for lab 3)
	n = ROUNDUP(NENV*sizeof(struct Env), PGSIZE);
	for (i = 0; i < n; i += PGSIZE)
		assert(check_va2pa(pgdir, UENVS + i) == PADDR(envs) + i);
f0100e65:	a1 44 52 28 f0       	mov    0xf0285244,%eax
f0100e6a:	89 45 e4             	mov    %eax,-0x1c(%ebp)
f0100e6d:	bb 00 00 00 00       	mov    $0x0,%ebx
f0100e72:	8d 93 00 00 c0 ee    	lea    -0x11400000(%ebx),%edx
f0100e78:	89 f8                	mov    %edi,%eax
f0100e7a:	e8 58 fe ff ff       	call   f0100cd7 <check_va2pa>
f0100e7f:	89 c6                	mov    %eax,%esi
f0100e81:	8b 4d e4             	mov    -0x1c(%ebp),%ecx
f0100e84:	ba 51 03 00 00       	mov    $0x351,%edx
f0100e89:	b8 bf 6b 10 f0       	mov    $0xf0106bbf,%eax
f0100e8e:	e8 b4 fe ff ff       	call   f0100d47 <_paddr>
f0100e93:	01 d8                	add    %ebx,%eax
f0100e95:	39 c6                	cmp    %eax,%esi
f0100e97:	74 19                	je     f0100eb2 <check_kern_pgdir+0xcd>
f0100e99:	68 d4 62 10 f0       	push   $0xf01062d4
f0100e9e:	68 de 6b 10 f0       	push   $0xf0106bde
f0100ea3:	68 51 03 00 00       	push   $0x351
f0100ea8:	68 bf 6b 10 f0       	push   $0xf0106bbf
f0100ead:	e8 ab f1 ff ff       	call   f010005d <_panic>
	for (i = 0; i < n; i += PGSIZE)
		assert(check_va2pa(pgdir, UPAGES + i) == PADDR(pages) + i);

	// check envs array (new test for lab 3)
	n = ROUNDUP(NENV*sizeof(struct Env), PGSIZE);
	for (i = 0; i < n; i += PGSIZE)
f0100eb2:	81 c3 00 10 00 00    	add    $0x1000,%ebx
f0100eb8:	81 fb 00 f0 01 00    	cmp    $0x1f000,%ebx
f0100ebe:	75 b2                	jne    f0100e72 <check_kern_pgdir+0x8d>
		assert(check_va2pa(pgdir, UENVS + i) == PADDR(envs) + i);

	// check phys mem
	for (i = 0; i < npages * PGSIZE; i += PGSIZE)
f0100ec0:	8b 75 dc             	mov    -0x24(%ebp),%esi
f0100ec3:	c1 e6 0c             	shl    $0xc,%esi
f0100ec6:	bb 00 00 00 00       	mov    $0x0,%ebx
f0100ecb:	eb 30                	jmp    f0100efd <check_kern_pgdir+0x118>
		assert(check_va2pa(pgdir, KERNBASE + i) == i);
f0100ecd:	8d 93 00 00 00 f0    	lea    -0x10000000(%ebx),%edx
f0100ed3:	89 f8                	mov    %edi,%eax
f0100ed5:	e8 fd fd ff ff       	call   f0100cd7 <check_va2pa>
f0100eda:	39 c3                	cmp    %eax,%ebx
f0100edc:	74 19                	je     f0100ef7 <check_kern_pgdir+0x112>
f0100ede:	68 08 63 10 f0       	push   $0xf0106308
f0100ee3:	68 de 6b 10 f0       	push   $0xf0106bde
f0100ee8:	68 55 03 00 00       	push   $0x355
f0100eed:	68 bf 6b 10 f0       	push   $0xf0106bbf
f0100ef2:	e8 66 f1 ff ff       	call   f010005d <_panic>
	n = ROUNDUP(NENV*sizeof(struct Env), PGSIZE);
	for (i = 0; i < n; i += PGSIZE)
		assert(check_va2pa(pgdir, UENVS + i) == PADDR(envs) + i);

	// check phys mem
	for (i = 0; i < npages * PGSIZE; i += PGSIZE)
f0100ef7:	81 c3 00 10 00 00    	add    $0x1000,%ebx
f0100efd:	39 f3                	cmp    %esi,%ebx
f0100eff:	72 cc                	jb     f0100ecd <check_kern_pgdir+0xe8>
f0100f01:	c7 45 e0 00 80 28 f0 	movl   $0xf0288000,-0x20(%ebp)
f0100f08:	be 00 80 ff ef       	mov    $0xefff8000,%esi

	// check kernel stack
	// (updated in lab 4 to check per-CPU kernel stacks)
	for (n = 0; n < NCPU; n++) {
		uint32_t base = KSTACKTOP - (KSTKSIZE + KSTKGAP) * (n + 1);
		for (i = 0; i < KSTKSIZE; i += PGSIZE)
f0100f0d:	bb 00 00 00 00       	mov    $0x0,%ebx
			assert(check_va2pa(pgdir, base + KSTKGAP + i)
f0100f12:	8d 14 1e             	lea    (%esi,%ebx,1),%edx
f0100f15:	89 f8                	mov    %edi,%eax
f0100f17:	e8 bb fd ff ff       	call   f0100cd7 <check_va2pa>
f0100f1c:	89 45 e4             	mov    %eax,-0x1c(%ebp)
f0100f1f:	8b 4d e0             	mov    -0x20(%ebp),%ecx
f0100f22:	ba 5d 03 00 00       	mov    $0x35d,%edx
f0100f27:	b8 bf 6b 10 f0       	mov    $0xf0106bbf,%eax
f0100f2c:	e8 16 fe ff ff       	call   f0100d47 <_paddr>
f0100f31:	01 d8                	add    %ebx,%eax
f0100f33:	39 45 e4             	cmp    %eax,-0x1c(%ebp)
f0100f36:	74 19                	je     f0100f51 <check_kern_pgdir+0x16c>
f0100f38:	68 30 63 10 f0       	push   $0xf0106330
f0100f3d:	68 de 6b 10 f0       	push   $0xf0106bde
f0100f42:	68 5d 03 00 00       	push   $0x35d
f0100f47:	68 bf 6b 10 f0       	push   $0xf0106bbf
f0100f4c:	e8 0c f1 ff ff       	call   f010005d <_panic>

	// check kernel stack
	// (updated in lab 4 to check per-CPU kernel stacks)
	for (n = 0; n < NCPU; n++) {
		uint32_t base = KSTACKTOP - (KSTKSIZE + KSTKGAP) * (n + 1);
		for (i = 0; i < KSTKSIZE; i += PGSIZE)
f0100f51:	81 c3 00 10 00 00    	add    $0x1000,%ebx
f0100f57:	81 fb 00 80 00 00    	cmp    $0x8000,%ebx
f0100f5d:	75 b3                	jne    f0100f12 <check_kern_pgdir+0x12d>
f0100f5f:	8d 9e 00 80 ff ff    	lea    -0x8000(%esi),%ebx
			assert(check_va2pa(pgdir, base + KSTKGAP + i)
				== PADDR(percpu_kstacks[n]) + i);
		for (i = 0; i < KSTKGAP; i += PGSIZE)
			assert(check_va2pa(pgdir, base + i) == ~0);
f0100f65:	89 da                	mov    %ebx,%edx
f0100f67:	89 f8                	mov    %edi,%eax
f0100f69:	e8 69 fd ff ff       	call   f0100cd7 <check_va2pa>
f0100f6e:	83 f8 ff             	cmp    $0xffffffff,%eax
f0100f71:	74 19                	je     f0100f8c <check_kern_pgdir+0x1a7>
f0100f73:	68 78 63 10 f0       	push   $0xf0106378
f0100f78:	68 de 6b 10 f0       	push   $0xf0106bde
f0100f7d:	68 5f 03 00 00       	push   $0x35f
f0100f82:	68 bf 6b 10 f0       	push   $0xf0106bbf
f0100f87:	e8 d1 f0 ff ff       	call   f010005d <_panic>
f0100f8c:	81 c3 00 10 00 00    	add    $0x1000,%ebx
	for (n = 0; n < NCPU; n++) {
		uint32_t base = KSTACKTOP - (KSTKSIZE + KSTKGAP) * (n + 1);
		for (i = 0; i < KSTKSIZE; i += PGSIZE)
			assert(check_va2pa(pgdir, base + KSTKGAP + i)
				== PADDR(percpu_kstacks[n]) + i);
		for (i = 0; i < KSTKGAP; i += PGSIZE)
f0100f92:	39 de                	cmp    %ebx,%esi
f0100f94:	75 cf                	jne    f0100f65 <check_kern_pgdir+0x180>
f0100f96:	81 ee 00 00 01 00    	sub    $0x10000,%esi
f0100f9c:	81 45 e0 00 80 00 00 	addl   $0x8000,-0x20(%ebp)
	for (i = 0; i < npages * PGSIZE; i += PGSIZE)
		assert(check_va2pa(pgdir, KERNBASE + i) == i);

	// check kernel stack
	// (updated in lab 4 to check per-CPU kernel stacks)
	for (n = 0; n < NCPU; n++) {
f0100fa3:	81 fe 00 80 f7 ef    	cmp    $0xeff78000,%esi
f0100fa9:	0f 85 5e ff ff ff    	jne    f0100f0d <check_kern_pgdir+0x128>
f0100faf:	b8 00 00 00 00       	mov    $0x0,%eax
f0100fb4:	eb 2a                	jmp    f0100fe0 <check_kern_pgdir+0x1fb>
			assert(check_va2pa(pgdir, base + i) == ~0);
	}

	// check PDE permissions
	for (i = 0; i < NPDENTRIES; i++) {
		switch (i) {
f0100fb6:	8d 90 45 fc ff ff    	lea    -0x3bb(%eax),%edx
f0100fbc:	83 fa 04             	cmp    $0x4,%edx
f0100fbf:	77 1f                	ja     f0100fe0 <check_kern_pgdir+0x1fb>
		case PDX(UVPT):
		case PDX(KSTACKTOP-1):
		case PDX(UPAGES):
		case PDX(UENVS):
		case PDX(MMIOBASE):
			assert(pgdir[i] & PTE_P);
f0100fc1:	f6 04 87 01          	testb  $0x1,(%edi,%eax,4)
f0100fc5:	75 7e                	jne    f0101045 <check_kern_pgdir+0x260>
f0100fc7:	68 f3 6b 10 f0       	push   $0xf0106bf3
f0100fcc:	68 de 6b 10 f0       	push   $0xf0106bde
f0100fd1:	68 6a 03 00 00       	push   $0x36a
f0100fd6:	68 bf 6b 10 f0       	push   $0xf0106bbf
f0100fdb:	e8 7d f0 ff ff       	call   f010005d <_panic>
			break;
		default:
			if (i >= PDX(KERNBASE)) {
f0100fe0:	3d bf 03 00 00       	cmp    $0x3bf,%eax
f0100fe5:	76 3f                	jbe    f0101026 <check_kern_pgdir+0x241>
				assert(pgdir[i] & PTE_P);
f0100fe7:	8b 14 87             	mov    (%edi,%eax,4),%edx
f0100fea:	f6 c2 01             	test   $0x1,%dl
f0100fed:	75 19                	jne    f0101008 <check_kern_pgdir+0x223>
f0100fef:	68 f3 6b 10 f0       	push   $0xf0106bf3
f0100ff4:	68 de 6b 10 f0       	push   $0xf0106bde
f0100ff9:	68 6e 03 00 00       	push   $0x36e
f0100ffe:	68 bf 6b 10 f0       	push   $0xf0106bbf
f0101003:	e8 55 f0 ff ff       	call   f010005d <_panic>
				assert(pgdir[i] & PTE_W);
f0101008:	f6 c2 02             	test   $0x2,%dl
f010100b:	75 38                	jne    f0101045 <check_kern_pgdir+0x260>
f010100d:	68 04 6c 10 f0       	push   $0xf0106c04
f0101012:	68 de 6b 10 f0       	push   $0xf0106bde
f0101017:	68 6f 03 00 00       	push   $0x36f
f010101c:	68 bf 6b 10 f0       	push   $0xf0106bbf
f0101021:	e8 37 f0 ff ff       	call   f010005d <_panic>
			} else
				assert(pgdir[i] == 0);
f0101026:	83 3c 87 00          	cmpl   $0x0,(%edi,%eax,4)
f010102a:	74 19                	je     f0101045 <check_kern_pgdir+0x260>
f010102c:	68 15 6c 10 f0       	push   $0xf0106c15
f0101031:	68 de 6b 10 f0       	push   $0xf0106bde
f0101036:	68 71 03 00 00       	push   $0x371
f010103b:	68 bf 6b 10 f0       	push   $0xf0106bbf
f0101040:	e8 18 f0 ff ff       	call   f010005d <_panic>
		for (i = 0; i < KSTKGAP; i += PGSIZE)
			assert(check_va2pa(pgdir, base + i) == ~0);
	}

	// check PDE permissions
	for (i = 0; i < NPDENTRIES; i++) {
f0101045:	83 c0 01             	add    $0x1,%eax
f0101048:	3d ff 03 00 00       	cmp    $0x3ff,%eax
f010104d:	0f 86 63 ff ff ff    	jbe    f0100fb6 <check_kern_pgdir+0x1d1>
			} else
				assert(pgdir[i] == 0);
			break;
		}
	}
	cprintf("check_kern_pgdir() succeeded!\n");
f0101053:	83 ec 0c             	sub    $0xc,%esp
f0101056:	68 9c 63 10 f0       	push   $0xf010639c
f010105b:	e8 0f 28 00 00       	call   f010386f <cprintf>
			assert(PTE_ADDR(pgdir[i]) == (i - kern_pdx) << PDXSHIFT);
		}
		cprintf("check_kern_pgdir_pse() succeeded!\n");
	#endif

}
f0101060:	83 c4 10             	add    $0x10,%esp
f0101063:	8d 65 f4             	lea    -0xc(%ebp),%esp
f0101066:	5b                   	pop    %ebx
f0101067:	5e                   	pop    %esi
f0101068:	5f                   	pop    %edi
f0101069:	5d                   	pop    %ebp
f010106a:	c3                   	ret    

f010106b <check_page_free_list>:
//
// Check that the pages on the page_free_list are reasonable.
//
static void
check_page_free_list(bool only_low_memory)
{
f010106b:	55                   	push   %ebp
f010106c:	89 e5                	mov    %esp,%ebp
f010106e:	57                   	push   %edi
f010106f:	56                   	push   %esi
f0101070:	53                   	push   %ebx
f0101071:	83 ec 3c             	sub    $0x3c,%esp
	struct PageInfo *pp;
	unsigned pdx_limit = only_low_memory ? 1 : NPDENTRIES;
f0101074:	84 c0                	test   %al,%al
f0101076:	0f 85 6c 02 00 00    	jne    f01012e8 <check_page_free_list+0x27d>
f010107c:	e9 7a 02 00 00       	jmp    f01012fb <check_page_free_list+0x290>
	int nfree_basemem = 0, nfree_extmem = 0;
	char *first_free_page;

	if (!page_free_list)
		panic("'page_free_list' is a null pointer!");
f0101081:	83 ec 04             	sub    $0x4,%esp
f0101084:	68 bc 63 10 f0       	push   $0xf01063bc
f0101089:	68 b8 02 00 00       	push   $0x2b8
f010108e:	68 bf 6b 10 f0       	push   $0xf0106bbf
f0101093:	e8 c5 ef ff ff       	call   f010005d <_panic>

	if (only_low_memory) {
		// Move pages with lower addresses first in the free
		// list, since entry_pgdir does not map all pages.
		struct PageInfo *pp1, *pp2;
		struct PageInfo **tp[2] = { &pp1, &pp2 };
f0101098:	8d 45 d8             	lea    -0x28(%ebp),%eax
f010109b:	89 45 e0             	mov    %eax,-0x20(%ebp)
f010109e:	8d 45 dc             	lea    -0x24(%ebp),%eax
f01010a1:	89 45 e4             	mov    %eax,-0x1c(%ebp)
		for (pp = page_free_list; pp; pp = pp->pp_link) {
			int pagetype = PDX(page2pa(pp)) >= pdx_limit;
f01010a4:	89 d8                	mov    %ebx,%eax
f01010a6:	e8 42 fb ff ff       	call   f0100bed <page2pa>
f01010ab:	c1 e8 16             	shr    $0x16,%eax
f01010ae:	85 c0                	test   %eax,%eax
f01010b0:	0f 95 c0             	setne  %al
f01010b3:	0f b6 c0             	movzbl %al,%eax
			*tp[pagetype] = pp;
f01010b6:	8b 54 85 e0          	mov    -0x20(%ebp,%eax,4),%edx
f01010ba:	89 1a                	mov    %ebx,(%edx)
			tp[pagetype] = &pp->pp_link;
f01010bc:	89 5c 85 e0          	mov    %ebx,-0x20(%ebp,%eax,4)
	if (only_low_memory) {
		// Move pages with lower addresses first in the free
		// list, since entry_pgdir does not map all pages.
		struct PageInfo *pp1, *pp2;
		struct PageInfo **tp[2] = { &pp1, &pp2 };
		for (pp = page_free_list; pp; pp = pp->pp_link) {
f01010c0:	8b 1b                	mov    (%ebx),%ebx
f01010c2:	85 db                	test   %ebx,%ebx
f01010c4:	75 de                	jne    f01010a4 <check_page_free_list+0x39>
			int pagetype = PDX(page2pa(pp)) >= pdx_limit;
			*tp[pagetype] = pp;
			tp[pagetype] = &pp->pp_link;
		}
		*tp[1] = 0;
f01010c6:	8b 45 e4             	mov    -0x1c(%ebp),%eax
f01010c9:	c7 00 00 00 00 00    	movl   $0x0,(%eax)
		*tp[0] = pp2;
f01010cf:	8b 45 e0             	mov    -0x20(%ebp),%eax
f01010d2:	8b 55 dc             	mov    -0x24(%ebp),%edx
f01010d5:	89 10                	mov    %edx,(%eax)
		page_free_list = pp1;
f01010d7:	8b 45 d8             	mov    -0x28(%ebp),%eax
f01010da:	a3 40 52 28 f0       	mov    %eax,0xf0285240
//
static void
check_page_free_list(bool only_low_memory)
{
	struct PageInfo *pp;
	unsigned pdx_limit = only_low_memory ? 1 : NPDENTRIES;
f01010df:	be 01 00 00 00       	mov    $0x1,%esi
		page_free_list = pp1;
	}

	// if there's a page that shouldn't be on the free list,
	// try to make sure it eventually causes trouble.
	for (pp = page_free_list; pp; pp = pp->pp_link)
f01010e4:	8b 1d 40 52 28 f0    	mov    0xf0285240,%ebx
f01010ea:	eb 2d                	jmp    f0101119 <check_page_free_list+0xae>
		if (PDX(page2pa(pp)) < pdx_limit)
f01010ec:	89 d8                	mov    %ebx,%eax
f01010ee:	e8 fa fa ff ff       	call   f0100bed <page2pa>
f01010f3:	c1 e8 16             	shr    $0x16,%eax
f01010f6:	39 f0                	cmp    %esi,%eax
f01010f8:	73 1d                	jae    f0101117 <check_page_free_list+0xac>
			memset(page2kva(pp), 0x97, 128);
f01010fa:	89 d8                	mov    %ebx,%eax
f01010fc:	e8 b8 fb ff ff       	call   f0100cb9 <page2kva>
f0101101:	83 ec 04             	sub    $0x4,%esp
f0101104:	68 80 00 00 00       	push   $0x80
f0101109:	68 97 00 00 00       	push   $0x97
f010110e:	50                   	push   %eax
f010110f:	e8 65 3e 00 00       	call   f0104f79 <memset>
f0101114:	83 c4 10             	add    $0x10,%esp
		page_free_list = pp1;
	}

	// if there's a page that shouldn't be on the free list,
	// try to make sure it eventually causes trouble.
	for (pp = page_free_list; pp; pp = pp->pp_link)
f0101117:	8b 1b                	mov    (%ebx),%ebx
f0101119:	85 db                	test   %ebx,%ebx
f010111b:	75 cf                	jne    f01010ec <check_page_free_list+0x81>
		if (PDX(page2pa(pp)) < pdx_limit)
			memset(page2kva(pp), 0x97, 128);

	first_free_page = (char *) boot_alloc(0);
f010111d:	b8 00 00 00 00       	mov    $0x0,%eax
f0101122:	e8 42 fc ff ff       	call   f0100d69 <boot_alloc>
f0101127:	89 45 c4             	mov    %eax,-0x3c(%ebp)
	for (pp = page_free_list; pp; pp = pp->pp_link) {
f010112a:	8b 1d 40 52 28 f0    	mov    0xf0285240,%ebx
		// check that we didn't corrupt the free list itself
		assert(pp >= pages);
f0101130:	8b 3d 10 6f 28 f0    	mov    0xf0286f10,%edi
		assert(pp < pages + npages);
f0101136:	a1 08 6f 28 f0       	mov    0xf0286f08,%eax
f010113b:	8d 04 c7             	lea    (%edi,%eax,8),%eax
f010113e:	89 45 d4             	mov    %eax,-0x2c(%ebp)
		assert(((char *) pp - (char *) pages) % sizeof(*pp) == 0);
f0101141:	89 7d d0             	mov    %edi,-0x30(%ebp)
static void
check_page_free_list(bool only_low_memory)
{
	struct PageInfo *pp;
	unsigned pdx_limit = only_low_memory ? 1 : NPDENTRIES;
	int nfree_basemem = 0, nfree_extmem = 0;
f0101144:	c7 45 c8 00 00 00 00 	movl   $0x0,-0x38(%ebp)
f010114b:	c7 45 cc 00 00 00 00 	movl   $0x0,-0x34(%ebp)
	for (pp = page_free_list; pp; pp = pp->pp_link)
		if (PDX(page2pa(pp)) < pdx_limit)
			memset(page2kva(pp), 0x97, 128);

	first_free_page = (char *) boot_alloc(0);
	for (pp = page_free_list; pp; pp = pp->pp_link) {
f0101152:	e9 3c 01 00 00       	jmp    f0101293 <check_page_free_list+0x228>
		// check that we didn't corrupt the free list itself
		assert(pp >= pages);
f0101157:	39 fb                	cmp    %edi,%ebx
f0101159:	73 19                	jae    f0101174 <check_page_free_list+0x109>
f010115b:	68 23 6c 10 f0       	push   $0xf0106c23
f0101160:	68 de 6b 10 f0       	push   $0xf0106bde
f0101165:	68 d2 02 00 00       	push   $0x2d2
f010116a:	68 bf 6b 10 f0       	push   $0xf0106bbf
f010116f:	e8 e9 ee ff ff       	call   f010005d <_panic>
		assert(pp < pages + npages);
f0101174:	3b 5d d4             	cmp    -0x2c(%ebp),%ebx
f0101177:	72 19                	jb     f0101192 <check_page_free_list+0x127>
f0101179:	68 2f 6c 10 f0       	push   $0xf0106c2f
f010117e:	68 de 6b 10 f0       	push   $0xf0106bde
f0101183:	68 d3 02 00 00       	push   $0x2d3
f0101188:	68 bf 6b 10 f0       	push   $0xf0106bbf
f010118d:	e8 cb ee ff ff       	call   f010005d <_panic>
		assert(((char *) pp - (char *) pages) % sizeof(*pp) == 0);
f0101192:	89 d8                	mov    %ebx,%eax
f0101194:	2b 45 d0             	sub    -0x30(%ebp),%eax
f0101197:	a8 07                	test   $0x7,%al
f0101199:	74 19                	je     f01011b4 <check_page_free_list+0x149>
f010119b:	68 e0 63 10 f0       	push   $0xf01063e0
f01011a0:	68 de 6b 10 f0       	push   $0xf0106bde
f01011a5:	68 d4 02 00 00       	push   $0x2d4
f01011aa:	68 bf 6b 10 f0       	push   $0xf0106bbf
f01011af:	e8 a9 ee ff ff       	call   f010005d <_panic>

		// check a few pages that shouldn't be on the free list
		assert(page2pa(pp) != 0);
f01011b4:	89 d8                	mov    %ebx,%eax
f01011b6:	e8 32 fa ff ff       	call   f0100bed <page2pa>
f01011bb:	89 c6                	mov    %eax,%esi
f01011bd:	85 c0                	test   %eax,%eax
f01011bf:	75 19                	jne    f01011da <check_page_free_list+0x16f>
f01011c1:	68 43 6c 10 f0       	push   $0xf0106c43
f01011c6:	68 de 6b 10 f0       	push   $0xf0106bde
f01011cb:	68 d7 02 00 00       	push   $0x2d7
f01011d0:	68 bf 6b 10 f0       	push   $0xf0106bbf
f01011d5:	e8 83 ee ff ff       	call   f010005d <_panic>
		assert(page2pa(pp) != IOPHYSMEM);
f01011da:	3d 00 00 0a 00       	cmp    $0xa0000,%eax
f01011df:	75 19                	jne    f01011fa <check_page_free_list+0x18f>
f01011e1:	68 54 6c 10 f0       	push   $0xf0106c54
f01011e6:	68 de 6b 10 f0       	push   $0xf0106bde
f01011eb:	68 d8 02 00 00       	push   $0x2d8
f01011f0:	68 bf 6b 10 f0       	push   $0xf0106bbf
f01011f5:	e8 63 ee ff ff       	call   f010005d <_panic>
		assert(page2pa(pp) != EXTPHYSMEM - PGSIZE);
f01011fa:	3d 00 f0 0f 00       	cmp    $0xff000,%eax
f01011ff:	75 19                	jne    f010121a <check_page_free_list+0x1af>
f0101201:	68 14 64 10 f0       	push   $0xf0106414
f0101206:	68 de 6b 10 f0       	push   $0xf0106bde
f010120b:	68 d9 02 00 00       	push   $0x2d9
f0101210:	68 bf 6b 10 f0       	push   $0xf0106bbf
f0101215:	e8 43 ee ff ff       	call   f010005d <_panic>
		assert(page2pa(pp) != EXTPHYSMEM);
f010121a:	3d 00 00 10 00       	cmp    $0x100000,%eax
f010121f:	75 19                	jne    f010123a <check_page_free_list+0x1cf>
f0101221:	68 6d 6c 10 f0       	push   $0xf0106c6d
f0101226:	68 de 6b 10 f0       	push   $0xf0106bde
f010122b:	68 da 02 00 00       	push   $0x2da
f0101230:	68 bf 6b 10 f0       	push   $0xf0106bbf
f0101235:	e8 23 ee ff ff       	call   f010005d <_panic>
		assert(page2pa(pp) < EXTPHYSMEM || (char *) page2kva(pp) >= first_free_page);
f010123a:	3d ff ff 0f 00       	cmp    $0xfffff,%eax
f010123f:	0f 86 cd 00 00 00    	jbe    f0101312 <check_page_free_list+0x2a7>
f0101245:	89 d8                	mov    %ebx,%eax
f0101247:	e8 6d fa ff ff       	call   f0100cb9 <page2kva>
f010124c:	39 45 c4             	cmp    %eax,-0x3c(%ebp)
f010124f:	0f 86 cd 00 00 00    	jbe    f0101322 <check_page_free_list+0x2b7>
f0101255:	68 38 64 10 f0       	push   $0xf0106438
f010125a:	68 de 6b 10 f0       	push   $0xf0106bde
f010125f:	68 db 02 00 00       	push   $0x2db
f0101264:	68 bf 6b 10 f0       	push   $0xf0106bbf
f0101269:	e8 ef ed ff ff       	call   f010005d <_panic>
		// (new test for lab 4)
		assert(page2pa(pp) != MPENTRY_PADDR);
f010126e:	68 87 6c 10 f0       	push   $0xf0106c87
f0101273:	68 de 6b 10 f0       	push   $0xf0106bde
f0101278:	68 dd 02 00 00       	push   $0x2dd
f010127d:	68 bf 6b 10 f0       	push   $0xf0106bbf
f0101282:	e8 d6 ed ff ff       	call   f010005d <_panic>

		if (page2pa(pp) < EXTPHYSMEM)
			++nfree_basemem;
f0101287:	83 45 cc 01          	addl   $0x1,-0x34(%ebp)
f010128b:	eb 04                	jmp    f0101291 <check_page_free_list+0x226>
		else
			++nfree_extmem;
f010128d:	83 45 c8 01          	addl   $0x1,-0x38(%ebp)
	for (pp = page_free_list; pp; pp = pp->pp_link)
		if (PDX(page2pa(pp)) < pdx_limit)
			memset(page2kva(pp), 0x97, 128);

	first_free_page = (char *) boot_alloc(0);
	for (pp = page_free_list; pp; pp = pp->pp_link) {
f0101291:	8b 1b                	mov    (%ebx),%ebx
f0101293:	85 db                	test   %ebx,%ebx
f0101295:	0f 85 bc fe ff ff    	jne    f0101157 <check_page_free_list+0xec>
			++nfree_basemem;
		else
			++nfree_extmem;
	}

	assert(nfree_basemem > 0);
f010129b:	83 7d cc 00          	cmpl   $0x0,-0x34(%ebp)
f010129f:	7f 19                	jg     f01012ba <check_page_free_list+0x24f>
f01012a1:	68 a4 6c 10 f0       	push   $0xf0106ca4
f01012a6:	68 de 6b 10 f0       	push   $0xf0106bde
f01012ab:	68 e5 02 00 00       	push   $0x2e5
f01012b0:	68 bf 6b 10 f0       	push   $0xf0106bbf
f01012b5:	e8 a3 ed ff ff       	call   f010005d <_panic>
	assert(nfree_extmem > 0);
f01012ba:	83 7d c8 00          	cmpl   $0x0,-0x38(%ebp)
f01012be:	7f 19                	jg     f01012d9 <check_page_free_list+0x26e>
f01012c0:	68 b6 6c 10 f0       	push   $0xf0106cb6
f01012c5:	68 de 6b 10 f0       	push   $0xf0106bde
f01012ca:	68 e6 02 00 00       	push   $0x2e6
f01012cf:	68 bf 6b 10 f0       	push   $0xf0106bbf
f01012d4:	e8 84 ed ff ff       	call   f010005d <_panic>

	cprintf("check_page_free_list() succeeded!\n");
f01012d9:	83 ec 0c             	sub    $0xc,%esp
f01012dc:	68 80 64 10 f0       	push   $0xf0106480
f01012e1:	e8 89 25 00 00       	call   f010386f <cprintf>
}
f01012e6:	eb 4b                	jmp    f0101333 <check_page_free_list+0x2c8>
	struct PageInfo *pp;
	unsigned pdx_limit = only_low_memory ? 1 : NPDENTRIES;
	int nfree_basemem = 0, nfree_extmem = 0;
	char *first_free_page;

	if (!page_free_list)
f01012e8:	8b 1d 40 52 28 f0    	mov    0xf0285240,%ebx
f01012ee:	85 db                	test   %ebx,%ebx
f01012f0:	0f 85 a2 fd ff ff    	jne    f0101098 <check_page_free_list+0x2d>
f01012f6:	e9 86 fd ff ff       	jmp    f0101081 <check_page_free_list+0x16>
f01012fb:	83 3d 40 52 28 f0 00 	cmpl   $0x0,0xf0285240
f0101302:	0f 84 79 fd ff ff    	je     f0101081 <check_page_free_list+0x16>
//
static void
check_page_free_list(bool only_low_memory)
{
	struct PageInfo *pp;
	unsigned pdx_limit = only_low_memory ? 1 : NPDENTRIES;
f0101308:	be 00 04 00 00       	mov    $0x400,%esi
f010130d:	e9 d2 fd ff ff       	jmp    f01010e4 <check_page_free_list+0x79>
		assert(page2pa(pp) != IOPHYSMEM);
		assert(page2pa(pp) != EXTPHYSMEM - PGSIZE);
		assert(page2pa(pp) != EXTPHYSMEM);
		assert(page2pa(pp) < EXTPHYSMEM || (char *) page2kva(pp) >= first_free_page);
		// (new test for lab 4)
		assert(page2pa(pp) != MPENTRY_PADDR);
f0101312:	3d 00 70 00 00       	cmp    $0x7000,%eax
f0101317:	0f 85 6a ff ff ff    	jne    f0101287 <check_page_free_list+0x21c>
f010131d:	e9 4c ff ff ff       	jmp    f010126e <check_page_free_list+0x203>
f0101322:	81 fe 00 70 00 00    	cmp    $0x7000,%esi
f0101328:	0f 85 5f ff ff ff    	jne    f010128d <check_page_free_list+0x222>
f010132e:	e9 3b ff ff ff       	jmp    f010126e <check_page_free_list+0x203>

	assert(nfree_basemem > 0);
	assert(nfree_extmem > 0);

	cprintf("check_page_free_list() succeeded!\n");
}
f0101333:	8d 65 f4             	lea    -0xc(%ebp),%esp
f0101336:	5b                   	pop    %ebx
f0101337:	5e                   	pop    %esi
f0101338:	5f                   	pop    %edi
f0101339:	5d                   	pop    %ebp
f010133a:	c3                   	ret    

f010133b <pa2page>:
}

static inline struct PageInfo*
pa2page(physaddr_t pa)
{
	if (PGNUM(pa) >= npages)
f010133b:	c1 e8 0c             	shr    $0xc,%eax
f010133e:	3b 05 08 6f 28 f0    	cmp    0xf0286f08,%eax
f0101344:	72 17                	jb     f010135d <pa2page+0x22>
	return (pp - pages) << PGSHIFT;
}

static inline struct PageInfo*
pa2page(physaddr_t pa)
{
f0101346:	55                   	push   %ebp
f0101347:	89 e5                	mov    %esp,%ebp
f0101349:	83 ec 0c             	sub    $0xc,%esp
	if (PGNUM(pa) >= npages)
		panic("pa2page called with invalid pa");
f010134c:	68 a4 64 10 f0       	push   $0xf01064a4
f0101351:	6a 51                	push   $0x51
f0101353:	68 b1 6b 10 f0       	push   $0xf0106bb1
f0101358:	e8 00 ed ff ff       	call   f010005d <_panic>
	return &pages[PGNUM(pa)];
f010135d:	8b 15 10 6f 28 f0    	mov    0xf0286f10,%edx
f0101363:	8d 04 c2             	lea    (%edx,%eax,8),%eax
}
f0101366:	c3                   	ret    

f0101367 <page_init>:
// allocator functions below to allocate and deallocate physical
// memory via the page_free_list.
//
void
page_init(void)
{
f0101367:	55                   	push   %ebp
f0101368:	89 e5                	mov    %esp,%ebp
f010136a:	57                   	push   %edi
f010136b:	56                   	push   %esi
f010136c:	53                   	push   %ebx
f010136d:	83 ec 0c             	sub    $0xc,%esp
	// NB: DO NOT actually touch the physical memory corresponding to
	// free pages!
	size_t i;
	uint32_t lim_inf_IO = PGNUM(IOPHYSMEM);//==npages_basemem
	//uint32_t lim_sup_IO = PGNUM(EXTPHYSMEM); //no hace falta por lim_sup_kernmem > lim_sup_IO
	uint32_t lim_sup_kernmem = PGNUM(PADDR(boot_alloc(0)));
f0101370:	b8 00 00 00 00       	mov    $0x0,%eax
f0101375:	e8 ef f9 ff ff       	call   f0100d69 <boot_alloc>
f010137a:	89 c1                	mov    %eax,%ecx
f010137c:	ba 42 01 00 00       	mov    $0x142,%edx
f0101381:	b8 bf 6b 10 f0       	mov    $0xf0106bbf,%eax
f0101386:	e8 bc f9 ff ff       	call   f0100d47 <_paddr>
f010138b:	c1 e8 0c             	shr    $0xc,%eax
f010138e:	8b 35 40 52 28 f0    	mov    0xf0285240,%esi
	for (i = 1; i < npages; i++) {//la 0 no se agrega tampoco
f0101394:	bf 00 00 00 00       	mov    $0x0,%edi
f0101399:	ba 01 00 00 00       	mov    $0x1,%edx
f010139e:	eb 3e                	jmp    f01013de <page_init+0x77>
		if ((i>=lim_inf_IO && i<lim_sup_kernmem) || i == PGNUM(MPENTRY_PADDR)) continue;//asi es como se no-mapea		
f01013a0:	81 fa 9f 00 00 00    	cmp    $0x9f,%edx
f01013a6:	0f 97 c3             	seta   %bl
f01013a9:	39 c2                	cmp    %eax,%edx
f01013ab:	0f 92 c1             	setb   %cl
f01013ae:	84 cb                	test   %cl,%bl
f01013b0:	75 29                	jne    f01013db <page_init+0x74>
f01013b2:	83 fa 07             	cmp    $0x7,%edx
f01013b5:	74 24                	je     f01013db <page_init+0x74>
		pages[i].pp_ref = 0;
f01013b7:	8d 0c d5 00 00 00 00 	lea    0x0(,%edx,8),%ecx
f01013be:	89 cb                	mov    %ecx,%ebx
f01013c0:	03 1d 10 6f 28 f0    	add    0xf0286f10,%ebx
f01013c6:	66 c7 43 04 00 00    	movw   $0x0,0x4(%ebx)
		pages[i].pp_link = page_free_list;
f01013cc:	89 33                	mov    %esi,(%ebx)
		page_free_list = &pages[i];
f01013ce:	89 ce                	mov    %ecx,%esi
f01013d0:	03 35 10 6f 28 f0    	add    0xf0286f10,%esi
f01013d6:	bf 01 00 00 00       	mov    $0x1,%edi
	// free pages!
	size_t i;
	uint32_t lim_inf_IO = PGNUM(IOPHYSMEM);//==npages_basemem
	//uint32_t lim_sup_IO = PGNUM(EXTPHYSMEM); //no hace falta por lim_sup_kernmem > lim_sup_IO
	uint32_t lim_sup_kernmem = PGNUM(PADDR(boot_alloc(0)));
	for (i = 1; i < npages; i++) {//la 0 no se agrega tampoco
f01013db:	83 c2 01             	add    $0x1,%edx
f01013de:	3b 15 08 6f 28 f0    	cmp    0xf0286f08,%edx
f01013e4:	72 ba                	jb     f01013a0 <page_init+0x39>
f01013e6:	89 f8                	mov    %edi,%eax
f01013e8:	84 c0                	test   %al,%al
f01013ea:	74 06                	je     f01013f2 <page_init+0x8b>
f01013ec:	89 35 40 52 28 f0    	mov    %esi,0xf0285240
		if ((i>=lim_inf_IO && i<lim_sup_kernmem) || i == PGNUM(MPENTRY_PADDR)) continue;//asi es como se no-mapea		
		pages[i].pp_ref = 0;
		pages[i].pp_link = page_free_list;
		page_free_list = &pages[i];
	}
}
f01013f2:	83 c4 0c             	add    $0xc,%esp
f01013f5:	5b                   	pop    %ebx
f01013f6:	5e                   	pop    %esi
f01013f7:	5f                   	pop    %edi
f01013f8:	5d                   	pop    %ebp
f01013f9:	c3                   	ret    

f01013fa <page_alloc>:
// Returns NULL if out of free memory.
//
// Hint: use page2kva and memset
struct PageInfo *
page_alloc(int alloc_flags)
{	if (page_free_list == NULL) return NULL;
f01013fa:	55                   	push   %ebp
f01013fb:	89 e5                	mov    %esp,%ebp
f01013fd:	53                   	push   %ebx
f01013fe:	83 ec 04             	sub    $0x4,%esp
f0101401:	8b 1d 40 52 28 f0    	mov    0xf0285240,%ebx
f0101407:	85 db                	test   %ebx,%ebx
f0101409:	74 2d                	je     f0101438 <page_alloc+0x3e>
	struct PageInfo* pag = page_free_list;
	page_free_list = page_free_list->pp_link;
f010140b:	8b 03                	mov    (%ebx),%eax
f010140d:	a3 40 52 28 f0       	mov    %eax,0xf0285240
	pag->pp_link = NULL;
f0101412:	c7 03 00 00 00 00    	movl   $0x0,(%ebx)
	if (alloc_flags & ALLOC_ZERO) memset(page2kva(pag),0,PGSIZE);
f0101418:	f6 45 08 01          	testb  $0x1,0x8(%ebp)
f010141c:	74 1a                	je     f0101438 <page_alloc+0x3e>
f010141e:	89 d8                	mov    %ebx,%eax
f0101420:	e8 94 f8 ff ff       	call   f0100cb9 <page2kva>
f0101425:	83 ec 04             	sub    $0x4,%esp
f0101428:	68 00 10 00 00       	push   $0x1000
f010142d:	6a 00                	push   $0x0
f010142f:	50                   	push   %eax
f0101430:	e8 44 3b 00 00       	call   f0104f79 <memset>
f0101435:	83 c4 10             	add    $0x10,%esp
	return pag;
}
f0101438:	89 d8                	mov    %ebx,%eax
f010143a:	8b 5d fc             	mov    -0x4(%ebp),%ebx
f010143d:	c9                   	leave  
f010143e:	c3                   	ret    

f010143f <page_free>:
// Return a page to the free list.
// (This function should only be called when pp->pp_ref reaches 0.)
//
void
page_free(struct PageInfo *pp)
{
f010143f:	55                   	push   %ebp
f0101440:	89 e5                	mov    %esp,%ebp
f0101442:	83 ec 08             	sub    $0x8,%esp
f0101445:	8b 45 08             	mov    0x8(%ebp),%eax
	// Fill this function in
	// Hint: You may want to panic if pp->pp_ref is nonzero or
	// pp->pp_link is not NULL.
	if (pp->pp_ref) panic("page still in use!\n");
f0101448:	66 83 78 04 00       	cmpw   $0x0,0x4(%eax)
f010144d:	74 17                	je     f0101466 <page_free+0x27>
f010144f:	83 ec 04             	sub    $0x4,%esp
f0101452:	68 c7 6c 10 f0       	push   $0xf0106cc7
f0101457:	68 6b 01 00 00       	push   $0x16b
f010145c:	68 bf 6b 10 f0       	push   $0xf0106bbf
f0101461:	e8 f7 eb ff ff       	call   f010005d <_panic>
	if (pp->pp_link) panic("page has non-NULL pp_link (already freed?)\n");
f0101466:	83 38 00             	cmpl   $0x0,(%eax)
f0101469:	74 17                	je     f0101482 <page_free+0x43>
f010146b:	83 ec 04             	sub    $0x4,%esp
f010146e:	68 c4 64 10 f0       	push   $0xf01064c4
f0101473:	68 6c 01 00 00       	push   $0x16c
f0101478:	68 bf 6b 10 f0       	push   $0xf0106bbf
f010147d:	e8 db eb ff ff       	call   f010005d <_panic>
	//pp_ref=0,pp_link=NULL
	pp->pp_link=page_free_list;
f0101482:	8b 15 40 52 28 f0    	mov    0xf0285240,%edx
f0101488:	89 10                	mov    %edx,(%eax)
	page_free_list=pp;
f010148a:	a3 40 52 28 f0       	mov    %eax,0xf0285240
}
f010148f:	c9                   	leave  
f0101490:	c3                   	ret    

f0101491 <check_page_alloc>:
// Check the physical page allocator (page_alloc(), page_free(),
// and page_init()).
//
static void
check_page_alloc(void)
{
f0101491:	55                   	push   %ebp
f0101492:	89 e5                	mov    %esp,%ebp
f0101494:	57                   	push   %edi
f0101495:	56                   	push   %esi
f0101496:	53                   	push   %ebx
f0101497:	83 ec 1c             	sub    $0x1c,%esp
	int nfree;
	struct PageInfo *fl;
	char *c;
	int i;

	if (!pages)
f010149a:	83 3d 10 6f 28 f0 00 	cmpl   $0x0,0xf0286f10
f01014a1:	75 17                	jne    f01014ba <check_page_alloc+0x29>
		panic("'pages' is a null pointer!");
f01014a3:	83 ec 04             	sub    $0x4,%esp
f01014a6:	68 db 6c 10 f0       	push   $0xf0106cdb
f01014ab:	68 f9 02 00 00       	push   $0x2f9
f01014b0:	68 bf 6b 10 f0       	push   $0xf0106bbf
f01014b5:	e8 a3 eb ff ff       	call   f010005d <_panic>

	// check number of free pages
	for (pp = page_free_list, nfree = 0; pp; pp = pp->pp_link)
f01014ba:	a1 40 52 28 f0       	mov    0xf0285240,%eax
f01014bf:	be 00 00 00 00       	mov    $0x0,%esi
f01014c4:	eb 05                	jmp    f01014cb <check_page_alloc+0x3a>
		++nfree;
f01014c6:	83 c6 01             	add    $0x1,%esi

	if (!pages)
		panic("'pages' is a null pointer!");

	// check number of free pages
	for (pp = page_free_list, nfree = 0; pp; pp = pp->pp_link)
f01014c9:	8b 00                	mov    (%eax),%eax
f01014cb:	85 c0                	test   %eax,%eax
f01014cd:	75 f7                	jne    f01014c6 <check_page_alloc+0x35>
		++nfree;

	// should be able to allocate three pages
	pp0 = pp1 = pp2 = 0;
	assert((pp0 = page_alloc(0)));
f01014cf:	83 ec 0c             	sub    $0xc,%esp
f01014d2:	6a 00                	push   $0x0
f01014d4:	e8 21 ff ff ff       	call   f01013fa <page_alloc>
f01014d9:	89 c7                	mov    %eax,%edi
f01014db:	83 c4 10             	add    $0x10,%esp
f01014de:	85 c0                	test   %eax,%eax
f01014e0:	75 19                	jne    f01014fb <check_page_alloc+0x6a>
f01014e2:	68 f6 6c 10 f0       	push   $0xf0106cf6
f01014e7:	68 de 6b 10 f0       	push   $0xf0106bde
f01014ec:	68 01 03 00 00       	push   $0x301
f01014f1:	68 bf 6b 10 f0       	push   $0xf0106bbf
f01014f6:	e8 62 eb ff ff       	call   f010005d <_panic>
	assert((pp1 = page_alloc(0)));
f01014fb:	83 ec 0c             	sub    $0xc,%esp
f01014fe:	6a 00                	push   $0x0
f0101500:	e8 f5 fe ff ff       	call   f01013fa <page_alloc>
f0101505:	89 45 e4             	mov    %eax,-0x1c(%ebp)
f0101508:	83 c4 10             	add    $0x10,%esp
f010150b:	85 c0                	test   %eax,%eax
f010150d:	75 19                	jne    f0101528 <check_page_alloc+0x97>
f010150f:	68 0c 6d 10 f0       	push   $0xf0106d0c
f0101514:	68 de 6b 10 f0       	push   $0xf0106bde
f0101519:	68 02 03 00 00       	push   $0x302
f010151e:	68 bf 6b 10 f0       	push   $0xf0106bbf
f0101523:	e8 35 eb ff ff       	call   f010005d <_panic>
	assert((pp2 = page_alloc(0)));
f0101528:	83 ec 0c             	sub    $0xc,%esp
f010152b:	6a 00                	push   $0x0
f010152d:	e8 c8 fe ff ff       	call   f01013fa <page_alloc>
f0101532:	89 c3                	mov    %eax,%ebx
f0101534:	83 c4 10             	add    $0x10,%esp
f0101537:	85 c0                	test   %eax,%eax
f0101539:	75 19                	jne    f0101554 <check_page_alloc+0xc3>
f010153b:	68 22 6d 10 f0       	push   $0xf0106d22
f0101540:	68 de 6b 10 f0       	push   $0xf0106bde
f0101545:	68 03 03 00 00       	push   $0x303
f010154a:	68 bf 6b 10 f0       	push   $0xf0106bbf
f010154f:	e8 09 eb ff ff       	call   f010005d <_panic>

	assert(pp0);
	assert(pp1 && pp1 != pp0);
f0101554:	3b 7d e4             	cmp    -0x1c(%ebp),%edi
f0101557:	75 19                	jne    f0101572 <check_page_alloc+0xe1>
f0101559:	68 38 6d 10 f0       	push   $0xf0106d38
f010155e:	68 de 6b 10 f0       	push   $0xf0106bde
f0101563:	68 06 03 00 00       	push   $0x306
f0101568:	68 bf 6b 10 f0       	push   $0xf0106bbf
f010156d:	e8 eb ea ff ff       	call   f010005d <_panic>
	assert(pp2 && pp2 != pp1 && pp2 != pp0);
f0101572:	39 45 e4             	cmp    %eax,-0x1c(%ebp)
f0101575:	74 04                	je     f010157b <check_page_alloc+0xea>
f0101577:	39 c7                	cmp    %eax,%edi
f0101579:	75 19                	jne    f0101594 <check_page_alloc+0x103>
f010157b:	68 f0 64 10 f0       	push   $0xf01064f0
f0101580:	68 de 6b 10 f0       	push   $0xf0106bde
f0101585:	68 07 03 00 00       	push   $0x307
f010158a:	68 bf 6b 10 f0       	push   $0xf0106bbf
f010158f:	e8 c9 ea ff ff       	call   f010005d <_panic>
	assert(page2pa(pp0) < npages*PGSIZE);
f0101594:	89 f8                	mov    %edi,%eax
f0101596:	e8 52 f6 ff ff       	call   f0100bed <page2pa>
f010159b:	8b 0d 08 6f 28 f0    	mov    0xf0286f08,%ecx
f01015a1:	c1 e1 0c             	shl    $0xc,%ecx
f01015a4:	89 4d e0             	mov    %ecx,-0x20(%ebp)
f01015a7:	39 c8                	cmp    %ecx,%eax
f01015a9:	72 19                	jb     f01015c4 <check_page_alloc+0x133>
f01015ab:	68 4a 6d 10 f0       	push   $0xf0106d4a
f01015b0:	68 de 6b 10 f0       	push   $0xf0106bde
f01015b5:	68 08 03 00 00       	push   $0x308
f01015ba:	68 bf 6b 10 f0       	push   $0xf0106bbf
f01015bf:	e8 99 ea ff ff       	call   f010005d <_panic>
	assert(page2pa(pp1) < npages*PGSIZE);
f01015c4:	8b 45 e4             	mov    -0x1c(%ebp),%eax
f01015c7:	e8 21 f6 ff ff       	call   f0100bed <page2pa>
f01015cc:	39 45 e0             	cmp    %eax,-0x20(%ebp)
f01015cf:	77 19                	ja     f01015ea <check_page_alloc+0x159>
f01015d1:	68 67 6d 10 f0       	push   $0xf0106d67
f01015d6:	68 de 6b 10 f0       	push   $0xf0106bde
f01015db:	68 09 03 00 00       	push   $0x309
f01015e0:	68 bf 6b 10 f0       	push   $0xf0106bbf
f01015e5:	e8 73 ea ff ff       	call   f010005d <_panic>
	assert(page2pa(pp2) < npages*PGSIZE);
f01015ea:	89 d8                	mov    %ebx,%eax
f01015ec:	e8 fc f5 ff ff       	call   f0100bed <page2pa>
f01015f1:	39 45 e0             	cmp    %eax,-0x20(%ebp)
f01015f4:	77 19                	ja     f010160f <check_page_alloc+0x17e>
f01015f6:	68 84 6d 10 f0       	push   $0xf0106d84
f01015fb:	68 de 6b 10 f0       	push   $0xf0106bde
f0101600:	68 0a 03 00 00       	push   $0x30a
f0101605:	68 bf 6b 10 f0       	push   $0xf0106bbf
f010160a:	e8 4e ea ff ff       	call   f010005d <_panic>

	// temporarily steal the rest of the free pages
	fl = page_free_list;
f010160f:	a1 40 52 28 f0       	mov    0xf0285240,%eax
f0101614:	89 45 e0             	mov    %eax,-0x20(%ebp)
	page_free_list = 0;
f0101617:	c7 05 40 52 28 f0 00 	movl   $0x0,0xf0285240
f010161e:	00 00 00 

	// should be no free memory
	assert(!page_alloc(0));
f0101621:	83 ec 0c             	sub    $0xc,%esp
f0101624:	6a 00                	push   $0x0
f0101626:	e8 cf fd ff ff       	call   f01013fa <page_alloc>
f010162b:	83 c4 10             	add    $0x10,%esp
f010162e:	85 c0                	test   %eax,%eax
f0101630:	74 19                	je     f010164b <check_page_alloc+0x1ba>
f0101632:	68 a1 6d 10 f0       	push   $0xf0106da1
f0101637:	68 de 6b 10 f0       	push   $0xf0106bde
f010163c:	68 11 03 00 00       	push   $0x311
f0101641:	68 bf 6b 10 f0       	push   $0xf0106bbf
f0101646:	e8 12 ea ff ff       	call   f010005d <_panic>

	// free and re-allocate?
	page_free(pp0);
f010164b:	83 ec 0c             	sub    $0xc,%esp
f010164e:	57                   	push   %edi
f010164f:	e8 eb fd ff ff       	call   f010143f <page_free>
	page_free(pp1);
f0101654:	83 c4 04             	add    $0x4,%esp
f0101657:	ff 75 e4             	pushl  -0x1c(%ebp)
f010165a:	e8 e0 fd ff ff       	call   f010143f <page_free>
	page_free(pp2);
f010165f:	89 1c 24             	mov    %ebx,(%esp)
f0101662:	e8 d8 fd ff ff       	call   f010143f <page_free>
	pp0 = pp1 = pp2 = 0;
	assert((pp0 = page_alloc(0)));
f0101667:	c7 04 24 00 00 00 00 	movl   $0x0,(%esp)
f010166e:	e8 87 fd ff ff       	call   f01013fa <page_alloc>
f0101673:	89 c3                	mov    %eax,%ebx
f0101675:	83 c4 10             	add    $0x10,%esp
f0101678:	85 c0                	test   %eax,%eax
f010167a:	75 19                	jne    f0101695 <check_page_alloc+0x204>
f010167c:	68 f6 6c 10 f0       	push   $0xf0106cf6
f0101681:	68 de 6b 10 f0       	push   $0xf0106bde
f0101686:	68 18 03 00 00       	push   $0x318
f010168b:	68 bf 6b 10 f0       	push   $0xf0106bbf
f0101690:	e8 c8 e9 ff ff       	call   f010005d <_panic>
	assert((pp1 = page_alloc(0)));
f0101695:	83 ec 0c             	sub    $0xc,%esp
f0101698:	6a 00                	push   $0x0
f010169a:	e8 5b fd ff ff       	call   f01013fa <page_alloc>
f010169f:	89 45 e4             	mov    %eax,-0x1c(%ebp)
f01016a2:	83 c4 10             	add    $0x10,%esp
f01016a5:	85 c0                	test   %eax,%eax
f01016a7:	75 19                	jne    f01016c2 <check_page_alloc+0x231>
f01016a9:	68 0c 6d 10 f0       	push   $0xf0106d0c
f01016ae:	68 de 6b 10 f0       	push   $0xf0106bde
f01016b3:	68 19 03 00 00       	push   $0x319
f01016b8:	68 bf 6b 10 f0       	push   $0xf0106bbf
f01016bd:	e8 9b e9 ff ff       	call   f010005d <_panic>
	assert((pp2 = page_alloc(0)));
f01016c2:	83 ec 0c             	sub    $0xc,%esp
f01016c5:	6a 00                	push   $0x0
f01016c7:	e8 2e fd ff ff       	call   f01013fa <page_alloc>
f01016cc:	89 c7                	mov    %eax,%edi
f01016ce:	83 c4 10             	add    $0x10,%esp
f01016d1:	85 c0                	test   %eax,%eax
f01016d3:	75 19                	jne    f01016ee <check_page_alloc+0x25d>
f01016d5:	68 22 6d 10 f0       	push   $0xf0106d22
f01016da:	68 de 6b 10 f0       	push   $0xf0106bde
f01016df:	68 1a 03 00 00       	push   $0x31a
f01016e4:	68 bf 6b 10 f0       	push   $0xf0106bbf
f01016e9:	e8 6f e9 ff ff       	call   f010005d <_panic>
	assert(pp0);
	assert(pp1 && pp1 != pp0);
f01016ee:	3b 5d e4             	cmp    -0x1c(%ebp),%ebx
f01016f1:	75 19                	jne    f010170c <check_page_alloc+0x27b>
f01016f3:	68 38 6d 10 f0       	push   $0xf0106d38
f01016f8:	68 de 6b 10 f0       	push   $0xf0106bde
f01016fd:	68 1c 03 00 00       	push   $0x31c
f0101702:	68 bf 6b 10 f0       	push   $0xf0106bbf
f0101707:	e8 51 e9 ff ff       	call   f010005d <_panic>
	assert(pp2 && pp2 != pp1 && pp2 != pp0);
f010170c:	39 45 e4             	cmp    %eax,-0x1c(%ebp)
f010170f:	74 04                	je     f0101715 <check_page_alloc+0x284>
f0101711:	39 c3                	cmp    %eax,%ebx
f0101713:	75 19                	jne    f010172e <check_page_alloc+0x29d>
f0101715:	68 f0 64 10 f0       	push   $0xf01064f0
f010171a:	68 de 6b 10 f0       	push   $0xf0106bde
f010171f:	68 1d 03 00 00       	push   $0x31d
f0101724:	68 bf 6b 10 f0       	push   $0xf0106bbf
f0101729:	e8 2f e9 ff ff       	call   f010005d <_panic>
	assert(!page_alloc(0));
f010172e:	83 ec 0c             	sub    $0xc,%esp
f0101731:	6a 00                	push   $0x0
f0101733:	e8 c2 fc ff ff       	call   f01013fa <page_alloc>
f0101738:	83 c4 10             	add    $0x10,%esp
f010173b:	85 c0                	test   %eax,%eax
f010173d:	74 19                	je     f0101758 <check_page_alloc+0x2c7>
f010173f:	68 a1 6d 10 f0       	push   $0xf0106da1
f0101744:	68 de 6b 10 f0       	push   $0xf0106bde
f0101749:	68 1e 03 00 00       	push   $0x31e
f010174e:	68 bf 6b 10 f0       	push   $0xf0106bbf
f0101753:	e8 05 e9 ff ff       	call   f010005d <_panic>

	// test flags
	memset(page2kva(pp0), 1, PGSIZE);
f0101758:	89 d8                	mov    %ebx,%eax
f010175a:	e8 5a f5 ff ff       	call   f0100cb9 <page2kva>
f010175f:	83 ec 04             	sub    $0x4,%esp
f0101762:	68 00 10 00 00       	push   $0x1000
f0101767:	6a 01                	push   $0x1
f0101769:	50                   	push   %eax
f010176a:	e8 0a 38 00 00       	call   f0104f79 <memset>
	page_free(pp0);
f010176f:	89 1c 24             	mov    %ebx,(%esp)
f0101772:	e8 c8 fc ff ff       	call   f010143f <page_free>
	assert((pp = page_alloc(ALLOC_ZERO)));
f0101777:	c7 04 24 01 00 00 00 	movl   $0x1,(%esp)
f010177e:	e8 77 fc ff ff       	call   f01013fa <page_alloc>
f0101783:	83 c4 10             	add    $0x10,%esp
f0101786:	85 c0                	test   %eax,%eax
f0101788:	75 19                	jne    f01017a3 <check_page_alloc+0x312>
f010178a:	68 b0 6d 10 f0       	push   $0xf0106db0
f010178f:	68 de 6b 10 f0       	push   $0xf0106bde
f0101794:	68 23 03 00 00       	push   $0x323
f0101799:	68 bf 6b 10 f0       	push   $0xf0106bbf
f010179e:	e8 ba e8 ff ff       	call   f010005d <_panic>
	assert(pp && pp0 == pp);
f01017a3:	39 c3                	cmp    %eax,%ebx
f01017a5:	74 19                	je     f01017c0 <check_page_alloc+0x32f>
f01017a7:	68 ce 6d 10 f0       	push   $0xf0106dce
f01017ac:	68 de 6b 10 f0       	push   $0xf0106bde
f01017b1:	68 24 03 00 00       	push   $0x324
f01017b6:	68 bf 6b 10 f0       	push   $0xf0106bbf
f01017bb:	e8 9d e8 ff ff       	call   f010005d <_panic>
	c = page2kva(pp);
f01017c0:	89 d8                	mov    %ebx,%eax
f01017c2:	e8 f2 f4 ff ff       	call   f0100cb9 <page2kva>
f01017c7:	8d 90 00 10 00 00    	lea    0x1000(%eax),%edx
	for (i = 0; i < PGSIZE; i++)
		assert(c[i] == 0);
f01017cd:	80 38 00             	cmpb   $0x0,(%eax)
f01017d0:	74 19                	je     f01017eb <check_page_alloc+0x35a>
f01017d2:	68 de 6d 10 f0       	push   $0xf0106dde
f01017d7:	68 de 6b 10 f0       	push   $0xf0106bde
f01017dc:	68 27 03 00 00       	push   $0x327
f01017e1:	68 bf 6b 10 f0       	push   $0xf0106bbf
f01017e6:	e8 72 e8 ff ff       	call   f010005d <_panic>
f01017eb:	83 c0 01             	add    $0x1,%eax
	memset(page2kva(pp0), 1, PGSIZE);
	page_free(pp0);
	assert((pp = page_alloc(ALLOC_ZERO)));
	assert(pp && pp0 == pp);
	c = page2kva(pp);
	for (i = 0; i < PGSIZE; i++)
f01017ee:	39 d0                	cmp    %edx,%eax
f01017f0:	75 db                	jne    f01017cd <check_page_alloc+0x33c>
		assert(c[i] == 0);

	// give free list back
	page_free_list = fl;
f01017f2:	8b 45 e0             	mov    -0x20(%ebp),%eax
f01017f5:	a3 40 52 28 f0       	mov    %eax,0xf0285240

	// free the pages we took
	page_free(pp0);
f01017fa:	83 ec 0c             	sub    $0xc,%esp
f01017fd:	53                   	push   %ebx
f01017fe:	e8 3c fc ff ff       	call   f010143f <page_free>
	page_free(pp1);
f0101803:	83 c4 04             	add    $0x4,%esp
f0101806:	ff 75 e4             	pushl  -0x1c(%ebp)
f0101809:	e8 31 fc ff ff       	call   f010143f <page_free>
	page_free(pp2);
f010180e:	89 3c 24             	mov    %edi,(%esp)
f0101811:	e8 29 fc ff ff       	call   f010143f <page_free>

	// number of free pages should be the same
	for (pp = page_free_list; pp; pp = pp->pp_link)
f0101816:	a1 40 52 28 f0       	mov    0xf0285240,%eax
f010181b:	83 c4 10             	add    $0x10,%esp
f010181e:	eb 05                	jmp    f0101825 <check_page_alloc+0x394>
		--nfree;
f0101820:	83 ee 01             	sub    $0x1,%esi
	page_free(pp0);
	page_free(pp1);
	page_free(pp2);

	// number of free pages should be the same
	for (pp = page_free_list; pp; pp = pp->pp_link)
f0101823:	8b 00                	mov    (%eax),%eax
f0101825:	85 c0                	test   %eax,%eax
f0101827:	75 f7                	jne    f0101820 <check_page_alloc+0x38f>
		--nfree;
	assert(nfree == 0);
f0101829:	85 f6                	test   %esi,%esi
f010182b:	74 19                	je     f0101846 <check_page_alloc+0x3b5>
f010182d:	68 e8 6d 10 f0       	push   $0xf0106de8
f0101832:	68 de 6b 10 f0       	push   $0xf0106bde
f0101837:	68 34 03 00 00       	push   $0x334
f010183c:	68 bf 6b 10 f0       	push   $0xf0106bbf
f0101841:	e8 17 e8 ff ff       	call   f010005d <_panic>

	cprintf("check_page_alloc() succeeded!\n");
f0101846:	83 ec 0c             	sub    $0xc,%esp
f0101849:	68 10 65 10 f0       	push   $0xf0106510
f010184e:	e8 1c 20 00 00       	call   f010386f <cprintf>
}
f0101853:	83 c4 10             	add    $0x10,%esp
f0101856:	8d 65 f4             	lea    -0xc(%ebp),%esp
f0101859:	5b                   	pop    %ebx
f010185a:	5e                   	pop    %esi
f010185b:	5f                   	pop    %edi
f010185c:	5d                   	pop    %ebp
f010185d:	c3                   	ret    

f010185e <page_decref>:
// Decrement the reference count on a page,
// freeing it if there are no more refs.
//
void
page_decref(struct PageInfo* pp)
{
f010185e:	55                   	push   %ebp
f010185f:	89 e5                	mov    %esp,%ebp
f0101861:	83 ec 08             	sub    $0x8,%esp
f0101864:	8b 55 08             	mov    0x8(%ebp),%edx
	if (--pp->pp_ref == 0)
f0101867:	0f b7 42 04          	movzwl 0x4(%edx),%eax
f010186b:	83 e8 01             	sub    $0x1,%eax
f010186e:	66 89 42 04          	mov    %ax,0x4(%edx)
f0101872:	66 85 c0             	test   %ax,%ax
f0101875:	75 0c                	jne    f0101883 <page_decref+0x25>
		page_free(pp);
f0101877:	83 ec 0c             	sub    $0xc,%esp
f010187a:	52                   	push   %edx
f010187b:	e8 bf fb ff ff       	call   f010143f <page_free>
f0101880:	83 c4 10             	add    $0x10,%esp
}
f0101883:	c9                   	leave  
f0101884:	c3                   	ret    

f0101885 <pgdir_walk>:
// Hint 3: look at inc/mmu.h for useful macros that mainipulate page
// table and page directory entries.
//
pte_t *
pgdir_walk(pde_t *pgdir, const void *va, int create)
{
f0101885:	55                   	push   %ebp
f0101886:	89 e5                	mov    %esp,%ebp
f0101888:	57                   	push   %edi
f0101889:	56                   	push   %esi
f010188a:	53                   	push   %ebx
f010188b:	83 ec 0c             	sub    $0xc,%esp
f010188e:	8b 75 0c             	mov    0xc(%ebp),%esi
	pde_t pde =  pgdir[PDX(va)]; //ojo que esto es P.Addr. !!
f0101891:	89 f3                	mov    %esi,%ebx
f0101893:	c1 eb 16             	shr    $0x16,%ebx
f0101896:	c1 e3 02             	shl    $0x2,%ebx
f0101899:	03 5d 08             	add    0x8(%ebp),%ebx
f010189c:	8b 3b                	mov    (%ebx),%edi
	pte_t* pte = (pte_t*) KADDR(PTE_ADDR(pde));
f010189e:	89 f9                	mov    %edi,%ecx
f01018a0:	81 e1 00 f0 ff ff    	and    $0xfffff000,%ecx
f01018a6:	ba 97 01 00 00       	mov    $0x197,%edx
f01018ab:	b8 bf 6b 10 f0       	mov    $0xf0106bbf,%eax
f01018b0:	e8 d8 f3 ff ff       	call   f0100c8d <_kaddr>

	if (pde & PTE_P) return pte+PTX(va);
f01018b5:	f7 c7 01 00 00 00    	test   $0x1,%edi
f01018bb:	74 0d                	je     f01018ca <pgdir_walk+0x45>
f01018bd:	c1 ee 0a             	shr    $0xa,%esi
f01018c0:	81 e6 fc 0f 00 00    	and    $0xffc,%esi
f01018c6:	01 f0                	add    %esi,%eax
f01018c8:	eb 52                	jmp    f010191c <pgdir_walk+0x97>

	if (!create) return NULL;
f01018ca:	b8 00 00 00 00       	mov    $0x0,%eax
f01018cf:	83 7d 10 00          	cmpl   $0x0,0x10(%ebp)
f01018d3:	74 47                	je     f010191c <pgdir_walk+0x97>
	struct PageInfo *page = page_alloc(ALLOC_ZERO);
f01018d5:	83 ec 0c             	sub    $0xc,%esp
f01018d8:	6a 01                	push   $0x1
f01018da:	e8 1b fb ff ff       	call   f01013fa <page_alloc>
f01018df:	89 c7                	mov    %eax,%edi
	if (page==NULL) return NULL;
f01018e1:	83 c4 10             	add    $0x10,%esp
f01018e4:	85 c0                	test   %eax,%eax
f01018e6:	74 2f                	je     f0101917 <pgdir_walk+0x92>
	physaddr_t pt_start = page2pa(page);
f01018e8:	e8 00 f3 ff ff       	call   f0100bed <page2pa>
	page->pp_ref ++;
f01018ed:	66 83 47 04 01       	addw   $0x1,0x4(%edi)
	*(pgdir+PDX(va)) = pt_start | PTE_P | PTE_U | PTE_W;
f01018f2:	89 c2                	mov    %eax,%edx
f01018f4:	83 ca 07             	or     $0x7,%edx
f01018f7:	89 13                	mov    %edx,(%ebx)
	return (pte_t*)KADDR(pt_start)+PTX(va);
f01018f9:	89 c1                	mov    %eax,%ecx
f01018fb:	ba a1 01 00 00       	mov    $0x1a1,%edx
f0101900:	b8 bf 6b 10 f0       	mov    $0xf0106bbf,%eax
f0101905:	e8 83 f3 ff ff       	call   f0100c8d <_kaddr>
f010190a:	c1 ee 0a             	shr    $0xa,%esi
f010190d:	81 e6 fc 0f 00 00    	and    $0xffc,%esi
f0101913:	01 f0                	add    %esi,%eax
f0101915:	eb 05                	jmp    f010191c <pgdir_walk+0x97>

	if (pde & PTE_P) return pte+PTX(va);

	if (!create) return NULL;
	struct PageInfo *page = page_alloc(ALLOC_ZERO);
	if (page==NULL) return NULL;
f0101917:	b8 00 00 00 00       	mov    $0x0,%eax
	physaddr_t pt_start = page2pa(page);
	page->pp_ref ++;
	*(pgdir+PDX(va)) = pt_start | PTE_P | PTE_U | PTE_W;
	return (pte_t*)KADDR(pt_start)+PTX(va);
}
f010191c:	8d 65 f4             	lea    -0xc(%ebp),%esp
f010191f:	5b                   	pop    %ebx
f0101920:	5e                   	pop    %esi
f0101921:	5f                   	pop    %edi
f0101922:	5d                   	pop    %ebp
f0101923:	c3                   	ret    

f0101924 <boot_map_region>:
//
// Hint: the TA solution uses pgdir_walk
//#define TP1_PSE 1
static void
boot_map_region(pde_t *pgdir, uintptr_t va, size_t size, physaddr_t pa, int perm)
{
f0101924:	55                   	push   %ebp
f0101925:	89 e5                	mov    %esp,%ebp
f0101927:	57                   	push   %edi
f0101928:	56                   	push   %esi
f0101929:	53                   	push   %ebx
f010192a:	83 ec 1c             	sub    $0x1c,%esp
f010192d:	89 45 e0             	mov    %eax,-0x20(%ebp)
f0101930:	8b 45 08             	mov    0x8(%ebp),%eax
	assert(va % PGSIZE == 0);
f0101933:	f7 c2 ff 0f 00 00    	test   $0xfff,%edx
f0101939:	74 19                	je     f0101954 <boot_map_region+0x30>
f010193b:	68 f3 6d 10 f0       	push   $0xf0106df3
f0101940:	68 de 6b 10 f0       	push   $0xf0106bde
f0101945:	68 b3 01 00 00       	push   $0x1b3
f010194a:	68 bf 6b 10 f0       	push   $0xf0106bbf
f010194f:	e8 09 e7 ff ff       	call   f010005d <_panic>
f0101954:	89 cf                	mov    %ecx,%edi
	assert(pa % PGSIZE == 0);
f0101956:	a9 ff 0f 00 00       	test   $0xfff,%eax
f010195b:	74 19                	je     f0101976 <boot_map_region+0x52>
f010195d:	68 04 6e 10 f0       	push   $0xf0106e04
f0101962:	68 de 6b 10 f0       	push   $0xf0106bde
f0101967:	68 b4 01 00 00       	push   $0x1b4
f010196c:	68 bf 6b 10 f0       	push   $0xf0106bbf
f0101971:	e8 e7 e6 ff ff       	call   f010005d <_panic>
	assert(size % PGSIZE == 0);	
f0101976:	f7 c1 ff 0f 00 00    	test   $0xfff,%ecx
f010197c:	74 3d                	je     f01019bb <boot_map_region+0x97>
f010197e:	68 15 6e 10 f0       	push   $0xf0106e15
f0101983:	68 de 6b 10 f0       	push   $0xf0106bde
f0101988:	68 b5 01 00 00       	push   $0x1b5
f010198d:	68 bf 6b 10 f0       	push   $0xf0106bbf
f0101992:	e8 c6 e6 ff ff       	call   f010005d <_panic>
	//uint32_t cant_iteraciones = size/PGSIZE;
	//for (int i=0;i<cant_iteraciones;i++){//al ser iteraciones fijas no hay problema de overflow
	//physaddr_t pa_inicial = pa;	
	#ifndef TP1_PSE
		while(size){			
			pte_t* pte_addr = pgdir_walk(pgdir,(void*)va,true);
f0101997:	83 ec 04             	sub    $0x4,%esp
f010199a:	6a 01                	push   $0x1
f010199c:	53                   	push   %ebx
f010199d:	ff 75 e0             	pushl  -0x20(%ebp)
f01019a0:	e8 e0 fe ff ff       	call   f0101885 <pgdir_walk>
			*pte_addr = pa | perm | PTE_P;
f01019a5:	0b 75 dc             	or     -0x24(%ebp),%esi
f01019a8:	89 30                	mov    %esi,(%eax)
			size-=PGSIZE;		
f01019aa:	81 ef 00 10 00 00    	sub    $0x1000,%edi
			//incremento
			va+=PGSIZE;
f01019b0:	81 c3 00 10 00 00    	add    $0x1000,%ebx
f01019b6:	83 c4 10             	add    $0x10,%esp
f01019b9:	eb 10                	jmp    f01019cb <boot_map_region+0xa7>
f01019bb:	89 d3                	mov    %edx,%ebx
f01019bd:	29 d0                	sub    %edx,%eax
f01019bf:	89 45 e4             	mov    %eax,-0x1c(%ebp)
	//for (int i=0;i<cant_iteraciones;i++){//al ser iteraciones fijas no hay problema de overflow
	//physaddr_t pa_inicial = pa;	
	#ifndef TP1_PSE
		while(size){			
			pte_t* pte_addr = pgdir_walk(pgdir,(void*)va,true);
			*pte_addr = pa | perm | PTE_P;
f01019c2:	8b 45 0c             	mov    0xc(%ebp),%eax
f01019c5:	83 c8 01             	or     $0x1,%eax
f01019c8:	89 45 dc             	mov    %eax,-0x24(%ebp)
f01019cb:	8b 45 e4             	mov    -0x1c(%ebp),%eax
f01019ce:	8d 34 18             	lea    (%eax,%ebx,1),%esi

	//uint32_t cant_iteraciones = size/PGSIZE;
	//for (int i=0;i<cant_iteraciones;i++){//al ser iteraciones fijas no hay problema de overflow
	//physaddr_t pa_inicial = pa;	
	#ifndef TP1_PSE
		while(size){			
f01019d1:	85 ff                	test   %edi,%edi
f01019d3:	75 c2                	jne    f0101997 <boot_map_region+0x73>
				va+=PGSIZE;
				pa+=PGSIZE;
			}
		}
	#endif
}
f01019d5:	8d 65 f4             	lea    -0xc(%ebp),%esp
f01019d8:	5b                   	pop    %ebx
f01019d9:	5e                   	pop    %esi
f01019da:	5f                   	pop    %edi
f01019db:	5d                   	pop    %ebp
f01019dc:	c3                   	ret    

f01019dd <mem_init_mp>:
// Modify mappings in kern_pgdir to support SMP
//   - Map the per-CPU stacks in the region [KSTACKTOP-PTSIZE, KSTACKTOP)
//
static void
mem_init_mp(void)
{
f01019dd:	55                   	push   %ebp
f01019de:	89 e5                	mov    %esp,%ebp
f01019e0:	56                   	push   %esi
f01019e1:	53                   	push   %ebx
f01019e2:	be 00 80 28 f0       	mov    $0xf0288000,%esi
	//             it will fault rather than overwrite another CPU's stack.
	//             Known as a "guard page".
	//     Permissions: kernel RW, user NONE
	//
	// LAB 4: Your code here:
	uintptr_t kernelstack_va = KSTACKTOP - KSTKSIZE;
f01019e7:	bb 00 80 ff ef       	mov    $0xefff8000,%ebx
	for (int i = 0; i<NCPU; i++){
		//calcular posicion
		physaddr_t kstacktop_pa = PADDR(percpu_kstacks[i]);
f01019ec:	89 f1                	mov    %esi,%ecx
f01019ee:	ba 14 01 00 00       	mov    $0x114,%edx
f01019f3:	b8 bf 6b 10 f0       	mov    $0xf0106bbf,%eax
f01019f8:	e8 4a f3 ff ff       	call   f0100d47 <_paddr>
		boot_map_region(kern_pgdir, kernelstack_va, KSTKSIZE, kstacktop_pa, PTE_W|PTE_P);
f01019fd:	83 ec 08             	sub    $0x8,%esp
f0101a00:	6a 03                	push   $0x3
f0101a02:	50                   	push   %eax
f0101a03:	b9 00 80 00 00       	mov    $0x8000,%ecx
f0101a08:	89 da                	mov    %ebx,%edx
f0101a0a:	a1 0c 6f 28 f0       	mov    0xf0286f0c,%eax
f0101a0f:	e8 10 ff ff ff       	call   f0101924 <boot_map_region>
		kernelstack_va -= (KSTKSIZE + KSTKGAP);
f0101a14:	81 eb 00 00 01 00    	sub    $0x10000,%ebx
f0101a1a:	81 c6 00 80 00 00    	add    $0x8000,%esi
	//             Known as a "guard page".
	//     Permissions: kernel RW, user NONE
	//
	// LAB 4: Your code here:
	uintptr_t kernelstack_va = KSTACKTOP - KSTKSIZE;
	for (int i = 0; i<NCPU; i++){
f0101a20:	83 c4 10             	add    $0x10,%esp
f0101a23:	81 fb 00 80 f7 ef    	cmp    $0xeff78000,%ebx
f0101a29:	75 c1                	jne    f01019ec <mem_init_mp+0xf>
		physaddr_t kstacktop_pa = PADDR(percpu_kstacks[i]);
		boot_map_region(kern_pgdir, kernelstack_va, KSTKSIZE, kstacktop_pa, PTE_W|PTE_P);
		kernelstack_va -= (KSTKSIZE + KSTKGAP);

	}
}
f0101a2b:	8d 65 f8             	lea    -0x8(%ebp),%esp
f0101a2e:	5b                   	pop    %ebx
f0101a2f:	5e                   	pop    %esi
f0101a30:	5d                   	pop    %ebp
f0101a31:	c3                   	ret    

f0101a32 <page_lookup>:
//
// Hint: the TA solution uses pgdir_walk and pa2page.
//
struct PageInfo *
page_lookup(pde_t *pgdir, void *va, pte_t **pte_store)
{
f0101a32:	55                   	push   %ebp
f0101a33:	89 e5                	mov    %esp,%ebp
f0101a35:	53                   	push   %ebx
f0101a36:	83 ec 08             	sub    $0x8,%esp
f0101a39:	8b 5d 10             	mov    0x10(%ebp),%ebx
	pte_t* pte_addr = pgdir_walk(pgdir,va,false);
f0101a3c:	6a 00                	push   $0x0
f0101a3e:	ff 75 0c             	pushl  0xc(%ebp)
f0101a41:	ff 75 08             	pushl  0x8(%ebp)
f0101a44:	e8 3c fe ff ff       	call   f0101885 <pgdir_walk>
	if (pte_store) *pte_store = pte_addr;
f0101a49:	83 c4 10             	add    $0x10,%esp
f0101a4c:	85 db                	test   %ebx,%ebx
f0101a4e:	74 02                	je     f0101a52 <page_lookup+0x20>
f0101a50:	89 03                	mov    %eax,(%ebx)
	if (!pte_addr) return NULL;		//no recuerdo si era lazy checking o no, por las dudas dejo asi
f0101a52:	85 c0                	test   %eax,%eax
f0101a54:	74 1a                	je     f0101a70 <page_lookup+0x3e>
	if (!(*pte_addr & PTE_P)) return NULL;
f0101a56:	8b 10                	mov    (%eax),%edx
f0101a58:	b8 00 00 00 00       	mov    $0x0,%eax
f0101a5d:	f6 c2 01             	test   $0x1,%dl
f0101a60:	74 13                	je     f0101a75 <page_lookup+0x43>
	physaddr_t pageaddr = PTE_ADDR(*pte_addr);
	return pa2page(pageaddr);
f0101a62:	89 d0                	mov    %edx,%eax
f0101a64:	25 00 f0 ff ff       	and    $0xfffff000,%eax
f0101a69:	e8 cd f8 ff ff       	call   f010133b <pa2page>
f0101a6e:	eb 05                	jmp    f0101a75 <page_lookup+0x43>
struct PageInfo *
page_lookup(pde_t *pgdir, void *va, pte_t **pte_store)
{
	pte_t* pte_addr = pgdir_walk(pgdir,va,false);
	if (pte_store) *pte_store = pte_addr;
	if (!pte_addr) return NULL;		//no recuerdo si era lazy checking o no, por las dudas dejo asi
f0101a70:	b8 00 00 00 00       	mov    $0x0,%eax
	if (!(*pte_addr & PTE_P)) return NULL;
	physaddr_t pageaddr = PTE_ADDR(*pte_addr);
	return pa2page(pageaddr);
}
f0101a75:	8b 5d fc             	mov    -0x4(%ebp),%ebx
f0101a78:	c9                   	leave  
f0101a79:	c3                   	ret    

f0101a7a <tlb_invalidate>:
// Invalidate a TLB entry, but only if the page tables being
// edited are the ones currently in use by the processor.
//
void
tlb_invalidate(pde_t *pgdir, void *va)
{
f0101a7a:	55                   	push   %ebp
f0101a7b:	89 e5                	mov    %esp,%ebp
f0101a7d:	83 ec 08             	sub    $0x8,%esp
	// Flush the entry only if we're modifying the current address space.
	if (!curenv || curenv->env_pgdir == pgdir)
f0101a80:	e8 89 3b 00 00       	call   f010560e <cpunum>
f0101a85:	6b c0 74             	imul   $0x74,%eax,%eax
f0101a88:	83 b8 28 70 28 f0 00 	cmpl   $0x0,-0xfd78fd8(%eax)
f0101a8f:	74 16                	je     f0101aa7 <tlb_invalidate+0x2d>
f0101a91:	e8 78 3b 00 00       	call   f010560e <cpunum>
f0101a96:	6b c0 74             	imul   $0x74,%eax,%eax
f0101a99:	8b 80 28 70 28 f0    	mov    -0xfd78fd8(%eax),%eax
f0101a9f:	8b 55 08             	mov    0x8(%ebp),%edx
f0101aa2:	39 50 60             	cmp    %edx,0x60(%eax)
f0101aa5:	75 08                	jne    f0101aaf <tlb_invalidate+0x35>
		invlpg(va);
f0101aa7:	8b 45 0c             	mov    0xc(%ebp),%eax
f0101aaa:	e8 1e f1 ff ff       	call   f0100bcd <invlpg>
}
f0101aaf:	c9                   	leave  
f0101ab0:	c3                   	ret    

f0101ab1 <page_remove>:
// Hint: The TA solution is implemented using page_lookup,
// 	tlb_invalidate, and page_decref.
//
void
page_remove(pde_t *pgdir, void *va)
{
f0101ab1:	55                   	push   %ebp
f0101ab2:	89 e5                	mov    %esp,%ebp
f0101ab4:	56                   	push   %esi
f0101ab5:	53                   	push   %ebx
f0101ab6:	83 ec 14             	sub    $0x14,%esp
f0101ab9:	8b 5d 08             	mov    0x8(%ebp),%ebx
f0101abc:	8b 75 0c             	mov    0xc(%ebp),%esi
	pte_t* pte_addr;
	struct PageInfo* page_ptr = page_lookup(pgdir,va,&pte_addr);
f0101abf:	8d 45 f4             	lea    -0xc(%ebp),%eax
f0101ac2:	50                   	push   %eax
f0101ac3:	56                   	push   %esi
f0101ac4:	53                   	push   %ebx
f0101ac5:	e8 68 ff ff ff       	call   f0101a32 <page_lookup>
	if (!page_ptr) return;
f0101aca:	83 c4 10             	add    $0x10,%esp
f0101acd:	85 c0                	test   %eax,%eax
f0101acf:	74 1f                	je     f0101af0 <page_remove+0x3f>
	page_decref(page_ptr);
f0101ad1:	83 ec 0c             	sub    $0xc,%esp
f0101ad4:	50                   	push   %eax
f0101ad5:	e8 84 fd ff ff       	call   f010185e <page_decref>
	*pte_addr = 0;
f0101ada:	8b 45 f4             	mov    -0xc(%ebp),%eax
f0101add:	c7 00 00 00 00 00    	movl   $0x0,(%eax)
	tlb_invalidate(pgdir,va);
f0101ae3:	83 c4 08             	add    $0x8,%esp
f0101ae6:	56                   	push   %esi
f0101ae7:	53                   	push   %ebx
f0101ae8:	e8 8d ff ff ff       	call   f0101a7a <tlb_invalidate>
f0101aed:	83 c4 10             	add    $0x10,%esp
}
f0101af0:	8d 65 f8             	lea    -0x8(%ebp),%esp
f0101af3:	5b                   	pop    %ebx
f0101af4:	5e                   	pop    %esi
f0101af5:	5d                   	pop    %ebp
f0101af6:	c3                   	ret    

f0101af7 <page_insert>:
// Hint: The TA solution is implemented using pgdir_walk, page_remove,
// and page2pa.
//
int
page_insert(pde_t *pgdir, struct PageInfo *pp, void *va, int perm)
{
f0101af7:	55                   	push   %ebp
f0101af8:	89 e5                	mov    %esp,%ebp
f0101afa:	57                   	push   %edi
f0101afb:	56                   	push   %esi
f0101afc:	53                   	push   %ebx
f0101afd:	83 ec 10             	sub    $0x10,%esp
f0101b00:	8b 5d 0c             	mov    0xc(%ebp),%ebx
f0101b03:	8b 7d 10             	mov    0x10(%ebp),%edi
	pte_t* pte_addr = pgdir_walk(pgdir,va,true);//entra a la PT, si no habia la crea
f0101b06:	6a 01                	push   $0x1
f0101b08:	57                   	push   %edi
f0101b09:	ff 75 08             	pushl  0x8(%ebp)
f0101b0c:	e8 74 fd ff ff       	call   f0101885 <pgdir_walk>
	if (!pte_addr) return -E_NO_MEM;	//solo NULL si no habia y no la pudo crear
f0101b11:	83 c4 10             	add    $0x10,%esp
f0101b14:	85 c0                	test   %eax,%eax
f0101b16:	74 33                	je     f0101b4b <page_insert+0x54>
f0101b18:	89 c6                	mov    %eax,%esi
	//a partir de aca hay pte_addr valida
	pp->pp_ref++;
f0101b1a:	66 83 43 04 01       	addw   $0x1,0x4(%ebx)
	if (*pte_addr & PTE_P) page_remove(pgdir,va);
f0101b1f:	f6 00 01             	testb  $0x1,(%eax)
f0101b22:	74 0f                	je     f0101b33 <page_insert+0x3c>
f0101b24:	83 ec 08             	sub    $0x8,%esp
f0101b27:	57                   	push   %edi
f0101b28:	ff 75 08             	pushl  0x8(%ebp)
f0101b2b:	e8 81 ff ff ff       	call   f0101ab1 <page_remove>
f0101b30:	83 c4 10             	add    $0x10,%esp
	*pte_addr = page2pa(pp) | perm | PTE_P;
f0101b33:	89 d8                	mov    %ebx,%eax
f0101b35:	e8 b3 f0 ff ff       	call   f0100bed <page2pa>
f0101b3a:	8b 55 14             	mov    0x14(%ebp),%edx
f0101b3d:	83 ca 01             	or     $0x1,%edx
f0101b40:	09 d0                	or     %edx,%eax
f0101b42:	89 06                	mov    %eax,(%esi)
	return 0;
f0101b44:	b8 00 00 00 00       	mov    $0x0,%eax
f0101b49:	eb 05                	jmp    f0101b50 <page_insert+0x59>
//
int
page_insert(pde_t *pgdir, struct PageInfo *pp, void *va, int perm)
{
	pte_t* pte_addr = pgdir_walk(pgdir,va,true);//entra a la PT, si no habia la crea
	if (!pte_addr) return -E_NO_MEM;	//solo NULL si no habia y no la pudo crear
f0101b4b:	b8 fc ff ff ff       	mov    $0xfffffffc,%eax
	//a partir de aca hay pte_addr valida
	pp->pp_ref++;
	if (*pte_addr & PTE_P) page_remove(pgdir,va);
	*pte_addr = page2pa(pp) | perm | PTE_P;
	return 0;
}
f0101b50:	8d 65 f4             	lea    -0xc(%ebp),%esp
f0101b53:	5b                   	pop    %ebx
f0101b54:	5e                   	pop    %esi
f0101b55:	5f                   	pop    %edi
f0101b56:	5d                   	pop    %ebp
f0101b57:	c3                   	ret    

f0101b58 <check_page_installed_pgdir>:
}

// check page_insert, page_remove, &c, with an installed kern_pgdir
static void
check_page_installed_pgdir(void)
{
f0101b58:	55                   	push   %ebp
f0101b59:	89 e5                	mov    %esp,%ebp
f0101b5b:	57                   	push   %edi
f0101b5c:	56                   	push   %esi
f0101b5d:	53                   	push   %ebx
f0101b5e:	83 ec 18             	sub    $0x18,%esp
	uintptr_t va;
	int i;

	// check that we can read and write installed pages
	pp1 = pp2 = 0;
	assert((pp0 = page_alloc(0)));
f0101b61:	6a 00                	push   $0x0
f0101b63:	e8 92 f8 ff ff       	call   f01013fa <page_alloc>
f0101b68:	83 c4 10             	add    $0x10,%esp
f0101b6b:	85 c0                	test   %eax,%eax
f0101b6d:	75 19                	jne    f0101b88 <check_page_installed_pgdir+0x30>
f0101b6f:	68 f6 6c 10 f0       	push   $0xf0106cf6
f0101b74:	68 de 6b 10 f0       	push   $0xf0106bde
f0101b79:	68 54 04 00 00       	push   $0x454
f0101b7e:	68 bf 6b 10 f0       	push   $0xf0106bbf
f0101b83:	e8 d5 e4 ff ff       	call   f010005d <_panic>
f0101b88:	89 c6                	mov    %eax,%esi
	assert((pp1 = page_alloc(0)));
f0101b8a:	83 ec 0c             	sub    $0xc,%esp
f0101b8d:	6a 00                	push   $0x0
f0101b8f:	e8 66 f8 ff ff       	call   f01013fa <page_alloc>
f0101b94:	89 c7                	mov    %eax,%edi
f0101b96:	83 c4 10             	add    $0x10,%esp
f0101b99:	85 c0                	test   %eax,%eax
f0101b9b:	75 19                	jne    f0101bb6 <check_page_installed_pgdir+0x5e>
f0101b9d:	68 0c 6d 10 f0       	push   $0xf0106d0c
f0101ba2:	68 de 6b 10 f0       	push   $0xf0106bde
f0101ba7:	68 55 04 00 00       	push   $0x455
f0101bac:	68 bf 6b 10 f0       	push   $0xf0106bbf
f0101bb1:	e8 a7 e4 ff ff       	call   f010005d <_panic>
	assert((pp2 = page_alloc(0)));
f0101bb6:	83 ec 0c             	sub    $0xc,%esp
f0101bb9:	6a 00                	push   $0x0
f0101bbb:	e8 3a f8 ff ff       	call   f01013fa <page_alloc>
f0101bc0:	89 c3                	mov    %eax,%ebx
f0101bc2:	83 c4 10             	add    $0x10,%esp
f0101bc5:	85 c0                	test   %eax,%eax
f0101bc7:	75 19                	jne    f0101be2 <check_page_installed_pgdir+0x8a>
f0101bc9:	68 22 6d 10 f0       	push   $0xf0106d22
f0101bce:	68 de 6b 10 f0       	push   $0xf0106bde
f0101bd3:	68 56 04 00 00       	push   $0x456
f0101bd8:	68 bf 6b 10 f0       	push   $0xf0106bbf
f0101bdd:	e8 7b e4 ff ff       	call   f010005d <_panic>
	page_free(pp0);
f0101be2:	83 ec 0c             	sub    $0xc,%esp
f0101be5:	56                   	push   %esi
f0101be6:	e8 54 f8 ff ff       	call   f010143f <page_free>
	memset(page2kva(pp1), 1, PGSIZE);
f0101beb:	89 f8                	mov    %edi,%eax
f0101bed:	e8 c7 f0 ff ff       	call   f0100cb9 <page2kva>
f0101bf2:	83 c4 0c             	add    $0xc,%esp
f0101bf5:	68 00 10 00 00       	push   $0x1000
f0101bfa:	6a 01                	push   $0x1
f0101bfc:	50                   	push   %eax
f0101bfd:	e8 77 33 00 00       	call   f0104f79 <memset>
	memset(page2kva(pp2), 2, PGSIZE);
f0101c02:	89 d8                	mov    %ebx,%eax
f0101c04:	e8 b0 f0 ff ff       	call   f0100cb9 <page2kva>
f0101c09:	83 c4 0c             	add    $0xc,%esp
f0101c0c:	68 00 10 00 00       	push   $0x1000
f0101c11:	6a 02                	push   $0x2
f0101c13:	50                   	push   %eax
f0101c14:	e8 60 33 00 00       	call   f0104f79 <memset>
	page_insert(kern_pgdir, pp1, (void*) PGSIZE, PTE_W);
f0101c19:	6a 02                	push   $0x2
f0101c1b:	68 00 10 00 00       	push   $0x1000
f0101c20:	57                   	push   %edi
f0101c21:	ff 35 0c 6f 28 f0    	pushl  0xf0286f0c
f0101c27:	e8 cb fe ff ff       	call   f0101af7 <page_insert>
	assert(pp1->pp_ref == 1);
f0101c2c:	83 c4 20             	add    $0x20,%esp
f0101c2f:	66 83 7f 04 01       	cmpw   $0x1,0x4(%edi)
f0101c34:	74 19                	je     f0101c4f <check_page_installed_pgdir+0xf7>
f0101c36:	68 28 6e 10 f0       	push   $0xf0106e28
f0101c3b:	68 de 6b 10 f0       	push   $0xf0106bde
f0101c40:	68 5b 04 00 00       	push   $0x45b
f0101c45:	68 bf 6b 10 f0       	push   $0xf0106bbf
f0101c4a:	e8 0e e4 ff ff       	call   f010005d <_panic>
	assert(*(uint32_t *)PGSIZE == 0x01010101U);
f0101c4f:	81 3d 00 10 00 00 01 	cmpl   $0x1010101,0x1000
f0101c56:	01 01 01 
f0101c59:	74 19                	je     f0101c74 <check_page_installed_pgdir+0x11c>
f0101c5b:	68 30 65 10 f0       	push   $0xf0106530
f0101c60:	68 de 6b 10 f0       	push   $0xf0106bde
f0101c65:	68 5c 04 00 00       	push   $0x45c
f0101c6a:	68 bf 6b 10 f0       	push   $0xf0106bbf
f0101c6f:	e8 e9 e3 ff ff       	call   f010005d <_panic>
	page_insert(kern_pgdir, pp2, (void*) PGSIZE, PTE_W);
f0101c74:	6a 02                	push   $0x2
f0101c76:	68 00 10 00 00       	push   $0x1000
f0101c7b:	53                   	push   %ebx
f0101c7c:	ff 35 0c 6f 28 f0    	pushl  0xf0286f0c
f0101c82:	e8 70 fe ff ff       	call   f0101af7 <page_insert>
	assert(*(uint32_t *)PGSIZE == 0x02020202U);
f0101c87:	83 c4 10             	add    $0x10,%esp
f0101c8a:	81 3d 00 10 00 00 02 	cmpl   $0x2020202,0x1000
f0101c91:	02 02 02 
f0101c94:	74 19                	je     f0101caf <check_page_installed_pgdir+0x157>
f0101c96:	68 54 65 10 f0       	push   $0xf0106554
f0101c9b:	68 de 6b 10 f0       	push   $0xf0106bde
f0101ca0:	68 5e 04 00 00       	push   $0x45e
f0101ca5:	68 bf 6b 10 f0       	push   $0xf0106bbf
f0101caa:	e8 ae e3 ff ff       	call   f010005d <_panic>
	assert(pp2->pp_ref == 1);
f0101caf:	66 83 7b 04 01       	cmpw   $0x1,0x4(%ebx)
f0101cb4:	74 19                	je     f0101ccf <check_page_installed_pgdir+0x177>
f0101cb6:	68 39 6e 10 f0       	push   $0xf0106e39
f0101cbb:	68 de 6b 10 f0       	push   $0xf0106bde
f0101cc0:	68 5f 04 00 00       	push   $0x45f
f0101cc5:	68 bf 6b 10 f0       	push   $0xf0106bbf
f0101cca:	e8 8e e3 ff ff       	call   f010005d <_panic>
	assert(pp1->pp_ref == 0);
f0101ccf:	66 83 7f 04 00       	cmpw   $0x0,0x4(%edi)
f0101cd4:	74 19                	je     f0101cef <check_page_installed_pgdir+0x197>
f0101cd6:	68 4a 6e 10 f0       	push   $0xf0106e4a
f0101cdb:	68 de 6b 10 f0       	push   $0xf0106bde
f0101ce0:	68 60 04 00 00       	push   $0x460
f0101ce5:	68 bf 6b 10 f0       	push   $0xf0106bbf
f0101cea:	e8 6e e3 ff ff       	call   f010005d <_panic>
	*(uint32_t *)PGSIZE = 0x03030303U;
f0101cef:	c7 05 00 10 00 00 03 	movl   $0x3030303,0x1000
f0101cf6:	03 03 03 
	assert(*(uint32_t *)page2kva(pp2) == 0x03030303U);
f0101cf9:	89 d8                	mov    %ebx,%eax
f0101cfb:	e8 b9 ef ff ff       	call   f0100cb9 <page2kva>
f0101d00:	81 38 03 03 03 03    	cmpl   $0x3030303,(%eax)
f0101d06:	74 19                	je     f0101d21 <check_page_installed_pgdir+0x1c9>
f0101d08:	68 78 65 10 f0       	push   $0xf0106578
f0101d0d:	68 de 6b 10 f0       	push   $0xf0106bde
f0101d12:	68 62 04 00 00       	push   $0x462
f0101d17:	68 bf 6b 10 f0       	push   $0xf0106bbf
f0101d1c:	e8 3c e3 ff ff       	call   f010005d <_panic>
	page_remove(kern_pgdir, (void*) PGSIZE);
f0101d21:	83 ec 08             	sub    $0x8,%esp
f0101d24:	68 00 10 00 00       	push   $0x1000
f0101d29:	ff 35 0c 6f 28 f0    	pushl  0xf0286f0c
f0101d2f:	e8 7d fd ff ff       	call   f0101ab1 <page_remove>
	assert(pp2->pp_ref == 0);
f0101d34:	83 c4 10             	add    $0x10,%esp
f0101d37:	66 83 7b 04 00       	cmpw   $0x0,0x4(%ebx)
f0101d3c:	74 19                	je     f0101d57 <check_page_installed_pgdir+0x1ff>
f0101d3e:	68 5b 6e 10 f0       	push   $0xf0106e5b
f0101d43:	68 de 6b 10 f0       	push   $0xf0106bde
f0101d48:	68 64 04 00 00       	push   $0x464
f0101d4d:	68 bf 6b 10 f0       	push   $0xf0106bbf
f0101d52:	e8 06 e3 ff ff       	call   f010005d <_panic>

	// forcibly take pp0 back
	assert(PTE_ADDR(kern_pgdir[0]) == page2pa(pp0));
f0101d57:	8b 1d 0c 6f 28 f0    	mov    0xf0286f0c,%ebx
f0101d5d:	89 f0                	mov    %esi,%eax
f0101d5f:	e8 89 ee ff ff       	call   f0100bed <page2pa>
f0101d64:	8b 13                	mov    (%ebx),%edx
f0101d66:	81 e2 00 f0 ff ff    	and    $0xfffff000,%edx
f0101d6c:	39 c2                	cmp    %eax,%edx
f0101d6e:	74 19                	je     f0101d89 <check_page_installed_pgdir+0x231>
f0101d70:	68 a4 65 10 f0       	push   $0xf01065a4
f0101d75:	68 de 6b 10 f0       	push   $0xf0106bde
f0101d7a:	68 67 04 00 00       	push   $0x467
f0101d7f:	68 bf 6b 10 f0       	push   $0xf0106bbf
f0101d84:	e8 d4 e2 ff ff       	call   f010005d <_panic>
	kern_pgdir[0] = 0;
f0101d89:	c7 03 00 00 00 00    	movl   $0x0,(%ebx)
	assert(pp0->pp_ref == 1);
f0101d8f:	66 83 7e 04 01       	cmpw   $0x1,0x4(%esi)
f0101d94:	74 19                	je     f0101daf <check_page_installed_pgdir+0x257>
f0101d96:	68 6c 6e 10 f0       	push   $0xf0106e6c
f0101d9b:	68 de 6b 10 f0       	push   $0xf0106bde
f0101da0:	68 69 04 00 00       	push   $0x469
f0101da5:	68 bf 6b 10 f0       	push   $0xf0106bbf
f0101daa:	e8 ae e2 ff ff       	call   f010005d <_panic>
	pp0->pp_ref = 0;
f0101daf:	66 c7 46 04 00 00    	movw   $0x0,0x4(%esi)

	// free the pages we took
	page_free(pp0);
f0101db5:	83 ec 0c             	sub    $0xc,%esp
f0101db8:	56                   	push   %esi
f0101db9:	e8 81 f6 ff ff       	call   f010143f <page_free>

	cprintf("check_page_installed_pgdir() succeeded!\n");
f0101dbe:	c7 04 24 cc 65 10 f0 	movl   $0xf01065cc,(%esp)
f0101dc5:	e8 a5 1a 00 00       	call   f010386f <cprintf>
}
f0101dca:	83 c4 10             	add    $0x10,%esp
f0101dcd:	8d 65 f4             	lea    -0xc(%ebp),%esp
f0101dd0:	5b                   	pop    %ebx
f0101dd1:	5e                   	pop    %esi
f0101dd2:	5f                   	pop    %edi
f0101dd3:	5d                   	pop    %ebp
f0101dd4:	c3                   	ret    

f0101dd5 <mmio_map_region>:
// location.  Return the base of the reserved region.  size does *not*
// have to be multiple of PGSIZE.
//
void *
mmio_map_region(physaddr_t pa, size_t size)
{
f0101dd5:	55                   	push   %ebp
f0101dd6:	89 e5                	mov    %esp,%ebp
f0101dd8:	53                   	push   %ebx
f0101dd9:	83 ec 04             	sub    $0x4,%esp
	// okay to simply panic if this happens).
	//
	// Hint: The staff solution uses boot_map_region.
	//
	// Your code here:
	size_t mult_size = ROUNDUP(size, PGSIZE);
f0101ddc:	8b 45 0c             	mov    0xc(%ebp),%eax
f0101ddf:	8d 98 ff 0f 00 00    	lea    0xfff(%eax),%ebx
f0101de5:	81 e3 00 f0 ff ff    	and    $0xfffff000,%ebx
	if(base+mult_size > MMIOLIM){
f0101deb:	8b 15 00 13 11 f0    	mov    0xf0111300,%edx
f0101df1:	8d 04 13             	lea    (%ebx,%edx,1),%eax
f0101df4:	3d 00 00 c0 ef       	cmp    $0xefc00000,%eax
f0101df9:	76 17                	jbe    f0101e12 <mmio_map_region+0x3d>
		panic("Overflowing MMIOLIM");
f0101dfb:	83 ec 04             	sub    $0x4,%esp
f0101dfe:	68 7d 6e 10 f0       	push   $0xf0106e7d
f0101e03:	68 5a 02 00 00       	push   $0x25a
f0101e08:	68 bf 6b 10 f0       	push   $0xf0106bbf
f0101e0d:	e8 4b e2 ff ff       	call   f010005d <_panic>
	}
	boot_map_region(kern_pgdir, base, mult_size, pa, PTE_P | PTE_PWT | PTE_PCD);
f0101e12:	83 ec 08             	sub    $0x8,%esp
f0101e15:	6a 19                	push   $0x19
f0101e17:	ff 75 08             	pushl  0x8(%ebp)
f0101e1a:	89 d9                	mov    %ebx,%ecx
f0101e1c:	a1 0c 6f 28 f0       	mov    0xf0286f0c,%eax
f0101e21:	e8 fe fa ff ff       	call   f0101924 <boot_map_region>

	uintptr_t mapped_base = base;
f0101e26:	a1 00 13 11 f0       	mov    0xf0111300,%eax
	base += mult_size;
f0101e2b:	01 c3                	add    %eax,%ebx
f0101e2d:	89 1d 00 13 11 f0    	mov    %ebx,0xf0111300
	return (void *) mapped_base;
}
f0101e33:	8b 5d fc             	mov    -0x4(%ebp),%ebx
f0101e36:	c9                   	leave  
f0101e37:	c3                   	ret    

f0101e38 <check_page>:


// check page_insert, page_remove, &c
static void
check_page(void)
{
f0101e38:	55                   	push   %ebp
f0101e39:	89 e5                	mov    %esp,%ebp
f0101e3b:	57                   	push   %edi
f0101e3c:	56                   	push   %esi
f0101e3d:	53                   	push   %ebx
f0101e3e:	83 ec 38             	sub    $0x38,%esp
	int i;
	extern pde_t entry_pgdir[];

	// should be able to allocate three pages
	pp0 = pp1 = pp2 = 0;
	assert((pp0 = page_alloc(0)));
f0101e41:	6a 00                	push   $0x0
f0101e43:	e8 b2 f5 ff ff       	call   f01013fa <page_alloc>
f0101e48:	89 45 d4             	mov    %eax,-0x2c(%ebp)
f0101e4b:	83 c4 10             	add    $0x10,%esp
f0101e4e:	85 c0                	test   %eax,%eax
f0101e50:	75 19                	jne    f0101e6b <check_page+0x33>
f0101e52:	68 f6 6c 10 f0       	push   $0xf0106cf6
f0101e57:	68 de 6b 10 f0       	push   $0xf0106bde
f0101e5c:	68 a6 03 00 00       	push   $0x3a6
f0101e61:	68 bf 6b 10 f0       	push   $0xf0106bbf
f0101e66:	e8 f2 e1 ff ff       	call   f010005d <_panic>
	assert((pp1 = page_alloc(0)));
f0101e6b:	83 ec 0c             	sub    $0xc,%esp
f0101e6e:	6a 00                	push   $0x0
f0101e70:	e8 85 f5 ff ff       	call   f01013fa <page_alloc>
f0101e75:	89 c6                	mov    %eax,%esi
f0101e77:	83 c4 10             	add    $0x10,%esp
f0101e7a:	85 c0                	test   %eax,%eax
f0101e7c:	75 19                	jne    f0101e97 <check_page+0x5f>
f0101e7e:	68 0c 6d 10 f0       	push   $0xf0106d0c
f0101e83:	68 de 6b 10 f0       	push   $0xf0106bde
f0101e88:	68 a7 03 00 00       	push   $0x3a7
f0101e8d:	68 bf 6b 10 f0       	push   $0xf0106bbf
f0101e92:	e8 c6 e1 ff ff       	call   f010005d <_panic>
	assert((pp2 = page_alloc(0)));
f0101e97:	83 ec 0c             	sub    $0xc,%esp
f0101e9a:	6a 00                	push   $0x0
f0101e9c:	e8 59 f5 ff ff       	call   f01013fa <page_alloc>
f0101ea1:	89 c3                	mov    %eax,%ebx
f0101ea3:	83 c4 10             	add    $0x10,%esp
f0101ea6:	85 c0                	test   %eax,%eax
f0101ea8:	75 19                	jne    f0101ec3 <check_page+0x8b>
f0101eaa:	68 22 6d 10 f0       	push   $0xf0106d22
f0101eaf:	68 de 6b 10 f0       	push   $0xf0106bde
f0101eb4:	68 a8 03 00 00       	push   $0x3a8
f0101eb9:	68 bf 6b 10 f0       	push   $0xf0106bbf
f0101ebe:	e8 9a e1 ff ff       	call   f010005d <_panic>

	assert(pp0);
	assert(pp1 && pp1 != pp0);
f0101ec3:	39 75 d4             	cmp    %esi,-0x2c(%ebp)
f0101ec6:	75 19                	jne    f0101ee1 <check_page+0xa9>
f0101ec8:	68 38 6d 10 f0       	push   $0xf0106d38
f0101ecd:	68 de 6b 10 f0       	push   $0xf0106bde
f0101ed2:	68 ab 03 00 00       	push   $0x3ab
f0101ed7:	68 bf 6b 10 f0       	push   $0xf0106bbf
f0101edc:	e8 7c e1 ff ff       	call   f010005d <_panic>
	assert(pp2 && pp2 != pp1 && pp2 != pp0);
f0101ee1:	39 c6                	cmp    %eax,%esi
f0101ee3:	74 05                	je     f0101eea <check_page+0xb2>
f0101ee5:	39 45 d4             	cmp    %eax,-0x2c(%ebp)
f0101ee8:	75 19                	jne    f0101f03 <check_page+0xcb>
f0101eea:	68 f0 64 10 f0       	push   $0xf01064f0
f0101eef:	68 de 6b 10 f0       	push   $0xf0106bde
f0101ef4:	68 ac 03 00 00       	push   $0x3ac
f0101ef9:	68 bf 6b 10 f0       	push   $0xf0106bbf
f0101efe:	e8 5a e1 ff ff       	call   f010005d <_panic>

	// temporarily steal the rest of the free pages
	fl = page_free_list;
f0101f03:	a1 40 52 28 f0       	mov    0xf0285240,%eax
f0101f08:	89 45 cc             	mov    %eax,-0x34(%ebp)
	page_free_list = 0;
f0101f0b:	c7 05 40 52 28 f0 00 	movl   $0x0,0xf0285240
f0101f12:	00 00 00 

	// should be no free memory
	assert(!page_alloc(0));
f0101f15:	83 ec 0c             	sub    $0xc,%esp
f0101f18:	6a 00                	push   $0x0
f0101f1a:	e8 db f4 ff ff       	call   f01013fa <page_alloc>
f0101f1f:	83 c4 10             	add    $0x10,%esp
f0101f22:	85 c0                	test   %eax,%eax
f0101f24:	74 19                	je     f0101f3f <check_page+0x107>
f0101f26:	68 a1 6d 10 f0       	push   $0xf0106da1
f0101f2b:	68 de 6b 10 f0       	push   $0xf0106bde
f0101f30:	68 b3 03 00 00       	push   $0x3b3
f0101f35:	68 bf 6b 10 f0       	push   $0xf0106bbf
f0101f3a:	e8 1e e1 ff ff       	call   f010005d <_panic>

	// there is no page allocated at address 0
	assert(page_lookup(kern_pgdir, (void *) 0x0, &ptep) == NULL);
f0101f3f:	83 ec 04             	sub    $0x4,%esp
f0101f42:	8d 45 e4             	lea    -0x1c(%ebp),%eax
f0101f45:	50                   	push   %eax
f0101f46:	6a 00                	push   $0x0
f0101f48:	ff 35 0c 6f 28 f0    	pushl  0xf0286f0c
f0101f4e:	e8 df fa ff ff       	call   f0101a32 <page_lookup>
f0101f53:	83 c4 10             	add    $0x10,%esp
f0101f56:	85 c0                	test   %eax,%eax
f0101f58:	74 19                	je     f0101f73 <check_page+0x13b>
f0101f5a:	68 f8 65 10 f0       	push   $0xf01065f8
f0101f5f:	68 de 6b 10 f0       	push   $0xf0106bde
f0101f64:	68 b6 03 00 00       	push   $0x3b6
f0101f69:	68 bf 6b 10 f0       	push   $0xf0106bbf
f0101f6e:	e8 ea e0 ff ff       	call   f010005d <_panic>

	// there is no free memory, so we can't allocate a page table
	assert(page_insert(kern_pgdir, pp1, 0x0, PTE_W) < 0);
f0101f73:	6a 02                	push   $0x2
f0101f75:	6a 00                	push   $0x0
f0101f77:	56                   	push   %esi
f0101f78:	ff 35 0c 6f 28 f0    	pushl  0xf0286f0c
f0101f7e:	e8 74 fb ff ff       	call   f0101af7 <page_insert>
f0101f83:	83 c4 10             	add    $0x10,%esp
f0101f86:	85 c0                	test   %eax,%eax
f0101f88:	78 19                	js     f0101fa3 <check_page+0x16b>
f0101f8a:	68 30 66 10 f0       	push   $0xf0106630
f0101f8f:	68 de 6b 10 f0       	push   $0xf0106bde
f0101f94:	68 b9 03 00 00       	push   $0x3b9
f0101f99:	68 bf 6b 10 f0       	push   $0xf0106bbf
f0101f9e:	e8 ba e0 ff ff       	call   f010005d <_panic>

	// free pp0 and try again: pp0 should be used for page table
	page_free(pp0);
f0101fa3:	83 ec 0c             	sub    $0xc,%esp
f0101fa6:	ff 75 d4             	pushl  -0x2c(%ebp)
f0101fa9:	e8 91 f4 ff ff       	call   f010143f <page_free>
	assert(page_insert(kern_pgdir, pp1, 0x0, PTE_W) == 0);
f0101fae:	6a 02                	push   $0x2
f0101fb0:	6a 00                	push   $0x0
f0101fb2:	56                   	push   %esi
f0101fb3:	ff 35 0c 6f 28 f0    	pushl  0xf0286f0c
f0101fb9:	e8 39 fb ff ff       	call   f0101af7 <page_insert>
f0101fbe:	83 c4 20             	add    $0x20,%esp
f0101fc1:	85 c0                	test   %eax,%eax
f0101fc3:	74 19                	je     f0101fde <check_page+0x1a6>
f0101fc5:	68 60 66 10 f0       	push   $0xf0106660
f0101fca:	68 de 6b 10 f0       	push   $0xf0106bde
f0101fcf:	68 bd 03 00 00       	push   $0x3bd
f0101fd4:	68 bf 6b 10 f0       	push   $0xf0106bbf
f0101fd9:	e8 7f e0 ff ff       	call   f010005d <_panic>
	assert(PTE_ADDR(kern_pgdir[0]) == page2pa(pp0));
f0101fde:	8b 3d 0c 6f 28 f0    	mov    0xf0286f0c,%edi
f0101fe4:	8b 45 d4             	mov    -0x2c(%ebp),%eax
f0101fe7:	e8 01 ec ff ff       	call   f0100bed <page2pa>
f0101fec:	8b 17                	mov    (%edi),%edx
f0101fee:	81 e2 00 f0 ff ff    	and    $0xfffff000,%edx
f0101ff4:	39 c2                	cmp    %eax,%edx
f0101ff6:	74 19                	je     f0102011 <check_page+0x1d9>
f0101ff8:	68 a4 65 10 f0       	push   $0xf01065a4
f0101ffd:	68 de 6b 10 f0       	push   $0xf0106bde
f0102002:	68 be 03 00 00       	push   $0x3be
f0102007:	68 bf 6b 10 f0       	push   $0xf0106bbf
f010200c:	e8 4c e0 ff ff       	call   f010005d <_panic>
	assert(check_va2pa(kern_pgdir, 0x0) == page2pa(pp1));
f0102011:	ba 00 00 00 00       	mov    $0x0,%edx
f0102016:	89 f8                	mov    %edi,%eax
f0102018:	e8 ba ec ff ff       	call   f0100cd7 <check_va2pa>
f010201d:	89 45 d0             	mov    %eax,-0x30(%ebp)
f0102020:	89 f0                	mov    %esi,%eax
f0102022:	e8 c6 eb ff ff       	call   f0100bed <page2pa>
f0102027:	39 45 d0             	cmp    %eax,-0x30(%ebp)
f010202a:	74 19                	je     f0102045 <check_page+0x20d>
f010202c:	68 90 66 10 f0       	push   $0xf0106690
f0102031:	68 de 6b 10 f0       	push   $0xf0106bde
f0102036:	68 bf 03 00 00       	push   $0x3bf
f010203b:	68 bf 6b 10 f0       	push   $0xf0106bbf
f0102040:	e8 18 e0 ff ff       	call   f010005d <_panic>
	assert(pp1->pp_ref == 1);
f0102045:	66 83 7e 04 01       	cmpw   $0x1,0x4(%esi)
f010204a:	74 19                	je     f0102065 <check_page+0x22d>
f010204c:	68 28 6e 10 f0       	push   $0xf0106e28
f0102051:	68 de 6b 10 f0       	push   $0xf0106bde
f0102056:	68 c0 03 00 00       	push   $0x3c0
f010205b:	68 bf 6b 10 f0       	push   $0xf0106bbf
f0102060:	e8 f8 df ff ff       	call   f010005d <_panic>
	assert(pp0->pp_ref == 1);
f0102065:	8b 45 d4             	mov    -0x2c(%ebp),%eax
f0102068:	66 83 78 04 01       	cmpw   $0x1,0x4(%eax)
f010206d:	74 19                	je     f0102088 <check_page+0x250>
f010206f:	68 6c 6e 10 f0       	push   $0xf0106e6c
f0102074:	68 de 6b 10 f0       	push   $0xf0106bde
f0102079:	68 c1 03 00 00       	push   $0x3c1
f010207e:	68 bf 6b 10 f0       	push   $0xf0106bbf
f0102083:	e8 d5 df ff ff       	call   f010005d <_panic>
	// should be able to map pp2 at PGSIZE because pp0 is already allocated for page table
	assert(page_insert(kern_pgdir, pp2, (void*) PGSIZE, PTE_W) == 0);
f0102088:	6a 02                	push   $0x2
f010208a:	68 00 10 00 00       	push   $0x1000
f010208f:	53                   	push   %ebx
f0102090:	57                   	push   %edi
f0102091:	e8 61 fa ff ff       	call   f0101af7 <page_insert>
f0102096:	83 c4 10             	add    $0x10,%esp
f0102099:	85 c0                	test   %eax,%eax
f010209b:	74 19                	je     f01020b6 <check_page+0x27e>
f010209d:	68 c0 66 10 f0       	push   $0xf01066c0
f01020a2:	68 de 6b 10 f0       	push   $0xf0106bde
f01020a7:	68 c3 03 00 00       	push   $0x3c3
f01020ac:	68 bf 6b 10 f0       	push   $0xf0106bbf
f01020b1:	e8 a7 df ff ff       	call   f010005d <_panic>
	assert(check_va2pa(kern_pgdir, PGSIZE) == page2pa(pp2));
f01020b6:	ba 00 10 00 00       	mov    $0x1000,%edx
f01020bb:	a1 0c 6f 28 f0       	mov    0xf0286f0c,%eax
f01020c0:	e8 12 ec ff ff       	call   f0100cd7 <check_va2pa>
f01020c5:	89 c7                	mov    %eax,%edi
f01020c7:	89 d8                	mov    %ebx,%eax
f01020c9:	e8 1f eb ff ff       	call   f0100bed <page2pa>
f01020ce:	39 c7                	cmp    %eax,%edi
f01020d0:	74 19                	je     f01020eb <check_page+0x2b3>
f01020d2:	68 fc 66 10 f0       	push   $0xf01066fc
f01020d7:	68 de 6b 10 f0       	push   $0xf0106bde
f01020dc:	68 c4 03 00 00       	push   $0x3c4
f01020e1:	68 bf 6b 10 f0       	push   $0xf0106bbf
f01020e6:	e8 72 df ff ff       	call   f010005d <_panic>
	assert(pp2->pp_ref == 1);
f01020eb:	66 83 7b 04 01       	cmpw   $0x1,0x4(%ebx)
f01020f0:	74 19                	je     f010210b <check_page+0x2d3>
f01020f2:	68 39 6e 10 f0       	push   $0xf0106e39
f01020f7:	68 de 6b 10 f0       	push   $0xf0106bde
f01020fc:	68 c5 03 00 00       	push   $0x3c5
f0102101:	68 bf 6b 10 f0       	push   $0xf0106bbf
f0102106:	e8 52 df ff ff       	call   f010005d <_panic>

	// should be no free memory
	assert(!page_alloc(0));
f010210b:	83 ec 0c             	sub    $0xc,%esp
f010210e:	6a 00                	push   $0x0
f0102110:	e8 e5 f2 ff ff       	call   f01013fa <page_alloc>
f0102115:	83 c4 10             	add    $0x10,%esp
f0102118:	85 c0                	test   %eax,%eax
f010211a:	74 19                	je     f0102135 <check_page+0x2fd>
f010211c:	68 a1 6d 10 f0       	push   $0xf0106da1
f0102121:	68 de 6b 10 f0       	push   $0xf0106bde
f0102126:	68 c8 03 00 00       	push   $0x3c8
f010212b:	68 bf 6b 10 f0       	push   $0xf0106bbf
f0102130:	e8 28 df ff ff       	call   f010005d <_panic>

	// should be able to map pp2 at PGSIZE because it's already there
	assert(page_insert(kern_pgdir, pp2, (void*) PGSIZE, PTE_W) == 0);
f0102135:	6a 02                	push   $0x2
f0102137:	68 00 10 00 00       	push   $0x1000
f010213c:	53                   	push   %ebx
f010213d:	ff 35 0c 6f 28 f0    	pushl  0xf0286f0c
f0102143:	e8 af f9 ff ff       	call   f0101af7 <page_insert>
f0102148:	83 c4 10             	add    $0x10,%esp
f010214b:	85 c0                	test   %eax,%eax
f010214d:	74 19                	je     f0102168 <check_page+0x330>
f010214f:	68 c0 66 10 f0       	push   $0xf01066c0
f0102154:	68 de 6b 10 f0       	push   $0xf0106bde
f0102159:	68 cb 03 00 00       	push   $0x3cb
f010215e:	68 bf 6b 10 f0       	push   $0xf0106bbf
f0102163:	e8 f5 de ff ff       	call   f010005d <_panic>
	assert(check_va2pa(kern_pgdir, PGSIZE) == page2pa(pp2));
f0102168:	ba 00 10 00 00       	mov    $0x1000,%edx
f010216d:	a1 0c 6f 28 f0       	mov    0xf0286f0c,%eax
f0102172:	e8 60 eb ff ff       	call   f0100cd7 <check_va2pa>
f0102177:	89 c7                	mov    %eax,%edi
f0102179:	89 d8                	mov    %ebx,%eax
f010217b:	e8 6d ea ff ff       	call   f0100bed <page2pa>
f0102180:	39 c7                	cmp    %eax,%edi
f0102182:	74 19                	je     f010219d <check_page+0x365>
f0102184:	68 fc 66 10 f0       	push   $0xf01066fc
f0102189:	68 de 6b 10 f0       	push   $0xf0106bde
f010218e:	68 cc 03 00 00       	push   $0x3cc
f0102193:	68 bf 6b 10 f0       	push   $0xf0106bbf
f0102198:	e8 c0 de ff ff       	call   f010005d <_panic>
	assert(pp2->pp_ref == 1);
f010219d:	66 83 7b 04 01       	cmpw   $0x1,0x4(%ebx)
f01021a2:	74 19                	je     f01021bd <check_page+0x385>
f01021a4:	68 39 6e 10 f0       	push   $0xf0106e39
f01021a9:	68 de 6b 10 f0       	push   $0xf0106bde
f01021ae:	68 cd 03 00 00       	push   $0x3cd
f01021b3:	68 bf 6b 10 f0       	push   $0xf0106bbf
f01021b8:	e8 a0 de ff ff       	call   f010005d <_panic>

	// pp2 should NOT be on the free list
	// could happen in ref counts are handled sloppily in page_insert
	assert(!page_alloc(0));
f01021bd:	83 ec 0c             	sub    $0xc,%esp
f01021c0:	6a 00                	push   $0x0
f01021c2:	e8 33 f2 ff ff       	call   f01013fa <page_alloc>
f01021c7:	83 c4 10             	add    $0x10,%esp
f01021ca:	85 c0                	test   %eax,%eax
f01021cc:	74 19                	je     f01021e7 <check_page+0x3af>
f01021ce:	68 a1 6d 10 f0       	push   $0xf0106da1
f01021d3:	68 de 6b 10 f0       	push   $0xf0106bde
f01021d8:	68 d1 03 00 00       	push   $0x3d1
f01021dd:	68 bf 6b 10 f0       	push   $0xf0106bbf
f01021e2:	e8 76 de ff ff       	call   f010005d <_panic>

	// check that pgdir_walk returns a pointer to the pte
	ptep = (pte_t *) KADDR(PTE_ADDR(kern_pgdir[PDX(PGSIZE)]));
f01021e7:	8b 3d 0c 6f 28 f0    	mov    0xf0286f0c,%edi
f01021ed:	8b 0f                	mov    (%edi),%ecx
f01021ef:	81 e1 00 f0 ff ff    	and    $0xfffff000,%ecx
f01021f5:	ba d4 03 00 00       	mov    $0x3d4,%edx
f01021fa:	b8 bf 6b 10 f0       	mov    $0xf0106bbf,%eax
f01021ff:	e8 89 ea ff ff       	call   f0100c8d <_kaddr>
f0102204:	89 45 e4             	mov    %eax,-0x1c(%ebp)
	assert(pgdir_walk(kern_pgdir, (void*)PGSIZE, 0) == ptep+PTX(PGSIZE));
f0102207:	83 ec 04             	sub    $0x4,%esp
f010220a:	6a 00                	push   $0x0
f010220c:	68 00 10 00 00       	push   $0x1000
f0102211:	57                   	push   %edi
f0102212:	e8 6e f6 ff ff       	call   f0101885 <pgdir_walk>
f0102217:	8b 4d e4             	mov    -0x1c(%ebp),%ecx
f010221a:	8d 51 04             	lea    0x4(%ecx),%edx
f010221d:	83 c4 10             	add    $0x10,%esp
f0102220:	39 d0                	cmp    %edx,%eax
f0102222:	74 19                	je     f010223d <check_page+0x405>
f0102224:	68 2c 67 10 f0       	push   $0xf010672c
f0102229:	68 de 6b 10 f0       	push   $0xf0106bde
f010222e:	68 d5 03 00 00       	push   $0x3d5
f0102233:	68 bf 6b 10 f0       	push   $0xf0106bbf
f0102238:	e8 20 de ff ff       	call   f010005d <_panic>

	// should be able to change permissions too.
	assert(page_insert(kern_pgdir, pp2, (void*) PGSIZE, PTE_W|PTE_U) == 0);
f010223d:	6a 06                	push   $0x6
f010223f:	68 00 10 00 00       	push   $0x1000
f0102244:	53                   	push   %ebx
f0102245:	ff 35 0c 6f 28 f0    	pushl  0xf0286f0c
f010224b:	e8 a7 f8 ff ff       	call   f0101af7 <page_insert>
f0102250:	83 c4 10             	add    $0x10,%esp
f0102253:	85 c0                	test   %eax,%eax
f0102255:	74 19                	je     f0102270 <check_page+0x438>
f0102257:	68 6c 67 10 f0       	push   $0xf010676c
f010225c:	68 de 6b 10 f0       	push   $0xf0106bde
f0102261:	68 d8 03 00 00       	push   $0x3d8
f0102266:	68 bf 6b 10 f0       	push   $0xf0106bbf
f010226b:	e8 ed dd ff ff       	call   f010005d <_panic>
	assert(check_va2pa(kern_pgdir, PGSIZE) == page2pa(pp2));
f0102270:	8b 3d 0c 6f 28 f0    	mov    0xf0286f0c,%edi
f0102276:	ba 00 10 00 00       	mov    $0x1000,%edx
f010227b:	89 f8                	mov    %edi,%eax
f010227d:	e8 55 ea ff ff       	call   f0100cd7 <check_va2pa>
f0102282:	89 45 d0             	mov    %eax,-0x30(%ebp)
f0102285:	89 d8                	mov    %ebx,%eax
f0102287:	e8 61 e9 ff ff       	call   f0100bed <page2pa>
f010228c:	39 45 d0             	cmp    %eax,-0x30(%ebp)
f010228f:	74 19                	je     f01022aa <check_page+0x472>
f0102291:	68 fc 66 10 f0       	push   $0xf01066fc
f0102296:	68 de 6b 10 f0       	push   $0xf0106bde
f010229b:	68 d9 03 00 00       	push   $0x3d9
f01022a0:	68 bf 6b 10 f0       	push   $0xf0106bbf
f01022a5:	e8 b3 dd ff ff       	call   f010005d <_panic>
	assert(pp2->pp_ref == 1);
f01022aa:	66 83 7b 04 01       	cmpw   $0x1,0x4(%ebx)
f01022af:	74 19                	je     f01022ca <check_page+0x492>
f01022b1:	68 39 6e 10 f0       	push   $0xf0106e39
f01022b6:	68 de 6b 10 f0       	push   $0xf0106bde
f01022bb:	68 da 03 00 00       	push   $0x3da
f01022c0:	68 bf 6b 10 f0       	push   $0xf0106bbf
f01022c5:	e8 93 dd ff ff       	call   f010005d <_panic>
	assert(*pgdir_walk(kern_pgdir, (void*) PGSIZE, 0) & PTE_U);
f01022ca:	83 ec 04             	sub    $0x4,%esp
f01022cd:	6a 00                	push   $0x0
f01022cf:	68 00 10 00 00       	push   $0x1000
f01022d4:	57                   	push   %edi
f01022d5:	e8 ab f5 ff ff       	call   f0101885 <pgdir_walk>
f01022da:	83 c4 10             	add    $0x10,%esp
f01022dd:	f6 00 04             	testb  $0x4,(%eax)
f01022e0:	75 19                	jne    f01022fb <check_page+0x4c3>
f01022e2:	68 ac 67 10 f0       	push   $0xf01067ac
f01022e7:	68 de 6b 10 f0       	push   $0xf0106bde
f01022ec:	68 db 03 00 00       	push   $0x3db
f01022f1:	68 bf 6b 10 f0       	push   $0xf0106bbf
f01022f6:	e8 62 dd ff ff       	call   f010005d <_panic>
	assert(kern_pgdir[0] & PTE_U);
f01022fb:	a1 0c 6f 28 f0       	mov    0xf0286f0c,%eax
f0102300:	f6 00 04             	testb  $0x4,(%eax)
f0102303:	75 19                	jne    f010231e <check_page+0x4e6>
f0102305:	68 91 6e 10 f0       	push   $0xf0106e91
f010230a:	68 de 6b 10 f0       	push   $0xf0106bde
f010230f:	68 dc 03 00 00       	push   $0x3dc
f0102314:	68 bf 6b 10 f0       	push   $0xf0106bbf
f0102319:	e8 3f dd ff ff       	call   f010005d <_panic>

	// should be able to remap with fewer permissions
	assert(page_insert(kern_pgdir, pp2, (void*) PGSIZE, PTE_W) == 0);
f010231e:	6a 02                	push   $0x2
f0102320:	68 00 10 00 00       	push   $0x1000
f0102325:	53                   	push   %ebx
f0102326:	50                   	push   %eax
f0102327:	e8 cb f7 ff ff       	call   f0101af7 <page_insert>
f010232c:	83 c4 10             	add    $0x10,%esp
f010232f:	85 c0                	test   %eax,%eax
f0102331:	74 19                	je     f010234c <check_page+0x514>
f0102333:	68 c0 66 10 f0       	push   $0xf01066c0
f0102338:	68 de 6b 10 f0       	push   $0xf0106bde
f010233d:	68 df 03 00 00       	push   $0x3df
f0102342:	68 bf 6b 10 f0       	push   $0xf0106bbf
f0102347:	e8 11 dd ff ff       	call   f010005d <_panic>
	assert(*pgdir_walk(kern_pgdir, (void*) PGSIZE, 0) & PTE_W);
f010234c:	83 ec 04             	sub    $0x4,%esp
f010234f:	6a 00                	push   $0x0
f0102351:	68 00 10 00 00       	push   $0x1000
f0102356:	ff 35 0c 6f 28 f0    	pushl  0xf0286f0c
f010235c:	e8 24 f5 ff ff       	call   f0101885 <pgdir_walk>
f0102361:	83 c4 10             	add    $0x10,%esp
f0102364:	f6 00 02             	testb  $0x2,(%eax)
f0102367:	75 19                	jne    f0102382 <check_page+0x54a>
f0102369:	68 e0 67 10 f0       	push   $0xf01067e0
f010236e:	68 de 6b 10 f0       	push   $0xf0106bde
f0102373:	68 e0 03 00 00       	push   $0x3e0
f0102378:	68 bf 6b 10 f0       	push   $0xf0106bbf
f010237d:	e8 db dc ff ff       	call   f010005d <_panic>
	assert(!(*pgdir_walk(kern_pgdir, (void*) PGSIZE, 0) & PTE_U));
f0102382:	83 ec 04             	sub    $0x4,%esp
f0102385:	6a 00                	push   $0x0
f0102387:	68 00 10 00 00       	push   $0x1000
f010238c:	ff 35 0c 6f 28 f0    	pushl  0xf0286f0c
f0102392:	e8 ee f4 ff ff       	call   f0101885 <pgdir_walk>
f0102397:	83 c4 10             	add    $0x10,%esp
f010239a:	f6 00 04             	testb  $0x4,(%eax)
f010239d:	74 19                	je     f01023b8 <check_page+0x580>
f010239f:	68 14 68 10 f0       	push   $0xf0106814
f01023a4:	68 de 6b 10 f0       	push   $0xf0106bde
f01023a9:	68 e1 03 00 00       	push   $0x3e1
f01023ae:	68 bf 6b 10 f0       	push   $0xf0106bbf
f01023b3:	e8 a5 dc ff ff       	call   f010005d <_panic>

	// should not be able to map at PTSIZE because need free page for page table
	assert(page_insert(kern_pgdir, pp0, (void*) PTSIZE, PTE_W) < 0);
f01023b8:	6a 02                	push   $0x2
f01023ba:	68 00 00 40 00       	push   $0x400000
f01023bf:	ff 75 d4             	pushl  -0x2c(%ebp)
f01023c2:	ff 35 0c 6f 28 f0    	pushl  0xf0286f0c
f01023c8:	e8 2a f7 ff ff       	call   f0101af7 <page_insert>
f01023cd:	83 c4 10             	add    $0x10,%esp
f01023d0:	85 c0                	test   %eax,%eax
f01023d2:	78 19                	js     f01023ed <check_page+0x5b5>
f01023d4:	68 4c 68 10 f0       	push   $0xf010684c
f01023d9:	68 de 6b 10 f0       	push   $0xf0106bde
f01023de:	68 e4 03 00 00       	push   $0x3e4
f01023e3:	68 bf 6b 10 f0       	push   $0xf0106bbf
f01023e8:	e8 70 dc ff ff       	call   f010005d <_panic>

	// insert pp1 at PGSIZE (replacing pp2)
	assert(page_insert(kern_pgdir, pp1, (void*) PGSIZE, PTE_W) == 0);
f01023ed:	6a 02                	push   $0x2
f01023ef:	68 00 10 00 00       	push   $0x1000
f01023f4:	56                   	push   %esi
f01023f5:	ff 35 0c 6f 28 f0    	pushl  0xf0286f0c
f01023fb:	e8 f7 f6 ff ff       	call   f0101af7 <page_insert>
f0102400:	83 c4 10             	add    $0x10,%esp
f0102403:	85 c0                	test   %eax,%eax
f0102405:	74 19                	je     f0102420 <check_page+0x5e8>
f0102407:	68 84 68 10 f0       	push   $0xf0106884
f010240c:	68 de 6b 10 f0       	push   $0xf0106bde
f0102411:	68 e7 03 00 00       	push   $0x3e7
f0102416:	68 bf 6b 10 f0       	push   $0xf0106bbf
f010241b:	e8 3d dc ff ff       	call   f010005d <_panic>
	assert(!(*pgdir_walk(kern_pgdir, (void*) PGSIZE, 0) & PTE_U));
f0102420:	83 ec 04             	sub    $0x4,%esp
f0102423:	6a 00                	push   $0x0
f0102425:	68 00 10 00 00       	push   $0x1000
f010242a:	ff 35 0c 6f 28 f0    	pushl  0xf0286f0c
f0102430:	e8 50 f4 ff ff       	call   f0101885 <pgdir_walk>
f0102435:	83 c4 10             	add    $0x10,%esp
f0102438:	f6 00 04             	testb  $0x4,(%eax)
f010243b:	74 19                	je     f0102456 <check_page+0x61e>
f010243d:	68 14 68 10 f0       	push   $0xf0106814
f0102442:	68 de 6b 10 f0       	push   $0xf0106bde
f0102447:	68 e8 03 00 00       	push   $0x3e8
f010244c:	68 bf 6b 10 f0       	push   $0xf0106bbf
f0102451:	e8 07 dc ff ff       	call   f010005d <_panic>

	// should have pp1 at both 0 and PGSIZE, pp2 nowhere, ...
	assert(check_va2pa(kern_pgdir, 0) == page2pa(pp1));
f0102456:	8b 3d 0c 6f 28 f0    	mov    0xf0286f0c,%edi
f010245c:	ba 00 00 00 00       	mov    $0x0,%edx
f0102461:	89 f8                	mov    %edi,%eax
f0102463:	e8 6f e8 ff ff       	call   f0100cd7 <check_va2pa>
f0102468:	89 45 d0             	mov    %eax,-0x30(%ebp)
f010246b:	89 f0                	mov    %esi,%eax
f010246d:	e8 7b e7 ff ff       	call   f0100bed <page2pa>
f0102472:	39 45 d0             	cmp    %eax,-0x30(%ebp)
f0102475:	74 19                	je     f0102490 <check_page+0x658>
f0102477:	68 c0 68 10 f0       	push   $0xf01068c0
f010247c:	68 de 6b 10 f0       	push   $0xf0106bde
f0102481:	68 eb 03 00 00       	push   $0x3eb
f0102486:	68 bf 6b 10 f0       	push   $0xf0106bbf
f010248b:	e8 cd db ff ff       	call   f010005d <_panic>
	assert(check_va2pa(kern_pgdir, PGSIZE) == page2pa(pp1));
f0102490:	ba 00 10 00 00       	mov    $0x1000,%edx
f0102495:	89 f8                	mov    %edi,%eax
f0102497:	e8 3b e8 ff ff       	call   f0100cd7 <check_va2pa>
f010249c:	39 45 d0             	cmp    %eax,-0x30(%ebp)
f010249f:	74 19                	je     f01024ba <check_page+0x682>
f01024a1:	68 ec 68 10 f0       	push   $0xf01068ec
f01024a6:	68 de 6b 10 f0       	push   $0xf0106bde
f01024ab:	68 ec 03 00 00       	push   $0x3ec
f01024b0:	68 bf 6b 10 f0       	push   $0xf0106bbf
f01024b5:	e8 a3 db ff ff       	call   f010005d <_panic>
	// ... and ref counts should reflect this
	assert(pp1->pp_ref == 2);
f01024ba:	66 83 7e 04 02       	cmpw   $0x2,0x4(%esi)
f01024bf:	74 19                	je     f01024da <check_page+0x6a2>
f01024c1:	68 a7 6e 10 f0       	push   $0xf0106ea7
f01024c6:	68 de 6b 10 f0       	push   $0xf0106bde
f01024cb:	68 ee 03 00 00       	push   $0x3ee
f01024d0:	68 bf 6b 10 f0       	push   $0xf0106bbf
f01024d5:	e8 83 db ff ff       	call   f010005d <_panic>
	assert(pp2->pp_ref == 0);
f01024da:	66 83 7b 04 00       	cmpw   $0x0,0x4(%ebx)
f01024df:	74 19                	je     f01024fa <check_page+0x6c2>
f01024e1:	68 5b 6e 10 f0       	push   $0xf0106e5b
f01024e6:	68 de 6b 10 f0       	push   $0xf0106bde
f01024eb:	68 ef 03 00 00       	push   $0x3ef
f01024f0:	68 bf 6b 10 f0       	push   $0xf0106bbf
f01024f5:	e8 63 db ff ff       	call   f010005d <_panic>

	// pp2 should be returned by page_alloc
	assert((pp = page_alloc(0)) && pp == pp2);
f01024fa:	83 ec 0c             	sub    $0xc,%esp
f01024fd:	6a 00                	push   $0x0
f01024ff:	e8 f6 ee ff ff       	call   f01013fa <page_alloc>
f0102504:	83 c4 10             	add    $0x10,%esp
f0102507:	39 c3                	cmp    %eax,%ebx
f0102509:	75 04                	jne    f010250f <check_page+0x6d7>
f010250b:	85 c0                	test   %eax,%eax
f010250d:	75 19                	jne    f0102528 <check_page+0x6f0>
f010250f:	68 1c 69 10 f0       	push   $0xf010691c
f0102514:	68 de 6b 10 f0       	push   $0xf0106bde
f0102519:	68 f2 03 00 00       	push   $0x3f2
f010251e:	68 bf 6b 10 f0       	push   $0xf0106bbf
f0102523:	e8 35 db ff ff       	call   f010005d <_panic>

	// unmapping pp1 at 0 should keep pp1 at PGSIZE
	page_remove(kern_pgdir, 0x0);
f0102528:	83 ec 08             	sub    $0x8,%esp
f010252b:	6a 00                	push   $0x0
f010252d:	ff 35 0c 6f 28 f0    	pushl  0xf0286f0c
f0102533:	e8 79 f5 ff ff       	call   f0101ab1 <page_remove>
	assert(check_va2pa(kern_pgdir, 0x0) == ~0);
f0102538:	8b 3d 0c 6f 28 f0    	mov    0xf0286f0c,%edi
f010253e:	ba 00 00 00 00       	mov    $0x0,%edx
f0102543:	89 f8                	mov    %edi,%eax
f0102545:	e8 8d e7 ff ff       	call   f0100cd7 <check_va2pa>
f010254a:	83 c4 10             	add    $0x10,%esp
f010254d:	83 f8 ff             	cmp    $0xffffffff,%eax
f0102550:	74 19                	je     f010256b <check_page+0x733>
f0102552:	68 40 69 10 f0       	push   $0xf0106940
f0102557:	68 de 6b 10 f0       	push   $0xf0106bde
f010255c:	68 f6 03 00 00       	push   $0x3f6
f0102561:	68 bf 6b 10 f0       	push   $0xf0106bbf
f0102566:	e8 f2 da ff ff       	call   f010005d <_panic>
	assert(check_va2pa(kern_pgdir, PGSIZE) == page2pa(pp1));
f010256b:	ba 00 10 00 00       	mov    $0x1000,%edx
f0102570:	89 f8                	mov    %edi,%eax
f0102572:	e8 60 e7 ff ff       	call   f0100cd7 <check_va2pa>
f0102577:	89 45 d0             	mov    %eax,-0x30(%ebp)
f010257a:	89 f0                	mov    %esi,%eax
f010257c:	e8 6c e6 ff ff       	call   f0100bed <page2pa>
f0102581:	39 45 d0             	cmp    %eax,-0x30(%ebp)
f0102584:	74 19                	je     f010259f <check_page+0x767>
f0102586:	68 ec 68 10 f0       	push   $0xf01068ec
f010258b:	68 de 6b 10 f0       	push   $0xf0106bde
f0102590:	68 f7 03 00 00       	push   $0x3f7
f0102595:	68 bf 6b 10 f0       	push   $0xf0106bbf
f010259a:	e8 be da ff ff       	call   f010005d <_panic>
	assert(pp1->pp_ref == 1);
f010259f:	66 83 7e 04 01       	cmpw   $0x1,0x4(%esi)
f01025a4:	74 19                	je     f01025bf <check_page+0x787>
f01025a6:	68 28 6e 10 f0       	push   $0xf0106e28
f01025ab:	68 de 6b 10 f0       	push   $0xf0106bde
f01025b0:	68 f8 03 00 00       	push   $0x3f8
f01025b5:	68 bf 6b 10 f0       	push   $0xf0106bbf
f01025ba:	e8 9e da ff ff       	call   f010005d <_panic>
	assert(pp2->pp_ref == 0);
f01025bf:	66 83 7b 04 00       	cmpw   $0x0,0x4(%ebx)
f01025c4:	74 19                	je     f01025df <check_page+0x7a7>
f01025c6:	68 5b 6e 10 f0       	push   $0xf0106e5b
f01025cb:	68 de 6b 10 f0       	push   $0xf0106bde
f01025d0:	68 f9 03 00 00       	push   $0x3f9
f01025d5:	68 bf 6b 10 f0       	push   $0xf0106bbf
f01025da:	e8 7e da ff ff       	call   f010005d <_panic>

	// test re-inserting pp1 at PGSIZE
	assert(page_insert(kern_pgdir, pp1, (void*) PGSIZE, 0) == 0);
f01025df:	6a 00                	push   $0x0
f01025e1:	68 00 10 00 00       	push   $0x1000
f01025e6:	56                   	push   %esi
f01025e7:	57                   	push   %edi
f01025e8:	e8 0a f5 ff ff       	call   f0101af7 <page_insert>
f01025ed:	83 c4 10             	add    $0x10,%esp
f01025f0:	85 c0                	test   %eax,%eax
f01025f2:	74 19                	je     f010260d <check_page+0x7d5>
f01025f4:	68 64 69 10 f0       	push   $0xf0106964
f01025f9:	68 de 6b 10 f0       	push   $0xf0106bde
f01025fe:	68 fc 03 00 00       	push   $0x3fc
f0102603:	68 bf 6b 10 f0       	push   $0xf0106bbf
f0102608:	e8 50 da ff ff       	call   f010005d <_panic>
	assert(pp1->pp_ref);
f010260d:	66 83 7e 04 00       	cmpw   $0x0,0x4(%esi)
f0102612:	75 19                	jne    f010262d <check_page+0x7f5>
f0102614:	68 b8 6e 10 f0       	push   $0xf0106eb8
f0102619:	68 de 6b 10 f0       	push   $0xf0106bde
f010261e:	68 fd 03 00 00       	push   $0x3fd
f0102623:	68 bf 6b 10 f0       	push   $0xf0106bbf
f0102628:	e8 30 da ff ff       	call   f010005d <_panic>
	assert(pp1->pp_link == NULL);
f010262d:	83 3e 00             	cmpl   $0x0,(%esi)
f0102630:	74 19                	je     f010264b <check_page+0x813>
f0102632:	68 c4 6e 10 f0       	push   $0xf0106ec4
f0102637:	68 de 6b 10 f0       	push   $0xf0106bde
f010263c:	68 fe 03 00 00       	push   $0x3fe
f0102641:	68 bf 6b 10 f0       	push   $0xf0106bbf
f0102646:	e8 12 da ff ff       	call   f010005d <_panic>

	// unmapping pp1 at PGSIZE should free it
	page_remove(kern_pgdir, (void*) PGSIZE);
f010264b:	83 ec 08             	sub    $0x8,%esp
f010264e:	68 00 10 00 00       	push   $0x1000
f0102653:	ff 35 0c 6f 28 f0    	pushl  0xf0286f0c
f0102659:	e8 53 f4 ff ff       	call   f0101ab1 <page_remove>
	assert(check_va2pa(kern_pgdir, 0x0) == ~0);
f010265e:	8b 3d 0c 6f 28 f0    	mov    0xf0286f0c,%edi
f0102664:	ba 00 00 00 00       	mov    $0x0,%edx
f0102669:	89 f8                	mov    %edi,%eax
f010266b:	e8 67 e6 ff ff       	call   f0100cd7 <check_va2pa>
f0102670:	83 c4 10             	add    $0x10,%esp
f0102673:	83 f8 ff             	cmp    $0xffffffff,%eax
f0102676:	74 19                	je     f0102691 <check_page+0x859>
f0102678:	68 40 69 10 f0       	push   $0xf0106940
f010267d:	68 de 6b 10 f0       	push   $0xf0106bde
f0102682:	68 02 04 00 00       	push   $0x402
f0102687:	68 bf 6b 10 f0       	push   $0xf0106bbf
f010268c:	e8 cc d9 ff ff       	call   f010005d <_panic>
	assert(check_va2pa(kern_pgdir, PGSIZE) == ~0);
f0102691:	ba 00 10 00 00       	mov    $0x1000,%edx
f0102696:	89 f8                	mov    %edi,%eax
f0102698:	e8 3a e6 ff ff       	call   f0100cd7 <check_va2pa>
f010269d:	83 f8 ff             	cmp    $0xffffffff,%eax
f01026a0:	74 19                	je     f01026bb <check_page+0x883>
f01026a2:	68 9c 69 10 f0       	push   $0xf010699c
f01026a7:	68 de 6b 10 f0       	push   $0xf0106bde
f01026ac:	68 03 04 00 00       	push   $0x403
f01026b1:	68 bf 6b 10 f0       	push   $0xf0106bbf
f01026b6:	e8 a2 d9 ff ff       	call   f010005d <_panic>
	assert(pp1->pp_ref == 0);
f01026bb:	66 83 7e 04 00       	cmpw   $0x0,0x4(%esi)
f01026c0:	74 19                	je     f01026db <check_page+0x8a3>
f01026c2:	68 4a 6e 10 f0       	push   $0xf0106e4a
f01026c7:	68 de 6b 10 f0       	push   $0xf0106bde
f01026cc:	68 04 04 00 00       	push   $0x404
f01026d1:	68 bf 6b 10 f0       	push   $0xf0106bbf
f01026d6:	e8 82 d9 ff ff       	call   f010005d <_panic>
	assert(pp2->pp_ref == 0);
f01026db:	66 83 7b 04 00       	cmpw   $0x0,0x4(%ebx)
f01026e0:	74 19                	je     f01026fb <check_page+0x8c3>
f01026e2:	68 5b 6e 10 f0       	push   $0xf0106e5b
f01026e7:	68 de 6b 10 f0       	push   $0xf0106bde
f01026ec:	68 05 04 00 00       	push   $0x405
f01026f1:	68 bf 6b 10 f0       	push   $0xf0106bbf
f01026f6:	e8 62 d9 ff ff       	call   f010005d <_panic>

	// so it should be returned by page_alloc
	assert((pp = page_alloc(0)) && pp == pp1);
f01026fb:	83 ec 0c             	sub    $0xc,%esp
f01026fe:	6a 00                	push   $0x0
f0102700:	e8 f5 ec ff ff       	call   f01013fa <page_alloc>
f0102705:	83 c4 10             	add    $0x10,%esp
f0102708:	39 c6                	cmp    %eax,%esi
f010270a:	75 04                	jne    f0102710 <check_page+0x8d8>
f010270c:	85 c0                	test   %eax,%eax
f010270e:	75 19                	jne    f0102729 <check_page+0x8f1>
f0102710:	68 c4 69 10 f0       	push   $0xf01069c4
f0102715:	68 de 6b 10 f0       	push   $0xf0106bde
f010271a:	68 08 04 00 00       	push   $0x408
f010271f:	68 bf 6b 10 f0       	push   $0xf0106bbf
f0102724:	e8 34 d9 ff ff       	call   f010005d <_panic>

	// should be no free memory
	assert(!page_alloc(0));
f0102729:	83 ec 0c             	sub    $0xc,%esp
f010272c:	6a 00                	push   $0x0
f010272e:	e8 c7 ec ff ff       	call   f01013fa <page_alloc>
f0102733:	83 c4 10             	add    $0x10,%esp
f0102736:	85 c0                	test   %eax,%eax
f0102738:	74 19                	je     f0102753 <check_page+0x91b>
f010273a:	68 a1 6d 10 f0       	push   $0xf0106da1
f010273f:	68 de 6b 10 f0       	push   $0xf0106bde
f0102744:	68 0b 04 00 00       	push   $0x40b
f0102749:	68 bf 6b 10 f0       	push   $0xf0106bbf
f010274e:	e8 0a d9 ff ff       	call   f010005d <_panic>

	// forcibly take pp0 back
	assert(PTE_ADDR(kern_pgdir[0]) == page2pa(pp0));
f0102753:	8b 3d 0c 6f 28 f0    	mov    0xf0286f0c,%edi
f0102759:	8b 45 d4             	mov    -0x2c(%ebp),%eax
f010275c:	e8 8c e4 ff ff       	call   f0100bed <page2pa>
f0102761:	8b 17                	mov    (%edi),%edx
f0102763:	81 e2 00 f0 ff ff    	and    $0xfffff000,%edx
f0102769:	39 c2                	cmp    %eax,%edx
f010276b:	74 19                	je     f0102786 <check_page+0x94e>
f010276d:	68 a4 65 10 f0       	push   $0xf01065a4
f0102772:	68 de 6b 10 f0       	push   $0xf0106bde
f0102777:	68 0e 04 00 00       	push   $0x40e
f010277c:	68 bf 6b 10 f0       	push   $0xf0106bbf
f0102781:	e8 d7 d8 ff ff       	call   f010005d <_panic>
	kern_pgdir[0] = 0;
f0102786:	c7 07 00 00 00 00    	movl   $0x0,(%edi)
	assert(pp0->pp_ref == 1);
f010278c:	8b 45 d4             	mov    -0x2c(%ebp),%eax
f010278f:	66 83 78 04 01       	cmpw   $0x1,0x4(%eax)
f0102794:	74 19                	je     f01027af <check_page+0x977>
f0102796:	68 6c 6e 10 f0       	push   $0xf0106e6c
f010279b:	68 de 6b 10 f0       	push   $0xf0106bde
f01027a0:	68 10 04 00 00       	push   $0x410
f01027a5:	68 bf 6b 10 f0       	push   $0xf0106bbf
f01027aa:	e8 ae d8 ff ff       	call   f010005d <_panic>
	pp0->pp_ref = 0;
f01027af:	8b 45 d4             	mov    -0x2c(%ebp),%eax
f01027b2:	66 c7 40 04 00 00    	movw   $0x0,0x4(%eax)

	// check pointer arithmetic in pgdir_walk
	page_free(pp0);
f01027b8:	83 ec 0c             	sub    $0xc,%esp
f01027bb:	50                   	push   %eax
f01027bc:	e8 7e ec ff ff       	call   f010143f <page_free>
	va = (void*)(PGSIZE * NPDENTRIES + PGSIZE);
	ptep = pgdir_walk(kern_pgdir, va, 1);
f01027c1:	83 c4 0c             	add    $0xc,%esp
f01027c4:	6a 01                	push   $0x1
f01027c6:	68 00 10 40 00       	push   $0x401000
f01027cb:	ff 35 0c 6f 28 f0    	pushl  0xf0286f0c
f01027d1:	e8 af f0 ff ff       	call   f0101885 <pgdir_walk>
f01027d6:	89 45 d0             	mov    %eax,-0x30(%ebp)
f01027d9:	89 45 e4             	mov    %eax,-0x1c(%ebp)
	ptep1 = (pte_t *) KADDR(PTE_ADDR(kern_pgdir[PDX(va)]));
f01027dc:	8b 3d 0c 6f 28 f0    	mov    0xf0286f0c,%edi
f01027e2:	8b 4f 04             	mov    0x4(%edi),%ecx
f01027e5:	81 e1 00 f0 ff ff    	and    $0xfffff000,%ecx
f01027eb:	ba 17 04 00 00       	mov    $0x417,%edx
f01027f0:	b8 bf 6b 10 f0       	mov    $0xf0106bbf,%eax
f01027f5:	e8 93 e4 ff ff       	call   f0100c8d <_kaddr>
	assert(ptep == ptep1 + PTX(va));
f01027fa:	83 c0 04             	add    $0x4,%eax
f01027fd:	83 c4 10             	add    $0x10,%esp
f0102800:	39 45 d0             	cmp    %eax,-0x30(%ebp)
f0102803:	74 19                	je     f010281e <check_page+0x9e6>
f0102805:	68 d9 6e 10 f0       	push   $0xf0106ed9
f010280a:	68 de 6b 10 f0       	push   $0xf0106bde
f010280f:	68 18 04 00 00       	push   $0x418
f0102814:	68 bf 6b 10 f0       	push   $0xf0106bbf
f0102819:	e8 3f d8 ff ff       	call   f010005d <_panic>
	kern_pgdir[PDX(va)] = 0;
f010281e:	c7 47 04 00 00 00 00 	movl   $0x0,0x4(%edi)
	pp0->pp_ref = 0;
f0102825:	8b 7d d4             	mov    -0x2c(%ebp),%edi
f0102828:	89 f8                	mov    %edi,%eax
f010282a:	66 c7 47 04 00 00    	movw   $0x0,0x4(%edi)

	// check that new page tables get cleared
	memset(page2kva(pp0), 0xFF, PGSIZE);
f0102830:	e8 84 e4 ff ff       	call   f0100cb9 <page2kva>
f0102835:	83 ec 04             	sub    $0x4,%esp
f0102838:	68 00 10 00 00       	push   $0x1000
f010283d:	68 ff 00 00 00       	push   $0xff
f0102842:	50                   	push   %eax
f0102843:	e8 31 27 00 00       	call   f0104f79 <memset>
	page_free(pp0);
f0102848:	89 3c 24             	mov    %edi,(%esp)
f010284b:	e8 ef eb ff ff       	call   f010143f <page_free>
	pgdir_walk(kern_pgdir, 0x0, 1);
f0102850:	83 c4 0c             	add    $0xc,%esp
f0102853:	6a 01                	push   $0x1
f0102855:	6a 00                	push   $0x0
f0102857:	ff 35 0c 6f 28 f0    	pushl  0xf0286f0c
f010285d:	e8 23 f0 ff ff       	call   f0101885 <pgdir_walk>
	ptep = (pte_t *) page2kva(pp0);
f0102862:	89 f8                	mov    %edi,%eax
f0102864:	e8 50 e4 ff ff       	call   f0100cb9 <page2kva>
f0102869:	89 45 e4             	mov    %eax,-0x1c(%ebp)
f010286c:	89 c2                	mov    %eax,%edx
f010286e:	05 00 10 00 00       	add    $0x1000,%eax
f0102873:	83 c4 10             	add    $0x10,%esp
	for(i=0; i<NPTENTRIES; i++)
		assert((ptep[i] & PTE_P) == 0);
f0102876:	f6 02 01             	testb  $0x1,(%edx)
f0102879:	74 19                	je     f0102894 <check_page+0xa5c>
f010287b:	68 f1 6e 10 f0       	push   $0xf0106ef1
f0102880:	68 de 6b 10 f0       	push   $0xf0106bde
f0102885:	68 22 04 00 00       	push   $0x422
f010288a:	68 bf 6b 10 f0       	push   $0xf0106bbf
f010288f:	e8 c9 d7 ff ff       	call   f010005d <_panic>
f0102894:	83 c2 04             	add    $0x4,%edx
	// check that new page tables get cleared
	memset(page2kva(pp0), 0xFF, PGSIZE);
	page_free(pp0);
	pgdir_walk(kern_pgdir, 0x0, 1);
	ptep = (pte_t *) page2kva(pp0);
	for(i=0; i<NPTENTRIES; i++)
f0102897:	39 d0                	cmp    %edx,%eax
f0102899:	75 db                	jne    f0102876 <check_page+0xa3e>
		assert((ptep[i] & PTE_P) == 0);
	kern_pgdir[0] = 0;
f010289b:	a1 0c 6f 28 f0       	mov    0xf0286f0c,%eax
f01028a0:	c7 00 00 00 00 00    	movl   $0x0,(%eax)
	pp0->pp_ref = 0;
f01028a6:	8b 45 d4             	mov    -0x2c(%ebp),%eax
f01028a9:	66 c7 40 04 00 00    	movw   $0x0,0x4(%eax)

	// give free list back
	page_free_list = fl;
f01028af:	8b 4d cc             	mov    -0x34(%ebp),%ecx
f01028b2:	89 0d 40 52 28 f0    	mov    %ecx,0xf0285240

	// free the pages we took
	page_free(pp0);
f01028b8:	83 ec 0c             	sub    $0xc,%esp
f01028bb:	50                   	push   %eax
f01028bc:	e8 7e eb ff ff       	call   f010143f <page_free>
	page_free(pp1);
f01028c1:	89 34 24             	mov    %esi,(%esp)
f01028c4:	e8 76 eb ff ff       	call   f010143f <page_free>
	page_free(pp2);
f01028c9:	89 1c 24             	mov    %ebx,(%esp)
f01028cc:	e8 6e eb ff ff       	call   f010143f <page_free>

	// test mmio_map_region
	mm1 = (uintptr_t) mmio_map_region(0, 4097);
f01028d1:	83 c4 08             	add    $0x8,%esp
f01028d4:	68 01 10 00 00       	push   $0x1001
f01028d9:	6a 00                	push   $0x0
f01028db:	e8 f5 f4 ff ff       	call   f0101dd5 <mmio_map_region>
f01028e0:	89 c3                	mov    %eax,%ebx
	mm2 = (uintptr_t) mmio_map_region(0, 4096);
f01028e2:	83 c4 08             	add    $0x8,%esp
f01028e5:	68 00 10 00 00       	push   $0x1000
f01028ea:	6a 00                	push   $0x0
f01028ec:	e8 e4 f4 ff ff       	call   f0101dd5 <mmio_map_region>
f01028f1:	89 c6                	mov    %eax,%esi
	// check that they're in the right region
	assert(mm1 >= MMIOBASE && mm1 + 8096 < MMIOLIM);
f01028f3:	8d 83 a0 1f 00 00    	lea    0x1fa0(%ebx),%eax
f01028f9:	83 c4 10             	add    $0x10,%esp
f01028fc:	81 fb ff ff 7f ef    	cmp    $0xef7fffff,%ebx
f0102902:	76 07                	jbe    f010290b <check_page+0xad3>
f0102904:	3d ff ff bf ef       	cmp    $0xefbfffff,%eax
f0102909:	76 19                	jbe    f0102924 <check_page+0xaec>
f010290b:	68 e8 69 10 f0       	push   $0xf01069e8
f0102910:	68 de 6b 10 f0       	push   $0xf0106bde
f0102915:	68 32 04 00 00       	push   $0x432
f010291a:	68 bf 6b 10 f0       	push   $0xf0106bbf
f010291f:	e8 39 d7 ff ff       	call   f010005d <_panic>
	assert(mm2 >= MMIOBASE && mm2 + 8096 < MMIOLIM);
f0102924:	8d 96 a0 1f 00 00    	lea    0x1fa0(%esi),%edx
f010292a:	81 fa ff ff bf ef    	cmp    $0xefbfffff,%edx
f0102930:	77 08                	ja     f010293a <check_page+0xb02>
f0102932:	81 fe ff ff 7f ef    	cmp    $0xef7fffff,%esi
f0102938:	77 19                	ja     f0102953 <check_page+0xb1b>
f010293a:	68 10 6a 10 f0       	push   $0xf0106a10
f010293f:	68 de 6b 10 f0       	push   $0xf0106bde
f0102944:	68 33 04 00 00       	push   $0x433
f0102949:	68 bf 6b 10 f0       	push   $0xf0106bbf
f010294e:	e8 0a d7 ff ff       	call   f010005d <_panic>
	// check that they're page-aligned
	assert(mm1 % PGSIZE == 0 && mm2 % PGSIZE == 0);
f0102953:	89 da                	mov    %ebx,%edx
f0102955:	09 f2                	or     %esi,%edx
f0102957:	f7 c2 ff 0f 00 00    	test   $0xfff,%edx
f010295d:	74 19                	je     f0102978 <check_page+0xb40>
f010295f:	68 38 6a 10 f0       	push   $0xf0106a38
f0102964:	68 de 6b 10 f0       	push   $0xf0106bde
f0102969:	68 35 04 00 00       	push   $0x435
f010296e:	68 bf 6b 10 f0       	push   $0xf0106bbf
f0102973:	e8 e5 d6 ff ff       	call   f010005d <_panic>
	// check that they don't overlap
	assert(mm1 + 8096 <= mm2);
f0102978:	39 c6                	cmp    %eax,%esi
f010297a:	73 19                	jae    f0102995 <check_page+0xb5d>
f010297c:	68 08 6f 10 f0       	push   $0xf0106f08
f0102981:	68 de 6b 10 f0       	push   $0xf0106bde
f0102986:	68 37 04 00 00       	push   $0x437
f010298b:	68 bf 6b 10 f0       	push   $0xf0106bbf
f0102990:	e8 c8 d6 ff ff       	call   f010005d <_panic>
	// check page mappings
	assert(check_va2pa(kern_pgdir, mm1) == 0);
f0102995:	8b 3d 0c 6f 28 f0    	mov    0xf0286f0c,%edi
f010299b:	89 da                	mov    %ebx,%edx
f010299d:	89 f8                	mov    %edi,%eax
f010299f:	e8 33 e3 ff ff       	call   f0100cd7 <check_va2pa>
f01029a4:	85 c0                	test   %eax,%eax
f01029a6:	74 19                	je     f01029c1 <check_page+0xb89>
f01029a8:	68 60 6a 10 f0       	push   $0xf0106a60
f01029ad:	68 de 6b 10 f0       	push   $0xf0106bde
f01029b2:	68 39 04 00 00       	push   $0x439
f01029b7:	68 bf 6b 10 f0       	push   $0xf0106bbf
f01029bc:	e8 9c d6 ff ff       	call   f010005d <_panic>
	assert(check_va2pa(kern_pgdir, mm1+PGSIZE) == PGSIZE);
f01029c1:	8d 83 00 10 00 00    	lea    0x1000(%ebx),%eax
f01029c7:	89 45 d4             	mov    %eax,-0x2c(%ebp)
f01029ca:	89 c2                	mov    %eax,%edx
f01029cc:	89 f8                	mov    %edi,%eax
f01029ce:	e8 04 e3 ff ff       	call   f0100cd7 <check_va2pa>
f01029d3:	3d 00 10 00 00       	cmp    $0x1000,%eax
f01029d8:	74 19                	je     f01029f3 <check_page+0xbbb>
f01029da:	68 84 6a 10 f0       	push   $0xf0106a84
f01029df:	68 de 6b 10 f0       	push   $0xf0106bde
f01029e4:	68 3a 04 00 00       	push   $0x43a
f01029e9:	68 bf 6b 10 f0       	push   $0xf0106bbf
f01029ee:	e8 6a d6 ff ff       	call   f010005d <_panic>
	assert(check_va2pa(kern_pgdir, mm2) == 0);
f01029f3:	89 f2                	mov    %esi,%edx
f01029f5:	89 f8                	mov    %edi,%eax
f01029f7:	e8 db e2 ff ff       	call   f0100cd7 <check_va2pa>
f01029fc:	85 c0                	test   %eax,%eax
f01029fe:	74 19                	je     f0102a19 <check_page+0xbe1>
f0102a00:	68 b4 6a 10 f0       	push   $0xf0106ab4
f0102a05:	68 de 6b 10 f0       	push   $0xf0106bde
f0102a0a:	68 3b 04 00 00       	push   $0x43b
f0102a0f:	68 bf 6b 10 f0       	push   $0xf0106bbf
f0102a14:	e8 44 d6 ff ff       	call   f010005d <_panic>
	assert(check_va2pa(kern_pgdir, mm2+PGSIZE) == ~0);
f0102a19:	8d 96 00 10 00 00    	lea    0x1000(%esi),%edx
f0102a1f:	89 f8                	mov    %edi,%eax
f0102a21:	e8 b1 e2 ff ff       	call   f0100cd7 <check_va2pa>
f0102a26:	83 f8 ff             	cmp    $0xffffffff,%eax
f0102a29:	74 19                	je     f0102a44 <check_page+0xc0c>
f0102a2b:	68 d8 6a 10 f0       	push   $0xf0106ad8
f0102a30:	68 de 6b 10 f0       	push   $0xf0106bde
f0102a35:	68 3c 04 00 00       	push   $0x43c
f0102a3a:	68 bf 6b 10 f0       	push   $0xf0106bbf
f0102a3f:	e8 19 d6 ff ff       	call   f010005d <_panic>
	// check permissions
	assert(*pgdir_walk(kern_pgdir, (void*) mm1, 0) & (PTE_W|PTE_PWT|PTE_PCD));
f0102a44:	83 ec 04             	sub    $0x4,%esp
f0102a47:	6a 00                	push   $0x0
f0102a49:	53                   	push   %ebx
f0102a4a:	57                   	push   %edi
f0102a4b:	e8 35 ee ff ff       	call   f0101885 <pgdir_walk>
f0102a50:	83 c4 10             	add    $0x10,%esp
f0102a53:	f6 00 1a             	testb  $0x1a,(%eax)
f0102a56:	75 19                	jne    f0102a71 <check_page+0xc39>
f0102a58:	68 04 6b 10 f0       	push   $0xf0106b04
f0102a5d:	68 de 6b 10 f0       	push   $0xf0106bde
f0102a62:	68 3e 04 00 00       	push   $0x43e
f0102a67:	68 bf 6b 10 f0       	push   $0xf0106bbf
f0102a6c:	e8 ec d5 ff ff       	call   f010005d <_panic>
	assert(!(*pgdir_walk(kern_pgdir, (void*) mm1, 0) & PTE_U));
f0102a71:	83 ec 04             	sub    $0x4,%esp
f0102a74:	6a 00                	push   $0x0
f0102a76:	53                   	push   %ebx
f0102a77:	ff 35 0c 6f 28 f0    	pushl  0xf0286f0c
f0102a7d:	e8 03 ee ff ff       	call   f0101885 <pgdir_walk>
f0102a82:	83 c4 10             	add    $0x10,%esp
f0102a85:	f6 00 04             	testb  $0x4,(%eax)
f0102a88:	74 19                	je     f0102aa3 <check_page+0xc6b>
f0102a8a:	68 48 6b 10 f0       	push   $0xf0106b48
f0102a8f:	68 de 6b 10 f0       	push   $0xf0106bde
f0102a94:	68 3f 04 00 00       	push   $0x43f
f0102a99:	68 bf 6b 10 f0       	push   $0xf0106bbf
f0102a9e:	e8 ba d5 ff ff       	call   f010005d <_panic>
	// clear the mappings
	*pgdir_walk(kern_pgdir, (void*) mm1, 0) = 0;
f0102aa3:	83 ec 04             	sub    $0x4,%esp
f0102aa6:	6a 00                	push   $0x0
f0102aa8:	53                   	push   %ebx
f0102aa9:	ff 35 0c 6f 28 f0    	pushl  0xf0286f0c
f0102aaf:	e8 d1 ed ff ff       	call   f0101885 <pgdir_walk>
f0102ab4:	c7 00 00 00 00 00    	movl   $0x0,(%eax)
	*pgdir_walk(kern_pgdir, (void*) mm1 + PGSIZE, 0) = 0;
f0102aba:	83 c4 0c             	add    $0xc,%esp
f0102abd:	6a 00                	push   $0x0
f0102abf:	ff 75 d4             	pushl  -0x2c(%ebp)
f0102ac2:	ff 35 0c 6f 28 f0    	pushl  0xf0286f0c
f0102ac8:	e8 b8 ed ff ff       	call   f0101885 <pgdir_walk>
f0102acd:	c7 00 00 00 00 00    	movl   $0x0,(%eax)
	*pgdir_walk(kern_pgdir, (void*) mm2, 0) = 0;
f0102ad3:	83 c4 0c             	add    $0xc,%esp
f0102ad6:	6a 00                	push   $0x0
f0102ad8:	56                   	push   %esi
f0102ad9:	ff 35 0c 6f 28 f0    	pushl  0xf0286f0c
f0102adf:	e8 a1 ed ff ff       	call   f0101885 <pgdir_walk>
f0102ae4:	c7 00 00 00 00 00    	movl   $0x0,(%eax)

	cprintf("check_page() succeeded!\n");
f0102aea:	c7 04 24 1a 6f 10 f0 	movl   $0xf0106f1a,(%esp)
f0102af1:	e8 79 0d 00 00       	call   f010386f <cprintf>
}
f0102af6:	83 c4 10             	add    $0x10,%esp
f0102af9:	8d 65 f4             	lea    -0xc(%ebp),%esp
f0102afc:	5b                   	pop    %ebx
f0102afd:	5e                   	pop    %esi
f0102afe:	5f                   	pop    %edi
f0102aff:	5d                   	pop    %ebp
f0102b00:	c3                   	ret    

f0102b01 <mem_init>:
//
// From UTOP to ULIM, the user is allowed to read but not write.
// Above ULIM the user cannot read or write.
void
mem_init(void)
{
f0102b01:	55                   	push   %ebp
f0102b02:	89 e5                	mov    %esp,%ebp
f0102b04:	53                   	push   %ebx
f0102b05:	83 ec 04             	sub    $0x4,%esp
	uint32_t cr0;
	size_t n;

	// Find out how much memory the machine has (npages & npages_basemem).
	i386_detect_memory();
f0102b08:	e8 1a e1 ff ff       	call   f0100c27 <i386_detect_memory>
	// Remove this line when you're ready to test this function.
	//panic("mem_init: This function is not finished\n");

	//////////////////////////////////////////////////////////////////////
	// create initial page directory.
	kern_pgdir = (pde_t *) boot_alloc(PGSIZE);
f0102b0d:	b8 00 10 00 00       	mov    $0x1000,%eax
f0102b12:	e8 52 e2 ff ff       	call   f0100d69 <boot_alloc>
f0102b17:	a3 0c 6f 28 f0       	mov    %eax,0xf0286f0c
	memset(kern_pgdir, 0, PGSIZE);
f0102b1c:	83 ec 04             	sub    $0x4,%esp
f0102b1f:	68 00 10 00 00       	push   $0x1000
f0102b24:	6a 00                	push   $0x0
f0102b26:	50                   	push   %eax
f0102b27:	e8 4d 24 00 00       	call   f0104f79 <memset>
	// a virtual page table at virtual address UVPT.
	// (For now, you don't have understand the greater purpose of the
	// following line.)

	// Permissions: kernel R, user R
	kern_pgdir[PDX(UVPT)] = PADDR(kern_pgdir) | PTE_U | PTE_P;
f0102b2c:	8b 1d 0c 6f 28 f0    	mov    0xf0286f0c,%ebx
f0102b32:	89 d9                	mov    %ebx,%ecx
f0102b34:	ba 95 00 00 00       	mov    $0x95,%edx
f0102b39:	b8 bf 6b 10 f0       	mov    $0xf0106bbf,%eax
f0102b3e:	e8 04 e2 ff ff       	call   f0100d47 <_paddr>
f0102b43:	83 c8 05             	or     $0x5,%eax
f0102b46:	89 83 f4 0e 00 00    	mov    %eax,0xef4(%ebx)
	// The kernel uses this array to keep track of physical pages: for
	// each physical page, there is a corresponding struct PageInfo in this
	// array.  'npages' is the number of physical pages in memory.  Use memset
	// to initialize all fields of each struct PageInfo to 0.
	// Your code goes here:
	pages=boot_alloc(npages //[page]
f0102b4c:	a1 08 6f 28 f0       	mov    0xf0286f08,%eax
f0102b51:	c1 e0 03             	shl    $0x3,%eax
f0102b54:	e8 10 e2 ff ff       	call   f0100d69 <boot_alloc>
f0102b59:	a3 10 6f 28 f0       	mov    %eax,0xf0286f10
					 * sizeof(struct PageInfo));//[B/page]
	memset(pages,0,npages*sizeof(struct PageInfo));
f0102b5e:	83 c4 0c             	add    $0xc,%esp
f0102b61:	8b 1d 08 6f 28 f0    	mov    0xf0286f08,%ebx
f0102b67:	8d 14 dd 00 00 00 00 	lea    0x0(,%ebx,8),%edx
f0102b6e:	52                   	push   %edx
f0102b6f:	6a 00                	push   $0x0
f0102b71:	50                   	push   %eax
f0102b72:	e8 02 24 00 00       	call   f0104f79 <memset>
	//////////////////////////////////////////////////////////////////////
	// Make 'envs' point to an array of size 'NENV' of 'struct Env'.
	// LAB 3: Your code here.

	envs = boot_alloc(NENV*sizeof(struct Env));
f0102b77:	b8 00 f0 01 00       	mov    $0x1f000,%eax
f0102b7c:	e8 e8 e1 ff ff       	call   f0100d69 <boot_alloc>
f0102b81:	a3 44 52 28 f0       	mov    %eax,0xf0285244
	memset(envs,0, NENV*sizeof(struct Env));
f0102b86:	83 c4 0c             	add    $0xc,%esp
f0102b89:	68 00 f0 01 00       	push   $0x1f000
f0102b8e:	6a 00                	push   $0x0
f0102b90:	50                   	push   %eax
f0102b91:	e8 e3 23 00 00       	call   f0104f79 <memset>
	// Now that we've allocated the initial kernel data structures, we set
	// up the list of free physical pages. Once we've done so, all further
	// memory management will go through the page_* functions. In
	// particular, we can now map memory using boot_map_region
	// or page_insert
	page_init();
f0102b96:	e8 cc e7 ff ff       	call   f0101367 <page_init>

	check_page_free_list(1);
f0102b9b:	b8 01 00 00 00       	mov    $0x1,%eax
f0102ba0:	e8 c6 e4 ff ff       	call   f010106b <check_page_free_list>
	check_page_alloc();
f0102ba5:	e8 e7 e8 ff ff       	call   f0101491 <check_page_alloc>
	check_page();
f0102baa:	e8 89 f2 ff ff       	call   f0101e38 <check_page>
	// Permissions:
	//    - the new image at UPAGES -- kernel R, user R
	//      (ie. perm = PTE_U | PTE_P)
	//    - pages itself -- kernel RW, user NONE
	// Your code goes here:
	boot_map_region(kern_pgdir,UPAGES,npages*sizeof(struct PageInfo),PADDR(pages),PTE_U|PTE_P);
f0102baf:	8b 0d 10 6f 28 f0    	mov    0xf0286f10,%ecx
f0102bb5:	ba bf 00 00 00       	mov    $0xbf,%edx
f0102bba:	b8 bf 6b 10 f0       	mov    $0xf0106bbf,%eax
f0102bbf:	e8 83 e1 ff ff       	call   f0100d47 <_paddr>
f0102bc4:	8b 1d 08 6f 28 f0    	mov    0xf0286f08,%ebx
f0102bca:	8d 0c dd 00 00 00 00 	lea    0x0(,%ebx,8),%ecx
f0102bd1:	83 c4 08             	add    $0x8,%esp
f0102bd4:	6a 05                	push   $0x5
f0102bd6:	50                   	push   %eax
f0102bd7:	ba 00 00 00 ef       	mov    $0xef000000,%edx
f0102bdc:	a1 0c 6f 28 f0       	mov    0xf0286f0c,%eax
f0102be1:	e8 3e ed ff ff       	call   f0101924 <boot_map_region>
	// (ie. perm = PTE_U | PTE_P).
	// Permissions:
	//    - the new image at UENVS  -- kernel R, user R
	//    - envs itself -- kernel RW, user NONE
	// LAB 3: Your code here.
	boot_map_region(kern_pgdir, UENVS, NENV*sizeof(struct Env), PADDR(envs), PTE_U|PTE_P);
f0102be6:	8b 0d 44 52 28 f0    	mov    0xf0285244,%ecx
f0102bec:	ba c7 00 00 00       	mov    $0xc7,%edx
f0102bf1:	b8 bf 6b 10 f0       	mov    $0xf0106bbf,%eax
f0102bf6:	e8 4c e1 ff ff       	call   f0100d47 <_paddr>
f0102bfb:	83 c4 08             	add    $0x8,%esp
f0102bfe:	6a 05                	push   $0x5
f0102c00:	50                   	push   %eax
f0102c01:	b9 00 f0 01 00       	mov    $0x1f000,%ecx
f0102c06:	ba 00 00 c0 ee       	mov    $0xeec00000,%edx
f0102c0b:	a1 0c 6f 28 f0       	mov    0xf0286f0c,%eax
f0102c10:	e8 0f ed ff ff       	call   f0101924 <boot_map_region>
	//     * [KSTACKTOP-PTSIZE, KSTACKTOP-KSTKSIZE) -- not backed; so if
	//       the kernel overflows its stack, it will fault rather than
	//       overwrite memory.  Known as a "guard page".
	//     Permissions: kernel RW, user NONE
	// Your code goes here:
	boot_map_region(kern_pgdir,KSTACKTOP-KSTKSIZE,KSTKSIZE,PADDR(bootstack),PTE_P|PTE_W);
f0102c15:	b9 00 80 10 f0       	mov    $0xf0108000,%ecx
f0102c1a:	ba d4 00 00 00       	mov    $0xd4,%edx
f0102c1f:	b8 bf 6b 10 f0       	mov    $0xf0106bbf,%eax
f0102c24:	e8 1e e1 ff ff       	call   f0100d47 <_paddr>
f0102c29:	83 c4 08             	add    $0x8,%esp
f0102c2c:	6a 03                	push   $0x3
f0102c2e:	50                   	push   %eax
f0102c2f:	b9 00 80 00 00       	mov    $0x8000,%ecx
f0102c34:	ba 00 80 ff ef       	mov    $0xefff8000,%edx
f0102c39:	a1 0c 6f 28 f0       	mov    0xf0286f0c,%eax
f0102c3e:	e8 e1 ec ff ff       	call   f0101924 <boot_map_region>
	//      the PA range [0, 2^32 - KERNBASE)
	// We might not have 2^32 - KERNBASE bytes of physical memory, but
	// we just set up the mapping anyway.
	// Permissions: kernel RW, user NONE
	// Your code goes here:
	boot_map_region(kern_pgdir,KERNBASE,~0x0-KERNBASE+1,0,PTE_P|PTE_W);
f0102c43:	83 c4 08             	add    $0x8,%esp
f0102c46:	6a 03                	push   $0x3
f0102c48:	6a 00                	push   $0x0
f0102c4a:	b9 00 00 00 10       	mov    $0x10000000,%ecx
f0102c4f:	ba 00 00 00 f0       	mov    $0xf0000000,%edx
f0102c54:	a1 0c 6f 28 f0       	mov    0xf0286f0c,%eax
f0102c59:	e8 c6 ec ff ff       	call   f0101924 <boot_map_region>
	// Initialize the SMP-related parts of the memory map
	mem_init_mp();
f0102c5e:	e8 7a ed ff ff       	call   f01019dd <mem_init_mp>

	// Check that the initial page directory has been set up correctly.
	check_kern_pgdir();
f0102c63:	e8 7d e1 ff ff       	call   f0100de5 <check_kern_pgdir>
	// somewhere between KERNBASE and KERNBASE+4MB right now, which is
	// mapped the same way by both page tables.
	//
	// If the machine reboots at this point, you've probably set up your
	// kern_pgdir wrong.
	lcr3(PADDR(kern_pgdir));
f0102c68:	8b 0d 0c 6f 28 f0    	mov    0xf0286f0c,%ecx
f0102c6e:	ba ec 00 00 00       	mov    $0xec,%edx
f0102c73:	b8 bf 6b 10 f0       	mov    $0xf0106bbf,%eax
f0102c78:	e8 ca e0 ff ff       	call   f0100d47 <_paddr>
f0102c7d:	e8 63 df ff ff       	call   f0100be5 <lcr3>

	check_page_free_list(0);
f0102c82:	b8 00 00 00 00       	mov    $0x0,%eax
f0102c87:	e8 df e3 ff ff       	call   f010106b <check_page_free_list>

	// entry.S set the really important flags in cr0 (including enabling
	// paging).  Here we configure the rest of the flags that we care about.
	cr0 = rcr0();
f0102c8c:	e8 4c df ff ff       	call   f0100bdd <rcr0>
f0102c91:	83 e0 f3             	and    $0xfffffff3,%eax
	cr0 |= CR0_PE|CR0_PG|CR0_AM|CR0_WP|CR0_NE|CR0_MP;
	cr0 &= ~(CR0_TS|CR0_EM);
	lcr0(cr0);
f0102c94:	0d 23 00 05 80       	or     $0x80050023,%eax
f0102c99:	e8 37 df ff ff       	call   f0100bd5 <lcr0>

	// Some more checks, only possible after kern_pgdir is installed.
	check_page_installed_pgdir();
f0102c9e:	e8 b5 ee ff ff       	call   f0101b58 <check_page_installed_pgdir>
}
f0102ca3:	83 c4 10             	add    $0x10,%esp
f0102ca6:	8b 5d fc             	mov    -0x4(%ebp),%ebx
f0102ca9:	c9                   	leave  
f0102caa:	c3                   	ret    

f0102cab <user_mem_check>:
// Returns 0 if the user program can access this range of addresses,
// and -E_FAULT otherwise.
//
int
user_mem_check(struct Env *env, const void *va, size_t len, int perm)
{
f0102cab:	55                   	push   %ebp
f0102cac:	89 e5                	mov    %esp,%ebp
f0102cae:	57                   	push   %edi
f0102caf:	56                   	push   %esi
f0102cb0:	53                   	push   %ebx
f0102cb1:	83 ec 2c             	sub    $0x2c,%esp
f0102cb4:	8b 45 0c             	mov    0xc(%ebp),%eax
f0102cb7:	8b 75 14             	mov    0x14(%ebp),%esi
	// LAB 3: Your code here.
	//MARTIN_TP2_PARTE5
	uintptr_t xva = (uintptr_t) va;
	uintptr_t lim_va = xva+len;
f0102cba:	89 c1                	mov    %eax,%ecx
f0102cbc:	03 4d 10             	add    0x10(%ebp),%ecx
f0102cbf:	89 4d d4             	mov    %ecx,-0x2c(%ebp)
	if (xva >= ULIM){
f0102cc2:	3d ff ff 7f ef       	cmp    $0xef7fffff,%eax
f0102cc7:	76 0c                	jbe    f0102cd5 <user_mem_check+0x2a>
		user_mem_check_addr = xva;
f0102cc9:	a3 3c 52 28 f0       	mov    %eax,0xf028523c
		return -E_FAULT;
f0102cce:	b8 fa ff ff ff       	mov    $0xfffffffa,%eax
f0102cd3:	eb 6e                	jmp    f0102d43 <user_mem_check+0x98>
f0102cd5:	89 c3                	mov    %eax,%ebx
	}
	if (lim_va >= ULIM || lim_va < xva){ //Bolzano dice que esto anda
f0102cd7:	8b 4d d4             	mov    -0x2c(%ebp),%ecx
f0102cda:	81 f9 ff ff 7f ef    	cmp    $0xef7fffff,%ecx
f0102ce0:	77 07                	ja     f0102ce9 <user_mem_check+0x3e>
		return -E_FAULT;		
	}

	pte_t* pteaddr;
	while(xva<lim_va){ 
		if (!page_lookup(env->env_pgdir,(void*) xva,&pteaddr)){	//si no esta alojada o !PTE_P
f0102ce2:	8d 7d e4             	lea    -0x1c(%ebp),%edi
	uintptr_t lim_va = xva+len;
	if (xva >= ULIM){
		user_mem_check_addr = xva;
		return -E_FAULT;
	}
	if (lim_va >= ULIM || lim_va < xva){ //Bolzano dice que esto anda
f0102ce5:	39 c8                	cmp    %ecx,%eax
f0102ce7:	76 50                	jbe    f0102d39 <user_mem_check+0x8e>
		user_mem_check_addr = ULIM; 
f0102ce9:	c7 05 3c 52 28 f0 00 	movl   $0xef800000,0xf028523c
f0102cf0:	00 80 ef 
		return -E_FAULT;		
f0102cf3:	b8 fa ff ff ff       	mov    $0xfffffffa,%eax
f0102cf8:	eb 49                	jmp    f0102d43 <user_mem_check+0x98>
	}

	pte_t* pteaddr;
	while(xva<lim_va){ 
		if (!page_lookup(env->env_pgdir,(void*) xva,&pteaddr)){	//si no esta alojada o !PTE_P
f0102cfa:	83 ec 04             	sub    $0x4,%esp
f0102cfd:	57                   	push   %edi
f0102cfe:	53                   	push   %ebx
f0102cff:	8b 45 08             	mov    0x8(%ebp),%eax
f0102d02:	ff 70 60             	pushl  0x60(%eax)
f0102d05:	e8 28 ed ff ff       	call   f0101a32 <page_lookup>
f0102d0a:	83 c4 10             	add    $0x10,%esp
f0102d0d:	85 c0                	test   %eax,%eax
f0102d0f:	75 0d                	jne    f0102d1e <user_mem_check+0x73>
			user_mem_check_addr = xva;
f0102d11:	89 1d 3c 52 28 f0    	mov    %ebx,0xf028523c
			return -E_FAULT;
f0102d17:	b8 fa ff ff ff       	mov    $0xfffffffa,%eax
f0102d1c:	eb 25                	jmp    f0102d43 <user_mem_check+0x98>
		}
		if ((*pteaddr & perm) != perm){ //si no tiene permisos perm (PTE_P ya chequeado)
f0102d1e:	8b 45 e4             	mov    -0x1c(%ebp),%eax
f0102d21:	89 f2                	mov    %esi,%edx
f0102d23:	23 10                	and    (%eax),%edx
f0102d25:	39 d6                	cmp    %edx,%esi
f0102d27:	74 0d                	je     f0102d36 <user_mem_check+0x8b>
			user_mem_check_addr = xva;
f0102d29:	89 1d 3c 52 28 f0    	mov    %ebx,0xf028523c
			return -E_FAULT;
f0102d2f:	b8 fa ff ff ff       	mov    $0xfffffffa,%eax
f0102d34:	eb 0d                	jmp    f0102d43 <user_mem_check+0x98>
		}
		ROUNDUP(++xva,PGSIZE);
f0102d36:	83 c3 01             	add    $0x1,%ebx
		user_mem_check_addr = ULIM; 
		return -E_FAULT;		
	}

	pte_t* pteaddr;
	while(xva<lim_va){ 
f0102d39:	3b 5d d4             	cmp    -0x2c(%ebp),%ebx
f0102d3c:	72 bc                	jb     f0102cfa <user_mem_check+0x4f>
			user_mem_check_addr = xva;
			return -E_FAULT;
		}
		ROUNDUP(++xva,PGSIZE);
	}
	return 0;
f0102d3e:	b8 00 00 00 00       	mov    $0x0,%eax
}
f0102d43:	8d 65 f4             	lea    -0xc(%ebp),%esp
f0102d46:	5b                   	pop    %ebx
f0102d47:	5e                   	pop    %esi
f0102d48:	5f                   	pop    %edi
f0102d49:	5d                   	pop    %ebp
f0102d4a:	c3                   	ret    

f0102d4b <user_mem_assert>:
// If it cannot, 'env' is destroyed and, if env is the current
// environment, this function will not return.
//
void
user_mem_assert(struct Env *env, const void *va, size_t len, int perm)
{
f0102d4b:	55                   	push   %ebp
f0102d4c:	89 e5                	mov    %esp,%ebp
f0102d4e:	53                   	push   %ebx
f0102d4f:	83 ec 04             	sub    $0x4,%esp
f0102d52:	8b 5d 08             	mov    0x8(%ebp),%ebx
	if (user_mem_check(env, va, len, perm | PTE_U) < 0) {
f0102d55:	8b 45 14             	mov    0x14(%ebp),%eax
f0102d58:	83 c8 04             	or     $0x4,%eax
f0102d5b:	50                   	push   %eax
f0102d5c:	ff 75 10             	pushl  0x10(%ebp)
f0102d5f:	ff 75 0c             	pushl  0xc(%ebp)
f0102d62:	53                   	push   %ebx
f0102d63:	e8 43 ff ff ff       	call   f0102cab <user_mem_check>
f0102d68:	83 c4 10             	add    $0x10,%esp
f0102d6b:	85 c0                	test   %eax,%eax
f0102d6d:	79 21                	jns    f0102d90 <user_mem_assert+0x45>
		cprintf("[%08x] user_mem_check assertion failure for "
f0102d6f:	83 ec 04             	sub    $0x4,%esp
f0102d72:	ff 35 3c 52 28 f0    	pushl  0xf028523c
f0102d78:	ff 73 48             	pushl  0x48(%ebx)
f0102d7b:	68 7c 6b 10 f0       	push   $0xf0106b7c
f0102d80:	e8 ea 0a 00 00       	call   f010386f <cprintf>
			"va %08x\n", env->env_id, user_mem_check_addr);
		env_destroy(env);	// may not return
f0102d85:	89 1c 24             	mov    %ebx,(%esp)
f0102d88:	e8 08 07 00 00       	call   f0103495 <env_destroy>
f0102d8d:	83 c4 10             	add    $0x10,%esp
	}
}
f0102d90:	8b 5d fc             	mov    -0x4(%ebp),%ebx
f0102d93:	c9                   	leave  
f0102d94:	c3                   	ret    

f0102d95 <lgdt>:
	asm volatile("lidt (%0)" : : "r" (p));
}

static inline void
lgdt(void *p)
{
f0102d95:	55                   	push   %ebp
f0102d96:	89 e5                	mov    %esp,%ebp
	asm volatile("lgdt (%0)" : : "r" (p));
f0102d98:	0f 01 10             	lgdtl  (%eax)
}
f0102d9b:	5d                   	pop    %ebp
f0102d9c:	c3                   	ret    

f0102d9d <lldt>:

static inline void
lldt(uint16_t sel)
{
f0102d9d:	55                   	push   %ebp
f0102d9e:	89 e5                	mov    %esp,%ebp
	asm volatile("lldt %0" : : "r" (sel));
f0102da0:	0f 00 d0             	lldt   %ax
}
f0102da3:	5d                   	pop    %ebp
f0102da4:	c3                   	ret    

f0102da5 <lcr3>:
	return val;
}

static inline void
lcr3(uint32_t val)
{
f0102da5:	55                   	push   %ebp
f0102da6:	89 e5                	mov    %esp,%ebp
	asm volatile("movl %0,%%cr3" : : "r" (val));
f0102da8:	0f 22 d8             	mov    %eax,%cr3
}
f0102dab:	5d                   	pop    %ebp
f0102dac:	c3                   	ret    

f0102dad <rcr3>:

static inline uint32_t
rcr3(void)
{
f0102dad:	55                   	push   %ebp
f0102dae:	89 e5                	mov    %esp,%ebp
	uint32_t val;
	asm volatile("movl %%cr3,%0" : "=r" (val));
f0102db0:	0f 20 d8             	mov    %cr3,%eax
	return val;
}
f0102db3:	5d                   	pop    %ebp
f0102db4:	c3                   	ret    

f0102db5 <page2pa>:
int	user_mem_check(struct Env *env, const void *va, size_t len, int perm);
void	user_mem_assert(struct Env *env, const void *va, size_t len, int perm);

static inline physaddr_t
page2pa(struct PageInfo *pp)
{
f0102db5:	55                   	push   %ebp
f0102db6:	89 e5                	mov    %esp,%ebp
	return (pp - pages) << PGSHIFT;
f0102db8:	2b 05 10 6f 28 f0    	sub    0xf0286f10,%eax
f0102dbe:	c1 f8 03             	sar    $0x3,%eax
f0102dc1:	c1 e0 0c             	shl    $0xc,%eax
}
f0102dc4:	5d                   	pop    %ebp
f0102dc5:	c3                   	ret    

f0102dc6 <_kaddr>:
 * virtual address.  It panics if you pass an invalid physical address. */
#define KADDR(pa) _kaddr(__FILE__, __LINE__, pa)

static inline void*
_kaddr(const char *file, int line, physaddr_t pa)
{
f0102dc6:	55                   	push   %ebp
f0102dc7:	89 e5                	mov    %esp,%ebp
f0102dc9:	53                   	push   %ebx
f0102dca:	83 ec 04             	sub    $0x4,%esp
	if (PGNUM(pa) >= npages)
f0102dcd:	89 cb                	mov    %ecx,%ebx
f0102dcf:	c1 eb 0c             	shr    $0xc,%ebx
f0102dd2:	3b 1d 08 6f 28 f0    	cmp    0xf0286f08,%ebx
f0102dd8:	72 0d                	jb     f0102de7 <_kaddr+0x21>
		_panic(file, line, "KADDR called with invalid pa %08lx", pa);
f0102dda:	51                   	push   %ecx
f0102ddb:	68 ec 5c 10 f0       	push   $0xf0105cec
f0102de0:	52                   	push   %edx
f0102de1:	50                   	push   %eax
f0102de2:	e8 76 d2 ff ff       	call   f010005d <_panic>
	return (void *)(pa + KERNBASE);
f0102de7:	8d 81 00 00 00 f0    	lea    -0x10000000(%ecx),%eax
}
f0102ded:	8b 5d fc             	mov    -0x4(%ebp),%ebx
f0102df0:	c9                   	leave  
f0102df1:	c3                   	ret    

f0102df2 <page2kva>:
	return &pages[PGNUM(pa)];
}

static inline void*
page2kva(struct PageInfo *pp)
{
f0102df2:	55                   	push   %ebp
f0102df3:	89 e5                	mov    %esp,%ebp
f0102df5:	83 ec 08             	sub    $0x8,%esp
	return KADDR(page2pa(pp));
f0102df8:	e8 b8 ff ff ff       	call   f0102db5 <page2pa>
f0102dfd:	89 c1                	mov    %eax,%ecx
f0102dff:	ba 58 00 00 00       	mov    $0x58,%edx
f0102e04:	b8 b1 6b 10 f0       	mov    $0xf0106bb1,%eax
f0102e09:	e8 b8 ff ff ff       	call   f0102dc6 <_kaddr>
}
f0102e0e:	c9                   	leave  
f0102e0f:	c3                   	ret    

f0102e10 <_paddr>:
#define PADDR(kva) _paddr(__FILE__, __LINE__, kva)

static inline physaddr_t
_paddr(const char *file, int line, void *kva)
{
	if ((uint32_t)kva < KERNBASE)
f0102e10:	81 f9 ff ff ff ef    	cmp    $0xefffffff,%ecx
f0102e16:	77 13                	ja     f0102e2b <_paddr+0x1b>
 */
#define PADDR(kva) _paddr(__FILE__, __LINE__, kva)

static inline physaddr_t
_paddr(const char *file, int line, void *kva)
{
f0102e18:	55                   	push   %ebp
f0102e19:	89 e5                	mov    %esp,%ebp
f0102e1b:	83 ec 08             	sub    $0x8,%esp
	if ((uint32_t)kva < KERNBASE)
		_panic(file, line, "PADDR called with invalid kva %08lx", kva);
f0102e1e:	51                   	push   %ecx
f0102e1f:	68 10 5d 10 f0       	push   $0xf0105d10
f0102e24:	52                   	push   %edx
f0102e25:	50                   	push   %eax
f0102e26:	e8 32 d2 ff ff       	call   f010005d <_panic>
	return (physaddr_t)kva - KERNBASE;
f0102e2b:	8d 81 00 00 00 10    	lea    0x10000000(%ecx),%eax
}
f0102e31:	c3                   	ret    

f0102e32 <env_setup_vm>:
// Returns 0 on success, < 0 on error.  Errors include:
//	-E_NO_MEM if page directory or table could not be allocated.
//
static int
env_setup_vm(struct Env *e)
{
f0102e32:	55                   	push   %ebp
f0102e33:	89 e5                	mov    %esp,%ebp
f0102e35:	56                   	push   %esi
f0102e36:	53                   	push   %ebx
f0102e37:	89 c6                	mov    %eax,%esi
	int i;
	struct PageInfo *p = NULL;

	// Allocate a page for the page directory
	if (!(p = page_alloc(ALLOC_ZERO)))
f0102e39:	83 ec 0c             	sub    $0xc,%esp
f0102e3c:	6a 01                	push   $0x1
f0102e3e:	e8 b7 e5 ff ff       	call   f01013fa <page_alloc>
f0102e43:	83 c4 10             	add    $0x10,%esp
f0102e46:	85 c0                	test   %eax,%eax
f0102e48:	74 4a                	je     f0102e94 <env_setup_vm+0x62>
f0102e4a:	89 c3                	mov    %eax,%ebx
	//    - Note: In general, pp_ref is not maintained for
	//	physical pages mapped only above UTOP, but env_pgdir
	//	is an exception -- you need to increment env_pgdir's
	//	pp_ref for env_free to work correctly.
	//    - The functions in kern/pmap.h are handy.
	e->env_pgdir = page2kva(p);
f0102e4c:	e8 a1 ff ff ff       	call   f0102df2 <page2kva>
f0102e51:	89 46 60             	mov    %eax,0x60(%esi)
	memcpy(e->env_pgdir, kern_pgdir, PGSIZE);
f0102e54:	83 ec 04             	sub    $0x4,%esp
f0102e57:	68 00 10 00 00       	push   $0x1000
f0102e5c:	ff 35 0c 6f 28 f0    	pushl  0xf0286f0c
f0102e62:	50                   	push   %eax
f0102e63:	e8 c7 21 00 00       	call   f010502f <memcpy>
	p->pp_ref ++;
f0102e68:	66 83 43 04 01       	addw   $0x1,0x4(%ebx)
	
	// LAB 3: Your code here.

	// UVPT maps the env's own page table read-only.
	// Permissions: kernel R, user R
	e->env_pgdir[PDX(UVPT)] = PADDR(e->env_pgdir) | PTE_P | PTE_U;
f0102e6d:	8b 5e 60             	mov    0x60(%esi),%ebx
f0102e70:	89 d9                	mov    %ebx,%ecx
f0102e72:	ba c5 00 00 00       	mov    $0xc5,%edx
f0102e77:	b8 76 6f 10 f0       	mov    $0xf0106f76,%eax
f0102e7c:	e8 8f ff ff ff       	call   f0102e10 <_paddr>
f0102e81:	83 c8 05             	or     $0x5,%eax
f0102e84:	89 83 f4 0e 00 00    	mov    %eax,0xef4(%ebx)

	return 0;
f0102e8a:	83 c4 10             	add    $0x10,%esp
f0102e8d:	b8 00 00 00 00       	mov    $0x0,%eax
f0102e92:	eb 05                	jmp    f0102e99 <env_setup_vm+0x67>
	int i;
	struct PageInfo *p = NULL;

	// Allocate a page for the page directory
	if (!(p = page_alloc(ALLOC_ZERO)))
		return -E_NO_MEM;
f0102e94:	b8 fc ff ff ff       	mov    $0xfffffffc,%eax
	// UVPT maps the env's own page table read-only.
	// Permissions: kernel R, user R
	e->env_pgdir[PDX(UVPT)] = PADDR(e->env_pgdir) | PTE_P | PTE_U;

	return 0;
}
f0102e99:	8d 65 f8             	lea    -0x8(%ebp),%esp
f0102e9c:	5b                   	pop    %ebx
f0102e9d:	5e                   	pop    %esi
f0102e9e:	5d                   	pop    %ebp
f0102e9f:	c3                   	ret    

f0102ea0 <pa2page>:
}

static inline struct PageInfo*
pa2page(physaddr_t pa)
{
	if (PGNUM(pa) >= npages)
f0102ea0:	c1 e8 0c             	shr    $0xc,%eax
f0102ea3:	3b 05 08 6f 28 f0    	cmp    0xf0286f08,%eax
f0102ea9:	72 17                	jb     f0102ec2 <pa2page+0x22>
	return (pp - pages) << PGSHIFT;
}

static inline struct PageInfo*
pa2page(physaddr_t pa)
{
f0102eab:	55                   	push   %ebp
f0102eac:	89 e5                	mov    %esp,%ebp
f0102eae:	83 ec 0c             	sub    $0xc,%esp
	if (PGNUM(pa) >= npages)
		panic("pa2page called with invalid pa");
f0102eb1:	68 a4 64 10 f0       	push   $0xf01064a4
f0102eb6:	6a 51                	push   $0x51
f0102eb8:	68 b1 6b 10 f0       	push   $0xf0106bb1
f0102ebd:	e8 9b d1 ff ff       	call   f010005d <_panic>
	return &pages[PGNUM(pa)];
f0102ec2:	8b 15 10 6f 28 f0    	mov    0xf0286f10,%edx
f0102ec8:	8d 04 c2             	lea    (%edx,%eax,8),%eax
}
f0102ecb:	c3                   	ret    

f0102ecc <region_alloc>:
	// Hint: It is easier to use region_alloc if the caller can pass
	//   'va' and 'len' values that are not page-aligned.
	//   You should round va down, and round (va + len) up.
	//   (Watch out for corner-cases!)

	if (!len) return;
f0102ecc:	85 c9                	test   %ecx,%ecx
f0102ece:	0f 84 b3 00 00 00    	je     f0102f87 <region_alloc+0xbb>
// Pages should be writable by user and kernel.
// Panic if any allocation attempt fails.
//
static void
region_alloc(struct Env *e, void *va, size_t len)
{
f0102ed4:	55                   	push   %ebp
f0102ed5:	89 e5                	mov    %esp,%ebp
f0102ed7:	57                   	push   %edi
f0102ed8:	56                   	push   %esi
f0102ed9:	53                   	push   %ebx
f0102eda:	83 ec 0c             	sub    $0xc,%esp
f0102edd:	89 d3                	mov    %edx,%ebx
f0102edf:	89 c7                	mov    %eax,%edi
	//   'va' and 'len' values that are not page-aligned.
	//   You should round va down, and round (va + len) up.
	//   (Watch out for corner-cases!)

	if (!len) return;
	void* va_finish = ROUNDUP(va+len,PGSIZE);
f0102ee1:	8d b4 0a ff 0f 00 00 	lea    0xfff(%edx,%ecx,1),%esi
f0102ee8:	81 e6 00 f0 ff ff    	and    $0xfffff000,%esi
	va = ROUNDDOWN(va,PGSIZE);
f0102eee:	81 e3 00 f0 ff ff    	and    $0xfffff000,%ebx
f0102ef4:	eb 58                	jmp    f0102f4e <region_alloc+0x82>
		len = ~0x0-(uint32_t)va+1;//si hizo overflow
	}
	struct PageInfo* page;
	while (va<va_finish)
	{
		if(!(page = page_alloc(0)))
f0102ef6:	83 ec 0c             	sub    $0xc,%esp
f0102ef9:	6a 00                	push   $0x0
f0102efb:	e8 fa e4 ff ff       	call   f01013fa <page_alloc>
f0102f00:	83 c4 10             	add    $0x10,%esp
f0102f03:	85 c0                	test   %eax,%eax
f0102f05:	75 17                	jne    f0102f1e <region_alloc+0x52>
			panic("Page Alloc Fail:region_alloc");
f0102f07:	83 ec 04             	sub    $0x4,%esp
f0102f0a:	68 81 6f 10 f0       	push   $0xf0106f81
f0102f0f:	68 31 01 00 00       	push   $0x131
f0102f14:	68 76 6f 10 f0       	push   $0xf0106f76
f0102f19:	e8 3f d1 ff ff       	call   f010005d <_panic>
		if(page_insert(e->env_pgdir,page,va,PTE_U | PTE_W ))
f0102f1e:	6a 06                	push   $0x6
f0102f20:	53                   	push   %ebx
f0102f21:	50                   	push   %eax
f0102f22:	ff 77 60             	pushl  0x60(%edi)
f0102f25:	e8 cd eb ff ff       	call   f0101af7 <page_insert>
f0102f2a:	83 c4 10             	add    $0x10,%esp
f0102f2d:	85 c0                	test   %eax,%eax
f0102f2f:	74 17                	je     f0102f48 <region_alloc+0x7c>
			panic("Page Insert Fail: region_alloc");
f0102f31:	83 ec 04             	sub    $0x4,%esp
f0102f34:	68 34 6f 10 f0       	push   $0xf0106f34
f0102f39:	68 33 01 00 00       	push   $0x133
f0102f3e:	68 76 6f 10 f0       	push   $0xf0106f76
f0102f43:	e8 15 d1 ff ff       	call   f010005d <_panic>
		
		va+=PGSIZE;
f0102f48:	81 c3 00 10 00 00    	add    $0x1000,%ebx
	}
	else {
		len = ~0x0-(uint32_t)va+1;//si hizo overflow
	}
	struct PageInfo* page;
	while (va<va_finish)
f0102f4e:	39 f3                	cmp    %esi,%ebx
f0102f50:	72 a4                	jb     f0102ef6 <region_alloc+0x2a>
			panic("Page Insert Fail: region_alloc");
		
		va+=PGSIZE;
		//len-=PGSIZE;
	}
	assert(va==va_finish);
f0102f52:	39 f3                	cmp    %esi,%ebx
f0102f54:	74 19                	je     f0102f6f <region_alloc+0xa3>
f0102f56:	68 9e 6f 10 f0       	push   $0xf0106f9e
f0102f5b:	68 de 6b 10 f0       	push   $0xf0106bde
f0102f60:	68 38 01 00 00       	push   $0x138
f0102f65:	68 76 6f 10 f0       	push   $0xf0106f76
f0102f6a:	e8 ee d0 ff ff       	call   f010005d <_panic>
	cprintf("va es %p\n",va);
f0102f6f:	83 ec 08             	sub    $0x8,%esp
f0102f72:	53                   	push   %ebx
f0102f73:	68 ac 6f 10 f0       	push   $0xf0106fac
f0102f78:	e8 f2 08 00 00       	call   f010386f <cprintf>
f0102f7d:	83 c4 10             	add    $0x10,%esp
		if(page_insert(e->env_pgdir,p,in,PTE_U | PTE_W ))
			panic("Page Insert Fail: region_alloc");
		in+=PGSIZE;
	}*/

}
f0102f80:	8d 65 f4             	lea    -0xc(%ebp),%esp
f0102f83:	5b                   	pop    %ebx
f0102f84:	5e                   	pop    %esi
f0102f85:	5f                   	pop    %edi
f0102f86:	5d                   	pop    %ebp
f0102f87:	f3 c3                	repz ret 

f0102f89 <load_icode>:
// load_icode panics if it encounters problems.
//  - How might load_icode fail?  What might be wrong with the given input?
//
static void
load_icode(struct Env *e, uint8_t *binary)
{
f0102f89:	55                   	push   %ebp
f0102f8a:	89 e5                	mov    %esp,%ebp
f0102f8c:	57                   	push   %edi
f0102f8d:	56                   	push   %esi
f0102f8e:	53                   	push   %ebx
f0102f8f:	83 ec 1c             	sub    $0x1c,%esp
f0102f92:	89 45 e4             	mov    %eax,-0x1c(%ebp)
f0102f95:	89 d7                	mov    %edx,%edi
	//  to make sure that the environment starts executing there.
	//  What?  (See env_run() and env_pop_tf() below.)

	// LAB 3: Your code here.
	
	assert(rcr3()==PADDR(kern_pgdir));
f0102f97:	e8 11 fe ff ff       	call   f0102dad <rcr3>
f0102f9c:	89 c3                	mov    %eax,%ebx
f0102f9e:	8b 0d 0c 6f 28 f0    	mov    0xf0286f0c,%ecx
f0102fa4:	ba 82 01 00 00       	mov    $0x182,%edx
f0102fa9:	b8 76 6f 10 f0       	mov    $0xf0106f76,%eax
f0102fae:	e8 5d fe ff ff       	call   f0102e10 <_paddr>
f0102fb3:	39 c3                	cmp    %eax,%ebx
f0102fb5:	74 19                	je     f0102fd0 <load_icode+0x47>
f0102fb7:	68 b6 6f 10 f0       	push   $0xf0106fb6
f0102fbc:	68 de 6b 10 f0       	push   $0xf0106bde
f0102fc1:	68 82 01 00 00       	push   $0x182
f0102fc6:	68 76 6f 10 f0       	push   $0xf0106f76
f0102fcb:	e8 8d d0 ff ff       	call   f010005d <_panic>
	lcr3(PADDR(e->env_pgdir));//cambio a pgdir del env para que anden memcpy y memset
f0102fd0:	8b 75 e4             	mov    -0x1c(%ebp),%esi
f0102fd3:	8b 4e 60             	mov    0x60(%esi),%ecx
f0102fd6:	ba 83 01 00 00       	mov    $0x183,%edx
f0102fdb:	b8 76 6f 10 f0       	mov    $0xf0106f76,%eax
f0102fe0:	e8 2b fe ff ff       	call   f0102e10 <_paddr>
f0102fe5:	e8 bb fd ff ff       	call   f0102da5 <lcr3>
	assert(rcr3()==PADDR(e->env_pgdir));
f0102fea:	e8 be fd ff ff       	call   f0102dad <rcr3>
f0102fef:	89 c3                	mov    %eax,%ebx
f0102ff1:	8b 4e 60             	mov    0x60(%esi),%ecx
f0102ff4:	ba 84 01 00 00       	mov    $0x184,%edx
f0102ff9:	b8 76 6f 10 f0       	mov    $0xf0106f76,%eax
f0102ffe:	e8 0d fe ff ff       	call   f0102e10 <_paddr>
f0103003:	39 c3                	cmp    %eax,%ebx
f0103005:	74 19                	je     f0103020 <load_icode+0x97>
f0103007:	68 d0 6f 10 f0       	push   $0xf0106fd0
f010300c:	68 de 6b 10 f0       	push   $0xf0106bde
f0103011:	68 84 01 00 00       	push   $0x184
f0103016:	68 76 6f 10 f0       	push   $0xf0106f76
f010301b:	e8 3d d0 ff ff       	call   f010005d <_panic>

	struct Elf* elf = (struct Elf *) binary;
	if (elf->e_magic != ELF_MAGIC) panic("Invalid binary");
f0103020:	81 3f 7f 45 4c 46    	cmpl   $0x464c457f,(%edi)
f0103026:	74 17                	je     f010303f <load_icode+0xb6>
f0103028:	83 ec 04             	sub    $0x4,%esp
f010302b:	68 ec 6f 10 f0       	push   $0xf0106fec
f0103030:	68 87 01 00 00       	push   $0x187
f0103035:	68 76 6f 10 f0       	push   $0xf0106f76
f010303a:	e8 1e d0 ff ff       	call   f010005d <_panic>

	struct Proghdr* ph = (struct Proghdr*)(binary + elf->e_phoff);
f010303f:	89 fb                	mov    %edi,%ebx
f0103041:	03 5f 1c             	add    0x1c(%edi),%ebx
	void* va;
	for (int hdr_num = 0; hdr_num < elf->e_phnum; hdr_num++,ph++){
f0103044:	be 00 00 00 00       	mov    $0x0,%esi
f0103049:	eb 4c                	jmp    f0103097 <load_icode+0x10e>
		va=(void*) ph->p_va;
		if (ph->p_type != ELF_PROG_LOAD) continue;
f010304b:	83 3b 01             	cmpl   $0x1,(%ebx)
f010304e:	75 41                	jne    f0103091 <load_icode+0x108>
	if (elf->e_magic != ELF_MAGIC) panic("Invalid binary");

	struct Proghdr* ph = (struct Proghdr*)(binary + elf->e_phoff);
	void* va;
	for (int hdr_num = 0; hdr_num < elf->e_phnum; hdr_num++,ph++){
		va=(void*) ph->p_va;
f0103050:	8b 43 08             	mov    0x8(%ebx),%eax
		if (ph->p_type != ELF_PROG_LOAD) continue;
		region_alloc(e,va,ph->p_memsz);
f0103053:	8b 4b 14             	mov    0x14(%ebx),%ecx
f0103056:	89 45 e0             	mov    %eax,-0x20(%ebp)
f0103059:	89 c2                	mov    %eax,%edx
f010305b:	8b 45 e4             	mov    -0x1c(%ebp),%eax
f010305e:	e8 69 fe ff ff       	call   f0102ecc <region_alloc>
		memcpy(va,(void*)binary+ph->p_offset,ph->p_filesz);
f0103063:	83 ec 04             	sub    $0x4,%esp
f0103066:	ff 73 10             	pushl  0x10(%ebx)
f0103069:	89 f9                	mov    %edi,%ecx
f010306b:	03 4b 04             	add    0x4(%ebx),%ecx
f010306e:	51                   	push   %ecx
f010306f:	ff 75 e0             	pushl  -0x20(%ebp)
f0103072:	e8 b8 1f 00 00       	call   f010502f <memcpy>
		memset(va + ph->p_filesz,0,ph->p_memsz - ph->p_filesz);//VA+FILESZ->VA+MEMSZ
f0103077:	8b 43 10             	mov    0x10(%ebx),%eax
f010307a:	83 c4 0c             	add    $0xc,%esp
f010307d:	8b 53 14             	mov    0x14(%ebx),%edx
f0103080:	29 c2                	sub    %eax,%edx
f0103082:	52                   	push   %edx
f0103083:	6a 00                	push   $0x0
f0103085:	03 45 e0             	add    -0x20(%ebp),%eax
f0103088:	50                   	push   %eax
f0103089:	e8 eb 1e 00 00       	call   f0104f79 <memset>
f010308e:	83 c4 10             	add    $0x10,%esp
	struct Elf* elf = (struct Elf *) binary;
	if (elf->e_magic != ELF_MAGIC) panic("Invalid binary");

	struct Proghdr* ph = (struct Proghdr*)(binary + elf->e_phoff);
	void* va;
	for (int hdr_num = 0; hdr_num < elf->e_phnum; hdr_num++,ph++){
f0103091:	83 c6 01             	add    $0x1,%esi
f0103094:	83 c3 20             	add    $0x20,%ebx
f0103097:	0f b7 47 2c          	movzwl 0x2c(%edi),%eax
f010309b:	39 c6                	cmp    %eax,%esi
f010309d:	7c ac                	jl     f010304b <load_icode+0xc2>
		//ph++;
		//ph += elf->e_phentsize;
	}


	e->env_tf.tf_eip=elf->e_entry;
f010309f:	8b 47 18             	mov    0x18(%edi),%eax
f01030a2:	8b 7d e4             	mov    -0x1c(%ebp),%edi
f01030a5:	89 47 30             	mov    %eax,0x30(%edi)
	// Now map one page for the program's initial stack
	// at virtual address USTACKTOP - PGSIZE.

	// LAB 3: Your code here.

	region_alloc(e,(void*)(USTACKTOP - PGSIZE),PGSIZE);
f01030a8:	b9 00 10 00 00       	mov    $0x1000,%ecx
f01030ad:	ba 00 d0 bf ee       	mov    $0xeebfd000,%edx
f01030b2:	89 f8                	mov    %edi,%eax
f01030b4:	e8 13 fe ff ff       	call   f0102ecc <region_alloc>

	lcr3(PADDR(kern_pgdir));//vuelvo a poner el pgdir del kernel 
f01030b9:	8b 0d 0c 6f 28 f0    	mov    0xf0286f0c,%ecx
f01030bf:	ba 9f 01 00 00       	mov    $0x19f,%edx
f01030c4:	b8 76 6f 10 f0       	mov    $0xf0106f76,%eax
f01030c9:	e8 42 fd ff ff       	call   f0102e10 <_paddr>
f01030ce:	e8 d2 fc ff ff       	call   f0102da5 <lcr3>
}
f01030d3:	8d 65 f4             	lea    -0xc(%ebp),%esp
f01030d6:	5b                   	pop    %ebx
f01030d7:	5e                   	pop    %esi
f01030d8:	5f                   	pop    %edi
f01030d9:	5d                   	pop    %ebp
f01030da:	c3                   	ret    

f01030db <envid2env>:
//   On success, sets *env_store to the environment.
//   On error, sets *env_store to NULL.
//
int
envid2env(envid_t envid, struct Env **env_store, bool checkperm)
{
f01030db:	55                   	push   %ebp
f01030dc:	89 e5                	mov    %esp,%ebp
f01030de:	56                   	push   %esi
f01030df:	53                   	push   %ebx
f01030e0:	8b 45 08             	mov    0x8(%ebp),%eax
f01030e3:	8b 55 10             	mov    0x10(%ebp),%edx
	struct Env *e;

	// If envid is zero, return the current environment.
	if (envid == 0) {
f01030e6:	85 c0                	test   %eax,%eax
f01030e8:	75 1a                	jne    f0103104 <envid2env+0x29>
		*env_store = curenv;
f01030ea:	e8 1f 25 00 00       	call   f010560e <cpunum>
f01030ef:	6b c0 74             	imul   $0x74,%eax,%eax
f01030f2:	8b 80 28 70 28 f0    	mov    -0xfd78fd8(%eax),%eax
f01030f8:	8b 4d 0c             	mov    0xc(%ebp),%ecx
f01030fb:	89 01                	mov    %eax,(%ecx)
		return 0;
f01030fd:	b8 00 00 00 00       	mov    $0x0,%eax
f0103102:	eb 70                	jmp    f0103174 <envid2env+0x99>
	// Look up the Env structure via the index part of the envid,
	// then check the env_id field in that struct Env
	// to ensure that the envid is not stale
	// (i.e., does not refer to a _previous_ environment
	// that used the same slot in the envs[] array).
	e = &envs[ENVX(envid)];
f0103104:	89 c3                	mov    %eax,%ebx
f0103106:	81 e3 ff 03 00 00    	and    $0x3ff,%ebx
f010310c:	6b db 7c             	imul   $0x7c,%ebx,%ebx
f010310f:	03 1d 44 52 28 f0    	add    0xf0285244,%ebx
	if (e->env_status == ENV_FREE || e->env_id != envid) {
f0103115:	83 7b 54 00          	cmpl   $0x0,0x54(%ebx)
f0103119:	74 05                	je     f0103120 <envid2env+0x45>
f010311b:	3b 43 48             	cmp    0x48(%ebx),%eax
f010311e:	74 10                	je     f0103130 <envid2env+0x55>
		*env_store = 0;
f0103120:	8b 45 0c             	mov    0xc(%ebp),%eax
f0103123:	c7 00 00 00 00 00    	movl   $0x0,(%eax)
		return -E_BAD_ENV;
f0103129:	b8 fe ff ff ff       	mov    $0xfffffffe,%eax
f010312e:	eb 44                	jmp    f0103174 <envid2env+0x99>
	// Check that the calling environment has legitimate permission
	// to manipulate the specified environment.
	// If checkperm is set, the specified environment
	// must be either the current environment
	// or an immediate child of the current environment.
	if (checkperm && e != curenv && e->env_parent_id != curenv->env_id) {
f0103130:	84 d2                	test   %dl,%dl
f0103132:	74 36                	je     f010316a <envid2env+0x8f>
f0103134:	e8 d5 24 00 00       	call   f010560e <cpunum>
f0103139:	6b c0 74             	imul   $0x74,%eax,%eax
f010313c:	3b 98 28 70 28 f0    	cmp    -0xfd78fd8(%eax),%ebx
f0103142:	74 26                	je     f010316a <envid2env+0x8f>
f0103144:	8b 73 4c             	mov    0x4c(%ebx),%esi
f0103147:	e8 c2 24 00 00       	call   f010560e <cpunum>
f010314c:	6b c0 74             	imul   $0x74,%eax,%eax
f010314f:	8b 80 28 70 28 f0    	mov    -0xfd78fd8(%eax),%eax
f0103155:	3b 70 48             	cmp    0x48(%eax),%esi
f0103158:	74 10                	je     f010316a <envid2env+0x8f>
		*env_store = 0;
f010315a:	8b 45 0c             	mov    0xc(%ebp),%eax
f010315d:	c7 00 00 00 00 00    	movl   $0x0,(%eax)
		return -E_BAD_ENV;
f0103163:	b8 fe ff ff ff       	mov    $0xfffffffe,%eax
f0103168:	eb 0a                	jmp    f0103174 <envid2env+0x99>
	}

	*env_store = e;
f010316a:	8b 45 0c             	mov    0xc(%ebp),%eax
f010316d:	89 18                	mov    %ebx,(%eax)
	return 0;
f010316f:	b8 00 00 00 00       	mov    $0x0,%eax
}
f0103174:	5b                   	pop    %ebx
f0103175:	5e                   	pop    %esi
f0103176:	5d                   	pop    %ebp
f0103177:	c3                   	ret    

f0103178 <env_init_percpu>:
}

// Load GDT and segment descriptors.
void
env_init_percpu(void)
{
f0103178:	55                   	push   %ebp
f0103179:	89 e5                	mov    %esp,%ebp
	lgdt(&gdt_pd);
f010317b:	b8 20 13 11 f0       	mov    $0xf0111320,%eax
f0103180:	e8 10 fc ff ff       	call   f0102d95 <lgdt>
	// The kernel never uses GS or FS, so we leave those set to
	// the user data segment.
	asm volatile("movw %%ax,%%gs" : : "a"(GD_UD | 3));
f0103185:	b8 23 00 00 00       	mov    $0x23,%eax
f010318a:	8e e8                	mov    %eax,%gs
	asm volatile("movw %%ax,%%fs" : : "a"(GD_UD | 3));
f010318c:	8e e0                	mov    %eax,%fs
	// The kernel does use ES, DS, and SS.  We'll change between
	// the kernel and user data segments as needed.
	asm volatile("movw %%ax,%%es" : : "a"(GD_KD));
f010318e:	b8 10 00 00 00       	mov    $0x10,%eax
f0103193:	8e c0                	mov    %eax,%es
	asm volatile("movw %%ax,%%ds" : : "a"(GD_KD));
f0103195:	8e d8                	mov    %eax,%ds
	asm volatile("movw %%ax,%%ss" : : "a"(GD_KD));
f0103197:	8e d0                	mov    %eax,%ss
	// Load the kernel text segment into CS.
	asm volatile("ljmp %0,$1f\n 1:\n" : : "i"(GD_KT));
f0103199:	ea a0 31 10 f0 08 00 	ljmp   $0x8,$0xf01031a0
	// For good measure, clear the local descriptor table (LDT),
	// since we don't use it.
	lldt(0);
f01031a0:	b8 00 00 00 00       	mov    $0x0,%eax
f01031a5:	e8 f3 fb ff ff       	call   f0102d9d <lldt>
}
f01031aa:	5d                   	pop    %ebp
f01031ab:	c3                   	ret    

f01031ac <env_init>:
{
	// Set up envs array
	// LAB 3: Your code here. (OK)
	
	for (size_t i=0; i< NENV-1; i++){
		envs[i].env_status = ENV_FREE; 
f01031ac:	8b 15 44 52 28 f0    	mov    0xf0285244,%edx
f01031b2:	8d 42 7c             	lea    0x7c(%edx),%eax
f01031b5:	81 c2 00 f0 01 00    	add    $0x1f000,%edx
f01031bb:	c7 40 d8 00 00 00 00 	movl   $0x0,-0x28(%eax)
		envs[i].env_id = 0;
f01031c2:	c7 40 cc 00 00 00 00 	movl   $0x0,-0x34(%eax)
		envs[i].env_link = &envs[i+1];
f01031c9:	89 40 c8             	mov    %eax,-0x38(%eax)
f01031cc:	83 c0 7c             	add    $0x7c,%eax
env_init(void)
{
	// Set up envs array
	// LAB 3: Your code here. (OK)
	
	for (size_t i=0; i< NENV-1; i++){
f01031cf:	39 d0                	cmp    %edx,%eax
f01031d1:	75 e8                	jne    f01031bb <env_init+0xf>
// they are in the envs array (i.e., so that the first call to
// env_alloc() returns envs[0]).
//
void
env_init(void)
{
f01031d3:	55                   	push   %ebp
f01031d4:	89 e5                	mov    %esp,%ebp
		envs[i].env_status = ENV_FREE; 
		envs[i].env_id = 0;
		envs[i].env_link = &envs[i+1];
		
	}
	envs[NENV-1].env_status = ENV_FREE;
f01031d6:	a1 44 52 28 f0       	mov    0xf0285244,%eax
f01031db:	c7 80 d8 ef 01 00 00 	movl   $0x0,0x1efd8(%eax)
f01031e2:	00 00 00 
	envs[NENV-1].env_id = 0;
f01031e5:	c7 80 cc ef 01 00 00 	movl   $0x0,0x1efcc(%eax)
f01031ec:	00 00 00 
	env_free_list = &envs[0];
f01031ef:	a3 48 52 28 f0       	mov    %eax,0xf0285248
	// Per-CPU part of the initialization
	env_init_percpu();
f01031f4:	e8 7f ff ff ff       	call   f0103178 <env_init_percpu>
}
f01031f9:	5d                   	pop    %ebp
f01031fa:	c3                   	ret    

f01031fb <env_alloc>:
//	-E_NO_FREE_ENV if all NENVS environments are allocated
//	-E_NO_MEM on memory exhaustion
//
int
env_alloc(struct Env **newenv_store, envid_t parent_id)
{
f01031fb:	55                   	push   %ebp
f01031fc:	89 e5                	mov    %esp,%ebp
f01031fe:	53                   	push   %ebx
f01031ff:	83 ec 04             	sub    $0x4,%esp
	int32_t generation;
	int r;
	struct Env *e;

	if (!(e = env_free_list))
f0103202:	8b 1d 48 52 28 f0    	mov    0xf0285248,%ebx
f0103208:	85 db                	test   %ebx,%ebx
f010320a:	0f 84 df 00 00 00    	je     f01032ef <env_alloc+0xf4>
		return -E_NO_FREE_ENV;

	// Allocate and set up the page directory for this environment.
	if ((r = env_setup_vm(e)) < 0)
f0103210:	89 d8                	mov    %ebx,%eax
f0103212:	e8 1b fc ff ff       	call   f0102e32 <env_setup_vm>
f0103217:	85 c0                	test   %eax,%eax
f0103219:	0f 88 d5 00 00 00    	js     f01032f4 <env_alloc+0xf9>
		return r;

	// Generate an env_id for this environment.
	generation = (e->env_id + (1 << ENVGENSHIFT)) & ~(NENV - 1);
f010321f:	8b 43 48             	mov    0x48(%ebx),%eax
f0103222:	05 00 10 00 00       	add    $0x1000,%eax
	if (generation <= 0)  // Don't create a negative env_id.
f0103227:	25 00 fc ff ff       	and    $0xfffffc00,%eax
		generation = 1 << ENVGENSHIFT;
f010322c:	ba 00 10 00 00       	mov    $0x1000,%edx
f0103231:	0f 4e c2             	cmovle %edx,%eax
	e->env_id = generation | (e - envs);
f0103234:	89 da                	mov    %ebx,%edx
f0103236:	2b 15 44 52 28 f0    	sub    0xf0285244,%edx
f010323c:	c1 fa 02             	sar    $0x2,%edx
f010323f:	69 d2 df 7b ef bd    	imul   $0xbdef7bdf,%edx,%edx
f0103245:	09 d0                	or     %edx,%eax
f0103247:	89 43 48             	mov    %eax,0x48(%ebx)

	// Set the basic status variables.
	e->env_parent_id = parent_id;
f010324a:	8b 45 0c             	mov    0xc(%ebp),%eax
f010324d:	89 43 4c             	mov    %eax,0x4c(%ebx)
	e->env_type = ENV_TYPE_USER;
f0103250:	c7 43 50 00 00 00 00 	movl   $0x0,0x50(%ebx)
	e->env_status = ENV_RUNNABLE;
f0103257:	c7 43 54 02 00 00 00 	movl   $0x2,0x54(%ebx)
	e->env_runs = 0;
f010325e:	c7 43 58 00 00 00 00 	movl   $0x0,0x58(%ebx)

	// Clear out all the saved register state,
	// to prevent the register values
	// of a prior environment inhabiting this Env structure
	// from "leaking" into our new environment.
	memset(&e->env_tf, 0, sizeof(e->env_tf));
f0103265:	83 ec 04             	sub    $0x4,%esp
f0103268:	6a 44                	push   $0x44
f010326a:	6a 00                	push   $0x0
f010326c:	53                   	push   %ebx
f010326d:	e8 07 1d 00 00       	call   f0104f79 <memset>
	// The low 2 bits of each segment register contains the
	// Requestor Privilege Level (RPL); 3 means user mode.  When
	// we switch privilege levels, the hardware does various
	// checks involving the RPL and the Descriptor Privilege Level
	// (DPL) stored in the descriptors themselves.
	e->env_tf.tf_ds = GD_UD | 3;
f0103272:	66 c7 43 24 23 00    	movw   $0x23,0x24(%ebx)
	e->env_tf.tf_es = GD_UD | 3;
f0103278:	66 c7 43 20 23 00    	movw   $0x23,0x20(%ebx)
	e->env_tf.tf_ss = GD_UD | 3;
f010327e:	66 c7 43 40 23 00    	movw   $0x23,0x40(%ebx)
	e->env_tf.tf_esp = USTACKTOP;
f0103284:	c7 43 3c 00 e0 bf ee 	movl   $0xeebfe000,0x3c(%ebx)
	e->env_tf.tf_cs = GD_UT | 3;
f010328b:	66 c7 43 34 1b 00    	movw   $0x1b,0x34(%ebx)

	// Enable interrupts while in user mode.
	// LAB 4: Your code here.

	// Clear the page fault handler until user installs one.
	e->env_pgfault_upcall = 0;
f0103291:	c7 43 64 00 00 00 00 	movl   $0x0,0x64(%ebx)

	// Also clear the IPC receiving flag.
	e->env_ipc_recving = 0;
f0103298:	c6 43 68 00          	movb   $0x0,0x68(%ebx)

	// commit the allocation
	env_free_list = e->env_link;
f010329c:	8b 43 44             	mov    0x44(%ebx),%eax
f010329f:	a3 48 52 28 f0       	mov    %eax,0xf0285248
	*newenv_store = e; 
f01032a4:	8b 45 08             	mov    0x8(%ebp),%eax
f01032a7:	89 18                	mov    %ebx,(%eax)

	cprintf("[%08x] new env %08x\n", curenv ? curenv->env_id : 0, e->env_id);
f01032a9:	8b 5b 48             	mov    0x48(%ebx),%ebx
f01032ac:	e8 5d 23 00 00       	call   f010560e <cpunum>
f01032b1:	6b c0 74             	imul   $0x74,%eax,%eax
f01032b4:	83 c4 10             	add    $0x10,%esp
f01032b7:	ba 00 00 00 00       	mov    $0x0,%edx
f01032bc:	83 b8 28 70 28 f0 00 	cmpl   $0x0,-0xfd78fd8(%eax)
f01032c3:	74 11                	je     f01032d6 <env_alloc+0xdb>
f01032c5:	e8 44 23 00 00       	call   f010560e <cpunum>
f01032ca:	6b c0 74             	imul   $0x74,%eax,%eax
f01032cd:	8b 80 28 70 28 f0    	mov    -0xfd78fd8(%eax),%eax
f01032d3:	8b 50 48             	mov    0x48(%eax),%edx
f01032d6:	83 ec 04             	sub    $0x4,%esp
f01032d9:	53                   	push   %ebx
f01032da:	52                   	push   %edx
f01032db:	68 fb 6f 10 f0       	push   $0xf0106ffb
f01032e0:	e8 8a 05 00 00       	call   f010386f <cprintf>
	return 0;
f01032e5:	83 c4 10             	add    $0x10,%esp
f01032e8:	b8 00 00 00 00       	mov    $0x0,%eax
f01032ed:	eb 05                	jmp    f01032f4 <env_alloc+0xf9>
	int32_t generation;
	int r;
	struct Env *e;

	if (!(e = env_free_list))
		return -E_NO_FREE_ENV;
f01032ef:	b8 fb ff ff ff       	mov    $0xfffffffb,%eax
	env_free_list = e->env_link;
	*newenv_store = e; 

	cprintf("[%08x] new env %08x\n", curenv ? curenv->env_id : 0, e->env_id);
	return 0;
}
f01032f4:	8b 5d fc             	mov    -0x4(%ebp),%ebx
f01032f7:	c9                   	leave  
f01032f8:	c3                   	ret    

f01032f9 <env_create>:
// before running the first user-mode environment.
// The new env's parent ID is set to 0.
//
void
env_create(uint8_t *binary, enum EnvType type)
{
f01032f9:	55                   	push   %ebp
f01032fa:	89 e5                	mov    %esp,%ebp
f01032fc:	83 ec 20             	sub    $0x20,%esp
	// LAB 3: Your code here.
	struct Env* e;
	int err = env_alloc(&e,0);//hace lugar para un Env cuya dir se guarda en e, parent_id es 0 por def.
f01032ff:	6a 00                	push   $0x0
f0103301:	8d 45 f4             	lea    -0xc(%ebp),%eax
f0103304:	50                   	push   %eax
f0103305:	e8 f1 fe ff ff       	call   f01031fb <env_alloc>
	if (err<0) panic("env_create: %e", err);
f010330a:	83 c4 10             	add    $0x10,%esp
f010330d:	85 c0                	test   %eax,%eax
f010330f:	79 15                	jns    f0103326 <env_create+0x2d>
f0103311:	50                   	push   %eax
f0103312:	68 10 70 10 f0       	push   $0xf0107010
f0103317:	68 af 01 00 00       	push   $0x1af
f010331c:	68 76 6f 10 f0       	push   $0xf0106f76
f0103321:	e8 37 cd ff ff       	call   f010005d <_panic>
	load_icode(e,binary);
f0103326:	8b 55 08             	mov    0x8(%ebp),%edx
f0103329:	8b 45 f4             	mov    -0xc(%ebp),%eax
f010332c:	e8 58 fc ff ff       	call   f0102f89 <load_icode>
	e->env_type = type;
f0103331:	8b 45 f4             	mov    -0xc(%ebp),%eax
f0103334:	8b 55 0c             	mov    0xc(%ebp),%edx
f0103337:	89 50 50             	mov    %edx,0x50(%eax)
}
f010333a:	c9                   	leave  
f010333b:	c3                   	ret    

f010333c <env_free>:
//
// Frees env e and all memory it uses.
//
void
env_free(struct Env *e)
{
f010333c:	55                   	push   %ebp
f010333d:	89 e5                	mov    %esp,%ebp
f010333f:	57                   	push   %edi
f0103340:	56                   	push   %esi
f0103341:	53                   	push   %ebx
f0103342:	83 ec 1c             	sub    $0x1c,%esp
f0103345:	8b 7d 08             	mov    0x8(%ebp),%edi
	physaddr_t pa;

	// If freeing the current environment, switch to kern_pgdir
	// before freeing the page directory, just in case the page
	// gets reused.
	if (e == curenv)
f0103348:	e8 c1 22 00 00       	call   f010560e <cpunum>
f010334d:	6b c0 74             	imul   $0x74,%eax,%eax
f0103350:	39 b8 28 70 28 f0    	cmp    %edi,-0xfd78fd8(%eax)
f0103356:	75 1a                	jne    f0103372 <env_free+0x36>
		lcr3(PADDR(kern_pgdir));
f0103358:	8b 0d 0c 6f 28 f0    	mov    0xf0286f0c,%ecx
f010335e:	ba c2 01 00 00       	mov    $0x1c2,%edx
f0103363:	b8 76 6f 10 f0       	mov    $0xf0106f76,%eax
f0103368:	e8 a3 fa ff ff       	call   f0102e10 <_paddr>
f010336d:	e8 33 fa ff ff       	call   f0102da5 <lcr3>

	// Note the environment's demise.
	cprintf("[%08x] free env %08x\n", curenv ? curenv->env_id : 0, e->env_id);
f0103372:	8b 5f 48             	mov    0x48(%edi),%ebx
f0103375:	e8 94 22 00 00       	call   f010560e <cpunum>
f010337a:	6b c0 74             	imul   $0x74,%eax,%eax
f010337d:	ba 00 00 00 00       	mov    $0x0,%edx
f0103382:	83 b8 28 70 28 f0 00 	cmpl   $0x0,-0xfd78fd8(%eax)
f0103389:	74 11                	je     f010339c <env_free+0x60>
f010338b:	e8 7e 22 00 00       	call   f010560e <cpunum>
f0103390:	6b c0 74             	imul   $0x74,%eax,%eax
f0103393:	8b 80 28 70 28 f0    	mov    -0xfd78fd8(%eax),%eax
f0103399:	8b 50 48             	mov    0x48(%eax),%edx
f010339c:	83 ec 04             	sub    $0x4,%esp
f010339f:	53                   	push   %ebx
f01033a0:	52                   	push   %edx
f01033a1:	68 1f 70 10 f0       	push   $0xf010701f
f01033a6:	e8 c4 04 00 00       	call   f010386f <cprintf>
f01033ab:	83 c4 10             	add    $0x10,%esp

	// Flush all mapped pages in the user portion of the address space
	static_assert(UTOP % PTSIZE == 0);
	for (pdeno = 0; pdeno < PDX(UTOP); pdeno++) {
f01033ae:	c7 45 e0 00 00 00 00 	movl   $0x0,-0x20(%ebp)
f01033b5:	8b 55 e0             	mov    -0x20(%ebp),%edx
f01033b8:	89 d0                	mov    %edx,%eax
f01033ba:	c1 e0 02             	shl    $0x2,%eax
f01033bd:	89 45 dc             	mov    %eax,-0x24(%ebp)
		// only look at mapped page tables
		if (!(e->env_pgdir[pdeno] & PTE_P))
f01033c0:	8b 47 60             	mov    0x60(%edi),%eax
f01033c3:	8b 04 90             	mov    (%eax,%edx,4),%eax
f01033c6:	a8 01                	test   $0x1,%al
f01033c8:	74 72                	je     f010343c <env_free+0x100>
			continue;

		// find the pa and va of the page table
		pa = PTE_ADDR(e->env_pgdir[pdeno]);
f01033ca:	25 00 f0 ff ff       	and    $0xfffff000,%eax
f01033cf:	89 45 d8             	mov    %eax,-0x28(%ebp)
		pt = (pte_t *) KADDR(pa);
f01033d2:	89 c1                	mov    %eax,%ecx
f01033d4:	ba d0 01 00 00       	mov    $0x1d0,%edx
f01033d9:	b8 76 6f 10 f0       	mov    $0xf0106f76,%eax
f01033de:	e8 e3 f9 ff ff       	call   f0102dc6 <_kaddr>
f01033e3:	89 c6                	mov    %eax,%esi

		// unmap all PTEs in this page table
		for (pteno = 0; pteno <= PTX(~0); pteno++) {
			if (pt[pteno] & PTE_P)
				page_remove(e->env_pgdir, PGADDR(pdeno, pteno, 0));
f01033e5:	8b 45 e0             	mov    -0x20(%ebp),%eax
f01033e8:	c1 e0 16             	shl    $0x16,%eax
f01033eb:	89 45 e4             	mov    %eax,-0x1c(%ebp)
		// find the pa and va of the page table
		pa = PTE_ADDR(e->env_pgdir[pdeno]);
		pt = (pte_t *) KADDR(pa);

		// unmap all PTEs in this page table
		for (pteno = 0; pteno <= PTX(~0); pteno++) {
f01033ee:	bb 00 00 00 00       	mov    $0x0,%ebx
			if (pt[pteno] & PTE_P)
f01033f3:	f6 04 9e 01          	testb  $0x1,(%esi,%ebx,4)
f01033f7:	74 17                	je     f0103410 <env_free+0xd4>
				page_remove(e->env_pgdir, PGADDR(pdeno, pteno, 0));
f01033f9:	83 ec 08             	sub    $0x8,%esp
f01033fc:	89 d8                	mov    %ebx,%eax
f01033fe:	c1 e0 0c             	shl    $0xc,%eax
f0103401:	0b 45 e4             	or     -0x1c(%ebp),%eax
f0103404:	50                   	push   %eax
f0103405:	ff 77 60             	pushl  0x60(%edi)
f0103408:	e8 a4 e6 ff ff       	call   f0101ab1 <page_remove>
f010340d:	83 c4 10             	add    $0x10,%esp
		// find the pa and va of the page table
		pa = PTE_ADDR(e->env_pgdir[pdeno]);
		pt = (pte_t *) KADDR(pa);

		// unmap all PTEs in this page table
		for (pteno = 0; pteno <= PTX(~0); pteno++) {
f0103410:	83 c3 01             	add    $0x1,%ebx
f0103413:	81 fb 00 04 00 00    	cmp    $0x400,%ebx
f0103419:	75 d8                	jne    f01033f3 <env_free+0xb7>
			if (pt[pteno] & PTE_P)
				page_remove(e->env_pgdir, PGADDR(pdeno, pteno, 0));
		}

		// free the page table itself
		e->env_pgdir[pdeno] = 0;
f010341b:	8b 47 60             	mov    0x60(%edi),%eax
f010341e:	8b 55 dc             	mov    -0x24(%ebp),%edx
f0103421:	c7 04 10 00 00 00 00 	movl   $0x0,(%eax,%edx,1)
		page_decref(pa2page(pa));
f0103428:	8b 45 d8             	mov    -0x28(%ebp),%eax
f010342b:	e8 70 fa ff ff       	call   f0102ea0 <pa2page>
f0103430:	83 ec 0c             	sub    $0xc,%esp
f0103433:	50                   	push   %eax
f0103434:	e8 25 e4 ff ff       	call   f010185e <page_decref>
f0103439:	83 c4 10             	add    $0x10,%esp
	// Note the environment's demise.
	cprintf("[%08x] free env %08x\n", curenv ? curenv->env_id : 0, e->env_id);

	// Flush all mapped pages in the user portion of the address space
	static_assert(UTOP % PTSIZE == 0);
	for (pdeno = 0; pdeno < PDX(UTOP); pdeno++) {
f010343c:	83 45 e0 01          	addl   $0x1,-0x20(%ebp)
f0103440:	8b 45 e0             	mov    -0x20(%ebp),%eax
f0103443:	3d bb 03 00 00       	cmp    $0x3bb,%eax
f0103448:	0f 85 67 ff ff ff    	jne    f01033b5 <env_free+0x79>
		e->env_pgdir[pdeno] = 0;
		page_decref(pa2page(pa));
	}

	// free the page directory
	pa = PADDR(e->env_pgdir);
f010344e:	8b 4f 60             	mov    0x60(%edi),%ecx
f0103451:	ba de 01 00 00       	mov    $0x1de,%edx
f0103456:	b8 76 6f 10 f0       	mov    $0xf0106f76,%eax
f010345b:	e8 b0 f9 ff ff       	call   f0102e10 <_paddr>
	e->env_pgdir = 0;
f0103460:	c7 47 60 00 00 00 00 	movl   $0x0,0x60(%edi)
	page_decref(pa2page(pa));
f0103467:	e8 34 fa ff ff       	call   f0102ea0 <pa2page>
f010346c:	83 ec 0c             	sub    $0xc,%esp
f010346f:	50                   	push   %eax
f0103470:	e8 e9 e3 ff ff       	call   f010185e <page_decref>

	// return the environment to the free list
	e->env_status = ENV_FREE;
f0103475:	c7 47 54 00 00 00 00 	movl   $0x0,0x54(%edi)
	e->env_link = env_free_list;
f010347c:	a1 48 52 28 f0       	mov    0xf0285248,%eax
f0103481:	89 47 44             	mov    %eax,0x44(%edi)
	env_free_list = e;
f0103484:	89 3d 48 52 28 f0    	mov    %edi,0xf0285248
}
f010348a:	83 c4 10             	add    $0x10,%esp
f010348d:	8d 65 f4             	lea    -0xc(%ebp),%esp
f0103490:	5b                   	pop    %ebx
f0103491:	5e                   	pop    %esi
f0103492:	5f                   	pop    %edi
f0103493:	5d                   	pop    %ebp
f0103494:	c3                   	ret    

f0103495 <env_destroy>:
// If e was the current env, then runs a new environment (and does not return
// to the caller).
//
void
env_destroy(struct Env *e)
{
f0103495:	55                   	push   %ebp
f0103496:	89 e5                	mov    %esp,%ebp
f0103498:	53                   	push   %ebx
f0103499:	83 ec 04             	sub    $0x4,%esp
f010349c:	8b 5d 08             	mov    0x8(%ebp),%ebx
	// If e is currently running on other CPUs, we change its state to
	// ENV_DYING. A zombie environment will be freed the next time
	// it traps to the kernel.
	if (e->env_status == ENV_RUNNING && curenv != e) {
f010349f:	83 7b 54 03          	cmpl   $0x3,0x54(%ebx)
f01034a3:	75 19                	jne    f01034be <env_destroy+0x29>
f01034a5:	e8 64 21 00 00       	call   f010560e <cpunum>
f01034aa:	6b c0 74             	imul   $0x74,%eax,%eax
f01034ad:	3b 98 28 70 28 f0    	cmp    -0xfd78fd8(%eax),%ebx
f01034b3:	74 09                	je     f01034be <env_destroy+0x29>
		e->env_status = ENV_DYING;
f01034b5:	c7 43 54 01 00 00 00 	movl   $0x1,0x54(%ebx)
		return;
f01034bc:	eb 33                	jmp    f01034f1 <env_destroy+0x5c>
	}

	env_free(e);
f01034be:	83 ec 0c             	sub    $0xc,%esp
f01034c1:	53                   	push   %ebx
f01034c2:	e8 75 fe ff ff       	call   f010333c <env_free>

	if (curenv == e) {
f01034c7:	e8 42 21 00 00       	call   f010560e <cpunum>
f01034cc:	6b c0 74             	imul   $0x74,%eax,%eax
f01034cf:	83 c4 10             	add    $0x10,%esp
f01034d2:	3b 98 28 70 28 f0    	cmp    -0xfd78fd8(%eax),%ebx
f01034d8:	75 17                	jne    f01034f1 <env_destroy+0x5c>
		curenv = NULL;
f01034da:	e8 2f 21 00 00       	call   f010560e <cpunum>
f01034df:	6b c0 74             	imul   $0x74,%eax,%eax
f01034e2:	c7 80 28 70 28 f0 00 	movl   $0x0,-0xfd78fd8(%eax)
f01034e9:	00 00 00 
		sched_yield();
f01034ec:	e8 b8 0d 00 00       	call   f01042a9 <sched_yield>
	}
}
f01034f1:	8b 5d fc             	mov    -0x4(%ebp),%ebx
f01034f4:	c9                   	leave  
f01034f5:	c3                   	ret    

f01034f6 <env_pop_tf>:
//
// This function does not return.
//
void
env_pop_tf(struct Trapframe *tf)
{
f01034f6:	55                   	push   %ebp
f01034f7:	89 e5                	mov    %esp,%ebp
f01034f9:	53                   	push   %ebx
f01034fa:	83 ec 04             	sub    $0x4,%esp
	// Record the CPU we are running on for user-space debugging
	curenv->env_cpunum = cpunum();
f01034fd:	e8 0c 21 00 00       	call   f010560e <cpunum>
f0103502:	6b c0 74             	imul   $0x74,%eax,%eax
f0103505:	8b 98 28 70 28 f0    	mov    -0xfd78fd8(%eax),%ebx
f010350b:	e8 fe 20 00 00       	call   f010560e <cpunum>
f0103510:	89 43 5c             	mov    %eax,0x5c(%ebx)

	asm volatile("\tmovl %0,%%esp\n"
f0103513:	8b 65 08             	mov    0x8(%ebp),%esp
f0103516:	61                   	popa   
f0103517:	07                   	pop    %es
f0103518:	1f                   	pop    %ds
f0103519:	83 c4 08             	add    $0x8,%esp
f010351c:	cf                   	iret   
	             "\taddl $0x8,%%esp\n" /* skip tf_trapno and tf_errcode */
	             "\tiret\n"
	             :
	             : "g"(tf)
	             : "memory");
	panic("iret failed"); /* mostly to placate the compiler */
f010351d:	83 ec 04             	sub    $0x4,%esp
f0103520:	68 35 70 10 f0       	push   $0xf0107035
f0103525:	68 16 02 00 00       	push   $0x216
f010352a:	68 76 6f 10 f0       	push   $0xf0106f76
f010352f:	e8 29 cb ff ff       	call   f010005d <_panic>

f0103534 <env_run>:
//
// This function does not return.
//
void
env_run(struct Env *e)
{
f0103534:	55                   	push   %ebp
f0103535:	89 e5                	mov    %esp,%ebp
f0103537:	83 ec 08             	sub    $0x8,%esp

	// LAB 3: Your code here.
	
	//panic("env_run not yet implemented");

	if(curenv != NULL){	//si no es la primera vez que se corre esto hay que guardar todo
f010353a:	e8 cf 20 00 00       	call   f010560e <cpunum>
f010353f:	6b c0 74             	imul   $0x74,%eax,%eax
f0103542:	83 b8 28 70 28 f0 00 	cmpl   $0x0,-0xfd78fd8(%eax)
f0103549:	74 56                	je     f01035a1 <env_run+0x6d>
		assert(curenv->env_status == ENV_RUNNING);
f010354b:	e8 be 20 00 00       	call   f010560e <cpunum>
f0103550:	6b c0 74             	imul   $0x74,%eax,%eax
f0103553:	8b 80 28 70 28 f0    	mov    -0xfd78fd8(%eax),%eax
f0103559:	83 78 54 03          	cmpl   $0x3,0x54(%eax)
f010355d:	74 19                	je     f0103578 <env_run+0x44>
f010355f:	68 54 6f 10 f0       	push   $0xf0106f54
f0103564:	68 de 6b 10 f0       	push   $0xf0106bde
f0103569:	68 38 02 00 00       	push   $0x238
f010356e:	68 76 6f 10 f0       	push   $0xf0106f76
f0103573:	e8 e5 ca ff ff       	call   f010005d <_panic>
		if (curenv->env_status == ENV_RUNNING) curenv->env_status=ENV_RUNNABLE;
f0103578:	e8 91 20 00 00       	call   f010560e <cpunum>
f010357d:	6b c0 74             	imul   $0x74,%eax,%eax
f0103580:	8b 80 28 70 28 f0    	mov    -0xfd78fd8(%eax),%eax
f0103586:	83 78 54 03          	cmpl   $0x3,0x54(%eax)
f010358a:	75 15                	jne    f01035a1 <env_run+0x6d>
f010358c:	e8 7d 20 00 00       	call   f010560e <cpunum>
f0103591:	6b c0 74             	imul   $0x74,%eax,%eax
f0103594:	8b 80 28 70 28 f0    	mov    -0xfd78fd8(%eax),%eax
f010359a:	c7 40 54 02 00 00 00 	movl   $0x2,0x54(%eax)
		//si FREE no tiene nada, no tiene sentido
		//si DYING ????
		//si RUNNABLE no deberia estar corriendo
		//si NOT_RUNNABLE ???
	}
	assert(e->env_status != ENV_FREE);//DEBUG2
f01035a1:	8b 45 08             	mov    0x8(%ebp),%eax
f01035a4:	8b 40 54             	mov    0x54(%eax),%eax
f01035a7:	85 c0                	test   %eax,%eax
f01035a9:	75 19                	jne    f01035c4 <env_run+0x90>
f01035ab:	68 41 70 10 f0       	push   $0xf0107041
f01035b0:	68 de 6b 10 f0       	push   $0xf0106bde
f01035b5:	68 40 02 00 00       	push   $0x240
f01035ba:	68 76 6f 10 f0       	push   $0xf0106f76
f01035bf:	e8 99 ca ff ff       	call   f010005d <_panic>
	assert(e->env_status == ENV_RUNNABLE);//DEBUG2
f01035c4:	83 f8 02             	cmp    $0x2,%eax
f01035c7:	74 19                	je     f01035e2 <env_run+0xae>
f01035c9:	68 5b 70 10 f0       	push   $0xf010705b
f01035ce:	68 de 6b 10 f0       	push   $0xf0106bde
f01035d3:	68 41 02 00 00       	push   $0x241
f01035d8:	68 76 6f 10 f0       	push   $0xf0106f76
f01035dd:	e8 7b ca ff ff       	call   f010005d <_panic>
	curenv=e;
f01035e2:	e8 27 20 00 00       	call   f010560e <cpunum>
f01035e7:	6b c0 74             	imul   $0x74,%eax,%eax
f01035ea:	8b 55 08             	mov    0x8(%ebp),%edx
f01035ed:	89 90 28 70 28 f0    	mov    %edx,-0xfd78fd8(%eax)
	curenv->env_status = ENV_RUNNING;
f01035f3:	e8 16 20 00 00       	call   f010560e <cpunum>
f01035f8:	6b c0 74             	imul   $0x74,%eax,%eax
f01035fb:	8b 80 28 70 28 f0    	mov    -0xfd78fd8(%eax),%eax
f0103601:	c7 40 54 03 00 00 00 	movl   $0x3,0x54(%eax)
	curenv->env_runs++;
f0103608:	e8 01 20 00 00       	call   f010560e <cpunum>
f010360d:	6b c0 74             	imul   $0x74,%eax,%eax
f0103610:	8b 80 28 70 28 f0    	mov    -0xfd78fd8(%eax),%eax
f0103616:	83 40 58 01          	addl   $0x1,0x58(%eax)
	lcr3(PADDR(curenv->env_pgdir));
f010361a:	e8 ef 1f 00 00       	call   f010560e <cpunum>
f010361f:	6b c0 74             	imul   $0x74,%eax,%eax
f0103622:	8b 80 28 70 28 f0    	mov    -0xfd78fd8(%eax),%eax
f0103628:	8b 48 60             	mov    0x60(%eax),%ecx
f010362b:	ba 45 02 00 00       	mov    $0x245,%edx
f0103630:	b8 76 6f 10 f0       	mov    $0xf0106f76,%eax
f0103635:	e8 d6 f7 ff ff       	call   f0102e10 <_paddr>
f010363a:	e8 66 f7 ff ff       	call   f0102da5 <lcr3>
	env_pop_tf(&(curenv->env_tf));
f010363f:	e8 ca 1f 00 00       	call   f010560e <cpunum>
f0103644:	83 ec 0c             	sub    $0xc,%esp
f0103647:	6b c0 74             	imul   $0x74,%eax,%eax
f010364a:	ff b0 28 70 28 f0    	pushl  -0xfd78fd8(%eax)
f0103650:	e8 a1 fe ff ff       	call   f01034f6 <env_pop_tf>

f0103655 <inb>:
	asm volatile("int3");
}

static inline uint8_t
inb(int port)
{
f0103655:	55                   	push   %ebp
f0103656:	89 e5                	mov    %esp,%ebp
	uint8_t data;
	asm volatile("inb %w1,%0" : "=a" (data) : "d" (port));
f0103658:	89 c2                	mov    %eax,%edx
f010365a:	ec                   	in     (%dx),%al
	return data;
}
f010365b:	5d                   	pop    %ebp
f010365c:	c3                   	ret    

f010365d <outb>:
		     : "memory", "cc");
}

static inline void
outb(int port, uint8_t data)
{
f010365d:	55                   	push   %ebp
f010365e:	89 e5                	mov    %esp,%ebp
f0103660:	89 c1                	mov    %eax,%ecx
f0103662:	89 d0                	mov    %edx,%eax
	asm volatile("outb %0,%w1" : : "a" (data), "d" (port));
f0103664:	89 ca                	mov    %ecx,%edx
f0103666:	ee                   	out    %al,(%dx)
}
f0103667:	5d                   	pop    %ebp
f0103668:	c3                   	ret    

f0103669 <mc146818_read>:
#include <kern/kclock.h>


unsigned
mc146818_read(unsigned reg)
{
f0103669:	55                   	push   %ebp
f010366a:	89 e5                	mov    %esp,%ebp
	outb(IO_RTC, reg);
f010366c:	0f b6 55 08          	movzbl 0x8(%ebp),%edx
f0103670:	b8 70 00 00 00       	mov    $0x70,%eax
f0103675:	e8 e3 ff ff ff       	call   f010365d <outb>
	return inb(IO_RTC+1);
f010367a:	b8 71 00 00 00       	mov    $0x71,%eax
f010367f:	e8 d1 ff ff ff       	call   f0103655 <inb>
f0103684:	0f b6 c0             	movzbl %al,%eax
}
f0103687:	5d                   	pop    %ebp
f0103688:	c3                   	ret    

f0103689 <mc146818_write>:

void
mc146818_write(unsigned reg, unsigned datum)
{
f0103689:	55                   	push   %ebp
f010368a:	89 e5                	mov    %esp,%ebp
	outb(IO_RTC, reg);
f010368c:	0f b6 55 08          	movzbl 0x8(%ebp),%edx
f0103690:	b8 70 00 00 00       	mov    $0x70,%eax
f0103695:	e8 c3 ff ff ff       	call   f010365d <outb>
	outb(IO_RTC+1, datum);
f010369a:	0f b6 55 0c          	movzbl 0xc(%ebp),%edx
f010369e:	b8 71 00 00 00       	mov    $0x71,%eax
f01036a3:	e8 b5 ff ff ff       	call   f010365d <outb>
}
f01036a8:	5d                   	pop    %ebp
f01036a9:	c3                   	ret    

f01036aa <outb>:
		     : "memory", "cc");
}

static inline void
outb(int port, uint8_t data)
{
f01036aa:	55                   	push   %ebp
f01036ab:	89 e5                	mov    %esp,%ebp
f01036ad:	89 c1                	mov    %eax,%ecx
f01036af:	89 d0                	mov    %edx,%eax
	asm volatile("outb %0,%w1" : : "a" (data), "d" (port));
f01036b1:	89 ca                	mov    %ecx,%edx
f01036b3:	ee                   	out    %al,(%dx)
}
f01036b4:	5d                   	pop    %ebp
f01036b5:	c3                   	ret    

f01036b6 <irq_setmask_8259A>:
		irq_setmask_8259A(irq_mask_8259A);
}

void
irq_setmask_8259A(uint16_t mask)
{
f01036b6:	55                   	push   %ebp
f01036b7:	89 e5                	mov    %esp,%ebp
f01036b9:	56                   	push   %esi
f01036ba:	53                   	push   %ebx
f01036bb:	8b 5d 08             	mov    0x8(%ebp),%ebx
	int i;
	irq_mask_8259A = mask;
f01036be:	66 89 1d a8 13 11 f0 	mov    %bx,0xf01113a8
	if (!didinit)
f01036c5:	80 3d 4c 52 28 f0 00 	cmpb   $0x0,0xf028524c
f01036cc:	74 64                	je     f0103732 <irq_setmask_8259A+0x7c>
f01036ce:	89 de                	mov    %ebx,%esi
		return;
	outb(IO_PIC1+1, (char)mask);
f01036d0:	0f b6 d3             	movzbl %bl,%edx
f01036d3:	b8 21 00 00 00       	mov    $0x21,%eax
f01036d8:	e8 cd ff ff ff       	call   f01036aa <outb>
	outb(IO_PIC2+1, (char)(mask >> 8));
f01036dd:	0f b6 d7             	movzbl %bh,%edx
f01036e0:	b8 a1 00 00 00       	mov    $0xa1,%eax
f01036e5:	e8 c0 ff ff ff       	call   f01036aa <outb>
	cprintf("enabled interrupts:");
f01036ea:	83 ec 0c             	sub    $0xc,%esp
f01036ed:	68 79 70 10 f0       	push   $0xf0107079
f01036f2:	e8 78 01 00 00       	call   f010386f <cprintf>
f01036f7:	83 c4 10             	add    $0x10,%esp
	for (i = 0; i < 16; i++)
f01036fa:	bb 00 00 00 00       	mov    $0x0,%ebx
		if (~mask & (1<<i))
f01036ff:	0f b7 f6             	movzwl %si,%esi
f0103702:	f7 d6                	not    %esi
f0103704:	0f a3 de             	bt     %ebx,%esi
f0103707:	73 11                	jae    f010371a <irq_setmask_8259A+0x64>
			cprintf(" %d", i);
f0103709:	83 ec 08             	sub    $0x8,%esp
f010370c:	53                   	push   %ebx
f010370d:	68 82 75 10 f0       	push   $0xf0107582
f0103712:	e8 58 01 00 00       	call   f010386f <cprintf>
f0103717:	83 c4 10             	add    $0x10,%esp
	if (!didinit)
		return;
	outb(IO_PIC1+1, (char)mask);
	outb(IO_PIC2+1, (char)(mask >> 8));
	cprintf("enabled interrupts:");
	for (i = 0; i < 16; i++)
f010371a:	83 c3 01             	add    $0x1,%ebx
f010371d:	83 fb 10             	cmp    $0x10,%ebx
f0103720:	75 e2                	jne    f0103704 <irq_setmask_8259A+0x4e>
		if (~mask & (1<<i))
			cprintf(" %d", i);
	cprintf("\n");
f0103722:	83 ec 0c             	sub    $0xc,%esp
f0103725:	68 cf 70 10 f0       	push   $0xf01070cf
f010372a:	e8 40 01 00 00       	call   f010386f <cprintf>
f010372f:	83 c4 10             	add    $0x10,%esp
}
f0103732:	8d 65 f8             	lea    -0x8(%ebp),%esp
f0103735:	5b                   	pop    %ebx
f0103736:	5e                   	pop    %esi
f0103737:	5d                   	pop    %ebp
f0103738:	c3                   	ret    

f0103739 <pic_init>:
static bool didinit;

/* Initialize the 8259A interrupt controllers. */
void
pic_init(void)
{
f0103739:	55                   	push   %ebp
f010373a:	89 e5                	mov    %esp,%ebp
f010373c:	83 ec 08             	sub    $0x8,%esp
	didinit = 1;
f010373f:	c6 05 4c 52 28 f0 01 	movb   $0x1,0xf028524c

	// mask all interrupts
	outb(IO_PIC1+1, 0xFF);
f0103746:	ba ff 00 00 00       	mov    $0xff,%edx
f010374b:	b8 21 00 00 00       	mov    $0x21,%eax
f0103750:	e8 55 ff ff ff       	call   f01036aa <outb>
	outb(IO_PIC2+1, 0xFF);
f0103755:	ba ff 00 00 00       	mov    $0xff,%edx
f010375a:	b8 a1 00 00 00       	mov    $0xa1,%eax
f010375f:	e8 46 ff ff ff       	call   f01036aa <outb>

	// ICW1:  0001g0hi
	//    g:  0 = edge triggering, 1 = level triggering
	//    h:  0 = cascaded PICs, 1 = master only
	//    i:  0 = no ICW4, 1 = ICW4 required
	outb(IO_PIC1, 0x11);
f0103764:	ba 11 00 00 00       	mov    $0x11,%edx
f0103769:	b8 20 00 00 00       	mov    $0x20,%eax
f010376e:	e8 37 ff ff ff       	call   f01036aa <outb>

	// ICW2:  Vector offset
	outb(IO_PIC1+1, IRQ_OFFSET);
f0103773:	ba 20 00 00 00       	mov    $0x20,%edx
f0103778:	b8 21 00 00 00       	mov    $0x21,%eax
f010377d:	e8 28 ff ff ff       	call   f01036aa <outb>

	// ICW3:  bit mask of IR lines connected to slave PICs (master PIC),
	//        3-bit No of IR line at which slave connects to master(slave PIC).
	outb(IO_PIC1+1, 1<<IRQ_SLAVE);
f0103782:	ba 04 00 00 00       	mov    $0x4,%edx
f0103787:	b8 21 00 00 00       	mov    $0x21,%eax
f010378c:	e8 19 ff ff ff       	call   f01036aa <outb>
	//    m:  0 = slave PIC, 1 = master PIC
	//	  (ignored when b is 0, as the master/slave role
	//	  can be hardwired).
	//    a:  1 = Automatic EOI mode
	//    p:  0 = MCS-80/85 mode, 1 = intel x86 mode
	outb(IO_PIC1+1, 0x3);
f0103791:	ba 03 00 00 00       	mov    $0x3,%edx
f0103796:	b8 21 00 00 00       	mov    $0x21,%eax
f010379b:	e8 0a ff ff ff       	call   f01036aa <outb>

	// Set up slave (8259A-2)
	outb(IO_PIC2, 0x11);			// ICW1
f01037a0:	ba 11 00 00 00       	mov    $0x11,%edx
f01037a5:	b8 a0 00 00 00       	mov    $0xa0,%eax
f01037aa:	e8 fb fe ff ff       	call   f01036aa <outb>
	outb(IO_PIC2+1, IRQ_OFFSET + 8);	// ICW2
f01037af:	ba 28 00 00 00       	mov    $0x28,%edx
f01037b4:	b8 a1 00 00 00       	mov    $0xa1,%eax
f01037b9:	e8 ec fe ff ff       	call   f01036aa <outb>
	outb(IO_PIC2+1, IRQ_SLAVE);		// ICW3
f01037be:	ba 02 00 00 00       	mov    $0x2,%edx
f01037c3:	b8 a1 00 00 00       	mov    $0xa1,%eax
f01037c8:	e8 dd fe ff ff       	call   f01036aa <outb>
	// NB Automatic EOI mode doesn't tend to work on the slave.
	// Linux source code says it's "to be investigated".
	outb(IO_PIC2+1, 0x01);			// ICW4
f01037cd:	ba 01 00 00 00       	mov    $0x1,%edx
f01037d2:	b8 a1 00 00 00       	mov    $0xa1,%eax
f01037d7:	e8 ce fe ff ff       	call   f01036aa <outb>

	// OCW3:  0ef01prs
	//   ef:  0x = NOP, 10 = clear specific mask, 11 = set specific mask
	//    p:  0 = no polling, 1 = polling mode
	//   rs:  0x = NOP, 10 = read IRR, 11 = read ISR
	outb(IO_PIC1, 0x68);             /* clear specific mask */
f01037dc:	ba 68 00 00 00       	mov    $0x68,%edx
f01037e1:	b8 20 00 00 00       	mov    $0x20,%eax
f01037e6:	e8 bf fe ff ff       	call   f01036aa <outb>
	outb(IO_PIC1, 0x0a);             /* read IRR by default */
f01037eb:	ba 0a 00 00 00       	mov    $0xa,%edx
f01037f0:	b8 20 00 00 00       	mov    $0x20,%eax
f01037f5:	e8 b0 fe ff ff       	call   f01036aa <outb>

	outb(IO_PIC2, 0x68);               /* OCW3 */
f01037fa:	ba 68 00 00 00       	mov    $0x68,%edx
f01037ff:	b8 a0 00 00 00       	mov    $0xa0,%eax
f0103804:	e8 a1 fe ff ff       	call   f01036aa <outb>
	outb(IO_PIC2, 0x0a);               /* OCW3 */
f0103809:	ba 0a 00 00 00       	mov    $0xa,%edx
f010380e:	b8 a0 00 00 00       	mov    $0xa0,%eax
f0103813:	e8 92 fe ff ff       	call   f01036aa <outb>

	if (irq_mask_8259A != 0xFFFF)
f0103818:	0f b7 05 a8 13 11 f0 	movzwl 0xf01113a8,%eax
f010381f:	66 83 f8 ff          	cmp    $0xffff,%ax
f0103823:	74 0f                	je     f0103834 <pic_init+0xfb>
		irq_setmask_8259A(irq_mask_8259A);
f0103825:	83 ec 0c             	sub    $0xc,%esp
f0103828:	0f b7 c0             	movzwl %ax,%eax
f010382b:	50                   	push   %eax
f010382c:	e8 85 fe ff ff       	call   f01036b6 <irq_setmask_8259A>
f0103831:	83 c4 10             	add    $0x10,%esp
}
f0103834:	c9                   	leave  
f0103835:	c3                   	ret    

f0103836 <putch>:
#include <inc/stdarg.h>


static void
putch(int ch, int *cnt)
{
f0103836:	55                   	push   %ebp
f0103837:	89 e5                	mov    %esp,%ebp
f0103839:	83 ec 14             	sub    $0x14,%esp
	cputchar(ch);
f010383c:	ff 75 08             	pushl  0x8(%ebp)
f010383f:	e8 8f d0 ff ff       	call   f01008d3 <cputchar>
	*cnt++;
}
f0103844:	83 c4 10             	add    $0x10,%esp
f0103847:	c9                   	leave  
f0103848:	c3                   	ret    

f0103849 <vcprintf>:

int
vcprintf(const char *fmt, va_list ap)
{
f0103849:	55                   	push   %ebp
f010384a:	89 e5                	mov    %esp,%ebp
f010384c:	83 ec 18             	sub    $0x18,%esp
	int cnt = 0;
f010384f:	c7 45 f4 00 00 00 00 	movl   $0x0,-0xc(%ebp)

	vprintfmt((void*)putch, &cnt, fmt, ap);
f0103856:	ff 75 0c             	pushl  0xc(%ebp)
f0103859:	ff 75 08             	pushl  0x8(%ebp)
f010385c:	8d 45 f4             	lea    -0xc(%ebp),%eax
f010385f:	50                   	push   %eax
f0103860:	68 36 38 10 f0       	push   $0xf0103836
f0103865:	e8 e8 10 00 00       	call   f0104952 <vprintfmt>
	return cnt;
}
f010386a:	8b 45 f4             	mov    -0xc(%ebp),%eax
f010386d:	c9                   	leave  
f010386e:	c3                   	ret    

f010386f <cprintf>:

int
cprintf(const char *fmt, ...)
{
f010386f:	55                   	push   %ebp
f0103870:	89 e5                	mov    %esp,%ebp
f0103872:	83 ec 10             	sub    $0x10,%esp
	va_list ap;
	int cnt;

	va_start(ap, fmt);
f0103875:	8d 45 0c             	lea    0xc(%ebp),%eax
	cnt = vcprintf(fmt, ap);
f0103878:	50                   	push   %eax
f0103879:	ff 75 08             	pushl  0x8(%ebp)
f010387c:	e8 c8 ff ff ff       	call   f0103849 <vcprintf>
	va_end(ap);

	return cnt;
}
f0103881:	c9                   	leave  
f0103882:	c3                   	ret    

f0103883 <lidt>:
	asm volatile("invlpg (%0)" : : "r" (addr) : "memory");
}

static inline void
lidt(void *p)
{
f0103883:	55                   	push   %ebp
f0103884:	89 e5                	mov    %esp,%ebp
	asm volatile("lidt (%0)" : : "r" (p));
f0103886:	0f 01 18             	lidtl  (%eax)
}
f0103889:	5d                   	pop    %ebp
f010388a:	c3                   	ret    

f010388b <ltr>:
	asm volatile("lldt %0" : : "r" (sel));
}

static inline void
ltr(uint16_t sel)
{
f010388b:	55                   	push   %ebp
f010388c:	89 e5                	mov    %esp,%ebp
	asm volatile("ltr %0" : : "r" (sel));
f010388e:	0f 00 d8             	ltr    %ax
}
f0103891:	5d                   	pop    %ebp
f0103892:	c3                   	ret    

f0103893 <rcr2>:
	return val;
}

static inline uint32_t
rcr2(void)
{
f0103893:	55                   	push   %ebp
f0103894:	89 e5                	mov    %esp,%ebp
	uint32_t val;
	asm volatile("movl %%cr2,%0" : "=r" (val));
f0103896:	0f 20 d0             	mov    %cr2,%eax
	return val;
}
f0103899:	5d                   	pop    %ebp
f010389a:	c3                   	ret    

f010389b <read_eflags>:
	asm volatile("movl %0,%%cr3" : : "r" (cr3));
}

static inline uint32_t
read_eflags(void)
{
f010389b:	55                   	push   %ebp
f010389c:	89 e5                	mov    %esp,%ebp
	uint32_t eflags;
	asm volatile("pushfl; popl %0" : "=r" (eflags));
f010389e:	9c                   	pushf  
f010389f:	58                   	pop    %eax
	return eflags;
}
f01038a0:	5d                   	pop    %ebp
f01038a1:	c3                   	ret    

f01038a2 <xchg>:
	return tsc;
}

static inline uint32_t
xchg(volatile uint32_t *addr, uint32_t newval)
{
f01038a2:	55                   	push   %ebp
f01038a3:	89 e5                	mov    %esp,%ebp
f01038a5:	89 c1                	mov    %eax,%ecx
	uint32_t result;

	// The + in "+m" denotes a read-modify-write operand.
	asm volatile("lock; xchgl %0, %1"
f01038a7:	89 d0                	mov    %edx,%eax
f01038a9:	f0 87 01             	lock xchg %eax,(%ecx)
		     : "+m" (*addr), "=a" (result)
		     : "1" (newval)
		     : "cc");
	return result;
}
f01038ac:	5d                   	pop    %ebp
f01038ad:	c3                   	ret    

f01038ae <trapname>:
struct Pseudodesc idt_pd = { sizeof(idt) - 1, (uint32_t) idt };


static const char *
trapname(int trapno)
{
f01038ae:	55                   	push   %ebp
f01038af:	89 e5                	mov    %esp,%ebp
		"Alignment Check",
		"Machine-Check",
		"SIMD Floating-Point Exception"
	};

	if (trapno < ARRAY_SIZE(excnames))
f01038b1:	83 f8 13             	cmp    $0x13,%eax
f01038b4:	77 09                	ja     f01038bf <trapname+0x11>
		return excnames[trapno];
f01038b6:	8b 04 85 60 74 10 f0 	mov    -0xfef8ba0(,%eax,4),%eax
f01038bd:	eb 1f                	jmp    f01038de <trapname+0x30>
	if (trapno == T_SYSCALL)
f01038bf:	83 f8 30             	cmp    $0x30,%eax
f01038c2:	74 15                	je     f01038d9 <trapname+0x2b>
		return "System call";
	if (trapno >= IRQ_OFFSET && trapno < IRQ_OFFSET + 16)
f01038c4:	83 e8 20             	sub    $0x20,%eax
		return "Hardware Interrupt";
	return "(unknown trap)";
f01038c7:	83 f8 10             	cmp    $0x10,%eax
f01038ca:	ba ac 70 10 f0       	mov    $0xf01070ac,%edx
f01038cf:	b8 99 70 10 f0       	mov    $0xf0107099,%eax
f01038d4:	0f 43 c2             	cmovae %edx,%eax
f01038d7:	eb 05                	jmp    f01038de <trapname+0x30>
	};

	if (trapno < ARRAY_SIZE(excnames))
		return excnames[trapno];
	if (trapno == T_SYSCALL)
		return "System call";
f01038d9:	b8 8d 70 10 f0       	mov    $0xf010708d,%eax
	if (trapno >= IRQ_OFFSET && trapno < IRQ_OFFSET + 16)
		return "Hardware Interrupt";
	return "(unknown trap)";
}
f01038de:	5d                   	pop    %ebp
f01038df:	c3                   	ret    

f01038e0 <lock_kernel>:

extern struct spinlock kernel_lock;

static inline void
lock_kernel(void)
{
f01038e0:	55                   	push   %ebp
f01038e1:	89 e5                	mov    %esp,%ebp
f01038e3:	83 ec 14             	sub    $0x14,%esp
	spin_lock(&kernel_lock);
f01038e6:	68 20 14 11 f0       	push   $0xf0111420
f01038eb:	e8 f4 1f 00 00       	call   f01058e4 <spin_lock>
}
f01038f0:	83 c4 10             	add    $0x10,%esp
f01038f3:	c9                   	leave  
f01038f4:	c3                   	ret    

f01038f5 <trap_init_percpu>:
}

// Initialize and load the per-CPU TSS and IDT
void
trap_init_percpu(void)
{
f01038f5:	55                   	push   %ebp
f01038f6:	89 e5                	mov    %esp,%ebp
	//
	// LAB 4: Your code here:

	// Setup a TSS so that we get the right stack
	// when we trap to the kernel.
	ts.ts_esp0 = KSTACKTOP;
f01038f8:	b8 80 5a 28 f0       	mov    $0xf0285a80,%eax
f01038fd:	c7 05 84 5a 28 f0 00 	movl   $0xf0000000,0xf0285a84
f0103904:	00 00 f0 
	ts.ts_ss0 = GD_KD;
f0103907:	66 c7 05 88 5a 28 f0 	movw   $0x10,0xf0285a88
f010390e:	10 00 
	ts.ts_iomb = sizeof(struct Taskstate);
f0103910:	66 c7 05 e6 5a 28 f0 	movw   $0x68,0xf0285ae6
f0103917:	68 00 

	// Initialize the TSS slot of the gdt.
	gdt[GD_TSS0 >> 3] =
f0103919:	66 c7 05 68 13 11 f0 	movw   $0x67,0xf0111368
f0103920:	67 00 
f0103922:	66 a3 6a 13 11 f0    	mov    %ax,0xf011136a
f0103928:	89 c2                	mov    %eax,%edx
f010392a:	c1 ea 10             	shr    $0x10,%edx
f010392d:	88 15 6c 13 11 f0    	mov    %dl,0xf011136c
f0103933:	c6 05 6e 13 11 f0 40 	movb   $0x40,0xf011136e
f010393a:	c1 e8 18             	shr    $0x18,%eax
f010393d:	a2 6f 13 11 f0       	mov    %al,0xf011136f
	        SEG16(STS_T32A, (uint32_t)(&ts), sizeof(struct Taskstate) - 1, 0);
	gdt[GD_TSS0 >> 3].sd_s = 0;
f0103942:	c6 05 6d 13 11 f0 89 	movb   $0x89,0xf011136d

	// Load the TSS selector (like other segment selectors, the
	// bottom three bits are special; we leave them 0)
	ltr(GD_TSS0);
f0103949:	b8 28 00 00 00       	mov    $0x28,%eax
f010394e:	e8 38 ff ff ff       	call   f010388b <ltr>

	// Load the IDT
	lidt(&idt_pd);
f0103953:	b8 ac 13 11 f0       	mov    $0xf01113ac,%eax
f0103958:	e8 26 ff ff ff       	call   f0103883 <lidt>
}
f010395d:	5d                   	pop    %ebp
f010395e:	c3                   	ret    

f010395f <trap_init>:
void Trap_48();


void
trap_init(void)
{
f010395f:	55                   	push   %ebp
f0103960:	89 e5                	mov    %esp,%ebp
f0103962:	83 ec 14             	sub    $0x14,%esp
	cprintf("Se setean los gates \n");
f0103965:	68 bb 70 10 f0       	push   $0xf01070bb
f010396a:	e8 00 ff ff ff       	call   f010386f <cprintf>
	extern struct Segdesc gdt[];

	// LAB 3: Your code here.
	SETGATE(idt[0], 0, GD_KT, Trap_0, 0);
f010396f:	b8 2c 41 10 f0       	mov    $0xf010412c,%eax
f0103974:	66 a3 60 52 28 f0    	mov    %ax,0xf0285260
f010397a:	66 c7 05 62 52 28 f0 	movw   $0x8,0xf0285262
f0103981:	08 00 
f0103983:	c6 05 64 52 28 f0 00 	movb   $0x0,0xf0285264
f010398a:	c6 05 65 52 28 f0 8e 	movb   $0x8e,0xf0285265
f0103991:	c1 e8 10             	shr    $0x10,%eax
f0103994:	66 a3 66 52 28 f0    	mov    %ax,0xf0285266
	SETGATE(idt[1], 0, GD_KT, Trap_1, 0);
f010399a:	b8 32 41 10 f0       	mov    $0xf0104132,%eax
f010399f:	66 a3 68 52 28 f0    	mov    %ax,0xf0285268
f01039a5:	66 c7 05 6a 52 28 f0 	movw   $0x8,0xf028526a
f01039ac:	08 00 
f01039ae:	c6 05 6c 52 28 f0 00 	movb   $0x0,0xf028526c
f01039b5:	c6 05 6d 52 28 f0 8e 	movb   $0x8e,0xf028526d
f01039bc:	c1 e8 10             	shr    $0x10,%eax
f01039bf:	66 a3 6e 52 28 f0    	mov    %ax,0xf028526e
	SETGATE(idt[2], 0, GD_KT, Trap_2, 0); 
f01039c5:	b8 38 41 10 f0       	mov    $0xf0104138,%eax
f01039ca:	66 a3 70 52 28 f0    	mov    %ax,0xf0285270
f01039d0:	66 c7 05 72 52 28 f0 	movw   $0x8,0xf0285272
f01039d7:	08 00 
f01039d9:	c6 05 74 52 28 f0 00 	movb   $0x0,0xf0285274
f01039e0:	c6 05 75 52 28 f0 8e 	movb   $0x8e,0xf0285275
f01039e7:	c1 e8 10             	shr    $0x10,%eax
f01039ea:	66 a3 76 52 28 f0    	mov    %ax,0xf0285276
	SETGATE(idt[3], 0, GD_KT, Trap_3, 3);
f01039f0:	b8 3e 41 10 f0       	mov    $0xf010413e,%eax
f01039f5:	66 a3 78 52 28 f0    	mov    %ax,0xf0285278
f01039fb:	66 c7 05 7a 52 28 f0 	movw   $0x8,0xf028527a
f0103a02:	08 00 
f0103a04:	c6 05 7c 52 28 f0 00 	movb   $0x0,0xf028527c
f0103a0b:	c6 05 7d 52 28 f0 ee 	movb   $0xee,0xf028527d
f0103a12:	c1 e8 10             	shr    $0x10,%eax
f0103a15:	66 a3 7e 52 28 f0    	mov    %ax,0xf028527e
	SETGATE(idt[4], 0, GD_KT, Trap_4, 0);
f0103a1b:	b8 44 41 10 f0       	mov    $0xf0104144,%eax
f0103a20:	66 a3 80 52 28 f0    	mov    %ax,0xf0285280
f0103a26:	66 c7 05 82 52 28 f0 	movw   $0x8,0xf0285282
f0103a2d:	08 00 
f0103a2f:	c6 05 84 52 28 f0 00 	movb   $0x0,0xf0285284
f0103a36:	c6 05 85 52 28 f0 8e 	movb   $0x8e,0xf0285285
f0103a3d:	c1 e8 10             	shr    $0x10,%eax
f0103a40:	66 a3 86 52 28 f0    	mov    %ax,0xf0285286
	SETGATE(idt[5], 0, GD_KT, Trap_5, 0);
f0103a46:	b8 4a 41 10 f0       	mov    $0xf010414a,%eax
f0103a4b:	66 a3 88 52 28 f0    	mov    %ax,0xf0285288
f0103a51:	66 c7 05 8a 52 28 f0 	movw   $0x8,0xf028528a
f0103a58:	08 00 
f0103a5a:	c6 05 8c 52 28 f0 00 	movb   $0x0,0xf028528c
f0103a61:	c6 05 8d 52 28 f0 8e 	movb   $0x8e,0xf028528d
f0103a68:	c1 e8 10             	shr    $0x10,%eax
f0103a6b:	66 a3 8e 52 28 f0    	mov    %ax,0xf028528e
	SETGATE(idt[6], 0, GD_KT, Trap_6, 0);
f0103a71:	b8 50 41 10 f0       	mov    $0xf0104150,%eax
f0103a76:	66 a3 90 52 28 f0    	mov    %ax,0xf0285290
f0103a7c:	66 c7 05 92 52 28 f0 	movw   $0x8,0xf0285292
f0103a83:	08 00 
f0103a85:	c6 05 94 52 28 f0 00 	movb   $0x0,0xf0285294
f0103a8c:	c6 05 95 52 28 f0 8e 	movb   $0x8e,0xf0285295
f0103a93:	c1 e8 10             	shr    $0x10,%eax
f0103a96:	66 a3 96 52 28 f0    	mov    %ax,0xf0285296
	SETGATE(idt[7], 0, GD_KT, Trap_7, 0);
f0103a9c:	b8 56 41 10 f0       	mov    $0xf0104156,%eax
f0103aa1:	66 a3 98 52 28 f0    	mov    %ax,0xf0285298
f0103aa7:	66 c7 05 9a 52 28 f0 	movw   $0x8,0xf028529a
f0103aae:	08 00 
f0103ab0:	c6 05 9c 52 28 f0 00 	movb   $0x0,0xf028529c
f0103ab7:	c6 05 9d 52 28 f0 8e 	movb   $0x8e,0xf028529d
f0103abe:	c1 e8 10             	shr    $0x10,%eax
f0103ac1:	66 a3 9e 52 28 f0    	mov    %ax,0xf028529e
	SETGATE(idt[8], 0, GD_KT, Trap_8, 0); 
f0103ac7:	b8 5c 41 10 f0       	mov    $0xf010415c,%eax
f0103acc:	66 a3 a0 52 28 f0    	mov    %ax,0xf02852a0
f0103ad2:	66 c7 05 a2 52 28 f0 	movw   $0x8,0xf02852a2
f0103ad9:	08 00 
f0103adb:	c6 05 a4 52 28 f0 00 	movb   $0x0,0xf02852a4
f0103ae2:	c6 05 a5 52 28 f0 8e 	movb   $0x8e,0xf02852a5
f0103ae9:	c1 e8 10             	shr    $0x10,%eax
f0103aec:	66 a3 a6 52 28 f0    	mov    %ax,0xf02852a6
	SETGATE(idt[10], 0, GD_KT, Trap_10, 0); 
f0103af2:	b8 60 41 10 f0       	mov    $0xf0104160,%eax
f0103af7:	66 a3 b0 52 28 f0    	mov    %ax,0xf02852b0
f0103afd:	66 c7 05 b2 52 28 f0 	movw   $0x8,0xf02852b2
f0103b04:	08 00 
f0103b06:	c6 05 b4 52 28 f0 00 	movb   $0x0,0xf02852b4
f0103b0d:	c6 05 b5 52 28 f0 8e 	movb   $0x8e,0xf02852b5
f0103b14:	c1 e8 10             	shr    $0x10,%eax
f0103b17:	66 a3 b6 52 28 f0    	mov    %ax,0xf02852b6
	SETGATE(idt[11], 0, GD_KT, Trap_11, 0); 
f0103b1d:	b8 64 41 10 f0       	mov    $0xf0104164,%eax
f0103b22:	66 a3 b8 52 28 f0    	mov    %ax,0xf02852b8
f0103b28:	66 c7 05 ba 52 28 f0 	movw   $0x8,0xf02852ba
f0103b2f:	08 00 
f0103b31:	c6 05 bc 52 28 f0 00 	movb   $0x0,0xf02852bc
f0103b38:	c6 05 bd 52 28 f0 8e 	movb   $0x8e,0xf02852bd
f0103b3f:	c1 e8 10             	shr    $0x10,%eax
f0103b42:	66 a3 be 52 28 f0    	mov    %ax,0xf02852be
	SETGATE(idt[12], 0, GD_KT, Trap_12, 0); 
f0103b48:	b8 68 41 10 f0       	mov    $0xf0104168,%eax
f0103b4d:	66 a3 c0 52 28 f0    	mov    %ax,0xf02852c0
f0103b53:	66 c7 05 c2 52 28 f0 	movw   $0x8,0xf02852c2
f0103b5a:	08 00 
f0103b5c:	c6 05 c4 52 28 f0 00 	movb   $0x0,0xf02852c4
f0103b63:	c6 05 c5 52 28 f0 8e 	movb   $0x8e,0xf02852c5
f0103b6a:	c1 e8 10             	shr    $0x10,%eax
f0103b6d:	66 a3 c6 52 28 f0    	mov    %ax,0xf02852c6
	SETGATE(idt[13], 0, GD_KT, Trap_13, 0); 
f0103b73:	b8 6c 41 10 f0       	mov    $0xf010416c,%eax
f0103b78:	66 a3 c8 52 28 f0    	mov    %ax,0xf02852c8
f0103b7e:	66 c7 05 ca 52 28 f0 	movw   $0x8,0xf02852ca
f0103b85:	08 00 
f0103b87:	c6 05 cc 52 28 f0 00 	movb   $0x0,0xf02852cc
f0103b8e:	c6 05 cd 52 28 f0 8e 	movb   $0x8e,0xf02852cd
f0103b95:	c1 e8 10             	shr    $0x10,%eax
f0103b98:	66 a3 ce 52 28 f0    	mov    %ax,0xf02852ce
	SETGATE(idt[14], 0, GD_KT, Trap_14, 0); 
f0103b9e:	b8 70 41 10 f0       	mov    $0xf0104170,%eax
f0103ba3:	66 a3 d0 52 28 f0    	mov    %ax,0xf02852d0
f0103ba9:	66 c7 05 d2 52 28 f0 	movw   $0x8,0xf02852d2
f0103bb0:	08 00 
f0103bb2:	c6 05 d4 52 28 f0 00 	movb   $0x0,0xf02852d4
f0103bb9:	c6 05 d5 52 28 f0 8e 	movb   $0x8e,0xf02852d5
f0103bc0:	c1 e8 10             	shr    $0x10,%eax
f0103bc3:	66 a3 d6 52 28 f0    	mov    %ax,0xf02852d6
	SETGATE(idt[16], 0, GD_KT, Trap_16, 0);
f0103bc9:	b8 74 41 10 f0       	mov    $0xf0104174,%eax
f0103bce:	66 a3 e0 52 28 f0    	mov    %ax,0xf02852e0
f0103bd4:	66 c7 05 e2 52 28 f0 	movw   $0x8,0xf02852e2
f0103bdb:	08 00 
f0103bdd:	c6 05 e4 52 28 f0 00 	movb   $0x0,0xf02852e4
f0103be4:	c6 05 e5 52 28 f0 8e 	movb   $0x8e,0xf02852e5
f0103beb:	c1 e8 10             	shr    $0x10,%eax
f0103bee:	66 a3 e6 52 28 f0    	mov    %ax,0xf02852e6
	SETGATE(idt[17], 0, GD_KT, Trap_17, 0); 
f0103bf4:	b8 7a 41 10 f0       	mov    $0xf010417a,%eax
f0103bf9:	66 a3 e8 52 28 f0    	mov    %ax,0xf02852e8
f0103bff:	66 c7 05 ea 52 28 f0 	movw   $0x8,0xf02852ea
f0103c06:	08 00 
f0103c08:	c6 05 ec 52 28 f0 00 	movb   $0x0,0xf02852ec
f0103c0f:	c6 05 ed 52 28 f0 8e 	movb   $0x8e,0xf02852ed
f0103c16:	c1 e8 10             	shr    $0x10,%eax
f0103c19:	66 a3 ee 52 28 f0    	mov    %ax,0xf02852ee
	SETGATE(idt[18], 0, GD_KT, Trap_18, 0); 
f0103c1f:	b8 7e 41 10 f0       	mov    $0xf010417e,%eax
f0103c24:	66 a3 f0 52 28 f0    	mov    %ax,0xf02852f0
f0103c2a:	66 c7 05 f2 52 28 f0 	movw   $0x8,0xf02852f2
f0103c31:	08 00 
f0103c33:	c6 05 f4 52 28 f0 00 	movb   $0x0,0xf02852f4
f0103c3a:	c6 05 f5 52 28 f0 8e 	movb   $0x8e,0xf02852f5
f0103c41:	c1 e8 10             	shr    $0x10,%eax
f0103c44:	66 a3 f6 52 28 f0    	mov    %ax,0xf02852f6
	SETGATE(idt[19], 0, GD_KT, Trap_19, 0); 
f0103c4a:	b8 84 41 10 f0       	mov    $0xf0104184,%eax
f0103c4f:	66 a3 f8 52 28 f0    	mov    %ax,0xf02852f8
f0103c55:	66 c7 05 fa 52 28 f0 	movw   $0x8,0xf02852fa
f0103c5c:	08 00 
f0103c5e:	c6 05 fc 52 28 f0 00 	movb   $0x0,0xf02852fc
f0103c65:	c6 05 fd 52 28 f0 8e 	movb   $0x8e,0xf02852fd
f0103c6c:	c1 e8 10             	shr    $0x10,%eax
f0103c6f:	66 a3 fe 52 28 f0    	mov    %ax,0xf02852fe
	SETGATE(idt[48], 0, GD_KT, Trap_48, 3);
f0103c75:	b8 8a 41 10 f0       	mov    $0xf010418a,%eax
f0103c7a:	66 a3 e0 53 28 f0    	mov    %ax,0xf02853e0
f0103c80:	66 c7 05 e2 53 28 f0 	movw   $0x8,0xf02853e2
f0103c87:	08 00 
f0103c89:	c6 05 e4 53 28 f0 00 	movb   $0x0,0xf02853e4
f0103c90:	c6 05 e5 53 28 f0 ee 	movb   $0xee,0xf02853e5
f0103c97:	c1 e8 10             	shr    $0x10,%eax
f0103c9a:	66 a3 e6 53 28 f0    	mov    %ax,0xf02853e6

	cprintf("Se setearon los gates\n");
f0103ca0:	c7 04 24 d1 70 10 f0 	movl   $0xf01070d1,(%esp)
f0103ca7:	e8 c3 fb ff ff       	call   f010386f <cprintf>

	// Per-CPU setup
	trap_init_percpu();
f0103cac:	e8 44 fc ff ff       	call   f01038f5 <trap_init_percpu>
}
f0103cb1:	83 c4 10             	add    $0x10,%esp
f0103cb4:	c9                   	leave  
f0103cb5:	c3                   	ret    

f0103cb6 <print_regs>:
	}
}

void
print_regs(struct PushRegs *regs)
{
f0103cb6:	55                   	push   %ebp
f0103cb7:	89 e5                	mov    %esp,%ebp
f0103cb9:	53                   	push   %ebx
f0103cba:	83 ec 0c             	sub    $0xc,%esp
f0103cbd:	8b 5d 08             	mov    0x8(%ebp),%ebx
	cprintf("  edi  0x%08x\n", regs->reg_edi);
f0103cc0:	ff 33                	pushl  (%ebx)
f0103cc2:	68 e8 70 10 f0       	push   $0xf01070e8
f0103cc7:	e8 a3 fb ff ff       	call   f010386f <cprintf>
	cprintf("  esi  0x%08x\n", regs->reg_esi);
f0103ccc:	83 c4 08             	add    $0x8,%esp
f0103ccf:	ff 73 04             	pushl  0x4(%ebx)
f0103cd2:	68 f7 70 10 f0       	push   $0xf01070f7
f0103cd7:	e8 93 fb ff ff       	call   f010386f <cprintf>
	cprintf("  ebp  0x%08x\n", regs->reg_ebp);
f0103cdc:	83 c4 08             	add    $0x8,%esp
f0103cdf:	ff 73 08             	pushl  0x8(%ebx)
f0103ce2:	68 06 71 10 f0       	push   $0xf0107106
f0103ce7:	e8 83 fb ff ff       	call   f010386f <cprintf>
	cprintf("  oesp 0x%08x\n", regs->reg_oesp);
f0103cec:	83 c4 08             	add    $0x8,%esp
f0103cef:	ff 73 0c             	pushl  0xc(%ebx)
f0103cf2:	68 15 71 10 f0       	push   $0xf0107115
f0103cf7:	e8 73 fb ff ff       	call   f010386f <cprintf>
	cprintf("  ebx  0x%08x\n", regs->reg_ebx);
f0103cfc:	83 c4 08             	add    $0x8,%esp
f0103cff:	ff 73 10             	pushl  0x10(%ebx)
f0103d02:	68 24 71 10 f0       	push   $0xf0107124
f0103d07:	e8 63 fb ff ff       	call   f010386f <cprintf>
	cprintf("  edx  0x%08x\n", regs->reg_edx);
f0103d0c:	83 c4 08             	add    $0x8,%esp
f0103d0f:	ff 73 14             	pushl  0x14(%ebx)
f0103d12:	68 33 71 10 f0       	push   $0xf0107133
f0103d17:	e8 53 fb ff ff       	call   f010386f <cprintf>
	cprintf("  ecx  0x%08x\n", regs->reg_ecx);
f0103d1c:	83 c4 08             	add    $0x8,%esp
f0103d1f:	ff 73 18             	pushl  0x18(%ebx)
f0103d22:	68 42 71 10 f0       	push   $0xf0107142
f0103d27:	e8 43 fb ff ff       	call   f010386f <cprintf>
	cprintf("  eax  0x%08x\n", regs->reg_eax);
f0103d2c:	83 c4 08             	add    $0x8,%esp
f0103d2f:	ff 73 1c             	pushl  0x1c(%ebx)
f0103d32:	68 51 71 10 f0       	push   $0xf0107151
f0103d37:	e8 33 fb ff ff       	call   f010386f <cprintf>
}
f0103d3c:	83 c4 10             	add    $0x10,%esp
f0103d3f:	8b 5d fc             	mov    -0x4(%ebp),%ebx
f0103d42:	c9                   	leave  
f0103d43:	c3                   	ret    

f0103d44 <print_trapframe>:
	lidt(&idt_pd);
}

void
print_trapframe(struct Trapframe *tf)
{
f0103d44:	55                   	push   %ebp
f0103d45:	89 e5                	mov    %esp,%ebp
f0103d47:	56                   	push   %esi
f0103d48:	53                   	push   %ebx
f0103d49:	8b 5d 08             	mov    0x8(%ebp),%ebx
	cprintf("TRAP frame at %p from CPU %d\n", tf, cpunum());
f0103d4c:	e8 bd 18 00 00       	call   f010560e <cpunum>
f0103d51:	83 ec 04             	sub    $0x4,%esp
f0103d54:	50                   	push   %eax
f0103d55:	53                   	push   %ebx
f0103d56:	68 87 71 10 f0       	push   $0xf0107187
f0103d5b:	e8 0f fb ff ff       	call   f010386f <cprintf>
	print_regs(&tf->tf_regs);
f0103d60:	89 1c 24             	mov    %ebx,(%esp)
f0103d63:	e8 4e ff ff ff       	call   f0103cb6 <print_regs>
	cprintf("  es   0x----%04x\n", tf->tf_es);
f0103d68:	83 c4 08             	add    $0x8,%esp
f0103d6b:	0f b7 43 20          	movzwl 0x20(%ebx),%eax
f0103d6f:	50                   	push   %eax
f0103d70:	68 a5 71 10 f0       	push   $0xf01071a5
f0103d75:	e8 f5 fa ff ff       	call   f010386f <cprintf>
	cprintf("  ds   0x----%04x\n", tf->tf_ds);
f0103d7a:	83 c4 08             	add    $0x8,%esp
f0103d7d:	0f b7 43 24          	movzwl 0x24(%ebx),%eax
f0103d81:	50                   	push   %eax
f0103d82:	68 b8 71 10 f0       	push   $0xf01071b8
f0103d87:	e8 e3 fa ff ff       	call   f010386f <cprintf>
	cprintf("  trap 0x%08x %s\n", tf->tf_trapno, trapname(tf->tf_trapno));
f0103d8c:	8b 73 28             	mov    0x28(%ebx),%esi
f0103d8f:	89 f0                	mov    %esi,%eax
f0103d91:	e8 18 fb ff ff       	call   f01038ae <trapname>
f0103d96:	83 c4 0c             	add    $0xc,%esp
f0103d99:	50                   	push   %eax
f0103d9a:	56                   	push   %esi
f0103d9b:	68 cb 71 10 f0       	push   $0xf01071cb
f0103da0:	e8 ca fa ff ff       	call   f010386f <cprintf>
	// If this trap was a page fault that just happened
	// (so %cr2 is meaningful), print the faulting linear address.
	if (tf == last_tf && tf->tf_trapno == T_PGFLT)
f0103da5:	83 c4 10             	add    $0x10,%esp
f0103da8:	3b 1d 60 5a 28 f0    	cmp    0xf0285a60,%ebx
f0103dae:	75 1c                	jne    f0103dcc <print_trapframe+0x88>
f0103db0:	83 7b 28 0e          	cmpl   $0xe,0x28(%ebx)
f0103db4:	75 16                	jne    f0103dcc <print_trapframe+0x88>
		cprintf("  cr2  0x%08x\n", rcr2());
f0103db6:	e8 d8 fa ff ff       	call   f0103893 <rcr2>
f0103dbb:	83 ec 08             	sub    $0x8,%esp
f0103dbe:	50                   	push   %eax
f0103dbf:	68 dd 71 10 f0       	push   $0xf01071dd
f0103dc4:	e8 a6 fa ff ff       	call   f010386f <cprintf>
f0103dc9:	83 c4 10             	add    $0x10,%esp
	cprintf("  err  0x%08x", tf->tf_err);
f0103dcc:	83 ec 08             	sub    $0x8,%esp
f0103dcf:	ff 73 2c             	pushl  0x2c(%ebx)
f0103dd2:	68 ec 71 10 f0       	push   $0xf01071ec
f0103dd7:	e8 93 fa ff ff       	call   f010386f <cprintf>
	// For page faults, print decoded fault error code:
	// U/K=fault occurred in user/kernel mode
	// W/R=a write/read caused the fault
	// PR=a protection violation caused the fault (NP=page not present).
	if (tf->tf_trapno == T_PGFLT)
f0103ddc:	83 c4 10             	add    $0x10,%esp
f0103ddf:	83 7b 28 0e          	cmpl   $0xe,0x28(%ebx)
f0103de3:	75 49                	jne    f0103e2e <print_trapframe+0xea>
		cprintf(" [%s, %s, %s]\n",
		        tf->tf_err & 4 ? "user" : "kernel",
		        tf->tf_err & 2 ? "write" : "read",
		        tf->tf_err & 1 ? "protection" : "not-present");
f0103de5:	8b 43 2c             	mov    0x2c(%ebx),%eax
	// For page faults, print decoded fault error code:
	// U/K=fault occurred in user/kernel mode
	// W/R=a write/read caused the fault
	// PR=a protection violation caused the fault (NP=page not present).
	if (tf->tf_trapno == T_PGFLT)
		cprintf(" [%s, %s, %s]\n",
f0103de8:	89 c2                	mov    %eax,%edx
f0103dea:	83 e2 01             	and    $0x1,%edx
f0103ded:	ba 6b 71 10 f0       	mov    $0xf010716b,%edx
f0103df2:	b9 60 71 10 f0       	mov    $0xf0107160,%ecx
f0103df7:	0f 44 ca             	cmove  %edx,%ecx
f0103dfa:	89 c2                	mov    %eax,%edx
f0103dfc:	83 e2 02             	and    $0x2,%edx
f0103dff:	ba 7d 71 10 f0       	mov    $0xf010717d,%edx
f0103e04:	be 77 71 10 f0       	mov    $0xf0107177,%esi
f0103e09:	0f 45 d6             	cmovne %esi,%edx
f0103e0c:	83 e0 04             	and    $0x4,%eax
f0103e0f:	be 97 72 10 f0       	mov    $0xf0107297,%esi
f0103e14:	b8 82 71 10 f0       	mov    $0xf0107182,%eax
f0103e19:	0f 44 c6             	cmove  %esi,%eax
f0103e1c:	51                   	push   %ecx
f0103e1d:	52                   	push   %edx
f0103e1e:	50                   	push   %eax
f0103e1f:	68 fa 71 10 f0       	push   $0xf01071fa
f0103e24:	e8 46 fa ff ff       	call   f010386f <cprintf>
f0103e29:	83 c4 10             	add    $0x10,%esp
f0103e2c:	eb 10                	jmp    f0103e3e <print_trapframe+0xfa>
		        tf->tf_err & 4 ? "user" : "kernel",
		        tf->tf_err & 2 ? "write" : "read",
		        tf->tf_err & 1 ? "protection" : "not-present");
	else
		cprintf("\n");
f0103e2e:	83 ec 0c             	sub    $0xc,%esp
f0103e31:	68 cf 70 10 f0       	push   $0xf01070cf
f0103e36:	e8 34 fa ff ff       	call   f010386f <cprintf>
f0103e3b:	83 c4 10             	add    $0x10,%esp
	cprintf("  eip  0x%08x\n", tf->tf_eip);
f0103e3e:	83 ec 08             	sub    $0x8,%esp
f0103e41:	ff 73 30             	pushl  0x30(%ebx)
f0103e44:	68 09 72 10 f0       	push   $0xf0107209
f0103e49:	e8 21 fa ff ff       	call   f010386f <cprintf>
	cprintf("  cs   0x----%04x\n", tf->tf_cs);
f0103e4e:	83 c4 08             	add    $0x8,%esp
f0103e51:	0f b7 43 34          	movzwl 0x34(%ebx),%eax
f0103e55:	50                   	push   %eax
f0103e56:	68 18 72 10 f0       	push   $0xf0107218
f0103e5b:	e8 0f fa ff ff       	call   f010386f <cprintf>
	cprintf("  flag 0x%08x\n", tf->tf_eflags);
f0103e60:	83 c4 08             	add    $0x8,%esp
f0103e63:	ff 73 38             	pushl  0x38(%ebx)
f0103e66:	68 2b 72 10 f0       	push   $0xf010722b
f0103e6b:	e8 ff f9 ff ff       	call   f010386f <cprintf>
	if ((tf->tf_cs & 3) != 0) {
f0103e70:	83 c4 10             	add    $0x10,%esp
f0103e73:	f6 43 34 03          	testb  $0x3,0x34(%ebx)
f0103e77:	74 25                	je     f0103e9e <print_trapframe+0x15a>
		cprintf("  esp  0x%08x\n", tf->tf_esp);
f0103e79:	83 ec 08             	sub    $0x8,%esp
f0103e7c:	ff 73 3c             	pushl  0x3c(%ebx)
f0103e7f:	68 3a 72 10 f0       	push   $0xf010723a
f0103e84:	e8 e6 f9 ff ff       	call   f010386f <cprintf>
		cprintf("  ss   0x----%04x\n", tf->tf_ss);
f0103e89:	83 c4 08             	add    $0x8,%esp
f0103e8c:	0f b7 43 40          	movzwl 0x40(%ebx),%eax
f0103e90:	50                   	push   %eax
f0103e91:	68 49 72 10 f0       	push   $0xf0107249
f0103e96:	e8 d4 f9 ff ff       	call   f010386f <cprintf>
f0103e9b:	83 c4 10             	add    $0x10,%esp
	}
}
f0103e9e:	8d 65 f8             	lea    -0x8(%ebp),%esp
f0103ea1:	5b                   	pop    %ebx
f0103ea2:	5e                   	pop    %esi
f0103ea3:	5d                   	pop    %ebp
f0103ea4:	c3                   	ret    

f0103ea5 <page_fault_handler>:
}


void
page_fault_handler(struct Trapframe *tf)
{
f0103ea5:	55                   	push   %ebp
f0103ea6:	89 e5                	mov    %esp,%ebp
f0103ea8:	57                   	push   %edi
f0103ea9:	56                   	push   %esi
f0103eaa:	53                   	push   %ebx
f0103eab:	83 ec 0c             	sub    $0xc,%esp
f0103eae:	8b 5d 08             	mov    0x8(%ebp),%ebx
	uint32_t fault_va;

	// Read processor's CR2 register to find the faulting address
	fault_va = rcr2();
f0103eb1:	e8 dd f9 ff ff       	call   f0103893 <rcr2>
f0103eb6:	89 c6                	mov    %eax,%esi

	// Handle kernel-mode page faults.

	// LAB 3: Your code here.
	//MARTIN_TP2_PARTE5
	if (!(tf->tf_cs & 0x3)) { //si CPL==0 es ring0 aka kernel
f0103eb8:	0f b7 43 34          	movzwl 0x34(%ebx),%eax
f0103ebc:	a8 03                	test   $0x3,%al
f0103ebe:	75 18                	jne    f0103ed8 <page_fault_handler+0x33>
		panic("Kernel-mode page fault!!tf_cs=%p",tf->tf_cs);
f0103ec0:	0f b7 c0             	movzwl %ax,%eax
f0103ec3:	50                   	push   %eax
f0103ec4:	68 04 74 10 f0       	push   $0xf0107404
f0103ec9:	68 4c 01 00 00       	push   $0x14c
f0103ece:	68 5c 72 10 f0       	push   $0xf010725c
f0103ed3:	e8 85 c1 ff ff       	call   f010005d <_panic>
	//   (the 'tf' variable points at 'curenv->env_tf').

	// LAB 4: Your code here.

	// Destroy the environment that caused the fault.
	cprintf("[%08x] user fault va %08x ip %08x\n",
f0103ed8:	8b 7b 30             	mov    0x30(%ebx),%edi
	        curenv->env_id,
f0103edb:	e8 2e 17 00 00       	call   f010560e <cpunum>
	//   (the 'tf' variable points at 'curenv->env_tf').

	// LAB 4: Your code here.

	// Destroy the environment that caused the fault.
	cprintf("[%08x] user fault va %08x ip %08x\n",
f0103ee0:	57                   	push   %edi
f0103ee1:	56                   	push   %esi
	        curenv->env_id,
f0103ee2:	6b c0 74             	imul   $0x74,%eax,%eax
	//   (the 'tf' variable points at 'curenv->env_tf').

	// LAB 4: Your code here.

	// Destroy the environment that caused the fault.
	cprintf("[%08x] user fault va %08x ip %08x\n",
f0103ee5:	8b 80 28 70 28 f0    	mov    -0xfd78fd8(%eax),%eax
f0103eeb:	ff 70 48             	pushl  0x48(%eax)
f0103eee:	68 28 74 10 f0       	push   $0xf0107428
f0103ef3:	e8 77 f9 ff ff       	call   f010386f <cprintf>
	        curenv->env_id,
	        fault_va,
	        tf->tf_eip);
	print_trapframe(tf);
f0103ef8:	89 1c 24             	mov    %ebx,(%esp)
f0103efb:	e8 44 fe ff ff       	call   f0103d44 <print_trapframe>
	env_destroy(curenv);
f0103f00:	e8 09 17 00 00       	call   f010560e <cpunum>
f0103f05:	83 c4 04             	add    $0x4,%esp
f0103f08:	6b c0 74             	imul   $0x74,%eax,%eax
f0103f0b:	ff b0 28 70 28 f0    	pushl  -0xfd78fd8(%eax)
f0103f11:	e8 7f f5 ff ff       	call   f0103495 <env_destroy>
}
f0103f16:	83 c4 10             	add    $0x10,%esp
f0103f19:	8d 65 f4             	lea    -0xc(%ebp),%esp
f0103f1c:	5b                   	pop    %ebx
f0103f1d:	5e                   	pop    %esi
f0103f1e:	5f                   	pop    %edi
f0103f1f:	5d                   	pop    %ebp
f0103f20:	c3                   	ret    

f0103f21 <trap_dispatch>:
	cprintf("  eax  0x%08x\n", regs->reg_eax);
}

static void
trap_dispatch(struct Trapframe *tf)
{
f0103f21:	55                   	push   %ebp
f0103f22:	89 e5                	mov    %esp,%ebp
f0103f24:	53                   	push   %ebx
f0103f25:	83 ec 04             	sub    $0x4,%esp
f0103f28:	89 c3                	mov    %eax,%ebx
	// Handle processor exceptions.
	// LAB 3: Your code here.
	if(tf->tf_trapno == T_BRKPT){
f0103f2a:	8b 40 28             	mov    0x28(%eax),%eax
f0103f2d:	83 f8 03             	cmp    $0x3,%eax
f0103f30:	75 11                	jne    f0103f43 <trap_dispatch+0x22>
		monitor(tf);	
f0103f32:	83 ec 0c             	sub    $0xc,%esp
f0103f35:	53                   	push   %ebx
f0103f36:	e8 3b cc ff ff       	call   f0100b76 <monitor>
		return;
f0103f3b:	83 c4 10             	add    $0x10,%esp
f0103f3e:	e9 9e 00 00 00       	jmp    f0103fe1 <trap_dispatch+0xc0>
	}
	if(tf->tf_trapno == T_PGFLT){
f0103f43:	83 f8 0e             	cmp    $0xe,%eax
f0103f46:	75 11                	jne    f0103f59 <trap_dispatch+0x38>
		page_fault_handler(tf);
f0103f48:	83 ec 0c             	sub    $0xc,%esp
f0103f4b:	53                   	push   %ebx
f0103f4c:	e8 54 ff ff ff       	call   f0103ea5 <page_fault_handler>
		return;
f0103f51:	83 c4 10             	add    $0x10,%esp
f0103f54:	e9 88 00 00 00       	jmp    f0103fe1 <trap_dispatch+0xc0>
	}
	if(tf->tf_trapno == T_SYSCALL){
f0103f59:	83 f8 30             	cmp    $0x30,%eax
f0103f5c:	75 21                	jne    f0103f7f <trap_dispatch+0x5e>
		uint32_t resultado = syscall(tf->tf_regs.reg_eax, tf->tf_regs.reg_edx, tf->tf_regs.reg_ecx, tf->tf_regs.reg_ebx, tf->tf_regs.reg_edi, tf->tf_regs.reg_esi);
f0103f5e:	83 ec 08             	sub    $0x8,%esp
f0103f61:	ff 73 04             	pushl  0x4(%ebx)
f0103f64:	ff 33                	pushl  (%ebx)
f0103f66:	ff 73 10             	pushl  0x10(%ebx)
f0103f69:	ff 73 18             	pushl  0x18(%ebx)
f0103f6c:	ff 73 14             	pushl  0x14(%ebx)
f0103f6f:	ff 73 1c             	pushl  0x1c(%ebx)
f0103f72:	e8 4e 04 00 00       	call   f01043c5 <syscall>

		//guardar resultado en eax;
		tf->tf_regs.reg_eax = resultado;
f0103f77:	89 43 1c             	mov    %eax,0x1c(%ebx)
		return;
f0103f7a:	83 c4 20             	add    $0x20,%esp
f0103f7d:	eb 62                	jmp    f0103fe1 <trap_dispatch+0xc0>


	// Handle spurious interrupts
	// The hardware sometimes raises these because of noise on the
	// IRQ line or other reasons. We don't care.
	if (tf->tf_trapno == IRQ_OFFSET + IRQ_SPURIOUS) {
f0103f7f:	83 f8 27             	cmp    $0x27,%eax
f0103f82:	75 1a                	jne    f0103f9e <trap_dispatch+0x7d>
		cprintf("Spurious interrupt on irq 7\n");
f0103f84:	83 ec 0c             	sub    $0xc,%esp
f0103f87:	68 68 72 10 f0       	push   $0xf0107268
f0103f8c:	e8 de f8 ff ff       	call   f010386f <cprintf>
		print_trapframe(tf);
f0103f91:	89 1c 24             	mov    %ebx,(%esp)
f0103f94:	e8 ab fd ff ff       	call   f0103d44 <print_trapframe>
		return;
f0103f99:	83 c4 10             	add    $0x10,%esp
f0103f9c:	eb 43                	jmp    f0103fe1 <trap_dispatch+0xc0>
	// Handle clock interrupts. Don't forget to acknowledge the
	// interrupt using lapic_eoi() before calling the scheduler!
	// LAB 4: Your code here.

	// Unexpected trap: The user process or the kernel has a bug.
	print_trapframe(tf);
f0103f9e:	83 ec 0c             	sub    $0xc,%esp
f0103fa1:	53                   	push   %ebx
f0103fa2:	e8 9d fd ff ff       	call   f0103d44 <print_trapframe>
	if (tf->tf_cs == GD_KT)
f0103fa7:	83 c4 10             	add    $0x10,%esp
f0103faa:	66 83 7b 34 08       	cmpw   $0x8,0x34(%ebx)
f0103faf:	75 17                	jne    f0103fc8 <trap_dispatch+0xa7>
		panic("unhandled trap in kernel");
f0103fb1:	83 ec 04             	sub    $0x4,%esp
f0103fb4:	68 85 72 10 f0       	push   $0xf0107285
f0103fb9:	68 fc 00 00 00       	push   $0xfc
f0103fbe:	68 5c 72 10 f0       	push   $0xf010725c
f0103fc3:	e8 95 c0 ff ff       	call   f010005d <_panic>
	else {
		env_destroy(curenv);
f0103fc8:	e8 41 16 00 00       	call   f010560e <cpunum>
f0103fcd:	83 ec 0c             	sub    $0xc,%esp
f0103fd0:	6b c0 74             	imul   $0x74,%eax,%eax
f0103fd3:	ff b0 28 70 28 f0    	pushl  -0xfd78fd8(%eax)
f0103fd9:	e8 b7 f4 ff ff       	call   f0103495 <env_destroy>
		return;
f0103fde:	83 c4 10             	add    $0x10,%esp
	}
}
f0103fe1:	8b 5d fc             	mov    -0x4(%ebp),%ebx
f0103fe4:	c9                   	leave  
f0103fe5:	c3                   	ret    

f0103fe6 <trap>:

void
trap(struct Trapframe *tf)
{
f0103fe6:	55                   	push   %ebp
f0103fe7:	89 e5                	mov    %esp,%ebp
f0103fe9:	57                   	push   %edi
f0103fea:	56                   	push   %esi
f0103feb:	8b 75 08             	mov    0x8(%ebp),%esi
	// The environment may have set DF and some versions
	// of GCC rely on DF being clear
	asm volatile("cld" ::: "cc");
f0103fee:	fc                   	cld    

	// Halt the CPU if some other CPU has called panic()
	extern char *panicstr;
	if (panicstr)
f0103fef:	83 3d 00 6f 28 f0 00 	cmpl   $0x0,0xf0286f00
f0103ff6:	74 01                	je     f0103ff9 <trap+0x13>
		asm volatile("hlt");
f0103ff8:	f4                   	hlt    

	// Re-acquire the big kernel lock if we were halted in
	// sched_yield()
	if (xchg(&thiscpu->cpu_status, CPU_STARTED) == CPU_HALTED)
f0103ff9:	e8 10 16 00 00       	call   f010560e <cpunum>
f0103ffe:	6b c0 74             	imul   $0x74,%eax,%eax
f0104001:	05 24 70 28 f0       	add    $0xf0287024,%eax
f0104006:	ba 01 00 00 00       	mov    $0x1,%edx
f010400b:	e8 92 f8 ff ff       	call   f01038a2 <xchg>
f0104010:	83 f8 02             	cmp    $0x2,%eax
f0104013:	75 05                	jne    f010401a <trap+0x34>
		lock_kernel();
f0104015:	e8 c6 f8 ff ff       	call   f01038e0 <lock_kernel>
	// Check that interrupts are disabled.  If this assertion
	// fails, DO NOT be tempted to fix it by inserting a "cli" in
	// the interrupt path.
	assert(!(read_eflags() & FL_IF));
f010401a:	e8 7c f8 ff ff       	call   f010389b <read_eflags>
f010401f:	f6 c4 02             	test   $0x2,%ah
f0104022:	74 19                	je     f010403d <trap+0x57>
f0104024:	68 9e 72 10 f0       	push   $0xf010729e
f0104029:	68 de 6b 10 f0       	push   $0xf0106bde
f010402e:	68 16 01 00 00       	push   $0x116
f0104033:	68 5c 72 10 f0       	push   $0xf010725c
f0104038:	e8 20 c0 ff ff       	call   f010005d <_panic>

	if ((tf->tf_cs & 3) == 3) {
f010403d:	0f b7 46 34          	movzwl 0x34(%esi),%eax
f0104041:	83 e0 03             	and    $0x3,%eax
f0104044:	66 83 f8 03          	cmp    $0x3,%ax
f0104048:	0f 85 90 00 00 00    	jne    f01040de <trap+0xf8>
		// Trapped from user mode.
		// Acquire the big kernel lock before doing any
		// serious kernel work.
		// LAB 4: Your code here.
		assert(curenv);
f010404e:	e8 bb 15 00 00       	call   f010560e <cpunum>
f0104053:	6b c0 74             	imul   $0x74,%eax,%eax
f0104056:	83 b8 28 70 28 f0 00 	cmpl   $0x0,-0xfd78fd8(%eax)
f010405d:	75 19                	jne    f0104078 <trap+0x92>
f010405f:	68 b7 72 10 f0       	push   $0xf01072b7
f0104064:	68 de 6b 10 f0       	push   $0xf0106bde
f0104069:	68 1d 01 00 00       	push   $0x11d
f010406e:	68 5c 72 10 f0       	push   $0xf010725c
f0104073:	e8 e5 bf ff ff       	call   f010005d <_panic>

		// Garbage collect if current enviroment is a zombie
		if (curenv->env_status == ENV_DYING) {
f0104078:	e8 91 15 00 00       	call   f010560e <cpunum>
f010407d:	6b c0 74             	imul   $0x74,%eax,%eax
f0104080:	8b 80 28 70 28 f0    	mov    -0xfd78fd8(%eax),%eax
f0104086:	83 78 54 01          	cmpl   $0x1,0x54(%eax)
f010408a:	75 2d                	jne    f01040b9 <trap+0xd3>
			env_free(curenv);
f010408c:	e8 7d 15 00 00       	call   f010560e <cpunum>
f0104091:	83 ec 0c             	sub    $0xc,%esp
f0104094:	6b c0 74             	imul   $0x74,%eax,%eax
f0104097:	ff b0 28 70 28 f0    	pushl  -0xfd78fd8(%eax)
f010409d:	e8 9a f2 ff ff       	call   f010333c <env_free>
			curenv = NULL;
f01040a2:	e8 67 15 00 00       	call   f010560e <cpunum>
f01040a7:	6b c0 74             	imul   $0x74,%eax,%eax
f01040aa:	c7 80 28 70 28 f0 00 	movl   $0x0,-0xfd78fd8(%eax)
f01040b1:	00 00 00 
			sched_yield();
f01040b4:	e8 f0 01 00 00       	call   f01042a9 <sched_yield>
		}

		// Copy trap frame (which is currently on the stack)
		// into 'curenv->env_tf', so that running the environment
		// will restart at the trap point.
		curenv->env_tf = *tf;
f01040b9:	e8 50 15 00 00       	call   f010560e <cpunum>
f01040be:	6b c0 74             	imul   $0x74,%eax,%eax
f01040c1:	8b 80 28 70 28 f0    	mov    -0xfd78fd8(%eax),%eax
f01040c7:	b9 11 00 00 00       	mov    $0x11,%ecx
f01040cc:	89 c7                	mov    %eax,%edi
f01040ce:	f3 a5                	rep movsl %ds:(%esi),%es:(%edi)
		// The trapframe on the stack should be ignored from here on.
		tf = &curenv->env_tf;
f01040d0:	e8 39 15 00 00       	call   f010560e <cpunum>
f01040d5:	6b c0 74             	imul   $0x74,%eax,%eax
f01040d8:	8b b0 28 70 28 f0    	mov    -0xfd78fd8(%eax),%esi
	}

	// Record that tf is the last real trapframe so
	// print_trapframe can print some additional information.
	last_tf = tf;
f01040de:	89 35 60 5a 28 f0    	mov    %esi,0xf0285a60

	// Dispatch based on what type of trap occurred
	trap_dispatch(tf);
f01040e4:	89 f0                	mov    %esi,%eax
f01040e6:	e8 36 fe ff ff       	call   f0103f21 <trap_dispatch>

	// If we made it to this point, then no other environment was
	// scheduled, so we should return to the current environment
	// if doing so makes sense.
	if (curenv && curenv->env_status == ENV_RUNNING)
f01040eb:	e8 1e 15 00 00       	call   f010560e <cpunum>
f01040f0:	6b c0 74             	imul   $0x74,%eax,%eax
f01040f3:	83 b8 28 70 28 f0 00 	cmpl   $0x0,-0xfd78fd8(%eax)
f01040fa:	74 2a                	je     f0104126 <trap+0x140>
f01040fc:	e8 0d 15 00 00       	call   f010560e <cpunum>
f0104101:	6b c0 74             	imul   $0x74,%eax,%eax
f0104104:	8b 80 28 70 28 f0    	mov    -0xfd78fd8(%eax),%eax
f010410a:	83 78 54 03          	cmpl   $0x3,0x54(%eax)
f010410e:	75 16                	jne    f0104126 <trap+0x140>
		env_run(curenv);
f0104110:	e8 f9 14 00 00       	call   f010560e <cpunum>
f0104115:	83 ec 0c             	sub    $0xc,%esp
f0104118:	6b c0 74             	imul   $0x74,%eax,%eax
f010411b:	ff b0 28 70 28 f0    	pushl  -0xfd78fd8(%eax)
f0104121:	e8 0e f4 ff ff       	call   f0103534 <env_run>
	else
		sched_yield();
f0104126:	e8 7e 01 00 00       	call   f01042a9 <sched_yield>
f010412b:	90                   	nop

f010412c <Trap_0>:
.text

/*
 * Lab 3: Your code here for generating entry points for the different traps.
 */
TRAPHANDLER_NOEC(Trap_0, T_DIVIDE)
f010412c:	6a 00                	push   $0x0
f010412e:	6a 00                	push   $0x0
f0104130:	eb 5e                	jmp    f0104190 <_alltraps>

f0104132 <Trap_1>:
TRAPHANDLER_NOEC(Trap_1, T_DEBUG)
f0104132:	6a 00                	push   $0x0
f0104134:	6a 01                	push   $0x1
f0104136:	eb 58                	jmp    f0104190 <_alltraps>

f0104138 <Trap_2>:
TRAPHANDLER_NOEC(Trap_2, T_NMI)
f0104138:	6a 00                	push   $0x0
f010413a:	6a 02                	push   $0x2
f010413c:	eb 52                	jmp    f0104190 <_alltraps>

f010413e <Trap_3>:
TRAPHANDLER_NOEC(Trap_3, T_BRKPT)
f010413e:	6a 00                	push   $0x0
f0104140:	6a 03                	push   $0x3
f0104142:	eb 4c                	jmp    f0104190 <_alltraps>

f0104144 <Trap_4>:
TRAPHANDLER_NOEC(Trap_4, T_OFLOW)
f0104144:	6a 00                	push   $0x0
f0104146:	6a 04                	push   $0x4
f0104148:	eb 46                	jmp    f0104190 <_alltraps>

f010414a <Trap_5>:
TRAPHANDLER_NOEC(Trap_5, T_BOUND)
f010414a:	6a 00                	push   $0x0
f010414c:	6a 05                	push   $0x5
f010414e:	eb 40                	jmp    f0104190 <_alltraps>

f0104150 <Trap_6>:
TRAPHANDLER_NOEC(Trap_6, T_ILLOP)
f0104150:	6a 00                	push   $0x0
f0104152:	6a 06                	push   $0x6
f0104154:	eb 3a                	jmp    f0104190 <_alltraps>

f0104156 <Trap_7>:
TRAPHANDLER_NOEC(Trap_7, T_DEVICE)
f0104156:	6a 00                	push   $0x0
f0104158:	6a 07                	push   $0x7
f010415a:	eb 34                	jmp    f0104190 <_alltraps>

f010415c <Trap_8>:
TRAPHANDLER(Trap_8, T_DBLFLT)
f010415c:	6a 08                	push   $0x8
f010415e:	eb 30                	jmp    f0104190 <_alltraps>

f0104160 <Trap_10>:
TRAPHANDLER(Trap_10, T_TSS)
f0104160:	6a 0a                	push   $0xa
f0104162:	eb 2c                	jmp    f0104190 <_alltraps>

f0104164 <Trap_11>:
TRAPHANDLER(Trap_11, T_SEGNP)
f0104164:	6a 0b                	push   $0xb
f0104166:	eb 28                	jmp    f0104190 <_alltraps>

f0104168 <Trap_12>:
TRAPHANDLER(Trap_12, T_STACK)
f0104168:	6a 0c                	push   $0xc
f010416a:	eb 24                	jmp    f0104190 <_alltraps>

f010416c <Trap_13>:
TRAPHANDLER(Trap_13, T_GPFLT)
f010416c:	6a 0d                	push   $0xd
f010416e:	eb 20                	jmp    f0104190 <_alltraps>

f0104170 <Trap_14>:
TRAPHANDLER(Trap_14, T_PGFLT)
f0104170:	6a 0e                	push   $0xe
f0104172:	eb 1c                	jmp    f0104190 <_alltraps>

f0104174 <Trap_16>:
TRAPHANDLER_NOEC(Trap_16, T_FPERR)
f0104174:	6a 00                	push   $0x0
f0104176:	6a 10                	push   $0x10
f0104178:	eb 16                	jmp    f0104190 <_alltraps>

f010417a <Trap_17>:
TRAPHANDLER(Trap_17, T_ALIGN)
f010417a:	6a 11                	push   $0x11
f010417c:	eb 12                	jmp    f0104190 <_alltraps>

f010417e <Trap_18>:
TRAPHANDLER_NOEC(Trap_18, T_MCHK)
f010417e:	6a 00                	push   $0x0
f0104180:	6a 12                	push   $0x12
f0104182:	eb 0c                	jmp    f0104190 <_alltraps>

f0104184 <Trap_19>:
TRAPHANDLER_NOEC(Trap_19, T_SIMDERR)
f0104184:	6a 00                	push   $0x0
f0104186:	6a 13                	push   $0x13
f0104188:	eb 06                	jmp    f0104190 <_alltraps>

f010418a <Trap_48>:
TRAPHANDLER_NOEC(Trap_48, T_SYSCALL)
f010418a:	6a 00                	push   $0x0
f010418c:	6a 30                	push   $0x30
f010418e:	eb 00                	jmp    f0104190 <_alltraps>

f0104190 <_alltraps>:
/*
 * Lab 3: Your code here for _alltraps
 */

_alltraps:
	pushl %ds
f0104190:	1e                   	push   %ds
    pushl %es
f0104191:	06                   	push   %es
	pushal
f0104192:	60                   	pusha  

	movw $GD_KD, %ax
f0104193:	66 b8 10 00          	mov    $0x10,%ax
	movw %ax, %ds
f0104197:	8e d8                	mov    %eax,%ds
	movw %ax, %es 
f0104199:	8e c0                	mov    %eax,%es

    pushl %esp
f010419b:	54                   	push   %esp
    call trap	
f010419c:	e8 45 fe ff ff       	call   f0103fe6 <trap>

f01041a1 <lcr3>:
	return val;
}

static inline void
lcr3(uint32_t val)
{
f01041a1:	55                   	push   %ebp
f01041a2:	89 e5                	mov    %esp,%ebp
	asm volatile("movl %0,%%cr3" : : "r" (val));
f01041a4:	0f 22 d8             	mov    %eax,%cr3
}
f01041a7:	5d                   	pop    %ebp
f01041a8:	c3                   	ret    

f01041a9 <xchg>:
	return tsc;
}

static inline uint32_t
xchg(volatile uint32_t *addr, uint32_t newval)
{
f01041a9:	55                   	push   %ebp
f01041aa:	89 e5                	mov    %esp,%ebp
f01041ac:	89 c1                	mov    %eax,%ecx
	uint32_t result;

	// The + in "+m" denotes a read-modify-write operand.
	asm volatile("lock; xchgl %0, %1"
f01041ae:	89 d0                	mov    %edx,%eax
f01041b0:	f0 87 01             	lock xchg %eax,(%ecx)
		     : "+m" (*addr), "=a" (result)
		     : "1" (newval)
		     : "cc");
	return result;
}
f01041b3:	5d                   	pop    %ebp
f01041b4:	c3                   	ret    

f01041b5 <_paddr>:
#define PADDR(kva) _paddr(__FILE__, __LINE__, kva)

static inline physaddr_t
_paddr(const char *file, int line, void *kva)
{
	if ((uint32_t)kva < KERNBASE)
f01041b5:	81 f9 ff ff ff ef    	cmp    $0xefffffff,%ecx
f01041bb:	77 13                	ja     f01041d0 <_paddr+0x1b>
 */
#define PADDR(kva) _paddr(__FILE__, __LINE__, kva)

static inline physaddr_t
_paddr(const char *file, int line, void *kva)
{
f01041bd:	55                   	push   %ebp
f01041be:	89 e5                	mov    %esp,%ebp
f01041c0:	83 ec 08             	sub    $0x8,%esp
	if ((uint32_t)kva < KERNBASE)
		_panic(file, line, "PADDR called with invalid kva %08lx", kva);
f01041c3:	51                   	push   %ecx
f01041c4:	68 10 5d 10 f0       	push   $0xf0105d10
f01041c9:	52                   	push   %edx
f01041ca:	50                   	push   %eax
f01041cb:	e8 8d be ff ff       	call   f010005d <_panic>
	return (physaddr_t)kva - KERNBASE;
f01041d0:	8d 81 00 00 00 10    	lea    0x10000000(%ecx),%eax
}
f01041d6:	c3                   	ret    

f01041d7 <unlock_kernel>:

static inline void
unlock_kernel(void)
{
f01041d7:	55                   	push   %ebp
f01041d8:	89 e5                	mov    %esp,%ebp
f01041da:	83 ec 14             	sub    $0x14,%esp
	spin_unlock(&kernel_lock);
f01041dd:	68 20 14 11 f0       	push   $0xf0111420
f01041e2:	e8 5f 17 00 00       	call   f0105946 <spin_unlock>

	// Normally we wouldn't need to do this, but QEMU only runs
	// one CPU at a time and has a long time-slice.  Without the
	// pause, this CPU is likely to reacquire the lock before
	// another CPU has even been given a chance to acquire it.
	asm volatile("pause");
f01041e7:	f3 90                	pause  
}
f01041e9:	83 c4 10             	add    $0x10,%esp
f01041ec:	c9                   	leave  
f01041ed:	c3                   	ret    

f01041ee <sched_halt>:
// Halt this CPU when there is nothing to do. Wait until the
// timer interrupt wakes it up. This function never returns.
//
void
sched_halt(void)
{
f01041ee:	55                   	push   %ebp
f01041ef:	89 e5                	mov    %esp,%ebp
f01041f1:	83 ec 08             	sub    $0x8,%esp
f01041f4:	a1 44 52 28 f0       	mov    0xf0285244,%eax
f01041f9:	8d 50 54             	lea    0x54(%eax),%edx
	int i;

	// For debugging and testing purposes, if there are no runnable
	// environments in the system, then drop into the kernel monitor.
	for (i = 0; i < NENV; i++) {
f01041fc:	b9 00 00 00 00       	mov    $0x0,%ecx
		if ((envs[i].env_status == ENV_RUNNABLE ||
f0104201:	8b 02                	mov    (%edx),%eax
f0104203:	83 e8 01             	sub    $0x1,%eax
f0104206:	83 f8 02             	cmp    $0x2,%eax
f0104209:	76 10                	jbe    f010421b <sched_halt+0x2d>
{
	int i;

	// For debugging and testing purposes, if there are no runnable
	// environments in the system, then drop into the kernel monitor.
	for (i = 0; i < NENV; i++) {
f010420b:	83 c1 01             	add    $0x1,%ecx
f010420e:	83 c2 7c             	add    $0x7c,%edx
f0104211:	81 f9 00 04 00 00    	cmp    $0x400,%ecx
f0104217:	75 e8                	jne    f0104201 <sched_halt+0x13>
f0104219:	eb 08                	jmp    f0104223 <sched_halt+0x35>
		if ((envs[i].env_status == ENV_RUNNABLE ||
		     envs[i].env_status == ENV_RUNNING ||
		     envs[i].env_status == ENV_DYING))
			break;
	}
	if (i == NENV) {
f010421b:	81 f9 00 04 00 00    	cmp    $0x400,%ecx
f0104221:	75 1f                	jne    f0104242 <sched_halt+0x54>
		cprintf("No runnable environments in the system!\n");
f0104223:	83 ec 0c             	sub    $0xc,%esp
f0104226:	68 b0 74 10 f0       	push   $0xf01074b0
f010422b:	e8 3f f6 ff ff       	call   f010386f <cprintf>
f0104230:	83 c4 10             	add    $0x10,%esp
		while (1)
			monitor(NULL);
f0104233:	83 ec 0c             	sub    $0xc,%esp
f0104236:	6a 00                	push   $0x0
f0104238:	e8 39 c9 ff ff       	call   f0100b76 <monitor>
f010423d:	83 c4 10             	add    $0x10,%esp
f0104240:	eb f1                	jmp    f0104233 <sched_halt+0x45>
	}

	// Mark that no environment is running on this CPU
	curenv = NULL;
f0104242:	e8 c7 13 00 00       	call   f010560e <cpunum>
f0104247:	6b c0 74             	imul   $0x74,%eax,%eax
f010424a:	c7 80 28 70 28 f0 00 	movl   $0x0,-0xfd78fd8(%eax)
f0104251:	00 00 00 
	lcr3(PADDR(kern_pgdir));
f0104254:	8b 0d 0c 6f 28 f0    	mov    0xf0286f0c,%ecx
f010425a:	ba 3d 00 00 00       	mov    $0x3d,%edx
f010425f:	b8 d9 74 10 f0       	mov    $0xf01074d9,%eax
f0104264:	e8 4c ff ff ff       	call   f01041b5 <_paddr>
f0104269:	e8 33 ff ff ff       	call   f01041a1 <lcr3>

	// Mark that this CPU is in the HALT state, so that when
	// timer interupts come in, we know we should re-acquire the
	// big kernel lock
	xchg(&thiscpu->cpu_status, CPU_HALTED);
f010426e:	e8 9b 13 00 00       	call   f010560e <cpunum>
f0104273:	6b c0 74             	imul   $0x74,%eax,%eax
f0104276:	05 24 70 28 f0       	add    $0xf0287024,%eax
f010427b:	ba 02 00 00 00       	mov    $0x2,%edx
f0104280:	e8 24 ff ff ff       	call   f01041a9 <xchg>

	// Release the big kernel lock as if we were "leaving" the kernel
	unlock_kernel();
f0104285:	e8 4d ff ff ff       	call   f01041d7 <unlock_kernel>
	             "sti\n"
	             "1:\n"
	             "hlt\n"
	             "jmp 1b\n"
	             :
	             : "a"(thiscpu->cpu_ts.ts_esp0));
f010428a:	e8 7f 13 00 00       	call   f010560e <cpunum>
f010428f:	6b c0 74             	imul   $0x74,%eax,%eax

	// Release the big kernel lock as if we were "leaving" the kernel
	unlock_kernel();

	// Reset stack pointer, enable interrupts and then halt.
	asm volatile("movl $0, %%ebp\n"
f0104292:	8b 80 30 70 28 f0    	mov    -0xfd78fd0(%eax),%eax
f0104298:	bd 00 00 00 00       	mov    $0x0,%ebp
f010429d:	89 c4                	mov    %eax,%esp
f010429f:	6a 00                	push   $0x0
f01042a1:	6a 00                	push   $0x0
f01042a3:	fb                   	sti    
f01042a4:	f4                   	hlt    
f01042a5:	eb fd                	jmp    f01042a4 <sched_halt+0xb6>
	             "1:\n"
	             "hlt\n"
	             "jmp 1b\n"
	             :
	             : "a"(thiscpu->cpu_ts.ts_esp0));
}
f01042a7:	c9                   	leave  
f01042a8:	c3                   	ret    

f01042a9 <sched_yield>:
void sched_halt(void);

// Choose a user environment to run and run it.
void
sched_yield(void)
{
f01042a9:	55                   	push   %ebp
f01042aa:	89 e5                	mov    %esp,%ebp
f01042ac:	83 ec 08             	sub    $0x8,%esp
	// below to halt the cpu.

	// LAB 4: Your code here.

	// sched_halt never returns
	sched_halt();
f01042af:	e8 3a ff ff ff       	call   f01041ee <sched_halt>
}
f01042b4:	c9                   	leave  
f01042b5:	c3                   	ret    

f01042b6 <sys_getenvid>:
}

// Returns the current environment's envid.
static envid_t
sys_getenvid(void)
{
f01042b6:	55                   	push   %ebp
f01042b7:	89 e5                	mov    %esp,%ebp
f01042b9:	83 ec 14             	sub    $0x14,%esp
	cprintf("Entre a f3()\n");
f01042bc:	68 e6 74 10 f0       	push   $0xf01074e6
f01042c1:	e8 a9 f5 ff ff       	call   f010386f <cprintf>
	return curenv->env_id;
f01042c6:	e8 43 13 00 00       	call   f010560e <cpunum>
f01042cb:	6b c0 74             	imul   $0x74,%eax,%eax
f01042ce:	8b 80 28 70 28 f0    	mov    -0xfd78fd8(%eax),%eax
f01042d4:	8b 40 48             	mov    0x48(%eax),%eax
}
f01042d7:	c9                   	leave  
f01042d8:	c3                   	ret    

f01042d9 <sys_cputs>:
// Print a string to the system console.
// The string is exactly 'len' characters long.
// Destroys the environment on memory errors.
static void
sys_cputs(const char *s, size_t len)
{
f01042d9:	55                   	push   %ebp
f01042da:	89 e5                	mov    %esp,%ebp
f01042dc:	56                   	push   %esi
f01042dd:	53                   	push   %ebx
f01042de:	89 c6                	mov    %eax,%esi
f01042e0:	89 d3                	mov    %edx,%ebx
	// Check that the user has permission to read memory [s, s+len).
	// Destroy the environment if not.

	// LAB 3: Your code here.
	//MARTIN_TP2_PARTE
	user_mem_assert(curenv,s,len,0);
f01042e2:	e8 27 13 00 00       	call   f010560e <cpunum>
f01042e7:	6a 00                	push   $0x0
f01042e9:	53                   	push   %ebx
f01042ea:	56                   	push   %esi
f01042eb:	6b c0 74             	imul   $0x74,%eax,%eax
f01042ee:	ff b0 28 70 28 f0    	pushl  -0xfd78fd8(%eax)
f01042f4:	e8 52 ea ff ff       	call   f0102d4b <user_mem_assert>
	

	// Print the string supplied by the user.
	cprintf("%.*s", len, s);
f01042f9:	83 c4 0c             	add    $0xc,%esp
f01042fc:	56                   	push   %esi
f01042fd:	53                   	push   %ebx
f01042fe:	68 f4 74 10 f0       	push   $0xf01074f4
f0104303:	e8 67 f5 ff ff       	call   f010386f <cprintf>
}
f0104308:	83 c4 10             	add    $0x10,%esp
f010430b:	8d 65 f8             	lea    -0x8(%ebp),%esp
f010430e:	5b                   	pop    %ebx
f010430f:	5e                   	pop    %esi
f0104310:	5d                   	pop    %ebp
f0104311:	c3                   	ret    

f0104312 <sys_cgetc>:

// Read a character from the system console without blocking.
// Returns the character, or 0 if there is no input waiting.
static int
sys_cgetc(void)
{
f0104312:	55                   	push   %ebp
f0104313:	89 e5                	mov    %esp,%ebp
f0104315:	83 ec 14             	sub    $0x14,%esp
	cprintf("Entre a f2()\n");
f0104318:	68 f9 74 10 f0       	push   $0xf01074f9
f010431d:	e8 4d f5 ff ff       	call   f010386f <cprintf>
	return cons_getc();
f0104322:	e8 32 c5 ff ff       	call   f0100859 <cons_getc>
}
f0104327:	c9                   	leave  
f0104328:	c3                   	ret    

f0104329 <sys_env_destroy>:
// Returns 0 on success, < 0 on error.  Errors are:
//	-E_BAD_ENV if environment envid doesn't currently exist,
//		or the caller doesn't have permission to change envid.
static int
sys_env_destroy(envid_t envid)
{
f0104329:	55                   	push   %ebp
f010432a:	89 e5                	mov    %esp,%ebp
f010432c:	53                   	push   %ebx
f010432d:	83 ec 20             	sub    $0x20,%esp
f0104330:	89 c3                	mov    %eax,%ebx
	cprintf("Entre a f4()\n");
f0104332:	68 07 75 10 f0       	push   $0xf0107507
f0104337:	e8 33 f5 ff ff       	call   f010386f <cprintf>
	int r;
	struct Env *e;

	if ((r = envid2env(envid, &e, 1)) < 0)
f010433c:	83 c4 0c             	add    $0xc,%esp
f010433f:	6a 01                	push   $0x1
f0104341:	8d 45 f4             	lea    -0xc(%ebp),%eax
f0104344:	50                   	push   %eax
f0104345:	53                   	push   %ebx
f0104346:	e8 90 ed ff ff       	call   f01030db <envid2env>
f010434b:	83 c4 10             	add    $0x10,%esp
f010434e:	85 c0                	test   %eax,%eax
f0104350:	78 6e                	js     f01043c0 <sys_env_destroy+0x97>
		return r;
	if (e == curenv)
f0104352:	e8 b7 12 00 00       	call   f010560e <cpunum>
f0104357:	8b 55 f4             	mov    -0xc(%ebp),%edx
f010435a:	6b c0 74             	imul   $0x74,%eax,%eax
f010435d:	39 90 28 70 28 f0    	cmp    %edx,-0xfd78fd8(%eax)
f0104363:	75 23                	jne    f0104388 <sys_env_destroy+0x5f>
		cprintf("[%08x] exiting gracefully\n", curenv->env_id);
f0104365:	e8 a4 12 00 00       	call   f010560e <cpunum>
f010436a:	83 ec 08             	sub    $0x8,%esp
f010436d:	6b c0 74             	imul   $0x74,%eax,%eax
f0104370:	8b 80 28 70 28 f0    	mov    -0xfd78fd8(%eax),%eax
f0104376:	ff 70 48             	pushl  0x48(%eax)
f0104379:	68 15 75 10 f0       	push   $0xf0107515
f010437e:	e8 ec f4 ff ff       	call   f010386f <cprintf>
f0104383:	83 c4 10             	add    $0x10,%esp
f0104386:	eb 25                	jmp    f01043ad <sys_env_destroy+0x84>
	else
		cprintf("[%08x] destroying %08x\n", curenv->env_id, e->env_id);
f0104388:	8b 5a 48             	mov    0x48(%edx),%ebx
f010438b:	e8 7e 12 00 00       	call   f010560e <cpunum>
f0104390:	83 ec 04             	sub    $0x4,%esp
f0104393:	53                   	push   %ebx
f0104394:	6b c0 74             	imul   $0x74,%eax,%eax
f0104397:	8b 80 28 70 28 f0    	mov    -0xfd78fd8(%eax),%eax
f010439d:	ff 70 48             	pushl  0x48(%eax)
f01043a0:	68 30 75 10 f0       	push   $0xf0107530
f01043a5:	e8 c5 f4 ff ff       	call   f010386f <cprintf>
f01043aa:	83 c4 10             	add    $0x10,%esp
	env_destroy(e);
f01043ad:	83 ec 0c             	sub    $0xc,%esp
f01043b0:	ff 75 f4             	pushl  -0xc(%ebp)
f01043b3:	e8 dd f0 ff ff       	call   f0103495 <env_destroy>
	return 0;
f01043b8:	83 c4 10             	add    $0x10,%esp
f01043bb:	b8 00 00 00 00       	mov    $0x0,%eax
}
f01043c0:	8b 5d fc             	mov    -0x4(%ebp),%ebx
f01043c3:	c9                   	leave  
f01043c4:	c3                   	ret    

f01043c5 <syscall>:
}

// Dispatches to the correct kernel function, passing the arguments.
int32_t
syscall(uint32_t syscallno, uint32_t a1, uint32_t a2, uint32_t a3, uint32_t a4, uint32_t a5)
{
f01043c5:	55                   	push   %ebp
f01043c6:	89 e5                	mov    %esp,%ebp
f01043c8:	53                   	push   %ebx
f01043c9:	83 ec 10             	sub    $0x10,%esp
f01043cc:	8b 5d 08             	mov    0x8(%ebp),%ebx
	// Call the function corresponding to the 'syscallno' parameter.
	// Return any appropriate return value.
	// LAB 3: Your code here.

	//panic("syscall not implemented");
	cprintf("Entre a syscall()\n");
f01043cf:	68 48 75 10 f0       	push   $0xf0107548
f01043d4:	e8 96 f4 ff ff       	call   f010386f <cprintf>
	switch (syscallno) {
f01043d9:	83 c4 10             	add    $0x10,%esp
f01043dc:	83 fb 01             	cmp    $0x1,%ebx
f01043df:	74 23                	je     f0104404 <syscall+0x3f>
f01043e1:	83 fb 01             	cmp    $0x1,%ebx
f01043e4:	72 0c                	jb     f01043f2 <syscall+0x2d>
f01043e6:	83 fb 02             	cmp    $0x2,%ebx
f01043e9:	74 20                	je     f010440b <syscall+0x46>
f01043eb:	83 fb 03             	cmp    $0x3,%ebx
f01043ee:	74 22                	je     f0104412 <syscall+0x4d>
f01043f0:	eb 2a                	jmp    f010441c <syscall+0x57>
	case SYS_cputs:
		sys_cputs((char *)a1, a2);
f01043f2:	8b 55 10             	mov    0x10(%ebp),%edx
f01043f5:	8b 45 0c             	mov    0xc(%ebp),%eax
f01043f8:	e8 dc fe ff ff       	call   f01042d9 <sys_cputs>
		return 0;
f01043fd:	b8 00 00 00 00       	mov    $0x0,%eax
f0104402:	eb 1d                	jmp    f0104421 <syscall+0x5c>
	case SYS_cgetc:
		return sys_cgetc();
f0104404:	e8 09 ff ff ff       	call   f0104312 <sys_cgetc>
f0104409:	eb 16                	jmp    f0104421 <syscall+0x5c>
	case SYS_getenvid:
		return sys_getenvid();
f010440b:	e8 a6 fe ff ff       	call   f01042b6 <sys_getenvid>
f0104410:	eb 0f                	jmp    f0104421 <syscall+0x5c>
	case SYS_env_destroy:
		return sys_env_destroy(a1);
f0104412:	8b 45 0c             	mov    0xc(%ebp),%eax
f0104415:	e8 0f ff ff ff       	call   f0104329 <sys_env_destroy>
f010441a:	eb 05                	jmp    f0104421 <syscall+0x5c>
	default:
		return -E_INVAL;
f010441c:	b8 fd ff ff ff       	mov    $0xfffffffd,%eax
	}
}
f0104421:	8b 5d fc             	mov    -0x4(%ebp),%ebx
f0104424:	c9                   	leave  
f0104425:	c3                   	ret    

f0104426 <stab_binsearch>:
stab_binsearch(const struct Stab *stabs,
               int *region_left,
               int *region_right,
               int type,
               uintptr_t addr)
{
f0104426:	55                   	push   %ebp
f0104427:	89 e5                	mov    %esp,%ebp
f0104429:	57                   	push   %edi
f010442a:	56                   	push   %esi
f010442b:	53                   	push   %ebx
f010442c:	83 ec 14             	sub    $0x14,%esp
f010442f:	89 45 ec             	mov    %eax,-0x14(%ebp)
f0104432:	89 55 e4             	mov    %edx,-0x1c(%ebp)
f0104435:	89 4d e0             	mov    %ecx,-0x20(%ebp)
f0104438:	8b 7d 08             	mov    0x8(%ebp),%edi
	int l = *region_left, r = *region_right, any_matches = 0;
f010443b:	8b 1a                	mov    (%edx),%ebx
f010443d:	8b 01                	mov    (%ecx),%eax
f010443f:	89 45 f0             	mov    %eax,-0x10(%ebp)
f0104442:	c7 45 e8 00 00 00 00 	movl   $0x0,-0x18(%ebp)

	while (l <= r) {
f0104449:	eb 7f                	jmp    f01044ca <stab_binsearch+0xa4>
		int true_m = (l + r) / 2, m = true_m;
f010444b:	8b 45 f0             	mov    -0x10(%ebp),%eax
f010444e:	01 d8                	add    %ebx,%eax
f0104450:	89 c6                	mov    %eax,%esi
f0104452:	c1 ee 1f             	shr    $0x1f,%esi
f0104455:	01 c6                	add    %eax,%esi
f0104457:	d1 fe                	sar    %esi
f0104459:	8d 04 76             	lea    (%esi,%esi,2),%eax
f010445c:	8b 4d ec             	mov    -0x14(%ebp),%ecx
f010445f:	8d 14 81             	lea    (%ecx,%eax,4),%edx
f0104462:	89 f0                	mov    %esi,%eax

		// search for earliest stab with right type
		while (m >= l && stabs[m].n_type != type)
f0104464:	eb 03                	jmp    f0104469 <stab_binsearch+0x43>
			m--;
f0104466:	83 e8 01             	sub    $0x1,%eax

	while (l <= r) {
		int true_m = (l + r) / 2, m = true_m;

		// search for earliest stab with right type
		while (m >= l && stabs[m].n_type != type)
f0104469:	39 c3                	cmp    %eax,%ebx
f010446b:	7f 0d                	jg     f010447a <stab_binsearch+0x54>
f010446d:	0f b6 4a 04          	movzbl 0x4(%edx),%ecx
f0104471:	83 ea 0c             	sub    $0xc,%edx
f0104474:	39 f9                	cmp    %edi,%ecx
f0104476:	75 ee                	jne    f0104466 <stab_binsearch+0x40>
f0104478:	eb 05                	jmp    f010447f <stab_binsearch+0x59>
			m--;
		if (m < l) {  // no match in [l, m]
			l = true_m + 1;
f010447a:	8d 5e 01             	lea    0x1(%esi),%ebx
			continue;
f010447d:	eb 4b                	jmp    f01044ca <stab_binsearch+0xa4>
		}

		// actual binary search
		any_matches = 1;
		if (stabs[m].n_value < addr) {
f010447f:	8d 14 40             	lea    (%eax,%eax,2),%edx
f0104482:	8b 4d ec             	mov    -0x14(%ebp),%ecx
f0104485:	8b 54 91 08          	mov    0x8(%ecx,%edx,4),%edx
f0104489:	39 55 0c             	cmp    %edx,0xc(%ebp)
f010448c:	76 11                	jbe    f010449f <stab_binsearch+0x79>
			*region_left = m;
f010448e:	8b 5d e4             	mov    -0x1c(%ebp),%ebx
f0104491:	89 03                	mov    %eax,(%ebx)
			l = true_m + 1;
f0104493:	8d 5e 01             	lea    0x1(%esi),%ebx
			l = true_m + 1;
			continue;
		}

		// actual binary search
		any_matches = 1;
f0104496:	c7 45 e8 01 00 00 00 	movl   $0x1,-0x18(%ebp)
f010449d:	eb 2b                	jmp    f01044ca <stab_binsearch+0xa4>
		if (stabs[m].n_value < addr) {
			*region_left = m;
			l = true_m + 1;
		} else if (stabs[m].n_value > addr) {
f010449f:	39 55 0c             	cmp    %edx,0xc(%ebp)
f01044a2:	73 14                	jae    f01044b8 <stab_binsearch+0x92>
			*region_right = m - 1;
f01044a4:	83 e8 01             	sub    $0x1,%eax
f01044a7:	89 45 f0             	mov    %eax,-0x10(%ebp)
f01044aa:	8b 75 e0             	mov    -0x20(%ebp),%esi
f01044ad:	89 06                	mov    %eax,(%esi)
			l = true_m + 1;
			continue;
		}

		// actual binary search
		any_matches = 1;
f01044af:	c7 45 e8 01 00 00 00 	movl   $0x1,-0x18(%ebp)
f01044b6:	eb 12                	jmp    f01044ca <stab_binsearch+0xa4>
			*region_right = m - 1;
			r = m - 1;
		} else {
			// exact match for 'addr', but continue loop to find
			// *region_right
			*region_left = m;
f01044b8:	8b 75 e4             	mov    -0x1c(%ebp),%esi
f01044bb:	89 06                	mov    %eax,(%esi)
			l = m;
			addr++;
f01044bd:	83 45 0c 01          	addl   $0x1,0xc(%ebp)
f01044c1:	89 c3                	mov    %eax,%ebx
			l = true_m + 1;
			continue;
		}

		// actual binary search
		any_matches = 1;
f01044c3:	c7 45 e8 01 00 00 00 	movl   $0x1,-0x18(%ebp)
               int type,
               uintptr_t addr)
{
	int l = *region_left, r = *region_right, any_matches = 0;

	while (l <= r) {
f01044ca:	3b 5d f0             	cmp    -0x10(%ebp),%ebx
f01044cd:	0f 8e 78 ff ff ff    	jle    f010444b <stab_binsearch+0x25>
			l = m;
			addr++;
		}
	}

	if (!any_matches)
f01044d3:	83 7d e8 00          	cmpl   $0x0,-0x18(%ebp)
f01044d7:	75 0f                	jne    f01044e8 <stab_binsearch+0xc2>
		*region_right = *region_left - 1;
f01044d9:	8b 45 e4             	mov    -0x1c(%ebp),%eax
f01044dc:	8b 00                	mov    (%eax),%eax
f01044de:	83 e8 01             	sub    $0x1,%eax
f01044e1:	8b 75 e0             	mov    -0x20(%ebp),%esi
f01044e4:	89 06                	mov    %eax,(%esi)
f01044e6:	eb 2c                	jmp    f0104514 <stab_binsearch+0xee>
	else {
		// find rightmost region containing 'addr'
		for (l = *region_right;
f01044e8:	8b 45 e0             	mov    -0x20(%ebp),%eax
f01044eb:	8b 00                	mov    (%eax),%eax
		     l > *region_left && stabs[l].n_type != type;
f01044ed:	8b 75 e4             	mov    -0x1c(%ebp),%esi
f01044f0:	8b 0e                	mov    (%esi),%ecx
f01044f2:	8d 14 40             	lea    (%eax,%eax,2),%edx
f01044f5:	8b 75 ec             	mov    -0x14(%ebp),%esi
f01044f8:	8d 14 96             	lea    (%esi,%edx,4),%edx

	if (!any_matches)
		*region_right = *region_left - 1;
	else {
		// find rightmost region containing 'addr'
		for (l = *region_right;
f01044fb:	eb 03                	jmp    f0104500 <stab_binsearch+0xda>
		     l > *region_left && stabs[l].n_type != type;
		     l--)
f01044fd:	83 e8 01             	sub    $0x1,%eax

	if (!any_matches)
		*region_right = *region_left - 1;
	else {
		// find rightmost region containing 'addr'
		for (l = *region_right;
f0104500:	39 c8                	cmp    %ecx,%eax
f0104502:	7e 0b                	jle    f010450f <stab_binsearch+0xe9>
		     l > *region_left && stabs[l].n_type != type;
f0104504:	0f b6 5a 04          	movzbl 0x4(%edx),%ebx
f0104508:	83 ea 0c             	sub    $0xc,%edx
f010450b:	39 df                	cmp    %ebx,%edi
f010450d:	75 ee                	jne    f01044fd <stab_binsearch+0xd7>
		     l--)
			/* do nothing */;
		*region_left = l;
f010450f:	8b 75 e4             	mov    -0x1c(%ebp),%esi
f0104512:	89 06                	mov    %eax,(%esi)
	}
}
f0104514:	83 c4 14             	add    $0x14,%esp
f0104517:	5b                   	pop    %ebx
f0104518:	5e                   	pop    %esi
f0104519:	5f                   	pop    %edi
f010451a:	5d                   	pop    %ebp
f010451b:	c3                   	ret    

f010451c <debuginfo_eip>:
//	negative if not.  But even if it returns negative it has stored some
//	information into '*info'.
//
int
debuginfo_eip(uintptr_t addr, struct Eipdebuginfo *info)
{
f010451c:	55                   	push   %ebp
f010451d:	89 e5                	mov    %esp,%ebp
f010451f:	57                   	push   %edi
f0104520:	56                   	push   %esi
f0104521:	53                   	push   %ebx
f0104522:	83 ec 3c             	sub    $0x3c,%esp
f0104525:	8b 7d 08             	mov    0x8(%ebp),%edi
f0104528:	8b 5d 0c             	mov    0xc(%ebp),%ebx
	const struct Stab *stabs, *stab_end;
	const char *stabstr, *stabstr_end;
	int lfile, rfile, lfun, rfun, lline, rline;

	// Initialize *info
	info->eip_file = "<unknown>";
f010452b:	c7 03 5b 75 10 f0    	movl   $0xf010755b,(%ebx)
	info->eip_line = 0;
f0104531:	c7 43 04 00 00 00 00 	movl   $0x0,0x4(%ebx)
	info->eip_fn_name = "<unknown>";
f0104538:	c7 43 08 5b 75 10 f0 	movl   $0xf010755b,0x8(%ebx)
	info->eip_fn_namelen = 9;
f010453f:	c7 43 0c 09 00 00 00 	movl   $0x9,0xc(%ebx)
	info->eip_fn_addr = addr;
f0104546:	89 7b 10             	mov    %edi,0x10(%ebx)
	info->eip_fn_narg = 0;
f0104549:	c7 43 14 00 00 00 00 	movl   $0x0,0x14(%ebx)

	// Find the relevant set of stabs
	if (addr >= ULIM) {
f0104550:	81 ff ff ff 7f ef    	cmp    $0xef7fffff,%edi
f0104556:	0f 87 a3 00 00 00    	ja     f01045ff <debuginfo_eip+0xe3>
		        (const struct UserStabData *) USTABDATA;

		// Make sure this memory is valid.
		// Return -1 if it is not.  Hint: Call user_mem_check.
		// LAB 3: Your code here.
		if (user_mem_check(curenv, usd, sizeof(struct UserStabData), 0))
f010455c:	e8 ad 10 00 00       	call   f010560e <cpunum>
f0104561:	6a 00                	push   $0x0
f0104563:	6a 10                	push   $0x10
f0104565:	68 00 00 20 00       	push   $0x200000
f010456a:	6b c0 74             	imul   $0x74,%eax,%eax
f010456d:	ff b0 28 70 28 f0    	pushl  -0xfd78fd8(%eax)
f0104573:	e8 33 e7 ff ff       	call   f0102cab <user_mem_check>
f0104578:	83 c4 10             	add    $0x10,%esp
f010457b:	85 c0                	test   %eax,%eax
f010457d:	0f 85 43 02 00 00    	jne    f01047c6 <debuginfo_eip+0x2aa>
			return -1;

		stabs = usd->stabs;
f0104583:	a1 00 00 20 00       	mov    0x200000,%eax
f0104588:	89 45 c0             	mov    %eax,-0x40(%ebp)
		stab_end = usd->stab_end;
f010458b:	8b 35 04 00 20 00    	mov    0x200004,%esi
		stabstr = usd->stabstr;
f0104591:	8b 15 08 00 20 00    	mov    0x200008,%edx
f0104597:	89 55 b8             	mov    %edx,-0x48(%ebp)
		stabstr_end = usd->stabstr_end;
f010459a:	a1 0c 00 20 00       	mov    0x20000c,%eax
f010459f:	89 45 bc             	mov    %eax,-0x44(%ebp)

		// Make sure the STABS and string table memory is valid.
		// LAB 3: Your code here.
		if (user_mem_check(curenv, stabs, stab_end - stabs, 0) ||
f01045a2:	e8 67 10 00 00       	call   f010560e <cpunum>
f01045a7:	6a 00                	push   $0x0
f01045a9:	89 f2                	mov    %esi,%edx
f01045ab:	8b 4d c0             	mov    -0x40(%ebp),%ecx
f01045ae:	29 ca                	sub    %ecx,%edx
f01045b0:	c1 fa 02             	sar    $0x2,%edx
f01045b3:	69 d2 ab aa aa aa    	imul   $0xaaaaaaab,%edx,%edx
f01045b9:	52                   	push   %edx
f01045ba:	51                   	push   %ecx
f01045bb:	6b c0 74             	imul   $0x74,%eax,%eax
f01045be:	ff b0 28 70 28 f0    	pushl  -0xfd78fd8(%eax)
f01045c4:	e8 e2 e6 ff ff       	call   f0102cab <user_mem_check>
f01045c9:	83 c4 10             	add    $0x10,%esp
f01045cc:	85 c0                	test   %eax,%eax
f01045ce:	0f 85 f9 01 00 00    	jne    f01047cd <debuginfo_eip+0x2b1>
		    user_mem_check(curenv, stabstr, stabstr_end - stabstr, 0))
f01045d4:	e8 35 10 00 00       	call   f010560e <cpunum>
f01045d9:	6a 00                	push   $0x0
f01045db:	8b 55 bc             	mov    -0x44(%ebp),%edx
f01045de:	8b 4d b8             	mov    -0x48(%ebp),%ecx
f01045e1:	29 ca                	sub    %ecx,%edx
f01045e3:	52                   	push   %edx
f01045e4:	51                   	push   %ecx
f01045e5:	6b c0 74             	imul   $0x74,%eax,%eax
f01045e8:	ff b0 28 70 28 f0    	pushl  -0xfd78fd8(%eax)
f01045ee:	e8 b8 e6 ff ff       	call   f0102cab <user_mem_check>
		stabstr = usd->stabstr;
		stabstr_end = usd->stabstr_end;

		// Make sure the STABS and string table memory is valid.
		// LAB 3: Your code here.
		if (user_mem_check(curenv, stabs, stab_end - stabs, 0) ||
f01045f3:	83 c4 10             	add    $0x10,%esp
f01045f6:	85 c0                	test   %eax,%eax
f01045f8:	74 1f                	je     f0104619 <debuginfo_eip+0xfd>
f01045fa:	e9 d5 01 00 00       	jmp    f01047d4 <debuginfo_eip+0x2b8>
	// Find the relevant set of stabs
	if (addr >= ULIM) {
		stabs = __STAB_BEGIN__;
		stab_end = __STAB_END__;
		stabstr = __STABSTR_BEGIN__;
		stabstr_end = __STABSTR_END__;
f01045ff:	c7 45 bc 34 7a 10 f0 	movl   $0xf0107a34,-0x44(%ebp)

	// Find the relevant set of stabs
	if (addr >= ULIM) {
		stabs = __STAB_BEGIN__;
		stab_end = __STAB_END__;
		stabstr = __STABSTR_BEGIN__;
f0104606:	c7 45 b8 34 7a 10 f0 	movl   $0xf0107a34,-0x48(%ebp)
	info->eip_fn_narg = 0;

	// Find the relevant set of stabs
	if (addr >= ULIM) {
		stabs = __STAB_BEGIN__;
		stab_end = __STAB_END__;
f010460d:	be 33 7a 10 f0       	mov    $0xf0107a33,%esi
	info->eip_fn_addr = addr;
	info->eip_fn_narg = 0;

	// Find the relevant set of stabs
	if (addr >= ULIM) {
		stabs = __STAB_BEGIN__;
f0104612:	c7 45 c0 33 7a 10 f0 	movl   $0xf0107a33,-0x40(%ebp)
		    user_mem_check(curenv, stabstr, stabstr_end - stabstr, 0))
			return -1;
	}

	// String table validity checks
	if (stabstr_end <= stabstr || stabstr_end[-1] != 0)
f0104619:	8b 45 bc             	mov    -0x44(%ebp),%eax
f010461c:	39 45 b8             	cmp    %eax,-0x48(%ebp)
f010461f:	0f 83 b6 01 00 00    	jae    f01047db <debuginfo_eip+0x2bf>
f0104625:	80 78 ff 00          	cmpb   $0x0,-0x1(%eax)
f0104629:	0f 85 b3 01 00 00    	jne    f01047e2 <debuginfo_eip+0x2c6>
	// 'eip'.  First, we find the basic source file containing 'eip'.
	// Then, we look in that source file for the function.  Then we look
	// for the line number.

	// Search the entire set of stabs for the source file (type N_SO).
	lfile = 0;
f010462f:	c7 45 e4 00 00 00 00 	movl   $0x0,-0x1c(%ebp)
	rfile = (stab_end - stabs) - 1;
f0104636:	2b 75 c0             	sub    -0x40(%ebp),%esi
f0104639:	c1 fe 02             	sar    $0x2,%esi
f010463c:	69 c6 ab aa aa aa    	imul   $0xaaaaaaab,%esi,%eax
f0104642:	83 e8 01             	sub    $0x1,%eax
f0104645:	89 45 e0             	mov    %eax,-0x20(%ebp)
	stab_binsearch(stabs, &lfile, &rfile, N_SO, addr);
f0104648:	83 ec 08             	sub    $0x8,%esp
f010464b:	57                   	push   %edi
f010464c:	6a 64                	push   $0x64
f010464e:	8d 55 e0             	lea    -0x20(%ebp),%edx
f0104651:	89 d1                	mov    %edx,%ecx
f0104653:	8d 55 e4             	lea    -0x1c(%ebp),%edx
f0104656:	8b 75 c0             	mov    -0x40(%ebp),%esi
f0104659:	89 f0                	mov    %esi,%eax
f010465b:	e8 c6 fd ff ff       	call   f0104426 <stab_binsearch>
	if (lfile == 0)
f0104660:	8b 45 e4             	mov    -0x1c(%ebp),%eax
f0104663:	83 c4 10             	add    $0x10,%esp
f0104666:	85 c0                	test   %eax,%eax
f0104668:	0f 84 7b 01 00 00    	je     f01047e9 <debuginfo_eip+0x2cd>
		return -1;

	// Search within that file's stabs for the function definition
	// (N_FUN).
	lfun = lfile;
f010466e:	89 45 dc             	mov    %eax,-0x24(%ebp)
	rfun = rfile;
f0104671:	8b 45 e0             	mov    -0x20(%ebp),%eax
f0104674:	89 45 d8             	mov    %eax,-0x28(%ebp)
	stab_binsearch(stabs, &lfun, &rfun, N_FUN, addr);
f0104677:	83 ec 08             	sub    $0x8,%esp
f010467a:	57                   	push   %edi
f010467b:	6a 24                	push   $0x24
f010467d:	8d 55 d8             	lea    -0x28(%ebp),%edx
f0104680:	89 d1                	mov    %edx,%ecx
f0104682:	8d 55 dc             	lea    -0x24(%ebp),%edx
f0104685:	89 f0                	mov    %esi,%eax
f0104687:	e8 9a fd ff ff       	call   f0104426 <stab_binsearch>

	if (lfun <= rfun) {
f010468c:	8b 45 dc             	mov    -0x24(%ebp),%eax
f010468f:	8b 55 d8             	mov    -0x28(%ebp),%edx
f0104692:	83 c4 10             	add    $0x10,%esp
f0104695:	39 d0                	cmp    %edx,%eax
f0104697:	7f 2e                	jg     f01046c7 <debuginfo_eip+0x1ab>
		// stabs[lfun] points to the function name
		// in the string table, but check bounds just in case.
		if (stabs[lfun].n_strx < stabstr_end - stabstr)
f0104699:	8d 0c 40             	lea    (%eax,%eax,2),%ecx
f010469c:	8d 34 8e             	lea    (%esi,%ecx,4),%esi
f010469f:	89 75 c4             	mov    %esi,-0x3c(%ebp)
f01046a2:	8b 36                	mov    (%esi),%esi
f01046a4:	8b 4d bc             	mov    -0x44(%ebp),%ecx
f01046a7:	2b 4d b8             	sub    -0x48(%ebp),%ecx
f01046aa:	39 ce                	cmp    %ecx,%esi
f01046ac:	73 06                	jae    f01046b4 <debuginfo_eip+0x198>
			info->eip_fn_name = stabstr + stabs[lfun].n_strx;
f01046ae:	03 75 b8             	add    -0x48(%ebp),%esi
f01046b1:	89 73 08             	mov    %esi,0x8(%ebx)
		info->eip_fn_addr = stabs[lfun].n_value;
f01046b4:	8b 75 c4             	mov    -0x3c(%ebp),%esi
f01046b7:	8b 4e 08             	mov    0x8(%esi),%ecx
f01046ba:	89 4b 10             	mov    %ecx,0x10(%ebx)
		addr -= info->eip_fn_addr;
f01046bd:	29 cf                	sub    %ecx,%edi
		// Search within the function definition for the line number.
		lline = lfun;
f01046bf:	89 45 d4             	mov    %eax,-0x2c(%ebp)
		rline = rfun;
f01046c2:	89 55 d0             	mov    %edx,-0x30(%ebp)
f01046c5:	eb 0f                	jmp    f01046d6 <debuginfo_eip+0x1ba>
	} else {
		// Couldn't find function stab!  Maybe we're in an assembly
		// file.  Search the whole file for the line number.
		info->eip_fn_addr = addr;
f01046c7:	89 7b 10             	mov    %edi,0x10(%ebx)
		lline = lfile;
f01046ca:	8b 45 e4             	mov    -0x1c(%ebp),%eax
f01046cd:	89 45 d4             	mov    %eax,-0x2c(%ebp)
		rline = rfile;
f01046d0:	8b 45 e0             	mov    -0x20(%ebp),%eax
f01046d3:	89 45 d0             	mov    %eax,-0x30(%ebp)
	}
	// Ignore stuff after the colon.
	info->eip_fn_namelen = strfind(info->eip_fn_name, ':') - info->eip_fn_name;
f01046d6:	83 ec 08             	sub    $0x8,%esp
f01046d9:	6a 3a                	push   $0x3a
f01046db:	ff 73 08             	pushl  0x8(%ebx)
f01046de:	e8 7a 08 00 00       	call   f0104f5d <strfind>
f01046e3:	2b 43 08             	sub    0x8(%ebx),%eax
f01046e6:	89 43 0c             	mov    %eax,0xc(%ebx)
	//	There's a particular stabs type used for line numbers.
	//	Look at the STABS documentation and <inc/stab.h> to find
	//	which one.
	// Your code here.

	stab_binsearch(stabs, &lline, &rline, N_SLINE, addr);
f01046e9:	83 c4 08             	add    $0x8,%esp
f01046ec:	57                   	push   %edi
f01046ed:	6a 44                	push   $0x44
f01046ef:	8d 4d d0             	lea    -0x30(%ebp),%ecx
f01046f2:	8d 55 d4             	lea    -0x2c(%ebp),%edx
f01046f5:	8b 7d c0             	mov    -0x40(%ebp),%edi
f01046f8:	89 f8                	mov    %edi,%eax
f01046fa:	e8 27 fd ff ff       	call   f0104426 <stab_binsearch>
	if (lline <= rline) {
f01046ff:	8b 55 d4             	mov    -0x2c(%ebp),%edx
f0104702:	83 c4 10             	add    $0x10,%esp
f0104705:	3b 55 d0             	cmp    -0x30(%ebp),%edx
f0104708:	7f 0b                	jg     f0104715 <debuginfo_eip+0x1f9>
		info->eip_line = stabs[lline].n_desc;
f010470a:	8d 04 52             	lea    (%edx,%edx,2),%eax
f010470d:	0f b7 44 87 06       	movzwl 0x6(%edi,%eax,4),%eax
f0104712:	89 43 04             	mov    %eax,0x4(%ebx)
	// Search backwards from the line number for the relevant filename
	// stab.
	// We can't just use the "lfile" stab because inlined functions
	// can interpolate code from a different file!
	// Such included source files use the N_SOL stab type.
	while (lline >= lfile && stabs[lline].n_type != N_SOL &&
f0104715:	8b 7d e4             	mov    -0x1c(%ebp),%edi
f0104718:	89 d0                	mov    %edx,%eax
f010471a:	8d 14 52             	lea    (%edx,%edx,2),%edx
f010471d:	8b 75 c0             	mov    -0x40(%ebp),%esi
f0104720:	8d 14 96             	lea    (%esi,%edx,4),%edx
f0104723:	c6 45 c4 00          	movb   $0x0,-0x3c(%ebp)
f0104727:	89 5d 0c             	mov    %ebx,0xc(%ebp)
f010472a:	eb 0a                	jmp    f0104736 <debuginfo_eip+0x21a>
f010472c:	83 e8 01             	sub    $0x1,%eax
f010472f:	83 ea 0c             	sub    $0xc,%edx
f0104732:	c6 45 c4 01          	movb   $0x1,-0x3c(%ebp)
f0104736:	39 c7                	cmp    %eax,%edi
f0104738:	7e 05                	jle    f010473f <debuginfo_eip+0x223>
f010473a:	8b 5d 0c             	mov    0xc(%ebp),%ebx
f010473d:	eb 47                	jmp    f0104786 <debuginfo_eip+0x26a>
f010473f:	0f b6 4a 04          	movzbl 0x4(%edx),%ecx
f0104743:	80 f9 84             	cmp    $0x84,%cl
f0104746:	75 0e                	jne    f0104756 <debuginfo_eip+0x23a>
f0104748:	8b 5d 0c             	mov    0xc(%ebp),%ebx
f010474b:	80 7d c4 00          	cmpb   $0x0,-0x3c(%ebp)
f010474f:	74 1c                	je     f010476d <debuginfo_eip+0x251>
f0104751:	89 45 d4             	mov    %eax,-0x2c(%ebp)
f0104754:	eb 17                	jmp    f010476d <debuginfo_eip+0x251>
f0104756:	80 f9 64             	cmp    $0x64,%cl
f0104759:	75 d1                	jne    f010472c <debuginfo_eip+0x210>
	       (stabs[lline].n_type != N_SO || !stabs[lline].n_value))
f010475b:	83 7a 08 00          	cmpl   $0x0,0x8(%edx)
f010475f:	74 cb                	je     f010472c <debuginfo_eip+0x210>
f0104761:	8b 5d 0c             	mov    0xc(%ebp),%ebx
f0104764:	80 7d c4 00          	cmpb   $0x0,-0x3c(%ebp)
f0104768:	74 03                	je     f010476d <debuginfo_eip+0x251>
f010476a:	89 45 d4             	mov    %eax,-0x2c(%ebp)
		lline--;
	if (lline >= lfile && stabs[lline].n_strx < stabstr_end - stabstr)
f010476d:	8d 04 40             	lea    (%eax,%eax,2),%eax
f0104770:	8b 7d c0             	mov    -0x40(%ebp),%edi
f0104773:	8b 14 87             	mov    (%edi,%eax,4),%edx
f0104776:	8b 45 bc             	mov    -0x44(%ebp),%eax
f0104779:	8b 7d b8             	mov    -0x48(%ebp),%edi
f010477c:	29 f8                	sub    %edi,%eax
f010477e:	39 c2                	cmp    %eax,%edx
f0104780:	73 04                	jae    f0104786 <debuginfo_eip+0x26a>
		info->eip_file = stabstr + stabs[lline].n_strx;
f0104782:	01 fa                	add    %edi,%edx
f0104784:	89 13                	mov    %edx,(%ebx)


	// Set eip_fn_narg to the number of arguments taken by the function,
	// or 0 if there was no containing function.
	if (lfun < rfun)
f0104786:	8b 55 dc             	mov    -0x24(%ebp),%edx
f0104789:	8b 75 d8             	mov    -0x28(%ebp),%esi
		for (lline = lfun + 1;
		     lline < rfun && stabs[lline].n_type == N_PSYM;
		     lline++)
			info->eip_fn_narg++;

	return 0;
f010478c:	b8 00 00 00 00       	mov    $0x0,%eax
		info->eip_file = stabstr + stabs[lline].n_strx;


	// Set eip_fn_narg to the number of arguments taken by the function,
	// or 0 if there was no containing function.
	if (lfun < rfun)
f0104791:	39 f2                	cmp    %esi,%edx
f0104793:	7d 60                	jge    f01047f5 <debuginfo_eip+0x2d9>
		for (lline = lfun + 1;
f0104795:	83 c2 01             	add    $0x1,%edx
f0104798:	89 55 d4             	mov    %edx,-0x2c(%ebp)
f010479b:	89 d0                	mov    %edx,%eax
f010479d:	8d 14 52             	lea    (%edx,%edx,2),%edx
f01047a0:	8b 7d c0             	mov    -0x40(%ebp),%edi
f01047a3:	8d 14 97             	lea    (%edi,%edx,4),%edx
f01047a6:	eb 04                	jmp    f01047ac <debuginfo_eip+0x290>
		     lline < rfun && stabs[lline].n_type == N_PSYM;
		     lline++)
			info->eip_fn_narg++;
f01047a8:	83 43 14 01          	addl   $0x1,0x14(%ebx)


	// Set eip_fn_narg to the number of arguments taken by the function,
	// or 0 if there was no containing function.
	if (lfun < rfun)
		for (lline = lfun + 1;
f01047ac:	39 c6                	cmp    %eax,%esi
f01047ae:	7e 40                	jle    f01047f0 <debuginfo_eip+0x2d4>
		     lline < rfun && stabs[lline].n_type == N_PSYM;
f01047b0:	0f b6 4a 04          	movzbl 0x4(%edx),%ecx
f01047b4:	83 c0 01             	add    $0x1,%eax
f01047b7:	83 c2 0c             	add    $0xc,%edx
f01047ba:	80 f9 a0             	cmp    $0xa0,%cl
f01047bd:	74 e9                	je     f01047a8 <debuginfo_eip+0x28c>
		     lline++)
			info->eip_fn_narg++;

	return 0;
f01047bf:	b8 00 00 00 00       	mov    $0x0,%eax
f01047c4:	eb 2f                	jmp    f01047f5 <debuginfo_eip+0x2d9>

		// Make sure this memory is valid.
		// Return -1 if it is not.  Hint: Call user_mem_check.
		// LAB 3: Your code here.
		if (user_mem_check(curenv, usd, sizeof(struct UserStabData), 0))
			return -1;
f01047c6:	b8 ff ff ff ff       	mov    $0xffffffff,%eax
f01047cb:	eb 28                	jmp    f01047f5 <debuginfo_eip+0x2d9>

		// Make sure the STABS and string table memory is valid.
		// LAB 3: Your code here.
		if (user_mem_check(curenv, stabs, stab_end - stabs, 0) ||
		    user_mem_check(curenv, stabstr, stabstr_end - stabstr, 0))
			return -1;
f01047cd:	b8 ff ff ff ff       	mov    $0xffffffff,%eax
f01047d2:	eb 21                	jmp    f01047f5 <debuginfo_eip+0x2d9>
f01047d4:	b8 ff ff ff ff       	mov    $0xffffffff,%eax
f01047d9:	eb 1a                	jmp    f01047f5 <debuginfo_eip+0x2d9>
	}

	// String table validity checks
	if (stabstr_end <= stabstr || stabstr_end[-1] != 0)
		return -1;
f01047db:	b8 ff ff ff ff       	mov    $0xffffffff,%eax
f01047e0:	eb 13                	jmp    f01047f5 <debuginfo_eip+0x2d9>
f01047e2:	b8 ff ff ff ff       	mov    $0xffffffff,%eax
f01047e7:	eb 0c                	jmp    f01047f5 <debuginfo_eip+0x2d9>
	// Search the entire set of stabs for the source file (type N_SO).
	lfile = 0;
	rfile = (stab_end - stabs) - 1;
	stab_binsearch(stabs, &lfile, &rfile, N_SO, addr);
	if (lfile == 0)
		return -1;
f01047e9:	b8 ff ff ff ff       	mov    $0xffffffff,%eax
f01047ee:	eb 05                	jmp    f01047f5 <debuginfo_eip+0x2d9>
		for (lline = lfun + 1;
		     lline < rfun && stabs[lline].n_type == N_PSYM;
		     lline++)
			info->eip_fn_narg++;

	return 0;
f01047f0:	b8 00 00 00 00       	mov    $0x0,%eax
}
f01047f5:	8d 65 f4             	lea    -0xc(%ebp),%esp
f01047f8:	5b                   	pop    %ebx
f01047f9:	5e                   	pop    %esi
f01047fa:	5f                   	pop    %edi
f01047fb:	5d                   	pop    %ebp
f01047fc:	c3                   	ret    

f01047fd <printnum>:
 * using specified putch function and associated pointer putdat.
 */
static void
printnum(void (*putch)(int, void*), void *putdat,
	 unsigned long long num, unsigned base, int width, int padc)
{
f01047fd:	55                   	push   %ebp
f01047fe:	89 e5                	mov    %esp,%ebp
f0104800:	57                   	push   %edi
f0104801:	56                   	push   %esi
f0104802:	53                   	push   %ebx
f0104803:	83 ec 1c             	sub    $0x1c,%esp
f0104806:	89 c7                	mov    %eax,%edi
f0104808:	89 d6                	mov    %edx,%esi
f010480a:	8b 45 08             	mov    0x8(%ebp),%eax
f010480d:	8b 55 0c             	mov    0xc(%ebp),%edx
f0104810:	89 45 d8             	mov    %eax,-0x28(%ebp)
f0104813:	89 55 dc             	mov    %edx,-0x24(%ebp)
	// first recursively print all preceding (more significant) digits
	if (num >= base) {
f0104816:	8b 4d 10             	mov    0x10(%ebp),%ecx
f0104819:	bb 00 00 00 00       	mov    $0x0,%ebx
f010481e:	89 4d e0             	mov    %ecx,-0x20(%ebp)
f0104821:	89 5d e4             	mov    %ebx,-0x1c(%ebp)
f0104824:	39 d3                	cmp    %edx,%ebx
f0104826:	72 05                	jb     f010482d <printnum+0x30>
f0104828:	39 45 10             	cmp    %eax,0x10(%ebp)
f010482b:	77 45                	ja     f0104872 <printnum+0x75>
		printnum(putch, putdat, num / base, base, width - 1, padc);
f010482d:	83 ec 0c             	sub    $0xc,%esp
f0104830:	ff 75 18             	pushl  0x18(%ebp)
f0104833:	8b 45 14             	mov    0x14(%ebp),%eax
f0104836:	8d 58 ff             	lea    -0x1(%eax),%ebx
f0104839:	53                   	push   %ebx
f010483a:	ff 75 10             	pushl  0x10(%ebp)
f010483d:	83 ec 08             	sub    $0x8,%esp
f0104840:	ff 75 e4             	pushl  -0x1c(%ebp)
f0104843:	ff 75 e0             	pushl  -0x20(%ebp)
f0104846:	ff 75 dc             	pushl  -0x24(%ebp)
f0104849:	ff 75 d8             	pushl  -0x28(%ebp)
f010484c:	e8 df 11 00 00       	call   f0105a30 <__udivdi3>
f0104851:	83 c4 18             	add    $0x18,%esp
f0104854:	52                   	push   %edx
f0104855:	50                   	push   %eax
f0104856:	89 f2                	mov    %esi,%edx
f0104858:	89 f8                	mov    %edi,%eax
f010485a:	e8 9e ff ff ff       	call   f01047fd <printnum>
f010485f:	83 c4 20             	add    $0x20,%esp
f0104862:	eb 18                	jmp    f010487c <printnum+0x7f>
	} else {
		// print any needed pad characters before first digit
		while (--width > 0)
			putch(padc, putdat);
f0104864:	83 ec 08             	sub    $0x8,%esp
f0104867:	56                   	push   %esi
f0104868:	ff 75 18             	pushl  0x18(%ebp)
f010486b:	ff d7                	call   *%edi
f010486d:	83 c4 10             	add    $0x10,%esp
f0104870:	eb 03                	jmp    f0104875 <printnum+0x78>
f0104872:	8b 5d 14             	mov    0x14(%ebp),%ebx
	// first recursively print all preceding (more significant) digits
	if (num >= base) {
		printnum(putch, putdat, num / base, base, width - 1, padc);
	} else {
		// print any needed pad characters before first digit
		while (--width > 0)
f0104875:	83 eb 01             	sub    $0x1,%ebx
f0104878:	85 db                	test   %ebx,%ebx
f010487a:	7f e8                	jg     f0104864 <printnum+0x67>
			putch(padc, putdat);
	}

	// then print this (the least significant) digit
	putch("0123456789abcdef"[num % base], putdat);
f010487c:	83 ec 08             	sub    $0x8,%esp
f010487f:	56                   	push   %esi
f0104880:	83 ec 04             	sub    $0x4,%esp
f0104883:	ff 75 e4             	pushl  -0x1c(%ebp)
f0104886:	ff 75 e0             	pushl  -0x20(%ebp)
f0104889:	ff 75 dc             	pushl  -0x24(%ebp)
f010488c:	ff 75 d8             	pushl  -0x28(%ebp)
f010488f:	e8 cc 12 00 00       	call   f0105b60 <__umoddi3>
f0104894:	83 c4 14             	add    $0x14,%esp
f0104897:	0f be 80 65 75 10 f0 	movsbl -0xfef8a9b(%eax),%eax
f010489e:	50                   	push   %eax
f010489f:	ff d7                	call   *%edi
}
f01048a1:	83 c4 10             	add    $0x10,%esp
f01048a4:	8d 65 f4             	lea    -0xc(%ebp),%esp
f01048a7:	5b                   	pop    %ebx
f01048a8:	5e                   	pop    %esi
f01048a9:	5f                   	pop    %edi
f01048aa:	5d                   	pop    %ebp
f01048ab:	c3                   	ret    

f01048ac <getuint>:

// Get an unsigned int of various possible sizes from a varargs list,
// depending on the lflag parameter.
static unsigned long long
getuint(va_list *ap, int lflag)
{
f01048ac:	55                   	push   %ebp
f01048ad:	89 e5                	mov    %esp,%ebp
	if (lflag >= 2)
f01048af:	83 fa 01             	cmp    $0x1,%edx
f01048b2:	7e 0e                	jle    f01048c2 <getuint+0x16>
		return va_arg(*ap, unsigned long long);
f01048b4:	8b 10                	mov    (%eax),%edx
f01048b6:	8d 4a 08             	lea    0x8(%edx),%ecx
f01048b9:	89 08                	mov    %ecx,(%eax)
f01048bb:	8b 02                	mov    (%edx),%eax
f01048bd:	8b 52 04             	mov    0x4(%edx),%edx
f01048c0:	eb 22                	jmp    f01048e4 <getuint+0x38>
	else if (lflag)
f01048c2:	85 d2                	test   %edx,%edx
f01048c4:	74 10                	je     f01048d6 <getuint+0x2a>
		return va_arg(*ap, unsigned long);
f01048c6:	8b 10                	mov    (%eax),%edx
f01048c8:	8d 4a 04             	lea    0x4(%edx),%ecx
f01048cb:	89 08                	mov    %ecx,(%eax)
f01048cd:	8b 02                	mov    (%edx),%eax
f01048cf:	ba 00 00 00 00       	mov    $0x0,%edx
f01048d4:	eb 0e                	jmp    f01048e4 <getuint+0x38>
	else
		return va_arg(*ap, unsigned int);
f01048d6:	8b 10                	mov    (%eax),%edx
f01048d8:	8d 4a 04             	lea    0x4(%edx),%ecx
f01048db:	89 08                	mov    %ecx,(%eax)
f01048dd:	8b 02                	mov    (%edx),%eax
f01048df:	ba 00 00 00 00       	mov    $0x0,%edx
}
f01048e4:	5d                   	pop    %ebp
f01048e5:	c3                   	ret    

f01048e6 <getint>:

// Same as getuint but signed - can't use getuint
// because of sign extension
static long long
getint(va_list *ap, int lflag)
{
f01048e6:	55                   	push   %ebp
f01048e7:	89 e5                	mov    %esp,%ebp
	if (lflag >= 2)
f01048e9:	83 fa 01             	cmp    $0x1,%edx
f01048ec:	7e 0e                	jle    f01048fc <getint+0x16>
		return va_arg(*ap, long long);
f01048ee:	8b 10                	mov    (%eax),%edx
f01048f0:	8d 4a 08             	lea    0x8(%edx),%ecx
f01048f3:	89 08                	mov    %ecx,(%eax)
f01048f5:	8b 02                	mov    (%edx),%eax
f01048f7:	8b 52 04             	mov    0x4(%edx),%edx
f01048fa:	eb 1a                	jmp    f0104916 <getint+0x30>
	else if (lflag)
f01048fc:	85 d2                	test   %edx,%edx
f01048fe:	74 0c                	je     f010490c <getint+0x26>
		return va_arg(*ap, long);
f0104900:	8b 10                	mov    (%eax),%edx
f0104902:	8d 4a 04             	lea    0x4(%edx),%ecx
f0104905:	89 08                	mov    %ecx,(%eax)
f0104907:	8b 02                	mov    (%edx),%eax
f0104909:	99                   	cltd   
f010490a:	eb 0a                	jmp    f0104916 <getint+0x30>
	else
		return va_arg(*ap, int);
f010490c:	8b 10                	mov    (%eax),%edx
f010490e:	8d 4a 04             	lea    0x4(%edx),%ecx
f0104911:	89 08                	mov    %ecx,(%eax)
f0104913:	8b 02                	mov    (%edx),%eax
f0104915:	99                   	cltd   
}
f0104916:	5d                   	pop    %ebp
f0104917:	c3                   	ret    

f0104918 <sprintputch>:
	int cnt;
};

static void
sprintputch(int ch, struct sprintbuf *b)
{
f0104918:	55                   	push   %ebp
f0104919:	89 e5                	mov    %esp,%ebp
f010491b:	8b 45 0c             	mov    0xc(%ebp),%eax
	b->cnt++;
f010491e:	83 40 08 01          	addl   $0x1,0x8(%eax)
	if (b->buf < b->ebuf)
f0104922:	8b 10                	mov    (%eax),%edx
f0104924:	3b 50 04             	cmp    0x4(%eax),%edx
f0104927:	73 0a                	jae    f0104933 <sprintputch+0x1b>
		*b->buf++ = ch;
f0104929:	8d 4a 01             	lea    0x1(%edx),%ecx
f010492c:	89 08                	mov    %ecx,(%eax)
f010492e:	8b 45 08             	mov    0x8(%ebp),%eax
f0104931:	88 02                	mov    %al,(%edx)
}
f0104933:	5d                   	pop    %ebp
f0104934:	c3                   	ret    

f0104935 <printfmt>:
	}
}

void
printfmt(void (*putch)(int, void*), void *putdat, const char *fmt, ...)
{
f0104935:	55                   	push   %ebp
f0104936:	89 e5                	mov    %esp,%ebp
f0104938:	83 ec 08             	sub    $0x8,%esp
	va_list ap;

	va_start(ap, fmt);
f010493b:	8d 45 14             	lea    0x14(%ebp),%eax
	vprintfmt(putch, putdat, fmt, ap);
f010493e:	50                   	push   %eax
f010493f:	ff 75 10             	pushl  0x10(%ebp)
f0104942:	ff 75 0c             	pushl  0xc(%ebp)
f0104945:	ff 75 08             	pushl  0x8(%ebp)
f0104948:	e8 05 00 00 00       	call   f0104952 <vprintfmt>
	va_end(ap);
}
f010494d:	83 c4 10             	add    $0x10,%esp
f0104950:	c9                   	leave  
f0104951:	c3                   	ret    

f0104952 <vprintfmt>:
// Main function to format and print a string.
void printfmt(void (*putch)(int, void*), void *putdat, const char *fmt, ...);

void
vprintfmt(void (*putch)(int, void*), void *putdat, const char *fmt, va_list ap)
{
f0104952:	55                   	push   %ebp
f0104953:	89 e5                	mov    %esp,%ebp
f0104955:	57                   	push   %edi
f0104956:	56                   	push   %esi
f0104957:	53                   	push   %ebx
f0104958:	83 ec 2c             	sub    $0x2c,%esp
f010495b:	8b 75 08             	mov    0x8(%ebp),%esi
f010495e:	8b 5d 0c             	mov    0xc(%ebp),%ebx
f0104961:	8b 7d 10             	mov    0x10(%ebp),%edi
f0104964:	eb 12                	jmp    f0104978 <vprintfmt+0x26>
	int base, lflag, width, precision, altflag;
	char padc;

	while (1) {
		while ((ch = *(unsigned char *) fmt++) != '%') {
			if (ch == '\0')
f0104966:	85 c0                	test   %eax,%eax
f0104968:	0f 84 44 03 00 00    	je     f0104cb2 <vprintfmt+0x360>
				return;
			putch(ch, putdat);
f010496e:	83 ec 08             	sub    $0x8,%esp
f0104971:	53                   	push   %ebx
f0104972:	50                   	push   %eax
f0104973:	ff d6                	call   *%esi
f0104975:	83 c4 10             	add    $0x10,%esp
	unsigned long long num;
	int base, lflag, width, precision, altflag;
	char padc;

	while (1) {
		while ((ch = *(unsigned char *) fmt++) != '%') {
f0104978:	83 c7 01             	add    $0x1,%edi
f010497b:	0f b6 47 ff          	movzbl -0x1(%edi),%eax
f010497f:	83 f8 25             	cmp    $0x25,%eax
f0104982:	75 e2                	jne    f0104966 <vprintfmt+0x14>
f0104984:	c6 45 d4 20          	movb   $0x20,-0x2c(%ebp)
f0104988:	c7 45 d8 00 00 00 00 	movl   $0x0,-0x28(%ebp)
f010498f:	c7 45 d0 ff ff ff ff 	movl   $0xffffffff,-0x30(%ebp)
f0104996:	c7 45 e0 ff ff ff ff 	movl   $0xffffffff,-0x20(%ebp)
f010499d:	ba 00 00 00 00       	mov    $0x0,%edx
f01049a2:	eb 07                	jmp    f01049ab <vprintfmt+0x59>
		width = -1;
		precision = -1;
		lflag = 0;
		altflag = 0;
	reswitch:
		switch (ch = *(unsigned char *) fmt++) {
f01049a4:	8b 7d e4             	mov    -0x1c(%ebp),%edi

		// flag to pad on the right
		case '-':
			padc = '-';
f01049a7:	c6 45 d4 2d          	movb   $0x2d,-0x2c(%ebp)
		width = -1;
		precision = -1;
		lflag = 0;
		altflag = 0;
	reswitch:
		switch (ch = *(unsigned char *) fmt++) {
f01049ab:	8d 47 01             	lea    0x1(%edi),%eax
f01049ae:	89 45 e4             	mov    %eax,-0x1c(%ebp)
f01049b1:	0f b6 07             	movzbl (%edi),%eax
f01049b4:	0f b6 c8             	movzbl %al,%ecx
f01049b7:	83 e8 23             	sub    $0x23,%eax
f01049ba:	3c 55                	cmp    $0x55,%al
f01049bc:	0f 87 d5 02 00 00    	ja     f0104c97 <vprintfmt+0x345>
f01049c2:	0f b6 c0             	movzbl %al,%eax
f01049c5:	ff 24 85 20 76 10 f0 	jmp    *-0xfef89e0(,%eax,4)
f01049cc:	8b 7d e4             	mov    -0x1c(%ebp),%edi
			padc = '-';
			goto reswitch;

		// flag to pad with 0's instead of spaces
		case '0':
			padc = '0';
f01049cf:	c6 45 d4 30          	movb   $0x30,-0x2c(%ebp)
f01049d3:	eb d6                	jmp    f01049ab <vprintfmt+0x59>
		width = -1;
		precision = -1;
		lflag = 0;
		altflag = 0;
	reswitch:
		switch (ch = *(unsigned char *) fmt++) {
f01049d5:	8b 7d e4             	mov    -0x1c(%ebp),%edi
f01049d8:	b8 00 00 00 00       	mov    $0x0,%eax
f01049dd:	89 55 e4             	mov    %edx,-0x1c(%ebp)
		case '6':
		case '7':
		case '8':
		case '9':
			for (precision = 0; ; ++fmt) {
				precision = precision * 10 + ch - '0';
f01049e0:	8d 04 80             	lea    (%eax,%eax,4),%eax
f01049e3:	8d 44 41 d0          	lea    -0x30(%ecx,%eax,2),%eax
				ch = *fmt;
f01049e7:	0f be 0f             	movsbl (%edi),%ecx
				if (ch < '0' || ch > '9')
f01049ea:	8d 51 d0             	lea    -0x30(%ecx),%edx
f01049ed:	83 fa 09             	cmp    $0x9,%edx
f01049f0:	77 39                	ja     f0104a2b <vprintfmt+0xd9>
		case '5':
		case '6':
		case '7':
		case '8':
		case '9':
			for (precision = 0; ; ++fmt) {
f01049f2:	83 c7 01             	add    $0x1,%edi
				precision = precision * 10 + ch - '0';
				ch = *fmt;
				if (ch < '0' || ch > '9')
					break;
			}
f01049f5:	eb e9                	jmp    f01049e0 <vprintfmt+0x8e>
			goto process_precision;

		case '*':
			precision = va_arg(ap, int);
f01049f7:	8b 45 14             	mov    0x14(%ebp),%eax
f01049fa:	8d 48 04             	lea    0x4(%eax),%ecx
f01049fd:	89 4d 14             	mov    %ecx,0x14(%ebp)
f0104a00:	8b 00                	mov    (%eax),%eax
f0104a02:	89 45 d0             	mov    %eax,-0x30(%ebp)
		width = -1;
		precision = -1;
		lflag = 0;
		altflag = 0;
	reswitch:
		switch (ch = *(unsigned char *) fmt++) {
f0104a05:	8b 7d e4             	mov    -0x1c(%ebp),%edi
			}
			goto process_precision;

		case '*':
			precision = va_arg(ap, int);
			goto process_precision;
f0104a08:	eb 27                	jmp    f0104a31 <vprintfmt+0xdf>
f0104a0a:	8b 45 e0             	mov    -0x20(%ebp),%eax
f0104a0d:	85 c0                	test   %eax,%eax
f0104a0f:	b9 00 00 00 00       	mov    $0x0,%ecx
f0104a14:	0f 49 c8             	cmovns %eax,%ecx
f0104a17:	89 4d e0             	mov    %ecx,-0x20(%ebp)
		width = -1;
		precision = -1;
		lflag = 0;
		altflag = 0;
	reswitch:
		switch (ch = *(unsigned char *) fmt++) {
f0104a1a:	8b 7d e4             	mov    -0x1c(%ebp),%edi
f0104a1d:	eb 8c                	jmp    f01049ab <vprintfmt+0x59>
f0104a1f:	8b 7d e4             	mov    -0x1c(%ebp),%edi
			if (width < 0)
				width = 0;
			goto reswitch;

		case '#':
			altflag = 1;
f0104a22:	c7 45 d8 01 00 00 00 	movl   $0x1,-0x28(%ebp)
			goto reswitch;
f0104a29:	eb 80                	jmp    f01049ab <vprintfmt+0x59>
f0104a2b:	8b 55 e4             	mov    -0x1c(%ebp),%edx
f0104a2e:	89 45 d0             	mov    %eax,-0x30(%ebp)

		process_precision:
			if (width < 0)
f0104a31:	83 7d e0 00          	cmpl   $0x0,-0x20(%ebp)
f0104a35:	0f 89 70 ff ff ff    	jns    f01049ab <vprintfmt+0x59>
				width = precision, precision = -1;
f0104a3b:	8b 45 d0             	mov    -0x30(%ebp),%eax
f0104a3e:	89 45 e0             	mov    %eax,-0x20(%ebp)
f0104a41:	c7 45 d0 ff ff ff ff 	movl   $0xffffffff,-0x30(%ebp)
f0104a48:	e9 5e ff ff ff       	jmp    f01049ab <vprintfmt+0x59>
			goto reswitch;

		// long flag (doubled for long long)
		case 'l':
			lflag++;
f0104a4d:	83 c2 01             	add    $0x1,%edx
		width = -1;
		precision = -1;
		lflag = 0;
		altflag = 0;
	reswitch:
		switch (ch = *(unsigned char *) fmt++) {
f0104a50:	8b 7d e4             	mov    -0x1c(%ebp),%edi
			goto reswitch;

		// long flag (doubled for long long)
		case 'l':
			lflag++;
			goto reswitch;
f0104a53:	e9 53 ff ff ff       	jmp    f01049ab <vprintfmt+0x59>

		// character
		case 'c':
			putch(va_arg(ap, int), putdat);
f0104a58:	8b 45 14             	mov    0x14(%ebp),%eax
f0104a5b:	8d 50 04             	lea    0x4(%eax),%edx
f0104a5e:	89 55 14             	mov    %edx,0x14(%ebp)
f0104a61:	83 ec 08             	sub    $0x8,%esp
f0104a64:	53                   	push   %ebx
f0104a65:	ff 30                	pushl  (%eax)
f0104a67:	ff d6                	call   *%esi
			break;
f0104a69:	83 c4 10             	add    $0x10,%esp
		width = -1;
		precision = -1;
		lflag = 0;
		altflag = 0;
	reswitch:
		switch (ch = *(unsigned char *) fmt++) {
f0104a6c:	8b 7d e4             	mov    -0x1c(%ebp),%edi
			goto reswitch;

		// character
		case 'c':
			putch(va_arg(ap, int), putdat);
			break;
f0104a6f:	e9 04 ff ff ff       	jmp    f0104978 <vprintfmt+0x26>

		// error message
		case 'e':
			err = va_arg(ap, int);
f0104a74:	8b 45 14             	mov    0x14(%ebp),%eax
f0104a77:	8d 50 04             	lea    0x4(%eax),%edx
f0104a7a:	89 55 14             	mov    %edx,0x14(%ebp)
f0104a7d:	8b 00                	mov    (%eax),%eax
f0104a7f:	99                   	cltd   
f0104a80:	31 d0                	xor    %edx,%eax
f0104a82:	29 d0                	sub    %edx,%eax
			if (err < 0)
				err = -err;
			if (err >= MAXERROR || (p = error_string[err]) == NULL)
f0104a84:	83 f8 08             	cmp    $0x8,%eax
f0104a87:	7f 0b                	jg     f0104a94 <vprintfmt+0x142>
f0104a89:	8b 14 85 80 77 10 f0 	mov    -0xfef8880(,%eax,4),%edx
f0104a90:	85 d2                	test   %edx,%edx
f0104a92:	75 18                	jne    f0104aac <vprintfmt+0x15a>
				printfmt(putch, putdat, "error %d", err);
f0104a94:	50                   	push   %eax
f0104a95:	68 7d 75 10 f0       	push   $0xf010757d
f0104a9a:	53                   	push   %ebx
f0104a9b:	56                   	push   %esi
f0104a9c:	e8 94 fe ff ff       	call   f0104935 <printfmt>
f0104aa1:	83 c4 10             	add    $0x10,%esp
		width = -1;
		precision = -1;
		lflag = 0;
		altflag = 0;
	reswitch:
		switch (ch = *(unsigned char *) fmt++) {
f0104aa4:	8b 7d e4             	mov    -0x1c(%ebp),%edi
		case 'e':
			err = va_arg(ap, int);
			if (err < 0)
				err = -err;
			if (err >= MAXERROR || (p = error_string[err]) == NULL)
				printfmt(putch, putdat, "error %d", err);
f0104aa7:	e9 cc fe ff ff       	jmp    f0104978 <vprintfmt+0x26>
			else
				printfmt(putch, putdat, "%s", p);
f0104aac:	52                   	push   %edx
f0104aad:	68 f0 6b 10 f0       	push   $0xf0106bf0
f0104ab2:	53                   	push   %ebx
f0104ab3:	56                   	push   %esi
f0104ab4:	e8 7c fe ff ff       	call   f0104935 <printfmt>
f0104ab9:	83 c4 10             	add    $0x10,%esp
		width = -1;
		precision = -1;
		lflag = 0;
		altflag = 0;
	reswitch:
		switch (ch = *(unsigned char *) fmt++) {
f0104abc:	8b 7d e4             	mov    -0x1c(%ebp),%edi
f0104abf:	e9 b4 fe ff ff       	jmp    f0104978 <vprintfmt+0x26>
				printfmt(putch, putdat, "%s", p);
			break;

		// string
		case 's':
			if ((p = va_arg(ap, char *)) == NULL)
f0104ac4:	8b 45 14             	mov    0x14(%ebp),%eax
f0104ac7:	8d 50 04             	lea    0x4(%eax),%edx
f0104aca:	89 55 14             	mov    %edx,0x14(%ebp)
f0104acd:	8b 38                	mov    (%eax),%edi
				p = "(null)";
f0104acf:	85 ff                	test   %edi,%edi
f0104ad1:	b8 76 75 10 f0       	mov    $0xf0107576,%eax
f0104ad6:	0f 44 f8             	cmove  %eax,%edi
			if (width > 0 && padc != '-')
f0104ad9:	83 7d e0 00          	cmpl   $0x0,-0x20(%ebp)
f0104add:	0f 8e 94 00 00 00    	jle    f0104b77 <vprintfmt+0x225>
f0104ae3:	80 7d d4 2d          	cmpb   $0x2d,-0x2c(%ebp)
f0104ae7:	0f 84 98 00 00 00    	je     f0104b85 <vprintfmt+0x233>
				for (width -= strnlen(p, precision); width > 0; width--)
f0104aed:	83 ec 08             	sub    $0x8,%esp
f0104af0:	ff 75 d0             	pushl  -0x30(%ebp)
f0104af3:	57                   	push   %edi
f0104af4:	e8 1a 03 00 00       	call   f0104e13 <strnlen>
f0104af9:	8b 4d e0             	mov    -0x20(%ebp),%ecx
f0104afc:	29 c1                	sub    %eax,%ecx
f0104afe:	89 4d cc             	mov    %ecx,-0x34(%ebp)
f0104b01:	83 c4 10             	add    $0x10,%esp
					putch(padc, putdat);
f0104b04:	0f be 45 d4          	movsbl -0x2c(%ebp),%eax
f0104b08:	89 45 e0             	mov    %eax,-0x20(%ebp)
f0104b0b:	89 7d d4             	mov    %edi,-0x2c(%ebp)
f0104b0e:	89 cf                	mov    %ecx,%edi
		// string
		case 's':
			if ((p = va_arg(ap, char *)) == NULL)
				p = "(null)";
			if (width > 0 && padc != '-')
				for (width -= strnlen(p, precision); width > 0; width--)
f0104b10:	eb 0f                	jmp    f0104b21 <vprintfmt+0x1cf>
					putch(padc, putdat);
f0104b12:	83 ec 08             	sub    $0x8,%esp
f0104b15:	53                   	push   %ebx
f0104b16:	ff 75 e0             	pushl  -0x20(%ebp)
f0104b19:	ff d6                	call   *%esi
		// string
		case 's':
			if ((p = va_arg(ap, char *)) == NULL)
				p = "(null)";
			if (width > 0 && padc != '-')
				for (width -= strnlen(p, precision); width > 0; width--)
f0104b1b:	83 ef 01             	sub    $0x1,%edi
f0104b1e:	83 c4 10             	add    $0x10,%esp
f0104b21:	85 ff                	test   %edi,%edi
f0104b23:	7f ed                	jg     f0104b12 <vprintfmt+0x1c0>
f0104b25:	8b 7d d4             	mov    -0x2c(%ebp),%edi
f0104b28:	8b 4d cc             	mov    -0x34(%ebp),%ecx
f0104b2b:	85 c9                	test   %ecx,%ecx
f0104b2d:	b8 00 00 00 00       	mov    $0x0,%eax
f0104b32:	0f 49 c1             	cmovns %ecx,%eax
f0104b35:	29 c1                	sub    %eax,%ecx
f0104b37:	89 75 08             	mov    %esi,0x8(%ebp)
f0104b3a:	8b 75 d0             	mov    -0x30(%ebp),%esi
f0104b3d:	89 5d 0c             	mov    %ebx,0xc(%ebp)
f0104b40:	89 cb                	mov    %ecx,%ebx
f0104b42:	eb 4d                	jmp    f0104b91 <vprintfmt+0x23f>
					putch(padc, putdat);
			for (; (ch = *p++) != '\0' && (precision < 0 || --precision >= 0); width--)
				if (altflag && (ch < ' ' || ch > '~'))
f0104b44:	83 7d d8 00          	cmpl   $0x0,-0x28(%ebp)
f0104b48:	74 1b                	je     f0104b65 <vprintfmt+0x213>
f0104b4a:	0f be c0             	movsbl %al,%eax
f0104b4d:	83 e8 20             	sub    $0x20,%eax
f0104b50:	83 f8 5e             	cmp    $0x5e,%eax
f0104b53:	76 10                	jbe    f0104b65 <vprintfmt+0x213>
					putch('?', putdat);
f0104b55:	83 ec 08             	sub    $0x8,%esp
f0104b58:	ff 75 0c             	pushl  0xc(%ebp)
f0104b5b:	6a 3f                	push   $0x3f
f0104b5d:	ff 55 08             	call   *0x8(%ebp)
f0104b60:	83 c4 10             	add    $0x10,%esp
f0104b63:	eb 0d                	jmp    f0104b72 <vprintfmt+0x220>
				else
					putch(ch, putdat);
f0104b65:	83 ec 08             	sub    $0x8,%esp
f0104b68:	ff 75 0c             	pushl  0xc(%ebp)
f0104b6b:	52                   	push   %edx
f0104b6c:	ff 55 08             	call   *0x8(%ebp)
f0104b6f:	83 c4 10             	add    $0x10,%esp
			if ((p = va_arg(ap, char *)) == NULL)
				p = "(null)";
			if (width > 0 && padc != '-')
				for (width -= strnlen(p, precision); width > 0; width--)
					putch(padc, putdat);
			for (; (ch = *p++) != '\0' && (precision < 0 || --precision >= 0); width--)
f0104b72:	83 eb 01             	sub    $0x1,%ebx
f0104b75:	eb 1a                	jmp    f0104b91 <vprintfmt+0x23f>
f0104b77:	89 75 08             	mov    %esi,0x8(%ebp)
f0104b7a:	8b 75 d0             	mov    -0x30(%ebp),%esi
f0104b7d:	89 5d 0c             	mov    %ebx,0xc(%ebp)
f0104b80:	8b 5d e0             	mov    -0x20(%ebp),%ebx
f0104b83:	eb 0c                	jmp    f0104b91 <vprintfmt+0x23f>
f0104b85:	89 75 08             	mov    %esi,0x8(%ebp)
f0104b88:	8b 75 d0             	mov    -0x30(%ebp),%esi
f0104b8b:	89 5d 0c             	mov    %ebx,0xc(%ebp)
f0104b8e:	8b 5d e0             	mov    -0x20(%ebp),%ebx
f0104b91:	83 c7 01             	add    $0x1,%edi
f0104b94:	0f b6 47 ff          	movzbl -0x1(%edi),%eax
f0104b98:	0f be d0             	movsbl %al,%edx
f0104b9b:	85 d2                	test   %edx,%edx
f0104b9d:	74 23                	je     f0104bc2 <vprintfmt+0x270>
f0104b9f:	85 f6                	test   %esi,%esi
f0104ba1:	78 a1                	js     f0104b44 <vprintfmt+0x1f2>
f0104ba3:	83 ee 01             	sub    $0x1,%esi
f0104ba6:	79 9c                	jns    f0104b44 <vprintfmt+0x1f2>
f0104ba8:	89 df                	mov    %ebx,%edi
f0104baa:	8b 75 08             	mov    0x8(%ebp),%esi
f0104bad:	8b 5d 0c             	mov    0xc(%ebp),%ebx
f0104bb0:	eb 18                	jmp    f0104bca <vprintfmt+0x278>
				if (altflag && (ch < ' ' || ch > '~'))
					putch('?', putdat);
				else
					putch(ch, putdat);
			for (; width > 0; width--)
				putch(' ', putdat);
f0104bb2:	83 ec 08             	sub    $0x8,%esp
f0104bb5:	53                   	push   %ebx
f0104bb6:	6a 20                	push   $0x20
f0104bb8:	ff d6                	call   *%esi
			for (; (ch = *p++) != '\0' && (precision < 0 || --precision >= 0); width--)
				if (altflag && (ch < ' ' || ch > '~'))
					putch('?', putdat);
				else
					putch(ch, putdat);
			for (; width > 0; width--)
f0104bba:	83 ef 01             	sub    $0x1,%edi
f0104bbd:	83 c4 10             	add    $0x10,%esp
f0104bc0:	eb 08                	jmp    f0104bca <vprintfmt+0x278>
f0104bc2:	89 df                	mov    %ebx,%edi
f0104bc4:	8b 75 08             	mov    0x8(%ebp),%esi
f0104bc7:	8b 5d 0c             	mov    0xc(%ebp),%ebx
f0104bca:	85 ff                	test   %edi,%edi
f0104bcc:	7f e4                	jg     f0104bb2 <vprintfmt+0x260>
		width = -1;
		precision = -1;
		lflag = 0;
		altflag = 0;
	reswitch:
		switch (ch = *(unsigned char *) fmt++) {
f0104bce:	8b 7d e4             	mov    -0x1c(%ebp),%edi
f0104bd1:	e9 a2 fd ff ff       	jmp    f0104978 <vprintfmt+0x26>
				putch(' ', putdat);
			break;

		// (signed) decimal
		case 'd':
			num = getint(&ap, lflag);
f0104bd6:	8d 45 14             	lea    0x14(%ebp),%eax
f0104bd9:	e8 08 fd ff ff       	call   f01048e6 <getint>
f0104bde:	89 45 d8             	mov    %eax,-0x28(%ebp)
f0104be1:	89 55 dc             	mov    %edx,-0x24(%ebp)
			if ((long long) num < 0) {
				putch('-', putdat);
				num = -(long long) num;
			}
			base = 10;
f0104be4:	b9 0a 00 00 00       	mov    $0xa,%ecx
			break;

		// (signed) decimal
		case 'd':
			num = getint(&ap, lflag);
			if ((long long) num < 0) {
f0104be9:	83 7d dc 00          	cmpl   $0x0,-0x24(%ebp)
f0104bed:	79 74                	jns    f0104c63 <vprintfmt+0x311>
				putch('-', putdat);
f0104bef:	83 ec 08             	sub    $0x8,%esp
f0104bf2:	53                   	push   %ebx
f0104bf3:	6a 2d                	push   $0x2d
f0104bf5:	ff d6                	call   *%esi
				num = -(long long) num;
f0104bf7:	8b 45 d8             	mov    -0x28(%ebp),%eax
f0104bfa:	8b 55 dc             	mov    -0x24(%ebp),%edx
f0104bfd:	f7 d8                	neg    %eax
f0104bff:	83 d2 00             	adc    $0x0,%edx
f0104c02:	f7 da                	neg    %edx
f0104c04:	83 c4 10             	add    $0x10,%esp
			}
			base = 10;
f0104c07:	b9 0a 00 00 00       	mov    $0xa,%ecx
f0104c0c:	eb 55                	jmp    f0104c63 <vprintfmt+0x311>
			goto number;

		// unsigned decimal
		case 'u':
			num = getuint(&ap, lflag);
f0104c0e:	8d 45 14             	lea    0x14(%ebp),%eax
f0104c11:	e8 96 fc ff ff       	call   f01048ac <getuint>
			base = 10;
f0104c16:	b9 0a 00 00 00       	mov    $0xa,%ecx
			goto number;
f0104c1b:	eb 46                	jmp    f0104c63 <vprintfmt+0x311>

		// (unsigned) octal
		case 'o':
			num = getuint(&ap, lflag);
f0104c1d:	8d 45 14             	lea    0x14(%ebp),%eax
f0104c20:	e8 87 fc ff ff       	call   f01048ac <getuint>
			base = 8;
f0104c25:	b9 08 00 00 00       	mov    $0x8,%ecx
			goto number;
f0104c2a:	eb 37                	jmp    f0104c63 <vprintfmt+0x311>

		// pointer
		case 'p':
			putch('0', putdat);
f0104c2c:	83 ec 08             	sub    $0x8,%esp
f0104c2f:	53                   	push   %ebx
f0104c30:	6a 30                	push   $0x30
f0104c32:	ff d6                	call   *%esi
			putch('x', putdat);
f0104c34:	83 c4 08             	add    $0x8,%esp
f0104c37:	53                   	push   %ebx
f0104c38:	6a 78                	push   $0x78
f0104c3a:	ff d6                	call   *%esi
			num = (unsigned long long)
				(uintptr_t) va_arg(ap, void *);
f0104c3c:	8b 45 14             	mov    0x14(%ebp),%eax
f0104c3f:	8d 50 04             	lea    0x4(%eax),%edx
f0104c42:	89 55 14             	mov    %edx,0x14(%ebp)

		// pointer
		case 'p':
			putch('0', putdat);
			putch('x', putdat);
			num = (unsigned long long)
f0104c45:	8b 00                	mov    (%eax),%eax
f0104c47:	ba 00 00 00 00       	mov    $0x0,%edx
				(uintptr_t) va_arg(ap, void *);
			base = 16;
			goto number;
f0104c4c:	83 c4 10             	add    $0x10,%esp
		case 'p':
			putch('0', putdat);
			putch('x', putdat);
			num = (unsigned long long)
				(uintptr_t) va_arg(ap, void *);
			base = 16;
f0104c4f:	b9 10 00 00 00       	mov    $0x10,%ecx
			goto number;
f0104c54:	eb 0d                	jmp    f0104c63 <vprintfmt+0x311>

		// (unsigned) hexadecimal
		case 'x':
			num = getuint(&ap, lflag);
f0104c56:	8d 45 14             	lea    0x14(%ebp),%eax
f0104c59:	e8 4e fc ff ff       	call   f01048ac <getuint>
			base = 16;
f0104c5e:	b9 10 00 00 00       	mov    $0x10,%ecx
		number:
			printnum(putch, putdat, num, base, width, padc);
f0104c63:	83 ec 0c             	sub    $0xc,%esp
f0104c66:	0f be 7d d4          	movsbl -0x2c(%ebp),%edi
f0104c6a:	57                   	push   %edi
f0104c6b:	ff 75 e0             	pushl  -0x20(%ebp)
f0104c6e:	51                   	push   %ecx
f0104c6f:	52                   	push   %edx
f0104c70:	50                   	push   %eax
f0104c71:	89 da                	mov    %ebx,%edx
f0104c73:	89 f0                	mov    %esi,%eax
f0104c75:	e8 83 fb ff ff       	call   f01047fd <printnum>
			break;
f0104c7a:	83 c4 20             	add    $0x20,%esp
f0104c7d:	8b 7d e4             	mov    -0x1c(%ebp),%edi
f0104c80:	e9 f3 fc ff ff       	jmp    f0104978 <vprintfmt+0x26>

		// escaped '%' character
		case '%':
			putch(ch, putdat);
f0104c85:	83 ec 08             	sub    $0x8,%esp
f0104c88:	53                   	push   %ebx
f0104c89:	51                   	push   %ecx
f0104c8a:	ff d6                	call   *%esi
			break;
f0104c8c:	83 c4 10             	add    $0x10,%esp
		width = -1;
		precision = -1;
		lflag = 0;
		altflag = 0;
	reswitch:
		switch (ch = *(unsigned char *) fmt++) {
f0104c8f:	8b 7d e4             	mov    -0x1c(%ebp),%edi
			break;

		// escaped '%' character
		case '%':
			putch(ch, putdat);
			break;
f0104c92:	e9 e1 fc ff ff       	jmp    f0104978 <vprintfmt+0x26>

		// unrecognized escape sequence - just print it literally
		default:
			putch('%', putdat);
f0104c97:	83 ec 08             	sub    $0x8,%esp
f0104c9a:	53                   	push   %ebx
f0104c9b:	6a 25                	push   $0x25
f0104c9d:	ff d6                	call   *%esi
			for (fmt--; fmt[-1] != '%'; fmt--)
f0104c9f:	83 c4 10             	add    $0x10,%esp
f0104ca2:	eb 03                	jmp    f0104ca7 <vprintfmt+0x355>
f0104ca4:	83 ef 01             	sub    $0x1,%edi
f0104ca7:	80 7f ff 25          	cmpb   $0x25,-0x1(%edi)
f0104cab:	75 f7                	jne    f0104ca4 <vprintfmt+0x352>
f0104cad:	e9 c6 fc ff ff       	jmp    f0104978 <vprintfmt+0x26>
				/* do nothing */;
			break;
		}
	}
}
f0104cb2:	8d 65 f4             	lea    -0xc(%ebp),%esp
f0104cb5:	5b                   	pop    %ebx
f0104cb6:	5e                   	pop    %esi
f0104cb7:	5f                   	pop    %edi
f0104cb8:	5d                   	pop    %ebp
f0104cb9:	c3                   	ret    

f0104cba <vsnprintf>:
		*b->buf++ = ch;
}

int
vsnprintf(char *buf, int n, const char *fmt, va_list ap)
{
f0104cba:	55                   	push   %ebp
f0104cbb:	89 e5                	mov    %esp,%ebp
f0104cbd:	83 ec 18             	sub    $0x18,%esp
f0104cc0:	8b 45 08             	mov    0x8(%ebp),%eax
f0104cc3:	8b 55 0c             	mov    0xc(%ebp),%edx
	struct sprintbuf b = {buf, buf+n-1, 0};
f0104cc6:	89 45 ec             	mov    %eax,-0x14(%ebp)
f0104cc9:	8d 4c 10 ff          	lea    -0x1(%eax,%edx,1),%ecx
f0104ccd:	89 4d f0             	mov    %ecx,-0x10(%ebp)
f0104cd0:	c7 45 f4 00 00 00 00 	movl   $0x0,-0xc(%ebp)

	if (buf == NULL || n < 1)
f0104cd7:	85 c0                	test   %eax,%eax
f0104cd9:	74 26                	je     f0104d01 <vsnprintf+0x47>
f0104cdb:	85 d2                	test   %edx,%edx
f0104cdd:	7e 22                	jle    f0104d01 <vsnprintf+0x47>
		return -E_INVAL;

	// print the string to the buffer
	vprintfmt((void*)sprintputch, &b, fmt, ap);
f0104cdf:	ff 75 14             	pushl  0x14(%ebp)
f0104ce2:	ff 75 10             	pushl  0x10(%ebp)
f0104ce5:	8d 45 ec             	lea    -0x14(%ebp),%eax
f0104ce8:	50                   	push   %eax
f0104ce9:	68 18 49 10 f0       	push   $0xf0104918
f0104cee:	e8 5f fc ff ff       	call   f0104952 <vprintfmt>

	// null terminate the buffer
	*b.buf = '\0';
f0104cf3:	8b 45 ec             	mov    -0x14(%ebp),%eax
f0104cf6:	c6 00 00             	movb   $0x0,(%eax)

	return b.cnt;
f0104cf9:	8b 45 f4             	mov    -0xc(%ebp),%eax
f0104cfc:	83 c4 10             	add    $0x10,%esp
f0104cff:	eb 05                	jmp    f0104d06 <vsnprintf+0x4c>
vsnprintf(char *buf, int n, const char *fmt, va_list ap)
{
	struct sprintbuf b = {buf, buf+n-1, 0};

	if (buf == NULL || n < 1)
		return -E_INVAL;
f0104d01:	b8 fd ff ff ff       	mov    $0xfffffffd,%eax

	// null terminate the buffer
	*b.buf = '\0';

	return b.cnt;
}
f0104d06:	c9                   	leave  
f0104d07:	c3                   	ret    

f0104d08 <snprintf>:

int
snprintf(char *buf, int n, const char *fmt, ...)
{
f0104d08:	55                   	push   %ebp
f0104d09:	89 e5                	mov    %esp,%ebp
f0104d0b:	83 ec 08             	sub    $0x8,%esp
	va_list ap;
	int rc;

	va_start(ap, fmt);
f0104d0e:	8d 45 14             	lea    0x14(%ebp),%eax
	rc = vsnprintf(buf, n, fmt, ap);
f0104d11:	50                   	push   %eax
f0104d12:	ff 75 10             	pushl  0x10(%ebp)
f0104d15:	ff 75 0c             	pushl  0xc(%ebp)
f0104d18:	ff 75 08             	pushl  0x8(%ebp)
f0104d1b:	e8 9a ff ff ff       	call   f0104cba <vsnprintf>
	va_end(ap);

	return rc;
}
f0104d20:	c9                   	leave  
f0104d21:	c3                   	ret    

f0104d22 <readline>:
#define BUFLEN 1024
static char buf[BUFLEN];

char *
readline(const char *prompt)
{
f0104d22:	55                   	push   %ebp
f0104d23:	89 e5                	mov    %esp,%ebp
f0104d25:	57                   	push   %edi
f0104d26:	56                   	push   %esi
f0104d27:	53                   	push   %ebx
f0104d28:	83 ec 0c             	sub    $0xc,%esp
f0104d2b:	8b 45 08             	mov    0x8(%ebp),%eax
	int i, c, echoing;

	if (prompt != NULL)
f0104d2e:	85 c0                	test   %eax,%eax
f0104d30:	74 11                	je     f0104d43 <readline+0x21>
		cprintf("%s", prompt);
f0104d32:	83 ec 08             	sub    $0x8,%esp
f0104d35:	50                   	push   %eax
f0104d36:	68 f0 6b 10 f0       	push   $0xf0106bf0
f0104d3b:	e8 2f eb ff ff       	call   f010386f <cprintf>
f0104d40:	83 c4 10             	add    $0x10,%esp

	i = 0;
	echoing = iscons(0);
f0104d43:	83 ec 0c             	sub    $0xc,%esp
f0104d46:	6a 00                	push   $0x0
f0104d48:	e8 a7 bb ff ff       	call   f01008f4 <iscons>
f0104d4d:	89 c7                	mov    %eax,%edi
f0104d4f:	83 c4 10             	add    $0x10,%esp
	int i, c, echoing;

	if (prompt != NULL)
		cprintf("%s", prompt);

	i = 0;
f0104d52:	be 00 00 00 00       	mov    $0x0,%esi
	echoing = iscons(0);
	while (1) {
		c = getchar();
f0104d57:	e8 87 bb ff ff       	call   f01008e3 <getchar>
f0104d5c:	89 c3                	mov    %eax,%ebx
		if (c < 0) {
f0104d5e:	85 c0                	test   %eax,%eax
f0104d60:	79 18                	jns    f0104d7a <readline+0x58>
			cprintf("read error: %e\n", c);
f0104d62:	83 ec 08             	sub    $0x8,%esp
f0104d65:	50                   	push   %eax
f0104d66:	68 a4 77 10 f0       	push   $0xf01077a4
f0104d6b:	e8 ff ea ff ff       	call   f010386f <cprintf>
			return NULL;
f0104d70:	83 c4 10             	add    $0x10,%esp
f0104d73:	b8 00 00 00 00       	mov    $0x0,%eax
f0104d78:	eb 79                	jmp    f0104df3 <readline+0xd1>
		} else if ((c == '\b' || c == '\x7f') && i > 0) {
f0104d7a:	83 f8 08             	cmp    $0x8,%eax
f0104d7d:	0f 94 c2             	sete   %dl
f0104d80:	83 f8 7f             	cmp    $0x7f,%eax
f0104d83:	0f 94 c0             	sete   %al
f0104d86:	08 c2                	or     %al,%dl
f0104d88:	74 1a                	je     f0104da4 <readline+0x82>
f0104d8a:	85 f6                	test   %esi,%esi
f0104d8c:	7e 16                	jle    f0104da4 <readline+0x82>
			if (echoing)
f0104d8e:	85 ff                	test   %edi,%edi
f0104d90:	74 0d                	je     f0104d9f <readline+0x7d>
				cputchar('\b');
f0104d92:	83 ec 0c             	sub    $0xc,%esp
f0104d95:	6a 08                	push   $0x8
f0104d97:	e8 37 bb ff ff       	call   f01008d3 <cputchar>
f0104d9c:	83 c4 10             	add    $0x10,%esp
			i--;
f0104d9f:	83 ee 01             	sub    $0x1,%esi
f0104da2:	eb b3                	jmp    f0104d57 <readline+0x35>
		} else if (c >= ' ' && i < BUFLEN-1) {
f0104da4:	83 fb 1f             	cmp    $0x1f,%ebx
f0104da7:	7e 23                	jle    f0104dcc <readline+0xaa>
f0104da9:	81 fe fe 03 00 00    	cmp    $0x3fe,%esi
f0104daf:	7f 1b                	jg     f0104dcc <readline+0xaa>
			if (echoing)
f0104db1:	85 ff                	test   %edi,%edi
f0104db3:	74 0c                	je     f0104dc1 <readline+0x9f>
				cputchar(c);
f0104db5:	83 ec 0c             	sub    $0xc,%esp
f0104db8:	53                   	push   %ebx
f0104db9:	e8 15 bb ff ff       	call   f01008d3 <cputchar>
f0104dbe:	83 c4 10             	add    $0x10,%esp
			buf[i++] = c;
f0104dc1:	88 9e 00 5b 28 f0    	mov    %bl,-0xfd7a500(%esi)
f0104dc7:	8d 76 01             	lea    0x1(%esi),%esi
f0104dca:	eb 8b                	jmp    f0104d57 <readline+0x35>
		} else if (c == '\n' || c == '\r') {
f0104dcc:	83 fb 0a             	cmp    $0xa,%ebx
f0104dcf:	74 05                	je     f0104dd6 <readline+0xb4>
f0104dd1:	83 fb 0d             	cmp    $0xd,%ebx
f0104dd4:	75 81                	jne    f0104d57 <readline+0x35>
			if (echoing)
f0104dd6:	85 ff                	test   %edi,%edi
f0104dd8:	74 0d                	je     f0104de7 <readline+0xc5>
				cputchar('\n');
f0104dda:	83 ec 0c             	sub    $0xc,%esp
f0104ddd:	6a 0a                	push   $0xa
f0104ddf:	e8 ef ba ff ff       	call   f01008d3 <cputchar>
f0104de4:	83 c4 10             	add    $0x10,%esp
			buf[i] = 0;
f0104de7:	c6 86 00 5b 28 f0 00 	movb   $0x0,-0xfd7a500(%esi)
			return buf;
f0104dee:	b8 00 5b 28 f0       	mov    $0xf0285b00,%eax
		}
	}
}
f0104df3:	8d 65 f4             	lea    -0xc(%ebp),%esp
f0104df6:	5b                   	pop    %ebx
f0104df7:	5e                   	pop    %esi
f0104df8:	5f                   	pop    %edi
f0104df9:	5d                   	pop    %ebp
f0104dfa:	c3                   	ret    

f0104dfb <strlen>:
// Primespipe runs 3x faster this way.
#define ASM 1

int
strlen(const char *s)
{
f0104dfb:	55                   	push   %ebp
f0104dfc:	89 e5                	mov    %esp,%ebp
f0104dfe:	8b 55 08             	mov    0x8(%ebp),%edx
	int n;

	for (n = 0; *s != '\0'; s++)
f0104e01:	b8 00 00 00 00       	mov    $0x0,%eax
f0104e06:	eb 03                	jmp    f0104e0b <strlen+0x10>
		n++;
f0104e08:	83 c0 01             	add    $0x1,%eax
int
strlen(const char *s)
{
	int n;

	for (n = 0; *s != '\0'; s++)
f0104e0b:	80 3c 02 00          	cmpb   $0x0,(%edx,%eax,1)
f0104e0f:	75 f7                	jne    f0104e08 <strlen+0xd>
		n++;
	return n;
}
f0104e11:	5d                   	pop    %ebp
f0104e12:	c3                   	ret    

f0104e13 <strnlen>:

int
strnlen(const char *s, size_t size)
{
f0104e13:	55                   	push   %ebp
f0104e14:	89 e5                	mov    %esp,%ebp
f0104e16:	8b 4d 08             	mov    0x8(%ebp),%ecx
f0104e19:	8b 45 0c             	mov    0xc(%ebp),%eax
	int n;

	for (n = 0; size > 0 && *s != '\0'; s++, size--)
f0104e1c:	ba 00 00 00 00       	mov    $0x0,%edx
f0104e21:	eb 03                	jmp    f0104e26 <strnlen+0x13>
		n++;
f0104e23:	83 c2 01             	add    $0x1,%edx
int
strnlen(const char *s, size_t size)
{
	int n;

	for (n = 0; size > 0 && *s != '\0'; s++, size--)
f0104e26:	39 c2                	cmp    %eax,%edx
f0104e28:	74 08                	je     f0104e32 <strnlen+0x1f>
f0104e2a:	80 3c 11 00          	cmpb   $0x0,(%ecx,%edx,1)
f0104e2e:	75 f3                	jne    f0104e23 <strnlen+0x10>
f0104e30:	89 d0                	mov    %edx,%eax
		n++;
	return n;
}
f0104e32:	5d                   	pop    %ebp
f0104e33:	c3                   	ret    

f0104e34 <strcpy>:

char *
strcpy(char *dst, const char *src)
{
f0104e34:	55                   	push   %ebp
f0104e35:	89 e5                	mov    %esp,%ebp
f0104e37:	53                   	push   %ebx
f0104e38:	8b 45 08             	mov    0x8(%ebp),%eax
f0104e3b:	8b 4d 0c             	mov    0xc(%ebp),%ecx
	char *ret;

	ret = dst;
	while ((*dst++ = *src++) != '\0')
f0104e3e:	89 c2                	mov    %eax,%edx
f0104e40:	83 c2 01             	add    $0x1,%edx
f0104e43:	83 c1 01             	add    $0x1,%ecx
f0104e46:	0f b6 59 ff          	movzbl -0x1(%ecx),%ebx
f0104e4a:	88 5a ff             	mov    %bl,-0x1(%edx)
f0104e4d:	84 db                	test   %bl,%bl
f0104e4f:	75 ef                	jne    f0104e40 <strcpy+0xc>
		/* do nothing */;
	return ret;
}
f0104e51:	5b                   	pop    %ebx
f0104e52:	5d                   	pop    %ebp
f0104e53:	c3                   	ret    

f0104e54 <strcat>:

char *
strcat(char *dst, const char *src)
{
f0104e54:	55                   	push   %ebp
f0104e55:	89 e5                	mov    %esp,%ebp
f0104e57:	53                   	push   %ebx
f0104e58:	8b 5d 08             	mov    0x8(%ebp),%ebx
	int len = strlen(dst);
f0104e5b:	53                   	push   %ebx
f0104e5c:	e8 9a ff ff ff       	call   f0104dfb <strlen>
f0104e61:	83 c4 04             	add    $0x4,%esp
	strcpy(dst + len, src);
f0104e64:	ff 75 0c             	pushl  0xc(%ebp)
f0104e67:	01 d8                	add    %ebx,%eax
f0104e69:	50                   	push   %eax
f0104e6a:	e8 c5 ff ff ff       	call   f0104e34 <strcpy>
	return dst;
}
f0104e6f:	89 d8                	mov    %ebx,%eax
f0104e71:	8b 5d fc             	mov    -0x4(%ebp),%ebx
f0104e74:	c9                   	leave  
f0104e75:	c3                   	ret    

f0104e76 <strncpy>:

char *
strncpy(char *dst, const char *src, size_t size) {
f0104e76:	55                   	push   %ebp
f0104e77:	89 e5                	mov    %esp,%ebp
f0104e79:	56                   	push   %esi
f0104e7a:	53                   	push   %ebx
f0104e7b:	8b 75 08             	mov    0x8(%ebp),%esi
f0104e7e:	8b 4d 0c             	mov    0xc(%ebp),%ecx
f0104e81:	89 f3                	mov    %esi,%ebx
f0104e83:	03 5d 10             	add    0x10(%ebp),%ebx
	size_t i;
	char *ret;

	ret = dst;
	for (i = 0; i < size; i++) {
f0104e86:	89 f2                	mov    %esi,%edx
f0104e88:	eb 0f                	jmp    f0104e99 <strncpy+0x23>
		*dst++ = *src;
f0104e8a:	83 c2 01             	add    $0x1,%edx
f0104e8d:	0f b6 01             	movzbl (%ecx),%eax
f0104e90:	88 42 ff             	mov    %al,-0x1(%edx)
		// If strlen(src) < size, null-pad 'dst' out to 'size' chars
		if (*src != '\0')
			src++;
f0104e93:	80 39 01             	cmpb   $0x1,(%ecx)
f0104e96:	83 d9 ff             	sbb    $0xffffffff,%ecx
strncpy(char *dst, const char *src, size_t size) {
	size_t i;
	char *ret;

	ret = dst;
	for (i = 0; i < size; i++) {
f0104e99:	39 da                	cmp    %ebx,%edx
f0104e9b:	75 ed                	jne    f0104e8a <strncpy+0x14>
		// If strlen(src) < size, null-pad 'dst' out to 'size' chars
		if (*src != '\0')
			src++;
	}
	return ret;
}
f0104e9d:	89 f0                	mov    %esi,%eax
f0104e9f:	5b                   	pop    %ebx
f0104ea0:	5e                   	pop    %esi
f0104ea1:	5d                   	pop    %ebp
f0104ea2:	c3                   	ret    

f0104ea3 <strlcpy>:

size_t
strlcpy(char *dst, const char *src, size_t size)
{
f0104ea3:	55                   	push   %ebp
f0104ea4:	89 e5                	mov    %esp,%ebp
f0104ea6:	56                   	push   %esi
f0104ea7:	53                   	push   %ebx
f0104ea8:	8b 75 08             	mov    0x8(%ebp),%esi
f0104eab:	8b 4d 0c             	mov    0xc(%ebp),%ecx
f0104eae:	8b 55 10             	mov    0x10(%ebp),%edx
f0104eb1:	89 f0                	mov    %esi,%eax
	char *dst_in;

	dst_in = dst;
	if (size > 0) {
f0104eb3:	85 d2                	test   %edx,%edx
f0104eb5:	74 21                	je     f0104ed8 <strlcpy+0x35>
f0104eb7:	8d 44 16 ff          	lea    -0x1(%esi,%edx,1),%eax
f0104ebb:	89 f2                	mov    %esi,%edx
f0104ebd:	eb 09                	jmp    f0104ec8 <strlcpy+0x25>
		while (--size > 0 && *src != '\0')
			*dst++ = *src++;
f0104ebf:	83 c2 01             	add    $0x1,%edx
f0104ec2:	83 c1 01             	add    $0x1,%ecx
f0104ec5:	88 5a ff             	mov    %bl,-0x1(%edx)
{
	char *dst_in;

	dst_in = dst;
	if (size > 0) {
		while (--size > 0 && *src != '\0')
f0104ec8:	39 c2                	cmp    %eax,%edx
f0104eca:	74 09                	je     f0104ed5 <strlcpy+0x32>
f0104ecc:	0f b6 19             	movzbl (%ecx),%ebx
f0104ecf:	84 db                	test   %bl,%bl
f0104ed1:	75 ec                	jne    f0104ebf <strlcpy+0x1c>
f0104ed3:	89 d0                	mov    %edx,%eax
			*dst++ = *src++;
		*dst = '\0';
f0104ed5:	c6 00 00             	movb   $0x0,(%eax)
	}
	return dst - dst_in;
f0104ed8:	29 f0                	sub    %esi,%eax
}
f0104eda:	5b                   	pop    %ebx
f0104edb:	5e                   	pop    %esi
f0104edc:	5d                   	pop    %ebp
f0104edd:	c3                   	ret    

f0104ede <strcmp>:

int
strcmp(const char *p, const char *q)
{
f0104ede:	55                   	push   %ebp
f0104edf:	89 e5                	mov    %esp,%ebp
f0104ee1:	8b 4d 08             	mov    0x8(%ebp),%ecx
f0104ee4:	8b 55 0c             	mov    0xc(%ebp),%edx
	while (*p && *p == *q)
f0104ee7:	eb 06                	jmp    f0104eef <strcmp+0x11>
		p++, q++;
f0104ee9:	83 c1 01             	add    $0x1,%ecx
f0104eec:	83 c2 01             	add    $0x1,%edx
}

int
strcmp(const char *p, const char *q)
{
	while (*p && *p == *q)
f0104eef:	0f b6 01             	movzbl (%ecx),%eax
f0104ef2:	84 c0                	test   %al,%al
f0104ef4:	74 04                	je     f0104efa <strcmp+0x1c>
f0104ef6:	3a 02                	cmp    (%edx),%al
f0104ef8:	74 ef                	je     f0104ee9 <strcmp+0xb>
		p++, q++;
	return (int) ((unsigned char) *p - (unsigned char) *q);
f0104efa:	0f b6 c0             	movzbl %al,%eax
f0104efd:	0f b6 12             	movzbl (%edx),%edx
f0104f00:	29 d0                	sub    %edx,%eax
}
f0104f02:	5d                   	pop    %ebp
f0104f03:	c3                   	ret    

f0104f04 <strncmp>:

int
strncmp(const char *p, const char *q, size_t n)
{
f0104f04:	55                   	push   %ebp
f0104f05:	89 e5                	mov    %esp,%ebp
f0104f07:	53                   	push   %ebx
f0104f08:	8b 45 08             	mov    0x8(%ebp),%eax
f0104f0b:	8b 55 0c             	mov    0xc(%ebp),%edx
f0104f0e:	89 c3                	mov    %eax,%ebx
f0104f10:	03 5d 10             	add    0x10(%ebp),%ebx
	while (n > 0 && *p && *p == *q)
f0104f13:	eb 06                	jmp    f0104f1b <strncmp+0x17>
		n--, p++, q++;
f0104f15:	83 c0 01             	add    $0x1,%eax
f0104f18:	83 c2 01             	add    $0x1,%edx
}

int
strncmp(const char *p, const char *q, size_t n)
{
	while (n > 0 && *p && *p == *q)
f0104f1b:	39 d8                	cmp    %ebx,%eax
f0104f1d:	74 15                	je     f0104f34 <strncmp+0x30>
f0104f1f:	0f b6 08             	movzbl (%eax),%ecx
f0104f22:	84 c9                	test   %cl,%cl
f0104f24:	74 04                	je     f0104f2a <strncmp+0x26>
f0104f26:	3a 0a                	cmp    (%edx),%cl
f0104f28:	74 eb                	je     f0104f15 <strncmp+0x11>
		n--, p++, q++;
	if (n == 0)
		return 0;
	else
		return (int) ((unsigned char) *p - (unsigned char) *q);
f0104f2a:	0f b6 00             	movzbl (%eax),%eax
f0104f2d:	0f b6 12             	movzbl (%edx),%edx
f0104f30:	29 d0                	sub    %edx,%eax
f0104f32:	eb 05                	jmp    f0104f39 <strncmp+0x35>
strncmp(const char *p, const char *q, size_t n)
{
	while (n > 0 && *p && *p == *q)
		n--, p++, q++;
	if (n == 0)
		return 0;
f0104f34:	b8 00 00 00 00       	mov    $0x0,%eax
	else
		return (int) ((unsigned char) *p - (unsigned char) *q);
}
f0104f39:	5b                   	pop    %ebx
f0104f3a:	5d                   	pop    %ebp
f0104f3b:	c3                   	ret    

f0104f3c <strchr>:

// Return a pointer to the first occurrence of 'c' in 's',
// or a null pointer if the string has no 'c'.
char *
strchr(const char *s, char c)
{
f0104f3c:	55                   	push   %ebp
f0104f3d:	89 e5                	mov    %esp,%ebp
f0104f3f:	8b 45 08             	mov    0x8(%ebp),%eax
f0104f42:	0f b6 4d 0c          	movzbl 0xc(%ebp),%ecx
	for (; *s; s++)
f0104f46:	eb 07                	jmp    f0104f4f <strchr+0x13>
		if (*s == c)
f0104f48:	38 ca                	cmp    %cl,%dl
f0104f4a:	74 0f                	je     f0104f5b <strchr+0x1f>
// Return a pointer to the first occurrence of 'c' in 's',
// or a null pointer if the string has no 'c'.
char *
strchr(const char *s, char c)
{
	for (; *s; s++)
f0104f4c:	83 c0 01             	add    $0x1,%eax
f0104f4f:	0f b6 10             	movzbl (%eax),%edx
f0104f52:	84 d2                	test   %dl,%dl
f0104f54:	75 f2                	jne    f0104f48 <strchr+0xc>
		if (*s == c)
			return (char *) s;
	return 0;
f0104f56:	b8 00 00 00 00       	mov    $0x0,%eax
}
f0104f5b:	5d                   	pop    %ebp
f0104f5c:	c3                   	ret    

f0104f5d <strfind>:

// Return a pointer to the first occurrence of 'c' in 's',
// or a pointer to the string-ending null character if the string has no 'c'.
char *
strfind(const char *s, char c)
{
f0104f5d:	55                   	push   %ebp
f0104f5e:	89 e5                	mov    %esp,%ebp
f0104f60:	8b 45 08             	mov    0x8(%ebp),%eax
f0104f63:	0f b6 4d 0c          	movzbl 0xc(%ebp),%ecx
	for (; *s; s++)
f0104f67:	eb 03                	jmp    f0104f6c <strfind+0xf>
f0104f69:	83 c0 01             	add    $0x1,%eax
f0104f6c:	0f b6 10             	movzbl (%eax),%edx
		if (*s == c)
f0104f6f:	38 ca                	cmp    %cl,%dl
f0104f71:	74 04                	je     f0104f77 <strfind+0x1a>
f0104f73:	84 d2                	test   %dl,%dl
f0104f75:	75 f2                	jne    f0104f69 <strfind+0xc>
			break;
	return (char *) s;
}
f0104f77:	5d                   	pop    %ebp
f0104f78:	c3                   	ret    

f0104f79 <memset>:

#if ASM
void *
memset(void *v, int c, size_t n)
{
f0104f79:	55                   	push   %ebp
f0104f7a:	89 e5                	mov    %esp,%ebp
f0104f7c:	57                   	push   %edi
f0104f7d:	56                   	push   %esi
f0104f7e:	53                   	push   %ebx
f0104f7f:	8b 55 08             	mov    0x8(%ebp),%edx
f0104f82:	8b 4d 10             	mov    0x10(%ebp),%ecx
	char *p = v;

	if (n == 0)
f0104f85:	85 c9                	test   %ecx,%ecx
f0104f87:	74 37                	je     f0104fc0 <memset+0x47>
		return v;
	if ((int)v%4 == 0 && n%4 == 0) {
f0104f89:	f6 c2 03             	test   $0x3,%dl
f0104f8c:	75 2a                	jne    f0104fb8 <memset+0x3f>
f0104f8e:	f6 c1 03             	test   $0x3,%cl
f0104f91:	75 25                	jne    f0104fb8 <memset+0x3f>
		c &= 0xFF;
f0104f93:	0f b6 5d 0c          	movzbl 0xc(%ebp),%ebx
		c = (c<<24)|(c<<16)|(c<<8)|c;
f0104f97:	89 df                	mov    %ebx,%edi
f0104f99:	c1 e7 08             	shl    $0x8,%edi
f0104f9c:	89 de                	mov    %ebx,%esi
f0104f9e:	c1 e6 18             	shl    $0x18,%esi
f0104fa1:	89 d8                	mov    %ebx,%eax
f0104fa3:	c1 e0 10             	shl    $0x10,%eax
f0104fa6:	09 f0                	or     %esi,%eax
f0104fa8:	09 c3                	or     %eax,%ebx
		asm volatile("cld; rep stosl\n"
			: "=D" (p), "=c" (n)
			: "D" (p), "a" (c), "c" (n/4)
f0104faa:	c1 e9 02             	shr    $0x2,%ecx
	if (n == 0)
		return v;
	if ((int)v%4 == 0 && n%4 == 0) {
		c &= 0xFF;
		c = (c<<24)|(c<<16)|(c<<8)|c;
		asm volatile("cld; rep stosl\n"
f0104fad:	89 f8                	mov    %edi,%eax
f0104faf:	09 d8                	or     %ebx,%eax
f0104fb1:	89 d7                	mov    %edx,%edi
f0104fb3:	fc                   	cld    
f0104fb4:	f3 ab                	rep stos %eax,%es:(%edi)
f0104fb6:	eb 08                	jmp    f0104fc0 <memset+0x47>
			: "=D" (p), "=c" (n)
			: "D" (p), "a" (c), "c" (n/4)
			: "cc", "memory");
	} else
		asm volatile("cld; rep stosb\n"
f0104fb8:	89 d7                	mov    %edx,%edi
f0104fba:	8b 45 0c             	mov    0xc(%ebp),%eax
f0104fbd:	fc                   	cld    
f0104fbe:	f3 aa                	rep stos %al,%es:(%edi)
			: "=D" (p), "=c" (n)
			: "0" (p), "a" (c), "1" (n)
			: "cc", "memory");
	return v;
}
f0104fc0:	89 d0                	mov    %edx,%eax
f0104fc2:	5b                   	pop    %ebx
f0104fc3:	5e                   	pop    %esi
f0104fc4:	5f                   	pop    %edi
f0104fc5:	5d                   	pop    %ebp
f0104fc6:	c3                   	ret    

f0104fc7 <memmove>:

void *
memmove(void *dst, const void *src, size_t n)
{
f0104fc7:	55                   	push   %ebp
f0104fc8:	89 e5                	mov    %esp,%ebp
f0104fca:	57                   	push   %edi
f0104fcb:	56                   	push   %esi
f0104fcc:	8b 45 08             	mov    0x8(%ebp),%eax
f0104fcf:	8b 75 0c             	mov    0xc(%ebp),%esi
f0104fd2:	8b 4d 10             	mov    0x10(%ebp),%ecx
	const char *s;
	char *d;

	s = src;
	d = dst;
	if (s < d && s + n > d) {
f0104fd5:	39 c6                	cmp    %eax,%esi
f0104fd7:	73 35                	jae    f010500e <memmove+0x47>
f0104fd9:	8d 14 0e             	lea    (%esi,%ecx,1),%edx
f0104fdc:	39 d0                	cmp    %edx,%eax
f0104fde:	73 2e                	jae    f010500e <memmove+0x47>
		s += n;
		d += n;
f0104fe0:	8d 3c 08             	lea    (%eax,%ecx,1),%edi
		if ((int)s%4 == 0 && (int)d%4 == 0 && n%4 == 0)
f0104fe3:	89 d6                	mov    %edx,%esi
f0104fe5:	09 fe                	or     %edi,%esi
f0104fe7:	f7 c6 03 00 00 00    	test   $0x3,%esi
f0104fed:	75 13                	jne    f0105002 <memmove+0x3b>
f0104fef:	f6 c1 03             	test   $0x3,%cl
f0104ff2:	75 0e                	jne    f0105002 <memmove+0x3b>
			asm volatile("std; rep movsl\n"
f0104ff4:	83 ef 04             	sub    $0x4,%edi
f0104ff7:	8d 72 fc             	lea    -0x4(%edx),%esi
f0104ffa:	c1 e9 02             	shr    $0x2,%ecx
f0104ffd:	fd                   	std    
f0104ffe:	f3 a5                	rep movsl %ds:(%esi),%es:(%edi)
f0105000:	eb 09                	jmp    f010500b <memmove+0x44>
				:: "D" (d-4), "S" (s-4), "c" (n/4) : "cc", "memory");
		else
			asm volatile("std; rep movsb\n"
f0105002:	83 ef 01             	sub    $0x1,%edi
f0105005:	8d 72 ff             	lea    -0x1(%edx),%esi
f0105008:	fd                   	std    
f0105009:	f3 a4                	rep movsb %ds:(%esi),%es:(%edi)
				:: "D" (d-1), "S" (s-1), "c" (n) : "cc", "memory");
		// Some versions of GCC rely on DF being clear
		asm volatile("cld" ::: "cc");
f010500b:	fc                   	cld    
f010500c:	eb 1d                	jmp    f010502b <memmove+0x64>
	} else {
		if ((int)s%4 == 0 && (int)d%4 == 0 && n%4 == 0)
f010500e:	89 f2                	mov    %esi,%edx
f0105010:	09 c2                	or     %eax,%edx
f0105012:	f6 c2 03             	test   $0x3,%dl
f0105015:	75 0f                	jne    f0105026 <memmove+0x5f>
f0105017:	f6 c1 03             	test   $0x3,%cl
f010501a:	75 0a                	jne    f0105026 <memmove+0x5f>
			asm volatile("cld; rep movsl\n"
f010501c:	c1 e9 02             	shr    $0x2,%ecx
f010501f:	89 c7                	mov    %eax,%edi
f0105021:	fc                   	cld    
f0105022:	f3 a5                	rep movsl %ds:(%esi),%es:(%edi)
f0105024:	eb 05                	jmp    f010502b <memmove+0x64>
				:: "D" (d), "S" (s), "c" (n/4) : "cc", "memory");
		else
			asm volatile("cld; rep movsb\n"
f0105026:	89 c7                	mov    %eax,%edi
f0105028:	fc                   	cld    
f0105029:	f3 a4                	rep movsb %ds:(%esi),%es:(%edi)
				:: "D" (d), "S" (s), "c" (n) : "cc", "memory");
	}
	return dst;
}
f010502b:	5e                   	pop    %esi
f010502c:	5f                   	pop    %edi
f010502d:	5d                   	pop    %ebp
f010502e:	c3                   	ret    

f010502f <memcpy>:
}
#endif

void *
memcpy(void *dst, const void *src, size_t n)
{
f010502f:	55                   	push   %ebp
f0105030:	89 e5                	mov    %esp,%ebp
	return memmove(dst, src, n);
f0105032:	ff 75 10             	pushl  0x10(%ebp)
f0105035:	ff 75 0c             	pushl  0xc(%ebp)
f0105038:	ff 75 08             	pushl  0x8(%ebp)
f010503b:	e8 87 ff ff ff       	call   f0104fc7 <memmove>
}
f0105040:	c9                   	leave  
f0105041:	c3                   	ret    

f0105042 <memcmp>:

int
memcmp(const void *v1, const void *v2, size_t n)
{
f0105042:	55                   	push   %ebp
f0105043:	89 e5                	mov    %esp,%ebp
f0105045:	56                   	push   %esi
f0105046:	53                   	push   %ebx
f0105047:	8b 45 08             	mov    0x8(%ebp),%eax
f010504a:	8b 55 0c             	mov    0xc(%ebp),%edx
f010504d:	89 c6                	mov    %eax,%esi
f010504f:	03 75 10             	add    0x10(%ebp),%esi
	const uint8_t *s1 = (const uint8_t *) v1;
	const uint8_t *s2 = (const uint8_t *) v2;

	while (n-- > 0) {
f0105052:	eb 1a                	jmp    f010506e <memcmp+0x2c>
		if (*s1 != *s2)
f0105054:	0f b6 08             	movzbl (%eax),%ecx
f0105057:	0f b6 1a             	movzbl (%edx),%ebx
f010505a:	38 d9                	cmp    %bl,%cl
f010505c:	74 0a                	je     f0105068 <memcmp+0x26>
			return (int) *s1 - (int) *s2;
f010505e:	0f b6 c1             	movzbl %cl,%eax
f0105061:	0f b6 db             	movzbl %bl,%ebx
f0105064:	29 d8                	sub    %ebx,%eax
f0105066:	eb 0f                	jmp    f0105077 <memcmp+0x35>
		s1++, s2++;
f0105068:	83 c0 01             	add    $0x1,%eax
f010506b:	83 c2 01             	add    $0x1,%edx
memcmp(const void *v1, const void *v2, size_t n)
{
	const uint8_t *s1 = (const uint8_t *) v1;
	const uint8_t *s2 = (const uint8_t *) v2;

	while (n-- > 0) {
f010506e:	39 f0                	cmp    %esi,%eax
f0105070:	75 e2                	jne    f0105054 <memcmp+0x12>
		if (*s1 != *s2)
			return (int) *s1 - (int) *s2;
		s1++, s2++;
	}

	return 0;
f0105072:	b8 00 00 00 00       	mov    $0x0,%eax
}
f0105077:	5b                   	pop    %ebx
f0105078:	5e                   	pop    %esi
f0105079:	5d                   	pop    %ebp
f010507a:	c3                   	ret    

f010507b <memfind>:

void *
memfind(const void *s, int c, size_t n)
{
f010507b:	55                   	push   %ebp
f010507c:	89 e5                	mov    %esp,%ebp
f010507e:	8b 45 08             	mov    0x8(%ebp),%eax
f0105081:	8b 4d 0c             	mov    0xc(%ebp),%ecx
	const void *ends = (const char *) s + n;
f0105084:	89 c2                	mov    %eax,%edx
f0105086:	03 55 10             	add    0x10(%ebp),%edx
	for (; s < ends; s++)
f0105089:	eb 07                	jmp    f0105092 <memfind+0x17>
		if (*(const unsigned char *) s == (unsigned char) c)
f010508b:	38 08                	cmp    %cl,(%eax)
f010508d:	74 07                	je     f0105096 <memfind+0x1b>

void *
memfind(const void *s, int c, size_t n)
{
	const void *ends = (const char *) s + n;
	for (; s < ends; s++)
f010508f:	83 c0 01             	add    $0x1,%eax
f0105092:	39 d0                	cmp    %edx,%eax
f0105094:	72 f5                	jb     f010508b <memfind+0x10>
		if (*(const unsigned char *) s == (unsigned char) c)
			break;
	return (void *) s;
}
f0105096:	5d                   	pop    %ebp
f0105097:	c3                   	ret    

f0105098 <strtol>:

long
strtol(const char *s, char **endptr, int base)
{
f0105098:	55                   	push   %ebp
f0105099:	89 e5                	mov    %esp,%ebp
f010509b:	57                   	push   %edi
f010509c:	56                   	push   %esi
f010509d:	53                   	push   %ebx
f010509e:	8b 4d 08             	mov    0x8(%ebp),%ecx
f01050a1:	8b 5d 10             	mov    0x10(%ebp),%ebx
	int neg = 0;
	long val = 0;

	// gobble initial whitespace
	while (*s == ' ' || *s == '\t')
f01050a4:	eb 03                	jmp    f01050a9 <strtol+0x11>
		s++;
f01050a6:	83 c1 01             	add    $0x1,%ecx
{
	int neg = 0;
	long val = 0;

	// gobble initial whitespace
	while (*s == ' ' || *s == '\t')
f01050a9:	0f b6 01             	movzbl (%ecx),%eax
f01050ac:	3c 20                	cmp    $0x20,%al
f01050ae:	74 f6                	je     f01050a6 <strtol+0xe>
f01050b0:	3c 09                	cmp    $0x9,%al
f01050b2:	74 f2                	je     f01050a6 <strtol+0xe>
		s++;

	// plus/minus sign
	if (*s == '+')
f01050b4:	3c 2b                	cmp    $0x2b,%al
f01050b6:	75 0a                	jne    f01050c2 <strtol+0x2a>
		s++;
f01050b8:	83 c1 01             	add    $0x1,%ecx
}

long
strtol(const char *s, char **endptr, int base)
{
	int neg = 0;
f01050bb:	bf 00 00 00 00       	mov    $0x0,%edi
f01050c0:	eb 11                	jmp    f01050d3 <strtol+0x3b>
f01050c2:	bf 00 00 00 00       	mov    $0x0,%edi
		s++;

	// plus/minus sign
	if (*s == '+')
		s++;
	else if (*s == '-')
f01050c7:	3c 2d                	cmp    $0x2d,%al
f01050c9:	75 08                	jne    f01050d3 <strtol+0x3b>
		s++, neg = 1;
f01050cb:	83 c1 01             	add    $0x1,%ecx
f01050ce:	bf 01 00 00 00       	mov    $0x1,%edi

	// hex or octal base prefix
	if ((base == 0 || base == 16) && (s[0] == '0' && s[1] == 'x'))
f01050d3:	f7 c3 ef ff ff ff    	test   $0xffffffef,%ebx
f01050d9:	75 15                	jne    f01050f0 <strtol+0x58>
f01050db:	80 39 30             	cmpb   $0x30,(%ecx)
f01050de:	75 10                	jne    f01050f0 <strtol+0x58>
f01050e0:	80 79 01 78          	cmpb   $0x78,0x1(%ecx)
f01050e4:	75 7c                	jne    f0105162 <strtol+0xca>
		s += 2, base = 16;
f01050e6:	83 c1 02             	add    $0x2,%ecx
f01050e9:	bb 10 00 00 00       	mov    $0x10,%ebx
f01050ee:	eb 16                	jmp    f0105106 <strtol+0x6e>
	else if (base == 0 && s[0] == '0')
f01050f0:	85 db                	test   %ebx,%ebx
f01050f2:	75 12                	jne    f0105106 <strtol+0x6e>
		s++, base = 8;
	else if (base == 0)
		base = 10;
f01050f4:	bb 0a 00 00 00       	mov    $0xa,%ebx
		s++, neg = 1;

	// hex or octal base prefix
	if ((base == 0 || base == 16) && (s[0] == '0' && s[1] == 'x'))
		s += 2, base = 16;
	else if (base == 0 && s[0] == '0')
f01050f9:	80 39 30             	cmpb   $0x30,(%ecx)
f01050fc:	75 08                	jne    f0105106 <strtol+0x6e>
		s++, base = 8;
f01050fe:	83 c1 01             	add    $0x1,%ecx
f0105101:	bb 08 00 00 00       	mov    $0x8,%ebx
	else if (base == 0)
		base = 10;
f0105106:	b8 00 00 00 00       	mov    $0x0,%eax
f010510b:	89 5d 10             	mov    %ebx,0x10(%ebp)

	// digits
	while (1) {
		int dig;

		if (*s >= '0' && *s <= '9')
f010510e:	0f b6 11             	movzbl (%ecx),%edx
f0105111:	8d 72 d0             	lea    -0x30(%edx),%esi
f0105114:	89 f3                	mov    %esi,%ebx
f0105116:	80 fb 09             	cmp    $0x9,%bl
f0105119:	77 08                	ja     f0105123 <strtol+0x8b>
			dig = *s - '0';
f010511b:	0f be d2             	movsbl %dl,%edx
f010511e:	83 ea 30             	sub    $0x30,%edx
f0105121:	eb 22                	jmp    f0105145 <strtol+0xad>
		else if (*s >= 'a' && *s <= 'z')
f0105123:	8d 72 9f             	lea    -0x61(%edx),%esi
f0105126:	89 f3                	mov    %esi,%ebx
f0105128:	80 fb 19             	cmp    $0x19,%bl
f010512b:	77 08                	ja     f0105135 <strtol+0x9d>
			dig = *s - 'a' + 10;
f010512d:	0f be d2             	movsbl %dl,%edx
f0105130:	83 ea 57             	sub    $0x57,%edx
f0105133:	eb 10                	jmp    f0105145 <strtol+0xad>
		else if (*s >= 'A' && *s <= 'Z')
f0105135:	8d 72 bf             	lea    -0x41(%edx),%esi
f0105138:	89 f3                	mov    %esi,%ebx
f010513a:	80 fb 19             	cmp    $0x19,%bl
f010513d:	77 16                	ja     f0105155 <strtol+0xbd>
			dig = *s - 'A' + 10;
f010513f:	0f be d2             	movsbl %dl,%edx
f0105142:	83 ea 37             	sub    $0x37,%edx
		else
			break;
		if (dig >= base)
f0105145:	3b 55 10             	cmp    0x10(%ebp),%edx
f0105148:	7d 0b                	jge    f0105155 <strtol+0xbd>
			break;
		s++, val = (val * base) + dig;
f010514a:	83 c1 01             	add    $0x1,%ecx
f010514d:	0f af 45 10          	imul   0x10(%ebp),%eax
f0105151:	01 d0                	add    %edx,%eax
		// we don't properly detect overflow!
	}
f0105153:	eb b9                	jmp    f010510e <strtol+0x76>

	if (endptr)
f0105155:	83 7d 0c 00          	cmpl   $0x0,0xc(%ebp)
f0105159:	74 0d                	je     f0105168 <strtol+0xd0>
		*endptr = (char *) s;
f010515b:	8b 75 0c             	mov    0xc(%ebp),%esi
f010515e:	89 0e                	mov    %ecx,(%esi)
f0105160:	eb 06                	jmp    f0105168 <strtol+0xd0>
		s++, neg = 1;

	// hex or octal base prefix
	if ((base == 0 || base == 16) && (s[0] == '0' && s[1] == 'x'))
		s += 2, base = 16;
	else if (base == 0 && s[0] == '0')
f0105162:	85 db                	test   %ebx,%ebx
f0105164:	74 98                	je     f01050fe <strtol+0x66>
f0105166:	eb 9e                	jmp    f0105106 <strtol+0x6e>
		// we don't properly detect overflow!
	}

	if (endptr)
		*endptr = (char *) s;
	return (neg ? -val : val);
f0105168:	89 c2                	mov    %eax,%edx
f010516a:	f7 da                	neg    %edx
f010516c:	85 ff                	test   %edi,%edi
f010516e:	0f 45 c2             	cmovne %edx,%eax
}
f0105171:	5b                   	pop    %ebx
f0105172:	5e                   	pop    %esi
f0105173:	5f                   	pop    %edi
f0105174:	5d                   	pop    %ebp
f0105175:	c3                   	ret    
f0105176:	66 90                	xchg   %ax,%ax

f0105178 <mpentry_start>:
.set PROT_MODE_DSEG, 0x10	# kernel data segment selector

.code16           
.globl mpentry_start
mpentry_start:
	cli            
f0105178:	fa                   	cli    

	xorw    %ax, %ax
f0105179:	31 c0                	xor    %eax,%eax
	movw    %ax, %ds
f010517b:	8e d8                	mov    %eax,%ds
	movw    %ax, %es
f010517d:	8e c0                	mov    %eax,%es
	movw    %ax, %ss
f010517f:	8e d0                	mov    %eax,%ss

	lgdt    MPBOOTPHYS(gdtdesc)
f0105181:	0f 01 16             	lgdtl  (%esi)
f0105184:	74 70                	je     f01051f6 <inb+0x3>
	movl    %cr0, %eax
f0105186:	0f 20 c0             	mov    %cr0,%eax
	orl     $CR0_PE, %eax
f0105189:	66 83 c8 01          	or     $0x1,%ax
	movl    %eax, %cr0
f010518d:	0f 22 c0             	mov    %eax,%cr0

	ljmpl   $(PROT_MODE_CSEG), $(MPBOOTPHYS(start32))
f0105190:	66 ea 20 70 00 00    	ljmpw  $0x0,$0x7020
f0105196:	08 00                	or     %al,(%eax)

f0105198 <start32>:

.code32
start32:
	movw    $(PROT_MODE_DSEG), %ax
f0105198:	66 b8 10 00          	mov    $0x10,%ax
	movw    %ax, %ds
f010519c:	8e d8                	mov    %eax,%ds
	movw    %ax, %es
f010519e:	8e c0                	mov    %eax,%es
	movw    %ax, %ss
f01051a0:	8e d0                	mov    %eax,%ss
	movw    $0, %ax
f01051a2:	66 b8 00 00          	mov    $0x0,%ax
	movw    %ax, %fs
f01051a6:	8e e0                	mov    %eax,%fs
	movw    %ax, %gs
f01051a8:	8e e8                	mov    %eax,%gs

	# Set up initial page table. We cannot use kern_pgdir yet because
	# we are still running at a low EIP.
	movl    $(RELOC(entry_pgdir)), %eax
f01051aa:	b8 00 00 11 00       	mov    $0x110000,%eax
	movl    %eax, %cr3
f01051af:	0f 22 d8             	mov    %eax,%cr3
	# Turn on paging.
	movl    %cr0, %eax
f01051b2:	0f 20 c0             	mov    %cr0,%eax
	orl     $(CR0_PE|CR0_PG|CR0_WP), %eax
f01051b5:	0d 01 00 01 80       	or     $0x80010001,%eax
	movl    %eax, %cr0
f01051ba:	0f 22 c0             	mov    %eax,%cr0

	# Switch to the per-cpu stack allocated in boot_aps()
	movl    mpentry_kstack, %esp
f01051bd:	8b 25 04 6f 28 f0    	mov    0xf0286f04,%esp
	movl    $0x0, %ebp       # nuke frame pointer
f01051c3:	bd 00 00 00 00       	mov    $0x0,%ebp

	# Call mp_main().  (Exercise for the reader: why the indirect call?)
	movl    $mp_main, %eax
f01051c8:	b8 28 02 10 f0       	mov    $0xf0100228,%eax
	call    *%eax
f01051cd:	ff d0                	call   *%eax

f01051cf <spin>:

	# If mp_main returns (it shouldn't), loop.
spin:
	jmp     spin
f01051cf:	eb fe                	jmp    f01051cf <spin>
f01051d1:	8d 76 00             	lea    0x0(%esi),%esi

f01051d4 <gdt>:
	...
f01051dc:	ff                   	(bad)  
f01051dd:	ff 00                	incl   (%eax)
f01051df:	00 00                	add    %al,(%eax)
f01051e1:	9a cf 00 ff ff 00 00 	lcall  $0x0,$0xffff00cf
f01051e8:	00 92 cf 00 17 00    	add    %dl,0x1700cf(%edx)

f01051ec <gdtdesc>:
f01051ec:	17                   	pop    %ss
f01051ed:	00 5c 70 00          	add    %bl,0x0(%eax,%esi,2)
	...

f01051f2 <mpentry_end>:
	.word   0x17				# sizeof(gdt) - 1
	.long   MPBOOTPHYS(gdt)			# address gdt

.globl mpentry_end
mpentry_end:
	nop
f01051f2:	90                   	nop

f01051f3 <inb>:
	asm volatile("int3");
}

static inline uint8_t
inb(int port)
{
f01051f3:	55                   	push   %ebp
f01051f4:	89 e5                	mov    %esp,%ebp
	uint8_t data;
	asm volatile("inb %w1,%0" : "=a" (data) : "d" (port));
f01051f6:	89 c2                	mov    %eax,%edx
f01051f8:	ec                   	in     (%dx),%al
	return data;
}
f01051f9:	5d                   	pop    %ebp
f01051fa:	c3                   	ret    

f01051fb <outb>:
		     : "memory", "cc");
}

static inline void
outb(int port, uint8_t data)
{
f01051fb:	55                   	push   %ebp
f01051fc:	89 e5                	mov    %esp,%ebp
f01051fe:	89 c1                	mov    %eax,%ecx
f0105200:	89 d0                	mov    %edx,%eax
	asm volatile("outb %0,%w1" : : "a" (data), "d" (port));
f0105202:	89 ca                	mov    %ecx,%edx
f0105204:	ee                   	out    %al,(%dx)
}
f0105205:	5d                   	pop    %ebp
f0105206:	c3                   	ret    

f0105207 <sum>:
#define MPIOINTR  0x03  // One per bus interrupt source
#define MPLINTR   0x04  // One per system interrupt source

static uint8_t
sum(void *addr, int len)
{
f0105207:	55                   	push   %ebp
f0105208:	89 e5                	mov    %esp,%ebp
f010520a:	56                   	push   %esi
f010520b:	53                   	push   %ebx
	int i, sum;

	sum = 0;
f010520c:	bb 00 00 00 00       	mov    $0x0,%ebx
	for (i = 0; i < len; i++)
f0105211:	b9 00 00 00 00       	mov    $0x0,%ecx
f0105216:	eb 09                	jmp    f0105221 <sum+0x1a>
		sum += ((uint8_t *)addr)[i];
f0105218:	0f b6 34 08          	movzbl (%eax,%ecx,1),%esi
f010521c:	01 f3                	add    %esi,%ebx
sum(void *addr, int len)
{
	int i, sum;

	sum = 0;
	for (i = 0; i < len; i++)
f010521e:	83 c1 01             	add    $0x1,%ecx
f0105221:	39 d1                	cmp    %edx,%ecx
f0105223:	7c f3                	jl     f0105218 <sum+0x11>
		sum += ((uint8_t *)addr)[i];
	return sum;
}
f0105225:	89 d8                	mov    %ebx,%eax
f0105227:	5b                   	pop    %ebx
f0105228:	5e                   	pop    %esi
f0105229:	5d                   	pop    %ebp
f010522a:	c3                   	ret    

f010522b <_kaddr>:
 * virtual address.  It panics if you pass an invalid physical address. */
#define KADDR(pa) _kaddr(__FILE__, __LINE__, pa)

static inline void*
_kaddr(const char *file, int line, physaddr_t pa)
{
f010522b:	55                   	push   %ebp
f010522c:	89 e5                	mov    %esp,%ebp
f010522e:	53                   	push   %ebx
f010522f:	83 ec 04             	sub    $0x4,%esp
	if (PGNUM(pa) >= npages)
f0105232:	89 cb                	mov    %ecx,%ebx
f0105234:	c1 eb 0c             	shr    $0xc,%ebx
f0105237:	3b 1d 08 6f 28 f0    	cmp    0xf0286f08,%ebx
f010523d:	72 0d                	jb     f010524c <_kaddr+0x21>
		_panic(file, line, "KADDR called with invalid pa %08lx", pa);
f010523f:	51                   	push   %ecx
f0105240:	68 ec 5c 10 f0       	push   $0xf0105cec
f0105245:	52                   	push   %edx
f0105246:	50                   	push   %eax
f0105247:	e8 11 ae ff ff       	call   f010005d <_panic>
	return (void *)(pa + KERNBASE);
f010524c:	8d 81 00 00 00 f0    	lea    -0x10000000(%ecx),%eax
}
f0105252:	8b 5d fc             	mov    -0x4(%ebp),%ebx
f0105255:	c9                   	leave  
f0105256:	c3                   	ret    

f0105257 <mpsearch1>:

// Look for an MP structure in the len bytes at physical address addr.
static struct mp *
mpsearch1(physaddr_t a, int len)
{
f0105257:	55                   	push   %ebp
f0105258:	89 e5                	mov    %esp,%ebp
f010525a:	57                   	push   %edi
f010525b:	56                   	push   %esi
f010525c:	53                   	push   %ebx
f010525d:	83 ec 0c             	sub    $0xc,%esp
f0105260:	89 c6                	mov    %eax,%esi
f0105262:	89 d7                	mov    %edx,%edi
	struct mp *mp = KADDR(a), *end = KADDR(a + len);
f0105264:	89 c1                	mov    %eax,%ecx
f0105266:	ba 57 00 00 00       	mov    $0x57,%edx
f010526b:	b8 41 79 10 f0       	mov    $0xf0107941,%eax
f0105270:	e8 b6 ff ff ff       	call   f010522b <_kaddr>
f0105275:	89 c3                	mov    %eax,%ebx
f0105277:	8d 0c 37             	lea    (%edi,%esi,1),%ecx
f010527a:	ba 57 00 00 00       	mov    $0x57,%edx
f010527f:	b8 41 79 10 f0       	mov    $0xf0107941,%eax
f0105284:	e8 a2 ff ff ff       	call   f010522b <_kaddr>
f0105289:	89 c6                	mov    %eax,%esi

	for (; mp < end; mp++)
f010528b:	eb 2a                	jmp    f01052b7 <mpsearch1+0x60>
		if (memcmp(mp->signature, "_MP_", 4) == 0 &&
f010528d:	83 ec 04             	sub    $0x4,%esp
f0105290:	6a 04                	push   $0x4
f0105292:	68 51 79 10 f0       	push   $0xf0107951
f0105297:	53                   	push   %ebx
f0105298:	e8 a5 fd ff ff       	call   f0105042 <memcmp>
f010529d:	83 c4 10             	add    $0x10,%esp
f01052a0:	85 c0                	test   %eax,%eax
f01052a2:	75 10                	jne    f01052b4 <mpsearch1+0x5d>
		    sum(mp, sizeof(*mp)) == 0)
f01052a4:	ba 10 00 00 00       	mov    $0x10,%edx
f01052a9:	89 d8                	mov    %ebx,%eax
f01052ab:	e8 57 ff ff ff       	call   f0105207 <sum>
mpsearch1(physaddr_t a, int len)
{
	struct mp *mp = KADDR(a), *end = KADDR(a + len);

	for (; mp < end; mp++)
		if (memcmp(mp->signature, "_MP_", 4) == 0 &&
f01052b0:	84 c0                	test   %al,%al
f01052b2:	74 0e                	je     f01052c2 <mpsearch1+0x6b>
static struct mp *
mpsearch1(physaddr_t a, int len)
{
	struct mp *mp = KADDR(a), *end = KADDR(a + len);

	for (; mp < end; mp++)
f01052b4:	83 c3 10             	add    $0x10,%ebx
f01052b7:	39 f3                	cmp    %esi,%ebx
f01052b9:	72 d2                	jb     f010528d <mpsearch1+0x36>
		if (memcmp(mp->signature, "_MP_", 4) == 0 &&
		    sum(mp, sizeof(*mp)) == 0)
			return mp;
	return NULL;
f01052bb:	b8 00 00 00 00       	mov    $0x0,%eax
f01052c0:	eb 02                	jmp    f01052c4 <mpsearch1+0x6d>
f01052c2:	89 d8                	mov    %ebx,%eax
}
f01052c4:	8d 65 f4             	lea    -0xc(%ebp),%esp
f01052c7:	5b                   	pop    %ebx
f01052c8:	5e                   	pop    %esi
f01052c9:	5f                   	pop    %edi
f01052ca:	5d                   	pop    %ebp
f01052cb:	c3                   	ret    

f01052cc <mpsearch>:
// 1) in the first KB of the EBDA;
// 2) if there is no EBDA, in the last KB of system base memory;
// 3) in the BIOS ROM between 0xE0000 and 0xFFFFF.
static struct mp *
mpsearch(void)
{
f01052cc:	55                   	push   %ebp
f01052cd:	89 e5                	mov    %esp,%ebp
f01052cf:	83 ec 08             	sub    $0x8,%esp
	struct mp *mp;

	static_assert(sizeof(*mp) == 16);

	// The BIOS data area lives in 16-bit segment 0x40.
	bda = (uint8_t *) KADDR(0x40 << 4);
f01052d2:	b9 00 04 00 00       	mov    $0x400,%ecx
f01052d7:	ba 6f 00 00 00       	mov    $0x6f,%edx
f01052dc:	b8 41 79 10 f0       	mov    $0xf0107941,%eax
f01052e1:	e8 45 ff ff ff       	call   f010522b <_kaddr>

	// [MP 4] The 16-bit segment of the EBDA is in the two bytes
	// starting at byte 0x0E of the BDA.  0 if not present.
	if ((p = *(uint16_t *) (bda + 0x0E))) {
f01052e6:	0f b7 50 0e          	movzwl 0xe(%eax),%edx
f01052ea:	85 d2                	test   %edx,%edx
f01052ec:	74 17                	je     f0105305 <mpsearch+0x39>
		p <<= 4;	// Translate from segment to PA
		if ((mp = mpsearch1(p, 1024)))
f01052ee:	89 d0                	mov    %edx,%eax
f01052f0:	c1 e0 04             	shl    $0x4,%eax
f01052f3:	ba 00 04 00 00       	mov    $0x400,%edx
f01052f8:	e8 5a ff ff ff       	call   f0105257 <mpsearch1>
			return mp;
f01052fd:	89 c2                	mov    %eax,%edx

	// [MP 4] The 16-bit segment of the EBDA is in the two bytes
	// starting at byte 0x0E of the BDA.  0 if not present.
	if ((p = *(uint16_t *) (bda + 0x0E))) {
		p <<= 4;	// Translate from segment to PA
		if ((mp = mpsearch1(p, 1024)))
f01052ff:	85 c0                	test   %eax,%eax
f0105301:	75 2f                	jne    f0105332 <mpsearch+0x66>
f0105303:	eb 1c                	jmp    f0105321 <mpsearch+0x55>
			return mp;
	} else {
		// The size of base memory, in KB is in the two bytes
		// starting at 0x13 of the BDA.
		p = *(uint16_t *) (bda + 0x13) * 1024;
		if ((mp = mpsearch1(p - 1024, 1024)))
f0105305:	0f b7 40 13          	movzwl 0x13(%eax),%eax
f0105309:	c1 e0 0a             	shl    $0xa,%eax
f010530c:	2d 00 04 00 00       	sub    $0x400,%eax
f0105311:	ba 00 04 00 00       	mov    $0x400,%edx
f0105316:	e8 3c ff ff ff       	call   f0105257 <mpsearch1>
			return mp;
f010531b:	89 c2                	mov    %eax,%edx
			return mp;
	} else {
		// The size of base memory, in KB is in the two bytes
		// starting at 0x13 of the BDA.
		p = *(uint16_t *) (bda + 0x13) * 1024;
		if ((mp = mpsearch1(p - 1024, 1024)))
f010531d:	85 c0                	test   %eax,%eax
f010531f:	75 11                	jne    f0105332 <mpsearch+0x66>
			return mp;
	}
	return mpsearch1(0xF0000, 0x10000);
f0105321:	ba 00 00 01 00       	mov    $0x10000,%edx
f0105326:	b8 00 00 0f 00       	mov    $0xf0000,%eax
f010532b:	e8 27 ff ff ff       	call   f0105257 <mpsearch1>
f0105330:	89 c2                	mov    %eax,%edx
}
f0105332:	89 d0                	mov    %edx,%eax
f0105334:	c9                   	leave  
f0105335:	c3                   	ret    

f0105336 <mpconfig>:
// Search for an MP configuration table.  For now, don't accept the
// default configurations (physaddr == 0).
// Check for the correct signature, checksum, and version.
static struct mpconf *
mpconfig(struct mp **pmp)
{
f0105336:	55                   	push   %ebp
f0105337:	89 e5                	mov    %esp,%ebp
f0105339:	57                   	push   %edi
f010533a:	56                   	push   %esi
f010533b:	53                   	push   %ebx
f010533c:	83 ec 1c             	sub    $0x1c,%esp
f010533f:	89 45 e4             	mov    %eax,-0x1c(%ebp)
	struct mpconf *conf;
	struct mp *mp;

	if ((mp = mpsearch()) == 0)
f0105342:	e8 85 ff ff ff       	call   f01052cc <mpsearch>
f0105347:	85 c0                	test   %eax,%eax
f0105349:	0f 84 ee 00 00 00    	je     f010543d <mpconfig+0x107>
f010534f:	89 c7                	mov    %eax,%edi
		return NULL;
	if (mp->physaddr == 0 || mp->type != 0) {
f0105351:	8b 48 04             	mov    0x4(%eax),%ecx
f0105354:	85 c9                	test   %ecx,%ecx
f0105356:	74 06                	je     f010535e <mpconfig+0x28>
f0105358:	80 78 0b 00          	cmpb   $0x0,0xb(%eax)
f010535c:	74 1a                	je     f0105378 <mpconfig+0x42>
		cprintf("SMP: Default configurations not implemented\n");
f010535e:	83 ec 0c             	sub    $0xc,%esp
f0105361:	68 b4 77 10 f0       	push   $0xf01077b4
f0105366:	e8 04 e5 ff ff       	call   f010386f <cprintf>
		return NULL;
f010536b:	83 c4 10             	add    $0x10,%esp
f010536e:	b8 00 00 00 00       	mov    $0x0,%eax
f0105373:	e9 ca 00 00 00       	jmp    f0105442 <mpconfig+0x10c>
	}
	conf = (struct mpconf *) KADDR(mp->physaddr);
f0105378:	ba 90 00 00 00       	mov    $0x90,%edx
f010537d:	b8 41 79 10 f0       	mov    $0xf0107941,%eax
f0105382:	e8 a4 fe ff ff       	call   f010522b <_kaddr>
f0105387:	89 c3                	mov    %eax,%ebx
	if (memcmp(conf, "PCMP", 4) != 0) {
f0105389:	83 ec 04             	sub    $0x4,%esp
f010538c:	6a 04                	push   $0x4
f010538e:	68 56 79 10 f0       	push   $0xf0107956
f0105393:	50                   	push   %eax
f0105394:	e8 a9 fc ff ff       	call   f0105042 <memcmp>
f0105399:	83 c4 10             	add    $0x10,%esp
f010539c:	85 c0                	test   %eax,%eax
f010539e:	74 1a                	je     f01053ba <mpconfig+0x84>
		cprintf("SMP: Incorrect MP configuration table signature\n");
f01053a0:	83 ec 0c             	sub    $0xc,%esp
f01053a3:	68 e4 77 10 f0       	push   $0xf01077e4
f01053a8:	e8 c2 e4 ff ff       	call   f010386f <cprintf>
		return NULL;
f01053ad:	83 c4 10             	add    $0x10,%esp
f01053b0:	b8 00 00 00 00       	mov    $0x0,%eax
f01053b5:	e9 88 00 00 00       	jmp    f0105442 <mpconfig+0x10c>
	}
	if (sum(conf, conf->length) != 0) {
f01053ba:	0f b7 73 04          	movzwl 0x4(%ebx),%esi
f01053be:	0f b7 d6             	movzwl %si,%edx
f01053c1:	89 d8                	mov    %ebx,%eax
f01053c3:	e8 3f fe ff ff       	call   f0105207 <sum>
f01053c8:	84 c0                	test   %al,%al
f01053ca:	74 17                	je     f01053e3 <mpconfig+0xad>
		cprintf("SMP: Bad MP configuration checksum\n");
f01053cc:	83 ec 0c             	sub    $0xc,%esp
f01053cf:	68 18 78 10 f0       	push   $0xf0107818
f01053d4:	e8 96 e4 ff ff       	call   f010386f <cprintf>
		return NULL;
f01053d9:	83 c4 10             	add    $0x10,%esp
f01053dc:	b8 00 00 00 00       	mov    $0x0,%eax
f01053e1:	eb 5f                	jmp    f0105442 <mpconfig+0x10c>
	}
	if (conf->version != 1 && conf->version != 4) {
f01053e3:	0f b6 43 06          	movzbl 0x6(%ebx),%eax
f01053e7:	3c 01                	cmp    $0x1,%al
f01053e9:	74 1f                	je     f010540a <mpconfig+0xd4>
f01053eb:	3c 04                	cmp    $0x4,%al
f01053ed:	74 1b                	je     f010540a <mpconfig+0xd4>
		cprintf("SMP: Unsupported MP version %d\n", conf->version);
f01053ef:	83 ec 08             	sub    $0x8,%esp
f01053f2:	0f b6 c0             	movzbl %al,%eax
f01053f5:	50                   	push   %eax
f01053f6:	68 3c 78 10 f0       	push   $0xf010783c
f01053fb:	e8 6f e4 ff ff       	call   f010386f <cprintf>
		return NULL;
f0105400:	83 c4 10             	add    $0x10,%esp
f0105403:	b8 00 00 00 00       	mov    $0x0,%eax
f0105408:	eb 38                	jmp    f0105442 <mpconfig+0x10c>
	}
	if ((sum((uint8_t *)conf + conf->length, conf->xlength) + conf->xchecksum) & 0xff) {
f010540a:	0f b7 53 28          	movzwl 0x28(%ebx),%edx
f010540e:	0f b7 c6             	movzwl %si,%eax
f0105411:	01 d8                	add    %ebx,%eax
f0105413:	e8 ef fd ff ff       	call   f0105207 <sum>
f0105418:	02 43 2a             	add    0x2a(%ebx),%al
f010541b:	74 17                	je     f0105434 <mpconfig+0xfe>
		cprintf("SMP: Bad MP configuration extended checksum\n");
f010541d:	83 ec 0c             	sub    $0xc,%esp
f0105420:	68 5c 78 10 f0       	push   $0xf010785c
f0105425:	e8 45 e4 ff ff       	call   f010386f <cprintf>
		return NULL;
f010542a:	83 c4 10             	add    $0x10,%esp
f010542d:	b8 00 00 00 00       	mov    $0x0,%eax
f0105432:	eb 0e                	jmp    f0105442 <mpconfig+0x10c>
	}
	*pmp = mp;
f0105434:	8b 45 e4             	mov    -0x1c(%ebp),%eax
f0105437:	89 38                	mov    %edi,(%eax)
	return conf;
f0105439:	89 d8                	mov    %ebx,%eax
f010543b:	eb 05                	jmp    f0105442 <mpconfig+0x10c>
{
	struct mpconf *conf;
	struct mp *mp;

	if ((mp = mpsearch()) == 0)
		return NULL;
f010543d:	b8 00 00 00 00       	mov    $0x0,%eax
		cprintf("SMP: Bad MP configuration extended checksum\n");
		return NULL;
	}
	*pmp = mp;
	return conf;
}
f0105442:	8d 65 f4             	lea    -0xc(%ebp),%esp
f0105445:	5b                   	pop    %ebx
f0105446:	5e                   	pop    %esi
f0105447:	5f                   	pop    %edi
f0105448:	5d                   	pop    %ebp
f0105449:	c3                   	ret    

f010544a <mp_init>:

void
mp_init(void)
{
f010544a:	55                   	push   %ebp
f010544b:	89 e5                	mov    %esp,%ebp
f010544d:	57                   	push   %edi
f010544e:	56                   	push   %esi
f010544f:	53                   	push   %ebx
f0105450:	83 ec 1c             	sub    $0x1c,%esp
	struct mpconf *conf;
	struct mpproc *proc;
	uint8_t *p;
	unsigned int i;

	bootcpu = &cpus[0];
f0105453:	c7 05 c0 73 28 f0 20 	movl   $0xf0287020,0xf02873c0
f010545a:	70 28 f0 
	if ((conf = mpconfig(&mp)) == 0)
f010545d:	8d 45 e4             	lea    -0x1c(%ebp),%eax
f0105460:	e8 d1 fe ff ff       	call   f0105336 <mpconfig>
f0105465:	85 c0                	test   %eax,%eax
f0105467:	0f 84 49 01 00 00    	je     f01055b6 <mp_init+0x16c>
f010546d:	89 c7                	mov    %eax,%edi
		return;
	ismp = 1;
f010546f:	c7 05 00 70 28 f0 01 	movl   $0x1,0xf0287000
f0105476:	00 00 00 
	lapicaddr = conf->lapicaddr;
f0105479:	8b 40 24             	mov    0x24(%eax),%eax
f010547c:	a3 00 80 2c f0       	mov    %eax,0xf02c8000

	for (p = conf->entries, i = 0; i < conf->entry; i++) {
f0105481:	8d 77 2c             	lea    0x2c(%edi),%esi
f0105484:	bb 00 00 00 00       	mov    $0x0,%ebx
f0105489:	e9 85 00 00 00       	jmp    f0105513 <mp_init+0xc9>
		switch (*p) {
f010548e:	0f b6 06             	movzbl (%esi),%eax
f0105491:	84 c0                	test   %al,%al
f0105493:	74 06                	je     f010549b <mp_init+0x51>
f0105495:	3c 04                	cmp    $0x4,%al
f0105497:	77 55                	ja     f01054ee <mp_init+0xa4>
f0105499:	eb 4e                	jmp    f01054e9 <mp_init+0x9f>
		case MPPROC:
			proc = (struct mpproc *)p;
			if (proc->flags & MPPROC_BOOT)
f010549b:	f6 46 03 02          	testb  $0x2,0x3(%esi)
f010549f:	74 11                	je     f01054b2 <mp_init+0x68>
				bootcpu = &cpus[ncpu];
f01054a1:	6b 05 c4 73 28 f0 74 	imul   $0x74,0xf02873c4,%eax
f01054a8:	05 20 70 28 f0       	add    $0xf0287020,%eax
f01054ad:	a3 c0 73 28 f0       	mov    %eax,0xf02873c0
			if (ncpu < NCPU) {
f01054b2:	a1 c4 73 28 f0       	mov    0xf02873c4,%eax
f01054b7:	83 f8 07             	cmp    $0x7,%eax
f01054ba:	7f 13                	jg     f01054cf <mp_init+0x85>
				cpus[ncpu].cpu_id = ncpu;
f01054bc:	6b d0 74             	imul   $0x74,%eax,%edx
f01054bf:	88 82 20 70 28 f0    	mov    %al,-0xfd78fe0(%edx)
				ncpu++;
f01054c5:	83 c0 01             	add    $0x1,%eax
f01054c8:	a3 c4 73 28 f0       	mov    %eax,0xf02873c4
f01054cd:	eb 15                	jmp    f01054e4 <mp_init+0x9a>
			} else {
				cprintf("SMP: too many CPUs, CPU %d disabled\n",
f01054cf:	83 ec 08             	sub    $0x8,%esp
f01054d2:	0f b6 46 01          	movzbl 0x1(%esi),%eax
f01054d6:	50                   	push   %eax
f01054d7:	68 8c 78 10 f0       	push   $0xf010788c
f01054dc:	e8 8e e3 ff ff       	call   f010386f <cprintf>
f01054e1:	83 c4 10             	add    $0x10,%esp
					proc->apicid);
			}
			p += sizeof(struct mpproc);
f01054e4:	83 c6 14             	add    $0x14,%esi
			continue;
f01054e7:	eb 27                	jmp    f0105510 <mp_init+0xc6>
		case MPBUS:
		case MPIOAPIC:
		case MPIOINTR:
		case MPLINTR:
			p += 8;
f01054e9:	83 c6 08             	add    $0x8,%esi
			continue;
f01054ec:	eb 22                	jmp    f0105510 <mp_init+0xc6>
		default:
			cprintf("mpinit: unknown config type %x\n", *p);
f01054ee:	83 ec 08             	sub    $0x8,%esp
f01054f1:	0f b6 c0             	movzbl %al,%eax
f01054f4:	50                   	push   %eax
f01054f5:	68 b4 78 10 f0       	push   $0xf01078b4
f01054fa:	e8 70 e3 ff ff       	call   f010386f <cprintf>
			ismp = 0;
f01054ff:	c7 05 00 70 28 f0 00 	movl   $0x0,0xf0287000
f0105506:	00 00 00 
			i = conf->entry;
f0105509:	0f b7 5f 22          	movzwl 0x22(%edi),%ebx
f010550d:	83 c4 10             	add    $0x10,%esp
	if ((conf = mpconfig(&mp)) == 0)
		return;
	ismp = 1;
	lapicaddr = conf->lapicaddr;

	for (p = conf->entries, i = 0; i < conf->entry; i++) {
f0105510:	83 c3 01             	add    $0x1,%ebx
f0105513:	0f b7 47 22          	movzwl 0x22(%edi),%eax
f0105517:	39 c3                	cmp    %eax,%ebx
f0105519:	0f 82 6f ff ff ff    	jb     f010548e <mp_init+0x44>
			ismp = 0;
			i = conf->entry;
		}
	}

	bootcpu->cpu_status = CPU_STARTED;
f010551f:	a1 c0 73 28 f0       	mov    0xf02873c0,%eax
f0105524:	c7 40 04 01 00 00 00 	movl   $0x1,0x4(%eax)
	if (!ismp) {
f010552b:	83 3d 00 70 28 f0 00 	cmpl   $0x0,0xf0287000
f0105532:	75 26                	jne    f010555a <mp_init+0x110>
		// Didn't like what we found; fall back to no MP.
		ncpu = 1;
f0105534:	c7 05 c4 73 28 f0 01 	movl   $0x1,0xf02873c4
f010553b:	00 00 00 
		lapicaddr = 0;
f010553e:	c7 05 00 80 2c f0 00 	movl   $0x0,0xf02c8000
f0105545:	00 00 00 
		cprintf("SMP: configuration not found, SMP disabled\n");
f0105548:	83 ec 0c             	sub    $0xc,%esp
f010554b:	68 d4 78 10 f0       	push   $0xf01078d4
f0105550:	e8 1a e3 ff ff       	call   f010386f <cprintf>
		return;
f0105555:	83 c4 10             	add    $0x10,%esp
f0105558:	eb 5c                	jmp    f01055b6 <mp_init+0x16c>
	}
	cprintf("SMP: CPU %d found %d CPU(s)\n", bootcpu->cpu_id,  ncpu);
f010555a:	83 ec 04             	sub    $0x4,%esp
f010555d:	ff 35 c4 73 28 f0    	pushl  0xf02873c4
f0105563:	0f b6 00             	movzbl (%eax),%eax
f0105566:	50                   	push   %eax
f0105567:	68 5b 79 10 f0       	push   $0xf010795b
f010556c:	e8 fe e2 ff ff       	call   f010386f <cprintf>

	if (mp->imcrp) {
f0105571:	83 c4 10             	add    $0x10,%esp
f0105574:	8b 45 e4             	mov    -0x1c(%ebp),%eax
f0105577:	80 78 0c 00          	cmpb   $0x0,0xc(%eax)
f010557b:	74 39                	je     f01055b6 <mp_init+0x16c>
		// [MP 3.2.6.1] If the hardware implements PIC mode,
		// switch to getting interrupts from the LAPIC.
		cprintf("SMP: Setting IMCR to switch from PIC mode to symmetric I/O mode\n");
f010557d:	83 ec 0c             	sub    $0xc,%esp
f0105580:	68 00 79 10 f0       	push   $0xf0107900
f0105585:	e8 e5 e2 ff ff       	call   f010386f <cprintf>
		outb(0x22, 0x70);   // Select IMCR
f010558a:	ba 70 00 00 00       	mov    $0x70,%edx
f010558f:	b8 22 00 00 00       	mov    $0x22,%eax
f0105594:	e8 62 fc ff ff       	call   f01051fb <outb>
		outb(0x23, inb(0x23) | 1);  // Mask external interrupts.
f0105599:	b8 23 00 00 00       	mov    $0x23,%eax
f010559e:	e8 50 fc ff ff       	call   f01051f3 <inb>
f01055a3:	83 c8 01             	or     $0x1,%eax
f01055a6:	0f b6 d0             	movzbl %al,%edx
f01055a9:	b8 23 00 00 00       	mov    $0x23,%eax
f01055ae:	e8 48 fc ff ff       	call   f01051fb <outb>
f01055b3:	83 c4 10             	add    $0x10,%esp
	}
}
f01055b6:	8d 65 f4             	lea    -0xc(%ebp),%esp
f01055b9:	5b                   	pop    %ebx
f01055ba:	5e                   	pop    %esi
f01055bb:	5f                   	pop    %edi
f01055bc:	5d                   	pop    %ebp
f01055bd:	c3                   	ret    

f01055be <outb>:
		     : "memory", "cc");
}

static inline void
outb(int port, uint8_t data)
{
f01055be:	55                   	push   %ebp
f01055bf:	89 e5                	mov    %esp,%ebp
f01055c1:	89 c1                	mov    %eax,%ecx
f01055c3:	89 d0                	mov    %edx,%eax
	asm volatile("outb %0,%w1" : : "a" (data), "d" (port));
f01055c5:	89 ca                	mov    %ecx,%edx
f01055c7:	ee                   	out    %al,(%dx)
}
f01055c8:	5d                   	pop    %ebp
f01055c9:	c3                   	ret    

f01055ca <lapicw>:
physaddr_t lapicaddr;        // Initialized in mpconfig.c
volatile uint32_t *lapic;

static void
lapicw(int index, int value)
{
f01055ca:	55                   	push   %ebp
f01055cb:	89 e5                	mov    %esp,%ebp
	lapic[index] = value;
f01055cd:	8b 0d 04 80 2c f0    	mov    0xf02c8004,%ecx
f01055d3:	8d 04 81             	lea    (%ecx,%eax,4),%eax
f01055d6:	89 10                	mov    %edx,(%eax)
	lapic[ID];  // wait for write to finish, by reading
f01055d8:	a1 04 80 2c f0       	mov    0xf02c8004,%eax
f01055dd:	8b 40 20             	mov    0x20(%eax),%eax
}
f01055e0:	5d                   	pop    %ebp
f01055e1:	c3                   	ret    

f01055e2 <_kaddr>:
 * virtual address.  It panics if you pass an invalid physical address. */
#define KADDR(pa) _kaddr(__FILE__, __LINE__, pa)

static inline void*
_kaddr(const char *file, int line, physaddr_t pa)
{
f01055e2:	55                   	push   %ebp
f01055e3:	89 e5                	mov    %esp,%ebp
f01055e5:	53                   	push   %ebx
f01055e6:	83 ec 04             	sub    $0x4,%esp
	if (PGNUM(pa) >= npages)
f01055e9:	89 cb                	mov    %ecx,%ebx
f01055eb:	c1 eb 0c             	shr    $0xc,%ebx
f01055ee:	3b 1d 08 6f 28 f0    	cmp    0xf0286f08,%ebx
f01055f4:	72 0d                	jb     f0105603 <_kaddr+0x21>
		_panic(file, line, "KADDR called with invalid pa %08lx", pa);
f01055f6:	51                   	push   %ecx
f01055f7:	68 ec 5c 10 f0       	push   $0xf0105cec
f01055fc:	52                   	push   %edx
f01055fd:	50                   	push   %eax
f01055fe:	e8 5a aa ff ff       	call   f010005d <_panic>
	return (void *)(pa + KERNBASE);
f0105603:	8d 81 00 00 00 f0    	lea    -0x10000000(%ecx),%eax
}
f0105609:	8b 5d fc             	mov    -0x4(%ebp),%ebx
f010560c:	c9                   	leave  
f010560d:	c3                   	ret    

f010560e <cpunum>:
	lapicw(TPR, 0);
}

int
cpunum(void)
{
f010560e:	55                   	push   %ebp
f010560f:	89 e5                	mov    %esp,%ebp
	if (lapic)
f0105611:	a1 04 80 2c f0       	mov    0xf02c8004,%eax
f0105616:	85 c0                	test   %eax,%eax
f0105618:	74 08                	je     f0105622 <cpunum+0x14>
		return lapic[ID] >> 24;
f010561a:	8b 40 20             	mov    0x20(%eax),%eax
f010561d:	c1 e8 18             	shr    $0x18,%eax
f0105620:	eb 05                	jmp    f0105627 <cpunum+0x19>
	return 0;
f0105622:	b8 00 00 00 00       	mov    $0x0,%eax
}
f0105627:	5d                   	pop    %ebp
f0105628:	c3                   	ret    

f0105629 <lapic_init>:
}

void
lapic_init(void)
{
	if (!lapicaddr)
f0105629:	a1 00 80 2c f0       	mov    0xf02c8000,%eax
f010562e:	85 c0                	test   %eax,%eax
f0105630:	0f 84 21 01 00 00    	je     f0105757 <lapic_init+0x12e>
	lapic[ID];  // wait for write to finish, by reading
}

void
lapic_init(void)
{
f0105636:	55                   	push   %ebp
f0105637:	89 e5                	mov    %esp,%ebp
f0105639:	83 ec 10             	sub    $0x10,%esp
	if (!lapicaddr)
		return;

	// lapicaddr is the physical address of the LAPIC's 4K MMIO
	// region.  Map it in to virtual memory so we can access it.
	lapic = mmio_map_region(lapicaddr, 4096);
f010563c:	68 00 10 00 00       	push   $0x1000
f0105641:	50                   	push   %eax
f0105642:	e8 8e c7 ff ff       	call   f0101dd5 <mmio_map_region>
f0105647:	a3 04 80 2c f0       	mov    %eax,0xf02c8004

	// Enable local APIC; set spurious interrupt vector.
	lapicw(SVR, ENABLE | (IRQ_OFFSET + IRQ_SPURIOUS));
f010564c:	ba 27 01 00 00       	mov    $0x127,%edx
f0105651:	b8 3c 00 00 00       	mov    $0x3c,%eax
f0105656:	e8 6f ff ff ff       	call   f01055ca <lapicw>

	// The timer repeatedly counts down at bus frequency
	// from lapic[TICR] and then issues an interrupt.  
	// If we cared more about precise timekeeping,
	// TICR would be calibrated using an external time source.
	lapicw(TDCR, X1);
f010565b:	ba 0b 00 00 00       	mov    $0xb,%edx
f0105660:	b8 f8 00 00 00       	mov    $0xf8,%eax
f0105665:	e8 60 ff ff ff       	call   f01055ca <lapicw>
	lapicw(TIMER, PERIODIC | (IRQ_OFFSET + IRQ_TIMER));
f010566a:	ba 20 00 02 00       	mov    $0x20020,%edx
f010566f:	b8 c8 00 00 00       	mov    $0xc8,%eax
f0105674:	e8 51 ff ff ff       	call   f01055ca <lapicw>
	lapicw(TICR, 10000000); 
f0105679:	ba 80 96 98 00       	mov    $0x989680,%edx
f010567e:	b8 e0 00 00 00       	mov    $0xe0,%eax
f0105683:	e8 42 ff ff ff       	call   f01055ca <lapicw>
	//
	// According to Intel MP Specification, the BIOS should initialize
	// BSP's local APIC in Virtual Wire Mode, in which 8259A's
	// INTR is virtually connected to BSP's LINTIN0. In this mode,
	// we do not need to program the IOAPIC.
	if (thiscpu != bootcpu)
f0105688:	e8 81 ff ff ff       	call   f010560e <cpunum>
f010568d:	6b c0 74             	imul   $0x74,%eax,%eax
f0105690:	05 20 70 28 f0       	add    $0xf0287020,%eax
f0105695:	83 c4 10             	add    $0x10,%esp
f0105698:	39 05 c0 73 28 f0    	cmp    %eax,0xf02873c0
f010569e:	74 0f                	je     f01056af <lapic_init+0x86>
		lapicw(LINT0, MASKED);
f01056a0:	ba 00 00 01 00       	mov    $0x10000,%edx
f01056a5:	b8 d4 00 00 00       	mov    $0xd4,%eax
f01056aa:	e8 1b ff ff ff       	call   f01055ca <lapicw>

	// Disable NMI (LINT1) on all CPUs
	lapicw(LINT1, MASKED);
f01056af:	ba 00 00 01 00       	mov    $0x10000,%edx
f01056b4:	b8 d8 00 00 00       	mov    $0xd8,%eax
f01056b9:	e8 0c ff ff ff       	call   f01055ca <lapicw>

	// Disable performance counter overflow interrupts
	// on machines that provide that interrupt entry.
	if (((lapic[VER]>>16) & 0xFF) >= 4)
f01056be:	a1 04 80 2c f0       	mov    0xf02c8004,%eax
f01056c3:	8b 40 30             	mov    0x30(%eax),%eax
f01056c6:	c1 e8 10             	shr    $0x10,%eax
f01056c9:	3c 03                	cmp    $0x3,%al
f01056cb:	76 0f                	jbe    f01056dc <lapic_init+0xb3>
		lapicw(PCINT, MASKED);
f01056cd:	ba 00 00 01 00       	mov    $0x10000,%edx
f01056d2:	b8 d0 00 00 00       	mov    $0xd0,%eax
f01056d7:	e8 ee fe ff ff       	call   f01055ca <lapicw>

	// Map error interrupt to IRQ_ERROR.
	lapicw(ERROR, IRQ_OFFSET + IRQ_ERROR);
f01056dc:	ba 33 00 00 00       	mov    $0x33,%edx
f01056e1:	b8 dc 00 00 00       	mov    $0xdc,%eax
f01056e6:	e8 df fe ff ff       	call   f01055ca <lapicw>

	// Clear error status register (requires back-to-back writes).
	lapicw(ESR, 0);
f01056eb:	ba 00 00 00 00       	mov    $0x0,%edx
f01056f0:	b8 a0 00 00 00       	mov    $0xa0,%eax
f01056f5:	e8 d0 fe ff ff       	call   f01055ca <lapicw>
	lapicw(ESR, 0);
f01056fa:	ba 00 00 00 00       	mov    $0x0,%edx
f01056ff:	b8 a0 00 00 00       	mov    $0xa0,%eax
f0105704:	e8 c1 fe ff ff       	call   f01055ca <lapicw>

	// Ack any outstanding interrupts.
	lapicw(EOI, 0);
f0105709:	ba 00 00 00 00       	mov    $0x0,%edx
f010570e:	b8 2c 00 00 00       	mov    $0x2c,%eax
f0105713:	e8 b2 fe ff ff       	call   f01055ca <lapicw>

	// Send an Init Level De-Assert to synchronize arbitration ID's.
	lapicw(ICRHI, 0);
f0105718:	ba 00 00 00 00       	mov    $0x0,%edx
f010571d:	b8 c4 00 00 00       	mov    $0xc4,%eax
f0105722:	e8 a3 fe ff ff       	call   f01055ca <lapicw>
	lapicw(ICRLO, BCAST | INIT | LEVEL);
f0105727:	ba 00 85 08 00       	mov    $0x88500,%edx
f010572c:	b8 c0 00 00 00       	mov    $0xc0,%eax
f0105731:	e8 94 fe ff ff       	call   f01055ca <lapicw>
	while(lapic[ICRLO] & DELIVS)
f0105736:	8b 15 04 80 2c f0    	mov    0xf02c8004,%edx
f010573c:	8b 82 00 03 00 00    	mov    0x300(%edx),%eax
f0105742:	f6 c4 10             	test   $0x10,%ah
f0105745:	75 f5                	jne    f010573c <lapic_init+0x113>
		;

	// Enable interrupts on the APIC (but not on the processor).
	lapicw(TPR, 0);
f0105747:	ba 00 00 00 00       	mov    $0x0,%edx
f010574c:	b8 20 00 00 00       	mov    $0x20,%eax
f0105751:	e8 74 fe ff ff       	call   f01055ca <lapicw>
}
f0105756:	c9                   	leave  
f0105757:	f3 c3                	repz ret 

f0105759 <lapic_eoi>:

// Acknowledge interrupt.
void
lapic_eoi(void)
{
	if (lapic)
f0105759:	83 3d 04 80 2c f0 00 	cmpl   $0x0,0xf02c8004
f0105760:	74 13                	je     f0105775 <lapic_eoi+0x1c>
}

// Acknowledge interrupt.
void
lapic_eoi(void)
{
f0105762:	55                   	push   %ebp
f0105763:	89 e5                	mov    %esp,%ebp
	if (lapic)
		lapicw(EOI, 0);
f0105765:	ba 00 00 00 00       	mov    $0x0,%edx
f010576a:	b8 2c 00 00 00       	mov    $0x2c,%eax
f010576f:	e8 56 fe ff ff       	call   f01055ca <lapicw>
}
f0105774:	5d                   	pop    %ebp
f0105775:	f3 c3                	repz ret 

f0105777 <lapic_startap>:

// Start additional processor running entry code at addr.
// See Appendix B of MultiProcessor Specification.
void
lapic_startap(uint8_t apicid, uint32_t addr)
{
f0105777:	55                   	push   %ebp
f0105778:	89 e5                	mov    %esp,%ebp
f010577a:	56                   	push   %esi
f010577b:	53                   	push   %ebx
f010577c:	8b 75 08             	mov    0x8(%ebp),%esi
f010577f:	8b 5d 0c             	mov    0xc(%ebp),%ebx
	uint16_t *wrv;

	// "The BSP must initialize CMOS shutdown code to 0AH
	// and the warm reset vector (DWORD based at 40:67) to point at
	// the AP startup code prior to the [universal startup algorithm]."
	outb(IO_RTC, 0xF);  // offset 0xF is shutdown code
f0105782:	ba 0f 00 00 00       	mov    $0xf,%edx
f0105787:	b8 70 00 00 00       	mov    $0x70,%eax
f010578c:	e8 2d fe ff ff       	call   f01055be <outb>
	outb(IO_RTC+1, 0x0A);
f0105791:	ba 0a 00 00 00       	mov    $0xa,%edx
f0105796:	b8 71 00 00 00       	mov    $0x71,%eax
f010579b:	e8 1e fe ff ff       	call   f01055be <outb>
	wrv = (uint16_t *)KADDR((0x40 << 4 | 0x67));  // Warm reset vector
f01057a0:	b9 67 04 00 00       	mov    $0x467,%ecx
f01057a5:	ba 98 00 00 00       	mov    $0x98,%edx
f01057aa:	b8 78 79 10 f0       	mov    $0xf0107978,%eax
f01057af:	e8 2e fe ff ff       	call   f01055e2 <_kaddr>
	wrv[0] = 0;
f01057b4:	66 c7 00 00 00       	movw   $0x0,(%eax)
	wrv[1] = addr >> 4;
f01057b9:	89 da                	mov    %ebx,%edx
f01057bb:	c1 ea 04             	shr    $0x4,%edx
f01057be:	66 89 50 02          	mov    %dx,0x2(%eax)

	// "Universal startup algorithm."
	// Send INIT (level-triggered) interrupt to reset other CPU.
	lapicw(ICRHI, apicid << 24);
f01057c2:	c1 e6 18             	shl    $0x18,%esi
f01057c5:	89 f2                	mov    %esi,%edx
f01057c7:	b8 c4 00 00 00       	mov    $0xc4,%eax
f01057cc:	e8 f9 fd ff ff       	call   f01055ca <lapicw>
	lapicw(ICRLO, INIT | LEVEL | ASSERT);
f01057d1:	ba 00 c5 00 00       	mov    $0xc500,%edx
f01057d6:	b8 c0 00 00 00       	mov    $0xc0,%eax
f01057db:	e8 ea fd ff ff       	call   f01055ca <lapicw>
	microdelay(200);
	lapicw(ICRLO, INIT | LEVEL);
f01057e0:	ba 00 85 00 00       	mov    $0x8500,%edx
f01057e5:	b8 c0 00 00 00       	mov    $0xc0,%eax
f01057ea:	e8 db fd ff ff       	call   f01055ca <lapicw>
	// when it is in the halted state due to an INIT.  So the second
	// should be ignored, but it is part of the official Intel algorithm.
	// Bochs complains about the second one.  Too bad for Bochs.
	for (i = 0; i < 2; i++) {
		lapicw(ICRHI, apicid << 24);
		lapicw(ICRLO, STARTUP | (addr >> 12));
f01057ef:	c1 eb 0c             	shr    $0xc,%ebx
f01057f2:	80 cf 06             	or     $0x6,%bh
	// Regular hardware is supposed to only accept a STARTUP
	// when it is in the halted state due to an INIT.  So the second
	// should be ignored, but it is part of the official Intel algorithm.
	// Bochs complains about the second one.  Too bad for Bochs.
	for (i = 0; i < 2; i++) {
		lapicw(ICRHI, apicid << 24);
f01057f5:	89 f2                	mov    %esi,%edx
f01057f7:	b8 c4 00 00 00       	mov    $0xc4,%eax
f01057fc:	e8 c9 fd ff ff       	call   f01055ca <lapicw>
		lapicw(ICRLO, STARTUP | (addr >> 12));
f0105801:	89 da                	mov    %ebx,%edx
f0105803:	b8 c0 00 00 00       	mov    $0xc0,%eax
f0105808:	e8 bd fd ff ff       	call   f01055ca <lapicw>
	// Regular hardware is supposed to only accept a STARTUP
	// when it is in the halted state due to an INIT.  So the second
	// should be ignored, but it is part of the official Intel algorithm.
	// Bochs complains about the second one.  Too bad for Bochs.
	for (i = 0; i < 2; i++) {
		lapicw(ICRHI, apicid << 24);
f010580d:	89 f2                	mov    %esi,%edx
f010580f:	b8 c4 00 00 00       	mov    $0xc4,%eax
f0105814:	e8 b1 fd ff ff       	call   f01055ca <lapicw>
		lapicw(ICRLO, STARTUP | (addr >> 12));
f0105819:	89 da                	mov    %ebx,%edx
f010581b:	b8 c0 00 00 00       	mov    $0xc0,%eax
f0105820:	e8 a5 fd ff ff       	call   f01055ca <lapicw>
		microdelay(200);
	}
}
f0105825:	5b                   	pop    %ebx
f0105826:	5e                   	pop    %esi
f0105827:	5d                   	pop    %ebp
f0105828:	c3                   	ret    

f0105829 <lapic_ipi>:

void
lapic_ipi(int vector)
{
f0105829:	55                   	push   %ebp
f010582a:	89 e5                	mov    %esp,%ebp
	lapicw(ICRLO, OTHERS | FIXED | vector);
f010582c:	8b 55 08             	mov    0x8(%ebp),%edx
f010582f:	81 ca 00 00 0c 00    	or     $0xc0000,%edx
f0105835:	b8 c0 00 00 00       	mov    $0xc0,%eax
f010583a:	e8 8b fd ff ff       	call   f01055ca <lapicw>
	while (lapic[ICRLO] & DELIVS)
f010583f:	8b 15 04 80 2c f0    	mov    0xf02c8004,%edx
f0105845:	8b 82 00 03 00 00    	mov    0x300(%edx),%eax
f010584b:	f6 c4 10             	test   $0x10,%ah
f010584e:	75 f5                	jne    f0105845 <lapic_ipi+0x1c>
		;
}
f0105850:	5d                   	pop    %ebp
f0105851:	c3                   	ret    

f0105852 <xchg>:
	return tsc;
}

static inline uint32_t
xchg(volatile uint32_t *addr, uint32_t newval)
{
f0105852:	55                   	push   %ebp
f0105853:	89 e5                	mov    %esp,%ebp
f0105855:	89 c1                	mov    %eax,%ecx
	uint32_t result;

	// The + in "+m" denotes a read-modify-write operand.
	asm volatile("lock; xchgl %0, %1"
f0105857:	89 d0                	mov    %edx,%eax
f0105859:	f0 87 01             	lock xchg %eax,(%ecx)
		     : "+m" (*addr), "=a" (result)
		     : "1" (newval)
		     : "cc");
	return result;
}
f010585c:	5d                   	pop    %ebp
f010585d:	c3                   	ret    

f010585e <get_caller_pcs>:

#ifdef DEBUG_SPINLOCK
// Record the current call stack in pcs[] by following the %ebp chain.
static void
get_caller_pcs(uint32_t pcs[])
{
f010585e:	55                   	push   %ebp
f010585f:	89 e5                	mov    %esp,%ebp
f0105861:	53                   	push   %ebx

static inline uint32_t __attribute__((always_inline))
read_ebp(void)
{
	uint32_t ebp;
	asm volatile("movl %%ebp,%0" : "=r" (ebp));
f0105862:	89 e9                	mov    %ebp,%ecx
	uint32_t *ebp;
	int i;

	ebp = (uint32_t *)read_ebp();
	for (i = 0; i < 10; i++){
f0105864:	ba 00 00 00 00       	mov    $0x0,%edx
f0105869:	eb 0b                	jmp    f0105876 <get_caller_pcs+0x18>
		if (ebp == 0 || ebp < (uint32_t *)ULIM)
			break;
		pcs[i] = ebp[1];          // saved %eip
f010586b:	8b 59 04             	mov    0x4(%ecx),%ebx
f010586e:	89 1c 90             	mov    %ebx,(%eax,%edx,4)
		ebp = (uint32_t *)ebp[0]; // saved %ebp
f0105871:	8b 09                	mov    (%ecx),%ecx
{
	uint32_t *ebp;
	int i;

	ebp = (uint32_t *)read_ebp();
	for (i = 0; i < 10; i++){
f0105873:	83 c2 01             	add    $0x1,%edx
		if (ebp == 0 || ebp < (uint32_t *)ULIM)
f0105876:	81 f9 ff ff 7f ef    	cmp    $0xef7fffff,%ecx
f010587c:	76 11                	jbe    f010588f <get_caller_pcs+0x31>
f010587e:	83 fa 09             	cmp    $0x9,%edx
f0105881:	7e e8                	jle    f010586b <get_caller_pcs+0xd>
f0105883:	eb 0a                	jmp    f010588f <get_caller_pcs+0x31>
			break;
		pcs[i] = ebp[1];          // saved %eip
		ebp = (uint32_t *)ebp[0]; // saved %ebp
	}
	for (; i < 10; i++)
		pcs[i] = 0;
f0105885:	c7 04 90 00 00 00 00 	movl   $0x0,(%eax,%edx,4)
		if (ebp == 0 || ebp < (uint32_t *)ULIM)
			break;
		pcs[i] = ebp[1];          // saved %eip
		ebp = (uint32_t *)ebp[0]; // saved %ebp
	}
	for (; i < 10; i++)
f010588c:	83 c2 01             	add    $0x1,%edx
f010588f:	83 fa 09             	cmp    $0x9,%edx
f0105892:	7e f1                	jle    f0105885 <get_caller_pcs+0x27>
		pcs[i] = 0;
}
f0105894:	5b                   	pop    %ebx
f0105895:	5d                   	pop    %ebp
f0105896:	c3                   	ret    

f0105897 <holding>:

// Check whether this CPU is holding the lock.
static int
holding(struct spinlock *lock)
{
	return lock->locked && lock->cpu == thiscpu;
f0105897:	83 38 00             	cmpl   $0x0,(%eax)
f010589a:	74 21                	je     f01058bd <holding+0x26>
}

// Check whether this CPU is holding the lock.
static int
holding(struct spinlock *lock)
{
f010589c:	55                   	push   %ebp
f010589d:	89 e5                	mov    %esp,%ebp
f010589f:	53                   	push   %ebx
f01058a0:	83 ec 04             	sub    $0x4,%esp
	return lock->locked && lock->cpu == thiscpu;
f01058a3:	8b 58 08             	mov    0x8(%eax),%ebx
f01058a6:	e8 63 fd ff ff       	call   f010560e <cpunum>
f01058ab:	6b c0 74             	imul   $0x74,%eax,%eax
f01058ae:	05 20 70 28 f0       	add    $0xf0287020,%eax
f01058b3:	39 c3                	cmp    %eax,%ebx
f01058b5:	0f 94 c0             	sete   %al
f01058b8:	0f b6 c0             	movzbl %al,%eax
f01058bb:	eb 06                	jmp    f01058c3 <holding+0x2c>
f01058bd:	b8 00 00 00 00       	mov    $0x0,%eax
f01058c2:	c3                   	ret    
}
f01058c3:	83 c4 04             	add    $0x4,%esp
f01058c6:	5b                   	pop    %ebx
f01058c7:	5d                   	pop    %ebp
f01058c8:	c3                   	ret    

f01058c9 <__spin_initlock>:
#endif

void
__spin_initlock(struct spinlock *lk, char *name)
{
f01058c9:	55                   	push   %ebp
f01058ca:	89 e5                	mov    %esp,%ebp
f01058cc:	8b 45 08             	mov    0x8(%ebp),%eax
	lk->locked = 0;
f01058cf:	c7 00 00 00 00 00    	movl   $0x0,(%eax)
#ifdef DEBUG_SPINLOCK
	lk->name = name;
f01058d5:	8b 55 0c             	mov    0xc(%ebp),%edx
f01058d8:	89 50 04             	mov    %edx,0x4(%eax)
	lk->cpu = 0;
f01058db:	c7 40 08 00 00 00 00 	movl   $0x0,0x8(%eax)
#endif
}
f01058e2:	5d                   	pop    %ebp
f01058e3:	c3                   	ret    

f01058e4 <spin_lock>:
// Loops (spins) until the lock is acquired.
// Holding a lock for a long time may cause
// other CPUs to waste time spinning to acquire it.
void
spin_lock(struct spinlock *lk)
{
f01058e4:	55                   	push   %ebp
f01058e5:	89 e5                	mov    %esp,%ebp
f01058e7:	53                   	push   %ebx
f01058e8:	83 ec 04             	sub    $0x4,%esp
f01058eb:	8b 5d 08             	mov    0x8(%ebp),%ebx
#ifdef DEBUG_SPINLOCK
	if (holding(lk))
f01058ee:	89 d8                	mov    %ebx,%eax
f01058f0:	e8 a2 ff ff ff       	call   f0105897 <holding>
f01058f5:	85 c0                	test   %eax,%eax
f01058f7:	74 20                	je     f0105919 <spin_lock+0x35>
		panic("CPU %d cannot acquire %s: already holding", cpunum(), lk->name);
f01058f9:	8b 5b 04             	mov    0x4(%ebx),%ebx
f01058fc:	e8 0d fd ff ff       	call   f010560e <cpunum>
f0105901:	83 ec 0c             	sub    $0xc,%esp
f0105904:	53                   	push   %ebx
f0105905:	50                   	push   %eax
f0105906:	68 88 79 10 f0       	push   $0xf0107988
f010590b:	6a 41                	push   $0x41
f010590d:	68 ec 79 10 f0       	push   $0xf01079ec
f0105912:	e8 46 a7 ff ff       	call   f010005d <_panic>

	// The xchg is atomic.
	// It also serializes, so that reads after acquire are not
	// reordered before it. 
	while (xchg(&lk->locked, 1) != 0)
		asm volatile ("pause");
f0105917:	f3 90                	pause  
#endif

	// The xchg is atomic.
	// It also serializes, so that reads after acquire are not
	// reordered before it. 
	while (xchg(&lk->locked, 1) != 0)
f0105919:	ba 01 00 00 00       	mov    $0x1,%edx
f010591e:	89 d8                	mov    %ebx,%eax
f0105920:	e8 2d ff ff ff       	call   f0105852 <xchg>
f0105925:	85 c0                	test   %eax,%eax
f0105927:	75 ee                	jne    f0105917 <spin_lock+0x33>
		asm volatile ("pause");

	// Record info about lock acquisition for debugging.
#ifdef DEBUG_SPINLOCK
	lk->cpu = thiscpu;
f0105929:	e8 e0 fc ff ff       	call   f010560e <cpunum>
f010592e:	6b c0 74             	imul   $0x74,%eax,%eax
f0105931:	05 20 70 28 f0       	add    $0xf0287020,%eax
f0105936:	89 43 08             	mov    %eax,0x8(%ebx)
	get_caller_pcs(lk->pcs);
f0105939:	8d 43 0c             	lea    0xc(%ebx),%eax
f010593c:	e8 1d ff ff ff       	call   f010585e <get_caller_pcs>
#endif
}
f0105941:	8b 5d fc             	mov    -0x4(%ebp),%ebx
f0105944:	c9                   	leave  
f0105945:	c3                   	ret    

f0105946 <spin_unlock>:

// Release the lock.
void
spin_unlock(struct spinlock *lk)
{
f0105946:	55                   	push   %ebp
f0105947:	89 e5                	mov    %esp,%ebp
f0105949:	57                   	push   %edi
f010594a:	56                   	push   %esi
f010594b:	53                   	push   %ebx
f010594c:	83 ec 4c             	sub    $0x4c,%esp
f010594f:	8b 75 08             	mov    0x8(%ebp),%esi
#ifdef DEBUG_SPINLOCK
	if (!holding(lk)) {
f0105952:	89 f0                	mov    %esi,%eax
f0105954:	e8 3e ff ff ff       	call   f0105897 <holding>
f0105959:	85 c0                	test   %eax,%eax
f010595b:	0f 85 a5 00 00 00    	jne    f0105a06 <spin_unlock+0xc0>
		int i;
		uint32_t pcs[10];
		// Nab the acquiring EIP chain before it gets released
		memmove(pcs, lk->pcs, sizeof pcs);
f0105961:	83 ec 04             	sub    $0x4,%esp
f0105964:	6a 28                	push   $0x28
f0105966:	8d 46 0c             	lea    0xc(%esi),%eax
f0105969:	50                   	push   %eax
f010596a:	8d 5d c0             	lea    -0x40(%ebp),%ebx
f010596d:	53                   	push   %ebx
f010596e:	e8 54 f6 ff ff       	call   f0104fc7 <memmove>
		cprintf("CPU %d cannot release %s: held by CPU %d\nAcquired at:", 
			cpunum(), lk->name, lk->cpu->cpu_id);
f0105973:	8b 46 08             	mov    0x8(%esi),%eax
	if (!holding(lk)) {
		int i;
		uint32_t pcs[10];
		// Nab the acquiring EIP chain before it gets released
		memmove(pcs, lk->pcs, sizeof pcs);
		cprintf("CPU %d cannot release %s: held by CPU %d\nAcquired at:", 
f0105976:	0f b6 38             	movzbl (%eax),%edi
f0105979:	8b 76 04             	mov    0x4(%esi),%esi
f010597c:	e8 8d fc ff ff       	call   f010560e <cpunum>
f0105981:	57                   	push   %edi
f0105982:	56                   	push   %esi
f0105983:	50                   	push   %eax
f0105984:	68 b4 79 10 f0       	push   $0xf01079b4
f0105989:	e8 e1 de ff ff       	call   f010386f <cprintf>
f010598e:	83 c4 20             	add    $0x20,%esp
			cpunum(), lk->name, lk->cpu->cpu_id);
		for (i = 0; i < 10 && pcs[i]; i++) {
			struct Eipdebuginfo info;
			if (debuginfo_eip(pcs[i], &info) >= 0)
f0105991:	8d 7d a8             	lea    -0x58(%ebp),%edi
f0105994:	eb 54                	jmp    f01059ea <spin_unlock+0xa4>
f0105996:	83 ec 08             	sub    $0x8,%esp
f0105999:	57                   	push   %edi
f010599a:	50                   	push   %eax
f010599b:	e8 7c eb ff ff       	call   f010451c <debuginfo_eip>
f01059a0:	83 c4 10             	add    $0x10,%esp
f01059a3:	85 c0                	test   %eax,%eax
f01059a5:	78 27                	js     f01059ce <spin_unlock+0x88>
				cprintf("  %08x %s:%d: %.*s+%x\n", pcs[i],
					info.eip_file, info.eip_line,
					info.eip_fn_namelen, info.eip_fn_name,
					pcs[i] - info.eip_fn_addr);
f01059a7:	8b 06                	mov    (%esi),%eax
		cprintf("CPU %d cannot release %s: held by CPU %d\nAcquired at:", 
			cpunum(), lk->name, lk->cpu->cpu_id);
		for (i = 0; i < 10 && pcs[i]; i++) {
			struct Eipdebuginfo info;
			if (debuginfo_eip(pcs[i], &info) >= 0)
				cprintf("  %08x %s:%d: %.*s+%x\n", pcs[i],
f01059a9:	83 ec 04             	sub    $0x4,%esp
f01059ac:	89 c2                	mov    %eax,%edx
f01059ae:	2b 55 b8             	sub    -0x48(%ebp),%edx
f01059b1:	52                   	push   %edx
f01059b2:	ff 75 b0             	pushl  -0x50(%ebp)
f01059b5:	ff 75 b4             	pushl  -0x4c(%ebp)
f01059b8:	ff 75 ac             	pushl  -0x54(%ebp)
f01059bb:	ff 75 a8             	pushl  -0x58(%ebp)
f01059be:	50                   	push   %eax
f01059bf:	68 fc 79 10 f0       	push   $0xf01079fc
f01059c4:	e8 a6 de ff ff       	call   f010386f <cprintf>
f01059c9:	83 c4 20             	add    $0x20,%esp
f01059cc:	eb 12                	jmp    f01059e0 <spin_unlock+0x9a>
					info.eip_file, info.eip_line,
					info.eip_fn_namelen, info.eip_fn_name,
					pcs[i] - info.eip_fn_addr);
			else
				cprintf("  %08x\n", pcs[i]);
f01059ce:	83 ec 08             	sub    $0x8,%esp
f01059d1:	ff 36                	pushl  (%esi)
f01059d3:	68 13 7a 10 f0       	push   $0xf0107a13
f01059d8:	e8 92 de ff ff       	call   f010386f <cprintf>
f01059dd:	83 c4 10             	add    $0x10,%esp
f01059e0:	83 c3 04             	add    $0x4,%ebx
		uint32_t pcs[10];
		// Nab the acquiring EIP chain before it gets released
		memmove(pcs, lk->pcs, sizeof pcs);
		cprintf("CPU %d cannot release %s: held by CPU %d\nAcquired at:", 
			cpunum(), lk->name, lk->cpu->cpu_id);
		for (i = 0; i < 10 && pcs[i]; i++) {
f01059e3:	8d 45 e8             	lea    -0x18(%ebp),%eax
f01059e6:	39 c3                	cmp    %eax,%ebx
f01059e8:	74 08                	je     f01059f2 <spin_unlock+0xac>
f01059ea:	89 de                	mov    %ebx,%esi
f01059ec:	8b 03                	mov    (%ebx),%eax
f01059ee:	85 c0                	test   %eax,%eax
f01059f0:	75 a4                	jne    f0105996 <spin_unlock+0x50>
					info.eip_fn_namelen, info.eip_fn_name,
					pcs[i] - info.eip_fn_addr);
			else
				cprintf("  %08x\n", pcs[i]);
		}
		panic("spin_unlock");
f01059f2:	83 ec 04             	sub    $0x4,%esp
f01059f5:	68 1b 7a 10 f0       	push   $0xf0107a1b
f01059fa:	6a 67                	push   $0x67
f01059fc:	68 ec 79 10 f0       	push   $0xf01079ec
f0105a01:	e8 57 a6 ff ff       	call   f010005d <_panic>
	}

	lk->pcs[0] = 0;
f0105a06:	c7 46 0c 00 00 00 00 	movl   $0x0,0xc(%esi)
	lk->cpu = 0;
f0105a0d:	c7 46 08 00 00 00 00 	movl   $0x0,0x8(%esi)
	// The xchg instruction is atomic (i.e. uses the "lock" prefix) with
	// respect to any other instruction which references the same memory.
	// x86 CPUs will not reorder loads/stores across locked instructions
	// (vol 3, 8.2.2). Because xchg() is implemented using asm volatile,
	// gcc will not reorder C statements across the xchg.
	xchg(&lk->locked, 0);
f0105a14:	ba 00 00 00 00       	mov    $0x0,%edx
f0105a19:	89 f0                	mov    %esi,%eax
f0105a1b:	e8 32 fe ff ff       	call   f0105852 <xchg>
}
f0105a20:	8d 65 f4             	lea    -0xc(%ebp),%esp
f0105a23:	5b                   	pop    %ebx
f0105a24:	5e                   	pop    %esi
f0105a25:	5f                   	pop    %edi
f0105a26:	5d                   	pop    %ebp
f0105a27:	c3                   	ret    
f0105a28:	66 90                	xchg   %ax,%ax
f0105a2a:	66 90                	xchg   %ax,%ax
f0105a2c:	66 90                	xchg   %ax,%ax
f0105a2e:	66 90                	xchg   %ax,%ax

f0105a30 <__udivdi3>:
f0105a30:	55                   	push   %ebp
f0105a31:	57                   	push   %edi
f0105a32:	56                   	push   %esi
f0105a33:	53                   	push   %ebx
f0105a34:	83 ec 1c             	sub    $0x1c,%esp
f0105a37:	8b 74 24 3c          	mov    0x3c(%esp),%esi
f0105a3b:	8b 5c 24 30          	mov    0x30(%esp),%ebx
f0105a3f:	8b 4c 24 34          	mov    0x34(%esp),%ecx
f0105a43:	8b 7c 24 38          	mov    0x38(%esp),%edi
f0105a47:	85 f6                	test   %esi,%esi
f0105a49:	89 5c 24 08          	mov    %ebx,0x8(%esp)
f0105a4d:	89 ca                	mov    %ecx,%edx
f0105a4f:	89 f8                	mov    %edi,%eax
f0105a51:	75 3d                	jne    f0105a90 <__udivdi3+0x60>
f0105a53:	39 cf                	cmp    %ecx,%edi
f0105a55:	0f 87 c5 00 00 00    	ja     f0105b20 <__udivdi3+0xf0>
f0105a5b:	85 ff                	test   %edi,%edi
f0105a5d:	89 fd                	mov    %edi,%ebp
f0105a5f:	75 0b                	jne    f0105a6c <__udivdi3+0x3c>
f0105a61:	b8 01 00 00 00       	mov    $0x1,%eax
f0105a66:	31 d2                	xor    %edx,%edx
f0105a68:	f7 f7                	div    %edi
f0105a6a:	89 c5                	mov    %eax,%ebp
f0105a6c:	89 c8                	mov    %ecx,%eax
f0105a6e:	31 d2                	xor    %edx,%edx
f0105a70:	f7 f5                	div    %ebp
f0105a72:	89 c1                	mov    %eax,%ecx
f0105a74:	89 d8                	mov    %ebx,%eax
f0105a76:	89 cf                	mov    %ecx,%edi
f0105a78:	f7 f5                	div    %ebp
f0105a7a:	89 c3                	mov    %eax,%ebx
f0105a7c:	89 d8                	mov    %ebx,%eax
f0105a7e:	89 fa                	mov    %edi,%edx
f0105a80:	83 c4 1c             	add    $0x1c,%esp
f0105a83:	5b                   	pop    %ebx
f0105a84:	5e                   	pop    %esi
f0105a85:	5f                   	pop    %edi
f0105a86:	5d                   	pop    %ebp
f0105a87:	c3                   	ret    
f0105a88:	90                   	nop
f0105a89:	8d b4 26 00 00 00 00 	lea    0x0(%esi,%eiz,1),%esi
f0105a90:	39 ce                	cmp    %ecx,%esi
f0105a92:	77 74                	ja     f0105b08 <__udivdi3+0xd8>
f0105a94:	0f bd fe             	bsr    %esi,%edi
f0105a97:	83 f7 1f             	xor    $0x1f,%edi
f0105a9a:	0f 84 98 00 00 00    	je     f0105b38 <__udivdi3+0x108>
f0105aa0:	bb 20 00 00 00       	mov    $0x20,%ebx
f0105aa5:	89 f9                	mov    %edi,%ecx
f0105aa7:	89 c5                	mov    %eax,%ebp
f0105aa9:	29 fb                	sub    %edi,%ebx
f0105aab:	d3 e6                	shl    %cl,%esi
f0105aad:	89 d9                	mov    %ebx,%ecx
f0105aaf:	d3 ed                	shr    %cl,%ebp
f0105ab1:	89 f9                	mov    %edi,%ecx
f0105ab3:	d3 e0                	shl    %cl,%eax
f0105ab5:	09 ee                	or     %ebp,%esi
f0105ab7:	89 d9                	mov    %ebx,%ecx
f0105ab9:	89 44 24 0c          	mov    %eax,0xc(%esp)
f0105abd:	89 d5                	mov    %edx,%ebp
f0105abf:	8b 44 24 08          	mov    0x8(%esp),%eax
f0105ac3:	d3 ed                	shr    %cl,%ebp
f0105ac5:	89 f9                	mov    %edi,%ecx
f0105ac7:	d3 e2                	shl    %cl,%edx
f0105ac9:	89 d9                	mov    %ebx,%ecx
f0105acb:	d3 e8                	shr    %cl,%eax
f0105acd:	09 c2                	or     %eax,%edx
f0105acf:	89 d0                	mov    %edx,%eax
f0105ad1:	89 ea                	mov    %ebp,%edx
f0105ad3:	f7 f6                	div    %esi
f0105ad5:	89 d5                	mov    %edx,%ebp
f0105ad7:	89 c3                	mov    %eax,%ebx
f0105ad9:	f7 64 24 0c          	mull   0xc(%esp)
f0105add:	39 d5                	cmp    %edx,%ebp
f0105adf:	72 10                	jb     f0105af1 <__udivdi3+0xc1>
f0105ae1:	8b 74 24 08          	mov    0x8(%esp),%esi
f0105ae5:	89 f9                	mov    %edi,%ecx
f0105ae7:	d3 e6                	shl    %cl,%esi
f0105ae9:	39 c6                	cmp    %eax,%esi
f0105aeb:	73 07                	jae    f0105af4 <__udivdi3+0xc4>
f0105aed:	39 d5                	cmp    %edx,%ebp
f0105aef:	75 03                	jne    f0105af4 <__udivdi3+0xc4>
f0105af1:	83 eb 01             	sub    $0x1,%ebx
f0105af4:	31 ff                	xor    %edi,%edi
f0105af6:	89 d8                	mov    %ebx,%eax
f0105af8:	89 fa                	mov    %edi,%edx
f0105afa:	83 c4 1c             	add    $0x1c,%esp
f0105afd:	5b                   	pop    %ebx
f0105afe:	5e                   	pop    %esi
f0105aff:	5f                   	pop    %edi
f0105b00:	5d                   	pop    %ebp
f0105b01:	c3                   	ret    
f0105b02:	8d b6 00 00 00 00    	lea    0x0(%esi),%esi
f0105b08:	31 ff                	xor    %edi,%edi
f0105b0a:	31 db                	xor    %ebx,%ebx
f0105b0c:	89 d8                	mov    %ebx,%eax
f0105b0e:	89 fa                	mov    %edi,%edx
f0105b10:	83 c4 1c             	add    $0x1c,%esp
f0105b13:	5b                   	pop    %ebx
f0105b14:	5e                   	pop    %esi
f0105b15:	5f                   	pop    %edi
f0105b16:	5d                   	pop    %ebp
f0105b17:	c3                   	ret    
f0105b18:	90                   	nop
f0105b19:	8d b4 26 00 00 00 00 	lea    0x0(%esi,%eiz,1),%esi
f0105b20:	89 d8                	mov    %ebx,%eax
f0105b22:	f7 f7                	div    %edi
f0105b24:	31 ff                	xor    %edi,%edi
f0105b26:	89 c3                	mov    %eax,%ebx
f0105b28:	89 d8                	mov    %ebx,%eax
f0105b2a:	89 fa                	mov    %edi,%edx
f0105b2c:	83 c4 1c             	add    $0x1c,%esp
f0105b2f:	5b                   	pop    %ebx
f0105b30:	5e                   	pop    %esi
f0105b31:	5f                   	pop    %edi
f0105b32:	5d                   	pop    %ebp
f0105b33:	c3                   	ret    
f0105b34:	8d 74 26 00          	lea    0x0(%esi,%eiz,1),%esi
f0105b38:	39 ce                	cmp    %ecx,%esi
f0105b3a:	72 0c                	jb     f0105b48 <__udivdi3+0x118>
f0105b3c:	31 db                	xor    %ebx,%ebx
f0105b3e:	3b 44 24 08          	cmp    0x8(%esp),%eax
f0105b42:	0f 87 34 ff ff ff    	ja     f0105a7c <__udivdi3+0x4c>
f0105b48:	bb 01 00 00 00       	mov    $0x1,%ebx
f0105b4d:	e9 2a ff ff ff       	jmp    f0105a7c <__udivdi3+0x4c>
f0105b52:	66 90                	xchg   %ax,%ax
f0105b54:	66 90                	xchg   %ax,%ax
f0105b56:	66 90                	xchg   %ax,%ax
f0105b58:	66 90                	xchg   %ax,%ax
f0105b5a:	66 90                	xchg   %ax,%ax
f0105b5c:	66 90                	xchg   %ax,%ax
f0105b5e:	66 90                	xchg   %ax,%ax

f0105b60 <__umoddi3>:
f0105b60:	55                   	push   %ebp
f0105b61:	57                   	push   %edi
f0105b62:	56                   	push   %esi
f0105b63:	53                   	push   %ebx
f0105b64:	83 ec 1c             	sub    $0x1c,%esp
f0105b67:	8b 54 24 3c          	mov    0x3c(%esp),%edx
f0105b6b:	8b 4c 24 30          	mov    0x30(%esp),%ecx
f0105b6f:	8b 74 24 34          	mov    0x34(%esp),%esi
f0105b73:	8b 7c 24 38          	mov    0x38(%esp),%edi
f0105b77:	85 d2                	test   %edx,%edx
f0105b79:	89 4c 24 0c          	mov    %ecx,0xc(%esp)
f0105b7d:	89 4c 24 08          	mov    %ecx,0x8(%esp)
f0105b81:	89 f3                	mov    %esi,%ebx
f0105b83:	89 3c 24             	mov    %edi,(%esp)
f0105b86:	89 74 24 04          	mov    %esi,0x4(%esp)
f0105b8a:	75 1c                	jne    f0105ba8 <__umoddi3+0x48>
f0105b8c:	39 f7                	cmp    %esi,%edi
f0105b8e:	76 50                	jbe    f0105be0 <__umoddi3+0x80>
f0105b90:	89 c8                	mov    %ecx,%eax
f0105b92:	89 f2                	mov    %esi,%edx
f0105b94:	f7 f7                	div    %edi
f0105b96:	89 d0                	mov    %edx,%eax
f0105b98:	31 d2                	xor    %edx,%edx
f0105b9a:	83 c4 1c             	add    $0x1c,%esp
f0105b9d:	5b                   	pop    %ebx
f0105b9e:	5e                   	pop    %esi
f0105b9f:	5f                   	pop    %edi
f0105ba0:	5d                   	pop    %ebp
f0105ba1:	c3                   	ret    
f0105ba2:	8d b6 00 00 00 00    	lea    0x0(%esi),%esi
f0105ba8:	39 f2                	cmp    %esi,%edx
f0105baa:	89 d0                	mov    %edx,%eax
f0105bac:	77 52                	ja     f0105c00 <__umoddi3+0xa0>
f0105bae:	0f bd ea             	bsr    %edx,%ebp
f0105bb1:	83 f5 1f             	xor    $0x1f,%ebp
f0105bb4:	75 5a                	jne    f0105c10 <__umoddi3+0xb0>
f0105bb6:	3b 54 24 04          	cmp    0x4(%esp),%edx
f0105bba:	0f 82 e0 00 00 00    	jb     f0105ca0 <__umoddi3+0x140>
f0105bc0:	39 0c 24             	cmp    %ecx,(%esp)
f0105bc3:	0f 86 d7 00 00 00    	jbe    f0105ca0 <__umoddi3+0x140>
f0105bc9:	8b 44 24 08          	mov    0x8(%esp),%eax
f0105bcd:	8b 54 24 04          	mov    0x4(%esp),%edx
f0105bd1:	83 c4 1c             	add    $0x1c,%esp
f0105bd4:	5b                   	pop    %ebx
f0105bd5:	5e                   	pop    %esi
f0105bd6:	5f                   	pop    %edi
f0105bd7:	5d                   	pop    %ebp
f0105bd8:	c3                   	ret    
f0105bd9:	8d b4 26 00 00 00 00 	lea    0x0(%esi,%eiz,1),%esi
f0105be0:	85 ff                	test   %edi,%edi
f0105be2:	89 fd                	mov    %edi,%ebp
f0105be4:	75 0b                	jne    f0105bf1 <__umoddi3+0x91>
f0105be6:	b8 01 00 00 00       	mov    $0x1,%eax
f0105beb:	31 d2                	xor    %edx,%edx
f0105bed:	f7 f7                	div    %edi
f0105bef:	89 c5                	mov    %eax,%ebp
f0105bf1:	89 f0                	mov    %esi,%eax
f0105bf3:	31 d2                	xor    %edx,%edx
f0105bf5:	f7 f5                	div    %ebp
f0105bf7:	89 c8                	mov    %ecx,%eax
f0105bf9:	f7 f5                	div    %ebp
f0105bfb:	89 d0                	mov    %edx,%eax
f0105bfd:	eb 99                	jmp    f0105b98 <__umoddi3+0x38>
f0105bff:	90                   	nop
f0105c00:	89 c8                	mov    %ecx,%eax
f0105c02:	89 f2                	mov    %esi,%edx
f0105c04:	83 c4 1c             	add    $0x1c,%esp
f0105c07:	5b                   	pop    %ebx
f0105c08:	5e                   	pop    %esi
f0105c09:	5f                   	pop    %edi
f0105c0a:	5d                   	pop    %ebp
f0105c0b:	c3                   	ret    
f0105c0c:	8d 74 26 00          	lea    0x0(%esi,%eiz,1),%esi
f0105c10:	8b 34 24             	mov    (%esp),%esi
f0105c13:	bf 20 00 00 00       	mov    $0x20,%edi
f0105c18:	89 e9                	mov    %ebp,%ecx
f0105c1a:	29 ef                	sub    %ebp,%edi
f0105c1c:	d3 e0                	shl    %cl,%eax
f0105c1e:	89 f9                	mov    %edi,%ecx
f0105c20:	89 f2                	mov    %esi,%edx
f0105c22:	d3 ea                	shr    %cl,%edx
f0105c24:	89 e9                	mov    %ebp,%ecx
f0105c26:	09 c2                	or     %eax,%edx
f0105c28:	89 d8                	mov    %ebx,%eax
f0105c2a:	89 14 24             	mov    %edx,(%esp)
f0105c2d:	89 f2                	mov    %esi,%edx
f0105c2f:	d3 e2                	shl    %cl,%edx
f0105c31:	89 f9                	mov    %edi,%ecx
f0105c33:	89 54 24 04          	mov    %edx,0x4(%esp)
f0105c37:	8b 54 24 0c          	mov    0xc(%esp),%edx
f0105c3b:	d3 e8                	shr    %cl,%eax
f0105c3d:	89 e9                	mov    %ebp,%ecx
f0105c3f:	89 c6                	mov    %eax,%esi
f0105c41:	d3 e3                	shl    %cl,%ebx
f0105c43:	89 f9                	mov    %edi,%ecx
f0105c45:	89 d0                	mov    %edx,%eax
f0105c47:	d3 e8                	shr    %cl,%eax
f0105c49:	89 e9                	mov    %ebp,%ecx
f0105c4b:	09 d8                	or     %ebx,%eax
f0105c4d:	89 d3                	mov    %edx,%ebx
f0105c4f:	89 f2                	mov    %esi,%edx
f0105c51:	f7 34 24             	divl   (%esp)
f0105c54:	89 d6                	mov    %edx,%esi
f0105c56:	d3 e3                	shl    %cl,%ebx
f0105c58:	f7 64 24 04          	mull   0x4(%esp)
f0105c5c:	39 d6                	cmp    %edx,%esi
f0105c5e:	89 5c 24 08          	mov    %ebx,0x8(%esp)
f0105c62:	89 d1                	mov    %edx,%ecx
f0105c64:	89 c3                	mov    %eax,%ebx
f0105c66:	72 08                	jb     f0105c70 <__umoddi3+0x110>
f0105c68:	75 11                	jne    f0105c7b <__umoddi3+0x11b>
f0105c6a:	39 44 24 08          	cmp    %eax,0x8(%esp)
f0105c6e:	73 0b                	jae    f0105c7b <__umoddi3+0x11b>
f0105c70:	2b 44 24 04          	sub    0x4(%esp),%eax
f0105c74:	1b 14 24             	sbb    (%esp),%edx
f0105c77:	89 d1                	mov    %edx,%ecx
f0105c79:	89 c3                	mov    %eax,%ebx
f0105c7b:	8b 54 24 08          	mov    0x8(%esp),%edx
f0105c7f:	29 da                	sub    %ebx,%edx
f0105c81:	19 ce                	sbb    %ecx,%esi
f0105c83:	89 f9                	mov    %edi,%ecx
f0105c85:	89 f0                	mov    %esi,%eax
f0105c87:	d3 e0                	shl    %cl,%eax
f0105c89:	89 e9                	mov    %ebp,%ecx
f0105c8b:	d3 ea                	shr    %cl,%edx
f0105c8d:	89 e9                	mov    %ebp,%ecx
f0105c8f:	d3 ee                	shr    %cl,%esi
f0105c91:	09 d0                	or     %edx,%eax
f0105c93:	89 f2                	mov    %esi,%edx
f0105c95:	83 c4 1c             	add    $0x1c,%esp
f0105c98:	5b                   	pop    %ebx
f0105c99:	5e                   	pop    %esi
f0105c9a:	5f                   	pop    %edi
f0105c9b:	5d                   	pop    %ebp
f0105c9c:	c3                   	ret    
f0105c9d:	8d 76 00             	lea    0x0(%esi),%esi
f0105ca0:	29 f9                	sub    %edi,%ecx
f0105ca2:	19 d6                	sbb    %edx,%esi
f0105ca4:	89 74 24 04          	mov    %esi,0x4(%esp)
f0105ca8:	89 4c 24 08          	mov    %ecx,0x8(%esp)
f0105cac:	e9 18 ff ff ff       	jmp    f0105bc9 <__umoddi3+0x69>
