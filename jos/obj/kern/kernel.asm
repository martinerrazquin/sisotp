
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
f0100061:	e8 71 45 00 00       	call   f01045d7 <memset>

	// Initialize the console.
	// Can't call cprintf until after we do this!
	cons_init();
f0100066:	e8 86 06 00 00       	call   f01006f1 <cons_init>

	cprintf("6828 decimal is %o octal!\n", 6828);
f010006b:	83 c4 08             	add    $0x8,%esp
f010006e:	68 ac 1a 00 00       	push   $0x1aac
f0100073:	68 80 4a 10 f0       	push   $0xf0104a80
f0100078:	e8 9b 35 00 00       	call   f0103618 <cprintf>

	// Lab 2 memory management initialization functions
	mem_init();
f010007d:	e8 55 2b 00 00       	call   f0102bd7 <mem_init>

	// Lab 3 user environment initialization functions
	env_init();
f0100082:	e8 8f 31 00 00       	call   f0103216 <env_init>
	trap_init();
f0100087:	e8 49 36 00 00       	call   f01036d5 <trap_init>

#if defined(TEST)
	// Don't touch -- used by grading script!
	ENV_CREATE(TEST, ENV_TYPE_USER);
f010008c:	83 c4 08             	add    $0x8,%esp
f010008f:	6a 00                	push   $0x0
f0100091:	68 56 b3 11 f0       	push   $0xf011b356
f0100096:	e8 a4 32 00 00       	call   f010333f <env_create>
#else
	// Touch all you want.
	ENV_CREATE(user_hello, ENV_TYPE_USER);
#endif // TEST*
	// We only have one user environment for now, so just run it.
	env_run(&envs[0]);
f010009b:	83 c4 04             	add    $0x4,%esp
f010009e:	ff 35 c8 52 18 f0    	pushl  0xf01852c8
f01000a4:	e8 66 34 00 00       	call   f010350f <env_run>

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
f01000ce:	68 bc 4a 10 f0       	push   $0xf0104abc
f01000d3:	e8 40 35 00 00       	call   f0103618 <cprintf>
	vcprintf(fmt, ap);
f01000d8:	83 c4 08             	add    $0x8,%esp
f01000db:	53                   	push   %ebx
f01000dc:	56                   	push   %esi
f01000dd:	e8 03 35 00 00       	call   f01035e5 <vcprintf>
	cprintf("\n>>>\n");
f01000e2:	c7 04 24 9b 4a 10 f0 	movl   $0xf0104a9b,(%esp)
f01000e9:	e8 2a 35 00 00       	call   f0103618 <cprintf>
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
f0100110:	68 a1 4a 10 f0       	push   $0xf0104aa1
f0100115:	e8 fe 34 00 00       	call   f0103618 <cprintf>
	vcprintf(fmt, ap);
f010011a:	83 c4 08             	add    $0x8,%esp
f010011d:	53                   	push   %ebx
f010011e:	ff 75 10             	pushl  0x10(%ebp)
f0100121:	e8 bf 34 00 00       	call   f01035e5 <vcprintf>
	cprintf("\n");
f0100126:	c7 04 24 ea 5a 10 f0 	movl   $0xf0105aea,(%esp)
f010012d:	e8 e6 34 00 00       	call   f0103618 <cprintf>
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
f010040c:	0f b6 80 40 4c 10 f0 	movzbl -0xfefb3c0(%eax),%eax
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
f0100447:	0f b6 90 40 4c 10 f0 	movzbl -0xfefb3c0(%eax),%edx
f010044e:	0b 15 80 50 18 f0    	or     0xf0185080,%edx
	shift ^= togglecode[data];
f0100454:	0f b6 88 40 4b 10 f0 	movzbl -0xfefb4c0(%eax),%ecx
f010045b:	31 ca                	xor    %ecx,%edx
f010045d:	89 15 80 50 18 f0    	mov    %edx,0xf0185080

	c = charcode[shift & (CTL | SHIFT)][data];
f0100463:	89 d1                	mov    %edx,%ecx
f0100465:	83 e1 03             	and    $0x3,%ecx
f0100468:	8b 0c 8d 20 4b 10 f0 	mov    -0xfefb4e0(,%ecx,4),%ecx
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
f01004a7:	c7 04 24 dc 4a 10 f0 	movl   $0xf0104adc,(%esp)
f01004ae:	e8 65 31 00 00       	call   f0103618 <cprintf>
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
f01005e7:	e8 39 40 00 00       	call   f0104625 <memmove>
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
f010070a:	c7 04 24 e8 4a 10 f0 	movl   $0xf0104ae8,(%esp)
f0100711:	e8 02 2f 00 00       	call   f0103618 <cprintf>
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
f0100756:	c7 44 24 08 40 4d 10 	movl   $0xf0104d40,0x8(%esp)
f010075d:	f0 
f010075e:	c7 44 24 04 5e 4d 10 	movl   $0xf0104d5e,0x4(%esp)
f0100765:	f0 
f0100766:	c7 04 24 63 4d 10 f0 	movl   $0xf0104d63,(%esp)
f010076d:	e8 a6 2e 00 00       	call   f0103618 <cprintf>
f0100772:	c7 44 24 08 00 4e 10 	movl   $0xf0104e00,0x8(%esp)
f0100779:	f0 
f010077a:	c7 44 24 04 6c 4d 10 	movl   $0xf0104d6c,0x4(%esp)
f0100781:	f0 
f0100782:	c7 04 24 63 4d 10 f0 	movl   $0xf0104d63,(%esp)
f0100789:	e8 8a 2e 00 00       	call   f0103618 <cprintf>
f010078e:	c7 44 24 08 75 4d 10 	movl   $0xf0104d75,0x8(%esp)
f0100795:	f0 
f0100796:	c7 44 24 04 89 4d 10 	movl   $0xf0104d89,0x4(%esp)
f010079d:	f0 
f010079e:	c7 04 24 63 4d 10 f0 	movl   $0xf0104d63,(%esp)
f01007a5:	e8 6e 2e 00 00       	call   f0103618 <cprintf>
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
f01007b7:	c7 04 24 93 4d 10 f0 	movl   $0xf0104d93,(%esp)
f01007be:	e8 55 2e 00 00       	call   f0103618 <cprintf>
	cprintf("  _start                  %08x (phys)\n", _start);
f01007c3:	c7 44 24 04 0c 00 10 	movl   $0x10000c,0x4(%esp)
f01007ca:	00 
f01007cb:	c7 04 24 28 4e 10 f0 	movl   $0xf0104e28,(%esp)
f01007d2:	e8 41 2e 00 00       	call   f0103618 <cprintf>
	cprintf("  entry  %08x (virt)  %08x (phys)\n", entry, entry - KERNBASE);
f01007d7:	c7 44 24 08 0c 00 10 	movl   $0x10000c,0x8(%esp)
f01007de:	00 
f01007df:	c7 44 24 04 0c 00 10 	movl   $0xf010000c,0x4(%esp)
f01007e6:	f0 
f01007e7:	c7 04 24 50 4e 10 f0 	movl   $0xf0104e50,(%esp)
f01007ee:	e8 25 2e 00 00       	call   f0103618 <cprintf>
	cprintf("  etext  %08x (virt)  %08x (phys)\n", etext, etext - KERNBASE);
f01007f3:	c7 44 24 08 61 4a 10 	movl   $0x104a61,0x8(%esp)
f01007fa:	00 
f01007fb:	c7 44 24 04 61 4a 10 	movl   $0xf0104a61,0x4(%esp)
f0100802:	f0 
f0100803:	c7 04 24 74 4e 10 f0 	movl   $0xf0104e74,(%esp)
f010080a:	e8 09 2e 00 00       	call   f0103618 <cprintf>
	cprintf("  edata  %08x (virt)  %08x (phys)\n", edata, edata - KERNBASE);
f010080f:	c7 44 24 08 78 50 18 	movl   $0x185078,0x8(%esp)
f0100816:	00 
f0100817:	c7 44 24 04 78 50 18 	movl   $0xf0185078,0x4(%esp)
f010081e:	f0 
f010081f:	c7 04 24 98 4e 10 f0 	movl   $0xf0104e98,(%esp)
f0100826:	e8 ed 2d 00 00       	call   f0103618 <cprintf>
	cprintf("  end    %08x (virt)  %08x (phys)\n", end, end - KERNBASE);
f010082b:	c7 44 24 08 90 6f 18 	movl   $0x186f90,0x8(%esp)
f0100832:	00 
f0100833:	c7 44 24 04 90 6f 18 	movl   $0xf0186f90,0x4(%esp)
f010083a:	f0 
f010083b:	c7 04 24 bc 4e 10 f0 	movl   $0xf0104ebc,(%esp)
f0100842:	e8 d1 2d 00 00       	call   f0103618 <cprintf>
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
f0100868:	c7 04 24 e0 4e 10 f0 	movl   $0xf0104ee0,(%esp)
f010086f:	e8 a4 2d 00 00       	call   f0103618 <cprintf>
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
f01008b9:	c7 04 24 0c 4f 10 f0 	movl   $0xf0104f0c,(%esp)
f01008c0:	e8 53 2d 00 00       	call   f0103618 <cprintf>
			*(uint32_t *)(ebp+8), *(uint32_t *)(ebp+12), *(uint32_t *)(ebp+16),
			*(uint32_t *)(ebp+20), *(uint32_t *)(ebp+24));
	debuginfo_eip(eip,&dbgi);
f01008c5:	89 7c 24 04          	mov    %edi,0x4(%esp)
f01008c9:	89 34 24             	mov    %esi,(%esp)
f01008cc:	e8 b8 32 00 00       	call   f0103b89 <debuginfo_eip>
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
f01008f4:	c7 04 24 ac 4d 10 f0 	movl   $0xf0104dac,(%esp)
f01008fb:	e8 18 2d 00 00       	call   f0103618 <cprintf>
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
f0100947:	c7 04 24 c3 4d 10 f0 	movl   $0xf0104dc3,(%esp)
f010094e:	e8 47 3c 00 00       	call   f010459a <strchr>
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
f010096a:	c7 04 24 c8 4d 10 f0 	movl   $0xf0104dc8,(%esp)
f0100971:	e8 a2 2c 00 00       	call   f0103618 <cprintf>
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
f010099a:	c7 04 24 c3 4d 10 f0 	movl   $0xf0104dc3,(%esp)
f01009a1:	e8 f4 3b 00 00       	call   f010459a <strchr>
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
f01009c5:	8b 04 85 a0 4f 10 f0 	mov    -0xfefb060(,%eax,4),%eax
f01009cc:	89 44 24 04          	mov    %eax,0x4(%esp)
f01009d0:	8b 45 a8             	mov    -0x58(%ebp),%eax
f01009d3:	89 04 24             	mov    %eax,(%esp)
f01009d6:	e8 61 3b 00 00       	call   f010453c <strcmp>
f01009db:	85 c0                	test   %eax,%eax
f01009dd:	75 1d                	jne    f01009fc <runcmd+0xe9>
			return commands[i].func(argc, argv, tf);
f01009df:	8d 04 5b             	lea    (%ebx,%ebx,2),%eax
f01009e2:	8b 4d a4             	mov    -0x5c(%ebp),%ecx
f01009e5:	89 4c 24 08          	mov    %ecx,0x8(%esp)
f01009e9:	8d 55 a8             	lea    -0x58(%ebp),%edx
f01009ec:	89 54 24 04          	mov    %edx,0x4(%esp)
f01009f0:	89 34 24             	mov    %esi,(%esp)
f01009f3:	ff 14 85 a8 4f 10 f0 	call   *-0xfefb058(,%eax,4)
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
f0100a0b:	c7 04 24 e5 4d 10 f0 	movl   $0xf0104de5,(%esp)
f0100a12:	e8 01 2c 00 00       	call   f0103618 <cprintf>
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
f0100a2e:	c7 04 24 40 4f 10 f0 	movl   $0xf0104f40,(%esp)
f0100a35:	e8 de 2b 00 00       	call   f0103618 <cprintf>
	cprintf("Type 'help' for a list of commands.\n");
f0100a3a:	c7 04 24 64 4f 10 f0 	movl   $0xf0104f64,(%esp)
f0100a41:	e8 d2 2b 00 00       	call   f0103618 <cprintf>

	if (tf != NULL)
f0100a46:	85 db                	test   %ebx,%ebx
f0100a48:	74 08                	je     f0100a52 <monitor+0x2e>
		print_trapframe(tf);
f0100a4a:	89 1c 24             	mov    %ebx,(%esp)
f0100a4d:	e8 34 2d 00 00       	call   f0103786 <print_trapframe>

	while (1) {
		buf = readline("K> ");
f0100a52:	c7 04 24 fb 4d 10 f0 	movl   $0xf0104dfb,(%esp)
f0100a59:	e8 22 39 00 00       	call   f0104380 <readline>
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
f0100ab1:	e8 db 2a 00 00       	call   f0103591 <mc146818_read>
f0100ab6:	89 c6                	mov    %eax,%esi
f0100ab8:	83 c3 01             	add    $0x1,%ebx
f0100abb:	89 1c 24             	mov    %ebx,(%esp)
f0100abe:	e8 ce 2a 00 00       	call   f0103591 <mc146818_read>
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
f0100b38:	c7 04 24 c4 4f 10 f0 	movl   $0xf0104fc4,(%esp)
f0100b3f:	e8 d4 2a 00 00       	call   f0103618 <cprintf>
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
f0100b63:	c7 44 24 08 00 50 10 	movl   $0xf0105000,0x8(%esp)
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
f0100b95:	b8 ad 57 10 f0       	mov    $0xf01057ad,%eax
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
f0100bdb:	b8 bb 57 10 f0       	mov    $0xf01057bb,%eax
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
f0100c1f:	c7 44 24 08 24 50 10 	movl   $0xf0105024,0x8(%esp)
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
f0100c84:	b8 bb 57 10 f0       	mov    $0xf01057bb,%eax
f0100c89:	e8 7f ff ff ff       	call   f0100c0d <_paddr>
f0100c8e:	8b 15 84 6f 18 f0    	mov    0xf0186f84,%edx
f0100c94:	c1 e2 0c             	shl    $0xc,%edx
f0100c97:	39 d0                	cmp    %edx,%eax
f0100c99:	76 1c                	jbe    f0100cb7 <boot_alloc+0x7d>
f0100c9b:	c7 44 24 08 c7 57 10 	movl   $0xf01057c7,0x8(%esp)
f0100ca2:	f0 
f0100ca3:	c7 44 24 04 6e 00 00 	movl   $0x6e,0x4(%esp)
f0100caa:	00 
f0100cab:	c7 04 24 bb 57 10 f0 	movl   $0xf01057bb,(%esp)
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
f0100d0b:	b8 bb 57 10 f0       	mov    $0xf01057bb,%eax
f0100d10:	e8 f8 fe ff ff       	call   f0100c0d <_paddr>
f0100d15:	01 f0                	add    %esi,%eax
f0100d17:	39 c7                	cmp    %eax,%edi
f0100d19:	74 24                	je     f0100d3f <check_kern_pgdir+0x80>
f0100d1b:	c7 44 24 0c 48 50 10 	movl   $0xf0105048,0xc(%esp)
f0100d22:	f0 
f0100d23:	c7 44 24 08 da 57 10 	movl   $0xf01057da,0x8(%esp)
f0100d2a:	f0 
f0100d2b:	c7 44 24 04 dd 02 00 	movl   $0x2dd,0x4(%esp)
f0100d32:	00 
f0100d33:	c7 04 24 bb 57 10 f0 	movl   $0xf01057bb,(%esp)
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
f0100d6e:	b8 bb 57 10 f0       	mov    $0xf01057bb,%eax
f0100d73:	e8 95 fe ff ff       	call   f0100c0d <_paddr>
f0100d78:	01 f0                	add    %esi,%eax
f0100d7a:	39 c7                	cmp    %eax,%edi
f0100d7c:	74 24                	je     f0100da2 <check_kern_pgdir+0xe3>
f0100d7e:	c7 44 24 0c 7c 50 10 	movl   $0xf010507c,0xc(%esp)
f0100d85:	f0 
f0100d86:	c7 44 24 08 da 57 10 	movl   $0xf01057da,0x8(%esp)
f0100d8d:	f0 
f0100d8e:	c7 44 24 04 e2 02 00 	movl   $0x2e2,0x4(%esp)
f0100d95:	00 
f0100d96:	c7 04 24 bb 57 10 f0 	movl   $0xf01057bb,(%esp)
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
f0100dce:	c7 44 24 0c b0 50 10 	movl   $0xf01050b0,0xc(%esp)
f0100dd5:	f0 
f0100dd6:	c7 44 24 08 da 57 10 	movl   $0xf01057da,0x8(%esp)
f0100ddd:	f0 
f0100dde:	c7 44 24 04 e6 02 00 	movl   $0x2e6,0x4(%esp)
f0100de5:	00 
f0100de6:	c7 04 24 bb 57 10 f0 	movl   $0xf01057bb,(%esp)
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
f0100e1a:	b8 bb 57 10 f0       	mov    $0xf01057bb,%eax
f0100e1f:	e8 e9 fd ff ff       	call   f0100c0d <_paddr>
f0100e24:	01 f0                	add    %esi,%eax
f0100e26:	39 c7                	cmp    %eax,%edi
f0100e28:	74 24                	je     f0100e4e <check_kern_pgdir+0x18f>
f0100e2a:	c7 44 24 0c d8 50 10 	movl   $0xf01050d8,0xc(%esp)
f0100e31:	f0 
f0100e32:	c7 44 24 08 da 57 10 	movl   $0xf01057da,0x8(%esp)
f0100e39:	f0 
f0100e3a:	c7 44 24 04 ea 02 00 	movl   $0x2ea,0x4(%esp)
f0100e41:	00 
f0100e42:	c7 04 24 bb 57 10 f0 	movl   $0xf01057bb,(%esp)
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
f0100e77:	c7 44 24 0c 20 51 10 	movl   $0xf0105120,0xc(%esp)
f0100e7e:	f0 
f0100e7f:	c7 44 24 08 da 57 10 	movl   $0xf01057da,0x8(%esp)
f0100e86:	f0 
f0100e87:	c7 44 24 04 eb 02 00 	movl   $0x2eb,0x4(%esp)
f0100e8e:	00 
f0100e8f:	c7 04 24 bb 57 10 f0 	movl   $0xf01057bb,(%esp)
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
f0100eba:	c7 44 24 0c ef 57 10 	movl   $0xf01057ef,0xc(%esp)
f0100ec1:	f0 
f0100ec2:	c7 44 24 08 da 57 10 	movl   $0xf01057da,0x8(%esp)
f0100ec9:	f0 
f0100eca:	c7 44 24 04 f4 02 00 	movl   $0x2f4,0x4(%esp)
f0100ed1:	00 
f0100ed2:	c7 04 24 bb 57 10 f0 	movl   $0xf01057bb,(%esp)
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
f0100eed:	c7 44 24 0c ef 57 10 	movl   $0xf01057ef,0xc(%esp)
f0100ef4:	f0 
f0100ef5:	c7 44 24 08 da 57 10 	movl   $0xf01057da,0x8(%esp)
f0100efc:	f0 
f0100efd:	c7 44 24 04 f8 02 00 	movl   $0x2f8,0x4(%esp)
f0100f04:	00 
f0100f05:	c7 04 24 bb 57 10 f0 	movl   $0xf01057bb,(%esp)
f0100f0c:	e8 98 f1 ff ff       	call   f01000a9 <_panic>
				assert(pgdir[i] & PTE_W);
f0100f11:	f6 c2 02             	test   $0x2,%dl
f0100f14:	75 4e                	jne    f0100f64 <check_kern_pgdir+0x2a5>
f0100f16:	c7 44 24 0c 00 58 10 	movl   $0xf0105800,0xc(%esp)
f0100f1d:	f0 
f0100f1e:	c7 44 24 08 da 57 10 	movl   $0xf01057da,0x8(%esp)
f0100f25:	f0 
f0100f26:	c7 44 24 04 f9 02 00 	movl   $0x2f9,0x4(%esp)
f0100f2d:	00 
f0100f2e:	c7 04 24 bb 57 10 f0 	movl   $0xf01057bb,(%esp)
f0100f35:	e8 6f f1 ff ff       	call   f01000a9 <_panic>
			} else
				assert(pgdir[i] == 0);
f0100f3a:	83 3c 83 00          	cmpl   $0x0,(%ebx,%eax,4)
f0100f3e:	74 24                	je     f0100f64 <check_kern_pgdir+0x2a5>
f0100f40:	c7 44 24 0c 11 58 10 	movl   $0xf0105811,0xc(%esp)
f0100f47:	f0 
f0100f48:	c7 44 24 08 da 57 10 	movl   $0xf01057da,0x8(%esp)
f0100f4f:	f0 
f0100f50:	c7 44 24 04 fb 02 00 	movl   $0x2fb,0x4(%esp)
f0100f57:	00 
f0100f58:	c7 04 24 bb 57 10 f0 	movl   $0xf01057bb,(%esp)
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
f0100f72:	c7 04 24 50 51 10 f0 	movl   $0xf0105150,(%esp)
f0100f79:	e8 9a 26 00 00       	call   f0103618 <cprintf>
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
f0100f9c:	c7 44 24 08 70 51 10 	movl   $0xf0105170,0x8(%esp)
f0100fa3:	f0 
f0100fa4:	c7 44 24 04 4d 02 00 	movl   $0x24d,0x4(%esp)
f0100fab:	00 
f0100fac:	c7 04 24 bb 57 10 f0 	movl   $0xf01057bb,(%esp)
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
f0101034:	e8 9e 35 00 00       	call   f01045d7 <memset>
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
f010107b:	c7 44 24 0c 1f 58 10 	movl   $0xf010581f,0xc(%esp)
f0101082:	f0 
f0101083:	c7 44 24 08 da 57 10 	movl   $0xf01057da,0x8(%esp)
f010108a:	f0 
f010108b:	c7 44 24 04 67 02 00 	movl   $0x267,0x4(%esp)
f0101092:	00 
f0101093:	c7 04 24 bb 57 10 f0 	movl   $0xf01057bb,(%esp)
f010109a:	e8 0a f0 ff ff       	call   f01000a9 <_panic>
		assert(pp < pages + npages);
f010109f:	3b 5d d4             	cmp    -0x2c(%ebp),%ebx
f01010a2:	72 24                	jb     f01010c8 <check_page_free_list+0x142>
f01010a4:	c7 44 24 0c 2b 58 10 	movl   $0xf010582b,0xc(%esp)
f01010ab:	f0 
f01010ac:	c7 44 24 08 da 57 10 	movl   $0xf01057da,0x8(%esp)
f01010b3:	f0 
f01010b4:	c7 44 24 04 68 02 00 	movl   $0x268,0x4(%esp)
f01010bb:	00 
f01010bc:	c7 04 24 bb 57 10 f0 	movl   $0xf01057bb,(%esp)
f01010c3:	e8 e1 ef ff ff       	call   f01000a9 <_panic>
		assert(((char *) pp - (char *) pages) % sizeof(*pp) == 0);
f01010c8:	89 d8                	mov    %ebx,%eax
f01010ca:	2b 45 d0             	sub    -0x30(%ebp),%eax
f01010cd:	a8 07                	test   $0x7,%al
f01010cf:	74 24                	je     f01010f5 <check_page_free_list+0x16f>
f01010d1:	c7 44 24 0c 94 51 10 	movl   $0xf0105194,0xc(%esp)
f01010d8:	f0 
f01010d9:	c7 44 24 08 da 57 10 	movl   $0xf01057da,0x8(%esp)
f01010e0:	f0 
f01010e1:	c7 44 24 04 69 02 00 	movl   $0x269,0x4(%esp)
f01010e8:	00 
f01010e9:	c7 04 24 bb 57 10 f0 	movl   $0xf01057bb,(%esp)
f01010f0:	e8 b4 ef ff ff       	call   f01000a9 <_panic>

		// check a few pages that shouldn't be on the free list
		assert(page2pa(pp) != 0);
f01010f5:	89 d8                	mov    %ebx,%eax
f01010f7:	e8 97 f9 ff ff       	call   f0100a93 <page2pa>
f01010fc:	85 c0                	test   %eax,%eax
f01010fe:	75 24                	jne    f0101124 <check_page_free_list+0x19e>
f0101100:	c7 44 24 0c 3f 58 10 	movl   $0xf010583f,0xc(%esp)
f0101107:	f0 
f0101108:	c7 44 24 08 da 57 10 	movl   $0xf01057da,0x8(%esp)
f010110f:	f0 
f0101110:	c7 44 24 04 6c 02 00 	movl   $0x26c,0x4(%esp)
f0101117:	00 
f0101118:	c7 04 24 bb 57 10 f0 	movl   $0xf01057bb,(%esp)
f010111f:	e8 85 ef ff ff       	call   f01000a9 <_panic>
		assert(page2pa(pp) != IOPHYSMEM);
f0101124:	3d 00 00 0a 00       	cmp    $0xa0000,%eax
f0101129:	75 24                	jne    f010114f <check_page_free_list+0x1c9>
f010112b:	c7 44 24 0c 50 58 10 	movl   $0xf0105850,0xc(%esp)
f0101132:	f0 
f0101133:	c7 44 24 08 da 57 10 	movl   $0xf01057da,0x8(%esp)
f010113a:	f0 
f010113b:	c7 44 24 04 6d 02 00 	movl   $0x26d,0x4(%esp)
f0101142:	00 
f0101143:	c7 04 24 bb 57 10 f0 	movl   $0xf01057bb,(%esp)
f010114a:	e8 5a ef ff ff       	call   f01000a9 <_panic>
		assert(page2pa(pp) != EXTPHYSMEM - PGSIZE);
f010114f:	3d 00 f0 0f 00       	cmp    $0xff000,%eax
f0101154:	75 24                	jne    f010117a <check_page_free_list+0x1f4>
f0101156:	c7 44 24 0c c8 51 10 	movl   $0xf01051c8,0xc(%esp)
f010115d:	f0 
f010115e:	c7 44 24 08 da 57 10 	movl   $0xf01057da,0x8(%esp)
f0101165:	f0 
f0101166:	c7 44 24 04 6e 02 00 	movl   $0x26e,0x4(%esp)
f010116d:	00 
f010116e:	c7 04 24 bb 57 10 f0 	movl   $0xf01057bb,(%esp)
f0101175:	e8 2f ef ff ff       	call   f01000a9 <_panic>
		assert(page2pa(pp) != EXTPHYSMEM);
f010117a:	3d 00 00 10 00       	cmp    $0x100000,%eax
f010117f:	75 24                	jne    f01011a5 <check_page_free_list+0x21f>
f0101181:	c7 44 24 0c 69 58 10 	movl   $0xf0105869,0xc(%esp)
f0101188:	f0 
f0101189:	c7 44 24 08 da 57 10 	movl   $0xf01057da,0x8(%esp)
f0101190:	f0 
f0101191:	c7 44 24 04 6f 02 00 	movl   $0x26f,0x4(%esp)
f0101198:	00 
f0101199:	c7 04 24 bb 57 10 f0 	movl   $0xf01057bb,(%esp)
f01011a0:	e8 04 ef ff ff       	call   f01000a9 <_panic>
		assert(page2pa(pp) < EXTPHYSMEM || (char *) page2kva(pp) >= first_free_page);
f01011a5:	3d ff ff 0f 00       	cmp    $0xfffff,%eax
f01011aa:	76 30                	jbe    f01011dc <check_page_free_list+0x256>
f01011ac:	89 d8                	mov    %ebx,%eax
f01011ae:	e8 d0 f9 ff ff       	call   f0100b83 <page2kva>
f01011b3:	39 45 c8             	cmp    %eax,-0x38(%ebp)
f01011b6:	76 29                	jbe    f01011e1 <check_page_free_list+0x25b>
f01011b8:	c7 44 24 0c ec 51 10 	movl   $0xf01051ec,0xc(%esp)
f01011bf:	f0 
f01011c0:	c7 44 24 08 da 57 10 	movl   $0xf01057da,0x8(%esp)
f01011c7:	f0 
f01011c8:	c7 44 24 04 70 02 00 	movl   $0x270,0x4(%esp)
f01011cf:	00 
f01011d0:	c7 04 24 bb 57 10 f0 	movl   $0xf01057bb,(%esp)
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
f01011f3:	c7 44 24 0c 83 58 10 	movl   $0xf0105883,0xc(%esp)
f01011fa:	f0 
f01011fb:	c7 44 24 08 da 57 10 	movl   $0xf01057da,0x8(%esp)
f0101202:	f0 
f0101203:	c7 44 24 04 78 02 00 	movl   $0x278,0x4(%esp)
f010120a:	00 
f010120b:	c7 04 24 bb 57 10 f0 	movl   $0xf01057bb,(%esp)
f0101212:	e8 92 ee ff ff       	call   f01000a9 <_panic>
	assert(nfree_extmem > 0);
f0101217:	83 7d cc 00          	cmpl   $0x0,-0x34(%ebp)
f010121b:	7f 4e                	jg     f010126b <check_page_free_list+0x2e5>
f010121d:	c7 44 24 0c 95 58 10 	movl   $0xf0105895,0xc(%esp)
f0101224:	f0 
f0101225:	c7 44 24 08 da 57 10 	movl   $0xf01057da,0x8(%esp)
f010122c:	f0 
f010122d:	c7 44 24 04 79 02 00 	movl   $0x279,0x4(%esp)
f0101234:	00 
f0101235:	c7 04 24 bb 57 10 f0 	movl   $0xf01057bb,(%esp)
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
f0101284:	c7 44 24 08 34 52 10 	movl   $0xf0105234,0x8(%esp)
f010128b:	f0 
f010128c:	c7 44 24 04 4f 00 00 	movl   $0x4f,0x4(%esp)
f0101293:	00 
f0101294:	c7 04 24 ad 57 10 f0 	movl   $0xf01057ad,(%esp)
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
f01012c0:	b8 bb 57 10 f0       	mov    $0xf01057bb,%eax
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
f0101358:	e8 7a 32 00 00       	call   f01045d7 <memset>
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
f010137c:	c7 44 24 08 a6 58 10 	movl   $0xf01058a6,0x8(%esp)
f0101383:	f0 
f0101384:	c7 44 24 04 42 01 00 	movl   $0x142,0x4(%esp)
f010138b:	00 
f010138c:	c7 04 24 bb 57 10 f0 	movl   $0xf01057bb,(%esp)
f0101393:	e8 11 ed ff ff       	call   f01000a9 <_panic>
	if (pp->pp_link) panic("page has non-NULL pp_link (already freed?)\n");
f0101398:	83 38 00             	cmpl   $0x0,(%eax)
f010139b:	74 1c                	je     f01013b9 <page_free+0x4d>
f010139d:	c7 44 24 08 54 52 10 	movl   $0xf0105254,0x8(%esp)
f01013a4:	f0 
f01013a5:	c7 44 24 04 43 01 00 	movl   $0x143,0x4(%esp)
f01013ac:	00 
f01013ad:	c7 04 24 bb 57 10 f0 	movl   $0xf01057bb,(%esp)
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
f01013da:	c7 44 24 08 ba 58 10 	movl   $0xf01058ba,0x8(%esp)
f01013e1:	f0 
f01013e2:	c7 44 24 04 8a 02 00 	movl   $0x28a,0x4(%esp)
f01013e9:	00 
f01013ea:	c7 04 24 bb 57 10 f0 	movl   $0xf01057bb,(%esp)
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
f010141d:	c7 44 24 0c d5 58 10 	movl   $0xf01058d5,0xc(%esp)
f0101424:	f0 
f0101425:	c7 44 24 08 da 57 10 	movl   $0xf01057da,0x8(%esp)
f010142c:	f0 
f010142d:	c7 44 24 04 92 02 00 	movl   $0x292,0x4(%esp)
f0101434:	00 
f0101435:	c7 04 24 bb 57 10 f0 	movl   $0xf01057bb,(%esp)
f010143c:	e8 68 ec ff ff       	call   f01000a9 <_panic>
	assert((pp1 = page_alloc(0)));
f0101441:	c7 04 24 00 00 00 00 	movl   $0x0,(%esp)
f0101448:	e8 cd fe ff ff       	call   f010131a <page_alloc>
f010144d:	89 45 e4             	mov    %eax,-0x1c(%ebp)
f0101450:	85 c0                	test   %eax,%eax
f0101452:	75 24                	jne    f0101478 <check_page_alloc+0xb0>
f0101454:	c7 44 24 0c eb 58 10 	movl   $0xf01058eb,0xc(%esp)
f010145b:	f0 
f010145c:	c7 44 24 08 da 57 10 	movl   $0xf01057da,0x8(%esp)
f0101463:	f0 
f0101464:	c7 44 24 04 93 02 00 	movl   $0x293,0x4(%esp)
f010146b:	00 
f010146c:	c7 04 24 bb 57 10 f0 	movl   $0xf01057bb,(%esp)
f0101473:	e8 31 ec ff ff       	call   f01000a9 <_panic>
	assert((pp2 = page_alloc(0)));
f0101478:	c7 04 24 00 00 00 00 	movl   $0x0,(%esp)
f010147f:	e8 96 fe ff ff       	call   f010131a <page_alloc>
f0101484:	89 c3                	mov    %eax,%ebx
f0101486:	85 c0                	test   %eax,%eax
f0101488:	75 24                	jne    f01014ae <check_page_alloc+0xe6>
f010148a:	c7 44 24 0c 01 59 10 	movl   $0xf0105901,0xc(%esp)
f0101491:	f0 
f0101492:	c7 44 24 08 da 57 10 	movl   $0xf01057da,0x8(%esp)
f0101499:	f0 
f010149a:	c7 44 24 04 94 02 00 	movl   $0x294,0x4(%esp)
f01014a1:	00 
f01014a2:	c7 04 24 bb 57 10 f0 	movl   $0xf01057bb,(%esp)
f01014a9:	e8 fb eb ff ff       	call   f01000a9 <_panic>

	assert(pp0);
	assert(pp1 && pp1 != pp0);
f01014ae:	3b 7d e4             	cmp    -0x1c(%ebp),%edi
f01014b1:	75 24                	jne    f01014d7 <check_page_alloc+0x10f>
f01014b3:	c7 44 24 0c 17 59 10 	movl   $0xf0105917,0xc(%esp)
f01014ba:	f0 
f01014bb:	c7 44 24 08 da 57 10 	movl   $0xf01057da,0x8(%esp)
f01014c2:	f0 
f01014c3:	c7 44 24 04 97 02 00 	movl   $0x297,0x4(%esp)
f01014ca:	00 
f01014cb:	c7 04 24 bb 57 10 f0 	movl   $0xf01057bb,(%esp)
f01014d2:	e8 d2 eb ff ff       	call   f01000a9 <_panic>
	assert(pp2 && pp2 != pp1 && pp2 != pp0);
f01014d7:	39 45 e4             	cmp    %eax,-0x1c(%ebp)
f01014da:	74 04                	je     f01014e0 <check_page_alloc+0x118>
f01014dc:	39 f8                	cmp    %edi,%eax
f01014de:	75 24                	jne    f0101504 <check_page_alloc+0x13c>
f01014e0:	c7 44 24 0c 80 52 10 	movl   $0xf0105280,0xc(%esp)
f01014e7:	f0 
f01014e8:	c7 44 24 08 da 57 10 	movl   $0xf01057da,0x8(%esp)
f01014ef:	f0 
f01014f0:	c7 44 24 04 98 02 00 	movl   $0x298,0x4(%esp)
f01014f7:	00 
f01014f8:	c7 04 24 bb 57 10 f0 	movl   $0xf01057bb,(%esp)
f01014ff:	e8 a5 eb ff ff       	call   f01000a9 <_panic>
	assert(page2pa(pp0) < npages*PGSIZE);
f0101504:	89 f8                	mov    %edi,%eax
f0101506:	e8 88 f5 ff ff       	call   f0100a93 <page2pa>
f010150b:	8b 0d 84 6f 18 f0    	mov    0xf0186f84,%ecx
f0101511:	c1 e1 0c             	shl    $0xc,%ecx
f0101514:	89 4d e0             	mov    %ecx,-0x20(%ebp)
f0101517:	39 c8                	cmp    %ecx,%eax
f0101519:	72 24                	jb     f010153f <check_page_alloc+0x177>
f010151b:	c7 44 24 0c 29 59 10 	movl   $0xf0105929,0xc(%esp)
f0101522:	f0 
f0101523:	c7 44 24 08 da 57 10 	movl   $0xf01057da,0x8(%esp)
f010152a:	f0 
f010152b:	c7 44 24 04 99 02 00 	movl   $0x299,0x4(%esp)
f0101532:	00 
f0101533:	c7 04 24 bb 57 10 f0 	movl   $0xf01057bb,(%esp)
f010153a:	e8 6a eb ff ff       	call   f01000a9 <_panic>
	assert(page2pa(pp1) < npages*PGSIZE);
f010153f:	8b 45 e4             	mov    -0x1c(%ebp),%eax
f0101542:	e8 4c f5 ff ff       	call   f0100a93 <page2pa>
f0101547:	39 45 e0             	cmp    %eax,-0x20(%ebp)
f010154a:	77 24                	ja     f0101570 <check_page_alloc+0x1a8>
f010154c:	c7 44 24 0c 46 59 10 	movl   $0xf0105946,0xc(%esp)
f0101553:	f0 
f0101554:	c7 44 24 08 da 57 10 	movl   $0xf01057da,0x8(%esp)
f010155b:	f0 
f010155c:	c7 44 24 04 9a 02 00 	movl   $0x29a,0x4(%esp)
f0101563:	00 
f0101564:	c7 04 24 bb 57 10 f0 	movl   $0xf01057bb,(%esp)
f010156b:	e8 39 eb ff ff       	call   f01000a9 <_panic>
	assert(page2pa(pp2) < npages*PGSIZE);
f0101570:	89 d8                	mov    %ebx,%eax
f0101572:	e8 1c f5 ff ff       	call   f0100a93 <page2pa>
f0101577:	39 45 e0             	cmp    %eax,-0x20(%ebp)
f010157a:	77 24                	ja     f01015a0 <check_page_alloc+0x1d8>
f010157c:	c7 44 24 0c 63 59 10 	movl   $0xf0105963,0xc(%esp)
f0101583:	f0 
f0101584:	c7 44 24 08 da 57 10 	movl   $0xf01057da,0x8(%esp)
f010158b:	f0 
f010158c:	c7 44 24 04 9b 02 00 	movl   $0x29b,0x4(%esp)
f0101593:	00 
f0101594:	c7 04 24 bb 57 10 f0 	movl   $0xf01057bb,(%esp)
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
f01015c2:	c7 44 24 0c 80 59 10 	movl   $0xf0105980,0xc(%esp)
f01015c9:	f0 
f01015ca:	c7 44 24 08 da 57 10 	movl   $0xf01057da,0x8(%esp)
f01015d1:	f0 
f01015d2:	c7 44 24 04 a2 02 00 	movl   $0x2a2,0x4(%esp)
f01015d9:	00 
f01015da:	c7 04 24 bb 57 10 f0 	movl   $0xf01057bb,(%esp)
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
f0101613:	c7 44 24 0c d5 58 10 	movl   $0xf01058d5,0xc(%esp)
f010161a:	f0 
f010161b:	c7 44 24 08 da 57 10 	movl   $0xf01057da,0x8(%esp)
f0101622:	f0 
f0101623:	c7 44 24 04 a9 02 00 	movl   $0x2a9,0x4(%esp)
f010162a:	00 
f010162b:	c7 04 24 bb 57 10 f0 	movl   $0xf01057bb,(%esp)
f0101632:	e8 72 ea ff ff       	call   f01000a9 <_panic>
	assert((pp1 = page_alloc(0)));
f0101637:	c7 04 24 00 00 00 00 	movl   $0x0,(%esp)
f010163e:	e8 d7 fc ff ff       	call   f010131a <page_alloc>
f0101643:	89 45 e4             	mov    %eax,-0x1c(%ebp)
f0101646:	85 c0                	test   %eax,%eax
f0101648:	75 24                	jne    f010166e <check_page_alloc+0x2a6>
f010164a:	c7 44 24 0c eb 58 10 	movl   $0xf01058eb,0xc(%esp)
f0101651:	f0 
f0101652:	c7 44 24 08 da 57 10 	movl   $0xf01057da,0x8(%esp)
f0101659:	f0 
f010165a:	c7 44 24 04 aa 02 00 	movl   $0x2aa,0x4(%esp)
f0101661:	00 
f0101662:	c7 04 24 bb 57 10 f0 	movl   $0xf01057bb,(%esp)
f0101669:	e8 3b ea ff ff       	call   f01000a9 <_panic>
	assert((pp2 = page_alloc(0)));
f010166e:	c7 04 24 00 00 00 00 	movl   $0x0,(%esp)
f0101675:	e8 a0 fc ff ff       	call   f010131a <page_alloc>
f010167a:	89 c7                	mov    %eax,%edi
f010167c:	85 c0                	test   %eax,%eax
f010167e:	75 24                	jne    f01016a4 <check_page_alloc+0x2dc>
f0101680:	c7 44 24 0c 01 59 10 	movl   $0xf0105901,0xc(%esp)
f0101687:	f0 
f0101688:	c7 44 24 08 da 57 10 	movl   $0xf01057da,0x8(%esp)
f010168f:	f0 
f0101690:	c7 44 24 04 ab 02 00 	movl   $0x2ab,0x4(%esp)
f0101697:	00 
f0101698:	c7 04 24 bb 57 10 f0 	movl   $0xf01057bb,(%esp)
f010169f:	e8 05 ea ff ff       	call   f01000a9 <_panic>
	assert(pp0);
	assert(pp1 && pp1 != pp0);
f01016a4:	3b 5d e4             	cmp    -0x1c(%ebp),%ebx
f01016a7:	75 24                	jne    f01016cd <check_page_alloc+0x305>
f01016a9:	c7 44 24 0c 17 59 10 	movl   $0xf0105917,0xc(%esp)
f01016b0:	f0 
f01016b1:	c7 44 24 08 da 57 10 	movl   $0xf01057da,0x8(%esp)
f01016b8:	f0 
f01016b9:	c7 44 24 04 ad 02 00 	movl   $0x2ad,0x4(%esp)
f01016c0:	00 
f01016c1:	c7 04 24 bb 57 10 f0 	movl   $0xf01057bb,(%esp)
f01016c8:	e8 dc e9 ff ff       	call   f01000a9 <_panic>
	assert(pp2 && pp2 != pp1 && pp2 != pp0);
f01016cd:	39 45 e4             	cmp    %eax,-0x1c(%ebp)
f01016d0:	74 04                	je     f01016d6 <check_page_alloc+0x30e>
f01016d2:	39 d8                	cmp    %ebx,%eax
f01016d4:	75 24                	jne    f01016fa <check_page_alloc+0x332>
f01016d6:	c7 44 24 0c 80 52 10 	movl   $0xf0105280,0xc(%esp)
f01016dd:	f0 
f01016de:	c7 44 24 08 da 57 10 	movl   $0xf01057da,0x8(%esp)
f01016e5:	f0 
f01016e6:	c7 44 24 04 ae 02 00 	movl   $0x2ae,0x4(%esp)
f01016ed:	00 
f01016ee:	c7 04 24 bb 57 10 f0 	movl   $0xf01057bb,(%esp)
f01016f5:	e8 af e9 ff ff       	call   f01000a9 <_panic>
	assert(!page_alloc(0));
f01016fa:	c7 04 24 00 00 00 00 	movl   $0x0,(%esp)
f0101701:	e8 14 fc ff ff       	call   f010131a <page_alloc>
f0101706:	85 c0                	test   %eax,%eax
f0101708:	74 24                	je     f010172e <check_page_alloc+0x366>
f010170a:	c7 44 24 0c 80 59 10 	movl   $0xf0105980,0xc(%esp)
f0101711:	f0 
f0101712:	c7 44 24 08 da 57 10 	movl   $0xf01057da,0x8(%esp)
f0101719:	f0 
f010171a:	c7 44 24 04 af 02 00 	movl   $0x2af,0x4(%esp)
f0101721:	00 
f0101722:	c7 04 24 bb 57 10 f0 	movl   $0xf01057bb,(%esp)
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
f0101748:	e8 8a 2e 00 00       	call   f01045d7 <memset>
	page_free(pp0);
f010174d:	89 1c 24             	mov    %ebx,(%esp)
f0101750:	e8 17 fc ff ff       	call   f010136c <page_free>
	assert((pp = page_alloc(ALLOC_ZERO)));
f0101755:	c7 04 24 01 00 00 00 	movl   $0x1,(%esp)
f010175c:	e8 b9 fb ff ff       	call   f010131a <page_alloc>
f0101761:	85 c0                	test   %eax,%eax
f0101763:	75 24                	jne    f0101789 <check_page_alloc+0x3c1>
f0101765:	c7 44 24 0c 8f 59 10 	movl   $0xf010598f,0xc(%esp)
f010176c:	f0 
f010176d:	c7 44 24 08 da 57 10 	movl   $0xf01057da,0x8(%esp)
f0101774:	f0 
f0101775:	c7 44 24 04 b4 02 00 	movl   $0x2b4,0x4(%esp)
f010177c:	00 
f010177d:	c7 04 24 bb 57 10 f0 	movl   $0xf01057bb,(%esp)
f0101784:	e8 20 e9 ff ff       	call   f01000a9 <_panic>
	assert(pp && pp0 == pp);
f0101789:	39 c3                	cmp    %eax,%ebx
f010178b:	74 24                	je     f01017b1 <check_page_alloc+0x3e9>
f010178d:	c7 44 24 0c ad 59 10 	movl   $0xf01059ad,0xc(%esp)
f0101794:	f0 
f0101795:	c7 44 24 08 da 57 10 	movl   $0xf01057da,0x8(%esp)
f010179c:	f0 
f010179d:	c7 44 24 04 b5 02 00 	movl   $0x2b5,0x4(%esp)
f01017a4:	00 
f01017a5:	c7 04 24 bb 57 10 f0 	movl   $0xf01057bb,(%esp)
f01017ac:	e8 f8 e8 ff ff       	call   f01000a9 <_panic>
	c = page2kva(pp);
f01017b1:	89 d8                	mov    %ebx,%eax
f01017b3:	e8 cb f3 ff ff       	call   f0100b83 <page2kva>
	for (i = 0; i < PGSIZE; i++)
f01017b8:	ba 00 00 00 00       	mov    $0x0,%edx
		assert(c[i] == 0);
f01017bd:	80 3c 10 00          	cmpb   $0x0,(%eax,%edx,1)
f01017c1:	74 24                	je     f01017e7 <check_page_alloc+0x41f>
f01017c3:	c7 44 24 0c bd 59 10 	movl   $0xf01059bd,0xc(%esp)
f01017ca:	f0 
f01017cb:	c7 44 24 08 da 57 10 	movl   $0xf01057da,0x8(%esp)
f01017d2:	f0 
f01017d3:	c7 44 24 04 b8 02 00 	movl   $0x2b8,0x4(%esp)
f01017da:	00 
f01017db:	c7 04 24 bb 57 10 f0 	movl   $0xf01057bb,(%esp)
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
f0101829:	c7 44 24 0c c7 59 10 	movl   $0xf01059c7,0xc(%esp)
f0101830:	f0 
f0101831:	c7 44 24 08 da 57 10 	movl   $0xf01057da,0x8(%esp)
f0101838:	f0 
f0101839:	c7 44 24 04 c5 02 00 	movl   $0x2c5,0x4(%esp)
f0101840:	00 
f0101841:	c7 04 24 bb 57 10 f0 	movl   $0xf01057bb,(%esp)
f0101848:	e8 5c e8 ff ff       	call   f01000a9 <_panic>

	cprintf("check_page_alloc() succeeded!\n");
f010184d:	c7 04 24 a0 52 10 f0 	movl   $0xf01052a0,(%esp)
f0101854:	e8 bf 1d 00 00       	call   f0103618 <cprintf>
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
f01018aa:	b8 bb 57 10 f0       	mov    $0xf01057bb,%eax
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
f01018fb:	b8 bb 57 10 f0       	mov    $0xf01057bb,%eax
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
f0101936:	c7 44 24 0c d2 59 10 	movl   $0xf01059d2,0xc(%esp)
f010193d:	f0 
f010193e:	c7 44 24 08 da 57 10 	movl   $0xf01057da,0x8(%esp)
f0101945:	f0 
f0101946:	c7 44 24 04 8a 01 00 	movl   $0x18a,0x4(%esp)
f010194d:	00 
f010194e:	c7 04 24 bb 57 10 f0 	movl   $0xf01057bb,(%esp)
f0101955:	e8 4f e7 ff ff       	call   f01000a9 <_panic>
f010195a:	89 ce                	mov    %ecx,%esi
	assert(pa % PGSIZE == 0);
f010195c:	a9 ff 0f 00 00       	test   $0xfff,%eax
f0101961:	74 24                	je     f0101987 <boot_map_region+0x68>
f0101963:	c7 44 24 0c e3 59 10 	movl   $0xf01059e3,0xc(%esp)
f010196a:	f0 
f010196b:	c7 44 24 08 da 57 10 	movl   $0xf01057da,0x8(%esp)
f0101972:	f0 
f0101973:	c7 44 24 04 8b 01 00 	movl   $0x18b,0x4(%esp)
f010197a:	00 
f010197b:	c7 04 24 bb 57 10 f0 	movl   $0xf01057bb,(%esp)
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
f01019a1:	c7 44 24 0c f4 59 10 	movl   $0xf01059f4,0xc(%esp)
f01019a8:	f0 
f01019a9:	c7 44 24 08 da 57 10 	movl   $0xf01057da,0x8(%esp)
f01019b0:	f0 
f01019b1:	c7 44 24 04 8c 01 00 	movl   $0x18c,0x4(%esp)
f01019b8:	00 
f01019b9:	c7 04 24 bb 57 10 f0 	movl   $0xf01057bb,(%esp)
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
f0101b2e:	c7 44 24 0c d5 58 10 	movl   $0xf01058d5,0xc(%esp)
f0101b35:	f0 
f0101b36:	c7 44 24 08 da 57 10 	movl   $0xf01057da,0x8(%esp)
f0101b3d:	f0 
f0101b3e:	c7 44 24 04 2f 03 00 	movl   $0x32f,0x4(%esp)
f0101b45:	00 
f0101b46:	c7 04 24 bb 57 10 f0 	movl   $0xf01057bb,(%esp)
f0101b4d:	e8 57 e5 ff ff       	call   f01000a9 <_panic>
	assert((pp1 = page_alloc(0)));
f0101b52:	c7 04 24 00 00 00 00 	movl   $0x0,(%esp)
f0101b59:	e8 bc f7 ff ff       	call   f010131a <page_alloc>
f0101b5e:	89 c3                	mov    %eax,%ebx
f0101b60:	85 c0                	test   %eax,%eax
f0101b62:	75 24                	jne    f0101b88 <check_page+0x76>
f0101b64:	c7 44 24 0c eb 58 10 	movl   $0xf01058eb,0xc(%esp)
f0101b6b:	f0 
f0101b6c:	c7 44 24 08 da 57 10 	movl   $0xf01057da,0x8(%esp)
f0101b73:	f0 
f0101b74:	c7 44 24 04 30 03 00 	movl   $0x330,0x4(%esp)
f0101b7b:	00 
f0101b7c:	c7 04 24 bb 57 10 f0 	movl   $0xf01057bb,(%esp)
f0101b83:	e8 21 e5 ff ff       	call   f01000a9 <_panic>
	assert((pp2 = page_alloc(0)));
f0101b88:	c7 04 24 00 00 00 00 	movl   $0x0,(%esp)
f0101b8f:	e8 86 f7 ff ff       	call   f010131a <page_alloc>
f0101b94:	89 c6                	mov    %eax,%esi
f0101b96:	85 c0                	test   %eax,%eax
f0101b98:	75 24                	jne    f0101bbe <check_page+0xac>
f0101b9a:	c7 44 24 0c 01 59 10 	movl   $0xf0105901,0xc(%esp)
f0101ba1:	f0 
f0101ba2:	c7 44 24 08 da 57 10 	movl   $0xf01057da,0x8(%esp)
f0101ba9:	f0 
f0101baa:	c7 44 24 04 31 03 00 	movl   $0x331,0x4(%esp)
f0101bb1:	00 
f0101bb2:	c7 04 24 bb 57 10 f0 	movl   $0xf01057bb,(%esp)
f0101bb9:	e8 eb e4 ff ff       	call   f01000a9 <_panic>

	assert(pp0);
	assert(pp1 && pp1 != pp0);
f0101bbe:	39 5d d4             	cmp    %ebx,-0x2c(%ebp)
f0101bc1:	75 24                	jne    f0101be7 <check_page+0xd5>
f0101bc3:	c7 44 24 0c 17 59 10 	movl   $0xf0105917,0xc(%esp)
f0101bca:	f0 
f0101bcb:	c7 44 24 08 da 57 10 	movl   $0xf01057da,0x8(%esp)
f0101bd2:	f0 
f0101bd3:	c7 44 24 04 34 03 00 	movl   $0x334,0x4(%esp)
f0101bda:	00 
f0101bdb:	c7 04 24 bb 57 10 f0 	movl   $0xf01057bb,(%esp)
f0101be2:	e8 c2 e4 ff ff       	call   f01000a9 <_panic>
	assert(pp2 && pp2 != pp1 && pp2 != pp0);
f0101be7:	39 c3                	cmp    %eax,%ebx
f0101be9:	74 05                	je     f0101bf0 <check_page+0xde>
f0101beb:	3b 45 d4             	cmp    -0x2c(%ebp),%eax
f0101bee:	75 24                	jne    f0101c14 <check_page+0x102>
f0101bf0:	c7 44 24 0c 80 52 10 	movl   $0xf0105280,0xc(%esp)
f0101bf7:	f0 
f0101bf8:	c7 44 24 08 da 57 10 	movl   $0xf01057da,0x8(%esp)
f0101bff:	f0 
f0101c00:	c7 44 24 04 35 03 00 	movl   $0x335,0x4(%esp)
f0101c07:	00 
f0101c08:	c7 04 24 bb 57 10 f0 	movl   $0xf01057bb,(%esp)
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
f0101c36:	c7 44 24 0c 80 59 10 	movl   $0xf0105980,0xc(%esp)
f0101c3d:	f0 
f0101c3e:	c7 44 24 08 da 57 10 	movl   $0xf01057da,0x8(%esp)
f0101c45:	f0 
f0101c46:	c7 44 24 04 3c 03 00 	movl   $0x33c,0x4(%esp)
f0101c4d:	00 
f0101c4e:	c7 04 24 bb 57 10 f0 	movl   $0xf01057bb,(%esp)
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
f0101c7a:	c7 44 24 0c c0 52 10 	movl   $0xf01052c0,0xc(%esp)
f0101c81:	f0 
f0101c82:	c7 44 24 08 da 57 10 	movl   $0xf01057da,0x8(%esp)
f0101c89:	f0 
f0101c8a:	c7 44 24 04 3f 03 00 	movl   $0x33f,0x4(%esp)
f0101c91:	00 
f0101c92:	c7 04 24 bb 57 10 f0 	movl   $0xf01057bb,(%esp)
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
f0101cc3:	c7 44 24 0c f8 52 10 	movl   $0xf01052f8,0xc(%esp)
f0101cca:	f0 
f0101ccb:	c7 44 24 08 da 57 10 	movl   $0xf01057da,0x8(%esp)
f0101cd2:	f0 
f0101cd3:	c7 44 24 04 42 03 00 	movl   $0x342,0x4(%esp)
f0101cda:	00 
f0101cdb:	c7 04 24 bb 57 10 f0 	movl   $0xf01057bb,(%esp)
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
f0101d17:	c7 44 24 0c 28 53 10 	movl   $0xf0105328,0xc(%esp)
f0101d1e:	f0 
f0101d1f:	c7 44 24 08 da 57 10 	movl   $0xf01057da,0x8(%esp)
f0101d26:	f0 
f0101d27:	c7 44 24 04 46 03 00 	movl   $0x346,0x4(%esp)
f0101d2e:	00 
f0101d2f:	c7 04 24 bb 57 10 f0 	movl   $0xf01057bb,(%esp)
f0101d36:	e8 6e e3 ff ff       	call   f01000a9 <_panic>
	assert(PTE_ADDR(kern_pgdir[0]) == page2pa(pp0));
f0101d3b:	8b 3d 88 6f 18 f0    	mov    0xf0186f88,%edi
f0101d41:	8b 45 d4             	mov    -0x2c(%ebp),%eax
f0101d44:	e8 4a ed ff ff       	call   f0100a93 <page2pa>
f0101d49:	8b 17                	mov    (%edi),%edx
f0101d4b:	81 e2 00 f0 ff ff    	and    $0xfffff000,%edx
f0101d51:	39 c2                	cmp    %eax,%edx
f0101d53:	74 24                	je     f0101d79 <check_page+0x267>
f0101d55:	c7 44 24 0c 58 53 10 	movl   $0xf0105358,0xc(%esp)
f0101d5c:	f0 
f0101d5d:	c7 44 24 08 da 57 10 	movl   $0xf01057da,0x8(%esp)
f0101d64:	f0 
f0101d65:	c7 44 24 04 47 03 00 	movl   $0x347,0x4(%esp)
f0101d6c:	00 
f0101d6d:	c7 04 24 bb 57 10 f0 	movl   $0xf01057bb,(%esp)
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
f0101d94:	c7 44 24 0c 80 53 10 	movl   $0xf0105380,0xc(%esp)
f0101d9b:	f0 
f0101d9c:	c7 44 24 08 da 57 10 	movl   $0xf01057da,0x8(%esp)
f0101da3:	f0 
f0101da4:	c7 44 24 04 48 03 00 	movl   $0x348,0x4(%esp)
f0101dab:	00 
f0101dac:	c7 04 24 bb 57 10 f0 	movl   $0xf01057bb,(%esp)
f0101db3:	e8 f1 e2 ff ff       	call   f01000a9 <_panic>
	assert(pp1->pp_ref == 1);
f0101db8:	66 83 7b 04 01       	cmpw   $0x1,0x4(%ebx)
f0101dbd:	74 24                	je     f0101de3 <check_page+0x2d1>
f0101dbf:	c7 44 24 0c 07 5a 10 	movl   $0xf0105a07,0xc(%esp)
f0101dc6:	f0 
f0101dc7:	c7 44 24 08 da 57 10 	movl   $0xf01057da,0x8(%esp)
f0101dce:	f0 
f0101dcf:	c7 44 24 04 49 03 00 	movl   $0x349,0x4(%esp)
f0101dd6:	00 
f0101dd7:	c7 04 24 bb 57 10 f0 	movl   $0xf01057bb,(%esp)
f0101dde:	e8 c6 e2 ff ff       	call   f01000a9 <_panic>
	assert(pp0->pp_ref == 1);
f0101de3:	8b 45 d4             	mov    -0x2c(%ebp),%eax
f0101de6:	66 83 78 04 01       	cmpw   $0x1,0x4(%eax)
f0101deb:	74 24                	je     f0101e11 <check_page+0x2ff>
f0101ded:	c7 44 24 0c 18 5a 10 	movl   $0xf0105a18,0xc(%esp)
f0101df4:	f0 
f0101df5:	c7 44 24 08 da 57 10 	movl   $0xf01057da,0x8(%esp)
f0101dfc:	f0 
f0101dfd:	c7 44 24 04 4a 03 00 	movl   $0x34a,0x4(%esp)
f0101e04:	00 
f0101e05:	c7 04 24 bb 57 10 f0 	movl   $0xf01057bb,(%esp)
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
f0101e31:	c7 44 24 0c b0 53 10 	movl   $0xf01053b0,0xc(%esp)
f0101e38:	f0 
f0101e39:	c7 44 24 08 da 57 10 	movl   $0xf01057da,0x8(%esp)
f0101e40:	f0 
f0101e41:	c7 44 24 04 4c 03 00 	movl   $0x34c,0x4(%esp)
f0101e48:	00 
f0101e49:	c7 04 24 bb 57 10 f0 	movl   $0xf01057bb,(%esp)
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
f0101e71:	c7 44 24 0c ec 53 10 	movl   $0xf01053ec,0xc(%esp)
f0101e78:	f0 
f0101e79:	c7 44 24 08 da 57 10 	movl   $0xf01057da,0x8(%esp)
f0101e80:	f0 
f0101e81:	c7 44 24 04 4d 03 00 	movl   $0x34d,0x4(%esp)
f0101e88:	00 
f0101e89:	c7 04 24 bb 57 10 f0 	movl   $0xf01057bb,(%esp)
f0101e90:	e8 14 e2 ff ff       	call   f01000a9 <_panic>
	assert(pp2->pp_ref == 1);
f0101e95:	66 83 7e 04 01       	cmpw   $0x1,0x4(%esi)
f0101e9a:	74 24                	je     f0101ec0 <check_page+0x3ae>
f0101e9c:	c7 44 24 0c 29 5a 10 	movl   $0xf0105a29,0xc(%esp)
f0101ea3:	f0 
f0101ea4:	c7 44 24 08 da 57 10 	movl   $0xf01057da,0x8(%esp)
f0101eab:	f0 
f0101eac:	c7 44 24 04 4e 03 00 	movl   $0x34e,0x4(%esp)
f0101eb3:	00 
f0101eb4:	c7 04 24 bb 57 10 f0 	movl   $0xf01057bb,(%esp)
f0101ebb:	e8 e9 e1 ff ff       	call   f01000a9 <_panic>

	// should be no free memory
	assert(!page_alloc(0));
f0101ec0:	c7 04 24 00 00 00 00 	movl   $0x0,(%esp)
f0101ec7:	e8 4e f4 ff ff       	call   f010131a <page_alloc>
f0101ecc:	85 c0                	test   %eax,%eax
f0101ece:	74 24                	je     f0101ef4 <check_page+0x3e2>
f0101ed0:	c7 44 24 0c 80 59 10 	movl   $0xf0105980,0xc(%esp)
f0101ed7:	f0 
f0101ed8:	c7 44 24 08 da 57 10 	movl   $0xf01057da,0x8(%esp)
f0101edf:	f0 
f0101ee0:	c7 44 24 04 51 03 00 	movl   $0x351,0x4(%esp)
f0101ee7:	00 
f0101ee8:	c7 04 24 bb 57 10 f0 	movl   $0xf01057bb,(%esp)
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
f0101f19:	c7 44 24 0c b0 53 10 	movl   $0xf01053b0,0xc(%esp)
f0101f20:	f0 
f0101f21:	c7 44 24 08 da 57 10 	movl   $0xf01057da,0x8(%esp)
f0101f28:	f0 
f0101f29:	c7 44 24 04 54 03 00 	movl   $0x354,0x4(%esp)
f0101f30:	00 
f0101f31:	c7 04 24 bb 57 10 f0 	movl   $0xf01057bb,(%esp)
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
f0101f59:	c7 44 24 0c ec 53 10 	movl   $0xf01053ec,0xc(%esp)
f0101f60:	f0 
f0101f61:	c7 44 24 08 da 57 10 	movl   $0xf01057da,0x8(%esp)
f0101f68:	f0 
f0101f69:	c7 44 24 04 55 03 00 	movl   $0x355,0x4(%esp)
f0101f70:	00 
f0101f71:	c7 04 24 bb 57 10 f0 	movl   $0xf01057bb,(%esp)
f0101f78:	e8 2c e1 ff ff       	call   f01000a9 <_panic>
	assert(pp2->pp_ref == 1);
f0101f7d:	66 83 7e 04 01       	cmpw   $0x1,0x4(%esi)
f0101f82:	74 24                	je     f0101fa8 <check_page+0x496>
f0101f84:	c7 44 24 0c 29 5a 10 	movl   $0xf0105a29,0xc(%esp)
f0101f8b:	f0 
f0101f8c:	c7 44 24 08 da 57 10 	movl   $0xf01057da,0x8(%esp)
f0101f93:	f0 
f0101f94:	c7 44 24 04 56 03 00 	movl   $0x356,0x4(%esp)
f0101f9b:	00 
f0101f9c:	c7 04 24 bb 57 10 f0 	movl   $0xf01057bb,(%esp)
f0101fa3:	e8 01 e1 ff ff       	call   f01000a9 <_panic>

	// pp2 should NOT be on the free list
	// could happen in ref counts are handled sloppily in page_insert
	assert(!page_alloc(0));
f0101fa8:	c7 04 24 00 00 00 00 	movl   $0x0,(%esp)
f0101faf:	e8 66 f3 ff ff       	call   f010131a <page_alloc>
f0101fb4:	85 c0                	test   %eax,%eax
f0101fb6:	74 24                	je     f0101fdc <check_page+0x4ca>
f0101fb8:	c7 44 24 0c 80 59 10 	movl   $0xf0105980,0xc(%esp)
f0101fbf:	f0 
f0101fc0:	c7 44 24 08 da 57 10 	movl   $0xf01057da,0x8(%esp)
f0101fc7:	f0 
f0101fc8:	c7 44 24 04 5a 03 00 	movl   $0x35a,0x4(%esp)
f0101fcf:	00 
f0101fd0:	c7 04 24 bb 57 10 f0 	movl   $0xf01057bb,(%esp)
f0101fd7:	e8 cd e0 ff ff       	call   f01000a9 <_panic>

	// check that pgdir_walk returns a pointer to the pte
	ptep = (pte_t *) KADDR(PTE_ADDR(kern_pgdir[PDX(PGSIZE)]));
f0101fdc:	8b 3d 88 6f 18 f0    	mov    0xf0186f88,%edi
f0101fe2:	8b 0f                	mov    (%edi),%ecx
f0101fe4:	81 e1 00 f0 ff ff    	and    $0xfffff000,%ecx
f0101fea:	ba 5d 03 00 00       	mov    $0x35d,%edx
f0101fef:	b8 bb 57 10 f0       	mov    $0xf01057bb,%eax
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
f010201e:	c7 44 24 0c 1c 54 10 	movl   $0xf010541c,0xc(%esp)
f0102025:	f0 
f0102026:	c7 44 24 08 da 57 10 	movl   $0xf01057da,0x8(%esp)
f010202d:	f0 
f010202e:	c7 44 24 04 5e 03 00 	movl   $0x35e,0x4(%esp)
f0102035:	00 
f0102036:	c7 04 24 bb 57 10 f0 	movl   $0xf01057bb,(%esp)
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
f0102067:	c7 44 24 0c 5c 54 10 	movl   $0xf010545c,0xc(%esp)
f010206e:	f0 
f010206f:	c7 44 24 08 da 57 10 	movl   $0xf01057da,0x8(%esp)
f0102076:	f0 
f0102077:	c7 44 24 04 61 03 00 	movl   $0x361,0x4(%esp)
f010207e:	00 
f010207f:	c7 04 24 bb 57 10 f0 	movl   $0xf01057bb,(%esp)
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
f01020ac:	c7 44 24 0c ec 53 10 	movl   $0xf01053ec,0xc(%esp)
f01020b3:	f0 
f01020b4:	c7 44 24 08 da 57 10 	movl   $0xf01057da,0x8(%esp)
f01020bb:	f0 
f01020bc:	c7 44 24 04 62 03 00 	movl   $0x362,0x4(%esp)
f01020c3:	00 
f01020c4:	c7 04 24 bb 57 10 f0 	movl   $0xf01057bb,(%esp)
f01020cb:	e8 d9 df ff ff       	call   f01000a9 <_panic>
	assert(pp2->pp_ref == 1);
f01020d0:	66 83 7e 04 01       	cmpw   $0x1,0x4(%esi)
f01020d5:	74 24                	je     f01020fb <check_page+0x5e9>
f01020d7:	c7 44 24 0c 29 5a 10 	movl   $0xf0105a29,0xc(%esp)
f01020de:	f0 
f01020df:	c7 44 24 08 da 57 10 	movl   $0xf01057da,0x8(%esp)
f01020e6:	f0 
f01020e7:	c7 44 24 04 63 03 00 	movl   $0x363,0x4(%esp)
f01020ee:	00 
f01020ef:	c7 04 24 bb 57 10 f0 	movl   $0xf01057bb,(%esp)
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
f0102118:	c7 44 24 0c 9c 54 10 	movl   $0xf010549c,0xc(%esp)
f010211f:	f0 
f0102120:	c7 44 24 08 da 57 10 	movl   $0xf01057da,0x8(%esp)
f0102127:	f0 
f0102128:	c7 44 24 04 64 03 00 	movl   $0x364,0x4(%esp)
f010212f:	00 
f0102130:	c7 04 24 bb 57 10 f0 	movl   $0xf01057bb,(%esp)
f0102137:	e8 6d df ff ff       	call   f01000a9 <_panic>
	assert(kern_pgdir[0] & PTE_U);
f010213c:	a1 88 6f 18 f0       	mov    0xf0186f88,%eax
f0102141:	f6 00 04             	testb  $0x4,(%eax)
f0102144:	75 24                	jne    f010216a <check_page+0x658>
f0102146:	c7 44 24 0c 3a 5a 10 	movl   $0xf0105a3a,0xc(%esp)
f010214d:	f0 
f010214e:	c7 44 24 08 da 57 10 	movl   $0xf01057da,0x8(%esp)
f0102155:	f0 
f0102156:	c7 44 24 04 65 03 00 	movl   $0x365,0x4(%esp)
f010215d:	00 
f010215e:	c7 04 24 bb 57 10 f0 	movl   $0xf01057bb,(%esp)
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
f010218a:	c7 44 24 0c b0 53 10 	movl   $0xf01053b0,0xc(%esp)
f0102191:	f0 
f0102192:	c7 44 24 08 da 57 10 	movl   $0xf01057da,0x8(%esp)
f0102199:	f0 
f010219a:	c7 44 24 04 68 03 00 	movl   $0x368,0x4(%esp)
f01021a1:	00 
f01021a2:	c7 04 24 bb 57 10 f0 	movl   $0xf01057bb,(%esp)
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
f01021d0:	c7 44 24 0c d0 54 10 	movl   $0xf01054d0,0xc(%esp)
f01021d7:	f0 
f01021d8:	c7 44 24 08 da 57 10 	movl   $0xf01057da,0x8(%esp)
f01021df:	f0 
f01021e0:	c7 44 24 04 69 03 00 	movl   $0x369,0x4(%esp)
f01021e7:	00 
f01021e8:	c7 04 24 bb 57 10 f0 	movl   $0xf01057bb,(%esp)
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
f0102216:	c7 44 24 0c 04 55 10 	movl   $0xf0105504,0xc(%esp)
f010221d:	f0 
f010221e:	c7 44 24 08 da 57 10 	movl   $0xf01057da,0x8(%esp)
f0102225:	f0 
f0102226:	c7 44 24 04 6a 03 00 	movl   $0x36a,0x4(%esp)
f010222d:	00 
f010222e:	c7 04 24 bb 57 10 f0 	movl   $0xf01057bb,(%esp)
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
f0102262:	c7 44 24 0c 3c 55 10 	movl   $0xf010553c,0xc(%esp)
f0102269:	f0 
f010226a:	c7 44 24 08 da 57 10 	movl   $0xf01057da,0x8(%esp)
f0102271:	f0 
f0102272:	c7 44 24 04 6d 03 00 	movl   $0x36d,0x4(%esp)
f0102279:	00 
f010227a:	c7 04 24 bb 57 10 f0 	movl   $0xf01057bb,(%esp)
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
f01022ab:	c7 44 24 0c 74 55 10 	movl   $0xf0105574,0xc(%esp)
f01022b2:	f0 
f01022b3:	c7 44 24 08 da 57 10 	movl   $0xf01057da,0x8(%esp)
f01022ba:	f0 
f01022bb:	c7 44 24 04 70 03 00 	movl   $0x370,0x4(%esp)
f01022c2:	00 
f01022c3:	c7 04 24 bb 57 10 f0 	movl   $0xf01057bb,(%esp)
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
f01022f1:	c7 44 24 0c 04 55 10 	movl   $0xf0105504,0xc(%esp)
f01022f8:	f0 
f01022f9:	c7 44 24 08 da 57 10 	movl   $0xf01057da,0x8(%esp)
f0102300:	f0 
f0102301:	c7 44 24 04 71 03 00 	movl   $0x371,0x4(%esp)
f0102308:	00 
f0102309:	c7 04 24 bb 57 10 f0 	movl   $0xf01057bb,(%esp)
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
f0102336:	c7 44 24 0c b0 55 10 	movl   $0xf01055b0,0xc(%esp)
f010233d:	f0 
f010233e:	c7 44 24 08 da 57 10 	movl   $0xf01057da,0x8(%esp)
f0102345:	f0 
f0102346:	c7 44 24 04 74 03 00 	movl   $0x374,0x4(%esp)
f010234d:	00 
f010234e:	c7 04 24 bb 57 10 f0 	movl   $0xf01057bb,(%esp)
f0102355:	e8 4f dd ff ff       	call   f01000a9 <_panic>
	assert(check_va2pa(kern_pgdir, PGSIZE) == page2pa(pp1));
f010235a:	ba 00 10 00 00       	mov    $0x1000,%edx
f010235f:	89 f8                	mov    %edi,%eax
f0102361:	e8 3b e8 ff ff       	call   f0100ba1 <check_va2pa>
f0102366:	39 45 d0             	cmp    %eax,-0x30(%ebp)
f0102369:	74 24                	je     f010238f <check_page+0x87d>
f010236b:	c7 44 24 0c dc 55 10 	movl   $0xf01055dc,0xc(%esp)
f0102372:	f0 
f0102373:	c7 44 24 08 da 57 10 	movl   $0xf01057da,0x8(%esp)
f010237a:	f0 
f010237b:	c7 44 24 04 75 03 00 	movl   $0x375,0x4(%esp)
f0102382:	00 
f0102383:	c7 04 24 bb 57 10 f0 	movl   $0xf01057bb,(%esp)
f010238a:	e8 1a dd ff ff       	call   f01000a9 <_panic>
	// ... and ref counts should reflect this
	assert(pp1->pp_ref == 2);
f010238f:	66 83 7b 04 02       	cmpw   $0x2,0x4(%ebx)
f0102394:	74 24                	je     f01023ba <check_page+0x8a8>
f0102396:	c7 44 24 0c 50 5a 10 	movl   $0xf0105a50,0xc(%esp)
f010239d:	f0 
f010239e:	c7 44 24 08 da 57 10 	movl   $0xf01057da,0x8(%esp)
f01023a5:	f0 
f01023a6:	c7 44 24 04 77 03 00 	movl   $0x377,0x4(%esp)
f01023ad:	00 
f01023ae:	c7 04 24 bb 57 10 f0 	movl   $0xf01057bb,(%esp)
f01023b5:	e8 ef dc ff ff       	call   f01000a9 <_panic>
	assert(pp2->pp_ref == 0);
f01023ba:	66 83 7e 04 00       	cmpw   $0x0,0x4(%esi)
f01023bf:	74 24                	je     f01023e5 <check_page+0x8d3>
f01023c1:	c7 44 24 0c 61 5a 10 	movl   $0xf0105a61,0xc(%esp)
f01023c8:	f0 
f01023c9:	c7 44 24 08 da 57 10 	movl   $0xf01057da,0x8(%esp)
f01023d0:	f0 
f01023d1:	c7 44 24 04 78 03 00 	movl   $0x378,0x4(%esp)
f01023d8:	00 
f01023d9:	c7 04 24 bb 57 10 f0 	movl   $0xf01057bb,(%esp)
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
f01023fb:	c7 44 24 0c 0c 56 10 	movl   $0xf010560c,0xc(%esp)
f0102402:	f0 
f0102403:	c7 44 24 08 da 57 10 	movl   $0xf01057da,0x8(%esp)
f010240a:	f0 
f010240b:	c7 44 24 04 7b 03 00 	movl   $0x37b,0x4(%esp)
f0102412:	00 
f0102413:	c7 04 24 bb 57 10 f0 	movl   $0xf01057bb,(%esp)
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
f010244b:	c7 44 24 0c 30 56 10 	movl   $0xf0105630,0xc(%esp)
f0102452:	f0 
f0102453:	c7 44 24 08 da 57 10 	movl   $0xf01057da,0x8(%esp)
f010245a:	f0 
f010245b:	c7 44 24 04 7f 03 00 	movl   $0x37f,0x4(%esp)
f0102462:	00 
f0102463:	c7 04 24 bb 57 10 f0 	movl   $0xf01057bb,(%esp)
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
f010248a:	c7 44 24 0c dc 55 10 	movl   $0xf01055dc,0xc(%esp)
f0102491:	f0 
f0102492:	c7 44 24 08 da 57 10 	movl   $0xf01057da,0x8(%esp)
f0102499:	f0 
f010249a:	c7 44 24 04 80 03 00 	movl   $0x380,0x4(%esp)
f01024a1:	00 
f01024a2:	c7 04 24 bb 57 10 f0 	movl   $0xf01057bb,(%esp)
f01024a9:	e8 fb db ff ff       	call   f01000a9 <_panic>
	assert(pp1->pp_ref == 1);
f01024ae:	66 83 7b 04 01       	cmpw   $0x1,0x4(%ebx)
f01024b3:	74 24                	je     f01024d9 <check_page+0x9c7>
f01024b5:	c7 44 24 0c 07 5a 10 	movl   $0xf0105a07,0xc(%esp)
f01024bc:	f0 
f01024bd:	c7 44 24 08 da 57 10 	movl   $0xf01057da,0x8(%esp)
f01024c4:	f0 
f01024c5:	c7 44 24 04 81 03 00 	movl   $0x381,0x4(%esp)
f01024cc:	00 
f01024cd:	c7 04 24 bb 57 10 f0 	movl   $0xf01057bb,(%esp)
f01024d4:	e8 d0 db ff ff       	call   f01000a9 <_panic>
	assert(pp2->pp_ref == 0);
f01024d9:	66 83 7f 04 00       	cmpw   $0x0,0x4(%edi)
f01024de:	74 24                	je     f0102504 <check_page+0x9f2>
f01024e0:	c7 44 24 0c 61 5a 10 	movl   $0xf0105a61,0xc(%esp)
f01024e7:	f0 
f01024e8:	c7 44 24 08 da 57 10 	movl   $0xf01057da,0x8(%esp)
f01024ef:	f0 
f01024f0:	c7 44 24 04 82 03 00 	movl   $0x382,0x4(%esp)
f01024f7:	00 
f01024f8:	c7 04 24 bb 57 10 f0 	movl   $0xf01057bb,(%esp)
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
f0102524:	c7 44 24 0c 54 56 10 	movl   $0xf0105654,0xc(%esp)
f010252b:	f0 
f010252c:	c7 44 24 08 da 57 10 	movl   $0xf01057da,0x8(%esp)
f0102533:	f0 
f0102534:	c7 44 24 04 85 03 00 	movl   $0x385,0x4(%esp)
f010253b:	00 
f010253c:	c7 04 24 bb 57 10 f0 	movl   $0xf01057bb,(%esp)
f0102543:	e8 61 db ff ff       	call   f01000a9 <_panic>
	assert(pp1->pp_ref);
f0102548:	66 83 7b 04 00       	cmpw   $0x0,0x4(%ebx)
f010254d:	75 24                	jne    f0102573 <check_page+0xa61>
f010254f:	c7 44 24 0c 72 5a 10 	movl   $0xf0105a72,0xc(%esp)
f0102556:	f0 
f0102557:	c7 44 24 08 da 57 10 	movl   $0xf01057da,0x8(%esp)
f010255e:	f0 
f010255f:	c7 44 24 04 86 03 00 	movl   $0x386,0x4(%esp)
f0102566:	00 
f0102567:	c7 04 24 bb 57 10 f0 	movl   $0xf01057bb,(%esp)
f010256e:	e8 36 db ff ff       	call   f01000a9 <_panic>
	assert(pp1->pp_link == NULL);
f0102573:	83 3b 00             	cmpl   $0x0,(%ebx)
f0102576:	74 24                	je     f010259c <check_page+0xa8a>
f0102578:	c7 44 24 0c 7e 5a 10 	movl   $0xf0105a7e,0xc(%esp)
f010257f:	f0 
f0102580:	c7 44 24 08 da 57 10 	movl   $0xf01057da,0x8(%esp)
f0102587:	f0 
f0102588:	c7 44 24 04 87 03 00 	movl   $0x387,0x4(%esp)
f010258f:	00 
f0102590:	c7 04 24 bb 57 10 f0 	movl   $0xf01057bb,(%esp)
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
f01025c8:	c7 44 24 0c 30 56 10 	movl   $0xf0105630,0xc(%esp)
f01025cf:	f0 
f01025d0:	c7 44 24 08 da 57 10 	movl   $0xf01057da,0x8(%esp)
f01025d7:	f0 
f01025d8:	c7 44 24 04 8b 03 00 	movl   $0x38b,0x4(%esp)
f01025df:	00 
f01025e0:	c7 04 24 bb 57 10 f0 	movl   $0xf01057bb,(%esp)
f01025e7:	e8 bd da ff ff       	call   f01000a9 <_panic>
	assert(check_va2pa(kern_pgdir, PGSIZE) == ~0);
f01025ec:	ba 00 10 00 00       	mov    $0x1000,%edx
f01025f1:	89 f0                	mov    %esi,%eax
f01025f3:	e8 a9 e5 ff ff       	call   f0100ba1 <check_va2pa>
f01025f8:	83 f8 ff             	cmp    $0xffffffff,%eax
f01025fb:	74 24                	je     f0102621 <check_page+0xb0f>
f01025fd:	c7 44 24 0c 8c 56 10 	movl   $0xf010568c,0xc(%esp)
f0102604:	f0 
f0102605:	c7 44 24 08 da 57 10 	movl   $0xf01057da,0x8(%esp)
f010260c:	f0 
f010260d:	c7 44 24 04 8c 03 00 	movl   $0x38c,0x4(%esp)
f0102614:	00 
f0102615:	c7 04 24 bb 57 10 f0 	movl   $0xf01057bb,(%esp)
f010261c:	e8 88 da ff ff       	call   f01000a9 <_panic>
	assert(pp1->pp_ref == 0);
f0102621:	66 83 7b 04 00       	cmpw   $0x0,0x4(%ebx)
f0102626:	74 24                	je     f010264c <check_page+0xb3a>
f0102628:	c7 44 24 0c 93 5a 10 	movl   $0xf0105a93,0xc(%esp)
f010262f:	f0 
f0102630:	c7 44 24 08 da 57 10 	movl   $0xf01057da,0x8(%esp)
f0102637:	f0 
f0102638:	c7 44 24 04 8d 03 00 	movl   $0x38d,0x4(%esp)
f010263f:	00 
f0102640:	c7 04 24 bb 57 10 f0 	movl   $0xf01057bb,(%esp)
f0102647:	e8 5d da ff ff       	call   f01000a9 <_panic>
	assert(pp2->pp_ref == 0);
f010264c:	66 83 7f 04 00       	cmpw   $0x0,0x4(%edi)
f0102651:	74 24                	je     f0102677 <check_page+0xb65>
f0102653:	c7 44 24 0c 61 5a 10 	movl   $0xf0105a61,0xc(%esp)
f010265a:	f0 
f010265b:	c7 44 24 08 da 57 10 	movl   $0xf01057da,0x8(%esp)
f0102662:	f0 
f0102663:	c7 44 24 04 8e 03 00 	movl   $0x38e,0x4(%esp)
f010266a:	00 
f010266b:	c7 04 24 bb 57 10 f0 	movl   $0xf01057bb,(%esp)
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
f010268d:	c7 44 24 0c b4 56 10 	movl   $0xf01056b4,0xc(%esp)
f0102694:	f0 
f0102695:	c7 44 24 08 da 57 10 	movl   $0xf01057da,0x8(%esp)
f010269c:	f0 
f010269d:	c7 44 24 04 91 03 00 	movl   $0x391,0x4(%esp)
f01026a4:	00 
f01026a5:	c7 04 24 bb 57 10 f0 	movl   $0xf01057bb,(%esp)
f01026ac:	e8 f8 d9 ff ff       	call   f01000a9 <_panic>

	// should be no free memory
	assert(!page_alloc(0));
f01026b1:	c7 04 24 00 00 00 00 	movl   $0x0,(%esp)
f01026b8:	e8 5d ec ff ff       	call   f010131a <page_alloc>
f01026bd:	85 c0                	test   %eax,%eax
f01026bf:	74 24                	je     f01026e5 <check_page+0xbd3>
f01026c1:	c7 44 24 0c 80 59 10 	movl   $0xf0105980,0xc(%esp)
f01026c8:	f0 
f01026c9:	c7 44 24 08 da 57 10 	movl   $0xf01057da,0x8(%esp)
f01026d0:	f0 
f01026d1:	c7 44 24 04 94 03 00 	movl   $0x394,0x4(%esp)
f01026d8:	00 
f01026d9:	c7 04 24 bb 57 10 f0 	movl   $0xf01057bb,(%esp)
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
f01026ff:	c7 44 24 0c 58 53 10 	movl   $0xf0105358,0xc(%esp)
f0102706:	f0 
f0102707:	c7 44 24 08 da 57 10 	movl   $0xf01057da,0x8(%esp)
f010270e:	f0 
f010270f:	c7 44 24 04 97 03 00 	movl   $0x397,0x4(%esp)
f0102716:	00 
f0102717:	c7 04 24 bb 57 10 f0 	movl   $0xf01057bb,(%esp)
f010271e:	e8 86 d9 ff ff       	call   f01000a9 <_panic>
	kern_pgdir[0] = 0;
f0102723:	c7 03 00 00 00 00    	movl   $0x0,(%ebx)
	assert(pp0->pp_ref == 1);
f0102729:	8b 45 d4             	mov    -0x2c(%ebp),%eax
f010272c:	66 83 78 04 01       	cmpw   $0x1,0x4(%eax)
f0102731:	74 24                	je     f0102757 <check_page+0xc45>
f0102733:	c7 44 24 0c 18 5a 10 	movl   $0xf0105a18,0xc(%esp)
f010273a:	f0 
f010273b:	c7 44 24 08 da 57 10 	movl   $0xf01057da,0x8(%esp)
f0102742:	f0 
f0102743:	c7 44 24 04 99 03 00 	movl   $0x399,0x4(%esp)
f010274a:	00 
f010274b:	c7 04 24 bb 57 10 f0 	movl   $0xf01057bb,(%esp)
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
f010279f:	b8 bb 57 10 f0       	mov    $0xf01057bb,%eax
f01027a4:	e8 a2 e3 ff ff       	call   f0100b4b <_kaddr>
	assert(ptep == ptep1 + PTX(va));
f01027a9:	83 c0 04             	add    $0x4,%eax
f01027ac:	39 45 d0             	cmp    %eax,-0x30(%ebp)
f01027af:	74 24                	je     f01027d5 <check_page+0xcc3>
f01027b1:	c7 44 24 0c a4 5a 10 	movl   $0xf0105aa4,0xc(%esp)
f01027b8:	f0 
f01027b9:	c7 44 24 08 da 57 10 	movl   $0xf01057da,0x8(%esp)
f01027c0:	f0 
f01027c1:	c7 44 24 04 a1 03 00 	movl   $0x3a1,0x4(%esp)
f01027c8:	00 
f01027c9:	c7 04 24 bb 57 10 f0 	movl   $0xf01057bb,(%esp)
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
f01027ff:	e8 d3 1d 00 00       	call   f01045d7 <memset>
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
f010283e:	c7 44 24 0c bc 5a 10 	movl   $0xf0105abc,0xc(%esp)
f0102845:	f0 
f0102846:	c7 44 24 08 da 57 10 	movl   $0xf01057da,0x8(%esp)
f010284d:	f0 
f010284e:	c7 44 24 04 ab 03 00 	movl   $0x3ab,0x4(%esp)
f0102855:	00 
f0102856:	c7 04 24 bb 57 10 f0 	movl   $0xf01057bb,(%esp)
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
f01028a2:	c7 04 24 d3 5a 10 f0 	movl   $0xf0105ad3,(%esp)
f01028a9:	e8 6a 0d 00 00       	call   f0103618 <cprintf>
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
f01028d1:	c7 44 24 0c d5 58 10 	movl   $0xf01058d5,0xc(%esp)
f01028d8:	f0 
f01028d9:	c7 44 24 08 da 57 10 	movl   $0xf01057da,0x8(%esp)
f01028e0:	f0 
f01028e1:	c7 44 24 04 c6 03 00 	movl   $0x3c6,0x4(%esp)
f01028e8:	00 
f01028e9:	c7 04 24 bb 57 10 f0 	movl   $0xf01057bb,(%esp)
f01028f0:	e8 b4 d7 ff ff       	call   f01000a9 <_panic>
	assert((pp1 = page_alloc(0)));
f01028f5:	c7 04 24 00 00 00 00 	movl   $0x0,(%esp)
f01028fc:	e8 19 ea ff ff       	call   f010131a <page_alloc>
f0102901:	89 c7                	mov    %eax,%edi
f0102903:	85 c0                	test   %eax,%eax
f0102905:	75 24                	jne    f010292b <check_page_installed_pgdir+0x75>
f0102907:	c7 44 24 0c eb 58 10 	movl   $0xf01058eb,0xc(%esp)
f010290e:	f0 
f010290f:	c7 44 24 08 da 57 10 	movl   $0xf01057da,0x8(%esp)
f0102916:	f0 
f0102917:	c7 44 24 04 c7 03 00 	movl   $0x3c7,0x4(%esp)
f010291e:	00 
f010291f:	c7 04 24 bb 57 10 f0 	movl   $0xf01057bb,(%esp)
f0102926:	e8 7e d7 ff ff       	call   f01000a9 <_panic>
	assert((pp2 = page_alloc(0)));
f010292b:	c7 04 24 00 00 00 00 	movl   $0x0,(%esp)
f0102932:	e8 e3 e9 ff ff       	call   f010131a <page_alloc>
f0102937:	89 c3                	mov    %eax,%ebx
f0102939:	85 c0                	test   %eax,%eax
f010293b:	75 24                	jne    f0102961 <check_page_installed_pgdir+0xab>
f010293d:	c7 44 24 0c 01 59 10 	movl   $0xf0105901,0xc(%esp)
f0102944:	f0 
f0102945:	c7 44 24 08 da 57 10 	movl   $0xf01057da,0x8(%esp)
f010294c:	f0 
f010294d:	c7 44 24 04 c8 03 00 	movl   $0x3c8,0x4(%esp)
f0102954:	00 
f0102955:	c7 04 24 bb 57 10 f0 	movl   $0xf01057bb,(%esp)
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
f0102983:	e8 4f 1c 00 00       	call   f01045d7 <memset>
	memset(page2kva(pp2), 2, PGSIZE);
f0102988:	89 d8                	mov    %ebx,%eax
f010298a:	e8 f4 e1 ff ff       	call   f0100b83 <page2kva>
f010298f:	c7 44 24 08 00 10 00 	movl   $0x1000,0x8(%esp)
f0102996:	00 
f0102997:	c7 44 24 04 02 00 00 	movl   $0x2,0x4(%esp)
f010299e:	00 
f010299f:	89 04 24             	mov    %eax,(%esp)
f01029a2:	e8 30 1c 00 00       	call   f01045d7 <memset>
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
f01029cf:	c7 44 24 0c 07 5a 10 	movl   $0xf0105a07,0xc(%esp)
f01029d6:	f0 
f01029d7:	c7 44 24 08 da 57 10 	movl   $0xf01057da,0x8(%esp)
f01029de:	f0 
f01029df:	c7 44 24 04 cd 03 00 	movl   $0x3cd,0x4(%esp)
f01029e6:	00 
f01029e7:	c7 04 24 bb 57 10 f0 	movl   $0xf01057bb,(%esp)
f01029ee:	e8 b6 d6 ff ff       	call   f01000a9 <_panic>
	assert(*(uint32_t *)PGSIZE == 0x01010101U);
f01029f3:	81 3d 00 10 00 00 01 	cmpl   $0x1010101,0x1000
f01029fa:	01 01 01 
f01029fd:	74 24                	je     f0102a23 <check_page_installed_pgdir+0x16d>
f01029ff:	c7 44 24 0c d8 56 10 	movl   $0xf01056d8,0xc(%esp)
f0102a06:	f0 
f0102a07:	c7 44 24 08 da 57 10 	movl   $0xf01057da,0x8(%esp)
f0102a0e:	f0 
f0102a0f:	c7 44 24 04 ce 03 00 	movl   $0x3ce,0x4(%esp)
f0102a16:	00 
f0102a17:	c7 04 24 bb 57 10 f0 	movl   $0xf01057bb,(%esp)
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
f0102a50:	c7 44 24 0c fc 56 10 	movl   $0xf01056fc,0xc(%esp)
f0102a57:	f0 
f0102a58:	c7 44 24 08 da 57 10 	movl   $0xf01057da,0x8(%esp)
f0102a5f:	f0 
f0102a60:	c7 44 24 04 d0 03 00 	movl   $0x3d0,0x4(%esp)
f0102a67:	00 
f0102a68:	c7 04 24 bb 57 10 f0 	movl   $0xf01057bb,(%esp)
f0102a6f:	e8 35 d6 ff ff       	call   f01000a9 <_panic>
	assert(pp2->pp_ref == 1);
f0102a74:	66 83 7b 04 01       	cmpw   $0x1,0x4(%ebx)
f0102a79:	74 24                	je     f0102a9f <check_page_installed_pgdir+0x1e9>
f0102a7b:	c7 44 24 0c 29 5a 10 	movl   $0xf0105a29,0xc(%esp)
f0102a82:	f0 
f0102a83:	c7 44 24 08 da 57 10 	movl   $0xf01057da,0x8(%esp)
f0102a8a:	f0 
f0102a8b:	c7 44 24 04 d1 03 00 	movl   $0x3d1,0x4(%esp)
f0102a92:	00 
f0102a93:	c7 04 24 bb 57 10 f0 	movl   $0xf01057bb,(%esp)
f0102a9a:	e8 0a d6 ff ff       	call   f01000a9 <_panic>
	assert(pp1->pp_ref == 0);
f0102a9f:	66 83 7f 04 00       	cmpw   $0x0,0x4(%edi)
f0102aa4:	74 24                	je     f0102aca <check_page_installed_pgdir+0x214>
f0102aa6:	c7 44 24 0c 93 5a 10 	movl   $0xf0105a93,0xc(%esp)
f0102aad:	f0 
f0102aae:	c7 44 24 08 da 57 10 	movl   $0xf01057da,0x8(%esp)
f0102ab5:	f0 
f0102ab6:	c7 44 24 04 d2 03 00 	movl   $0x3d2,0x4(%esp)
f0102abd:	00 
f0102abe:	c7 04 24 bb 57 10 f0 	movl   $0xf01057bb,(%esp)
f0102ac5:	e8 df d5 ff ff       	call   f01000a9 <_panic>
	*(uint32_t *)PGSIZE = 0x03030303U;
f0102aca:	c7 05 00 10 00 00 03 	movl   $0x3030303,0x1000
f0102ad1:	03 03 03 
	assert(*(uint32_t *)page2kva(pp2) == 0x03030303U);
f0102ad4:	89 d8                	mov    %ebx,%eax
f0102ad6:	e8 a8 e0 ff ff       	call   f0100b83 <page2kva>
f0102adb:	81 38 03 03 03 03    	cmpl   $0x3030303,(%eax)
f0102ae1:	74 24                	je     f0102b07 <check_page_installed_pgdir+0x251>
f0102ae3:	c7 44 24 0c 20 57 10 	movl   $0xf0105720,0xc(%esp)
f0102aea:	f0 
f0102aeb:	c7 44 24 08 da 57 10 	movl   $0xf01057da,0x8(%esp)
f0102af2:	f0 
f0102af3:	c7 44 24 04 d4 03 00 	movl   $0x3d4,0x4(%esp)
f0102afa:	00 
f0102afb:	c7 04 24 bb 57 10 f0 	movl   $0xf01057bb,(%esp)
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
f0102b23:	c7 44 24 0c 61 5a 10 	movl   $0xf0105a61,0xc(%esp)
f0102b2a:	f0 
f0102b2b:	c7 44 24 08 da 57 10 	movl   $0xf01057da,0x8(%esp)
f0102b32:	f0 
f0102b33:	c7 44 24 04 d6 03 00 	movl   $0x3d6,0x4(%esp)
f0102b3a:	00 
f0102b3b:	c7 04 24 bb 57 10 f0 	movl   $0xf01057bb,(%esp)
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
f0102b60:	c7 44 24 0c 58 53 10 	movl   $0xf0105358,0xc(%esp)
f0102b67:	f0 
f0102b68:	c7 44 24 08 da 57 10 	movl   $0xf01057da,0x8(%esp)
f0102b6f:	f0 
f0102b70:	c7 44 24 04 d9 03 00 	movl   $0x3d9,0x4(%esp)
f0102b77:	00 
f0102b78:	c7 04 24 bb 57 10 f0 	movl   $0xf01057bb,(%esp)
f0102b7f:	e8 25 d5 ff ff       	call   f01000a9 <_panic>
	kern_pgdir[0] = 0;
f0102b84:	c7 03 00 00 00 00    	movl   $0x0,(%ebx)
	assert(pp0->pp_ref == 1);
f0102b8a:	66 83 7e 04 01       	cmpw   $0x1,0x4(%esi)
f0102b8f:	74 24                	je     f0102bb5 <check_page_installed_pgdir+0x2ff>
f0102b91:	c7 44 24 0c 18 5a 10 	movl   $0xf0105a18,0xc(%esp)
f0102b98:	f0 
f0102b99:	c7 44 24 08 da 57 10 	movl   $0xf01057da,0x8(%esp)
f0102ba0:	f0 
f0102ba1:	c7 44 24 04 db 03 00 	movl   $0x3db,0x4(%esp)
f0102ba8:	00 
f0102ba9:	c7 04 24 bb 57 10 f0 	movl   $0xf01057bb,(%esp)
f0102bb0:	e8 f4 d4 ff ff       	call   f01000a9 <_panic>
	pp0->pp_ref = 0;
f0102bb5:	66 c7 46 04 00 00    	movw   $0x0,0x4(%esi)

	// free the pages we took
	page_free(pp0);
f0102bbb:	89 34 24             	mov    %esi,(%esp)
f0102bbe:	e8 a9 e7 ff ff       	call   f010136c <page_free>

	cprintf("check_page_installed_pgdir() succeeded!\n");
f0102bc3:	c7 04 24 4c 57 10 f0 	movl   $0xf010574c,(%esp)
f0102bca:	e8 49 0a 00 00       	call   f0103618 <cprintf>
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
f0102c05:	e8 cd 19 00 00       	call   f01045d7 <memset>
	// a virtual page table at virtual address UVPT.
	// (For now, you don't have understand the greater purpose of the
	// following line.)

	// Permissions: kernel R, user R
	kern_pgdir[PDX(UVPT)] = PADDR(kern_pgdir) | PTE_U | PTE_P;
f0102c0a:	8b 1d 88 6f 18 f0    	mov    0xf0186f88,%ebx
f0102c10:	89 d9                	mov    %ebx,%ecx
f0102c12:	ba 93 00 00 00       	mov    $0x93,%edx
f0102c17:	b8 bb 57 10 f0       	mov    $0xf01057bb,%eax
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
f0102c58:	e8 7a 19 00 00       	call   f01045d7 <memset>
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
f0102c7f:	e8 53 19 00 00       	call   f01045d7 <memset>
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
f0102ca8:	b8 bb 57 10 f0       	mov    $0xf01057bb,%eax
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
f0102ce4:	b8 bb 57 10 f0       	mov    $0xf01057bb,%eax
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
f0102d17:	b8 bb 57 10 f0       	mov    $0xf01057bb,%eax
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
f0102d73:	b8 bb 57 10 f0       	mov    $0xf01057bb,%eax
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
f0102df0:	c7 04 24 78 57 10 f0 	movl   $0xf0105778,(%esp)
f0102df7:	e8 1c 08 00 00       	call   f0103618 <cprintf>
			"va %08x\n", env->env_id, user_mem_check_addr);
		env_destroy(env);	// may not return
f0102dfc:	89 1c 24             	mov    %ebx,(%esp)
f0102dff:	e8 bb 06 00 00       	call   f01034bf <env_destroy>
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

f0102e22 <page2pa>:
int	user_mem_check(struct Env *env, const void *va, size_t len, int perm);
void	user_mem_assert(struct Env *env, const void *va, size_t len, int perm);

static inline physaddr_t
page2pa(struct PageInfo *pp)
{
f0102e22:	55                   	push   %ebp
f0102e23:	89 e5                	mov    %esp,%ebp
	return (pp - pages) << PGSHIFT;
f0102e25:	2b 05 8c 6f 18 f0    	sub    0xf0186f8c,%eax
f0102e2b:	c1 f8 03             	sar    $0x3,%eax
f0102e2e:	c1 e0 0c             	shl    $0xc,%eax
}
f0102e31:	5d                   	pop    %ebp
f0102e32:	c3                   	ret    

f0102e33 <_kaddr>:
 * virtual address.  It panics if you pass an invalid physical address. */
#define KADDR(pa) _kaddr(__FILE__, __LINE__, pa)

static inline void*
_kaddr(const char *file, int line, physaddr_t pa)
{
f0102e33:	55                   	push   %ebp
f0102e34:	89 e5                	mov    %esp,%ebp
f0102e36:	53                   	push   %ebx
f0102e37:	83 ec 04             	sub    $0x4,%esp
	if (PGNUM(pa) >= npages)
f0102e3a:	89 cb                	mov    %ecx,%ebx
f0102e3c:	c1 eb 0c             	shr    $0xc,%ebx
f0102e3f:	3b 1d 84 6f 18 f0    	cmp    0xf0186f84,%ebx
f0102e45:	72 0d                	jb     f0102e54 <_kaddr+0x21>
		_panic(file, line, "KADDR called with invalid pa %08lx", pa);
f0102e47:	51                   	push   %ecx
f0102e48:	68 00 50 10 f0       	push   $0xf0105000
f0102e4d:	52                   	push   %edx
f0102e4e:	50                   	push   %eax
f0102e4f:	e8 55 d2 ff ff       	call   f01000a9 <_panic>
	return (void *)(pa + KERNBASE);
f0102e54:	8d 81 00 00 00 f0    	lea    -0x10000000(%ecx),%eax
}
f0102e5a:	8b 5d fc             	mov    -0x4(%ebp),%ebx
f0102e5d:	c9                   	leave  
f0102e5e:	c3                   	ret    

f0102e5f <page2kva>:
	return &pages[PGNUM(pa)];
}

static inline void*
page2kva(struct PageInfo *pp)
{
f0102e5f:	55                   	push   %ebp
f0102e60:	89 e5                	mov    %esp,%ebp
f0102e62:	83 ec 08             	sub    $0x8,%esp
	return KADDR(page2pa(pp));
f0102e65:	e8 b8 ff ff ff       	call   f0102e22 <page2pa>
f0102e6a:	89 c1                	mov    %eax,%ecx
f0102e6c:	ba 56 00 00 00       	mov    $0x56,%edx
f0102e71:	b8 ad 57 10 f0       	mov    $0xf01057ad,%eax
f0102e76:	e8 b8 ff ff ff       	call   f0102e33 <_kaddr>
}
f0102e7b:	c9                   	leave  
f0102e7c:	c3                   	ret    

f0102e7d <_paddr>:
#define PADDR(kva) _paddr(__FILE__, __LINE__, kva)

static inline physaddr_t
_paddr(const char *file, int line, void *kva)
{
	if ((uint32_t)kva < KERNBASE)
f0102e7d:	81 f9 ff ff ff ef    	cmp    $0xefffffff,%ecx
f0102e83:	77 13                	ja     f0102e98 <_paddr+0x1b>
 */
#define PADDR(kva) _paddr(__FILE__, __LINE__, kva)

static inline physaddr_t
_paddr(const char *file, int line, void *kva)
{
f0102e85:	55                   	push   %ebp
f0102e86:	89 e5                	mov    %esp,%ebp
f0102e88:	83 ec 08             	sub    $0x8,%esp
	if ((uint32_t)kva < KERNBASE)
		_panic(file, line, "PADDR called with invalid kva %08lx", kva);
f0102e8b:	51                   	push   %ecx
f0102e8c:	68 24 50 10 f0       	push   $0xf0105024
f0102e91:	52                   	push   %edx
f0102e92:	50                   	push   %eax
f0102e93:	e8 11 d2 ff ff       	call   f01000a9 <_panic>
	return (physaddr_t)kva - KERNBASE;
f0102e98:	8d 81 00 00 00 10    	lea    0x10000000(%ecx),%eax
}
f0102e9e:	c3                   	ret    

f0102e9f <env_setup_vm>:
// Returns 0 on success, < 0 on error.  Errors include:
//	-E_NO_MEM if page directory or table could not be allocated.
//
static int
env_setup_vm(struct Env *e)
{
f0102e9f:	55                   	push   %ebp
f0102ea0:	89 e5                	mov    %esp,%ebp
f0102ea2:	56                   	push   %esi
f0102ea3:	53                   	push   %ebx
f0102ea4:	89 c6                	mov    %eax,%esi
	int i;
	struct PageInfo *p = NULL;

	// Allocate a page for the page directory
	if (!(p = page_alloc(ALLOC_ZERO)))
f0102ea6:	83 ec 0c             	sub    $0xc,%esp
f0102ea9:	6a 01                	push   $0x1
f0102eab:	e8 6a e4 ff ff       	call   f010131a <page_alloc>
f0102eb0:	83 c4 10             	add    $0x10,%esp
f0102eb3:	85 c0                	test   %eax,%eax
f0102eb5:	74 4a                	je     f0102f01 <env_setup_vm+0x62>
f0102eb7:	89 c3                	mov    %eax,%ebx
	//	physical pages mapped only above UTOP, but env_pgdir
	//	is an exception -- you need to increment env_pgdir's
	//	pp_ref for env_free to work correctly.
	//    - The functions in kern/pmap.h are handy.
	
	e->env_pgdir = page2kva(p);
f0102eb9:	e8 a1 ff ff ff       	call   f0102e5f <page2kva>
f0102ebe:	89 46 5c             	mov    %eax,0x5c(%esi)
	memcpy(e->env_pgdir, kern_pgdir, PGSIZE);
f0102ec1:	83 ec 04             	sub    $0x4,%esp
f0102ec4:	68 00 10 00 00       	push   $0x1000
f0102ec9:	ff 35 88 6f 18 f0    	pushl  0xf0186f88
f0102ecf:	50                   	push   %eax
f0102ed0:	e8 b8 17 00 00       	call   f010468d <memcpy>
	p->pp_ref ++;
f0102ed5:	66 83 43 04 01       	addw   $0x1,0x4(%ebx)
	
	// LAB 3: Your code here.

	// UVPT maps the env's own page table read-only.
	// Permissions: kernel R, user R
	e->env_pgdir[PDX(UVPT)] = PADDR(e->env_pgdir) | PTE_P | PTE_U;
f0102eda:	8b 5e 5c             	mov    0x5c(%esi),%ebx
f0102edd:	89 d9                	mov    %ebx,%ecx
f0102edf:	ba c0 00 00 00       	mov    $0xc0,%edx
f0102ee4:	b8 4c 5b 10 f0       	mov    $0xf0105b4c,%eax
f0102ee9:	e8 8f ff ff ff       	call   f0102e7d <_paddr>
f0102eee:	83 c8 05             	or     $0x5,%eax
f0102ef1:	89 83 f4 0e 00 00    	mov    %eax,0xef4(%ebx)

	return 0;
f0102ef7:	83 c4 10             	add    $0x10,%esp
f0102efa:	b8 00 00 00 00       	mov    $0x0,%eax
f0102eff:	eb 05                	jmp    f0102f06 <env_setup_vm+0x67>
	int i;
	struct PageInfo *p = NULL;

	// Allocate a page for the page directory
	if (!(p = page_alloc(ALLOC_ZERO)))
		return -E_NO_MEM;
f0102f01:	b8 fc ff ff ff       	mov    $0xfffffffc,%eax
	// UVPT maps the env's own page table read-only.
	// Permissions: kernel R, user R
	e->env_pgdir[PDX(UVPT)] = PADDR(e->env_pgdir) | PTE_P | PTE_U;

	return 0;
}
f0102f06:	8d 65 f8             	lea    -0x8(%ebp),%esp
f0102f09:	5b                   	pop    %ebx
f0102f0a:	5e                   	pop    %esi
f0102f0b:	5d                   	pop    %ebp
f0102f0c:	c3                   	ret    

f0102f0d <pa2page>:
}

static inline struct PageInfo*
pa2page(physaddr_t pa)
{
	if (PGNUM(pa) >= npages)
f0102f0d:	c1 e8 0c             	shr    $0xc,%eax
f0102f10:	3b 05 84 6f 18 f0    	cmp    0xf0186f84,%eax
f0102f16:	72 17                	jb     f0102f2f <pa2page+0x22>
	return (pp - pages) << PGSHIFT;
}

static inline struct PageInfo*
pa2page(physaddr_t pa)
{
f0102f18:	55                   	push   %ebp
f0102f19:	89 e5                	mov    %esp,%ebp
f0102f1b:	83 ec 0c             	sub    $0xc,%esp
	if (PGNUM(pa) >= npages)
		panic("pa2page called with invalid pa");
f0102f1e:	68 34 52 10 f0       	push   $0xf0105234
f0102f23:	6a 4f                	push   $0x4f
f0102f25:	68 ad 57 10 f0       	push   $0xf01057ad
f0102f2a:	e8 7a d1 ff ff       	call   f01000a9 <_panic>
	return &pages[PGNUM(pa)];
f0102f2f:	8b 15 8c 6f 18 f0    	mov    0xf0186f8c,%edx
f0102f35:	8d 04 c2             	lea    (%edx,%eax,8),%eax
}
f0102f38:	c3                   	ret    

f0102f39 <region_alloc>:
// Pages should be writable by user and kernel.
// Panic if any allocation attempt fails.
//
static void
region_alloc(struct Env *e, void *va, size_t len)
{
f0102f39:	55                   	push   %ebp
f0102f3a:	89 e5                	mov    %esp,%ebp
f0102f3c:	57                   	push   %edi
f0102f3d:	56                   	push   %esi
f0102f3e:	53                   	push   %ebx
f0102f3f:	83 ec 28             	sub    $0x28,%esp
f0102f42:	89 c7                	mov    %eax,%edi
		}
		va_copy = va_copy + PGSIZE;
	}
*/

	va = ROUNDDOWN(va,PGSIZE);
f0102f44:	81 e2 00 f0 ff ff    	and    $0xfffff000,%edx
f0102f4a:	89 d3                	mov    %edx,%ebx
f0102f4c:	89 d6                	mov    %edx,%esi
	void* va_finish = ROUNDUP(va+len,PGSIZE);
f0102f4e:	8d 84 0a ff 0f 00 00 	lea    0xfff(%edx,%ecx,1),%eax
f0102f55:	25 00 f0 ff ff       	and    $0xfffff000,%eax
f0102f5a:	89 45 e4             	mov    %eax,-0x1c(%ebp)
	cprintf("checkpoint\n");//DEBUG2
f0102f5d:	68 57 5b 10 f0       	push   $0xf0105b57
f0102f62:	e8 b1 06 00 00       	call   f0103618 <cprintf>
	if (va_finish>va) {len = va_finish - va; //es un multiplo de PGSIZE	
f0102f67:	83 c4 10             	add    $0x10,%esp
f0102f6a:	8b 45 e4             	mov    -0x1c(%ebp),%eax
f0102f6d:	39 c3                	cmp    %eax,%ebx
f0102f6f:	73 16                	jae    f0102f87 <region_alloc+0x4e>
f0102f71:	29 d8                	sub    %ebx,%eax
f0102f73:	89 c3                	mov    %eax,%ebx
						cprintf("FLAGTRUE\n");}//DEBUG2
f0102f75:	83 ec 0c             	sub    $0xc,%esp
f0102f78:	68 63 5b 10 f0       	push   $0xf0105b63
f0102f7d:	e8 96 06 00 00       	call   f0103618 <cprintf>
f0102f82:	83 c4 10             	add    $0x10,%esp
f0102f85:	eb 73                	jmp    f0102ffa <region_alloc+0xc1>
	else {len = ~0x0-(uint32_t)va+1;//si hizo overflow
f0102f87:	f7 db                	neg    %ebx
						cprintf("FLAGFALSE\n");}//DEBUG2
f0102f89:	83 ec 0c             	sub    $0xc,%esp
f0102f8c:	68 6d 5b 10 f0       	push   $0xf0105b6d
f0102f91:	e8 82 06 00 00       	call   f0103618 <cprintf>
f0102f96:	83 c4 10             	add    $0x10,%esp
f0102f99:	eb 5f                	jmp    f0102ffa <region_alloc+0xc1>
	while (len>0){
		struct PageInfo* page = page_alloc(0);//no hay que inicializar
f0102f9b:	83 ec 0c             	sub    $0xc,%esp
f0102f9e:	6a 00                	push   $0x0
f0102fa0:	e8 75 e3 ff ff       	call   f010131a <page_alloc>
		if (page == NULL) panic("Error allocating environment");
f0102fa5:	83 c4 10             	add    $0x10,%esp
f0102fa8:	85 c0                	test   %eax,%eax
f0102faa:	75 17                	jne    f0102fc3 <region_alloc+0x8a>
f0102fac:	83 ec 04             	sub    $0x4,%esp
f0102faf:	68 78 5b 10 f0       	push   $0xf0105b78
f0102fb4:	68 32 01 00 00       	push   $0x132
f0102fb9:	68 4c 5b 10 f0       	push   $0xf0105b4c
f0102fbe:	e8 e6 d0 ff ff       	call   f01000a9 <_panic>

		int ret_code = page_insert(e->env_pgdir, page, va, PTE_W | PTE_U);
f0102fc3:	6a 06                	push   $0x6
f0102fc5:	56                   	push   %esi
f0102fc6:	50                   	push   %eax
f0102fc7:	ff 77 5c             	pushl  0x5c(%edi)
f0102fca:	e8 d9 ea ff ff       	call   f0101aa8 <page_insert>
		if (ret_code == -E_NO_MEM)	panic("Error allocating environment");
f0102fcf:	83 c4 10             	add    $0x10,%esp
f0102fd2:	83 f8 fc             	cmp    $0xfffffffc,%eax
f0102fd5:	75 17                	jne    f0102fee <region_alloc+0xb5>
f0102fd7:	83 ec 04             	sub    $0x4,%esp
f0102fda:	68 78 5b 10 f0       	push   $0xf0105b78
f0102fdf:	68 35 01 00 00       	push   $0x135
f0102fe4:	68 4c 5b 10 f0       	push   $0xf0105b4c
f0102fe9:	e8 bb d0 ff ff       	call   f01000a9 <_panic>
		
		va+=PGSIZE;
f0102fee:	81 c6 00 10 00 00    	add    $0x1000,%esi
		len-=PGSIZE;
f0102ff4:	81 eb 00 10 00 00    	sub    $0x1000,%ebx
	cprintf("checkpoint\n");//DEBUG2
	if (va_finish>va) {len = va_finish - va; //es un multiplo de PGSIZE	
						cprintf("FLAGTRUE\n");}//DEBUG2
	else {len = ~0x0-(uint32_t)va+1;//si hizo overflow
						cprintf("FLAGFALSE\n");}//DEBUG2
	while (len>0){
f0102ffa:	85 db                	test   %ebx,%ebx
f0102ffc:	75 9d                	jne    f0102f9b <region_alloc+0x62>
		if (ret_code == -E_NO_MEM)	panic("Error allocating environment");
		
		va+=PGSIZE;
		len-=PGSIZE;
	}
	assert(va==va_finish);
f0102ffe:	3b 75 e4             	cmp    -0x1c(%ebp),%esi
f0103001:	74 19                	je     f010301c <region_alloc+0xe3>
f0103003:	68 95 5b 10 f0       	push   $0xf0105b95
f0103008:	68 da 57 10 f0       	push   $0xf01057da
f010300d:	68 3a 01 00 00       	push   $0x13a
f0103012:	68 4c 5b 10 f0       	push   $0xf0105b4c
f0103017:	e8 8d d0 ff ff       	call   f01000a9 <_panic>
}
f010301c:	8d 65 f4             	lea    -0xc(%ebp),%esp
f010301f:	5b                   	pop    %ebx
f0103020:	5e                   	pop    %esi
f0103021:	5f                   	pop    %edi
f0103022:	5d                   	pop    %ebp
f0103023:	c3                   	ret    

f0103024 <load_icode>:
// load_icode panics if it encounters problems.
//  - How might load_icode fail?  What might be wrong with the given input?
//
static void
load_icode(struct Env *e, uint8_t *binary)
{
f0103024:	55                   	push   %ebp
f0103025:	89 e5                	mov    %esp,%ebp
f0103027:	57                   	push   %edi
f0103028:	56                   	push   %esi
f0103029:	53                   	push   %ebx
f010302a:	83 ec 1c             	sub    $0x1c,%esp
f010302d:	89 45 e0             	mov    %eax,-0x20(%ebp)

	return;
*/

	struct Elf* elf = (struct Elf *) binary;
	if (elf->e_magic != ELF_MAGIC) panic("Invalid binary");
f0103030:	81 3a 7f 45 4c 46    	cmpl   $0x464c457f,(%edx)
f0103036:	74 17                	je     f010304f <load_icode+0x2b>
f0103038:	83 ec 04             	sub    $0x4,%esp
f010303b:	68 a3 5b 10 f0       	push   $0xf0105ba3
f0103040:	68 9c 01 00 00       	push   $0x19c
f0103045:	68 4c 5b 10 f0       	push   $0xf0105b4c
f010304a:	e8 5a d0 ff ff       	call   f01000a9 <_panic>
f010304f:	89 d6                	mov    %edx,%esi

	struct Proghdr* ph = (struct Proghdr*)(binary + elf->e_phoff);
f0103051:	89 d3                	mov    %edx,%ebx
f0103053:	03 5a 1c             	add    0x1c(%edx),%ebx
	void* va;
	for (int hdr_num = 0; hdr_num < elf->e_phnum; hdr_num++){
f0103056:	bf 00 00 00 00       	mov    $0x0,%edi
f010305b:	e9 d6 00 00 00       	jmp    f0103136 <load_icode+0x112>
		va=(void*) ph->p_va;
		if (ph->p_type != ELF_PROG_LOAD) continue;
f0103060:	83 3b 01             	cmpl   $0x1,(%ebx)
f0103063:	0f 85 ca 00 00 00    	jne    f0103133 <load_icode+0x10f>
	if (elf->e_magic != ELF_MAGIC) panic("Invalid binary");

	struct Proghdr* ph = (struct Proghdr*)(binary + elf->e_phoff);
	void* va;
	for (int hdr_num = 0; hdr_num < elf->e_phnum; hdr_num++){
		va=(void*) ph->p_va;
f0103069:	8b 43 08             	mov    0x8(%ebx),%eax
		if (ph->p_type != ELF_PROG_LOAD) continue;
		region_alloc(e,va,ph->p_memsz);
f010306c:	8b 4b 14             	mov    0x14(%ebx),%ecx
f010306f:	89 45 e4             	mov    %eax,-0x1c(%ebp)
f0103072:	89 c2                	mov    %eax,%edx
f0103074:	8b 45 e0             	mov    -0x20(%ebp),%eax
f0103077:	e8 bd fe ff ff       	call   f0102f39 <region_alloc>
		cprintf("\tVA es %p\n",va);//DEBUG2
f010307c:	83 ec 08             	sub    $0x8,%esp
f010307f:	ff 75 e4             	pushl  -0x1c(%ebp)
f0103082:	68 b2 5b 10 f0       	push   $0xf0105bb2
f0103087:	e8 8c 05 00 00       	call   f0103618 <cprintf>
		cprintf("\tbinary es %p\n",binary);//DEBUG2
f010308c:	83 c4 08             	add    $0x8,%esp
f010308f:	56                   	push   %esi
f0103090:	68 bd 5b 10 f0       	push   $0xf0105bbd
f0103095:	e8 7e 05 00 00       	call   f0103618 <cprintf>
		cprintf("\tph es %p\n",ph);//DEBUG2
f010309a:	83 c4 08             	add    $0x8,%esp
f010309d:	53                   	push   %ebx
f010309e:	68 cc 5b 10 f0       	push   $0xf0105bcc
f01030a3:	e8 70 05 00 00       	call   f0103618 <cprintf>
		cprintf("\tp_offset es %p\n",ph->p_offset);//DEBUG2
f01030a8:	83 c4 08             	add    $0x8,%esp
f01030ab:	ff 73 04             	pushl  0x4(%ebx)
f01030ae:	68 d7 5b 10 f0       	push   $0xf0105bd7
f01030b3:	e8 60 05 00 00       	call   f0103618 <cprintf>
		cprintf("\tbin+p_off es %p\n",(void*)binary+ph->p_offset);//DEBUG2
f01030b8:	83 c4 08             	add    $0x8,%esp
f01030bb:	89 f0                	mov    %esi,%eax
f01030bd:	03 43 04             	add    0x4(%ebx),%eax
f01030c0:	50                   	push   %eax
f01030c1:	68 e8 5b 10 f0       	push   $0xf0105be8
f01030c6:	e8 4d 05 00 00       	call   f0103618 <cprintf>
		cprintf("\tfilesz es %d y memsz es %d\n",ph->p_filesz,ph->p_memsz);//DEBUG2
f01030cb:	83 c4 0c             	add    $0xc,%esp
f01030ce:	ff 73 14             	pushl  0x14(%ebx)
f01030d1:	ff 73 10             	pushl  0x10(%ebx)
f01030d4:	68 fa 5b 10 f0       	push   $0xf0105bfa
f01030d9:	e8 3a 05 00 00       	call   f0103618 <cprintf>
		cprintf("\tentsize es %d\n",elf->e_phentsize);//DEBUG2
f01030de:	83 c4 08             	add    $0x8,%esp
f01030e1:	0f b7 46 2a          	movzwl 0x2a(%esi),%eax
f01030e5:	50                   	push   %eax
f01030e6:	68 17 5c 10 f0       	push   $0xf0105c17
f01030eb:	e8 28 05 00 00       	call   f0103618 <cprintf>
		memcpy(va,(void*)binary+ph->p_offset,ph->p_filesz);//chequear la suma de int8+int32
f01030f0:	83 c4 0c             	add    $0xc,%esp
f01030f3:	ff 73 10             	pushl  0x10(%ebx)
f01030f6:	89 f0                	mov    %esi,%eax
f01030f8:	03 43 04             	add    0x4(%ebx),%eax
f01030fb:	50                   	push   %eax
f01030fc:	ff 75 e4             	pushl  -0x1c(%ebp)
f01030ff:	e8 89 15 00 00       	call   f010468d <memcpy>
		cprintf("\thizo el memcpy\n");//DEBUG2
f0103104:	c7 04 24 27 5c 10 f0 	movl   $0xf0105c27,(%esp)
f010310b:	e8 08 05 00 00       	call   f0103618 <cprintf>
		memset(va + ph->p_filesz,0,ph->p_memsz - ph->p_filesz);//VA+FILESZ->VA+MEMSZ
f0103110:	8b 43 10             	mov    0x10(%ebx),%eax
f0103113:	83 c4 0c             	add    $0xc,%esp
f0103116:	8b 53 14             	mov    0x14(%ebx),%edx
f0103119:	29 c2                	sub    %eax,%edx
f010311b:	52                   	push   %edx
f010311c:	6a 00                	push   $0x0
f010311e:	03 45 e4             	add    -0x1c(%ebp),%eax
f0103121:	50                   	push   %eax
f0103122:	e8 b0 14 00 00       	call   f01045d7 <memset>
		ph += elf->e_phentsize;
f0103127:	0f b7 46 2a          	movzwl 0x2a(%esi),%eax
f010312b:	c1 e0 05             	shl    $0x5,%eax
f010312e:	01 c3                	add    %eax,%ebx
f0103130:	83 c4 10             	add    $0x10,%esp
	struct Elf* elf = (struct Elf *) binary;
	if (elf->e_magic != ELF_MAGIC) panic("Invalid binary");

	struct Proghdr* ph = (struct Proghdr*)(binary + elf->e_phoff);
	void* va;
	for (int hdr_num = 0; hdr_num < elf->e_phnum; hdr_num++){
f0103133:	83 c7 01             	add    $0x1,%edi
f0103136:	0f b7 46 2c          	movzwl 0x2c(%esi),%eax
f010313a:	39 c7                	cmp    %eax,%edi
f010313c:	0f 8c 1e ff ff ff    	jl     f0103060 <load_icode+0x3c>
		memset(va + ph->p_filesz,0,ph->p_memsz - ph->p_filesz);//VA+FILESZ->VA+MEMSZ
		ph += elf->e_phentsize;
	}


	e->env_tf.tf_eip=elf->e_entry;
f0103142:	8b 46 18             	mov    0x18(%esi),%eax
f0103145:	8b 7d e0             	mov    -0x20(%ebp),%edi
f0103148:	89 47 30             	mov    %eax,0x30(%edi)
	// Now map one page for the program's initial stack
	// at virtual address USTACKTOP - PGSIZE.

	// LAB 3: Your code here.

	region_alloc(e,(void*)USTACKTOP - PGSIZE,PGSIZE);
f010314b:	b9 00 10 00 00       	mov    $0x1000,%ecx
f0103150:	ba 00 d0 bf ee       	mov    $0xeebfd000,%edx
f0103155:	89 f8                	mov    %edi,%eax
f0103157:	e8 dd fd ff ff       	call   f0102f39 <region_alloc>
}
f010315c:	8d 65 f4             	lea    -0xc(%ebp),%esp
f010315f:	5b                   	pop    %ebx
f0103160:	5e                   	pop    %esi
f0103161:	5f                   	pop    %edi
f0103162:	5d                   	pop    %ebp
f0103163:	c3                   	ret    

f0103164 <envid2env>:
//   On success, sets *env_store to the environment.
//   On error, sets *env_store to NULL.
//
int
envid2env(envid_t envid, struct Env **env_store, bool checkperm)
{
f0103164:	55                   	push   %ebp
f0103165:	89 e5                	mov    %esp,%ebp
f0103167:	8b 55 08             	mov    0x8(%ebp),%edx
f010316a:	8b 4d 10             	mov    0x10(%ebp),%ecx
	struct Env *e;

	// If envid is zero, return the current environment.
	if (envid == 0) {
f010316d:	85 d2                	test   %edx,%edx
f010316f:	75 11                	jne    f0103182 <envid2env+0x1e>
		*env_store = curenv;
f0103171:	a1 c4 52 18 f0       	mov    0xf01852c4,%eax
f0103176:	8b 4d 0c             	mov    0xc(%ebp),%ecx
f0103179:	89 01                	mov    %eax,(%ecx)
		return 0;
f010317b:	b8 00 00 00 00       	mov    $0x0,%eax
f0103180:	eb 5e                	jmp    f01031e0 <envid2env+0x7c>
	// Look up the Env structure via the index part of the envid,
	// then check the env_id field in that struct Env
	// to ensure that the envid is not stale
	// (i.e., does not refer to a _previous_ environment
	// that used the same slot in the envs[] array).
	e = &envs[ENVX(envid)];
f0103182:	89 d0                	mov    %edx,%eax
f0103184:	25 ff 03 00 00       	and    $0x3ff,%eax
f0103189:	8d 04 40             	lea    (%eax,%eax,2),%eax
f010318c:	c1 e0 05             	shl    $0x5,%eax
f010318f:	03 05 c8 52 18 f0    	add    0xf01852c8,%eax
	if (e->env_status == ENV_FREE || e->env_id != envid) {
f0103195:	83 78 54 00          	cmpl   $0x0,0x54(%eax)
f0103199:	74 05                	je     f01031a0 <envid2env+0x3c>
f010319b:	3b 50 48             	cmp    0x48(%eax),%edx
f010319e:	74 10                	je     f01031b0 <envid2env+0x4c>
		*env_store = 0;
f01031a0:	8b 45 0c             	mov    0xc(%ebp),%eax
f01031a3:	c7 00 00 00 00 00    	movl   $0x0,(%eax)
		return -E_BAD_ENV;
f01031a9:	b8 fe ff ff ff       	mov    $0xfffffffe,%eax
f01031ae:	eb 30                	jmp    f01031e0 <envid2env+0x7c>
	// Check that the calling environment has legitimate permission
	// to manipulate the specified environment.
	// If checkperm is set, the specified environment
	// must be either the current environment
	// or an immediate child of the current environment.
	if (checkperm && e != curenv && e->env_parent_id != curenv->env_id) {
f01031b0:	84 c9                	test   %cl,%cl
f01031b2:	74 22                	je     f01031d6 <envid2env+0x72>
f01031b4:	8b 15 c4 52 18 f0    	mov    0xf01852c4,%edx
f01031ba:	39 d0                	cmp    %edx,%eax
f01031bc:	74 18                	je     f01031d6 <envid2env+0x72>
f01031be:	8b 4a 48             	mov    0x48(%edx),%ecx
f01031c1:	39 48 4c             	cmp    %ecx,0x4c(%eax)
f01031c4:	74 10                	je     f01031d6 <envid2env+0x72>
		*env_store = 0;
f01031c6:	8b 45 0c             	mov    0xc(%ebp),%eax
f01031c9:	c7 00 00 00 00 00    	movl   $0x0,(%eax)
		return -E_BAD_ENV;
f01031cf:	b8 fe ff ff ff       	mov    $0xfffffffe,%eax
f01031d4:	eb 0a                	jmp    f01031e0 <envid2env+0x7c>
	}

	*env_store = e;
f01031d6:	8b 4d 0c             	mov    0xc(%ebp),%ecx
f01031d9:	89 01                	mov    %eax,(%ecx)
	return 0;
f01031db:	b8 00 00 00 00       	mov    $0x0,%eax
}
f01031e0:	5d                   	pop    %ebp
f01031e1:	c3                   	ret    

f01031e2 <env_init_percpu>:
}

// Load GDT and segment descriptors.
void
env_init_percpu(void)
{
f01031e2:	55                   	push   %ebp
f01031e3:	89 e5                	mov    %esp,%ebp
	lgdt(&gdt_pd);
f01031e5:	b8 00 b3 11 f0       	mov    $0xf011b300,%eax
f01031ea:	e8 1b fc ff ff       	call   f0102e0a <lgdt>
	// The kernel never uses GS or FS, so we leave those set to
	// the user data segment.
	asm volatile("movw %%ax,%%gs" : : "a"(GD_UD | 3));
f01031ef:	b8 23 00 00 00       	mov    $0x23,%eax
f01031f4:	8e e8                	mov    %eax,%gs
	asm volatile("movw %%ax,%%fs" : : "a"(GD_UD | 3));
f01031f6:	8e e0                	mov    %eax,%fs
	// The kernel does use ES, DS, and SS.  We'll change between
	// the kernel and user data segments as needed.
	asm volatile("movw %%ax,%%es" : : "a"(GD_KD));
f01031f8:	b8 10 00 00 00       	mov    $0x10,%eax
f01031fd:	8e c0                	mov    %eax,%es
	asm volatile("movw %%ax,%%ds" : : "a"(GD_KD));
f01031ff:	8e d8                	mov    %eax,%ds
	asm volatile("movw %%ax,%%ss" : : "a"(GD_KD));
f0103201:	8e d0                	mov    %eax,%ss
	// Load the kernel text segment into CS.
	asm volatile("ljmp %0,$1f\n 1:\n" : : "i"(GD_KT));
f0103203:	ea 0a 32 10 f0 08 00 	ljmp   $0x8,$0xf010320a
	// For good measure, clear the local descriptor table (LDT),
	// since we don't use it.
	lldt(0);
f010320a:	b8 00 00 00 00       	mov    $0x0,%eax
f010320f:	e8 fe fb ff ff       	call   f0102e12 <lldt>
}
f0103214:	5d                   	pop    %ebp
f0103215:	c3                   	ret    

f0103216 <env_init>:
// they are in the envs array (i.e., so that the first call to
// env_alloc() returns envs[0]).
//
void
env_init(void)
{
f0103216:	55                   	push   %ebp
f0103217:	89 e5                	mov    %esp,%ebp
f0103219:	56                   	push   %esi
f010321a:	53                   	push   %ebx
	// Set up envs array
	// LAB 3: Your code here. (OK)
	for (size_t i=0; i< NENV; i++){
		envs[i].env_status = ENV_FREE; 
f010321b:	8b 35 c8 52 18 f0    	mov    0xf01852c8,%esi
f0103221:	8b 15 cc 52 18 f0    	mov    0xf01852cc,%edx
f0103227:	89 f0                	mov    %esi,%eax
f0103229:	8d 9e 00 80 01 00    	lea    0x18000(%esi),%ebx
f010322f:	89 c1                	mov    %eax,%ecx
f0103231:	c7 40 54 00 00 00 00 	movl   $0x0,0x54(%eax)
		envs[i].env_id = 0;
f0103238:	c7 40 48 00 00 00 00 	movl   $0x0,0x48(%eax)
		envs[i].env_link = env_free_list;
f010323f:	89 50 44             	mov    %edx,0x44(%eax)
f0103242:	83 c0 60             	add    $0x60,%eax
		env_free_list = &envs[i];
f0103245:	89 ca                	mov    %ecx,%edx
void
env_init(void)
{
	// Set up envs array
	// LAB 3: Your code here. (OK)
	for (size_t i=0; i< NENV; i++){
f0103247:	39 d8                	cmp    %ebx,%eax
f0103249:	75 e4                	jne    f010322f <env_init+0x19>
f010324b:	81 c6 a0 7f 01 00    	add    $0x17fa0,%esi
f0103251:	89 35 cc 52 18 f0    	mov    %esi,0xf01852cc
		envs[i].env_link = env_free_list;
		env_free_list = &envs[i];
	}

	// Per-CPU part of the initialization
	env_init_percpu();
f0103257:	e8 86 ff ff ff       	call   f01031e2 <env_init_percpu>
}
f010325c:	5b                   	pop    %ebx
f010325d:	5e                   	pop    %esi
f010325e:	5d                   	pop    %ebp
f010325f:	c3                   	ret    

f0103260 <env_alloc>:
//	-E_NO_FREE_ENV if all NENVS environments are allocated
//	-E_NO_MEM on memory exhaustion
//
int
env_alloc(struct Env **newenv_store, envid_t parent_id)
{
f0103260:	55                   	push   %ebp
f0103261:	89 e5                	mov    %esp,%ebp
f0103263:	53                   	push   %ebx
f0103264:	83 ec 04             	sub    $0x4,%esp
	int32_t generation;
	int r;
	struct Env *e;

	if (!(e = env_free_list))
f0103267:	8b 1d cc 52 18 f0    	mov    0xf01852cc,%ebx
f010326d:	85 db                	test   %ebx,%ebx
f010326f:	0f 84 c0 00 00 00    	je     f0103335 <env_alloc+0xd5>
		return -E_NO_FREE_ENV;

	// Allocate and set up the page directory for this environment.
	if ((r = env_setup_vm(e)) < 0)
f0103275:	89 d8                	mov    %ebx,%eax
f0103277:	e8 23 fc ff ff       	call   f0102e9f <env_setup_vm>
f010327c:	85 c0                	test   %eax,%eax
f010327e:	0f 88 b6 00 00 00    	js     f010333a <env_alloc+0xda>
		return r;

	// Generate an env_id for this environment.
	generation = (e->env_id + (1 << ENVGENSHIFT)) & ~(NENV - 1);
f0103284:	8b 43 48             	mov    0x48(%ebx),%eax
f0103287:	05 00 10 00 00       	add    $0x1000,%eax
	if (generation <= 0)  // Don't create a negative env_id.
f010328c:	25 00 fc ff ff       	and    $0xfffffc00,%eax
		generation = 1 << ENVGENSHIFT;
f0103291:	ba 00 10 00 00       	mov    $0x1000,%edx
f0103296:	0f 4e c2             	cmovle %edx,%eax
	e->env_id = generation | (e - envs);
f0103299:	89 da                	mov    %ebx,%edx
f010329b:	2b 15 c8 52 18 f0    	sub    0xf01852c8,%edx
f01032a1:	c1 fa 05             	sar    $0x5,%edx
f01032a4:	69 d2 ab aa aa aa    	imul   $0xaaaaaaab,%edx,%edx
f01032aa:	09 d0                	or     %edx,%eax
f01032ac:	89 43 48             	mov    %eax,0x48(%ebx)

	// Set the basic status variables.
	e->env_parent_id = parent_id;
f01032af:	8b 45 0c             	mov    0xc(%ebp),%eax
f01032b2:	89 43 4c             	mov    %eax,0x4c(%ebx)
	e->env_type = ENV_TYPE_USER;
f01032b5:	c7 43 50 00 00 00 00 	movl   $0x0,0x50(%ebx)
	e->env_status = ENV_RUNNABLE;
f01032bc:	c7 43 54 02 00 00 00 	movl   $0x2,0x54(%ebx)
	e->env_runs = 0;
f01032c3:	c7 43 58 00 00 00 00 	movl   $0x0,0x58(%ebx)

	// Clear out all the saved register state,
	// to prevent the register values
	// of a prior environment inhabiting this Env structure
	// from "leaking" into our new environment.
	memset(&e->env_tf, 0, sizeof(e->env_tf));
f01032ca:	83 ec 04             	sub    $0x4,%esp
f01032cd:	6a 44                	push   $0x44
f01032cf:	6a 00                	push   $0x0
f01032d1:	53                   	push   %ebx
f01032d2:	e8 00 13 00 00       	call   f01045d7 <memset>
	// The low 2 bits of each segment register contains the
	// Requestor Privilege Level (RPL); 3 means user mode.  When
	// we switch privilege levels, the hardware does various
	// checks involving the RPL and the Descriptor Privilege Level
	// (DPL) stored in the descriptors themselves.
	e->env_tf.tf_ds = GD_UD | 3;
f01032d7:	66 c7 43 24 23 00    	movw   $0x23,0x24(%ebx)
	e->env_tf.tf_es = GD_UD | 3;
f01032dd:	66 c7 43 20 23 00    	movw   $0x23,0x20(%ebx)
	e->env_tf.tf_ss = GD_UD | 3;
f01032e3:	66 c7 43 40 23 00    	movw   $0x23,0x40(%ebx)
	e->env_tf.tf_esp = USTACKTOP;
f01032e9:	c7 43 3c 00 e0 bf ee 	movl   $0xeebfe000,0x3c(%ebx)
	e->env_tf.tf_cs = GD_UT | 3;
f01032f0:	66 c7 43 34 1b 00    	movw   $0x1b,0x34(%ebx)
	// You will set e->env_tf.tf_eip later.

	// commit the allocation
	env_free_list = e->env_link;
f01032f6:	8b 43 44             	mov    0x44(%ebx),%eax
f01032f9:	a3 cc 52 18 f0       	mov    %eax,0xf01852cc
	*newenv_store = e; 
f01032fe:	8b 45 08             	mov    0x8(%ebp),%eax
f0103301:	89 18                	mov    %ebx,(%eax)

	cprintf("[%08x] new env %08x\n", curenv ? curenv->env_id : 0, e->env_id);
f0103303:	8b 53 48             	mov    0x48(%ebx),%edx
f0103306:	a1 c4 52 18 f0       	mov    0xf01852c4,%eax
f010330b:	83 c4 10             	add    $0x10,%esp
f010330e:	85 c0                	test   %eax,%eax
f0103310:	74 05                	je     f0103317 <env_alloc+0xb7>
f0103312:	8b 40 48             	mov    0x48(%eax),%eax
f0103315:	eb 05                	jmp    f010331c <env_alloc+0xbc>
f0103317:	b8 00 00 00 00       	mov    $0x0,%eax
f010331c:	83 ec 04             	sub    $0x4,%esp
f010331f:	52                   	push   %edx
f0103320:	50                   	push   %eax
f0103321:	68 38 5c 10 f0       	push   $0xf0105c38
f0103326:	e8 ed 02 00 00       	call   f0103618 <cprintf>
	return 0;
f010332b:	83 c4 10             	add    $0x10,%esp
f010332e:	b8 00 00 00 00       	mov    $0x0,%eax
f0103333:	eb 05                	jmp    f010333a <env_alloc+0xda>
	int32_t generation;
	int r;
	struct Env *e;

	if (!(e = env_free_list))
		return -E_NO_FREE_ENV;
f0103335:	b8 fb ff ff ff       	mov    $0xfffffffb,%eax
	env_free_list = e->env_link;
	*newenv_store = e; 

	cprintf("[%08x] new env %08x\n", curenv ? curenv->env_id : 0, e->env_id);
	return 0;
}
f010333a:	8b 5d fc             	mov    -0x4(%ebp),%ebx
f010333d:	c9                   	leave  
f010333e:	c3                   	ret    

f010333f <env_create>:
// before running the first user-mode environment.
// The new env's parent ID is set to 0.
//
void
env_create(uint8_t *binary, enum EnvType type)
{
f010333f:	55                   	push   %ebp
f0103340:	89 e5                	mov    %esp,%ebp
f0103342:	83 ec 20             	sub    $0x20,%esp
	// LAB 3: Your code here.
	struct Env* e;
	int err = env_alloc(&e,0);//hace lugar para un Env cuya dir se guarda en e, parent_id es 0 por def.
f0103345:	6a 00                	push   $0x0
f0103347:	8d 45 f4             	lea    -0xc(%ebp),%eax
f010334a:	50                   	push   %eax
f010334b:	e8 10 ff ff ff       	call   f0103260 <env_alloc>
	if (err<0) panic("env_create: %e", err);
f0103350:	83 c4 10             	add    $0x10,%esp
f0103353:	85 c0                	test   %eax,%eax
f0103355:	79 15                	jns    f010336c <env_create+0x2d>
f0103357:	50                   	push   %eax
f0103358:	68 4d 5c 10 f0       	push   $0xf0105c4d
f010335d:	68 c9 01 00 00       	push   $0x1c9
f0103362:	68 4c 5b 10 f0       	push   $0xf0105b4c
f0103367:	e8 3d cd ff ff       	call   f01000a9 <_panic>
	load_icode(e,binary);
f010336c:	8b 55 08             	mov    0x8(%ebp),%edx
f010336f:	8b 45 f4             	mov    -0xc(%ebp),%eax
f0103372:	e8 ad fc ff ff       	call   f0103024 <load_icode>
	e->env_type = type;
f0103377:	8b 45 f4             	mov    -0xc(%ebp),%eax
f010337a:	8b 55 0c             	mov    0xc(%ebp),%edx
f010337d:	89 50 50             	mov    %edx,0x50(%eax)
}
f0103380:	c9                   	leave  
f0103381:	c3                   	ret    

f0103382 <env_free>:
//
// Frees env e and all memory it uses.
//
void
env_free(struct Env *e)
{
f0103382:	55                   	push   %ebp
f0103383:	89 e5                	mov    %esp,%ebp
f0103385:	57                   	push   %edi
f0103386:	56                   	push   %esi
f0103387:	53                   	push   %ebx
f0103388:	83 ec 1c             	sub    $0x1c,%esp
f010338b:	8b 7d 08             	mov    0x8(%ebp),%edi
	physaddr_t pa;

	// If freeing the current environment, switch to kern_pgdir
	// before freeing the page directory, just in case the page
	// gets reused.
	if (e == curenv)
f010338e:	39 3d c4 52 18 f0    	cmp    %edi,0xf01852c4
f0103394:	75 1a                	jne    f01033b0 <env_free+0x2e>
		lcr3(PADDR(kern_pgdir));
f0103396:	8b 0d 88 6f 18 f0    	mov    0xf0186f88,%ecx
f010339c:	ba dc 01 00 00       	mov    $0x1dc,%edx
f01033a1:	b8 4c 5b 10 f0       	mov    $0xf0105b4c,%eax
f01033a6:	e8 d2 fa ff ff       	call   f0102e7d <_paddr>
f01033ab:	e8 6a fa ff ff       	call   f0102e1a <lcr3>

	// Note the environment's demise.
	cprintf("[%08x] free env %08x\n", curenv ? curenv->env_id : 0, e->env_id);
f01033b0:	8b 57 48             	mov    0x48(%edi),%edx
f01033b3:	a1 c4 52 18 f0       	mov    0xf01852c4,%eax
f01033b8:	85 c0                	test   %eax,%eax
f01033ba:	74 05                	je     f01033c1 <env_free+0x3f>
f01033bc:	8b 40 48             	mov    0x48(%eax),%eax
f01033bf:	eb 05                	jmp    f01033c6 <env_free+0x44>
f01033c1:	b8 00 00 00 00       	mov    $0x0,%eax
f01033c6:	83 ec 04             	sub    $0x4,%esp
f01033c9:	52                   	push   %edx
f01033ca:	50                   	push   %eax
f01033cb:	68 5c 5c 10 f0       	push   $0xf0105c5c
f01033d0:	e8 43 02 00 00       	call   f0103618 <cprintf>
f01033d5:	83 c4 10             	add    $0x10,%esp

	// Flush all mapped pages in the user portion of the address space
	static_assert(UTOP % PTSIZE == 0);
	for (pdeno = 0; pdeno < PDX(UTOP); pdeno++) {
f01033d8:	c7 45 e0 00 00 00 00 	movl   $0x0,-0x20(%ebp)
f01033df:	8b 4d e0             	mov    -0x20(%ebp),%ecx
f01033e2:	89 c8                	mov    %ecx,%eax
f01033e4:	c1 e0 02             	shl    $0x2,%eax
f01033e7:	89 45 dc             	mov    %eax,-0x24(%ebp)
		// only look at mapped page tables
		if (!(e->env_pgdir[pdeno] & PTE_P))
f01033ea:	8b 47 5c             	mov    0x5c(%edi),%eax
f01033ed:	8b 04 88             	mov    (%eax,%ecx,4),%eax
f01033f0:	a8 01                	test   $0x1,%al
f01033f2:	74 72                	je     f0103466 <env_free+0xe4>
			continue;

		// find the pa and va of the page table
		pa = PTE_ADDR(e->env_pgdir[pdeno]);
f01033f4:	25 00 f0 ff ff       	and    $0xfffff000,%eax
f01033f9:	89 45 d8             	mov    %eax,-0x28(%ebp)
		pt = (pte_t *) KADDR(pa);
f01033fc:	89 c1                	mov    %eax,%ecx
f01033fe:	ba ea 01 00 00       	mov    $0x1ea,%edx
f0103403:	b8 4c 5b 10 f0       	mov    $0xf0105b4c,%eax
f0103408:	e8 26 fa ff ff       	call   f0102e33 <_kaddr>
f010340d:	89 c6                	mov    %eax,%esi

		// unmap all PTEs in this page table
		for (pteno = 0; pteno <= PTX(~0); pteno++) {
			if (pt[pteno] & PTE_P)
				page_remove(e->env_pgdir, PGADDR(pdeno, pteno, 0));
f010340f:	8b 45 e0             	mov    -0x20(%ebp),%eax
f0103412:	c1 e0 16             	shl    $0x16,%eax
f0103415:	89 45 e4             	mov    %eax,-0x1c(%ebp)
		// find the pa and va of the page table
		pa = PTE_ADDR(e->env_pgdir[pdeno]);
		pt = (pte_t *) KADDR(pa);

		// unmap all PTEs in this page table
		for (pteno = 0; pteno <= PTX(~0); pteno++) {
f0103418:	bb 00 00 00 00       	mov    $0x0,%ebx
			if (pt[pteno] & PTE_P)
f010341d:	f6 04 9e 01          	testb  $0x1,(%esi,%ebx,4)
f0103421:	74 17                	je     f010343a <env_free+0xb8>
				page_remove(e->env_pgdir, PGADDR(pdeno, pteno, 0));
f0103423:	83 ec 08             	sub    $0x8,%esp
f0103426:	89 d8                	mov    %ebx,%eax
f0103428:	c1 e0 0c             	shl    $0xc,%eax
f010342b:	0b 45 e4             	or     -0x1c(%ebp),%eax
f010342e:	50                   	push   %eax
f010342f:	ff 77 5c             	pushl  0x5c(%edi)
f0103432:	e8 28 e6 ff ff       	call   f0101a5f <page_remove>
f0103437:	83 c4 10             	add    $0x10,%esp
		// find the pa and va of the page table
		pa = PTE_ADDR(e->env_pgdir[pdeno]);
		pt = (pte_t *) KADDR(pa);

		// unmap all PTEs in this page table
		for (pteno = 0; pteno <= PTX(~0); pteno++) {
f010343a:	83 c3 01             	add    $0x1,%ebx
f010343d:	81 fb 00 04 00 00    	cmp    $0x400,%ebx
f0103443:	75 d8                	jne    f010341d <env_free+0x9b>
			if (pt[pteno] & PTE_P)
				page_remove(e->env_pgdir, PGADDR(pdeno, pteno, 0));
		}

		// free the page table itself
		e->env_pgdir[pdeno] = 0;
f0103445:	8b 47 5c             	mov    0x5c(%edi),%eax
f0103448:	8b 4d dc             	mov    -0x24(%ebp),%ecx
f010344b:	c7 04 08 00 00 00 00 	movl   $0x0,(%eax,%ecx,1)
		page_decref(pa2page(pa));
f0103452:	8b 45 d8             	mov    -0x28(%ebp),%eax
f0103455:	e8 b3 fa ff ff       	call   f0102f0d <pa2page>
f010345a:	83 ec 0c             	sub    $0xc,%esp
f010345d:	50                   	push   %eax
f010345e:	e8 fe e3 ff ff       	call   f0101861 <page_decref>
f0103463:	83 c4 10             	add    $0x10,%esp
	// Note the environment's demise.
	cprintf("[%08x] free env %08x\n", curenv ? curenv->env_id : 0, e->env_id);

	// Flush all mapped pages in the user portion of the address space
	static_assert(UTOP % PTSIZE == 0);
	for (pdeno = 0; pdeno < PDX(UTOP); pdeno++) {
f0103466:	83 45 e0 01          	addl   $0x1,-0x20(%ebp)
f010346a:	8b 45 e0             	mov    -0x20(%ebp),%eax
f010346d:	3d bb 03 00 00       	cmp    $0x3bb,%eax
f0103472:	0f 85 67 ff ff ff    	jne    f01033df <env_free+0x5d>
		e->env_pgdir[pdeno] = 0;
		page_decref(pa2page(pa));
	}

	// free the page directory
	pa = PADDR(e->env_pgdir);
f0103478:	8b 4f 5c             	mov    0x5c(%edi),%ecx
f010347b:	ba f8 01 00 00       	mov    $0x1f8,%edx
f0103480:	b8 4c 5b 10 f0       	mov    $0xf0105b4c,%eax
f0103485:	e8 f3 f9 ff ff       	call   f0102e7d <_paddr>
	e->env_pgdir = 0;
f010348a:	c7 47 5c 00 00 00 00 	movl   $0x0,0x5c(%edi)
	page_decref(pa2page(pa));
f0103491:	e8 77 fa ff ff       	call   f0102f0d <pa2page>
f0103496:	83 ec 0c             	sub    $0xc,%esp
f0103499:	50                   	push   %eax
f010349a:	e8 c2 e3 ff ff       	call   f0101861 <page_decref>

	// return the environment to the free list
	e->env_status = ENV_FREE;
f010349f:	c7 47 54 00 00 00 00 	movl   $0x0,0x54(%edi)
	e->env_link = env_free_list;
f01034a6:	a1 cc 52 18 f0       	mov    0xf01852cc,%eax
f01034ab:	89 47 44             	mov    %eax,0x44(%edi)
	env_free_list = e;
f01034ae:	89 3d cc 52 18 f0    	mov    %edi,0xf01852cc
}
f01034b4:	83 c4 10             	add    $0x10,%esp
f01034b7:	8d 65 f4             	lea    -0xc(%ebp),%esp
f01034ba:	5b                   	pop    %ebx
f01034bb:	5e                   	pop    %esi
f01034bc:	5f                   	pop    %edi
f01034bd:	5d                   	pop    %ebp
f01034be:	c3                   	ret    

f01034bf <env_destroy>:
//
// Frees environment e.
//
void
env_destroy(struct Env *e)
{
f01034bf:	55                   	push   %ebp
f01034c0:	89 e5                	mov    %esp,%ebp
f01034c2:	83 ec 14             	sub    $0x14,%esp
	env_free(e);
f01034c5:	ff 75 08             	pushl  0x8(%ebp)
f01034c8:	e8 b5 fe ff ff       	call   f0103382 <env_free>

	cprintf("Destroyed the only environment - nothing more to do!\n");
f01034cd:	c7 04 24 ec 5a 10 f0 	movl   $0xf0105aec,(%esp)
f01034d4:	e8 3f 01 00 00       	call   f0103618 <cprintf>
f01034d9:	83 c4 10             	add    $0x10,%esp
	while (1)
		monitor(NULL);
f01034dc:	83 ec 0c             	sub    $0xc,%esp
f01034df:	6a 00                	push   $0x0
f01034e1:	e8 3e d5 ff ff       	call   f0100a24 <monitor>
f01034e6:	83 c4 10             	add    $0x10,%esp
f01034e9:	eb f1                	jmp    f01034dc <env_destroy+0x1d>

f01034eb <env_pop_tf>:
//
// This function does not return.
//
void
env_pop_tf(struct Trapframe *tf)
{
f01034eb:	55                   	push   %ebp
f01034ec:	89 e5                	mov    %esp,%ebp
f01034ee:	83 ec 0c             	sub    $0xc,%esp
	asm volatile("\tmovl %0,%%esp\n"
f01034f1:	8b 65 08             	mov    0x8(%ebp),%esp
f01034f4:	61                   	popa   
f01034f5:	07                   	pop    %es
f01034f6:	1f                   	pop    %ds
f01034f7:	83 c4 08             	add    $0x8,%esp
f01034fa:	cf                   	iret   
	             "\taddl $0x8,%%esp\n" /* skip tf_trapno and tf_errcode */
	             "\tiret\n"
	             :
	             : "g"(tf)
	             : "memory");
	panic("iret failed"); /* mostly to placate the compiler */
f01034fb:	68 72 5c 10 f0       	push   $0xf0105c72
f0103500:	68 22 02 00 00       	push   $0x222
f0103505:	68 4c 5b 10 f0       	push   $0xf0105b4c
f010350a:	e8 9a cb ff ff       	call   f01000a9 <_panic>

f010350f <env_run>:
//
// This function does not return.
//
void
env_run(struct Env *e)
{
f010350f:	55                   	push   %ebp
f0103510:	89 e5                	mov    %esp,%ebp
f0103512:	53                   	push   %ebx
f0103513:	83 ec 04             	sub    $0x4,%esp
f0103516:	8b 5d 08             	mov    0x8(%ebp),%ebx

	// LAB 3: Your code here.
	
	//panic("env_run not yet implemented");

	if(curenv != NULL){	//si no es la primera vez que se corre esto hay que guardar todo
f0103519:	a1 c4 52 18 f0       	mov    0xf01852c4,%eax
f010351e:	85 c0                	test   %eax,%eax
f0103520:	74 25                	je     f0103547 <env_run+0x38>
		cprintf("Estoy en un proc y su env_status es %d\n",curenv->env_status);//DEBUG2
f0103522:	83 ec 08             	sub    $0x8,%esp
f0103525:	ff 70 54             	pushl  0x54(%eax)
f0103528:	68 24 5b 10 f0       	push   $0xf0105b24
f010352d:	e8 e6 00 00 00       	call   f0103618 <cprintf>
		if (curenv->env_status == ENV_RUNNING) curenv->env_status=ENV_RUNNABLE;
f0103532:	a1 c4 52 18 f0       	mov    0xf01852c4,%eax
f0103537:	83 c4 10             	add    $0x10,%esp
f010353a:	83 78 54 03          	cmpl   $0x3,0x54(%eax)
f010353e:	75 07                	jne    f0103547 <env_run+0x38>
f0103540:	c7 40 54 02 00 00 00 	movl   $0x2,0x54(%eax)
		//si FREE no tiene nada, no tiene sentido
		//si DYING ????
		//si RUNNABLE no deberia estar corriendo
		//si NOT_RUNNABLE ???
	}
	curenv=e;
f0103547:	89 1d c4 52 18 f0    	mov    %ebx,0xf01852c4
	curenv->env_status = ENV_RUNNING;
f010354d:	c7 43 54 03 00 00 00 	movl   $0x3,0x54(%ebx)
	curenv->env_runs++;
f0103554:	83 43 58 01          	addl   $0x1,0x58(%ebx)
	lcr3(PADDR(curenv->env_pgdir));
f0103558:	8b 4b 5c             	mov    0x5c(%ebx),%ecx
f010355b:	ba 4f 02 00 00       	mov    $0x24f,%edx
f0103560:	b8 4c 5b 10 f0       	mov    $0xf0105b4c,%eax
f0103565:	e8 13 f9 ff ff       	call   f0102e7d <_paddr>
f010356a:	e8 ab f8 ff ff       	call   f0102e1a <lcr3>

	env_pop_tf(&(curenv->env_tf));
f010356f:	83 ec 0c             	sub    $0xc,%esp
f0103572:	ff 35 c4 52 18 f0    	pushl  0xf01852c4
f0103578:	e8 6e ff ff ff       	call   f01034eb <env_pop_tf>

f010357d <inb>:
	asm volatile("int3");
}

static inline uint8_t
inb(int port)
{
f010357d:	55                   	push   %ebp
f010357e:	89 e5                	mov    %esp,%ebp
	uint8_t data;
	asm volatile("inb %w1,%0" : "=a" (data) : "d" (port));
f0103580:	89 c2                	mov    %eax,%edx
f0103582:	ec                   	in     (%dx),%al
	return data;
}
f0103583:	5d                   	pop    %ebp
f0103584:	c3                   	ret    

f0103585 <outb>:
		     : "memory", "cc");
}

static inline void
outb(int port, uint8_t data)
{
f0103585:	55                   	push   %ebp
f0103586:	89 e5                	mov    %esp,%ebp
f0103588:	89 c1                	mov    %eax,%ecx
f010358a:	89 d0                	mov    %edx,%eax
	asm volatile("outb %0,%w1" : : "a" (data), "d" (port));
f010358c:	89 ca                	mov    %ecx,%edx
f010358e:	ee                   	out    %al,(%dx)
}
f010358f:	5d                   	pop    %ebp
f0103590:	c3                   	ret    

f0103591 <mc146818_read>:
#include <kern/kclock.h>


unsigned
mc146818_read(unsigned reg)
{
f0103591:	55                   	push   %ebp
f0103592:	89 e5                	mov    %esp,%ebp
f0103594:	0f b6 55 08          	movzbl 0x8(%ebp),%edx
	outb(IO_RTC, reg);
f0103598:	b8 70 00 00 00       	mov    $0x70,%eax
f010359d:	e8 e3 ff ff ff       	call   f0103585 <outb>
	return inb(IO_RTC+1);
f01035a2:	b8 71 00 00 00       	mov    $0x71,%eax
f01035a7:	e8 d1 ff ff ff       	call   f010357d <inb>
f01035ac:	0f b6 c0             	movzbl %al,%eax
}
f01035af:	5d                   	pop    %ebp
f01035b0:	c3                   	ret    

f01035b1 <mc146818_write>:

void
mc146818_write(unsigned reg, unsigned datum)
{
f01035b1:	55                   	push   %ebp
f01035b2:	89 e5                	mov    %esp,%ebp
f01035b4:	0f b6 55 08          	movzbl 0x8(%ebp),%edx
	outb(IO_RTC, reg);
f01035b8:	b8 70 00 00 00       	mov    $0x70,%eax
f01035bd:	e8 c3 ff ff ff       	call   f0103585 <outb>
f01035c2:	0f b6 55 0c          	movzbl 0xc(%ebp),%edx
	outb(IO_RTC+1, datum);
f01035c6:	b8 71 00 00 00       	mov    $0x71,%eax
f01035cb:	e8 b5 ff ff ff       	call   f0103585 <outb>
}
f01035d0:	5d                   	pop    %ebp
f01035d1:	c3                   	ret    

f01035d2 <putch>:
#include <inc/stdarg.h>


static void
putch(int ch, int *cnt)
{
f01035d2:	55                   	push   %ebp
f01035d3:	89 e5                	mov    %esp,%ebp
f01035d5:	83 ec 18             	sub    $0x18,%esp
	cputchar(ch);
f01035d8:	8b 45 08             	mov    0x8(%ebp),%eax
f01035db:	89 04 24             	mov    %eax,(%esp)
f01035de:	e8 35 d1 ff ff       	call   f0100718 <cputchar>
	*cnt++;
}
f01035e3:	c9                   	leave  
f01035e4:	c3                   	ret    

f01035e5 <vcprintf>:

int
vcprintf(const char *fmt, va_list ap)
{
f01035e5:	55                   	push   %ebp
f01035e6:	89 e5                	mov    %esp,%ebp
f01035e8:	83 ec 28             	sub    $0x28,%esp
	int cnt = 0;
f01035eb:	c7 45 f4 00 00 00 00 	movl   $0x0,-0xc(%ebp)

	vprintfmt((void*)putch, &cnt, fmt, ap);
f01035f2:	8b 45 0c             	mov    0xc(%ebp),%eax
f01035f5:	89 44 24 0c          	mov    %eax,0xc(%esp)
f01035f9:	8b 45 08             	mov    0x8(%ebp),%eax
f01035fc:	89 44 24 08          	mov    %eax,0x8(%esp)
f0103600:	8d 45 f4             	lea    -0xc(%ebp),%eax
f0103603:	89 44 24 04          	mov    %eax,0x4(%esp)
f0103607:	c7 04 24 d2 35 10 f0 	movl   $0xf01035d2,(%esp)
f010360e:	e8 5d 09 00 00       	call   f0103f70 <vprintfmt>
	return cnt;
}
f0103613:	8b 45 f4             	mov    -0xc(%ebp),%eax
f0103616:	c9                   	leave  
f0103617:	c3                   	ret    

f0103618 <cprintf>:

int
cprintf(const char *fmt, ...)
{
f0103618:	55                   	push   %ebp
f0103619:	89 e5                	mov    %esp,%ebp
f010361b:	83 ec 18             	sub    $0x18,%esp
	va_list ap;
	int cnt;

	va_start(ap, fmt);
f010361e:	8d 45 0c             	lea    0xc(%ebp),%eax
	cnt = vcprintf(fmt, ap);
f0103621:	89 44 24 04          	mov    %eax,0x4(%esp)
f0103625:	8b 45 08             	mov    0x8(%ebp),%eax
f0103628:	89 04 24             	mov    %eax,(%esp)
f010362b:	e8 b5 ff ff ff       	call   f01035e5 <vcprintf>
	va_end(ap);

	return cnt;
}
f0103630:	c9                   	leave  
f0103631:	c3                   	ret    

f0103632 <lidt>:
	asm volatile("invlpg (%0)" : : "r" (addr) : "memory");
}

static inline void
lidt(void *p)
{
f0103632:	55                   	push   %ebp
f0103633:	89 e5                	mov    %esp,%ebp
	asm volatile("lidt (%0)" : : "r" (p));
f0103635:	0f 01 18             	lidtl  (%eax)
}
f0103638:	5d                   	pop    %ebp
f0103639:	c3                   	ret    

f010363a <ltr>:
	asm volatile("lldt %0" : : "r" (sel));
}

static inline void
ltr(uint16_t sel)
{
f010363a:	55                   	push   %ebp
f010363b:	89 e5                	mov    %esp,%ebp
	asm volatile("ltr %0" : : "r" (sel));
f010363d:	0f 00 d8             	ltr    %ax
}
f0103640:	5d                   	pop    %ebp
f0103641:	c3                   	ret    

f0103642 <rcr2>:
	return val;
}

static inline uint32_t
rcr2(void)
{
f0103642:	55                   	push   %ebp
f0103643:	89 e5                	mov    %esp,%ebp
	uint32_t val;
	asm volatile("movl %%cr2,%0" : "=r" (val));
f0103645:	0f 20 d0             	mov    %cr2,%eax
	return val;
}
f0103648:	5d                   	pop    %ebp
f0103649:	c3                   	ret    

f010364a <read_eflags>:
	asm volatile("movl %0,%%cr3" : : "r" (cr3));
}

static inline uint32_t
read_eflags(void)
{
f010364a:	55                   	push   %ebp
f010364b:	89 e5                	mov    %esp,%ebp
	uint32_t eflags;
	asm volatile("pushfl; popl %0" : "=r" (eflags));
f010364d:	9c                   	pushf  
f010364e:	58                   	pop    %eax
	return eflags;
}
f010364f:	5d                   	pop    %ebp
f0103650:	c3                   	ret    

f0103651 <trapname>:
struct Pseudodesc idt_pd = { sizeof(idt) - 1, (uint32_t) idt };


static const char *
trapname(int trapno)
{
f0103651:	55                   	push   %ebp
f0103652:	89 e5                	mov    %esp,%ebp
		"Alignment Check",
		"Machine-Check",
		"SIMD Floating-Point Exception"
	};

	if (trapno < ARRAY_SIZE(excnames))
f0103654:	83 f8 13             	cmp    $0x13,%eax
f0103657:	77 09                	ja     f0103662 <trapname+0x11>
		return excnames[trapno];
f0103659:	8b 04 85 00 60 10 f0 	mov    -0xfefa000(,%eax,4),%eax
f0103660:	eb 10                	jmp    f0103672 <trapname+0x21>
	if (trapno == T_SYSCALL)
f0103662:	83 f8 30             	cmp    $0x30,%eax
		return "System call";
f0103665:	b8 7e 5c 10 f0       	mov    $0xf0105c7e,%eax
f010366a:	ba 8a 5c 10 f0       	mov    $0xf0105c8a,%edx
f010366f:	0f 45 c2             	cmovne %edx,%eax
	return "(unknown trap)";
}
f0103672:	5d                   	pop    %ebp
f0103673:	c3                   	ret    

f0103674 <trap_init_percpu>:
}

// Initialize and load the per-CPU TSS and IDT
void
trap_init_percpu(void)
{
f0103674:	55                   	push   %ebp
f0103675:	89 e5                	mov    %esp,%ebp
	// Setup a TSS so that we get the right stack
	// when we trap to the kernel.
	ts.ts_esp0 = KSTACKTOP;
f0103677:	c7 05 04 5b 18 f0 00 	movl   $0xf0000000,0xf0185b04
f010367e:	00 00 f0 
	ts.ts_ss0 = GD_KD;
f0103681:	66 c7 05 08 5b 18 f0 	movw   $0x10,0xf0185b08
f0103688:	10 00 

	// Initialize the TSS slot of the gdt.
	gdt[GD_TSS0 >> 3] =
f010368a:	66 c7 05 48 b3 11 f0 	movw   $0x67,0xf011b348
f0103691:	67 00 
f0103693:	b8 00 5b 18 f0       	mov    $0xf0185b00,%eax
f0103698:	66 a3 4a b3 11 f0    	mov    %ax,0xf011b34a
	        SEG16(STS_T32A, (uint32_t)(&ts), sizeof(struct Taskstate) - 1, 0);
f010369e:	89 c2                	mov    %eax,%edx
f01036a0:	c1 ea 10             	shr    $0x10,%edx
	// when we trap to the kernel.
	ts.ts_esp0 = KSTACKTOP;
	ts.ts_ss0 = GD_KD;

	// Initialize the TSS slot of the gdt.
	gdt[GD_TSS0 >> 3] =
f01036a3:	88 15 4c b3 11 f0    	mov    %dl,0xf011b34c
f01036a9:	c6 05 4e b3 11 f0 40 	movb   $0x40,0xf011b34e
	        SEG16(STS_T32A, (uint32_t)(&ts), sizeof(struct Taskstate) - 1, 0);
f01036b0:	c1 e8 18             	shr    $0x18,%eax
	// when we trap to the kernel.
	ts.ts_esp0 = KSTACKTOP;
	ts.ts_ss0 = GD_KD;

	// Initialize the TSS slot of the gdt.
	gdt[GD_TSS0 >> 3] =
f01036b3:	a2 4f b3 11 f0       	mov    %al,0xf011b34f
	        SEG16(STS_T32A, (uint32_t)(&ts), sizeof(struct Taskstate) - 1, 0);
	gdt[GD_TSS0 >> 3].sd_s = 0;
f01036b8:	c6 05 4d b3 11 f0 89 	movb   $0x89,0xf011b34d

	// Load the TSS selector (like other segment selectors, the
	// bottom three bits are special; we leave them 0)
	ltr(GD_TSS0);
f01036bf:	b8 28 00 00 00       	mov    $0x28,%eax
f01036c4:	e8 71 ff ff ff       	call   f010363a <ltr>

	// Load the IDT
	lidt(&idt_pd);
f01036c9:	b8 50 b3 11 f0       	mov    $0xf011b350,%eax
f01036ce:	e8 5f ff ff ff       	call   f0103632 <lidt>
}
f01036d3:	5d                   	pop    %ebp
f01036d4:	c3                   	ret    

f01036d5 <trap_init>:
}


void
trap_init(void)
{
f01036d5:	55                   	push   %ebp
f01036d6:	89 e5                	mov    %esp,%ebp
	extern struct Segdesc gdt[];

	// LAB 3: Your code here.

	// Per-CPU setup
	trap_init_percpu();
f01036d8:	e8 97 ff ff ff       	call   f0103674 <trap_init_percpu>
}
f01036dd:	5d                   	pop    %ebp
f01036de:	c3                   	ret    

f01036df <print_regs>:
	}
}

void
print_regs(struct PushRegs *regs)
{
f01036df:	55                   	push   %ebp
f01036e0:	89 e5                	mov    %esp,%ebp
f01036e2:	53                   	push   %ebx
f01036e3:	83 ec 14             	sub    $0x14,%esp
f01036e6:	8b 5d 08             	mov    0x8(%ebp),%ebx
	cprintf("  edi  0x%08x\n", regs->reg_edi);
f01036e9:	8b 03                	mov    (%ebx),%eax
f01036eb:	89 44 24 04          	mov    %eax,0x4(%esp)
f01036ef:	c7 04 24 99 5c 10 f0 	movl   $0xf0105c99,(%esp)
f01036f6:	e8 1d ff ff ff       	call   f0103618 <cprintf>
	cprintf("  esi  0x%08x\n", regs->reg_esi);
f01036fb:	8b 43 04             	mov    0x4(%ebx),%eax
f01036fe:	89 44 24 04          	mov    %eax,0x4(%esp)
f0103702:	c7 04 24 a8 5c 10 f0 	movl   $0xf0105ca8,(%esp)
f0103709:	e8 0a ff ff ff       	call   f0103618 <cprintf>
	cprintf("  ebp  0x%08x\n", regs->reg_ebp);
f010370e:	8b 43 08             	mov    0x8(%ebx),%eax
f0103711:	89 44 24 04          	mov    %eax,0x4(%esp)
f0103715:	c7 04 24 b7 5c 10 f0 	movl   $0xf0105cb7,(%esp)
f010371c:	e8 f7 fe ff ff       	call   f0103618 <cprintf>
	cprintf("  oesp 0x%08x\n", regs->reg_oesp);
f0103721:	8b 43 0c             	mov    0xc(%ebx),%eax
f0103724:	89 44 24 04          	mov    %eax,0x4(%esp)
f0103728:	c7 04 24 c6 5c 10 f0 	movl   $0xf0105cc6,(%esp)
f010372f:	e8 e4 fe ff ff       	call   f0103618 <cprintf>
	cprintf("  ebx  0x%08x\n", regs->reg_ebx);
f0103734:	8b 43 10             	mov    0x10(%ebx),%eax
f0103737:	89 44 24 04          	mov    %eax,0x4(%esp)
f010373b:	c7 04 24 d5 5c 10 f0 	movl   $0xf0105cd5,(%esp)
f0103742:	e8 d1 fe ff ff       	call   f0103618 <cprintf>
	cprintf("  edx  0x%08x\n", regs->reg_edx);
f0103747:	8b 43 14             	mov    0x14(%ebx),%eax
f010374a:	89 44 24 04          	mov    %eax,0x4(%esp)
f010374e:	c7 04 24 e4 5c 10 f0 	movl   $0xf0105ce4,(%esp)
f0103755:	e8 be fe ff ff       	call   f0103618 <cprintf>
	cprintf("  ecx  0x%08x\n", regs->reg_ecx);
f010375a:	8b 43 18             	mov    0x18(%ebx),%eax
f010375d:	89 44 24 04          	mov    %eax,0x4(%esp)
f0103761:	c7 04 24 f3 5c 10 f0 	movl   $0xf0105cf3,(%esp)
f0103768:	e8 ab fe ff ff       	call   f0103618 <cprintf>
	cprintf("  eax  0x%08x\n", regs->reg_eax);
f010376d:	8b 43 1c             	mov    0x1c(%ebx),%eax
f0103770:	89 44 24 04          	mov    %eax,0x4(%esp)
f0103774:	c7 04 24 02 5d 10 f0 	movl   $0xf0105d02,(%esp)
f010377b:	e8 98 fe ff ff       	call   f0103618 <cprintf>
}
f0103780:	83 c4 14             	add    $0x14,%esp
f0103783:	5b                   	pop    %ebx
f0103784:	5d                   	pop    %ebp
f0103785:	c3                   	ret    

f0103786 <print_trapframe>:
	lidt(&idt_pd);
}

void
print_trapframe(struct Trapframe *tf)
{
f0103786:	55                   	push   %ebp
f0103787:	89 e5                	mov    %esp,%ebp
f0103789:	56                   	push   %esi
f010378a:	53                   	push   %ebx
f010378b:	83 ec 10             	sub    $0x10,%esp
f010378e:	8b 5d 08             	mov    0x8(%ebp),%ebx
	cprintf("TRAP frame at %p\n", tf);
f0103791:	89 5c 24 04          	mov    %ebx,0x4(%esp)
f0103795:	c7 04 24 36 5e 10 f0 	movl   $0xf0105e36,(%esp)
f010379c:	e8 77 fe ff ff       	call   f0103618 <cprintf>
	print_regs(&tf->tf_regs);
f01037a1:	89 1c 24             	mov    %ebx,(%esp)
f01037a4:	e8 36 ff ff ff       	call   f01036df <print_regs>
	cprintf("  es   0x----%04x\n", tf->tf_es);
f01037a9:	0f b7 43 20          	movzwl 0x20(%ebx),%eax
f01037ad:	89 44 24 04          	mov    %eax,0x4(%esp)
f01037b1:	c7 04 24 38 5d 10 f0 	movl   $0xf0105d38,(%esp)
f01037b8:	e8 5b fe ff ff       	call   f0103618 <cprintf>
	cprintf("  ds   0x----%04x\n", tf->tf_ds);
f01037bd:	0f b7 43 24          	movzwl 0x24(%ebx),%eax
f01037c1:	89 44 24 04          	mov    %eax,0x4(%esp)
f01037c5:	c7 04 24 4b 5d 10 f0 	movl   $0xf0105d4b,(%esp)
f01037cc:	e8 47 fe ff ff       	call   f0103618 <cprintf>
	cprintf("  trap 0x%08x %s\n", tf->tf_trapno, trapname(tf->tf_trapno));
f01037d1:	8b 73 28             	mov    0x28(%ebx),%esi
f01037d4:	89 f0                	mov    %esi,%eax
f01037d6:	e8 76 fe ff ff       	call   f0103651 <trapname>
f01037db:	89 44 24 08          	mov    %eax,0x8(%esp)
f01037df:	89 74 24 04          	mov    %esi,0x4(%esp)
f01037e3:	c7 04 24 5e 5d 10 f0 	movl   $0xf0105d5e,(%esp)
f01037ea:	e8 29 fe ff ff       	call   f0103618 <cprintf>
	// If this trap was a page fault that just happened
	// (so %cr2 is meaningful), print the faulting linear address.
	if (tf == last_tf && tf->tf_trapno == T_PGFLT)
f01037ef:	3b 1d e0 5a 18 f0    	cmp    0xf0185ae0,%ebx
f01037f5:	75 1b                	jne    f0103812 <print_trapframe+0x8c>
f01037f7:	83 7b 28 0e          	cmpl   $0xe,0x28(%ebx)
f01037fb:	75 15                	jne    f0103812 <print_trapframe+0x8c>
		cprintf("  cr2  0x%08x\n", rcr2());
f01037fd:	e8 40 fe ff ff       	call   f0103642 <rcr2>
f0103802:	89 44 24 04          	mov    %eax,0x4(%esp)
f0103806:	c7 04 24 70 5d 10 f0 	movl   $0xf0105d70,(%esp)
f010380d:	e8 06 fe ff ff       	call   f0103618 <cprintf>
	cprintf("  err  0x%08x", tf->tf_err);
f0103812:	8b 43 2c             	mov    0x2c(%ebx),%eax
f0103815:	89 44 24 04          	mov    %eax,0x4(%esp)
f0103819:	c7 04 24 7f 5d 10 f0 	movl   $0xf0105d7f,(%esp)
f0103820:	e8 f3 fd ff ff       	call   f0103618 <cprintf>
	// For page faults, print decoded fault error code:
	// U/K=fault occurred in user/kernel mode
	// W/R=a write/read caused the fault
	// PR=a protection violation caused the fault (NP=page not present).
	if (tf->tf_trapno == T_PGFLT)
f0103825:	83 7b 28 0e          	cmpl   $0xe,0x28(%ebx)
f0103829:	75 51                	jne    f010387c <print_trapframe+0xf6>
		cprintf(" [%s, %s, %s]\n",
		        tf->tf_err & 4 ? "user" : "kernel",
		        tf->tf_err & 2 ? "write" : "read",
		        tf->tf_err & 1 ? "protection" : "not-present");
f010382b:	8b 43 2c             	mov    0x2c(%ebx),%eax
	// For page faults, print decoded fault error code:
	// U/K=fault occurred in user/kernel mode
	// W/R=a write/read caused the fault
	// PR=a protection violation caused the fault (NP=page not present).
	if (tf->tf_trapno == T_PGFLT)
		cprintf(" [%s, %s, %s]\n",
f010382e:	89 c2                	mov    %eax,%edx
f0103830:	83 e2 01             	and    $0x1,%edx
f0103833:	ba 11 5d 10 f0       	mov    $0xf0105d11,%edx
f0103838:	b9 1c 5d 10 f0       	mov    $0xf0105d1c,%ecx
f010383d:	0f 45 ca             	cmovne %edx,%ecx
f0103840:	89 c2                	mov    %eax,%edx
f0103842:	83 e2 02             	and    $0x2,%edx
f0103845:	ba 28 5d 10 f0       	mov    $0xf0105d28,%edx
f010384a:	be 2e 5d 10 f0       	mov    $0xf0105d2e,%esi
f010384f:	0f 44 d6             	cmove  %esi,%edx
f0103852:	83 e0 04             	and    $0x4,%eax
f0103855:	b8 33 5d 10 f0       	mov    $0xf0105d33,%eax
f010385a:	be 01 5e 10 f0       	mov    $0xf0105e01,%esi
f010385f:	0f 44 c6             	cmove  %esi,%eax
f0103862:	89 4c 24 0c          	mov    %ecx,0xc(%esp)
f0103866:	89 54 24 08          	mov    %edx,0x8(%esp)
f010386a:	89 44 24 04          	mov    %eax,0x4(%esp)
f010386e:	c7 04 24 8d 5d 10 f0 	movl   $0xf0105d8d,(%esp)
f0103875:	e8 9e fd ff ff       	call   f0103618 <cprintf>
f010387a:	eb 0c                	jmp    f0103888 <print_trapframe+0x102>
		        tf->tf_err & 4 ? "user" : "kernel",
		        tf->tf_err & 2 ? "write" : "read",
		        tf->tf_err & 1 ? "protection" : "not-present");
	else
		cprintf("\n");
f010387c:	c7 04 24 ea 5a 10 f0 	movl   $0xf0105aea,(%esp)
f0103883:	e8 90 fd ff ff       	call   f0103618 <cprintf>
	cprintf("  eip  0x%08x\n", tf->tf_eip);
f0103888:	8b 43 30             	mov    0x30(%ebx),%eax
f010388b:	89 44 24 04          	mov    %eax,0x4(%esp)
f010388f:	c7 04 24 9c 5d 10 f0 	movl   $0xf0105d9c,(%esp)
f0103896:	e8 7d fd ff ff       	call   f0103618 <cprintf>
	cprintf("  cs   0x----%04x\n", tf->tf_cs);
f010389b:	0f b7 43 34          	movzwl 0x34(%ebx),%eax
f010389f:	89 44 24 04          	mov    %eax,0x4(%esp)
f01038a3:	c7 04 24 ab 5d 10 f0 	movl   $0xf0105dab,(%esp)
f01038aa:	e8 69 fd ff ff       	call   f0103618 <cprintf>
	cprintf("  flag 0x%08x\n", tf->tf_eflags);
f01038af:	8b 43 38             	mov    0x38(%ebx),%eax
f01038b2:	89 44 24 04          	mov    %eax,0x4(%esp)
f01038b6:	c7 04 24 be 5d 10 f0 	movl   $0xf0105dbe,(%esp)
f01038bd:	e8 56 fd ff ff       	call   f0103618 <cprintf>
	if ((tf->tf_cs & 3) != 0) {
f01038c2:	f6 43 34 03          	testb  $0x3,0x34(%ebx)
f01038c6:	74 27                	je     f01038ef <print_trapframe+0x169>
		cprintf("  esp  0x%08x\n", tf->tf_esp);
f01038c8:	8b 43 3c             	mov    0x3c(%ebx),%eax
f01038cb:	89 44 24 04          	mov    %eax,0x4(%esp)
f01038cf:	c7 04 24 cd 5d 10 f0 	movl   $0xf0105dcd,(%esp)
f01038d6:	e8 3d fd ff ff       	call   f0103618 <cprintf>
		cprintf("  ss   0x----%04x\n", tf->tf_ss);
f01038db:	0f b7 43 40          	movzwl 0x40(%ebx),%eax
f01038df:	89 44 24 04          	mov    %eax,0x4(%esp)
f01038e3:	c7 04 24 dc 5d 10 f0 	movl   $0xf0105ddc,(%esp)
f01038ea:	e8 29 fd ff ff       	call   f0103618 <cprintf>
	}
}
f01038ef:	83 c4 10             	add    $0x10,%esp
f01038f2:	5b                   	pop    %ebx
f01038f3:	5e                   	pop    %esi
f01038f4:	5d                   	pop    %ebp
f01038f5:	c3                   	ret    

f01038f6 <trap_dispatch>:
	cprintf("  eax  0x%08x\n", regs->reg_eax);
}

static void
trap_dispatch(struct Trapframe *tf)
{
f01038f6:	55                   	push   %ebp
f01038f7:	89 e5                	mov    %esp,%ebp
f01038f9:	53                   	push   %ebx
f01038fa:	83 ec 14             	sub    $0x14,%esp
f01038fd:	89 c3                	mov    %eax,%ebx
	// Handle processor exceptions.
	// LAB 3: Your code here.

	// Unexpected trap: The user process or the kernel has a bug.
	print_trapframe(tf);
f01038ff:	89 04 24             	mov    %eax,(%esp)
f0103902:	e8 7f fe ff ff       	call   f0103786 <print_trapframe>
	if (tf->tf_cs == GD_KT)
f0103907:	66 83 7b 34 08       	cmpw   $0x8,0x34(%ebx)
f010390c:	75 1c                	jne    f010392a <trap_dispatch+0x34>
		panic("unhandled trap in kernel");
f010390e:	c7 44 24 08 ef 5d 10 	movl   $0xf0105def,0x8(%esp)
f0103915:	f0 
f0103916:	c7 44 24 04 95 00 00 	movl   $0x95,0x4(%esp)
f010391d:	00 
f010391e:	c7 04 24 08 5e 10 f0 	movl   $0xf0105e08,(%esp)
f0103925:	e8 7f c7 ff ff       	call   f01000a9 <_panic>
	else {
		env_destroy(curenv);
f010392a:	a1 c4 52 18 f0       	mov    0xf01852c4,%eax
f010392f:	89 04 24             	mov    %eax,(%esp)
f0103932:	e8 88 fb ff ff       	call   f01034bf <env_destroy>
		return;
	}
}
f0103937:	83 c4 14             	add    $0x14,%esp
f010393a:	5b                   	pop    %ebx
f010393b:	5d                   	pop    %ebp
f010393c:	c3                   	ret    

f010393d <trap>:

void
trap(struct Trapframe *tf)
{
f010393d:	55                   	push   %ebp
f010393e:	89 e5                	mov    %esp,%ebp
f0103940:	57                   	push   %edi
f0103941:	56                   	push   %esi
f0103942:	83 ec 10             	sub    $0x10,%esp
f0103945:	8b 75 08             	mov    0x8(%ebp),%esi
	// The environment may have set DF and some versions
	// of GCC rely on DF being clear
	asm volatile("cld" ::: "cc");
f0103948:	fc                   	cld    

	// Check that interrupts are disabled.  If this assertion
	// fails, DO NOT be tempted to fix it by inserting a "cli" in
	// the interrupt path.
	assert(!(read_eflags() & FL_IF));
f0103949:	e8 fc fc ff ff       	call   f010364a <read_eflags>
f010394e:	f6 c4 02             	test   $0x2,%ah
f0103951:	74 24                	je     f0103977 <trap+0x3a>
f0103953:	c7 44 24 0c 14 5e 10 	movl   $0xf0105e14,0xc(%esp)
f010395a:	f0 
f010395b:	c7 44 24 08 da 57 10 	movl   $0xf01057da,0x8(%esp)
f0103962:	f0 
f0103963:	c7 44 24 04 a6 00 00 	movl   $0xa6,0x4(%esp)
f010396a:	00 
f010396b:	c7 04 24 08 5e 10 f0 	movl   $0xf0105e08,(%esp)
f0103972:	e8 32 c7 ff ff       	call   f01000a9 <_panic>

	cprintf("Incoming TRAP frame at %p\n", tf);
f0103977:	89 74 24 04          	mov    %esi,0x4(%esp)
f010397b:	c7 04 24 2d 5e 10 f0 	movl   $0xf0105e2d,(%esp)
f0103982:	e8 91 fc ff ff       	call   f0103618 <cprintf>

	if ((tf->tf_cs & 3) == 3) {
f0103987:	0f b7 46 34          	movzwl 0x34(%esi),%eax
f010398b:	83 e0 03             	and    $0x3,%eax
f010398e:	66 83 f8 03          	cmp    $0x3,%ax
f0103992:	75 3c                	jne    f01039d0 <trap+0x93>
		// Trapped from user mode.
		assert(curenv);
f0103994:	a1 c4 52 18 f0       	mov    0xf01852c4,%eax
f0103999:	85 c0                	test   %eax,%eax
f010399b:	75 24                	jne    f01039c1 <trap+0x84>
f010399d:	c7 44 24 0c 48 5e 10 	movl   $0xf0105e48,0xc(%esp)
f01039a4:	f0 
f01039a5:	c7 44 24 08 da 57 10 	movl   $0xf01057da,0x8(%esp)
f01039ac:	f0 
f01039ad:	c7 44 24 04 ac 00 00 	movl   $0xac,0x4(%esp)
f01039b4:	00 
f01039b5:	c7 04 24 08 5e 10 f0 	movl   $0xf0105e08,(%esp)
f01039bc:	e8 e8 c6 ff ff       	call   f01000a9 <_panic>

		// Copy trap frame (which is currently on the stack)
		// into 'curenv->env_tf', so that running the environment
		// will restart at the trap point.
		curenv->env_tf = *tf;
f01039c1:	b9 11 00 00 00       	mov    $0x11,%ecx
f01039c6:	89 c7                	mov    %eax,%edi
f01039c8:	f3 a5                	rep movsl %ds:(%esi),%es:(%edi)
		// The trapframe on the stack should be ignored from here on.
		tf = &curenv->env_tf;
f01039ca:	8b 35 c4 52 18 f0    	mov    0xf01852c4,%esi
	}

	// Record that tf is the last real trapframe so
	// print_trapframe can print some additional information.
	last_tf = tf;
f01039d0:	89 35 e0 5a 18 f0    	mov    %esi,0xf0185ae0

	// Dispatch based on what type of trap occurred
	trap_dispatch(tf);
f01039d6:	89 f0                	mov    %esi,%eax
f01039d8:	e8 19 ff ff ff       	call   f01038f6 <trap_dispatch>

	// Return to the current environment, which should be running.
	assert(curenv && curenv->env_status == ENV_RUNNING);
f01039dd:	a1 c4 52 18 f0       	mov    0xf01852c4,%eax
f01039e2:	85 c0                	test   %eax,%eax
f01039e4:	74 06                	je     f01039ec <trap+0xaf>
f01039e6:	83 78 54 03          	cmpl   $0x3,0x54(%eax)
f01039ea:	74 24                	je     f0103a10 <trap+0xd3>
f01039ec:	c7 44 24 0c 94 5f 10 	movl   $0xf0105f94,0xc(%esp)
f01039f3:	f0 
f01039f4:	c7 44 24 08 da 57 10 	movl   $0xf01057da,0x8(%esp)
f01039fb:	f0 
f01039fc:	c7 44 24 04 be 00 00 	movl   $0xbe,0x4(%esp)
f0103a03:	00 
f0103a04:	c7 04 24 08 5e 10 f0 	movl   $0xf0105e08,(%esp)
f0103a0b:	e8 99 c6 ff ff       	call   f01000a9 <_panic>
	env_run(curenv);
f0103a10:	89 04 24             	mov    %eax,(%esp)
f0103a13:	e8 f7 fa ff ff       	call   f010350f <env_run>

f0103a18 <page_fault_handler>:
}


void
page_fault_handler(struct Trapframe *tf)
{
f0103a18:	55                   	push   %ebp
f0103a19:	89 e5                	mov    %esp,%ebp
f0103a1b:	53                   	push   %ebx
f0103a1c:	83 ec 14             	sub    $0x14,%esp
f0103a1f:	8b 5d 08             	mov    0x8(%ebp),%ebx
	uint32_t fault_va;

	// Read processor's CR2 register to find the faulting address
	fault_va = rcr2();
f0103a22:	e8 1b fc ff ff       	call   f0103642 <rcr2>

	// We've already handled kernel-mode exceptions, so if we get here,
	// the page fault happened in user mode.

	// Destroy the environment that caused the fault.
	cprintf("[%08x] user fault va %08x ip %08x\n",
f0103a27:	8b 53 30             	mov    0x30(%ebx),%edx
f0103a2a:	89 54 24 0c          	mov    %edx,0xc(%esp)
f0103a2e:	89 44 24 08          	mov    %eax,0x8(%esp)
f0103a32:	a1 c4 52 18 f0       	mov    0xf01852c4,%eax
f0103a37:	8b 40 48             	mov    0x48(%eax),%eax
f0103a3a:	89 44 24 04          	mov    %eax,0x4(%esp)
f0103a3e:	c7 04 24 c0 5f 10 f0 	movl   $0xf0105fc0,(%esp)
f0103a45:	e8 ce fb ff ff       	call   f0103618 <cprintf>
	        curenv->env_id,
	        fault_va,
	        tf->tf_eip);
	print_trapframe(tf);
f0103a4a:	89 1c 24             	mov    %ebx,(%esp)
f0103a4d:	e8 34 fd ff ff       	call   f0103786 <print_trapframe>
	env_destroy(curenv);
f0103a52:	a1 c4 52 18 f0       	mov    0xf01852c4,%eax
f0103a57:	89 04 24             	mov    %eax,(%esp)
f0103a5a:	e8 60 fa ff ff       	call   f01034bf <env_destroy>
}
f0103a5f:	83 c4 14             	add    $0x14,%esp
f0103a62:	5b                   	pop    %ebx
f0103a63:	5d                   	pop    %ebp
f0103a64:	c3                   	ret    

f0103a65 <syscall>:
f0103a65:	55                   	push   %ebp
f0103a66:	89 e5                	mov    %esp,%ebp
f0103a68:	83 ec 18             	sub    $0x18,%esp
f0103a6b:	c7 44 24 08 50 60 10 	movl   $0xf0106050,0x8(%esp)
f0103a72:	f0 
f0103a73:	c7 44 24 04 49 00 00 	movl   $0x49,0x4(%esp)
f0103a7a:	00 
f0103a7b:	c7 04 24 68 60 10 f0 	movl   $0xf0106068,(%esp)
f0103a82:	e8 22 c6 ff ff       	call   f01000a9 <_panic>

f0103a87 <stab_binsearch>:
stab_binsearch(const struct Stab *stabs,
               int *region_left,
               int *region_right,
               int type,
               uintptr_t addr)
{
f0103a87:	55                   	push   %ebp
f0103a88:	89 e5                	mov    %esp,%ebp
f0103a8a:	57                   	push   %edi
f0103a8b:	56                   	push   %esi
f0103a8c:	53                   	push   %ebx
f0103a8d:	83 ec 14             	sub    $0x14,%esp
f0103a90:	89 45 ec             	mov    %eax,-0x14(%ebp)
f0103a93:	89 55 e4             	mov    %edx,-0x1c(%ebp)
f0103a96:	89 4d e0             	mov    %ecx,-0x20(%ebp)
f0103a99:	8b 75 08             	mov    0x8(%ebp),%esi
	int l = *region_left, r = *region_right, any_matches = 0;
f0103a9c:	8b 1a                	mov    (%edx),%ebx
f0103a9e:	8b 01                	mov    (%ecx),%eax
f0103aa0:	89 45 f0             	mov    %eax,-0x10(%ebp)
f0103aa3:	c7 45 e8 00 00 00 00 	movl   $0x0,-0x18(%ebp)

	while (l <= r) {
f0103aaa:	e9 88 00 00 00       	jmp    f0103b37 <stab_binsearch+0xb0>
		int true_m = (l + r) / 2, m = true_m;
f0103aaf:	8b 45 f0             	mov    -0x10(%ebp),%eax
f0103ab2:	01 d8                	add    %ebx,%eax
f0103ab4:	89 c7                	mov    %eax,%edi
f0103ab6:	c1 ef 1f             	shr    $0x1f,%edi
f0103ab9:	01 c7                	add    %eax,%edi
f0103abb:	d1 ff                	sar    %edi
f0103abd:	8d 04 7f             	lea    (%edi,%edi,2),%eax
f0103ac0:	8b 4d ec             	mov    -0x14(%ebp),%ecx
f0103ac3:	8d 14 81             	lea    (%ecx,%eax,4),%edx
f0103ac6:	89 f8                	mov    %edi,%eax

		// search for earliest stab with right type
		while (m >= l && stabs[m].n_type != type)
f0103ac8:	eb 03                	jmp    f0103acd <stab_binsearch+0x46>
			m--;
f0103aca:	83 e8 01             	sub    $0x1,%eax

	while (l <= r) {
		int true_m = (l + r) / 2, m = true_m;

		// search for earliest stab with right type
		while (m >= l && stabs[m].n_type != type)
f0103acd:	39 c3                	cmp    %eax,%ebx
f0103acf:	7f 1f                	jg     f0103af0 <stab_binsearch+0x69>
f0103ad1:	0f b6 4a 04          	movzbl 0x4(%edx),%ecx
f0103ad5:	83 ea 0c             	sub    $0xc,%edx
f0103ad8:	39 f1                	cmp    %esi,%ecx
f0103ada:	75 ee                	jne    f0103aca <stab_binsearch+0x43>
f0103adc:	89 45 e8             	mov    %eax,-0x18(%ebp)
			continue;
		}

		// actual binary search
		any_matches = 1;
		if (stabs[m].n_value < addr) {
f0103adf:	8d 14 40             	lea    (%eax,%eax,2),%edx
f0103ae2:	8b 4d ec             	mov    -0x14(%ebp),%ecx
f0103ae5:	8b 54 91 08          	mov    0x8(%ecx,%edx,4),%edx
f0103ae9:	39 55 0c             	cmp    %edx,0xc(%ebp)
f0103aec:	76 18                	jbe    f0103b06 <stab_binsearch+0x7f>
f0103aee:	eb 05                	jmp    f0103af5 <stab_binsearch+0x6e>

		// search for earliest stab with right type
		while (m >= l && stabs[m].n_type != type)
			m--;
		if (m < l) {  // no match in [l, m]
			l = true_m + 1;
f0103af0:	8d 5f 01             	lea    0x1(%edi),%ebx
			continue;
f0103af3:	eb 42                	jmp    f0103b37 <stab_binsearch+0xb0>
		}

		// actual binary search
		any_matches = 1;
		if (stabs[m].n_value < addr) {
			*region_left = m;
f0103af5:	8b 5d e4             	mov    -0x1c(%ebp),%ebx
f0103af8:	89 03                	mov    %eax,(%ebx)
			l = true_m + 1;
f0103afa:	8d 5f 01             	lea    0x1(%edi),%ebx
			l = true_m + 1;
			continue;
		}

		// actual binary search
		any_matches = 1;
f0103afd:	c7 45 e8 01 00 00 00 	movl   $0x1,-0x18(%ebp)
f0103b04:	eb 31                	jmp    f0103b37 <stab_binsearch+0xb0>
		if (stabs[m].n_value < addr) {
			*region_left = m;
			l = true_m + 1;
		} else if (stabs[m].n_value > addr) {
f0103b06:	39 55 0c             	cmp    %edx,0xc(%ebp)
f0103b09:	73 17                	jae    f0103b22 <stab_binsearch+0x9b>
			*region_right = m - 1;
f0103b0b:	8b 45 e8             	mov    -0x18(%ebp),%eax
f0103b0e:	83 e8 01             	sub    $0x1,%eax
f0103b11:	89 45 f0             	mov    %eax,-0x10(%ebp)
f0103b14:	8b 7d e0             	mov    -0x20(%ebp),%edi
f0103b17:	89 07                	mov    %eax,(%edi)
			l = true_m + 1;
			continue;
		}

		// actual binary search
		any_matches = 1;
f0103b19:	c7 45 e8 01 00 00 00 	movl   $0x1,-0x18(%ebp)
f0103b20:	eb 15                	jmp    f0103b37 <stab_binsearch+0xb0>
			*region_right = m - 1;
			r = m - 1;
		} else {
			// exact match for 'addr', but continue loop to find
			// *region_right
			*region_left = m;
f0103b22:	8b 7d e4             	mov    -0x1c(%ebp),%edi
f0103b25:	8b 5d e8             	mov    -0x18(%ebp),%ebx
f0103b28:	89 1f                	mov    %ebx,(%edi)
			l = m;
			addr++;
f0103b2a:	83 45 0c 01          	addl   $0x1,0xc(%ebp)
f0103b2e:	89 c3                	mov    %eax,%ebx
			l = true_m + 1;
			continue;
		}

		// actual binary search
		any_matches = 1;
f0103b30:	c7 45 e8 01 00 00 00 	movl   $0x1,-0x18(%ebp)
               int type,
               uintptr_t addr)
{
	int l = *region_left, r = *region_right, any_matches = 0;

	while (l <= r) {
f0103b37:	3b 5d f0             	cmp    -0x10(%ebp),%ebx
f0103b3a:	0f 8e 6f ff ff ff    	jle    f0103aaf <stab_binsearch+0x28>
			l = m;
			addr++;
		}
	}

	if (!any_matches)
f0103b40:	83 7d e8 00          	cmpl   $0x0,-0x18(%ebp)
f0103b44:	75 0f                	jne    f0103b55 <stab_binsearch+0xce>
		*region_right = *region_left - 1;
f0103b46:	8b 45 e4             	mov    -0x1c(%ebp),%eax
f0103b49:	8b 00                	mov    (%eax),%eax
f0103b4b:	83 e8 01             	sub    $0x1,%eax
f0103b4e:	8b 7d e0             	mov    -0x20(%ebp),%edi
f0103b51:	89 07                	mov    %eax,(%edi)
f0103b53:	eb 2c                	jmp    f0103b81 <stab_binsearch+0xfa>
	else {
		// find rightmost region containing 'addr'
		for (l = *region_right;
f0103b55:	8b 45 e0             	mov    -0x20(%ebp),%eax
f0103b58:	8b 00                	mov    (%eax),%eax
		     l > *region_left && stabs[l].n_type != type;
f0103b5a:	8b 7d e4             	mov    -0x1c(%ebp),%edi
f0103b5d:	8b 0f                	mov    (%edi),%ecx
f0103b5f:	8d 14 40             	lea    (%eax,%eax,2),%edx
f0103b62:	8b 7d ec             	mov    -0x14(%ebp),%edi
f0103b65:	8d 14 97             	lea    (%edi,%edx,4),%edx

	if (!any_matches)
		*region_right = *region_left - 1;
	else {
		// find rightmost region containing 'addr'
		for (l = *region_right;
f0103b68:	eb 03                	jmp    f0103b6d <stab_binsearch+0xe6>
		     l > *region_left && stabs[l].n_type != type;
		     l--)
f0103b6a:	83 e8 01             	sub    $0x1,%eax

	if (!any_matches)
		*region_right = *region_left - 1;
	else {
		// find rightmost region containing 'addr'
		for (l = *region_right;
f0103b6d:	39 c8                	cmp    %ecx,%eax
f0103b6f:	7e 0b                	jle    f0103b7c <stab_binsearch+0xf5>
		     l > *region_left && stabs[l].n_type != type;
f0103b71:	0f b6 5a 04          	movzbl 0x4(%edx),%ebx
f0103b75:	83 ea 0c             	sub    $0xc,%edx
f0103b78:	39 f3                	cmp    %esi,%ebx
f0103b7a:	75 ee                	jne    f0103b6a <stab_binsearch+0xe3>
		     l--)
			/* do nothing */;
		*region_left = l;
f0103b7c:	8b 7d e4             	mov    -0x1c(%ebp),%edi
f0103b7f:	89 07                	mov    %eax,(%edi)
	}
}
f0103b81:	83 c4 14             	add    $0x14,%esp
f0103b84:	5b                   	pop    %ebx
f0103b85:	5e                   	pop    %esi
f0103b86:	5f                   	pop    %edi
f0103b87:	5d                   	pop    %ebp
f0103b88:	c3                   	ret    

f0103b89 <debuginfo_eip>:
//	negative if not.  But even if it returns negative it has stored some
//	information into '*info'.
//
int
debuginfo_eip(uintptr_t addr, struct Eipdebuginfo *info)
{
f0103b89:	55                   	push   %ebp
f0103b8a:	89 e5                	mov    %esp,%ebp
f0103b8c:	57                   	push   %edi
f0103b8d:	56                   	push   %esi
f0103b8e:	53                   	push   %ebx
f0103b8f:	83 ec 4c             	sub    $0x4c,%esp
f0103b92:	8b 5d 08             	mov    0x8(%ebp),%ebx
f0103b95:	8b 7d 0c             	mov    0xc(%ebp),%edi
	const struct Stab *stabs, *stab_end;
	const char *stabstr, *stabstr_end;
	int lfile, rfile, lfun, rfun, lline, rline;

	// Initialize *info
	info->eip_file = "<unknown>";
f0103b98:	c7 07 77 60 10 f0    	movl   $0xf0106077,(%edi)
	info->eip_line = 0;
f0103b9e:	c7 47 04 00 00 00 00 	movl   $0x0,0x4(%edi)
	info->eip_fn_name = "<unknown>";
f0103ba5:	c7 47 08 77 60 10 f0 	movl   $0xf0106077,0x8(%edi)
	info->eip_fn_namelen = 9;
f0103bac:	c7 47 0c 09 00 00 00 	movl   $0x9,0xc(%edi)
	info->eip_fn_addr = addr;
f0103bb3:	89 5f 10             	mov    %ebx,0x10(%edi)
	info->eip_fn_narg = 0;
f0103bb6:	c7 47 14 00 00 00 00 	movl   $0x0,0x14(%edi)

	// Find the relevant set of stabs
	if (addr >= ULIM) {
f0103bbd:	81 fb ff ff 7f ef    	cmp    $0xef7fffff,%ebx
f0103bc3:	77 21                	ja     f0103be6 <debuginfo_eip+0x5d>

		// Make sure this memory is valid.
		// Return -1 if it is not.  Hint: Call user_mem_check.
		// LAB 3: Your code here.

		stabs = usd->stabs;
f0103bc5:	a1 00 00 20 00       	mov    0x200000,%eax
f0103bca:	89 45 c4             	mov    %eax,-0x3c(%ebp)
		stab_end = usd->stab_end;
f0103bcd:	a1 04 00 20 00       	mov    0x200004,%eax
		stabstr = usd->stabstr;
f0103bd2:	8b 35 08 00 20 00    	mov    0x200008,%esi
f0103bd8:	89 75 c0             	mov    %esi,-0x40(%ebp)
		stabstr_end = usd->stabstr_end;
f0103bdb:	8b 35 0c 00 20 00    	mov    0x20000c,%esi
f0103be1:	89 75 bc             	mov    %esi,-0x44(%ebp)
f0103be4:	eb 1a                	jmp    f0103c00 <debuginfo_eip+0x77>
	// Find the relevant set of stabs
	if (addr >= ULIM) {
		stabs = __STAB_BEGIN__;
		stab_end = __STAB_END__;
		stabstr = __STABSTR_BEGIN__;
		stabstr_end = __STABSTR_END__;
f0103be6:	c7 45 bc 5d 10 11 f0 	movl   $0xf011105d,-0x44(%ebp)

	// Find the relevant set of stabs
	if (addr >= ULIM) {
		stabs = __STAB_BEGIN__;
		stab_end = __STAB_END__;
		stabstr = __STABSTR_BEGIN__;
f0103bed:	c7 45 c0 8d de 10 f0 	movl   $0xf010de8d,-0x40(%ebp)
	info->eip_fn_narg = 0;

	// Find the relevant set of stabs
	if (addr >= ULIM) {
		stabs = __STAB_BEGIN__;
		stab_end = __STAB_END__;
f0103bf4:	b8 8c de 10 f0       	mov    $0xf010de8c,%eax
	info->eip_fn_addr = addr;
	info->eip_fn_narg = 0;

	// Find the relevant set of stabs
	if (addr >= ULIM) {
		stabs = __STAB_BEGIN__;
f0103bf9:	c7 45 c4 90 62 10 f0 	movl   $0xf0106290,-0x3c(%ebp)
		// Make sure the STABS and string table memory is valid.
		// LAB 3: Your code here.
	}

	// String table validity checks
	if (stabstr_end <= stabstr || stabstr_end[-1] != 0)
f0103c00:	8b 75 bc             	mov    -0x44(%ebp),%esi
f0103c03:	39 75 c0             	cmp    %esi,-0x40(%ebp)
f0103c06:	0f 83 9f 01 00 00    	jae    f0103dab <debuginfo_eip+0x222>
f0103c0c:	80 7e ff 00          	cmpb   $0x0,-0x1(%esi)
f0103c10:	0f 85 9c 01 00 00    	jne    f0103db2 <debuginfo_eip+0x229>
	// 'eip'.  First, we find the basic source file containing 'eip'.
	// Then, we look in that source file for the function.  Then we look
	// for the line number.

	// Search the entire set of stabs for the source file (type N_SO).
	lfile = 0;
f0103c16:	c7 45 e4 00 00 00 00 	movl   $0x0,-0x1c(%ebp)
	rfile = (stab_end - stabs) - 1;
f0103c1d:	8b 75 c4             	mov    -0x3c(%ebp),%esi
f0103c20:	29 f0                	sub    %esi,%eax
f0103c22:	c1 f8 02             	sar    $0x2,%eax
f0103c25:	69 c0 ab aa aa aa    	imul   $0xaaaaaaab,%eax,%eax
f0103c2b:	83 e8 01             	sub    $0x1,%eax
f0103c2e:	89 45 e0             	mov    %eax,-0x20(%ebp)
	stab_binsearch(stabs, &lfile, &rfile, N_SO, addr);
f0103c31:	89 5c 24 04          	mov    %ebx,0x4(%esp)
f0103c35:	c7 04 24 64 00 00 00 	movl   $0x64,(%esp)
f0103c3c:	8d 4d e0             	lea    -0x20(%ebp),%ecx
f0103c3f:	8d 55 e4             	lea    -0x1c(%ebp),%edx
f0103c42:	89 f0                	mov    %esi,%eax
f0103c44:	e8 3e fe ff ff       	call   f0103a87 <stab_binsearch>
	if (lfile == 0)
f0103c49:	8b 45 e4             	mov    -0x1c(%ebp),%eax
f0103c4c:	85 c0                	test   %eax,%eax
f0103c4e:	0f 84 65 01 00 00    	je     f0103db9 <debuginfo_eip+0x230>
		return -1;

	// Search within that file's stabs for the function definition
	// (N_FUN).
	lfun = lfile;
f0103c54:	89 45 dc             	mov    %eax,-0x24(%ebp)
	rfun = rfile;
f0103c57:	8b 45 e0             	mov    -0x20(%ebp),%eax
f0103c5a:	89 45 d8             	mov    %eax,-0x28(%ebp)
	stab_binsearch(stabs, &lfun, &rfun, N_FUN, addr);
f0103c5d:	89 5c 24 04          	mov    %ebx,0x4(%esp)
f0103c61:	c7 04 24 24 00 00 00 	movl   $0x24,(%esp)
f0103c68:	8d 4d d8             	lea    -0x28(%ebp),%ecx
f0103c6b:	8d 55 dc             	lea    -0x24(%ebp),%edx
f0103c6e:	89 f0                	mov    %esi,%eax
f0103c70:	e8 12 fe ff ff       	call   f0103a87 <stab_binsearch>

	if (lfun <= rfun) {
f0103c75:	8b 45 dc             	mov    -0x24(%ebp),%eax
f0103c78:	8b 4d d8             	mov    -0x28(%ebp),%ecx
f0103c7b:	39 c8                	cmp    %ecx,%eax
f0103c7d:	7f 32                	jg     f0103cb1 <debuginfo_eip+0x128>
		// stabs[lfun] points to the function name
		// in the string table, but check bounds just in case.
		if (stabs[lfun].n_strx < stabstr_end - stabstr)
f0103c7f:	8d 14 40             	lea    (%eax,%eax,2),%edx
f0103c82:	8b 75 c4             	mov    -0x3c(%ebp),%esi
f0103c85:	8d 34 96             	lea    (%esi,%edx,4),%esi
f0103c88:	8b 16                	mov    (%esi),%edx
f0103c8a:	89 55 b8             	mov    %edx,-0x48(%ebp)
f0103c8d:	8b 55 bc             	mov    -0x44(%ebp),%edx
f0103c90:	2b 55 c0             	sub    -0x40(%ebp),%edx
f0103c93:	39 55 b8             	cmp    %edx,-0x48(%ebp)
f0103c96:	73 09                	jae    f0103ca1 <debuginfo_eip+0x118>
			info->eip_fn_name = stabstr + stabs[lfun].n_strx;
f0103c98:	8b 55 b8             	mov    -0x48(%ebp),%edx
f0103c9b:	03 55 c0             	add    -0x40(%ebp),%edx
f0103c9e:	89 57 08             	mov    %edx,0x8(%edi)
		info->eip_fn_addr = stabs[lfun].n_value;
f0103ca1:	8b 56 08             	mov    0x8(%esi),%edx
f0103ca4:	89 57 10             	mov    %edx,0x10(%edi)
		addr -= info->eip_fn_addr;
f0103ca7:	29 d3                	sub    %edx,%ebx
		// Search within the function definition for the line number.
		lline = lfun;
f0103ca9:	89 45 d4             	mov    %eax,-0x2c(%ebp)
		rline = rfun;
f0103cac:	89 4d d0             	mov    %ecx,-0x30(%ebp)
f0103caf:	eb 0f                	jmp    f0103cc0 <debuginfo_eip+0x137>
	} else {
		// Couldn't find function stab!  Maybe we're in an assembly
		// file.  Search the whole file for the line number.
		info->eip_fn_addr = addr;
f0103cb1:	89 5f 10             	mov    %ebx,0x10(%edi)
		lline = lfile;
f0103cb4:	8b 45 e4             	mov    -0x1c(%ebp),%eax
f0103cb7:	89 45 d4             	mov    %eax,-0x2c(%ebp)
		rline = rfile;
f0103cba:	8b 45 e0             	mov    -0x20(%ebp),%eax
f0103cbd:	89 45 d0             	mov    %eax,-0x30(%ebp)
	}
	// Ignore stuff after the colon.
	info->eip_fn_namelen = strfind(info->eip_fn_name, ':') - info->eip_fn_name;
f0103cc0:	c7 44 24 04 3a 00 00 	movl   $0x3a,0x4(%esp)
f0103cc7:	00 
f0103cc8:	8b 47 08             	mov    0x8(%edi),%eax
f0103ccb:	89 04 24             	mov    %eax,(%esp)
f0103cce:	e8 e8 08 00 00       	call   f01045bb <strfind>
f0103cd3:	2b 47 08             	sub    0x8(%edi),%eax
f0103cd6:	89 47 0c             	mov    %eax,0xc(%edi)
	//	There's a particular stabs type used for line numbers.
	//	Look at the STABS documentation and <inc/stab.h> to find
	//	which one.
	// Your code here.

	stab_binsearch(stabs, &lline, &rline, N_SLINE, addr);
f0103cd9:	89 5c 24 04          	mov    %ebx,0x4(%esp)
f0103cdd:	c7 04 24 44 00 00 00 	movl   $0x44,(%esp)
f0103ce4:	8d 4d d0             	lea    -0x30(%ebp),%ecx
f0103ce7:	8d 55 d4             	lea    -0x2c(%ebp),%edx
f0103cea:	8b 45 c4             	mov    -0x3c(%ebp),%eax
f0103ced:	e8 95 fd ff ff       	call   f0103a87 <stab_binsearch>
	if (lline <= rline) {
f0103cf2:	8b 45 d4             	mov    -0x2c(%ebp),%eax
f0103cf5:	3b 45 d0             	cmp    -0x30(%ebp),%eax
f0103cf8:	7f 0e                	jg     f0103d08 <debuginfo_eip+0x17f>
		info->eip_line = stabs[lline].n_desc;
f0103cfa:	8d 04 40             	lea    (%eax,%eax,2),%eax
f0103cfd:	8b 5d c4             	mov    -0x3c(%ebp),%ebx
f0103d00:	0f b7 44 83 06       	movzwl 0x6(%ebx,%eax,4),%eax
f0103d05:	89 47 04             	mov    %eax,0x4(%edi)
	// Search backwards from the line number for the relevant filename
	// stab.
	// We can't just use the "lfile" stab because inlined functions
	// can interpolate code from a different file!
	// Such included source files use the N_SOL stab type.
	while (lline >= lfile && stabs[lline].n_type != N_SOL &&
f0103d08:	8b 45 e4             	mov    -0x1c(%ebp),%eax
f0103d0b:	89 c6                	mov    %eax,%esi
f0103d0d:	8b 45 d4             	mov    -0x2c(%ebp),%eax
f0103d10:	8d 14 40             	lea    (%eax,%eax,2),%edx
f0103d13:	8b 5d c4             	mov    -0x3c(%ebp),%ebx
f0103d16:	8d 14 93             	lea    (%ebx,%edx,4),%edx
f0103d19:	89 7d 0c             	mov    %edi,0xc(%ebp)
f0103d1c:	89 f7                	mov    %esi,%edi
f0103d1e:	eb 06                	jmp    f0103d26 <debuginfo_eip+0x19d>
f0103d20:	83 e8 01             	sub    $0x1,%eax
f0103d23:	83 ea 0c             	sub    $0xc,%edx
f0103d26:	89 c6                	mov    %eax,%esi
f0103d28:	39 c7                	cmp    %eax,%edi
f0103d2a:	7f 3c                	jg     f0103d68 <debuginfo_eip+0x1df>
f0103d2c:	0f b6 4a 04          	movzbl 0x4(%edx),%ecx
f0103d30:	80 f9 84             	cmp    $0x84,%cl
f0103d33:	75 08                	jne    f0103d3d <debuginfo_eip+0x1b4>
f0103d35:	8b 7d 0c             	mov    0xc(%ebp),%edi
f0103d38:	89 45 d4             	mov    %eax,-0x2c(%ebp)
f0103d3b:	eb 11                	jmp    f0103d4e <debuginfo_eip+0x1c5>
f0103d3d:	80 f9 64             	cmp    $0x64,%cl
f0103d40:	75 de                	jne    f0103d20 <debuginfo_eip+0x197>
	       (stabs[lline].n_type != N_SO || !stabs[lline].n_value))
f0103d42:	83 7a 08 00          	cmpl   $0x0,0x8(%edx)
f0103d46:	74 d8                	je     f0103d20 <debuginfo_eip+0x197>
f0103d48:	8b 7d 0c             	mov    0xc(%ebp),%edi
f0103d4b:	89 45 d4             	mov    %eax,-0x2c(%ebp)
		lline--;
	if (lline >= lfile && stabs[lline].n_strx < stabstr_end - stabstr)
f0103d4e:	8d 04 76             	lea    (%esi,%esi,2),%eax
f0103d51:	8b 5d c4             	mov    -0x3c(%ebp),%ebx
f0103d54:	8b 04 83             	mov    (%ebx,%eax,4),%eax
f0103d57:	8b 55 bc             	mov    -0x44(%ebp),%edx
f0103d5a:	2b 55 c0             	sub    -0x40(%ebp),%edx
f0103d5d:	39 d0                	cmp    %edx,%eax
f0103d5f:	73 0a                	jae    f0103d6b <debuginfo_eip+0x1e2>
		info->eip_file = stabstr + stabs[lline].n_strx;
f0103d61:	03 45 c0             	add    -0x40(%ebp),%eax
f0103d64:	89 07                	mov    %eax,(%edi)
f0103d66:	eb 03                	jmp    f0103d6b <debuginfo_eip+0x1e2>
f0103d68:	8b 7d 0c             	mov    0xc(%ebp),%edi


	// Set eip_fn_narg to the number of arguments taken by the function,
	// or 0 if there was no containing function.
	if (lfun < rfun)
f0103d6b:	8b 55 dc             	mov    -0x24(%ebp),%edx
f0103d6e:	8b 5d d8             	mov    -0x28(%ebp),%ebx
		for (lline = lfun + 1;
		     lline < rfun && stabs[lline].n_type == N_PSYM;
		     lline++)
			info->eip_fn_narg++;

	return 0;
f0103d71:	b8 00 00 00 00       	mov    $0x0,%eax
		info->eip_file = stabstr + stabs[lline].n_strx;


	// Set eip_fn_narg to the number of arguments taken by the function,
	// or 0 if there was no containing function.
	if (lfun < rfun)
f0103d76:	39 da                	cmp    %ebx,%edx
f0103d78:	7d 4b                	jge    f0103dc5 <debuginfo_eip+0x23c>
		for (lline = lfun + 1;
f0103d7a:	83 c2 01             	add    $0x1,%edx
f0103d7d:	89 55 d4             	mov    %edx,-0x2c(%ebp)
f0103d80:	89 d0                	mov    %edx,%eax
f0103d82:	8d 14 52             	lea    (%edx,%edx,2),%edx
f0103d85:	8b 75 c4             	mov    -0x3c(%ebp),%esi
f0103d88:	8d 14 96             	lea    (%esi,%edx,4),%edx
f0103d8b:	eb 04                	jmp    f0103d91 <debuginfo_eip+0x208>
		     lline < rfun && stabs[lline].n_type == N_PSYM;
		     lline++)
			info->eip_fn_narg++;
f0103d8d:	83 47 14 01          	addl   $0x1,0x14(%edi)


	// Set eip_fn_narg to the number of arguments taken by the function,
	// or 0 if there was no containing function.
	if (lfun < rfun)
		for (lline = lfun + 1;
f0103d91:	39 c3                	cmp    %eax,%ebx
f0103d93:	7e 2b                	jle    f0103dc0 <debuginfo_eip+0x237>
		     lline < rfun && stabs[lline].n_type == N_PSYM;
f0103d95:	0f b6 4a 04          	movzbl 0x4(%edx),%ecx
f0103d99:	83 c0 01             	add    $0x1,%eax
f0103d9c:	83 c2 0c             	add    $0xc,%edx
f0103d9f:	80 f9 a0             	cmp    $0xa0,%cl
f0103da2:	74 e9                	je     f0103d8d <debuginfo_eip+0x204>
		     lline++)
			info->eip_fn_narg++;

	return 0;
f0103da4:	b8 00 00 00 00       	mov    $0x0,%eax
f0103da9:	eb 1a                	jmp    f0103dc5 <debuginfo_eip+0x23c>
		// LAB 3: Your code here.
	}

	// String table validity checks
	if (stabstr_end <= stabstr || stabstr_end[-1] != 0)
		return -1;
f0103dab:	b8 ff ff ff ff       	mov    $0xffffffff,%eax
f0103db0:	eb 13                	jmp    f0103dc5 <debuginfo_eip+0x23c>
f0103db2:	b8 ff ff ff ff       	mov    $0xffffffff,%eax
f0103db7:	eb 0c                	jmp    f0103dc5 <debuginfo_eip+0x23c>
	// Search the entire set of stabs for the source file (type N_SO).
	lfile = 0;
	rfile = (stab_end - stabs) - 1;
	stab_binsearch(stabs, &lfile, &rfile, N_SO, addr);
	if (lfile == 0)
		return -1;
f0103db9:	b8 ff ff ff ff       	mov    $0xffffffff,%eax
f0103dbe:	eb 05                	jmp    f0103dc5 <debuginfo_eip+0x23c>
		for (lline = lfun + 1;
		     lline < rfun && stabs[lline].n_type == N_PSYM;
		     lline++)
			info->eip_fn_narg++;

	return 0;
f0103dc0:	b8 00 00 00 00       	mov    $0x0,%eax
}
f0103dc5:	83 c4 4c             	add    $0x4c,%esp
f0103dc8:	5b                   	pop    %ebx
f0103dc9:	5e                   	pop    %esi
f0103dca:	5f                   	pop    %edi
f0103dcb:	5d                   	pop    %ebp
f0103dcc:	c3                   	ret    
f0103dcd:	66 90                	xchg   %ax,%ax
f0103dcf:	90                   	nop

f0103dd0 <printnum>:
 * using specified putch function and associated pointer putdat.
 */
static void
printnum(void (*putch)(int, void*), void *putdat,
	 unsigned long long num, unsigned base, int width, int padc)
{
f0103dd0:	55                   	push   %ebp
f0103dd1:	89 e5                	mov    %esp,%ebp
f0103dd3:	57                   	push   %edi
f0103dd4:	56                   	push   %esi
f0103dd5:	53                   	push   %ebx
f0103dd6:	83 ec 3c             	sub    $0x3c,%esp
f0103dd9:	89 45 e4             	mov    %eax,-0x1c(%ebp)
f0103ddc:	89 d7                	mov    %edx,%edi
f0103dde:	8b 45 08             	mov    0x8(%ebp),%eax
f0103de1:	89 45 e0             	mov    %eax,-0x20(%ebp)
f0103de4:	8b 45 0c             	mov    0xc(%ebp),%eax
f0103de7:	89 c3                	mov    %eax,%ebx
f0103de9:	89 45 d4             	mov    %eax,-0x2c(%ebp)
f0103dec:	8b 45 10             	mov    0x10(%ebp),%eax
f0103def:	8b 75 14             	mov    0x14(%ebp),%esi
	// first recursively print all preceding (more significant) digits
	if (num >= base) {
f0103df2:	b9 00 00 00 00       	mov    $0x0,%ecx
f0103df7:	89 45 d8             	mov    %eax,-0x28(%ebp)
f0103dfa:	89 4d dc             	mov    %ecx,-0x24(%ebp)
f0103dfd:	39 d9                	cmp    %ebx,%ecx
f0103dff:	72 05                	jb     f0103e06 <printnum+0x36>
f0103e01:	3b 45 e0             	cmp    -0x20(%ebp),%eax
f0103e04:	77 69                	ja     f0103e6f <printnum+0x9f>
		printnum(putch, putdat, num / base, base, width - 1, padc);
f0103e06:	8b 4d 18             	mov    0x18(%ebp),%ecx
f0103e09:	89 4c 24 10          	mov    %ecx,0x10(%esp)
f0103e0d:	83 ee 01             	sub    $0x1,%esi
f0103e10:	89 74 24 0c          	mov    %esi,0xc(%esp)
f0103e14:	89 44 24 08          	mov    %eax,0x8(%esp)
f0103e18:	8b 44 24 08          	mov    0x8(%esp),%eax
f0103e1c:	8b 54 24 0c          	mov    0xc(%esp),%edx
f0103e20:	89 c3                	mov    %eax,%ebx
f0103e22:	89 d6                	mov    %edx,%esi
f0103e24:	8b 55 d8             	mov    -0x28(%ebp),%edx
f0103e27:	8b 4d dc             	mov    -0x24(%ebp),%ecx
f0103e2a:	89 54 24 08          	mov    %edx,0x8(%esp)
f0103e2e:	89 4c 24 0c          	mov    %ecx,0xc(%esp)
f0103e32:	8b 45 e0             	mov    -0x20(%ebp),%eax
f0103e35:	89 04 24             	mov    %eax,(%esp)
f0103e38:	8b 45 d4             	mov    -0x2c(%ebp),%eax
f0103e3b:	89 44 24 04          	mov    %eax,0x4(%esp)
f0103e3f:	e8 9c 09 00 00       	call   f01047e0 <__udivdi3>
f0103e44:	89 d9                	mov    %ebx,%ecx
f0103e46:	89 4c 24 08          	mov    %ecx,0x8(%esp)
f0103e4a:	89 74 24 0c          	mov    %esi,0xc(%esp)
f0103e4e:	89 04 24             	mov    %eax,(%esp)
f0103e51:	89 54 24 04          	mov    %edx,0x4(%esp)
f0103e55:	89 fa                	mov    %edi,%edx
f0103e57:	8b 45 e4             	mov    -0x1c(%ebp),%eax
f0103e5a:	e8 71 ff ff ff       	call   f0103dd0 <printnum>
f0103e5f:	eb 1b                	jmp    f0103e7c <printnum+0xac>
	} else {
		// print any needed pad characters before first digit
		while (--width > 0)
			putch(padc, putdat);
f0103e61:	89 7c 24 04          	mov    %edi,0x4(%esp)
f0103e65:	8b 45 18             	mov    0x18(%ebp),%eax
f0103e68:	89 04 24             	mov    %eax,(%esp)
f0103e6b:	ff d3                	call   *%ebx
f0103e6d:	eb 03                	jmp    f0103e72 <printnum+0xa2>
f0103e6f:	8b 5d e4             	mov    -0x1c(%ebp),%ebx
	// first recursively print all preceding (more significant) digits
	if (num >= base) {
		printnum(putch, putdat, num / base, base, width - 1, padc);
	} else {
		// print any needed pad characters before first digit
		while (--width > 0)
f0103e72:	83 ee 01             	sub    $0x1,%esi
f0103e75:	85 f6                	test   %esi,%esi
f0103e77:	7f e8                	jg     f0103e61 <printnum+0x91>
f0103e79:	89 5d e4             	mov    %ebx,-0x1c(%ebp)
			putch(padc, putdat);
	}

	// then print this (the least significant) digit
	putch("0123456789abcdef"[num % base], putdat);
f0103e7c:	89 7c 24 04          	mov    %edi,0x4(%esp)
f0103e80:	8b 7c 24 04          	mov    0x4(%esp),%edi
f0103e84:	8b 45 d8             	mov    -0x28(%ebp),%eax
f0103e87:	8b 55 dc             	mov    -0x24(%ebp),%edx
f0103e8a:	89 44 24 08          	mov    %eax,0x8(%esp)
f0103e8e:	89 54 24 0c          	mov    %edx,0xc(%esp)
f0103e92:	8b 45 e0             	mov    -0x20(%ebp),%eax
f0103e95:	89 04 24             	mov    %eax,(%esp)
f0103e98:	8b 45 d4             	mov    -0x2c(%ebp),%eax
f0103e9b:	89 44 24 04          	mov    %eax,0x4(%esp)
f0103e9f:	e8 6c 0a 00 00       	call   f0104910 <__umoddi3>
f0103ea4:	89 7c 24 04          	mov    %edi,0x4(%esp)
f0103ea8:	0f be 80 81 60 10 f0 	movsbl -0xfef9f7f(%eax),%eax
f0103eaf:	89 04 24             	mov    %eax,(%esp)
f0103eb2:	8b 45 e4             	mov    -0x1c(%ebp),%eax
f0103eb5:	ff d0                	call   *%eax
}
f0103eb7:	83 c4 3c             	add    $0x3c,%esp
f0103eba:	5b                   	pop    %ebx
f0103ebb:	5e                   	pop    %esi
f0103ebc:	5f                   	pop    %edi
f0103ebd:	5d                   	pop    %ebp
f0103ebe:	c3                   	ret    

f0103ebf <getuint>:

// Get an unsigned int of various possible sizes from a varargs list,
// depending on the lflag parameter.
static unsigned long long
getuint(va_list *ap, int lflag)
{
f0103ebf:	55                   	push   %ebp
f0103ec0:	89 e5                	mov    %esp,%ebp
	if (lflag >= 2)
f0103ec2:	83 fa 01             	cmp    $0x1,%edx
f0103ec5:	7e 0e                	jle    f0103ed5 <getuint+0x16>
		return va_arg(*ap, unsigned long long);
f0103ec7:	8b 10                	mov    (%eax),%edx
f0103ec9:	8d 4a 08             	lea    0x8(%edx),%ecx
f0103ecc:	89 08                	mov    %ecx,(%eax)
f0103ece:	8b 02                	mov    (%edx),%eax
f0103ed0:	8b 52 04             	mov    0x4(%edx),%edx
f0103ed3:	eb 22                	jmp    f0103ef7 <getuint+0x38>
	else if (lflag)
f0103ed5:	85 d2                	test   %edx,%edx
f0103ed7:	74 10                	je     f0103ee9 <getuint+0x2a>
		return va_arg(*ap, unsigned long);
f0103ed9:	8b 10                	mov    (%eax),%edx
f0103edb:	8d 4a 04             	lea    0x4(%edx),%ecx
f0103ede:	89 08                	mov    %ecx,(%eax)
f0103ee0:	8b 02                	mov    (%edx),%eax
f0103ee2:	ba 00 00 00 00       	mov    $0x0,%edx
f0103ee7:	eb 0e                	jmp    f0103ef7 <getuint+0x38>
	else
		return va_arg(*ap, unsigned int);
f0103ee9:	8b 10                	mov    (%eax),%edx
f0103eeb:	8d 4a 04             	lea    0x4(%edx),%ecx
f0103eee:	89 08                	mov    %ecx,(%eax)
f0103ef0:	8b 02                	mov    (%edx),%eax
f0103ef2:	ba 00 00 00 00       	mov    $0x0,%edx
}
f0103ef7:	5d                   	pop    %ebp
f0103ef8:	c3                   	ret    

f0103ef9 <getint>:

// Same as getuint but signed - can't use getuint
// because of sign extension
static long long
getint(va_list *ap, int lflag)
{
f0103ef9:	55                   	push   %ebp
f0103efa:	89 e5                	mov    %esp,%ebp
	if (lflag >= 2)
f0103efc:	83 fa 01             	cmp    $0x1,%edx
f0103eff:	7e 0e                	jle    f0103f0f <getint+0x16>
		return va_arg(*ap, long long);
f0103f01:	8b 10                	mov    (%eax),%edx
f0103f03:	8d 4a 08             	lea    0x8(%edx),%ecx
f0103f06:	89 08                	mov    %ecx,(%eax)
f0103f08:	8b 02                	mov    (%edx),%eax
f0103f0a:	8b 52 04             	mov    0x4(%edx),%edx
f0103f0d:	eb 1a                	jmp    f0103f29 <getint+0x30>
	else if (lflag)
f0103f0f:	85 d2                	test   %edx,%edx
f0103f11:	74 0c                	je     f0103f1f <getint+0x26>
		return va_arg(*ap, long);
f0103f13:	8b 10                	mov    (%eax),%edx
f0103f15:	8d 4a 04             	lea    0x4(%edx),%ecx
f0103f18:	89 08                	mov    %ecx,(%eax)
f0103f1a:	8b 02                	mov    (%edx),%eax
f0103f1c:	99                   	cltd   
f0103f1d:	eb 0a                	jmp    f0103f29 <getint+0x30>
	else
		return va_arg(*ap, int);
f0103f1f:	8b 10                	mov    (%eax),%edx
f0103f21:	8d 4a 04             	lea    0x4(%edx),%ecx
f0103f24:	89 08                	mov    %ecx,(%eax)
f0103f26:	8b 02                	mov    (%edx),%eax
f0103f28:	99                   	cltd   
}
f0103f29:	5d                   	pop    %ebp
f0103f2a:	c3                   	ret    

f0103f2b <sprintputch>:
	int cnt;
};

static void
sprintputch(int ch, struct sprintbuf *b)
{
f0103f2b:	55                   	push   %ebp
f0103f2c:	89 e5                	mov    %esp,%ebp
f0103f2e:	8b 45 0c             	mov    0xc(%ebp),%eax
	b->cnt++;
f0103f31:	83 40 08 01          	addl   $0x1,0x8(%eax)
	if (b->buf < b->ebuf)
f0103f35:	8b 10                	mov    (%eax),%edx
f0103f37:	3b 50 04             	cmp    0x4(%eax),%edx
f0103f3a:	73 0a                	jae    f0103f46 <sprintputch+0x1b>
		*b->buf++ = ch;
f0103f3c:	8d 4a 01             	lea    0x1(%edx),%ecx
f0103f3f:	89 08                	mov    %ecx,(%eax)
f0103f41:	8b 45 08             	mov    0x8(%ebp),%eax
f0103f44:	88 02                	mov    %al,(%edx)
}
f0103f46:	5d                   	pop    %ebp
f0103f47:	c3                   	ret    

f0103f48 <printfmt>:
	}
}

void
printfmt(void (*putch)(int, void*), void *putdat, const char *fmt, ...)
{
f0103f48:	55                   	push   %ebp
f0103f49:	89 e5                	mov    %esp,%ebp
f0103f4b:	83 ec 18             	sub    $0x18,%esp
	va_list ap;

	va_start(ap, fmt);
f0103f4e:	8d 45 14             	lea    0x14(%ebp),%eax
	vprintfmt(putch, putdat, fmt, ap);
f0103f51:	89 44 24 0c          	mov    %eax,0xc(%esp)
f0103f55:	8b 45 10             	mov    0x10(%ebp),%eax
f0103f58:	89 44 24 08          	mov    %eax,0x8(%esp)
f0103f5c:	8b 45 0c             	mov    0xc(%ebp),%eax
f0103f5f:	89 44 24 04          	mov    %eax,0x4(%esp)
f0103f63:	8b 45 08             	mov    0x8(%ebp),%eax
f0103f66:	89 04 24             	mov    %eax,(%esp)
f0103f69:	e8 02 00 00 00       	call   f0103f70 <vprintfmt>
	va_end(ap);
}
f0103f6e:	c9                   	leave  
f0103f6f:	c3                   	ret    

f0103f70 <vprintfmt>:
// Main function to format and print a string.
void printfmt(void (*putch)(int, void*), void *putdat, const char *fmt, ...);

void
vprintfmt(void (*putch)(int, void*), void *putdat, const char *fmt, va_list ap)
{
f0103f70:	55                   	push   %ebp
f0103f71:	89 e5                	mov    %esp,%ebp
f0103f73:	57                   	push   %edi
f0103f74:	56                   	push   %esi
f0103f75:	53                   	push   %ebx
f0103f76:	83 ec 3c             	sub    $0x3c,%esp
f0103f79:	8b 75 0c             	mov    0xc(%ebp),%esi
f0103f7c:	8b 7d 10             	mov    0x10(%ebp),%edi
f0103f7f:	eb 14                	jmp    f0103f95 <vprintfmt+0x25>
	int base, lflag, width, precision, altflag;
	char padc;

	while (1) {
		while ((ch = *(unsigned char *) fmt++) != '%') {
			if (ch == '\0')
f0103f81:	85 c0                	test   %eax,%eax
f0103f83:	0f 84 63 03 00 00    	je     f01042ec <vprintfmt+0x37c>
				return;
			putch(ch, putdat);
f0103f89:	89 74 24 04          	mov    %esi,0x4(%esp)
f0103f8d:	89 04 24             	mov    %eax,(%esp)
f0103f90:	ff 55 08             	call   *0x8(%ebp)
	unsigned long long num;
	int base, lflag, width, precision, altflag;
	char padc;

	while (1) {
		while ((ch = *(unsigned char *) fmt++) != '%') {
f0103f93:	89 df                	mov    %ebx,%edi
f0103f95:	8d 5f 01             	lea    0x1(%edi),%ebx
f0103f98:	0f b6 07             	movzbl (%edi),%eax
f0103f9b:	83 f8 25             	cmp    $0x25,%eax
f0103f9e:	75 e1                	jne    f0103f81 <vprintfmt+0x11>
f0103fa0:	c6 45 d8 20          	movb   $0x20,-0x28(%ebp)
f0103fa4:	c7 45 e0 00 00 00 00 	movl   $0x0,-0x20(%ebp)
f0103fab:	c7 45 d4 ff ff ff ff 	movl   $0xffffffff,-0x2c(%ebp)
f0103fb2:	c7 45 dc ff ff ff ff 	movl   $0xffffffff,-0x24(%ebp)
f0103fb9:	ba 00 00 00 00       	mov    $0x0,%edx
f0103fbe:	eb 1d                	jmp    f0103fdd <vprintfmt+0x6d>
		width = -1;
		precision = -1;
		lflag = 0;
		altflag = 0;
	reswitch:
		switch (ch = *(unsigned char *) fmt++) {
f0103fc0:	89 fb                	mov    %edi,%ebx

		// flag to pad on the right
		case '-':
			padc = '-';
f0103fc2:	c6 45 d8 2d          	movb   $0x2d,-0x28(%ebp)
f0103fc6:	eb 15                	jmp    f0103fdd <vprintfmt+0x6d>
		width = -1;
		precision = -1;
		lflag = 0;
		altflag = 0;
	reswitch:
		switch (ch = *(unsigned char *) fmt++) {
f0103fc8:	89 fb                	mov    %edi,%ebx
			padc = '-';
			goto reswitch;

		// flag to pad with 0's instead of spaces
		case '0':
			padc = '0';
f0103fca:	c6 45 d8 30          	movb   $0x30,-0x28(%ebp)
f0103fce:	eb 0d                	jmp    f0103fdd <vprintfmt+0x6d>
			altflag = 1;
			goto reswitch;

		process_precision:
			if (width < 0)
				width = precision, precision = -1;
f0103fd0:	8b 45 d4             	mov    -0x2c(%ebp),%eax
f0103fd3:	89 45 dc             	mov    %eax,-0x24(%ebp)
f0103fd6:	c7 45 d4 ff ff ff ff 	movl   $0xffffffff,-0x2c(%ebp)
		width = -1;
		precision = -1;
		lflag = 0;
		altflag = 0;
	reswitch:
		switch (ch = *(unsigned char *) fmt++) {
f0103fdd:	8d 7b 01             	lea    0x1(%ebx),%edi
f0103fe0:	0f b6 0b             	movzbl (%ebx),%ecx
f0103fe3:	0f b6 c1             	movzbl %cl,%eax
f0103fe6:	83 e9 23             	sub    $0x23,%ecx
f0103fe9:	80 f9 55             	cmp    $0x55,%cl
f0103fec:	0f 87 da 02 00 00    	ja     f01042cc <vprintfmt+0x35c>
f0103ff2:	0f b6 c9             	movzbl %cl,%ecx
f0103ff5:	ff 24 8d 0c 61 10 f0 	jmp    *-0xfef9ef4(,%ecx,4)
f0103ffc:	89 fb                	mov    %edi,%ebx
f0103ffe:	b9 00 00 00 00       	mov    $0x0,%ecx
		case '6':
		case '7':
		case '8':
		case '9':
			for (precision = 0; ; ++fmt) {
				precision = precision * 10 + ch - '0';
f0104003:	8d 0c 89             	lea    (%ecx,%ecx,4),%ecx
f0104006:	8d 4c 48 d0          	lea    -0x30(%eax,%ecx,2),%ecx
				ch = *fmt;
f010400a:	0f be 03             	movsbl (%ebx),%eax
				if (ch < '0' || ch > '9')
f010400d:	8d 78 d0             	lea    -0x30(%eax),%edi
f0104010:	83 ff 09             	cmp    $0x9,%edi
f0104013:	77 36                	ja     f010404b <vprintfmt+0xdb>
		case '5':
		case '6':
		case '7':
		case '8':
		case '9':
			for (precision = 0; ; ++fmt) {
f0104015:	83 c3 01             	add    $0x1,%ebx
				precision = precision * 10 + ch - '0';
				ch = *fmt;
				if (ch < '0' || ch > '9')
					break;
			}
f0104018:	eb e9                	jmp    f0104003 <vprintfmt+0x93>
			goto process_precision;

		case '*':
			precision = va_arg(ap, int);
f010401a:	8b 45 14             	mov    0x14(%ebp),%eax
f010401d:	8d 48 04             	lea    0x4(%eax),%ecx
f0104020:	89 4d 14             	mov    %ecx,0x14(%ebp)
f0104023:	8b 00                	mov    (%eax),%eax
f0104025:	89 45 d4             	mov    %eax,-0x2c(%ebp)
		width = -1;
		precision = -1;
		lflag = 0;
		altflag = 0;
	reswitch:
		switch (ch = *(unsigned char *) fmt++) {
f0104028:	89 fb                	mov    %edi,%ebx
			}
			goto process_precision;

		case '*':
			precision = va_arg(ap, int);
			goto process_precision;
f010402a:	eb 22                	jmp    f010404e <vprintfmt+0xde>
f010402c:	8b 4d dc             	mov    -0x24(%ebp),%ecx
f010402f:	85 c9                	test   %ecx,%ecx
f0104031:	b8 00 00 00 00       	mov    $0x0,%eax
f0104036:	0f 49 c1             	cmovns %ecx,%eax
f0104039:	89 45 dc             	mov    %eax,-0x24(%ebp)
		width = -1;
		precision = -1;
		lflag = 0;
		altflag = 0;
	reswitch:
		switch (ch = *(unsigned char *) fmt++) {
f010403c:	89 fb                	mov    %edi,%ebx
f010403e:	eb 9d                	jmp    f0103fdd <vprintfmt+0x6d>
f0104040:	89 fb                	mov    %edi,%ebx
			if (width < 0)
				width = 0;
			goto reswitch;

		case '#':
			altflag = 1;
f0104042:	c7 45 e0 01 00 00 00 	movl   $0x1,-0x20(%ebp)
			goto reswitch;
f0104049:	eb 92                	jmp    f0103fdd <vprintfmt+0x6d>
f010404b:	89 4d d4             	mov    %ecx,-0x2c(%ebp)

		process_precision:
			if (width < 0)
f010404e:	83 7d dc 00          	cmpl   $0x0,-0x24(%ebp)
f0104052:	79 89                	jns    f0103fdd <vprintfmt+0x6d>
f0104054:	e9 77 ff ff ff       	jmp    f0103fd0 <vprintfmt+0x60>
				width = precision, precision = -1;
			goto reswitch;

		// long flag (doubled for long long)
		case 'l':
			lflag++;
f0104059:	83 c2 01             	add    $0x1,%edx
		width = -1;
		precision = -1;
		lflag = 0;
		altflag = 0;
	reswitch:
		switch (ch = *(unsigned char *) fmt++) {
f010405c:	89 fb                	mov    %edi,%ebx
			goto reswitch;

		// long flag (doubled for long long)
		case 'l':
			lflag++;
			goto reswitch;
f010405e:	e9 7a ff ff ff       	jmp    f0103fdd <vprintfmt+0x6d>

		// character
		case 'c':
			putch(va_arg(ap, int), putdat);
f0104063:	8b 45 14             	mov    0x14(%ebp),%eax
f0104066:	8d 50 04             	lea    0x4(%eax),%edx
f0104069:	89 55 14             	mov    %edx,0x14(%ebp)
f010406c:	89 74 24 04          	mov    %esi,0x4(%esp)
f0104070:	8b 00                	mov    (%eax),%eax
f0104072:	89 04 24             	mov    %eax,(%esp)
f0104075:	ff 55 08             	call   *0x8(%ebp)
			break;
f0104078:	e9 18 ff ff ff       	jmp    f0103f95 <vprintfmt+0x25>

		// error message
		case 'e':
			err = va_arg(ap, int);
f010407d:	8b 45 14             	mov    0x14(%ebp),%eax
f0104080:	8d 50 04             	lea    0x4(%eax),%edx
f0104083:	89 55 14             	mov    %edx,0x14(%ebp)
f0104086:	8b 00                	mov    (%eax),%eax
f0104088:	99                   	cltd   
f0104089:	31 d0                	xor    %edx,%eax
f010408b:	29 d0                	sub    %edx,%eax
			if (err < 0)
				err = -err;
			if (err >= MAXERROR || (p = error_string[err]) == NULL)
f010408d:	83 f8 06             	cmp    $0x6,%eax
f0104090:	7f 0b                	jg     f010409d <vprintfmt+0x12d>
f0104092:	8b 14 85 64 62 10 f0 	mov    -0xfef9d9c(,%eax,4),%edx
f0104099:	85 d2                	test   %edx,%edx
f010409b:	75 20                	jne    f01040bd <vprintfmt+0x14d>
				printfmt(putch, putdat, "error %d", err);
f010409d:	89 44 24 0c          	mov    %eax,0xc(%esp)
f01040a1:	c7 44 24 08 99 60 10 	movl   $0xf0106099,0x8(%esp)
f01040a8:	f0 
f01040a9:	89 74 24 04          	mov    %esi,0x4(%esp)
f01040ad:	8b 45 08             	mov    0x8(%ebp),%eax
f01040b0:	89 04 24             	mov    %eax,(%esp)
f01040b3:	e8 90 fe ff ff       	call   f0103f48 <printfmt>
f01040b8:	e9 d8 fe ff ff       	jmp    f0103f95 <vprintfmt+0x25>
			else
				printfmt(putch, putdat, "%s", p);
f01040bd:	89 54 24 0c          	mov    %edx,0xc(%esp)
f01040c1:	c7 44 24 08 ec 57 10 	movl   $0xf01057ec,0x8(%esp)
f01040c8:	f0 
f01040c9:	89 74 24 04          	mov    %esi,0x4(%esp)
f01040cd:	8b 45 08             	mov    0x8(%ebp),%eax
f01040d0:	89 04 24             	mov    %eax,(%esp)
f01040d3:	e8 70 fe ff ff       	call   f0103f48 <printfmt>
f01040d8:	e9 b8 fe ff ff       	jmp    f0103f95 <vprintfmt+0x25>
		width = -1;
		precision = -1;
		lflag = 0;
		altflag = 0;
	reswitch:
		switch (ch = *(unsigned char *) fmt++) {
f01040dd:	8b 4d d4             	mov    -0x2c(%ebp),%ecx
f01040e0:	8b 45 dc             	mov    -0x24(%ebp),%eax
f01040e3:	89 45 d0             	mov    %eax,-0x30(%ebp)
				printfmt(putch, putdat, "%s", p);
			break;

		// string
		case 's':
			if ((p = va_arg(ap, char *)) == NULL)
f01040e6:	8b 45 14             	mov    0x14(%ebp),%eax
f01040e9:	8d 50 04             	lea    0x4(%eax),%edx
f01040ec:	89 55 14             	mov    %edx,0x14(%ebp)
f01040ef:	8b 18                	mov    (%eax),%ebx
				p = "(null)";
f01040f1:	85 db                	test   %ebx,%ebx
f01040f3:	b8 92 60 10 f0       	mov    $0xf0106092,%eax
f01040f8:	0f 44 d8             	cmove  %eax,%ebx
			if (width > 0 && padc != '-')
f01040fb:	80 7d d8 2d          	cmpb   $0x2d,-0x28(%ebp)
f01040ff:	0f 84 97 00 00 00    	je     f010419c <vprintfmt+0x22c>
f0104105:	83 7d d0 00          	cmpl   $0x0,-0x30(%ebp)
f0104109:	0f 8e 9b 00 00 00    	jle    f01041aa <vprintfmt+0x23a>
				for (width -= strnlen(p, precision); width > 0; width--)
f010410f:	89 4c 24 04          	mov    %ecx,0x4(%esp)
f0104113:	89 1c 24             	mov    %ebx,(%esp)
f0104116:	e8 4d 03 00 00       	call   f0104468 <strnlen>
f010411b:	8b 55 d0             	mov    -0x30(%ebp),%edx
f010411e:	29 c2                	sub    %eax,%edx
f0104120:	89 55 d0             	mov    %edx,-0x30(%ebp)
					putch(padc, putdat);
f0104123:	0f be 45 d8          	movsbl -0x28(%ebp),%eax
f0104127:	89 45 dc             	mov    %eax,-0x24(%ebp)
f010412a:	89 5d d8             	mov    %ebx,-0x28(%ebp)
f010412d:	89 d3                	mov    %edx,%ebx
f010412f:	89 7d 10             	mov    %edi,0x10(%ebp)
f0104132:	8b 7d 08             	mov    0x8(%ebp),%edi
		// string
		case 's':
			if ((p = va_arg(ap, char *)) == NULL)
				p = "(null)";
			if (width > 0 && padc != '-')
				for (width -= strnlen(p, precision); width > 0; width--)
f0104135:	eb 0f                	jmp    f0104146 <vprintfmt+0x1d6>
					putch(padc, putdat);
f0104137:	89 74 24 04          	mov    %esi,0x4(%esp)
f010413b:	8b 45 dc             	mov    -0x24(%ebp),%eax
f010413e:	89 04 24             	mov    %eax,(%esp)
f0104141:	ff d7                	call   *%edi
		// string
		case 's':
			if ((p = va_arg(ap, char *)) == NULL)
				p = "(null)";
			if (width > 0 && padc != '-')
				for (width -= strnlen(p, precision); width > 0; width--)
f0104143:	83 eb 01             	sub    $0x1,%ebx
f0104146:	85 db                	test   %ebx,%ebx
f0104148:	7f ed                	jg     f0104137 <vprintfmt+0x1c7>
f010414a:	8b 5d d8             	mov    -0x28(%ebp),%ebx
f010414d:	8b 55 d0             	mov    -0x30(%ebp),%edx
f0104150:	85 d2                	test   %edx,%edx
f0104152:	b8 00 00 00 00       	mov    $0x0,%eax
f0104157:	0f 49 c2             	cmovns %edx,%eax
f010415a:	29 c2                	sub    %eax,%edx
f010415c:	89 75 0c             	mov    %esi,0xc(%ebp)
f010415f:	89 d6                	mov    %edx,%esi
f0104161:	8b 7d d4             	mov    -0x2c(%ebp),%edi
f0104164:	eb 50                	jmp    f01041b6 <vprintfmt+0x246>
					putch(padc, putdat);
			for (; (ch = *p++) != '\0' && (precision < 0 || --precision >= 0); width--)
				if (altflag && (ch < ' ' || ch > '~'))
f0104166:	83 7d e0 00          	cmpl   $0x0,-0x20(%ebp)
f010416a:	74 1e                	je     f010418a <vprintfmt+0x21a>
f010416c:	0f be d2             	movsbl %dl,%edx
f010416f:	83 ea 20             	sub    $0x20,%edx
f0104172:	83 fa 5e             	cmp    $0x5e,%edx
f0104175:	76 13                	jbe    f010418a <vprintfmt+0x21a>
					putch('?', putdat);
f0104177:	8b 45 0c             	mov    0xc(%ebp),%eax
f010417a:	89 44 24 04          	mov    %eax,0x4(%esp)
f010417e:	c7 04 24 3f 00 00 00 	movl   $0x3f,(%esp)
f0104185:	ff 55 08             	call   *0x8(%ebp)
f0104188:	eb 0d                	jmp    f0104197 <vprintfmt+0x227>
				else
					putch(ch, putdat);
f010418a:	8b 55 0c             	mov    0xc(%ebp),%edx
f010418d:	89 54 24 04          	mov    %edx,0x4(%esp)
f0104191:	89 04 24             	mov    %eax,(%esp)
f0104194:	ff 55 08             	call   *0x8(%ebp)
			if ((p = va_arg(ap, char *)) == NULL)
				p = "(null)";
			if (width > 0 && padc != '-')
				for (width -= strnlen(p, precision); width > 0; width--)
					putch(padc, putdat);
			for (; (ch = *p++) != '\0' && (precision < 0 || --precision >= 0); width--)
f0104197:	83 ee 01             	sub    $0x1,%esi
f010419a:	eb 1a                	jmp    f01041b6 <vprintfmt+0x246>
f010419c:	89 75 0c             	mov    %esi,0xc(%ebp)
f010419f:	8b 75 dc             	mov    -0x24(%ebp),%esi
f01041a2:	89 7d 10             	mov    %edi,0x10(%ebp)
f01041a5:	8b 7d d4             	mov    -0x2c(%ebp),%edi
f01041a8:	eb 0c                	jmp    f01041b6 <vprintfmt+0x246>
f01041aa:	89 75 0c             	mov    %esi,0xc(%ebp)
f01041ad:	8b 75 dc             	mov    -0x24(%ebp),%esi
f01041b0:	89 7d 10             	mov    %edi,0x10(%ebp)
f01041b3:	8b 7d d4             	mov    -0x2c(%ebp),%edi
f01041b6:	83 c3 01             	add    $0x1,%ebx
f01041b9:	0f b6 53 ff          	movzbl -0x1(%ebx),%edx
f01041bd:	0f be c2             	movsbl %dl,%eax
f01041c0:	85 c0                	test   %eax,%eax
f01041c2:	74 25                	je     f01041e9 <vprintfmt+0x279>
f01041c4:	85 ff                	test   %edi,%edi
f01041c6:	78 9e                	js     f0104166 <vprintfmt+0x1f6>
f01041c8:	83 ef 01             	sub    $0x1,%edi
f01041cb:	79 99                	jns    f0104166 <vprintfmt+0x1f6>
f01041cd:	89 f3                	mov    %esi,%ebx
f01041cf:	8b 75 0c             	mov    0xc(%ebp),%esi
f01041d2:	8b 7d 08             	mov    0x8(%ebp),%edi
f01041d5:	eb 1a                	jmp    f01041f1 <vprintfmt+0x281>
				if (altflag && (ch < ' ' || ch > '~'))
					putch('?', putdat);
				else
					putch(ch, putdat);
			for (; width > 0; width--)
				putch(' ', putdat);
f01041d7:	89 74 24 04          	mov    %esi,0x4(%esp)
f01041db:	c7 04 24 20 00 00 00 	movl   $0x20,(%esp)
f01041e2:	ff d7                	call   *%edi
			for (; (ch = *p++) != '\0' && (precision < 0 || --precision >= 0); width--)
				if (altflag && (ch < ' ' || ch > '~'))
					putch('?', putdat);
				else
					putch(ch, putdat);
			for (; width > 0; width--)
f01041e4:	83 eb 01             	sub    $0x1,%ebx
f01041e7:	eb 08                	jmp    f01041f1 <vprintfmt+0x281>
f01041e9:	89 f3                	mov    %esi,%ebx
f01041eb:	8b 7d 08             	mov    0x8(%ebp),%edi
f01041ee:	8b 75 0c             	mov    0xc(%ebp),%esi
f01041f1:	85 db                	test   %ebx,%ebx
f01041f3:	7f e2                	jg     f01041d7 <vprintfmt+0x267>
f01041f5:	89 7d 08             	mov    %edi,0x8(%ebp)
f01041f8:	8b 7d 10             	mov    0x10(%ebp),%edi
f01041fb:	e9 95 fd ff ff       	jmp    f0103f95 <vprintfmt+0x25>
				putch(' ', putdat);
			break;

		// (signed) decimal
		case 'd':
			num = getint(&ap, lflag);
f0104200:	8d 45 14             	lea    0x14(%ebp),%eax
f0104203:	e8 f1 fc ff ff       	call   f0103ef9 <getint>
f0104208:	89 45 e0             	mov    %eax,-0x20(%ebp)
f010420b:	89 55 e4             	mov    %edx,-0x1c(%ebp)
			if ((long long) num < 0) {
				putch('-', putdat);
				num = -(long long) num;
			}
			base = 10;
f010420e:	bb 0a 00 00 00       	mov    $0xa,%ebx
			break;

		// (signed) decimal
		case 'd':
			num = getint(&ap, lflag);
			if ((long long) num < 0) {
f0104213:	83 7d e4 00          	cmpl   $0x0,-0x1c(%ebp)
f0104217:	79 7b                	jns    f0104294 <vprintfmt+0x324>
				putch('-', putdat);
f0104219:	89 74 24 04          	mov    %esi,0x4(%esp)
f010421d:	c7 04 24 2d 00 00 00 	movl   $0x2d,(%esp)
f0104224:	ff 55 08             	call   *0x8(%ebp)
				num = -(long long) num;
f0104227:	8b 45 e0             	mov    -0x20(%ebp),%eax
f010422a:	8b 55 e4             	mov    -0x1c(%ebp),%edx
f010422d:	f7 d8                	neg    %eax
f010422f:	83 d2 00             	adc    $0x0,%edx
f0104232:	f7 da                	neg    %edx
f0104234:	eb 5e                	jmp    f0104294 <vprintfmt+0x324>
			base = 10;
			goto number;

		// unsigned decimal
		case 'u':
			num = getuint(&ap, lflag);
f0104236:	8d 45 14             	lea    0x14(%ebp),%eax
f0104239:	e8 81 fc ff ff       	call   f0103ebf <getuint>
			base = 10;
f010423e:	bb 0a 00 00 00       	mov    $0xa,%ebx
			goto number;
f0104243:	eb 4f                	jmp    f0104294 <vprintfmt+0x324>

		// (unsigned) octal
		case 'o':
			num = getuint(&ap, lflag);
f0104245:	8d 45 14             	lea    0x14(%ebp),%eax
f0104248:	e8 72 fc ff ff       	call   f0103ebf <getuint>
			base = 8;
f010424d:	bb 08 00 00 00       	mov    $0x8,%ebx
			goto number;
f0104252:	eb 40                	jmp    f0104294 <vprintfmt+0x324>

		// pointer
		case 'p':
			putch('0', putdat);
f0104254:	89 74 24 04          	mov    %esi,0x4(%esp)
f0104258:	c7 04 24 30 00 00 00 	movl   $0x30,(%esp)
f010425f:	ff 55 08             	call   *0x8(%ebp)
			putch('x', putdat);
f0104262:	89 74 24 04          	mov    %esi,0x4(%esp)
f0104266:	c7 04 24 78 00 00 00 	movl   $0x78,(%esp)
f010426d:	ff 55 08             	call   *0x8(%ebp)
			num = (unsigned long long)
				(uintptr_t) va_arg(ap, void *);
f0104270:	8b 45 14             	mov    0x14(%ebp),%eax
f0104273:	8d 50 04             	lea    0x4(%eax),%edx
f0104276:	89 55 14             	mov    %edx,0x14(%ebp)

		// pointer
		case 'p':
			putch('0', putdat);
			putch('x', putdat);
			num = (unsigned long long)
f0104279:	8b 00                	mov    (%eax),%eax
f010427b:	ba 00 00 00 00       	mov    $0x0,%edx
				(uintptr_t) va_arg(ap, void *);
			base = 16;
f0104280:	bb 10 00 00 00       	mov    $0x10,%ebx
			goto number;
f0104285:	eb 0d                	jmp    f0104294 <vprintfmt+0x324>

		// (unsigned) hexadecimal
		case 'x':
			num = getuint(&ap, lflag);
f0104287:	8d 45 14             	lea    0x14(%ebp),%eax
f010428a:	e8 30 fc ff ff       	call   f0103ebf <getuint>
			base = 16;
f010428f:	bb 10 00 00 00       	mov    $0x10,%ebx
		number:
			printnum(putch, putdat, num, base, width, padc);
f0104294:	0f be 4d d8          	movsbl -0x28(%ebp),%ecx
f0104298:	89 4c 24 10          	mov    %ecx,0x10(%esp)
f010429c:	8b 4d dc             	mov    -0x24(%ebp),%ecx
f010429f:	89 4c 24 0c          	mov    %ecx,0xc(%esp)
f01042a3:	89 5c 24 08          	mov    %ebx,0x8(%esp)
f01042a7:	89 04 24             	mov    %eax,(%esp)
f01042aa:	89 54 24 04          	mov    %edx,0x4(%esp)
f01042ae:	89 f2                	mov    %esi,%edx
f01042b0:	8b 45 08             	mov    0x8(%ebp),%eax
f01042b3:	e8 18 fb ff ff       	call   f0103dd0 <printnum>
			break;
f01042b8:	e9 d8 fc ff ff       	jmp    f0103f95 <vprintfmt+0x25>

		// escaped '%' character
		case '%':
			putch(ch, putdat);
f01042bd:	89 74 24 04          	mov    %esi,0x4(%esp)
f01042c1:	89 04 24             	mov    %eax,(%esp)
f01042c4:	ff 55 08             	call   *0x8(%ebp)
			break;
f01042c7:	e9 c9 fc ff ff       	jmp    f0103f95 <vprintfmt+0x25>

		// unrecognized escape sequence - just print it literally
		default:
			putch('%', putdat);
f01042cc:	89 74 24 04          	mov    %esi,0x4(%esp)
f01042d0:	c7 04 24 25 00 00 00 	movl   $0x25,(%esp)
f01042d7:	ff 55 08             	call   *0x8(%ebp)
			for (fmt--; fmt[-1] != '%'; fmt--)
f01042da:	89 df                	mov    %ebx,%edi
f01042dc:	eb 03                	jmp    f01042e1 <vprintfmt+0x371>
f01042de:	83 ef 01             	sub    $0x1,%edi
f01042e1:	80 7f ff 25          	cmpb   $0x25,-0x1(%edi)
f01042e5:	75 f7                	jne    f01042de <vprintfmt+0x36e>
f01042e7:	e9 a9 fc ff ff       	jmp    f0103f95 <vprintfmt+0x25>
				/* do nothing */;
			break;
		}
	}
}
f01042ec:	83 c4 3c             	add    $0x3c,%esp
f01042ef:	5b                   	pop    %ebx
f01042f0:	5e                   	pop    %esi
f01042f1:	5f                   	pop    %edi
f01042f2:	5d                   	pop    %ebp
f01042f3:	c3                   	ret    

f01042f4 <vsnprintf>:
		*b->buf++ = ch;
}

int
vsnprintf(char *buf, int n, const char *fmt, va_list ap)
{
f01042f4:	55                   	push   %ebp
f01042f5:	89 e5                	mov    %esp,%ebp
f01042f7:	83 ec 28             	sub    $0x28,%esp
f01042fa:	8b 45 08             	mov    0x8(%ebp),%eax
f01042fd:	8b 55 0c             	mov    0xc(%ebp),%edx
	struct sprintbuf b = {buf, buf+n-1, 0};
f0104300:	89 45 ec             	mov    %eax,-0x14(%ebp)
f0104303:	8d 4c 10 ff          	lea    -0x1(%eax,%edx,1),%ecx
f0104307:	89 4d f0             	mov    %ecx,-0x10(%ebp)
f010430a:	c7 45 f4 00 00 00 00 	movl   $0x0,-0xc(%ebp)

	if (buf == NULL || n < 1)
f0104311:	85 c0                	test   %eax,%eax
f0104313:	74 30                	je     f0104345 <vsnprintf+0x51>
f0104315:	85 d2                	test   %edx,%edx
f0104317:	7e 2c                	jle    f0104345 <vsnprintf+0x51>
		return -E_INVAL;

	// print the string to the buffer
	vprintfmt((void*)sprintputch, &b, fmt, ap);
f0104319:	8b 45 14             	mov    0x14(%ebp),%eax
f010431c:	89 44 24 0c          	mov    %eax,0xc(%esp)
f0104320:	8b 45 10             	mov    0x10(%ebp),%eax
f0104323:	89 44 24 08          	mov    %eax,0x8(%esp)
f0104327:	8d 45 ec             	lea    -0x14(%ebp),%eax
f010432a:	89 44 24 04          	mov    %eax,0x4(%esp)
f010432e:	c7 04 24 2b 3f 10 f0 	movl   $0xf0103f2b,(%esp)
f0104335:	e8 36 fc ff ff       	call   f0103f70 <vprintfmt>

	// null terminate the buffer
	*b.buf = '\0';
f010433a:	8b 45 ec             	mov    -0x14(%ebp),%eax
f010433d:	c6 00 00             	movb   $0x0,(%eax)

	return b.cnt;
f0104340:	8b 45 f4             	mov    -0xc(%ebp),%eax
f0104343:	eb 05                	jmp    f010434a <vsnprintf+0x56>
vsnprintf(char *buf, int n, const char *fmt, va_list ap)
{
	struct sprintbuf b = {buf, buf+n-1, 0};

	if (buf == NULL || n < 1)
		return -E_INVAL;
f0104345:	b8 fd ff ff ff       	mov    $0xfffffffd,%eax

	// null terminate the buffer
	*b.buf = '\0';

	return b.cnt;
}
f010434a:	c9                   	leave  
f010434b:	c3                   	ret    

f010434c <snprintf>:

int
snprintf(char *buf, int n, const char *fmt, ...)
{
f010434c:	55                   	push   %ebp
f010434d:	89 e5                	mov    %esp,%ebp
f010434f:	83 ec 18             	sub    $0x18,%esp
	va_list ap;
	int rc;

	va_start(ap, fmt);
f0104352:	8d 45 14             	lea    0x14(%ebp),%eax
	rc = vsnprintf(buf, n, fmt, ap);
f0104355:	89 44 24 0c          	mov    %eax,0xc(%esp)
f0104359:	8b 45 10             	mov    0x10(%ebp),%eax
f010435c:	89 44 24 08          	mov    %eax,0x8(%esp)
f0104360:	8b 45 0c             	mov    0xc(%ebp),%eax
f0104363:	89 44 24 04          	mov    %eax,0x4(%esp)
f0104367:	8b 45 08             	mov    0x8(%ebp),%eax
f010436a:	89 04 24             	mov    %eax,(%esp)
f010436d:	e8 82 ff ff ff       	call   f01042f4 <vsnprintf>
	va_end(ap);

	return rc;
}
f0104372:	c9                   	leave  
f0104373:	c3                   	ret    
f0104374:	66 90                	xchg   %ax,%ax
f0104376:	66 90                	xchg   %ax,%ax
f0104378:	66 90                	xchg   %ax,%ax
f010437a:	66 90                	xchg   %ax,%ax
f010437c:	66 90                	xchg   %ax,%ax
f010437e:	66 90                	xchg   %ax,%ax

f0104380 <readline>:
#define BUFLEN 1024
static char buf[BUFLEN];

char *
readline(const char *prompt)
{
f0104380:	55                   	push   %ebp
f0104381:	89 e5                	mov    %esp,%ebp
f0104383:	57                   	push   %edi
f0104384:	56                   	push   %esi
f0104385:	53                   	push   %ebx
f0104386:	83 ec 1c             	sub    $0x1c,%esp
f0104389:	8b 45 08             	mov    0x8(%ebp),%eax
	int i, c, echoing;

	if (prompt != NULL)
f010438c:	85 c0                	test   %eax,%eax
f010438e:	74 10                	je     f01043a0 <readline+0x20>
		cprintf("%s", prompt);
f0104390:	89 44 24 04          	mov    %eax,0x4(%esp)
f0104394:	c7 04 24 ec 57 10 f0 	movl   $0xf01057ec,(%esp)
f010439b:	e8 78 f2 ff ff       	call   f0103618 <cprintf>

	i = 0;
	echoing = iscons(0);
f01043a0:	c7 04 24 00 00 00 00 	movl   $0x0,(%esp)
f01043a7:	e8 8d c3 ff ff       	call   f0100739 <iscons>
f01043ac:	89 c7                	mov    %eax,%edi
	int i, c, echoing;

	if (prompt != NULL)
		cprintf("%s", prompt);

	i = 0;
f01043ae:	be 00 00 00 00       	mov    $0x0,%esi
	echoing = iscons(0);
	while (1) {
		c = getchar();
f01043b3:	e8 70 c3 ff ff       	call   f0100728 <getchar>
f01043b8:	89 c3                	mov    %eax,%ebx
		if (c < 0) {
f01043ba:	85 c0                	test   %eax,%eax
f01043bc:	79 17                	jns    f01043d5 <readline+0x55>
			cprintf("read error: %e\n", c);
f01043be:	89 44 24 04          	mov    %eax,0x4(%esp)
f01043c2:	c7 04 24 80 62 10 f0 	movl   $0xf0106280,(%esp)
f01043c9:	e8 4a f2 ff ff       	call   f0103618 <cprintf>
			return NULL;
f01043ce:	b8 00 00 00 00       	mov    $0x0,%eax
f01043d3:	eb 6d                	jmp    f0104442 <readline+0xc2>
		} else if ((c == '\b' || c == '\x7f') && i > 0) {
f01043d5:	83 f8 7f             	cmp    $0x7f,%eax
f01043d8:	74 05                	je     f01043df <readline+0x5f>
f01043da:	83 f8 08             	cmp    $0x8,%eax
f01043dd:	75 19                	jne    f01043f8 <readline+0x78>
f01043df:	85 f6                	test   %esi,%esi
f01043e1:	7e 15                	jle    f01043f8 <readline+0x78>
			if (echoing)
f01043e3:	85 ff                	test   %edi,%edi
f01043e5:	74 0c                	je     f01043f3 <readline+0x73>
				cputchar('\b');
f01043e7:	c7 04 24 08 00 00 00 	movl   $0x8,(%esp)
f01043ee:	e8 25 c3 ff ff       	call   f0100718 <cputchar>
			i--;
f01043f3:	83 ee 01             	sub    $0x1,%esi
f01043f6:	eb bb                	jmp    f01043b3 <readline+0x33>
		} else if (c >= ' ' && i < BUFLEN-1) {
f01043f8:	81 fe fe 03 00 00    	cmp    $0x3fe,%esi
f01043fe:	7f 1c                	jg     f010441c <readline+0x9c>
f0104400:	83 fb 1f             	cmp    $0x1f,%ebx
f0104403:	7e 17                	jle    f010441c <readline+0x9c>
			if (echoing)
f0104405:	85 ff                	test   %edi,%edi
f0104407:	74 08                	je     f0104411 <readline+0x91>
				cputchar(c);
f0104409:	89 1c 24             	mov    %ebx,(%esp)
f010440c:	e8 07 c3 ff ff       	call   f0100718 <cputchar>
			buf[i++] = c;
f0104411:	88 9e 80 5b 18 f0    	mov    %bl,-0xfe7a480(%esi)
f0104417:	8d 76 01             	lea    0x1(%esi),%esi
f010441a:	eb 97                	jmp    f01043b3 <readline+0x33>
		} else if (c == '\n' || c == '\r') {
f010441c:	83 fb 0d             	cmp    $0xd,%ebx
f010441f:	74 05                	je     f0104426 <readline+0xa6>
f0104421:	83 fb 0a             	cmp    $0xa,%ebx
f0104424:	75 8d                	jne    f01043b3 <readline+0x33>
			if (echoing)
f0104426:	85 ff                	test   %edi,%edi
f0104428:	74 0c                	je     f0104436 <readline+0xb6>
				cputchar('\n');
f010442a:	c7 04 24 0a 00 00 00 	movl   $0xa,(%esp)
f0104431:	e8 e2 c2 ff ff       	call   f0100718 <cputchar>
			buf[i] = 0;
f0104436:	c6 86 80 5b 18 f0 00 	movb   $0x0,-0xfe7a480(%esi)
			return buf;
f010443d:	b8 80 5b 18 f0       	mov    $0xf0185b80,%eax
		}
	}
}
f0104442:	83 c4 1c             	add    $0x1c,%esp
f0104445:	5b                   	pop    %ebx
f0104446:	5e                   	pop    %esi
f0104447:	5f                   	pop    %edi
f0104448:	5d                   	pop    %ebp
f0104449:	c3                   	ret    
f010444a:	66 90                	xchg   %ax,%ax
f010444c:	66 90                	xchg   %ax,%ax
f010444e:	66 90                	xchg   %ax,%ax

f0104450 <strlen>:
// Primespipe runs 3x faster this way.
#define ASM 1

int
strlen(const char *s)
{
f0104450:	55                   	push   %ebp
f0104451:	89 e5                	mov    %esp,%ebp
f0104453:	8b 55 08             	mov    0x8(%ebp),%edx
	int n;

	for (n = 0; *s != '\0'; s++)
f0104456:	b8 00 00 00 00       	mov    $0x0,%eax
f010445b:	eb 03                	jmp    f0104460 <strlen+0x10>
		n++;
f010445d:	83 c0 01             	add    $0x1,%eax
int
strlen(const char *s)
{
	int n;

	for (n = 0; *s != '\0'; s++)
f0104460:	80 3c 02 00          	cmpb   $0x0,(%edx,%eax,1)
f0104464:	75 f7                	jne    f010445d <strlen+0xd>
		n++;
	return n;
}
f0104466:	5d                   	pop    %ebp
f0104467:	c3                   	ret    

f0104468 <strnlen>:

int
strnlen(const char *s, size_t size)
{
f0104468:	55                   	push   %ebp
f0104469:	89 e5                	mov    %esp,%ebp
f010446b:	8b 4d 08             	mov    0x8(%ebp),%ecx
f010446e:	8b 55 0c             	mov    0xc(%ebp),%edx
	int n;

	for (n = 0; size > 0 && *s != '\0'; s++, size--)
f0104471:	b8 00 00 00 00       	mov    $0x0,%eax
f0104476:	eb 03                	jmp    f010447b <strnlen+0x13>
		n++;
f0104478:	83 c0 01             	add    $0x1,%eax
int
strnlen(const char *s, size_t size)
{
	int n;

	for (n = 0; size > 0 && *s != '\0'; s++, size--)
f010447b:	39 d0                	cmp    %edx,%eax
f010447d:	74 06                	je     f0104485 <strnlen+0x1d>
f010447f:	80 3c 01 00          	cmpb   $0x0,(%ecx,%eax,1)
f0104483:	75 f3                	jne    f0104478 <strnlen+0x10>
		n++;
	return n;
}
f0104485:	5d                   	pop    %ebp
f0104486:	c3                   	ret    

f0104487 <strcpy>:

char *
strcpy(char *dst, const char *src)
{
f0104487:	55                   	push   %ebp
f0104488:	89 e5                	mov    %esp,%ebp
f010448a:	53                   	push   %ebx
f010448b:	8b 45 08             	mov    0x8(%ebp),%eax
f010448e:	8b 4d 0c             	mov    0xc(%ebp),%ecx
	char *ret;

	ret = dst;
	while ((*dst++ = *src++) != '\0')
f0104491:	89 c2                	mov    %eax,%edx
f0104493:	83 c2 01             	add    $0x1,%edx
f0104496:	83 c1 01             	add    $0x1,%ecx
f0104499:	0f b6 59 ff          	movzbl -0x1(%ecx),%ebx
f010449d:	88 5a ff             	mov    %bl,-0x1(%edx)
f01044a0:	84 db                	test   %bl,%bl
f01044a2:	75 ef                	jne    f0104493 <strcpy+0xc>
		/* do nothing */;
	return ret;
}
f01044a4:	5b                   	pop    %ebx
f01044a5:	5d                   	pop    %ebp
f01044a6:	c3                   	ret    

f01044a7 <strcat>:

char *
strcat(char *dst, const char *src)
{
f01044a7:	55                   	push   %ebp
f01044a8:	89 e5                	mov    %esp,%ebp
f01044aa:	53                   	push   %ebx
f01044ab:	83 ec 08             	sub    $0x8,%esp
f01044ae:	8b 5d 08             	mov    0x8(%ebp),%ebx
	int len = strlen(dst);
f01044b1:	89 1c 24             	mov    %ebx,(%esp)
f01044b4:	e8 97 ff ff ff       	call   f0104450 <strlen>
	strcpy(dst + len, src);
f01044b9:	8b 55 0c             	mov    0xc(%ebp),%edx
f01044bc:	89 54 24 04          	mov    %edx,0x4(%esp)
f01044c0:	01 d8                	add    %ebx,%eax
f01044c2:	89 04 24             	mov    %eax,(%esp)
f01044c5:	e8 bd ff ff ff       	call   f0104487 <strcpy>
	return dst;
}
f01044ca:	89 d8                	mov    %ebx,%eax
f01044cc:	83 c4 08             	add    $0x8,%esp
f01044cf:	5b                   	pop    %ebx
f01044d0:	5d                   	pop    %ebp
f01044d1:	c3                   	ret    

f01044d2 <strncpy>:

char *
strncpy(char *dst, const char *src, size_t size) {
f01044d2:	55                   	push   %ebp
f01044d3:	89 e5                	mov    %esp,%ebp
f01044d5:	56                   	push   %esi
f01044d6:	53                   	push   %ebx
f01044d7:	8b 75 08             	mov    0x8(%ebp),%esi
f01044da:	8b 4d 0c             	mov    0xc(%ebp),%ecx
f01044dd:	89 f3                	mov    %esi,%ebx
f01044df:	03 5d 10             	add    0x10(%ebp),%ebx
	size_t i;
	char *ret;

	ret = dst;
	for (i = 0; i < size; i++) {
f01044e2:	89 f2                	mov    %esi,%edx
f01044e4:	eb 0f                	jmp    f01044f5 <strncpy+0x23>
		*dst++ = *src;
f01044e6:	83 c2 01             	add    $0x1,%edx
f01044e9:	0f b6 01             	movzbl (%ecx),%eax
f01044ec:	88 42 ff             	mov    %al,-0x1(%edx)
		// If strlen(src) < size, null-pad 'dst' out to 'size' chars
		if (*src != '\0')
			src++;
f01044ef:	80 39 01             	cmpb   $0x1,(%ecx)
f01044f2:	83 d9 ff             	sbb    $0xffffffff,%ecx
strncpy(char *dst, const char *src, size_t size) {
	size_t i;
	char *ret;

	ret = dst;
	for (i = 0; i < size; i++) {
f01044f5:	39 da                	cmp    %ebx,%edx
f01044f7:	75 ed                	jne    f01044e6 <strncpy+0x14>
		// If strlen(src) < size, null-pad 'dst' out to 'size' chars
		if (*src != '\0')
			src++;
	}
	return ret;
}
f01044f9:	89 f0                	mov    %esi,%eax
f01044fb:	5b                   	pop    %ebx
f01044fc:	5e                   	pop    %esi
f01044fd:	5d                   	pop    %ebp
f01044fe:	c3                   	ret    

f01044ff <strlcpy>:

size_t
strlcpy(char *dst, const char *src, size_t size)
{
f01044ff:	55                   	push   %ebp
f0104500:	89 e5                	mov    %esp,%ebp
f0104502:	56                   	push   %esi
f0104503:	53                   	push   %ebx
f0104504:	8b 75 08             	mov    0x8(%ebp),%esi
f0104507:	8b 55 0c             	mov    0xc(%ebp),%edx
f010450a:	8b 4d 10             	mov    0x10(%ebp),%ecx
f010450d:	89 f0                	mov    %esi,%eax
f010450f:	8d 5c 0e ff          	lea    -0x1(%esi,%ecx,1),%ebx
	char *dst_in;

	dst_in = dst;
	if (size > 0) {
f0104513:	85 c9                	test   %ecx,%ecx
f0104515:	75 0b                	jne    f0104522 <strlcpy+0x23>
f0104517:	eb 1d                	jmp    f0104536 <strlcpy+0x37>
		while (--size > 0 && *src != '\0')
			*dst++ = *src++;
f0104519:	83 c0 01             	add    $0x1,%eax
f010451c:	83 c2 01             	add    $0x1,%edx
f010451f:	88 48 ff             	mov    %cl,-0x1(%eax)
{
	char *dst_in;

	dst_in = dst;
	if (size > 0) {
		while (--size > 0 && *src != '\0')
f0104522:	39 d8                	cmp    %ebx,%eax
f0104524:	74 0b                	je     f0104531 <strlcpy+0x32>
f0104526:	0f b6 0a             	movzbl (%edx),%ecx
f0104529:	84 c9                	test   %cl,%cl
f010452b:	75 ec                	jne    f0104519 <strlcpy+0x1a>
f010452d:	89 c2                	mov    %eax,%edx
f010452f:	eb 02                	jmp    f0104533 <strlcpy+0x34>
f0104531:	89 c2                	mov    %eax,%edx
			*dst++ = *src++;
		*dst = '\0';
f0104533:	c6 02 00             	movb   $0x0,(%edx)
	}
	return dst - dst_in;
f0104536:	29 f0                	sub    %esi,%eax
}
f0104538:	5b                   	pop    %ebx
f0104539:	5e                   	pop    %esi
f010453a:	5d                   	pop    %ebp
f010453b:	c3                   	ret    

f010453c <strcmp>:

int
strcmp(const char *p, const char *q)
{
f010453c:	55                   	push   %ebp
f010453d:	89 e5                	mov    %esp,%ebp
f010453f:	8b 4d 08             	mov    0x8(%ebp),%ecx
f0104542:	8b 55 0c             	mov    0xc(%ebp),%edx
	while (*p && *p == *q)
f0104545:	eb 06                	jmp    f010454d <strcmp+0x11>
		p++, q++;
f0104547:	83 c1 01             	add    $0x1,%ecx
f010454a:	83 c2 01             	add    $0x1,%edx
}

int
strcmp(const char *p, const char *q)
{
	while (*p && *p == *q)
f010454d:	0f b6 01             	movzbl (%ecx),%eax
f0104550:	84 c0                	test   %al,%al
f0104552:	74 04                	je     f0104558 <strcmp+0x1c>
f0104554:	3a 02                	cmp    (%edx),%al
f0104556:	74 ef                	je     f0104547 <strcmp+0xb>
		p++, q++;
	return (int) ((unsigned char) *p - (unsigned char) *q);
f0104558:	0f b6 c0             	movzbl %al,%eax
f010455b:	0f b6 12             	movzbl (%edx),%edx
f010455e:	29 d0                	sub    %edx,%eax
}
f0104560:	5d                   	pop    %ebp
f0104561:	c3                   	ret    

f0104562 <strncmp>:

int
strncmp(const char *p, const char *q, size_t n)
{
f0104562:	55                   	push   %ebp
f0104563:	89 e5                	mov    %esp,%ebp
f0104565:	53                   	push   %ebx
f0104566:	8b 45 08             	mov    0x8(%ebp),%eax
f0104569:	8b 55 0c             	mov    0xc(%ebp),%edx
f010456c:	89 c3                	mov    %eax,%ebx
f010456e:	03 5d 10             	add    0x10(%ebp),%ebx
	while (n > 0 && *p && *p == *q)
f0104571:	eb 06                	jmp    f0104579 <strncmp+0x17>
		n--, p++, q++;
f0104573:	83 c0 01             	add    $0x1,%eax
f0104576:	83 c2 01             	add    $0x1,%edx
}

int
strncmp(const char *p, const char *q, size_t n)
{
	while (n > 0 && *p && *p == *q)
f0104579:	39 d8                	cmp    %ebx,%eax
f010457b:	74 15                	je     f0104592 <strncmp+0x30>
f010457d:	0f b6 08             	movzbl (%eax),%ecx
f0104580:	84 c9                	test   %cl,%cl
f0104582:	74 04                	je     f0104588 <strncmp+0x26>
f0104584:	3a 0a                	cmp    (%edx),%cl
f0104586:	74 eb                	je     f0104573 <strncmp+0x11>
		n--, p++, q++;
	if (n == 0)
		return 0;
	else
		return (int) ((unsigned char) *p - (unsigned char) *q);
f0104588:	0f b6 00             	movzbl (%eax),%eax
f010458b:	0f b6 12             	movzbl (%edx),%edx
f010458e:	29 d0                	sub    %edx,%eax
f0104590:	eb 05                	jmp    f0104597 <strncmp+0x35>
strncmp(const char *p, const char *q, size_t n)
{
	while (n > 0 && *p && *p == *q)
		n--, p++, q++;
	if (n == 0)
		return 0;
f0104592:	b8 00 00 00 00       	mov    $0x0,%eax
	else
		return (int) ((unsigned char) *p - (unsigned char) *q);
}
f0104597:	5b                   	pop    %ebx
f0104598:	5d                   	pop    %ebp
f0104599:	c3                   	ret    

f010459a <strchr>:

// Return a pointer to the first occurrence of 'c' in 's',
// or a null pointer if the string has no 'c'.
char *
strchr(const char *s, char c)
{
f010459a:	55                   	push   %ebp
f010459b:	89 e5                	mov    %esp,%ebp
f010459d:	8b 45 08             	mov    0x8(%ebp),%eax
f01045a0:	0f b6 4d 0c          	movzbl 0xc(%ebp),%ecx
	for (; *s; s++)
f01045a4:	eb 07                	jmp    f01045ad <strchr+0x13>
		if (*s == c)
f01045a6:	38 ca                	cmp    %cl,%dl
f01045a8:	74 0f                	je     f01045b9 <strchr+0x1f>
// Return a pointer to the first occurrence of 'c' in 's',
// or a null pointer if the string has no 'c'.
char *
strchr(const char *s, char c)
{
	for (; *s; s++)
f01045aa:	83 c0 01             	add    $0x1,%eax
f01045ad:	0f b6 10             	movzbl (%eax),%edx
f01045b0:	84 d2                	test   %dl,%dl
f01045b2:	75 f2                	jne    f01045a6 <strchr+0xc>
		if (*s == c)
			return (char *) s;
	return 0;
f01045b4:	b8 00 00 00 00       	mov    $0x0,%eax
}
f01045b9:	5d                   	pop    %ebp
f01045ba:	c3                   	ret    

f01045bb <strfind>:

// Return a pointer to the first occurrence of 'c' in 's',
// or a pointer to the string-ending null character if the string has no 'c'.
char *
strfind(const char *s, char c)
{
f01045bb:	55                   	push   %ebp
f01045bc:	89 e5                	mov    %esp,%ebp
f01045be:	8b 45 08             	mov    0x8(%ebp),%eax
f01045c1:	0f b6 4d 0c          	movzbl 0xc(%ebp),%ecx
	for (; *s; s++)
f01045c5:	eb 07                	jmp    f01045ce <strfind+0x13>
		if (*s == c)
f01045c7:	38 ca                	cmp    %cl,%dl
f01045c9:	74 0a                	je     f01045d5 <strfind+0x1a>
// Return a pointer to the first occurrence of 'c' in 's',
// or a pointer to the string-ending null character if the string has no 'c'.
char *
strfind(const char *s, char c)
{
	for (; *s; s++)
f01045cb:	83 c0 01             	add    $0x1,%eax
f01045ce:	0f b6 10             	movzbl (%eax),%edx
f01045d1:	84 d2                	test   %dl,%dl
f01045d3:	75 f2                	jne    f01045c7 <strfind+0xc>
		if (*s == c)
			break;
	return (char *) s;
}
f01045d5:	5d                   	pop    %ebp
f01045d6:	c3                   	ret    

f01045d7 <memset>:

#if ASM
void *
memset(void *v, int c, size_t n)
{
f01045d7:	55                   	push   %ebp
f01045d8:	89 e5                	mov    %esp,%ebp
f01045da:	57                   	push   %edi
f01045db:	56                   	push   %esi
f01045dc:	53                   	push   %ebx
f01045dd:	8b 55 08             	mov    0x8(%ebp),%edx
f01045e0:	8b 4d 10             	mov    0x10(%ebp),%ecx
	char *p = v;

	if (n == 0)
f01045e3:	85 c9                	test   %ecx,%ecx
f01045e5:	74 37                	je     f010461e <memset+0x47>
		return v;
	if ((int)v%4 == 0 && n%4 == 0) {
f01045e7:	f6 c2 03             	test   $0x3,%dl
f01045ea:	75 2a                	jne    f0104616 <memset+0x3f>
f01045ec:	f6 c1 03             	test   $0x3,%cl
f01045ef:	75 25                	jne    f0104616 <memset+0x3f>
		c &= 0xFF;
f01045f1:	0f b6 7d 0c          	movzbl 0xc(%ebp),%edi
		c = (c<<24)|(c<<16)|(c<<8)|c;
f01045f5:	89 fb                	mov    %edi,%ebx
f01045f7:	c1 e3 08             	shl    $0x8,%ebx
f01045fa:	89 fe                	mov    %edi,%esi
f01045fc:	c1 e6 18             	shl    $0x18,%esi
f01045ff:	89 f8                	mov    %edi,%eax
f0104601:	c1 e0 10             	shl    $0x10,%eax
f0104604:	09 f0                	or     %esi,%eax
f0104606:	09 c7                	or     %eax,%edi
		asm volatile("cld; rep stosl\n"
			: "=D" (p), "=c" (n)
			: "D" (p), "a" (c), "c" (n/4)
f0104608:	c1 e9 02             	shr    $0x2,%ecx

	if (n == 0)
		return v;
	if ((int)v%4 == 0 && n%4 == 0) {
		c &= 0xFF;
		c = (c<<24)|(c<<16)|(c<<8)|c;
f010460b:	89 f8                	mov    %edi,%eax
f010460d:	09 d8                	or     %ebx,%eax
		asm volatile("cld; rep stosl\n"
f010460f:	89 d7                	mov    %edx,%edi
f0104611:	fc                   	cld    
f0104612:	f3 ab                	rep stos %eax,%es:(%edi)
f0104614:	eb 08                	jmp    f010461e <memset+0x47>
			: "=D" (p), "=c" (n)
			: "D" (p), "a" (c), "c" (n/4)
			: "cc", "memory");
	} else
		asm volatile("cld; rep stosb\n"
f0104616:	89 d7                	mov    %edx,%edi
f0104618:	8b 45 0c             	mov    0xc(%ebp),%eax
f010461b:	fc                   	cld    
f010461c:	f3 aa                	rep stos %al,%es:(%edi)
			: "=D" (p), "=c" (n)
			: "0" (p), "a" (c), "1" (n)
			: "cc", "memory");
	return v;
}
f010461e:	89 d0                	mov    %edx,%eax
f0104620:	5b                   	pop    %ebx
f0104621:	5e                   	pop    %esi
f0104622:	5f                   	pop    %edi
f0104623:	5d                   	pop    %ebp
f0104624:	c3                   	ret    

f0104625 <memmove>:

void *
memmove(void *dst, const void *src, size_t n)
{
f0104625:	55                   	push   %ebp
f0104626:	89 e5                	mov    %esp,%ebp
f0104628:	57                   	push   %edi
f0104629:	56                   	push   %esi
f010462a:	8b 45 08             	mov    0x8(%ebp),%eax
f010462d:	8b 75 0c             	mov    0xc(%ebp),%esi
f0104630:	8b 4d 10             	mov    0x10(%ebp),%ecx
	const char *s;
	char *d;

	s = src;
	d = dst;
	if (s < d && s + n > d) {
f0104633:	39 c6                	cmp    %eax,%esi
f0104635:	73 35                	jae    f010466c <memmove+0x47>
f0104637:	8d 14 0e             	lea    (%esi,%ecx,1),%edx
f010463a:	39 d0                	cmp    %edx,%eax
f010463c:	73 2e                	jae    f010466c <memmove+0x47>
		s += n;
		d += n;
f010463e:	8d 3c 08             	lea    (%eax,%ecx,1),%edi
f0104641:	89 d6                	mov    %edx,%esi
f0104643:	09 fe                	or     %edi,%esi
		if ((int)s%4 == 0 && (int)d%4 == 0 && n%4 == 0)
f0104645:	f7 c6 03 00 00 00    	test   $0x3,%esi
f010464b:	75 13                	jne    f0104660 <memmove+0x3b>
f010464d:	f6 c1 03             	test   $0x3,%cl
f0104650:	75 0e                	jne    f0104660 <memmove+0x3b>
			asm volatile("std; rep movsl\n"
				:: "D" (d-4), "S" (s-4), "c" (n/4) : "cc", "memory");
f0104652:	83 ef 04             	sub    $0x4,%edi
f0104655:	8d 72 fc             	lea    -0x4(%edx),%esi
f0104658:	c1 e9 02             	shr    $0x2,%ecx
	d = dst;
	if (s < d && s + n > d) {
		s += n;
		d += n;
		if ((int)s%4 == 0 && (int)d%4 == 0 && n%4 == 0)
			asm volatile("std; rep movsl\n"
f010465b:	fd                   	std    
f010465c:	f3 a5                	rep movsl %ds:(%esi),%es:(%edi)
f010465e:	eb 09                	jmp    f0104669 <memmove+0x44>
				:: "D" (d-4), "S" (s-4), "c" (n/4) : "cc", "memory");
		else
			asm volatile("std; rep movsb\n"
				:: "D" (d-1), "S" (s-1), "c" (n) : "cc", "memory");
f0104660:	83 ef 01             	sub    $0x1,%edi
f0104663:	8d 72 ff             	lea    -0x1(%edx),%esi
		d += n;
		if ((int)s%4 == 0 && (int)d%4 == 0 && n%4 == 0)
			asm volatile("std; rep movsl\n"
				:: "D" (d-4), "S" (s-4), "c" (n/4) : "cc", "memory");
		else
			asm volatile("std; rep movsb\n"
f0104666:	fd                   	std    
f0104667:	f3 a4                	rep movsb %ds:(%esi),%es:(%edi)
				:: "D" (d-1), "S" (s-1), "c" (n) : "cc", "memory");
		// Some versions of GCC rely on DF being clear
		asm volatile("cld" ::: "cc");
f0104669:	fc                   	cld    
f010466a:	eb 1d                	jmp    f0104689 <memmove+0x64>
f010466c:	89 f2                	mov    %esi,%edx
f010466e:	09 c2                	or     %eax,%edx
	} else {
		if ((int)s%4 == 0 && (int)d%4 == 0 && n%4 == 0)
f0104670:	f6 c2 03             	test   $0x3,%dl
f0104673:	75 0f                	jne    f0104684 <memmove+0x5f>
f0104675:	f6 c1 03             	test   $0x3,%cl
f0104678:	75 0a                	jne    f0104684 <memmove+0x5f>
			asm volatile("cld; rep movsl\n"
				:: "D" (d), "S" (s), "c" (n/4) : "cc", "memory");
f010467a:	c1 e9 02             	shr    $0x2,%ecx
				:: "D" (d-1), "S" (s-1), "c" (n) : "cc", "memory");
		// Some versions of GCC rely on DF being clear
		asm volatile("cld" ::: "cc");
	} else {
		if ((int)s%4 == 0 && (int)d%4 == 0 && n%4 == 0)
			asm volatile("cld; rep movsl\n"
f010467d:	89 c7                	mov    %eax,%edi
f010467f:	fc                   	cld    
f0104680:	f3 a5                	rep movsl %ds:(%esi),%es:(%edi)
f0104682:	eb 05                	jmp    f0104689 <memmove+0x64>
				:: "D" (d), "S" (s), "c" (n/4) : "cc", "memory");
		else
			asm volatile("cld; rep movsb\n"
f0104684:	89 c7                	mov    %eax,%edi
f0104686:	fc                   	cld    
f0104687:	f3 a4                	rep movsb %ds:(%esi),%es:(%edi)
				:: "D" (d), "S" (s), "c" (n) : "cc", "memory");
	}
	return dst;
}
f0104689:	5e                   	pop    %esi
f010468a:	5f                   	pop    %edi
f010468b:	5d                   	pop    %ebp
f010468c:	c3                   	ret    

f010468d <memcpy>:
}
#endif

void *
memcpy(void *dst, const void *src, size_t n)
{
f010468d:	55                   	push   %ebp
f010468e:	89 e5                	mov    %esp,%ebp
f0104690:	83 ec 0c             	sub    $0xc,%esp
	return memmove(dst, src, n);
f0104693:	8b 45 10             	mov    0x10(%ebp),%eax
f0104696:	89 44 24 08          	mov    %eax,0x8(%esp)
f010469a:	8b 45 0c             	mov    0xc(%ebp),%eax
f010469d:	89 44 24 04          	mov    %eax,0x4(%esp)
f01046a1:	8b 45 08             	mov    0x8(%ebp),%eax
f01046a4:	89 04 24             	mov    %eax,(%esp)
f01046a7:	e8 79 ff ff ff       	call   f0104625 <memmove>
}
f01046ac:	c9                   	leave  
f01046ad:	c3                   	ret    

f01046ae <memcmp>:

int
memcmp(const void *v1, const void *v2, size_t n)
{
f01046ae:	55                   	push   %ebp
f01046af:	89 e5                	mov    %esp,%ebp
f01046b1:	56                   	push   %esi
f01046b2:	53                   	push   %ebx
f01046b3:	8b 55 08             	mov    0x8(%ebp),%edx
f01046b6:	8b 4d 0c             	mov    0xc(%ebp),%ecx
f01046b9:	89 d6                	mov    %edx,%esi
f01046bb:	03 75 10             	add    0x10(%ebp),%esi
	const uint8_t *s1 = (const uint8_t *) v1;
	const uint8_t *s2 = (const uint8_t *) v2;

	while (n-- > 0) {
f01046be:	eb 1a                	jmp    f01046da <memcmp+0x2c>
		if (*s1 != *s2)
f01046c0:	0f b6 02             	movzbl (%edx),%eax
f01046c3:	0f b6 19             	movzbl (%ecx),%ebx
f01046c6:	38 d8                	cmp    %bl,%al
f01046c8:	74 0a                	je     f01046d4 <memcmp+0x26>
			return (int) *s1 - (int) *s2;
f01046ca:	0f b6 c0             	movzbl %al,%eax
f01046cd:	0f b6 db             	movzbl %bl,%ebx
f01046d0:	29 d8                	sub    %ebx,%eax
f01046d2:	eb 0f                	jmp    f01046e3 <memcmp+0x35>
		s1++, s2++;
f01046d4:	83 c2 01             	add    $0x1,%edx
f01046d7:	83 c1 01             	add    $0x1,%ecx
memcmp(const void *v1, const void *v2, size_t n)
{
	const uint8_t *s1 = (const uint8_t *) v1;
	const uint8_t *s2 = (const uint8_t *) v2;

	while (n-- > 0) {
f01046da:	39 f2                	cmp    %esi,%edx
f01046dc:	75 e2                	jne    f01046c0 <memcmp+0x12>
		if (*s1 != *s2)
			return (int) *s1 - (int) *s2;
		s1++, s2++;
	}

	return 0;
f01046de:	b8 00 00 00 00       	mov    $0x0,%eax
}
f01046e3:	5b                   	pop    %ebx
f01046e4:	5e                   	pop    %esi
f01046e5:	5d                   	pop    %ebp
f01046e6:	c3                   	ret    

f01046e7 <memfind>:

void *
memfind(const void *s, int c, size_t n)
{
f01046e7:	55                   	push   %ebp
f01046e8:	89 e5                	mov    %esp,%ebp
f01046ea:	8b 45 08             	mov    0x8(%ebp),%eax
f01046ed:	8b 4d 0c             	mov    0xc(%ebp),%ecx
	const void *ends = (const char *) s + n;
f01046f0:	89 c2                	mov    %eax,%edx
f01046f2:	03 55 10             	add    0x10(%ebp),%edx
	for (; s < ends; s++)
f01046f5:	eb 07                	jmp    f01046fe <memfind+0x17>
		if (*(const unsigned char *) s == (unsigned char) c)
f01046f7:	38 08                	cmp    %cl,(%eax)
f01046f9:	74 07                	je     f0104702 <memfind+0x1b>

void *
memfind(const void *s, int c, size_t n)
{
	const void *ends = (const char *) s + n;
	for (; s < ends; s++)
f01046fb:	83 c0 01             	add    $0x1,%eax
f01046fe:	39 d0                	cmp    %edx,%eax
f0104700:	72 f5                	jb     f01046f7 <memfind+0x10>
		if (*(const unsigned char *) s == (unsigned char) c)
			break;
	return (void *) s;
}
f0104702:	5d                   	pop    %ebp
f0104703:	c3                   	ret    

f0104704 <strtol>:

long
strtol(const char *s, char **endptr, int base)
{
f0104704:	55                   	push   %ebp
f0104705:	89 e5                	mov    %esp,%ebp
f0104707:	57                   	push   %edi
f0104708:	56                   	push   %esi
f0104709:	53                   	push   %ebx
f010470a:	8b 55 08             	mov    0x8(%ebp),%edx
f010470d:	8b 45 10             	mov    0x10(%ebp),%eax
	int neg = 0;
	long val = 0;

	// gobble initial whitespace
	while (*s == ' ' || *s == '\t')
f0104710:	eb 03                	jmp    f0104715 <strtol+0x11>
		s++;
f0104712:	83 c2 01             	add    $0x1,%edx
{
	int neg = 0;
	long val = 0;

	// gobble initial whitespace
	while (*s == ' ' || *s == '\t')
f0104715:	0f b6 0a             	movzbl (%edx),%ecx
f0104718:	80 f9 09             	cmp    $0x9,%cl
f010471b:	74 f5                	je     f0104712 <strtol+0xe>
f010471d:	80 f9 20             	cmp    $0x20,%cl
f0104720:	74 f0                	je     f0104712 <strtol+0xe>
		s++;

	// plus/minus sign
	if (*s == '+')
f0104722:	80 f9 2b             	cmp    $0x2b,%cl
f0104725:	75 0a                	jne    f0104731 <strtol+0x2d>
		s++;
f0104727:	83 c2 01             	add    $0x1,%edx
}

long
strtol(const char *s, char **endptr, int base)
{
	int neg = 0;
f010472a:	bf 00 00 00 00       	mov    $0x0,%edi
f010472f:	eb 11                	jmp    f0104742 <strtol+0x3e>
f0104731:	bf 00 00 00 00       	mov    $0x0,%edi
		s++;

	// plus/minus sign
	if (*s == '+')
		s++;
	else if (*s == '-')
f0104736:	80 f9 2d             	cmp    $0x2d,%cl
f0104739:	75 07                	jne    f0104742 <strtol+0x3e>
		s++, neg = 1;
f010473b:	8d 52 01             	lea    0x1(%edx),%edx
f010473e:	66 bf 01 00          	mov    $0x1,%di

	// hex or octal base prefix
	if ((base == 0 || base == 16) && (s[0] == '0' && s[1] == 'x'))
f0104742:	a9 ef ff ff ff       	test   $0xffffffef,%eax
f0104747:	75 15                	jne    f010475e <strtol+0x5a>
f0104749:	80 3a 30             	cmpb   $0x30,(%edx)
f010474c:	75 10                	jne    f010475e <strtol+0x5a>
f010474e:	80 7a 01 78          	cmpb   $0x78,0x1(%edx)
f0104752:	75 0a                	jne    f010475e <strtol+0x5a>
		s += 2, base = 16;
f0104754:	83 c2 02             	add    $0x2,%edx
f0104757:	b8 10 00 00 00       	mov    $0x10,%eax
f010475c:	eb 10                	jmp    f010476e <strtol+0x6a>
	else if (base == 0 && s[0] == '0')
f010475e:	85 c0                	test   %eax,%eax
f0104760:	75 0c                	jne    f010476e <strtol+0x6a>
		s++, base = 8;
	else if (base == 0)
		base = 10;
f0104762:	b0 0a                	mov    $0xa,%al
		s++, neg = 1;

	// hex or octal base prefix
	if ((base == 0 || base == 16) && (s[0] == '0' && s[1] == 'x'))
		s += 2, base = 16;
	else if (base == 0 && s[0] == '0')
f0104764:	80 3a 30             	cmpb   $0x30,(%edx)
f0104767:	75 05                	jne    f010476e <strtol+0x6a>
		s++, base = 8;
f0104769:	83 c2 01             	add    $0x1,%edx
f010476c:	b0 08                	mov    $0x8,%al
	else if (base == 0)
		base = 10;
f010476e:	bb 00 00 00 00       	mov    $0x0,%ebx
f0104773:	89 45 10             	mov    %eax,0x10(%ebp)

	// digits
	while (1) {
		int dig;

		if (*s >= '0' && *s <= '9')
f0104776:	0f b6 0a             	movzbl (%edx),%ecx
f0104779:	8d 71 d0             	lea    -0x30(%ecx),%esi
f010477c:	89 f0                	mov    %esi,%eax
f010477e:	3c 09                	cmp    $0x9,%al
f0104780:	77 08                	ja     f010478a <strtol+0x86>
			dig = *s - '0';
f0104782:	0f be c9             	movsbl %cl,%ecx
f0104785:	83 e9 30             	sub    $0x30,%ecx
f0104788:	eb 20                	jmp    f01047aa <strtol+0xa6>
		else if (*s >= 'a' && *s <= 'z')
f010478a:	8d 71 9f             	lea    -0x61(%ecx),%esi
f010478d:	89 f0                	mov    %esi,%eax
f010478f:	3c 19                	cmp    $0x19,%al
f0104791:	77 08                	ja     f010479b <strtol+0x97>
			dig = *s - 'a' + 10;
f0104793:	0f be c9             	movsbl %cl,%ecx
f0104796:	83 e9 57             	sub    $0x57,%ecx
f0104799:	eb 0f                	jmp    f01047aa <strtol+0xa6>
		else if (*s >= 'A' && *s <= 'Z')
f010479b:	8d 71 bf             	lea    -0x41(%ecx),%esi
f010479e:	89 f0                	mov    %esi,%eax
f01047a0:	3c 19                	cmp    $0x19,%al
f01047a2:	77 16                	ja     f01047ba <strtol+0xb6>
			dig = *s - 'A' + 10;
f01047a4:	0f be c9             	movsbl %cl,%ecx
f01047a7:	83 e9 37             	sub    $0x37,%ecx
		else
			break;
		if (dig >= base)
f01047aa:	3b 4d 10             	cmp    0x10(%ebp),%ecx
f01047ad:	7d 0f                	jge    f01047be <strtol+0xba>
			break;
		s++, val = (val * base) + dig;
f01047af:	83 c2 01             	add    $0x1,%edx
f01047b2:	0f af 5d 10          	imul   0x10(%ebp),%ebx
f01047b6:	01 cb                	add    %ecx,%ebx
		// we don't properly detect overflow!
	}
f01047b8:	eb bc                	jmp    f0104776 <strtol+0x72>
f01047ba:	89 d8                	mov    %ebx,%eax
f01047bc:	eb 02                	jmp    f01047c0 <strtol+0xbc>
f01047be:	89 d8                	mov    %ebx,%eax

	if (endptr)
f01047c0:	83 7d 0c 00          	cmpl   $0x0,0xc(%ebp)
f01047c4:	74 05                	je     f01047cb <strtol+0xc7>
		*endptr = (char *) s;
f01047c6:	8b 75 0c             	mov    0xc(%ebp),%esi
f01047c9:	89 16                	mov    %edx,(%esi)
	return (neg ? -val : val);
f01047cb:	f7 d8                	neg    %eax
f01047cd:	85 ff                	test   %edi,%edi
f01047cf:	0f 44 c3             	cmove  %ebx,%eax
}
f01047d2:	5b                   	pop    %ebx
f01047d3:	5e                   	pop    %esi
f01047d4:	5f                   	pop    %edi
f01047d5:	5d                   	pop    %ebp
f01047d6:	c3                   	ret    
f01047d7:	66 90                	xchg   %ax,%ax
f01047d9:	66 90                	xchg   %ax,%ax
f01047db:	66 90                	xchg   %ax,%ax
f01047dd:	66 90                	xchg   %ax,%ax
f01047df:	90                   	nop

f01047e0 <__udivdi3>:
f01047e0:	55                   	push   %ebp
f01047e1:	57                   	push   %edi
f01047e2:	56                   	push   %esi
f01047e3:	53                   	push   %ebx
f01047e4:	83 ec 1c             	sub    $0x1c,%esp
f01047e7:	8b 74 24 3c          	mov    0x3c(%esp),%esi
f01047eb:	8b 5c 24 30          	mov    0x30(%esp),%ebx
f01047ef:	8b 4c 24 34          	mov    0x34(%esp),%ecx
f01047f3:	8b 7c 24 38          	mov    0x38(%esp),%edi
f01047f7:	85 f6                	test   %esi,%esi
f01047f9:	89 5c 24 08          	mov    %ebx,0x8(%esp)
f01047fd:	89 ca                	mov    %ecx,%edx
f01047ff:	89 f8                	mov    %edi,%eax
f0104801:	75 3d                	jne    f0104840 <__udivdi3+0x60>
f0104803:	39 cf                	cmp    %ecx,%edi
f0104805:	0f 87 c5 00 00 00    	ja     f01048d0 <__udivdi3+0xf0>
f010480b:	85 ff                	test   %edi,%edi
f010480d:	89 fd                	mov    %edi,%ebp
f010480f:	75 0b                	jne    f010481c <__udivdi3+0x3c>
f0104811:	b8 01 00 00 00       	mov    $0x1,%eax
f0104816:	31 d2                	xor    %edx,%edx
f0104818:	f7 f7                	div    %edi
f010481a:	89 c5                	mov    %eax,%ebp
f010481c:	89 c8                	mov    %ecx,%eax
f010481e:	31 d2                	xor    %edx,%edx
f0104820:	f7 f5                	div    %ebp
f0104822:	89 c1                	mov    %eax,%ecx
f0104824:	89 d8                	mov    %ebx,%eax
f0104826:	89 cf                	mov    %ecx,%edi
f0104828:	f7 f5                	div    %ebp
f010482a:	89 c3                	mov    %eax,%ebx
f010482c:	89 d8                	mov    %ebx,%eax
f010482e:	89 fa                	mov    %edi,%edx
f0104830:	83 c4 1c             	add    $0x1c,%esp
f0104833:	5b                   	pop    %ebx
f0104834:	5e                   	pop    %esi
f0104835:	5f                   	pop    %edi
f0104836:	5d                   	pop    %ebp
f0104837:	c3                   	ret    
f0104838:	90                   	nop
f0104839:	8d b4 26 00 00 00 00 	lea    0x0(%esi,%eiz,1),%esi
f0104840:	39 ce                	cmp    %ecx,%esi
f0104842:	77 74                	ja     f01048b8 <__udivdi3+0xd8>
f0104844:	0f bd fe             	bsr    %esi,%edi
f0104847:	83 f7 1f             	xor    $0x1f,%edi
f010484a:	0f 84 98 00 00 00    	je     f01048e8 <__udivdi3+0x108>
f0104850:	bb 20 00 00 00       	mov    $0x20,%ebx
f0104855:	89 f9                	mov    %edi,%ecx
f0104857:	89 c5                	mov    %eax,%ebp
f0104859:	29 fb                	sub    %edi,%ebx
f010485b:	d3 e6                	shl    %cl,%esi
f010485d:	89 d9                	mov    %ebx,%ecx
f010485f:	d3 ed                	shr    %cl,%ebp
f0104861:	89 f9                	mov    %edi,%ecx
f0104863:	d3 e0                	shl    %cl,%eax
f0104865:	09 ee                	or     %ebp,%esi
f0104867:	89 d9                	mov    %ebx,%ecx
f0104869:	89 44 24 0c          	mov    %eax,0xc(%esp)
f010486d:	89 d5                	mov    %edx,%ebp
f010486f:	8b 44 24 08          	mov    0x8(%esp),%eax
f0104873:	d3 ed                	shr    %cl,%ebp
f0104875:	89 f9                	mov    %edi,%ecx
f0104877:	d3 e2                	shl    %cl,%edx
f0104879:	89 d9                	mov    %ebx,%ecx
f010487b:	d3 e8                	shr    %cl,%eax
f010487d:	09 c2                	or     %eax,%edx
f010487f:	89 d0                	mov    %edx,%eax
f0104881:	89 ea                	mov    %ebp,%edx
f0104883:	f7 f6                	div    %esi
f0104885:	89 d5                	mov    %edx,%ebp
f0104887:	89 c3                	mov    %eax,%ebx
f0104889:	f7 64 24 0c          	mull   0xc(%esp)
f010488d:	39 d5                	cmp    %edx,%ebp
f010488f:	72 10                	jb     f01048a1 <__udivdi3+0xc1>
f0104891:	8b 74 24 08          	mov    0x8(%esp),%esi
f0104895:	89 f9                	mov    %edi,%ecx
f0104897:	d3 e6                	shl    %cl,%esi
f0104899:	39 c6                	cmp    %eax,%esi
f010489b:	73 07                	jae    f01048a4 <__udivdi3+0xc4>
f010489d:	39 d5                	cmp    %edx,%ebp
f010489f:	75 03                	jne    f01048a4 <__udivdi3+0xc4>
f01048a1:	83 eb 01             	sub    $0x1,%ebx
f01048a4:	31 ff                	xor    %edi,%edi
f01048a6:	89 d8                	mov    %ebx,%eax
f01048a8:	89 fa                	mov    %edi,%edx
f01048aa:	83 c4 1c             	add    $0x1c,%esp
f01048ad:	5b                   	pop    %ebx
f01048ae:	5e                   	pop    %esi
f01048af:	5f                   	pop    %edi
f01048b0:	5d                   	pop    %ebp
f01048b1:	c3                   	ret    
f01048b2:	8d b6 00 00 00 00    	lea    0x0(%esi),%esi
f01048b8:	31 ff                	xor    %edi,%edi
f01048ba:	31 db                	xor    %ebx,%ebx
f01048bc:	89 d8                	mov    %ebx,%eax
f01048be:	89 fa                	mov    %edi,%edx
f01048c0:	83 c4 1c             	add    $0x1c,%esp
f01048c3:	5b                   	pop    %ebx
f01048c4:	5e                   	pop    %esi
f01048c5:	5f                   	pop    %edi
f01048c6:	5d                   	pop    %ebp
f01048c7:	c3                   	ret    
f01048c8:	90                   	nop
f01048c9:	8d b4 26 00 00 00 00 	lea    0x0(%esi,%eiz,1),%esi
f01048d0:	89 d8                	mov    %ebx,%eax
f01048d2:	f7 f7                	div    %edi
f01048d4:	31 ff                	xor    %edi,%edi
f01048d6:	89 c3                	mov    %eax,%ebx
f01048d8:	89 d8                	mov    %ebx,%eax
f01048da:	89 fa                	mov    %edi,%edx
f01048dc:	83 c4 1c             	add    $0x1c,%esp
f01048df:	5b                   	pop    %ebx
f01048e0:	5e                   	pop    %esi
f01048e1:	5f                   	pop    %edi
f01048e2:	5d                   	pop    %ebp
f01048e3:	c3                   	ret    
f01048e4:	8d 74 26 00          	lea    0x0(%esi,%eiz,1),%esi
f01048e8:	39 ce                	cmp    %ecx,%esi
f01048ea:	72 0c                	jb     f01048f8 <__udivdi3+0x118>
f01048ec:	31 db                	xor    %ebx,%ebx
f01048ee:	3b 44 24 08          	cmp    0x8(%esp),%eax
f01048f2:	0f 87 34 ff ff ff    	ja     f010482c <__udivdi3+0x4c>
f01048f8:	bb 01 00 00 00       	mov    $0x1,%ebx
f01048fd:	e9 2a ff ff ff       	jmp    f010482c <__udivdi3+0x4c>
f0104902:	66 90                	xchg   %ax,%ax
f0104904:	66 90                	xchg   %ax,%ax
f0104906:	66 90                	xchg   %ax,%ax
f0104908:	66 90                	xchg   %ax,%ax
f010490a:	66 90                	xchg   %ax,%ax
f010490c:	66 90                	xchg   %ax,%ax
f010490e:	66 90                	xchg   %ax,%ax

f0104910 <__umoddi3>:
f0104910:	55                   	push   %ebp
f0104911:	57                   	push   %edi
f0104912:	56                   	push   %esi
f0104913:	53                   	push   %ebx
f0104914:	83 ec 1c             	sub    $0x1c,%esp
f0104917:	8b 54 24 3c          	mov    0x3c(%esp),%edx
f010491b:	8b 4c 24 30          	mov    0x30(%esp),%ecx
f010491f:	8b 74 24 34          	mov    0x34(%esp),%esi
f0104923:	8b 7c 24 38          	mov    0x38(%esp),%edi
f0104927:	85 d2                	test   %edx,%edx
f0104929:	89 4c 24 0c          	mov    %ecx,0xc(%esp)
f010492d:	89 4c 24 08          	mov    %ecx,0x8(%esp)
f0104931:	89 f3                	mov    %esi,%ebx
f0104933:	89 3c 24             	mov    %edi,(%esp)
f0104936:	89 74 24 04          	mov    %esi,0x4(%esp)
f010493a:	75 1c                	jne    f0104958 <__umoddi3+0x48>
f010493c:	39 f7                	cmp    %esi,%edi
f010493e:	76 50                	jbe    f0104990 <__umoddi3+0x80>
f0104940:	89 c8                	mov    %ecx,%eax
f0104942:	89 f2                	mov    %esi,%edx
f0104944:	f7 f7                	div    %edi
f0104946:	89 d0                	mov    %edx,%eax
f0104948:	31 d2                	xor    %edx,%edx
f010494a:	83 c4 1c             	add    $0x1c,%esp
f010494d:	5b                   	pop    %ebx
f010494e:	5e                   	pop    %esi
f010494f:	5f                   	pop    %edi
f0104950:	5d                   	pop    %ebp
f0104951:	c3                   	ret    
f0104952:	8d b6 00 00 00 00    	lea    0x0(%esi),%esi
f0104958:	39 f2                	cmp    %esi,%edx
f010495a:	89 d0                	mov    %edx,%eax
f010495c:	77 52                	ja     f01049b0 <__umoddi3+0xa0>
f010495e:	0f bd ea             	bsr    %edx,%ebp
f0104961:	83 f5 1f             	xor    $0x1f,%ebp
f0104964:	75 5a                	jne    f01049c0 <__umoddi3+0xb0>
f0104966:	3b 54 24 04          	cmp    0x4(%esp),%edx
f010496a:	0f 82 e0 00 00 00    	jb     f0104a50 <__umoddi3+0x140>
f0104970:	39 0c 24             	cmp    %ecx,(%esp)
f0104973:	0f 86 d7 00 00 00    	jbe    f0104a50 <__umoddi3+0x140>
f0104979:	8b 44 24 08          	mov    0x8(%esp),%eax
f010497d:	8b 54 24 04          	mov    0x4(%esp),%edx
f0104981:	83 c4 1c             	add    $0x1c,%esp
f0104984:	5b                   	pop    %ebx
f0104985:	5e                   	pop    %esi
f0104986:	5f                   	pop    %edi
f0104987:	5d                   	pop    %ebp
f0104988:	c3                   	ret    
f0104989:	8d b4 26 00 00 00 00 	lea    0x0(%esi,%eiz,1),%esi
f0104990:	85 ff                	test   %edi,%edi
f0104992:	89 fd                	mov    %edi,%ebp
f0104994:	75 0b                	jne    f01049a1 <__umoddi3+0x91>
f0104996:	b8 01 00 00 00       	mov    $0x1,%eax
f010499b:	31 d2                	xor    %edx,%edx
f010499d:	f7 f7                	div    %edi
f010499f:	89 c5                	mov    %eax,%ebp
f01049a1:	89 f0                	mov    %esi,%eax
f01049a3:	31 d2                	xor    %edx,%edx
f01049a5:	f7 f5                	div    %ebp
f01049a7:	89 c8                	mov    %ecx,%eax
f01049a9:	f7 f5                	div    %ebp
f01049ab:	89 d0                	mov    %edx,%eax
f01049ad:	eb 99                	jmp    f0104948 <__umoddi3+0x38>
f01049af:	90                   	nop
f01049b0:	89 c8                	mov    %ecx,%eax
f01049b2:	89 f2                	mov    %esi,%edx
f01049b4:	83 c4 1c             	add    $0x1c,%esp
f01049b7:	5b                   	pop    %ebx
f01049b8:	5e                   	pop    %esi
f01049b9:	5f                   	pop    %edi
f01049ba:	5d                   	pop    %ebp
f01049bb:	c3                   	ret    
f01049bc:	8d 74 26 00          	lea    0x0(%esi,%eiz,1),%esi
f01049c0:	8b 34 24             	mov    (%esp),%esi
f01049c3:	bf 20 00 00 00       	mov    $0x20,%edi
f01049c8:	89 e9                	mov    %ebp,%ecx
f01049ca:	29 ef                	sub    %ebp,%edi
f01049cc:	d3 e0                	shl    %cl,%eax
f01049ce:	89 f9                	mov    %edi,%ecx
f01049d0:	89 f2                	mov    %esi,%edx
f01049d2:	d3 ea                	shr    %cl,%edx
f01049d4:	89 e9                	mov    %ebp,%ecx
f01049d6:	09 c2                	or     %eax,%edx
f01049d8:	89 d8                	mov    %ebx,%eax
f01049da:	89 14 24             	mov    %edx,(%esp)
f01049dd:	89 f2                	mov    %esi,%edx
f01049df:	d3 e2                	shl    %cl,%edx
f01049e1:	89 f9                	mov    %edi,%ecx
f01049e3:	89 54 24 04          	mov    %edx,0x4(%esp)
f01049e7:	8b 54 24 0c          	mov    0xc(%esp),%edx
f01049eb:	d3 e8                	shr    %cl,%eax
f01049ed:	89 e9                	mov    %ebp,%ecx
f01049ef:	89 c6                	mov    %eax,%esi
f01049f1:	d3 e3                	shl    %cl,%ebx
f01049f3:	89 f9                	mov    %edi,%ecx
f01049f5:	89 d0                	mov    %edx,%eax
f01049f7:	d3 e8                	shr    %cl,%eax
f01049f9:	89 e9                	mov    %ebp,%ecx
f01049fb:	09 d8                	or     %ebx,%eax
f01049fd:	89 d3                	mov    %edx,%ebx
f01049ff:	89 f2                	mov    %esi,%edx
f0104a01:	f7 34 24             	divl   (%esp)
f0104a04:	89 d6                	mov    %edx,%esi
f0104a06:	d3 e3                	shl    %cl,%ebx
f0104a08:	f7 64 24 04          	mull   0x4(%esp)
f0104a0c:	39 d6                	cmp    %edx,%esi
f0104a0e:	89 5c 24 08          	mov    %ebx,0x8(%esp)
f0104a12:	89 d1                	mov    %edx,%ecx
f0104a14:	89 c3                	mov    %eax,%ebx
f0104a16:	72 08                	jb     f0104a20 <__umoddi3+0x110>
f0104a18:	75 11                	jne    f0104a2b <__umoddi3+0x11b>
f0104a1a:	39 44 24 08          	cmp    %eax,0x8(%esp)
f0104a1e:	73 0b                	jae    f0104a2b <__umoddi3+0x11b>
f0104a20:	2b 44 24 04          	sub    0x4(%esp),%eax
f0104a24:	1b 14 24             	sbb    (%esp),%edx
f0104a27:	89 d1                	mov    %edx,%ecx
f0104a29:	89 c3                	mov    %eax,%ebx
f0104a2b:	8b 54 24 08          	mov    0x8(%esp),%edx
f0104a2f:	29 da                	sub    %ebx,%edx
f0104a31:	19 ce                	sbb    %ecx,%esi
f0104a33:	89 f9                	mov    %edi,%ecx
f0104a35:	89 f0                	mov    %esi,%eax
f0104a37:	d3 e0                	shl    %cl,%eax
f0104a39:	89 e9                	mov    %ebp,%ecx
f0104a3b:	d3 ea                	shr    %cl,%edx
f0104a3d:	89 e9                	mov    %ebp,%ecx
f0104a3f:	d3 ee                	shr    %cl,%esi
f0104a41:	09 d0                	or     %edx,%eax
f0104a43:	89 f2                	mov    %esi,%edx
f0104a45:	83 c4 1c             	add    $0x1c,%esp
f0104a48:	5b                   	pop    %ebx
f0104a49:	5e                   	pop    %esi
f0104a4a:	5f                   	pop    %edi
f0104a4b:	5d                   	pop    %ebp
f0104a4c:	c3                   	ret    
f0104a4d:	8d 76 00             	lea    0x0(%esi),%esi
f0104a50:	29 f9                	sub    %edi,%ecx
f0104a52:	19 d6                	sbb    %edx,%esi
f0104a54:	89 74 24 04          	mov    %esi,0x4(%esp)
f0104a58:	89 4c 24 08          	mov    %ecx,0x8(%esp)
f0104a5c:	e9 18 ff ff ff       	jmp    f0104979 <__umoddi3+0x69>
