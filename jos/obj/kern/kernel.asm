
obj/kern/kernel:     file format elf32-i386


Disassembly of section .text:

f0100000 <_start+0xeffffff4>:
.globl		_start
_start = RELOC(entry)

.globl entry
entry:
	movw	$0x1234,0x472			# warm boot
f0100000:	02 b0 ad 1b 00 00    	add    0x1bad(%eax),%dh
f0100006:	00 00                	add    %al,(%eax)
f0100008:	fe 4f 52             	decb   0x52(%edi)
f010000b:	e4                   	.byte 0xe4

f010000c <entry>:
f010000c:	66 c7 05 72 04 00 00 	movw   $0x1234,0x472
f0100013:	34 12 
	# sufficient until we set up our real page table in mem_init
	# in lab 2.

	# Load the physical address of entry_pgdir into cr3.  entry_pgdir
	# is defined in entrypgdir.c.
	movl	$(RELOC(entry_pgdir)), %eax
f0100015:	b8 00 a0 11 00       	mov    $0x11a000,%eax
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
f010003d:	bc 00 a0 11 f0       	mov    $0xf011a000,%esp

	# now to C code
	call	i386_init
f0100042:	e8 02 00 00 00       	call   f0100049 <i386_init>

f0100047 <spin>:

	# Should never get here, but in case we do, just spin.
spin:	jmp	spin
f0100047:	eb fe                	jmp    f0100047 <spin>

f0100049 <i386_init>:
#include <kern/trap.h>


void
i386_init(void)
{
f0100049:	55                   	push   %ebp
f010004a:	89 e5                	mov    %esp,%ebp
f010004c:	83 ec 0c             	sub    $0xc,%esp
	extern char __bss_start[], end[];

	// Before doing anything else, complete the ELF loading process.
	// Clear the uninitialized global data (BSS) section of our program.
	// This ensures that all static/global variables start out zero.
	memset(__bss_start, 0, end - __bss_start);
f010004f:	b8 90 6f 18 f0       	mov    $0xf0186f90,%eax
f0100054:	2d 80 50 18 f0       	sub    $0xf0185080,%eax
f0100059:	50                   	push   %eax
f010005a:	6a 00                	push   $0x0
f010005c:	68 80 50 18 f0       	push   $0xf0185080
f0100061:	e8 61 46 00 00       	call   f01046c7 <memset>

	// Initialize the console.
	// Can't call cprintf until after we do this!
	cons_init();
f0100066:	e8 86 06 00 00       	call   f01006f1 <cons_init>

	cprintf("6828 decimal is %o octal!\n", 6828);
f010006b:	83 c4 08             	add    $0x8,%esp
f010006e:	68 ac 1a 00 00       	push   $0x1aac
f0100073:	68 60 4b 10 f0       	push   $0xf0104b60
f0100078:	e8 81 36 00 00       	call   f01036fe <cprintf>

	// Lab 2 memory management initialization functions
	mem_init();
f010007d:	e8 55 2b 00 00       	call   f0102bd7 <mem_init>

	// Lab 3 user environment initialization functions
	env_init();
f0100082:	e8 22 32 00 00       	call   f01032a9 <env_init>
	trap_init();
f0100087:	e8 2f 37 00 00       	call   f01037bb <trap_init>

#if defined(TEST)
	// Don't touch -- used by grading script!
	ENV_CREATE(TEST, ENV_TYPE_USER);
f010008c:	83 c4 08             	add    $0x8,%esp
f010008f:	6a 00                	push   $0x0
f0100091:	68 56 b3 11 f0       	push   $0xf011b356
f0100096:	e8 37 33 00 00       	call   f01033d2 <env_create>
#else
	// Touch all you want.
	ENV_CREATE(user_hello, ENV_TYPE_USER);
#endif // TEST*
	// We only have one user environment for now, so just run it.
	env_run(&envs[0]);
f010009b:	83 c4 04             	add    $0x4,%esp
f010009e:	ff 35 c8 52 18 f0    	pushl  0xf01852c8
f01000a4:	e8 f9 34 00 00       	call   f01035a2 <env_run>

f01000a9 <_panic>:
 * Panic is called on unresolvable fatal errors.
 * It prints "panic: mesg", and then enters the kernel monitor.
 */
void
_panic(const char *file, int line, const char *fmt,...)
{
f01000a9:	55                   	push   %ebp
f01000aa:	89 e5                	mov    %esp,%ebp
f01000ac:	56                   	push   %esi
f01000ad:	53                   	push   %ebx
f01000ae:	8b 75 10             	mov    0x10(%ebp),%esi
	va_list ap;

	if (panicstr)
f01000b1:	83 3d 80 6f 18 f0 00 	cmpl   $0x0,0xf0186f80
f01000b8:	75 37                	jne    f01000f1 <_panic+0x48>
		goto dead;
	panicstr = fmt;
f01000ba:	89 35 80 6f 18 f0    	mov    %esi,0xf0186f80

	// Be extra sure that the machine is in as reasonable state
	asm volatile("cli; cld");
f01000c0:	fa                   	cli    
f01000c1:	fc                   	cld    

	va_start(ap, fmt);
f01000c2:	8d 5d 14             	lea    0x14(%ebp),%ebx
	cprintf(">>>\n>>> kernel panic at %s:%d: ", file, line);
f01000c5:	83 ec 04             	sub    $0x4,%esp
f01000c8:	ff 75 0c             	pushl  0xc(%ebp)
f01000cb:	ff 75 08             	pushl  0x8(%ebp)
f01000ce:	68 9c 4b 10 f0       	push   $0xf0104b9c
f01000d3:	e8 26 36 00 00       	call   f01036fe <cprintf>
	vcprintf(fmt, ap);
f01000d8:	83 c4 08             	add    $0x8,%esp
f01000db:	53                   	push   %ebx
f01000dc:	56                   	push   %esi
f01000dd:	e8 e9 35 00 00       	call   f01036cb <vcprintf>
	cprintf("\n>>>\n");
f01000e2:	c7 04 24 7b 4b 10 f0 	movl   $0xf0104b7b,(%esp)
f01000e9:	e8 10 36 00 00       	call   f01036fe <cprintf>
	va_end(ap);
f01000ee:	83 c4 10             	add    $0x10,%esp

dead:
	/* break into the kernel monitor */
	while (1)
		monitor(NULL);
f01000f1:	83 ec 0c             	sub    $0xc,%esp
f01000f4:	6a 00                	push   $0x0
f01000f6:	e8 29 09 00 00       	call   f0100a24 <monitor>
f01000fb:	83 c4 10             	add    $0x10,%esp
f01000fe:	eb f1                	jmp    f01000f1 <_panic+0x48>

f0100100 <_warn>:
}

/* like panic, but don't */
void
_warn(const char *file, int line, const char *fmt,...)
{
f0100100:	55                   	push   %ebp
f0100101:	89 e5                	mov    %esp,%ebp
f0100103:	53                   	push   %ebx
f0100104:	83 ec 08             	sub    $0x8,%esp
	va_list ap;

	va_start(ap, fmt);
f0100107:	8d 5d 14             	lea    0x14(%ebp),%ebx
	cprintf("kernel warning at %s:%d: ", file, line);
f010010a:	ff 75 0c             	pushl  0xc(%ebp)
f010010d:	ff 75 08             	pushl  0x8(%ebp)
f0100110:	68 81 4b 10 f0       	push   $0xf0104b81
f0100115:	e8 e4 35 00 00       	call   f01036fe <cprintf>
	vcprintf(fmt, ap);
f010011a:	83 c4 08             	add    $0x8,%esp
f010011d:	53                   	push   %ebx
f010011e:	ff 75 10             	pushl  0x10(%ebp)
f0100121:	e8 a5 35 00 00       	call   f01036cb <vcprintf>
	cprintf("\n");
f0100126:	c7 04 24 ca 5b 10 f0 	movl   $0xf0105bca,(%esp)
f010012d:	e8 cc 35 00 00       	call   f01036fe <cprintf>
	va_end(ap);
}
f0100132:	83 c4 10             	add    $0x10,%esp
f0100135:	8b 5d fc             	mov    -0x4(%ebp),%ebx
f0100138:	c9                   	leave  
f0100139:	c3                   	ret    
f010013a:	66 90                	xchg   %ax,%ax
f010013c:	66 90                	xchg   %ax,%ax
f010013e:	66 90                	xchg   %ax,%ax

f0100140 <inb>:
	asm volatile("int3");
}

static inline uint8_t
inb(int port)
{
f0100140:	55                   	push   %ebp
f0100141:	89 e5                	mov    %esp,%ebp
	uint8_t data;
	asm volatile("inb %w1,%0" : "=a" (data) : "d" (port));
f0100143:	89 c2                	mov    %eax,%edx
f0100145:	ec                   	in     (%dx),%al
	return data;
}
f0100146:	5d                   	pop    %ebp
f0100147:	c3                   	ret    

f0100148 <outb>:
		     : "memory", "cc");
}

static inline void
outb(int port, uint8_t data)
{
f0100148:	55                   	push   %ebp
f0100149:	89 e5                	mov    %esp,%ebp
f010014b:	89 c1                	mov    %eax,%ecx
f010014d:	89 d0                	mov    %edx,%eax
	asm volatile("outb %0,%w1" : : "a" (data), "d" (port));
f010014f:	89 ca                	mov    %ecx,%edx
f0100151:	ee                   	out    %al,(%dx)
}
f0100152:	5d                   	pop    %ebp
f0100153:	c3                   	ret    

f0100154 <delay>:
static void cons_putc(int c);

// Stupid I/O delay routine necessitated by historical PC design flaws
static void
delay(void)
{
f0100154:	55                   	push   %ebp
f0100155:	89 e5                	mov    %esp,%ebp
	inb(0x84);
f0100157:	b8 84 00 00 00       	mov    $0x84,%eax
f010015c:	e8 df ff ff ff       	call   f0100140 <inb>
	inb(0x84);
f0100161:	b8 84 00 00 00       	mov    $0x84,%eax
f0100166:	e8 d5 ff ff ff       	call   f0100140 <inb>
	inb(0x84);
f010016b:	b8 84 00 00 00       	mov    $0x84,%eax
f0100170:	e8 cb ff ff ff       	call   f0100140 <inb>
	inb(0x84);
f0100175:	b8 84 00 00 00       	mov    $0x84,%eax
f010017a:	e8 c1 ff ff ff       	call   f0100140 <inb>
}
f010017f:	5d                   	pop    %ebp
f0100180:	c3                   	ret    

f0100181 <serial_proc_data>:

static bool serial_exists;

static int
serial_proc_data(void)
{
f0100181:	55                   	push   %ebp
f0100182:	89 e5                	mov    %esp,%ebp
	if (!(inb(COM1+COM_LSR) & COM_LSR_DATA))
f0100184:	b8 fd 03 00 00       	mov    $0x3fd,%eax
f0100189:	e8 b2 ff ff ff       	call   f0100140 <inb>
f010018e:	a8 01                	test   $0x1,%al
f0100190:	74 0f                	je     f01001a1 <serial_proc_data+0x20>
		return -1;
	return inb(COM1+COM_RX);
f0100192:	b8 f8 03 00 00       	mov    $0x3f8,%eax
f0100197:	e8 a4 ff ff ff       	call   f0100140 <inb>
f010019c:	0f b6 c0             	movzbl %al,%eax
f010019f:	eb 05                	jmp    f01001a6 <serial_proc_data+0x25>

static int
serial_proc_data(void)
{
	if (!(inb(COM1+COM_LSR) & COM_LSR_DATA))
		return -1;
f01001a1:	b8 ff ff ff ff       	mov    $0xffffffff,%eax
	return inb(COM1+COM_RX);
}
f01001a6:	5d                   	pop    %ebp
f01001a7:	c3                   	ret    

f01001a8 <serial_putc>:
		cons_intr(serial_proc_data);
}

static void
serial_putc(int c)
{
f01001a8:	55                   	push   %ebp
f01001a9:	89 e5                	mov    %esp,%ebp
f01001ab:	56                   	push   %esi
f01001ac:	53                   	push   %ebx
f01001ad:	89 c6                	mov    %eax,%esi
	int i;

	for (i = 0;
f01001af:	bb 01 32 00 00       	mov    $0x3201,%ebx
f01001b4:	eb 05                	jmp    f01001bb <serial_putc+0x13>
	     !(inb(COM1 + COM_LSR) & COM_LSR_TXRDY) && i < 12800;
	     i++)
		delay();
f01001b6:	e8 99 ff ff ff       	call   f0100154 <delay>
serial_putc(int c)
{
	int i;

	for (i = 0;
	     !(inb(COM1 + COM_LSR) & COM_LSR_TXRDY) && i < 12800;
f01001bb:	b8 fd 03 00 00       	mov    $0x3fd,%eax
f01001c0:	e8 7b ff ff ff       	call   f0100140 <inb>
static void
serial_putc(int c)
{
	int i;

	for (i = 0;
f01001c5:	a8 20                	test   $0x20,%al
f01001c7:	75 05                	jne    f01001ce <serial_putc+0x26>
	     !(inb(COM1 + COM_LSR) & COM_LSR_TXRDY) && i < 12800;
f01001c9:	83 eb 01             	sub    $0x1,%ebx
f01001cc:	75 e8                	jne    f01001b6 <serial_putc+0xe>
	     i++)
		delay();

	outb(COM1 + COM_TX, c);
f01001ce:	89 f0                	mov    %esi,%eax
f01001d0:	0f b6 d0             	movzbl %al,%edx
f01001d3:	b8 f8 03 00 00       	mov    $0x3f8,%eax
f01001d8:	e8 6b ff ff ff       	call   f0100148 <outb>
}
f01001dd:	5b                   	pop    %ebx
f01001de:	5e                   	pop    %esi
f01001df:	5d                   	pop    %ebp
f01001e0:	c3                   	ret    

f01001e1 <serial_init>:

static void
serial_init(void)
{
f01001e1:	55                   	push   %ebp
f01001e2:	89 e5                	mov    %esp,%ebp
	// Turn off the FIFO
	outb(COM1+COM_FCR, 0);
f01001e4:	ba 00 00 00 00       	mov    $0x0,%edx
f01001e9:	b8 fa 03 00 00       	mov    $0x3fa,%eax
f01001ee:	e8 55 ff ff ff       	call   f0100148 <outb>

	// Set speed; requires DLAB latch
	outb(COM1+COM_LCR, COM_LCR_DLAB);
f01001f3:	ba 80 00 00 00       	mov    $0x80,%edx
f01001f8:	b8 fb 03 00 00       	mov    $0x3fb,%eax
f01001fd:	e8 46 ff ff ff       	call   f0100148 <outb>
	outb(COM1+COM_DLL, (uint8_t) (115200 / 9600));
f0100202:	ba 0c 00 00 00       	mov    $0xc,%edx
f0100207:	b8 f8 03 00 00       	mov    $0x3f8,%eax
f010020c:	e8 37 ff ff ff       	call   f0100148 <outb>
	outb(COM1+COM_DLM, 0);
f0100211:	ba 00 00 00 00       	mov    $0x0,%edx
f0100216:	b8 f9 03 00 00       	mov    $0x3f9,%eax
f010021b:	e8 28 ff ff ff       	call   f0100148 <outb>

	// 8 data bits, 1 stop bit, parity off; turn off DLAB latch
	outb(COM1+COM_LCR, COM_LCR_WLEN8 & ~COM_LCR_DLAB);
f0100220:	ba 03 00 00 00       	mov    $0x3,%edx
f0100225:	b8 fb 03 00 00       	mov    $0x3fb,%eax
f010022a:	e8 19 ff ff ff       	call   f0100148 <outb>

	// No modem controls
	outb(COM1+COM_MCR, 0);
f010022f:	ba 00 00 00 00       	mov    $0x0,%edx
f0100234:	b8 fc 03 00 00       	mov    $0x3fc,%eax
f0100239:	e8 0a ff ff ff       	call   f0100148 <outb>
	// Enable rcv interrupts
	outb(COM1+COM_IER, COM_IER_RDI);
f010023e:	ba 01 00 00 00       	mov    $0x1,%edx
f0100243:	b8 f9 03 00 00       	mov    $0x3f9,%eax
f0100248:	e8 fb fe ff ff       	call   f0100148 <outb>

	// Clear any preexisting overrun indications and interrupts
	// Serial port doesn't exist if COM_LSR returns 0xFF
	serial_exists = (inb(COM1+COM_LSR) != 0xFF);
f010024d:	b8 fd 03 00 00       	mov    $0x3fd,%eax
f0100252:	e8 e9 fe ff ff       	call   f0100140 <inb>
f0100257:	3c ff                	cmp    $0xff,%al
f0100259:	0f 95 05 b4 52 18 f0 	setne  0xf01852b4
	(void) inb(COM1+COM_IIR);
f0100260:	b8 fa 03 00 00       	mov    $0x3fa,%eax
f0100265:	e8 d6 fe ff ff       	call   f0100140 <inb>
	(void) inb(COM1+COM_RX);
f010026a:	b8 f8 03 00 00       	mov    $0x3f8,%eax
f010026f:	e8 cc fe ff ff       	call   f0100140 <inb>

}
f0100274:	5d                   	pop    %ebp
f0100275:	c3                   	ret    

f0100276 <lpt_putc>:
// For information on PC parallel port programming, see the class References
// page.

static void
lpt_putc(int c)
{
f0100276:	55                   	push   %ebp
f0100277:	89 e5                	mov    %esp,%ebp
f0100279:	56                   	push   %esi
f010027a:	53                   	push   %ebx
f010027b:	89 c6                	mov    %eax,%esi
	int i;

	for (i = 0; !(inb(0x378+1) & 0x80) && i < 12800; i++)
f010027d:	bb 01 32 00 00       	mov    $0x3201,%ebx
f0100282:	eb 05                	jmp    f0100289 <lpt_putc+0x13>
		delay();
f0100284:	e8 cb fe ff ff       	call   f0100154 <delay>
static void
lpt_putc(int c)
{
	int i;

	for (i = 0; !(inb(0x378+1) & 0x80) && i < 12800; i++)
f0100289:	b8 79 03 00 00       	mov    $0x379,%eax
f010028e:	e8 ad fe ff ff       	call   f0100140 <inb>
f0100293:	84 c0                	test   %al,%al
f0100295:	78 05                	js     f010029c <lpt_putc+0x26>
f0100297:	83 eb 01             	sub    $0x1,%ebx
f010029a:	75 e8                	jne    f0100284 <lpt_putc+0xe>
		delay();
	outb(0x378+0, c);
f010029c:	89 f0                	mov    %esi,%eax
f010029e:	0f b6 d0             	movzbl %al,%edx
f01002a1:	b8 78 03 00 00       	mov    $0x378,%eax
f01002a6:	e8 9d fe ff ff       	call   f0100148 <outb>
	outb(0x378+2, 0x08|0x04|0x01);
f01002ab:	ba 0d 00 00 00       	mov    $0xd,%edx
f01002b0:	b8 7a 03 00 00       	mov    $0x37a,%eax
f01002b5:	e8 8e fe ff ff       	call   f0100148 <outb>
	outb(0x378+2, 0x08);
f01002ba:	ba 08 00 00 00       	mov    $0x8,%edx
f01002bf:	b8 7a 03 00 00       	mov    $0x37a,%eax
f01002c4:	e8 7f fe ff ff       	call   f0100148 <outb>
}
f01002c9:	5b                   	pop    %ebx
f01002ca:	5e                   	pop    %esi
f01002cb:	5d                   	pop    %ebp
f01002cc:	c3                   	ret    

f01002cd <cga_init>:
static uint16_t *crt_buf;
static uint16_t crt_pos;

static void
cga_init(void)
{
f01002cd:	55                   	push   %ebp
f01002ce:	89 e5                	mov    %esp,%ebp
f01002d0:	57                   	push   %edi
f01002d1:	56                   	push   %esi
f01002d2:	53                   	push   %ebx
f01002d3:	83 ec 04             	sub    $0x4,%esp
	volatile uint16_t *cp;
	uint16_t was;
	unsigned pos;

	cp = (uint16_t*) (KERNBASE + CGA_BUF);
	was = *cp;
f01002d6:	0f b7 15 00 80 0b f0 	movzwl 0xf00b8000,%edx
	*cp = (uint16_t) 0xA55A;
f01002dd:	66 c7 05 00 80 0b f0 	movw   $0xa55a,0xf00b8000
f01002e4:	5a a5 
	if (*cp != 0xA55A) {
f01002e6:	0f b7 05 00 80 0b f0 	movzwl 0xf00b8000,%eax
f01002ed:	66 3d 5a a5          	cmp    $0xa55a,%ax
f01002f1:	74 11                	je     f0100304 <cga_init+0x37>
		cp = (uint16_t*) (KERNBASE + MONO_BUF);
		addr_6845 = MONO_BASE;
f01002f3:	c7 05 b0 52 18 f0 b4 	movl   $0x3b4,0xf01852b0
f01002fa:	03 00 00 

	cp = (uint16_t*) (KERNBASE + CGA_BUF);
	was = *cp;
	*cp = (uint16_t) 0xA55A;
	if (*cp != 0xA55A) {
		cp = (uint16_t*) (KERNBASE + MONO_BUF);
f01002fd:	bf 00 00 0b f0       	mov    $0xf00b0000,%edi
f0100302:	eb 16                	jmp    f010031a <cga_init+0x4d>
		addr_6845 = MONO_BASE;
	} else {
		*cp = was;
f0100304:	66 89 15 00 80 0b f0 	mov    %dx,0xf00b8000
		addr_6845 = CGA_BASE;
f010030b:	c7 05 b0 52 18 f0 d4 	movl   $0x3d4,0xf01852b0
f0100312:	03 00 00 
{
	volatile uint16_t *cp;
	uint16_t was;
	unsigned pos;

	cp = (uint16_t*) (KERNBASE + CGA_BUF);
f0100315:	bf 00 80 0b f0       	mov    $0xf00b8000,%edi
		*cp = was;
		addr_6845 = CGA_BASE;
	}

	/* Extract cursor location */
	outb(addr_6845, 14);
f010031a:	8b 1d b0 52 18 f0    	mov    0xf01852b0,%ebx
f0100320:	ba 0e 00 00 00       	mov    $0xe,%edx
f0100325:	89 d8                	mov    %ebx,%eax
f0100327:	e8 1c fe ff ff       	call   f0100148 <outb>
	pos = inb(addr_6845 + 1) << 8;
f010032c:	8d 73 01             	lea    0x1(%ebx),%esi
f010032f:	89 f0                	mov    %esi,%eax
f0100331:	e8 0a fe ff ff       	call   f0100140 <inb>
f0100336:	0f b6 c0             	movzbl %al,%eax
f0100339:	c1 e0 08             	shl    $0x8,%eax
f010033c:	89 45 f0             	mov    %eax,-0x10(%ebp)
	outb(addr_6845, 15);
f010033f:	ba 0f 00 00 00       	mov    $0xf,%edx
f0100344:	89 d8                	mov    %ebx,%eax
f0100346:	e8 fd fd ff ff       	call   f0100148 <outb>
	pos |= inb(addr_6845 + 1);
f010034b:	89 f0                	mov    %esi,%eax
f010034d:	e8 ee fd ff ff       	call   f0100140 <inb>

	crt_buf = (uint16_t*) cp;
f0100352:	89 3d ac 52 18 f0    	mov    %edi,0xf01852ac

	/* Extract cursor location */
	outb(addr_6845, 14);
	pos = inb(addr_6845 + 1) << 8;
	outb(addr_6845, 15);
	pos |= inb(addr_6845 + 1);
f0100358:	0f b6 c0             	movzbl %al,%eax
f010035b:	0b 45 f0             	or     -0x10(%ebp),%eax

	crt_buf = (uint16_t*) cp;
	crt_pos = pos;
f010035e:	66 a3 a8 52 18 f0    	mov    %ax,0xf01852a8
}
f0100364:	83 c4 04             	add    $0x4,%esp
f0100367:	5b                   	pop    %ebx
f0100368:	5e                   	pop    %esi
f0100369:	5f                   	pop    %edi
f010036a:	5d                   	pop    %ebp
f010036b:	c3                   	ret    

f010036c <cons_intr>:

// called by device interrupt routines to feed input characters
// into the circular console input buffer.
static void
cons_intr(int (*proc)(void))
{
f010036c:	55                   	push   %ebp
f010036d:	89 e5                	mov    %esp,%ebp
f010036f:	53                   	push   %ebx
f0100370:	83 ec 04             	sub    $0x4,%esp
f0100373:	89 c3                	mov    %eax,%ebx
	int c;

	while ((c = (*proc)()) != -1) {
f0100375:	eb 2a                	jmp    f01003a1 <cons_intr+0x35>
		if (c == 0)
f0100377:	85 d2                	test   %edx,%edx
f0100379:	74 26                	je     f01003a1 <cons_intr+0x35>
			continue;
		cons.buf[cons.wpos++] = c;
f010037b:	a1 a4 52 18 f0       	mov    0xf01852a4,%eax
f0100380:	8d 48 01             	lea    0x1(%eax),%ecx
f0100383:	89 0d a4 52 18 f0    	mov    %ecx,0xf01852a4
f0100389:	88 90 a0 50 18 f0    	mov    %dl,-0xfe7af60(%eax)
		if (cons.wpos == CONSBUFSIZE)
f010038f:	81 f9 00 02 00 00    	cmp    $0x200,%ecx
f0100395:	75 0a                	jne    f01003a1 <cons_intr+0x35>
			cons.wpos = 0;
f0100397:	c7 05 a4 52 18 f0 00 	movl   $0x0,0xf01852a4
f010039e:	00 00 00 
static void
cons_intr(int (*proc)(void))
{
	int c;

	while ((c = (*proc)()) != -1) {
f01003a1:	ff d3                	call   *%ebx
f01003a3:	89 c2                	mov    %eax,%edx
f01003a5:	83 f8 ff             	cmp    $0xffffffff,%eax
f01003a8:	75 cd                	jne    f0100377 <cons_intr+0xb>
			continue;
		cons.buf[cons.wpos++] = c;
		if (cons.wpos == CONSBUFSIZE)
			cons.wpos = 0;
	}
}
f01003aa:	83 c4 04             	add    $0x4,%esp
f01003ad:	5b                   	pop    %ebx
f01003ae:	5d                   	pop    %ebp
f01003af:	c3                   	ret    

f01003b0 <kbd_proc_data>:
 * Get data from the keyboard.  If we finish a character, return it.  Else 0.
 * Return -1 if no data.
 */
static int
kbd_proc_data(void)
{
f01003b0:	55                   	push   %ebp
f01003b1:	89 e5                	mov    %esp,%ebp
f01003b3:	53                   	push   %ebx
f01003b4:	83 ec 14             	sub    $0x14,%esp
	int c;
	uint8_t stat, data;
	static uint32_t shift;

	stat = inb(KBSTATP);
f01003b7:	b8 64 00 00 00       	mov    $0x64,%eax
f01003bc:	e8 7f fd ff ff       	call   f0100140 <inb>
	if ((stat & KBS_DIB) == 0)
f01003c1:	a8 01                	test   $0x1,%al
f01003c3:	0f 84 fd 00 00 00    	je     f01004c6 <kbd_proc_data+0x116>
		return -1;
	// Ignore data from mouse.
	if (stat & KBS_TERR)
f01003c9:	a8 20                	test   $0x20,%al
f01003cb:	0f 85 fc 00 00 00    	jne    f01004cd <kbd_proc_data+0x11d>
		return -1;

	data = inb(KBDATAP);
f01003d1:	b8 60 00 00 00       	mov    $0x60,%eax
f01003d6:	e8 65 fd ff ff       	call   f0100140 <inb>

	if (data == 0xE0) {
f01003db:	3c e0                	cmp    $0xe0,%al
f01003dd:	75 11                	jne    f01003f0 <kbd_proc_data+0x40>
		// E0 escape character
		shift |= E0ESC;
f01003df:	83 0d 80 50 18 f0 40 	orl    $0x40,0xf0185080
		return 0;
f01003e6:	b8 00 00 00 00       	mov    $0x0,%eax
f01003eb:	e9 e2 00 00 00       	jmp    f01004d2 <kbd_proc_data+0x122>
	} else if (data & 0x80) {
f01003f0:	84 c0                	test   %al,%al
f01003f2:	79 39                	jns    f010042d <kbd_proc_data+0x7d>
		// Key released
		data = (shift & E0ESC ? data : data & 0x7F);
f01003f4:	8b 15 80 50 18 f0    	mov    0xf0185080,%edx
f01003fa:	89 d3                	mov    %edx,%ebx
f01003fc:	83 e3 40             	and    $0x40,%ebx
f01003ff:	89 c1                	mov    %eax,%ecx
f0100401:	83 e1 7f             	and    $0x7f,%ecx
f0100404:	85 db                	test   %ebx,%ebx
f0100406:	0f 44 c1             	cmove  %ecx,%eax
		shift &= ~(shiftcode[data] | E0ESC);
f0100409:	0f b6 c0             	movzbl %al,%eax
f010040c:	0f b6 80 20 4d 10 f0 	movzbl -0xfefb2e0(%eax),%eax
f0100413:	83 c8 40             	or     $0x40,%eax
f0100416:	0f b6 c0             	movzbl %al,%eax
f0100419:	f7 d0                	not    %eax
f010041b:	21 c2                	and    %eax,%edx
f010041d:	89 15 80 50 18 f0    	mov    %edx,0xf0185080
		return 0;
f0100423:	b8 00 00 00 00       	mov    $0x0,%eax
f0100428:	e9 a5 00 00 00       	jmp    f01004d2 <kbd_proc_data+0x122>
	} else if (shift & E0ESC) {
f010042d:	8b 15 80 50 18 f0    	mov    0xf0185080,%edx
f0100433:	f6 c2 40             	test   $0x40,%dl
f0100436:	74 0c                	je     f0100444 <kbd_proc_data+0x94>
		// Last character was an E0 escape; or with 0x80
		data |= 0x80;
f0100438:	83 c8 80             	or     $0xffffff80,%eax
		shift &= ~E0ESC;
f010043b:	83 e2 bf             	and    $0xffffffbf,%edx
f010043e:	89 15 80 50 18 f0    	mov    %edx,0xf0185080
	}

	shift |= shiftcode[data];
f0100444:	0f b6 c0             	movzbl %al,%eax
f0100447:	0f b6 90 20 4d 10 f0 	movzbl -0xfefb2e0(%eax),%edx
f010044e:	0b 15 80 50 18 f0    	or     0xf0185080,%edx
	shift ^= togglecode[data];
f0100454:	0f b6 88 20 4c 10 f0 	movzbl -0xfefb3e0(%eax),%ecx
f010045b:	31 ca                	xor    %ecx,%edx
f010045d:	89 15 80 50 18 f0    	mov    %edx,0xf0185080

	c = charcode[shift & (CTL | SHIFT)][data];
f0100463:	89 d1                	mov    %edx,%ecx
f0100465:	83 e1 03             	and    $0x3,%ecx
f0100468:	8b 0c 8d 00 4c 10 f0 	mov    -0xfefb400(,%ecx,4),%ecx
f010046f:	0f b6 04 01          	movzbl (%ecx,%eax,1),%eax
f0100473:	0f b6 d8             	movzbl %al,%ebx
	if (shift & CAPSLOCK) {
f0100476:	f6 c2 08             	test   $0x8,%dl
f0100479:	74 1b                	je     f0100496 <kbd_proc_data+0xe6>
		if ('a' <= c && c <= 'z')
f010047b:	89 d8                	mov    %ebx,%eax
f010047d:	8d 4b 9f             	lea    -0x61(%ebx),%ecx
f0100480:	83 f9 19             	cmp    $0x19,%ecx
f0100483:	77 05                	ja     f010048a <kbd_proc_data+0xda>
			c += 'A' - 'a';
f0100485:	83 eb 20             	sub    $0x20,%ebx
f0100488:	eb 0c                	jmp    f0100496 <kbd_proc_data+0xe6>
		else if ('A' <= c && c <= 'Z')
f010048a:	83 e8 41             	sub    $0x41,%eax
			c += 'a' - 'A';
f010048d:	8d 4b 20             	lea    0x20(%ebx),%ecx
f0100490:	83 f8 19             	cmp    $0x19,%eax
f0100493:	0f 46 d9             	cmovbe %ecx,%ebx
	}

	// Process special keys
	// Ctrl-Alt-Del: reboot
	if (!(~shift & (CTL | ALT)) && c == KEY_DEL) {
f0100496:	f7 d2                	not    %edx
		cprintf("Rebooting!\n");
		outb(0x92, 0x3); // courtesy of Chris Frost
	}

	return c;
f0100498:	89 d8                	mov    %ebx,%eax
			c += 'a' - 'A';
	}

	// Process special keys
	// Ctrl-Alt-Del: reboot
	if (!(~shift & (CTL | ALT)) && c == KEY_DEL) {
f010049a:	f6 c2 06             	test   $0x6,%dl
f010049d:	75 33                	jne    f01004d2 <kbd_proc_data+0x122>
f010049f:	81 fb e9 00 00 00    	cmp    $0xe9,%ebx
f01004a5:	75 2b                	jne    f01004d2 <kbd_proc_data+0x122>
		cprintf("Rebooting!\n");
f01004a7:	c7 04 24 bc 4b 10 f0 	movl   $0xf0104bbc,(%esp)
f01004ae:	e8 4b 32 00 00       	call   f01036fe <cprintf>
		outb(0x92, 0x3); // courtesy of Chris Frost
f01004b3:	ba 03 00 00 00       	mov    $0x3,%edx
f01004b8:	b8 92 00 00 00       	mov    $0x92,%eax
f01004bd:	e8 86 fc ff ff       	call   f0100148 <outb>
	}

	return c;
f01004c2:	89 d8                	mov    %ebx,%eax
f01004c4:	eb 0c                	jmp    f01004d2 <kbd_proc_data+0x122>
	uint8_t stat, data;
	static uint32_t shift;

	stat = inb(KBSTATP);
	if ((stat & KBS_DIB) == 0)
		return -1;
f01004c6:	b8 ff ff ff ff       	mov    $0xffffffff,%eax
f01004cb:	eb 05                	jmp    f01004d2 <kbd_proc_data+0x122>
	// Ignore data from mouse.
	if (stat & KBS_TERR)
		return -1;
f01004cd:	b8 ff ff ff ff       	mov    $0xffffffff,%eax
		cprintf("Rebooting!\n");
		outb(0x92, 0x3); // courtesy of Chris Frost
	}

	return c;
}
f01004d2:	83 c4 14             	add    $0x14,%esp
f01004d5:	5b                   	pop    %ebx
f01004d6:	5d                   	pop    %ebp
f01004d7:	c3                   	ret    

f01004d8 <cga_putc>:



static void
cga_putc(int c)
{
f01004d8:	55                   	push   %ebp
f01004d9:	89 e5                	mov    %esp,%ebp
f01004db:	57                   	push   %edi
f01004dc:	56                   	push   %esi
f01004dd:	53                   	push   %ebx
f01004de:	83 ec 1c             	sub    $0x1c,%esp
	// if no attribute given, then use black on white
	if (!(c & ~0xFF))
f01004e1:	89 c1                	mov    %eax,%ecx
f01004e3:	81 e1 00 ff ff ff    	and    $0xffffff00,%ecx
		c |= 0x0700;
f01004e9:	89 c2                	mov    %eax,%edx
f01004eb:	80 ce 07             	or     $0x7,%dh
f01004ee:	85 c9                	test   %ecx,%ecx
f01004f0:	0f 44 c2             	cmove  %edx,%eax

	switch (c & 0xff) {
f01004f3:	0f b6 d0             	movzbl %al,%edx
f01004f6:	83 fa 09             	cmp    $0x9,%edx
f01004f9:	74 75                	je     f0100570 <cga_putc+0x98>
f01004fb:	83 fa 09             	cmp    $0x9,%edx
f01004fe:	7f 0a                	jg     f010050a <cga_putc+0x32>
f0100500:	83 fa 08             	cmp    $0x8,%edx
f0100503:	74 17                	je     f010051c <cga_putc+0x44>
f0100505:	e9 9a 00 00 00       	jmp    f01005a4 <cga_putc+0xcc>
f010050a:	83 fa 0a             	cmp    $0xa,%edx
f010050d:	8d 76 00             	lea    0x0(%esi),%esi
f0100510:	74 38                	je     f010054a <cga_putc+0x72>
f0100512:	83 fa 0d             	cmp    $0xd,%edx
f0100515:	74 3b                	je     f0100552 <cga_putc+0x7a>
f0100517:	e9 88 00 00 00       	jmp    f01005a4 <cga_putc+0xcc>
	case '\b':
		if (crt_pos > 0) {
f010051c:	0f b7 15 a8 52 18 f0 	movzwl 0xf01852a8,%edx
f0100523:	66 85 d2             	test   %dx,%dx
f0100526:	0f 84 e3 00 00 00    	je     f010060f <cga_putc+0x137>
			crt_pos--;
f010052c:	83 ea 01             	sub    $0x1,%edx
f010052f:	66 89 15 a8 52 18 f0 	mov    %dx,0xf01852a8
			crt_buf[crt_pos] = (c & ~0xff) | ' ';
f0100536:	0f b7 d2             	movzwl %dx,%edx
f0100539:	b0 00                	mov    $0x0,%al
f010053b:	83 c8 20             	or     $0x20,%eax
f010053e:	8b 0d ac 52 18 f0    	mov    0xf01852ac,%ecx
f0100544:	66 89 04 51          	mov    %ax,(%ecx,%edx,2)
f0100548:	eb 78                	jmp    f01005c2 <cga_putc+0xea>
		}
		break;
	case '\n':
		crt_pos += CRT_COLS;
f010054a:	66 83 05 a8 52 18 f0 	addw   $0x50,0xf01852a8
f0100551:	50 
		/* fallthru */
	case '\r':
		crt_pos -= (crt_pos % CRT_COLS);
f0100552:	0f b7 05 a8 52 18 f0 	movzwl 0xf01852a8,%eax
f0100559:	69 c0 cd cc 00 00    	imul   $0xcccd,%eax,%eax
f010055f:	c1 e8 16             	shr    $0x16,%eax
f0100562:	8d 04 80             	lea    (%eax,%eax,4),%eax
f0100565:	c1 e0 04             	shl    $0x4,%eax
f0100568:	66 a3 a8 52 18 f0    	mov    %ax,0xf01852a8
		break;
f010056e:	eb 52                	jmp    f01005c2 <cga_putc+0xea>
	case '\t':
		cons_putc(' ');
f0100570:	b8 20 00 00 00       	mov    $0x20,%eax
f0100575:	e8 dd 00 00 00       	call   f0100657 <cons_putc>
		cons_putc(' ');
f010057a:	b8 20 00 00 00       	mov    $0x20,%eax
f010057f:	e8 d3 00 00 00       	call   f0100657 <cons_putc>
		cons_putc(' ');
f0100584:	b8 20 00 00 00       	mov    $0x20,%eax
f0100589:	e8 c9 00 00 00       	call   f0100657 <cons_putc>
		cons_putc(' ');
f010058e:	b8 20 00 00 00       	mov    $0x20,%eax
f0100593:	e8 bf 00 00 00       	call   f0100657 <cons_putc>
		cons_putc(' ');
f0100598:	b8 20 00 00 00       	mov    $0x20,%eax
f010059d:	e8 b5 00 00 00       	call   f0100657 <cons_putc>
		break;
f01005a2:	eb 1e                	jmp    f01005c2 <cga_putc+0xea>
	default:
		crt_buf[crt_pos++] = c;		/* write the character */
f01005a4:	0f b7 15 a8 52 18 f0 	movzwl 0xf01852a8,%edx
f01005ab:	8d 4a 01             	lea    0x1(%edx),%ecx
f01005ae:	66 89 0d a8 52 18 f0 	mov    %cx,0xf01852a8
f01005b5:	0f b7 d2             	movzwl %dx,%edx
f01005b8:	8b 0d ac 52 18 f0    	mov    0xf01852ac,%ecx
f01005be:	66 89 04 51          	mov    %ax,(%ecx,%edx,2)
		break;
	}

	// What is the purpose of this?
	if (crt_pos >= CRT_SIZE) {
f01005c2:	66 81 3d a8 52 18 f0 	cmpw   $0x7cf,0xf01852a8
f01005c9:	cf 07 
f01005cb:	76 42                	jbe    f010060f <cga_putc+0x137>
		int i;

		memmove(crt_buf, crt_buf + CRT_COLS, (CRT_SIZE - CRT_COLS) * sizeof(uint16_t));
f01005cd:	a1 ac 52 18 f0       	mov    0xf01852ac,%eax
f01005d2:	c7 44 24 08 00 0f 00 	movl   $0xf00,0x8(%esp)
f01005d9:	00 
f01005da:	8d 90 a0 00 00 00    	lea    0xa0(%eax),%edx
f01005e0:	89 54 24 04          	mov    %edx,0x4(%esp)
f01005e4:	89 04 24             	mov    %eax,(%esp)
f01005e7:	e8 29 41 00 00       	call   f0104715 <memmove>
		for (i = CRT_SIZE - CRT_COLS; i < CRT_SIZE; i++)
			crt_buf[i] = 0x0700 | ' ';
f01005ec:	8b 15 ac 52 18 f0    	mov    0xf01852ac,%edx
	// What is the purpose of this?
	if (crt_pos >= CRT_SIZE) {
		int i;

		memmove(crt_buf, crt_buf + CRT_COLS, (CRT_SIZE - CRT_COLS) * sizeof(uint16_t));
		for (i = CRT_SIZE - CRT_COLS; i < CRT_SIZE; i++)
f01005f2:	b8 80 07 00 00       	mov    $0x780,%eax
			crt_buf[i] = 0x0700 | ' ';
f01005f7:	66 c7 04 42 20 07    	movw   $0x720,(%edx,%eax,2)
	// What is the purpose of this?
	if (crt_pos >= CRT_SIZE) {
		int i;

		memmove(crt_buf, crt_buf + CRT_COLS, (CRT_SIZE - CRT_COLS) * sizeof(uint16_t));
		for (i = CRT_SIZE - CRT_COLS; i < CRT_SIZE; i++)
f01005fd:	83 c0 01             	add    $0x1,%eax
f0100600:	3d d0 07 00 00       	cmp    $0x7d0,%eax
f0100605:	75 f0                	jne    f01005f7 <cga_putc+0x11f>
			crt_buf[i] = 0x0700 | ' ';
		crt_pos -= CRT_COLS;
f0100607:	66 83 2d a8 52 18 f0 	subw   $0x50,0xf01852a8
f010060e:	50 
	}

	/* move that little blinky thing */
	outb(addr_6845, 14);
f010060f:	8b 1d b0 52 18 f0    	mov    0xf01852b0,%ebx
f0100615:	ba 0e 00 00 00       	mov    $0xe,%edx
f010061a:	89 d8                	mov    %ebx,%eax
f010061c:	e8 27 fb ff ff       	call   f0100148 <outb>
	outb(addr_6845 + 1, crt_pos >> 8);
f0100621:	0f b7 3d a8 52 18 f0 	movzwl 0xf01852a8,%edi
f0100628:	8d 73 01             	lea    0x1(%ebx),%esi
f010062b:	89 f8                	mov    %edi,%eax
f010062d:	0f b6 d4             	movzbl %ah,%edx
f0100630:	89 f0                	mov    %esi,%eax
f0100632:	e8 11 fb ff ff       	call   f0100148 <outb>
	outb(addr_6845, 15);
f0100637:	ba 0f 00 00 00       	mov    $0xf,%edx
f010063c:	89 d8                	mov    %ebx,%eax
f010063e:	e8 05 fb ff ff       	call   f0100148 <outb>
	outb(addr_6845 + 1, crt_pos);
f0100643:	89 f8                	mov    %edi,%eax
f0100645:	0f b6 d0             	movzbl %al,%edx
f0100648:	89 f0                	mov    %esi,%eax
f010064a:	e8 f9 fa ff ff       	call   f0100148 <outb>
}
f010064f:	83 c4 1c             	add    $0x1c,%esp
f0100652:	5b                   	pop    %ebx
f0100653:	5e                   	pop    %esi
f0100654:	5f                   	pop    %edi
f0100655:	5d                   	pop    %ebp
f0100656:	c3                   	ret    

f0100657 <cons_putc>:
}

// output a character to the console
static void
cons_putc(int c)
{
f0100657:	55                   	push   %ebp
f0100658:	89 e5                	mov    %esp,%ebp
f010065a:	53                   	push   %ebx
f010065b:	83 ec 04             	sub    $0x4,%esp
f010065e:	89 c3                	mov    %eax,%ebx
	serial_putc(c);
f0100660:	e8 43 fb ff ff       	call   f01001a8 <serial_putc>
	lpt_putc(c);
f0100665:	89 d8                	mov    %ebx,%eax
f0100667:	e8 0a fc ff ff       	call   f0100276 <lpt_putc>
	cga_putc(c);
f010066c:	89 d8                	mov    %ebx,%eax
f010066e:	e8 65 fe ff ff       	call   f01004d8 <cga_putc>
}
f0100673:	83 c4 04             	add    $0x4,%esp
f0100676:	5b                   	pop    %ebx
f0100677:	5d                   	pop    %ebp
f0100678:	c3                   	ret    

f0100679 <serial_intr>:
}

void
serial_intr(void)
{
	if (serial_exists)
f0100679:	80 3d b4 52 18 f0 00 	cmpb   $0x0,0xf01852b4
f0100680:	74 11                	je     f0100693 <serial_intr+0x1a>
	return inb(COM1+COM_RX);
}

void
serial_intr(void)
{
f0100682:	55                   	push   %ebp
f0100683:	89 e5                	mov    %esp,%ebp
f0100685:	83 ec 08             	sub    $0x8,%esp
	if (serial_exists)
		cons_intr(serial_proc_data);
f0100688:	b8 81 01 10 f0       	mov    $0xf0100181,%eax
f010068d:	e8 da fc ff ff       	call   f010036c <cons_intr>
}
f0100692:	c9                   	leave  
f0100693:	f3 c3                	repz ret 

f0100695 <kbd_intr>:
	return c;
}

void
kbd_intr(void)
{
f0100695:	55                   	push   %ebp
f0100696:	89 e5                	mov    %esp,%ebp
f0100698:	83 ec 08             	sub    $0x8,%esp
	cons_intr(kbd_proc_data);
f010069b:	b8 b0 03 10 f0       	mov    $0xf01003b0,%eax
f01006a0:	e8 c7 fc ff ff       	call   f010036c <cons_intr>
}
f01006a5:	c9                   	leave  
f01006a6:	c3                   	ret    

f01006a7 <cons_getc>:
}

// return the next input character from the console, or 0 if none waiting
int
cons_getc(void)
{
f01006a7:	55                   	push   %ebp
f01006a8:	89 e5                	mov    %esp,%ebp
f01006aa:	83 ec 08             	sub    $0x8,%esp
	int c;

	// poll for any pending input characters,
	// so that this function works even when interrupts are disabled
	// (e.g., when called from the kernel monitor).
	serial_intr();
f01006ad:	e8 c7 ff ff ff       	call   f0100679 <serial_intr>
	kbd_intr();
f01006b2:	e8 de ff ff ff       	call   f0100695 <kbd_intr>

	// grab the next character from the input buffer.
	if (cons.rpos != cons.wpos) {
f01006b7:	a1 a0 52 18 f0       	mov    0xf01852a0,%eax
f01006bc:	3b 05 a4 52 18 f0    	cmp    0xf01852a4,%eax
f01006c2:	74 26                	je     f01006ea <cons_getc+0x43>
		c = cons.buf[cons.rpos++];
f01006c4:	8d 50 01             	lea    0x1(%eax),%edx
f01006c7:	89 15 a0 52 18 f0    	mov    %edx,0xf01852a0
f01006cd:	0f b6 88 a0 50 18 f0 	movzbl -0xfe7af60(%eax),%ecx
		if (cons.rpos == CONSBUFSIZE)
			cons.rpos = 0;
		return c;
f01006d4:	89 c8                	mov    %ecx,%eax
	kbd_intr();

	// grab the next character from the input buffer.
	if (cons.rpos != cons.wpos) {
		c = cons.buf[cons.rpos++];
		if (cons.rpos == CONSBUFSIZE)
f01006d6:	81 fa 00 02 00 00    	cmp    $0x200,%edx
f01006dc:	75 11                	jne    f01006ef <cons_getc+0x48>
			cons.rpos = 0;
f01006de:	c7 05 a0 52 18 f0 00 	movl   $0x0,0xf01852a0
f01006e5:	00 00 00 
f01006e8:	eb 05                	jmp    f01006ef <cons_getc+0x48>
		return c;
	}
	return 0;
f01006ea:	b8 00 00 00 00       	mov    $0x0,%eax
}
f01006ef:	c9                   	leave  
f01006f0:	c3                   	ret    

f01006f1 <cons_init>:
}

// initialize the console devices
void
cons_init(void)
{
f01006f1:	55                   	push   %ebp
f01006f2:	89 e5                	mov    %esp,%ebp
f01006f4:	83 ec 18             	sub    $0x18,%esp
	cga_init();
f01006f7:	e8 d1 fb ff ff       	call   f01002cd <cga_init>
	kbd_init();
	serial_init();
f01006fc:	e8 e0 fa ff ff       	call   f01001e1 <serial_init>

	if (!serial_exists)
f0100701:	80 3d b4 52 18 f0 00 	cmpb   $0x0,0xf01852b4
f0100708:	75 0c                	jne    f0100716 <cons_init+0x25>
		cprintf("Serial port does not exist!\n");
f010070a:	c7 04 24 c8 4b 10 f0 	movl   $0xf0104bc8,(%esp)
f0100711:	e8 e8 2f 00 00       	call   f01036fe <cprintf>
}
f0100716:	c9                   	leave  
f0100717:	c3                   	ret    

f0100718 <cputchar>:

// `High'-level console I/O.  Used by readline and cprintf.

void
cputchar(int c)
{
f0100718:	55                   	push   %ebp
f0100719:	89 e5                	mov    %esp,%ebp
f010071b:	83 ec 08             	sub    $0x8,%esp
	cons_putc(c);
f010071e:	8b 45 08             	mov    0x8(%ebp),%eax
f0100721:	e8 31 ff ff ff       	call   f0100657 <cons_putc>
}
f0100726:	c9                   	leave  
f0100727:	c3                   	ret    

f0100728 <getchar>:

int
getchar(void)
{
f0100728:	55                   	push   %ebp
f0100729:	89 e5                	mov    %esp,%ebp
f010072b:	83 ec 08             	sub    $0x8,%esp
	int c;

	while ((c = cons_getc()) == 0)
f010072e:	e8 74 ff ff ff       	call   f01006a7 <cons_getc>
f0100733:	85 c0                	test   %eax,%eax
f0100735:	74 f7                	je     f010072e <getchar+0x6>
		/* do nothing */;
	return c;
}
f0100737:	c9                   	leave  
f0100738:	c3                   	ret    

f0100739 <iscons>:

int
iscons(int fdnum)
{
f0100739:	55                   	push   %ebp
f010073a:	89 e5                	mov    %esp,%ebp
	// used by readline
	return 1;
}
f010073c:	b8 01 00 00 00       	mov    $0x1,%eax
f0100741:	5d                   	pop    %ebp
f0100742:	c3                   	ret    
f0100743:	66 90                	xchg   %ax,%ax
f0100745:	66 90                	xchg   %ax,%ax
f0100747:	66 90                	xchg   %ax,%ax
f0100749:	66 90                	xchg   %ax,%ax
f010074b:	66 90                	xchg   %ax,%ax
f010074d:	66 90                	xchg   %ax,%ax
f010074f:	90                   	nop

f0100750 <mon_help>:

/***** Implementations of basic kernel monitor commands *****/

int
mon_help(int argc, char **argv, struct Trapframe *tf)
{
f0100750:	55                   	push   %ebp
f0100751:	89 e5                	mov    %esp,%ebp
f0100753:	83 ec 18             	sub    $0x18,%esp
	int i;

	for (i = 0; i < ARRAY_SIZE(commands); i++)
		cprintf("%s - %s\n", commands[i].name, commands[i].desc);
f0100756:	c7 44 24 08 20 4e 10 	movl   $0xf0104e20,0x8(%esp)
f010075d:	f0 
f010075e:	c7 44 24 04 3e 4e 10 	movl   $0xf0104e3e,0x4(%esp)
f0100765:	f0 
f0100766:	c7 04 24 43 4e 10 f0 	movl   $0xf0104e43,(%esp)
f010076d:	e8 8c 2f 00 00       	call   f01036fe <cprintf>
f0100772:	c7 44 24 08 e0 4e 10 	movl   $0xf0104ee0,0x8(%esp)
f0100779:	f0 
f010077a:	c7 44 24 04 4c 4e 10 	movl   $0xf0104e4c,0x4(%esp)
f0100781:	f0 
f0100782:	c7 04 24 43 4e 10 f0 	movl   $0xf0104e43,(%esp)
f0100789:	e8 70 2f 00 00       	call   f01036fe <cprintf>
f010078e:	c7 44 24 08 55 4e 10 	movl   $0xf0104e55,0x8(%esp)
f0100795:	f0 
f0100796:	c7 44 24 04 69 4e 10 	movl   $0xf0104e69,0x4(%esp)
f010079d:	f0 
f010079e:	c7 04 24 43 4e 10 f0 	movl   $0xf0104e43,(%esp)
f01007a5:	e8 54 2f 00 00       	call   f01036fe <cprintf>
	return 0;
}
f01007aa:	b8 00 00 00 00       	mov    $0x0,%eax
f01007af:	c9                   	leave  
f01007b0:	c3                   	ret    

f01007b1 <mon_kerninfo>:

int
mon_kerninfo(int argc, char **argv, struct Trapframe *tf)
{
f01007b1:	55                   	push   %ebp
f01007b2:	89 e5                	mov    %esp,%ebp
f01007b4:	83 ec 18             	sub    $0x18,%esp
	extern char _start[], entry[], etext[], edata[], end[];

	cprintf("Special kernel symbols:\n");
f01007b7:	c7 04 24 73 4e 10 f0 	movl   $0xf0104e73,(%esp)
f01007be:	e8 3b 2f 00 00       	call   f01036fe <cprintf>
	cprintf("  _start                  %08x (phys)\n", _start);
f01007c3:	c7 44 24 04 0c 00 10 	movl   $0x10000c,0x4(%esp)
f01007ca:	00 
f01007cb:	c7 04 24 08 4f 10 f0 	movl   $0xf0104f08,(%esp)
f01007d2:	e8 27 2f 00 00       	call   f01036fe <cprintf>
	cprintf("  entry  %08x (virt)  %08x (phys)\n", entry, entry - KERNBASE);
f01007d7:	c7 44 24 08 0c 00 10 	movl   $0x10000c,0x8(%esp)
f01007de:	00 
f01007df:	c7 44 24 04 0c 00 10 	movl   $0xf010000c,0x4(%esp)
f01007e6:	f0 
f01007e7:	c7 04 24 30 4f 10 f0 	movl   $0xf0104f30,(%esp)
f01007ee:	e8 0b 2f 00 00       	call   f01036fe <cprintf>
	cprintf("  etext  %08x (virt)  %08x (phys)\n", etext, etext - KERNBASE);
f01007f3:	c7 44 24 08 51 4b 10 	movl   $0x104b51,0x8(%esp)
f01007fa:	00 
f01007fb:	c7 44 24 04 51 4b 10 	movl   $0xf0104b51,0x4(%esp)
f0100802:	f0 
f0100803:	c7 04 24 54 4f 10 f0 	movl   $0xf0104f54,(%esp)
f010080a:	e8 ef 2e 00 00       	call   f01036fe <cprintf>
	cprintf("  edata  %08x (virt)  %08x (phys)\n", edata, edata - KERNBASE);
f010080f:	c7 44 24 08 78 50 18 	movl   $0x185078,0x8(%esp)
f0100816:	00 
f0100817:	c7 44 24 04 78 50 18 	movl   $0xf0185078,0x4(%esp)
f010081e:	f0 
f010081f:	c7 04 24 78 4f 10 f0 	movl   $0xf0104f78,(%esp)
f0100826:	e8 d3 2e 00 00       	call   f01036fe <cprintf>
	cprintf("  end    %08x (virt)  %08x (phys)\n", end, end - KERNBASE);
f010082b:	c7 44 24 08 90 6f 18 	movl   $0x186f90,0x8(%esp)
f0100832:	00 
f0100833:	c7 44 24 04 90 6f 18 	movl   $0xf0186f90,0x4(%esp)
f010083a:	f0 
f010083b:	c7 04 24 9c 4f 10 f0 	movl   $0xf0104f9c,(%esp)
f0100842:	e8 b7 2e 00 00       	call   f01036fe <cprintf>
	cprintf("Kernel executable memory footprint: %dKB\n",
		ROUNDUP(end - entry, 1024) / 1024);
f0100847:	b8 8f 73 18 f0       	mov    $0xf018738f,%eax
f010084c:	2d 0c 00 10 f0       	sub    $0xf010000c,%eax
f0100851:	25 00 fc ff ff       	and    $0xfffffc00,%eax
	cprintf("  _start                  %08x (phys)\n", _start);
	cprintf("  entry  %08x (virt)  %08x (phys)\n", entry, entry - KERNBASE);
	cprintf("  etext  %08x (virt)  %08x (phys)\n", etext, etext - KERNBASE);
	cprintf("  edata  %08x (virt)  %08x (phys)\n", edata, edata - KERNBASE);
	cprintf("  end    %08x (virt)  %08x (phys)\n", end, end - KERNBASE);
	cprintf("Kernel executable memory footprint: %dKB\n",
f0100856:	8d 90 ff 03 00 00    	lea    0x3ff(%eax),%edx
f010085c:	85 c0                	test   %eax,%eax
f010085e:	0f 48 c2             	cmovs  %edx,%eax
f0100861:	c1 f8 0a             	sar    $0xa,%eax
f0100864:	89 44 24 04          	mov    %eax,0x4(%esp)
f0100868:	c7 04 24 c0 4f 10 f0 	movl   $0xf0104fc0,(%esp)
f010086f:	e8 8a 2e 00 00       	call   f01036fe <cprintf>
		ROUNDUP(end - entry, 1024) / 1024);
	return 0;
}
f0100874:	b8 00 00 00 00       	mov    $0x0,%eax
f0100879:	c9                   	leave  
f010087a:	c3                   	ret    

f010087b <mon_backtrace>:

int
mon_backtrace(int argc, char **argv, struct Trapframe *tf)
{
f010087b:	55                   	push   %ebp
f010087c:	89 e5                	mov    %esp,%ebp
f010087e:	57                   	push   %edi
f010087f:	56                   	push   %esi
f0100880:	53                   	push   %ebx
f0100881:	83 ec 4c             	sub    $0x4c,%esp

static inline uint32_t __attribute__((always_inline))
read_ebp(void)
{
	uint32_t ebp;
	asm volatile("movl %%ebp,%0" : "=r" (ebp));
f0100884:	89 eb                	mov    %ebp,%ebx
	while (ebp != 0x0){
	uint32_t eip=*(uint32_t *)(ebp+4);
	cprintf("  ebp %08x eip %08x args %08x %08x %08x %08x %08x\n", ebp, eip, 
			*(uint32_t *)(ebp+8), *(uint32_t *)(ebp+12), *(uint32_t *)(ebp+16),
			*(uint32_t *)(ebp+20), *(uint32_t *)(ebp+24));
	debuginfo_eip(eip,&dbgi);
f0100886:	8d 7d d0             	lea    -0x30(%ebp),%edi
int
mon_backtrace(int argc, char **argv, struct Trapframe *tf)
{
	uint32_t ebp = read_ebp();
	struct Eipdebuginfo dbgi;
	while (ebp != 0x0){
f0100889:	eb 77                	jmp    f0100902 <mon_backtrace+0x87>
	uint32_t eip=*(uint32_t *)(ebp+4);
f010088b:	8b 73 04             	mov    0x4(%ebx),%esi
	cprintf("  ebp %08x eip %08x args %08x %08x %08x %08x %08x\n", ebp, eip, 
f010088e:	8b 43 18             	mov    0x18(%ebx),%eax
f0100891:	89 44 24 1c          	mov    %eax,0x1c(%esp)
f0100895:	8b 43 14             	mov    0x14(%ebx),%eax
f0100898:	89 44 24 18          	mov    %eax,0x18(%esp)
f010089c:	8b 43 10             	mov    0x10(%ebx),%eax
f010089f:	89 44 24 14          	mov    %eax,0x14(%esp)
f01008a3:	8b 43 0c             	mov    0xc(%ebx),%eax
f01008a6:	89 44 24 10          	mov    %eax,0x10(%esp)
f01008aa:	8b 43 08             	mov    0x8(%ebx),%eax
f01008ad:	89 44 24 0c          	mov    %eax,0xc(%esp)
f01008b1:	89 74 24 08          	mov    %esi,0x8(%esp)
f01008b5:	89 5c 24 04          	mov    %ebx,0x4(%esp)
f01008b9:	c7 04 24 ec 4f 10 f0 	movl   $0xf0104fec,(%esp)
f01008c0:	e8 39 2e 00 00       	call   f01036fe <cprintf>
			*(uint32_t *)(ebp+8), *(uint32_t *)(ebp+12), *(uint32_t *)(ebp+16),
			*(uint32_t *)(ebp+20), *(uint32_t *)(ebp+24));
	debuginfo_eip(eip,&dbgi);
f01008c5:	89 7c 24 04          	mov    %edi,0x4(%esp)
f01008c9:	89 34 24             	mov    %esi,(%esp)
f01008cc:	e8 9e 33 00 00       	call   f0103c6f <debuginfo_eip>
	cprintf("       %s:%d: %.*s+%d\n", dbgi.eip_file, dbgi.eip_line, dbgi.eip_fn_namelen, 
f01008d1:	2b 75 e0             	sub    -0x20(%ebp),%esi
f01008d4:	89 74 24 14          	mov    %esi,0x14(%esp)
f01008d8:	8b 45 d8             	mov    -0x28(%ebp),%eax
f01008db:	89 44 24 10          	mov    %eax,0x10(%esp)
f01008df:	8b 45 dc             	mov    -0x24(%ebp),%eax
f01008e2:	89 44 24 0c          	mov    %eax,0xc(%esp)
f01008e6:	8b 45 d4             	mov    -0x2c(%ebp),%eax
f01008e9:	89 44 24 08          	mov    %eax,0x8(%esp)
f01008ed:	8b 45 d0             	mov    -0x30(%ebp),%eax
f01008f0:	89 44 24 04          	mov    %eax,0x4(%esp)
f01008f4:	c7 04 24 8c 4e 10 f0 	movl   $0xf0104e8c,(%esp)
f01008fb:	e8 fe 2d 00 00       	call   f01036fe <cprintf>
			dbgi.eip_fn_name,((uintptr_t)eip - dbgi.eip_fn_addr));
	ebp = *(uint32_t *)(ebp);
f0100900:	8b 1b                	mov    (%ebx),%ebx
int
mon_backtrace(int argc, char **argv, struct Trapframe *tf)
{
	uint32_t ebp = read_ebp();
	struct Eipdebuginfo dbgi;
	while (ebp != 0x0){
f0100902:	85 db                	test   %ebx,%ebx
f0100904:	75 85                	jne    f010088b <mon_backtrace+0x10>
	cprintf("       %s:%d: %.*s+%d\n", dbgi.eip_file, dbgi.eip_line, dbgi.eip_fn_namelen, 
			dbgi.eip_fn_name,((uintptr_t)eip - dbgi.eip_fn_addr));
	ebp = *(uint32_t *)(ebp);
	}
	return 0;
}
f0100906:	b8 00 00 00 00       	mov    $0x0,%eax
f010090b:	83 c4 4c             	add    $0x4c,%esp
f010090e:	5b                   	pop    %ebx
f010090f:	5e                   	pop    %esi
f0100910:	5f                   	pop    %edi
f0100911:	5d                   	pop    %ebp
f0100912:	c3                   	ret    

f0100913 <runcmd>:
#define WHITESPACE "\t\r\n "
#define MAXARGS 16

static int
runcmd(char *buf, struct Trapframe *tf)
{
f0100913:	55                   	push   %ebp
f0100914:	89 e5                	mov    %esp,%ebp
f0100916:	57                   	push   %edi
f0100917:	56                   	push   %esi
f0100918:	53                   	push   %ebx
f0100919:	83 ec 5c             	sub    $0x5c,%esp
f010091c:	89 c3                	mov    %eax,%ebx
f010091e:	89 55 a4             	mov    %edx,-0x5c(%ebp)
	char *argv[MAXARGS];
	int i;

	// Parse the command buffer into whitespace-separated arguments
	argc = 0;
	argv[argc] = 0;
f0100921:	c7 45 a8 00 00 00 00 	movl   $0x0,-0x58(%ebp)
	int argc;
	char *argv[MAXARGS];
	int i;

	// Parse the command buffer into whitespace-separated arguments
	argc = 0;
f0100928:	be 00 00 00 00       	mov    $0x0,%esi
f010092d:	eb 0a                	jmp    f0100939 <runcmd+0x26>
	argv[argc] = 0;
	while (1) {
		// gobble whitespace
		while (*buf && strchr(WHITESPACE, *buf))
			*buf++ = 0;
f010092f:	c6 03 00             	movb   $0x0,(%ebx)
f0100932:	89 f7                	mov    %esi,%edi
f0100934:	8d 5b 01             	lea    0x1(%ebx),%ebx
f0100937:	89 fe                	mov    %edi,%esi
	// Parse the command buffer into whitespace-separated arguments
	argc = 0;
	argv[argc] = 0;
	while (1) {
		// gobble whitespace
		while (*buf && strchr(WHITESPACE, *buf))
f0100939:	0f b6 03             	movzbl (%ebx),%eax
f010093c:	84 c0                	test   %al,%al
f010093e:	74 6c                	je     f01009ac <runcmd+0x99>
f0100940:	0f be c0             	movsbl %al,%eax
f0100943:	89 44 24 04          	mov    %eax,0x4(%esp)
f0100947:	c7 04 24 a3 4e 10 f0 	movl   $0xf0104ea3,(%esp)
f010094e:	e8 37 3d 00 00       	call   f010468a <strchr>
f0100953:	85 c0                	test   %eax,%eax
f0100955:	75 d8                	jne    f010092f <runcmd+0x1c>
			*buf++ = 0;
		if (*buf == 0)
f0100957:	80 3b 00             	cmpb   $0x0,(%ebx)
f010095a:	74 50                	je     f01009ac <runcmd+0x99>
			break;

		// save and scan past next arg
		if (argc == MAXARGS-1) {
f010095c:	83 fe 0f             	cmp    $0xf,%esi
f010095f:	90                   	nop
f0100960:	75 1e                	jne    f0100980 <runcmd+0x6d>
			cprintf("Too many arguments (max %d)\n", MAXARGS);
f0100962:	c7 44 24 04 10 00 00 	movl   $0x10,0x4(%esp)
f0100969:	00 
f010096a:	c7 04 24 a8 4e 10 f0 	movl   $0xf0104ea8,(%esp)
f0100971:	e8 88 2d 00 00       	call   f01036fe <cprintf>
			return 0;
f0100976:	b8 00 00 00 00       	mov    $0x0,%eax
f010097b:	e9 9c 00 00 00       	jmp    f0100a1c <runcmd+0x109>
		}
		argv[argc++] = buf;
f0100980:	8d 7e 01             	lea    0x1(%esi),%edi
f0100983:	89 5c b5 a8          	mov    %ebx,-0x58(%ebp,%esi,4)
		while (*buf && !strchr(WHITESPACE, *buf))
f0100987:	eb 03                	jmp    f010098c <runcmd+0x79>
			buf++;
f0100989:	83 c3 01             	add    $0x1,%ebx
		if (argc == MAXARGS-1) {
			cprintf("Too many arguments (max %d)\n", MAXARGS);
			return 0;
		}
		argv[argc++] = buf;
		while (*buf && !strchr(WHITESPACE, *buf))
f010098c:	0f b6 03             	movzbl (%ebx),%eax
f010098f:	84 c0                	test   %al,%al
f0100991:	74 a4                	je     f0100937 <runcmd+0x24>
f0100993:	0f be c0             	movsbl %al,%eax
f0100996:	89 44 24 04          	mov    %eax,0x4(%esp)
f010099a:	c7 04 24 a3 4e 10 f0 	movl   $0xf0104ea3,(%esp)
f01009a1:	e8 e4 3c 00 00       	call   f010468a <strchr>
f01009a6:	85 c0                	test   %eax,%eax
f01009a8:	74 df                	je     f0100989 <runcmd+0x76>
f01009aa:	eb 8b                	jmp    f0100937 <runcmd+0x24>
			buf++;
	}
	argv[argc] = 0;
f01009ac:	c7 44 b5 a8 00 00 00 	movl   $0x0,-0x58(%ebp,%esi,4)
f01009b3:	00 

	// Lookup and invoke the command
	if (argc == 0)
		return 0;
f01009b4:	b8 00 00 00 00       	mov    $0x0,%eax
			buf++;
	}
	argv[argc] = 0;

	// Lookup and invoke the command
	if (argc == 0)
f01009b9:	85 f6                	test   %esi,%esi
f01009bb:	74 5f                	je     f0100a1c <runcmd+0x109>
f01009bd:	bb 00 00 00 00       	mov    $0x0,%ebx
f01009c2:	8d 04 5b             	lea    (%ebx,%ebx,2),%eax
		return 0;
	for (i = 0; i < ARRAY_SIZE(commands); i++) {
		if (strcmp(argv[0], commands[i].name) == 0)
f01009c5:	8b 04 85 80 50 10 f0 	mov    -0xfefaf80(,%eax,4),%eax
f01009cc:	89 44 24 04          	mov    %eax,0x4(%esp)
f01009d0:	8b 45 a8             	mov    -0x58(%ebp),%eax
f01009d3:	89 04 24             	mov    %eax,(%esp)
f01009d6:	e8 51 3c 00 00       	call   f010462c <strcmp>
f01009db:	85 c0                	test   %eax,%eax
f01009dd:	75 1d                	jne    f01009fc <runcmd+0xe9>
			return commands[i].func(argc, argv, tf);
f01009df:	8d 04 5b             	lea    (%ebx,%ebx,2),%eax
f01009e2:	8b 4d a4             	mov    -0x5c(%ebp),%ecx
f01009e5:	89 4c 24 08          	mov    %ecx,0x8(%esp)
f01009e9:	8d 55 a8             	lea    -0x58(%ebp),%edx
f01009ec:	89 54 24 04          	mov    %edx,0x4(%esp)
f01009f0:	89 34 24             	mov    %esi,(%esp)
f01009f3:	ff 14 85 88 50 10 f0 	call   *-0xfefaf78(,%eax,4)
f01009fa:	eb 20                	jmp    f0100a1c <runcmd+0x109>
	argv[argc] = 0;

	// Lookup and invoke the command
	if (argc == 0)
		return 0;
	for (i = 0; i < ARRAY_SIZE(commands); i++) {
f01009fc:	83 c3 01             	add    $0x1,%ebx
f01009ff:	83 fb 03             	cmp    $0x3,%ebx
f0100a02:	75 be                	jne    f01009c2 <runcmd+0xaf>
		if (strcmp(argv[0], commands[i].name) == 0)
			return commands[i].func(argc, argv, tf);
	}
	cprintf("Unknown command '%s'\n", argv[0]);
f0100a04:	8b 45 a8             	mov    -0x58(%ebp),%eax
f0100a07:	89 44 24 04          	mov    %eax,0x4(%esp)
f0100a0b:	c7 04 24 c5 4e 10 f0 	movl   $0xf0104ec5,(%esp)
f0100a12:	e8 e7 2c 00 00       	call   f01036fe <cprintf>
	return 0;
f0100a17:	b8 00 00 00 00       	mov    $0x0,%eax
}
f0100a1c:	83 c4 5c             	add    $0x5c,%esp
f0100a1f:	5b                   	pop    %ebx
f0100a20:	5e                   	pop    %esi
f0100a21:	5f                   	pop    %edi
f0100a22:	5d                   	pop    %ebp
f0100a23:	c3                   	ret    

f0100a24 <monitor>:

void
monitor(struct Trapframe *tf)
{
f0100a24:	55                   	push   %ebp
f0100a25:	89 e5                	mov    %esp,%ebp
f0100a27:	53                   	push   %ebx
f0100a28:	83 ec 14             	sub    $0x14,%esp
f0100a2b:	8b 5d 08             	mov    0x8(%ebp),%ebx
	char *buf;

	cprintf("Welcome to the JOS kernel monitor!\n");
f0100a2e:	c7 04 24 20 50 10 f0 	movl   $0xf0105020,(%esp)
f0100a35:	e8 c4 2c 00 00       	call   f01036fe <cprintf>
	cprintf("Type 'help' for a list of commands.\n");
f0100a3a:	c7 04 24 44 50 10 f0 	movl   $0xf0105044,(%esp)
f0100a41:	e8 b8 2c 00 00       	call   f01036fe <cprintf>

	if (tf != NULL)
f0100a46:	85 db                	test   %ebx,%ebx
f0100a48:	74 08                	je     f0100a52 <monitor+0x2e>
		print_trapframe(tf);
f0100a4a:	89 1c 24             	mov    %ebx,(%esp)
f0100a4d:	e8 1a 2e 00 00       	call   f010386c <print_trapframe>

	while (1) {
		buf = readline("K> ");
f0100a52:	c7 04 24 db 4e 10 f0 	movl   $0xf0104edb,(%esp)
f0100a59:	e8 12 3a 00 00       	call   f0104470 <readline>
		if (buf != NULL)
f0100a5e:	85 c0                	test   %eax,%eax
f0100a60:	74 f0                	je     f0100a52 <monitor+0x2e>
			if (runcmd(buf, tf) < 0)
f0100a62:	89 da                	mov    %ebx,%edx
f0100a64:	e8 aa fe ff ff       	call   f0100913 <runcmd>
f0100a69:	85 c0                	test   %eax,%eax
f0100a6b:	79 e5                	jns    f0100a52 <monitor+0x2e>
				break;
	}
}
f0100a6d:	83 c4 14             	add    $0x14,%esp
f0100a70:	5b                   	pop    %ebx
f0100a71:	5d                   	pop    %ebp
f0100a72:	c3                   	ret    

f0100a73 <invlpg>:
	asm volatile("outl %0,%w1" : : "a" (data), "d" (port));
}

static inline void
invlpg(void *addr)
{
f0100a73:	55                   	push   %ebp
f0100a74:	89 e5                	mov    %esp,%ebp
	asm volatile("invlpg (%0)" : : "r" (addr) : "memory");
f0100a76:	0f 01 38             	invlpg (%eax)
}
f0100a79:	5d                   	pop    %ebp
f0100a7a:	c3                   	ret    

f0100a7b <lcr0>:
	asm volatile("ltr %0" : : "r" (sel));
}

static inline void
lcr0(uint32_t val)
{
f0100a7b:	55                   	push   %ebp
f0100a7c:	89 e5                	mov    %esp,%ebp
	asm volatile("movl %0,%%cr0" : : "r" (val));
f0100a7e:	0f 22 c0             	mov    %eax,%cr0
}
f0100a81:	5d                   	pop    %ebp
f0100a82:	c3                   	ret    

f0100a83 <rcr0>:

static inline uint32_t
rcr0(void)
{
f0100a83:	55                   	push   %ebp
f0100a84:	89 e5                	mov    %esp,%ebp
	uint32_t val;
	asm volatile("movl %%cr0,%0" : "=r" (val));
f0100a86:	0f 20 c0             	mov    %cr0,%eax
	return val;
}
f0100a89:	5d                   	pop    %ebp
f0100a8a:	c3                   	ret    

f0100a8b <lcr3>:
	return val;
}

static inline void
lcr3(uint32_t val)
{
f0100a8b:	55                   	push   %ebp
f0100a8c:	89 e5                	mov    %esp,%ebp
	asm volatile("movl %0,%%cr3" : : "r" (val));
f0100a8e:	0f 22 d8             	mov    %eax,%cr3
}
f0100a91:	5d                   	pop    %ebp
f0100a92:	c3                   	ret    

f0100a93 <page2pa>:
int	user_mem_check(struct Env *env, const void *va, size_t len, int perm);
void	user_mem_assert(struct Env *env, const void *va, size_t len, int perm);

static inline physaddr_t
page2pa(struct PageInfo *pp)
{
f0100a93:	55                   	push   %ebp
f0100a94:	89 e5                	mov    %esp,%ebp
	return (pp - pages) << PGSHIFT;
f0100a96:	2b 05 8c 6f 18 f0    	sub    0xf0186f8c,%eax
f0100a9c:	c1 f8 03             	sar    $0x3,%eax
f0100a9f:	c1 e0 0c             	shl    $0xc,%eax
}
f0100aa2:	5d                   	pop    %ebp
f0100aa3:	c3                   	ret    

f0100aa4 <nvram_read>:
// Detect machine's physical memory setup.
// --------------------------------------------------------------

static int
nvram_read(int r)
{
f0100aa4:	55                   	push   %ebp
f0100aa5:	89 e5                	mov    %esp,%ebp
f0100aa7:	56                   	push   %esi
f0100aa8:	53                   	push   %ebx
f0100aa9:	83 ec 10             	sub    $0x10,%esp
f0100aac:	89 c3                	mov    %eax,%ebx
	return mc146818_read(r) | (mc146818_read(r + 1) << 8);
f0100aae:	89 04 24             	mov    %eax,(%esp)
f0100ab1:	e8 c1 2b 00 00       	call   f0103677 <mc146818_read>
f0100ab6:	89 c6                	mov    %eax,%esi
f0100ab8:	83 c3 01             	add    $0x1,%ebx
f0100abb:	89 1c 24             	mov    %ebx,(%esp)
f0100abe:	e8 b4 2b 00 00       	call   f0103677 <mc146818_read>
f0100ac3:	c1 e0 08             	shl    $0x8,%eax
f0100ac6:	09 f0                	or     %esi,%eax
}
f0100ac8:	83 c4 10             	add    $0x10,%esp
f0100acb:	5b                   	pop    %ebx
f0100acc:	5e                   	pop    %esi
f0100acd:	5d                   	pop    %ebp
f0100ace:	c3                   	ret    

f0100acf <i386_detect_memory>:

static void
i386_detect_memory(void)
{
f0100acf:	55                   	push   %ebp
f0100ad0:	89 e5                	mov    %esp,%ebp
f0100ad2:	56                   	push   %esi
f0100ad3:	53                   	push   %ebx
f0100ad4:	83 ec 10             	sub    $0x10,%esp
	size_t basemem, extmem, ext16mem, totalmem;

	// Use CMOS calls to measure available base & extended memory.
	// (CMOS calls return results in kilobytes.)
	basemem = nvram_read(NVRAM_BASELO);
f0100ad7:	b8 15 00 00 00       	mov    $0x15,%eax
f0100adc:	e8 c3 ff ff ff       	call   f0100aa4 <nvram_read>
f0100ae1:	89 c3                	mov    %eax,%ebx
	extmem = nvram_read(NVRAM_EXTLO);
f0100ae3:	b8 17 00 00 00       	mov    $0x17,%eax
f0100ae8:	e8 b7 ff ff ff       	call   f0100aa4 <nvram_read>
f0100aed:	89 c6                	mov    %eax,%esi
	ext16mem = nvram_read(NVRAM_EXT16LO) * 64;
f0100aef:	b8 34 00 00 00       	mov    $0x34,%eax
f0100af4:	e8 ab ff ff ff       	call   f0100aa4 <nvram_read>
f0100af9:	c1 e0 06             	shl    $0x6,%eax

	// Calculate the number of physical pages available in both base
	// and extended memory.
	if (ext16mem)
f0100afc:	85 c0                	test   %eax,%eax
f0100afe:	74 07                	je     f0100b07 <i386_detect_memory+0x38>
		totalmem = 16 * 1024 + ext16mem;
f0100b00:	05 00 40 00 00       	add    $0x4000,%eax
f0100b05:	eb 0b                	jmp    f0100b12 <i386_detect_memory+0x43>
	else if (extmem)
		totalmem = 1 * 1024 + extmem;
f0100b07:	8d 86 00 04 00 00    	lea    0x400(%esi),%eax
f0100b0d:	85 f6                	test   %esi,%esi
f0100b0f:	0f 44 c3             	cmove  %ebx,%eax
	else
		totalmem = basemem;

	npages = totalmem / (PGSIZE / 1024);
f0100b12:	89 c2                	mov    %eax,%edx
f0100b14:	c1 ea 02             	shr    $0x2,%edx
f0100b17:	89 15 84 6f 18 f0    	mov    %edx,0xf0186f84
	npages_basemem = basemem / (PGSIZE / 1024);
f0100b1d:	89 da                	mov    %ebx,%edx
f0100b1f:	c1 ea 02             	shr    $0x2,%edx
f0100b22:	89 15 c0 52 18 f0    	mov    %edx,0xf01852c0

	cprintf("Physical memory: %uK available, base = %uK, extended = %uK\n",
f0100b28:	89 c2                	mov    %eax,%edx
f0100b2a:	29 da                	sub    %ebx,%edx
f0100b2c:	89 54 24 0c          	mov    %edx,0xc(%esp)
f0100b30:	89 5c 24 08          	mov    %ebx,0x8(%esp)
f0100b34:	89 44 24 04          	mov    %eax,0x4(%esp)
f0100b38:	c7 04 24 a4 50 10 f0 	movl   $0xf01050a4,(%esp)
f0100b3f:	e8 ba 2b 00 00       	call   f01036fe <cprintf>
		totalmem, basemem, totalmem - basemem);
}
f0100b44:	83 c4 10             	add    $0x10,%esp
f0100b47:	5b                   	pop    %ebx
f0100b48:	5e                   	pop    %esi
f0100b49:	5d                   	pop    %ebp
f0100b4a:	c3                   	ret    

f0100b4b <_kaddr>:
 * virtual address.  It panics if you pass an invalid physical address. */
#define KADDR(pa) _kaddr(__FILE__, __LINE__, pa)

static inline void*
_kaddr(const char *file, int line, physaddr_t pa)
{
f0100b4b:	55                   	push   %ebp
f0100b4c:	89 e5                	mov    %esp,%ebp
f0100b4e:	53                   	push   %ebx
f0100b4f:	83 ec 14             	sub    $0x14,%esp
	if (PGNUM(pa) >= npages)
f0100b52:	89 cb                	mov    %ecx,%ebx
f0100b54:	c1 eb 0c             	shr    $0xc,%ebx
f0100b57:	3b 1d 84 6f 18 f0    	cmp    0xf0186f84,%ebx
f0100b5d:	72 18                	jb     f0100b77 <_kaddr+0x2c>
		_panic(file, line, "KADDR called with invalid pa %08lx", pa);
f0100b5f:	89 4c 24 0c          	mov    %ecx,0xc(%esp)
f0100b63:	c7 44 24 08 e0 50 10 	movl   $0xf01050e0,0x8(%esp)
f0100b6a:	f0 
f0100b6b:	89 54 24 04          	mov    %edx,0x4(%esp)
f0100b6f:	89 04 24             	mov    %eax,(%esp)
f0100b72:	e8 32 f5 ff ff       	call   f01000a9 <_panic>
	return (void *)(pa + KERNBASE);
f0100b77:	8d 81 00 00 00 f0    	lea    -0x10000000(%ecx),%eax
}
f0100b7d:	83 c4 14             	add    $0x14,%esp
f0100b80:	5b                   	pop    %ebx
f0100b81:	5d                   	pop    %ebp
f0100b82:	c3                   	ret    

f0100b83 <page2kva>:
	return &pages[PGNUM(pa)];
}

static inline void*
page2kva(struct PageInfo *pp)
{
f0100b83:	55                   	push   %ebp
f0100b84:	89 e5                	mov    %esp,%ebp
f0100b86:	83 ec 08             	sub    $0x8,%esp
	return KADDR(page2pa(pp));
f0100b89:	e8 05 ff ff ff       	call   f0100a93 <page2pa>
f0100b8e:	89 c1                	mov    %eax,%ecx
f0100b90:	ba 56 00 00 00       	mov    $0x56,%edx
f0100b95:	b8 8d 58 10 f0       	mov    $0xf010588d,%eax
f0100b9a:	e8 ac ff ff ff       	call   f0100b4b <_kaddr>
}
f0100b9f:	c9                   	leave  
f0100ba0:	c3                   	ret    

f0100ba1 <check_va2pa>:
// this functionality for us!  We define our own version to help check
// the check_kern_pgdir() function; it shouldn't be used elsewhere.

static physaddr_t
check_va2pa(pde_t *pgdir, uintptr_t va)
{
f0100ba1:	55                   	push   %ebp
f0100ba2:	89 e5                	mov    %esp,%ebp
f0100ba4:	53                   	push   %ebx
f0100ba5:	83 ec 04             	sub    $0x4,%esp
f0100ba8:	89 d3                	mov    %edx,%ebx
	pte_t *p;

	pgdir = &pgdir[PDX(va)];
f0100baa:	c1 ea 16             	shr    $0x16,%edx
	if (!(*pgdir & PTE_P))
f0100bad:	8b 0c 90             	mov    (%eax,%edx,4),%ecx
		return ~0;
f0100bb0:	b8 ff ff ff ff       	mov    $0xffffffff,%eax
check_va2pa(pde_t *pgdir, uintptr_t va)
{
	pte_t *p;

	pgdir = &pgdir[PDX(va)];
	if (!(*pgdir & PTE_P))
f0100bb5:	f6 c1 01             	test   $0x1,%cl
f0100bb8:	74 4d                	je     f0100c07 <check_va2pa+0x66>
		return ~0;
	if (*pgdir & PTE_PS)
f0100bba:	f6 c1 80             	test   $0x80,%cl
f0100bbd:	74 11                	je     f0100bd0 <check_va2pa+0x2f>
		return (physaddr_t) PGADDR(PDX(*pgdir), PTX(va), PGOFF(va));
f0100bbf:	89 d8                	mov    %ebx,%eax
f0100bc1:	25 ff ff 3f 00       	and    $0x3fffff,%eax
f0100bc6:	81 e1 00 00 c0 ff    	and    $0xffc00000,%ecx
f0100bcc:	09 c8                	or     %ecx,%eax
f0100bce:	eb 37                	jmp    f0100c07 <check_va2pa+0x66>
	p = (pte_t*) KADDR(PTE_ADDR(*pgdir));
f0100bd0:	81 e1 00 f0 ff ff    	and    $0xfffff000,%ecx
f0100bd6:	ba 1b 03 00 00       	mov    $0x31b,%edx
f0100bdb:	b8 9b 58 10 f0       	mov    $0xf010589b,%eax
f0100be0:	e8 66 ff ff ff       	call   f0100b4b <_kaddr>
	if (!(p[PTX(va)] & PTE_P))
f0100be5:	c1 eb 0c             	shr    $0xc,%ebx
f0100be8:	81 e3 ff 03 00 00    	and    $0x3ff,%ebx
f0100bee:	8b 04 98             	mov    (%eax,%ebx,4),%eax
f0100bf1:	89 c2                	mov    %eax,%edx
f0100bf3:	83 e2 01             	and    $0x1,%edx
		return ~0;
	return PTE_ADDR(p[PTX(va)]);
f0100bf6:	25 00 f0 ff ff       	and    $0xfffff000,%eax
f0100bfb:	85 d2                	test   %edx,%edx
f0100bfd:	ba ff ff ff ff       	mov    $0xffffffff,%edx
f0100c02:	0f 44 c2             	cmove  %edx,%eax
f0100c05:	eb 00                	jmp    f0100c07 <check_va2pa+0x66>
}
f0100c07:	83 c4 04             	add    $0x4,%esp
f0100c0a:	5b                   	pop    %ebx
f0100c0b:	5d                   	pop    %ebp
f0100c0c:	c3                   	ret    

f0100c0d <_paddr>:
#define PADDR(kva) _paddr(__FILE__, __LINE__, kva)

static inline physaddr_t
_paddr(const char *file, int line, void *kva)
{
	if ((uint32_t)kva < KERNBASE)
f0100c0d:	81 f9 ff ff ff ef    	cmp    $0xefffffff,%ecx
f0100c13:	77 1e                	ja     f0100c33 <_paddr+0x26>
 */
#define PADDR(kva) _paddr(__FILE__, __LINE__, kva)

static inline physaddr_t
_paddr(const char *file, int line, void *kva)
{
f0100c15:	55                   	push   %ebp
f0100c16:	89 e5                	mov    %esp,%ebp
f0100c18:	83 ec 18             	sub    $0x18,%esp
	if ((uint32_t)kva < KERNBASE)
		_panic(file, line, "PADDR called with invalid kva %08lx", kva);
f0100c1b:	89 4c 24 0c          	mov    %ecx,0xc(%esp)
f0100c1f:	c7 44 24 08 04 51 10 	movl   $0xf0105104,0x8(%esp)
f0100c26:	f0 
f0100c27:	89 54 24 04          	mov    %edx,0x4(%esp)
f0100c2b:	89 04 24             	mov    %eax,(%esp)
f0100c2e:	e8 76 f4 ff ff       	call   f01000a9 <_panic>
	return (physaddr_t)kva - KERNBASE;
f0100c33:	8d 81 00 00 00 10    	lea    0x10000000(%ecx),%eax
}
f0100c39:	c3                   	ret    

f0100c3a <boot_alloc>:
	// Initialize nextfree if this is the first time.
	// 'end' is a magic symbol automatically generated by the linker,
	// which points to the end of the kernel's bss segment:
	// the first virtual address that the linker did *not* assign
	// to any kernel code or global variables.
	if (!nextfree) {
f0100c3a:	83 3d b8 52 18 f0 00 	cmpl   $0x0,0xf01852b8
f0100c41:	75 11                	jne    f0100c54 <boot_alloc+0x1a>
		extern char end[];
		nextfree = ROUNDUP((char *) end, PGSIZE);
f0100c43:	ba 8f 7f 18 f0       	mov    $0xf0187f8f,%edx
f0100c48:	81 e2 00 f0 ff ff    	and    $0xfffff000,%edx
f0100c4e:	89 15 b8 52 18 f0    	mov    %edx,0xf01852b8
	// Allocate a chunk large enough to hold 'n' bytes, then update
	// nextfree.  Make sure nextfree is kept aligned
	// to a multiple of PGSIZE.
	//
	// LAB 2: Your code here.
	if (n==0) return nextfree;
f0100c54:	85 c0                	test   %eax,%eax
f0100c56:	75 06                	jne    f0100c5e <boot_alloc+0x24>
f0100c58:	a1 b8 52 18 f0       	mov    0xf01852b8,%eax
	//n>0 (n<0 no deberia ocurrir por precond)
	result = nextfree;
	nextfree += ROUNDUP(n,PGSIZE);
	if (PADDR(nextfree)>npages*PGSIZE) panic("not enough memory\n");
	return (void*) result;
}
f0100c5d:	c3                   	ret    
// If we're out of memory, boot_alloc should panic.
// This function may ONLY be used during initialization,
// before the page_free_list list has been set up.
static void *
boot_alloc(uint32_t n)
{
f0100c5e:	55                   	push   %ebp
f0100c5f:	89 e5                	mov    %esp,%ebp
f0100c61:	53                   	push   %ebx
f0100c62:	83 ec 14             	sub    $0x14,%esp
	// to a multiple of PGSIZE.
	//
	// LAB 2: Your code here.
	if (n==0) return nextfree;
	//n>0 (n<0 no deberia ocurrir por precond)
	result = nextfree;
f0100c65:	8b 1d b8 52 18 f0    	mov    0xf01852b8,%ebx
	nextfree += ROUNDUP(n,PGSIZE);
f0100c6b:	8d 88 ff 0f 00 00    	lea    0xfff(%eax),%ecx
f0100c71:	81 e1 00 f0 ff ff    	and    $0xfffff000,%ecx
f0100c77:	01 d9                	add    %ebx,%ecx
f0100c79:	89 0d b8 52 18 f0    	mov    %ecx,0xf01852b8
	if (PADDR(nextfree)>npages*PGSIZE) panic("not enough memory\n");
f0100c7f:	ba 6e 00 00 00       	mov    $0x6e,%edx
f0100c84:	b8 9b 58 10 f0       	mov    $0xf010589b,%eax
f0100c89:	e8 7f ff ff ff       	call   f0100c0d <_paddr>
f0100c8e:	8b 15 84 6f 18 f0    	mov    0xf0186f84,%edx
f0100c94:	c1 e2 0c             	shl    $0xc,%edx
f0100c97:	39 d0                	cmp    %edx,%eax
f0100c99:	76 1c                	jbe    f0100cb7 <boot_alloc+0x7d>
f0100c9b:	c7 44 24 08 a7 58 10 	movl   $0xf01058a7,0x8(%esp)
f0100ca2:	f0 
f0100ca3:	c7 44 24 04 6e 00 00 	movl   $0x6e,0x4(%esp)
f0100caa:	00 
f0100cab:	c7 04 24 9b 58 10 f0 	movl   $0xf010589b,(%esp)
f0100cb2:	e8 f2 f3 ff ff       	call   f01000a9 <_panic>
	return (void*) result;
f0100cb7:	89 d8                	mov    %ebx,%eax
}
f0100cb9:	83 c4 14             	add    $0x14,%esp
f0100cbc:	5b                   	pop    %ebx
f0100cbd:	5d                   	pop    %ebp
f0100cbe:	c3                   	ret    

f0100cbf <check_kern_pgdir>:
// but it is a pretty good sanity check.
//

static void
check_kern_pgdir(void)
{
f0100cbf:	55                   	push   %ebp
f0100cc0:	89 e5                	mov    %esp,%ebp
f0100cc2:	57                   	push   %edi
f0100cc3:	56                   	push   %esi
f0100cc4:	53                   	push   %ebx
f0100cc5:	83 ec 2c             	sub    $0x2c,%esp
	uint32_t i, n;
	pde_t *pgdir;

	pgdir = kern_pgdir;
f0100cc8:	8b 1d 88 6f 18 f0    	mov    0xf0186f88,%ebx

	// check pages array
	n = ROUNDUP(npages*sizeof(struct PageInfo), PGSIZE);
f0100cce:	a1 84 6f 18 f0       	mov    0xf0186f84,%eax
f0100cd3:	89 45 dc             	mov    %eax,-0x24(%ebp)
f0100cd6:	8d 04 c5 ff 0f 00 00 	lea    0xfff(,%eax,8),%eax
f0100cdd:	25 00 f0 ff ff       	and    $0xfffff000,%eax
f0100ce2:	89 45 e4             	mov    %eax,-0x1c(%ebp)
	for (i = 0; i < n; i += PGSIZE)
		assert(check_va2pa(pgdir, UPAGES + i) == PADDR(pages) + i);
f0100ce5:	a1 8c 6f 18 f0       	mov    0xf0186f8c,%eax
f0100cea:	89 45 e0             	mov    %eax,-0x20(%ebp)

	pgdir = kern_pgdir;

	// check pages array
	n = ROUNDUP(npages*sizeof(struct PageInfo), PGSIZE);
	for (i = 0; i < n; i += PGSIZE)
f0100ced:	be 00 00 00 00       	mov    $0x0,%esi
f0100cf2:	eb 51                	jmp    f0100d45 <check_kern_pgdir+0x86>
f0100cf4:	8d 96 00 00 00 ef    	lea    -0x11000000(%esi),%edx
		assert(check_va2pa(pgdir, UPAGES + i) == PADDR(pages) + i);
f0100cfa:	89 d8                	mov    %ebx,%eax
f0100cfc:	e8 a0 fe ff ff       	call   f0100ba1 <check_va2pa>
f0100d01:	89 c7                	mov    %eax,%edi
f0100d03:	8b 4d e0             	mov    -0x20(%ebp),%ecx
f0100d06:	ba dd 02 00 00       	mov    $0x2dd,%edx
f0100d0b:	b8 9b 58 10 f0       	mov    $0xf010589b,%eax
f0100d10:	e8 f8 fe ff ff       	call   f0100c0d <_paddr>
f0100d15:	01 f0                	add    %esi,%eax
f0100d17:	39 c7                	cmp    %eax,%edi
f0100d19:	74 24                	je     f0100d3f <check_kern_pgdir+0x80>
f0100d1b:	c7 44 24 0c 28 51 10 	movl   $0xf0105128,0xc(%esp)
f0100d22:	f0 
f0100d23:	c7 44 24 08 ba 58 10 	movl   $0xf01058ba,0x8(%esp)
f0100d2a:	f0 
f0100d2b:	c7 44 24 04 dd 02 00 	movl   $0x2dd,0x4(%esp)
f0100d32:	00 
f0100d33:	c7 04 24 9b 58 10 f0 	movl   $0xf010589b,(%esp)
f0100d3a:	e8 6a f3 ff ff       	call   f01000a9 <_panic>

	pgdir = kern_pgdir;

	// check pages array
	n = ROUNDUP(npages*sizeof(struct PageInfo), PGSIZE);
	for (i = 0; i < n; i += PGSIZE)
f0100d3f:	81 c6 00 10 00 00    	add    $0x1000,%esi
f0100d45:	3b 75 e4             	cmp    -0x1c(%ebp),%esi
f0100d48:	72 aa                	jb     f0100cf4 <check_kern_pgdir+0x35>
		assert(check_va2pa(pgdir, UPAGES + i) == PADDR(pages) + i);

	// check envs array (new test for lab 3)
	n = ROUNDUP(NENV*sizeof(struct Env), PGSIZE);
	for (i = 0; i < n; i += PGSIZE)
		assert(check_va2pa(pgdir, UENVS + i) == PADDR(envs) + i);
f0100d4a:	a1 c8 52 18 f0       	mov    0xf01852c8,%eax
f0100d4f:	89 45 e4             	mov    %eax,-0x1c(%ebp)
f0100d52:	be 00 00 00 00       	mov    $0x0,%esi
f0100d57:	8d 96 00 00 c0 ee    	lea    -0x11400000(%esi),%edx
f0100d5d:	89 d8                	mov    %ebx,%eax
f0100d5f:	e8 3d fe ff ff       	call   f0100ba1 <check_va2pa>
f0100d64:	89 c7                	mov    %eax,%edi
f0100d66:	8b 4d e4             	mov    -0x1c(%ebp),%ecx
f0100d69:	ba e2 02 00 00       	mov    $0x2e2,%edx
f0100d6e:	b8 9b 58 10 f0       	mov    $0xf010589b,%eax
f0100d73:	e8 95 fe ff ff       	call   f0100c0d <_paddr>
f0100d78:	01 f0                	add    %esi,%eax
f0100d7a:	39 c7                	cmp    %eax,%edi
f0100d7c:	74 24                	je     f0100da2 <check_kern_pgdir+0xe3>
f0100d7e:	c7 44 24 0c 5c 51 10 	movl   $0xf010515c,0xc(%esp)
f0100d85:	f0 
f0100d86:	c7 44 24 08 ba 58 10 	movl   $0xf01058ba,0x8(%esp)
f0100d8d:	f0 
f0100d8e:	c7 44 24 04 e2 02 00 	movl   $0x2e2,0x4(%esp)
f0100d95:	00 
f0100d96:	c7 04 24 9b 58 10 f0 	movl   $0xf010589b,(%esp)
f0100d9d:	e8 07 f3 ff ff       	call   f01000a9 <_panic>
	for (i = 0; i < n; i += PGSIZE)
		assert(check_va2pa(pgdir, UPAGES + i) == PADDR(pages) + i);

	// check envs array (new test for lab 3)
	n = ROUNDUP(NENV*sizeof(struct Env), PGSIZE);
	for (i = 0; i < n; i += PGSIZE)
f0100da2:	81 c6 00 10 00 00    	add    $0x1000,%esi
f0100da8:	81 fe 00 80 01 00    	cmp    $0x18000,%esi
f0100dae:	75 a7                	jne    f0100d57 <check_kern_pgdir+0x98>
		assert(check_va2pa(pgdir, UENVS + i) == PADDR(envs) + i);

	// check phys mem
	for (i = 0; i < npages * PGSIZE; i += PGSIZE)
f0100db0:	8b 7d dc             	mov    -0x24(%ebp),%edi
f0100db3:	c1 e7 0c             	shl    $0xc,%edi
f0100db6:	be 00 00 00 00       	mov    $0x0,%esi
f0100dbb:	eb 3b                	jmp    f0100df8 <check_kern_pgdir+0x139>
f0100dbd:	8d 96 00 00 00 f0    	lea    -0x10000000(%esi),%edx
		assert(check_va2pa(pgdir, KERNBASE + i) == i);
f0100dc3:	89 d8                	mov    %ebx,%eax
f0100dc5:	e8 d7 fd ff ff       	call   f0100ba1 <check_va2pa>
f0100dca:	39 f0                	cmp    %esi,%eax
f0100dcc:	74 24                	je     f0100df2 <check_kern_pgdir+0x133>
f0100dce:	c7 44 24 0c 90 51 10 	movl   $0xf0105190,0xc(%esp)
f0100dd5:	f0 
f0100dd6:	c7 44 24 08 ba 58 10 	movl   $0xf01058ba,0x8(%esp)
f0100ddd:	f0 
f0100dde:	c7 44 24 04 e6 02 00 	movl   $0x2e6,0x4(%esp)
f0100de5:	00 
f0100de6:	c7 04 24 9b 58 10 f0 	movl   $0xf010589b,(%esp)
f0100ded:	e8 b7 f2 ff ff       	call   f01000a9 <_panic>
	n = ROUNDUP(NENV*sizeof(struct Env), PGSIZE);
	for (i = 0; i < n; i += PGSIZE)
		assert(check_va2pa(pgdir, UENVS + i) == PADDR(envs) + i);

	// check phys mem
	for (i = 0; i < npages * PGSIZE; i += PGSIZE)
f0100df2:	81 c6 00 10 00 00    	add    $0x1000,%esi
f0100df8:	39 fe                	cmp    %edi,%esi
f0100dfa:	72 c1                	jb     f0100dbd <check_kern_pgdir+0xfe>
f0100dfc:	be 00 00 00 00       	mov    $0x0,%esi
f0100e01:	8d 96 00 80 ff ef    	lea    -0x10008000(%esi),%edx
		assert(check_va2pa(pgdir, KERNBASE + i) == i);

	// check kernel stack
	for (i = 0; i < KSTKSIZE; i += PGSIZE)
		assert(check_va2pa(pgdir, KSTACKTOP - KSTKSIZE + i) == PADDR(bootstack) + i);
f0100e07:	89 d8                	mov    %ebx,%eax
f0100e09:	e8 93 fd ff ff       	call   f0100ba1 <check_va2pa>
f0100e0e:	89 c7                	mov    %eax,%edi
f0100e10:	b9 00 20 11 f0       	mov    $0xf0112000,%ecx
f0100e15:	ba ea 02 00 00       	mov    $0x2ea,%edx
f0100e1a:	b8 9b 58 10 f0       	mov    $0xf010589b,%eax
f0100e1f:	e8 e9 fd ff ff       	call   f0100c0d <_paddr>
f0100e24:	01 f0                	add    %esi,%eax
f0100e26:	39 c7                	cmp    %eax,%edi
f0100e28:	74 24                	je     f0100e4e <check_kern_pgdir+0x18f>
f0100e2a:	c7 44 24 0c b8 51 10 	movl   $0xf01051b8,0xc(%esp)
f0100e31:	f0 
f0100e32:	c7 44 24 08 ba 58 10 	movl   $0xf01058ba,0x8(%esp)
f0100e39:	f0 
f0100e3a:	c7 44 24 04 ea 02 00 	movl   $0x2ea,0x4(%esp)
f0100e41:	00 
f0100e42:	c7 04 24 9b 58 10 f0 	movl   $0xf010589b,(%esp)
f0100e49:	e8 5b f2 ff ff       	call   f01000a9 <_panic>
	// check phys mem
	for (i = 0; i < npages * PGSIZE; i += PGSIZE)
		assert(check_va2pa(pgdir, KERNBASE + i) == i);

	// check kernel stack
	for (i = 0; i < KSTKSIZE; i += PGSIZE)
f0100e4e:	81 c6 00 10 00 00    	add    $0x1000,%esi
f0100e54:	81 fe 00 80 00 00    	cmp    $0x8000,%esi
f0100e5a:	75 a5                	jne    f0100e01 <check_kern_pgdir+0x142>
		assert(check_va2pa(pgdir, KSTACKTOP - KSTKSIZE + i) == PADDR(bootstack) + i);
	assert(check_va2pa(pgdir, KSTACKTOP - PTSIZE) == ~0);
f0100e5c:	ba 00 00 c0 ef       	mov    $0xefc00000,%edx
f0100e61:	89 d8                	mov    %ebx,%eax
f0100e63:	e8 39 fd ff ff       	call   f0100ba1 <check_va2pa>
f0100e68:	83 f8 ff             	cmp    $0xffffffff,%eax
f0100e6b:	75 0a                	jne    f0100e77 <check_kern_pgdir+0x1b8>
f0100e6d:	b8 00 00 00 00       	mov    $0x0,%eax
f0100e72:	e9 f0 00 00 00       	jmp    f0100f67 <check_kern_pgdir+0x2a8>
f0100e77:	c7 44 24 0c 00 52 10 	movl   $0xf0105200,0xc(%esp)
f0100e7e:	f0 
f0100e7f:	c7 44 24 08 ba 58 10 	movl   $0xf01058ba,0x8(%esp)
f0100e86:	f0 
f0100e87:	c7 44 24 04 eb 02 00 	movl   $0x2eb,0x4(%esp)
f0100e8e:	00 
f0100e8f:	c7 04 24 9b 58 10 f0 	movl   $0xf010589b,(%esp)
f0100e96:	e8 0e f2 ff ff       	call   f01000a9 <_panic>

	// check PDE permissions
	for (i = 0; i < NPDENTRIES; i++) {
		switch (i) {
f0100e9b:	3d bb 03 00 00       	cmp    $0x3bb,%eax
f0100ea0:	72 3c                	jb     f0100ede <check_kern_pgdir+0x21f>
f0100ea2:	3d bd 03 00 00       	cmp    $0x3bd,%eax
f0100ea7:	76 07                	jbe    f0100eb0 <check_kern_pgdir+0x1f1>
f0100ea9:	3d bf 03 00 00       	cmp    $0x3bf,%eax
f0100eae:	75 2e                	jne    f0100ede <check_kern_pgdir+0x21f>
		case PDX(UVPT):
		case PDX(KSTACKTOP-1):
		case PDX(UPAGES):
		case PDX(UENVS):
			assert(pgdir[i] & PTE_P);
f0100eb0:	f6 04 83 01          	testb  $0x1,(%ebx,%eax,4)
f0100eb4:	0f 85 aa 00 00 00    	jne    f0100f64 <check_kern_pgdir+0x2a5>
f0100eba:	c7 44 24 0c cf 58 10 	movl   $0xf01058cf,0xc(%esp)
f0100ec1:	f0 
f0100ec2:	c7 44 24 08 ba 58 10 	movl   $0xf01058ba,0x8(%esp)
f0100ec9:	f0 
f0100eca:	c7 44 24 04 f4 02 00 	movl   $0x2f4,0x4(%esp)
f0100ed1:	00 
f0100ed2:	c7 04 24 9b 58 10 f0 	movl   $0xf010589b,(%esp)
f0100ed9:	e8 cb f1 ff ff       	call   f01000a9 <_panic>
			break;
		default:
			if (i >= PDX(KERNBASE)) {
f0100ede:	3d bf 03 00 00       	cmp    $0x3bf,%eax
f0100ee3:	76 55                	jbe    f0100f3a <check_kern_pgdir+0x27b>
				assert(pgdir[i] & PTE_P);
f0100ee5:	8b 14 83             	mov    (%ebx,%eax,4),%edx
f0100ee8:	f6 c2 01             	test   $0x1,%dl
f0100eeb:	75 24                	jne    f0100f11 <check_kern_pgdir+0x252>
f0100eed:	c7 44 24 0c cf 58 10 	movl   $0xf01058cf,0xc(%esp)
f0100ef4:	f0 
f0100ef5:	c7 44 24 08 ba 58 10 	movl   $0xf01058ba,0x8(%esp)
f0100efc:	f0 
f0100efd:	c7 44 24 04 f8 02 00 	movl   $0x2f8,0x4(%esp)
f0100f04:	00 
f0100f05:	c7 04 24 9b 58 10 f0 	movl   $0xf010589b,(%esp)
f0100f0c:	e8 98 f1 ff ff       	call   f01000a9 <_panic>
				assert(pgdir[i] & PTE_W);
f0100f11:	f6 c2 02             	test   $0x2,%dl
f0100f14:	75 4e                	jne    f0100f64 <check_kern_pgdir+0x2a5>
f0100f16:	c7 44 24 0c e0 58 10 	movl   $0xf01058e0,0xc(%esp)
f0100f1d:	f0 
f0100f1e:	c7 44 24 08 ba 58 10 	movl   $0xf01058ba,0x8(%esp)
f0100f25:	f0 
f0100f26:	c7 44 24 04 f9 02 00 	movl   $0x2f9,0x4(%esp)
f0100f2d:	00 
f0100f2e:	c7 04 24 9b 58 10 f0 	movl   $0xf010589b,(%esp)
f0100f35:	e8 6f f1 ff ff       	call   f01000a9 <_panic>
			} else
				assert(pgdir[i] == 0);
f0100f3a:	83 3c 83 00          	cmpl   $0x0,(%ebx,%eax,4)
f0100f3e:	74 24                	je     f0100f64 <check_kern_pgdir+0x2a5>
f0100f40:	c7 44 24 0c f1 58 10 	movl   $0xf01058f1,0xc(%esp)
f0100f47:	f0 
f0100f48:	c7 44 24 08 ba 58 10 	movl   $0xf01058ba,0x8(%esp)
f0100f4f:	f0 
f0100f50:	c7 44 24 04 fb 02 00 	movl   $0x2fb,0x4(%esp)
f0100f57:	00 
f0100f58:	c7 04 24 9b 58 10 f0 	movl   $0xf010589b,(%esp)
f0100f5f:	e8 45 f1 ff ff       	call   f01000a9 <_panic>
	for (i = 0; i < KSTKSIZE; i += PGSIZE)
		assert(check_va2pa(pgdir, KSTACKTOP - KSTKSIZE + i) == PADDR(bootstack) + i);
	assert(check_va2pa(pgdir, KSTACKTOP - PTSIZE) == ~0);

	// check PDE permissions
	for (i = 0; i < NPDENTRIES; i++) {
f0100f64:	83 c0 01             	add    $0x1,%eax
f0100f67:	3d 00 04 00 00       	cmp    $0x400,%eax
f0100f6c:	0f 85 29 ff ff ff    	jne    f0100e9b <check_kern_pgdir+0x1dc>
			} else
				assert(pgdir[i] == 0);
			break;
		}
	}
	cprintf("check_kern_pgdir() succeeded!\n");
f0100f72:	c7 04 24 30 52 10 f0 	movl   $0xf0105230,(%esp)
f0100f79:	e8 80 27 00 00       	call   f01036fe <cprintf>
			assert(PTE_ADDR(pgdir[i]) == (i - kern_pdx) << PDXSHIFT);
		}
		cprintf("check_kern_pgdir_pse() succeeded!\n");
	#endif

}
f0100f7e:	83 c4 2c             	add    $0x2c,%esp
f0100f81:	5b                   	pop    %ebx
f0100f82:	5e                   	pop    %esi
f0100f83:	5f                   	pop    %edi
f0100f84:	5d                   	pop    %ebp
f0100f85:	c3                   	ret    

f0100f86 <check_page_free_list>:
//
// Check that the pages on the page_free_list are reasonable.
//
static void
check_page_free_list(bool only_low_memory)
{
f0100f86:	55                   	push   %ebp
f0100f87:	89 e5                	mov    %esp,%ebp
f0100f89:	57                   	push   %edi
f0100f8a:	56                   	push   %esi
f0100f8b:	53                   	push   %ebx
f0100f8c:	83 ec 3c             	sub    $0x3c,%esp
	struct PageInfo *pp;
	unsigned pdx_limit = only_low_memory ? 1 : NPDENTRIES;
f0100f8f:	84 c0                	test   %al,%al
f0100f91:	0f 85 aa 02 00 00    	jne    f0101241 <check_page_free_list+0x2bb>
f0100f97:	e9 b8 02 00 00       	jmp    f0101254 <check_page_free_list+0x2ce>
	int nfree_basemem = 0, nfree_extmem = 0;
	char *first_free_page;

	if (!page_free_list)
		panic("'page_free_list' is a null pointer!");
f0100f9c:	c7 44 24 08 50 52 10 	movl   $0xf0105250,0x8(%esp)
f0100fa3:	f0 
f0100fa4:	c7 44 24 04 4d 02 00 	movl   $0x24d,0x4(%esp)
f0100fab:	00 
f0100fac:	c7 04 24 9b 58 10 f0 	movl   $0xf010589b,(%esp)
f0100fb3:	e8 f1 f0 ff ff       	call   f01000a9 <_panic>

	if (only_low_memory) {
		// Move pages with lower addresses first in the free
		// list, since entry_pgdir does not map all pages.
		struct PageInfo *pp1, *pp2;
		struct PageInfo **tp[2] = { &pp1, &pp2 };
f0100fb8:	8d 45 d8             	lea    -0x28(%ebp),%eax
f0100fbb:	89 45 e0             	mov    %eax,-0x20(%ebp)
f0100fbe:	8d 45 dc             	lea    -0x24(%ebp),%eax
f0100fc1:	89 45 e4             	mov    %eax,-0x1c(%ebp)
		for (pp = page_free_list; pp; pp = pp->pp_link) {
			int pagetype = PDX(page2pa(pp)) >= pdx_limit;
f0100fc4:	89 d8                	mov    %ebx,%eax
f0100fc6:	e8 c8 fa ff ff       	call   f0100a93 <page2pa>
f0100fcb:	c1 e8 16             	shr    $0x16,%eax
f0100fce:	85 c0                	test   %eax,%eax
f0100fd0:	0f 95 c0             	setne  %al
f0100fd3:	0f b6 c0             	movzbl %al,%eax
			*tp[pagetype] = pp;
f0100fd6:	8b 54 85 e0          	mov    -0x20(%ebp,%eax,4),%edx
f0100fda:	89 1a                	mov    %ebx,(%edx)
			tp[pagetype] = &pp->pp_link;
f0100fdc:	89 5c 85 e0          	mov    %ebx,-0x20(%ebp,%eax,4)
	if (only_low_memory) {
		// Move pages with lower addresses first in the free
		// list, since entry_pgdir does not map all pages.
		struct PageInfo *pp1, *pp2;
		struct PageInfo **tp[2] = { &pp1, &pp2 };
		for (pp = page_free_list; pp; pp = pp->pp_link) {
f0100fe0:	8b 1b                	mov    (%ebx),%ebx
f0100fe2:	85 db                	test   %ebx,%ebx
f0100fe4:	75 de                	jne    f0100fc4 <check_page_free_list+0x3e>
			int pagetype = PDX(page2pa(pp)) >= pdx_limit;
			*tp[pagetype] = pp;
			tp[pagetype] = &pp->pp_link;
		}
		*tp[1] = 0;
f0100fe6:	8b 45 e4             	mov    -0x1c(%ebp),%eax
f0100fe9:	c7 00 00 00 00 00    	movl   $0x0,(%eax)
		*tp[0] = pp2;
f0100fef:	8b 45 e0             	mov    -0x20(%ebp),%eax
f0100ff2:	8b 55 dc             	mov    -0x24(%ebp),%edx
f0100ff5:	89 10                	mov    %edx,(%eax)
		page_free_list = pp1;
f0100ff7:	8b 45 d8             	mov    -0x28(%ebp),%eax
f0100ffa:	a3 bc 52 18 f0       	mov    %eax,0xf01852bc
//
static void
check_page_free_list(bool only_low_memory)
{
	struct PageInfo *pp;
	unsigned pdx_limit = only_low_memory ? 1 : NPDENTRIES;
f0100fff:	be 01 00 00 00       	mov    $0x1,%esi
		page_free_list = pp1;
	}

	// if there's a page that shouldn't be on the free list,
	// try to make sure it eventually causes trouble.
	for (pp = page_free_list; pp; pp = pp->pp_link)
f0101004:	8b 1d bc 52 18 f0    	mov    0xf01852bc,%ebx
f010100a:	eb 2f                	jmp    f010103b <check_page_free_list+0xb5>
		if (PDX(page2pa(pp)) < pdx_limit)
f010100c:	89 d8                	mov    %ebx,%eax
f010100e:	e8 80 fa ff ff       	call   f0100a93 <page2pa>
f0101013:	c1 e8 16             	shr    $0x16,%eax
f0101016:	39 f0                	cmp    %esi,%eax
f0101018:	73 1f                	jae    f0101039 <check_page_free_list+0xb3>
			memset(page2kva(pp), 0x97, 128);
f010101a:	89 d8                	mov    %ebx,%eax
f010101c:	e8 62 fb ff ff       	call   f0100b83 <page2kva>
f0101021:	c7 44 24 08 80 00 00 	movl   $0x80,0x8(%esp)
f0101028:	00 
f0101029:	c7 44 24 04 97 00 00 	movl   $0x97,0x4(%esp)
f0101030:	00 
f0101031:	89 04 24             	mov    %eax,(%esp)
f0101034:	e8 8e 36 00 00       	call   f01046c7 <memset>
		page_free_list = pp1;
	}

	// if there's a page that shouldn't be on the free list,
	// try to make sure it eventually causes trouble.
	for (pp = page_free_list; pp; pp = pp->pp_link)
f0101039:	8b 1b                	mov    (%ebx),%ebx
f010103b:	85 db                	test   %ebx,%ebx
f010103d:	75 cd                	jne    f010100c <check_page_free_list+0x86>
		if (PDX(page2pa(pp)) < pdx_limit)
			memset(page2kva(pp), 0x97, 128);

	first_free_page = (char *) boot_alloc(0);
f010103f:	b8 00 00 00 00       	mov    $0x0,%eax
f0101044:	e8 f1 fb ff ff       	call   f0100c3a <boot_alloc>
f0101049:	89 45 c8             	mov    %eax,-0x38(%ebp)
	for (pp = page_free_list; pp; pp = pp->pp_link) {
f010104c:	8b 1d bc 52 18 f0    	mov    0xf01852bc,%ebx
		// check that we didn't corrupt the free list itself
		assert(pp >= pages);
f0101052:	8b 35 8c 6f 18 f0    	mov    0xf0186f8c,%esi
		assert(pp < pages + npages);
f0101058:	a1 84 6f 18 f0       	mov    0xf0186f84,%eax
f010105d:	8d 04 c6             	lea    (%esi,%eax,8),%eax
f0101060:	89 45 d4             	mov    %eax,-0x2c(%ebp)
		assert(((char *) pp - (char *) pages) % sizeof(*pp) == 0);
f0101063:	89 75 d0             	mov    %esi,-0x30(%ebp)
static void
check_page_free_list(bool only_low_memory)
{
	struct PageInfo *pp;
	unsigned pdx_limit = only_low_memory ? 1 : NPDENTRIES;
	int nfree_basemem = 0, nfree_extmem = 0;
f0101066:	c7 45 cc 00 00 00 00 	movl   $0x0,-0x34(%ebp)
f010106d:	bf 00 00 00 00       	mov    $0x0,%edi
	for (pp = page_free_list; pp; pp = pp->pp_link)
		if (PDX(page2pa(pp)) < pdx_limit)
			memset(page2kva(pp), 0x97, 128);

	first_free_page = (char *) boot_alloc(0);
	for (pp = page_free_list; pp; pp = pp->pp_link) {
f0101072:	e9 70 01 00 00       	jmp    f01011e7 <check_page_free_list+0x261>
		// check that we didn't corrupt the free list itself
		assert(pp >= pages);
f0101077:	39 f3                	cmp    %esi,%ebx
f0101079:	73 24                	jae    f010109f <check_page_free_list+0x119>
f010107b:	c7 44 24 0c ff 58 10 	movl   $0xf01058ff,0xc(%esp)
f0101082:	f0 
f0101083:	c7 44 24 08 ba 58 10 	movl   $0xf01058ba,0x8(%esp)
f010108a:	f0 
f010108b:	c7 44 24 04 67 02 00 	movl   $0x267,0x4(%esp)
f0101092:	00 
f0101093:	c7 04 24 9b 58 10 f0 	movl   $0xf010589b,(%esp)
f010109a:	e8 0a f0 ff ff       	call   f01000a9 <_panic>
		assert(pp < pages + npages);
f010109f:	3b 5d d4             	cmp    -0x2c(%ebp),%ebx
f01010a2:	72 24                	jb     f01010c8 <check_page_free_list+0x142>
f01010a4:	c7 44 24 0c 0b 59 10 	movl   $0xf010590b,0xc(%esp)
f01010ab:	f0 
f01010ac:	c7 44 24 08 ba 58 10 	movl   $0xf01058ba,0x8(%esp)
f01010b3:	f0 
f01010b4:	c7 44 24 04 68 02 00 	movl   $0x268,0x4(%esp)
f01010bb:	00 
f01010bc:	c7 04 24 9b 58 10 f0 	movl   $0xf010589b,(%esp)
f01010c3:	e8 e1 ef ff ff       	call   f01000a9 <_panic>
		assert(((char *) pp - (char *) pages) % sizeof(*pp) == 0);
f01010c8:	89 d8                	mov    %ebx,%eax
f01010ca:	2b 45 d0             	sub    -0x30(%ebp),%eax
f01010cd:	a8 07                	test   $0x7,%al
f01010cf:	74 24                	je     f01010f5 <check_page_free_list+0x16f>
f01010d1:	c7 44 24 0c 74 52 10 	movl   $0xf0105274,0xc(%esp)
f01010d8:	f0 
f01010d9:	c7 44 24 08 ba 58 10 	movl   $0xf01058ba,0x8(%esp)
f01010e0:	f0 
f01010e1:	c7 44 24 04 69 02 00 	movl   $0x269,0x4(%esp)
f01010e8:	00 
f01010e9:	c7 04 24 9b 58 10 f0 	movl   $0xf010589b,(%esp)
f01010f0:	e8 b4 ef ff ff       	call   f01000a9 <_panic>

		// check a few pages that shouldn't be on the free list
		assert(page2pa(pp) != 0);
f01010f5:	89 d8                	mov    %ebx,%eax
f01010f7:	e8 97 f9 ff ff       	call   f0100a93 <page2pa>
f01010fc:	85 c0                	test   %eax,%eax
f01010fe:	75 24                	jne    f0101124 <check_page_free_list+0x19e>
f0101100:	c7 44 24 0c 1f 59 10 	movl   $0xf010591f,0xc(%esp)
f0101107:	f0 
f0101108:	c7 44 24 08 ba 58 10 	movl   $0xf01058ba,0x8(%esp)
f010110f:	f0 
f0101110:	c7 44 24 04 6c 02 00 	movl   $0x26c,0x4(%esp)
f0101117:	00 
f0101118:	c7 04 24 9b 58 10 f0 	movl   $0xf010589b,(%esp)
f010111f:	e8 85 ef ff ff       	call   f01000a9 <_panic>
		assert(page2pa(pp) != IOPHYSMEM);
f0101124:	3d 00 00 0a 00       	cmp    $0xa0000,%eax
f0101129:	75 24                	jne    f010114f <check_page_free_list+0x1c9>
f010112b:	c7 44 24 0c 30 59 10 	movl   $0xf0105930,0xc(%esp)
f0101132:	f0 
f0101133:	c7 44 24 08 ba 58 10 	movl   $0xf01058ba,0x8(%esp)
f010113a:	f0 
f010113b:	c7 44 24 04 6d 02 00 	movl   $0x26d,0x4(%esp)
f0101142:	00 
f0101143:	c7 04 24 9b 58 10 f0 	movl   $0xf010589b,(%esp)
f010114a:	e8 5a ef ff ff       	call   f01000a9 <_panic>
		assert(page2pa(pp) != EXTPHYSMEM - PGSIZE);
f010114f:	3d 00 f0 0f 00       	cmp    $0xff000,%eax
f0101154:	75 24                	jne    f010117a <check_page_free_list+0x1f4>
f0101156:	c7 44 24 0c a8 52 10 	movl   $0xf01052a8,0xc(%esp)
f010115d:	f0 
f010115e:	c7 44 24 08 ba 58 10 	movl   $0xf01058ba,0x8(%esp)
f0101165:	f0 
f0101166:	c7 44 24 04 6e 02 00 	movl   $0x26e,0x4(%esp)
f010116d:	00 
f010116e:	c7 04 24 9b 58 10 f0 	movl   $0xf010589b,(%esp)
f0101175:	e8 2f ef ff ff       	call   f01000a9 <_panic>
		assert(page2pa(pp) != EXTPHYSMEM);
f010117a:	3d 00 00 10 00       	cmp    $0x100000,%eax
f010117f:	75 24                	jne    f01011a5 <check_page_free_list+0x21f>
f0101181:	c7 44 24 0c 49 59 10 	movl   $0xf0105949,0xc(%esp)
f0101188:	f0 
f0101189:	c7 44 24 08 ba 58 10 	movl   $0xf01058ba,0x8(%esp)
f0101190:	f0 
f0101191:	c7 44 24 04 6f 02 00 	movl   $0x26f,0x4(%esp)
f0101198:	00 
f0101199:	c7 04 24 9b 58 10 f0 	movl   $0xf010589b,(%esp)
f01011a0:	e8 04 ef ff ff       	call   f01000a9 <_panic>
		assert(page2pa(pp) < EXTPHYSMEM || (char *) page2kva(pp) >= first_free_page);
f01011a5:	3d ff ff 0f 00       	cmp    $0xfffff,%eax
f01011aa:	76 30                	jbe    f01011dc <check_page_free_list+0x256>
f01011ac:	89 d8                	mov    %ebx,%eax
f01011ae:	e8 d0 f9 ff ff       	call   f0100b83 <page2kva>
f01011b3:	39 45 c8             	cmp    %eax,-0x38(%ebp)
f01011b6:	76 29                	jbe    f01011e1 <check_page_free_list+0x25b>
f01011b8:	c7 44 24 0c cc 52 10 	movl   $0xf01052cc,0xc(%esp)
f01011bf:	f0 
f01011c0:	c7 44 24 08 ba 58 10 	movl   $0xf01058ba,0x8(%esp)
f01011c7:	f0 
f01011c8:	c7 44 24 04 70 02 00 	movl   $0x270,0x4(%esp)
f01011cf:	00 
f01011d0:	c7 04 24 9b 58 10 f0 	movl   $0xf010589b,(%esp)
f01011d7:	e8 cd ee ff ff       	call   f01000a9 <_panic>

		if (page2pa(pp) < EXTPHYSMEM)
			++nfree_basemem;
f01011dc:	83 c7 01             	add    $0x1,%edi
f01011df:	eb 04                	jmp    f01011e5 <check_page_free_list+0x25f>
		else
			++nfree_extmem;
f01011e1:	83 45 cc 01          	addl   $0x1,-0x34(%ebp)
	for (pp = page_free_list; pp; pp = pp->pp_link)
		if (PDX(page2pa(pp)) < pdx_limit)
			memset(page2kva(pp), 0x97, 128);

	first_free_page = (char *) boot_alloc(0);
	for (pp = page_free_list; pp; pp = pp->pp_link) {
f01011e5:	8b 1b                	mov    (%ebx),%ebx
f01011e7:	85 db                	test   %ebx,%ebx
f01011e9:	0f 85 88 fe ff ff    	jne    f0101077 <check_page_free_list+0xf1>
			++nfree_basemem;
		else
			++nfree_extmem;
	}

	assert(nfree_basemem > 0);
f01011ef:	85 ff                	test   %edi,%edi
f01011f1:	7f 24                	jg     f0101217 <check_page_free_list+0x291>
f01011f3:	c7 44 24 0c 63 59 10 	movl   $0xf0105963,0xc(%esp)
f01011fa:	f0 
f01011fb:	c7 44 24 08 ba 58 10 	movl   $0xf01058ba,0x8(%esp)
f0101202:	f0 
f0101203:	c7 44 24 04 78 02 00 	movl   $0x278,0x4(%esp)
f010120a:	00 
f010120b:	c7 04 24 9b 58 10 f0 	movl   $0xf010589b,(%esp)
f0101212:	e8 92 ee ff ff       	call   f01000a9 <_panic>
	assert(nfree_extmem > 0);
f0101217:	83 7d cc 00          	cmpl   $0x0,-0x34(%ebp)
f010121b:	7f 4e                	jg     f010126b <check_page_free_list+0x2e5>
f010121d:	c7 44 24 0c 75 59 10 	movl   $0xf0105975,0xc(%esp)
f0101224:	f0 
f0101225:	c7 44 24 08 ba 58 10 	movl   $0xf01058ba,0x8(%esp)
f010122c:	f0 
f010122d:	c7 44 24 04 79 02 00 	movl   $0x279,0x4(%esp)
f0101234:	00 
f0101235:	c7 04 24 9b 58 10 f0 	movl   $0xf010589b,(%esp)
f010123c:	e8 68 ee ff ff       	call   f01000a9 <_panic>
	struct PageInfo *pp;
	unsigned pdx_limit = only_low_memory ? 1 : NPDENTRIES;
	int nfree_basemem = 0, nfree_extmem = 0;
	char *first_free_page;

	if (!page_free_list)
f0101241:	8b 1d bc 52 18 f0    	mov    0xf01852bc,%ebx
f0101247:	85 db                	test   %ebx,%ebx
f0101249:	0f 85 69 fd ff ff    	jne    f0100fb8 <check_page_free_list+0x32>
f010124f:	e9 48 fd ff ff       	jmp    f0100f9c <check_page_free_list+0x16>
f0101254:	83 3d bc 52 18 f0 00 	cmpl   $0x0,0xf01852bc
f010125b:	0f 84 3b fd ff ff    	je     f0100f9c <check_page_free_list+0x16>
//
static void
check_page_free_list(bool only_low_memory)
{
	struct PageInfo *pp;
	unsigned pdx_limit = only_low_memory ? 1 : NPDENTRIES;
f0101261:	be 00 04 00 00       	mov    $0x400,%esi
f0101266:	e9 99 fd ff ff       	jmp    f0101004 <check_page_free_list+0x7e>
			++nfree_extmem;
	}

	assert(nfree_basemem > 0);
	assert(nfree_extmem > 0);
}
f010126b:	83 c4 3c             	add    $0x3c,%esp
f010126e:	5b                   	pop    %ebx
f010126f:	5e                   	pop    %esi
f0101270:	5f                   	pop    %edi
f0101271:	5d                   	pop    %ebp
f0101272:	c3                   	ret    

f0101273 <pa2page>:
}

static inline struct PageInfo*
pa2page(physaddr_t pa)
{
	if (PGNUM(pa) >= npages)
f0101273:	c1 e8 0c             	shr    $0xc,%eax
f0101276:	3b 05 84 6f 18 f0    	cmp    0xf0186f84,%eax
f010127c:	72 22                	jb     f01012a0 <pa2page+0x2d>
	return (pp - pages) << PGSHIFT;
}

static inline struct PageInfo*
pa2page(physaddr_t pa)
{
f010127e:	55                   	push   %ebp
f010127f:	89 e5                	mov    %esp,%ebp
f0101281:	83 ec 18             	sub    $0x18,%esp
	if (PGNUM(pa) >= npages)
		panic("pa2page called with invalid pa");
f0101284:	c7 44 24 08 14 53 10 	movl   $0xf0105314,0x8(%esp)
f010128b:	f0 
f010128c:	c7 44 24 04 4f 00 00 	movl   $0x4f,0x4(%esp)
f0101293:	00 
f0101294:	c7 04 24 8d 58 10 f0 	movl   $0xf010588d,(%esp)
f010129b:	e8 09 ee ff ff       	call   f01000a9 <_panic>
	return &pages[PGNUM(pa)];
f01012a0:	8b 15 8c 6f 18 f0    	mov    0xf0186f8c,%edx
f01012a6:	8d 04 c2             	lea    (%edx,%eax,8),%eax
}
f01012a9:	c3                   	ret    

f01012aa <page_init>:
// allocator functions below to allocate and deallocate physical
// memory via the page_free_list.
//
void
page_init(void)
{
f01012aa:	55                   	push   %ebp
f01012ab:	89 e5                	mov    %esp,%ebp
f01012ad:	56                   	push   %esi
f01012ae:	53                   	push   %ebx
	// NB: DO NOT actually touch the physical memory corresponding to
	// free pages!
	size_t i;
	uint32_t lim_inf_IO = PGNUM(IOPHYSMEM);//==npages_basemem
	//uint32_t lim_sup_IO = PGNUM(EXTPHYSMEM); //no hace falta por lim_sup_kernmem > lim_sup_IO
	uint32_t lim_sup_kernmem = PGNUM(PADDR(boot_alloc(0)));
f01012af:	b8 00 00 00 00       	mov    $0x0,%eax
f01012b4:	e8 81 f9 ff ff       	call   f0100c3a <boot_alloc>
f01012b9:	89 c1                	mov    %eax,%ecx
f01012bb:	ba 19 01 00 00       	mov    $0x119,%edx
f01012c0:	b8 9b 58 10 f0       	mov    $0xf010589b,%eax
f01012c5:	e8 43 f9 ff ff       	call   f0100c0d <_paddr>
f01012ca:	c1 e8 0c             	shr    $0xc,%eax
f01012cd:	8b 35 bc 52 18 f0    	mov    0xf01852bc,%esi
	for (i = 1; i < npages; i++) {//la 0 no se agrega tampoco
f01012d3:	ba 01 00 00 00       	mov    $0x1,%edx
f01012d8:	eb 2e                	jmp    f0101308 <page_init+0x5e>
		if (i>=lim_inf_IO && i<lim_sup_kernmem) continue;//asi es como se no-mapea		
f01012da:	39 c2                	cmp    %eax,%edx
f01012dc:	73 08                	jae    f01012e6 <page_init+0x3c>
f01012de:	81 fa 9f 00 00 00    	cmp    $0x9f,%edx
f01012e4:	77 1f                	ja     f0101305 <page_init+0x5b>
f01012e6:	8d 0c d5 00 00 00 00 	lea    0x0(,%edx,8),%ecx
		pages[i].pp_ref = 0;
f01012ed:	89 cb                	mov    %ecx,%ebx
f01012ef:	03 1d 8c 6f 18 f0    	add    0xf0186f8c,%ebx
f01012f5:	66 c7 43 04 00 00    	movw   $0x0,0x4(%ebx)
		pages[i].pp_link = page_free_list;
f01012fb:	89 33                	mov    %esi,(%ebx)
		page_free_list = &pages[i];
f01012fd:	89 ce                	mov    %ecx,%esi
f01012ff:	03 35 8c 6f 18 f0    	add    0xf0186f8c,%esi
	// free pages!
	size_t i;
	uint32_t lim_inf_IO = PGNUM(IOPHYSMEM);//==npages_basemem
	//uint32_t lim_sup_IO = PGNUM(EXTPHYSMEM); //no hace falta por lim_sup_kernmem > lim_sup_IO
	uint32_t lim_sup_kernmem = PGNUM(PADDR(boot_alloc(0)));
	for (i = 1; i < npages; i++) {//la 0 no se agrega tampoco
f0101305:	83 c2 01             	add    $0x1,%edx
f0101308:	3b 15 84 6f 18 f0    	cmp    0xf0186f84,%edx
f010130e:	72 ca                	jb     f01012da <page_init+0x30>
f0101310:	89 35 bc 52 18 f0    	mov    %esi,0xf01852bc
		if (i>=lim_inf_IO && i<lim_sup_kernmem) continue;//asi es como se no-mapea		
		pages[i].pp_ref = 0;
		pages[i].pp_link = page_free_list;
		page_free_list = &pages[i];
	}
}
f0101316:	5b                   	pop    %ebx
f0101317:	5e                   	pop    %esi
f0101318:	5d                   	pop    %ebp
f0101319:	c3                   	ret    

f010131a <page_alloc>:
// Returns NULL if out of free memory.
//
// Hint: use page2kva and memset
struct PageInfo *
page_alloc(int alloc_flags)
{	if (page_free_list == NULL) return NULL;
f010131a:	55                   	push   %ebp
f010131b:	89 e5                	mov    %esp,%ebp
f010131d:	53                   	push   %ebx
f010131e:	83 ec 14             	sub    $0x14,%esp
f0101321:	8b 1d bc 52 18 f0    	mov    0xf01852bc,%ebx
f0101327:	85 db                	test   %ebx,%ebx
f0101329:	74 36                	je     f0101361 <page_alloc+0x47>
	struct PageInfo* pag = page_free_list;
	page_free_list = page_free_list->pp_link;
f010132b:	8b 03                	mov    (%ebx),%eax
f010132d:	a3 bc 52 18 f0       	mov    %eax,0xf01852bc
	pag->pp_link = NULL;
f0101332:	c7 03 00 00 00 00    	movl   $0x0,(%ebx)
	if (alloc_flags & ALLOC_ZERO) memset(page2kva(pag),0,PGSIZE);
	return pag;
f0101338:	89 d8                	mov    %ebx,%eax
page_alloc(int alloc_flags)
{	if (page_free_list == NULL) return NULL;
	struct PageInfo* pag = page_free_list;
	page_free_list = page_free_list->pp_link;
	pag->pp_link = NULL;
	if (alloc_flags & ALLOC_ZERO) memset(page2kva(pag),0,PGSIZE);
f010133a:	f6 45 08 01          	testb  $0x1,0x8(%ebp)
f010133e:	74 26                	je     f0101366 <page_alloc+0x4c>
f0101340:	e8 3e f8 ff ff       	call   f0100b83 <page2kva>
f0101345:	c7 44 24 08 00 10 00 	movl   $0x1000,0x8(%esp)
f010134c:	00 
f010134d:	c7 44 24 04 00 00 00 	movl   $0x0,0x4(%esp)
f0101354:	00 
f0101355:	89 04 24             	mov    %eax,(%esp)
f0101358:	e8 6a 33 00 00       	call   f01046c7 <memset>
	return pag;
f010135d:	89 d8                	mov    %ebx,%eax
f010135f:	eb 05                	jmp    f0101366 <page_alloc+0x4c>
// Returns NULL if out of free memory.
//
// Hint: use page2kva and memset
struct PageInfo *
page_alloc(int alloc_flags)
{	if (page_free_list == NULL) return NULL;
f0101361:	b8 00 00 00 00       	mov    $0x0,%eax
	struct PageInfo* pag = page_free_list;
	page_free_list = page_free_list->pp_link;
	pag->pp_link = NULL;
	if (alloc_flags & ALLOC_ZERO) memset(page2kva(pag),0,PGSIZE);
	return pag;
}
f0101366:	83 c4 14             	add    $0x14,%esp
f0101369:	5b                   	pop    %ebx
f010136a:	5d                   	pop    %ebp
f010136b:	c3                   	ret    

f010136c <page_free>:
// Return a page to the free list.
// (This function should only be called when pp->pp_ref reaches 0.)
//
void
page_free(struct PageInfo *pp)
{
f010136c:	55                   	push   %ebp
f010136d:	89 e5                	mov    %esp,%ebp
f010136f:	83 ec 18             	sub    $0x18,%esp
f0101372:	8b 45 08             	mov    0x8(%ebp),%eax
	// Fill this function in
	// Hint: You may want to panic if pp->pp_ref is nonzero or
	// pp->pp_link is not NULL.
	if (pp->pp_ref) panic("page still in use!\n");
f0101375:	66 83 78 04 00       	cmpw   $0x0,0x4(%eax)
f010137a:	74 1c                	je     f0101398 <page_free+0x2c>
f010137c:	c7 44 24 08 86 59 10 	movl   $0xf0105986,0x8(%esp)
f0101383:	f0 
f0101384:	c7 44 24 04 42 01 00 	movl   $0x142,0x4(%esp)
f010138b:	00 
f010138c:	c7 04 24 9b 58 10 f0 	movl   $0xf010589b,(%esp)
f0101393:	e8 11 ed ff ff       	call   f01000a9 <_panic>
	if (pp->pp_link) panic("page has non-NULL pp_link (already freed?)\n");
f0101398:	83 38 00             	cmpl   $0x0,(%eax)
f010139b:	74 1c                	je     f01013b9 <page_free+0x4d>
f010139d:	c7 44 24 08 34 53 10 	movl   $0xf0105334,0x8(%esp)
f01013a4:	f0 
f01013a5:	c7 44 24 04 43 01 00 	movl   $0x143,0x4(%esp)
f01013ac:	00 
f01013ad:	c7 04 24 9b 58 10 f0 	movl   $0xf010589b,(%esp)
f01013b4:	e8 f0 ec ff ff       	call   f01000a9 <_panic>
	//pp_ref=0,pp_link=NULL
	pp->pp_link=page_free_list;
f01013b9:	8b 15 bc 52 18 f0    	mov    0xf01852bc,%edx
f01013bf:	89 10                	mov    %edx,(%eax)
	page_free_list=pp;
f01013c1:	a3 bc 52 18 f0       	mov    %eax,0xf01852bc
}
f01013c6:	c9                   	leave  
f01013c7:	c3                   	ret    

f01013c8 <check_page_alloc>:
// Check the physical page allocator (page_alloc(), page_free(),
// and page_init()).
//
static void
check_page_alloc(void)
{
f01013c8:	55                   	push   %ebp
f01013c9:	89 e5                	mov    %esp,%ebp
f01013cb:	57                   	push   %edi
f01013cc:	56                   	push   %esi
f01013cd:	53                   	push   %ebx
f01013ce:	83 ec 2c             	sub    $0x2c,%esp
	int nfree;
	struct PageInfo *fl;
	char *c;
	int i;

	if (!pages)
f01013d1:	83 3d 8c 6f 18 f0 00 	cmpl   $0x0,0xf0186f8c
f01013d8:	75 1c                	jne    f01013f6 <check_page_alloc+0x2e>
		panic("'pages' is a null pointer!");
f01013da:	c7 44 24 08 9a 59 10 	movl   $0xf010599a,0x8(%esp)
f01013e1:	f0 
f01013e2:	c7 44 24 04 8a 02 00 	movl   $0x28a,0x4(%esp)
f01013e9:	00 
f01013ea:	c7 04 24 9b 58 10 f0 	movl   $0xf010589b,(%esp)
f01013f1:	e8 b3 ec ff ff       	call   f01000a9 <_panic>

	// check number of free pages
	for (pp = page_free_list, nfree = 0; pp; pp = pp->pp_link)
f01013f6:	a1 bc 52 18 f0       	mov    0xf01852bc,%eax
f01013fb:	be 00 00 00 00       	mov    $0x0,%esi
f0101400:	eb 05                	jmp    f0101407 <check_page_alloc+0x3f>
		++nfree;
f0101402:	83 c6 01             	add    $0x1,%esi

	if (!pages)
		panic("'pages' is a null pointer!");

	// check number of free pages
	for (pp = page_free_list, nfree = 0; pp; pp = pp->pp_link)
f0101405:	8b 00                	mov    (%eax),%eax
f0101407:	85 c0                	test   %eax,%eax
f0101409:	75 f7                	jne    f0101402 <check_page_alloc+0x3a>
		++nfree;

	// should be able to allocate three pages
	pp0 = pp1 = pp2 = 0;
	assert((pp0 = page_alloc(0)));
f010140b:	c7 04 24 00 00 00 00 	movl   $0x0,(%esp)
f0101412:	e8 03 ff ff ff       	call   f010131a <page_alloc>
f0101417:	89 c7                	mov    %eax,%edi
f0101419:	85 c0                	test   %eax,%eax
f010141b:	75 24                	jne    f0101441 <check_page_alloc+0x79>
f010141d:	c7 44 24 0c b5 59 10 	movl   $0xf01059b5,0xc(%esp)
f0101424:	f0 
f0101425:	c7 44 24 08 ba 58 10 	movl   $0xf01058ba,0x8(%esp)
f010142c:	f0 
f010142d:	c7 44 24 04 92 02 00 	movl   $0x292,0x4(%esp)
f0101434:	00 
f0101435:	c7 04 24 9b 58 10 f0 	movl   $0xf010589b,(%esp)
f010143c:	e8 68 ec ff ff       	call   f01000a9 <_panic>
	assert((pp1 = page_alloc(0)));
f0101441:	c7 04 24 00 00 00 00 	movl   $0x0,(%esp)
f0101448:	e8 cd fe ff ff       	call   f010131a <page_alloc>
f010144d:	89 45 e4             	mov    %eax,-0x1c(%ebp)
f0101450:	85 c0                	test   %eax,%eax
f0101452:	75 24                	jne    f0101478 <check_page_alloc+0xb0>
f0101454:	c7 44 24 0c cb 59 10 	movl   $0xf01059cb,0xc(%esp)
f010145b:	f0 
f010145c:	c7 44 24 08 ba 58 10 	movl   $0xf01058ba,0x8(%esp)
f0101463:	f0 
f0101464:	c7 44 24 04 93 02 00 	movl   $0x293,0x4(%esp)
f010146b:	00 
f010146c:	c7 04 24 9b 58 10 f0 	movl   $0xf010589b,(%esp)
f0101473:	e8 31 ec ff ff       	call   f01000a9 <_panic>
	assert((pp2 = page_alloc(0)));
f0101478:	c7 04 24 00 00 00 00 	movl   $0x0,(%esp)
f010147f:	e8 96 fe ff ff       	call   f010131a <page_alloc>
f0101484:	89 c3                	mov    %eax,%ebx
f0101486:	85 c0                	test   %eax,%eax
f0101488:	75 24                	jne    f01014ae <check_page_alloc+0xe6>
f010148a:	c7 44 24 0c e1 59 10 	movl   $0xf01059e1,0xc(%esp)
f0101491:	f0 
f0101492:	c7 44 24 08 ba 58 10 	movl   $0xf01058ba,0x8(%esp)
f0101499:	f0 
f010149a:	c7 44 24 04 94 02 00 	movl   $0x294,0x4(%esp)
f01014a1:	00 
f01014a2:	c7 04 24 9b 58 10 f0 	movl   $0xf010589b,(%esp)
f01014a9:	e8 fb eb ff ff       	call   f01000a9 <_panic>

	assert(pp0);
	assert(pp1 && pp1 != pp0);
f01014ae:	3b 7d e4             	cmp    -0x1c(%ebp),%edi
f01014b1:	75 24                	jne    f01014d7 <check_page_alloc+0x10f>
f01014b3:	c7 44 24 0c f7 59 10 	movl   $0xf01059f7,0xc(%esp)
f01014ba:	f0 
f01014bb:	c7 44 24 08 ba 58 10 	movl   $0xf01058ba,0x8(%esp)
f01014c2:	f0 
f01014c3:	c7 44 24 04 97 02 00 	movl   $0x297,0x4(%esp)
f01014ca:	00 
f01014cb:	c7 04 24 9b 58 10 f0 	movl   $0xf010589b,(%esp)
f01014d2:	e8 d2 eb ff ff       	call   f01000a9 <_panic>
	assert(pp2 && pp2 != pp1 && pp2 != pp0);
f01014d7:	39 45 e4             	cmp    %eax,-0x1c(%ebp)
f01014da:	74 04                	je     f01014e0 <check_page_alloc+0x118>
f01014dc:	39 f8                	cmp    %edi,%eax
f01014de:	75 24                	jne    f0101504 <check_page_alloc+0x13c>
f01014e0:	c7 44 24 0c 60 53 10 	movl   $0xf0105360,0xc(%esp)
f01014e7:	f0 
f01014e8:	c7 44 24 08 ba 58 10 	movl   $0xf01058ba,0x8(%esp)
f01014ef:	f0 
f01014f0:	c7 44 24 04 98 02 00 	movl   $0x298,0x4(%esp)
f01014f7:	00 
f01014f8:	c7 04 24 9b 58 10 f0 	movl   $0xf010589b,(%esp)
f01014ff:	e8 a5 eb ff ff       	call   f01000a9 <_panic>
	assert(page2pa(pp0) < npages*PGSIZE);
f0101504:	89 f8                	mov    %edi,%eax
f0101506:	e8 88 f5 ff ff       	call   f0100a93 <page2pa>
f010150b:	8b 0d 84 6f 18 f0    	mov    0xf0186f84,%ecx
f0101511:	c1 e1 0c             	shl    $0xc,%ecx
f0101514:	89 4d e0             	mov    %ecx,-0x20(%ebp)
f0101517:	39 c8                	cmp    %ecx,%eax
f0101519:	72 24                	jb     f010153f <check_page_alloc+0x177>
f010151b:	c7 44 24 0c 09 5a 10 	movl   $0xf0105a09,0xc(%esp)
f0101522:	f0 
f0101523:	c7 44 24 08 ba 58 10 	movl   $0xf01058ba,0x8(%esp)
f010152a:	f0 
f010152b:	c7 44 24 04 99 02 00 	movl   $0x299,0x4(%esp)
f0101532:	00 
f0101533:	c7 04 24 9b 58 10 f0 	movl   $0xf010589b,(%esp)
f010153a:	e8 6a eb ff ff       	call   f01000a9 <_panic>
	assert(page2pa(pp1) < npages*PGSIZE);
f010153f:	8b 45 e4             	mov    -0x1c(%ebp),%eax
f0101542:	e8 4c f5 ff ff       	call   f0100a93 <page2pa>
f0101547:	39 45 e0             	cmp    %eax,-0x20(%ebp)
f010154a:	77 24                	ja     f0101570 <check_page_alloc+0x1a8>
f010154c:	c7 44 24 0c 26 5a 10 	movl   $0xf0105a26,0xc(%esp)
f0101553:	f0 
f0101554:	c7 44 24 08 ba 58 10 	movl   $0xf01058ba,0x8(%esp)
f010155b:	f0 
f010155c:	c7 44 24 04 9a 02 00 	movl   $0x29a,0x4(%esp)
f0101563:	00 
f0101564:	c7 04 24 9b 58 10 f0 	movl   $0xf010589b,(%esp)
f010156b:	e8 39 eb ff ff       	call   f01000a9 <_panic>
	assert(page2pa(pp2) < npages*PGSIZE);
f0101570:	89 d8                	mov    %ebx,%eax
f0101572:	e8 1c f5 ff ff       	call   f0100a93 <page2pa>
f0101577:	39 45 e0             	cmp    %eax,-0x20(%ebp)
f010157a:	77 24                	ja     f01015a0 <check_page_alloc+0x1d8>
f010157c:	c7 44 24 0c 43 5a 10 	movl   $0xf0105a43,0xc(%esp)
f0101583:	f0 
f0101584:	c7 44 24 08 ba 58 10 	movl   $0xf01058ba,0x8(%esp)
f010158b:	f0 
f010158c:	c7 44 24 04 9b 02 00 	movl   $0x29b,0x4(%esp)
f0101593:	00 
f0101594:	c7 04 24 9b 58 10 f0 	movl   $0xf010589b,(%esp)
f010159b:	e8 09 eb ff ff       	call   f01000a9 <_panic>

	// temporarily steal the rest of the free pages
	fl = page_free_list;
f01015a0:	a1 bc 52 18 f0       	mov    0xf01852bc,%eax
f01015a5:	89 45 e0             	mov    %eax,-0x20(%ebp)
	page_free_list = 0;
f01015a8:	c7 05 bc 52 18 f0 00 	movl   $0x0,0xf01852bc
f01015af:	00 00 00 

	// should be no free memory
	assert(!page_alloc(0));
f01015b2:	c7 04 24 00 00 00 00 	movl   $0x0,(%esp)
f01015b9:	e8 5c fd ff ff       	call   f010131a <page_alloc>
f01015be:	85 c0                	test   %eax,%eax
f01015c0:	74 24                	je     f01015e6 <check_page_alloc+0x21e>
f01015c2:	c7 44 24 0c 60 5a 10 	movl   $0xf0105a60,0xc(%esp)
f01015c9:	f0 
f01015ca:	c7 44 24 08 ba 58 10 	movl   $0xf01058ba,0x8(%esp)
f01015d1:	f0 
f01015d2:	c7 44 24 04 a2 02 00 	movl   $0x2a2,0x4(%esp)
f01015d9:	00 
f01015da:	c7 04 24 9b 58 10 f0 	movl   $0xf010589b,(%esp)
f01015e1:	e8 c3 ea ff ff       	call   f01000a9 <_panic>

	// free and re-allocate?
	page_free(pp0);
f01015e6:	89 3c 24             	mov    %edi,(%esp)
f01015e9:	e8 7e fd ff ff       	call   f010136c <page_free>
	page_free(pp1);
f01015ee:	8b 45 e4             	mov    -0x1c(%ebp),%eax
f01015f1:	89 04 24             	mov    %eax,(%esp)
f01015f4:	e8 73 fd ff ff       	call   f010136c <page_free>
	page_free(pp2);
f01015f9:	89 1c 24             	mov    %ebx,(%esp)
f01015fc:	e8 6b fd ff ff       	call   f010136c <page_free>
	pp0 = pp1 = pp2 = 0;
	assert((pp0 = page_alloc(0)));
f0101601:	c7 04 24 00 00 00 00 	movl   $0x0,(%esp)
f0101608:	e8 0d fd ff ff       	call   f010131a <page_alloc>
f010160d:	89 c3                	mov    %eax,%ebx
f010160f:	85 c0                	test   %eax,%eax
f0101611:	75 24                	jne    f0101637 <check_page_alloc+0x26f>
f0101613:	c7 44 24 0c b5 59 10 	movl   $0xf01059b5,0xc(%esp)
f010161a:	f0 
f010161b:	c7 44 24 08 ba 58 10 	movl   $0xf01058ba,0x8(%esp)
f0101622:	f0 
f0101623:	c7 44 24 04 a9 02 00 	movl   $0x2a9,0x4(%esp)
f010162a:	00 
f010162b:	c7 04 24 9b 58 10 f0 	movl   $0xf010589b,(%esp)
f0101632:	e8 72 ea ff ff       	call   f01000a9 <_panic>
	assert((pp1 = page_alloc(0)));
f0101637:	c7 04 24 00 00 00 00 	movl   $0x0,(%esp)
f010163e:	e8 d7 fc ff ff       	call   f010131a <page_alloc>
f0101643:	89 45 e4             	mov    %eax,-0x1c(%ebp)
f0101646:	85 c0                	test   %eax,%eax
f0101648:	75 24                	jne    f010166e <check_page_alloc+0x2a6>
f010164a:	c7 44 24 0c cb 59 10 	movl   $0xf01059cb,0xc(%esp)
f0101651:	f0 
f0101652:	c7 44 24 08 ba 58 10 	movl   $0xf01058ba,0x8(%esp)
f0101659:	f0 
f010165a:	c7 44 24 04 aa 02 00 	movl   $0x2aa,0x4(%esp)
f0101661:	00 
f0101662:	c7 04 24 9b 58 10 f0 	movl   $0xf010589b,(%esp)
f0101669:	e8 3b ea ff ff       	call   f01000a9 <_panic>
	assert((pp2 = page_alloc(0)));
f010166e:	c7 04 24 00 00 00 00 	movl   $0x0,(%esp)
f0101675:	e8 a0 fc ff ff       	call   f010131a <page_alloc>
f010167a:	89 c7                	mov    %eax,%edi
f010167c:	85 c0                	test   %eax,%eax
f010167e:	75 24                	jne    f01016a4 <check_page_alloc+0x2dc>
f0101680:	c7 44 24 0c e1 59 10 	movl   $0xf01059e1,0xc(%esp)
f0101687:	f0 
f0101688:	c7 44 24 08 ba 58 10 	movl   $0xf01058ba,0x8(%esp)
f010168f:	f0 
f0101690:	c7 44 24 04 ab 02 00 	movl   $0x2ab,0x4(%esp)
f0101697:	00 
f0101698:	c7 04 24 9b 58 10 f0 	movl   $0xf010589b,(%esp)
f010169f:	e8 05 ea ff ff       	call   f01000a9 <_panic>
	assert(pp0);
	assert(pp1 && pp1 != pp0);
f01016a4:	3b 5d e4             	cmp    -0x1c(%ebp),%ebx
f01016a7:	75 24                	jne    f01016cd <check_page_alloc+0x305>
f01016a9:	c7 44 24 0c f7 59 10 	movl   $0xf01059f7,0xc(%esp)
f01016b0:	f0 
f01016b1:	c7 44 24 08 ba 58 10 	movl   $0xf01058ba,0x8(%esp)
f01016b8:	f0 
f01016b9:	c7 44 24 04 ad 02 00 	movl   $0x2ad,0x4(%esp)
f01016c0:	00 
f01016c1:	c7 04 24 9b 58 10 f0 	movl   $0xf010589b,(%esp)
f01016c8:	e8 dc e9 ff ff       	call   f01000a9 <_panic>
	assert(pp2 && pp2 != pp1 && pp2 != pp0);
f01016cd:	39 45 e4             	cmp    %eax,-0x1c(%ebp)
f01016d0:	74 04                	je     f01016d6 <check_page_alloc+0x30e>
f01016d2:	39 d8                	cmp    %ebx,%eax
f01016d4:	75 24                	jne    f01016fa <check_page_alloc+0x332>
f01016d6:	c7 44 24 0c 60 53 10 	movl   $0xf0105360,0xc(%esp)
f01016dd:	f0 
f01016de:	c7 44 24 08 ba 58 10 	movl   $0xf01058ba,0x8(%esp)
f01016e5:	f0 
f01016e6:	c7 44 24 04 ae 02 00 	movl   $0x2ae,0x4(%esp)
f01016ed:	00 
f01016ee:	c7 04 24 9b 58 10 f0 	movl   $0xf010589b,(%esp)
f01016f5:	e8 af e9 ff ff       	call   f01000a9 <_panic>
	assert(!page_alloc(0));
f01016fa:	c7 04 24 00 00 00 00 	movl   $0x0,(%esp)
f0101701:	e8 14 fc ff ff       	call   f010131a <page_alloc>
f0101706:	85 c0                	test   %eax,%eax
f0101708:	74 24                	je     f010172e <check_page_alloc+0x366>
f010170a:	c7 44 24 0c 60 5a 10 	movl   $0xf0105a60,0xc(%esp)
f0101711:	f0 
f0101712:	c7 44 24 08 ba 58 10 	movl   $0xf01058ba,0x8(%esp)
f0101719:	f0 
f010171a:	c7 44 24 04 af 02 00 	movl   $0x2af,0x4(%esp)
f0101721:	00 
f0101722:	c7 04 24 9b 58 10 f0 	movl   $0xf010589b,(%esp)
f0101729:	e8 7b e9 ff ff       	call   f01000a9 <_panic>

	// test flags
	memset(page2kva(pp0), 1, PGSIZE);
f010172e:	89 d8                	mov    %ebx,%eax
f0101730:	e8 4e f4 ff ff       	call   f0100b83 <page2kva>
f0101735:	c7 44 24 08 00 10 00 	movl   $0x1000,0x8(%esp)
f010173c:	00 
f010173d:	c7 44 24 04 01 00 00 	movl   $0x1,0x4(%esp)
f0101744:	00 
f0101745:	89 04 24             	mov    %eax,(%esp)
f0101748:	e8 7a 2f 00 00       	call   f01046c7 <memset>
	page_free(pp0);
f010174d:	89 1c 24             	mov    %ebx,(%esp)
f0101750:	e8 17 fc ff ff       	call   f010136c <page_free>
	assert((pp = page_alloc(ALLOC_ZERO)));
f0101755:	c7 04 24 01 00 00 00 	movl   $0x1,(%esp)
f010175c:	e8 b9 fb ff ff       	call   f010131a <page_alloc>
f0101761:	85 c0                	test   %eax,%eax
f0101763:	75 24                	jne    f0101789 <check_page_alloc+0x3c1>
f0101765:	c7 44 24 0c 6f 5a 10 	movl   $0xf0105a6f,0xc(%esp)
f010176c:	f0 
f010176d:	c7 44 24 08 ba 58 10 	movl   $0xf01058ba,0x8(%esp)
f0101774:	f0 
f0101775:	c7 44 24 04 b4 02 00 	movl   $0x2b4,0x4(%esp)
f010177c:	00 
f010177d:	c7 04 24 9b 58 10 f0 	movl   $0xf010589b,(%esp)
f0101784:	e8 20 e9 ff ff       	call   f01000a9 <_panic>
	assert(pp && pp0 == pp);
f0101789:	39 c3                	cmp    %eax,%ebx
f010178b:	74 24                	je     f01017b1 <check_page_alloc+0x3e9>
f010178d:	c7 44 24 0c 8d 5a 10 	movl   $0xf0105a8d,0xc(%esp)
f0101794:	f0 
f0101795:	c7 44 24 08 ba 58 10 	movl   $0xf01058ba,0x8(%esp)
f010179c:	f0 
f010179d:	c7 44 24 04 b5 02 00 	movl   $0x2b5,0x4(%esp)
f01017a4:	00 
f01017a5:	c7 04 24 9b 58 10 f0 	movl   $0xf010589b,(%esp)
f01017ac:	e8 f8 e8 ff ff       	call   f01000a9 <_panic>
	c = page2kva(pp);
f01017b1:	89 d8                	mov    %ebx,%eax
f01017b3:	e8 cb f3 ff ff       	call   f0100b83 <page2kva>
	for (i = 0; i < PGSIZE; i++)
f01017b8:	ba 00 00 00 00       	mov    $0x0,%edx
		assert(c[i] == 0);
f01017bd:	80 3c 10 00          	cmpb   $0x0,(%eax,%edx,1)
f01017c1:	74 24                	je     f01017e7 <check_page_alloc+0x41f>
f01017c3:	c7 44 24 0c 9d 5a 10 	movl   $0xf0105a9d,0xc(%esp)
f01017ca:	f0 
f01017cb:	c7 44 24 08 ba 58 10 	movl   $0xf01058ba,0x8(%esp)
f01017d2:	f0 
f01017d3:	c7 44 24 04 b8 02 00 	movl   $0x2b8,0x4(%esp)
f01017da:	00 
f01017db:	c7 04 24 9b 58 10 f0 	movl   $0xf010589b,(%esp)
f01017e2:	e8 c2 e8 ff ff       	call   f01000a9 <_panic>
	memset(page2kva(pp0), 1, PGSIZE);
	page_free(pp0);
	assert((pp = page_alloc(ALLOC_ZERO)));
	assert(pp && pp0 == pp);
	c = page2kva(pp);
	for (i = 0; i < PGSIZE; i++)
f01017e7:	83 c2 01             	add    $0x1,%edx
f01017ea:	81 fa 00 10 00 00    	cmp    $0x1000,%edx
f01017f0:	75 cb                	jne    f01017bd <check_page_alloc+0x3f5>
		assert(c[i] == 0);

	// give free list back
	page_free_list = fl;
f01017f2:	8b 45 e0             	mov    -0x20(%ebp),%eax
f01017f5:	a3 bc 52 18 f0       	mov    %eax,0xf01852bc

	// free the pages we took
	page_free(pp0);
f01017fa:	89 1c 24             	mov    %ebx,(%esp)
f01017fd:	e8 6a fb ff ff       	call   f010136c <page_free>
	page_free(pp1);
f0101802:	8b 45 e4             	mov    -0x1c(%ebp),%eax
f0101805:	89 04 24             	mov    %eax,(%esp)
f0101808:	e8 5f fb ff ff       	call   f010136c <page_free>
	page_free(pp2);
f010180d:	89 3c 24             	mov    %edi,(%esp)
f0101810:	e8 57 fb ff ff       	call   f010136c <page_free>

	// number of free pages should be the same
	for (pp = page_free_list; pp; pp = pp->pp_link)
f0101815:	a1 bc 52 18 f0       	mov    0xf01852bc,%eax
f010181a:	eb 05                	jmp    f0101821 <check_page_alloc+0x459>
		--nfree;
f010181c:	83 ee 01             	sub    $0x1,%esi
	page_free(pp0);
	page_free(pp1);
	page_free(pp2);

	// number of free pages should be the same
	for (pp = page_free_list; pp; pp = pp->pp_link)
f010181f:	8b 00                	mov    (%eax),%eax
f0101821:	85 c0                	test   %eax,%eax
f0101823:	75 f7                	jne    f010181c <check_page_alloc+0x454>
		--nfree;
	assert(nfree == 0);
f0101825:	85 f6                	test   %esi,%esi
f0101827:	74 24                	je     f010184d <check_page_alloc+0x485>
f0101829:	c7 44 24 0c a7 5a 10 	movl   $0xf0105aa7,0xc(%esp)
f0101830:	f0 
f0101831:	c7 44 24 08 ba 58 10 	movl   $0xf01058ba,0x8(%esp)
f0101838:	f0 
f0101839:	c7 44 24 04 c5 02 00 	movl   $0x2c5,0x4(%esp)
f0101840:	00 
f0101841:	c7 04 24 9b 58 10 f0 	movl   $0xf010589b,(%esp)
f0101848:	e8 5c e8 ff ff       	call   f01000a9 <_panic>

	cprintf("check_page_alloc() succeeded!\n");
f010184d:	c7 04 24 80 53 10 f0 	movl   $0xf0105380,(%esp)
f0101854:	e8 a5 1e 00 00       	call   f01036fe <cprintf>
}
f0101859:	83 c4 2c             	add    $0x2c,%esp
f010185c:	5b                   	pop    %ebx
f010185d:	5e                   	pop    %esi
f010185e:	5f                   	pop    %edi
f010185f:	5d                   	pop    %ebp
f0101860:	c3                   	ret    

f0101861 <page_decref>:
// Decrement the reference count on a page,
// freeing it if there are no more refs.
//
void
page_decref(struct PageInfo* pp)
{
f0101861:	55                   	push   %ebp
f0101862:	89 e5                	mov    %esp,%ebp
f0101864:	83 ec 18             	sub    $0x18,%esp
f0101867:	8b 45 08             	mov    0x8(%ebp),%eax
	if (--pp->pp_ref == 0)
f010186a:	0f b7 48 04          	movzwl 0x4(%eax),%ecx
f010186e:	8d 51 ff             	lea    -0x1(%ecx),%edx
f0101871:	66 89 50 04          	mov    %dx,0x4(%eax)
f0101875:	66 85 d2             	test   %dx,%dx
f0101878:	75 08                	jne    f0101882 <page_decref+0x21>
		page_free(pp);
f010187a:	89 04 24             	mov    %eax,(%esp)
f010187d:	e8 ea fa ff ff       	call   f010136c <page_free>
}
f0101882:	c9                   	leave  
f0101883:	c3                   	ret    

f0101884 <pgdir_walk>:
// Hint 3: look at inc/mmu.h for useful macros that mainipulate page
// table and page directory entries.
//
pte_t *
pgdir_walk(pde_t *pgdir, const void *va, int create)
{
f0101884:	55                   	push   %ebp
f0101885:	89 e5                	mov    %esp,%ebp
f0101887:	57                   	push   %edi
f0101888:	56                   	push   %esi
f0101889:	53                   	push   %ebx
f010188a:	83 ec 1c             	sub    $0x1c,%esp
f010188d:	8b 75 0c             	mov    0xc(%ebp),%esi
	pde_t pde =  pgdir[PDX(va)]; //ojo que esto es P.Addr. !!
f0101890:	89 f7                	mov    %esi,%edi
f0101892:	c1 ef 16             	shr    $0x16,%edi
f0101895:	c1 e7 02             	shl    $0x2,%edi
f0101898:	03 7d 08             	add    0x8(%ebp),%edi
f010189b:	8b 1f                	mov    (%edi),%ebx
	pte_t* pte = (pte_t*) KADDR(PTE_ADDR(pde));
f010189d:	89 d9                	mov    %ebx,%ecx
f010189f:	81 e1 00 f0 ff ff    	and    $0xfffff000,%ecx
f01018a5:	ba 6e 01 00 00       	mov    $0x16e,%edx
f01018aa:	b8 9b 58 10 f0       	mov    $0xf010589b,%eax
f01018af:	e8 97 f2 ff ff       	call   f0100b4b <_kaddr>

	if (pde & PTE_P) return pte+PTX(va);
f01018b4:	f6 c3 01             	test   $0x1,%bl
f01018b7:	74 0d                	je     f01018c6 <pgdir_walk+0x42>
f01018b9:	c1 ee 0a             	shr    $0xa,%esi
f01018bc:	81 e6 fc 0f 00 00    	and    $0xffc,%esi
f01018c2:	01 f0                	add    %esi,%eax
f01018c4:	eb 51                	jmp    f0101917 <pgdir_walk+0x93>

	if (!create) return NULL;
f01018c6:	b8 00 00 00 00       	mov    $0x0,%eax
f01018cb:	83 7d 10 00          	cmpl   $0x0,0x10(%ebp)
f01018cf:	74 46                	je     f0101917 <pgdir_walk+0x93>
	struct PageInfo *page = page_alloc(ALLOC_ZERO);
f01018d1:	c7 04 24 01 00 00 00 	movl   $0x1,(%esp)
f01018d8:	e8 3d fa ff ff       	call   f010131a <page_alloc>
f01018dd:	89 c3                	mov    %eax,%ebx
	if (page==NULL) return NULL;
f01018df:	85 c0                	test   %eax,%eax
f01018e1:	74 2f                	je     f0101912 <pgdir_walk+0x8e>
	physaddr_t pt_start = page2pa(page);
f01018e3:	e8 ab f1 ff ff       	call   f0100a93 <page2pa>
	page->pp_ref ++;
f01018e8:	66 83 43 04 01       	addw   $0x1,0x4(%ebx)
	*(pgdir+PDX(va)) = pt_start | PTE_P | PTE_U | PTE_W;
f01018ed:	89 c2                	mov    %eax,%edx
f01018ef:	83 ca 07             	or     $0x7,%edx
f01018f2:	89 17                	mov    %edx,(%edi)
	return (pte_t*)KADDR(pt_start)+PTX(va);
f01018f4:	89 c1                	mov    %eax,%ecx
f01018f6:	ba 78 01 00 00       	mov    $0x178,%edx
f01018fb:	b8 9b 58 10 f0       	mov    $0xf010589b,%eax
f0101900:	e8 46 f2 ff ff       	call   f0100b4b <_kaddr>
f0101905:	c1 ee 0a             	shr    $0xa,%esi
f0101908:	81 e6 fc 0f 00 00    	and    $0xffc,%esi
f010190e:	01 f0                	add    %esi,%eax
f0101910:	eb 05                	jmp    f0101917 <pgdir_walk+0x93>

	if (pde & PTE_P) return pte+PTX(va);

	if (!create) return NULL;
	struct PageInfo *page = page_alloc(ALLOC_ZERO);
	if (page==NULL) return NULL;
f0101912:	b8 00 00 00 00       	mov    $0x0,%eax
	physaddr_t pt_start = page2pa(page);
	page->pp_ref ++;
	*(pgdir+PDX(va)) = pt_start | PTE_P | PTE_U | PTE_W;
	return (pte_t*)KADDR(pt_start)+PTX(va);
}
f0101917:	83 c4 1c             	add    $0x1c,%esp
f010191a:	5b                   	pop    %ebx
f010191b:	5e                   	pop    %esi
f010191c:	5f                   	pop    %edi
f010191d:	5d                   	pop    %ebp
f010191e:	c3                   	ret    

f010191f <boot_map_region>:
//
// Hint: the TA solution uses pgdir_walk
//#define TP1_PSE 1
static void
boot_map_region(pde_t *pgdir, uintptr_t va, size_t size, physaddr_t pa, int perm)
{
f010191f:	55                   	push   %ebp
f0101920:	89 e5                	mov    %esp,%ebp
f0101922:	57                   	push   %edi
f0101923:	56                   	push   %esi
f0101924:	53                   	push   %ebx
f0101925:	83 ec 2c             	sub    $0x2c,%esp
f0101928:	89 45 e0             	mov    %eax,-0x20(%ebp)
f010192b:	8b 45 08             	mov    0x8(%ebp),%eax
	assert(va % PGSIZE == 0);
f010192e:	f7 c2 ff 0f 00 00    	test   $0xfff,%edx
f0101934:	74 24                	je     f010195a <boot_map_region+0x3b>
f0101936:	c7 44 24 0c b2 5a 10 	movl   $0xf0105ab2,0xc(%esp)
f010193d:	f0 
f010193e:	c7 44 24 08 ba 58 10 	movl   $0xf01058ba,0x8(%esp)
f0101945:	f0 
f0101946:	c7 44 24 04 8a 01 00 	movl   $0x18a,0x4(%esp)
f010194d:	00 
f010194e:	c7 04 24 9b 58 10 f0 	movl   $0xf010589b,(%esp)
f0101955:	e8 4f e7 ff ff       	call   f01000a9 <_panic>
f010195a:	89 ce                	mov    %ecx,%esi
	assert(pa % PGSIZE == 0);
f010195c:	a9 ff 0f 00 00       	test   $0xfff,%eax
f0101961:	74 24                	je     f0101987 <boot_map_region+0x68>
f0101963:	c7 44 24 0c c3 5a 10 	movl   $0xf0105ac3,0xc(%esp)
f010196a:	f0 
f010196b:	c7 44 24 08 ba 58 10 	movl   $0xf01058ba,0x8(%esp)
f0101972:	f0 
f0101973:	c7 44 24 04 8b 01 00 	movl   $0x18b,0x4(%esp)
f010197a:	00 
f010197b:	c7 04 24 9b 58 10 f0 	movl   $0xf010589b,(%esp)
f0101982:	e8 22 e7 ff ff       	call   f01000a9 <_panic>
	assert(size % PGSIZE == 0);	
f0101987:	f7 c1 ff 0f 00 00    	test   $0xfff,%ecx
f010198d:	75 12                	jne    f01019a1 <boot_map_region+0x82>
f010198f:	89 d3                	mov    %edx,%ebx
f0101991:	29 d0                	sub    %edx,%eax
f0101993:	89 45 e4             	mov    %eax,-0x1c(%ebp)
	//for (int i=0;i<cant_iteraciones;i++){//al ser iteraciones fijas no hay problema de overflow
	//physaddr_t pa_inicial = pa;	
	#ifndef TP1_PSE
		while(size){			
			pte_t* pte_addr = pgdir_walk(pgdir,(void*)va,true);
			*pte_addr = pa | perm | PTE_P;
f0101996:	8b 45 0c             	mov    0xc(%ebp),%eax
f0101999:	83 c8 01             	or     $0x1,%eax
f010199c:	89 45 dc             	mov    %eax,-0x24(%ebp)
f010199f:	eb 4c                	jmp    f01019ed <boot_map_region+0xce>
static void
boot_map_region(pde_t *pgdir, uintptr_t va, size_t size, physaddr_t pa, int perm)
{
	assert(va % PGSIZE == 0);
	assert(pa % PGSIZE == 0);
	assert(size % PGSIZE == 0);	
f01019a1:	c7 44 24 0c d4 5a 10 	movl   $0xf0105ad4,0xc(%esp)
f01019a8:	f0 
f01019a9:	c7 44 24 08 ba 58 10 	movl   $0xf01058ba,0x8(%esp)
f01019b0:	f0 
f01019b1:	c7 44 24 04 8c 01 00 	movl   $0x18c,0x4(%esp)
f01019b8:	00 
f01019b9:	c7 04 24 9b 58 10 f0 	movl   $0xf010589b,(%esp)
f01019c0:	e8 e4 e6 ff ff       	call   f01000a9 <_panic>
	//uint32_t cant_iteraciones = size/PGSIZE;
	//for (int i=0;i<cant_iteraciones;i++){//al ser iteraciones fijas no hay problema de overflow
	//physaddr_t pa_inicial = pa;	
	#ifndef TP1_PSE
		while(size){			
			pte_t* pte_addr = pgdir_walk(pgdir,(void*)va,true);
f01019c5:	c7 44 24 08 01 00 00 	movl   $0x1,0x8(%esp)
f01019cc:	00 
f01019cd:	89 5c 24 04          	mov    %ebx,0x4(%esp)
f01019d1:	8b 45 e0             	mov    -0x20(%ebp),%eax
f01019d4:	89 04 24             	mov    %eax,(%esp)
f01019d7:	e8 a8 fe ff ff       	call   f0101884 <pgdir_walk>
			*pte_addr = pa | perm | PTE_P;
f01019dc:	0b 7d dc             	or     -0x24(%ebp),%edi
f01019df:	89 38                	mov    %edi,(%eax)
			size-=PGSIZE;		
f01019e1:	81 ee 00 10 00 00    	sub    $0x1000,%esi
			//incremento
			va+=PGSIZE;
f01019e7:	81 c3 00 10 00 00    	add    $0x1000,%ebx
f01019ed:	8b 45 e4             	mov    -0x1c(%ebp),%eax
f01019f0:	8d 3c 18             	lea    (%eax,%ebx,1),%edi

	//uint32_t cant_iteraciones = size/PGSIZE;
	//for (int i=0;i<cant_iteraciones;i++){//al ser iteraciones fijas no hay problema de overflow
	//physaddr_t pa_inicial = pa;	
	#ifndef TP1_PSE
		while(size){			
f01019f3:	85 f6                	test   %esi,%esi
f01019f5:	75 ce                	jne    f01019c5 <boot_map_region+0xa6>
				va+=PGSIZE;
				pa+=PGSIZE;
			}
		}
	#endif
}
f01019f7:	83 c4 2c             	add    $0x2c,%esp
f01019fa:	5b                   	pop    %ebx
f01019fb:	5e                   	pop    %esi
f01019fc:	5f                   	pop    %edi
f01019fd:	5d                   	pop    %ebp
f01019fe:	c3                   	ret    

f01019ff <page_lookup>:
//
// Hint: the TA solution uses pgdir_walk and pa2page.
//
struct PageInfo *
page_lookup(pde_t *pgdir, void *va, pte_t **pte_store)
{
f01019ff:	55                   	push   %ebp
f0101a00:	89 e5                	mov    %esp,%ebp
f0101a02:	53                   	push   %ebx
f0101a03:	83 ec 14             	sub    $0x14,%esp
f0101a06:	8b 5d 10             	mov    0x10(%ebp),%ebx
	pte_t* pte_addr = pgdir_walk(pgdir,va,false);
f0101a09:	c7 44 24 08 00 00 00 	movl   $0x0,0x8(%esp)
f0101a10:	00 
f0101a11:	8b 45 0c             	mov    0xc(%ebp),%eax
f0101a14:	89 44 24 04          	mov    %eax,0x4(%esp)
f0101a18:	8b 45 08             	mov    0x8(%ebp),%eax
f0101a1b:	89 04 24             	mov    %eax,(%esp)
f0101a1e:	e8 61 fe ff ff       	call   f0101884 <pgdir_walk>
	if (pte_store) *pte_store = pte_addr;
f0101a23:	85 db                	test   %ebx,%ebx
f0101a25:	74 02                	je     f0101a29 <page_lookup+0x2a>
f0101a27:	89 03                	mov    %eax,(%ebx)
	if (!pte_addr) return NULL;		//no recuerdo si era lazy checking o no, por las dudas dejo asi
f0101a29:	85 c0                	test   %eax,%eax
f0101a2b:	74 1a                	je     f0101a47 <page_lookup+0x48>
	if (!(*pte_addr & PTE_P)) return NULL;
f0101a2d:	8b 10                	mov    (%eax),%edx
f0101a2f:	b8 00 00 00 00       	mov    $0x0,%eax
f0101a34:	f6 c2 01             	test   $0x1,%dl
f0101a37:	74 13                	je     f0101a4c <page_lookup+0x4d>
	physaddr_t pageaddr = PTE_ADDR(*pte_addr);
f0101a39:	89 d0                	mov    %edx,%eax
f0101a3b:	25 00 f0 ff ff       	and    $0xfffff000,%eax
	return pa2page(pageaddr);
f0101a40:	e8 2e f8 ff ff       	call   f0101273 <pa2page>
f0101a45:	eb 05                	jmp    f0101a4c <page_lookup+0x4d>
struct PageInfo *
page_lookup(pde_t *pgdir, void *va, pte_t **pte_store)
{
	pte_t* pte_addr = pgdir_walk(pgdir,va,false);
	if (pte_store) *pte_store = pte_addr;
	if (!pte_addr) return NULL;		//no recuerdo si era lazy checking o no, por las dudas dejo asi
f0101a47:	b8 00 00 00 00       	mov    $0x0,%eax
	if (!(*pte_addr & PTE_P)) return NULL;
	physaddr_t pageaddr = PTE_ADDR(*pte_addr);
	return pa2page(pageaddr);
}
f0101a4c:	83 c4 14             	add    $0x14,%esp
f0101a4f:	5b                   	pop    %ebx
f0101a50:	5d                   	pop    %ebp
f0101a51:	c3                   	ret    

f0101a52 <tlb_invalidate>:
// Invalidate a TLB entry, but only if the page tables being
// edited are the ones currently in use by the processor.
//
void
tlb_invalidate(pde_t *pgdir, void *va)
{
f0101a52:	55                   	push   %ebp
f0101a53:	89 e5                	mov    %esp,%ebp
	// Flush the entry only if we're modifying the current address space.
	// For now, there is only one address space, so always invalidate.
	invlpg(va);
f0101a55:	8b 45 0c             	mov    0xc(%ebp),%eax
f0101a58:	e8 16 f0 ff ff       	call   f0100a73 <invlpg>
}
f0101a5d:	5d                   	pop    %ebp
f0101a5e:	c3                   	ret    

f0101a5f <page_remove>:
// Hint: The TA solution is implemented using page_lookup,
// 	tlb_invalidate, and page_decref.
//
void
page_remove(pde_t *pgdir, void *va)
{
f0101a5f:	55                   	push   %ebp
f0101a60:	89 e5                	mov    %esp,%ebp
f0101a62:	56                   	push   %esi
f0101a63:	53                   	push   %ebx
f0101a64:	83 ec 20             	sub    $0x20,%esp
f0101a67:	8b 5d 08             	mov    0x8(%ebp),%ebx
f0101a6a:	8b 75 0c             	mov    0xc(%ebp),%esi
	pte_t* pte_addr;
	struct PageInfo* page_ptr = page_lookup(pgdir,va,&pte_addr);
f0101a6d:	8d 45 f4             	lea    -0xc(%ebp),%eax
f0101a70:	89 44 24 08          	mov    %eax,0x8(%esp)
f0101a74:	89 74 24 04          	mov    %esi,0x4(%esp)
f0101a78:	89 1c 24             	mov    %ebx,(%esp)
f0101a7b:	e8 7f ff ff ff       	call   f01019ff <page_lookup>
	if (!page_ptr) return;
f0101a80:	85 c0                	test   %eax,%eax
f0101a82:	74 1d                	je     f0101aa1 <page_remove+0x42>
	page_decref(page_ptr);
f0101a84:	89 04 24             	mov    %eax,(%esp)
f0101a87:	e8 d5 fd ff ff       	call   f0101861 <page_decref>
	*pte_addr = 0;
f0101a8c:	8b 45 f4             	mov    -0xc(%ebp),%eax
f0101a8f:	c7 00 00 00 00 00    	movl   $0x0,(%eax)
	tlb_invalidate(pgdir,va);
f0101a95:	89 74 24 04          	mov    %esi,0x4(%esp)
f0101a99:	89 1c 24             	mov    %ebx,(%esp)
f0101a9c:	e8 b1 ff ff ff       	call   f0101a52 <tlb_invalidate>
}
f0101aa1:	83 c4 20             	add    $0x20,%esp
f0101aa4:	5b                   	pop    %ebx
f0101aa5:	5e                   	pop    %esi
f0101aa6:	5d                   	pop    %ebp
f0101aa7:	c3                   	ret    

f0101aa8 <page_insert>:
// Hint: The TA solution is implemented using pgdir_walk, page_remove,
// and page2pa.
//
int
page_insert(pde_t *pgdir, struct PageInfo *pp, void *va, int perm)
{
f0101aa8:	55                   	push   %ebp
f0101aa9:	89 e5                	mov    %esp,%ebp
f0101aab:	57                   	push   %edi
f0101aac:	56                   	push   %esi
f0101aad:	53                   	push   %ebx
f0101aae:	83 ec 1c             	sub    $0x1c,%esp
f0101ab1:	8b 75 0c             	mov    0xc(%ebp),%esi
f0101ab4:	8b 7d 10             	mov    0x10(%ebp),%edi
	pte_t* pte_addr = pgdir_walk(pgdir,va,true);//entra a la PT, si no habia la crea
f0101ab7:	c7 44 24 08 01 00 00 	movl   $0x1,0x8(%esp)
f0101abe:	00 
f0101abf:	89 7c 24 04          	mov    %edi,0x4(%esp)
f0101ac3:	8b 45 08             	mov    0x8(%ebp),%eax
f0101ac6:	89 04 24             	mov    %eax,(%esp)
f0101ac9:	e8 b6 fd ff ff       	call   f0101884 <pgdir_walk>
f0101ace:	89 c3                	mov    %eax,%ebx
	if (!pte_addr) return -E_NO_MEM;	//solo NULL si no habia y no la pudo crear
f0101ad0:	85 c0                	test   %eax,%eax
f0101ad2:	74 31                	je     f0101b05 <page_insert+0x5d>
	//a partir de aca hay pte_addr valida
	pp->pp_ref++;
f0101ad4:	66 83 46 04 01       	addw   $0x1,0x4(%esi)
	if (*pte_addr & PTE_P) page_remove(pgdir,va);
f0101ad9:	f6 00 01             	testb  $0x1,(%eax)
f0101adc:	74 0f                	je     f0101aed <page_insert+0x45>
f0101ade:	89 7c 24 04          	mov    %edi,0x4(%esp)
f0101ae2:	8b 45 08             	mov    0x8(%ebp),%eax
f0101ae5:	89 04 24             	mov    %eax,(%esp)
f0101ae8:	e8 72 ff ff ff       	call   f0101a5f <page_remove>
	*pte_addr = page2pa(pp) | perm | PTE_P;
f0101aed:	89 f0                	mov    %esi,%eax
f0101aef:	e8 9f ef ff ff       	call   f0100a93 <page2pa>
f0101af4:	8b 55 14             	mov    0x14(%ebp),%edx
f0101af7:	83 ca 01             	or     $0x1,%edx
f0101afa:	09 d0                	or     %edx,%eax
f0101afc:	89 03                	mov    %eax,(%ebx)
	return 0;
f0101afe:	b8 00 00 00 00       	mov    $0x0,%eax
f0101b03:	eb 05                	jmp    f0101b0a <page_insert+0x62>
//
int
page_insert(pde_t *pgdir, struct PageInfo *pp, void *va, int perm)
{
	pte_t* pte_addr = pgdir_walk(pgdir,va,true);//entra a la PT, si no habia la crea
	if (!pte_addr) return -E_NO_MEM;	//solo NULL si no habia y no la pudo crear
f0101b05:	b8 fc ff ff ff       	mov    $0xfffffffc,%eax
	//a partir de aca hay pte_addr valida
	pp->pp_ref++;
	if (*pte_addr & PTE_P) page_remove(pgdir,va);
	*pte_addr = page2pa(pp) | perm | PTE_P;
	return 0;
}
f0101b0a:	83 c4 1c             	add    $0x1c,%esp
f0101b0d:	5b                   	pop    %ebx
f0101b0e:	5e                   	pop    %esi
f0101b0f:	5f                   	pop    %edi
f0101b10:	5d                   	pop    %ebp
f0101b11:	c3                   	ret    

f0101b12 <check_page>:


// check page_insert, page_remove, &c
static void
check_page(void)
{
f0101b12:	55                   	push   %ebp
f0101b13:	89 e5                	mov    %esp,%ebp
f0101b15:	57                   	push   %edi
f0101b16:	56                   	push   %esi
f0101b17:	53                   	push   %ebx
f0101b18:	83 ec 3c             	sub    $0x3c,%esp
	int i;
	extern pde_t entry_pgdir[];

	// should be able to allocate three pages
	pp0 = pp1 = pp2 = 0;
	assert((pp0 = page_alloc(0)));
f0101b1b:	c7 04 24 00 00 00 00 	movl   $0x0,(%esp)
f0101b22:	e8 f3 f7 ff ff       	call   f010131a <page_alloc>
f0101b27:	89 45 d4             	mov    %eax,-0x2c(%ebp)
f0101b2a:	85 c0                	test   %eax,%eax
f0101b2c:	75 24                	jne    f0101b52 <check_page+0x40>
f0101b2e:	c7 44 24 0c b5 59 10 	movl   $0xf01059b5,0xc(%esp)
f0101b35:	f0 
f0101b36:	c7 44 24 08 ba 58 10 	movl   $0xf01058ba,0x8(%esp)
f0101b3d:	f0 
f0101b3e:	c7 44 24 04 2f 03 00 	movl   $0x32f,0x4(%esp)
f0101b45:	00 
f0101b46:	c7 04 24 9b 58 10 f0 	movl   $0xf010589b,(%esp)
f0101b4d:	e8 57 e5 ff ff       	call   f01000a9 <_panic>
	assert((pp1 = page_alloc(0)));
f0101b52:	c7 04 24 00 00 00 00 	movl   $0x0,(%esp)
f0101b59:	e8 bc f7 ff ff       	call   f010131a <page_alloc>
f0101b5e:	89 c3                	mov    %eax,%ebx
f0101b60:	85 c0                	test   %eax,%eax
f0101b62:	75 24                	jne    f0101b88 <check_page+0x76>
f0101b64:	c7 44 24 0c cb 59 10 	movl   $0xf01059cb,0xc(%esp)
f0101b6b:	f0 
f0101b6c:	c7 44 24 08 ba 58 10 	movl   $0xf01058ba,0x8(%esp)
f0101b73:	f0 
f0101b74:	c7 44 24 04 30 03 00 	movl   $0x330,0x4(%esp)
f0101b7b:	00 
f0101b7c:	c7 04 24 9b 58 10 f0 	movl   $0xf010589b,(%esp)
f0101b83:	e8 21 e5 ff ff       	call   f01000a9 <_panic>
	assert((pp2 = page_alloc(0)));
f0101b88:	c7 04 24 00 00 00 00 	movl   $0x0,(%esp)
f0101b8f:	e8 86 f7 ff ff       	call   f010131a <page_alloc>
f0101b94:	89 c6                	mov    %eax,%esi
f0101b96:	85 c0                	test   %eax,%eax
f0101b98:	75 24                	jne    f0101bbe <check_page+0xac>
f0101b9a:	c7 44 24 0c e1 59 10 	movl   $0xf01059e1,0xc(%esp)
f0101ba1:	f0 
f0101ba2:	c7 44 24 08 ba 58 10 	movl   $0xf01058ba,0x8(%esp)
f0101ba9:	f0 
f0101baa:	c7 44 24 04 31 03 00 	movl   $0x331,0x4(%esp)
f0101bb1:	00 
f0101bb2:	c7 04 24 9b 58 10 f0 	movl   $0xf010589b,(%esp)
f0101bb9:	e8 eb e4 ff ff       	call   f01000a9 <_panic>

	assert(pp0);
	assert(pp1 && pp1 != pp0);
f0101bbe:	39 5d d4             	cmp    %ebx,-0x2c(%ebp)
f0101bc1:	75 24                	jne    f0101be7 <check_page+0xd5>
f0101bc3:	c7 44 24 0c f7 59 10 	movl   $0xf01059f7,0xc(%esp)
f0101bca:	f0 
f0101bcb:	c7 44 24 08 ba 58 10 	movl   $0xf01058ba,0x8(%esp)
f0101bd2:	f0 
f0101bd3:	c7 44 24 04 34 03 00 	movl   $0x334,0x4(%esp)
f0101bda:	00 
f0101bdb:	c7 04 24 9b 58 10 f0 	movl   $0xf010589b,(%esp)
f0101be2:	e8 c2 e4 ff ff       	call   f01000a9 <_panic>
	assert(pp2 && pp2 != pp1 && pp2 != pp0);
f0101be7:	39 c3                	cmp    %eax,%ebx
f0101be9:	74 05                	je     f0101bf0 <check_page+0xde>
f0101beb:	3b 45 d4             	cmp    -0x2c(%ebp),%eax
f0101bee:	75 24                	jne    f0101c14 <check_page+0x102>
f0101bf0:	c7 44 24 0c 60 53 10 	movl   $0xf0105360,0xc(%esp)
f0101bf7:	f0 
f0101bf8:	c7 44 24 08 ba 58 10 	movl   $0xf01058ba,0x8(%esp)
f0101bff:	f0 
f0101c00:	c7 44 24 04 35 03 00 	movl   $0x335,0x4(%esp)
f0101c07:	00 
f0101c08:	c7 04 24 9b 58 10 f0 	movl   $0xf010589b,(%esp)
f0101c0f:	e8 95 e4 ff ff       	call   f01000a9 <_panic>

	// temporarily steal the rest of the free pages
	fl = page_free_list;
f0101c14:	a1 bc 52 18 f0       	mov    0xf01852bc,%eax
f0101c19:	89 45 cc             	mov    %eax,-0x34(%ebp)
	page_free_list = 0;
f0101c1c:	c7 05 bc 52 18 f0 00 	movl   $0x0,0xf01852bc
f0101c23:	00 00 00 

	// should be no free memory
	assert(!page_alloc(0));
f0101c26:	c7 04 24 00 00 00 00 	movl   $0x0,(%esp)
f0101c2d:	e8 e8 f6 ff ff       	call   f010131a <page_alloc>
f0101c32:	85 c0                	test   %eax,%eax
f0101c34:	74 24                	je     f0101c5a <check_page+0x148>
f0101c36:	c7 44 24 0c 60 5a 10 	movl   $0xf0105a60,0xc(%esp)
f0101c3d:	f0 
f0101c3e:	c7 44 24 08 ba 58 10 	movl   $0xf01058ba,0x8(%esp)
f0101c45:	f0 
f0101c46:	c7 44 24 04 3c 03 00 	movl   $0x33c,0x4(%esp)
f0101c4d:	00 
f0101c4e:	c7 04 24 9b 58 10 f0 	movl   $0xf010589b,(%esp)
f0101c55:	e8 4f e4 ff ff       	call   f01000a9 <_panic>

	// there is no page allocated at address 0
	assert(page_lookup(kern_pgdir, (void *) 0x0, &ptep) == NULL);
f0101c5a:	8d 45 e4             	lea    -0x1c(%ebp),%eax
f0101c5d:	89 44 24 08          	mov    %eax,0x8(%esp)
f0101c61:	c7 44 24 04 00 00 00 	movl   $0x0,0x4(%esp)
f0101c68:	00 
f0101c69:	a1 88 6f 18 f0       	mov    0xf0186f88,%eax
f0101c6e:	89 04 24             	mov    %eax,(%esp)
f0101c71:	e8 89 fd ff ff       	call   f01019ff <page_lookup>
f0101c76:	85 c0                	test   %eax,%eax
f0101c78:	74 24                	je     f0101c9e <check_page+0x18c>
f0101c7a:	c7 44 24 0c a0 53 10 	movl   $0xf01053a0,0xc(%esp)
f0101c81:	f0 
f0101c82:	c7 44 24 08 ba 58 10 	movl   $0xf01058ba,0x8(%esp)
f0101c89:	f0 
f0101c8a:	c7 44 24 04 3f 03 00 	movl   $0x33f,0x4(%esp)
f0101c91:	00 
f0101c92:	c7 04 24 9b 58 10 f0 	movl   $0xf010589b,(%esp)
f0101c99:	e8 0b e4 ff ff       	call   f01000a9 <_panic>

	// there is no free memory, so we can't allocate a page table
	assert(page_insert(kern_pgdir, pp1, 0x0, PTE_W) < 0);
f0101c9e:	c7 44 24 0c 02 00 00 	movl   $0x2,0xc(%esp)
f0101ca5:	00 
f0101ca6:	c7 44 24 08 00 00 00 	movl   $0x0,0x8(%esp)
f0101cad:	00 
f0101cae:	89 5c 24 04          	mov    %ebx,0x4(%esp)
f0101cb2:	a1 88 6f 18 f0       	mov    0xf0186f88,%eax
f0101cb7:	89 04 24             	mov    %eax,(%esp)
f0101cba:	e8 e9 fd ff ff       	call   f0101aa8 <page_insert>
f0101cbf:	85 c0                	test   %eax,%eax
f0101cc1:	78 24                	js     f0101ce7 <check_page+0x1d5>
f0101cc3:	c7 44 24 0c d8 53 10 	movl   $0xf01053d8,0xc(%esp)
f0101cca:	f0 
f0101ccb:	c7 44 24 08 ba 58 10 	movl   $0xf01058ba,0x8(%esp)
f0101cd2:	f0 
f0101cd3:	c7 44 24 04 42 03 00 	movl   $0x342,0x4(%esp)
f0101cda:	00 
f0101cdb:	c7 04 24 9b 58 10 f0 	movl   $0xf010589b,(%esp)
f0101ce2:	e8 c2 e3 ff ff       	call   f01000a9 <_panic>

	// free pp0 and try again: pp0 should be used for page table
	page_free(pp0);
f0101ce7:	8b 45 d4             	mov    -0x2c(%ebp),%eax
f0101cea:	89 04 24             	mov    %eax,(%esp)
f0101ced:	e8 7a f6 ff ff       	call   f010136c <page_free>
	assert(page_insert(kern_pgdir, pp1, 0x0, PTE_W) == 0);
f0101cf2:	c7 44 24 0c 02 00 00 	movl   $0x2,0xc(%esp)
f0101cf9:	00 
f0101cfa:	c7 44 24 08 00 00 00 	movl   $0x0,0x8(%esp)
f0101d01:	00 
f0101d02:	89 5c 24 04          	mov    %ebx,0x4(%esp)
f0101d06:	a1 88 6f 18 f0       	mov    0xf0186f88,%eax
f0101d0b:	89 04 24             	mov    %eax,(%esp)
f0101d0e:	e8 95 fd ff ff       	call   f0101aa8 <page_insert>
f0101d13:	85 c0                	test   %eax,%eax
f0101d15:	74 24                	je     f0101d3b <check_page+0x229>
f0101d17:	c7 44 24 0c 08 54 10 	movl   $0xf0105408,0xc(%esp)
f0101d1e:	f0 
f0101d1f:	c7 44 24 08 ba 58 10 	movl   $0xf01058ba,0x8(%esp)
f0101d26:	f0 
f0101d27:	c7 44 24 04 46 03 00 	movl   $0x346,0x4(%esp)
f0101d2e:	00 
f0101d2f:	c7 04 24 9b 58 10 f0 	movl   $0xf010589b,(%esp)
f0101d36:	e8 6e e3 ff ff       	call   f01000a9 <_panic>
	assert(PTE_ADDR(kern_pgdir[0]) == page2pa(pp0));
f0101d3b:	8b 3d 88 6f 18 f0    	mov    0xf0186f88,%edi
f0101d41:	8b 45 d4             	mov    -0x2c(%ebp),%eax
f0101d44:	e8 4a ed ff ff       	call   f0100a93 <page2pa>
f0101d49:	8b 17                	mov    (%edi),%edx
f0101d4b:	81 e2 00 f0 ff ff    	and    $0xfffff000,%edx
f0101d51:	39 c2                	cmp    %eax,%edx
f0101d53:	74 24                	je     f0101d79 <check_page+0x267>
f0101d55:	c7 44 24 0c 38 54 10 	movl   $0xf0105438,0xc(%esp)
f0101d5c:	f0 
f0101d5d:	c7 44 24 08 ba 58 10 	movl   $0xf01058ba,0x8(%esp)
f0101d64:	f0 
f0101d65:	c7 44 24 04 47 03 00 	movl   $0x347,0x4(%esp)
f0101d6c:	00 
f0101d6d:	c7 04 24 9b 58 10 f0 	movl   $0xf010589b,(%esp)
f0101d74:	e8 30 e3 ff ff       	call   f01000a9 <_panic>
	assert(check_va2pa(kern_pgdir, 0x0) == page2pa(pp1));
f0101d79:	ba 00 00 00 00       	mov    $0x0,%edx
f0101d7e:	89 f8                	mov    %edi,%eax
f0101d80:	e8 1c ee ff ff       	call   f0100ba1 <check_va2pa>
f0101d85:	89 45 d0             	mov    %eax,-0x30(%ebp)
f0101d88:	89 d8                	mov    %ebx,%eax
f0101d8a:	e8 04 ed ff ff       	call   f0100a93 <page2pa>
f0101d8f:	39 45 d0             	cmp    %eax,-0x30(%ebp)
f0101d92:	74 24                	je     f0101db8 <check_page+0x2a6>
f0101d94:	c7 44 24 0c 60 54 10 	movl   $0xf0105460,0xc(%esp)
f0101d9b:	f0 
f0101d9c:	c7 44 24 08 ba 58 10 	movl   $0xf01058ba,0x8(%esp)
f0101da3:	f0 
f0101da4:	c7 44 24 04 48 03 00 	movl   $0x348,0x4(%esp)
f0101dab:	00 
f0101dac:	c7 04 24 9b 58 10 f0 	movl   $0xf010589b,(%esp)
f0101db3:	e8 f1 e2 ff ff       	call   f01000a9 <_panic>
	assert(pp1->pp_ref == 1);
f0101db8:	66 83 7b 04 01       	cmpw   $0x1,0x4(%ebx)
f0101dbd:	74 24                	je     f0101de3 <check_page+0x2d1>
f0101dbf:	c7 44 24 0c e7 5a 10 	movl   $0xf0105ae7,0xc(%esp)
f0101dc6:	f0 
f0101dc7:	c7 44 24 08 ba 58 10 	movl   $0xf01058ba,0x8(%esp)
f0101dce:	f0 
f0101dcf:	c7 44 24 04 49 03 00 	movl   $0x349,0x4(%esp)
f0101dd6:	00 
f0101dd7:	c7 04 24 9b 58 10 f0 	movl   $0xf010589b,(%esp)
f0101dde:	e8 c6 e2 ff ff       	call   f01000a9 <_panic>
	assert(pp0->pp_ref == 1);
f0101de3:	8b 45 d4             	mov    -0x2c(%ebp),%eax
f0101de6:	66 83 78 04 01       	cmpw   $0x1,0x4(%eax)
f0101deb:	74 24                	je     f0101e11 <check_page+0x2ff>
f0101ded:	c7 44 24 0c f8 5a 10 	movl   $0xf0105af8,0xc(%esp)
f0101df4:	f0 
f0101df5:	c7 44 24 08 ba 58 10 	movl   $0xf01058ba,0x8(%esp)
f0101dfc:	f0 
f0101dfd:	c7 44 24 04 4a 03 00 	movl   $0x34a,0x4(%esp)
f0101e04:	00 
f0101e05:	c7 04 24 9b 58 10 f0 	movl   $0xf010589b,(%esp)
f0101e0c:	e8 98 e2 ff ff       	call   f01000a9 <_panic>
	// should be able to map pp2 at PGSIZE because pp0 is already allocated for page table
	assert(page_insert(kern_pgdir, pp2, (void*) PGSIZE, PTE_W) == 0);
f0101e11:	c7 44 24 0c 02 00 00 	movl   $0x2,0xc(%esp)
f0101e18:	00 
f0101e19:	c7 44 24 08 00 10 00 	movl   $0x1000,0x8(%esp)
f0101e20:	00 
f0101e21:	89 74 24 04          	mov    %esi,0x4(%esp)
f0101e25:	89 3c 24             	mov    %edi,(%esp)
f0101e28:	e8 7b fc ff ff       	call   f0101aa8 <page_insert>
f0101e2d:	85 c0                	test   %eax,%eax
f0101e2f:	74 24                	je     f0101e55 <check_page+0x343>
f0101e31:	c7 44 24 0c 90 54 10 	movl   $0xf0105490,0xc(%esp)
f0101e38:	f0 
f0101e39:	c7 44 24 08 ba 58 10 	movl   $0xf01058ba,0x8(%esp)
f0101e40:	f0 
f0101e41:	c7 44 24 04 4c 03 00 	movl   $0x34c,0x4(%esp)
f0101e48:	00 
f0101e49:	c7 04 24 9b 58 10 f0 	movl   $0xf010589b,(%esp)
f0101e50:	e8 54 e2 ff ff       	call   f01000a9 <_panic>
	assert(check_va2pa(kern_pgdir, PGSIZE) == page2pa(pp2));
f0101e55:	ba 00 10 00 00       	mov    $0x1000,%edx
f0101e5a:	a1 88 6f 18 f0       	mov    0xf0186f88,%eax
f0101e5f:	e8 3d ed ff ff       	call   f0100ba1 <check_va2pa>
f0101e64:	89 c7                	mov    %eax,%edi
f0101e66:	89 f0                	mov    %esi,%eax
f0101e68:	e8 26 ec ff ff       	call   f0100a93 <page2pa>
f0101e6d:	39 c7                	cmp    %eax,%edi
f0101e6f:	74 24                	je     f0101e95 <check_page+0x383>
f0101e71:	c7 44 24 0c cc 54 10 	movl   $0xf01054cc,0xc(%esp)
f0101e78:	f0 
f0101e79:	c7 44 24 08 ba 58 10 	movl   $0xf01058ba,0x8(%esp)
f0101e80:	f0 
f0101e81:	c7 44 24 04 4d 03 00 	movl   $0x34d,0x4(%esp)
f0101e88:	00 
f0101e89:	c7 04 24 9b 58 10 f0 	movl   $0xf010589b,(%esp)
f0101e90:	e8 14 e2 ff ff       	call   f01000a9 <_panic>
	assert(pp2->pp_ref == 1);
f0101e95:	66 83 7e 04 01       	cmpw   $0x1,0x4(%esi)
f0101e9a:	74 24                	je     f0101ec0 <check_page+0x3ae>
f0101e9c:	c7 44 24 0c 09 5b 10 	movl   $0xf0105b09,0xc(%esp)
f0101ea3:	f0 
f0101ea4:	c7 44 24 08 ba 58 10 	movl   $0xf01058ba,0x8(%esp)
f0101eab:	f0 
f0101eac:	c7 44 24 04 4e 03 00 	movl   $0x34e,0x4(%esp)
f0101eb3:	00 
f0101eb4:	c7 04 24 9b 58 10 f0 	movl   $0xf010589b,(%esp)
f0101ebb:	e8 e9 e1 ff ff       	call   f01000a9 <_panic>

	// should be no free memory
	assert(!page_alloc(0));
f0101ec0:	c7 04 24 00 00 00 00 	movl   $0x0,(%esp)
f0101ec7:	e8 4e f4 ff ff       	call   f010131a <page_alloc>
f0101ecc:	85 c0                	test   %eax,%eax
f0101ece:	74 24                	je     f0101ef4 <check_page+0x3e2>
f0101ed0:	c7 44 24 0c 60 5a 10 	movl   $0xf0105a60,0xc(%esp)
f0101ed7:	f0 
f0101ed8:	c7 44 24 08 ba 58 10 	movl   $0xf01058ba,0x8(%esp)
f0101edf:	f0 
f0101ee0:	c7 44 24 04 51 03 00 	movl   $0x351,0x4(%esp)
f0101ee7:	00 
f0101ee8:	c7 04 24 9b 58 10 f0 	movl   $0xf010589b,(%esp)
f0101eef:	e8 b5 e1 ff ff       	call   f01000a9 <_panic>

	// should be able to map pp2 at PGSIZE because it's already there
	assert(page_insert(kern_pgdir, pp2, (void*) PGSIZE, PTE_W) == 0);
f0101ef4:	c7 44 24 0c 02 00 00 	movl   $0x2,0xc(%esp)
f0101efb:	00 
f0101efc:	c7 44 24 08 00 10 00 	movl   $0x1000,0x8(%esp)
f0101f03:	00 
f0101f04:	89 74 24 04          	mov    %esi,0x4(%esp)
f0101f08:	a1 88 6f 18 f0       	mov    0xf0186f88,%eax
f0101f0d:	89 04 24             	mov    %eax,(%esp)
f0101f10:	e8 93 fb ff ff       	call   f0101aa8 <page_insert>
f0101f15:	85 c0                	test   %eax,%eax
f0101f17:	74 24                	je     f0101f3d <check_page+0x42b>
f0101f19:	c7 44 24 0c 90 54 10 	movl   $0xf0105490,0xc(%esp)
f0101f20:	f0 
f0101f21:	c7 44 24 08 ba 58 10 	movl   $0xf01058ba,0x8(%esp)
f0101f28:	f0 
f0101f29:	c7 44 24 04 54 03 00 	movl   $0x354,0x4(%esp)
f0101f30:	00 
f0101f31:	c7 04 24 9b 58 10 f0 	movl   $0xf010589b,(%esp)
f0101f38:	e8 6c e1 ff ff       	call   f01000a9 <_panic>
	assert(check_va2pa(kern_pgdir, PGSIZE) == page2pa(pp2));
f0101f3d:	ba 00 10 00 00       	mov    $0x1000,%edx
f0101f42:	a1 88 6f 18 f0       	mov    0xf0186f88,%eax
f0101f47:	e8 55 ec ff ff       	call   f0100ba1 <check_va2pa>
f0101f4c:	89 c7                	mov    %eax,%edi
f0101f4e:	89 f0                	mov    %esi,%eax
f0101f50:	e8 3e eb ff ff       	call   f0100a93 <page2pa>
f0101f55:	39 c7                	cmp    %eax,%edi
f0101f57:	74 24                	je     f0101f7d <check_page+0x46b>
f0101f59:	c7 44 24 0c cc 54 10 	movl   $0xf01054cc,0xc(%esp)
f0101f60:	f0 
f0101f61:	c7 44 24 08 ba 58 10 	movl   $0xf01058ba,0x8(%esp)
f0101f68:	f0 
f0101f69:	c7 44 24 04 55 03 00 	movl   $0x355,0x4(%esp)
f0101f70:	00 
f0101f71:	c7 04 24 9b 58 10 f0 	movl   $0xf010589b,(%esp)
f0101f78:	e8 2c e1 ff ff       	call   f01000a9 <_panic>
	assert(pp2->pp_ref == 1);
f0101f7d:	66 83 7e 04 01       	cmpw   $0x1,0x4(%esi)
f0101f82:	74 24                	je     f0101fa8 <check_page+0x496>
f0101f84:	c7 44 24 0c 09 5b 10 	movl   $0xf0105b09,0xc(%esp)
f0101f8b:	f0 
f0101f8c:	c7 44 24 08 ba 58 10 	movl   $0xf01058ba,0x8(%esp)
f0101f93:	f0 
f0101f94:	c7 44 24 04 56 03 00 	movl   $0x356,0x4(%esp)
f0101f9b:	00 
f0101f9c:	c7 04 24 9b 58 10 f0 	movl   $0xf010589b,(%esp)
f0101fa3:	e8 01 e1 ff ff       	call   f01000a9 <_panic>

	// pp2 should NOT be on the free list
	// could happen in ref counts are handled sloppily in page_insert
	assert(!page_alloc(0));
f0101fa8:	c7 04 24 00 00 00 00 	movl   $0x0,(%esp)
f0101faf:	e8 66 f3 ff ff       	call   f010131a <page_alloc>
f0101fb4:	85 c0                	test   %eax,%eax
f0101fb6:	74 24                	je     f0101fdc <check_page+0x4ca>
f0101fb8:	c7 44 24 0c 60 5a 10 	movl   $0xf0105a60,0xc(%esp)
f0101fbf:	f0 
f0101fc0:	c7 44 24 08 ba 58 10 	movl   $0xf01058ba,0x8(%esp)
f0101fc7:	f0 
f0101fc8:	c7 44 24 04 5a 03 00 	movl   $0x35a,0x4(%esp)
f0101fcf:	00 
f0101fd0:	c7 04 24 9b 58 10 f0 	movl   $0xf010589b,(%esp)
f0101fd7:	e8 cd e0 ff ff       	call   f01000a9 <_panic>

	// check that pgdir_walk returns a pointer to the pte
	ptep = (pte_t *) KADDR(PTE_ADDR(kern_pgdir[PDX(PGSIZE)]));
f0101fdc:	8b 3d 88 6f 18 f0    	mov    0xf0186f88,%edi
f0101fe2:	8b 0f                	mov    (%edi),%ecx
f0101fe4:	81 e1 00 f0 ff ff    	and    $0xfffff000,%ecx
f0101fea:	ba 5d 03 00 00       	mov    $0x35d,%edx
f0101fef:	b8 9b 58 10 f0       	mov    $0xf010589b,%eax
f0101ff4:	e8 52 eb ff ff       	call   f0100b4b <_kaddr>
f0101ff9:	89 45 e4             	mov    %eax,-0x1c(%ebp)
	assert(pgdir_walk(kern_pgdir, (void*)PGSIZE, 0) == ptep+PTX(PGSIZE));
f0101ffc:	c7 44 24 08 00 00 00 	movl   $0x0,0x8(%esp)
f0102003:	00 
f0102004:	c7 44 24 04 00 10 00 	movl   $0x1000,0x4(%esp)
f010200b:	00 
f010200c:	89 3c 24             	mov    %edi,(%esp)
f010200f:	e8 70 f8 ff ff       	call   f0101884 <pgdir_walk>
f0102014:	8b 4d e4             	mov    -0x1c(%ebp),%ecx
f0102017:	8d 51 04             	lea    0x4(%ecx),%edx
f010201a:	39 d0                	cmp    %edx,%eax
f010201c:	74 24                	je     f0102042 <check_page+0x530>
f010201e:	c7 44 24 0c fc 54 10 	movl   $0xf01054fc,0xc(%esp)
f0102025:	f0 
f0102026:	c7 44 24 08 ba 58 10 	movl   $0xf01058ba,0x8(%esp)
f010202d:	f0 
f010202e:	c7 44 24 04 5e 03 00 	movl   $0x35e,0x4(%esp)
f0102035:	00 
f0102036:	c7 04 24 9b 58 10 f0 	movl   $0xf010589b,(%esp)
f010203d:	e8 67 e0 ff ff       	call   f01000a9 <_panic>

	// should be able to change permissions too.
	assert(page_insert(kern_pgdir, pp2, (void*) PGSIZE, PTE_W|PTE_U) == 0);
f0102042:	c7 44 24 0c 06 00 00 	movl   $0x6,0xc(%esp)
f0102049:	00 
f010204a:	c7 44 24 08 00 10 00 	movl   $0x1000,0x8(%esp)
f0102051:	00 
f0102052:	89 74 24 04          	mov    %esi,0x4(%esp)
f0102056:	a1 88 6f 18 f0       	mov    0xf0186f88,%eax
f010205b:	89 04 24             	mov    %eax,(%esp)
f010205e:	e8 45 fa ff ff       	call   f0101aa8 <page_insert>
f0102063:	85 c0                	test   %eax,%eax
f0102065:	74 24                	je     f010208b <check_page+0x579>
f0102067:	c7 44 24 0c 3c 55 10 	movl   $0xf010553c,0xc(%esp)
f010206e:	f0 
f010206f:	c7 44 24 08 ba 58 10 	movl   $0xf01058ba,0x8(%esp)
f0102076:	f0 
f0102077:	c7 44 24 04 61 03 00 	movl   $0x361,0x4(%esp)
f010207e:	00 
f010207f:	c7 04 24 9b 58 10 f0 	movl   $0xf010589b,(%esp)
f0102086:	e8 1e e0 ff ff       	call   f01000a9 <_panic>
	assert(check_va2pa(kern_pgdir, PGSIZE) == page2pa(pp2));
f010208b:	8b 3d 88 6f 18 f0    	mov    0xf0186f88,%edi
f0102091:	ba 00 10 00 00       	mov    $0x1000,%edx
f0102096:	89 f8                	mov    %edi,%eax
f0102098:	e8 04 eb ff ff       	call   f0100ba1 <check_va2pa>
f010209d:	89 45 d0             	mov    %eax,-0x30(%ebp)
f01020a0:	89 f0                	mov    %esi,%eax
f01020a2:	e8 ec e9 ff ff       	call   f0100a93 <page2pa>
f01020a7:	39 45 d0             	cmp    %eax,-0x30(%ebp)
f01020aa:	74 24                	je     f01020d0 <check_page+0x5be>
f01020ac:	c7 44 24 0c cc 54 10 	movl   $0xf01054cc,0xc(%esp)
f01020b3:	f0 
f01020b4:	c7 44 24 08 ba 58 10 	movl   $0xf01058ba,0x8(%esp)
f01020bb:	f0 
f01020bc:	c7 44 24 04 62 03 00 	movl   $0x362,0x4(%esp)
f01020c3:	00 
f01020c4:	c7 04 24 9b 58 10 f0 	movl   $0xf010589b,(%esp)
f01020cb:	e8 d9 df ff ff       	call   f01000a9 <_panic>
	assert(pp2->pp_ref == 1);
f01020d0:	66 83 7e 04 01       	cmpw   $0x1,0x4(%esi)
f01020d5:	74 24                	je     f01020fb <check_page+0x5e9>
f01020d7:	c7 44 24 0c 09 5b 10 	movl   $0xf0105b09,0xc(%esp)
f01020de:	f0 
f01020df:	c7 44 24 08 ba 58 10 	movl   $0xf01058ba,0x8(%esp)
f01020e6:	f0 
f01020e7:	c7 44 24 04 63 03 00 	movl   $0x363,0x4(%esp)
f01020ee:	00 
f01020ef:	c7 04 24 9b 58 10 f0 	movl   $0xf010589b,(%esp)
f01020f6:	e8 ae df ff ff       	call   f01000a9 <_panic>
	assert(*pgdir_walk(kern_pgdir, (void*) PGSIZE, 0) & PTE_U);
f01020fb:	c7 44 24 08 00 00 00 	movl   $0x0,0x8(%esp)
f0102102:	00 
f0102103:	c7 44 24 04 00 10 00 	movl   $0x1000,0x4(%esp)
f010210a:	00 
f010210b:	89 3c 24             	mov    %edi,(%esp)
f010210e:	e8 71 f7 ff ff       	call   f0101884 <pgdir_walk>
f0102113:	f6 00 04             	testb  $0x4,(%eax)
f0102116:	75 24                	jne    f010213c <check_page+0x62a>
f0102118:	c7 44 24 0c 7c 55 10 	movl   $0xf010557c,0xc(%esp)
f010211f:	f0 
f0102120:	c7 44 24 08 ba 58 10 	movl   $0xf01058ba,0x8(%esp)
f0102127:	f0 
f0102128:	c7 44 24 04 64 03 00 	movl   $0x364,0x4(%esp)
f010212f:	00 
f0102130:	c7 04 24 9b 58 10 f0 	movl   $0xf010589b,(%esp)
f0102137:	e8 6d df ff ff       	call   f01000a9 <_panic>
	assert(kern_pgdir[0] & PTE_U);
f010213c:	a1 88 6f 18 f0       	mov    0xf0186f88,%eax
f0102141:	f6 00 04             	testb  $0x4,(%eax)
f0102144:	75 24                	jne    f010216a <check_page+0x658>
f0102146:	c7 44 24 0c 1a 5b 10 	movl   $0xf0105b1a,0xc(%esp)
f010214d:	f0 
f010214e:	c7 44 24 08 ba 58 10 	movl   $0xf01058ba,0x8(%esp)
f0102155:	f0 
f0102156:	c7 44 24 04 65 03 00 	movl   $0x365,0x4(%esp)
f010215d:	00 
f010215e:	c7 04 24 9b 58 10 f0 	movl   $0xf010589b,(%esp)
f0102165:	e8 3f df ff ff       	call   f01000a9 <_panic>

	// should be able to remap with fewer permissions
	assert(page_insert(kern_pgdir, pp2, (void*) PGSIZE, PTE_W) == 0);
f010216a:	c7 44 24 0c 02 00 00 	movl   $0x2,0xc(%esp)
f0102171:	00 
f0102172:	c7 44 24 08 00 10 00 	movl   $0x1000,0x8(%esp)
f0102179:	00 
f010217a:	89 74 24 04          	mov    %esi,0x4(%esp)
f010217e:	89 04 24             	mov    %eax,(%esp)
f0102181:	e8 22 f9 ff ff       	call   f0101aa8 <page_insert>
f0102186:	85 c0                	test   %eax,%eax
f0102188:	74 24                	je     f01021ae <check_page+0x69c>
f010218a:	c7 44 24 0c 90 54 10 	movl   $0xf0105490,0xc(%esp)
f0102191:	f0 
f0102192:	c7 44 24 08 ba 58 10 	movl   $0xf01058ba,0x8(%esp)
f0102199:	f0 
f010219a:	c7 44 24 04 68 03 00 	movl   $0x368,0x4(%esp)
f01021a1:	00 
f01021a2:	c7 04 24 9b 58 10 f0 	movl   $0xf010589b,(%esp)
f01021a9:	e8 fb de ff ff       	call   f01000a9 <_panic>
	assert(*pgdir_walk(kern_pgdir, (void*) PGSIZE, 0) & PTE_W);
f01021ae:	c7 44 24 08 00 00 00 	movl   $0x0,0x8(%esp)
f01021b5:	00 
f01021b6:	c7 44 24 04 00 10 00 	movl   $0x1000,0x4(%esp)
f01021bd:	00 
f01021be:	a1 88 6f 18 f0       	mov    0xf0186f88,%eax
f01021c3:	89 04 24             	mov    %eax,(%esp)
f01021c6:	e8 b9 f6 ff ff       	call   f0101884 <pgdir_walk>
f01021cb:	f6 00 02             	testb  $0x2,(%eax)
f01021ce:	75 24                	jne    f01021f4 <check_page+0x6e2>
f01021d0:	c7 44 24 0c b0 55 10 	movl   $0xf01055b0,0xc(%esp)
f01021d7:	f0 
f01021d8:	c7 44 24 08 ba 58 10 	movl   $0xf01058ba,0x8(%esp)
f01021df:	f0 
f01021e0:	c7 44 24 04 69 03 00 	movl   $0x369,0x4(%esp)
f01021e7:	00 
f01021e8:	c7 04 24 9b 58 10 f0 	movl   $0xf010589b,(%esp)
f01021ef:	e8 b5 de ff ff       	call   f01000a9 <_panic>
	assert(!(*pgdir_walk(kern_pgdir, (void*) PGSIZE, 0) & PTE_U));
f01021f4:	c7 44 24 08 00 00 00 	movl   $0x0,0x8(%esp)
f01021fb:	00 
f01021fc:	c7 44 24 04 00 10 00 	movl   $0x1000,0x4(%esp)
f0102203:	00 
f0102204:	a1 88 6f 18 f0       	mov    0xf0186f88,%eax
f0102209:	89 04 24             	mov    %eax,(%esp)
f010220c:	e8 73 f6 ff ff       	call   f0101884 <pgdir_walk>
f0102211:	f6 00 04             	testb  $0x4,(%eax)
f0102214:	74 24                	je     f010223a <check_page+0x728>
f0102216:	c7 44 24 0c e4 55 10 	movl   $0xf01055e4,0xc(%esp)
f010221d:	f0 
f010221e:	c7 44 24 08 ba 58 10 	movl   $0xf01058ba,0x8(%esp)
f0102225:	f0 
f0102226:	c7 44 24 04 6a 03 00 	movl   $0x36a,0x4(%esp)
f010222d:	00 
f010222e:	c7 04 24 9b 58 10 f0 	movl   $0xf010589b,(%esp)
f0102235:	e8 6f de ff ff       	call   f01000a9 <_panic>

	// should not be able to map at PTSIZE because need free page for page table
	assert(page_insert(kern_pgdir, pp0, (void*) PTSIZE, PTE_W) < 0);
f010223a:	c7 44 24 0c 02 00 00 	movl   $0x2,0xc(%esp)
f0102241:	00 
f0102242:	c7 44 24 08 00 00 40 	movl   $0x400000,0x8(%esp)
f0102249:	00 
f010224a:	8b 45 d4             	mov    -0x2c(%ebp),%eax
f010224d:	89 44 24 04          	mov    %eax,0x4(%esp)
f0102251:	a1 88 6f 18 f0       	mov    0xf0186f88,%eax
f0102256:	89 04 24             	mov    %eax,(%esp)
f0102259:	e8 4a f8 ff ff       	call   f0101aa8 <page_insert>
f010225e:	85 c0                	test   %eax,%eax
f0102260:	78 24                	js     f0102286 <check_page+0x774>
f0102262:	c7 44 24 0c 1c 56 10 	movl   $0xf010561c,0xc(%esp)
f0102269:	f0 
f010226a:	c7 44 24 08 ba 58 10 	movl   $0xf01058ba,0x8(%esp)
f0102271:	f0 
f0102272:	c7 44 24 04 6d 03 00 	movl   $0x36d,0x4(%esp)
f0102279:	00 
f010227a:	c7 04 24 9b 58 10 f0 	movl   $0xf010589b,(%esp)
f0102281:	e8 23 de ff ff       	call   f01000a9 <_panic>

	// insert pp1 at PGSIZE (replacing pp2)
	assert(page_insert(kern_pgdir, pp1, (void*) PGSIZE, PTE_W) == 0);
f0102286:	c7 44 24 0c 02 00 00 	movl   $0x2,0xc(%esp)
f010228d:	00 
f010228e:	c7 44 24 08 00 10 00 	movl   $0x1000,0x8(%esp)
f0102295:	00 
f0102296:	89 5c 24 04          	mov    %ebx,0x4(%esp)
f010229a:	a1 88 6f 18 f0       	mov    0xf0186f88,%eax
f010229f:	89 04 24             	mov    %eax,(%esp)
f01022a2:	e8 01 f8 ff ff       	call   f0101aa8 <page_insert>
f01022a7:	85 c0                	test   %eax,%eax
f01022a9:	74 24                	je     f01022cf <check_page+0x7bd>
f01022ab:	c7 44 24 0c 54 56 10 	movl   $0xf0105654,0xc(%esp)
f01022b2:	f0 
f01022b3:	c7 44 24 08 ba 58 10 	movl   $0xf01058ba,0x8(%esp)
f01022ba:	f0 
f01022bb:	c7 44 24 04 70 03 00 	movl   $0x370,0x4(%esp)
f01022c2:	00 
f01022c3:	c7 04 24 9b 58 10 f0 	movl   $0xf010589b,(%esp)
f01022ca:	e8 da dd ff ff       	call   f01000a9 <_panic>
	assert(!(*pgdir_walk(kern_pgdir, (void*) PGSIZE, 0) & PTE_U));
f01022cf:	c7 44 24 08 00 00 00 	movl   $0x0,0x8(%esp)
f01022d6:	00 
f01022d7:	c7 44 24 04 00 10 00 	movl   $0x1000,0x4(%esp)
f01022de:	00 
f01022df:	a1 88 6f 18 f0       	mov    0xf0186f88,%eax
f01022e4:	89 04 24             	mov    %eax,(%esp)
f01022e7:	e8 98 f5 ff ff       	call   f0101884 <pgdir_walk>
f01022ec:	f6 00 04             	testb  $0x4,(%eax)
f01022ef:	74 24                	je     f0102315 <check_page+0x803>
f01022f1:	c7 44 24 0c e4 55 10 	movl   $0xf01055e4,0xc(%esp)
f01022f8:	f0 
f01022f9:	c7 44 24 08 ba 58 10 	movl   $0xf01058ba,0x8(%esp)
f0102300:	f0 
f0102301:	c7 44 24 04 71 03 00 	movl   $0x371,0x4(%esp)
f0102308:	00 
f0102309:	c7 04 24 9b 58 10 f0 	movl   $0xf010589b,(%esp)
f0102310:	e8 94 dd ff ff       	call   f01000a9 <_panic>

	// should have pp1 at both 0 and PGSIZE, pp2 nowhere, ...
	assert(check_va2pa(kern_pgdir, 0) == page2pa(pp1));
f0102315:	8b 3d 88 6f 18 f0    	mov    0xf0186f88,%edi
f010231b:	ba 00 00 00 00       	mov    $0x0,%edx
f0102320:	89 f8                	mov    %edi,%eax
f0102322:	e8 7a e8 ff ff       	call   f0100ba1 <check_va2pa>
f0102327:	89 45 d0             	mov    %eax,-0x30(%ebp)
f010232a:	89 d8                	mov    %ebx,%eax
f010232c:	e8 62 e7 ff ff       	call   f0100a93 <page2pa>
f0102331:	39 45 d0             	cmp    %eax,-0x30(%ebp)
f0102334:	74 24                	je     f010235a <check_page+0x848>
f0102336:	c7 44 24 0c 90 56 10 	movl   $0xf0105690,0xc(%esp)
f010233d:	f0 
f010233e:	c7 44 24 08 ba 58 10 	movl   $0xf01058ba,0x8(%esp)
f0102345:	f0 
f0102346:	c7 44 24 04 74 03 00 	movl   $0x374,0x4(%esp)
f010234d:	00 
f010234e:	c7 04 24 9b 58 10 f0 	movl   $0xf010589b,(%esp)
f0102355:	e8 4f dd ff ff       	call   f01000a9 <_panic>
	assert(check_va2pa(kern_pgdir, PGSIZE) == page2pa(pp1));
f010235a:	ba 00 10 00 00       	mov    $0x1000,%edx
f010235f:	89 f8                	mov    %edi,%eax
f0102361:	e8 3b e8 ff ff       	call   f0100ba1 <check_va2pa>
f0102366:	39 45 d0             	cmp    %eax,-0x30(%ebp)
f0102369:	74 24                	je     f010238f <check_page+0x87d>
f010236b:	c7 44 24 0c bc 56 10 	movl   $0xf01056bc,0xc(%esp)
f0102372:	f0 
f0102373:	c7 44 24 08 ba 58 10 	movl   $0xf01058ba,0x8(%esp)
f010237a:	f0 
f010237b:	c7 44 24 04 75 03 00 	movl   $0x375,0x4(%esp)
f0102382:	00 
f0102383:	c7 04 24 9b 58 10 f0 	movl   $0xf010589b,(%esp)
f010238a:	e8 1a dd ff ff       	call   f01000a9 <_panic>
	// ... and ref counts should reflect this
	assert(pp1->pp_ref == 2);
f010238f:	66 83 7b 04 02       	cmpw   $0x2,0x4(%ebx)
f0102394:	74 24                	je     f01023ba <check_page+0x8a8>
f0102396:	c7 44 24 0c 30 5b 10 	movl   $0xf0105b30,0xc(%esp)
f010239d:	f0 
f010239e:	c7 44 24 08 ba 58 10 	movl   $0xf01058ba,0x8(%esp)
f01023a5:	f0 
f01023a6:	c7 44 24 04 77 03 00 	movl   $0x377,0x4(%esp)
f01023ad:	00 
f01023ae:	c7 04 24 9b 58 10 f0 	movl   $0xf010589b,(%esp)
f01023b5:	e8 ef dc ff ff       	call   f01000a9 <_panic>
	assert(pp2->pp_ref == 0);
f01023ba:	66 83 7e 04 00       	cmpw   $0x0,0x4(%esi)
f01023bf:	74 24                	je     f01023e5 <check_page+0x8d3>
f01023c1:	c7 44 24 0c 41 5b 10 	movl   $0xf0105b41,0xc(%esp)
f01023c8:	f0 
f01023c9:	c7 44 24 08 ba 58 10 	movl   $0xf01058ba,0x8(%esp)
f01023d0:	f0 
f01023d1:	c7 44 24 04 78 03 00 	movl   $0x378,0x4(%esp)
f01023d8:	00 
f01023d9:	c7 04 24 9b 58 10 f0 	movl   $0xf010589b,(%esp)
f01023e0:	e8 c4 dc ff ff       	call   f01000a9 <_panic>

	// pp2 should be returned by page_alloc
	assert((pp = page_alloc(0)) && pp == pp2);
f01023e5:	c7 04 24 00 00 00 00 	movl   $0x0,(%esp)
f01023ec:	e8 29 ef ff ff       	call   f010131a <page_alloc>
f01023f1:	89 c7                	mov    %eax,%edi
f01023f3:	85 c0                	test   %eax,%eax
f01023f5:	74 04                	je     f01023fb <check_page+0x8e9>
f01023f7:	39 f0                	cmp    %esi,%eax
f01023f9:	74 24                	je     f010241f <check_page+0x90d>
f01023fb:	c7 44 24 0c ec 56 10 	movl   $0xf01056ec,0xc(%esp)
f0102402:	f0 
f0102403:	c7 44 24 08 ba 58 10 	movl   $0xf01058ba,0x8(%esp)
f010240a:	f0 
f010240b:	c7 44 24 04 7b 03 00 	movl   $0x37b,0x4(%esp)
f0102412:	00 
f0102413:	c7 04 24 9b 58 10 f0 	movl   $0xf010589b,(%esp)
f010241a:	e8 8a dc ff ff       	call   f01000a9 <_panic>

	// unmapping pp1 at 0 should keep pp1 at PGSIZE
	page_remove(kern_pgdir, 0x0);
f010241f:	c7 44 24 04 00 00 00 	movl   $0x0,0x4(%esp)
f0102426:	00 
f0102427:	a1 88 6f 18 f0       	mov    0xf0186f88,%eax
f010242c:	89 04 24             	mov    %eax,(%esp)
f010242f:	e8 2b f6 ff ff       	call   f0101a5f <page_remove>
	assert(check_va2pa(kern_pgdir, 0x0) == ~0);
f0102434:	8b 35 88 6f 18 f0    	mov    0xf0186f88,%esi
f010243a:	ba 00 00 00 00       	mov    $0x0,%edx
f010243f:	89 f0                	mov    %esi,%eax
f0102441:	e8 5b e7 ff ff       	call   f0100ba1 <check_va2pa>
f0102446:	83 f8 ff             	cmp    $0xffffffff,%eax
f0102449:	74 24                	je     f010246f <check_page+0x95d>
f010244b:	c7 44 24 0c 10 57 10 	movl   $0xf0105710,0xc(%esp)
f0102452:	f0 
f0102453:	c7 44 24 08 ba 58 10 	movl   $0xf01058ba,0x8(%esp)
f010245a:	f0 
f010245b:	c7 44 24 04 7f 03 00 	movl   $0x37f,0x4(%esp)
f0102462:	00 
f0102463:	c7 04 24 9b 58 10 f0 	movl   $0xf010589b,(%esp)
f010246a:	e8 3a dc ff ff       	call   f01000a9 <_panic>
	assert(check_va2pa(kern_pgdir, PGSIZE) == page2pa(pp1));
f010246f:	ba 00 10 00 00       	mov    $0x1000,%edx
f0102474:	89 f0                	mov    %esi,%eax
f0102476:	e8 26 e7 ff ff       	call   f0100ba1 <check_va2pa>
f010247b:	89 45 d0             	mov    %eax,-0x30(%ebp)
f010247e:	89 d8                	mov    %ebx,%eax
f0102480:	e8 0e e6 ff ff       	call   f0100a93 <page2pa>
f0102485:	39 45 d0             	cmp    %eax,-0x30(%ebp)
f0102488:	74 24                	je     f01024ae <check_page+0x99c>
f010248a:	c7 44 24 0c bc 56 10 	movl   $0xf01056bc,0xc(%esp)
f0102491:	f0 
f0102492:	c7 44 24 08 ba 58 10 	movl   $0xf01058ba,0x8(%esp)
f0102499:	f0 
f010249a:	c7 44 24 04 80 03 00 	movl   $0x380,0x4(%esp)
f01024a1:	00 
f01024a2:	c7 04 24 9b 58 10 f0 	movl   $0xf010589b,(%esp)
f01024a9:	e8 fb db ff ff       	call   f01000a9 <_panic>
	assert(pp1->pp_ref == 1);
f01024ae:	66 83 7b 04 01       	cmpw   $0x1,0x4(%ebx)
f01024b3:	74 24                	je     f01024d9 <check_page+0x9c7>
f01024b5:	c7 44 24 0c e7 5a 10 	movl   $0xf0105ae7,0xc(%esp)
f01024bc:	f0 
f01024bd:	c7 44 24 08 ba 58 10 	movl   $0xf01058ba,0x8(%esp)
f01024c4:	f0 
f01024c5:	c7 44 24 04 81 03 00 	movl   $0x381,0x4(%esp)
f01024cc:	00 
f01024cd:	c7 04 24 9b 58 10 f0 	movl   $0xf010589b,(%esp)
f01024d4:	e8 d0 db ff ff       	call   f01000a9 <_panic>
	assert(pp2->pp_ref == 0);
f01024d9:	66 83 7f 04 00       	cmpw   $0x0,0x4(%edi)
f01024de:	74 24                	je     f0102504 <check_page+0x9f2>
f01024e0:	c7 44 24 0c 41 5b 10 	movl   $0xf0105b41,0xc(%esp)
f01024e7:	f0 
f01024e8:	c7 44 24 08 ba 58 10 	movl   $0xf01058ba,0x8(%esp)
f01024ef:	f0 
f01024f0:	c7 44 24 04 82 03 00 	movl   $0x382,0x4(%esp)
f01024f7:	00 
f01024f8:	c7 04 24 9b 58 10 f0 	movl   $0xf010589b,(%esp)
f01024ff:	e8 a5 db ff ff       	call   f01000a9 <_panic>

	// test re-inserting pp1 at PGSIZE
	assert(page_insert(kern_pgdir, pp1, (void*) PGSIZE, 0) == 0);
f0102504:	c7 44 24 0c 00 00 00 	movl   $0x0,0xc(%esp)
f010250b:	00 
f010250c:	c7 44 24 08 00 10 00 	movl   $0x1000,0x8(%esp)
f0102513:	00 
f0102514:	89 5c 24 04          	mov    %ebx,0x4(%esp)
f0102518:	89 34 24             	mov    %esi,(%esp)
f010251b:	e8 88 f5 ff ff       	call   f0101aa8 <page_insert>
f0102520:	85 c0                	test   %eax,%eax
f0102522:	74 24                	je     f0102548 <check_page+0xa36>
f0102524:	c7 44 24 0c 34 57 10 	movl   $0xf0105734,0xc(%esp)
f010252b:	f0 
f010252c:	c7 44 24 08 ba 58 10 	movl   $0xf01058ba,0x8(%esp)
f0102533:	f0 
f0102534:	c7 44 24 04 85 03 00 	movl   $0x385,0x4(%esp)
f010253b:	00 
f010253c:	c7 04 24 9b 58 10 f0 	movl   $0xf010589b,(%esp)
f0102543:	e8 61 db ff ff       	call   f01000a9 <_panic>
	assert(pp1->pp_ref);
f0102548:	66 83 7b 04 00       	cmpw   $0x0,0x4(%ebx)
f010254d:	75 24                	jne    f0102573 <check_page+0xa61>
f010254f:	c7 44 24 0c 52 5b 10 	movl   $0xf0105b52,0xc(%esp)
f0102556:	f0 
f0102557:	c7 44 24 08 ba 58 10 	movl   $0xf01058ba,0x8(%esp)
f010255e:	f0 
f010255f:	c7 44 24 04 86 03 00 	movl   $0x386,0x4(%esp)
f0102566:	00 
f0102567:	c7 04 24 9b 58 10 f0 	movl   $0xf010589b,(%esp)
f010256e:	e8 36 db ff ff       	call   f01000a9 <_panic>
	assert(pp1->pp_link == NULL);
f0102573:	83 3b 00             	cmpl   $0x0,(%ebx)
f0102576:	74 24                	je     f010259c <check_page+0xa8a>
f0102578:	c7 44 24 0c 5e 5b 10 	movl   $0xf0105b5e,0xc(%esp)
f010257f:	f0 
f0102580:	c7 44 24 08 ba 58 10 	movl   $0xf01058ba,0x8(%esp)
f0102587:	f0 
f0102588:	c7 44 24 04 87 03 00 	movl   $0x387,0x4(%esp)
f010258f:	00 
f0102590:	c7 04 24 9b 58 10 f0 	movl   $0xf010589b,(%esp)
f0102597:	e8 0d db ff ff       	call   f01000a9 <_panic>

	// unmapping pp1 at PGSIZE should free it
	page_remove(kern_pgdir, (void*) PGSIZE);
f010259c:	c7 44 24 04 00 10 00 	movl   $0x1000,0x4(%esp)
f01025a3:	00 
f01025a4:	a1 88 6f 18 f0       	mov    0xf0186f88,%eax
f01025a9:	89 04 24             	mov    %eax,(%esp)
f01025ac:	e8 ae f4 ff ff       	call   f0101a5f <page_remove>
	assert(check_va2pa(kern_pgdir, 0x0) == ~0);
f01025b1:	8b 35 88 6f 18 f0    	mov    0xf0186f88,%esi
f01025b7:	ba 00 00 00 00       	mov    $0x0,%edx
f01025bc:	89 f0                	mov    %esi,%eax
f01025be:	e8 de e5 ff ff       	call   f0100ba1 <check_va2pa>
f01025c3:	83 f8 ff             	cmp    $0xffffffff,%eax
f01025c6:	74 24                	je     f01025ec <check_page+0xada>
f01025c8:	c7 44 24 0c 10 57 10 	movl   $0xf0105710,0xc(%esp)
f01025cf:	f0 
f01025d0:	c7 44 24 08 ba 58 10 	movl   $0xf01058ba,0x8(%esp)
f01025d7:	f0 
f01025d8:	c7 44 24 04 8b 03 00 	movl   $0x38b,0x4(%esp)
f01025df:	00 
f01025e0:	c7 04 24 9b 58 10 f0 	movl   $0xf010589b,(%esp)
f01025e7:	e8 bd da ff ff       	call   f01000a9 <_panic>
	assert(check_va2pa(kern_pgdir, PGSIZE) == ~0);
f01025ec:	ba 00 10 00 00       	mov    $0x1000,%edx
f01025f1:	89 f0                	mov    %esi,%eax
f01025f3:	e8 a9 e5 ff ff       	call   f0100ba1 <check_va2pa>
f01025f8:	83 f8 ff             	cmp    $0xffffffff,%eax
f01025fb:	74 24                	je     f0102621 <check_page+0xb0f>
f01025fd:	c7 44 24 0c 6c 57 10 	movl   $0xf010576c,0xc(%esp)
f0102604:	f0 
f0102605:	c7 44 24 08 ba 58 10 	movl   $0xf01058ba,0x8(%esp)
f010260c:	f0 
f010260d:	c7 44 24 04 8c 03 00 	movl   $0x38c,0x4(%esp)
f0102614:	00 
f0102615:	c7 04 24 9b 58 10 f0 	movl   $0xf010589b,(%esp)
f010261c:	e8 88 da ff ff       	call   f01000a9 <_panic>
	assert(pp1->pp_ref == 0);
f0102621:	66 83 7b 04 00       	cmpw   $0x0,0x4(%ebx)
f0102626:	74 24                	je     f010264c <check_page+0xb3a>
f0102628:	c7 44 24 0c 73 5b 10 	movl   $0xf0105b73,0xc(%esp)
f010262f:	f0 
f0102630:	c7 44 24 08 ba 58 10 	movl   $0xf01058ba,0x8(%esp)
f0102637:	f0 
f0102638:	c7 44 24 04 8d 03 00 	movl   $0x38d,0x4(%esp)
f010263f:	00 
f0102640:	c7 04 24 9b 58 10 f0 	movl   $0xf010589b,(%esp)
f0102647:	e8 5d da ff ff       	call   f01000a9 <_panic>
	assert(pp2->pp_ref == 0);
f010264c:	66 83 7f 04 00       	cmpw   $0x0,0x4(%edi)
f0102651:	74 24                	je     f0102677 <check_page+0xb65>
f0102653:	c7 44 24 0c 41 5b 10 	movl   $0xf0105b41,0xc(%esp)
f010265a:	f0 
f010265b:	c7 44 24 08 ba 58 10 	movl   $0xf01058ba,0x8(%esp)
f0102662:	f0 
f0102663:	c7 44 24 04 8e 03 00 	movl   $0x38e,0x4(%esp)
f010266a:	00 
f010266b:	c7 04 24 9b 58 10 f0 	movl   $0xf010589b,(%esp)
f0102672:	e8 32 da ff ff       	call   f01000a9 <_panic>

	// so it should be returned by page_alloc
	assert((pp = page_alloc(0)) && pp == pp1);
f0102677:	c7 04 24 00 00 00 00 	movl   $0x0,(%esp)
f010267e:	e8 97 ec ff ff       	call   f010131a <page_alloc>
f0102683:	89 c6                	mov    %eax,%esi
f0102685:	85 c0                	test   %eax,%eax
f0102687:	74 04                	je     f010268d <check_page+0xb7b>
f0102689:	39 d8                	cmp    %ebx,%eax
f010268b:	74 24                	je     f01026b1 <check_page+0xb9f>
f010268d:	c7 44 24 0c 94 57 10 	movl   $0xf0105794,0xc(%esp)
f0102694:	f0 
f0102695:	c7 44 24 08 ba 58 10 	movl   $0xf01058ba,0x8(%esp)
f010269c:	f0 
f010269d:	c7 44 24 04 91 03 00 	movl   $0x391,0x4(%esp)
f01026a4:	00 
f01026a5:	c7 04 24 9b 58 10 f0 	movl   $0xf010589b,(%esp)
f01026ac:	e8 f8 d9 ff ff       	call   f01000a9 <_panic>

	// should be no free memory
	assert(!page_alloc(0));
f01026b1:	c7 04 24 00 00 00 00 	movl   $0x0,(%esp)
f01026b8:	e8 5d ec ff ff       	call   f010131a <page_alloc>
f01026bd:	85 c0                	test   %eax,%eax
f01026bf:	74 24                	je     f01026e5 <check_page+0xbd3>
f01026c1:	c7 44 24 0c 60 5a 10 	movl   $0xf0105a60,0xc(%esp)
f01026c8:	f0 
f01026c9:	c7 44 24 08 ba 58 10 	movl   $0xf01058ba,0x8(%esp)
f01026d0:	f0 
f01026d1:	c7 44 24 04 94 03 00 	movl   $0x394,0x4(%esp)
f01026d8:	00 
f01026d9:	c7 04 24 9b 58 10 f0 	movl   $0xf010589b,(%esp)
f01026e0:	e8 c4 d9 ff ff       	call   f01000a9 <_panic>

	// forcibly take pp0 back
	assert(PTE_ADDR(kern_pgdir[0]) == page2pa(pp0));
f01026e5:	8b 1d 88 6f 18 f0    	mov    0xf0186f88,%ebx
f01026eb:	8b 45 d4             	mov    -0x2c(%ebp),%eax
f01026ee:	e8 a0 e3 ff ff       	call   f0100a93 <page2pa>
f01026f3:	8b 13                	mov    (%ebx),%edx
f01026f5:	81 e2 00 f0 ff ff    	and    $0xfffff000,%edx
f01026fb:	39 c2                	cmp    %eax,%edx
f01026fd:	74 24                	je     f0102723 <check_page+0xc11>
f01026ff:	c7 44 24 0c 38 54 10 	movl   $0xf0105438,0xc(%esp)
f0102706:	f0 
f0102707:	c7 44 24 08 ba 58 10 	movl   $0xf01058ba,0x8(%esp)
f010270e:	f0 
f010270f:	c7 44 24 04 97 03 00 	movl   $0x397,0x4(%esp)
f0102716:	00 
f0102717:	c7 04 24 9b 58 10 f0 	movl   $0xf010589b,(%esp)
f010271e:	e8 86 d9 ff ff       	call   f01000a9 <_panic>
	kern_pgdir[0] = 0;
f0102723:	c7 03 00 00 00 00    	movl   $0x0,(%ebx)
	assert(pp0->pp_ref == 1);
f0102729:	8b 45 d4             	mov    -0x2c(%ebp),%eax
f010272c:	66 83 78 04 01       	cmpw   $0x1,0x4(%eax)
f0102731:	74 24                	je     f0102757 <check_page+0xc45>
f0102733:	c7 44 24 0c f8 5a 10 	movl   $0xf0105af8,0xc(%esp)
f010273a:	f0 
f010273b:	c7 44 24 08 ba 58 10 	movl   $0xf01058ba,0x8(%esp)
f0102742:	f0 
f0102743:	c7 44 24 04 99 03 00 	movl   $0x399,0x4(%esp)
f010274a:	00 
f010274b:	c7 04 24 9b 58 10 f0 	movl   $0xf010589b,(%esp)
f0102752:	e8 52 d9 ff ff       	call   f01000a9 <_panic>
	pp0->pp_ref = 0;
f0102757:	8b 45 d4             	mov    -0x2c(%ebp),%eax
f010275a:	66 c7 40 04 00 00    	movw   $0x0,0x4(%eax)

	// check pointer arithmetic in pgdir_walk
	page_free(pp0);
f0102760:	89 04 24             	mov    %eax,(%esp)
f0102763:	e8 04 ec ff ff       	call   f010136c <page_free>
	va = (void*)(PGSIZE * NPDENTRIES + PGSIZE);
	ptep = pgdir_walk(kern_pgdir, va, 1);
f0102768:	c7 44 24 08 01 00 00 	movl   $0x1,0x8(%esp)
f010276f:	00 
f0102770:	c7 44 24 04 00 10 40 	movl   $0x401000,0x4(%esp)
f0102777:	00 
f0102778:	a1 88 6f 18 f0       	mov    0xf0186f88,%eax
f010277d:	89 04 24             	mov    %eax,(%esp)
f0102780:	e8 ff f0 ff ff       	call   f0101884 <pgdir_walk>
f0102785:	89 45 d0             	mov    %eax,-0x30(%ebp)
f0102788:	89 45 e4             	mov    %eax,-0x1c(%ebp)
	ptep1 = (pte_t *) KADDR(PTE_ADDR(kern_pgdir[PDX(va)]));
f010278b:	8b 1d 88 6f 18 f0    	mov    0xf0186f88,%ebx
f0102791:	8b 4b 04             	mov    0x4(%ebx),%ecx
f0102794:	81 e1 00 f0 ff ff    	and    $0xfffff000,%ecx
f010279a:	ba a0 03 00 00       	mov    $0x3a0,%edx
f010279f:	b8 9b 58 10 f0       	mov    $0xf010589b,%eax
f01027a4:	e8 a2 e3 ff ff       	call   f0100b4b <_kaddr>
	assert(ptep == ptep1 + PTX(va));
f01027a9:	83 c0 04             	add    $0x4,%eax
f01027ac:	39 45 d0             	cmp    %eax,-0x30(%ebp)
f01027af:	74 24                	je     f01027d5 <check_page+0xcc3>
f01027b1:	c7 44 24 0c 84 5b 10 	movl   $0xf0105b84,0xc(%esp)
f01027b8:	f0 
f01027b9:	c7 44 24 08 ba 58 10 	movl   $0xf01058ba,0x8(%esp)
f01027c0:	f0 
f01027c1:	c7 44 24 04 a1 03 00 	movl   $0x3a1,0x4(%esp)
f01027c8:	00 
f01027c9:	c7 04 24 9b 58 10 f0 	movl   $0xf010589b,(%esp)
f01027d0:	e8 d4 d8 ff ff       	call   f01000a9 <_panic>
	kern_pgdir[PDX(va)] = 0;
f01027d5:	c7 43 04 00 00 00 00 	movl   $0x0,0x4(%ebx)
	pp0->pp_ref = 0;
f01027dc:	8b 5d d4             	mov    -0x2c(%ebp),%ebx
f01027df:	89 d8                	mov    %ebx,%eax
f01027e1:	66 c7 43 04 00 00    	movw   $0x0,0x4(%ebx)

	// check that new page tables get cleared
	memset(page2kva(pp0), 0xFF, PGSIZE);
f01027e7:	e8 97 e3 ff ff       	call   f0100b83 <page2kva>
f01027ec:	c7 44 24 08 00 10 00 	movl   $0x1000,0x8(%esp)
f01027f3:	00 
f01027f4:	c7 44 24 04 ff 00 00 	movl   $0xff,0x4(%esp)
f01027fb:	00 
f01027fc:	89 04 24             	mov    %eax,(%esp)
f01027ff:	e8 c3 1e 00 00       	call   f01046c7 <memset>
	page_free(pp0);
f0102804:	89 1c 24             	mov    %ebx,(%esp)
f0102807:	e8 60 eb ff ff       	call   f010136c <page_free>
	pgdir_walk(kern_pgdir, 0x0, 1);
f010280c:	c7 44 24 08 01 00 00 	movl   $0x1,0x8(%esp)
f0102813:	00 
f0102814:	c7 44 24 04 00 00 00 	movl   $0x0,0x4(%esp)
f010281b:	00 
f010281c:	a1 88 6f 18 f0       	mov    0xf0186f88,%eax
f0102821:	89 04 24             	mov    %eax,(%esp)
f0102824:	e8 5b f0 ff ff       	call   f0101884 <pgdir_walk>
	ptep = (pte_t *) page2kva(pp0);
f0102829:	89 d8                	mov    %ebx,%eax
f010282b:	e8 53 e3 ff ff       	call   f0100b83 <page2kva>
f0102830:	89 45 e4             	mov    %eax,-0x1c(%ebp)
	for(i=0; i<NPTENTRIES; i++)
f0102833:	ba 00 00 00 00       	mov    $0x0,%edx
		assert((ptep[i] & PTE_P) == 0);
f0102838:	f6 04 90 01          	testb  $0x1,(%eax,%edx,4)
f010283c:	74 24                	je     f0102862 <check_page+0xd50>
f010283e:	c7 44 24 0c 9c 5b 10 	movl   $0xf0105b9c,0xc(%esp)
f0102845:	f0 
f0102846:	c7 44 24 08 ba 58 10 	movl   $0xf01058ba,0x8(%esp)
f010284d:	f0 
f010284e:	c7 44 24 04 ab 03 00 	movl   $0x3ab,0x4(%esp)
f0102855:	00 
f0102856:	c7 04 24 9b 58 10 f0 	movl   $0xf010589b,(%esp)
f010285d:	e8 47 d8 ff ff       	call   f01000a9 <_panic>
	// check that new page tables get cleared
	memset(page2kva(pp0), 0xFF, PGSIZE);
	page_free(pp0);
	pgdir_walk(kern_pgdir, 0x0, 1);
	ptep = (pte_t *) page2kva(pp0);
	for(i=0; i<NPTENTRIES; i++)
f0102862:	83 c2 01             	add    $0x1,%edx
f0102865:	81 fa 00 04 00 00    	cmp    $0x400,%edx
f010286b:	75 cb                	jne    f0102838 <check_page+0xd26>
		assert((ptep[i] & PTE_P) == 0);
	kern_pgdir[0] = 0;
f010286d:	a1 88 6f 18 f0       	mov    0xf0186f88,%eax
f0102872:	c7 00 00 00 00 00    	movl   $0x0,(%eax)
	pp0->pp_ref = 0;
f0102878:	8b 45 d4             	mov    -0x2c(%ebp),%eax
f010287b:	66 c7 40 04 00 00    	movw   $0x0,0x4(%eax)

	// give free list back
	page_free_list = fl;
f0102881:	8b 4d cc             	mov    -0x34(%ebp),%ecx
f0102884:	89 0d bc 52 18 f0    	mov    %ecx,0xf01852bc

	// free the pages we took
	page_free(pp0);
f010288a:	89 04 24             	mov    %eax,(%esp)
f010288d:	e8 da ea ff ff       	call   f010136c <page_free>
	page_free(pp1);
f0102892:	89 34 24             	mov    %esi,(%esp)
f0102895:	e8 d2 ea ff ff       	call   f010136c <page_free>
	page_free(pp2);
f010289a:	89 3c 24             	mov    %edi,(%esp)
f010289d:	e8 ca ea ff ff       	call   f010136c <page_free>

	cprintf("check_page() succeeded!\n");
f01028a2:	c7 04 24 b3 5b 10 f0 	movl   $0xf0105bb3,(%esp)
f01028a9:	e8 50 0e 00 00       	call   f01036fe <cprintf>
}
f01028ae:	83 c4 3c             	add    $0x3c,%esp
f01028b1:	5b                   	pop    %ebx
f01028b2:	5e                   	pop    %esi
f01028b3:	5f                   	pop    %edi
f01028b4:	5d                   	pop    %ebp
f01028b5:	c3                   	ret    

f01028b6 <check_page_installed_pgdir>:

// check page_insert, page_remove, &c, with an installed kern_pgdir
static void
check_page_installed_pgdir(void)
{
f01028b6:	55                   	push   %ebp
f01028b7:	89 e5                	mov    %esp,%ebp
f01028b9:	57                   	push   %edi
f01028ba:	56                   	push   %esi
f01028bb:	53                   	push   %ebx
f01028bc:	83 ec 1c             	sub    $0x1c,%esp
	uintptr_t va;
	int i;

	// check that we can read and write installed pages
	pp1 = pp2 = 0;
	assert((pp0 = page_alloc(0)));
f01028bf:	c7 04 24 00 00 00 00 	movl   $0x0,(%esp)
f01028c6:	e8 4f ea ff ff       	call   f010131a <page_alloc>
f01028cb:	89 c6                	mov    %eax,%esi
f01028cd:	85 c0                	test   %eax,%eax
f01028cf:	75 24                	jne    f01028f5 <check_page_installed_pgdir+0x3f>
f01028d1:	c7 44 24 0c b5 59 10 	movl   $0xf01059b5,0xc(%esp)
f01028d8:	f0 
f01028d9:	c7 44 24 08 ba 58 10 	movl   $0xf01058ba,0x8(%esp)
f01028e0:	f0 
f01028e1:	c7 44 24 04 c6 03 00 	movl   $0x3c6,0x4(%esp)
f01028e8:	00 
f01028e9:	c7 04 24 9b 58 10 f0 	movl   $0xf010589b,(%esp)
f01028f0:	e8 b4 d7 ff ff       	call   f01000a9 <_panic>
	assert((pp1 = page_alloc(0)));
f01028f5:	c7 04 24 00 00 00 00 	movl   $0x0,(%esp)
f01028fc:	e8 19 ea ff ff       	call   f010131a <page_alloc>
f0102901:	89 c7                	mov    %eax,%edi
f0102903:	85 c0                	test   %eax,%eax
f0102905:	75 24                	jne    f010292b <check_page_installed_pgdir+0x75>
f0102907:	c7 44 24 0c cb 59 10 	movl   $0xf01059cb,0xc(%esp)
f010290e:	f0 
f010290f:	c7 44 24 08 ba 58 10 	movl   $0xf01058ba,0x8(%esp)
f0102916:	f0 
f0102917:	c7 44 24 04 c7 03 00 	movl   $0x3c7,0x4(%esp)
f010291e:	00 
f010291f:	c7 04 24 9b 58 10 f0 	movl   $0xf010589b,(%esp)
f0102926:	e8 7e d7 ff ff       	call   f01000a9 <_panic>
	assert((pp2 = page_alloc(0)));
f010292b:	c7 04 24 00 00 00 00 	movl   $0x0,(%esp)
f0102932:	e8 e3 e9 ff ff       	call   f010131a <page_alloc>
f0102937:	89 c3                	mov    %eax,%ebx
f0102939:	85 c0                	test   %eax,%eax
f010293b:	75 24                	jne    f0102961 <check_page_installed_pgdir+0xab>
f010293d:	c7 44 24 0c e1 59 10 	movl   $0xf01059e1,0xc(%esp)
f0102944:	f0 
f0102945:	c7 44 24 08 ba 58 10 	movl   $0xf01058ba,0x8(%esp)
f010294c:	f0 
f010294d:	c7 44 24 04 c8 03 00 	movl   $0x3c8,0x4(%esp)
f0102954:	00 
f0102955:	c7 04 24 9b 58 10 f0 	movl   $0xf010589b,(%esp)
f010295c:	e8 48 d7 ff ff       	call   f01000a9 <_panic>
	page_free(pp0);
f0102961:	89 34 24             	mov    %esi,(%esp)
f0102964:	e8 03 ea ff ff       	call   f010136c <page_free>
	memset(page2kva(pp1), 1, PGSIZE);
f0102969:	89 f8                	mov    %edi,%eax
f010296b:	e8 13 e2 ff ff       	call   f0100b83 <page2kva>
f0102970:	c7 44 24 08 00 10 00 	movl   $0x1000,0x8(%esp)
f0102977:	00 
f0102978:	c7 44 24 04 01 00 00 	movl   $0x1,0x4(%esp)
f010297f:	00 
f0102980:	89 04 24             	mov    %eax,(%esp)
f0102983:	e8 3f 1d 00 00       	call   f01046c7 <memset>
	memset(page2kva(pp2), 2, PGSIZE);
f0102988:	89 d8                	mov    %ebx,%eax
f010298a:	e8 f4 e1 ff ff       	call   f0100b83 <page2kva>
f010298f:	c7 44 24 08 00 10 00 	movl   $0x1000,0x8(%esp)
f0102996:	00 
f0102997:	c7 44 24 04 02 00 00 	movl   $0x2,0x4(%esp)
f010299e:	00 
f010299f:	89 04 24             	mov    %eax,(%esp)
f01029a2:	e8 20 1d 00 00       	call   f01046c7 <memset>
	page_insert(kern_pgdir, pp1, (void*) PGSIZE, PTE_W);
f01029a7:	c7 44 24 0c 02 00 00 	movl   $0x2,0xc(%esp)
f01029ae:	00 
f01029af:	c7 44 24 08 00 10 00 	movl   $0x1000,0x8(%esp)
f01029b6:	00 
f01029b7:	89 7c 24 04          	mov    %edi,0x4(%esp)
f01029bb:	a1 88 6f 18 f0       	mov    0xf0186f88,%eax
f01029c0:	89 04 24             	mov    %eax,(%esp)
f01029c3:	e8 e0 f0 ff ff       	call   f0101aa8 <page_insert>
	assert(pp1->pp_ref == 1);
f01029c8:	66 83 7f 04 01       	cmpw   $0x1,0x4(%edi)
f01029cd:	74 24                	je     f01029f3 <check_page_installed_pgdir+0x13d>
f01029cf:	c7 44 24 0c e7 5a 10 	movl   $0xf0105ae7,0xc(%esp)
f01029d6:	f0 
f01029d7:	c7 44 24 08 ba 58 10 	movl   $0xf01058ba,0x8(%esp)
f01029de:	f0 
f01029df:	c7 44 24 04 cd 03 00 	movl   $0x3cd,0x4(%esp)
f01029e6:	00 
f01029e7:	c7 04 24 9b 58 10 f0 	movl   $0xf010589b,(%esp)
f01029ee:	e8 b6 d6 ff ff       	call   f01000a9 <_panic>
	assert(*(uint32_t *)PGSIZE == 0x01010101U);
f01029f3:	81 3d 00 10 00 00 01 	cmpl   $0x1010101,0x1000
f01029fa:	01 01 01 
f01029fd:	74 24                	je     f0102a23 <check_page_installed_pgdir+0x16d>
f01029ff:	c7 44 24 0c b8 57 10 	movl   $0xf01057b8,0xc(%esp)
f0102a06:	f0 
f0102a07:	c7 44 24 08 ba 58 10 	movl   $0xf01058ba,0x8(%esp)
f0102a0e:	f0 
f0102a0f:	c7 44 24 04 ce 03 00 	movl   $0x3ce,0x4(%esp)
f0102a16:	00 
f0102a17:	c7 04 24 9b 58 10 f0 	movl   $0xf010589b,(%esp)
f0102a1e:	e8 86 d6 ff ff       	call   f01000a9 <_panic>
	page_insert(kern_pgdir, pp2, (void*) PGSIZE, PTE_W);
f0102a23:	c7 44 24 0c 02 00 00 	movl   $0x2,0xc(%esp)
f0102a2a:	00 
f0102a2b:	c7 44 24 08 00 10 00 	movl   $0x1000,0x8(%esp)
f0102a32:	00 
f0102a33:	89 5c 24 04          	mov    %ebx,0x4(%esp)
f0102a37:	a1 88 6f 18 f0       	mov    0xf0186f88,%eax
f0102a3c:	89 04 24             	mov    %eax,(%esp)
f0102a3f:	e8 64 f0 ff ff       	call   f0101aa8 <page_insert>
	assert(*(uint32_t *)PGSIZE == 0x02020202U);
f0102a44:	81 3d 00 10 00 00 02 	cmpl   $0x2020202,0x1000
f0102a4b:	02 02 02 
f0102a4e:	74 24                	je     f0102a74 <check_page_installed_pgdir+0x1be>
f0102a50:	c7 44 24 0c dc 57 10 	movl   $0xf01057dc,0xc(%esp)
f0102a57:	f0 
f0102a58:	c7 44 24 08 ba 58 10 	movl   $0xf01058ba,0x8(%esp)
f0102a5f:	f0 
f0102a60:	c7 44 24 04 d0 03 00 	movl   $0x3d0,0x4(%esp)
f0102a67:	00 
f0102a68:	c7 04 24 9b 58 10 f0 	movl   $0xf010589b,(%esp)
f0102a6f:	e8 35 d6 ff ff       	call   f01000a9 <_panic>
	assert(pp2->pp_ref == 1);
f0102a74:	66 83 7b 04 01       	cmpw   $0x1,0x4(%ebx)
f0102a79:	74 24                	je     f0102a9f <check_page_installed_pgdir+0x1e9>
f0102a7b:	c7 44 24 0c 09 5b 10 	movl   $0xf0105b09,0xc(%esp)
f0102a82:	f0 
f0102a83:	c7 44 24 08 ba 58 10 	movl   $0xf01058ba,0x8(%esp)
f0102a8a:	f0 
f0102a8b:	c7 44 24 04 d1 03 00 	movl   $0x3d1,0x4(%esp)
f0102a92:	00 
f0102a93:	c7 04 24 9b 58 10 f0 	movl   $0xf010589b,(%esp)
f0102a9a:	e8 0a d6 ff ff       	call   f01000a9 <_panic>
	assert(pp1->pp_ref == 0);
f0102a9f:	66 83 7f 04 00       	cmpw   $0x0,0x4(%edi)
f0102aa4:	74 24                	je     f0102aca <check_page_installed_pgdir+0x214>
f0102aa6:	c7 44 24 0c 73 5b 10 	movl   $0xf0105b73,0xc(%esp)
f0102aad:	f0 
f0102aae:	c7 44 24 08 ba 58 10 	movl   $0xf01058ba,0x8(%esp)
f0102ab5:	f0 
f0102ab6:	c7 44 24 04 d2 03 00 	movl   $0x3d2,0x4(%esp)
f0102abd:	00 
f0102abe:	c7 04 24 9b 58 10 f0 	movl   $0xf010589b,(%esp)
f0102ac5:	e8 df d5 ff ff       	call   f01000a9 <_panic>
	*(uint32_t *)PGSIZE = 0x03030303U;
f0102aca:	c7 05 00 10 00 00 03 	movl   $0x3030303,0x1000
f0102ad1:	03 03 03 
	assert(*(uint32_t *)page2kva(pp2) == 0x03030303U);
f0102ad4:	89 d8                	mov    %ebx,%eax
f0102ad6:	e8 a8 e0 ff ff       	call   f0100b83 <page2kva>
f0102adb:	81 38 03 03 03 03    	cmpl   $0x3030303,(%eax)
f0102ae1:	74 24                	je     f0102b07 <check_page_installed_pgdir+0x251>
f0102ae3:	c7 44 24 0c 00 58 10 	movl   $0xf0105800,0xc(%esp)
f0102aea:	f0 
f0102aeb:	c7 44 24 08 ba 58 10 	movl   $0xf01058ba,0x8(%esp)
f0102af2:	f0 
f0102af3:	c7 44 24 04 d4 03 00 	movl   $0x3d4,0x4(%esp)
f0102afa:	00 
f0102afb:	c7 04 24 9b 58 10 f0 	movl   $0xf010589b,(%esp)
f0102b02:	e8 a2 d5 ff ff       	call   f01000a9 <_panic>
	page_remove(kern_pgdir, (void*) PGSIZE);
f0102b07:	c7 44 24 04 00 10 00 	movl   $0x1000,0x4(%esp)
f0102b0e:	00 
f0102b0f:	a1 88 6f 18 f0       	mov    0xf0186f88,%eax
f0102b14:	89 04 24             	mov    %eax,(%esp)
f0102b17:	e8 43 ef ff ff       	call   f0101a5f <page_remove>
	assert(pp2->pp_ref == 0);
f0102b1c:	66 83 7b 04 00       	cmpw   $0x0,0x4(%ebx)
f0102b21:	74 24                	je     f0102b47 <check_page_installed_pgdir+0x291>
f0102b23:	c7 44 24 0c 41 5b 10 	movl   $0xf0105b41,0xc(%esp)
f0102b2a:	f0 
f0102b2b:	c7 44 24 08 ba 58 10 	movl   $0xf01058ba,0x8(%esp)
f0102b32:	f0 
f0102b33:	c7 44 24 04 d6 03 00 	movl   $0x3d6,0x4(%esp)
f0102b3a:	00 
f0102b3b:	c7 04 24 9b 58 10 f0 	movl   $0xf010589b,(%esp)
f0102b42:	e8 62 d5 ff ff       	call   f01000a9 <_panic>

	// forcibly take pp0 back
	assert(PTE_ADDR(kern_pgdir[0]) == page2pa(pp0));
f0102b47:	8b 1d 88 6f 18 f0    	mov    0xf0186f88,%ebx
f0102b4d:	89 f0                	mov    %esi,%eax
f0102b4f:	e8 3f df ff ff       	call   f0100a93 <page2pa>
f0102b54:	8b 13                	mov    (%ebx),%edx
f0102b56:	81 e2 00 f0 ff ff    	and    $0xfffff000,%edx
f0102b5c:	39 c2                	cmp    %eax,%edx
f0102b5e:	74 24                	je     f0102b84 <check_page_installed_pgdir+0x2ce>
f0102b60:	c7 44 24 0c 38 54 10 	movl   $0xf0105438,0xc(%esp)
f0102b67:	f0 
f0102b68:	c7 44 24 08 ba 58 10 	movl   $0xf01058ba,0x8(%esp)
f0102b6f:	f0 
f0102b70:	c7 44 24 04 d9 03 00 	movl   $0x3d9,0x4(%esp)
f0102b77:	00 
f0102b78:	c7 04 24 9b 58 10 f0 	movl   $0xf010589b,(%esp)
f0102b7f:	e8 25 d5 ff ff       	call   f01000a9 <_panic>
	kern_pgdir[0] = 0;
f0102b84:	c7 03 00 00 00 00    	movl   $0x0,(%ebx)
	assert(pp0->pp_ref == 1);
f0102b8a:	66 83 7e 04 01       	cmpw   $0x1,0x4(%esi)
f0102b8f:	74 24                	je     f0102bb5 <check_page_installed_pgdir+0x2ff>
f0102b91:	c7 44 24 0c f8 5a 10 	movl   $0xf0105af8,0xc(%esp)
f0102b98:	f0 
f0102b99:	c7 44 24 08 ba 58 10 	movl   $0xf01058ba,0x8(%esp)
f0102ba0:	f0 
f0102ba1:	c7 44 24 04 db 03 00 	movl   $0x3db,0x4(%esp)
f0102ba8:	00 
f0102ba9:	c7 04 24 9b 58 10 f0 	movl   $0xf010589b,(%esp)
f0102bb0:	e8 f4 d4 ff ff       	call   f01000a9 <_panic>
	pp0->pp_ref = 0;
f0102bb5:	66 c7 46 04 00 00    	movw   $0x0,0x4(%esi)

	// free the pages we took
	page_free(pp0);
f0102bbb:	89 34 24             	mov    %esi,(%esp)
f0102bbe:	e8 a9 e7 ff ff       	call   f010136c <page_free>

	cprintf("check_page_installed_pgdir() succeeded!\n");
f0102bc3:	c7 04 24 2c 58 10 f0 	movl   $0xf010582c,(%esp)
f0102bca:	e8 2f 0b 00 00       	call   f01036fe <cprintf>
}
f0102bcf:	83 c4 1c             	add    $0x1c,%esp
f0102bd2:	5b                   	pop    %ebx
f0102bd3:	5e                   	pop    %esi
f0102bd4:	5f                   	pop    %edi
f0102bd5:	5d                   	pop    %ebp
f0102bd6:	c3                   	ret    

f0102bd7 <mem_init>:
//
// From UTOP to ULIM, the user is allowed to read but not write.
// Above ULIM the user cannot read or write.
void
mem_init(void)
{
f0102bd7:	55                   	push   %ebp
f0102bd8:	89 e5                	mov    %esp,%ebp
f0102bda:	53                   	push   %ebx
f0102bdb:	83 ec 14             	sub    $0x14,%esp
	uint32_t cr0;
	size_t n;

	// Find out how much memory the machine has (npages & npages_basemem).
	i386_detect_memory();
f0102bde:	e8 ec de ff ff       	call   f0100acf <i386_detect_memory>
	// Remove this line when you're ready to test this function.
	//panic("mem_init: This function is not finished\n");

	//////////////////////////////////////////////////////////////////////
	// create initial page directory.
	kern_pgdir = (pde_t *) boot_alloc(PGSIZE);
f0102be3:	b8 00 10 00 00       	mov    $0x1000,%eax
f0102be8:	e8 4d e0 ff ff       	call   f0100c3a <boot_alloc>
f0102bed:	a3 88 6f 18 f0       	mov    %eax,0xf0186f88
	memset(kern_pgdir, 0, PGSIZE);
f0102bf2:	c7 44 24 08 00 10 00 	movl   $0x1000,0x8(%esp)
f0102bf9:	00 
f0102bfa:	c7 44 24 04 00 00 00 	movl   $0x0,0x4(%esp)
f0102c01:	00 
f0102c02:	89 04 24             	mov    %eax,(%esp)
f0102c05:	e8 bd 1a 00 00       	call   f01046c7 <memset>
	// a virtual page table at virtual address UVPT.
	// (For now, you don't have understand the greater purpose of the
	// following line.)

	// Permissions: kernel R, user R
	kern_pgdir[PDX(UVPT)] = PADDR(kern_pgdir) | PTE_U | PTE_P;
f0102c0a:	8b 1d 88 6f 18 f0    	mov    0xf0186f88,%ebx
f0102c10:	89 d9                	mov    %ebx,%ecx
f0102c12:	ba 93 00 00 00       	mov    $0x93,%edx
f0102c17:	b8 9b 58 10 f0       	mov    $0xf010589b,%eax
f0102c1c:	e8 ec df ff ff       	call   f0100c0d <_paddr>
f0102c21:	83 c8 05             	or     $0x5,%eax
f0102c24:	89 83 f4 0e 00 00    	mov    %eax,0xef4(%ebx)
	// The kernel uses this array to keep track of physical pages: for
	// each physical page, there is a corresponding struct PageInfo in this
	// array.  'npages' is the number of physical pages in memory.  Use memset
	// to initialize all fields of each struct PageInfo to 0.
	// Your code goes here:
	pages=boot_alloc(npages //[page]
f0102c2a:	a1 84 6f 18 f0       	mov    0xf0186f84,%eax
f0102c2f:	c1 e0 03             	shl    $0x3,%eax
f0102c32:	e8 03 e0 ff ff       	call   f0100c3a <boot_alloc>
f0102c37:	a3 8c 6f 18 f0       	mov    %eax,0xf0186f8c
					 * sizeof(struct PageInfo));//[B/page]
	memset(pages,0,npages*sizeof(struct PageInfo));
f0102c3c:	8b 1d 84 6f 18 f0    	mov    0xf0186f84,%ebx
f0102c42:	8d 14 dd 00 00 00 00 	lea    0x0(,%ebx,8),%edx
f0102c49:	89 54 24 08          	mov    %edx,0x8(%esp)
f0102c4d:	c7 44 24 04 00 00 00 	movl   $0x0,0x4(%esp)
f0102c54:	00 
f0102c55:	89 04 24             	mov    %eax,(%esp)
f0102c58:	e8 6a 1a 00 00       	call   f01046c7 <memset>
	//////////////////////////////////////////////////////////////////////
	// Make 'envs' point to an array of size 'NENV' of 'struct Env'.
	// LAB 3: Your code here.

	envs = boot_alloc(NENV*sizeof(struct Env));
f0102c5d:	b8 00 80 01 00       	mov    $0x18000,%eax
f0102c62:	e8 d3 df ff ff       	call   f0100c3a <boot_alloc>
f0102c67:	a3 c8 52 18 f0       	mov    %eax,0xf01852c8
	memset(envs,0, NENV*sizeof(struct Env));
f0102c6c:	c7 44 24 08 00 80 01 	movl   $0x18000,0x8(%esp)
f0102c73:	00 
f0102c74:	c7 44 24 04 00 00 00 	movl   $0x0,0x4(%esp)
f0102c7b:	00 
f0102c7c:	89 04 24             	mov    %eax,(%esp)
f0102c7f:	e8 43 1a 00 00       	call   f01046c7 <memset>
	// Now that we've allocated the initial kernel data structures, we set
	// up the list of free physical pages. Once we've done so, all further
	// memory management will go through the page_* functions. In
	// particular, we can now map memory using boot_map_region
	// or page_insert
	page_init();
f0102c84:	e8 21 e6 ff ff       	call   f01012aa <page_init>

	check_page_free_list(1);
f0102c89:	b8 01 00 00 00       	mov    $0x1,%eax
f0102c8e:	e8 f3 e2 ff ff       	call   f0100f86 <check_page_free_list>
	check_page_alloc();
f0102c93:	e8 30 e7 ff ff       	call   f01013c8 <check_page_alloc>
	check_page();
f0102c98:	e8 75 ee ff ff       	call   f0101b12 <check_page>
	// Permissions:
	//    - the new image at UPAGES -- kernel R, user R
	//      (ie. perm = PTE_U | PTE_P)
	//    - pages itself -- kernel RW, user NONE
	// Your code goes here:
	boot_map_region(kern_pgdir,UPAGES,npages*sizeof(struct PageInfo),PADDR(pages),PTE_U|PTE_P);
f0102c9d:	8b 0d 8c 6f 18 f0    	mov    0xf0186f8c,%ecx
f0102ca3:	ba bd 00 00 00       	mov    $0xbd,%edx
f0102ca8:	b8 9b 58 10 f0       	mov    $0xf010589b,%eax
f0102cad:	e8 5b df ff ff       	call   f0100c0d <_paddr>
f0102cb2:	8b 1d 84 6f 18 f0    	mov    0xf0186f84,%ebx
f0102cb8:	8d 0c dd 00 00 00 00 	lea    0x0(,%ebx,8),%ecx
f0102cbf:	c7 44 24 04 05 00 00 	movl   $0x5,0x4(%esp)
f0102cc6:	00 
f0102cc7:	89 04 24             	mov    %eax,(%esp)
f0102cca:	ba 00 00 00 ef       	mov    $0xef000000,%edx
f0102ccf:	a1 88 6f 18 f0       	mov    0xf0186f88,%eax
f0102cd4:	e8 46 ec ff ff       	call   f010191f <boot_map_region>
	// (ie. perm = PTE_U | PTE_P).
	// Permissions:
	//    - the new image at UENVS  -- kernel R, user R
	//    - envs itself -- kernel RW, user NONE
	// LAB 3: Your code here.
	boot_map_region(kern_pgdir, UENVS, NENV*sizeof(struct Env), PADDR(envs), PTE_U|PTE_P);
f0102cd9:	8b 0d c8 52 18 f0    	mov    0xf01852c8,%ecx
f0102cdf:	ba c5 00 00 00       	mov    $0xc5,%edx
f0102ce4:	b8 9b 58 10 f0       	mov    $0xf010589b,%eax
f0102ce9:	e8 1f df ff ff       	call   f0100c0d <_paddr>
f0102cee:	c7 44 24 04 05 00 00 	movl   $0x5,0x4(%esp)
f0102cf5:	00 
f0102cf6:	89 04 24             	mov    %eax,(%esp)
f0102cf9:	b9 00 80 01 00       	mov    $0x18000,%ecx
f0102cfe:	ba 00 00 c0 ee       	mov    $0xeec00000,%edx
f0102d03:	a1 88 6f 18 f0       	mov    0xf0186f88,%eax
f0102d08:	e8 12 ec ff ff       	call   f010191f <boot_map_region>
	//     * [KSTACKTOP-PTSIZE, KSTACKTOP-KSTKSIZE) -- not backed; so if
	//       the kernel overflows its stack, it will fault rather than
	//       overwrite memory.  Known as a "guard page".
	//     Permissions: kernel RW, user NONE
	// Your code goes here:
	boot_map_region(kern_pgdir,KSTACKTOP-KSTKSIZE,KSTKSIZE,PADDR(bootstack),PTE_P|PTE_W);
f0102d0d:	b9 00 20 11 f0       	mov    $0xf0112000,%ecx
f0102d12:	ba d2 00 00 00       	mov    $0xd2,%edx
f0102d17:	b8 9b 58 10 f0       	mov    $0xf010589b,%eax
f0102d1c:	e8 ec de ff ff       	call   f0100c0d <_paddr>
f0102d21:	c7 44 24 04 03 00 00 	movl   $0x3,0x4(%esp)
f0102d28:	00 
f0102d29:	89 04 24             	mov    %eax,(%esp)
f0102d2c:	b9 00 80 00 00       	mov    $0x8000,%ecx
f0102d31:	ba 00 80 ff ef       	mov    $0xefff8000,%edx
f0102d36:	a1 88 6f 18 f0       	mov    0xf0186f88,%eax
f0102d3b:	e8 df eb ff ff       	call   f010191f <boot_map_region>
	//      the PA range [0, 2^32 - KERNBASE)
	// We might not have 2^32 - KERNBASE bytes of physical memory, but
	// we just set up the mapping anyway.
	// Permissions: kernel RW, user NONE
	// Your code goes here:
	boot_map_region(kern_pgdir,KERNBASE,~0x0-KERNBASE+1,0,PTE_P|PTE_W);
f0102d40:	c7 44 24 04 03 00 00 	movl   $0x3,0x4(%esp)
f0102d47:	00 
f0102d48:	c7 04 24 00 00 00 00 	movl   $0x0,(%esp)
f0102d4f:	b9 00 00 00 10       	mov    $0x10000000,%ecx
f0102d54:	ba 00 00 00 f0       	mov    $0xf0000000,%edx
f0102d59:	a1 88 6f 18 f0       	mov    0xf0186f88,%eax
f0102d5e:	e8 bc eb ff ff       	call   f010191f <boot_map_region>
	// Check that the initial page directory has been set up correctly.
	check_kern_pgdir();
f0102d63:	e8 57 df ff ff       	call   f0100cbf <check_kern_pgdir>
	// somewhere between KERNBASE and KERNBASE+4MB right now, which is
	// mapped the same way by both page tables.
	//
	// If the machine reboots at this point, you've probably set up your
	// kern_pgdir wrong.
	lcr3(PADDR(kern_pgdir));
f0102d68:	8b 0d 88 6f 18 f0    	mov    0xf0186f88,%ecx
f0102d6e:	ba e7 00 00 00       	mov    $0xe7,%edx
f0102d73:	b8 9b 58 10 f0       	mov    $0xf010589b,%eax
f0102d78:	e8 90 de ff ff       	call   f0100c0d <_paddr>
f0102d7d:	e8 09 dd ff ff       	call   f0100a8b <lcr3>

	check_page_free_list(0);
f0102d82:	b8 00 00 00 00       	mov    $0x0,%eax
f0102d87:	e8 fa e1 ff ff       	call   f0100f86 <check_page_free_list>

	// entry.S set the really important flags in cr0 (including enabling
	// paging).  Here we configure the rest of the flags that we care about.
	cr0 = rcr0();
f0102d8c:	e8 f2 dc ff ff       	call   f0100a83 <rcr0>
	cr0 |= CR0_PE|CR0_PG|CR0_AM|CR0_WP|CR0_NE|CR0_MP;
	cr0 &= ~(CR0_TS|CR0_EM);
f0102d91:	83 e0 f3             	and    $0xfffffff3,%eax
f0102d94:	0d 23 00 05 80       	or     $0x80050023,%eax
	lcr0(cr0);
f0102d99:	e8 dd dc ff ff       	call   f0100a7b <lcr0>

	// Some more checks, only possible after kern_pgdir is installed.
	check_page_installed_pgdir();
f0102d9e:	e8 13 fb ff ff       	call   f01028b6 <check_page_installed_pgdir>
}
f0102da3:	83 c4 14             	add    $0x14,%esp
f0102da6:	5b                   	pop    %ebx
f0102da7:	5d                   	pop    %ebp
f0102da8:	c3                   	ret    

f0102da9 <user_mem_check>:
// Returns 0 if the user program can access this range of addresses,
// and -E_FAULT otherwise.
//
int
user_mem_check(struct Env *env, const void *va, size_t len, int perm)
{
f0102da9:	55                   	push   %ebp
f0102daa:	89 e5                	mov    %esp,%ebp
	// LAB 3: Your code here.

	return 0;
}
f0102dac:	b8 00 00 00 00       	mov    $0x0,%eax
f0102db1:	5d                   	pop    %ebp
f0102db2:	c3                   	ret    

f0102db3 <user_mem_assert>:
// If it cannot, 'env' is destroyed and, if env is the current
// environment, this function will not return.
//
void
user_mem_assert(struct Env *env, const void *va, size_t len, int perm)
{
f0102db3:	55                   	push   %ebp
f0102db4:	89 e5                	mov    %esp,%ebp
f0102db6:	53                   	push   %ebx
f0102db7:	83 ec 14             	sub    $0x14,%esp
f0102dba:	8b 5d 08             	mov    0x8(%ebp),%ebx
	if (user_mem_check(env, va, len, perm | PTE_U) < 0) {
f0102dbd:	8b 45 14             	mov    0x14(%ebp),%eax
f0102dc0:	83 c8 04             	or     $0x4,%eax
f0102dc3:	89 44 24 0c          	mov    %eax,0xc(%esp)
f0102dc7:	8b 45 10             	mov    0x10(%ebp),%eax
f0102dca:	89 44 24 08          	mov    %eax,0x8(%esp)
f0102dce:	8b 45 0c             	mov    0xc(%ebp),%eax
f0102dd1:	89 44 24 04          	mov    %eax,0x4(%esp)
f0102dd5:	89 1c 24             	mov    %ebx,(%esp)
f0102dd8:	e8 cc ff ff ff       	call   f0102da9 <user_mem_check>
f0102ddd:	85 c0                	test   %eax,%eax
f0102ddf:	79 23                	jns    f0102e04 <user_mem_assert+0x51>
		cprintf("[%08x] user_mem_check assertion failure for "
f0102de1:	c7 44 24 08 00 00 00 	movl   $0x0,0x8(%esp)
f0102de8:	00 
f0102de9:	8b 43 48             	mov    0x48(%ebx),%eax
f0102dec:	89 44 24 04          	mov    %eax,0x4(%esp)
f0102df0:	c7 04 24 58 58 10 f0 	movl   $0xf0105858,(%esp)
f0102df7:	e8 02 09 00 00       	call   f01036fe <cprintf>
			"va %08x\n", env->env_id, user_mem_check_addr);
		env_destroy(env);	// may not return
f0102dfc:	89 1c 24             	mov    %ebx,(%esp)
f0102dff:	e8 4e 07 00 00       	call   f0103552 <env_destroy>
	}
}
f0102e04:	83 c4 14             	add    $0x14,%esp
f0102e07:	5b                   	pop    %ebx
f0102e08:	5d                   	pop    %ebp
f0102e09:	c3                   	ret    

f0102e0a <lgdt>:
	asm volatile("lidt (%0)" : : "r" (p));
}

static inline void
lgdt(void *p)
{
f0102e0a:	55                   	push   %ebp
f0102e0b:	89 e5                	mov    %esp,%ebp
	asm volatile("lgdt (%0)" : : "r" (p));
f0102e0d:	0f 01 10             	lgdtl  (%eax)
}
f0102e10:	5d                   	pop    %ebp
f0102e11:	c3                   	ret    

f0102e12 <lldt>:

static inline void
lldt(uint16_t sel)
{
f0102e12:	55                   	push   %ebp
f0102e13:	89 e5                	mov    %esp,%ebp
	asm volatile("lldt %0" : : "r" (sel));
f0102e15:	0f 00 d0             	lldt   %ax
}
f0102e18:	5d                   	pop    %ebp
f0102e19:	c3                   	ret    

f0102e1a <lcr3>:
	return val;
}

static inline void
lcr3(uint32_t val)
{
f0102e1a:	55                   	push   %ebp
f0102e1b:	89 e5                	mov    %esp,%ebp
	asm volatile("movl %0,%%cr3" : : "r" (val));
f0102e1d:	0f 22 d8             	mov    %eax,%cr3
}
f0102e20:	5d                   	pop    %ebp
f0102e21:	c3                   	ret    

f0102e22 <rcr3>:

static inline uint32_t
rcr3(void)
{
f0102e22:	55                   	push   %ebp
f0102e23:	89 e5                	mov    %esp,%ebp
	uint32_t val;
	asm volatile("movl %%cr3,%0" : "=r" (val));
f0102e25:	0f 20 d8             	mov    %cr3,%eax
	return val;
}
f0102e28:	5d                   	pop    %ebp
f0102e29:	c3                   	ret    

f0102e2a <page2pa>:
int	user_mem_check(struct Env *env, const void *va, size_t len, int perm);
void	user_mem_assert(struct Env *env, const void *va, size_t len, int perm);

static inline physaddr_t
page2pa(struct PageInfo *pp)
{
f0102e2a:	55                   	push   %ebp
f0102e2b:	89 e5                	mov    %esp,%ebp
	return (pp - pages) << PGSHIFT;
f0102e2d:	2b 05 8c 6f 18 f0    	sub    0xf0186f8c,%eax
f0102e33:	c1 f8 03             	sar    $0x3,%eax
f0102e36:	c1 e0 0c             	shl    $0xc,%eax
}
f0102e39:	5d                   	pop    %ebp
f0102e3a:	c3                   	ret    

f0102e3b <_kaddr>:
 * virtual address.  It panics if you pass an invalid physical address. */
#define KADDR(pa) _kaddr(__FILE__, __LINE__, pa)

static inline void*
_kaddr(const char *file, int line, physaddr_t pa)
{
f0102e3b:	55                   	push   %ebp
f0102e3c:	89 e5                	mov    %esp,%ebp
f0102e3e:	53                   	push   %ebx
f0102e3f:	83 ec 04             	sub    $0x4,%esp
	if (PGNUM(pa) >= npages)
f0102e42:	89 cb                	mov    %ecx,%ebx
f0102e44:	c1 eb 0c             	shr    $0xc,%ebx
f0102e47:	3b 1d 84 6f 18 f0    	cmp    0xf0186f84,%ebx
f0102e4d:	72 0d                	jb     f0102e5c <_kaddr+0x21>
		_panic(file, line, "KADDR called with invalid pa %08lx", pa);
f0102e4f:	51                   	push   %ecx
f0102e50:	68 e0 50 10 f0       	push   $0xf01050e0
f0102e55:	52                   	push   %edx
f0102e56:	50                   	push   %eax
f0102e57:	e8 4d d2 ff ff       	call   f01000a9 <_panic>
	return (void *)(pa + KERNBASE);
f0102e5c:	8d 81 00 00 00 f0    	lea    -0x10000000(%ecx),%eax
}
f0102e62:	8b 5d fc             	mov    -0x4(%ebp),%ebx
f0102e65:	c9                   	leave  
f0102e66:	c3                   	ret    

f0102e67 <page2kva>:
	return &pages[PGNUM(pa)];
}

static inline void*
page2kva(struct PageInfo *pp)
{
f0102e67:	55                   	push   %ebp
f0102e68:	89 e5                	mov    %esp,%ebp
f0102e6a:	83 ec 08             	sub    $0x8,%esp
	return KADDR(page2pa(pp));
f0102e6d:	e8 b8 ff ff ff       	call   f0102e2a <page2pa>
f0102e72:	89 c1                	mov    %eax,%ecx
f0102e74:	ba 56 00 00 00       	mov    $0x56,%edx
f0102e79:	b8 8d 58 10 f0       	mov    $0xf010588d,%eax
f0102e7e:	e8 b8 ff ff ff       	call   f0102e3b <_kaddr>
}
f0102e83:	c9                   	leave  
f0102e84:	c3                   	ret    

f0102e85 <_paddr>:
#define PADDR(kva) _paddr(__FILE__, __LINE__, kva)

static inline physaddr_t
_paddr(const char *file, int line, void *kva)
{
	if ((uint32_t)kva < KERNBASE)
f0102e85:	81 f9 ff ff ff ef    	cmp    $0xefffffff,%ecx
f0102e8b:	77 13                	ja     f0102ea0 <_paddr+0x1b>
 */
#define PADDR(kva) _paddr(__FILE__, __LINE__, kva)

static inline physaddr_t
_paddr(const char *file, int line, void *kva)
{
f0102e8d:	55                   	push   %ebp
f0102e8e:	89 e5                	mov    %esp,%ebp
f0102e90:	83 ec 08             	sub    $0x8,%esp
	if ((uint32_t)kva < KERNBASE)
		_panic(file, line, "PADDR called with invalid kva %08lx", kva);
f0102e93:	51                   	push   %ecx
f0102e94:	68 04 51 10 f0       	push   $0xf0105104
f0102e99:	52                   	push   %edx
f0102e9a:	50                   	push   %eax
f0102e9b:	e8 09 d2 ff ff       	call   f01000a9 <_panic>
	return (physaddr_t)kva - KERNBASE;
f0102ea0:	8d 81 00 00 00 10    	lea    0x10000000(%ecx),%eax
}
f0102ea6:	c3                   	ret    

f0102ea7 <env_setup_vm>:
// Returns 0 on success, < 0 on error.  Errors include:
//	-E_NO_MEM if page directory or table could not be allocated.
//
static int
env_setup_vm(struct Env *e)
{
f0102ea7:	55                   	push   %ebp
f0102ea8:	89 e5                	mov    %esp,%ebp
f0102eaa:	56                   	push   %esi
f0102eab:	53                   	push   %ebx
f0102eac:	89 c6                	mov    %eax,%esi
	int i;
	struct PageInfo *p = NULL;

	// Allocate a page for the page directory
	if (!(p = page_alloc(ALLOC_ZERO)))
f0102eae:	83 ec 0c             	sub    $0xc,%esp
f0102eb1:	6a 01                	push   $0x1
f0102eb3:	e8 62 e4 ff ff       	call   f010131a <page_alloc>
f0102eb8:	83 c4 10             	add    $0x10,%esp
f0102ebb:	85 c0                	test   %eax,%eax
f0102ebd:	74 4a                	je     f0102f09 <env_setup_vm+0x62>
f0102ebf:	89 c3                	mov    %eax,%ebx
	//	physical pages mapped only above UTOP, but env_pgdir
	//	is an exception -- you need to increment env_pgdir's
	//	pp_ref for env_free to work correctly.
	//    - The functions in kern/pmap.h are handy.
	
	e->env_pgdir = page2kva(p);
f0102ec1:	e8 a1 ff ff ff       	call   f0102e67 <page2kva>
f0102ec6:	89 46 5c             	mov    %eax,0x5c(%esi)
	memcpy(e->env_pgdir, kern_pgdir, PGSIZE);
f0102ec9:	83 ec 04             	sub    $0x4,%esp
f0102ecc:	68 00 10 00 00       	push   $0x1000
f0102ed1:	ff 35 88 6f 18 f0    	pushl  0xf0186f88
f0102ed7:	50                   	push   %eax
f0102ed8:	e8 a0 18 00 00       	call   f010477d <memcpy>
	p->pp_ref ++;
f0102edd:	66 83 43 04 01       	addw   $0x1,0x4(%ebx)
	
	// LAB 3: Your code here.

	// UVPT maps the env's own page table read-only.
	// Permissions: kernel R, user R
	e->env_pgdir[PDX(UVPT)] = PADDR(e->env_pgdir) | PTE_P | PTE_U;
f0102ee2:	8b 5e 5c             	mov    0x5c(%esi),%ebx
f0102ee5:	89 d9                	mov    %ebx,%ecx
f0102ee7:	ba c0 00 00 00       	mov    $0xc0,%edx
f0102eec:	b8 5c 5c 10 f0       	mov    $0xf0105c5c,%eax
f0102ef1:	e8 8f ff ff ff       	call   f0102e85 <_paddr>
f0102ef6:	83 c8 05             	or     $0x5,%eax
f0102ef9:	89 83 f4 0e 00 00    	mov    %eax,0xef4(%ebx)

	return 0;
f0102eff:	83 c4 10             	add    $0x10,%esp
f0102f02:	b8 00 00 00 00       	mov    $0x0,%eax
f0102f07:	eb 05                	jmp    f0102f0e <env_setup_vm+0x67>
	int i;
	struct PageInfo *p = NULL;

	// Allocate a page for the page directory
	if (!(p = page_alloc(ALLOC_ZERO)))
		return -E_NO_MEM;
f0102f09:	b8 fc ff ff ff       	mov    $0xfffffffc,%eax
	// UVPT maps the env's own page table read-only.
	// Permissions: kernel R, user R
	e->env_pgdir[PDX(UVPT)] = PADDR(e->env_pgdir) | PTE_P | PTE_U;

	return 0;
}
f0102f0e:	8d 65 f8             	lea    -0x8(%ebp),%esp
f0102f11:	5b                   	pop    %ebx
f0102f12:	5e                   	pop    %esi
f0102f13:	5d                   	pop    %ebp
f0102f14:	c3                   	ret    

f0102f15 <pa2page>:
}

static inline struct PageInfo*
pa2page(physaddr_t pa)
{
	if (PGNUM(pa) >= npages)
f0102f15:	c1 e8 0c             	shr    $0xc,%eax
f0102f18:	3b 05 84 6f 18 f0    	cmp    0xf0186f84,%eax
f0102f1e:	72 17                	jb     f0102f37 <pa2page+0x22>
	return (pp - pages) << PGSHIFT;
}

static inline struct PageInfo*
pa2page(physaddr_t pa)
{
f0102f20:	55                   	push   %ebp
f0102f21:	89 e5                	mov    %esp,%ebp
f0102f23:	83 ec 0c             	sub    $0xc,%esp
	if (PGNUM(pa) >= npages)
		panic("pa2page called with invalid pa");
f0102f26:	68 14 53 10 f0       	push   $0xf0105314
f0102f2b:	6a 4f                	push   $0x4f
f0102f2d:	68 8d 58 10 f0       	push   $0xf010588d
f0102f32:	e8 72 d1 ff ff       	call   f01000a9 <_panic>
	return &pages[PGNUM(pa)];
f0102f37:	8b 15 8c 6f 18 f0    	mov    0xf0186f8c,%edx
f0102f3d:	8d 04 c2             	lea    (%edx,%eax,8),%eax
}
f0102f40:	c3                   	ret    

f0102f41 <region_alloc>:
// Pages should be writable by user and kernel.
// Panic if any allocation attempt fails.
//
static void
region_alloc(struct Env *e, void *va, size_t len)
{
f0102f41:	55                   	push   %ebp
f0102f42:	89 e5                	mov    %esp,%ebp
f0102f44:	57                   	push   %edi
f0102f45:	56                   	push   %esi
f0102f46:	53                   	push   %ebx
f0102f47:	83 ec 28             	sub    $0x28,%esp
f0102f4a:	89 c7                	mov    %eax,%edi
	// Hint: It is easier to use region_alloc if the caller can pass
	//   'va' and 'len' values that are not page-aligned.
	//   You should round va down, and round (va + len) up.
	//   (Watch out for corner-cases!)
	
	va = ROUNDDOWN(va,PGSIZE);
f0102f4c:	81 e2 00 f0 ff ff    	and    $0xfffff000,%edx
f0102f52:	89 d3                	mov    %edx,%ebx
f0102f54:	89 d6                	mov    %edx,%esi
	void* va_finish = ROUNDUP(va+len,PGSIZE);
f0102f56:	8d 84 0a ff 0f 00 00 	lea    0xfff(%edx,%ecx,1),%eax
f0102f5d:	25 00 f0 ff ff       	and    $0xfffff000,%eax
f0102f62:	89 45 e4             	mov    %eax,-0x1c(%ebp)
	cprintf("checkpoint\n");//DEBUG2
f0102f65:	68 67 5c 10 f0       	push   $0xf0105c67
f0102f6a:	e8 8f 07 00 00       	call   f01036fe <cprintf>
	if (va_finish>va) {len = va_finish - va; //es un multiplo de PGSIZE	
f0102f6f:	83 c4 10             	add    $0x10,%esp
f0102f72:	8b 45 e4             	mov    -0x1c(%ebp),%eax
f0102f75:	39 c3                	cmp    %eax,%ebx
f0102f77:	73 16                	jae    f0102f8f <region_alloc+0x4e>
f0102f79:	29 d8                	sub    %ebx,%eax
f0102f7b:	89 c3                	mov    %eax,%ebx
						cprintf("FLAGTRUE\n");}//DEBUG2
f0102f7d:	83 ec 0c             	sub    $0xc,%esp
f0102f80:	68 73 5c 10 f0       	push   $0xf0105c73
f0102f85:	e8 74 07 00 00       	call   f01036fe <cprintf>
f0102f8a:	83 c4 10             	add    $0x10,%esp
f0102f8d:	eb 73                	jmp    f0103002 <region_alloc+0xc1>
	else {len = ~0x0-(uint32_t)va+1;//si hizo overflow
f0102f8f:	f7 db                	neg    %ebx
						cprintf("FLAGFALSE\n");}//DEBUG2
f0102f91:	83 ec 0c             	sub    $0xc,%esp
f0102f94:	68 7d 5c 10 f0       	push   $0xf0105c7d
f0102f99:	e8 60 07 00 00       	call   f01036fe <cprintf>
f0102f9e:	83 c4 10             	add    $0x10,%esp
f0102fa1:	eb 5f                	jmp    f0103002 <region_alloc+0xc1>
	while (len>0){
		struct PageInfo* page = page_alloc(0);//no hay que inicializar
f0102fa3:	83 ec 0c             	sub    $0xc,%esp
f0102fa6:	6a 00                	push   $0x0
f0102fa8:	e8 6d e3 ff ff       	call   f010131a <page_alloc>
		if (page == NULL) panic("Error allocating environment");
f0102fad:	83 c4 10             	add    $0x10,%esp
f0102fb0:	85 c0                	test   %eax,%eax
f0102fb2:	75 17                	jne    f0102fcb <region_alloc+0x8a>
f0102fb4:	83 ec 04             	sub    $0x4,%esp
f0102fb7:	68 88 5c 10 f0       	push   $0xf0105c88
f0102fbc:	68 1f 01 00 00       	push   $0x11f
f0102fc1:	68 5c 5c 10 f0       	push   $0xf0105c5c
f0102fc6:	e8 de d0 ff ff       	call   f01000a9 <_panic>

		int ret_code = page_insert(e->env_pgdir, page, va, PTE_W | PTE_U);
f0102fcb:	6a 06                	push   $0x6
f0102fcd:	56                   	push   %esi
f0102fce:	50                   	push   %eax
f0102fcf:	ff 77 5c             	pushl  0x5c(%edi)
f0102fd2:	e8 d1 ea ff ff       	call   f0101aa8 <page_insert>
		if (ret_code == -E_NO_MEM)	panic("Error allocating environment");
f0102fd7:	83 c4 10             	add    $0x10,%esp
f0102fda:	83 f8 fc             	cmp    $0xfffffffc,%eax
f0102fdd:	75 17                	jne    f0102ff6 <region_alloc+0xb5>
f0102fdf:	83 ec 04             	sub    $0x4,%esp
f0102fe2:	68 88 5c 10 f0       	push   $0xf0105c88
f0102fe7:	68 22 01 00 00       	push   $0x122
f0102fec:	68 5c 5c 10 f0       	push   $0xf0105c5c
f0102ff1:	e8 b3 d0 ff ff       	call   f01000a9 <_panic>
		
		va+=PGSIZE;
f0102ff6:	81 c6 00 10 00 00    	add    $0x1000,%esi
		len-=PGSIZE;
f0102ffc:	81 eb 00 10 00 00    	sub    $0x1000,%ebx
	cprintf("checkpoint\n");//DEBUG2
	if (va_finish>va) {len = va_finish - va; //es un multiplo de PGSIZE	
						cprintf("FLAGTRUE\n");}//DEBUG2
	else {len = ~0x0-(uint32_t)va+1;//si hizo overflow
						cprintf("FLAGFALSE\n");}//DEBUG2
	while (len>0){
f0103002:	85 db                	test   %ebx,%ebx
f0103004:	75 9d                	jne    f0102fa3 <region_alloc+0x62>
		if (ret_code == -E_NO_MEM)	panic("Error allocating environment");
		
		va+=PGSIZE;
		len-=PGSIZE;
	}
	assert(va==va_finish);
f0103006:	3b 75 e4             	cmp    -0x1c(%ebp),%esi
f0103009:	74 19                	je     f0103024 <region_alloc+0xe3>
f010300b:	68 a5 5c 10 f0       	push   $0xf0105ca5
f0103010:	68 ba 58 10 f0       	push   $0xf01058ba
f0103015:	68 27 01 00 00       	push   $0x127
f010301a:	68 5c 5c 10 f0       	push   $0xf0105c5c
f010301f:	e8 85 d0 ff ff       	call   f01000a9 <_panic>
}
f0103024:	8d 65 f4             	lea    -0xc(%ebp),%esp
f0103027:	5b                   	pop    %ebx
f0103028:	5e                   	pop    %esi
f0103029:	5f                   	pop    %edi
f010302a:	5d                   	pop    %ebp
f010302b:	c3                   	ret    

f010302c <load_icode>:
// load_icode panics if it encounters problems.
//  - How might load_icode fail?  What might be wrong with the given input?
//
static void
load_icode(struct Env *e, uint8_t *binary)
{
f010302c:	55                   	push   %ebp
f010302d:	89 e5                	mov    %esp,%ebp
f010302f:	57                   	push   %edi
f0103030:	56                   	push   %esi
f0103031:	53                   	push   %ebx
f0103032:	83 ec 1c             	sub    $0x1c,%esp
f0103035:	89 45 e0             	mov    %eax,-0x20(%ebp)
f0103038:	89 d6                	mov    %edx,%esi
	//  to make sure that the environment starts executing there.
	//  What?  (See env_run() and env_pop_tf() below.)

	// LAB 3: Your code here.

	cprintf("rcr3 da %p\n,kern_pgdir es %p, env_pgdir es %p\n",(void*)rcr3(),kern_pgdir,e->env_pgdir);//DEBUG2
f010303a:	8b 78 5c             	mov    0x5c(%eax),%edi
f010303d:	8b 1d 88 6f 18 f0    	mov    0xf0186f88,%ebx
f0103043:	e8 da fd ff ff       	call   f0102e22 <rcr3>
f0103048:	57                   	push   %edi
f0103049:	53                   	push   %ebx
f010304a:	50                   	push   %eax
f010304b:	68 cc 5b 10 f0       	push   $0xf0105bcc
f0103050:	e8 a9 06 00 00       	call   f01036fe <cprintf>
	assert(rcr3()==PADDR(kern_pgdir));
f0103055:	e8 c8 fd ff ff       	call   f0102e22 <rcr3>
f010305a:	89 c3                	mov    %eax,%ebx
f010305c:	8b 0d 88 6f 18 f0    	mov    0xf0186f88,%ecx
f0103062:	ba 62 01 00 00       	mov    $0x162,%edx
f0103067:	b8 5c 5c 10 f0       	mov    $0xf0105c5c,%eax
f010306c:	e8 14 fe ff ff       	call   f0102e85 <_paddr>
f0103071:	83 c4 10             	add    $0x10,%esp
f0103074:	39 c3                	cmp    %eax,%ebx
f0103076:	74 19                	je     f0103091 <load_icode+0x65>
f0103078:	68 b3 5c 10 f0       	push   $0xf0105cb3
f010307d:	68 ba 58 10 f0       	push   $0xf01058ba
f0103082:	68 62 01 00 00       	push   $0x162
f0103087:	68 5c 5c 10 f0       	push   $0xf0105c5c
f010308c:	e8 18 d0 ff ff       	call   f01000a9 <_panic>
	lcr3(PADDR(e->env_pgdir));//cambio a pgdir del env para que anden memcpy y memset
f0103091:	8b 45 e0             	mov    -0x20(%ebp),%eax
f0103094:	8b 48 5c             	mov    0x5c(%eax),%ecx
f0103097:	ba 63 01 00 00       	mov    $0x163,%edx
f010309c:	b8 5c 5c 10 f0       	mov    $0xf0105c5c,%eax
f01030a1:	e8 df fd ff ff       	call   f0102e85 <_paddr>
f01030a6:	e8 6f fd ff ff       	call   f0102e1a <lcr3>

	struct Elf* elf = (struct Elf *) binary;
	if (elf->e_magic != ELF_MAGIC) panic("Invalid binary");
f01030ab:	81 3e 7f 45 4c 46    	cmpl   $0x464c457f,(%esi)
f01030b1:	74 17                	je     f01030ca <load_icode+0x9e>
f01030b3:	83 ec 04             	sub    $0x4,%esp
f01030b6:	68 cd 5c 10 f0       	push   $0xf0105ccd
f01030bb:	68 66 01 00 00       	push   $0x166
f01030c0:	68 5c 5c 10 f0       	push   $0xf0105c5c
f01030c5:	e8 df cf ff ff       	call   f01000a9 <_panic>

	struct Proghdr* ph = (struct Proghdr*)(binary + elf->e_phoff);
f01030ca:	89 f3                	mov    %esi,%ebx
f01030cc:	03 5e 1c             	add    0x1c(%esi),%ebx
	void* va;
	for (int hdr_num = 0; hdr_num < elf->e_phnum; hdr_num++){
f01030cf:	bf 00 00 00 00       	mov    $0x0,%edi
f01030d4:	e9 d6 00 00 00       	jmp    f01031af <load_icode+0x183>
		va=(void*) ph->p_va;
		if (ph->p_type != ELF_PROG_LOAD) continue;
f01030d9:	83 3b 01             	cmpl   $0x1,(%ebx)
f01030dc:	0f 85 ca 00 00 00    	jne    f01031ac <load_icode+0x180>
	if (elf->e_magic != ELF_MAGIC) panic("Invalid binary");

	struct Proghdr* ph = (struct Proghdr*)(binary + elf->e_phoff);
	void* va;
	for (int hdr_num = 0; hdr_num < elf->e_phnum; hdr_num++){
		va=(void*) ph->p_va;
f01030e2:	8b 43 08             	mov    0x8(%ebx),%eax
		if (ph->p_type != ELF_PROG_LOAD) continue;
		region_alloc(e,va,ph->p_memsz);
f01030e5:	8b 4b 14             	mov    0x14(%ebx),%ecx
f01030e8:	89 45 e4             	mov    %eax,-0x1c(%ebp)
f01030eb:	89 c2                	mov    %eax,%edx
f01030ed:	8b 45 e0             	mov    -0x20(%ebp),%eax
f01030f0:	e8 4c fe ff ff       	call   f0102f41 <region_alloc>
		cprintf("\tVA es %p\n",va);//DEBUG2
f01030f5:	83 ec 08             	sub    $0x8,%esp
f01030f8:	ff 75 e4             	pushl  -0x1c(%ebp)
f01030fb:	68 dc 5c 10 f0       	push   $0xf0105cdc
f0103100:	e8 f9 05 00 00       	call   f01036fe <cprintf>
		cprintf("\tbinary es %p\n",binary);//DEBUG2
f0103105:	83 c4 08             	add    $0x8,%esp
f0103108:	56                   	push   %esi
f0103109:	68 e7 5c 10 f0       	push   $0xf0105ce7
f010310e:	e8 eb 05 00 00       	call   f01036fe <cprintf>
		cprintf("\tph es %p\n",ph);//DEBUG2
f0103113:	83 c4 08             	add    $0x8,%esp
f0103116:	53                   	push   %ebx
f0103117:	68 f6 5c 10 f0       	push   $0xf0105cf6
f010311c:	e8 dd 05 00 00       	call   f01036fe <cprintf>
		cprintf("\tp_offset es %p\n",ph->p_offset);//DEBUG2
f0103121:	83 c4 08             	add    $0x8,%esp
f0103124:	ff 73 04             	pushl  0x4(%ebx)
f0103127:	68 01 5d 10 f0       	push   $0xf0105d01
f010312c:	e8 cd 05 00 00       	call   f01036fe <cprintf>
		cprintf("\tbin+p_off es %p\n",(void*)binary+ph->p_offset);//DEBUG2
f0103131:	83 c4 08             	add    $0x8,%esp
f0103134:	89 f0                	mov    %esi,%eax
f0103136:	03 43 04             	add    0x4(%ebx),%eax
f0103139:	50                   	push   %eax
f010313a:	68 12 5d 10 f0       	push   $0xf0105d12
f010313f:	e8 ba 05 00 00       	call   f01036fe <cprintf>
		cprintf("\tfilesz es %d y memsz es %d\n",ph->p_filesz,ph->p_memsz);//DEBUG2
f0103144:	83 c4 0c             	add    $0xc,%esp
f0103147:	ff 73 14             	pushl  0x14(%ebx)
f010314a:	ff 73 10             	pushl  0x10(%ebx)
f010314d:	68 24 5d 10 f0       	push   $0xf0105d24
f0103152:	e8 a7 05 00 00       	call   f01036fe <cprintf>
		cprintf("\tentsize es %d\n",elf->e_phentsize);//DEBUG2
f0103157:	83 c4 08             	add    $0x8,%esp
f010315a:	0f b7 46 2a          	movzwl 0x2a(%esi),%eax
f010315e:	50                   	push   %eax
f010315f:	68 41 5d 10 f0       	push   $0xf0105d41
f0103164:	e8 95 05 00 00       	call   f01036fe <cprintf>
		memcpy(va,(void*)binary+ph->p_offset,ph->p_filesz);
f0103169:	83 c4 0c             	add    $0xc,%esp
f010316c:	ff 73 10             	pushl  0x10(%ebx)
f010316f:	89 f0                	mov    %esi,%eax
f0103171:	03 43 04             	add    0x4(%ebx),%eax
f0103174:	50                   	push   %eax
f0103175:	ff 75 e4             	pushl  -0x1c(%ebp)
f0103178:	e8 00 16 00 00       	call   f010477d <memcpy>
		cprintf("\thizo el memcpy\n");//DEBUG2
f010317d:	c7 04 24 51 5d 10 f0 	movl   $0xf0105d51,(%esp)
f0103184:	e8 75 05 00 00       	call   f01036fe <cprintf>
		memset(va + ph->p_filesz,0,ph->p_memsz - ph->p_filesz);//VA+FILESZ->VA+MEMSZ
f0103189:	8b 43 10             	mov    0x10(%ebx),%eax
f010318c:	83 c4 0c             	add    $0xc,%esp
f010318f:	8b 4b 14             	mov    0x14(%ebx),%ecx
f0103192:	29 c1                	sub    %eax,%ecx
f0103194:	51                   	push   %ecx
f0103195:	6a 00                	push   $0x0
f0103197:	03 45 e4             	add    -0x1c(%ebp),%eax
f010319a:	50                   	push   %eax
f010319b:	e8 27 15 00 00       	call   f01046c7 <memset>
		ph += elf->e_phentsize;
f01031a0:	0f b7 46 2a          	movzwl 0x2a(%esi),%eax
f01031a4:	c1 e0 05             	shl    $0x5,%eax
f01031a7:	01 c3                	add    %eax,%ebx
f01031a9:	83 c4 10             	add    $0x10,%esp
	struct Elf* elf = (struct Elf *) binary;
	if (elf->e_magic != ELF_MAGIC) panic("Invalid binary");

	struct Proghdr* ph = (struct Proghdr*)(binary + elf->e_phoff);
	void* va;
	for (int hdr_num = 0; hdr_num < elf->e_phnum; hdr_num++){
f01031ac:	83 c7 01             	add    $0x1,%edi
f01031af:	0f b7 46 2c          	movzwl 0x2c(%esi),%eax
f01031b3:	39 c7                	cmp    %eax,%edi
f01031b5:	0f 8c 1e ff ff ff    	jl     f01030d9 <load_icode+0xad>
		memset(va + ph->p_filesz,0,ph->p_memsz - ph->p_filesz);//VA+FILESZ->VA+MEMSZ
		ph += elf->e_phentsize;
	}


	e->env_tf.tf_eip=elf->e_entry;
f01031bb:	8b 46 18             	mov    0x18(%esi),%eax
f01031be:	8b 7d e0             	mov    -0x20(%ebp),%edi
f01031c1:	89 47 30             	mov    %eax,0x30(%edi)
	// Now map one page for the program's initial stack
	// at virtual address USTACKTOP - PGSIZE.

	// LAB 3: Your code here.

	region_alloc(e,(void*)USTACKTOP - PGSIZE,PGSIZE);
f01031c4:	b9 00 10 00 00       	mov    $0x1000,%ecx
f01031c9:	ba 00 d0 bf ee       	mov    $0xeebfd000,%edx
f01031ce:	89 f8                	mov    %edi,%eax
f01031d0:	e8 6c fd ff ff       	call   f0102f41 <region_alloc>

	lcr3(PADDR(kern_pgdir));//vuelvo a poner el pgdir del kernel 
f01031d5:	8b 0d 88 6f 18 f0    	mov    0xf0186f88,%ecx
f01031db:	ba 85 01 00 00       	mov    $0x185,%edx
f01031e0:	b8 5c 5c 10 f0       	mov    $0xf0105c5c,%eax
f01031e5:	e8 9b fc ff ff       	call   f0102e85 <_paddr>
f01031ea:	e8 2b fc ff ff       	call   f0102e1a <lcr3>
}
f01031ef:	8d 65 f4             	lea    -0xc(%ebp),%esp
f01031f2:	5b                   	pop    %ebx
f01031f3:	5e                   	pop    %esi
f01031f4:	5f                   	pop    %edi
f01031f5:	5d                   	pop    %ebp
f01031f6:	c3                   	ret    

f01031f7 <envid2env>:
//   On success, sets *env_store to the environment.
//   On error, sets *env_store to NULL.
//
int
envid2env(envid_t envid, struct Env **env_store, bool checkperm)
{
f01031f7:	55                   	push   %ebp
f01031f8:	89 e5                	mov    %esp,%ebp
f01031fa:	8b 55 08             	mov    0x8(%ebp),%edx
f01031fd:	8b 4d 10             	mov    0x10(%ebp),%ecx
	struct Env *e;

	// If envid is zero, return the current environment.
	if (envid == 0) {
f0103200:	85 d2                	test   %edx,%edx
f0103202:	75 11                	jne    f0103215 <envid2env+0x1e>
		*env_store = curenv;
f0103204:	a1 c4 52 18 f0       	mov    0xf01852c4,%eax
f0103209:	8b 4d 0c             	mov    0xc(%ebp),%ecx
f010320c:	89 01                	mov    %eax,(%ecx)
		return 0;
f010320e:	b8 00 00 00 00       	mov    $0x0,%eax
f0103213:	eb 5e                	jmp    f0103273 <envid2env+0x7c>
	// Look up the Env structure via the index part of the envid,
	// then check the env_id field in that struct Env
	// to ensure that the envid is not stale
	// (i.e., does not refer to a _previous_ environment
	// that used the same slot in the envs[] array).
	e = &envs[ENVX(envid)];
f0103215:	89 d0                	mov    %edx,%eax
f0103217:	25 ff 03 00 00       	and    $0x3ff,%eax
f010321c:	8d 04 40             	lea    (%eax,%eax,2),%eax
f010321f:	c1 e0 05             	shl    $0x5,%eax
f0103222:	03 05 c8 52 18 f0    	add    0xf01852c8,%eax
	if (e->env_status == ENV_FREE || e->env_id != envid) {
f0103228:	83 78 54 00          	cmpl   $0x0,0x54(%eax)
f010322c:	74 05                	je     f0103233 <envid2env+0x3c>
f010322e:	3b 50 48             	cmp    0x48(%eax),%edx
f0103231:	74 10                	je     f0103243 <envid2env+0x4c>
		*env_store = 0;
f0103233:	8b 45 0c             	mov    0xc(%ebp),%eax
f0103236:	c7 00 00 00 00 00    	movl   $0x0,(%eax)
		return -E_BAD_ENV;
f010323c:	b8 fe ff ff ff       	mov    $0xfffffffe,%eax
f0103241:	eb 30                	jmp    f0103273 <envid2env+0x7c>
	// Check that the calling environment has legitimate permission
	// to manipulate the specified environment.
	// If checkperm is set, the specified environment
	// must be either the current environment
	// or an immediate child of the current environment.
	if (checkperm && e != curenv && e->env_parent_id != curenv->env_id) {
f0103243:	84 c9                	test   %cl,%cl
f0103245:	74 22                	je     f0103269 <envid2env+0x72>
f0103247:	8b 15 c4 52 18 f0    	mov    0xf01852c4,%edx
f010324d:	39 d0                	cmp    %edx,%eax
f010324f:	74 18                	je     f0103269 <envid2env+0x72>
f0103251:	8b 4a 48             	mov    0x48(%edx),%ecx
f0103254:	39 48 4c             	cmp    %ecx,0x4c(%eax)
f0103257:	74 10                	je     f0103269 <envid2env+0x72>
		*env_store = 0;
f0103259:	8b 45 0c             	mov    0xc(%ebp),%eax
f010325c:	c7 00 00 00 00 00    	movl   $0x0,(%eax)
		return -E_BAD_ENV;
f0103262:	b8 fe ff ff ff       	mov    $0xfffffffe,%eax
f0103267:	eb 0a                	jmp    f0103273 <envid2env+0x7c>
	}

	*env_store = e;
f0103269:	8b 4d 0c             	mov    0xc(%ebp),%ecx
f010326c:	89 01                	mov    %eax,(%ecx)
	return 0;
f010326e:	b8 00 00 00 00       	mov    $0x0,%eax
}
f0103273:	5d                   	pop    %ebp
f0103274:	c3                   	ret    

f0103275 <env_init_percpu>:
}

// Load GDT and segment descriptors.
void
env_init_percpu(void)
{
f0103275:	55                   	push   %ebp
f0103276:	89 e5                	mov    %esp,%ebp
	lgdt(&gdt_pd);
f0103278:	b8 00 b3 11 f0       	mov    $0xf011b300,%eax
f010327d:	e8 88 fb ff ff       	call   f0102e0a <lgdt>
	// The kernel never uses GS or FS, so we leave those set to
	// the user data segment.
	asm volatile("movw %%ax,%%gs" : : "a"(GD_UD | 3));
f0103282:	b8 23 00 00 00       	mov    $0x23,%eax
f0103287:	8e e8                	mov    %eax,%gs
	asm volatile("movw %%ax,%%fs" : : "a"(GD_UD | 3));
f0103289:	8e e0                	mov    %eax,%fs
	// The kernel does use ES, DS, and SS.  We'll change between
	// the kernel and user data segments as needed.
	asm volatile("movw %%ax,%%es" : : "a"(GD_KD));
f010328b:	b8 10 00 00 00       	mov    $0x10,%eax
f0103290:	8e c0                	mov    %eax,%es
	asm volatile("movw %%ax,%%ds" : : "a"(GD_KD));
f0103292:	8e d8                	mov    %eax,%ds
	asm volatile("movw %%ax,%%ss" : : "a"(GD_KD));
f0103294:	8e d0                	mov    %eax,%ss
	// Load the kernel text segment into CS.
	asm volatile("ljmp %0,$1f\n 1:\n" : : "i"(GD_KT));
f0103296:	ea 9d 32 10 f0 08 00 	ljmp   $0x8,$0xf010329d
	// For good measure, clear the local descriptor table (LDT),
	// since we don't use it.
	lldt(0);
f010329d:	b8 00 00 00 00       	mov    $0x0,%eax
f01032a2:	e8 6b fb ff ff       	call   f0102e12 <lldt>
}
f01032a7:	5d                   	pop    %ebp
f01032a8:	c3                   	ret    

f01032a9 <env_init>:
// they are in the envs array (i.e., so that the first call to
// env_alloc() returns envs[0]).
//
void
env_init(void)
{
f01032a9:	55                   	push   %ebp
f01032aa:	89 e5                	mov    %esp,%ebp
f01032ac:	56                   	push   %esi
f01032ad:	53                   	push   %ebx
	// Set up envs array
	// LAB 3: Your code here. (OK)
	for (size_t i=0; i< NENV; i++){
		envs[i].env_status = ENV_FREE; 
f01032ae:	8b 35 c8 52 18 f0    	mov    0xf01852c8,%esi
f01032b4:	8b 15 cc 52 18 f0    	mov    0xf01852cc,%edx
f01032ba:	89 f0                	mov    %esi,%eax
f01032bc:	8d 9e 00 80 01 00    	lea    0x18000(%esi),%ebx
f01032c2:	89 c1                	mov    %eax,%ecx
f01032c4:	c7 40 54 00 00 00 00 	movl   $0x0,0x54(%eax)
		envs[i].env_id = 0;
f01032cb:	c7 40 48 00 00 00 00 	movl   $0x0,0x48(%eax)
		envs[i].env_link = env_free_list;
f01032d2:	89 50 44             	mov    %edx,0x44(%eax)
f01032d5:	83 c0 60             	add    $0x60,%eax
		env_free_list = &envs[i];
f01032d8:	89 ca                	mov    %ecx,%edx
void
env_init(void)
{
	// Set up envs array
	// LAB 3: Your code here. (OK)
	for (size_t i=0; i< NENV; i++){
f01032da:	39 d8                	cmp    %ebx,%eax
f01032dc:	75 e4                	jne    f01032c2 <env_init+0x19>
f01032de:	81 c6 a0 7f 01 00    	add    $0x17fa0,%esi
f01032e4:	89 35 cc 52 18 f0    	mov    %esi,0xf01852cc
		envs[i].env_link = env_free_list;
		env_free_list = &envs[i];
	}

	// Per-CPU part of the initialization
	env_init_percpu();
f01032ea:	e8 86 ff ff ff       	call   f0103275 <env_init_percpu>
}
f01032ef:	5b                   	pop    %ebx
f01032f0:	5e                   	pop    %esi
f01032f1:	5d                   	pop    %ebp
f01032f2:	c3                   	ret    

f01032f3 <env_alloc>:
//	-E_NO_FREE_ENV if all NENVS environments are allocated
//	-E_NO_MEM on memory exhaustion
//
int
env_alloc(struct Env **newenv_store, envid_t parent_id)
{
f01032f3:	55                   	push   %ebp
f01032f4:	89 e5                	mov    %esp,%ebp
f01032f6:	53                   	push   %ebx
f01032f7:	83 ec 04             	sub    $0x4,%esp
	int32_t generation;
	int r;
	struct Env *e;

	if (!(e = env_free_list))
f01032fa:	8b 1d cc 52 18 f0    	mov    0xf01852cc,%ebx
f0103300:	85 db                	test   %ebx,%ebx
f0103302:	0f 84 c0 00 00 00    	je     f01033c8 <env_alloc+0xd5>
		return -E_NO_FREE_ENV;

	// Allocate and set up the page directory for this environment.
	if ((r = env_setup_vm(e)) < 0)
f0103308:	89 d8                	mov    %ebx,%eax
f010330a:	e8 98 fb ff ff       	call   f0102ea7 <env_setup_vm>
f010330f:	85 c0                	test   %eax,%eax
f0103311:	0f 88 b6 00 00 00    	js     f01033cd <env_alloc+0xda>
		return r;

	// Generate an env_id for this environment.
	generation = (e->env_id + (1 << ENVGENSHIFT)) & ~(NENV - 1);
f0103317:	8b 43 48             	mov    0x48(%ebx),%eax
f010331a:	05 00 10 00 00       	add    $0x1000,%eax
	if (generation <= 0)  // Don't create a negative env_id.
f010331f:	25 00 fc ff ff       	and    $0xfffffc00,%eax
		generation = 1 << ENVGENSHIFT;
f0103324:	ba 00 10 00 00       	mov    $0x1000,%edx
f0103329:	0f 4e c2             	cmovle %edx,%eax
	e->env_id = generation | (e - envs);
f010332c:	89 da                	mov    %ebx,%edx
f010332e:	2b 15 c8 52 18 f0    	sub    0xf01852c8,%edx
f0103334:	c1 fa 05             	sar    $0x5,%edx
f0103337:	69 d2 ab aa aa aa    	imul   $0xaaaaaaab,%edx,%edx
f010333d:	09 d0                	or     %edx,%eax
f010333f:	89 43 48             	mov    %eax,0x48(%ebx)

	// Set the basic status variables.
	e->env_parent_id = parent_id;
f0103342:	8b 45 0c             	mov    0xc(%ebp),%eax
f0103345:	89 43 4c             	mov    %eax,0x4c(%ebx)
	e->env_type = ENV_TYPE_USER;
f0103348:	c7 43 50 00 00 00 00 	movl   $0x0,0x50(%ebx)
	e->env_status = ENV_RUNNABLE;
f010334f:	c7 43 54 02 00 00 00 	movl   $0x2,0x54(%ebx)
	e->env_runs = 0;
f0103356:	c7 43 58 00 00 00 00 	movl   $0x0,0x58(%ebx)

	// Clear out all the saved register state,
	// to prevent the register values
	// of a prior environment inhabiting this Env structure
	// from "leaking" into our new environment.
	memset(&e->env_tf, 0, sizeof(e->env_tf));
f010335d:	83 ec 04             	sub    $0x4,%esp
f0103360:	6a 44                	push   $0x44
f0103362:	6a 00                	push   $0x0
f0103364:	53                   	push   %ebx
f0103365:	e8 5d 13 00 00       	call   f01046c7 <memset>
	// The low 2 bits of each segment register contains the
	// Requestor Privilege Level (RPL); 3 means user mode.  When
	// we switch privilege levels, the hardware does various
	// checks involving the RPL and the Descriptor Privilege Level
	// (DPL) stored in the descriptors themselves.
	e->env_tf.tf_ds = GD_UD | 3;
f010336a:	66 c7 43 24 23 00    	movw   $0x23,0x24(%ebx)
	e->env_tf.tf_es = GD_UD | 3;
f0103370:	66 c7 43 20 23 00    	movw   $0x23,0x20(%ebx)
	e->env_tf.tf_ss = GD_UD | 3;
f0103376:	66 c7 43 40 23 00    	movw   $0x23,0x40(%ebx)
	e->env_tf.tf_esp = USTACKTOP;
f010337c:	c7 43 3c 00 e0 bf ee 	movl   $0xeebfe000,0x3c(%ebx)
	e->env_tf.tf_cs = GD_UT | 3;
f0103383:	66 c7 43 34 1b 00    	movw   $0x1b,0x34(%ebx)
	// You will set e->env_tf.tf_eip later.

	// commit the allocation
	env_free_list = e->env_link;
f0103389:	8b 43 44             	mov    0x44(%ebx),%eax
f010338c:	a3 cc 52 18 f0       	mov    %eax,0xf01852cc
	*newenv_store = e; 
f0103391:	8b 45 08             	mov    0x8(%ebp),%eax
f0103394:	89 18                	mov    %ebx,(%eax)

	cprintf("[%08x] new env %08x\n", curenv ? curenv->env_id : 0, e->env_id);
f0103396:	8b 53 48             	mov    0x48(%ebx),%edx
f0103399:	a1 c4 52 18 f0       	mov    0xf01852c4,%eax
f010339e:	83 c4 10             	add    $0x10,%esp
f01033a1:	85 c0                	test   %eax,%eax
f01033a3:	74 05                	je     f01033aa <env_alloc+0xb7>
f01033a5:	8b 40 48             	mov    0x48(%eax),%eax
f01033a8:	eb 05                	jmp    f01033af <env_alloc+0xbc>
f01033aa:	b8 00 00 00 00       	mov    $0x0,%eax
f01033af:	83 ec 04             	sub    $0x4,%esp
f01033b2:	52                   	push   %edx
f01033b3:	50                   	push   %eax
f01033b4:	68 62 5d 10 f0       	push   $0xf0105d62
f01033b9:	e8 40 03 00 00       	call   f01036fe <cprintf>
	return 0;
f01033be:	83 c4 10             	add    $0x10,%esp
f01033c1:	b8 00 00 00 00       	mov    $0x0,%eax
f01033c6:	eb 05                	jmp    f01033cd <env_alloc+0xda>
	int32_t generation;
	int r;
	struct Env *e;

	if (!(e = env_free_list))
		return -E_NO_FREE_ENV;
f01033c8:	b8 fb ff ff ff       	mov    $0xfffffffb,%eax
	env_free_list = e->env_link;
	*newenv_store = e; 

	cprintf("[%08x] new env %08x\n", curenv ? curenv->env_id : 0, e->env_id);
	return 0;
}
f01033cd:	8b 5d fc             	mov    -0x4(%ebp),%ebx
f01033d0:	c9                   	leave  
f01033d1:	c3                   	ret    

f01033d2 <env_create>:
// before running the first user-mode environment.
// The new env's parent ID is set to 0.
//
void
env_create(uint8_t *binary, enum EnvType type)
{
f01033d2:	55                   	push   %ebp
f01033d3:	89 e5                	mov    %esp,%ebp
f01033d5:	83 ec 20             	sub    $0x20,%esp
	// LAB 3: Your code here.
	struct Env* e;
	int err = env_alloc(&e,0);//hace lugar para un Env cuya dir se guarda en e, parent_id es 0 por def.
f01033d8:	6a 00                	push   $0x0
f01033da:	8d 45 f4             	lea    -0xc(%ebp),%eax
f01033dd:	50                   	push   %eax
f01033de:	e8 10 ff ff ff       	call   f01032f3 <env_alloc>
	if (err<0) panic("env_create: %e", err);
f01033e3:	83 c4 10             	add    $0x10,%esp
f01033e6:	85 c0                	test   %eax,%eax
f01033e8:	79 15                	jns    f01033ff <env_create+0x2d>
f01033ea:	50                   	push   %eax
f01033eb:	68 77 5d 10 f0       	push   $0xf0105d77
f01033f0:	68 95 01 00 00       	push   $0x195
f01033f5:	68 5c 5c 10 f0       	push   $0xf0105c5c
f01033fa:	e8 aa cc ff ff       	call   f01000a9 <_panic>
	load_icode(e,binary);
f01033ff:	8b 55 08             	mov    0x8(%ebp),%edx
f0103402:	8b 45 f4             	mov    -0xc(%ebp),%eax
f0103405:	e8 22 fc ff ff       	call   f010302c <load_icode>
	e->env_type = type;
f010340a:	8b 45 f4             	mov    -0xc(%ebp),%eax
f010340d:	8b 55 0c             	mov    0xc(%ebp),%edx
f0103410:	89 50 50             	mov    %edx,0x50(%eax)
}
f0103413:	c9                   	leave  
f0103414:	c3                   	ret    

f0103415 <env_free>:
//
// Frees env e and all memory it uses.
//
void
env_free(struct Env *e)
{
f0103415:	55                   	push   %ebp
f0103416:	89 e5                	mov    %esp,%ebp
f0103418:	57                   	push   %edi
f0103419:	56                   	push   %esi
f010341a:	53                   	push   %ebx
f010341b:	83 ec 1c             	sub    $0x1c,%esp
f010341e:	8b 7d 08             	mov    0x8(%ebp),%edi
	physaddr_t pa;

	// If freeing the current environment, switch to kern_pgdir
	// before freeing the page directory, just in case the page
	// gets reused.
	if (e == curenv)
f0103421:	39 3d c4 52 18 f0    	cmp    %edi,0xf01852c4
f0103427:	75 1a                	jne    f0103443 <env_free+0x2e>
		lcr3(PADDR(kern_pgdir));
f0103429:	8b 0d 88 6f 18 f0    	mov    0xf0186f88,%ecx
f010342f:	ba a8 01 00 00       	mov    $0x1a8,%edx
f0103434:	b8 5c 5c 10 f0       	mov    $0xf0105c5c,%eax
f0103439:	e8 47 fa ff ff       	call   f0102e85 <_paddr>
f010343e:	e8 d7 f9 ff ff       	call   f0102e1a <lcr3>

	// Note the environment's demise.
	cprintf("[%08x] free env %08x\n", curenv ? curenv->env_id : 0, e->env_id);
f0103443:	8b 57 48             	mov    0x48(%edi),%edx
f0103446:	a1 c4 52 18 f0       	mov    0xf01852c4,%eax
f010344b:	85 c0                	test   %eax,%eax
f010344d:	74 05                	je     f0103454 <env_free+0x3f>
f010344f:	8b 40 48             	mov    0x48(%eax),%eax
f0103452:	eb 05                	jmp    f0103459 <env_free+0x44>
f0103454:	b8 00 00 00 00       	mov    $0x0,%eax
f0103459:	83 ec 04             	sub    $0x4,%esp
f010345c:	52                   	push   %edx
f010345d:	50                   	push   %eax
f010345e:	68 86 5d 10 f0       	push   $0xf0105d86
f0103463:	e8 96 02 00 00       	call   f01036fe <cprintf>
f0103468:	83 c4 10             	add    $0x10,%esp

	// Flush all mapped pages in the user portion of the address space
	static_assert(UTOP % PTSIZE == 0);
	for (pdeno = 0; pdeno < PDX(UTOP); pdeno++) {
f010346b:	c7 45 e0 00 00 00 00 	movl   $0x0,-0x20(%ebp)
f0103472:	8b 4d e0             	mov    -0x20(%ebp),%ecx
f0103475:	89 c8                	mov    %ecx,%eax
f0103477:	c1 e0 02             	shl    $0x2,%eax
f010347a:	89 45 dc             	mov    %eax,-0x24(%ebp)
		// only look at mapped page tables
		if (!(e->env_pgdir[pdeno] & PTE_P))
f010347d:	8b 47 5c             	mov    0x5c(%edi),%eax
f0103480:	8b 04 88             	mov    (%eax,%ecx,4),%eax
f0103483:	a8 01                	test   $0x1,%al
f0103485:	74 72                	je     f01034f9 <env_free+0xe4>
			continue;

		// find the pa and va of the page table
		pa = PTE_ADDR(e->env_pgdir[pdeno]);
f0103487:	25 00 f0 ff ff       	and    $0xfffff000,%eax
f010348c:	89 45 d8             	mov    %eax,-0x28(%ebp)
		pt = (pte_t *) KADDR(pa);
f010348f:	89 c1                	mov    %eax,%ecx
f0103491:	ba b6 01 00 00       	mov    $0x1b6,%edx
f0103496:	b8 5c 5c 10 f0       	mov    $0xf0105c5c,%eax
f010349b:	e8 9b f9 ff ff       	call   f0102e3b <_kaddr>
f01034a0:	89 c6                	mov    %eax,%esi

		// unmap all PTEs in this page table
		for (pteno = 0; pteno <= PTX(~0); pteno++) {
			if (pt[pteno] & PTE_P)
				page_remove(e->env_pgdir, PGADDR(pdeno, pteno, 0));
f01034a2:	8b 45 e0             	mov    -0x20(%ebp),%eax
f01034a5:	c1 e0 16             	shl    $0x16,%eax
f01034a8:	89 45 e4             	mov    %eax,-0x1c(%ebp)
		// find the pa and va of the page table
		pa = PTE_ADDR(e->env_pgdir[pdeno]);
		pt = (pte_t *) KADDR(pa);

		// unmap all PTEs in this page table
		for (pteno = 0; pteno <= PTX(~0); pteno++) {
f01034ab:	bb 00 00 00 00       	mov    $0x0,%ebx
			if (pt[pteno] & PTE_P)
f01034b0:	f6 04 9e 01          	testb  $0x1,(%esi,%ebx,4)
f01034b4:	74 17                	je     f01034cd <env_free+0xb8>
				page_remove(e->env_pgdir, PGADDR(pdeno, pteno, 0));
f01034b6:	83 ec 08             	sub    $0x8,%esp
f01034b9:	89 d8                	mov    %ebx,%eax
f01034bb:	c1 e0 0c             	shl    $0xc,%eax
f01034be:	0b 45 e4             	or     -0x1c(%ebp),%eax
f01034c1:	50                   	push   %eax
f01034c2:	ff 77 5c             	pushl  0x5c(%edi)
f01034c5:	e8 95 e5 ff ff       	call   f0101a5f <page_remove>
f01034ca:	83 c4 10             	add    $0x10,%esp
		// find the pa and va of the page table
		pa = PTE_ADDR(e->env_pgdir[pdeno]);
		pt = (pte_t *) KADDR(pa);

		// unmap all PTEs in this page table
		for (pteno = 0; pteno <= PTX(~0); pteno++) {
f01034cd:	83 c3 01             	add    $0x1,%ebx
f01034d0:	81 fb 00 04 00 00    	cmp    $0x400,%ebx
f01034d6:	75 d8                	jne    f01034b0 <env_free+0x9b>
			if (pt[pteno] & PTE_P)
				page_remove(e->env_pgdir, PGADDR(pdeno, pteno, 0));
		}

		// free the page table itself
		e->env_pgdir[pdeno] = 0;
f01034d8:	8b 47 5c             	mov    0x5c(%edi),%eax
f01034db:	8b 4d dc             	mov    -0x24(%ebp),%ecx
f01034de:	c7 04 08 00 00 00 00 	movl   $0x0,(%eax,%ecx,1)
		page_decref(pa2page(pa));
f01034e5:	8b 45 d8             	mov    -0x28(%ebp),%eax
f01034e8:	e8 28 fa ff ff       	call   f0102f15 <pa2page>
f01034ed:	83 ec 0c             	sub    $0xc,%esp
f01034f0:	50                   	push   %eax
f01034f1:	e8 6b e3 ff ff       	call   f0101861 <page_decref>
f01034f6:	83 c4 10             	add    $0x10,%esp
	// Note the environment's demise.
	cprintf("[%08x] free env %08x\n", curenv ? curenv->env_id : 0, e->env_id);

	// Flush all mapped pages in the user portion of the address space
	static_assert(UTOP % PTSIZE == 0);
	for (pdeno = 0; pdeno < PDX(UTOP); pdeno++) {
f01034f9:	83 45 e0 01          	addl   $0x1,-0x20(%ebp)
f01034fd:	8b 45 e0             	mov    -0x20(%ebp),%eax
f0103500:	3d bb 03 00 00       	cmp    $0x3bb,%eax
f0103505:	0f 85 67 ff ff ff    	jne    f0103472 <env_free+0x5d>
		e->env_pgdir[pdeno] = 0;
		page_decref(pa2page(pa));
	}

	// free the page directory
	pa = PADDR(e->env_pgdir);
f010350b:	8b 4f 5c             	mov    0x5c(%edi),%ecx
f010350e:	ba c4 01 00 00       	mov    $0x1c4,%edx
f0103513:	b8 5c 5c 10 f0       	mov    $0xf0105c5c,%eax
f0103518:	e8 68 f9 ff ff       	call   f0102e85 <_paddr>
	e->env_pgdir = 0;
f010351d:	c7 47 5c 00 00 00 00 	movl   $0x0,0x5c(%edi)
	page_decref(pa2page(pa));
f0103524:	e8 ec f9 ff ff       	call   f0102f15 <pa2page>
f0103529:	83 ec 0c             	sub    $0xc,%esp
f010352c:	50                   	push   %eax
f010352d:	e8 2f e3 ff ff       	call   f0101861 <page_decref>

	// return the environment to the free list
	e->env_status = ENV_FREE;
f0103532:	c7 47 54 00 00 00 00 	movl   $0x0,0x54(%edi)
	e->env_link = env_free_list;
f0103539:	a1 cc 52 18 f0       	mov    0xf01852cc,%eax
f010353e:	89 47 44             	mov    %eax,0x44(%edi)
	env_free_list = e;
f0103541:	89 3d cc 52 18 f0    	mov    %edi,0xf01852cc
}
f0103547:	83 c4 10             	add    $0x10,%esp
f010354a:	8d 65 f4             	lea    -0xc(%ebp),%esp
f010354d:	5b                   	pop    %ebx
f010354e:	5e                   	pop    %esi
f010354f:	5f                   	pop    %edi
f0103550:	5d                   	pop    %ebp
f0103551:	c3                   	ret    

f0103552 <env_destroy>:
//
// Frees environment e.
//
void
env_destroy(struct Env *e)
{
f0103552:	55                   	push   %ebp
f0103553:	89 e5                	mov    %esp,%ebp
f0103555:	83 ec 14             	sub    $0x14,%esp
	env_free(e);
f0103558:	ff 75 08             	pushl  0x8(%ebp)
f010355b:	e8 b5 fe ff ff       	call   f0103415 <env_free>

	cprintf("Destroyed the only environment - nothing more to do!\n");
f0103560:	c7 04 24 fc 5b 10 f0 	movl   $0xf0105bfc,(%esp)
f0103567:	e8 92 01 00 00       	call   f01036fe <cprintf>
f010356c:	83 c4 10             	add    $0x10,%esp
	while (1)
		monitor(NULL);
f010356f:	83 ec 0c             	sub    $0xc,%esp
f0103572:	6a 00                	push   $0x0
f0103574:	e8 ab d4 ff ff       	call   f0100a24 <monitor>
f0103579:	83 c4 10             	add    $0x10,%esp
f010357c:	eb f1                	jmp    f010356f <env_destroy+0x1d>

f010357e <env_pop_tf>:
//
// This function does not return.
//
void
env_pop_tf(struct Trapframe *tf)
{
f010357e:	55                   	push   %ebp
f010357f:	89 e5                	mov    %esp,%ebp
f0103581:	83 ec 0c             	sub    $0xc,%esp
	asm volatile("\tmovl %0,%%esp\n"
f0103584:	8b 65 08             	mov    0x8(%ebp),%esp
f0103587:	61                   	popa   
f0103588:	07                   	pop    %es
f0103589:	1f                   	pop    %ds
f010358a:	83 c4 08             	add    $0x8,%esp
f010358d:	cf                   	iret   
	             "\taddl $0x8,%%esp\n" /* skip tf_trapno and tf_errcode */
	             "\tiret\n"
	             :
	             : "g"(tf)
	             : "memory");
	panic("iret failed"); /* mostly to placate the compiler */
f010358e:	68 9c 5d 10 f0       	push   $0xf0105d9c
f0103593:	68 ee 01 00 00       	push   $0x1ee
f0103598:	68 5c 5c 10 f0       	push   $0xf0105c5c
f010359d:	e8 07 cb ff ff       	call   f01000a9 <_panic>

f01035a2 <env_run>:
//
// This function does not return.
//
void
env_run(struct Env *e)
{
f01035a2:	55                   	push   %ebp
f01035a3:	89 e5                	mov    %esp,%ebp
f01035a5:	53                   	push   %ebx
f01035a6:	83 ec 04             	sub    $0x4,%esp
f01035a9:	8b 5d 08             	mov    0x8(%ebp),%ebx

	// LAB 3: Your code here.
	
	//panic("env_run not yet implemented");

	if(curenv != NULL){	//si no es la primera vez que se corre esto hay que guardar todo
f01035ac:	a1 c4 52 18 f0       	mov    0xf01852c4,%eax
f01035b1:	85 c0                	test   %eax,%eax
f01035b3:	74 25                	je     f01035da <env_run+0x38>
		cprintf("Estoy en un proc y su env_status es %d\n",curenv->env_status);//DEBUG2
f01035b5:	83 ec 08             	sub    $0x8,%esp
f01035b8:	ff 70 54             	pushl  0x54(%eax)
f01035bb:	68 34 5c 10 f0       	push   $0xf0105c34
f01035c0:	e8 39 01 00 00       	call   f01036fe <cprintf>
		if (curenv->env_status == ENV_RUNNING) curenv->env_status=ENV_RUNNABLE;
f01035c5:	a1 c4 52 18 f0       	mov    0xf01852c4,%eax
f01035ca:	83 c4 10             	add    $0x10,%esp
f01035cd:	83 78 54 03          	cmpl   $0x3,0x54(%eax)
f01035d1:	75 07                	jne    f01035da <env_run+0x38>
f01035d3:	c7 40 54 02 00 00 00 	movl   $0x2,0x54(%eax)
		//si FREE no tiene nada, no tiene sentido
		//si DYING ????
		//si RUNNABLE no deberia estar corriendo
		//si NOT_RUNNABLE ???
	}
	assert(e->env_status != ENV_FREE);
f01035da:	8b 43 54             	mov    0x54(%ebx),%eax
f01035dd:	85 c0                	test   %eax,%eax
f01035df:	75 19                	jne    f01035fa <env_run+0x58>
f01035e1:	68 a8 5d 10 f0       	push   $0xf0105da8
f01035e6:	68 ba 58 10 f0       	push   $0xf01058ba
f01035eb:	68 18 02 00 00       	push   $0x218
f01035f0:	68 5c 5c 10 f0       	push   $0xf0105c5c
f01035f5:	e8 af ca ff ff       	call   f01000a9 <_panic>
	assert(e->env_status == ENV_RUNNABLE);
f01035fa:	83 f8 02             	cmp    $0x2,%eax
f01035fd:	74 19                	je     f0103618 <env_run+0x76>
f01035ff:	68 c2 5d 10 f0       	push   $0xf0105dc2
f0103604:	68 ba 58 10 f0       	push   $0xf01058ba
f0103609:	68 19 02 00 00       	push   $0x219
f010360e:	68 5c 5c 10 f0       	push   $0xf0105c5c
f0103613:	e8 91 ca ff ff       	call   f01000a9 <_panic>
	curenv=e;
f0103618:	89 1d c4 52 18 f0    	mov    %ebx,0xf01852c4
	curenv->env_status = ENV_RUNNING;
f010361e:	c7 43 54 03 00 00 00 	movl   $0x3,0x54(%ebx)
	curenv->env_runs++;
f0103625:	83 43 58 01          	addl   $0x1,0x58(%ebx)
	cprintf("env_pgdir es %p",e->env_pgdir);
f0103629:	83 ec 08             	sub    $0x8,%esp
f010362c:	ff 73 5c             	pushl  0x5c(%ebx)
f010362f:	68 e0 5d 10 f0       	push   $0xf0105de0
f0103634:	e8 c5 00 00 00       	call   f01036fe <cprintf>
	lcr3(PADDR(curenv->env_pgdir));
f0103639:	a1 c4 52 18 f0       	mov    0xf01852c4,%eax
f010363e:	8b 48 5c             	mov    0x5c(%eax),%ecx
f0103641:	ba 1e 02 00 00       	mov    $0x21e,%edx
f0103646:	b8 5c 5c 10 f0       	mov    $0xf0105c5c,%eax
f010364b:	e8 35 f8 ff ff       	call   f0102e85 <_paddr>
f0103650:	e8 c5 f7 ff ff       	call   f0102e1a <lcr3>
	env_pop_tf(&(curenv->env_tf));
f0103655:	83 c4 04             	add    $0x4,%esp
f0103658:	ff 35 c4 52 18 f0    	pushl  0xf01852c4
f010365e:	e8 1b ff ff ff       	call   f010357e <env_pop_tf>

f0103663 <inb>:
	asm volatile("int3");
}

static inline uint8_t
inb(int port)
{
f0103663:	55                   	push   %ebp
f0103664:	89 e5                	mov    %esp,%ebp
	uint8_t data;
	asm volatile("inb %w1,%0" : "=a" (data) : "d" (port));
f0103666:	89 c2                	mov    %eax,%edx
f0103668:	ec                   	in     (%dx),%al
	return data;
}
f0103669:	5d                   	pop    %ebp
f010366a:	c3                   	ret    

f010366b <outb>:
		     : "memory", "cc");
}

static inline void
outb(int port, uint8_t data)
{
f010366b:	55                   	push   %ebp
f010366c:	89 e5                	mov    %esp,%ebp
f010366e:	89 c1                	mov    %eax,%ecx
f0103670:	89 d0                	mov    %edx,%eax
	asm volatile("outb %0,%w1" : : "a" (data), "d" (port));
f0103672:	89 ca                	mov    %ecx,%edx
f0103674:	ee                   	out    %al,(%dx)
}
f0103675:	5d                   	pop    %ebp
f0103676:	c3                   	ret    

f0103677 <mc146818_read>:
#include <kern/kclock.h>


unsigned
mc146818_read(unsigned reg)
{
f0103677:	55                   	push   %ebp
f0103678:	89 e5                	mov    %esp,%ebp
f010367a:	0f b6 55 08          	movzbl 0x8(%ebp),%edx
	outb(IO_RTC, reg);
f010367e:	b8 70 00 00 00       	mov    $0x70,%eax
f0103683:	e8 e3 ff ff ff       	call   f010366b <outb>
	return inb(IO_RTC+1);
f0103688:	b8 71 00 00 00       	mov    $0x71,%eax
f010368d:	e8 d1 ff ff ff       	call   f0103663 <inb>
f0103692:	0f b6 c0             	movzbl %al,%eax
}
f0103695:	5d                   	pop    %ebp
f0103696:	c3                   	ret    

f0103697 <mc146818_write>:

void
mc146818_write(unsigned reg, unsigned datum)
{
f0103697:	55                   	push   %ebp
f0103698:	89 e5                	mov    %esp,%ebp
f010369a:	0f b6 55 08          	movzbl 0x8(%ebp),%edx
	outb(IO_RTC, reg);
f010369e:	b8 70 00 00 00       	mov    $0x70,%eax
f01036a3:	e8 c3 ff ff ff       	call   f010366b <outb>
f01036a8:	0f b6 55 0c          	movzbl 0xc(%ebp),%edx
	outb(IO_RTC+1, datum);
f01036ac:	b8 71 00 00 00       	mov    $0x71,%eax
f01036b1:	e8 b5 ff ff ff       	call   f010366b <outb>
}
f01036b6:	5d                   	pop    %ebp
f01036b7:	c3                   	ret    

f01036b8 <putch>:
#include <inc/stdarg.h>


static void
putch(int ch, int *cnt)
{
f01036b8:	55                   	push   %ebp
f01036b9:	89 e5                	mov    %esp,%ebp
f01036bb:	83 ec 18             	sub    $0x18,%esp
	cputchar(ch);
f01036be:	8b 45 08             	mov    0x8(%ebp),%eax
f01036c1:	89 04 24             	mov    %eax,(%esp)
f01036c4:	e8 4f d0 ff ff       	call   f0100718 <cputchar>
	*cnt++;
}
f01036c9:	c9                   	leave  
f01036ca:	c3                   	ret    

f01036cb <vcprintf>:

int
vcprintf(const char *fmt, va_list ap)
{
f01036cb:	55                   	push   %ebp
f01036cc:	89 e5                	mov    %esp,%ebp
f01036ce:	83 ec 28             	sub    $0x28,%esp
	int cnt = 0;
f01036d1:	c7 45 f4 00 00 00 00 	movl   $0x0,-0xc(%ebp)

	vprintfmt((void*)putch, &cnt, fmt, ap);
f01036d8:	8b 45 0c             	mov    0xc(%ebp),%eax
f01036db:	89 44 24 0c          	mov    %eax,0xc(%esp)
f01036df:	8b 45 08             	mov    0x8(%ebp),%eax
f01036e2:	89 44 24 08          	mov    %eax,0x8(%esp)
f01036e6:	8d 45 f4             	lea    -0xc(%ebp),%eax
f01036e9:	89 44 24 04          	mov    %eax,0x4(%esp)
f01036ed:	c7 04 24 b8 36 10 f0 	movl   $0xf01036b8,(%esp)
f01036f4:	e8 67 09 00 00       	call   f0104060 <vprintfmt>
	return cnt;
}
f01036f9:	8b 45 f4             	mov    -0xc(%ebp),%eax
f01036fc:	c9                   	leave  
f01036fd:	c3                   	ret    

f01036fe <cprintf>:

int
cprintf(const char *fmt, ...)
{
f01036fe:	55                   	push   %ebp
f01036ff:	89 e5                	mov    %esp,%ebp
f0103701:	83 ec 18             	sub    $0x18,%esp
	va_list ap;
	int cnt;

	va_start(ap, fmt);
f0103704:	8d 45 0c             	lea    0xc(%ebp),%eax
	cnt = vcprintf(fmt, ap);
f0103707:	89 44 24 04          	mov    %eax,0x4(%esp)
f010370b:	8b 45 08             	mov    0x8(%ebp),%eax
f010370e:	89 04 24             	mov    %eax,(%esp)
f0103711:	e8 b5 ff ff ff       	call   f01036cb <vcprintf>
	va_end(ap);

	return cnt;
}
f0103716:	c9                   	leave  
f0103717:	c3                   	ret    

f0103718 <lidt>:
	asm volatile("invlpg (%0)" : : "r" (addr) : "memory");
}

static inline void
lidt(void *p)
{
f0103718:	55                   	push   %ebp
f0103719:	89 e5                	mov    %esp,%ebp
	asm volatile("lidt (%0)" : : "r" (p));
f010371b:	0f 01 18             	lidtl  (%eax)
}
f010371e:	5d                   	pop    %ebp
f010371f:	c3                   	ret    

f0103720 <ltr>:
	asm volatile("lldt %0" : : "r" (sel));
}

static inline void
ltr(uint16_t sel)
{
f0103720:	55                   	push   %ebp
f0103721:	89 e5                	mov    %esp,%ebp
	asm volatile("ltr %0" : : "r" (sel));
f0103723:	0f 00 d8             	ltr    %ax
}
f0103726:	5d                   	pop    %ebp
f0103727:	c3                   	ret    

f0103728 <rcr2>:
	return val;
}

static inline uint32_t
rcr2(void)
{
f0103728:	55                   	push   %ebp
f0103729:	89 e5                	mov    %esp,%ebp
	uint32_t val;
	asm volatile("movl %%cr2,%0" : "=r" (val));
f010372b:	0f 20 d0             	mov    %cr2,%eax
	return val;
}
f010372e:	5d                   	pop    %ebp
f010372f:	c3                   	ret    

f0103730 <read_eflags>:
	asm volatile("movl %0,%%cr3" : : "r" (cr3));
}

static inline uint32_t
read_eflags(void)
{
f0103730:	55                   	push   %ebp
f0103731:	89 e5                	mov    %esp,%ebp
	uint32_t eflags;
	asm volatile("pushfl; popl %0" : "=r" (eflags));
f0103733:	9c                   	pushf  
f0103734:	58                   	pop    %eax
	return eflags;
}
f0103735:	5d                   	pop    %ebp
f0103736:	c3                   	ret    

f0103737 <trapname>:
struct Pseudodesc idt_pd = { sizeof(idt) - 1, (uint32_t) idt };


static const char *
trapname(int trapno)
{
f0103737:	55                   	push   %ebp
f0103738:	89 e5                	mov    %esp,%ebp
		"Alignment Check",
		"Machine-Check",
		"SIMD Floating-Point Exception"
	};

	if (trapno < ARRAY_SIZE(excnames))
f010373a:	83 f8 13             	cmp    $0x13,%eax
f010373d:	77 09                	ja     f0103748 <trapname+0x11>
		return excnames[trapno];
f010373f:	8b 04 85 60 61 10 f0 	mov    -0xfef9ea0(,%eax,4),%eax
f0103746:	eb 10                	jmp    f0103758 <trapname+0x21>
	if (trapno == T_SYSCALL)
f0103748:	83 f8 30             	cmp    $0x30,%eax
		return "System call";
f010374b:	b8 f0 5d 10 f0       	mov    $0xf0105df0,%eax
f0103750:	ba fc 5d 10 f0       	mov    $0xf0105dfc,%edx
f0103755:	0f 45 c2             	cmovne %edx,%eax
	return "(unknown trap)";
}
f0103758:	5d                   	pop    %ebp
f0103759:	c3                   	ret    

f010375a <trap_init_percpu>:
}

// Initialize and load the per-CPU TSS and IDT
void
trap_init_percpu(void)
{
f010375a:	55                   	push   %ebp
f010375b:	89 e5                	mov    %esp,%ebp
	// Setup a TSS so that we get the right stack
	// when we trap to the kernel.
	ts.ts_esp0 = KSTACKTOP;
f010375d:	c7 05 04 5b 18 f0 00 	movl   $0xf0000000,0xf0185b04
f0103764:	00 00 f0 
	ts.ts_ss0 = GD_KD;
f0103767:	66 c7 05 08 5b 18 f0 	movw   $0x10,0xf0185b08
f010376e:	10 00 

	// Initialize the TSS slot of the gdt.
	gdt[GD_TSS0 >> 3] =
f0103770:	66 c7 05 48 b3 11 f0 	movw   $0x67,0xf011b348
f0103777:	67 00 
f0103779:	b8 00 5b 18 f0       	mov    $0xf0185b00,%eax
f010377e:	66 a3 4a b3 11 f0    	mov    %ax,0xf011b34a
	        SEG16(STS_T32A, (uint32_t)(&ts), sizeof(struct Taskstate) - 1, 0);
f0103784:	89 c2                	mov    %eax,%edx
f0103786:	c1 ea 10             	shr    $0x10,%edx
	// when we trap to the kernel.
	ts.ts_esp0 = KSTACKTOP;
	ts.ts_ss0 = GD_KD;

	// Initialize the TSS slot of the gdt.
	gdt[GD_TSS0 >> 3] =
f0103789:	88 15 4c b3 11 f0    	mov    %dl,0xf011b34c
f010378f:	c6 05 4e b3 11 f0 40 	movb   $0x40,0xf011b34e
	        SEG16(STS_T32A, (uint32_t)(&ts), sizeof(struct Taskstate) - 1, 0);
f0103796:	c1 e8 18             	shr    $0x18,%eax
	// when we trap to the kernel.
	ts.ts_esp0 = KSTACKTOP;
	ts.ts_ss0 = GD_KD;

	// Initialize the TSS slot of the gdt.
	gdt[GD_TSS0 >> 3] =
f0103799:	a2 4f b3 11 f0       	mov    %al,0xf011b34f
	        SEG16(STS_T32A, (uint32_t)(&ts), sizeof(struct Taskstate) - 1, 0);
	gdt[GD_TSS0 >> 3].sd_s = 0;
f010379e:	c6 05 4d b3 11 f0 89 	movb   $0x89,0xf011b34d

	// Load the TSS selector (like other segment selectors, the
	// bottom three bits are special; we leave them 0)
	ltr(GD_TSS0);
f01037a5:	b8 28 00 00 00       	mov    $0x28,%eax
f01037aa:	e8 71 ff ff ff       	call   f0103720 <ltr>

	// Load the IDT
	lidt(&idt_pd);
f01037af:	b8 50 b3 11 f0       	mov    $0xf011b350,%eax
f01037b4:	e8 5f ff ff ff       	call   f0103718 <lidt>
}
f01037b9:	5d                   	pop    %ebp
f01037ba:	c3                   	ret    

f01037bb <trap_init>:
}


void
trap_init(void)
{
f01037bb:	55                   	push   %ebp
f01037bc:	89 e5                	mov    %esp,%ebp
	extern struct Segdesc gdt[];

	// LAB 3: Your code here.

	// Per-CPU setup
	trap_init_percpu();
f01037be:	e8 97 ff ff ff       	call   f010375a <trap_init_percpu>
}
f01037c3:	5d                   	pop    %ebp
f01037c4:	c3                   	ret    

f01037c5 <print_regs>:
	}
}

void
print_regs(struct PushRegs *regs)
{
f01037c5:	55                   	push   %ebp
f01037c6:	89 e5                	mov    %esp,%ebp
f01037c8:	53                   	push   %ebx
f01037c9:	83 ec 14             	sub    $0x14,%esp
f01037cc:	8b 5d 08             	mov    0x8(%ebp),%ebx
	cprintf("  edi  0x%08x\n", regs->reg_edi);
f01037cf:	8b 03                	mov    (%ebx),%eax
f01037d1:	89 44 24 04          	mov    %eax,0x4(%esp)
f01037d5:	c7 04 24 0b 5e 10 f0 	movl   $0xf0105e0b,(%esp)
f01037dc:	e8 1d ff ff ff       	call   f01036fe <cprintf>
	cprintf("  esi  0x%08x\n", regs->reg_esi);
f01037e1:	8b 43 04             	mov    0x4(%ebx),%eax
f01037e4:	89 44 24 04          	mov    %eax,0x4(%esp)
f01037e8:	c7 04 24 1a 5e 10 f0 	movl   $0xf0105e1a,(%esp)
f01037ef:	e8 0a ff ff ff       	call   f01036fe <cprintf>
	cprintf("  ebp  0x%08x\n", regs->reg_ebp);
f01037f4:	8b 43 08             	mov    0x8(%ebx),%eax
f01037f7:	89 44 24 04          	mov    %eax,0x4(%esp)
f01037fb:	c7 04 24 29 5e 10 f0 	movl   $0xf0105e29,(%esp)
f0103802:	e8 f7 fe ff ff       	call   f01036fe <cprintf>
	cprintf("  oesp 0x%08x\n", regs->reg_oesp);
f0103807:	8b 43 0c             	mov    0xc(%ebx),%eax
f010380a:	89 44 24 04          	mov    %eax,0x4(%esp)
f010380e:	c7 04 24 38 5e 10 f0 	movl   $0xf0105e38,(%esp)
f0103815:	e8 e4 fe ff ff       	call   f01036fe <cprintf>
	cprintf("  ebx  0x%08x\n", regs->reg_ebx);
f010381a:	8b 43 10             	mov    0x10(%ebx),%eax
f010381d:	89 44 24 04          	mov    %eax,0x4(%esp)
f0103821:	c7 04 24 47 5e 10 f0 	movl   $0xf0105e47,(%esp)
f0103828:	e8 d1 fe ff ff       	call   f01036fe <cprintf>
	cprintf("  edx  0x%08x\n", regs->reg_edx);
f010382d:	8b 43 14             	mov    0x14(%ebx),%eax
f0103830:	89 44 24 04          	mov    %eax,0x4(%esp)
f0103834:	c7 04 24 56 5e 10 f0 	movl   $0xf0105e56,(%esp)
f010383b:	e8 be fe ff ff       	call   f01036fe <cprintf>
	cprintf("  ecx  0x%08x\n", regs->reg_ecx);
f0103840:	8b 43 18             	mov    0x18(%ebx),%eax
f0103843:	89 44 24 04          	mov    %eax,0x4(%esp)
f0103847:	c7 04 24 65 5e 10 f0 	movl   $0xf0105e65,(%esp)
f010384e:	e8 ab fe ff ff       	call   f01036fe <cprintf>
	cprintf("  eax  0x%08x\n", regs->reg_eax);
f0103853:	8b 43 1c             	mov    0x1c(%ebx),%eax
f0103856:	89 44 24 04          	mov    %eax,0x4(%esp)
f010385a:	c7 04 24 74 5e 10 f0 	movl   $0xf0105e74,(%esp)
f0103861:	e8 98 fe ff ff       	call   f01036fe <cprintf>
}
f0103866:	83 c4 14             	add    $0x14,%esp
f0103869:	5b                   	pop    %ebx
f010386a:	5d                   	pop    %ebp
f010386b:	c3                   	ret    

f010386c <print_trapframe>:
	lidt(&idt_pd);
}

void
print_trapframe(struct Trapframe *tf)
{
f010386c:	55                   	push   %ebp
f010386d:	89 e5                	mov    %esp,%ebp
f010386f:	56                   	push   %esi
f0103870:	53                   	push   %ebx
f0103871:	83 ec 10             	sub    $0x10,%esp
f0103874:	8b 5d 08             	mov    0x8(%ebp),%ebx
	cprintf("TRAP frame at %p\n", tf);
f0103877:	89 5c 24 04          	mov    %ebx,0x4(%esp)
f010387b:	c7 04 24 a8 5f 10 f0 	movl   $0xf0105fa8,(%esp)
f0103882:	e8 77 fe ff ff       	call   f01036fe <cprintf>
	print_regs(&tf->tf_regs);
f0103887:	89 1c 24             	mov    %ebx,(%esp)
f010388a:	e8 36 ff ff ff       	call   f01037c5 <print_regs>
	cprintf("  es   0x----%04x\n", tf->tf_es);
f010388f:	0f b7 43 20          	movzwl 0x20(%ebx),%eax
f0103893:	89 44 24 04          	mov    %eax,0x4(%esp)
f0103897:	c7 04 24 aa 5e 10 f0 	movl   $0xf0105eaa,(%esp)
f010389e:	e8 5b fe ff ff       	call   f01036fe <cprintf>
	cprintf("  ds   0x----%04x\n", tf->tf_ds);
f01038a3:	0f b7 43 24          	movzwl 0x24(%ebx),%eax
f01038a7:	89 44 24 04          	mov    %eax,0x4(%esp)
f01038ab:	c7 04 24 bd 5e 10 f0 	movl   $0xf0105ebd,(%esp)
f01038b2:	e8 47 fe ff ff       	call   f01036fe <cprintf>
	cprintf("  trap 0x%08x %s\n", tf->tf_trapno, trapname(tf->tf_trapno));
f01038b7:	8b 73 28             	mov    0x28(%ebx),%esi
f01038ba:	89 f0                	mov    %esi,%eax
f01038bc:	e8 76 fe ff ff       	call   f0103737 <trapname>
f01038c1:	89 44 24 08          	mov    %eax,0x8(%esp)
f01038c5:	89 74 24 04          	mov    %esi,0x4(%esp)
f01038c9:	c7 04 24 d0 5e 10 f0 	movl   $0xf0105ed0,(%esp)
f01038d0:	e8 29 fe ff ff       	call   f01036fe <cprintf>
	// If this trap was a page fault that just happened
	// (so %cr2 is meaningful), print the faulting linear address.
	if (tf == last_tf && tf->tf_trapno == T_PGFLT)
f01038d5:	3b 1d e0 5a 18 f0    	cmp    0xf0185ae0,%ebx
f01038db:	75 1b                	jne    f01038f8 <print_trapframe+0x8c>
f01038dd:	83 7b 28 0e          	cmpl   $0xe,0x28(%ebx)
f01038e1:	75 15                	jne    f01038f8 <print_trapframe+0x8c>
		cprintf("  cr2  0x%08x\n", rcr2());
f01038e3:	e8 40 fe ff ff       	call   f0103728 <rcr2>
f01038e8:	89 44 24 04          	mov    %eax,0x4(%esp)
f01038ec:	c7 04 24 e2 5e 10 f0 	movl   $0xf0105ee2,(%esp)
f01038f3:	e8 06 fe ff ff       	call   f01036fe <cprintf>
	cprintf("  err  0x%08x", tf->tf_err);
f01038f8:	8b 43 2c             	mov    0x2c(%ebx),%eax
f01038fb:	89 44 24 04          	mov    %eax,0x4(%esp)
f01038ff:	c7 04 24 f1 5e 10 f0 	movl   $0xf0105ef1,(%esp)
f0103906:	e8 f3 fd ff ff       	call   f01036fe <cprintf>
	// For page faults, print decoded fault error code:
	// U/K=fault occurred in user/kernel mode
	// W/R=a write/read caused the fault
	// PR=a protection violation caused the fault (NP=page not present).
	if (tf->tf_trapno == T_PGFLT)
f010390b:	83 7b 28 0e          	cmpl   $0xe,0x28(%ebx)
f010390f:	75 51                	jne    f0103962 <print_trapframe+0xf6>
		cprintf(" [%s, %s, %s]\n",
		        tf->tf_err & 4 ? "user" : "kernel",
		        tf->tf_err & 2 ? "write" : "read",
		        tf->tf_err & 1 ? "protection" : "not-present");
f0103911:	8b 43 2c             	mov    0x2c(%ebx),%eax
	// For page faults, print decoded fault error code:
	// U/K=fault occurred in user/kernel mode
	// W/R=a write/read caused the fault
	// PR=a protection violation caused the fault (NP=page not present).
	if (tf->tf_trapno == T_PGFLT)
		cprintf(" [%s, %s, %s]\n",
f0103914:	89 c2                	mov    %eax,%edx
f0103916:	83 e2 01             	and    $0x1,%edx
f0103919:	ba 83 5e 10 f0       	mov    $0xf0105e83,%edx
f010391e:	b9 8e 5e 10 f0       	mov    $0xf0105e8e,%ecx
f0103923:	0f 45 ca             	cmovne %edx,%ecx
f0103926:	89 c2                	mov    %eax,%edx
f0103928:	83 e2 02             	and    $0x2,%edx
f010392b:	ba 9a 5e 10 f0       	mov    $0xf0105e9a,%edx
f0103930:	be a0 5e 10 f0       	mov    $0xf0105ea0,%esi
f0103935:	0f 44 d6             	cmove  %esi,%edx
f0103938:	83 e0 04             	and    $0x4,%eax
f010393b:	b8 a5 5e 10 f0       	mov    $0xf0105ea5,%eax
f0103940:	be 73 5f 10 f0       	mov    $0xf0105f73,%esi
f0103945:	0f 44 c6             	cmove  %esi,%eax
f0103948:	89 4c 24 0c          	mov    %ecx,0xc(%esp)
f010394c:	89 54 24 08          	mov    %edx,0x8(%esp)
f0103950:	89 44 24 04          	mov    %eax,0x4(%esp)
f0103954:	c7 04 24 ff 5e 10 f0 	movl   $0xf0105eff,(%esp)
f010395b:	e8 9e fd ff ff       	call   f01036fe <cprintf>
f0103960:	eb 0c                	jmp    f010396e <print_trapframe+0x102>
		        tf->tf_err & 4 ? "user" : "kernel",
		        tf->tf_err & 2 ? "write" : "read",
		        tf->tf_err & 1 ? "protection" : "not-present");
	else
		cprintf("\n");
f0103962:	c7 04 24 ca 5b 10 f0 	movl   $0xf0105bca,(%esp)
f0103969:	e8 90 fd ff ff       	call   f01036fe <cprintf>
	cprintf("  eip  0x%08x\n", tf->tf_eip);
f010396e:	8b 43 30             	mov    0x30(%ebx),%eax
f0103971:	89 44 24 04          	mov    %eax,0x4(%esp)
f0103975:	c7 04 24 0e 5f 10 f0 	movl   $0xf0105f0e,(%esp)
f010397c:	e8 7d fd ff ff       	call   f01036fe <cprintf>
	cprintf("  cs   0x----%04x\n", tf->tf_cs);
f0103981:	0f b7 43 34          	movzwl 0x34(%ebx),%eax
f0103985:	89 44 24 04          	mov    %eax,0x4(%esp)
f0103989:	c7 04 24 1d 5f 10 f0 	movl   $0xf0105f1d,(%esp)
f0103990:	e8 69 fd ff ff       	call   f01036fe <cprintf>
	cprintf("  flag 0x%08x\n", tf->tf_eflags);
f0103995:	8b 43 38             	mov    0x38(%ebx),%eax
f0103998:	89 44 24 04          	mov    %eax,0x4(%esp)
f010399c:	c7 04 24 30 5f 10 f0 	movl   $0xf0105f30,(%esp)
f01039a3:	e8 56 fd ff ff       	call   f01036fe <cprintf>
	if ((tf->tf_cs & 3) != 0) {
f01039a8:	f6 43 34 03          	testb  $0x3,0x34(%ebx)
f01039ac:	74 27                	je     f01039d5 <print_trapframe+0x169>
		cprintf("  esp  0x%08x\n", tf->tf_esp);
f01039ae:	8b 43 3c             	mov    0x3c(%ebx),%eax
f01039b1:	89 44 24 04          	mov    %eax,0x4(%esp)
f01039b5:	c7 04 24 3f 5f 10 f0 	movl   $0xf0105f3f,(%esp)
f01039bc:	e8 3d fd ff ff       	call   f01036fe <cprintf>
		cprintf("  ss   0x----%04x\n", tf->tf_ss);
f01039c1:	0f b7 43 40          	movzwl 0x40(%ebx),%eax
f01039c5:	89 44 24 04          	mov    %eax,0x4(%esp)
f01039c9:	c7 04 24 4e 5f 10 f0 	movl   $0xf0105f4e,(%esp)
f01039d0:	e8 29 fd ff ff       	call   f01036fe <cprintf>
	}
}
f01039d5:	83 c4 10             	add    $0x10,%esp
f01039d8:	5b                   	pop    %ebx
f01039d9:	5e                   	pop    %esi
f01039da:	5d                   	pop    %ebp
f01039db:	c3                   	ret    

f01039dc <trap_dispatch>:
	cprintf("  eax  0x%08x\n", regs->reg_eax);
}

static void
trap_dispatch(struct Trapframe *tf)
{
f01039dc:	55                   	push   %ebp
f01039dd:	89 e5                	mov    %esp,%ebp
f01039df:	53                   	push   %ebx
f01039e0:	83 ec 14             	sub    $0x14,%esp
f01039e3:	89 c3                	mov    %eax,%ebx
	// Handle processor exceptions.
	// LAB 3: Your code here.

	// Unexpected trap: The user process or the kernel has a bug.
	print_trapframe(tf);
f01039e5:	89 04 24             	mov    %eax,(%esp)
f01039e8:	e8 7f fe ff ff       	call   f010386c <print_trapframe>
	if (tf->tf_cs == GD_KT)
f01039ed:	66 83 7b 34 08       	cmpw   $0x8,0x34(%ebx)
f01039f2:	75 1c                	jne    f0103a10 <trap_dispatch+0x34>
		panic("unhandled trap in kernel");
f01039f4:	c7 44 24 08 61 5f 10 	movl   $0xf0105f61,0x8(%esp)
f01039fb:	f0 
f01039fc:	c7 44 24 04 95 00 00 	movl   $0x95,0x4(%esp)
f0103a03:	00 
f0103a04:	c7 04 24 7a 5f 10 f0 	movl   $0xf0105f7a,(%esp)
f0103a0b:	e8 99 c6 ff ff       	call   f01000a9 <_panic>
	else {
		env_destroy(curenv);
f0103a10:	a1 c4 52 18 f0       	mov    0xf01852c4,%eax
f0103a15:	89 04 24             	mov    %eax,(%esp)
f0103a18:	e8 35 fb ff ff       	call   f0103552 <env_destroy>
		return;
	}
}
f0103a1d:	83 c4 14             	add    $0x14,%esp
f0103a20:	5b                   	pop    %ebx
f0103a21:	5d                   	pop    %ebp
f0103a22:	c3                   	ret    

f0103a23 <trap>:

void
trap(struct Trapframe *tf)
{
f0103a23:	55                   	push   %ebp
f0103a24:	89 e5                	mov    %esp,%ebp
f0103a26:	57                   	push   %edi
f0103a27:	56                   	push   %esi
f0103a28:	83 ec 10             	sub    $0x10,%esp
f0103a2b:	8b 75 08             	mov    0x8(%ebp),%esi
	// The environment may have set DF and some versions
	// of GCC rely on DF being clear
	asm volatile("cld" ::: "cc");
f0103a2e:	fc                   	cld    

	// Check that interrupts are disabled.  If this assertion
	// fails, DO NOT be tempted to fix it by inserting a "cli" in
	// the interrupt path.
	assert(!(read_eflags() & FL_IF));
f0103a2f:	e8 fc fc ff ff       	call   f0103730 <read_eflags>
f0103a34:	f6 c4 02             	test   $0x2,%ah
f0103a37:	74 24                	je     f0103a5d <trap+0x3a>
f0103a39:	c7 44 24 0c 86 5f 10 	movl   $0xf0105f86,0xc(%esp)
f0103a40:	f0 
f0103a41:	c7 44 24 08 ba 58 10 	movl   $0xf01058ba,0x8(%esp)
f0103a48:	f0 
f0103a49:	c7 44 24 04 a6 00 00 	movl   $0xa6,0x4(%esp)
f0103a50:	00 
f0103a51:	c7 04 24 7a 5f 10 f0 	movl   $0xf0105f7a,(%esp)
f0103a58:	e8 4c c6 ff ff       	call   f01000a9 <_panic>

	cprintf("Incoming TRAP frame at %p\n", tf);
f0103a5d:	89 74 24 04          	mov    %esi,0x4(%esp)
f0103a61:	c7 04 24 9f 5f 10 f0 	movl   $0xf0105f9f,(%esp)
f0103a68:	e8 91 fc ff ff       	call   f01036fe <cprintf>

	if ((tf->tf_cs & 3) == 3) {
f0103a6d:	0f b7 46 34          	movzwl 0x34(%esi),%eax
f0103a71:	83 e0 03             	and    $0x3,%eax
f0103a74:	66 83 f8 03          	cmp    $0x3,%ax
f0103a78:	75 3c                	jne    f0103ab6 <trap+0x93>
		// Trapped from user mode.
		assert(curenv);
f0103a7a:	a1 c4 52 18 f0       	mov    0xf01852c4,%eax
f0103a7f:	85 c0                	test   %eax,%eax
f0103a81:	75 24                	jne    f0103aa7 <trap+0x84>
f0103a83:	c7 44 24 0c ba 5f 10 	movl   $0xf0105fba,0xc(%esp)
f0103a8a:	f0 
f0103a8b:	c7 44 24 08 ba 58 10 	movl   $0xf01058ba,0x8(%esp)
f0103a92:	f0 
f0103a93:	c7 44 24 04 ac 00 00 	movl   $0xac,0x4(%esp)
f0103a9a:	00 
f0103a9b:	c7 04 24 7a 5f 10 f0 	movl   $0xf0105f7a,(%esp)
f0103aa2:	e8 02 c6 ff ff       	call   f01000a9 <_panic>

		// Copy trap frame (which is currently on the stack)
		// into 'curenv->env_tf', so that running the environment
		// will restart at the trap point.
		curenv->env_tf = *tf;
f0103aa7:	b9 11 00 00 00       	mov    $0x11,%ecx
f0103aac:	89 c7                	mov    %eax,%edi
f0103aae:	f3 a5                	rep movsl %ds:(%esi),%es:(%edi)
		// The trapframe on the stack should be ignored from here on.
		tf = &curenv->env_tf;
f0103ab0:	8b 35 c4 52 18 f0    	mov    0xf01852c4,%esi
	}

	// Record that tf is the last real trapframe so
	// print_trapframe can print some additional information.
	last_tf = tf;
f0103ab6:	89 35 e0 5a 18 f0    	mov    %esi,0xf0185ae0

	// Dispatch based on what type of trap occurred
	trap_dispatch(tf);
f0103abc:	89 f0                	mov    %esi,%eax
f0103abe:	e8 19 ff ff ff       	call   f01039dc <trap_dispatch>

	// Return to the current environment, which should be running.
	assert(curenv && curenv->env_status == ENV_RUNNING);
f0103ac3:	a1 c4 52 18 f0       	mov    0xf01852c4,%eax
f0103ac8:	85 c0                	test   %eax,%eax
f0103aca:	74 06                	je     f0103ad2 <trap+0xaf>
f0103acc:	83 78 54 03          	cmpl   $0x3,0x54(%eax)
f0103ad0:	74 24                	je     f0103af6 <trap+0xd3>
f0103ad2:	c7 44 24 0c 04 61 10 	movl   $0xf0106104,0xc(%esp)
f0103ad9:	f0 
f0103ada:	c7 44 24 08 ba 58 10 	movl   $0xf01058ba,0x8(%esp)
f0103ae1:	f0 
f0103ae2:	c7 44 24 04 be 00 00 	movl   $0xbe,0x4(%esp)
f0103ae9:	00 
f0103aea:	c7 04 24 7a 5f 10 f0 	movl   $0xf0105f7a,(%esp)
f0103af1:	e8 b3 c5 ff ff       	call   f01000a9 <_panic>
	env_run(curenv);
f0103af6:	89 04 24             	mov    %eax,(%esp)
f0103af9:	e8 a4 fa ff ff       	call   f01035a2 <env_run>

f0103afe <page_fault_handler>:
}


void
page_fault_handler(struct Trapframe *tf)
{
f0103afe:	55                   	push   %ebp
f0103aff:	89 e5                	mov    %esp,%ebp
f0103b01:	53                   	push   %ebx
f0103b02:	83 ec 14             	sub    $0x14,%esp
f0103b05:	8b 5d 08             	mov    0x8(%ebp),%ebx
	uint32_t fault_va;

	// Read processor's CR2 register to find the faulting address
	fault_va = rcr2();
f0103b08:	e8 1b fc ff ff       	call   f0103728 <rcr2>

	// We've already handled kernel-mode exceptions, so if we get here,
	// the page fault happened in user mode.

	// Destroy the environment that caused the fault.
	cprintf("[%08x] user fault va %08x ip %08x\n",
f0103b0d:	8b 53 30             	mov    0x30(%ebx),%edx
f0103b10:	89 54 24 0c          	mov    %edx,0xc(%esp)
f0103b14:	89 44 24 08          	mov    %eax,0x8(%esp)
f0103b18:	a1 c4 52 18 f0       	mov    0xf01852c4,%eax
f0103b1d:	8b 40 48             	mov    0x48(%eax),%eax
f0103b20:	89 44 24 04          	mov    %eax,0x4(%esp)
f0103b24:	c7 04 24 30 61 10 f0 	movl   $0xf0106130,(%esp)
f0103b2b:	e8 ce fb ff ff       	call   f01036fe <cprintf>
	        curenv->env_id,
	        fault_va,
	        tf->tf_eip);
	print_trapframe(tf);
f0103b30:	89 1c 24             	mov    %ebx,(%esp)
f0103b33:	e8 34 fd ff ff       	call   f010386c <print_trapframe>
	env_destroy(curenv);
f0103b38:	a1 c4 52 18 f0       	mov    0xf01852c4,%eax
f0103b3d:	89 04 24             	mov    %eax,(%esp)
f0103b40:	e8 0d fa ff ff       	call   f0103552 <env_destroy>
}
f0103b45:	83 c4 14             	add    $0x14,%esp
f0103b48:	5b                   	pop    %ebx
f0103b49:	5d                   	pop    %ebp
f0103b4a:	c3                   	ret    

f0103b4b <syscall>:
f0103b4b:	55                   	push   %ebp
f0103b4c:	89 e5                	mov    %esp,%ebp
f0103b4e:	83 ec 18             	sub    $0x18,%esp
f0103b51:	c7 44 24 08 b0 61 10 	movl   $0xf01061b0,0x8(%esp)
f0103b58:	f0 
f0103b59:	c7 44 24 04 49 00 00 	movl   $0x49,0x4(%esp)
f0103b60:	00 
f0103b61:	c7 04 24 c8 61 10 f0 	movl   $0xf01061c8,(%esp)
f0103b68:	e8 3c c5 ff ff       	call   f01000a9 <_panic>

f0103b6d <stab_binsearch>:
stab_binsearch(const struct Stab *stabs,
               int *region_left,
               int *region_right,
               int type,
               uintptr_t addr)
{
f0103b6d:	55                   	push   %ebp
f0103b6e:	89 e5                	mov    %esp,%ebp
f0103b70:	57                   	push   %edi
f0103b71:	56                   	push   %esi
f0103b72:	53                   	push   %ebx
f0103b73:	83 ec 14             	sub    $0x14,%esp
f0103b76:	89 45 ec             	mov    %eax,-0x14(%ebp)
f0103b79:	89 55 e4             	mov    %edx,-0x1c(%ebp)
f0103b7c:	89 4d e0             	mov    %ecx,-0x20(%ebp)
f0103b7f:	8b 75 08             	mov    0x8(%ebp),%esi
	int l = *region_left, r = *region_right, any_matches = 0;
f0103b82:	8b 1a                	mov    (%edx),%ebx
f0103b84:	8b 01                	mov    (%ecx),%eax
f0103b86:	89 45 f0             	mov    %eax,-0x10(%ebp)
f0103b89:	c7 45 e8 00 00 00 00 	movl   $0x0,-0x18(%ebp)

	while (l <= r) {
f0103b90:	e9 88 00 00 00       	jmp    f0103c1d <stab_binsearch+0xb0>
		int true_m = (l + r) / 2, m = true_m;
f0103b95:	8b 45 f0             	mov    -0x10(%ebp),%eax
f0103b98:	01 d8                	add    %ebx,%eax
f0103b9a:	89 c7                	mov    %eax,%edi
f0103b9c:	c1 ef 1f             	shr    $0x1f,%edi
f0103b9f:	01 c7                	add    %eax,%edi
f0103ba1:	d1 ff                	sar    %edi
f0103ba3:	8d 04 7f             	lea    (%edi,%edi,2),%eax
f0103ba6:	8b 4d ec             	mov    -0x14(%ebp),%ecx
f0103ba9:	8d 14 81             	lea    (%ecx,%eax,4),%edx
f0103bac:	89 f8                	mov    %edi,%eax

		// search for earliest stab with right type
		while (m >= l && stabs[m].n_type != type)
f0103bae:	eb 03                	jmp    f0103bb3 <stab_binsearch+0x46>
			m--;
f0103bb0:	83 e8 01             	sub    $0x1,%eax

	while (l <= r) {
		int true_m = (l + r) / 2, m = true_m;

		// search for earliest stab with right type
		while (m >= l && stabs[m].n_type != type)
f0103bb3:	39 c3                	cmp    %eax,%ebx
f0103bb5:	7f 1f                	jg     f0103bd6 <stab_binsearch+0x69>
f0103bb7:	0f b6 4a 04          	movzbl 0x4(%edx),%ecx
f0103bbb:	83 ea 0c             	sub    $0xc,%edx
f0103bbe:	39 f1                	cmp    %esi,%ecx
f0103bc0:	75 ee                	jne    f0103bb0 <stab_binsearch+0x43>
f0103bc2:	89 45 e8             	mov    %eax,-0x18(%ebp)
			continue;
		}

		// actual binary search
		any_matches = 1;
		if (stabs[m].n_value < addr) {
f0103bc5:	8d 14 40             	lea    (%eax,%eax,2),%edx
f0103bc8:	8b 4d ec             	mov    -0x14(%ebp),%ecx
f0103bcb:	8b 54 91 08          	mov    0x8(%ecx,%edx,4),%edx
f0103bcf:	39 55 0c             	cmp    %edx,0xc(%ebp)
f0103bd2:	76 18                	jbe    f0103bec <stab_binsearch+0x7f>
f0103bd4:	eb 05                	jmp    f0103bdb <stab_binsearch+0x6e>

		// search for earliest stab with right type
		while (m >= l && stabs[m].n_type != type)
			m--;
		if (m < l) {  // no match in [l, m]
			l = true_m + 1;
f0103bd6:	8d 5f 01             	lea    0x1(%edi),%ebx
			continue;
f0103bd9:	eb 42                	jmp    f0103c1d <stab_binsearch+0xb0>
		}

		// actual binary search
		any_matches = 1;
		if (stabs[m].n_value < addr) {
			*region_left = m;
f0103bdb:	8b 5d e4             	mov    -0x1c(%ebp),%ebx
f0103bde:	89 03                	mov    %eax,(%ebx)
			l = true_m + 1;
f0103be0:	8d 5f 01             	lea    0x1(%edi),%ebx
			l = true_m + 1;
			continue;
		}

		// actual binary search
		any_matches = 1;
f0103be3:	c7 45 e8 01 00 00 00 	movl   $0x1,-0x18(%ebp)
f0103bea:	eb 31                	jmp    f0103c1d <stab_binsearch+0xb0>
		if (stabs[m].n_value < addr) {
			*region_left = m;
			l = true_m + 1;
		} else if (stabs[m].n_value > addr) {
f0103bec:	39 55 0c             	cmp    %edx,0xc(%ebp)
f0103bef:	73 17                	jae    f0103c08 <stab_binsearch+0x9b>
			*region_right = m - 1;
f0103bf1:	8b 45 e8             	mov    -0x18(%ebp),%eax
f0103bf4:	83 e8 01             	sub    $0x1,%eax
f0103bf7:	89 45 f0             	mov    %eax,-0x10(%ebp)
f0103bfa:	8b 7d e0             	mov    -0x20(%ebp),%edi
f0103bfd:	89 07                	mov    %eax,(%edi)
			l = true_m + 1;
			continue;
		}

		// actual binary search
		any_matches = 1;
f0103bff:	c7 45 e8 01 00 00 00 	movl   $0x1,-0x18(%ebp)
f0103c06:	eb 15                	jmp    f0103c1d <stab_binsearch+0xb0>
			*region_right = m - 1;
			r = m - 1;
		} else {
			// exact match for 'addr', but continue loop to find
			// *region_right
			*region_left = m;
f0103c08:	8b 7d e4             	mov    -0x1c(%ebp),%edi
f0103c0b:	8b 5d e8             	mov    -0x18(%ebp),%ebx
f0103c0e:	89 1f                	mov    %ebx,(%edi)
			l = m;
			addr++;
f0103c10:	83 45 0c 01          	addl   $0x1,0xc(%ebp)
f0103c14:	89 c3                	mov    %eax,%ebx
			l = true_m + 1;
			continue;
		}

		// actual binary search
		any_matches = 1;
f0103c16:	c7 45 e8 01 00 00 00 	movl   $0x1,-0x18(%ebp)
               int type,
               uintptr_t addr)
{
	int l = *region_left, r = *region_right, any_matches = 0;

	while (l <= r) {
f0103c1d:	3b 5d f0             	cmp    -0x10(%ebp),%ebx
f0103c20:	0f 8e 6f ff ff ff    	jle    f0103b95 <stab_binsearch+0x28>
			l = m;
			addr++;
		}
	}

	if (!any_matches)
f0103c26:	83 7d e8 00          	cmpl   $0x0,-0x18(%ebp)
f0103c2a:	75 0f                	jne    f0103c3b <stab_binsearch+0xce>
		*region_right = *region_left - 1;
f0103c2c:	8b 45 e4             	mov    -0x1c(%ebp),%eax
f0103c2f:	8b 00                	mov    (%eax),%eax
f0103c31:	83 e8 01             	sub    $0x1,%eax
f0103c34:	8b 7d e0             	mov    -0x20(%ebp),%edi
f0103c37:	89 07                	mov    %eax,(%edi)
f0103c39:	eb 2c                	jmp    f0103c67 <stab_binsearch+0xfa>
	else {
		// find rightmost region containing 'addr'
		for (l = *region_right;
f0103c3b:	8b 45 e0             	mov    -0x20(%ebp),%eax
f0103c3e:	8b 00                	mov    (%eax),%eax
		     l > *region_left && stabs[l].n_type != type;
f0103c40:	8b 7d e4             	mov    -0x1c(%ebp),%edi
f0103c43:	8b 0f                	mov    (%edi),%ecx
f0103c45:	8d 14 40             	lea    (%eax,%eax,2),%edx
f0103c48:	8b 7d ec             	mov    -0x14(%ebp),%edi
f0103c4b:	8d 14 97             	lea    (%edi,%edx,4),%edx

	if (!any_matches)
		*region_right = *region_left - 1;
	else {
		// find rightmost region containing 'addr'
		for (l = *region_right;
f0103c4e:	eb 03                	jmp    f0103c53 <stab_binsearch+0xe6>
		     l > *region_left && stabs[l].n_type != type;
		     l--)
f0103c50:	83 e8 01             	sub    $0x1,%eax

	if (!any_matches)
		*region_right = *region_left - 1;
	else {
		// find rightmost region containing 'addr'
		for (l = *region_right;
f0103c53:	39 c8                	cmp    %ecx,%eax
f0103c55:	7e 0b                	jle    f0103c62 <stab_binsearch+0xf5>
		     l > *region_left && stabs[l].n_type != type;
f0103c57:	0f b6 5a 04          	movzbl 0x4(%edx),%ebx
f0103c5b:	83 ea 0c             	sub    $0xc,%edx
f0103c5e:	39 f3                	cmp    %esi,%ebx
f0103c60:	75 ee                	jne    f0103c50 <stab_binsearch+0xe3>
		     l--)
			/* do nothing */;
		*region_left = l;
f0103c62:	8b 7d e4             	mov    -0x1c(%ebp),%edi
f0103c65:	89 07                	mov    %eax,(%edi)
	}
}
f0103c67:	83 c4 14             	add    $0x14,%esp
f0103c6a:	5b                   	pop    %ebx
f0103c6b:	5e                   	pop    %esi
f0103c6c:	5f                   	pop    %edi
f0103c6d:	5d                   	pop    %ebp
f0103c6e:	c3                   	ret    

f0103c6f <debuginfo_eip>:
//	negative if not.  But even if it returns negative it has stored some
//	information into '*info'.
//
int
debuginfo_eip(uintptr_t addr, struct Eipdebuginfo *info)
{
f0103c6f:	55                   	push   %ebp
f0103c70:	89 e5                	mov    %esp,%ebp
f0103c72:	57                   	push   %edi
f0103c73:	56                   	push   %esi
f0103c74:	53                   	push   %ebx
f0103c75:	83 ec 4c             	sub    $0x4c,%esp
f0103c78:	8b 5d 08             	mov    0x8(%ebp),%ebx
f0103c7b:	8b 7d 0c             	mov    0xc(%ebp),%edi
	const struct Stab *stabs, *stab_end;
	const char *stabstr, *stabstr_end;
	int lfile, rfile, lfun, rfun, lline, rline;

	// Initialize *info
	info->eip_file = "<unknown>";
f0103c7e:	c7 07 d7 61 10 f0    	movl   $0xf01061d7,(%edi)
	info->eip_line = 0;
f0103c84:	c7 47 04 00 00 00 00 	movl   $0x0,0x4(%edi)
	info->eip_fn_name = "<unknown>";
f0103c8b:	c7 47 08 d7 61 10 f0 	movl   $0xf01061d7,0x8(%edi)
	info->eip_fn_namelen = 9;
f0103c92:	c7 47 0c 09 00 00 00 	movl   $0x9,0xc(%edi)
	info->eip_fn_addr = addr;
f0103c99:	89 5f 10             	mov    %ebx,0x10(%edi)
	info->eip_fn_narg = 0;
f0103c9c:	c7 47 14 00 00 00 00 	movl   $0x0,0x14(%edi)

	// Find the relevant set of stabs
	if (addr >= ULIM) {
f0103ca3:	81 fb ff ff 7f ef    	cmp    $0xef7fffff,%ebx
f0103ca9:	77 21                	ja     f0103ccc <debuginfo_eip+0x5d>

		// Make sure this memory is valid.
		// Return -1 if it is not.  Hint: Call user_mem_check.
		// LAB 3: Your code here.

		stabs = usd->stabs;
f0103cab:	a1 00 00 20 00       	mov    0x200000,%eax
f0103cb0:	89 45 c4             	mov    %eax,-0x3c(%ebp)
		stab_end = usd->stab_end;
f0103cb3:	a1 04 00 20 00       	mov    0x200004,%eax
		stabstr = usd->stabstr;
f0103cb8:	8b 35 08 00 20 00    	mov    0x200008,%esi
f0103cbe:	89 75 c0             	mov    %esi,-0x40(%ebp)
		stabstr_end = usd->stabstr_end;
f0103cc1:	8b 35 0c 00 20 00    	mov    0x20000c,%esi
f0103cc7:	89 75 bc             	mov    %esi,-0x44(%ebp)
f0103cca:	eb 1a                	jmp    f0103ce6 <debuginfo_eip+0x77>
	// Find the relevant set of stabs
	if (addr >= ULIM) {
		stabs = __STAB_BEGIN__;
		stab_end = __STAB_END__;
		stabstr = __STABSTR_BEGIN__;
		stabstr_end = __STABSTR_END__;
f0103ccc:	c7 45 bc 71 12 11 f0 	movl   $0xf0111271,-0x44(%ebp)

	// Find the relevant set of stabs
	if (addr >= ULIM) {
		stabs = __STAB_BEGIN__;
		stab_end = __STAB_END__;
		stabstr = __STABSTR_BEGIN__;
f0103cd3:	c7 45 c0 95 e0 10 f0 	movl   $0xf010e095,-0x40(%ebp)
	info->eip_fn_narg = 0;

	// Find the relevant set of stabs
	if (addr >= ULIM) {
		stabs = __STAB_BEGIN__;
		stab_end = __STAB_END__;
f0103cda:	b8 94 e0 10 f0       	mov    $0xf010e094,%eax
	info->eip_fn_addr = addr;
	info->eip_fn_narg = 0;

	// Find the relevant set of stabs
	if (addr >= ULIM) {
		stabs = __STAB_BEGIN__;
f0103cdf:	c7 45 c4 f0 63 10 f0 	movl   $0xf01063f0,-0x3c(%ebp)
		// Make sure the STABS and string table memory is valid.
		// LAB 3: Your code here.
	}

	// String table validity checks
	if (stabstr_end <= stabstr || stabstr_end[-1] != 0)
f0103ce6:	8b 75 bc             	mov    -0x44(%ebp),%esi
f0103ce9:	39 75 c0             	cmp    %esi,-0x40(%ebp)
f0103cec:	0f 83 9f 01 00 00    	jae    f0103e91 <debuginfo_eip+0x222>
f0103cf2:	80 7e ff 00          	cmpb   $0x0,-0x1(%esi)
f0103cf6:	0f 85 9c 01 00 00    	jne    f0103e98 <debuginfo_eip+0x229>
	// 'eip'.  First, we find the basic source file containing 'eip'.
	// Then, we look in that source file for the function.  Then we look
	// for the line number.

	// Search the entire set of stabs for the source file (type N_SO).
	lfile = 0;
f0103cfc:	c7 45 e4 00 00 00 00 	movl   $0x0,-0x1c(%ebp)
	rfile = (stab_end - stabs) - 1;
f0103d03:	8b 75 c4             	mov    -0x3c(%ebp),%esi
f0103d06:	29 f0                	sub    %esi,%eax
f0103d08:	c1 f8 02             	sar    $0x2,%eax
f0103d0b:	69 c0 ab aa aa aa    	imul   $0xaaaaaaab,%eax,%eax
f0103d11:	83 e8 01             	sub    $0x1,%eax
f0103d14:	89 45 e0             	mov    %eax,-0x20(%ebp)
	stab_binsearch(stabs, &lfile, &rfile, N_SO, addr);
f0103d17:	89 5c 24 04          	mov    %ebx,0x4(%esp)
f0103d1b:	c7 04 24 64 00 00 00 	movl   $0x64,(%esp)
f0103d22:	8d 4d e0             	lea    -0x20(%ebp),%ecx
f0103d25:	8d 55 e4             	lea    -0x1c(%ebp),%edx
f0103d28:	89 f0                	mov    %esi,%eax
f0103d2a:	e8 3e fe ff ff       	call   f0103b6d <stab_binsearch>
	if (lfile == 0)
f0103d2f:	8b 45 e4             	mov    -0x1c(%ebp),%eax
f0103d32:	85 c0                	test   %eax,%eax
f0103d34:	0f 84 65 01 00 00    	je     f0103e9f <debuginfo_eip+0x230>
		return -1;

	// Search within that file's stabs for the function definition
	// (N_FUN).
	lfun = lfile;
f0103d3a:	89 45 dc             	mov    %eax,-0x24(%ebp)
	rfun = rfile;
f0103d3d:	8b 45 e0             	mov    -0x20(%ebp),%eax
f0103d40:	89 45 d8             	mov    %eax,-0x28(%ebp)
	stab_binsearch(stabs, &lfun, &rfun, N_FUN, addr);
f0103d43:	89 5c 24 04          	mov    %ebx,0x4(%esp)
f0103d47:	c7 04 24 24 00 00 00 	movl   $0x24,(%esp)
f0103d4e:	8d 4d d8             	lea    -0x28(%ebp),%ecx
f0103d51:	8d 55 dc             	lea    -0x24(%ebp),%edx
f0103d54:	89 f0                	mov    %esi,%eax
f0103d56:	e8 12 fe ff ff       	call   f0103b6d <stab_binsearch>

	if (lfun <= rfun) {
f0103d5b:	8b 45 dc             	mov    -0x24(%ebp),%eax
f0103d5e:	8b 4d d8             	mov    -0x28(%ebp),%ecx
f0103d61:	39 c8                	cmp    %ecx,%eax
f0103d63:	7f 32                	jg     f0103d97 <debuginfo_eip+0x128>
		// stabs[lfun] points to the function name
		// in the string table, but check bounds just in case.
		if (stabs[lfun].n_strx < stabstr_end - stabstr)
f0103d65:	8d 14 40             	lea    (%eax,%eax,2),%edx
f0103d68:	8b 75 c4             	mov    -0x3c(%ebp),%esi
f0103d6b:	8d 34 96             	lea    (%esi,%edx,4),%esi
f0103d6e:	8b 16                	mov    (%esi),%edx
f0103d70:	89 55 b8             	mov    %edx,-0x48(%ebp)
f0103d73:	8b 55 bc             	mov    -0x44(%ebp),%edx
f0103d76:	2b 55 c0             	sub    -0x40(%ebp),%edx
f0103d79:	39 55 b8             	cmp    %edx,-0x48(%ebp)
f0103d7c:	73 09                	jae    f0103d87 <debuginfo_eip+0x118>
			info->eip_fn_name = stabstr + stabs[lfun].n_strx;
f0103d7e:	8b 55 b8             	mov    -0x48(%ebp),%edx
f0103d81:	03 55 c0             	add    -0x40(%ebp),%edx
f0103d84:	89 57 08             	mov    %edx,0x8(%edi)
		info->eip_fn_addr = stabs[lfun].n_value;
f0103d87:	8b 56 08             	mov    0x8(%esi),%edx
f0103d8a:	89 57 10             	mov    %edx,0x10(%edi)
		addr -= info->eip_fn_addr;
f0103d8d:	29 d3                	sub    %edx,%ebx
		// Search within the function definition for the line number.
		lline = lfun;
f0103d8f:	89 45 d4             	mov    %eax,-0x2c(%ebp)
		rline = rfun;
f0103d92:	89 4d d0             	mov    %ecx,-0x30(%ebp)
f0103d95:	eb 0f                	jmp    f0103da6 <debuginfo_eip+0x137>
	} else {
		// Couldn't find function stab!  Maybe we're in an assembly
		// file.  Search the whole file for the line number.
		info->eip_fn_addr = addr;
f0103d97:	89 5f 10             	mov    %ebx,0x10(%edi)
		lline = lfile;
f0103d9a:	8b 45 e4             	mov    -0x1c(%ebp),%eax
f0103d9d:	89 45 d4             	mov    %eax,-0x2c(%ebp)
		rline = rfile;
f0103da0:	8b 45 e0             	mov    -0x20(%ebp),%eax
f0103da3:	89 45 d0             	mov    %eax,-0x30(%ebp)
	}
	// Ignore stuff after the colon.
	info->eip_fn_namelen = strfind(info->eip_fn_name, ':') - info->eip_fn_name;
f0103da6:	c7 44 24 04 3a 00 00 	movl   $0x3a,0x4(%esp)
f0103dad:	00 
f0103dae:	8b 47 08             	mov    0x8(%edi),%eax
f0103db1:	89 04 24             	mov    %eax,(%esp)
f0103db4:	e8 f2 08 00 00       	call   f01046ab <strfind>
f0103db9:	2b 47 08             	sub    0x8(%edi),%eax
f0103dbc:	89 47 0c             	mov    %eax,0xc(%edi)
	//	There's a particular stabs type used for line numbers.
	//	Look at the STABS documentation and <inc/stab.h> to find
	//	which one.
	// Your code here.

	stab_binsearch(stabs, &lline, &rline, N_SLINE, addr);
f0103dbf:	89 5c 24 04          	mov    %ebx,0x4(%esp)
f0103dc3:	c7 04 24 44 00 00 00 	movl   $0x44,(%esp)
f0103dca:	8d 4d d0             	lea    -0x30(%ebp),%ecx
f0103dcd:	8d 55 d4             	lea    -0x2c(%ebp),%edx
f0103dd0:	8b 45 c4             	mov    -0x3c(%ebp),%eax
f0103dd3:	e8 95 fd ff ff       	call   f0103b6d <stab_binsearch>
	if (lline <= rline) {
f0103dd8:	8b 45 d4             	mov    -0x2c(%ebp),%eax
f0103ddb:	3b 45 d0             	cmp    -0x30(%ebp),%eax
f0103dde:	7f 0e                	jg     f0103dee <debuginfo_eip+0x17f>
		info->eip_line = stabs[lline].n_desc;
f0103de0:	8d 04 40             	lea    (%eax,%eax,2),%eax
f0103de3:	8b 5d c4             	mov    -0x3c(%ebp),%ebx
f0103de6:	0f b7 44 83 06       	movzwl 0x6(%ebx,%eax,4),%eax
f0103deb:	89 47 04             	mov    %eax,0x4(%edi)
	// Search backwards from the line number for the relevant filename
	// stab.
	// We can't just use the "lfile" stab because inlined functions
	// can interpolate code from a different file!
	// Such included source files use the N_SOL stab type.
	while (lline >= lfile && stabs[lline].n_type != N_SOL &&
f0103dee:	8b 45 e4             	mov    -0x1c(%ebp),%eax
f0103df1:	89 c6                	mov    %eax,%esi
f0103df3:	8b 45 d4             	mov    -0x2c(%ebp),%eax
f0103df6:	8d 14 40             	lea    (%eax,%eax,2),%edx
f0103df9:	8b 5d c4             	mov    -0x3c(%ebp),%ebx
f0103dfc:	8d 14 93             	lea    (%ebx,%edx,4),%edx
f0103dff:	89 7d 0c             	mov    %edi,0xc(%ebp)
f0103e02:	89 f7                	mov    %esi,%edi
f0103e04:	eb 06                	jmp    f0103e0c <debuginfo_eip+0x19d>
f0103e06:	83 e8 01             	sub    $0x1,%eax
f0103e09:	83 ea 0c             	sub    $0xc,%edx
f0103e0c:	89 c6                	mov    %eax,%esi
f0103e0e:	39 c7                	cmp    %eax,%edi
f0103e10:	7f 3c                	jg     f0103e4e <debuginfo_eip+0x1df>
f0103e12:	0f b6 4a 04          	movzbl 0x4(%edx),%ecx
f0103e16:	80 f9 84             	cmp    $0x84,%cl
f0103e19:	75 08                	jne    f0103e23 <debuginfo_eip+0x1b4>
f0103e1b:	8b 7d 0c             	mov    0xc(%ebp),%edi
f0103e1e:	89 45 d4             	mov    %eax,-0x2c(%ebp)
f0103e21:	eb 11                	jmp    f0103e34 <debuginfo_eip+0x1c5>
f0103e23:	80 f9 64             	cmp    $0x64,%cl
f0103e26:	75 de                	jne    f0103e06 <debuginfo_eip+0x197>
	       (stabs[lline].n_type != N_SO || !stabs[lline].n_value))
f0103e28:	83 7a 08 00          	cmpl   $0x0,0x8(%edx)
f0103e2c:	74 d8                	je     f0103e06 <debuginfo_eip+0x197>
f0103e2e:	8b 7d 0c             	mov    0xc(%ebp),%edi
f0103e31:	89 45 d4             	mov    %eax,-0x2c(%ebp)
		lline--;
	if (lline >= lfile && stabs[lline].n_strx < stabstr_end - stabstr)
f0103e34:	8d 04 76             	lea    (%esi,%esi,2),%eax
f0103e37:	8b 5d c4             	mov    -0x3c(%ebp),%ebx
f0103e3a:	8b 04 83             	mov    (%ebx,%eax,4),%eax
f0103e3d:	8b 55 bc             	mov    -0x44(%ebp),%edx
f0103e40:	2b 55 c0             	sub    -0x40(%ebp),%edx
f0103e43:	39 d0                	cmp    %edx,%eax
f0103e45:	73 0a                	jae    f0103e51 <debuginfo_eip+0x1e2>
		info->eip_file = stabstr + stabs[lline].n_strx;
f0103e47:	03 45 c0             	add    -0x40(%ebp),%eax
f0103e4a:	89 07                	mov    %eax,(%edi)
f0103e4c:	eb 03                	jmp    f0103e51 <debuginfo_eip+0x1e2>
f0103e4e:	8b 7d 0c             	mov    0xc(%ebp),%edi


	// Set eip_fn_narg to the number of arguments taken by the function,
	// or 0 if there was no containing function.
	if (lfun < rfun)
f0103e51:	8b 55 dc             	mov    -0x24(%ebp),%edx
f0103e54:	8b 5d d8             	mov    -0x28(%ebp),%ebx
		for (lline = lfun + 1;
		     lline < rfun && stabs[lline].n_type == N_PSYM;
		     lline++)
			info->eip_fn_narg++;

	return 0;
f0103e57:	b8 00 00 00 00       	mov    $0x0,%eax
		info->eip_file = stabstr + stabs[lline].n_strx;


	// Set eip_fn_narg to the number of arguments taken by the function,
	// or 0 if there was no containing function.
	if (lfun < rfun)
f0103e5c:	39 da                	cmp    %ebx,%edx
f0103e5e:	7d 4b                	jge    f0103eab <debuginfo_eip+0x23c>
		for (lline = lfun + 1;
f0103e60:	83 c2 01             	add    $0x1,%edx
f0103e63:	89 55 d4             	mov    %edx,-0x2c(%ebp)
f0103e66:	89 d0                	mov    %edx,%eax
f0103e68:	8d 14 52             	lea    (%edx,%edx,2),%edx
f0103e6b:	8b 75 c4             	mov    -0x3c(%ebp),%esi
f0103e6e:	8d 14 96             	lea    (%esi,%edx,4),%edx
f0103e71:	eb 04                	jmp    f0103e77 <debuginfo_eip+0x208>
		     lline < rfun && stabs[lline].n_type == N_PSYM;
		     lline++)
			info->eip_fn_narg++;
f0103e73:	83 47 14 01          	addl   $0x1,0x14(%edi)


	// Set eip_fn_narg to the number of arguments taken by the function,
	// or 0 if there was no containing function.
	if (lfun < rfun)
		for (lline = lfun + 1;
f0103e77:	39 c3                	cmp    %eax,%ebx
f0103e79:	7e 2b                	jle    f0103ea6 <debuginfo_eip+0x237>
		     lline < rfun && stabs[lline].n_type == N_PSYM;
f0103e7b:	0f b6 4a 04          	movzbl 0x4(%edx),%ecx
f0103e7f:	83 c0 01             	add    $0x1,%eax
f0103e82:	83 c2 0c             	add    $0xc,%edx
f0103e85:	80 f9 a0             	cmp    $0xa0,%cl
f0103e88:	74 e9                	je     f0103e73 <debuginfo_eip+0x204>
		     lline++)
			info->eip_fn_narg++;

	return 0;
f0103e8a:	b8 00 00 00 00       	mov    $0x0,%eax
f0103e8f:	eb 1a                	jmp    f0103eab <debuginfo_eip+0x23c>
		// LAB 3: Your code here.
	}

	// String table validity checks
	if (stabstr_end <= stabstr || stabstr_end[-1] != 0)
		return -1;
f0103e91:	b8 ff ff ff ff       	mov    $0xffffffff,%eax
f0103e96:	eb 13                	jmp    f0103eab <debuginfo_eip+0x23c>
f0103e98:	b8 ff ff ff ff       	mov    $0xffffffff,%eax
f0103e9d:	eb 0c                	jmp    f0103eab <debuginfo_eip+0x23c>
	// Search the entire set of stabs for the source file (type N_SO).
	lfile = 0;
	rfile = (stab_end - stabs) - 1;
	stab_binsearch(stabs, &lfile, &rfile, N_SO, addr);
	if (lfile == 0)
		return -1;
f0103e9f:	b8 ff ff ff ff       	mov    $0xffffffff,%eax
f0103ea4:	eb 05                	jmp    f0103eab <debuginfo_eip+0x23c>
		for (lline = lfun + 1;
		     lline < rfun && stabs[lline].n_type == N_PSYM;
		     lline++)
			info->eip_fn_narg++;

	return 0;
f0103ea6:	b8 00 00 00 00       	mov    $0x0,%eax
}
f0103eab:	83 c4 4c             	add    $0x4c,%esp
f0103eae:	5b                   	pop    %ebx
f0103eaf:	5e                   	pop    %esi
f0103eb0:	5f                   	pop    %edi
f0103eb1:	5d                   	pop    %ebp
f0103eb2:	c3                   	ret    
f0103eb3:	66 90                	xchg   %ax,%ax
f0103eb5:	66 90                	xchg   %ax,%ax
f0103eb7:	66 90                	xchg   %ax,%ax
f0103eb9:	66 90                	xchg   %ax,%ax
f0103ebb:	66 90                	xchg   %ax,%ax
f0103ebd:	66 90                	xchg   %ax,%ax
f0103ebf:	90                   	nop

f0103ec0 <printnum>:
 * using specified putch function and associated pointer putdat.
 */
static void
printnum(void (*putch)(int, void*), void *putdat,
	 unsigned long long num, unsigned base, int width, int padc)
{
f0103ec0:	55                   	push   %ebp
f0103ec1:	89 e5                	mov    %esp,%ebp
f0103ec3:	57                   	push   %edi
f0103ec4:	56                   	push   %esi
f0103ec5:	53                   	push   %ebx
f0103ec6:	83 ec 3c             	sub    $0x3c,%esp
f0103ec9:	89 45 e4             	mov    %eax,-0x1c(%ebp)
f0103ecc:	89 d7                	mov    %edx,%edi
f0103ece:	8b 45 08             	mov    0x8(%ebp),%eax
f0103ed1:	89 45 e0             	mov    %eax,-0x20(%ebp)
f0103ed4:	8b 45 0c             	mov    0xc(%ebp),%eax
f0103ed7:	89 c3                	mov    %eax,%ebx
f0103ed9:	89 45 d4             	mov    %eax,-0x2c(%ebp)
f0103edc:	8b 45 10             	mov    0x10(%ebp),%eax
f0103edf:	8b 75 14             	mov    0x14(%ebp),%esi
	// first recursively print all preceding (more significant) digits
	if (num >= base) {
f0103ee2:	b9 00 00 00 00       	mov    $0x0,%ecx
f0103ee7:	89 45 d8             	mov    %eax,-0x28(%ebp)
f0103eea:	89 4d dc             	mov    %ecx,-0x24(%ebp)
f0103eed:	39 d9                	cmp    %ebx,%ecx
f0103eef:	72 05                	jb     f0103ef6 <printnum+0x36>
f0103ef1:	3b 45 e0             	cmp    -0x20(%ebp),%eax
f0103ef4:	77 69                	ja     f0103f5f <printnum+0x9f>
		printnum(putch, putdat, num / base, base, width - 1, padc);
f0103ef6:	8b 4d 18             	mov    0x18(%ebp),%ecx
f0103ef9:	89 4c 24 10          	mov    %ecx,0x10(%esp)
f0103efd:	83 ee 01             	sub    $0x1,%esi
f0103f00:	89 74 24 0c          	mov    %esi,0xc(%esp)
f0103f04:	89 44 24 08          	mov    %eax,0x8(%esp)
f0103f08:	8b 44 24 08          	mov    0x8(%esp),%eax
f0103f0c:	8b 54 24 0c          	mov    0xc(%esp),%edx
f0103f10:	89 c3                	mov    %eax,%ebx
f0103f12:	89 d6                	mov    %edx,%esi
f0103f14:	8b 55 d8             	mov    -0x28(%ebp),%edx
f0103f17:	8b 4d dc             	mov    -0x24(%ebp),%ecx
f0103f1a:	89 54 24 08          	mov    %edx,0x8(%esp)
f0103f1e:	89 4c 24 0c          	mov    %ecx,0xc(%esp)
f0103f22:	8b 45 e0             	mov    -0x20(%ebp),%eax
f0103f25:	89 04 24             	mov    %eax,(%esp)
f0103f28:	8b 45 d4             	mov    -0x2c(%ebp),%eax
f0103f2b:	89 44 24 04          	mov    %eax,0x4(%esp)
f0103f2f:	e8 9c 09 00 00       	call   f01048d0 <__udivdi3>
f0103f34:	89 d9                	mov    %ebx,%ecx
f0103f36:	89 4c 24 08          	mov    %ecx,0x8(%esp)
f0103f3a:	89 74 24 0c          	mov    %esi,0xc(%esp)
f0103f3e:	89 04 24             	mov    %eax,(%esp)
f0103f41:	89 54 24 04          	mov    %edx,0x4(%esp)
f0103f45:	89 fa                	mov    %edi,%edx
f0103f47:	8b 45 e4             	mov    -0x1c(%ebp),%eax
f0103f4a:	e8 71 ff ff ff       	call   f0103ec0 <printnum>
f0103f4f:	eb 1b                	jmp    f0103f6c <printnum+0xac>
	} else {
		// print any needed pad characters before first digit
		while (--width > 0)
			putch(padc, putdat);
f0103f51:	89 7c 24 04          	mov    %edi,0x4(%esp)
f0103f55:	8b 45 18             	mov    0x18(%ebp),%eax
f0103f58:	89 04 24             	mov    %eax,(%esp)
f0103f5b:	ff d3                	call   *%ebx
f0103f5d:	eb 03                	jmp    f0103f62 <printnum+0xa2>
f0103f5f:	8b 5d e4             	mov    -0x1c(%ebp),%ebx
	// first recursively print all preceding (more significant) digits
	if (num >= base) {
		printnum(putch, putdat, num / base, base, width - 1, padc);
	} else {
		// print any needed pad characters before first digit
		while (--width > 0)
f0103f62:	83 ee 01             	sub    $0x1,%esi
f0103f65:	85 f6                	test   %esi,%esi
f0103f67:	7f e8                	jg     f0103f51 <printnum+0x91>
f0103f69:	89 5d e4             	mov    %ebx,-0x1c(%ebp)
			putch(padc, putdat);
	}

	// then print this (the least significant) digit
	putch("0123456789abcdef"[num % base], putdat);
f0103f6c:	89 7c 24 04          	mov    %edi,0x4(%esp)
f0103f70:	8b 7c 24 04          	mov    0x4(%esp),%edi
f0103f74:	8b 45 d8             	mov    -0x28(%ebp),%eax
f0103f77:	8b 55 dc             	mov    -0x24(%ebp),%edx
f0103f7a:	89 44 24 08          	mov    %eax,0x8(%esp)
f0103f7e:	89 54 24 0c          	mov    %edx,0xc(%esp)
f0103f82:	8b 45 e0             	mov    -0x20(%ebp),%eax
f0103f85:	89 04 24             	mov    %eax,(%esp)
f0103f88:	8b 45 d4             	mov    -0x2c(%ebp),%eax
f0103f8b:	89 44 24 04          	mov    %eax,0x4(%esp)
f0103f8f:	e8 6c 0a 00 00       	call   f0104a00 <__umoddi3>
f0103f94:	89 7c 24 04          	mov    %edi,0x4(%esp)
f0103f98:	0f be 80 e1 61 10 f0 	movsbl -0xfef9e1f(%eax),%eax
f0103f9f:	89 04 24             	mov    %eax,(%esp)
f0103fa2:	8b 45 e4             	mov    -0x1c(%ebp),%eax
f0103fa5:	ff d0                	call   *%eax
}
f0103fa7:	83 c4 3c             	add    $0x3c,%esp
f0103faa:	5b                   	pop    %ebx
f0103fab:	5e                   	pop    %esi
f0103fac:	5f                   	pop    %edi
f0103fad:	5d                   	pop    %ebp
f0103fae:	c3                   	ret    

f0103faf <getuint>:

// Get an unsigned int of various possible sizes from a varargs list,
// depending on the lflag parameter.
static unsigned long long
getuint(va_list *ap, int lflag)
{
f0103faf:	55                   	push   %ebp
f0103fb0:	89 e5                	mov    %esp,%ebp
	if (lflag >= 2)
f0103fb2:	83 fa 01             	cmp    $0x1,%edx
f0103fb5:	7e 0e                	jle    f0103fc5 <getuint+0x16>
		return va_arg(*ap, unsigned long long);
f0103fb7:	8b 10                	mov    (%eax),%edx
f0103fb9:	8d 4a 08             	lea    0x8(%edx),%ecx
f0103fbc:	89 08                	mov    %ecx,(%eax)
f0103fbe:	8b 02                	mov    (%edx),%eax
f0103fc0:	8b 52 04             	mov    0x4(%edx),%edx
f0103fc3:	eb 22                	jmp    f0103fe7 <getuint+0x38>
	else if (lflag)
f0103fc5:	85 d2                	test   %edx,%edx
f0103fc7:	74 10                	je     f0103fd9 <getuint+0x2a>
		return va_arg(*ap, unsigned long);
f0103fc9:	8b 10                	mov    (%eax),%edx
f0103fcb:	8d 4a 04             	lea    0x4(%edx),%ecx
f0103fce:	89 08                	mov    %ecx,(%eax)
f0103fd0:	8b 02                	mov    (%edx),%eax
f0103fd2:	ba 00 00 00 00       	mov    $0x0,%edx
f0103fd7:	eb 0e                	jmp    f0103fe7 <getuint+0x38>
	else
		return va_arg(*ap, unsigned int);
f0103fd9:	8b 10                	mov    (%eax),%edx
f0103fdb:	8d 4a 04             	lea    0x4(%edx),%ecx
f0103fde:	89 08                	mov    %ecx,(%eax)
f0103fe0:	8b 02                	mov    (%edx),%eax
f0103fe2:	ba 00 00 00 00       	mov    $0x0,%edx
}
f0103fe7:	5d                   	pop    %ebp
f0103fe8:	c3                   	ret    

f0103fe9 <getint>:

// Same as getuint but signed - can't use getuint
// because of sign extension
static long long
getint(va_list *ap, int lflag)
{
f0103fe9:	55                   	push   %ebp
f0103fea:	89 e5                	mov    %esp,%ebp
	if (lflag >= 2)
f0103fec:	83 fa 01             	cmp    $0x1,%edx
f0103fef:	7e 0e                	jle    f0103fff <getint+0x16>
		return va_arg(*ap, long long);
f0103ff1:	8b 10                	mov    (%eax),%edx
f0103ff3:	8d 4a 08             	lea    0x8(%edx),%ecx
f0103ff6:	89 08                	mov    %ecx,(%eax)
f0103ff8:	8b 02                	mov    (%edx),%eax
f0103ffa:	8b 52 04             	mov    0x4(%edx),%edx
f0103ffd:	eb 1a                	jmp    f0104019 <getint+0x30>
	else if (lflag)
f0103fff:	85 d2                	test   %edx,%edx
f0104001:	74 0c                	je     f010400f <getint+0x26>
		return va_arg(*ap, long);
f0104003:	8b 10                	mov    (%eax),%edx
f0104005:	8d 4a 04             	lea    0x4(%edx),%ecx
f0104008:	89 08                	mov    %ecx,(%eax)
f010400a:	8b 02                	mov    (%edx),%eax
f010400c:	99                   	cltd   
f010400d:	eb 0a                	jmp    f0104019 <getint+0x30>
	else
		return va_arg(*ap, int);
f010400f:	8b 10                	mov    (%eax),%edx
f0104011:	8d 4a 04             	lea    0x4(%edx),%ecx
f0104014:	89 08                	mov    %ecx,(%eax)
f0104016:	8b 02                	mov    (%edx),%eax
f0104018:	99                   	cltd   
}
f0104019:	5d                   	pop    %ebp
f010401a:	c3                   	ret    

f010401b <sprintputch>:
	int cnt;
};

static void
sprintputch(int ch, struct sprintbuf *b)
{
f010401b:	55                   	push   %ebp
f010401c:	89 e5                	mov    %esp,%ebp
f010401e:	8b 45 0c             	mov    0xc(%ebp),%eax
	b->cnt++;
f0104021:	83 40 08 01          	addl   $0x1,0x8(%eax)
	if (b->buf < b->ebuf)
f0104025:	8b 10                	mov    (%eax),%edx
f0104027:	3b 50 04             	cmp    0x4(%eax),%edx
f010402a:	73 0a                	jae    f0104036 <sprintputch+0x1b>
		*b->buf++ = ch;
f010402c:	8d 4a 01             	lea    0x1(%edx),%ecx
f010402f:	89 08                	mov    %ecx,(%eax)
f0104031:	8b 45 08             	mov    0x8(%ebp),%eax
f0104034:	88 02                	mov    %al,(%edx)
}
f0104036:	5d                   	pop    %ebp
f0104037:	c3                   	ret    

f0104038 <printfmt>:
	}
}

void
printfmt(void (*putch)(int, void*), void *putdat, const char *fmt, ...)
{
f0104038:	55                   	push   %ebp
f0104039:	89 e5                	mov    %esp,%ebp
f010403b:	83 ec 18             	sub    $0x18,%esp
	va_list ap;

	va_start(ap, fmt);
f010403e:	8d 45 14             	lea    0x14(%ebp),%eax
	vprintfmt(putch, putdat, fmt, ap);
f0104041:	89 44 24 0c          	mov    %eax,0xc(%esp)
f0104045:	8b 45 10             	mov    0x10(%ebp),%eax
f0104048:	89 44 24 08          	mov    %eax,0x8(%esp)
f010404c:	8b 45 0c             	mov    0xc(%ebp),%eax
f010404f:	89 44 24 04          	mov    %eax,0x4(%esp)
f0104053:	8b 45 08             	mov    0x8(%ebp),%eax
f0104056:	89 04 24             	mov    %eax,(%esp)
f0104059:	e8 02 00 00 00       	call   f0104060 <vprintfmt>
	va_end(ap);
}
f010405e:	c9                   	leave  
f010405f:	c3                   	ret    

f0104060 <vprintfmt>:
// Main function to format and print a string.
void printfmt(void (*putch)(int, void*), void *putdat, const char *fmt, ...);

void
vprintfmt(void (*putch)(int, void*), void *putdat, const char *fmt, va_list ap)
{
f0104060:	55                   	push   %ebp
f0104061:	89 e5                	mov    %esp,%ebp
f0104063:	57                   	push   %edi
f0104064:	56                   	push   %esi
f0104065:	53                   	push   %ebx
f0104066:	83 ec 3c             	sub    $0x3c,%esp
f0104069:	8b 75 0c             	mov    0xc(%ebp),%esi
f010406c:	8b 7d 10             	mov    0x10(%ebp),%edi
f010406f:	eb 14                	jmp    f0104085 <vprintfmt+0x25>
	int base, lflag, width, precision, altflag;
	char padc;

	while (1) {
		while ((ch = *(unsigned char *) fmt++) != '%') {
			if (ch == '\0')
f0104071:	85 c0                	test   %eax,%eax
f0104073:	0f 84 63 03 00 00    	je     f01043dc <vprintfmt+0x37c>
				return;
			putch(ch, putdat);
f0104079:	89 74 24 04          	mov    %esi,0x4(%esp)
f010407d:	89 04 24             	mov    %eax,(%esp)
f0104080:	ff 55 08             	call   *0x8(%ebp)
	unsigned long long num;
	int base, lflag, width, precision, altflag;
	char padc;

	while (1) {
		while ((ch = *(unsigned char *) fmt++) != '%') {
f0104083:	89 df                	mov    %ebx,%edi
f0104085:	8d 5f 01             	lea    0x1(%edi),%ebx
f0104088:	0f b6 07             	movzbl (%edi),%eax
f010408b:	83 f8 25             	cmp    $0x25,%eax
f010408e:	75 e1                	jne    f0104071 <vprintfmt+0x11>
f0104090:	c6 45 d8 20          	movb   $0x20,-0x28(%ebp)
f0104094:	c7 45 e0 00 00 00 00 	movl   $0x0,-0x20(%ebp)
f010409b:	c7 45 d4 ff ff ff ff 	movl   $0xffffffff,-0x2c(%ebp)
f01040a2:	c7 45 dc ff ff ff ff 	movl   $0xffffffff,-0x24(%ebp)
f01040a9:	ba 00 00 00 00       	mov    $0x0,%edx
f01040ae:	eb 1d                	jmp    f01040cd <vprintfmt+0x6d>
		width = -1;
		precision = -1;
		lflag = 0;
		altflag = 0;
	reswitch:
		switch (ch = *(unsigned char *) fmt++) {
f01040b0:	89 fb                	mov    %edi,%ebx

		// flag to pad on the right
		case '-':
			padc = '-';
f01040b2:	c6 45 d8 2d          	movb   $0x2d,-0x28(%ebp)
f01040b6:	eb 15                	jmp    f01040cd <vprintfmt+0x6d>
		width = -1;
		precision = -1;
		lflag = 0;
		altflag = 0;
	reswitch:
		switch (ch = *(unsigned char *) fmt++) {
f01040b8:	89 fb                	mov    %edi,%ebx
			padc = '-';
			goto reswitch;

		// flag to pad with 0's instead of spaces
		case '0':
			padc = '0';
f01040ba:	c6 45 d8 30          	movb   $0x30,-0x28(%ebp)
f01040be:	eb 0d                	jmp    f01040cd <vprintfmt+0x6d>
			altflag = 1;
			goto reswitch;

		process_precision:
			if (width < 0)
				width = precision, precision = -1;
f01040c0:	8b 45 d4             	mov    -0x2c(%ebp),%eax
f01040c3:	89 45 dc             	mov    %eax,-0x24(%ebp)
f01040c6:	c7 45 d4 ff ff ff ff 	movl   $0xffffffff,-0x2c(%ebp)
		width = -1;
		precision = -1;
		lflag = 0;
		altflag = 0;
	reswitch:
		switch (ch = *(unsigned char *) fmt++) {
f01040cd:	8d 7b 01             	lea    0x1(%ebx),%edi
f01040d0:	0f b6 0b             	movzbl (%ebx),%ecx
f01040d3:	0f b6 c1             	movzbl %cl,%eax
f01040d6:	83 e9 23             	sub    $0x23,%ecx
f01040d9:	80 f9 55             	cmp    $0x55,%cl
f01040dc:	0f 87 da 02 00 00    	ja     f01043bc <vprintfmt+0x35c>
f01040e2:	0f b6 c9             	movzbl %cl,%ecx
f01040e5:	ff 24 8d 6c 62 10 f0 	jmp    *-0xfef9d94(,%ecx,4)
f01040ec:	89 fb                	mov    %edi,%ebx
f01040ee:	b9 00 00 00 00       	mov    $0x0,%ecx
		case '6':
		case '7':
		case '8':
		case '9':
			for (precision = 0; ; ++fmt) {
				precision = precision * 10 + ch - '0';
f01040f3:	8d 0c 89             	lea    (%ecx,%ecx,4),%ecx
f01040f6:	8d 4c 48 d0          	lea    -0x30(%eax,%ecx,2),%ecx
				ch = *fmt;
f01040fa:	0f be 03             	movsbl (%ebx),%eax
				if (ch < '0' || ch > '9')
f01040fd:	8d 78 d0             	lea    -0x30(%eax),%edi
f0104100:	83 ff 09             	cmp    $0x9,%edi
f0104103:	77 36                	ja     f010413b <vprintfmt+0xdb>
		case '5':
		case '6':
		case '7':
		case '8':
		case '9':
			for (precision = 0; ; ++fmt) {
f0104105:	83 c3 01             	add    $0x1,%ebx
				precision = precision * 10 + ch - '0';
				ch = *fmt;
				if (ch < '0' || ch > '9')
					break;
			}
f0104108:	eb e9                	jmp    f01040f3 <vprintfmt+0x93>
			goto process_precision;

		case '*':
			precision = va_arg(ap, int);
f010410a:	8b 45 14             	mov    0x14(%ebp),%eax
f010410d:	8d 48 04             	lea    0x4(%eax),%ecx
f0104110:	89 4d 14             	mov    %ecx,0x14(%ebp)
f0104113:	8b 00                	mov    (%eax),%eax
f0104115:	89 45 d4             	mov    %eax,-0x2c(%ebp)
		width = -1;
		precision = -1;
		lflag = 0;
		altflag = 0;
	reswitch:
		switch (ch = *(unsigned char *) fmt++) {
f0104118:	89 fb                	mov    %edi,%ebx
			}
			goto process_precision;

		case '*':
			precision = va_arg(ap, int);
			goto process_precision;
f010411a:	eb 22                	jmp    f010413e <vprintfmt+0xde>
f010411c:	8b 4d dc             	mov    -0x24(%ebp),%ecx
f010411f:	85 c9                	test   %ecx,%ecx
f0104121:	b8 00 00 00 00       	mov    $0x0,%eax
f0104126:	0f 49 c1             	cmovns %ecx,%eax
f0104129:	89 45 dc             	mov    %eax,-0x24(%ebp)
		width = -1;
		precision = -1;
		lflag = 0;
		altflag = 0;
	reswitch:
		switch (ch = *(unsigned char *) fmt++) {
f010412c:	89 fb                	mov    %edi,%ebx
f010412e:	eb 9d                	jmp    f01040cd <vprintfmt+0x6d>
f0104130:	89 fb                	mov    %edi,%ebx
			if (width < 0)
				width = 0;
			goto reswitch;

		case '#':
			altflag = 1;
f0104132:	c7 45 e0 01 00 00 00 	movl   $0x1,-0x20(%ebp)
			goto reswitch;
f0104139:	eb 92                	jmp    f01040cd <vprintfmt+0x6d>
f010413b:	89 4d d4             	mov    %ecx,-0x2c(%ebp)

		process_precision:
			if (width < 0)
f010413e:	83 7d dc 00          	cmpl   $0x0,-0x24(%ebp)
f0104142:	79 89                	jns    f01040cd <vprintfmt+0x6d>
f0104144:	e9 77 ff ff ff       	jmp    f01040c0 <vprintfmt+0x60>
				width = precision, precision = -1;
			goto reswitch;

		// long flag (doubled for long long)
		case 'l':
			lflag++;
f0104149:	83 c2 01             	add    $0x1,%edx
		width = -1;
		precision = -1;
		lflag = 0;
		altflag = 0;
	reswitch:
		switch (ch = *(unsigned char *) fmt++) {
f010414c:	89 fb                	mov    %edi,%ebx
			goto reswitch;

		// long flag (doubled for long long)
		case 'l':
			lflag++;
			goto reswitch;
f010414e:	e9 7a ff ff ff       	jmp    f01040cd <vprintfmt+0x6d>

		// character
		case 'c':
			putch(va_arg(ap, int), putdat);
f0104153:	8b 45 14             	mov    0x14(%ebp),%eax
f0104156:	8d 50 04             	lea    0x4(%eax),%edx
f0104159:	89 55 14             	mov    %edx,0x14(%ebp)
f010415c:	89 74 24 04          	mov    %esi,0x4(%esp)
f0104160:	8b 00                	mov    (%eax),%eax
f0104162:	89 04 24             	mov    %eax,(%esp)
f0104165:	ff 55 08             	call   *0x8(%ebp)
			break;
f0104168:	e9 18 ff ff ff       	jmp    f0104085 <vprintfmt+0x25>

		// error message
		case 'e':
			err = va_arg(ap, int);
f010416d:	8b 45 14             	mov    0x14(%ebp),%eax
f0104170:	8d 50 04             	lea    0x4(%eax),%edx
f0104173:	89 55 14             	mov    %edx,0x14(%ebp)
f0104176:	8b 00                	mov    (%eax),%eax
f0104178:	99                   	cltd   
f0104179:	31 d0                	xor    %edx,%eax
f010417b:	29 d0                	sub    %edx,%eax
			if (err < 0)
				err = -err;
			if (err >= MAXERROR || (p = error_string[err]) == NULL)
f010417d:	83 f8 06             	cmp    $0x6,%eax
f0104180:	7f 0b                	jg     f010418d <vprintfmt+0x12d>
f0104182:	8b 14 85 c4 63 10 f0 	mov    -0xfef9c3c(,%eax,4),%edx
f0104189:	85 d2                	test   %edx,%edx
f010418b:	75 20                	jne    f01041ad <vprintfmt+0x14d>
				printfmt(putch, putdat, "error %d", err);
f010418d:	89 44 24 0c          	mov    %eax,0xc(%esp)
f0104191:	c7 44 24 08 f9 61 10 	movl   $0xf01061f9,0x8(%esp)
f0104198:	f0 
f0104199:	89 74 24 04          	mov    %esi,0x4(%esp)
f010419d:	8b 45 08             	mov    0x8(%ebp),%eax
f01041a0:	89 04 24             	mov    %eax,(%esp)
f01041a3:	e8 90 fe ff ff       	call   f0104038 <printfmt>
f01041a8:	e9 d8 fe ff ff       	jmp    f0104085 <vprintfmt+0x25>
			else
				printfmt(putch, putdat, "%s", p);
f01041ad:	89 54 24 0c          	mov    %edx,0xc(%esp)
f01041b1:	c7 44 24 08 cc 58 10 	movl   $0xf01058cc,0x8(%esp)
f01041b8:	f0 
f01041b9:	89 74 24 04          	mov    %esi,0x4(%esp)
f01041bd:	8b 45 08             	mov    0x8(%ebp),%eax
f01041c0:	89 04 24             	mov    %eax,(%esp)
f01041c3:	e8 70 fe ff ff       	call   f0104038 <printfmt>
f01041c8:	e9 b8 fe ff ff       	jmp    f0104085 <vprintfmt+0x25>
		width = -1;
		precision = -1;
		lflag = 0;
		altflag = 0;
	reswitch:
		switch (ch = *(unsigned char *) fmt++) {
f01041cd:	8b 4d d4             	mov    -0x2c(%ebp),%ecx
f01041d0:	8b 45 dc             	mov    -0x24(%ebp),%eax
f01041d3:	89 45 d0             	mov    %eax,-0x30(%ebp)
				printfmt(putch, putdat, "%s", p);
			break;

		// string
		case 's':
			if ((p = va_arg(ap, char *)) == NULL)
f01041d6:	8b 45 14             	mov    0x14(%ebp),%eax
f01041d9:	8d 50 04             	lea    0x4(%eax),%edx
f01041dc:	89 55 14             	mov    %edx,0x14(%ebp)
f01041df:	8b 18                	mov    (%eax),%ebx
				p = "(null)";
f01041e1:	85 db                	test   %ebx,%ebx
f01041e3:	b8 f2 61 10 f0       	mov    $0xf01061f2,%eax
f01041e8:	0f 44 d8             	cmove  %eax,%ebx
			if (width > 0 && padc != '-')
f01041eb:	80 7d d8 2d          	cmpb   $0x2d,-0x28(%ebp)
f01041ef:	0f 84 97 00 00 00    	je     f010428c <vprintfmt+0x22c>
f01041f5:	83 7d d0 00          	cmpl   $0x0,-0x30(%ebp)
f01041f9:	0f 8e 9b 00 00 00    	jle    f010429a <vprintfmt+0x23a>
				for (width -= strnlen(p, precision); width > 0; width--)
f01041ff:	89 4c 24 04          	mov    %ecx,0x4(%esp)
f0104203:	89 1c 24             	mov    %ebx,(%esp)
f0104206:	e8 4d 03 00 00       	call   f0104558 <strnlen>
f010420b:	8b 55 d0             	mov    -0x30(%ebp),%edx
f010420e:	29 c2                	sub    %eax,%edx
f0104210:	89 55 d0             	mov    %edx,-0x30(%ebp)
					putch(padc, putdat);
f0104213:	0f be 45 d8          	movsbl -0x28(%ebp),%eax
f0104217:	89 45 dc             	mov    %eax,-0x24(%ebp)
f010421a:	89 5d d8             	mov    %ebx,-0x28(%ebp)
f010421d:	89 d3                	mov    %edx,%ebx
f010421f:	89 7d 10             	mov    %edi,0x10(%ebp)
f0104222:	8b 7d 08             	mov    0x8(%ebp),%edi
		// string
		case 's':
			if ((p = va_arg(ap, char *)) == NULL)
				p = "(null)";
			if (width > 0 && padc != '-')
				for (width -= strnlen(p, precision); width > 0; width--)
f0104225:	eb 0f                	jmp    f0104236 <vprintfmt+0x1d6>
					putch(padc, putdat);
f0104227:	89 74 24 04          	mov    %esi,0x4(%esp)
f010422b:	8b 45 dc             	mov    -0x24(%ebp),%eax
f010422e:	89 04 24             	mov    %eax,(%esp)
f0104231:	ff d7                	call   *%edi
		// string
		case 's':
			if ((p = va_arg(ap, char *)) == NULL)
				p = "(null)";
			if (width > 0 && padc != '-')
				for (width -= strnlen(p, precision); width > 0; width--)
f0104233:	83 eb 01             	sub    $0x1,%ebx
f0104236:	85 db                	test   %ebx,%ebx
f0104238:	7f ed                	jg     f0104227 <vprintfmt+0x1c7>
f010423a:	8b 5d d8             	mov    -0x28(%ebp),%ebx
f010423d:	8b 55 d0             	mov    -0x30(%ebp),%edx
f0104240:	85 d2                	test   %edx,%edx
f0104242:	b8 00 00 00 00       	mov    $0x0,%eax
f0104247:	0f 49 c2             	cmovns %edx,%eax
f010424a:	29 c2                	sub    %eax,%edx
f010424c:	89 75 0c             	mov    %esi,0xc(%ebp)
f010424f:	89 d6                	mov    %edx,%esi
f0104251:	8b 7d d4             	mov    -0x2c(%ebp),%edi
f0104254:	eb 50                	jmp    f01042a6 <vprintfmt+0x246>
					putch(padc, putdat);
			for (; (ch = *p++) != '\0' && (precision < 0 || --precision >= 0); width--)
				if (altflag && (ch < ' ' || ch > '~'))
f0104256:	83 7d e0 00          	cmpl   $0x0,-0x20(%ebp)
f010425a:	74 1e                	je     f010427a <vprintfmt+0x21a>
f010425c:	0f be d2             	movsbl %dl,%edx
f010425f:	83 ea 20             	sub    $0x20,%edx
f0104262:	83 fa 5e             	cmp    $0x5e,%edx
f0104265:	76 13                	jbe    f010427a <vprintfmt+0x21a>
					putch('?', putdat);
f0104267:	8b 45 0c             	mov    0xc(%ebp),%eax
f010426a:	89 44 24 04          	mov    %eax,0x4(%esp)
f010426e:	c7 04 24 3f 00 00 00 	movl   $0x3f,(%esp)
f0104275:	ff 55 08             	call   *0x8(%ebp)
f0104278:	eb 0d                	jmp    f0104287 <vprintfmt+0x227>
				else
					putch(ch, putdat);
f010427a:	8b 55 0c             	mov    0xc(%ebp),%edx
f010427d:	89 54 24 04          	mov    %edx,0x4(%esp)
f0104281:	89 04 24             	mov    %eax,(%esp)
f0104284:	ff 55 08             	call   *0x8(%ebp)
			if ((p = va_arg(ap, char *)) == NULL)
				p = "(null)";
			if (width > 0 && padc != '-')
				for (width -= strnlen(p, precision); width > 0; width--)
					putch(padc, putdat);
			for (; (ch = *p++) != '\0' && (precision < 0 || --precision >= 0); width--)
f0104287:	83 ee 01             	sub    $0x1,%esi
f010428a:	eb 1a                	jmp    f01042a6 <vprintfmt+0x246>
f010428c:	89 75 0c             	mov    %esi,0xc(%ebp)
f010428f:	8b 75 dc             	mov    -0x24(%ebp),%esi
f0104292:	89 7d 10             	mov    %edi,0x10(%ebp)
f0104295:	8b 7d d4             	mov    -0x2c(%ebp),%edi
f0104298:	eb 0c                	jmp    f01042a6 <vprintfmt+0x246>
f010429a:	89 75 0c             	mov    %esi,0xc(%ebp)
f010429d:	8b 75 dc             	mov    -0x24(%ebp),%esi
f01042a0:	89 7d 10             	mov    %edi,0x10(%ebp)
f01042a3:	8b 7d d4             	mov    -0x2c(%ebp),%edi
f01042a6:	83 c3 01             	add    $0x1,%ebx
f01042a9:	0f b6 53 ff          	movzbl -0x1(%ebx),%edx
f01042ad:	0f be c2             	movsbl %dl,%eax
f01042b0:	85 c0                	test   %eax,%eax
f01042b2:	74 25                	je     f01042d9 <vprintfmt+0x279>
f01042b4:	85 ff                	test   %edi,%edi
f01042b6:	78 9e                	js     f0104256 <vprintfmt+0x1f6>
f01042b8:	83 ef 01             	sub    $0x1,%edi
f01042bb:	79 99                	jns    f0104256 <vprintfmt+0x1f6>
f01042bd:	89 f3                	mov    %esi,%ebx
f01042bf:	8b 75 0c             	mov    0xc(%ebp),%esi
f01042c2:	8b 7d 08             	mov    0x8(%ebp),%edi
f01042c5:	eb 1a                	jmp    f01042e1 <vprintfmt+0x281>
				if (altflag && (ch < ' ' || ch > '~'))
					putch('?', putdat);
				else
					putch(ch, putdat);
			for (; width > 0; width--)
				putch(' ', putdat);
f01042c7:	89 74 24 04          	mov    %esi,0x4(%esp)
f01042cb:	c7 04 24 20 00 00 00 	movl   $0x20,(%esp)
f01042d2:	ff d7                	call   *%edi
			for (; (ch = *p++) != '\0' && (precision < 0 || --precision >= 0); width--)
				if (altflag && (ch < ' ' || ch > '~'))
					putch('?', putdat);
				else
					putch(ch, putdat);
			for (; width > 0; width--)
f01042d4:	83 eb 01             	sub    $0x1,%ebx
f01042d7:	eb 08                	jmp    f01042e1 <vprintfmt+0x281>
f01042d9:	89 f3                	mov    %esi,%ebx
f01042db:	8b 7d 08             	mov    0x8(%ebp),%edi
f01042de:	8b 75 0c             	mov    0xc(%ebp),%esi
f01042e1:	85 db                	test   %ebx,%ebx
f01042e3:	7f e2                	jg     f01042c7 <vprintfmt+0x267>
f01042e5:	89 7d 08             	mov    %edi,0x8(%ebp)
f01042e8:	8b 7d 10             	mov    0x10(%ebp),%edi
f01042eb:	e9 95 fd ff ff       	jmp    f0104085 <vprintfmt+0x25>
				putch(' ', putdat);
			break;

		// (signed) decimal
		case 'd':
			num = getint(&ap, lflag);
f01042f0:	8d 45 14             	lea    0x14(%ebp),%eax
f01042f3:	e8 f1 fc ff ff       	call   f0103fe9 <getint>
f01042f8:	89 45 e0             	mov    %eax,-0x20(%ebp)
f01042fb:	89 55 e4             	mov    %edx,-0x1c(%ebp)
			if ((long long) num < 0) {
				putch('-', putdat);
				num = -(long long) num;
			}
			base = 10;
f01042fe:	bb 0a 00 00 00       	mov    $0xa,%ebx
			break;

		// (signed) decimal
		case 'd':
			num = getint(&ap, lflag);
			if ((long long) num < 0) {
f0104303:	83 7d e4 00          	cmpl   $0x0,-0x1c(%ebp)
f0104307:	79 7b                	jns    f0104384 <vprintfmt+0x324>
				putch('-', putdat);
f0104309:	89 74 24 04          	mov    %esi,0x4(%esp)
f010430d:	c7 04 24 2d 00 00 00 	movl   $0x2d,(%esp)
f0104314:	ff 55 08             	call   *0x8(%ebp)
				num = -(long long) num;
f0104317:	8b 45 e0             	mov    -0x20(%ebp),%eax
f010431a:	8b 55 e4             	mov    -0x1c(%ebp),%edx
f010431d:	f7 d8                	neg    %eax
f010431f:	83 d2 00             	adc    $0x0,%edx
f0104322:	f7 da                	neg    %edx
f0104324:	eb 5e                	jmp    f0104384 <vprintfmt+0x324>
			base = 10;
			goto number;

		// unsigned decimal
		case 'u':
			num = getuint(&ap, lflag);
f0104326:	8d 45 14             	lea    0x14(%ebp),%eax
f0104329:	e8 81 fc ff ff       	call   f0103faf <getuint>
			base = 10;
f010432e:	bb 0a 00 00 00       	mov    $0xa,%ebx
			goto number;
f0104333:	eb 4f                	jmp    f0104384 <vprintfmt+0x324>

		// (unsigned) octal
		case 'o':
			num = getuint(&ap, lflag);
f0104335:	8d 45 14             	lea    0x14(%ebp),%eax
f0104338:	e8 72 fc ff ff       	call   f0103faf <getuint>
			base = 8;
f010433d:	bb 08 00 00 00       	mov    $0x8,%ebx
			goto number;
f0104342:	eb 40                	jmp    f0104384 <vprintfmt+0x324>

		// pointer
		case 'p':
			putch('0', putdat);
f0104344:	89 74 24 04          	mov    %esi,0x4(%esp)
f0104348:	c7 04 24 30 00 00 00 	movl   $0x30,(%esp)
f010434f:	ff 55 08             	call   *0x8(%ebp)
			putch('x', putdat);
f0104352:	89 74 24 04          	mov    %esi,0x4(%esp)
f0104356:	c7 04 24 78 00 00 00 	movl   $0x78,(%esp)
f010435d:	ff 55 08             	call   *0x8(%ebp)
			num = (unsigned long long)
				(uintptr_t) va_arg(ap, void *);
f0104360:	8b 45 14             	mov    0x14(%ebp),%eax
f0104363:	8d 50 04             	lea    0x4(%eax),%edx
f0104366:	89 55 14             	mov    %edx,0x14(%ebp)

		// pointer
		case 'p':
			putch('0', putdat);
			putch('x', putdat);
			num = (unsigned long long)
f0104369:	8b 00                	mov    (%eax),%eax
f010436b:	ba 00 00 00 00       	mov    $0x0,%edx
				(uintptr_t) va_arg(ap, void *);
			base = 16;
f0104370:	bb 10 00 00 00       	mov    $0x10,%ebx
			goto number;
f0104375:	eb 0d                	jmp    f0104384 <vprintfmt+0x324>

		// (unsigned) hexadecimal
		case 'x':
			num = getuint(&ap, lflag);
f0104377:	8d 45 14             	lea    0x14(%ebp),%eax
f010437a:	e8 30 fc ff ff       	call   f0103faf <getuint>
			base = 16;
f010437f:	bb 10 00 00 00       	mov    $0x10,%ebx
		number:
			printnum(putch, putdat, num, base, width, padc);
f0104384:	0f be 4d d8          	movsbl -0x28(%ebp),%ecx
f0104388:	89 4c 24 10          	mov    %ecx,0x10(%esp)
f010438c:	8b 4d dc             	mov    -0x24(%ebp),%ecx
f010438f:	89 4c 24 0c          	mov    %ecx,0xc(%esp)
f0104393:	89 5c 24 08          	mov    %ebx,0x8(%esp)
f0104397:	89 04 24             	mov    %eax,(%esp)
f010439a:	89 54 24 04          	mov    %edx,0x4(%esp)
f010439e:	89 f2                	mov    %esi,%edx
f01043a0:	8b 45 08             	mov    0x8(%ebp),%eax
f01043a3:	e8 18 fb ff ff       	call   f0103ec0 <printnum>
			break;
f01043a8:	e9 d8 fc ff ff       	jmp    f0104085 <vprintfmt+0x25>

		// escaped '%' character
		case '%':
			putch(ch, putdat);
f01043ad:	89 74 24 04          	mov    %esi,0x4(%esp)
f01043b1:	89 04 24             	mov    %eax,(%esp)
f01043b4:	ff 55 08             	call   *0x8(%ebp)
			break;
f01043b7:	e9 c9 fc ff ff       	jmp    f0104085 <vprintfmt+0x25>

		// unrecognized escape sequence - just print it literally
		default:
			putch('%', putdat);
f01043bc:	89 74 24 04          	mov    %esi,0x4(%esp)
f01043c0:	c7 04 24 25 00 00 00 	movl   $0x25,(%esp)
f01043c7:	ff 55 08             	call   *0x8(%ebp)
			for (fmt--; fmt[-1] != '%'; fmt--)
f01043ca:	89 df                	mov    %ebx,%edi
f01043cc:	eb 03                	jmp    f01043d1 <vprintfmt+0x371>
f01043ce:	83 ef 01             	sub    $0x1,%edi
f01043d1:	80 7f ff 25          	cmpb   $0x25,-0x1(%edi)
f01043d5:	75 f7                	jne    f01043ce <vprintfmt+0x36e>
f01043d7:	e9 a9 fc ff ff       	jmp    f0104085 <vprintfmt+0x25>
				/* do nothing */;
			break;
		}
	}
}
f01043dc:	83 c4 3c             	add    $0x3c,%esp
f01043df:	5b                   	pop    %ebx
f01043e0:	5e                   	pop    %esi
f01043e1:	5f                   	pop    %edi
f01043e2:	5d                   	pop    %ebp
f01043e3:	c3                   	ret    

f01043e4 <vsnprintf>:
		*b->buf++ = ch;
}

int
vsnprintf(char *buf, int n, const char *fmt, va_list ap)
{
f01043e4:	55                   	push   %ebp
f01043e5:	89 e5                	mov    %esp,%ebp
f01043e7:	83 ec 28             	sub    $0x28,%esp
f01043ea:	8b 45 08             	mov    0x8(%ebp),%eax
f01043ed:	8b 55 0c             	mov    0xc(%ebp),%edx
	struct sprintbuf b = {buf, buf+n-1, 0};
f01043f0:	89 45 ec             	mov    %eax,-0x14(%ebp)
f01043f3:	8d 4c 10 ff          	lea    -0x1(%eax,%edx,1),%ecx
f01043f7:	89 4d f0             	mov    %ecx,-0x10(%ebp)
f01043fa:	c7 45 f4 00 00 00 00 	movl   $0x0,-0xc(%ebp)

	if (buf == NULL || n < 1)
f0104401:	85 c0                	test   %eax,%eax
f0104403:	74 30                	je     f0104435 <vsnprintf+0x51>
f0104405:	85 d2                	test   %edx,%edx
f0104407:	7e 2c                	jle    f0104435 <vsnprintf+0x51>
		return -E_INVAL;

	// print the string to the buffer
	vprintfmt((void*)sprintputch, &b, fmt, ap);
f0104409:	8b 45 14             	mov    0x14(%ebp),%eax
f010440c:	89 44 24 0c          	mov    %eax,0xc(%esp)
f0104410:	8b 45 10             	mov    0x10(%ebp),%eax
f0104413:	89 44 24 08          	mov    %eax,0x8(%esp)
f0104417:	8d 45 ec             	lea    -0x14(%ebp),%eax
f010441a:	89 44 24 04          	mov    %eax,0x4(%esp)
f010441e:	c7 04 24 1b 40 10 f0 	movl   $0xf010401b,(%esp)
f0104425:	e8 36 fc ff ff       	call   f0104060 <vprintfmt>

	// null terminate the buffer
	*b.buf = '\0';
f010442a:	8b 45 ec             	mov    -0x14(%ebp),%eax
f010442d:	c6 00 00             	movb   $0x0,(%eax)

	return b.cnt;
f0104430:	8b 45 f4             	mov    -0xc(%ebp),%eax
f0104433:	eb 05                	jmp    f010443a <vsnprintf+0x56>
vsnprintf(char *buf, int n, const char *fmt, va_list ap)
{
	struct sprintbuf b = {buf, buf+n-1, 0};

	if (buf == NULL || n < 1)
		return -E_INVAL;
f0104435:	b8 fd ff ff ff       	mov    $0xfffffffd,%eax

	// null terminate the buffer
	*b.buf = '\0';

	return b.cnt;
}
f010443a:	c9                   	leave  
f010443b:	c3                   	ret    

f010443c <snprintf>:

int
snprintf(char *buf, int n, const char *fmt, ...)
{
f010443c:	55                   	push   %ebp
f010443d:	89 e5                	mov    %esp,%ebp
f010443f:	83 ec 18             	sub    $0x18,%esp
	va_list ap;
	int rc;

	va_start(ap, fmt);
f0104442:	8d 45 14             	lea    0x14(%ebp),%eax
	rc = vsnprintf(buf, n, fmt, ap);
f0104445:	89 44 24 0c          	mov    %eax,0xc(%esp)
f0104449:	8b 45 10             	mov    0x10(%ebp),%eax
f010444c:	89 44 24 08          	mov    %eax,0x8(%esp)
f0104450:	8b 45 0c             	mov    0xc(%ebp),%eax
f0104453:	89 44 24 04          	mov    %eax,0x4(%esp)
f0104457:	8b 45 08             	mov    0x8(%ebp),%eax
f010445a:	89 04 24             	mov    %eax,(%esp)
f010445d:	e8 82 ff ff ff       	call   f01043e4 <vsnprintf>
	va_end(ap);

	return rc;
}
f0104462:	c9                   	leave  
f0104463:	c3                   	ret    
f0104464:	66 90                	xchg   %ax,%ax
f0104466:	66 90                	xchg   %ax,%ax
f0104468:	66 90                	xchg   %ax,%ax
f010446a:	66 90                	xchg   %ax,%ax
f010446c:	66 90                	xchg   %ax,%ax
f010446e:	66 90                	xchg   %ax,%ax

f0104470 <readline>:
#define BUFLEN 1024
static char buf[BUFLEN];

char *
readline(const char *prompt)
{
f0104470:	55                   	push   %ebp
f0104471:	89 e5                	mov    %esp,%ebp
f0104473:	57                   	push   %edi
f0104474:	56                   	push   %esi
f0104475:	53                   	push   %ebx
f0104476:	83 ec 1c             	sub    $0x1c,%esp
f0104479:	8b 45 08             	mov    0x8(%ebp),%eax
	int i, c, echoing;

	if (prompt != NULL)
f010447c:	85 c0                	test   %eax,%eax
f010447e:	74 10                	je     f0104490 <readline+0x20>
		cprintf("%s", prompt);
f0104480:	89 44 24 04          	mov    %eax,0x4(%esp)
f0104484:	c7 04 24 cc 58 10 f0 	movl   $0xf01058cc,(%esp)
f010448b:	e8 6e f2 ff ff       	call   f01036fe <cprintf>

	i = 0;
	echoing = iscons(0);
f0104490:	c7 04 24 00 00 00 00 	movl   $0x0,(%esp)
f0104497:	e8 9d c2 ff ff       	call   f0100739 <iscons>
f010449c:	89 c7                	mov    %eax,%edi
	int i, c, echoing;

	if (prompt != NULL)
		cprintf("%s", prompt);

	i = 0;
f010449e:	be 00 00 00 00       	mov    $0x0,%esi
	echoing = iscons(0);
	while (1) {
		c = getchar();
f01044a3:	e8 80 c2 ff ff       	call   f0100728 <getchar>
f01044a8:	89 c3                	mov    %eax,%ebx
		if (c < 0) {
f01044aa:	85 c0                	test   %eax,%eax
f01044ac:	79 17                	jns    f01044c5 <readline+0x55>
			cprintf("read error: %e\n", c);
f01044ae:	89 44 24 04          	mov    %eax,0x4(%esp)
f01044b2:	c7 04 24 e0 63 10 f0 	movl   $0xf01063e0,(%esp)
f01044b9:	e8 40 f2 ff ff       	call   f01036fe <cprintf>
			return NULL;
f01044be:	b8 00 00 00 00       	mov    $0x0,%eax
f01044c3:	eb 6d                	jmp    f0104532 <readline+0xc2>
		} else if ((c == '\b' || c == '\x7f') && i > 0) {
f01044c5:	83 f8 7f             	cmp    $0x7f,%eax
f01044c8:	74 05                	je     f01044cf <readline+0x5f>
f01044ca:	83 f8 08             	cmp    $0x8,%eax
f01044cd:	75 19                	jne    f01044e8 <readline+0x78>
f01044cf:	85 f6                	test   %esi,%esi
f01044d1:	7e 15                	jle    f01044e8 <readline+0x78>
			if (echoing)
f01044d3:	85 ff                	test   %edi,%edi
f01044d5:	74 0c                	je     f01044e3 <readline+0x73>
				cputchar('\b');
f01044d7:	c7 04 24 08 00 00 00 	movl   $0x8,(%esp)
f01044de:	e8 35 c2 ff ff       	call   f0100718 <cputchar>
			i--;
f01044e3:	83 ee 01             	sub    $0x1,%esi
f01044e6:	eb bb                	jmp    f01044a3 <readline+0x33>
		} else if (c >= ' ' && i < BUFLEN-1) {
f01044e8:	81 fe fe 03 00 00    	cmp    $0x3fe,%esi
f01044ee:	7f 1c                	jg     f010450c <readline+0x9c>
f01044f0:	83 fb 1f             	cmp    $0x1f,%ebx
f01044f3:	7e 17                	jle    f010450c <readline+0x9c>
			if (echoing)
f01044f5:	85 ff                	test   %edi,%edi
f01044f7:	74 08                	je     f0104501 <readline+0x91>
				cputchar(c);
f01044f9:	89 1c 24             	mov    %ebx,(%esp)
f01044fc:	e8 17 c2 ff ff       	call   f0100718 <cputchar>
			buf[i++] = c;
f0104501:	88 9e 80 5b 18 f0    	mov    %bl,-0xfe7a480(%esi)
f0104507:	8d 76 01             	lea    0x1(%esi),%esi
f010450a:	eb 97                	jmp    f01044a3 <readline+0x33>
		} else if (c == '\n' || c == '\r') {
f010450c:	83 fb 0d             	cmp    $0xd,%ebx
f010450f:	74 05                	je     f0104516 <readline+0xa6>
f0104511:	83 fb 0a             	cmp    $0xa,%ebx
f0104514:	75 8d                	jne    f01044a3 <readline+0x33>
			if (echoing)
f0104516:	85 ff                	test   %edi,%edi
f0104518:	74 0c                	je     f0104526 <readline+0xb6>
				cputchar('\n');
f010451a:	c7 04 24 0a 00 00 00 	movl   $0xa,(%esp)
f0104521:	e8 f2 c1 ff ff       	call   f0100718 <cputchar>
			buf[i] = 0;
f0104526:	c6 86 80 5b 18 f0 00 	movb   $0x0,-0xfe7a480(%esi)
			return buf;
f010452d:	b8 80 5b 18 f0       	mov    $0xf0185b80,%eax
		}
	}
}
f0104532:	83 c4 1c             	add    $0x1c,%esp
f0104535:	5b                   	pop    %ebx
f0104536:	5e                   	pop    %esi
f0104537:	5f                   	pop    %edi
f0104538:	5d                   	pop    %ebp
f0104539:	c3                   	ret    
f010453a:	66 90                	xchg   %ax,%ax
f010453c:	66 90                	xchg   %ax,%ax
f010453e:	66 90                	xchg   %ax,%ax

f0104540 <strlen>:
// Primespipe runs 3x faster this way.
#define ASM 1

int
strlen(const char *s)
{
f0104540:	55                   	push   %ebp
f0104541:	89 e5                	mov    %esp,%ebp
f0104543:	8b 55 08             	mov    0x8(%ebp),%edx
	int n;

	for (n = 0; *s != '\0'; s++)
f0104546:	b8 00 00 00 00       	mov    $0x0,%eax
f010454b:	eb 03                	jmp    f0104550 <strlen+0x10>
		n++;
f010454d:	83 c0 01             	add    $0x1,%eax
int
strlen(const char *s)
{
	int n;

	for (n = 0; *s != '\0'; s++)
f0104550:	80 3c 02 00          	cmpb   $0x0,(%edx,%eax,1)
f0104554:	75 f7                	jne    f010454d <strlen+0xd>
		n++;
	return n;
}
f0104556:	5d                   	pop    %ebp
f0104557:	c3                   	ret    

f0104558 <strnlen>:

int
strnlen(const char *s, size_t size)
{
f0104558:	55                   	push   %ebp
f0104559:	89 e5                	mov    %esp,%ebp
f010455b:	8b 4d 08             	mov    0x8(%ebp),%ecx
f010455e:	8b 55 0c             	mov    0xc(%ebp),%edx
	int n;

	for (n = 0; size > 0 && *s != '\0'; s++, size--)
f0104561:	b8 00 00 00 00       	mov    $0x0,%eax
f0104566:	eb 03                	jmp    f010456b <strnlen+0x13>
		n++;
f0104568:	83 c0 01             	add    $0x1,%eax
int
strnlen(const char *s, size_t size)
{
	int n;

	for (n = 0; size > 0 && *s != '\0'; s++, size--)
f010456b:	39 d0                	cmp    %edx,%eax
f010456d:	74 06                	je     f0104575 <strnlen+0x1d>
f010456f:	80 3c 01 00          	cmpb   $0x0,(%ecx,%eax,1)
f0104573:	75 f3                	jne    f0104568 <strnlen+0x10>
		n++;
	return n;
}
f0104575:	5d                   	pop    %ebp
f0104576:	c3                   	ret    

f0104577 <strcpy>:

char *
strcpy(char *dst, const char *src)
{
f0104577:	55                   	push   %ebp
f0104578:	89 e5                	mov    %esp,%ebp
f010457a:	53                   	push   %ebx
f010457b:	8b 45 08             	mov    0x8(%ebp),%eax
f010457e:	8b 4d 0c             	mov    0xc(%ebp),%ecx
	char *ret;

	ret = dst;
	while ((*dst++ = *src++) != '\0')
f0104581:	89 c2                	mov    %eax,%edx
f0104583:	83 c2 01             	add    $0x1,%edx
f0104586:	83 c1 01             	add    $0x1,%ecx
f0104589:	0f b6 59 ff          	movzbl -0x1(%ecx),%ebx
f010458d:	88 5a ff             	mov    %bl,-0x1(%edx)
f0104590:	84 db                	test   %bl,%bl
f0104592:	75 ef                	jne    f0104583 <strcpy+0xc>
		/* do nothing */;
	return ret;
}
f0104594:	5b                   	pop    %ebx
f0104595:	5d                   	pop    %ebp
f0104596:	c3                   	ret    

f0104597 <strcat>:

char *
strcat(char *dst, const char *src)
{
f0104597:	55                   	push   %ebp
f0104598:	89 e5                	mov    %esp,%ebp
f010459a:	53                   	push   %ebx
f010459b:	83 ec 08             	sub    $0x8,%esp
f010459e:	8b 5d 08             	mov    0x8(%ebp),%ebx
	int len = strlen(dst);
f01045a1:	89 1c 24             	mov    %ebx,(%esp)
f01045a4:	e8 97 ff ff ff       	call   f0104540 <strlen>
	strcpy(dst + len, src);
f01045a9:	8b 55 0c             	mov    0xc(%ebp),%edx
f01045ac:	89 54 24 04          	mov    %edx,0x4(%esp)
f01045b0:	01 d8                	add    %ebx,%eax
f01045b2:	89 04 24             	mov    %eax,(%esp)
f01045b5:	e8 bd ff ff ff       	call   f0104577 <strcpy>
	return dst;
}
f01045ba:	89 d8                	mov    %ebx,%eax
f01045bc:	83 c4 08             	add    $0x8,%esp
f01045bf:	5b                   	pop    %ebx
f01045c0:	5d                   	pop    %ebp
f01045c1:	c3                   	ret    

f01045c2 <strncpy>:

char *
strncpy(char *dst, const char *src, size_t size) {
f01045c2:	55                   	push   %ebp
f01045c3:	89 e5                	mov    %esp,%ebp
f01045c5:	56                   	push   %esi
f01045c6:	53                   	push   %ebx
f01045c7:	8b 75 08             	mov    0x8(%ebp),%esi
f01045ca:	8b 4d 0c             	mov    0xc(%ebp),%ecx
f01045cd:	89 f3                	mov    %esi,%ebx
f01045cf:	03 5d 10             	add    0x10(%ebp),%ebx
	size_t i;
	char *ret;

	ret = dst;
	for (i = 0; i < size; i++) {
f01045d2:	89 f2                	mov    %esi,%edx
f01045d4:	eb 0f                	jmp    f01045e5 <strncpy+0x23>
		*dst++ = *src;
f01045d6:	83 c2 01             	add    $0x1,%edx
f01045d9:	0f b6 01             	movzbl (%ecx),%eax
f01045dc:	88 42 ff             	mov    %al,-0x1(%edx)
		// If strlen(src) < size, null-pad 'dst' out to 'size' chars
		if (*src != '\0')
			src++;
f01045df:	80 39 01             	cmpb   $0x1,(%ecx)
f01045e2:	83 d9 ff             	sbb    $0xffffffff,%ecx
strncpy(char *dst, const char *src, size_t size) {
	size_t i;
	char *ret;

	ret = dst;
	for (i = 0; i < size; i++) {
f01045e5:	39 da                	cmp    %ebx,%edx
f01045e7:	75 ed                	jne    f01045d6 <strncpy+0x14>
		// If strlen(src) < size, null-pad 'dst' out to 'size' chars
		if (*src != '\0')
			src++;
	}
	return ret;
}
f01045e9:	89 f0                	mov    %esi,%eax
f01045eb:	5b                   	pop    %ebx
f01045ec:	5e                   	pop    %esi
f01045ed:	5d                   	pop    %ebp
f01045ee:	c3                   	ret    

f01045ef <strlcpy>:

size_t
strlcpy(char *dst, const char *src, size_t size)
{
f01045ef:	55                   	push   %ebp
f01045f0:	89 e5                	mov    %esp,%ebp
f01045f2:	56                   	push   %esi
f01045f3:	53                   	push   %ebx
f01045f4:	8b 75 08             	mov    0x8(%ebp),%esi
f01045f7:	8b 55 0c             	mov    0xc(%ebp),%edx
f01045fa:	8b 4d 10             	mov    0x10(%ebp),%ecx
f01045fd:	89 f0                	mov    %esi,%eax
f01045ff:	8d 5c 0e ff          	lea    -0x1(%esi,%ecx,1),%ebx
	char *dst_in;

	dst_in = dst;
	if (size > 0) {
f0104603:	85 c9                	test   %ecx,%ecx
f0104605:	75 0b                	jne    f0104612 <strlcpy+0x23>
f0104607:	eb 1d                	jmp    f0104626 <strlcpy+0x37>
		while (--size > 0 && *src != '\0')
			*dst++ = *src++;
f0104609:	83 c0 01             	add    $0x1,%eax
f010460c:	83 c2 01             	add    $0x1,%edx
f010460f:	88 48 ff             	mov    %cl,-0x1(%eax)
{
	char *dst_in;

	dst_in = dst;
	if (size > 0) {
		while (--size > 0 && *src != '\0')
f0104612:	39 d8                	cmp    %ebx,%eax
f0104614:	74 0b                	je     f0104621 <strlcpy+0x32>
f0104616:	0f b6 0a             	movzbl (%edx),%ecx
f0104619:	84 c9                	test   %cl,%cl
f010461b:	75 ec                	jne    f0104609 <strlcpy+0x1a>
f010461d:	89 c2                	mov    %eax,%edx
f010461f:	eb 02                	jmp    f0104623 <strlcpy+0x34>
f0104621:	89 c2                	mov    %eax,%edx
			*dst++ = *src++;
		*dst = '\0';
f0104623:	c6 02 00             	movb   $0x0,(%edx)
	}
	return dst - dst_in;
f0104626:	29 f0                	sub    %esi,%eax
}
f0104628:	5b                   	pop    %ebx
f0104629:	5e                   	pop    %esi
f010462a:	5d                   	pop    %ebp
f010462b:	c3                   	ret    

f010462c <strcmp>:

int
strcmp(const char *p, const char *q)
{
f010462c:	55                   	push   %ebp
f010462d:	89 e5                	mov    %esp,%ebp
f010462f:	8b 4d 08             	mov    0x8(%ebp),%ecx
f0104632:	8b 55 0c             	mov    0xc(%ebp),%edx
	while (*p && *p == *q)
f0104635:	eb 06                	jmp    f010463d <strcmp+0x11>
		p++, q++;
f0104637:	83 c1 01             	add    $0x1,%ecx
f010463a:	83 c2 01             	add    $0x1,%edx
}

int
strcmp(const char *p, const char *q)
{
	while (*p && *p == *q)
f010463d:	0f b6 01             	movzbl (%ecx),%eax
f0104640:	84 c0                	test   %al,%al
f0104642:	74 04                	je     f0104648 <strcmp+0x1c>
f0104644:	3a 02                	cmp    (%edx),%al
f0104646:	74 ef                	je     f0104637 <strcmp+0xb>
		p++, q++;
	return (int) ((unsigned char) *p - (unsigned char) *q);
f0104648:	0f b6 c0             	movzbl %al,%eax
f010464b:	0f b6 12             	movzbl (%edx),%edx
f010464e:	29 d0                	sub    %edx,%eax
}
f0104650:	5d                   	pop    %ebp
f0104651:	c3                   	ret    

f0104652 <strncmp>:

int
strncmp(const char *p, const char *q, size_t n)
{
f0104652:	55                   	push   %ebp
f0104653:	89 e5                	mov    %esp,%ebp
f0104655:	53                   	push   %ebx
f0104656:	8b 45 08             	mov    0x8(%ebp),%eax
f0104659:	8b 55 0c             	mov    0xc(%ebp),%edx
f010465c:	89 c3                	mov    %eax,%ebx
f010465e:	03 5d 10             	add    0x10(%ebp),%ebx
	while (n > 0 && *p && *p == *q)
f0104661:	eb 06                	jmp    f0104669 <strncmp+0x17>
		n--, p++, q++;
f0104663:	83 c0 01             	add    $0x1,%eax
f0104666:	83 c2 01             	add    $0x1,%edx
}

int
strncmp(const char *p, const char *q, size_t n)
{
	while (n > 0 && *p && *p == *q)
f0104669:	39 d8                	cmp    %ebx,%eax
f010466b:	74 15                	je     f0104682 <strncmp+0x30>
f010466d:	0f b6 08             	movzbl (%eax),%ecx
f0104670:	84 c9                	test   %cl,%cl
f0104672:	74 04                	je     f0104678 <strncmp+0x26>
f0104674:	3a 0a                	cmp    (%edx),%cl
f0104676:	74 eb                	je     f0104663 <strncmp+0x11>
		n--, p++, q++;
	if (n == 0)
		return 0;
	else
		return (int) ((unsigned char) *p - (unsigned char) *q);
f0104678:	0f b6 00             	movzbl (%eax),%eax
f010467b:	0f b6 12             	movzbl (%edx),%edx
f010467e:	29 d0                	sub    %edx,%eax
f0104680:	eb 05                	jmp    f0104687 <strncmp+0x35>
strncmp(const char *p, const char *q, size_t n)
{
	while (n > 0 && *p && *p == *q)
		n--, p++, q++;
	if (n == 0)
		return 0;
f0104682:	b8 00 00 00 00       	mov    $0x0,%eax
	else
		return (int) ((unsigned char) *p - (unsigned char) *q);
}
f0104687:	5b                   	pop    %ebx
f0104688:	5d                   	pop    %ebp
f0104689:	c3                   	ret    

f010468a <strchr>:

// Return a pointer to the first occurrence of 'c' in 's',
// or a null pointer if the string has no 'c'.
char *
strchr(const char *s, char c)
{
f010468a:	55                   	push   %ebp
f010468b:	89 e5                	mov    %esp,%ebp
f010468d:	8b 45 08             	mov    0x8(%ebp),%eax
f0104690:	0f b6 4d 0c          	movzbl 0xc(%ebp),%ecx
	for (; *s; s++)
f0104694:	eb 07                	jmp    f010469d <strchr+0x13>
		if (*s == c)
f0104696:	38 ca                	cmp    %cl,%dl
f0104698:	74 0f                	je     f01046a9 <strchr+0x1f>
// Return a pointer to the first occurrence of 'c' in 's',
// or a null pointer if the string has no 'c'.
char *
strchr(const char *s, char c)
{
	for (; *s; s++)
f010469a:	83 c0 01             	add    $0x1,%eax
f010469d:	0f b6 10             	movzbl (%eax),%edx
f01046a0:	84 d2                	test   %dl,%dl
f01046a2:	75 f2                	jne    f0104696 <strchr+0xc>
		if (*s == c)
			return (char *) s;
	return 0;
f01046a4:	b8 00 00 00 00       	mov    $0x0,%eax
}
f01046a9:	5d                   	pop    %ebp
f01046aa:	c3                   	ret    

f01046ab <strfind>:

// Return a pointer to the first occurrence of 'c' in 's',
// or a pointer to the string-ending null character if the string has no 'c'.
char *
strfind(const char *s, char c)
{
f01046ab:	55                   	push   %ebp
f01046ac:	89 e5                	mov    %esp,%ebp
f01046ae:	8b 45 08             	mov    0x8(%ebp),%eax
f01046b1:	0f b6 4d 0c          	movzbl 0xc(%ebp),%ecx
	for (; *s; s++)
f01046b5:	eb 07                	jmp    f01046be <strfind+0x13>
		if (*s == c)
f01046b7:	38 ca                	cmp    %cl,%dl
f01046b9:	74 0a                	je     f01046c5 <strfind+0x1a>
// Return a pointer to the first occurrence of 'c' in 's',
// or a pointer to the string-ending null character if the string has no 'c'.
char *
strfind(const char *s, char c)
{
	for (; *s; s++)
f01046bb:	83 c0 01             	add    $0x1,%eax
f01046be:	0f b6 10             	movzbl (%eax),%edx
f01046c1:	84 d2                	test   %dl,%dl
f01046c3:	75 f2                	jne    f01046b7 <strfind+0xc>
		if (*s == c)
			break;
	return (char *) s;
}
f01046c5:	5d                   	pop    %ebp
f01046c6:	c3                   	ret    

f01046c7 <memset>:

#if ASM
void *
memset(void *v, int c, size_t n)
{
f01046c7:	55                   	push   %ebp
f01046c8:	89 e5                	mov    %esp,%ebp
f01046ca:	57                   	push   %edi
f01046cb:	56                   	push   %esi
f01046cc:	53                   	push   %ebx
f01046cd:	8b 55 08             	mov    0x8(%ebp),%edx
f01046d0:	8b 4d 10             	mov    0x10(%ebp),%ecx
	char *p = v;

	if (n == 0)
f01046d3:	85 c9                	test   %ecx,%ecx
f01046d5:	74 37                	je     f010470e <memset+0x47>
		return v;
	if ((int)v%4 == 0 && n%4 == 0) {
f01046d7:	f6 c2 03             	test   $0x3,%dl
f01046da:	75 2a                	jne    f0104706 <memset+0x3f>
f01046dc:	f6 c1 03             	test   $0x3,%cl
f01046df:	75 25                	jne    f0104706 <memset+0x3f>
		c &= 0xFF;
f01046e1:	0f b6 7d 0c          	movzbl 0xc(%ebp),%edi
		c = (c<<24)|(c<<16)|(c<<8)|c;
f01046e5:	89 fb                	mov    %edi,%ebx
f01046e7:	c1 e3 08             	shl    $0x8,%ebx
f01046ea:	89 fe                	mov    %edi,%esi
f01046ec:	c1 e6 18             	shl    $0x18,%esi
f01046ef:	89 f8                	mov    %edi,%eax
f01046f1:	c1 e0 10             	shl    $0x10,%eax
f01046f4:	09 f0                	or     %esi,%eax
f01046f6:	09 c7                	or     %eax,%edi
		asm volatile("cld; rep stosl\n"
			: "=D" (p), "=c" (n)
			: "D" (p), "a" (c), "c" (n/4)
f01046f8:	c1 e9 02             	shr    $0x2,%ecx

	if (n == 0)
		return v;
	if ((int)v%4 == 0 && n%4 == 0) {
		c &= 0xFF;
		c = (c<<24)|(c<<16)|(c<<8)|c;
f01046fb:	89 f8                	mov    %edi,%eax
f01046fd:	09 d8                	or     %ebx,%eax
		asm volatile("cld; rep stosl\n"
f01046ff:	89 d7                	mov    %edx,%edi
f0104701:	fc                   	cld    
f0104702:	f3 ab                	rep stos %eax,%es:(%edi)
f0104704:	eb 08                	jmp    f010470e <memset+0x47>
			: "=D" (p), "=c" (n)
			: "D" (p), "a" (c), "c" (n/4)
			: "cc", "memory");
	} else
		asm volatile("cld; rep stosb\n"
f0104706:	89 d7                	mov    %edx,%edi
f0104708:	8b 45 0c             	mov    0xc(%ebp),%eax
f010470b:	fc                   	cld    
f010470c:	f3 aa                	rep stos %al,%es:(%edi)
			: "=D" (p), "=c" (n)
			: "0" (p), "a" (c), "1" (n)
			: "cc", "memory");
	return v;
}
f010470e:	89 d0                	mov    %edx,%eax
f0104710:	5b                   	pop    %ebx
f0104711:	5e                   	pop    %esi
f0104712:	5f                   	pop    %edi
f0104713:	5d                   	pop    %ebp
f0104714:	c3                   	ret    

f0104715 <memmove>:

void *
memmove(void *dst, const void *src, size_t n)
{
f0104715:	55                   	push   %ebp
f0104716:	89 e5                	mov    %esp,%ebp
f0104718:	57                   	push   %edi
f0104719:	56                   	push   %esi
f010471a:	8b 45 08             	mov    0x8(%ebp),%eax
f010471d:	8b 75 0c             	mov    0xc(%ebp),%esi
f0104720:	8b 4d 10             	mov    0x10(%ebp),%ecx
	const char *s;
	char *d;

	s = src;
	d = dst;
	if (s < d && s + n > d) {
f0104723:	39 c6                	cmp    %eax,%esi
f0104725:	73 35                	jae    f010475c <memmove+0x47>
f0104727:	8d 14 0e             	lea    (%esi,%ecx,1),%edx
f010472a:	39 d0                	cmp    %edx,%eax
f010472c:	73 2e                	jae    f010475c <memmove+0x47>
		s += n;
		d += n;
f010472e:	8d 3c 08             	lea    (%eax,%ecx,1),%edi
f0104731:	89 d6                	mov    %edx,%esi
f0104733:	09 fe                	or     %edi,%esi
		if ((int)s%4 == 0 && (int)d%4 == 0 && n%4 == 0)
f0104735:	f7 c6 03 00 00 00    	test   $0x3,%esi
f010473b:	75 13                	jne    f0104750 <memmove+0x3b>
f010473d:	f6 c1 03             	test   $0x3,%cl
f0104740:	75 0e                	jne    f0104750 <memmove+0x3b>
			asm volatile("std; rep movsl\n"
				:: "D" (d-4), "S" (s-4), "c" (n/4) : "cc", "memory");
f0104742:	83 ef 04             	sub    $0x4,%edi
f0104745:	8d 72 fc             	lea    -0x4(%edx),%esi
f0104748:	c1 e9 02             	shr    $0x2,%ecx
	d = dst;
	if (s < d && s + n > d) {
		s += n;
		d += n;
		if ((int)s%4 == 0 && (int)d%4 == 0 && n%4 == 0)
			asm volatile("std; rep movsl\n"
f010474b:	fd                   	std    
f010474c:	f3 a5                	rep movsl %ds:(%esi),%es:(%edi)
f010474e:	eb 09                	jmp    f0104759 <memmove+0x44>
				:: "D" (d-4), "S" (s-4), "c" (n/4) : "cc", "memory");
		else
			asm volatile("std; rep movsb\n"
				:: "D" (d-1), "S" (s-1), "c" (n) : "cc", "memory");
f0104750:	83 ef 01             	sub    $0x1,%edi
f0104753:	8d 72 ff             	lea    -0x1(%edx),%esi
		d += n;
		if ((int)s%4 == 0 && (int)d%4 == 0 && n%4 == 0)
			asm volatile("std; rep movsl\n"
				:: "D" (d-4), "S" (s-4), "c" (n/4) : "cc", "memory");
		else
			asm volatile("std; rep movsb\n"
f0104756:	fd                   	std    
f0104757:	f3 a4                	rep movsb %ds:(%esi),%es:(%edi)
				:: "D" (d-1), "S" (s-1), "c" (n) : "cc", "memory");
		// Some versions of GCC rely on DF being clear
		asm volatile("cld" ::: "cc");
f0104759:	fc                   	cld    
f010475a:	eb 1d                	jmp    f0104779 <memmove+0x64>
f010475c:	89 f2                	mov    %esi,%edx
f010475e:	09 c2                	or     %eax,%edx
	} else {
		if ((int)s%4 == 0 && (int)d%4 == 0 && n%4 == 0)
f0104760:	f6 c2 03             	test   $0x3,%dl
f0104763:	75 0f                	jne    f0104774 <memmove+0x5f>
f0104765:	f6 c1 03             	test   $0x3,%cl
f0104768:	75 0a                	jne    f0104774 <memmove+0x5f>
			asm volatile("cld; rep movsl\n"
				:: "D" (d), "S" (s), "c" (n/4) : "cc", "memory");
f010476a:	c1 e9 02             	shr    $0x2,%ecx
				:: "D" (d-1), "S" (s-1), "c" (n) : "cc", "memory");
		// Some versions of GCC rely on DF being clear
		asm volatile("cld" ::: "cc");
	} else {
		if ((int)s%4 == 0 && (int)d%4 == 0 && n%4 == 0)
			asm volatile("cld; rep movsl\n"
f010476d:	89 c7                	mov    %eax,%edi
f010476f:	fc                   	cld    
f0104770:	f3 a5                	rep movsl %ds:(%esi),%es:(%edi)
f0104772:	eb 05                	jmp    f0104779 <memmove+0x64>
				:: "D" (d), "S" (s), "c" (n/4) : "cc", "memory");
		else
			asm volatile("cld; rep movsb\n"
f0104774:	89 c7                	mov    %eax,%edi
f0104776:	fc                   	cld    
f0104777:	f3 a4                	rep movsb %ds:(%esi),%es:(%edi)
				:: "D" (d), "S" (s), "c" (n) : "cc", "memory");
	}
	return dst;
}
f0104779:	5e                   	pop    %esi
f010477a:	5f                   	pop    %edi
f010477b:	5d                   	pop    %ebp
f010477c:	c3                   	ret    

f010477d <memcpy>:
}
#endif

void *
memcpy(void *dst, const void *src, size_t n)
{
f010477d:	55                   	push   %ebp
f010477e:	89 e5                	mov    %esp,%ebp
f0104780:	83 ec 0c             	sub    $0xc,%esp
	return memmove(dst, src, n);
f0104783:	8b 45 10             	mov    0x10(%ebp),%eax
f0104786:	89 44 24 08          	mov    %eax,0x8(%esp)
f010478a:	8b 45 0c             	mov    0xc(%ebp),%eax
f010478d:	89 44 24 04          	mov    %eax,0x4(%esp)
f0104791:	8b 45 08             	mov    0x8(%ebp),%eax
f0104794:	89 04 24             	mov    %eax,(%esp)
f0104797:	e8 79 ff ff ff       	call   f0104715 <memmove>
}
f010479c:	c9                   	leave  
f010479d:	c3                   	ret    

f010479e <memcmp>:

int
memcmp(const void *v1, const void *v2, size_t n)
{
f010479e:	55                   	push   %ebp
f010479f:	89 e5                	mov    %esp,%ebp
f01047a1:	56                   	push   %esi
f01047a2:	53                   	push   %ebx
f01047a3:	8b 55 08             	mov    0x8(%ebp),%edx
f01047a6:	8b 4d 0c             	mov    0xc(%ebp),%ecx
f01047a9:	89 d6                	mov    %edx,%esi
f01047ab:	03 75 10             	add    0x10(%ebp),%esi
	const uint8_t *s1 = (const uint8_t *) v1;
	const uint8_t *s2 = (const uint8_t *) v2;

	while (n-- > 0) {
f01047ae:	eb 1a                	jmp    f01047ca <memcmp+0x2c>
		if (*s1 != *s2)
f01047b0:	0f b6 02             	movzbl (%edx),%eax
f01047b3:	0f b6 19             	movzbl (%ecx),%ebx
f01047b6:	38 d8                	cmp    %bl,%al
f01047b8:	74 0a                	je     f01047c4 <memcmp+0x26>
			return (int) *s1 - (int) *s2;
f01047ba:	0f b6 c0             	movzbl %al,%eax
f01047bd:	0f b6 db             	movzbl %bl,%ebx
f01047c0:	29 d8                	sub    %ebx,%eax
f01047c2:	eb 0f                	jmp    f01047d3 <memcmp+0x35>
		s1++, s2++;
f01047c4:	83 c2 01             	add    $0x1,%edx
f01047c7:	83 c1 01             	add    $0x1,%ecx
memcmp(const void *v1, const void *v2, size_t n)
{
	const uint8_t *s1 = (const uint8_t *) v1;
	const uint8_t *s2 = (const uint8_t *) v2;

	while (n-- > 0) {
f01047ca:	39 f2                	cmp    %esi,%edx
f01047cc:	75 e2                	jne    f01047b0 <memcmp+0x12>
		if (*s1 != *s2)
			return (int) *s1 - (int) *s2;
		s1++, s2++;
	}

	return 0;
f01047ce:	b8 00 00 00 00       	mov    $0x0,%eax
}
f01047d3:	5b                   	pop    %ebx
f01047d4:	5e                   	pop    %esi
f01047d5:	5d                   	pop    %ebp
f01047d6:	c3                   	ret    

f01047d7 <memfind>:

void *
memfind(const void *s, int c, size_t n)
{
f01047d7:	55                   	push   %ebp
f01047d8:	89 e5                	mov    %esp,%ebp
f01047da:	8b 45 08             	mov    0x8(%ebp),%eax
f01047dd:	8b 4d 0c             	mov    0xc(%ebp),%ecx
	const void *ends = (const char *) s + n;
f01047e0:	89 c2                	mov    %eax,%edx
f01047e2:	03 55 10             	add    0x10(%ebp),%edx
	for (; s < ends; s++)
f01047e5:	eb 07                	jmp    f01047ee <memfind+0x17>
		if (*(const unsigned char *) s == (unsigned char) c)
f01047e7:	38 08                	cmp    %cl,(%eax)
f01047e9:	74 07                	je     f01047f2 <memfind+0x1b>

void *
memfind(const void *s, int c, size_t n)
{
	const void *ends = (const char *) s + n;
	for (; s < ends; s++)
f01047eb:	83 c0 01             	add    $0x1,%eax
f01047ee:	39 d0                	cmp    %edx,%eax
f01047f0:	72 f5                	jb     f01047e7 <memfind+0x10>
		if (*(const unsigned char *) s == (unsigned char) c)
			break;
	return (void *) s;
}
f01047f2:	5d                   	pop    %ebp
f01047f3:	c3                   	ret    

f01047f4 <strtol>:

long
strtol(const char *s, char **endptr, int base)
{
f01047f4:	55                   	push   %ebp
f01047f5:	89 e5                	mov    %esp,%ebp
f01047f7:	57                   	push   %edi
f01047f8:	56                   	push   %esi
f01047f9:	53                   	push   %ebx
f01047fa:	8b 55 08             	mov    0x8(%ebp),%edx
f01047fd:	8b 45 10             	mov    0x10(%ebp),%eax
	int neg = 0;
	long val = 0;

	// gobble initial whitespace
	while (*s == ' ' || *s == '\t')
f0104800:	eb 03                	jmp    f0104805 <strtol+0x11>
		s++;
f0104802:	83 c2 01             	add    $0x1,%edx
{
	int neg = 0;
	long val = 0;

	// gobble initial whitespace
	while (*s == ' ' || *s == '\t')
f0104805:	0f b6 0a             	movzbl (%edx),%ecx
f0104808:	80 f9 09             	cmp    $0x9,%cl
f010480b:	74 f5                	je     f0104802 <strtol+0xe>
f010480d:	80 f9 20             	cmp    $0x20,%cl
f0104810:	74 f0                	je     f0104802 <strtol+0xe>
		s++;

	// plus/minus sign
	if (*s == '+')
f0104812:	80 f9 2b             	cmp    $0x2b,%cl
f0104815:	75 0a                	jne    f0104821 <strtol+0x2d>
		s++;
f0104817:	83 c2 01             	add    $0x1,%edx
}

long
strtol(const char *s, char **endptr, int base)
{
	int neg = 0;
f010481a:	bf 00 00 00 00       	mov    $0x0,%edi
f010481f:	eb 11                	jmp    f0104832 <strtol+0x3e>
f0104821:	bf 00 00 00 00       	mov    $0x0,%edi
		s++;

	// plus/minus sign
	if (*s == '+')
		s++;
	else if (*s == '-')
f0104826:	80 f9 2d             	cmp    $0x2d,%cl
f0104829:	75 07                	jne    f0104832 <strtol+0x3e>
		s++, neg = 1;
f010482b:	8d 52 01             	lea    0x1(%edx),%edx
f010482e:	66 bf 01 00          	mov    $0x1,%di

	// hex or octal base prefix
	if ((base == 0 || base == 16) && (s[0] == '0' && s[1] == 'x'))
f0104832:	a9 ef ff ff ff       	test   $0xffffffef,%eax
f0104837:	75 15                	jne    f010484e <strtol+0x5a>
f0104839:	80 3a 30             	cmpb   $0x30,(%edx)
f010483c:	75 10                	jne    f010484e <strtol+0x5a>
f010483e:	80 7a 01 78          	cmpb   $0x78,0x1(%edx)
f0104842:	75 0a                	jne    f010484e <strtol+0x5a>
		s += 2, base = 16;
f0104844:	83 c2 02             	add    $0x2,%edx
f0104847:	b8 10 00 00 00       	mov    $0x10,%eax
f010484c:	eb 10                	jmp    f010485e <strtol+0x6a>
	else if (base == 0 && s[0] == '0')
f010484e:	85 c0                	test   %eax,%eax
f0104850:	75 0c                	jne    f010485e <strtol+0x6a>
		s++, base = 8;
	else if (base == 0)
		base = 10;
f0104852:	b0 0a                	mov    $0xa,%al
		s++, neg = 1;

	// hex or octal base prefix
	if ((base == 0 || base == 16) && (s[0] == '0' && s[1] == 'x'))
		s += 2, base = 16;
	else if (base == 0 && s[0] == '0')
f0104854:	80 3a 30             	cmpb   $0x30,(%edx)
f0104857:	75 05                	jne    f010485e <strtol+0x6a>
		s++, base = 8;
f0104859:	83 c2 01             	add    $0x1,%edx
f010485c:	b0 08                	mov    $0x8,%al
	else if (base == 0)
		base = 10;
f010485e:	bb 00 00 00 00       	mov    $0x0,%ebx
f0104863:	89 45 10             	mov    %eax,0x10(%ebp)

	// digits
	while (1) {
		int dig;

		if (*s >= '0' && *s <= '9')
f0104866:	0f b6 0a             	movzbl (%edx),%ecx
f0104869:	8d 71 d0             	lea    -0x30(%ecx),%esi
f010486c:	89 f0                	mov    %esi,%eax
f010486e:	3c 09                	cmp    $0x9,%al
f0104870:	77 08                	ja     f010487a <strtol+0x86>
			dig = *s - '0';
f0104872:	0f be c9             	movsbl %cl,%ecx
f0104875:	83 e9 30             	sub    $0x30,%ecx
f0104878:	eb 20                	jmp    f010489a <strtol+0xa6>
		else if (*s >= 'a' && *s <= 'z')
f010487a:	8d 71 9f             	lea    -0x61(%ecx),%esi
f010487d:	89 f0                	mov    %esi,%eax
f010487f:	3c 19                	cmp    $0x19,%al
f0104881:	77 08                	ja     f010488b <strtol+0x97>
			dig = *s - 'a' + 10;
f0104883:	0f be c9             	movsbl %cl,%ecx
f0104886:	83 e9 57             	sub    $0x57,%ecx
f0104889:	eb 0f                	jmp    f010489a <strtol+0xa6>
		else if (*s >= 'A' && *s <= 'Z')
f010488b:	8d 71 bf             	lea    -0x41(%ecx),%esi
f010488e:	89 f0                	mov    %esi,%eax
f0104890:	3c 19                	cmp    $0x19,%al
f0104892:	77 16                	ja     f01048aa <strtol+0xb6>
			dig = *s - 'A' + 10;
f0104894:	0f be c9             	movsbl %cl,%ecx
f0104897:	83 e9 37             	sub    $0x37,%ecx
		else
			break;
		if (dig >= base)
f010489a:	3b 4d 10             	cmp    0x10(%ebp),%ecx
f010489d:	7d 0f                	jge    f01048ae <strtol+0xba>
			break;
		s++, val = (val * base) + dig;
f010489f:	83 c2 01             	add    $0x1,%edx
f01048a2:	0f af 5d 10          	imul   0x10(%ebp),%ebx
f01048a6:	01 cb                	add    %ecx,%ebx
		// we don't properly detect overflow!
	}
f01048a8:	eb bc                	jmp    f0104866 <strtol+0x72>
f01048aa:	89 d8                	mov    %ebx,%eax
f01048ac:	eb 02                	jmp    f01048b0 <strtol+0xbc>
f01048ae:	89 d8                	mov    %ebx,%eax

	if (endptr)
f01048b0:	83 7d 0c 00          	cmpl   $0x0,0xc(%ebp)
f01048b4:	74 05                	je     f01048bb <strtol+0xc7>
		*endptr = (char *) s;
f01048b6:	8b 75 0c             	mov    0xc(%ebp),%esi
f01048b9:	89 16                	mov    %edx,(%esi)
	return (neg ? -val : val);
f01048bb:	f7 d8                	neg    %eax
f01048bd:	85 ff                	test   %edi,%edi
f01048bf:	0f 44 c3             	cmove  %ebx,%eax
}
f01048c2:	5b                   	pop    %ebx
f01048c3:	5e                   	pop    %esi
f01048c4:	5f                   	pop    %edi
f01048c5:	5d                   	pop    %ebp
f01048c6:	c3                   	ret    
f01048c7:	66 90                	xchg   %ax,%ax
f01048c9:	66 90                	xchg   %ax,%ax
f01048cb:	66 90                	xchg   %ax,%ax
f01048cd:	66 90                	xchg   %ax,%ax
f01048cf:	90                   	nop

f01048d0 <__udivdi3>:
f01048d0:	55                   	push   %ebp
f01048d1:	57                   	push   %edi
f01048d2:	56                   	push   %esi
f01048d3:	53                   	push   %ebx
f01048d4:	83 ec 1c             	sub    $0x1c,%esp
f01048d7:	8b 74 24 3c          	mov    0x3c(%esp),%esi
f01048db:	8b 5c 24 30          	mov    0x30(%esp),%ebx
f01048df:	8b 4c 24 34          	mov    0x34(%esp),%ecx
f01048e3:	8b 7c 24 38          	mov    0x38(%esp),%edi
f01048e7:	85 f6                	test   %esi,%esi
f01048e9:	89 5c 24 08          	mov    %ebx,0x8(%esp)
f01048ed:	89 ca                	mov    %ecx,%edx
f01048ef:	89 f8                	mov    %edi,%eax
f01048f1:	75 3d                	jne    f0104930 <__udivdi3+0x60>
f01048f3:	39 cf                	cmp    %ecx,%edi
f01048f5:	0f 87 c5 00 00 00    	ja     f01049c0 <__udivdi3+0xf0>
f01048fb:	85 ff                	test   %edi,%edi
f01048fd:	89 fd                	mov    %edi,%ebp
f01048ff:	75 0b                	jne    f010490c <__udivdi3+0x3c>
f0104901:	b8 01 00 00 00       	mov    $0x1,%eax
f0104906:	31 d2                	xor    %edx,%edx
f0104908:	f7 f7                	div    %edi
f010490a:	89 c5                	mov    %eax,%ebp
f010490c:	89 c8                	mov    %ecx,%eax
f010490e:	31 d2                	xor    %edx,%edx
f0104910:	f7 f5                	div    %ebp
f0104912:	89 c1                	mov    %eax,%ecx
f0104914:	89 d8                	mov    %ebx,%eax
f0104916:	89 cf                	mov    %ecx,%edi
f0104918:	f7 f5                	div    %ebp
f010491a:	89 c3                	mov    %eax,%ebx
f010491c:	89 d8                	mov    %ebx,%eax
f010491e:	89 fa                	mov    %edi,%edx
f0104920:	83 c4 1c             	add    $0x1c,%esp
f0104923:	5b                   	pop    %ebx
f0104924:	5e                   	pop    %esi
f0104925:	5f                   	pop    %edi
f0104926:	5d                   	pop    %ebp
f0104927:	c3                   	ret    
f0104928:	90                   	nop
f0104929:	8d b4 26 00 00 00 00 	lea    0x0(%esi,%eiz,1),%esi
f0104930:	39 ce                	cmp    %ecx,%esi
f0104932:	77 74                	ja     f01049a8 <__udivdi3+0xd8>
f0104934:	0f bd fe             	bsr    %esi,%edi
f0104937:	83 f7 1f             	xor    $0x1f,%edi
f010493a:	0f 84 98 00 00 00    	je     f01049d8 <__udivdi3+0x108>
f0104940:	bb 20 00 00 00       	mov    $0x20,%ebx
f0104945:	89 f9                	mov    %edi,%ecx
f0104947:	89 c5                	mov    %eax,%ebp
f0104949:	29 fb                	sub    %edi,%ebx
f010494b:	d3 e6                	shl    %cl,%esi
f010494d:	89 d9                	mov    %ebx,%ecx
f010494f:	d3 ed                	shr    %cl,%ebp
f0104951:	89 f9                	mov    %edi,%ecx
f0104953:	d3 e0                	shl    %cl,%eax
f0104955:	09 ee                	or     %ebp,%esi
f0104957:	89 d9                	mov    %ebx,%ecx
f0104959:	89 44 24 0c          	mov    %eax,0xc(%esp)
f010495d:	89 d5                	mov    %edx,%ebp
f010495f:	8b 44 24 08          	mov    0x8(%esp),%eax
f0104963:	d3 ed                	shr    %cl,%ebp
f0104965:	89 f9                	mov    %edi,%ecx
f0104967:	d3 e2                	shl    %cl,%edx
f0104969:	89 d9                	mov    %ebx,%ecx
f010496b:	d3 e8                	shr    %cl,%eax
f010496d:	09 c2                	or     %eax,%edx
f010496f:	89 d0                	mov    %edx,%eax
f0104971:	89 ea                	mov    %ebp,%edx
f0104973:	f7 f6                	div    %esi
f0104975:	89 d5                	mov    %edx,%ebp
f0104977:	89 c3                	mov    %eax,%ebx
f0104979:	f7 64 24 0c          	mull   0xc(%esp)
f010497d:	39 d5                	cmp    %edx,%ebp
f010497f:	72 10                	jb     f0104991 <__udivdi3+0xc1>
f0104981:	8b 74 24 08          	mov    0x8(%esp),%esi
f0104985:	89 f9                	mov    %edi,%ecx
f0104987:	d3 e6                	shl    %cl,%esi
f0104989:	39 c6                	cmp    %eax,%esi
f010498b:	73 07                	jae    f0104994 <__udivdi3+0xc4>
f010498d:	39 d5                	cmp    %edx,%ebp
f010498f:	75 03                	jne    f0104994 <__udivdi3+0xc4>
f0104991:	83 eb 01             	sub    $0x1,%ebx
f0104994:	31 ff                	xor    %edi,%edi
f0104996:	89 d8                	mov    %ebx,%eax
f0104998:	89 fa                	mov    %edi,%edx
f010499a:	83 c4 1c             	add    $0x1c,%esp
f010499d:	5b                   	pop    %ebx
f010499e:	5e                   	pop    %esi
f010499f:	5f                   	pop    %edi
f01049a0:	5d                   	pop    %ebp
f01049a1:	c3                   	ret    
f01049a2:	8d b6 00 00 00 00    	lea    0x0(%esi),%esi
f01049a8:	31 ff                	xor    %edi,%edi
f01049aa:	31 db                	xor    %ebx,%ebx
f01049ac:	89 d8                	mov    %ebx,%eax
f01049ae:	89 fa                	mov    %edi,%edx
f01049b0:	83 c4 1c             	add    $0x1c,%esp
f01049b3:	5b                   	pop    %ebx
f01049b4:	5e                   	pop    %esi
f01049b5:	5f                   	pop    %edi
f01049b6:	5d                   	pop    %ebp
f01049b7:	c3                   	ret    
f01049b8:	90                   	nop
f01049b9:	8d b4 26 00 00 00 00 	lea    0x0(%esi,%eiz,1),%esi
f01049c0:	89 d8                	mov    %ebx,%eax
f01049c2:	f7 f7                	div    %edi
f01049c4:	31 ff                	xor    %edi,%edi
f01049c6:	89 c3                	mov    %eax,%ebx
f01049c8:	89 d8                	mov    %ebx,%eax
f01049ca:	89 fa                	mov    %edi,%edx
f01049cc:	83 c4 1c             	add    $0x1c,%esp
f01049cf:	5b                   	pop    %ebx
f01049d0:	5e                   	pop    %esi
f01049d1:	5f                   	pop    %edi
f01049d2:	5d                   	pop    %ebp
f01049d3:	c3                   	ret    
f01049d4:	8d 74 26 00          	lea    0x0(%esi,%eiz,1),%esi
f01049d8:	39 ce                	cmp    %ecx,%esi
f01049da:	72 0c                	jb     f01049e8 <__udivdi3+0x118>
f01049dc:	31 db                	xor    %ebx,%ebx
f01049de:	3b 44 24 08          	cmp    0x8(%esp),%eax
f01049e2:	0f 87 34 ff ff ff    	ja     f010491c <__udivdi3+0x4c>
f01049e8:	bb 01 00 00 00       	mov    $0x1,%ebx
f01049ed:	e9 2a ff ff ff       	jmp    f010491c <__udivdi3+0x4c>
f01049f2:	66 90                	xchg   %ax,%ax
f01049f4:	66 90                	xchg   %ax,%ax
f01049f6:	66 90                	xchg   %ax,%ax
f01049f8:	66 90                	xchg   %ax,%ax
f01049fa:	66 90                	xchg   %ax,%ax
f01049fc:	66 90                	xchg   %ax,%ax
f01049fe:	66 90                	xchg   %ax,%ax

f0104a00 <__umoddi3>:
f0104a00:	55                   	push   %ebp
f0104a01:	57                   	push   %edi
f0104a02:	56                   	push   %esi
f0104a03:	53                   	push   %ebx
f0104a04:	83 ec 1c             	sub    $0x1c,%esp
f0104a07:	8b 54 24 3c          	mov    0x3c(%esp),%edx
f0104a0b:	8b 4c 24 30          	mov    0x30(%esp),%ecx
f0104a0f:	8b 74 24 34          	mov    0x34(%esp),%esi
f0104a13:	8b 7c 24 38          	mov    0x38(%esp),%edi
f0104a17:	85 d2                	test   %edx,%edx
f0104a19:	89 4c 24 0c          	mov    %ecx,0xc(%esp)
f0104a1d:	89 4c 24 08          	mov    %ecx,0x8(%esp)
f0104a21:	89 f3                	mov    %esi,%ebx
f0104a23:	89 3c 24             	mov    %edi,(%esp)
f0104a26:	89 74 24 04          	mov    %esi,0x4(%esp)
f0104a2a:	75 1c                	jne    f0104a48 <__umoddi3+0x48>
f0104a2c:	39 f7                	cmp    %esi,%edi
f0104a2e:	76 50                	jbe    f0104a80 <__umoddi3+0x80>
f0104a30:	89 c8                	mov    %ecx,%eax
f0104a32:	89 f2                	mov    %esi,%edx
f0104a34:	f7 f7                	div    %edi
f0104a36:	89 d0                	mov    %edx,%eax
f0104a38:	31 d2                	xor    %edx,%edx
f0104a3a:	83 c4 1c             	add    $0x1c,%esp
f0104a3d:	5b                   	pop    %ebx
f0104a3e:	5e                   	pop    %esi
f0104a3f:	5f                   	pop    %edi
f0104a40:	5d                   	pop    %ebp
f0104a41:	c3                   	ret    
f0104a42:	8d b6 00 00 00 00    	lea    0x0(%esi),%esi
f0104a48:	39 f2                	cmp    %esi,%edx
f0104a4a:	89 d0                	mov    %edx,%eax
f0104a4c:	77 52                	ja     f0104aa0 <__umoddi3+0xa0>
f0104a4e:	0f bd ea             	bsr    %edx,%ebp
f0104a51:	83 f5 1f             	xor    $0x1f,%ebp
f0104a54:	75 5a                	jne    f0104ab0 <__umoddi3+0xb0>
f0104a56:	3b 54 24 04          	cmp    0x4(%esp),%edx
f0104a5a:	0f 82 e0 00 00 00    	jb     f0104b40 <__umoddi3+0x140>
f0104a60:	39 0c 24             	cmp    %ecx,(%esp)
f0104a63:	0f 86 d7 00 00 00    	jbe    f0104b40 <__umoddi3+0x140>
f0104a69:	8b 44 24 08          	mov    0x8(%esp),%eax
f0104a6d:	8b 54 24 04          	mov    0x4(%esp),%edx
f0104a71:	83 c4 1c             	add    $0x1c,%esp
f0104a74:	5b                   	pop    %ebx
f0104a75:	5e                   	pop    %esi
f0104a76:	5f                   	pop    %edi
f0104a77:	5d                   	pop    %ebp
f0104a78:	c3                   	ret    
f0104a79:	8d b4 26 00 00 00 00 	lea    0x0(%esi,%eiz,1),%esi
f0104a80:	85 ff                	test   %edi,%edi
f0104a82:	89 fd                	mov    %edi,%ebp
f0104a84:	75 0b                	jne    f0104a91 <__umoddi3+0x91>
f0104a86:	b8 01 00 00 00       	mov    $0x1,%eax
f0104a8b:	31 d2                	xor    %edx,%edx
f0104a8d:	f7 f7                	div    %edi
f0104a8f:	89 c5                	mov    %eax,%ebp
f0104a91:	89 f0                	mov    %esi,%eax
f0104a93:	31 d2                	xor    %edx,%edx
f0104a95:	f7 f5                	div    %ebp
f0104a97:	89 c8                	mov    %ecx,%eax
f0104a99:	f7 f5                	div    %ebp
f0104a9b:	89 d0                	mov    %edx,%eax
f0104a9d:	eb 99                	jmp    f0104a38 <__umoddi3+0x38>
f0104a9f:	90                   	nop
f0104aa0:	89 c8                	mov    %ecx,%eax
f0104aa2:	89 f2                	mov    %esi,%edx
f0104aa4:	83 c4 1c             	add    $0x1c,%esp
f0104aa7:	5b                   	pop    %ebx
f0104aa8:	5e                   	pop    %esi
f0104aa9:	5f                   	pop    %edi
f0104aaa:	5d                   	pop    %ebp
f0104aab:	c3                   	ret    
f0104aac:	8d 74 26 00          	lea    0x0(%esi,%eiz,1),%esi
f0104ab0:	8b 34 24             	mov    (%esp),%esi
f0104ab3:	bf 20 00 00 00       	mov    $0x20,%edi
f0104ab8:	89 e9                	mov    %ebp,%ecx
f0104aba:	29 ef                	sub    %ebp,%edi
f0104abc:	d3 e0                	shl    %cl,%eax
f0104abe:	89 f9                	mov    %edi,%ecx
f0104ac0:	89 f2                	mov    %esi,%edx
f0104ac2:	d3 ea                	shr    %cl,%edx
f0104ac4:	89 e9                	mov    %ebp,%ecx
f0104ac6:	09 c2                	or     %eax,%edx
f0104ac8:	89 d8                	mov    %ebx,%eax
f0104aca:	89 14 24             	mov    %edx,(%esp)
f0104acd:	89 f2                	mov    %esi,%edx
f0104acf:	d3 e2                	shl    %cl,%edx
f0104ad1:	89 f9                	mov    %edi,%ecx
f0104ad3:	89 54 24 04          	mov    %edx,0x4(%esp)
f0104ad7:	8b 54 24 0c          	mov    0xc(%esp),%edx
f0104adb:	d3 e8                	shr    %cl,%eax
f0104add:	89 e9                	mov    %ebp,%ecx
f0104adf:	89 c6                	mov    %eax,%esi
f0104ae1:	d3 e3                	shl    %cl,%ebx
f0104ae3:	89 f9                	mov    %edi,%ecx
f0104ae5:	89 d0                	mov    %edx,%eax
f0104ae7:	d3 e8                	shr    %cl,%eax
f0104ae9:	89 e9                	mov    %ebp,%ecx
f0104aeb:	09 d8                	or     %ebx,%eax
f0104aed:	89 d3                	mov    %edx,%ebx
f0104aef:	89 f2                	mov    %esi,%edx
f0104af1:	f7 34 24             	divl   (%esp)
f0104af4:	89 d6                	mov    %edx,%esi
f0104af6:	d3 e3                	shl    %cl,%ebx
f0104af8:	f7 64 24 04          	mull   0x4(%esp)
f0104afc:	39 d6                	cmp    %edx,%esi
f0104afe:	89 5c 24 08          	mov    %ebx,0x8(%esp)
f0104b02:	89 d1                	mov    %edx,%ecx
f0104b04:	89 c3                	mov    %eax,%ebx
f0104b06:	72 08                	jb     f0104b10 <__umoddi3+0x110>
f0104b08:	75 11                	jne    f0104b1b <__umoddi3+0x11b>
f0104b0a:	39 44 24 08          	cmp    %eax,0x8(%esp)
f0104b0e:	73 0b                	jae    f0104b1b <__umoddi3+0x11b>
f0104b10:	2b 44 24 04          	sub    0x4(%esp),%eax
f0104b14:	1b 14 24             	sbb    (%esp),%edx
f0104b17:	89 d1                	mov    %edx,%ecx
f0104b19:	89 c3                	mov    %eax,%ebx
f0104b1b:	8b 54 24 08          	mov    0x8(%esp),%edx
f0104b1f:	29 da                	sub    %ebx,%edx
f0104b21:	19 ce                	sbb    %ecx,%esi
f0104b23:	89 f9                	mov    %edi,%ecx
f0104b25:	89 f0                	mov    %esi,%eax
f0104b27:	d3 e0                	shl    %cl,%eax
f0104b29:	89 e9                	mov    %ebp,%ecx
f0104b2b:	d3 ea                	shr    %cl,%edx
f0104b2d:	89 e9                	mov    %ebp,%ecx
f0104b2f:	d3 ee                	shr    %cl,%esi
f0104b31:	09 d0                	or     %edx,%eax
f0104b33:	89 f2                	mov    %esi,%edx
f0104b35:	83 c4 1c             	add    $0x1c,%esp
f0104b38:	5b                   	pop    %ebx
f0104b39:	5e                   	pop    %esi
f0104b3a:	5f                   	pop    %edi
f0104b3b:	5d                   	pop    %ebp
f0104b3c:	c3                   	ret    
f0104b3d:	8d 76 00             	lea    0x0(%esi),%esi
f0104b40:	29 f9                	sub    %edi,%ecx
f0104b42:	19 d6                	sbb    %edx,%esi
f0104b44:	89 74 24 04          	mov    %esi,0x4(%esp)
f0104b48:	89 4c 24 08          	mov    %ecx,0x8(%esp)
f0104b4c:	e9 18 ff ff ff       	jmp    f0104a69 <__umoddi3+0x69>
