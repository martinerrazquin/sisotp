
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
f0100015:	b8 00 f0 10 00       	mov    $0x10f000,%eax
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
f010003d:	bc 00 f0 10 f0       	mov    $0xf010f000,%esp

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
f010004f:	b8 90 59 19 f0       	mov    $0xf0195990,%eax
f0100054:	2d 80 3a 19 f0       	sub    $0xf0193a80,%eax
f0100059:	50                   	push   %eax
f010005a:	6a 00                	push   $0x0
f010005c:	68 80 3a 19 f0       	push   $0xf0193a80
f0100061:	e8 19 43 00 00       	call   f010437f <memset>

	// Initialize the console.
	// Can't call cprintf until after we do this!
	cons_init();
f0100066:	e8 8d 06 00 00       	call   f01006f8 <cons_init>

	cprintf("6828 decimal is %o octal!\n", 6828);
f010006b:	83 c4 08             	add    $0x8,%esp
f010006e:	68 ac 1a 00 00       	push   $0x1aac
f0100073:	68 20 48 10 f0       	push   $0xf0104820
f0100078:	e8 fb 2e 00 00       	call   f0102f78 <cprintf>

	// Lab 2 memory management initialization functions
	mem_init();
f010007d:	e8 44 25 00 00       	call   f01025c6 <mem_init>

	// Lab 3 user environment initialization functions
	env_init();
f0100082:	e8 1e 2b 00 00       	call   f0102ba5 <env_init>
	trap_init();
f0100087:	e8 a3 2f 00 00       	call   f010302f <trap_init>

#if defined(TEST)
	// Don't touch -- used by grading script!
	ENV_CREATE(TEST, ENV_TYPE_USER);
f010008c:	83 c4 08             	add    $0x8,%esp
f010008f:	6a 00                	push   $0x0
f0100091:	68 f6 ed 12 f0       	push   $0xf012edf6
f0100096:	e8 34 2c 00 00       	call   f0102ccf <env_create>
#else
	// Touch all you want.
	ENV_CREATE(user_hello, ENV_TYPE_USER);
#endif // TEST*
	// We only have one user environment for now, so just run it.
	env_run(&envs[0]);
f010009b:	83 c4 04             	add    $0x4,%esp
f010009e:	ff 35 c8 3c 19 f0    	pushl  0xf0193cc8
f01000a4:	e8 f6 2d 00 00       	call   f0102e9f <env_run>

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
f01000b1:	83 3d 80 59 19 f0 00 	cmpl   $0x0,0xf0195980
f01000b8:	75 37                	jne    f01000f1 <_panic+0x48>
		goto dead;
	panicstr = fmt;
f01000ba:	89 35 80 59 19 f0    	mov    %esi,0xf0195980

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
f01000ce:	68 5c 48 10 f0       	push   $0xf010485c
f01000d3:	e8 a0 2e 00 00       	call   f0102f78 <cprintf>
	vcprintf(fmt, ap);
f01000d8:	83 c4 08             	add    $0x8,%esp
f01000db:	53                   	push   %ebx
f01000dc:	56                   	push   %esi
f01000dd:	e8 70 2e 00 00       	call   f0102f52 <vcprintf>
	cprintf("\n>>>\n");
f01000e2:	c7 04 24 3b 48 10 f0 	movl   $0xf010483b,(%esp)
f01000e9:	e8 8a 2e 00 00       	call   f0102f78 <cprintf>
	va_end(ap);
f01000ee:	83 c4 10             	add    $0x10,%esp

dead:
	/* break into the kernel monitor */
	while (1)
		monitor(NULL);
f01000f1:	83 ec 0c             	sub    $0xc,%esp
f01000f4:	6a 00                	push   $0x0
f01000f6:	e8 cb 08 00 00       	call   f01009c6 <monitor>
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
f0100110:	68 41 48 10 f0       	push   $0xf0104841
f0100115:	e8 5e 2e 00 00       	call   f0102f78 <cprintf>
	vcprintf(fmt, ap);
f010011a:	83 c4 08             	add    $0x8,%esp
f010011d:	53                   	push   %ebx
f010011e:	ff 75 10             	pushl  0x10(%ebp)
f0100121:	e8 2c 2e 00 00       	call   f0102f52 <vcprintf>
	cprintf("\n");
f0100126:	c7 04 24 9e 59 10 f0 	movl   $0xf010599e,(%esp)
f010012d:	e8 46 2e 00 00       	call   f0102f78 <cprintf>
	va_end(ap);
}
f0100132:	83 c4 10             	add    $0x10,%esp
f0100135:	8b 5d fc             	mov    -0x4(%ebp),%ebx
f0100138:	c9                   	leave  
f0100139:	c3                   	ret    

f010013a <inb>:
	asm volatile("int3");
}

static inline uint8_t
inb(int port)
{
f010013a:	55                   	push   %ebp
f010013b:	89 e5                	mov    %esp,%ebp
	uint8_t data;
	asm volatile("inb %w1,%0" : "=a" (data) : "d" (port));
f010013d:	89 c2                	mov    %eax,%edx
f010013f:	ec                   	in     (%dx),%al
	return data;
}
f0100140:	5d                   	pop    %ebp
f0100141:	c3                   	ret    

f0100142 <outb>:
		     : "memory", "cc");
}

static inline void
outb(int port, uint8_t data)
{
f0100142:	55                   	push   %ebp
f0100143:	89 e5                	mov    %esp,%ebp
f0100145:	89 c1                	mov    %eax,%ecx
f0100147:	89 d0                	mov    %edx,%eax
	asm volatile("outb %0,%w1" : : "a" (data), "d" (port));
f0100149:	89 ca                	mov    %ecx,%edx
f010014b:	ee                   	out    %al,(%dx)
}
f010014c:	5d                   	pop    %ebp
f010014d:	c3                   	ret    

f010014e <delay>:
static void cons_putc(int c);

// Stupid I/O delay routine necessitated by historical PC design flaws
static void
delay(void)
{
f010014e:	55                   	push   %ebp
f010014f:	89 e5                	mov    %esp,%ebp
	inb(0x84);
f0100151:	b8 84 00 00 00       	mov    $0x84,%eax
f0100156:	e8 df ff ff ff       	call   f010013a <inb>
	inb(0x84);
f010015b:	b8 84 00 00 00       	mov    $0x84,%eax
f0100160:	e8 d5 ff ff ff       	call   f010013a <inb>
	inb(0x84);
f0100165:	b8 84 00 00 00       	mov    $0x84,%eax
f010016a:	e8 cb ff ff ff       	call   f010013a <inb>
	inb(0x84);
f010016f:	b8 84 00 00 00       	mov    $0x84,%eax
f0100174:	e8 c1 ff ff ff       	call   f010013a <inb>
}
f0100179:	5d                   	pop    %ebp
f010017a:	c3                   	ret    

f010017b <serial_proc_data>:

static bool serial_exists;

static int
serial_proc_data(void)
{
f010017b:	55                   	push   %ebp
f010017c:	89 e5                	mov    %esp,%ebp
	if (!(inb(COM1+COM_LSR) & COM_LSR_DATA))
f010017e:	b8 fd 03 00 00       	mov    $0x3fd,%eax
f0100183:	e8 b2 ff ff ff       	call   f010013a <inb>
f0100188:	a8 01                	test   $0x1,%al
f010018a:	74 0f                	je     f010019b <serial_proc_data+0x20>
		return -1;
	return inb(COM1+COM_RX);
f010018c:	b8 f8 03 00 00       	mov    $0x3f8,%eax
f0100191:	e8 a4 ff ff ff       	call   f010013a <inb>
f0100196:	0f b6 c0             	movzbl %al,%eax
f0100199:	eb 05                	jmp    f01001a0 <serial_proc_data+0x25>

static int
serial_proc_data(void)
{
	if (!(inb(COM1+COM_LSR) & COM_LSR_DATA))
		return -1;
f010019b:	b8 ff ff ff ff       	mov    $0xffffffff,%eax
	return inb(COM1+COM_RX);
}
f01001a0:	5d                   	pop    %ebp
f01001a1:	c3                   	ret    

f01001a2 <serial_putc>:
		cons_intr(serial_proc_data);
}

static void
serial_putc(int c)
{
f01001a2:	55                   	push   %ebp
f01001a3:	89 e5                	mov    %esp,%ebp
f01001a5:	56                   	push   %esi
f01001a6:	53                   	push   %ebx
f01001a7:	89 c6                	mov    %eax,%esi
	int i;

	for (i = 0;
f01001a9:	bb 00 00 00 00       	mov    $0x0,%ebx
f01001ae:	eb 08                	jmp    f01001b8 <serial_putc+0x16>
	     !(inb(COM1 + COM_LSR) & COM_LSR_TXRDY) && i < 12800;
	     i++)
		delay();
f01001b0:	e8 99 ff ff ff       	call   f010014e <delay>
{
	int i;

	for (i = 0;
	     !(inb(COM1 + COM_LSR) & COM_LSR_TXRDY) && i < 12800;
	     i++)
f01001b5:	83 c3 01             	add    $0x1,%ebx
serial_putc(int c)
{
	int i;

	for (i = 0;
	     !(inb(COM1 + COM_LSR) & COM_LSR_TXRDY) && i < 12800;
f01001b8:	b8 fd 03 00 00       	mov    $0x3fd,%eax
f01001bd:	e8 78 ff ff ff       	call   f010013a <inb>
f01001c2:	a8 20                	test   $0x20,%al
f01001c4:	75 08                	jne    f01001ce <serial_putc+0x2c>
f01001c6:	81 fb ff 31 00 00    	cmp    $0x31ff,%ebx
f01001cc:	7e e2                	jle    f01001b0 <serial_putc+0xe>
	     i++)
		delay();

	outb(COM1 + COM_TX, c);
f01001ce:	89 f0                	mov    %esi,%eax
f01001d0:	0f b6 d0             	movzbl %al,%edx
f01001d3:	b8 f8 03 00 00       	mov    $0x3f8,%eax
f01001d8:	e8 65 ff ff ff       	call   f0100142 <outb>
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
f01001ee:	e8 4f ff ff ff       	call   f0100142 <outb>

	// Set speed; requires DLAB latch
	outb(COM1+COM_LCR, COM_LCR_DLAB);
f01001f3:	ba 80 00 00 00       	mov    $0x80,%edx
f01001f8:	b8 fb 03 00 00       	mov    $0x3fb,%eax
f01001fd:	e8 40 ff ff ff       	call   f0100142 <outb>
	outb(COM1+COM_DLL, (uint8_t) (115200 / 9600));
f0100202:	ba 0c 00 00 00       	mov    $0xc,%edx
f0100207:	b8 f8 03 00 00       	mov    $0x3f8,%eax
f010020c:	e8 31 ff ff ff       	call   f0100142 <outb>
	outb(COM1+COM_DLM, 0);
f0100211:	ba 00 00 00 00       	mov    $0x0,%edx
f0100216:	b8 f9 03 00 00       	mov    $0x3f9,%eax
f010021b:	e8 22 ff ff ff       	call   f0100142 <outb>

	// 8 data bits, 1 stop bit, parity off; turn off DLAB latch
	outb(COM1+COM_LCR, COM_LCR_WLEN8 & ~COM_LCR_DLAB);
f0100220:	ba 03 00 00 00       	mov    $0x3,%edx
f0100225:	b8 fb 03 00 00       	mov    $0x3fb,%eax
f010022a:	e8 13 ff ff ff       	call   f0100142 <outb>

	// No modem controls
	outb(COM1+COM_MCR, 0);
f010022f:	ba 00 00 00 00       	mov    $0x0,%edx
f0100234:	b8 fc 03 00 00       	mov    $0x3fc,%eax
f0100239:	e8 04 ff ff ff       	call   f0100142 <outb>
	// Enable rcv interrupts
	outb(COM1+COM_IER, COM_IER_RDI);
f010023e:	ba 01 00 00 00       	mov    $0x1,%edx
f0100243:	b8 f9 03 00 00       	mov    $0x3f9,%eax
f0100248:	e8 f5 fe ff ff       	call   f0100142 <outb>

	// Clear any preexisting overrun indications and interrupts
	// Serial port doesn't exist if COM_LSR returns 0xFF
	serial_exists = (inb(COM1+COM_LSR) != 0xFF);
f010024d:	b8 fd 03 00 00       	mov    $0x3fd,%eax
f0100252:	e8 e3 fe ff ff       	call   f010013a <inb>
f0100257:	3c ff                	cmp    $0xff,%al
f0100259:	0f 95 05 b4 3c 19 f0 	setne  0xf0193cb4
	(void) inb(COM1+COM_IIR);
f0100260:	b8 fa 03 00 00       	mov    $0x3fa,%eax
f0100265:	e8 d0 fe ff ff       	call   f010013a <inb>
	(void) inb(COM1+COM_RX);
f010026a:	b8 f8 03 00 00       	mov    $0x3f8,%eax
f010026f:	e8 c6 fe ff ff       	call   f010013a <inb>

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
f010027d:	bb 00 00 00 00       	mov    $0x0,%ebx
f0100282:	eb 08                	jmp    f010028c <lpt_putc+0x16>
		delay();
f0100284:	e8 c5 fe ff ff       	call   f010014e <delay>
static void
lpt_putc(int c)
{
	int i;

	for (i = 0; !(inb(0x378+1) & 0x80) && i < 12800; i++)
f0100289:	83 c3 01             	add    $0x1,%ebx
f010028c:	b8 79 03 00 00       	mov    $0x379,%eax
f0100291:	e8 a4 fe ff ff       	call   f010013a <inb>
f0100296:	81 fb ff 31 00 00    	cmp    $0x31ff,%ebx
f010029c:	7f 04                	jg     f01002a2 <lpt_putc+0x2c>
f010029e:	84 c0                	test   %al,%al
f01002a0:	79 e2                	jns    f0100284 <lpt_putc+0xe>
		delay();
	outb(0x378+0, c);
f01002a2:	89 f0                	mov    %esi,%eax
f01002a4:	0f b6 d0             	movzbl %al,%edx
f01002a7:	b8 78 03 00 00       	mov    $0x378,%eax
f01002ac:	e8 91 fe ff ff       	call   f0100142 <outb>
	outb(0x378+2, 0x08|0x04|0x01);
f01002b1:	ba 0d 00 00 00       	mov    $0xd,%edx
f01002b6:	b8 7a 03 00 00       	mov    $0x37a,%eax
f01002bb:	e8 82 fe ff ff       	call   f0100142 <outb>
	outb(0x378+2, 0x08);
f01002c0:	ba 08 00 00 00       	mov    $0x8,%edx
f01002c5:	b8 7a 03 00 00       	mov    $0x37a,%eax
f01002ca:	e8 73 fe ff ff       	call   f0100142 <outb>
}
f01002cf:	5b                   	pop    %ebx
f01002d0:	5e                   	pop    %esi
f01002d1:	5d                   	pop    %ebp
f01002d2:	c3                   	ret    

f01002d3 <cga_init>:
static uint16_t *crt_buf;
static uint16_t crt_pos;

static void
cga_init(void)
{
f01002d3:	55                   	push   %ebp
f01002d4:	89 e5                	mov    %esp,%ebp
f01002d6:	57                   	push   %edi
f01002d7:	56                   	push   %esi
f01002d8:	53                   	push   %ebx
f01002d9:	83 ec 04             	sub    $0x4,%esp
	volatile uint16_t *cp;
	uint16_t was;
	unsigned pos;

	cp = (uint16_t*) (KERNBASE + CGA_BUF);
	was = *cp;
f01002dc:	0f b7 15 00 80 0b f0 	movzwl 0xf00b8000,%edx
	*cp = (uint16_t) 0xA55A;
f01002e3:	66 c7 05 00 80 0b f0 	movw   $0xa55a,0xf00b8000
f01002ea:	5a a5 
	if (*cp != 0xA55A) {
f01002ec:	0f b7 05 00 80 0b f0 	movzwl 0xf00b8000,%eax
f01002f3:	66 3d 5a a5          	cmp    $0xa55a,%ax
f01002f7:	74 13                	je     f010030c <cga_init+0x39>
		cp = (uint16_t*) (KERNBASE + MONO_BUF);
		addr_6845 = MONO_BASE;
f01002f9:	c7 05 b0 3c 19 f0 b4 	movl   $0x3b4,0xf0193cb0
f0100300:	03 00 00 

	cp = (uint16_t*) (KERNBASE + CGA_BUF);
	was = *cp;
	*cp = (uint16_t) 0xA55A;
	if (*cp != 0xA55A) {
		cp = (uint16_t*) (KERNBASE + MONO_BUF);
f0100303:	c7 45 f0 00 00 0b f0 	movl   $0xf00b0000,-0x10(%ebp)
f010030a:	eb 18                	jmp    f0100324 <cga_init+0x51>
		addr_6845 = MONO_BASE;
	} else {
		*cp = was;
f010030c:	66 89 15 00 80 0b f0 	mov    %dx,0xf00b8000
		addr_6845 = CGA_BASE;
f0100313:	c7 05 b0 3c 19 f0 d4 	movl   $0x3d4,0xf0193cb0
f010031a:	03 00 00 
{
	volatile uint16_t *cp;
	uint16_t was;
	unsigned pos;

	cp = (uint16_t*) (KERNBASE + CGA_BUF);
f010031d:	c7 45 f0 00 80 0b f0 	movl   $0xf00b8000,-0x10(%ebp)
		*cp = was;
		addr_6845 = CGA_BASE;
	}

	/* Extract cursor location */
	outb(addr_6845, 14);
f0100324:	8b 35 b0 3c 19 f0    	mov    0xf0193cb0,%esi
f010032a:	ba 0e 00 00 00       	mov    $0xe,%edx
f010032f:	89 f0                	mov    %esi,%eax
f0100331:	e8 0c fe ff ff       	call   f0100142 <outb>
	pos = inb(addr_6845 + 1) << 8;
f0100336:	8d 7e 01             	lea    0x1(%esi),%edi
f0100339:	89 f8                	mov    %edi,%eax
f010033b:	e8 fa fd ff ff       	call   f010013a <inb>
f0100340:	0f b6 d8             	movzbl %al,%ebx
f0100343:	c1 e3 08             	shl    $0x8,%ebx
	outb(addr_6845, 15);
f0100346:	ba 0f 00 00 00       	mov    $0xf,%edx
f010034b:	89 f0                	mov    %esi,%eax
f010034d:	e8 f0 fd ff ff       	call   f0100142 <outb>
	pos |= inb(addr_6845 + 1);
f0100352:	89 f8                	mov    %edi,%eax
f0100354:	e8 e1 fd ff ff       	call   f010013a <inb>

	crt_buf = (uint16_t*) cp;
f0100359:	8b 4d f0             	mov    -0x10(%ebp),%ecx
f010035c:	89 0d ac 3c 19 f0    	mov    %ecx,0xf0193cac
	crt_pos = pos;
f0100362:	0f b6 c0             	movzbl %al,%eax
f0100365:	09 c3                	or     %eax,%ebx
f0100367:	66 89 1d a8 3c 19 f0 	mov    %bx,0xf0193ca8
}
f010036e:	83 c4 04             	add    $0x4,%esp
f0100371:	5b                   	pop    %ebx
f0100372:	5e                   	pop    %esi
f0100373:	5f                   	pop    %edi
f0100374:	5d                   	pop    %ebp
f0100375:	c3                   	ret    

f0100376 <cons_intr>:

// called by device interrupt routines to feed input characters
// into the circular console input buffer.
static void
cons_intr(int (*proc)(void))
{
f0100376:	55                   	push   %ebp
f0100377:	89 e5                	mov    %esp,%ebp
f0100379:	53                   	push   %ebx
f010037a:	83 ec 04             	sub    $0x4,%esp
f010037d:	89 c3                	mov    %eax,%ebx
	int c;

	while ((c = (*proc)()) != -1) {
f010037f:	eb 2b                	jmp    f01003ac <cons_intr+0x36>
		if (c == 0)
f0100381:	85 c0                	test   %eax,%eax
f0100383:	74 27                	je     f01003ac <cons_intr+0x36>
			continue;
		cons.buf[cons.wpos++] = c;
f0100385:	8b 0d a4 3c 19 f0    	mov    0xf0193ca4,%ecx
f010038b:	8d 51 01             	lea    0x1(%ecx),%edx
f010038e:	89 15 a4 3c 19 f0    	mov    %edx,0xf0193ca4
f0100394:	88 81 a0 3a 19 f0    	mov    %al,-0xfe6c560(%ecx)
		if (cons.wpos == CONSBUFSIZE)
f010039a:	81 fa 00 02 00 00    	cmp    $0x200,%edx
f01003a0:	75 0a                	jne    f01003ac <cons_intr+0x36>
			cons.wpos = 0;
f01003a2:	c7 05 a4 3c 19 f0 00 	movl   $0x0,0xf0193ca4
f01003a9:	00 00 00 
static void
cons_intr(int (*proc)(void))
{
	int c;

	while ((c = (*proc)()) != -1) {
f01003ac:	ff d3                	call   *%ebx
f01003ae:	83 f8 ff             	cmp    $0xffffffff,%eax
f01003b1:	75 ce                	jne    f0100381 <cons_intr+0xb>
			continue;
		cons.buf[cons.wpos++] = c;
		if (cons.wpos == CONSBUFSIZE)
			cons.wpos = 0;
	}
}
f01003b3:	83 c4 04             	add    $0x4,%esp
f01003b6:	5b                   	pop    %ebx
f01003b7:	5d                   	pop    %ebp
f01003b8:	c3                   	ret    

f01003b9 <kbd_proc_data>:
 * Get data from the keyboard.  If we finish a character, return it.  Else 0.
 * Return -1 if no data.
 */
static int
kbd_proc_data(void)
{
f01003b9:	55                   	push   %ebp
f01003ba:	89 e5                	mov    %esp,%ebp
f01003bc:	53                   	push   %ebx
f01003bd:	83 ec 04             	sub    $0x4,%esp
	int c;
	uint8_t stat, data;
	static uint32_t shift;

	stat = inb(KBSTATP);
f01003c0:	b8 64 00 00 00       	mov    $0x64,%eax
f01003c5:	e8 70 fd ff ff       	call   f010013a <inb>
	if ((stat & KBS_DIB) == 0)
f01003ca:	a8 01                	test   $0x1,%al
f01003cc:	0f 84 fe 00 00 00    	je     f01004d0 <kbd_proc_data+0x117>
		return -1;
	// Ignore data from mouse.
	if (stat & KBS_TERR)
f01003d2:	a8 20                	test   $0x20,%al
f01003d4:	0f 85 fd 00 00 00    	jne    f01004d7 <kbd_proc_data+0x11e>
		return -1;

	data = inb(KBDATAP);
f01003da:	b8 60 00 00 00       	mov    $0x60,%eax
f01003df:	e8 56 fd ff ff       	call   f010013a <inb>

	if (data == 0xE0) {
f01003e4:	3c e0                	cmp    $0xe0,%al
f01003e6:	75 11                	jne    f01003f9 <kbd_proc_data+0x40>
		// E0 escape character
		shift |= E0ESC;
f01003e8:	83 0d 80 3a 19 f0 40 	orl    $0x40,0xf0193a80
		return 0;
f01003ef:	b8 00 00 00 00       	mov    $0x0,%eax
f01003f4:	e9 e7 00 00 00       	jmp    f01004e0 <kbd_proc_data+0x127>
	} else if (data & 0x80) {
f01003f9:	84 c0                	test   %al,%al
f01003fb:	79 38                	jns    f0100435 <kbd_proc_data+0x7c>
		// Key released
		data = (shift & E0ESC ? data : data & 0x7F);
f01003fd:	8b 0d 80 3a 19 f0    	mov    0xf0193a80,%ecx
f0100403:	89 cb                	mov    %ecx,%ebx
f0100405:	83 e3 40             	and    $0x40,%ebx
f0100408:	89 c2                	mov    %eax,%edx
f010040a:	83 e2 7f             	and    $0x7f,%edx
f010040d:	85 db                	test   %ebx,%ebx
f010040f:	0f 44 c2             	cmove  %edx,%eax
		shift &= ~(shiftcode[data] | E0ESC);
f0100412:	0f b6 c0             	movzbl %al,%eax
f0100415:	0f b6 80 e0 49 10 f0 	movzbl -0xfefb620(%eax),%eax
f010041c:	83 c8 40             	or     $0x40,%eax
f010041f:	0f b6 c0             	movzbl %al,%eax
f0100422:	f7 d0                	not    %eax
f0100424:	21 c8                	and    %ecx,%eax
f0100426:	a3 80 3a 19 f0       	mov    %eax,0xf0193a80
		return 0;
f010042b:	b8 00 00 00 00       	mov    $0x0,%eax
f0100430:	e9 ab 00 00 00       	jmp    f01004e0 <kbd_proc_data+0x127>
	} else if (shift & E0ESC) {
f0100435:	8b 15 80 3a 19 f0    	mov    0xf0193a80,%edx
f010043b:	f6 c2 40             	test   $0x40,%dl
f010043e:	74 0c                	je     f010044c <kbd_proc_data+0x93>
		// Last character was an E0 escape; or with 0x80
		data |= 0x80;
f0100440:	83 c8 80             	or     $0xffffff80,%eax
		shift &= ~E0ESC;
f0100443:	83 e2 bf             	and    $0xffffffbf,%edx
f0100446:	89 15 80 3a 19 f0    	mov    %edx,0xf0193a80
	}

	shift |= shiftcode[data];
f010044c:	0f b6 c0             	movzbl %al,%eax
	shift ^= togglecode[data];
f010044f:	0f b6 90 e0 49 10 f0 	movzbl -0xfefb620(%eax),%edx
f0100456:	0b 15 80 3a 19 f0    	or     0xf0193a80,%edx
f010045c:	0f b6 88 e0 48 10 f0 	movzbl -0xfefb720(%eax),%ecx
f0100463:	31 ca                	xor    %ecx,%edx
f0100465:	89 15 80 3a 19 f0    	mov    %edx,0xf0193a80

	c = charcode[shift & (CTL | SHIFT)][data];
f010046b:	89 d1                	mov    %edx,%ecx
f010046d:	83 e1 03             	and    $0x3,%ecx
f0100470:	8b 0c 8d c0 48 10 f0 	mov    -0xfefb740(,%ecx,4),%ecx
f0100477:	0f b6 04 01          	movzbl (%ecx,%eax,1),%eax
f010047b:	0f b6 d8             	movzbl %al,%ebx
	if (shift & CAPSLOCK) {
f010047e:	f6 c2 08             	test   $0x8,%dl
f0100481:	74 1b                	je     f010049e <kbd_proc_data+0xe5>
		if ('a' <= c && c <= 'z')
f0100483:	89 d8                	mov    %ebx,%eax
f0100485:	8d 4b 9f             	lea    -0x61(%ebx),%ecx
f0100488:	83 f9 19             	cmp    $0x19,%ecx
f010048b:	77 05                	ja     f0100492 <kbd_proc_data+0xd9>
			c += 'A' - 'a';
f010048d:	83 eb 20             	sub    $0x20,%ebx
f0100490:	eb 0c                	jmp    f010049e <kbd_proc_data+0xe5>
		else if ('A' <= c && c <= 'Z')
f0100492:	83 e8 41             	sub    $0x41,%eax
			c += 'a' - 'A';
f0100495:	8d 4b 20             	lea    0x20(%ebx),%ecx
f0100498:	83 f8 19             	cmp    $0x19,%eax
f010049b:	0f 46 d9             	cmovbe %ecx,%ebx
	}

	// Process special keys
	// Ctrl-Alt-Del: reboot
	if (!(~shift & (CTL | ALT)) && c == KEY_DEL) {
f010049e:	f7 d2                	not    %edx
f01004a0:	f6 c2 06             	test   $0x6,%dl
f01004a3:	75 39                	jne    f01004de <kbd_proc_data+0x125>
f01004a5:	81 fb e9 00 00 00    	cmp    $0xe9,%ebx
f01004ab:	75 31                	jne    f01004de <kbd_proc_data+0x125>
		cprintf("Rebooting!\n");
f01004ad:	83 ec 0c             	sub    $0xc,%esp
f01004b0:	68 7c 48 10 f0       	push   $0xf010487c
f01004b5:	e8 be 2a 00 00       	call   f0102f78 <cprintf>
		outb(0x92, 0x3); // courtesy of Chris Frost
f01004ba:	ba 03 00 00 00       	mov    $0x3,%edx
f01004bf:	b8 92 00 00 00       	mov    $0x92,%eax
f01004c4:	e8 79 fc ff ff       	call   f0100142 <outb>
f01004c9:	83 c4 10             	add    $0x10,%esp
	}

	return c;
f01004cc:	89 d8                	mov    %ebx,%eax
f01004ce:	eb 10                	jmp    f01004e0 <kbd_proc_data+0x127>
	uint8_t stat, data;
	static uint32_t shift;

	stat = inb(KBSTATP);
	if ((stat & KBS_DIB) == 0)
		return -1;
f01004d0:	b8 ff ff ff ff       	mov    $0xffffffff,%eax
f01004d5:	eb 09                	jmp    f01004e0 <kbd_proc_data+0x127>
	// Ignore data from mouse.
	if (stat & KBS_TERR)
		return -1;
f01004d7:	b8 ff ff ff ff       	mov    $0xffffffff,%eax
f01004dc:	eb 02                	jmp    f01004e0 <kbd_proc_data+0x127>
	if (!(~shift & (CTL | ALT)) && c == KEY_DEL) {
		cprintf("Rebooting!\n");
		outb(0x92, 0x3); // courtesy of Chris Frost
	}

	return c;
f01004de:	89 d8                	mov    %ebx,%eax
}
f01004e0:	8b 5d fc             	mov    -0x4(%ebp),%ebx
f01004e3:	c9                   	leave  
f01004e4:	c3                   	ret    

f01004e5 <cga_putc>:



static void
cga_putc(int c)
{
f01004e5:	55                   	push   %ebp
f01004e6:	89 e5                	mov    %esp,%ebp
f01004e8:	57                   	push   %edi
f01004e9:	56                   	push   %esi
f01004ea:	53                   	push   %ebx
f01004eb:	83 ec 0c             	sub    $0xc,%esp
	// if no attribute given, then use black on white
	if (!(c & ~0xFF))
f01004ee:	89 c1                	mov    %eax,%ecx
f01004f0:	81 e1 00 ff ff ff    	and    $0xffffff00,%ecx
		c |= 0x0700;
f01004f6:	89 c2                	mov    %eax,%edx
f01004f8:	80 ce 07             	or     $0x7,%dh
f01004fb:	85 c9                	test   %ecx,%ecx
f01004fd:	0f 44 c2             	cmove  %edx,%eax

	switch (c & 0xff) {
f0100500:	0f b6 d0             	movzbl %al,%edx
f0100503:	83 fa 09             	cmp    $0x9,%edx
f0100506:	74 72                	je     f010057a <cga_putc+0x95>
f0100508:	83 fa 09             	cmp    $0x9,%edx
f010050b:	7f 0a                	jg     f0100517 <cga_putc+0x32>
f010050d:	83 fa 08             	cmp    $0x8,%edx
f0100510:	74 14                	je     f0100526 <cga_putc+0x41>
f0100512:	e9 97 00 00 00       	jmp    f01005ae <cga_putc+0xc9>
f0100517:	83 fa 0a             	cmp    $0xa,%edx
f010051a:	74 38                	je     f0100554 <cga_putc+0x6f>
f010051c:	83 fa 0d             	cmp    $0xd,%edx
f010051f:	74 3b                	je     f010055c <cga_putc+0x77>
f0100521:	e9 88 00 00 00       	jmp    f01005ae <cga_putc+0xc9>
	case '\b':
		if (crt_pos > 0) {
f0100526:	0f b7 15 a8 3c 19 f0 	movzwl 0xf0193ca8,%edx
f010052d:	66 85 d2             	test   %dx,%dx
f0100530:	0f 84 e4 00 00 00    	je     f010061a <cga_putc+0x135>
			crt_pos--;
f0100536:	83 ea 01             	sub    $0x1,%edx
f0100539:	66 89 15 a8 3c 19 f0 	mov    %dx,0xf0193ca8
			crt_buf[crt_pos] = (c & ~0xff) | ' ';
f0100540:	0f b7 d2             	movzwl %dx,%edx
f0100543:	b0 00                	mov    $0x0,%al
f0100545:	83 c8 20             	or     $0x20,%eax
f0100548:	8b 0d ac 3c 19 f0    	mov    0xf0193cac,%ecx
f010054e:	66 89 04 51          	mov    %ax,(%ecx,%edx,2)
f0100552:	eb 78                	jmp    f01005cc <cga_putc+0xe7>
		}
		break;
	case '\n':
		crt_pos += CRT_COLS;
f0100554:	66 83 05 a8 3c 19 f0 	addw   $0x50,0xf0193ca8
f010055b:	50 
		/* fallthru */
	case '\r':
		crt_pos -= (crt_pos % CRT_COLS);
f010055c:	0f b7 05 a8 3c 19 f0 	movzwl 0xf0193ca8,%eax
f0100563:	69 c0 cd cc 00 00    	imul   $0xcccd,%eax,%eax
f0100569:	c1 e8 16             	shr    $0x16,%eax
f010056c:	8d 04 80             	lea    (%eax,%eax,4),%eax
f010056f:	c1 e0 04             	shl    $0x4,%eax
f0100572:	66 a3 a8 3c 19 f0    	mov    %ax,0xf0193ca8
		break;
f0100578:	eb 52                	jmp    f01005cc <cga_putc+0xe7>
	case '\t':
		cons_putc(' ');
f010057a:	b8 20 00 00 00       	mov    $0x20,%eax
f010057f:	e8 da 00 00 00       	call   f010065e <cons_putc>
		cons_putc(' ');
f0100584:	b8 20 00 00 00       	mov    $0x20,%eax
f0100589:	e8 d0 00 00 00       	call   f010065e <cons_putc>
		cons_putc(' ');
f010058e:	b8 20 00 00 00       	mov    $0x20,%eax
f0100593:	e8 c6 00 00 00       	call   f010065e <cons_putc>
		cons_putc(' ');
f0100598:	b8 20 00 00 00       	mov    $0x20,%eax
f010059d:	e8 bc 00 00 00       	call   f010065e <cons_putc>
		cons_putc(' ');
f01005a2:	b8 20 00 00 00       	mov    $0x20,%eax
f01005a7:	e8 b2 00 00 00       	call   f010065e <cons_putc>
		break;
f01005ac:	eb 1e                	jmp    f01005cc <cga_putc+0xe7>
	default:
		crt_buf[crt_pos++] = c;		/* write the character */
f01005ae:	0f b7 15 a8 3c 19 f0 	movzwl 0xf0193ca8,%edx
f01005b5:	8d 4a 01             	lea    0x1(%edx),%ecx
f01005b8:	66 89 0d a8 3c 19 f0 	mov    %cx,0xf0193ca8
f01005bf:	0f b7 d2             	movzwl %dx,%edx
f01005c2:	8b 0d ac 3c 19 f0    	mov    0xf0193cac,%ecx
f01005c8:	66 89 04 51          	mov    %ax,(%ecx,%edx,2)
		break;
	}

	// What is the purpose of this?
	if (crt_pos >= CRT_SIZE) {
f01005cc:	66 81 3d a8 3c 19 f0 	cmpw   $0x7cf,0xf0193ca8
f01005d3:	cf 07 
f01005d5:	76 43                	jbe    f010061a <cga_putc+0x135>
		int i;

		memmove(crt_buf, crt_buf + CRT_COLS, (CRT_SIZE - CRT_COLS) * sizeof(uint16_t));
f01005d7:	a1 ac 3c 19 f0       	mov    0xf0193cac,%eax
f01005dc:	83 ec 04             	sub    $0x4,%esp
f01005df:	68 00 0f 00 00       	push   $0xf00
f01005e4:	8d 90 a0 00 00 00    	lea    0xa0(%eax),%edx
f01005ea:	52                   	push   %edx
f01005eb:	50                   	push   %eax
f01005ec:	e8 dc 3d 00 00       	call   f01043cd <memmove>
		for (i = CRT_SIZE - CRT_COLS; i < CRT_SIZE; i++)
			crt_buf[i] = 0x0700 | ' ';
f01005f1:	8b 15 ac 3c 19 f0    	mov    0xf0193cac,%edx
f01005f7:	8d 82 00 0f 00 00    	lea    0xf00(%edx),%eax
f01005fd:	81 c2 a0 0f 00 00    	add    $0xfa0,%edx
f0100603:	83 c4 10             	add    $0x10,%esp
f0100606:	66 c7 00 20 07       	movw   $0x720,(%eax)
f010060b:	83 c0 02             	add    $0x2,%eax
	// What is the purpose of this?
	if (crt_pos >= CRT_SIZE) {
		int i;

		memmove(crt_buf, crt_buf + CRT_COLS, (CRT_SIZE - CRT_COLS) * sizeof(uint16_t));
		for (i = CRT_SIZE - CRT_COLS; i < CRT_SIZE; i++)
f010060e:	39 d0                	cmp    %edx,%eax
f0100610:	75 f4                	jne    f0100606 <cga_putc+0x121>
			crt_buf[i] = 0x0700 | ' ';
		crt_pos -= CRT_COLS;
f0100612:	66 83 2d a8 3c 19 f0 	subw   $0x50,0xf0193ca8
f0100619:	50 
	}

	/* move that little blinky thing */
	outb(addr_6845, 14);
f010061a:	8b 3d b0 3c 19 f0    	mov    0xf0193cb0,%edi
f0100620:	ba 0e 00 00 00       	mov    $0xe,%edx
f0100625:	89 f8                	mov    %edi,%eax
f0100627:	e8 16 fb ff ff       	call   f0100142 <outb>
	outb(addr_6845 + 1, crt_pos >> 8);
f010062c:	0f b7 1d a8 3c 19 f0 	movzwl 0xf0193ca8,%ebx
f0100633:	8d 77 01             	lea    0x1(%edi),%esi
f0100636:	0f b6 d7             	movzbl %bh,%edx
f0100639:	89 f0                	mov    %esi,%eax
f010063b:	e8 02 fb ff ff       	call   f0100142 <outb>
	outb(addr_6845, 15);
f0100640:	ba 0f 00 00 00       	mov    $0xf,%edx
f0100645:	89 f8                	mov    %edi,%eax
f0100647:	e8 f6 fa ff ff       	call   f0100142 <outb>
	outb(addr_6845 + 1, crt_pos);
f010064c:	0f b6 d3             	movzbl %bl,%edx
f010064f:	89 f0                	mov    %esi,%eax
f0100651:	e8 ec fa ff ff       	call   f0100142 <outb>
}
f0100656:	8d 65 f4             	lea    -0xc(%ebp),%esp
f0100659:	5b                   	pop    %ebx
f010065a:	5e                   	pop    %esi
f010065b:	5f                   	pop    %edi
f010065c:	5d                   	pop    %ebp
f010065d:	c3                   	ret    

f010065e <cons_putc>:
}

// output a character to the console
static void
cons_putc(int c)
{
f010065e:	55                   	push   %ebp
f010065f:	89 e5                	mov    %esp,%ebp
f0100661:	53                   	push   %ebx
f0100662:	83 ec 04             	sub    $0x4,%esp
f0100665:	89 c3                	mov    %eax,%ebx
	serial_putc(c);
f0100667:	e8 36 fb ff ff       	call   f01001a2 <serial_putc>
	lpt_putc(c);
f010066c:	89 d8                	mov    %ebx,%eax
f010066e:	e8 03 fc ff ff       	call   f0100276 <lpt_putc>
	cga_putc(c);
f0100673:	89 d8                	mov    %ebx,%eax
f0100675:	e8 6b fe ff ff       	call   f01004e5 <cga_putc>
}
f010067a:	83 c4 04             	add    $0x4,%esp
f010067d:	5b                   	pop    %ebx
f010067e:	5d                   	pop    %ebp
f010067f:	c3                   	ret    

f0100680 <serial_intr>:
}

void
serial_intr(void)
{
	if (serial_exists)
f0100680:	80 3d b4 3c 19 f0 00 	cmpb   $0x0,0xf0193cb4
f0100687:	74 11                	je     f010069a <serial_intr+0x1a>
	return inb(COM1+COM_RX);
}

void
serial_intr(void)
{
f0100689:	55                   	push   %ebp
f010068a:	89 e5                	mov    %esp,%ebp
f010068c:	83 ec 08             	sub    $0x8,%esp
	if (serial_exists)
		cons_intr(serial_proc_data);
f010068f:	b8 7b 01 10 f0       	mov    $0xf010017b,%eax
f0100694:	e8 dd fc ff ff       	call   f0100376 <cons_intr>
}
f0100699:	c9                   	leave  
f010069a:	f3 c3                	repz ret 

f010069c <kbd_intr>:
	return c;
}

void
kbd_intr(void)
{
f010069c:	55                   	push   %ebp
f010069d:	89 e5                	mov    %esp,%ebp
f010069f:	83 ec 08             	sub    $0x8,%esp
	cons_intr(kbd_proc_data);
f01006a2:	b8 b9 03 10 f0       	mov    $0xf01003b9,%eax
f01006a7:	e8 ca fc ff ff       	call   f0100376 <cons_intr>
}
f01006ac:	c9                   	leave  
f01006ad:	c3                   	ret    

f01006ae <cons_getc>:
}

// return the next input character from the console, or 0 if none waiting
int
cons_getc(void)
{
f01006ae:	55                   	push   %ebp
f01006af:	89 e5                	mov    %esp,%ebp
f01006b1:	83 ec 08             	sub    $0x8,%esp
	int c;

	// poll for any pending input characters,
	// so that this function works even when interrupts are disabled
	// (e.g., when called from the kernel monitor).
	serial_intr();
f01006b4:	e8 c7 ff ff ff       	call   f0100680 <serial_intr>
	kbd_intr();
f01006b9:	e8 de ff ff ff       	call   f010069c <kbd_intr>

	// grab the next character from the input buffer.
	if (cons.rpos != cons.wpos) {
f01006be:	a1 a0 3c 19 f0       	mov    0xf0193ca0,%eax
f01006c3:	3b 05 a4 3c 19 f0    	cmp    0xf0193ca4,%eax
f01006c9:	74 26                	je     f01006f1 <cons_getc+0x43>
		c = cons.buf[cons.rpos++];
f01006cb:	8d 50 01             	lea    0x1(%eax),%edx
f01006ce:	89 15 a0 3c 19 f0    	mov    %edx,0xf0193ca0
f01006d4:	0f b6 88 a0 3a 19 f0 	movzbl -0xfe6c560(%eax),%ecx
		if (cons.rpos == CONSBUFSIZE)
			cons.rpos = 0;
		return c;
f01006db:	89 c8                	mov    %ecx,%eax
	kbd_intr();

	// grab the next character from the input buffer.
	if (cons.rpos != cons.wpos) {
		c = cons.buf[cons.rpos++];
		if (cons.rpos == CONSBUFSIZE)
f01006dd:	81 fa 00 02 00 00    	cmp    $0x200,%edx
f01006e3:	75 11                	jne    f01006f6 <cons_getc+0x48>
			cons.rpos = 0;
f01006e5:	c7 05 a0 3c 19 f0 00 	movl   $0x0,0xf0193ca0
f01006ec:	00 00 00 
f01006ef:	eb 05                	jmp    f01006f6 <cons_getc+0x48>
		return c;
	}
	return 0;
f01006f1:	b8 00 00 00 00       	mov    $0x0,%eax
}
f01006f6:	c9                   	leave  
f01006f7:	c3                   	ret    

f01006f8 <cons_init>:
}

// initialize the console devices
void
cons_init(void)
{
f01006f8:	55                   	push   %ebp
f01006f9:	89 e5                	mov    %esp,%ebp
f01006fb:	83 ec 08             	sub    $0x8,%esp
	cga_init();
f01006fe:	e8 d0 fb ff ff       	call   f01002d3 <cga_init>
	kbd_init();
	serial_init();
f0100703:	e8 d9 fa ff ff       	call   f01001e1 <serial_init>

	if (!serial_exists)
f0100708:	80 3d b4 3c 19 f0 00 	cmpb   $0x0,0xf0193cb4
f010070f:	75 10                	jne    f0100721 <cons_init+0x29>
		cprintf("Serial port does not exist!\n");
f0100711:	83 ec 0c             	sub    $0xc,%esp
f0100714:	68 88 48 10 f0       	push   $0xf0104888
f0100719:	e8 5a 28 00 00       	call   f0102f78 <cprintf>
f010071e:	83 c4 10             	add    $0x10,%esp
}
f0100721:	c9                   	leave  
f0100722:	c3                   	ret    

f0100723 <cputchar>:

// `High'-level console I/O.  Used by readline and cprintf.

void
cputchar(int c)
{
f0100723:	55                   	push   %ebp
f0100724:	89 e5                	mov    %esp,%ebp
f0100726:	83 ec 08             	sub    $0x8,%esp
	cons_putc(c);
f0100729:	8b 45 08             	mov    0x8(%ebp),%eax
f010072c:	e8 2d ff ff ff       	call   f010065e <cons_putc>
}
f0100731:	c9                   	leave  
f0100732:	c3                   	ret    

f0100733 <getchar>:

int
getchar(void)
{
f0100733:	55                   	push   %ebp
f0100734:	89 e5                	mov    %esp,%ebp
f0100736:	83 ec 08             	sub    $0x8,%esp
	int c;

	while ((c = cons_getc()) == 0)
f0100739:	e8 70 ff ff ff       	call   f01006ae <cons_getc>
f010073e:	85 c0                	test   %eax,%eax
f0100740:	74 f7                	je     f0100739 <getchar+0x6>
		/* do nothing */;
	return c;
}
f0100742:	c9                   	leave  
f0100743:	c3                   	ret    

f0100744 <iscons>:

int
iscons(int fdnum)
{
f0100744:	55                   	push   %ebp
f0100745:	89 e5                	mov    %esp,%ebp
	// used by readline
	return 1;
}
f0100747:	b8 01 00 00 00       	mov    $0x1,%eax
f010074c:	5d                   	pop    %ebp
f010074d:	c3                   	ret    

f010074e <mon_help>:

/***** Implementations of basic kernel monitor commands *****/

int
mon_help(int argc, char **argv, struct Trapframe *tf)
{
f010074e:	55                   	push   %ebp
f010074f:	89 e5                	mov    %esp,%ebp
f0100751:	83 ec 0c             	sub    $0xc,%esp
	int i;

	for (i = 0; i < ARRAY_SIZE(commands); i++)
		cprintf("%s - %s\n", commands[i].name, commands[i].desc);
f0100754:	68 e0 4a 10 f0       	push   $0xf0104ae0
f0100759:	68 fe 4a 10 f0       	push   $0xf0104afe
f010075e:	68 03 4b 10 f0       	push   $0xf0104b03
f0100763:	e8 10 28 00 00       	call   f0102f78 <cprintf>
f0100768:	83 c4 0c             	add    $0xc,%esp
f010076b:	68 a0 4b 10 f0       	push   $0xf0104ba0
f0100770:	68 0c 4b 10 f0       	push   $0xf0104b0c
f0100775:	68 03 4b 10 f0       	push   $0xf0104b03
f010077a:	e8 f9 27 00 00       	call   f0102f78 <cprintf>
f010077f:	83 c4 0c             	add    $0xc,%esp
f0100782:	68 15 4b 10 f0       	push   $0xf0104b15
f0100787:	68 29 4b 10 f0       	push   $0xf0104b29
f010078c:	68 03 4b 10 f0       	push   $0xf0104b03
f0100791:	e8 e2 27 00 00       	call   f0102f78 <cprintf>
	return 0;
}
f0100796:	b8 00 00 00 00       	mov    $0x0,%eax
f010079b:	c9                   	leave  
f010079c:	c3                   	ret    

f010079d <mon_kerninfo>:

int
mon_kerninfo(int argc, char **argv, struct Trapframe *tf)
{
f010079d:	55                   	push   %ebp
f010079e:	89 e5                	mov    %esp,%ebp
f01007a0:	83 ec 14             	sub    $0x14,%esp
	extern char _start[], entry[], etext[], edata[], end[];

	cprintf("Special kernel symbols:\n");
f01007a3:	68 33 4b 10 f0       	push   $0xf0104b33
f01007a8:	e8 cb 27 00 00       	call   f0102f78 <cprintf>
	cprintf("  _start                  %08x (phys)\n", _start);
f01007ad:	83 c4 08             	add    $0x8,%esp
f01007b0:	68 0c 00 10 00       	push   $0x10000c
f01007b5:	68 c8 4b 10 f0       	push   $0xf0104bc8
f01007ba:	e8 b9 27 00 00       	call   f0102f78 <cprintf>
	cprintf("  entry  %08x (virt)  %08x (phys)\n", entry, entry - KERNBASE);
f01007bf:	83 c4 0c             	add    $0xc,%esp
f01007c2:	68 0c 00 10 00       	push   $0x10000c
f01007c7:	68 0c 00 10 f0       	push   $0xf010000c
f01007cc:	68 f0 4b 10 f0       	push   $0xf0104bf0
f01007d1:	e8 a2 27 00 00       	call   f0102f78 <cprintf>
	cprintf("  etext  %08x (virt)  %08x (phys)\n", etext, etext - KERNBASE);
f01007d6:	83 c4 0c             	add    $0xc,%esp
f01007d9:	68 01 48 10 00       	push   $0x104801
f01007de:	68 01 48 10 f0       	push   $0xf0104801
f01007e3:	68 14 4c 10 f0       	push   $0xf0104c14
f01007e8:	e8 8b 27 00 00       	call   f0102f78 <cprintf>
	cprintf("  edata  %08x (virt)  %08x (phys)\n", edata, edata - KERNBASE);
f01007ed:	83 c4 0c             	add    $0xc,%esp
f01007f0:	68 6c 3a 19 00       	push   $0x193a6c
f01007f5:	68 6c 3a 19 f0       	push   $0xf0193a6c
f01007fa:	68 38 4c 10 f0       	push   $0xf0104c38
f01007ff:	e8 74 27 00 00       	call   f0102f78 <cprintf>
	cprintf("  end    %08x (virt)  %08x (phys)\n", end, end - KERNBASE);
f0100804:	83 c4 0c             	add    $0xc,%esp
f0100807:	68 90 59 19 00       	push   $0x195990
f010080c:	68 90 59 19 f0       	push   $0xf0195990
f0100811:	68 5c 4c 10 f0       	push   $0xf0104c5c
f0100816:	e8 5d 27 00 00       	call   f0102f78 <cprintf>
	cprintf("Kernel executable memory footprint: %dKB\n",
		ROUNDUP(end - entry, 1024) / 1024);
f010081b:	b8 8f 5d 19 f0       	mov    $0xf0195d8f,%eax
f0100820:	2d 0c 00 10 f0       	sub    $0xf010000c,%eax
	cprintf("  _start                  %08x (phys)\n", _start);
	cprintf("  entry  %08x (virt)  %08x (phys)\n", entry, entry - KERNBASE);
	cprintf("  etext  %08x (virt)  %08x (phys)\n", etext, etext - KERNBASE);
	cprintf("  edata  %08x (virt)  %08x (phys)\n", edata, edata - KERNBASE);
	cprintf("  end    %08x (virt)  %08x (phys)\n", end, end - KERNBASE);
	cprintf("Kernel executable memory footprint: %dKB\n",
f0100825:	83 c4 08             	add    $0x8,%esp
f0100828:	25 00 fc ff ff       	and    $0xfffffc00,%eax
f010082d:	8d 90 ff 03 00 00    	lea    0x3ff(%eax),%edx
f0100833:	85 c0                	test   %eax,%eax
f0100835:	0f 48 c2             	cmovs  %edx,%eax
f0100838:	c1 f8 0a             	sar    $0xa,%eax
f010083b:	50                   	push   %eax
f010083c:	68 80 4c 10 f0       	push   $0xf0104c80
f0100841:	e8 32 27 00 00       	call   f0102f78 <cprintf>
		ROUNDUP(end - entry, 1024) / 1024);
	return 0;
}
f0100846:	b8 00 00 00 00       	mov    $0x0,%eax
f010084b:	c9                   	leave  
f010084c:	c3                   	ret    

f010084d <mon_backtrace>:

int
mon_backtrace(int argc, char **argv, struct Trapframe *tf)
{
f010084d:	55                   	push   %ebp
f010084e:	89 e5                	mov    %esp,%ebp
f0100850:	57                   	push   %edi
f0100851:	56                   	push   %esi
f0100852:	53                   	push   %ebx
f0100853:	83 ec 2c             	sub    $0x2c,%esp

static inline uint32_t __attribute__((always_inline))
read_ebp(void)
{
	uint32_t ebp;
	asm volatile("movl %%ebp,%0" : "=r" (ebp));
f0100856:	89 eb                	mov    %ebp,%ebx
	while (ebp != 0x0){
	uint32_t eip=*(uint32_t *)(ebp+4);
	cprintf("  ebp %08x eip %08x args %08x %08x %08x %08x %08x\n", ebp, eip, 
			*(uint32_t *)(ebp+8), *(uint32_t *)(ebp+12), *(uint32_t *)(ebp+16),
			*(uint32_t *)(ebp+20), *(uint32_t *)(ebp+24));
	debuginfo_eip(eip,&dbgi);
f0100858:	8d 7d d0             	lea    -0x30(%ebp),%edi
int
mon_backtrace(int argc, char **argv, struct Trapframe *tf)
{
	uint32_t ebp = read_ebp();
	struct Eipdebuginfo dbgi;
	while (ebp != 0x0){
f010085b:	eb 4a                	jmp    f01008a7 <mon_backtrace+0x5a>
	uint32_t eip=*(uint32_t *)(ebp+4);
f010085d:	8b 73 04             	mov    0x4(%ebx),%esi
	cprintf("  ebp %08x eip %08x args %08x %08x %08x %08x %08x\n", ebp, eip, 
f0100860:	ff 73 18             	pushl  0x18(%ebx)
f0100863:	ff 73 14             	pushl  0x14(%ebx)
f0100866:	ff 73 10             	pushl  0x10(%ebx)
f0100869:	ff 73 0c             	pushl  0xc(%ebx)
f010086c:	ff 73 08             	pushl  0x8(%ebx)
f010086f:	56                   	push   %esi
f0100870:	53                   	push   %ebx
f0100871:	68 ac 4c 10 f0       	push   $0xf0104cac
f0100876:	e8 fd 26 00 00       	call   f0102f78 <cprintf>
			*(uint32_t *)(ebp+8), *(uint32_t *)(ebp+12), *(uint32_t *)(ebp+16),
			*(uint32_t *)(ebp+20), *(uint32_t *)(ebp+24));
	debuginfo_eip(eip,&dbgi);
f010087b:	83 c4 18             	add    $0x18,%esp
f010087e:	57                   	push   %edi
f010087f:	56                   	push   %esi
f0100880:	e8 3f 31 00 00       	call   f01039c4 <debuginfo_eip>
	cprintf("       %s:%d: %.*s+%d\n", dbgi.eip_file, dbgi.eip_line, dbgi.eip_fn_namelen, 
f0100885:	83 c4 08             	add    $0x8,%esp
f0100888:	2b 75 e0             	sub    -0x20(%ebp),%esi
f010088b:	56                   	push   %esi
f010088c:	ff 75 d8             	pushl  -0x28(%ebp)
f010088f:	ff 75 dc             	pushl  -0x24(%ebp)
f0100892:	ff 75 d4             	pushl  -0x2c(%ebp)
f0100895:	ff 75 d0             	pushl  -0x30(%ebp)
f0100898:	68 4c 4b 10 f0       	push   $0xf0104b4c
f010089d:	e8 d6 26 00 00       	call   f0102f78 <cprintf>
			dbgi.eip_fn_name,((uintptr_t)eip - dbgi.eip_fn_addr));
	ebp = *(uint32_t *)(ebp);
f01008a2:	8b 1b                	mov    (%ebx),%ebx
f01008a4:	83 c4 20             	add    $0x20,%esp
int
mon_backtrace(int argc, char **argv, struct Trapframe *tf)
{
	uint32_t ebp = read_ebp();
	struct Eipdebuginfo dbgi;
	while (ebp != 0x0){
f01008a7:	85 db                	test   %ebx,%ebx
f01008a9:	75 b2                	jne    f010085d <mon_backtrace+0x10>
	cprintf("       %s:%d: %.*s+%d\n", dbgi.eip_file, dbgi.eip_line, dbgi.eip_fn_namelen, 
			dbgi.eip_fn_name,((uintptr_t)eip - dbgi.eip_fn_addr));
	ebp = *(uint32_t *)(ebp);
	}
	return 0;
}
f01008ab:	b8 00 00 00 00       	mov    $0x0,%eax
f01008b0:	8d 65 f4             	lea    -0xc(%ebp),%esp
f01008b3:	5b                   	pop    %ebx
f01008b4:	5e                   	pop    %esi
f01008b5:	5f                   	pop    %edi
f01008b6:	5d                   	pop    %ebp
f01008b7:	c3                   	ret    

f01008b8 <runcmd>:
#define WHITESPACE "\t\r\n "
#define MAXARGS 16

static int
runcmd(char *buf, struct Trapframe *tf)
{
f01008b8:	55                   	push   %ebp
f01008b9:	89 e5                	mov    %esp,%ebp
f01008bb:	57                   	push   %edi
f01008bc:	56                   	push   %esi
f01008bd:	53                   	push   %ebx
f01008be:	83 ec 5c             	sub    $0x5c,%esp
f01008c1:	89 c3                	mov    %eax,%ebx
f01008c3:	89 55 a4             	mov    %edx,-0x5c(%ebp)
	char *argv[MAXARGS];
	int i;

	// Parse the command buffer into whitespace-separated arguments
	argc = 0;
	argv[argc] = 0;
f01008c6:	c7 45 a8 00 00 00 00 	movl   $0x0,-0x58(%ebp)
	int argc;
	char *argv[MAXARGS];
	int i;

	// Parse the command buffer into whitespace-separated arguments
	argc = 0;
f01008cd:	be 00 00 00 00       	mov    $0x0,%esi
f01008d2:	eb 0a                	jmp    f01008de <runcmd+0x26>
	argv[argc] = 0;
	while (1) {
		// gobble whitespace
		while (*buf && strchr(WHITESPACE, *buf))
			*buf++ = 0;
f01008d4:	c6 03 00             	movb   $0x0,(%ebx)
f01008d7:	89 f7                	mov    %esi,%edi
f01008d9:	8d 5b 01             	lea    0x1(%ebx),%ebx
f01008dc:	89 fe                	mov    %edi,%esi
	// Parse the command buffer into whitespace-separated arguments
	argc = 0;
	argv[argc] = 0;
	while (1) {
		// gobble whitespace
		while (*buf && strchr(WHITESPACE, *buf))
f01008de:	0f b6 03             	movzbl (%ebx),%eax
f01008e1:	84 c0                	test   %al,%al
f01008e3:	74 6d                	je     f0100952 <runcmd+0x9a>
f01008e5:	83 ec 08             	sub    $0x8,%esp
f01008e8:	0f be c0             	movsbl %al,%eax
f01008eb:	50                   	push   %eax
f01008ec:	68 63 4b 10 f0       	push   $0xf0104b63
f01008f1:	e8 4c 3a 00 00       	call   f0104342 <strchr>
f01008f6:	83 c4 10             	add    $0x10,%esp
f01008f9:	85 c0                	test   %eax,%eax
f01008fb:	75 d7                	jne    f01008d4 <runcmd+0x1c>
			*buf++ = 0;
		if (*buf == 0)
f01008fd:	0f b6 03             	movzbl (%ebx),%eax
f0100900:	84 c0                	test   %al,%al
f0100902:	74 4e                	je     f0100952 <runcmd+0x9a>
			break;

		// save and scan past next arg
		if (argc == MAXARGS-1) {
f0100904:	83 fe 0f             	cmp    $0xf,%esi
f0100907:	75 1c                	jne    f0100925 <runcmd+0x6d>
			cprintf("Too many arguments (max %d)\n", MAXARGS);
f0100909:	83 ec 08             	sub    $0x8,%esp
f010090c:	6a 10                	push   $0x10
f010090e:	68 68 4b 10 f0       	push   $0xf0104b68
f0100913:	e8 60 26 00 00       	call   f0102f78 <cprintf>
			return 0;
f0100918:	83 c4 10             	add    $0x10,%esp
f010091b:	b8 00 00 00 00       	mov    $0x0,%eax
f0100920:	e9 99 00 00 00       	jmp    f01009be <runcmd+0x106>
		}
		argv[argc++] = buf;
f0100925:	8d 7e 01             	lea    0x1(%esi),%edi
f0100928:	89 5c b5 a8          	mov    %ebx,-0x58(%ebp,%esi,4)
f010092c:	eb 0a                	jmp    f0100938 <runcmd+0x80>
		while (*buf && !strchr(WHITESPACE, *buf))
			buf++;
f010092e:	83 c3 01             	add    $0x1,%ebx
		if (argc == MAXARGS-1) {
			cprintf("Too many arguments (max %d)\n", MAXARGS);
			return 0;
		}
		argv[argc++] = buf;
		while (*buf && !strchr(WHITESPACE, *buf))
f0100931:	0f b6 03             	movzbl (%ebx),%eax
f0100934:	84 c0                	test   %al,%al
f0100936:	74 a4                	je     f01008dc <runcmd+0x24>
f0100938:	83 ec 08             	sub    $0x8,%esp
f010093b:	0f be c0             	movsbl %al,%eax
f010093e:	50                   	push   %eax
f010093f:	68 63 4b 10 f0       	push   $0xf0104b63
f0100944:	e8 f9 39 00 00       	call   f0104342 <strchr>
f0100949:	83 c4 10             	add    $0x10,%esp
f010094c:	85 c0                	test   %eax,%eax
f010094e:	74 de                	je     f010092e <runcmd+0x76>
f0100950:	eb 8a                	jmp    f01008dc <runcmd+0x24>
			buf++;
	}
	argv[argc] = 0;
f0100952:	c7 44 b5 a8 00 00 00 	movl   $0x0,-0x58(%ebp,%esi,4)
f0100959:	00 

	// Lookup and invoke the command
	if (argc == 0)
		return 0;
f010095a:	b8 00 00 00 00       	mov    $0x0,%eax
			buf++;
	}
	argv[argc] = 0;

	// Lookup and invoke the command
	if (argc == 0)
f010095f:	85 f6                	test   %esi,%esi
f0100961:	74 5b                	je     f01009be <runcmd+0x106>
f0100963:	bb 00 00 00 00       	mov    $0x0,%ebx
		return 0;
	for (i = 0; i < ARRAY_SIZE(commands); i++) {
		if (strcmp(argv[0], commands[i].name) == 0)
f0100968:	83 ec 08             	sub    $0x8,%esp
f010096b:	8d 04 5b             	lea    (%ebx,%ebx,2),%eax
f010096e:	ff 34 85 40 4d 10 f0 	pushl  -0xfefb2c0(,%eax,4)
f0100975:	ff 75 a8             	pushl  -0x58(%ebp)
f0100978:	e8 67 39 00 00       	call   f01042e4 <strcmp>
f010097d:	83 c4 10             	add    $0x10,%esp
f0100980:	85 c0                	test   %eax,%eax
f0100982:	75 1a                	jne    f010099e <runcmd+0xe6>
			return commands[i].func(argc, argv, tf);
f0100984:	83 ec 04             	sub    $0x4,%esp
f0100987:	8d 04 5b             	lea    (%ebx,%ebx,2),%eax
f010098a:	ff 75 a4             	pushl  -0x5c(%ebp)
f010098d:	8d 55 a8             	lea    -0x58(%ebp),%edx
f0100990:	52                   	push   %edx
f0100991:	56                   	push   %esi
f0100992:	ff 14 85 48 4d 10 f0 	call   *-0xfefb2b8(,%eax,4)
f0100999:	83 c4 10             	add    $0x10,%esp
f010099c:	eb 20                	jmp    f01009be <runcmd+0x106>
	argv[argc] = 0;

	// Lookup and invoke the command
	if (argc == 0)
		return 0;
	for (i = 0; i < ARRAY_SIZE(commands); i++) {
f010099e:	83 c3 01             	add    $0x1,%ebx
f01009a1:	83 fb 03             	cmp    $0x3,%ebx
f01009a4:	75 c2                	jne    f0100968 <runcmd+0xb0>
		if (strcmp(argv[0], commands[i].name) == 0)
			return commands[i].func(argc, argv, tf);
	}
	cprintf("Unknown command '%s'\n", argv[0]);
f01009a6:	83 ec 08             	sub    $0x8,%esp
f01009a9:	ff 75 a8             	pushl  -0x58(%ebp)
f01009ac:	68 85 4b 10 f0       	push   $0xf0104b85
f01009b1:	e8 c2 25 00 00       	call   f0102f78 <cprintf>
	return 0;
f01009b6:	83 c4 10             	add    $0x10,%esp
f01009b9:	b8 00 00 00 00       	mov    $0x0,%eax
}
f01009be:	8d 65 f4             	lea    -0xc(%ebp),%esp
f01009c1:	5b                   	pop    %ebx
f01009c2:	5e                   	pop    %esi
f01009c3:	5f                   	pop    %edi
f01009c4:	5d                   	pop    %ebp
f01009c5:	c3                   	ret    

f01009c6 <monitor>:

void
monitor(struct Trapframe *tf)
{
f01009c6:	55                   	push   %ebp
f01009c7:	89 e5                	mov    %esp,%ebp
f01009c9:	53                   	push   %ebx
f01009ca:	83 ec 10             	sub    $0x10,%esp
f01009cd:	8b 5d 08             	mov    0x8(%ebp),%ebx
	char *buf;

	cprintf("Welcome to the JOS kernel monitor!\n");
f01009d0:	68 e0 4c 10 f0       	push   $0xf0104ce0
f01009d5:	e8 9e 25 00 00       	call   f0102f78 <cprintf>
	cprintf("Type 'help' for a list of commands.\n");
f01009da:	c7 04 24 04 4d 10 f0 	movl   $0xf0104d04,(%esp)
f01009e1:	e8 92 25 00 00       	call   f0102f78 <cprintf>

	if (tf != NULL)
f01009e6:	83 c4 10             	add    $0x10,%esp
f01009e9:	85 db                	test   %ebx,%ebx
f01009eb:	74 0c                	je     f01009f9 <monitor+0x33>
		print_trapframe(tf);
f01009ed:	83 ec 0c             	sub    $0xc,%esp
f01009f0:	53                   	push   %ebx
f01009f1:	e8 1e 2a 00 00       	call   f0103414 <print_trapframe>
f01009f6:	83 c4 10             	add    $0x10,%esp

	while (1) {
		buf = readline("K> ");
f01009f9:	83 ec 0c             	sub    $0xc,%esp
f01009fc:	68 9b 4b 10 f0       	push   $0xf0104b9b
f0100a01:	e8 22 37 00 00       	call   f0104128 <readline>
		if (buf != NULL)
f0100a06:	83 c4 10             	add    $0x10,%esp
f0100a09:	85 c0                	test   %eax,%eax
f0100a0b:	74 ec                	je     f01009f9 <monitor+0x33>
			if (runcmd(buf, tf) < 0)
f0100a0d:	89 da                	mov    %ebx,%edx
f0100a0f:	e8 a4 fe ff ff       	call   f01008b8 <runcmd>
f0100a14:	85 c0                	test   %eax,%eax
f0100a16:	79 e1                	jns    f01009f9 <monitor+0x33>
				break;
	}
}
f0100a18:	8b 5d fc             	mov    -0x4(%ebp),%ebx
f0100a1b:	c9                   	leave  
f0100a1c:	c3                   	ret    

f0100a1d <invlpg>:
	asm volatile("outl %0,%w1" : : "a" (data), "d" (port));
}

static inline void
invlpg(void *addr)
{
f0100a1d:	55                   	push   %ebp
f0100a1e:	89 e5                	mov    %esp,%ebp
	asm volatile("invlpg (%0)" : : "r" (addr) : "memory");
f0100a20:	0f 01 38             	invlpg (%eax)
}
f0100a23:	5d                   	pop    %ebp
f0100a24:	c3                   	ret    

f0100a25 <lcr0>:
	asm volatile("ltr %0" : : "r" (sel));
}

static inline void
lcr0(uint32_t val)
{
f0100a25:	55                   	push   %ebp
f0100a26:	89 e5                	mov    %esp,%ebp
	asm volatile("movl %0,%%cr0" : : "r" (val));
f0100a28:	0f 22 c0             	mov    %eax,%cr0
}
f0100a2b:	5d                   	pop    %ebp
f0100a2c:	c3                   	ret    

f0100a2d <rcr0>:

static inline uint32_t
rcr0(void)
{
f0100a2d:	55                   	push   %ebp
f0100a2e:	89 e5                	mov    %esp,%ebp
	uint32_t val;
	asm volatile("movl %%cr0,%0" : "=r" (val));
f0100a30:	0f 20 c0             	mov    %cr0,%eax
	return val;
}
f0100a33:	5d                   	pop    %ebp
f0100a34:	c3                   	ret    

f0100a35 <lcr3>:
	return val;
}

static inline void
lcr3(uint32_t val)
{
f0100a35:	55                   	push   %ebp
f0100a36:	89 e5                	mov    %esp,%ebp
	asm volatile("movl %0,%%cr3" : : "r" (val));
f0100a38:	0f 22 d8             	mov    %eax,%cr3
}
f0100a3b:	5d                   	pop    %ebp
f0100a3c:	c3                   	ret    

f0100a3d <page2pa>:
int	user_mem_check(struct Env *env, const void *va, size_t len, int perm);
void	user_mem_assert(struct Env *env, const void *va, size_t len, int perm);

static inline physaddr_t
page2pa(struct PageInfo *pp)
{
f0100a3d:	55                   	push   %ebp
f0100a3e:	89 e5                	mov    %esp,%ebp
	return (pp - pages) << PGSHIFT;
f0100a40:	2b 05 8c 59 19 f0    	sub    0xf019598c,%eax
f0100a46:	c1 f8 03             	sar    $0x3,%eax
f0100a49:	c1 e0 0c             	shl    $0xc,%eax
}
f0100a4c:	5d                   	pop    %ebp
f0100a4d:	c3                   	ret    

f0100a4e <nvram_read>:
// Detect machine's physical memory setup.
// --------------------------------------------------------------

static int
nvram_read(int r)
{
f0100a4e:	55                   	push   %ebp
f0100a4f:	89 e5                	mov    %esp,%ebp
f0100a51:	56                   	push   %esi
f0100a52:	53                   	push   %ebx
f0100a53:	89 c3                	mov    %eax,%ebx
	return mc146818_read(r) | (mc146818_read(r + 1) << 8);
f0100a55:	83 ec 0c             	sub    $0xc,%esp
f0100a58:	50                   	push   %eax
f0100a59:	e8 a0 24 00 00       	call   f0102efe <mc146818_read>
f0100a5e:	89 c6                	mov    %eax,%esi
f0100a60:	83 c3 01             	add    $0x1,%ebx
f0100a63:	89 1c 24             	mov    %ebx,(%esp)
f0100a66:	e8 93 24 00 00       	call   f0102efe <mc146818_read>
f0100a6b:	c1 e0 08             	shl    $0x8,%eax
f0100a6e:	09 f0                	or     %esi,%eax
}
f0100a70:	8d 65 f8             	lea    -0x8(%ebp),%esp
f0100a73:	5b                   	pop    %ebx
f0100a74:	5e                   	pop    %esi
f0100a75:	5d                   	pop    %ebp
f0100a76:	c3                   	ret    

f0100a77 <i386_detect_memory>:

static void
i386_detect_memory(void)
{
f0100a77:	55                   	push   %ebp
f0100a78:	89 e5                	mov    %esp,%ebp
f0100a7a:	56                   	push   %esi
f0100a7b:	53                   	push   %ebx
	size_t basemem, extmem, ext16mem, totalmem;

	// Use CMOS calls to measure available base & extended memory.
	// (CMOS calls return results in kilobytes.)
	basemem = nvram_read(NVRAM_BASELO);
f0100a7c:	b8 15 00 00 00       	mov    $0x15,%eax
f0100a81:	e8 c8 ff ff ff       	call   f0100a4e <nvram_read>
f0100a86:	89 c3                	mov    %eax,%ebx
	extmem = nvram_read(NVRAM_EXTLO);
f0100a88:	b8 17 00 00 00       	mov    $0x17,%eax
f0100a8d:	e8 bc ff ff ff       	call   f0100a4e <nvram_read>
f0100a92:	89 c6                	mov    %eax,%esi
	ext16mem = nvram_read(NVRAM_EXT16LO) * 64;
f0100a94:	b8 34 00 00 00       	mov    $0x34,%eax
f0100a99:	e8 b0 ff ff ff       	call   f0100a4e <nvram_read>
f0100a9e:	c1 e0 06             	shl    $0x6,%eax

	// Calculate the number of physical pages available in both base
	// and extended memory.
	if (ext16mem)
f0100aa1:	85 c0                	test   %eax,%eax
f0100aa3:	74 07                	je     f0100aac <i386_detect_memory+0x35>
		totalmem = 16 * 1024 + ext16mem;
f0100aa5:	05 00 40 00 00       	add    $0x4000,%eax
f0100aaa:	eb 0b                	jmp    f0100ab7 <i386_detect_memory+0x40>
	else if (extmem)
		totalmem = 1 * 1024 + extmem;
f0100aac:	8d 86 00 04 00 00    	lea    0x400(%esi),%eax
f0100ab2:	85 f6                	test   %esi,%esi
f0100ab4:	0f 44 c3             	cmove  %ebx,%eax
	else
		totalmem = basemem;

	npages = totalmem / (PGSIZE / 1024);
f0100ab7:	89 c2                	mov    %eax,%edx
f0100ab9:	c1 ea 02             	shr    $0x2,%edx
f0100abc:	89 15 84 59 19 f0    	mov    %edx,0xf0195984
	npages_basemem = basemem / (PGSIZE / 1024);

	cprintf("Physical memory: %uK available, base = %uK, extended = %uK\n",
f0100ac2:	89 c2                	mov    %eax,%edx
f0100ac4:	29 da                	sub    %ebx,%edx
f0100ac6:	52                   	push   %edx
f0100ac7:	53                   	push   %ebx
f0100ac8:	50                   	push   %eax
f0100ac9:	68 64 4d 10 f0       	push   $0xf0104d64
f0100ace:	e8 a5 24 00 00       	call   f0102f78 <cprintf>
		totalmem, basemem, totalmem - basemem);
}
f0100ad3:	83 c4 10             	add    $0x10,%esp
f0100ad6:	8d 65 f8             	lea    -0x8(%ebp),%esp
f0100ad9:	5b                   	pop    %ebx
f0100ada:	5e                   	pop    %esi
f0100adb:	5d                   	pop    %ebp
f0100adc:	c3                   	ret    

f0100add <_kaddr>:
 * virtual address.  It panics if you pass an invalid physical address. */
#define KADDR(pa) _kaddr(__FILE__, __LINE__, pa)

static inline void*
_kaddr(const char *file, int line, physaddr_t pa)
{
f0100add:	55                   	push   %ebp
f0100ade:	89 e5                	mov    %esp,%ebp
f0100ae0:	53                   	push   %ebx
f0100ae1:	83 ec 04             	sub    $0x4,%esp
	if (PGNUM(pa) >= npages)
f0100ae4:	89 cb                	mov    %ecx,%ebx
f0100ae6:	c1 eb 0c             	shr    $0xc,%ebx
f0100ae9:	3b 1d 84 59 19 f0    	cmp    0xf0195984,%ebx
f0100aef:	72 0d                	jb     f0100afe <_kaddr+0x21>
		_panic(file, line, "KADDR called with invalid pa %08lx", pa);
f0100af1:	51                   	push   %ecx
f0100af2:	68 a0 4d 10 f0       	push   $0xf0104da0
f0100af7:	52                   	push   %edx
f0100af8:	50                   	push   %eax
f0100af9:	e8 ab f5 ff ff       	call   f01000a9 <_panic>
	return (void *)(pa + KERNBASE);
f0100afe:	8d 81 00 00 00 f0    	lea    -0x10000000(%ecx),%eax
}
f0100b04:	8b 5d fc             	mov    -0x4(%ebp),%ebx
f0100b07:	c9                   	leave  
f0100b08:	c3                   	ret    

f0100b09 <page2kva>:
	return &pages[PGNUM(pa)];
}

static inline void*
page2kva(struct PageInfo *pp)
{
f0100b09:	55                   	push   %ebp
f0100b0a:	89 e5                	mov    %esp,%ebp
f0100b0c:	83 ec 08             	sub    $0x8,%esp
	return KADDR(page2pa(pp));
f0100b0f:	e8 29 ff ff ff       	call   f0100a3d <page2pa>
f0100b14:	89 c1                	mov    %eax,%ecx
f0100b16:	ba 56 00 00 00       	mov    $0x56,%edx
f0100b1b:	b8 4d 55 10 f0       	mov    $0xf010554d,%eax
f0100b20:	e8 b8 ff ff ff       	call   f0100add <_kaddr>
}
f0100b25:	c9                   	leave  
f0100b26:	c3                   	ret    

f0100b27 <check_va2pa>:
check_va2pa(pde_t *pgdir, uintptr_t va)
{
	pte_t *p;

	pgdir = &pgdir[PDX(va)];
	if (!(*pgdir & PTE_P))
f0100b27:	89 d1                	mov    %edx,%ecx
f0100b29:	c1 e9 16             	shr    $0x16,%ecx
f0100b2c:	8b 0c 88             	mov    (%eax,%ecx,4),%ecx
f0100b2f:	f6 c1 01             	test   $0x1,%cl
f0100b32:	74 57                	je     f0100b8b <check_va2pa+0x64>
		return ~0;
	if (*pgdir & PTE_PS)
f0100b34:	f6 c1 80             	test   $0x80,%cl
f0100b37:	74 10                	je     f0100b49 <check_va2pa+0x22>
		return (physaddr_t) PGADDR(PDX(*pgdir), PTX(va), PGOFF(va));
f0100b39:	89 d0                	mov    %edx,%eax
f0100b3b:	25 ff ff 3f 00       	and    $0x3fffff,%eax
f0100b40:	81 e1 00 00 c0 ff    	and    $0xffc00000,%ecx
f0100b46:	09 c8                	or     %ecx,%eax
f0100b48:	c3                   	ret    
// this functionality for us!  We define our own version to help check
// the check_kern_pgdir() function; it shouldn't be used elsewhere.

static physaddr_t
check_va2pa(pde_t *pgdir, uintptr_t va)
{
f0100b49:	55                   	push   %ebp
f0100b4a:	89 e5                	mov    %esp,%ebp
f0100b4c:	53                   	push   %ebx
f0100b4d:	83 ec 04             	sub    $0x4,%esp
f0100b50:	89 d3                	mov    %edx,%ebx
	pgdir = &pgdir[PDX(va)];
	if (!(*pgdir & PTE_P))
		return ~0;
	if (*pgdir & PTE_PS)
		return (physaddr_t) PGADDR(PDX(*pgdir), PTX(va), PGOFF(va));
	p = (pte_t*) KADDR(PTE_ADDR(*pgdir));
f0100b52:	81 e1 00 f0 ff ff    	and    $0xfffff000,%ecx
f0100b58:	ba 32 03 00 00       	mov    $0x332,%edx
f0100b5d:	b8 5b 55 10 f0       	mov    $0xf010555b,%eax
f0100b62:	e8 76 ff ff ff       	call   f0100add <_kaddr>
	if (!(p[PTX(va)] & PTE_P))
f0100b67:	c1 eb 0c             	shr    $0xc,%ebx
f0100b6a:	89 da                	mov    %ebx,%edx
f0100b6c:	81 e2 ff 03 00 00    	and    $0x3ff,%edx
f0100b72:	8b 04 90             	mov    (%eax,%edx,4),%eax
f0100b75:	89 c2                	mov    %eax,%edx
f0100b77:	83 e2 01             	and    $0x1,%edx
		return ~0;
	return PTE_ADDR(p[PTX(va)]);
f0100b7a:	25 00 f0 ff ff       	and    $0xfffff000,%eax
f0100b7f:	85 d2                	test   %edx,%edx
f0100b81:	b9 ff ff ff ff       	mov    $0xffffffff,%ecx
f0100b86:	0f 44 c1             	cmove  %ecx,%eax
f0100b89:	eb 06                	jmp    f0100b91 <check_va2pa+0x6a>
{
	pte_t *p;

	pgdir = &pgdir[PDX(va)];
	if (!(*pgdir & PTE_P))
		return ~0;
f0100b8b:	b8 ff ff ff ff       	mov    $0xffffffff,%eax
f0100b90:	c3                   	ret    
		return (physaddr_t) PGADDR(PDX(*pgdir), PTX(va), PGOFF(va));
	p = (pte_t*) KADDR(PTE_ADDR(*pgdir));
	if (!(p[PTX(va)] & PTE_P))
		return ~0;
	return PTE_ADDR(p[PTX(va)]);
}
f0100b91:	83 c4 04             	add    $0x4,%esp
f0100b94:	5b                   	pop    %ebx
f0100b95:	5d                   	pop    %ebp
f0100b96:	c3                   	ret    

f0100b97 <_paddr>:
#define PADDR(kva) _paddr(__FILE__, __LINE__, kva)

static inline physaddr_t
_paddr(const char *file, int line, void *kva)
{
	if ((uint32_t)kva < KERNBASE)
f0100b97:	81 f9 ff ff ff ef    	cmp    $0xefffffff,%ecx
f0100b9d:	77 13                	ja     f0100bb2 <_paddr+0x1b>
 */
#define PADDR(kva) _paddr(__FILE__, __LINE__, kva)

static inline physaddr_t
_paddr(const char *file, int line, void *kva)
{
f0100b9f:	55                   	push   %ebp
f0100ba0:	89 e5                	mov    %esp,%ebp
f0100ba2:	83 ec 08             	sub    $0x8,%esp
	if ((uint32_t)kva < KERNBASE)
		_panic(file, line, "PADDR called with invalid kva %08lx", kva);
f0100ba5:	51                   	push   %ecx
f0100ba6:	68 c4 4d 10 f0       	push   $0xf0104dc4
f0100bab:	52                   	push   %edx
f0100bac:	50                   	push   %eax
f0100bad:	e8 f7 f4 ff ff       	call   f01000a9 <_panic>
	return (physaddr_t)kva - KERNBASE;
f0100bb2:	8d 81 00 00 00 10    	lea    0x10000000(%ecx),%eax
}
f0100bb8:	c3                   	ret    

f0100bb9 <boot_alloc>:
	// Initialize nextfree if this is the first time.
	// 'end' is a magic symbol automatically generated by the linker,
	// which points to the end of the kernel's bss segment:
	// the first virtual address that the linker did *not* assign
	// to any kernel code or global variables.
	if (!nextfree) {
f0100bb9:	83 3d b8 3c 19 f0 00 	cmpl   $0x0,0xf0193cb8
f0100bc0:	75 11                	jne    f0100bd3 <boot_alloc+0x1a>
		extern char end[];
		nextfree = ROUNDUP((char *) end, PGSIZE);
f0100bc2:	ba 8f 69 19 f0       	mov    $0xf019698f,%edx
f0100bc7:	81 e2 00 f0 ff ff    	and    $0xfffff000,%edx
f0100bcd:	89 15 b8 3c 19 f0    	mov    %edx,0xf0193cb8
	// Allocate a chunk large enough to hold 'n' bytes, then update
	// nextfree.  Make sure nextfree is kept aligned
	// to a multiple of PGSIZE.
	//
	// LAB 2: Your code here.
	if (n==0) return nextfree;
f0100bd3:	85 c0                	test   %eax,%eax
f0100bd5:	75 06                	jne    f0100bdd <boot_alloc+0x24>
f0100bd7:	a1 b8 3c 19 f0       	mov    0xf0193cb8,%eax
	//n>0 (n<0 no deberia ocurrir por precond)
	result = nextfree;
	nextfree += ROUNDUP(n,PGSIZE);
	if (PADDR(nextfree)>npages*PGSIZE) panic("not enough memory\n");
	return (void*) result;
}
f0100bdc:	c3                   	ret    
// If we're out of memory, boot_alloc should panic.
// This function may ONLY be used during initialization,
// before the page_free_list list has been set up.
static void *
boot_alloc(uint32_t n)
{
f0100bdd:	55                   	push   %ebp
f0100bde:	89 e5                	mov    %esp,%ebp
f0100be0:	53                   	push   %ebx
f0100be1:	83 ec 04             	sub    $0x4,%esp
	// to a multiple of PGSIZE.
	//
	// LAB 2: Your code here.
	if (n==0) return nextfree;
	//n>0 (n<0 no deberia ocurrir por precond)
	result = nextfree;
f0100be4:	8b 1d b8 3c 19 f0    	mov    0xf0193cb8,%ebx
	nextfree += ROUNDUP(n,PGSIZE);
f0100bea:	8d 88 ff 0f 00 00    	lea    0xfff(%eax),%ecx
f0100bf0:	81 e1 00 f0 ff ff    	and    $0xfffff000,%ecx
f0100bf6:	01 d9                	add    %ebx,%ecx
f0100bf8:	89 0d b8 3c 19 f0    	mov    %ecx,0xf0193cb8
	if (PADDR(nextfree)>npages*PGSIZE) panic("not enough memory\n");
f0100bfe:	ba 6e 00 00 00       	mov    $0x6e,%edx
f0100c03:	b8 5b 55 10 f0       	mov    $0xf010555b,%eax
f0100c08:	e8 8a ff ff ff       	call   f0100b97 <_paddr>
f0100c0d:	8b 15 84 59 19 f0    	mov    0xf0195984,%edx
f0100c13:	c1 e2 0c             	shl    $0xc,%edx
f0100c16:	39 d0                	cmp    %edx,%eax
f0100c18:	76 14                	jbe    f0100c2e <boot_alloc+0x75>
f0100c1a:	83 ec 04             	sub    $0x4,%esp
f0100c1d:	68 67 55 10 f0       	push   $0xf0105567
f0100c22:	6a 6e                	push   $0x6e
f0100c24:	68 5b 55 10 f0       	push   $0xf010555b
f0100c29:	e8 7b f4 ff ff       	call   f01000a9 <_panic>
	return (void*) result;
f0100c2e:	89 d8                	mov    %ebx,%eax
}
f0100c30:	8b 5d fc             	mov    -0x4(%ebp),%ebx
f0100c33:	c9                   	leave  
f0100c34:	c3                   	ret    

f0100c35 <check_kern_pgdir>:
// but it is a pretty good sanity check.
//

static void
check_kern_pgdir(void)
{
f0100c35:	55                   	push   %ebp
f0100c36:	89 e5                	mov    %esp,%ebp
f0100c38:	57                   	push   %edi
f0100c39:	56                   	push   %esi
f0100c3a:	53                   	push   %ebx
f0100c3b:	83 ec 1c             	sub    $0x1c,%esp
	uint32_t i, n;
	pde_t *pgdir;

	pgdir = kern_pgdir;
f0100c3e:	8b 1d 88 59 19 f0    	mov    0xf0195988,%ebx

	// check pages array
	n = ROUNDUP(npages*sizeof(struct PageInfo), PGSIZE);
f0100c44:	a1 84 59 19 f0       	mov    0xf0195984,%eax
f0100c49:	89 45 dc             	mov    %eax,-0x24(%ebp)
f0100c4c:	8d 04 c5 ff 0f 00 00 	lea    0xfff(,%eax,8),%eax
f0100c53:	25 00 f0 ff ff       	and    $0xfffff000,%eax
f0100c58:	89 45 e4             	mov    %eax,-0x1c(%ebp)
	for (i = 0; i < n; i += PGSIZE)
		assert(check_va2pa(pgdir, UPAGES + i) == PADDR(pages) + i);
f0100c5b:	a1 8c 59 19 f0       	mov    0xf019598c,%eax
f0100c60:	89 45 e0             	mov    %eax,-0x20(%ebp)

	pgdir = kern_pgdir;

	// check pages array
	n = ROUNDUP(npages*sizeof(struct PageInfo), PGSIZE);
	for (i = 0; i < n; i += PGSIZE)
f0100c63:	be 00 00 00 00       	mov    $0x0,%esi
f0100c68:	eb 46                	jmp    f0100cb0 <check_kern_pgdir+0x7b>
		assert(check_va2pa(pgdir, UPAGES + i) == PADDR(pages) + i);
f0100c6a:	8d 96 00 00 00 ef    	lea    -0x11000000(%esi),%edx
f0100c70:	89 d8                	mov    %ebx,%eax
f0100c72:	e8 b0 fe ff ff       	call   f0100b27 <check_va2pa>
f0100c77:	89 c7                	mov    %eax,%edi
f0100c79:	8b 4d e0             	mov    -0x20(%ebp),%ecx
f0100c7c:	ba f4 02 00 00       	mov    $0x2f4,%edx
f0100c81:	b8 5b 55 10 f0       	mov    $0xf010555b,%eax
f0100c86:	e8 0c ff ff ff       	call   f0100b97 <_paddr>
f0100c8b:	01 f0                	add    %esi,%eax
f0100c8d:	39 c7                	cmp    %eax,%edi
f0100c8f:	74 19                	je     f0100caa <check_kern_pgdir+0x75>
f0100c91:	68 e8 4d 10 f0       	push   $0xf0104de8
f0100c96:	68 7a 55 10 f0       	push   $0xf010557a
f0100c9b:	68 f4 02 00 00       	push   $0x2f4
f0100ca0:	68 5b 55 10 f0       	push   $0xf010555b
f0100ca5:	e8 ff f3 ff ff       	call   f01000a9 <_panic>

	pgdir = kern_pgdir;

	// check pages array
	n = ROUNDUP(npages*sizeof(struct PageInfo), PGSIZE);
	for (i = 0; i < n; i += PGSIZE)
f0100caa:	81 c6 00 10 00 00    	add    $0x1000,%esi
f0100cb0:	3b 75 e4             	cmp    -0x1c(%ebp),%esi
f0100cb3:	72 b5                	jb     f0100c6a <check_kern_pgdir+0x35>
		assert(check_va2pa(pgdir, UPAGES + i) == PADDR(pages) + i);

	// check envs array (new test for lab 3)
	n = ROUNDUP(NENV*sizeof(struct Env), PGSIZE);
	for (i = 0; i < n; i += PGSIZE)
		assert(check_va2pa(pgdir, UENVS + i) == PADDR(envs) + i);
f0100cb5:	a1 c8 3c 19 f0       	mov    0xf0193cc8,%eax
f0100cba:	89 45 e4             	mov    %eax,-0x1c(%ebp)
f0100cbd:	be 00 00 00 00       	mov    $0x0,%esi
f0100cc2:	8d 96 00 00 c0 ee    	lea    -0x11400000(%esi),%edx
f0100cc8:	89 d8                	mov    %ebx,%eax
f0100cca:	e8 58 fe ff ff       	call   f0100b27 <check_va2pa>
f0100ccf:	89 c7                	mov    %eax,%edi
f0100cd1:	8b 4d e4             	mov    -0x1c(%ebp),%ecx
f0100cd4:	ba f9 02 00 00       	mov    $0x2f9,%edx
f0100cd9:	b8 5b 55 10 f0       	mov    $0xf010555b,%eax
f0100cde:	e8 b4 fe ff ff       	call   f0100b97 <_paddr>
f0100ce3:	01 f0                	add    %esi,%eax
f0100ce5:	39 c7                	cmp    %eax,%edi
f0100ce7:	74 19                	je     f0100d02 <check_kern_pgdir+0xcd>
f0100ce9:	68 1c 4e 10 f0       	push   $0xf0104e1c
f0100cee:	68 7a 55 10 f0       	push   $0xf010557a
f0100cf3:	68 f9 02 00 00       	push   $0x2f9
f0100cf8:	68 5b 55 10 f0       	push   $0xf010555b
f0100cfd:	e8 a7 f3 ff ff       	call   f01000a9 <_panic>
	for (i = 0; i < n; i += PGSIZE)
		assert(check_va2pa(pgdir, UPAGES + i) == PADDR(pages) + i);

	// check envs array (new test for lab 3)
	n = ROUNDUP(NENV*sizeof(struct Env), PGSIZE);
	for (i = 0; i < n; i += PGSIZE)
f0100d02:	81 c6 00 10 00 00    	add    $0x1000,%esi
f0100d08:	81 fe 00 80 01 00    	cmp    $0x18000,%esi
f0100d0e:	75 b2                	jne    f0100cc2 <check_kern_pgdir+0x8d>
		assert(check_va2pa(pgdir, UENVS + i) == PADDR(envs) + i);

	// check phys mem
	for (i = 0; i < npages * PGSIZE; i += PGSIZE)
f0100d10:	8b 7d dc             	mov    -0x24(%ebp),%edi
f0100d13:	c1 e7 0c             	shl    $0xc,%edi
f0100d16:	be 00 00 00 00       	mov    $0x0,%esi
f0100d1b:	eb 30                	jmp    f0100d4d <check_kern_pgdir+0x118>
		assert(check_va2pa(pgdir, KERNBASE + i) == i);
f0100d1d:	8d 96 00 00 00 f0    	lea    -0x10000000(%esi),%edx
f0100d23:	89 d8                	mov    %ebx,%eax
f0100d25:	e8 fd fd ff ff       	call   f0100b27 <check_va2pa>
f0100d2a:	39 c6                	cmp    %eax,%esi
f0100d2c:	74 19                	je     f0100d47 <check_kern_pgdir+0x112>
f0100d2e:	68 50 4e 10 f0       	push   $0xf0104e50
f0100d33:	68 7a 55 10 f0       	push   $0xf010557a
f0100d38:	68 fd 02 00 00       	push   $0x2fd
f0100d3d:	68 5b 55 10 f0       	push   $0xf010555b
f0100d42:	e8 62 f3 ff ff       	call   f01000a9 <_panic>
	n = ROUNDUP(NENV*sizeof(struct Env), PGSIZE);
	for (i = 0; i < n; i += PGSIZE)
		assert(check_va2pa(pgdir, UENVS + i) == PADDR(envs) + i);

	// check phys mem
	for (i = 0; i < npages * PGSIZE; i += PGSIZE)
f0100d47:	81 c6 00 10 00 00    	add    $0x1000,%esi
f0100d4d:	39 fe                	cmp    %edi,%esi
f0100d4f:	72 cc                	jb     f0100d1d <check_kern_pgdir+0xe8>
f0100d51:	be 00 00 00 00       	mov    $0x0,%esi
		assert(check_va2pa(pgdir, KERNBASE + i) == i);

	// check kernel stack
	for (i = 0; i < KSTKSIZE; i += PGSIZE)
		assert(check_va2pa(pgdir, KSTACKTOP - KSTKSIZE + i) == PADDR(bootstack) + i);
f0100d56:	8d 96 00 80 ff ef    	lea    -0x10008000(%esi),%edx
f0100d5c:	89 d8                	mov    %ebx,%eax
f0100d5e:	e8 c4 fd ff ff       	call   f0100b27 <check_va2pa>
f0100d63:	89 c7                	mov    %eax,%edi
f0100d65:	b9 00 70 10 f0       	mov    $0xf0107000,%ecx
f0100d6a:	ba 01 03 00 00       	mov    $0x301,%edx
f0100d6f:	b8 5b 55 10 f0       	mov    $0xf010555b,%eax
f0100d74:	e8 1e fe ff ff       	call   f0100b97 <_paddr>
f0100d79:	01 f0                	add    %esi,%eax
f0100d7b:	39 c7                	cmp    %eax,%edi
f0100d7d:	74 19                	je     f0100d98 <check_kern_pgdir+0x163>
f0100d7f:	68 78 4e 10 f0       	push   $0xf0104e78
f0100d84:	68 7a 55 10 f0       	push   $0xf010557a
f0100d89:	68 01 03 00 00       	push   $0x301
f0100d8e:	68 5b 55 10 f0       	push   $0xf010555b
f0100d93:	e8 11 f3 ff ff       	call   f01000a9 <_panic>
	// check phys mem
	for (i = 0; i < npages * PGSIZE; i += PGSIZE)
		assert(check_va2pa(pgdir, KERNBASE + i) == i);

	// check kernel stack
	for (i = 0; i < KSTKSIZE; i += PGSIZE)
f0100d98:	81 c6 00 10 00 00    	add    $0x1000,%esi
f0100d9e:	81 fe 00 80 00 00    	cmp    $0x8000,%esi
f0100da4:	75 b0                	jne    f0100d56 <check_kern_pgdir+0x121>
		assert(check_va2pa(pgdir, KSTACKTOP - KSTKSIZE + i) == PADDR(bootstack) + i);
	assert(check_va2pa(pgdir, KSTACKTOP - PTSIZE) == ~0);
f0100da6:	ba 00 00 c0 ef       	mov    $0xefc00000,%edx
f0100dab:	89 d8                	mov    %ebx,%eax
f0100dad:	e8 75 fd ff ff       	call   f0100b27 <check_va2pa>
f0100db2:	83 f8 ff             	cmp    $0xffffffff,%eax
f0100db5:	74 51                	je     f0100e08 <check_kern_pgdir+0x1d3>
f0100db7:	68 c0 4e 10 f0       	push   $0xf0104ec0
f0100dbc:	68 7a 55 10 f0       	push   $0xf010557a
f0100dc1:	68 02 03 00 00       	push   $0x302
f0100dc6:	68 5b 55 10 f0       	push   $0xf010555b
f0100dcb:	e8 d9 f2 ff ff       	call   f01000a9 <_panic>

	// check PDE permissions
	for (i = 0; i < NPDENTRIES; i++) {
		switch (i) {
f0100dd0:	3d bb 03 00 00       	cmp    $0x3bb,%eax
f0100dd5:	72 36                	jb     f0100e0d <check_kern_pgdir+0x1d8>
f0100dd7:	3d bd 03 00 00       	cmp    $0x3bd,%eax
f0100ddc:	76 07                	jbe    f0100de5 <check_kern_pgdir+0x1b0>
f0100dde:	3d bf 03 00 00       	cmp    $0x3bf,%eax
f0100de3:	75 28                	jne    f0100e0d <check_kern_pgdir+0x1d8>
		case PDX(UVPT):
		case PDX(KSTACKTOP-1):
		case PDX(UPAGES):
		case PDX(UENVS):
			assert(pgdir[i] & PTE_P);
f0100de5:	f6 04 83 01          	testb  $0x1,(%ebx,%eax,4)
f0100de9:	0f 85 83 00 00 00    	jne    f0100e72 <check_kern_pgdir+0x23d>
f0100def:	68 8f 55 10 f0       	push   $0xf010558f
f0100df4:	68 7a 55 10 f0       	push   $0xf010557a
f0100df9:	68 0b 03 00 00       	push   $0x30b
f0100dfe:	68 5b 55 10 f0       	push   $0xf010555b
f0100e03:	e8 a1 f2 ff ff       	call   f01000a9 <_panic>
f0100e08:	b8 00 00 00 00       	mov    $0x0,%eax
			break;
		default:
			if (i >= PDX(KERNBASE)) {
f0100e0d:	3d bf 03 00 00       	cmp    $0x3bf,%eax
f0100e12:	76 3f                	jbe    f0100e53 <check_kern_pgdir+0x21e>
				assert(pgdir[i] & PTE_P);
f0100e14:	8b 14 83             	mov    (%ebx,%eax,4),%edx
f0100e17:	f6 c2 01             	test   $0x1,%dl
f0100e1a:	75 19                	jne    f0100e35 <check_kern_pgdir+0x200>
f0100e1c:	68 8f 55 10 f0       	push   $0xf010558f
f0100e21:	68 7a 55 10 f0       	push   $0xf010557a
f0100e26:	68 0f 03 00 00       	push   $0x30f
f0100e2b:	68 5b 55 10 f0       	push   $0xf010555b
f0100e30:	e8 74 f2 ff ff       	call   f01000a9 <_panic>
				assert(pgdir[i] & PTE_W);
f0100e35:	f6 c2 02             	test   $0x2,%dl
f0100e38:	75 38                	jne    f0100e72 <check_kern_pgdir+0x23d>
f0100e3a:	68 a0 55 10 f0       	push   $0xf01055a0
f0100e3f:	68 7a 55 10 f0       	push   $0xf010557a
f0100e44:	68 10 03 00 00       	push   $0x310
f0100e49:	68 5b 55 10 f0       	push   $0xf010555b
f0100e4e:	e8 56 f2 ff ff       	call   f01000a9 <_panic>
			} else
				assert(pgdir[i] == 0);
f0100e53:	83 3c 83 00          	cmpl   $0x0,(%ebx,%eax,4)
f0100e57:	74 19                	je     f0100e72 <check_kern_pgdir+0x23d>
f0100e59:	68 b1 55 10 f0       	push   $0xf01055b1
f0100e5e:	68 7a 55 10 f0       	push   $0xf010557a
f0100e63:	68 12 03 00 00       	push   $0x312
f0100e68:	68 5b 55 10 f0       	push   $0xf010555b
f0100e6d:	e8 37 f2 ff ff       	call   f01000a9 <_panic>
	for (i = 0; i < KSTKSIZE; i += PGSIZE)
		assert(check_va2pa(pgdir, KSTACKTOP - KSTKSIZE + i) == PADDR(bootstack) + i);
	assert(check_va2pa(pgdir, KSTACKTOP - PTSIZE) == ~0);

	// check PDE permissions
	for (i = 0; i < NPDENTRIES; i++) {
f0100e72:	83 c0 01             	add    $0x1,%eax
f0100e75:	3d ff 03 00 00       	cmp    $0x3ff,%eax
f0100e7a:	0f 86 50 ff ff ff    	jbe    f0100dd0 <check_kern_pgdir+0x19b>
			} else
				assert(pgdir[i] == 0);
			break;
		}
	}
	cprintf("check_kern_pgdir() succeeded!\n");
f0100e80:	83 ec 0c             	sub    $0xc,%esp
f0100e83:	68 f0 4e 10 f0       	push   $0xf0104ef0
f0100e88:	e8 eb 20 00 00       	call   f0102f78 <cprintf>
			assert(PTE_ADDR(pgdir[i]) == (i - kern_pdx) << PDXSHIFT);
		}
		cprintf("check_kern_pgdir_pse() succeeded!\n");
	#endif

}
f0100e8d:	83 c4 10             	add    $0x10,%esp
f0100e90:	8d 65 f4             	lea    -0xc(%ebp),%esp
f0100e93:	5b                   	pop    %ebx
f0100e94:	5e                   	pop    %esi
f0100e95:	5f                   	pop    %edi
f0100e96:	5d                   	pop    %ebp
f0100e97:	c3                   	ret    

f0100e98 <check_page_free_list>:
//
// Check that the pages on the page_free_list are reasonable.
//
static void
check_page_free_list(bool only_low_memory)
{
f0100e98:	55                   	push   %ebp
f0100e99:	89 e5                	mov    %esp,%ebp
f0100e9b:	57                   	push   %edi
f0100e9c:	56                   	push   %esi
f0100e9d:	53                   	push   %ebx
f0100e9e:	83 ec 2c             	sub    $0x2c,%esp
	struct PageInfo *pp;
	unsigned pdx_limit = only_low_memory ? 1 : NPDENTRIES;
f0100ea1:	84 c0                	test   %al,%al
f0100ea3:	0f 85 35 02 00 00    	jne    f01010de <check_page_free_list+0x246>
f0100ea9:	e9 43 02 00 00       	jmp    f01010f1 <check_page_free_list+0x259>
	int nfree_basemem = 0, nfree_extmem = 0;
	char *first_free_page;

	if (!page_free_list)
		panic("'page_free_list' is a null pointer!");
f0100eae:	83 ec 04             	sub    $0x4,%esp
f0100eb1:	68 10 4f 10 f0       	push   $0xf0104f10
f0100eb6:	68 64 02 00 00       	push   $0x264
f0100ebb:	68 5b 55 10 f0       	push   $0xf010555b
f0100ec0:	e8 e4 f1 ff ff       	call   f01000a9 <_panic>

	if (only_low_memory) {
		// Move pages with lower addresses first in the free
		// list, since entry_pgdir does not map all pages.
		struct PageInfo *pp1, *pp2;
		struct PageInfo **tp[2] = { &pp1, &pp2 };
f0100ec5:	8d 45 d8             	lea    -0x28(%ebp),%eax
f0100ec8:	89 45 e0             	mov    %eax,-0x20(%ebp)
f0100ecb:	8d 45 dc             	lea    -0x24(%ebp),%eax
f0100ece:	89 45 e4             	mov    %eax,-0x1c(%ebp)
		for (pp = page_free_list; pp; pp = pp->pp_link) {
			int pagetype = PDX(page2pa(pp)) >= pdx_limit;
f0100ed1:	89 d8                	mov    %ebx,%eax
f0100ed3:	e8 65 fb ff ff       	call   f0100a3d <page2pa>
f0100ed8:	c1 e8 16             	shr    $0x16,%eax
f0100edb:	85 c0                	test   %eax,%eax
f0100edd:	0f 95 c0             	setne  %al
f0100ee0:	0f b6 c0             	movzbl %al,%eax
			*tp[pagetype] = pp;
f0100ee3:	8b 54 85 e0          	mov    -0x20(%ebp,%eax,4),%edx
f0100ee7:	89 1a                	mov    %ebx,(%edx)
			tp[pagetype] = &pp->pp_link;
f0100ee9:	89 5c 85 e0          	mov    %ebx,-0x20(%ebp,%eax,4)
	if (only_low_memory) {
		// Move pages with lower addresses first in the free
		// list, since entry_pgdir does not map all pages.
		struct PageInfo *pp1, *pp2;
		struct PageInfo **tp[2] = { &pp1, &pp2 };
		for (pp = page_free_list; pp; pp = pp->pp_link) {
f0100eed:	8b 1b                	mov    (%ebx),%ebx
f0100eef:	85 db                	test   %ebx,%ebx
f0100ef1:	75 de                	jne    f0100ed1 <check_page_free_list+0x39>
			int pagetype = PDX(page2pa(pp)) >= pdx_limit;
			*tp[pagetype] = pp;
			tp[pagetype] = &pp->pp_link;
		}
		*tp[1] = 0;
f0100ef3:	8b 45 e4             	mov    -0x1c(%ebp),%eax
f0100ef6:	c7 00 00 00 00 00    	movl   $0x0,(%eax)
		*tp[0] = pp2;
f0100efc:	8b 45 e0             	mov    -0x20(%ebp),%eax
f0100eff:	8b 55 dc             	mov    -0x24(%ebp),%edx
f0100f02:	89 10                	mov    %edx,(%eax)
		page_free_list = pp1;
f0100f04:	8b 45 d8             	mov    -0x28(%ebp),%eax
f0100f07:	a3 c0 3c 19 f0       	mov    %eax,0xf0193cc0
//
static void
check_page_free_list(bool only_low_memory)
{
	struct PageInfo *pp;
	unsigned pdx_limit = only_low_memory ? 1 : NPDENTRIES;
f0100f0c:	be 01 00 00 00       	mov    $0x1,%esi
		page_free_list = pp1;
	}

	// if there's a page that shouldn't be on the free list,
	// try to make sure it eventually causes trouble.
	for (pp = page_free_list; pp; pp = pp->pp_link)
f0100f11:	8b 1d c0 3c 19 f0    	mov    0xf0193cc0,%ebx
f0100f17:	eb 2d                	jmp    f0100f46 <check_page_free_list+0xae>
		if (PDX(page2pa(pp)) < pdx_limit)
f0100f19:	89 d8                	mov    %ebx,%eax
f0100f1b:	e8 1d fb ff ff       	call   f0100a3d <page2pa>
f0100f20:	c1 e8 16             	shr    $0x16,%eax
f0100f23:	39 f0                	cmp    %esi,%eax
f0100f25:	73 1d                	jae    f0100f44 <check_page_free_list+0xac>
			memset(page2kva(pp), 0x97, 128);
f0100f27:	89 d8                	mov    %ebx,%eax
f0100f29:	e8 db fb ff ff       	call   f0100b09 <page2kva>
f0100f2e:	83 ec 04             	sub    $0x4,%esp
f0100f31:	68 80 00 00 00       	push   $0x80
f0100f36:	68 97 00 00 00       	push   $0x97
f0100f3b:	50                   	push   %eax
f0100f3c:	e8 3e 34 00 00       	call   f010437f <memset>
f0100f41:	83 c4 10             	add    $0x10,%esp
		page_free_list = pp1;
	}

	// if there's a page that shouldn't be on the free list,
	// try to make sure it eventually causes trouble.
	for (pp = page_free_list; pp; pp = pp->pp_link)
f0100f44:	8b 1b                	mov    (%ebx),%ebx
f0100f46:	85 db                	test   %ebx,%ebx
f0100f48:	75 cf                	jne    f0100f19 <check_page_free_list+0x81>
		if (PDX(page2pa(pp)) < pdx_limit)
			memset(page2kva(pp), 0x97, 128);

	first_free_page = (char *) boot_alloc(0);
f0100f4a:	b8 00 00 00 00       	mov    $0x0,%eax
f0100f4f:	e8 65 fc ff ff       	call   f0100bb9 <boot_alloc>
f0100f54:	89 45 c8             	mov    %eax,-0x38(%ebp)
	for (pp = page_free_list; pp; pp = pp->pp_link) {
f0100f57:	8b 1d c0 3c 19 f0    	mov    0xf0193cc0,%ebx
		// check that we didn't corrupt the free list itself
		assert(pp >= pages);
f0100f5d:	8b 35 8c 59 19 f0    	mov    0xf019598c,%esi
		assert(pp < pages + npages);
f0100f63:	a1 84 59 19 f0       	mov    0xf0195984,%eax
f0100f68:	8d 04 c6             	lea    (%esi,%eax,8),%eax
f0100f6b:	89 45 d4             	mov    %eax,-0x2c(%ebp)
		assert(((char *) pp - (char *) pages) % sizeof(*pp) == 0);
f0100f6e:	89 75 d0             	mov    %esi,-0x30(%ebp)
static void
check_page_free_list(bool only_low_memory)
{
	struct PageInfo *pp;
	unsigned pdx_limit = only_low_memory ? 1 : NPDENTRIES;
	int nfree_basemem = 0, nfree_extmem = 0;
f0100f71:	c7 45 cc 00 00 00 00 	movl   $0x0,-0x34(%ebp)
f0100f78:	bf 00 00 00 00       	mov    $0x0,%edi
	for (pp = page_free_list; pp; pp = pp->pp_link)
		if (PDX(page2pa(pp)) < pdx_limit)
			memset(page2kva(pp), 0x97, 128);

	first_free_page = (char *) boot_alloc(0);
	for (pp = page_free_list; pp; pp = pp->pp_link) {
f0100f7d:	e9 18 01 00 00       	jmp    f010109a <check_page_free_list+0x202>
		// check that we didn't corrupt the free list itself
		assert(pp >= pages);
f0100f82:	39 f3                	cmp    %esi,%ebx
f0100f84:	73 19                	jae    f0100f9f <check_page_free_list+0x107>
f0100f86:	68 bf 55 10 f0       	push   $0xf01055bf
f0100f8b:	68 7a 55 10 f0       	push   $0xf010557a
f0100f90:	68 7e 02 00 00       	push   $0x27e
f0100f95:	68 5b 55 10 f0       	push   $0xf010555b
f0100f9a:	e8 0a f1 ff ff       	call   f01000a9 <_panic>
		assert(pp < pages + npages);
f0100f9f:	3b 5d d4             	cmp    -0x2c(%ebp),%ebx
f0100fa2:	72 19                	jb     f0100fbd <check_page_free_list+0x125>
f0100fa4:	68 cb 55 10 f0       	push   $0xf01055cb
f0100fa9:	68 7a 55 10 f0       	push   $0xf010557a
f0100fae:	68 7f 02 00 00       	push   $0x27f
f0100fb3:	68 5b 55 10 f0       	push   $0xf010555b
f0100fb8:	e8 ec f0 ff ff       	call   f01000a9 <_panic>
		assert(((char *) pp - (char *) pages) % sizeof(*pp) == 0);
f0100fbd:	89 d8                	mov    %ebx,%eax
f0100fbf:	2b 45 d0             	sub    -0x30(%ebp),%eax
f0100fc2:	a8 07                	test   $0x7,%al
f0100fc4:	74 19                	je     f0100fdf <check_page_free_list+0x147>
f0100fc6:	68 34 4f 10 f0       	push   $0xf0104f34
f0100fcb:	68 7a 55 10 f0       	push   $0xf010557a
f0100fd0:	68 80 02 00 00       	push   $0x280
f0100fd5:	68 5b 55 10 f0       	push   $0xf010555b
f0100fda:	e8 ca f0 ff ff       	call   f01000a9 <_panic>

		// check a few pages that shouldn't be on the free list
		assert(page2pa(pp) != 0);
f0100fdf:	89 d8                	mov    %ebx,%eax
f0100fe1:	e8 57 fa ff ff       	call   f0100a3d <page2pa>
f0100fe6:	85 c0                	test   %eax,%eax
f0100fe8:	75 19                	jne    f0101003 <check_page_free_list+0x16b>
f0100fea:	68 df 55 10 f0       	push   $0xf01055df
f0100fef:	68 7a 55 10 f0       	push   $0xf010557a
f0100ff4:	68 83 02 00 00       	push   $0x283
f0100ff9:	68 5b 55 10 f0       	push   $0xf010555b
f0100ffe:	e8 a6 f0 ff ff       	call   f01000a9 <_panic>
		assert(page2pa(pp) != IOPHYSMEM);
f0101003:	3d 00 00 0a 00       	cmp    $0xa0000,%eax
f0101008:	75 19                	jne    f0101023 <check_page_free_list+0x18b>
f010100a:	68 f0 55 10 f0       	push   $0xf01055f0
f010100f:	68 7a 55 10 f0       	push   $0xf010557a
f0101014:	68 84 02 00 00       	push   $0x284
f0101019:	68 5b 55 10 f0       	push   $0xf010555b
f010101e:	e8 86 f0 ff ff       	call   f01000a9 <_panic>
		assert(page2pa(pp) != EXTPHYSMEM - PGSIZE);
f0101023:	3d 00 f0 0f 00       	cmp    $0xff000,%eax
f0101028:	75 19                	jne    f0101043 <check_page_free_list+0x1ab>
f010102a:	68 68 4f 10 f0       	push   $0xf0104f68
f010102f:	68 7a 55 10 f0       	push   $0xf010557a
f0101034:	68 85 02 00 00       	push   $0x285
f0101039:	68 5b 55 10 f0       	push   $0xf010555b
f010103e:	e8 66 f0 ff ff       	call   f01000a9 <_panic>
		assert(page2pa(pp) != EXTPHYSMEM);
f0101043:	3d 00 00 10 00       	cmp    $0x100000,%eax
f0101048:	75 19                	jne    f0101063 <check_page_free_list+0x1cb>
f010104a:	68 09 56 10 f0       	push   $0xf0105609
f010104f:	68 7a 55 10 f0       	push   $0xf010557a
f0101054:	68 86 02 00 00       	push   $0x286
f0101059:	68 5b 55 10 f0       	push   $0xf010555b
f010105e:	e8 46 f0 ff ff       	call   f01000a9 <_panic>
		assert(page2pa(pp) < EXTPHYSMEM || (char *) page2kva(pp) >= first_free_page);
f0101063:	3d ff ff 0f 00       	cmp    $0xfffff,%eax
f0101068:	76 25                	jbe    f010108f <check_page_free_list+0x1f7>
f010106a:	89 d8                	mov    %ebx,%eax
f010106c:	e8 98 fa ff ff       	call   f0100b09 <page2kva>
f0101071:	39 45 c8             	cmp    %eax,-0x38(%ebp)
f0101074:	76 1e                	jbe    f0101094 <check_page_free_list+0x1fc>
f0101076:	68 8c 4f 10 f0       	push   $0xf0104f8c
f010107b:	68 7a 55 10 f0       	push   $0xf010557a
f0101080:	68 87 02 00 00       	push   $0x287
f0101085:	68 5b 55 10 f0       	push   $0xf010555b
f010108a:	e8 1a f0 ff ff       	call   f01000a9 <_panic>

		if (page2pa(pp) < EXTPHYSMEM)
			++nfree_basemem;
f010108f:	83 c7 01             	add    $0x1,%edi
f0101092:	eb 04                	jmp    f0101098 <check_page_free_list+0x200>
		else
			++nfree_extmem;
f0101094:	83 45 cc 01          	addl   $0x1,-0x34(%ebp)
	for (pp = page_free_list; pp; pp = pp->pp_link)
		if (PDX(page2pa(pp)) < pdx_limit)
			memset(page2kva(pp), 0x97, 128);

	first_free_page = (char *) boot_alloc(0);
	for (pp = page_free_list; pp; pp = pp->pp_link) {
f0101098:	8b 1b                	mov    (%ebx),%ebx
f010109a:	85 db                	test   %ebx,%ebx
f010109c:	0f 85 e0 fe ff ff    	jne    f0100f82 <check_page_free_list+0xea>
			++nfree_basemem;
		else
			++nfree_extmem;
	}

	assert(nfree_basemem > 0);
f01010a2:	85 ff                	test   %edi,%edi
f01010a4:	7f 19                	jg     f01010bf <check_page_free_list+0x227>
f01010a6:	68 23 56 10 f0       	push   $0xf0105623
f01010ab:	68 7a 55 10 f0       	push   $0xf010557a
f01010b0:	68 8f 02 00 00       	push   $0x28f
f01010b5:	68 5b 55 10 f0       	push   $0xf010555b
f01010ba:	e8 ea ef ff ff       	call   f01000a9 <_panic>
	assert(nfree_extmem > 0);
f01010bf:	83 7d cc 00          	cmpl   $0x0,-0x34(%ebp)
f01010c3:	7f 43                	jg     f0101108 <check_page_free_list+0x270>
f01010c5:	68 35 56 10 f0       	push   $0xf0105635
f01010ca:	68 7a 55 10 f0       	push   $0xf010557a
f01010cf:	68 90 02 00 00       	push   $0x290
f01010d4:	68 5b 55 10 f0       	push   $0xf010555b
f01010d9:	e8 cb ef ff ff       	call   f01000a9 <_panic>
	struct PageInfo *pp;
	unsigned pdx_limit = only_low_memory ? 1 : NPDENTRIES;
	int nfree_basemem = 0, nfree_extmem = 0;
	char *first_free_page;

	if (!page_free_list)
f01010de:	8b 1d c0 3c 19 f0    	mov    0xf0193cc0,%ebx
f01010e4:	85 db                	test   %ebx,%ebx
f01010e6:	0f 85 d9 fd ff ff    	jne    f0100ec5 <check_page_free_list+0x2d>
f01010ec:	e9 bd fd ff ff       	jmp    f0100eae <check_page_free_list+0x16>
f01010f1:	83 3d c0 3c 19 f0 00 	cmpl   $0x0,0xf0193cc0
f01010f8:	0f 84 b0 fd ff ff    	je     f0100eae <check_page_free_list+0x16>
//
static void
check_page_free_list(bool only_low_memory)
{
	struct PageInfo *pp;
	unsigned pdx_limit = only_low_memory ? 1 : NPDENTRIES;
f01010fe:	be 00 04 00 00       	mov    $0x400,%esi
f0101103:	e9 09 fe ff ff       	jmp    f0100f11 <check_page_free_list+0x79>
			++nfree_extmem;
	}

	assert(nfree_basemem > 0);
	assert(nfree_extmem > 0);
}
f0101108:	8d 65 f4             	lea    -0xc(%ebp),%esp
f010110b:	5b                   	pop    %ebx
f010110c:	5e                   	pop    %esi
f010110d:	5f                   	pop    %edi
f010110e:	5d                   	pop    %ebp
f010110f:	c3                   	ret    

f0101110 <pa2page>:
}

static inline struct PageInfo*
pa2page(physaddr_t pa)
{
	if (PGNUM(pa) >= npages)
f0101110:	c1 e8 0c             	shr    $0xc,%eax
f0101113:	3b 05 84 59 19 f0    	cmp    0xf0195984,%eax
f0101119:	72 17                	jb     f0101132 <pa2page+0x22>
	return (pp - pages) << PGSHIFT;
}

static inline struct PageInfo*
pa2page(physaddr_t pa)
{
f010111b:	55                   	push   %ebp
f010111c:	89 e5                	mov    %esp,%ebp
f010111e:	83 ec 0c             	sub    $0xc,%esp
	if (PGNUM(pa) >= npages)
		panic("pa2page called with invalid pa");
f0101121:	68 d4 4f 10 f0       	push   $0xf0104fd4
f0101126:	6a 4f                	push   $0x4f
f0101128:	68 4d 55 10 f0       	push   $0xf010554d
f010112d:	e8 77 ef ff ff       	call   f01000a9 <_panic>
	return &pages[PGNUM(pa)];
f0101132:	8b 15 8c 59 19 f0    	mov    0xf019598c,%edx
f0101138:	8d 04 c2             	lea    (%edx,%eax,8),%eax
}
f010113b:	c3                   	ret    

f010113c <page_init>:
// allocator functions below to allocate and deallocate physical
// memory via the page_free_list.
//
void
page_init(void)
{
f010113c:	55                   	push   %ebp
f010113d:	89 e5                	mov    %esp,%ebp
f010113f:	56                   	push   %esi
f0101140:	53                   	push   %ebx
	// NB: DO NOT actually touch the physical memory corresponding to
	// free pages!
	size_t i;
	uint32_t lim_inf_IO = PGNUM(IOPHYSMEM);//==npages_basemem
	//uint32_t lim_sup_IO = PGNUM(EXTPHYSMEM); //no hace falta por lim_sup_kernmem > lim_sup_IO
	uint32_t lim_sup_kernmem = PGNUM(PADDR(boot_alloc(0)));
f0101141:	b8 00 00 00 00       	mov    $0x0,%eax
f0101146:	e8 6e fa ff ff       	call   f0100bb9 <boot_alloc>
f010114b:	89 c1                	mov    %eax,%ecx
f010114d:	ba 19 01 00 00       	mov    $0x119,%edx
f0101152:	b8 5b 55 10 f0       	mov    $0xf010555b,%eax
f0101157:	e8 3b fa ff ff       	call   f0100b97 <_paddr>
f010115c:	c1 e8 0c             	shr    $0xc,%eax
f010115f:	8b 35 c0 3c 19 f0    	mov    0xf0193cc0,%esi
	for (i = 1; i < npages; i++) {//la 0 no se agrega tampoco
f0101165:	b9 00 00 00 00       	mov    $0x0,%ecx
f010116a:	ba 01 00 00 00       	mov    $0x1,%edx
f010116f:	eb 33                	jmp    f01011a4 <page_init+0x68>
		if (i>=lim_inf_IO && i<lim_sup_kernmem) continue;//asi es como se no-mapea		
f0101171:	81 fa 9f 00 00 00    	cmp    $0x9f,%edx
f0101177:	76 04                	jbe    f010117d <page_init+0x41>
f0101179:	39 c2                	cmp    %eax,%edx
f010117b:	72 24                	jb     f01011a1 <page_init+0x65>
		pages[i].pp_ref = 0;
f010117d:	8d 0c d5 00 00 00 00 	lea    0x0(,%edx,8),%ecx
f0101184:	89 cb                	mov    %ecx,%ebx
f0101186:	03 1d 8c 59 19 f0    	add    0xf019598c,%ebx
f010118c:	66 c7 43 04 00 00    	movw   $0x0,0x4(%ebx)
		pages[i].pp_link = page_free_list;
f0101192:	89 33                	mov    %esi,(%ebx)
		page_free_list = &pages[i];
f0101194:	89 ce                	mov    %ecx,%esi
f0101196:	03 35 8c 59 19 f0    	add    0xf019598c,%esi
f010119c:	b9 01 00 00 00       	mov    $0x1,%ecx
	// free pages!
	size_t i;
	uint32_t lim_inf_IO = PGNUM(IOPHYSMEM);//==npages_basemem
	//uint32_t lim_sup_IO = PGNUM(EXTPHYSMEM); //no hace falta por lim_sup_kernmem > lim_sup_IO
	uint32_t lim_sup_kernmem = PGNUM(PADDR(boot_alloc(0)));
	for (i = 1; i < npages; i++) {//la 0 no se agrega tampoco
f01011a1:	83 c2 01             	add    $0x1,%edx
f01011a4:	3b 15 84 59 19 f0    	cmp    0xf0195984,%edx
f01011aa:	72 c5                	jb     f0101171 <page_init+0x35>
f01011ac:	84 c9                	test   %cl,%cl
f01011ae:	74 06                	je     f01011b6 <page_init+0x7a>
f01011b0:	89 35 c0 3c 19 f0    	mov    %esi,0xf0193cc0
		if (i>=lim_inf_IO && i<lim_sup_kernmem) continue;//asi es como se no-mapea		
		pages[i].pp_ref = 0;
		pages[i].pp_link = page_free_list;
		page_free_list = &pages[i];
	}
}
f01011b6:	5b                   	pop    %ebx
f01011b7:	5e                   	pop    %esi
f01011b8:	5d                   	pop    %ebp
f01011b9:	c3                   	ret    

f01011ba <page_alloc>:
// Returns NULL if out of free memory.
//
// Hint: use page2kva and memset
struct PageInfo *
page_alloc(int alloc_flags)
{	if (page_free_list == NULL) return NULL;
f01011ba:	55                   	push   %ebp
f01011bb:	89 e5                	mov    %esp,%ebp
f01011bd:	53                   	push   %ebx
f01011be:	83 ec 04             	sub    $0x4,%esp
f01011c1:	8b 1d c0 3c 19 f0    	mov    0xf0193cc0,%ebx
f01011c7:	85 db                	test   %ebx,%ebx
f01011c9:	74 2d                	je     f01011f8 <page_alloc+0x3e>
	struct PageInfo* pag = page_free_list;
	page_free_list = page_free_list->pp_link;
f01011cb:	8b 03                	mov    (%ebx),%eax
f01011cd:	a3 c0 3c 19 f0       	mov    %eax,0xf0193cc0
	pag->pp_link = NULL;
f01011d2:	c7 03 00 00 00 00    	movl   $0x0,(%ebx)
	if (alloc_flags & ALLOC_ZERO) memset(page2kva(pag),0,PGSIZE);
f01011d8:	f6 45 08 01          	testb  $0x1,0x8(%ebp)
f01011dc:	74 1a                	je     f01011f8 <page_alloc+0x3e>
f01011de:	89 d8                	mov    %ebx,%eax
f01011e0:	e8 24 f9 ff ff       	call   f0100b09 <page2kva>
f01011e5:	83 ec 04             	sub    $0x4,%esp
f01011e8:	68 00 10 00 00       	push   $0x1000
f01011ed:	6a 00                	push   $0x0
f01011ef:	50                   	push   %eax
f01011f0:	e8 8a 31 00 00       	call   f010437f <memset>
f01011f5:	83 c4 10             	add    $0x10,%esp
	return pag;
}
f01011f8:	89 d8                	mov    %ebx,%eax
f01011fa:	8b 5d fc             	mov    -0x4(%ebp),%ebx
f01011fd:	c9                   	leave  
f01011fe:	c3                   	ret    

f01011ff <page_free>:
// Return a page to the free list.
// (This function should only be called when pp->pp_ref reaches 0.)
//
void
page_free(struct PageInfo *pp)
{
f01011ff:	55                   	push   %ebp
f0101200:	89 e5                	mov    %esp,%ebp
f0101202:	83 ec 08             	sub    $0x8,%esp
f0101205:	8b 45 08             	mov    0x8(%ebp),%eax
	// Fill this function in
	// Hint: You may want to panic if pp->pp_ref is nonzero or
	// pp->pp_link is not NULL.
	if (pp->pp_ref) panic("page still in use!\n");
f0101208:	66 83 78 04 00       	cmpw   $0x0,0x4(%eax)
f010120d:	74 17                	je     f0101226 <page_free+0x27>
f010120f:	83 ec 04             	sub    $0x4,%esp
f0101212:	68 46 56 10 f0       	push   $0xf0105646
f0101217:	68 42 01 00 00       	push   $0x142
f010121c:	68 5b 55 10 f0       	push   $0xf010555b
f0101221:	e8 83 ee ff ff       	call   f01000a9 <_panic>
	if (pp->pp_link) panic("page has non-NULL pp_link (already freed?)\n");
f0101226:	83 38 00             	cmpl   $0x0,(%eax)
f0101229:	74 17                	je     f0101242 <page_free+0x43>
f010122b:	83 ec 04             	sub    $0x4,%esp
f010122e:	68 f4 4f 10 f0       	push   $0xf0104ff4
f0101233:	68 43 01 00 00       	push   $0x143
f0101238:	68 5b 55 10 f0       	push   $0xf010555b
f010123d:	e8 67 ee ff ff       	call   f01000a9 <_panic>
	//pp_ref=0,pp_link=NULL
	pp->pp_link=page_free_list;
f0101242:	8b 15 c0 3c 19 f0    	mov    0xf0193cc0,%edx
f0101248:	89 10                	mov    %edx,(%eax)
	page_free_list=pp;
f010124a:	a3 c0 3c 19 f0       	mov    %eax,0xf0193cc0
}
f010124f:	c9                   	leave  
f0101250:	c3                   	ret    

f0101251 <check_page_alloc>:
// Check the physical page allocator (page_alloc(), page_free(),
// and page_init()).
//
static void
check_page_alloc(void)
{
f0101251:	55                   	push   %ebp
f0101252:	89 e5                	mov    %esp,%ebp
f0101254:	57                   	push   %edi
f0101255:	56                   	push   %esi
f0101256:	53                   	push   %ebx
f0101257:	83 ec 1c             	sub    $0x1c,%esp
	int nfree;
	struct PageInfo *fl;
	char *c;
	int i;

	if (!pages)
f010125a:	83 3d 8c 59 19 f0 00 	cmpl   $0x0,0xf019598c
f0101261:	75 17                	jne    f010127a <check_page_alloc+0x29>
		panic("'pages' is a null pointer!");
f0101263:	83 ec 04             	sub    $0x4,%esp
f0101266:	68 5a 56 10 f0       	push   $0xf010565a
f010126b:	68 a1 02 00 00       	push   $0x2a1
f0101270:	68 5b 55 10 f0       	push   $0xf010555b
f0101275:	e8 2f ee ff ff       	call   f01000a9 <_panic>

	// check number of free pages
	for (pp = page_free_list, nfree = 0; pp; pp = pp->pp_link)
f010127a:	a1 c0 3c 19 f0       	mov    0xf0193cc0,%eax
f010127f:	be 00 00 00 00       	mov    $0x0,%esi
f0101284:	eb 05                	jmp    f010128b <check_page_alloc+0x3a>
		++nfree;
f0101286:	83 c6 01             	add    $0x1,%esi

	if (!pages)
		panic("'pages' is a null pointer!");

	// check number of free pages
	for (pp = page_free_list, nfree = 0; pp; pp = pp->pp_link)
f0101289:	8b 00                	mov    (%eax),%eax
f010128b:	85 c0                	test   %eax,%eax
f010128d:	75 f7                	jne    f0101286 <check_page_alloc+0x35>
		++nfree;

	// should be able to allocate three pages
	pp0 = pp1 = pp2 = 0;
	assert((pp0 = page_alloc(0)));
f010128f:	83 ec 0c             	sub    $0xc,%esp
f0101292:	6a 00                	push   $0x0
f0101294:	e8 21 ff ff ff       	call   f01011ba <page_alloc>
f0101299:	89 c7                	mov    %eax,%edi
f010129b:	83 c4 10             	add    $0x10,%esp
f010129e:	85 c0                	test   %eax,%eax
f01012a0:	75 19                	jne    f01012bb <check_page_alloc+0x6a>
f01012a2:	68 75 56 10 f0       	push   $0xf0105675
f01012a7:	68 7a 55 10 f0       	push   $0xf010557a
f01012ac:	68 a9 02 00 00       	push   $0x2a9
f01012b1:	68 5b 55 10 f0       	push   $0xf010555b
f01012b6:	e8 ee ed ff ff       	call   f01000a9 <_panic>
	assert((pp1 = page_alloc(0)));
f01012bb:	83 ec 0c             	sub    $0xc,%esp
f01012be:	6a 00                	push   $0x0
f01012c0:	e8 f5 fe ff ff       	call   f01011ba <page_alloc>
f01012c5:	89 45 e4             	mov    %eax,-0x1c(%ebp)
f01012c8:	83 c4 10             	add    $0x10,%esp
f01012cb:	85 c0                	test   %eax,%eax
f01012cd:	75 19                	jne    f01012e8 <check_page_alloc+0x97>
f01012cf:	68 8b 56 10 f0       	push   $0xf010568b
f01012d4:	68 7a 55 10 f0       	push   $0xf010557a
f01012d9:	68 aa 02 00 00       	push   $0x2aa
f01012de:	68 5b 55 10 f0       	push   $0xf010555b
f01012e3:	e8 c1 ed ff ff       	call   f01000a9 <_panic>
	assert((pp2 = page_alloc(0)));
f01012e8:	83 ec 0c             	sub    $0xc,%esp
f01012eb:	6a 00                	push   $0x0
f01012ed:	e8 c8 fe ff ff       	call   f01011ba <page_alloc>
f01012f2:	89 c3                	mov    %eax,%ebx
f01012f4:	83 c4 10             	add    $0x10,%esp
f01012f7:	85 c0                	test   %eax,%eax
f01012f9:	75 19                	jne    f0101314 <check_page_alloc+0xc3>
f01012fb:	68 a1 56 10 f0       	push   $0xf01056a1
f0101300:	68 7a 55 10 f0       	push   $0xf010557a
f0101305:	68 ab 02 00 00       	push   $0x2ab
f010130a:	68 5b 55 10 f0       	push   $0xf010555b
f010130f:	e8 95 ed ff ff       	call   f01000a9 <_panic>

	assert(pp0);
	assert(pp1 && pp1 != pp0);
f0101314:	3b 7d e4             	cmp    -0x1c(%ebp),%edi
f0101317:	75 19                	jne    f0101332 <check_page_alloc+0xe1>
f0101319:	68 b7 56 10 f0       	push   $0xf01056b7
f010131e:	68 7a 55 10 f0       	push   $0xf010557a
f0101323:	68 ae 02 00 00       	push   $0x2ae
f0101328:	68 5b 55 10 f0       	push   $0xf010555b
f010132d:	e8 77 ed ff ff       	call   f01000a9 <_panic>
	assert(pp2 && pp2 != pp1 && pp2 != pp0);
f0101332:	39 45 e4             	cmp    %eax,-0x1c(%ebp)
f0101335:	74 04                	je     f010133b <check_page_alloc+0xea>
f0101337:	39 c7                	cmp    %eax,%edi
f0101339:	75 19                	jne    f0101354 <check_page_alloc+0x103>
f010133b:	68 20 50 10 f0       	push   $0xf0105020
f0101340:	68 7a 55 10 f0       	push   $0xf010557a
f0101345:	68 af 02 00 00       	push   $0x2af
f010134a:	68 5b 55 10 f0       	push   $0xf010555b
f010134f:	e8 55 ed ff ff       	call   f01000a9 <_panic>
	assert(page2pa(pp0) < npages*PGSIZE);
f0101354:	89 f8                	mov    %edi,%eax
f0101356:	e8 e2 f6 ff ff       	call   f0100a3d <page2pa>
f010135b:	8b 0d 84 59 19 f0    	mov    0xf0195984,%ecx
f0101361:	c1 e1 0c             	shl    $0xc,%ecx
f0101364:	89 4d e0             	mov    %ecx,-0x20(%ebp)
f0101367:	39 c8                	cmp    %ecx,%eax
f0101369:	72 19                	jb     f0101384 <check_page_alloc+0x133>
f010136b:	68 c9 56 10 f0       	push   $0xf01056c9
f0101370:	68 7a 55 10 f0       	push   $0xf010557a
f0101375:	68 b0 02 00 00       	push   $0x2b0
f010137a:	68 5b 55 10 f0       	push   $0xf010555b
f010137f:	e8 25 ed ff ff       	call   f01000a9 <_panic>
	assert(page2pa(pp1) < npages*PGSIZE);
f0101384:	8b 45 e4             	mov    -0x1c(%ebp),%eax
f0101387:	e8 b1 f6 ff ff       	call   f0100a3d <page2pa>
f010138c:	39 45 e0             	cmp    %eax,-0x20(%ebp)
f010138f:	77 19                	ja     f01013aa <check_page_alloc+0x159>
f0101391:	68 e6 56 10 f0       	push   $0xf01056e6
f0101396:	68 7a 55 10 f0       	push   $0xf010557a
f010139b:	68 b1 02 00 00       	push   $0x2b1
f01013a0:	68 5b 55 10 f0       	push   $0xf010555b
f01013a5:	e8 ff ec ff ff       	call   f01000a9 <_panic>
	assert(page2pa(pp2) < npages*PGSIZE);
f01013aa:	89 d8                	mov    %ebx,%eax
f01013ac:	e8 8c f6 ff ff       	call   f0100a3d <page2pa>
f01013b1:	39 45 e0             	cmp    %eax,-0x20(%ebp)
f01013b4:	77 19                	ja     f01013cf <check_page_alloc+0x17e>
f01013b6:	68 03 57 10 f0       	push   $0xf0105703
f01013bb:	68 7a 55 10 f0       	push   $0xf010557a
f01013c0:	68 b2 02 00 00       	push   $0x2b2
f01013c5:	68 5b 55 10 f0       	push   $0xf010555b
f01013ca:	e8 da ec ff ff       	call   f01000a9 <_panic>

	// temporarily steal the rest of the free pages
	fl = page_free_list;
f01013cf:	a1 c0 3c 19 f0       	mov    0xf0193cc0,%eax
f01013d4:	89 45 e0             	mov    %eax,-0x20(%ebp)
	page_free_list = 0;
f01013d7:	c7 05 c0 3c 19 f0 00 	movl   $0x0,0xf0193cc0
f01013de:	00 00 00 

	// should be no free memory
	assert(!page_alloc(0));
f01013e1:	83 ec 0c             	sub    $0xc,%esp
f01013e4:	6a 00                	push   $0x0
f01013e6:	e8 cf fd ff ff       	call   f01011ba <page_alloc>
f01013eb:	83 c4 10             	add    $0x10,%esp
f01013ee:	85 c0                	test   %eax,%eax
f01013f0:	74 19                	je     f010140b <check_page_alloc+0x1ba>
f01013f2:	68 20 57 10 f0       	push   $0xf0105720
f01013f7:	68 7a 55 10 f0       	push   $0xf010557a
f01013fc:	68 b9 02 00 00       	push   $0x2b9
f0101401:	68 5b 55 10 f0       	push   $0xf010555b
f0101406:	e8 9e ec ff ff       	call   f01000a9 <_panic>

	// free and re-allocate?
	page_free(pp0);
f010140b:	83 ec 0c             	sub    $0xc,%esp
f010140e:	57                   	push   %edi
f010140f:	e8 eb fd ff ff       	call   f01011ff <page_free>
	page_free(pp1);
f0101414:	83 c4 04             	add    $0x4,%esp
f0101417:	ff 75 e4             	pushl  -0x1c(%ebp)
f010141a:	e8 e0 fd ff ff       	call   f01011ff <page_free>
	page_free(pp2);
f010141f:	89 1c 24             	mov    %ebx,(%esp)
f0101422:	e8 d8 fd ff ff       	call   f01011ff <page_free>
	pp0 = pp1 = pp2 = 0;
	assert((pp0 = page_alloc(0)));
f0101427:	c7 04 24 00 00 00 00 	movl   $0x0,(%esp)
f010142e:	e8 87 fd ff ff       	call   f01011ba <page_alloc>
f0101433:	89 c3                	mov    %eax,%ebx
f0101435:	83 c4 10             	add    $0x10,%esp
f0101438:	85 c0                	test   %eax,%eax
f010143a:	75 19                	jne    f0101455 <check_page_alloc+0x204>
f010143c:	68 75 56 10 f0       	push   $0xf0105675
f0101441:	68 7a 55 10 f0       	push   $0xf010557a
f0101446:	68 c0 02 00 00       	push   $0x2c0
f010144b:	68 5b 55 10 f0       	push   $0xf010555b
f0101450:	e8 54 ec ff ff       	call   f01000a9 <_panic>
	assert((pp1 = page_alloc(0)));
f0101455:	83 ec 0c             	sub    $0xc,%esp
f0101458:	6a 00                	push   $0x0
f010145a:	e8 5b fd ff ff       	call   f01011ba <page_alloc>
f010145f:	89 45 e4             	mov    %eax,-0x1c(%ebp)
f0101462:	83 c4 10             	add    $0x10,%esp
f0101465:	85 c0                	test   %eax,%eax
f0101467:	75 19                	jne    f0101482 <check_page_alloc+0x231>
f0101469:	68 8b 56 10 f0       	push   $0xf010568b
f010146e:	68 7a 55 10 f0       	push   $0xf010557a
f0101473:	68 c1 02 00 00       	push   $0x2c1
f0101478:	68 5b 55 10 f0       	push   $0xf010555b
f010147d:	e8 27 ec ff ff       	call   f01000a9 <_panic>
	assert((pp2 = page_alloc(0)));
f0101482:	83 ec 0c             	sub    $0xc,%esp
f0101485:	6a 00                	push   $0x0
f0101487:	e8 2e fd ff ff       	call   f01011ba <page_alloc>
f010148c:	89 c7                	mov    %eax,%edi
f010148e:	83 c4 10             	add    $0x10,%esp
f0101491:	85 c0                	test   %eax,%eax
f0101493:	75 19                	jne    f01014ae <check_page_alloc+0x25d>
f0101495:	68 a1 56 10 f0       	push   $0xf01056a1
f010149a:	68 7a 55 10 f0       	push   $0xf010557a
f010149f:	68 c2 02 00 00       	push   $0x2c2
f01014a4:	68 5b 55 10 f0       	push   $0xf010555b
f01014a9:	e8 fb eb ff ff       	call   f01000a9 <_panic>
	assert(pp0);
	assert(pp1 && pp1 != pp0);
f01014ae:	3b 5d e4             	cmp    -0x1c(%ebp),%ebx
f01014b1:	75 19                	jne    f01014cc <check_page_alloc+0x27b>
f01014b3:	68 b7 56 10 f0       	push   $0xf01056b7
f01014b8:	68 7a 55 10 f0       	push   $0xf010557a
f01014bd:	68 c4 02 00 00       	push   $0x2c4
f01014c2:	68 5b 55 10 f0       	push   $0xf010555b
f01014c7:	e8 dd eb ff ff       	call   f01000a9 <_panic>
	assert(pp2 && pp2 != pp1 && pp2 != pp0);
f01014cc:	39 45 e4             	cmp    %eax,-0x1c(%ebp)
f01014cf:	74 04                	je     f01014d5 <check_page_alloc+0x284>
f01014d1:	39 c3                	cmp    %eax,%ebx
f01014d3:	75 19                	jne    f01014ee <check_page_alloc+0x29d>
f01014d5:	68 20 50 10 f0       	push   $0xf0105020
f01014da:	68 7a 55 10 f0       	push   $0xf010557a
f01014df:	68 c5 02 00 00       	push   $0x2c5
f01014e4:	68 5b 55 10 f0       	push   $0xf010555b
f01014e9:	e8 bb eb ff ff       	call   f01000a9 <_panic>
	assert(!page_alloc(0));
f01014ee:	83 ec 0c             	sub    $0xc,%esp
f01014f1:	6a 00                	push   $0x0
f01014f3:	e8 c2 fc ff ff       	call   f01011ba <page_alloc>
f01014f8:	83 c4 10             	add    $0x10,%esp
f01014fb:	85 c0                	test   %eax,%eax
f01014fd:	74 19                	je     f0101518 <check_page_alloc+0x2c7>
f01014ff:	68 20 57 10 f0       	push   $0xf0105720
f0101504:	68 7a 55 10 f0       	push   $0xf010557a
f0101509:	68 c6 02 00 00       	push   $0x2c6
f010150e:	68 5b 55 10 f0       	push   $0xf010555b
f0101513:	e8 91 eb ff ff       	call   f01000a9 <_panic>

	// test flags
	memset(page2kva(pp0), 1, PGSIZE);
f0101518:	89 d8                	mov    %ebx,%eax
f010151a:	e8 ea f5 ff ff       	call   f0100b09 <page2kva>
f010151f:	83 ec 04             	sub    $0x4,%esp
f0101522:	68 00 10 00 00       	push   $0x1000
f0101527:	6a 01                	push   $0x1
f0101529:	50                   	push   %eax
f010152a:	e8 50 2e 00 00       	call   f010437f <memset>
	page_free(pp0);
f010152f:	89 1c 24             	mov    %ebx,(%esp)
f0101532:	e8 c8 fc ff ff       	call   f01011ff <page_free>
	assert((pp = page_alloc(ALLOC_ZERO)));
f0101537:	c7 04 24 01 00 00 00 	movl   $0x1,(%esp)
f010153e:	e8 77 fc ff ff       	call   f01011ba <page_alloc>
f0101543:	83 c4 10             	add    $0x10,%esp
f0101546:	85 c0                	test   %eax,%eax
f0101548:	75 19                	jne    f0101563 <check_page_alloc+0x312>
f010154a:	68 2f 57 10 f0       	push   $0xf010572f
f010154f:	68 7a 55 10 f0       	push   $0xf010557a
f0101554:	68 cb 02 00 00       	push   $0x2cb
f0101559:	68 5b 55 10 f0       	push   $0xf010555b
f010155e:	e8 46 eb ff ff       	call   f01000a9 <_panic>
	assert(pp && pp0 == pp);
f0101563:	39 c3                	cmp    %eax,%ebx
f0101565:	74 19                	je     f0101580 <check_page_alloc+0x32f>
f0101567:	68 4d 57 10 f0       	push   $0xf010574d
f010156c:	68 7a 55 10 f0       	push   $0xf010557a
f0101571:	68 cc 02 00 00       	push   $0x2cc
f0101576:	68 5b 55 10 f0       	push   $0xf010555b
f010157b:	e8 29 eb ff ff       	call   f01000a9 <_panic>
	c = page2kva(pp);
f0101580:	89 d8                	mov    %ebx,%eax
f0101582:	e8 82 f5 ff ff       	call   f0100b09 <page2kva>
f0101587:	8d 90 00 10 00 00    	lea    0x1000(%eax),%edx
	for (i = 0; i < PGSIZE; i++)
		assert(c[i] == 0);
f010158d:	80 38 00             	cmpb   $0x0,(%eax)
f0101590:	74 19                	je     f01015ab <check_page_alloc+0x35a>
f0101592:	68 5d 57 10 f0       	push   $0xf010575d
f0101597:	68 7a 55 10 f0       	push   $0xf010557a
f010159c:	68 cf 02 00 00       	push   $0x2cf
f01015a1:	68 5b 55 10 f0       	push   $0xf010555b
f01015a6:	e8 fe ea ff ff       	call   f01000a9 <_panic>
f01015ab:	83 c0 01             	add    $0x1,%eax
	memset(page2kva(pp0), 1, PGSIZE);
	page_free(pp0);
	assert((pp = page_alloc(ALLOC_ZERO)));
	assert(pp && pp0 == pp);
	c = page2kva(pp);
	for (i = 0; i < PGSIZE; i++)
f01015ae:	39 d0                	cmp    %edx,%eax
f01015b0:	75 db                	jne    f010158d <check_page_alloc+0x33c>
		assert(c[i] == 0);

	// give free list back
	page_free_list = fl;
f01015b2:	8b 45 e0             	mov    -0x20(%ebp),%eax
f01015b5:	a3 c0 3c 19 f0       	mov    %eax,0xf0193cc0

	// free the pages we took
	page_free(pp0);
f01015ba:	83 ec 0c             	sub    $0xc,%esp
f01015bd:	53                   	push   %ebx
f01015be:	e8 3c fc ff ff       	call   f01011ff <page_free>
	page_free(pp1);
f01015c3:	83 c4 04             	add    $0x4,%esp
f01015c6:	ff 75 e4             	pushl  -0x1c(%ebp)
f01015c9:	e8 31 fc ff ff       	call   f01011ff <page_free>
	page_free(pp2);
f01015ce:	89 3c 24             	mov    %edi,(%esp)
f01015d1:	e8 29 fc ff ff       	call   f01011ff <page_free>

	// number of free pages should be the same
	for (pp = page_free_list; pp; pp = pp->pp_link)
f01015d6:	a1 c0 3c 19 f0       	mov    0xf0193cc0,%eax
f01015db:	83 c4 10             	add    $0x10,%esp
f01015de:	eb 05                	jmp    f01015e5 <check_page_alloc+0x394>
		--nfree;
f01015e0:	83 ee 01             	sub    $0x1,%esi
	page_free(pp0);
	page_free(pp1);
	page_free(pp2);

	// number of free pages should be the same
	for (pp = page_free_list; pp; pp = pp->pp_link)
f01015e3:	8b 00                	mov    (%eax),%eax
f01015e5:	85 c0                	test   %eax,%eax
f01015e7:	75 f7                	jne    f01015e0 <check_page_alloc+0x38f>
		--nfree;
	assert(nfree == 0);
f01015e9:	85 f6                	test   %esi,%esi
f01015eb:	74 19                	je     f0101606 <check_page_alloc+0x3b5>
f01015ed:	68 67 57 10 f0       	push   $0xf0105767
f01015f2:	68 7a 55 10 f0       	push   $0xf010557a
f01015f7:	68 dc 02 00 00       	push   $0x2dc
f01015fc:	68 5b 55 10 f0       	push   $0xf010555b
f0101601:	e8 a3 ea ff ff       	call   f01000a9 <_panic>

	cprintf("check_page_alloc() succeeded!\n");
f0101606:	83 ec 0c             	sub    $0xc,%esp
f0101609:	68 40 50 10 f0       	push   $0xf0105040
f010160e:	e8 65 19 00 00       	call   f0102f78 <cprintf>
}
f0101613:	83 c4 10             	add    $0x10,%esp
f0101616:	8d 65 f4             	lea    -0xc(%ebp),%esp
f0101619:	5b                   	pop    %ebx
f010161a:	5e                   	pop    %esi
f010161b:	5f                   	pop    %edi
f010161c:	5d                   	pop    %ebp
f010161d:	c3                   	ret    

f010161e <page_decref>:
// Decrement the reference count on a page,
// freeing it if there are no more refs.
//
void
page_decref(struct PageInfo* pp)
{
f010161e:	55                   	push   %ebp
f010161f:	89 e5                	mov    %esp,%ebp
f0101621:	83 ec 08             	sub    $0x8,%esp
f0101624:	8b 55 08             	mov    0x8(%ebp),%edx
	if (--pp->pp_ref == 0)
f0101627:	0f b7 42 04          	movzwl 0x4(%edx),%eax
f010162b:	83 e8 01             	sub    $0x1,%eax
f010162e:	66 89 42 04          	mov    %ax,0x4(%edx)
f0101632:	66 85 c0             	test   %ax,%ax
f0101635:	75 0c                	jne    f0101643 <page_decref+0x25>
		page_free(pp);
f0101637:	83 ec 0c             	sub    $0xc,%esp
f010163a:	52                   	push   %edx
f010163b:	e8 bf fb ff ff       	call   f01011ff <page_free>
f0101640:	83 c4 10             	add    $0x10,%esp
}
f0101643:	c9                   	leave  
f0101644:	c3                   	ret    

f0101645 <pgdir_walk>:
// Hint 3: look at inc/mmu.h for useful macros that mainipulate page
// table and page directory entries.
//
pte_t *
pgdir_walk(pde_t *pgdir, const void *va, int create)
{
f0101645:	55                   	push   %ebp
f0101646:	89 e5                	mov    %esp,%ebp
f0101648:	57                   	push   %edi
f0101649:	56                   	push   %esi
f010164a:	53                   	push   %ebx
f010164b:	83 ec 0c             	sub    $0xc,%esp
f010164e:	8b 75 0c             	mov    0xc(%ebp),%esi
	pde_t pde =  pgdir[PDX(va)]; //ojo que esto es P.Addr. !!
f0101651:	89 f3                	mov    %esi,%ebx
f0101653:	c1 eb 16             	shr    $0x16,%ebx
f0101656:	c1 e3 02             	shl    $0x2,%ebx
f0101659:	03 5d 08             	add    0x8(%ebp),%ebx
f010165c:	8b 3b                	mov    (%ebx),%edi
	pte_t* pte = (pte_t*) KADDR(PTE_ADDR(pde));
f010165e:	89 f9                	mov    %edi,%ecx
f0101660:	81 e1 00 f0 ff ff    	and    $0xfffff000,%ecx
f0101666:	ba 6e 01 00 00       	mov    $0x16e,%edx
f010166b:	b8 5b 55 10 f0       	mov    $0xf010555b,%eax
f0101670:	e8 68 f4 ff ff       	call   f0100add <_kaddr>

	if (pde & PTE_P) return pte+PTX(va);
f0101675:	f7 c7 01 00 00 00    	test   $0x1,%edi
f010167b:	74 0d                	je     f010168a <pgdir_walk+0x45>
f010167d:	c1 ee 0a             	shr    $0xa,%esi
f0101680:	81 e6 fc 0f 00 00    	and    $0xffc,%esi
f0101686:	01 f0                	add    %esi,%eax
f0101688:	eb 52                	jmp    f01016dc <pgdir_walk+0x97>

	if (!create) return NULL;
f010168a:	b8 00 00 00 00       	mov    $0x0,%eax
f010168f:	83 7d 10 00          	cmpl   $0x0,0x10(%ebp)
f0101693:	74 47                	je     f01016dc <pgdir_walk+0x97>
	struct PageInfo *page = page_alloc(ALLOC_ZERO);
f0101695:	83 ec 0c             	sub    $0xc,%esp
f0101698:	6a 01                	push   $0x1
f010169a:	e8 1b fb ff ff       	call   f01011ba <page_alloc>
f010169f:	89 c7                	mov    %eax,%edi
	if (page==NULL) return NULL;
f01016a1:	83 c4 10             	add    $0x10,%esp
f01016a4:	85 c0                	test   %eax,%eax
f01016a6:	74 2f                	je     f01016d7 <pgdir_walk+0x92>
	physaddr_t pt_start = page2pa(page);
f01016a8:	e8 90 f3 ff ff       	call   f0100a3d <page2pa>
	page->pp_ref ++;
f01016ad:	66 83 47 04 01       	addw   $0x1,0x4(%edi)
	*(pgdir+PDX(va)) = pt_start | PTE_P | PTE_U | PTE_W;
f01016b2:	89 c2                	mov    %eax,%edx
f01016b4:	83 ca 07             	or     $0x7,%edx
f01016b7:	89 13                	mov    %edx,(%ebx)
	return (pte_t*)KADDR(pt_start)+PTX(va);
f01016b9:	89 c1                	mov    %eax,%ecx
f01016bb:	ba 78 01 00 00       	mov    $0x178,%edx
f01016c0:	b8 5b 55 10 f0       	mov    $0xf010555b,%eax
f01016c5:	e8 13 f4 ff ff       	call   f0100add <_kaddr>
f01016ca:	c1 ee 0a             	shr    $0xa,%esi
f01016cd:	81 e6 fc 0f 00 00    	and    $0xffc,%esi
f01016d3:	01 f0                	add    %esi,%eax
f01016d5:	eb 05                	jmp    f01016dc <pgdir_walk+0x97>

	if (pde & PTE_P) return pte+PTX(va);

	if (!create) return NULL;
	struct PageInfo *page = page_alloc(ALLOC_ZERO);
	if (page==NULL) return NULL;
f01016d7:	b8 00 00 00 00       	mov    $0x0,%eax
	physaddr_t pt_start = page2pa(page);
	page->pp_ref ++;
	*(pgdir+PDX(va)) = pt_start | PTE_P | PTE_U | PTE_W;
	return (pte_t*)KADDR(pt_start)+PTX(va);
}
f01016dc:	8d 65 f4             	lea    -0xc(%ebp),%esp
f01016df:	5b                   	pop    %ebx
f01016e0:	5e                   	pop    %esi
f01016e1:	5f                   	pop    %edi
f01016e2:	5d                   	pop    %ebp
f01016e3:	c3                   	ret    

f01016e4 <boot_map_region>:
//
// Hint: the TA solution uses pgdir_walk
//#define TP1_PSE 1
static void
boot_map_region(pde_t *pgdir, uintptr_t va, size_t size, physaddr_t pa, int perm)
{
f01016e4:	55                   	push   %ebp
f01016e5:	89 e5                	mov    %esp,%ebp
f01016e7:	57                   	push   %edi
f01016e8:	56                   	push   %esi
f01016e9:	53                   	push   %ebx
f01016ea:	83 ec 1c             	sub    $0x1c,%esp
f01016ed:	89 45 e0             	mov    %eax,-0x20(%ebp)
f01016f0:	8b 45 08             	mov    0x8(%ebp),%eax
	assert(va % PGSIZE == 0);
f01016f3:	f7 c2 ff 0f 00 00    	test   $0xfff,%edx
f01016f9:	74 19                	je     f0101714 <boot_map_region+0x30>
f01016fb:	68 72 57 10 f0       	push   $0xf0105772
f0101700:	68 7a 55 10 f0       	push   $0xf010557a
f0101705:	68 8a 01 00 00       	push   $0x18a
f010170a:	68 5b 55 10 f0       	push   $0xf010555b
f010170f:	e8 95 e9 ff ff       	call   f01000a9 <_panic>
f0101714:	89 cf                	mov    %ecx,%edi
	assert(pa % PGSIZE == 0);
f0101716:	a9 ff 0f 00 00       	test   $0xfff,%eax
f010171b:	74 19                	je     f0101736 <boot_map_region+0x52>
f010171d:	68 83 57 10 f0       	push   $0xf0105783
f0101722:	68 7a 55 10 f0       	push   $0xf010557a
f0101727:	68 8b 01 00 00       	push   $0x18b
f010172c:	68 5b 55 10 f0       	push   $0xf010555b
f0101731:	e8 73 e9 ff ff       	call   f01000a9 <_panic>
	assert(size % PGSIZE == 0);	
f0101736:	f7 c1 ff 0f 00 00    	test   $0xfff,%ecx
f010173c:	74 3d                	je     f010177b <boot_map_region+0x97>
f010173e:	68 94 57 10 f0       	push   $0xf0105794
f0101743:	68 7a 55 10 f0       	push   $0xf010557a
f0101748:	68 8c 01 00 00       	push   $0x18c
f010174d:	68 5b 55 10 f0       	push   $0xf010555b
f0101752:	e8 52 e9 ff ff       	call   f01000a9 <_panic>
	//uint32_t cant_iteraciones = size/PGSIZE;
	//for (int i=0;i<cant_iteraciones;i++){//al ser iteraciones fijas no hay problema de overflow
	//physaddr_t pa_inicial = pa;	
	#ifndef TP1_PSE
		while(size){			
			pte_t* pte_addr = pgdir_walk(pgdir,(void*)va,true);
f0101757:	83 ec 04             	sub    $0x4,%esp
f010175a:	6a 01                	push   $0x1
f010175c:	53                   	push   %ebx
f010175d:	ff 75 e0             	pushl  -0x20(%ebp)
f0101760:	e8 e0 fe ff ff       	call   f0101645 <pgdir_walk>
			*pte_addr = pa | perm | PTE_P;
f0101765:	0b 75 dc             	or     -0x24(%ebp),%esi
f0101768:	89 30                	mov    %esi,(%eax)
			size-=PGSIZE;		
f010176a:	81 ef 00 10 00 00    	sub    $0x1000,%edi
			//incremento
			va+=PGSIZE;
f0101770:	81 c3 00 10 00 00    	add    $0x1000,%ebx
f0101776:	83 c4 10             	add    $0x10,%esp
f0101779:	eb 10                	jmp    f010178b <boot_map_region+0xa7>
f010177b:	89 d3                	mov    %edx,%ebx
f010177d:	29 d0                	sub    %edx,%eax
f010177f:	89 45 e4             	mov    %eax,-0x1c(%ebp)
	//for (int i=0;i<cant_iteraciones;i++){//al ser iteraciones fijas no hay problema de overflow
	//physaddr_t pa_inicial = pa;	
	#ifndef TP1_PSE
		while(size){			
			pte_t* pte_addr = pgdir_walk(pgdir,(void*)va,true);
			*pte_addr = pa | perm | PTE_P;
f0101782:	8b 45 0c             	mov    0xc(%ebp),%eax
f0101785:	83 c8 01             	or     $0x1,%eax
f0101788:	89 45 dc             	mov    %eax,-0x24(%ebp)
f010178b:	8b 45 e4             	mov    -0x1c(%ebp),%eax
f010178e:	8d 34 18             	lea    (%eax,%ebx,1),%esi

	//uint32_t cant_iteraciones = size/PGSIZE;
	//for (int i=0;i<cant_iteraciones;i++){//al ser iteraciones fijas no hay problema de overflow
	//physaddr_t pa_inicial = pa;	
	#ifndef TP1_PSE
		while(size){			
f0101791:	85 ff                	test   %edi,%edi
f0101793:	75 c2                	jne    f0101757 <boot_map_region+0x73>
				va+=PGSIZE;
				pa+=PGSIZE;
			}
		}
	#endif
}
f0101795:	8d 65 f4             	lea    -0xc(%ebp),%esp
f0101798:	5b                   	pop    %ebx
f0101799:	5e                   	pop    %esi
f010179a:	5f                   	pop    %edi
f010179b:	5d                   	pop    %ebp
f010179c:	c3                   	ret    

f010179d <page_lookup>:
//
// Hint: the TA solution uses pgdir_walk and pa2page.
//
struct PageInfo *
page_lookup(pde_t *pgdir, void *va, pte_t **pte_store)
{
f010179d:	55                   	push   %ebp
f010179e:	89 e5                	mov    %esp,%ebp
f01017a0:	53                   	push   %ebx
f01017a1:	83 ec 08             	sub    $0x8,%esp
f01017a4:	8b 5d 10             	mov    0x10(%ebp),%ebx
	pte_t* pte_addr = pgdir_walk(pgdir,va,false);
f01017a7:	6a 00                	push   $0x0
f01017a9:	ff 75 0c             	pushl  0xc(%ebp)
f01017ac:	ff 75 08             	pushl  0x8(%ebp)
f01017af:	e8 91 fe ff ff       	call   f0101645 <pgdir_walk>
	if (pte_store) *pte_store = pte_addr;
f01017b4:	83 c4 10             	add    $0x10,%esp
f01017b7:	85 db                	test   %ebx,%ebx
f01017b9:	74 02                	je     f01017bd <page_lookup+0x20>
f01017bb:	89 03                	mov    %eax,(%ebx)
	if (!pte_addr) return NULL;		//no recuerdo si era lazy checking o no, por las dudas dejo asi
f01017bd:	85 c0                	test   %eax,%eax
f01017bf:	74 1a                	je     f01017db <page_lookup+0x3e>
	if (!(*pte_addr & PTE_P)) return NULL;
f01017c1:	8b 10                	mov    (%eax),%edx
f01017c3:	b8 00 00 00 00       	mov    $0x0,%eax
f01017c8:	f6 c2 01             	test   $0x1,%dl
f01017cb:	74 13                	je     f01017e0 <page_lookup+0x43>
	physaddr_t pageaddr = PTE_ADDR(*pte_addr);
	return pa2page(pageaddr);
f01017cd:	89 d0                	mov    %edx,%eax
f01017cf:	25 00 f0 ff ff       	and    $0xfffff000,%eax
f01017d4:	e8 37 f9 ff ff       	call   f0101110 <pa2page>
f01017d9:	eb 05                	jmp    f01017e0 <page_lookup+0x43>
struct PageInfo *
page_lookup(pde_t *pgdir, void *va, pte_t **pte_store)
{
	pte_t* pte_addr = pgdir_walk(pgdir,va,false);
	if (pte_store) *pte_store = pte_addr;
	if (!pte_addr) return NULL;		//no recuerdo si era lazy checking o no, por las dudas dejo asi
f01017db:	b8 00 00 00 00       	mov    $0x0,%eax
	if (!(*pte_addr & PTE_P)) return NULL;
	physaddr_t pageaddr = PTE_ADDR(*pte_addr);
	return pa2page(pageaddr);
}
f01017e0:	8b 5d fc             	mov    -0x4(%ebp),%ebx
f01017e3:	c9                   	leave  
f01017e4:	c3                   	ret    

f01017e5 <tlb_invalidate>:
// Invalidate a TLB entry, but only if the page tables being
// edited are the ones currently in use by the processor.
//
void
tlb_invalidate(pde_t *pgdir, void *va)
{
f01017e5:	55                   	push   %ebp
f01017e6:	89 e5                	mov    %esp,%ebp
	// Flush the entry only if we're modifying the current address space.
	// For now, there is only one address space, so always invalidate.
	invlpg(va);
f01017e8:	8b 45 0c             	mov    0xc(%ebp),%eax
f01017eb:	e8 2d f2 ff ff       	call   f0100a1d <invlpg>
}
f01017f0:	5d                   	pop    %ebp
f01017f1:	c3                   	ret    

f01017f2 <page_remove>:
// Hint: The TA solution is implemented using page_lookup,
// 	tlb_invalidate, and page_decref.
//
void
page_remove(pde_t *pgdir, void *va)
{
f01017f2:	55                   	push   %ebp
f01017f3:	89 e5                	mov    %esp,%ebp
f01017f5:	56                   	push   %esi
f01017f6:	53                   	push   %ebx
f01017f7:	83 ec 14             	sub    $0x14,%esp
f01017fa:	8b 5d 08             	mov    0x8(%ebp),%ebx
f01017fd:	8b 75 0c             	mov    0xc(%ebp),%esi
	pte_t* pte_addr;
	struct PageInfo* page_ptr = page_lookup(pgdir,va,&pte_addr);
f0101800:	8d 45 f4             	lea    -0xc(%ebp),%eax
f0101803:	50                   	push   %eax
f0101804:	56                   	push   %esi
f0101805:	53                   	push   %ebx
f0101806:	e8 92 ff ff ff       	call   f010179d <page_lookup>
	if (!page_ptr) return;
f010180b:	83 c4 10             	add    $0x10,%esp
f010180e:	85 c0                	test   %eax,%eax
f0101810:	74 1f                	je     f0101831 <page_remove+0x3f>
	page_decref(page_ptr);
f0101812:	83 ec 0c             	sub    $0xc,%esp
f0101815:	50                   	push   %eax
f0101816:	e8 03 fe ff ff       	call   f010161e <page_decref>
	*pte_addr = 0;
f010181b:	8b 45 f4             	mov    -0xc(%ebp),%eax
f010181e:	c7 00 00 00 00 00    	movl   $0x0,(%eax)
	tlb_invalidate(pgdir,va);
f0101824:	83 c4 08             	add    $0x8,%esp
f0101827:	56                   	push   %esi
f0101828:	53                   	push   %ebx
f0101829:	e8 b7 ff ff ff       	call   f01017e5 <tlb_invalidate>
f010182e:	83 c4 10             	add    $0x10,%esp
}
f0101831:	8d 65 f8             	lea    -0x8(%ebp),%esp
f0101834:	5b                   	pop    %ebx
f0101835:	5e                   	pop    %esi
f0101836:	5d                   	pop    %ebp
f0101837:	c3                   	ret    

f0101838 <page_insert>:
// Hint: The TA solution is implemented using pgdir_walk, page_remove,
// and page2pa.
//
int
page_insert(pde_t *pgdir, struct PageInfo *pp, void *va, int perm)
{
f0101838:	55                   	push   %ebp
f0101839:	89 e5                	mov    %esp,%ebp
f010183b:	57                   	push   %edi
f010183c:	56                   	push   %esi
f010183d:	53                   	push   %ebx
f010183e:	83 ec 10             	sub    $0x10,%esp
f0101841:	8b 5d 0c             	mov    0xc(%ebp),%ebx
f0101844:	8b 7d 10             	mov    0x10(%ebp),%edi
	pte_t* pte_addr = pgdir_walk(pgdir,va,true);//entra a la PT, si no habia la crea
f0101847:	6a 01                	push   $0x1
f0101849:	57                   	push   %edi
f010184a:	ff 75 08             	pushl  0x8(%ebp)
f010184d:	e8 f3 fd ff ff       	call   f0101645 <pgdir_walk>
	if (!pte_addr) return -E_NO_MEM;	//solo NULL si no habia y no la pudo crear
f0101852:	83 c4 10             	add    $0x10,%esp
f0101855:	85 c0                	test   %eax,%eax
f0101857:	74 33                	je     f010188c <page_insert+0x54>
f0101859:	89 c6                	mov    %eax,%esi
	//a partir de aca hay pte_addr valida
	pp->pp_ref++;
f010185b:	66 83 43 04 01       	addw   $0x1,0x4(%ebx)
	if (*pte_addr & PTE_P) page_remove(pgdir,va);
f0101860:	f6 00 01             	testb  $0x1,(%eax)
f0101863:	74 0f                	je     f0101874 <page_insert+0x3c>
f0101865:	83 ec 08             	sub    $0x8,%esp
f0101868:	57                   	push   %edi
f0101869:	ff 75 08             	pushl  0x8(%ebp)
f010186c:	e8 81 ff ff ff       	call   f01017f2 <page_remove>
f0101871:	83 c4 10             	add    $0x10,%esp
	*pte_addr = page2pa(pp) | perm | PTE_P;
f0101874:	89 d8                	mov    %ebx,%eax
f0101876:	e8 c2 f1 ff ff       	call   f0100a3d <page2pa>
f010187b:	8b 55 14             	mov    0x14(%ebp),%edx
f010187e:	83 ca 01             	or     $0x1,%edx
f0101881:	09 d0                	or     %edx,%eax
f0101883:	89 06                	mov    %eax,(%esi)
	return 0;
f0101885:	b8 00 00 00 00       	mov    $0x0,%eax
f010188a:	eb 05                	jmp    f0101891 <page_insert+0x59>
//
int
page_insert(pde_t *pgdir, struct PageInfo *pp, void *va, int perm)
{
	pte_t* pte_addr = pgdir_walk(pgdir,va,true);//entra a la PT, si no habia la crea
	if (!pte_addr) return -E_NO_MEM;	//solo NULL si no habia y no la pudo crear
f010188c:	b8 fc ff ff ff       	mov    $0xfffffffc,%eax
	//a partir de aca hay pte_addr valida
	pp->pp_ref++;
	if (*pte_addr & PTE_P) page_remove(pgdir,va);
	*pte_addr = page2pa(pp) | perm | PTE_P;
	return 0;
}
f0101891:	8d 65 f4             	lea    -0xc(%ebp),%esp
f0101894:	5b                   	pop    %ebx
f0101895:	5e                   	pop    %esi
f0101896:	5f                   	pop    %edi
f0101897:	5d                   	pop    %ebp
f0101898:	c3                   	ret    

f0101899 <check_page>:


// check page_insert, page_remove, &c
static void
check_page(void)
{
f0101899:	55                   	push   %ebp
f010189a:	89 e5                	mov    %esp,%ebp
f010189c:	57                   	push   %edi
f010189d:	56                   	push   %esi
f010189e:	53                   	push   %ebx
f010189f:	83 ec 38             	sub    $0x38,%esp
	int i;
	extern pde_t entry_pgdir[];

	// should be able to allocate three pages
	pp0 = pp1 = pp2 = 0;
	assert((pp0 = page_alloc(0)));
f01018a2:	6a 00                	push   $0x0
f01018a4:	e8 11 f9 ff ff       	call   f01011ba <page_alloc>
f01018a9:	89 45 d4             	mov    %eax,-0x2c(%ebp)
f01018ac:	83 c4 10             	add    $0x10,%esp
f01018af:	85 c0                	test   %eax,%eax
f01018b1:	75 19                	jne    f01018cc <check_page+0x33>
f01018b3:	68 75 56 10 f0       	push   $0xf0105675
f01018b8:	68 7a 55 10 f0       	push   $0xf010557a
f01018bd:	68 46 03 00 00       	push   $0x346
f01018c2:	68 5b 55 10 f0       	push   $0xf010555b
f01018c7:	e8 dd e7 ff ff       	call   f01000a9 <_panic>
	assert((pp1 = page_alloc(0)));
f01018cc:	83 ec 0c             	sub    $0xc,%esp
f01018cf:	6a 00                	push   $0x0
f01018d1:	e8 e4 f8 ff ff       	call   f01011ba <page_alloc>
f01018d6:	89 c6                	mov    %eax,%esi
f01018d8:	83 c4 10             	add    $0x10,%esp
f01018db:	85 c0                	test   %eax,%eax
f01018dd:	75 19                	jne    f01018f8 <check_page+0x5f>
f01018df:	68 8b 56 10 f0       	push   $0xf010568b
f01018e4:	68 7a 55 10 f0       	push   $0xf010557a
f01018e9:	68 47 03 00 00       	push   $0x347
f01018ee:	68 5b 55 10 f0       	push   $0xf010555b
f01018f3:	e8 b1 e7 ff ff       	call   f01000a9 <_panic>
	assert((pp2 = page_alloc(0)));
f01018f8:	83 ec 0c             	sub    $0xc,%esp
f01018fb:	6a 00                	push   $0x0
f01018fd:	e8 b8 f8 ff ff       	call   f01011ba <page_alloc>
f0101902:	89 c3                	mov    %eax,%ebx
f0101904:	83 c4 10             	add    $0x10,%esp
f0101907:	85 c0                	test   %eax,%eax
f0101909:	75 19                	jne    f0101924 <check_page+0x8b>
f010190b:	68 a1 56 10 f0       	push   $0xf01056a1
f0101910:	68 7a 55 10 f0       	push   $0xf010557a
f0101915:	68 48 03 00 00       	push   $0x348
f010191a:	68 5b 55 10 f0       	push   $0xf010555b
f010191f:	e8 85 e7 ff ff       	call   f01000a9 <_panic>

	assert(pp0);
	assert(pp1 && pp1 != pp0);
f0101924:	39 75 d4             	cmp    %esi,-0x2c(%ebp)
f0101927:	75 19                	jne    f0101942 <check_page+0xa9>
f0101929:	68 b7 56 10 f0       	push   $0xf01056b7
f010192e:	68 7a 55 10 f0       	push   $0xf010557a
f0101933:	68 4b 03 00 00       	push   $0x34b
f0101938:	68 5b 55 10 f0       	push   $0xf010555b
f010193d:	e8 67 e7 ff ff       	call   f01000a9 <_panic>
	assert(pp2 && pp2 != pp1 && pp2 != pp0);
f0101942:	39 c6                	cmp    %eax,%esi
f0101944:	74 05                	je     f010194b <check_page+0xb2>
f0101946:	39 45 d4             	cmp    %eax,-0x2c(%ebp)
f0101949:	75 19                	jne    f0101964 <check_page+0xcb>
f010194b:	68 20 50 10 f0       	push   $0xf0105020
f0101950:	68 7a 55 10 f0       	push   $0xf010557a
f0101955:	68 4c 03 00 00       	push   $0x34c
f010195a:	68 5b 55 10 f0       	push   $0xf010555b
f010195f:	e8 45 e7 ff ff       	call   f01000a9 <_panic>

	// temporarily steal the rest of the free pages
	fl = page_free_list;
f0101964:	a1 c0 3c 19 f0       	mov    0xf0193cc0,%eax
f0101969:	89 45 cc             	mov    %eax,-0x34(%ebp)
	page_free_list = 0;
f010196c:	c7 05 c0 3c 19 f0 00 	movl   $0x0,0xf0193cc0
f0101973:	00 00 00 

	// should be no free memory
	assert(!page_alloc(0));
f0101976:	83 ec 0c             	sub    $0xc,%esp
f0101979:	6a 00                	push   $0x0
f010197b:	e8 3a f8 ff ff       	call   f01011ba <page_alloc>
f0101980:	83 c4 10             	add    $0x10,%esp
f0101983:	85 c0                	test   %eax,%eax
f0101985:	74 19                	je     f01019a0 <check_page+0x107>
f0101987:	68 20 57 10 f0       	push   $0xf0105720
f010198c:	68 7a 55 10 f0       	push   $0xf010557a
f0101991:	68 53 03 00 00       	push   $0x353
f0101996:	68 5b 55 10 f0       	push   $0xf010555b
f010199b:	e8 09 e7 ff ff       	call   f01000a9 <_panic>

	// there is no page allocated at address 0
	assert(page_lookup(kern_pgdir, (void *) 0x0, &ptep) == NULL);
f01019a0:	83 ec 04             	sub    $0x4,%esp
f01019a3:	8d 45 e4             	lea    -0x1c(%ebp),%eax
f01019a6:	50                   	push   %eax
f01019a7:	6a 00                	push   $0x0
f01019a9:	ff 35 88 59 19 f0    	pushl  0xf0195988
f01019af:	e8 e9 fd ff ff       	call   f010179d <page_lookup>
f01019b4:	83 c4 10             	add    $0x10,%esp
f01019b7:	85 c0                	test   %eax,%eax
f01019b9:	74 19                	je     f01019d4 <check_page+0x13b>
f01019bb:	68 60 50 10 f0       	push   $0xf0105060
f01019c0:	68 7a 55 10 f0       	push   $0xf010557a
f01019c5:	68 56 03 00 00       	push   $0x356
f01019ca:	68 5b 55 10 f0       	push   $0xf010555b
f01019cf:	e8 d5 e6 ff ff       	call   f01000a9 <_panic>

	// there is no free memory, so we can't allocate a page table
	assert(page_insert(kern_pgdir, pp1, 0x0, PTE_W) < 0);
f01019d4:	6a 02                	push   $0x2
f01019d6:	6a 00                	push   $0x0
f01019d8:	56                   	push   %esi
f01019d9:	ff 35 88 59 19 f0    	pushl  0xf0195988
f01019df:	e8 54 fe ff ff       	call   f0101838 <page_insert>
f01019e4:	83 c4 10             	add    $0x10,%esp
f01019e7:	85 c0                	test   %eax,%eax
f01019e9:	78 19                	js     f0101a04 <check_page+0x16b>
f01019eb:	68 98 50 10 f0       	push   $0xf0105098
f01019f0:	68 7a 55 10 f0       	push   $0xf010557a
f01019f5:	68 59 03 00 00       	push   $0x359
f01019fa:	68 5b 55 10 f0       	push   $0xf010555b
f01019ff:	e8 a5 e6 ff ff       	call   f01000a9 <_panic>

	// free pp0 and try again: pp0 should be used for page table
	page_free(pp0);
f0101a04:	83 ec 0c             	sub    $0xc,%esp
f0101a07:	ff 75 d4             	pushl  -0x2c(%ebp)
f0101a0a:	e8 f0 f7 ff ff       	call   f01011ff <page_free>
	assert(page_insert(kern_pgdir, pp1, 0x0, PTE_W) == 0);
f0101a0f:	6a 02                	push   $0x2
f0101a11:	6a 00                	push   $0x0
f0101a13:	56                   	push   %esi
f0101a14:	ff 35 88 59 19 f0    	pushl  0xf0195988
f0101a1a:	e8 19 fe ff ff       	call   f0101838 <page_insert>
f0101a1f:	83 c4 20             	add    $0x20,%esp
f0101a22:	85 c0                	test   %eax,%eax
f0101a24:	74 19                	je     f0101a3f <check_page+0x1a6>
f0101a26:	68 c8 50 10 f0       	push   $0xf01050c8
f0101a2b:	68 7a 55 10 f0       	push   $0xf010557a
f0101a30:	68 5d 03 00 00       	push   $0x35d
f0101a35:	68 5b 55 10 f0       	push   $0xf010555b
f0101a3a:	e8 6a e6 ff ff       	call   f01000a9 <_panic>
	assert(PTE_ADDR(kern_pgdir[0]) == page2pa(pp0));
f0101a3f:	8b 3d 88 59 19 f0    	mov    0xf0195988,%edi
f0101a45:	8b 45 d4             	mov    -0x2c(%ebp),%eax
f0101a48:	e8 f0 ef ff ff       	call   f0100a3d <page2pa>
f0101a4d:	8b 17                	mov    (%edi),%edx
f0101a4f:	81 e2 00 f0 ff ff    	and    $0xfffff000,%edx
f0101a55:	39 c2                	cmp    %eax,%edx
f0101a57:	74 19                	je     f0101a72 <check_page+0x1d9>
f0101a59:	68 f8 50 10 f0       	push   $0xf01050f8
f0101a5e:	68 7a 55 10 f0       	push   $0xf010557a
f0101a63:	68 5e 03 00 00       	push   $0x35e
f0101a68:	68 5b 55 10 f0       	push   $0xf010555b
f0101a6d:	e8 37 e6 ff ff       	call   f01000a9 <_panic>
	assert(check_va2pa(kern_pgdir, 0x0) == page2pa(pp1));
f0101a72:	ba 00 00 00 00       	mov    $0x0,%edx
f0101a77:	89 f8                	mov    %edi,%eax
f0101a79:	e8 a9 f0 ff ff       	call   f0100b27 <check_va2pa>
f0101a7e:	89 45 d0             	mov    %eax,-0x30(%ebp)
f0101a81:	89 f0                	mov    %esi,%eax
f0101a83:	e8 b5 ef ff ff       	call   f0100a3d <page2pa>
f0101a88:	39 45 d0             	cmp    %eax,-0x30(%ebp)
f0101a8b:	74 19                	je     f0101aa6 <check_page+0x20d>
f0101a8d:	68 20 51 10 f0       	push   $0xf0105120
f0101a92:	68 7a 55 10 f0       	push   $0xf010557a
f0101a97:	68 5f 03 00 00       	push   $0x35f
f0101a9c:	68 5b 55 10 f0       	push   $0xf010555b
f0101aa1:	e8 03 e6 ff ff       	call   f01000a9 <_panic>
	assert(pp1->pp_ref == 1);
f0101aa6:	66 83 7e 04 01       	cmpw   $0x1,0x4(%esi)
f0101aab:	74 19                	je     f0101ac6 <check_page+0x22d>
f0101aad:	68 a7 57 10 f0       	push   $0xf01057a7
f0101ab2:	68 7a 55 10 f0       	push   $0xf010557a
f0101ab7:	68 60 03 00 00       	push   $0x360
f0101abc:	68 5b 55 10 f0       	push   $0xf010555b
f0101ac1:	e8 e3 e5 ff ff       	call   f01000a9 <_panic>
	assert(pp0->pp_ref == 1);
f0101ac6:	8b 45 d4             	mov    -0x2c(%ebp),%eax
f0101ac9:	66 83 78 04 01       	cmpw   $0x1,0x4(%eax)
f0101ace:	74 19                	je     f0101ae9 <check_page+0x250>
f0101ad0:	68 b8 57 10 f0       	push   $0xf01057b8
f0101ad5:	68 7a 55 10 f0       	push   $0xf010557a
f0101ada:	68 61 03 00 00       	push   $0x361
f0101adf:	68 5b 55 10 f0       	push   $0xf010555b
f0101ae4:	e8 c0 e5 ff ff       	call   f01000a9 <_panic>
	// should be able to map pp2 at PGSIZE because pp0 is already allocated for page table
	assert(page_insert(kern_pgdir, pp2, (void*) PGSIZE, PTE_W) == 0);
f0101ae9:	6a 02                	push   $0x2
f0101aeb:	68 00 10 00 00       	push   $0x1000
f0101af0:	53                   	push   %ebx
f0101af1:	57                   	push   %edi
f0101af2:	e8 41 fd ff ff       	call   f0101838 <page_insert>
f0101af7:	83 c4 10             	add    $0x10,%esp
f0101afa:	85 c0                	test   %eax,%eax
f0101afc:	74 19                	je     f0101b17 <check_page+0x27e>
f0101afe:	68 50 51 10 f0       	push   $0xf0105150
f0101b03:	68 7a 55 10 f0       	push   $0xf010557a
f0101b08:	68 63 03 00 00       	push   $0x363
f0101b0d:	68 5b 55 10 f0       	push   $0xf010555b
f0101b12:	e8 92 e5 ff ff       	call   f01000a9 <_panic>
	assert(check_va2pa(kern_pgdir, PGSIZE) == page2pa(pp2));
f0101b17:	ba 00 10 00 00       	mov    $0x1000,%edx
f0101b1c:	a1 88 59 19 f0       	mov    0xf0195988,%eax
f0101b21:	e8 01 f0 ff ff       	call   f0100b27 <check_va2pa>
f0101b26:	89 c7                	mov    %eax,%edi
f0101b28:	89 d8                	mov    %ebx,%eax
f0101b2a:	e8 0e ef ff ff       	call   f0100a3d <page2pa>
f0101b2f:	39 c7                	cmp    %eax,%edi
f0101b31:	74 19                	je     f0101b4c <check_page+0x2b3>
f0101b33:	68 8c 51 10 f0       	push   $0xf010518c
f0101b38:	68 7a 55 10 f0       	push   $0xf010557a
f0101b3d:	68 64 03 00 00       	push   $0x364
f0101b42:	68 5b 55 10 f0       	push   $0xf010555b
f0101b47:	e8 5d e5 ff ff       	call   f01000a9 <_panic>
	assert(pp2->pp_ref == 1);
f0101b4c:	66 83 7b 04 01       	cmpw   $0x1,0x4(%ebx)
f0101b51:	74 19                	je     f0101b6c <check_page+0x2d3>
f0101b53:	68 c9 57 10 f0       	push   $0xf01057c9
f0101b58:	68 7a 55 10 f0       	push   $0xf010557a
f0101b5d:	68 65 03 00 00       	push   $0x365
f0101b62:	68 5b 55 10 f0       	push   $0xf010555b
f0101b67:	e8 3d e5 ff ff       	call   f01000a9 <_panic>

	// should be no free memory
	assert(!page_alloc(0));
f0101b6c:	83 ec 0c             	sub    $0xc,%esp
f0101b6f:	6a 00                	push   $0x0
f0101b71:	e8 44 f6 ff ff       	call   f01011ba <page_alloc>
f0101b76:	83 c4 10             	add    $0x10,%esp
f0101b79:	85 c0                	test   %eax,%eax
f0101b7b:	74 19                	je     f0101b96 <check_page+0x2fd>
f0101b7d:	68 20 57 10 f0       	push   $0xf0105720
f0101b82:	68 7a 55 10 f0       	push   $0xf010557a
f0101b87:	68 68 03 00 00       	push   $0x368
f0101b8c:	68 5b 55 10 f0       	push   $0xf010555b
f0101b91:	e8 13 e5 ff ff       	call   f01000a9 <_panic>

	// should be able to map pp2 at PGSIZE because it's already there
	assert(page_insert(kern_pgdir, pp2, (void*) PGSIZE, PTE_W) == 0);
f0101b96:	6a 02                	push   $0x2
f0101b98:	68 00 10 00 00       	push   $0x1000
f0101b9d:	53                   	push   %ebx
f0101b9e:	ff 35 88 59 19 f0    	pushl  0xf0195988
f0101ba4:	e8 8f fc ff ff       	call   f0101838 <page_insert>
f0101ba9:	83 c4 10             	add    $0x10,%esp
f0101bac:	85 c0                	test   %eax,%eax
f0101bae:	74 19                	je     f0101bc9 <check_page+0x330>
f0101bb0:	68 50 51 10 f0       	push   $0xf0105150
f0101bb5:	68 7a 55 10 f0       	push   $0xf010557a
f0101bba:	68 6b 03 00 00       	push   $0x36b
f0101bbf:	68 5b 55 10 f0       	push   $0xf010555b
f0101bc4:	e8 e0 e4 ff ff       	call   f01000a9 <_panic>
	assert(check_va2pa(kern_pgdir, PGSIZE) == page2pa(pp2));
f0101bc9:	ba 00 10 00 00       	mov    $0x1000,%edx
f0101bce:	a1 88 59 19 f0       	mov    0xf0195988,%eax
f0101bd3:	e8 4f ef ff ff       	call   f0100b27 <check_va2pa>
f0101bd8:	89 c7                	mov    %eax,%edi
f0101bda:	89 d8                	mov    %ebx,%eax
f0101bdc:	e8 5c ee ff ff       	call   f0100a3d <page2pa>
f0101be1:	39 c7                	cmp    %eax,%edi
f0101be3:	74 19                	je     f0101bfe <check_page+0x365>
f0101be5:	68 8c 51 10 f0       	push   $0xf010518c
f0101bea:	68 7a 55 10 f0       	push   $0xf010557a
f0101bef:	68 6c 03 00 00       	push   $0x36c
f0101bf4:	68 5b 55 10 f0       	push   $0xf010555b
f0101bf9:	e8 ab e4 ff ff       	call   f01000a9 <_panic>
	assert(pp2->pp_ref == 1);
f0101bfe:	66 83 7b 04 01       	cmpw   $0x1,0x4(%ebx)
f0101c03:	74 19                	je     f0101c1e <check_page+0x385>
f0101c05:	68 c9 57 10 f0       	push   $0xf01057c9
f0101c0a:	68 7a 55 10 f0       	push   $0xf010557a
f0101c0f:	68 6d 03 00 00       	push   $0x36d
f0101c14:	68 5b 55 10 f0       	push   $0xf010555b
f0101c19:	e8 8b e4 ff ff       	call   f01000a9 <_panic>

	// pp2 should NOT be on the free list
	// could happen in ref counts are handled sloppily in page_insert
	assert(!page_alloc(0));
f0101c1e:	83 ec 0c             	sub    $0xc,%esp
f0101c21:	6a 00                	push   $0x0
f0101c23:	e8 92 f5 ff ff       	call   f01011ba <page_alloc>
f0101c28:	83 c4 10             	add    $0x10,%esp
f0101c2b:	85 c0                	test   %eax,%eax
f0101c2d:	74 19                	je     f0101c48 <check_page+0x3af>
f0101c2f:	68 20 57 10 f0       	push   $0xf0105720
f0101c34:	68 7a 55 10 f0       	push   $0xf010557a
f0101c39:	68 71 03 00 00       	push   $0x371
f0101c3e:	68 5b 55 10 f0       	push   $0xf010555b
f0101c43:	e8 61 e4 ff ff       	call   f01000a9 <_panic>

	// check that pgdir_walk returns a pointer to the pte
	ptep = (pte_t *) KADDR(PTE_ADDR(kern_pgdir[PDX(PGSIZE)]));
f0101c48:	8b 3d 88 59 19 f0    	mov    0xf0195988,%edi
f0101c4e:	8b 0f                	mov    (%edi),%ecx
f0101c50:	81 e1 00 f0 ff ff    	and    $0xfffff000,%ecx
f0101c56:	ba 74 03 00 00       	mov    $0x374,%edx
f0101c5b:	b8 5b 55 10 f0       	mov    $0xf010555b,%eax
f0101c60:	e8 78 ee ff ff       	call   f0100add <_kaddr>
f0101c65:	89 45 e4             	mov    %eax,-0x1c(%ebp)
	assert(pgdir_walk(kern_pgdir, (void*)PGSIZE, 0) == ptep+PTX(PGSIZE));
f0101c68:	83 ec 04             	sub    $0x4,%esp
f0101c6b:	6a 00                	push   $0x0
f0101c6d:	68 00 10 00 00       	push   $0x1000
f0101c72:	57                   	push   %edi
f0101c73:	e8 cd f9 ff ff       	call   f0101645 <pgdir_walk>
f0101c78:	8b 4d e4             	mov    -0x1c(%ebp),%ecx
f0101c7b:	8d 51 04             	lea    0x4(%ecx),%edx
f0101c7e:	83 c4 10             	add    $0x10,%esp
f0101c81:	39 d0                	cmp    %edx,%eax
f0101c83:	74 19                	je     f0101c9e <check_page+0x405>
f0101c85:	68 bc 51 10 f0       	push   $0xf01051bc
f0101c8a:	68 7a 55 10 f0       	push   $0xf010557a
f0101c8f:	68 75 03 00 00       	push   $0x375
f0101c94:	68 5b 55 10 f0       	push   $0xf010555b
f0101c99:	e8 0b e4 ff ff       	call   f01000a9 <_panic>

	// should be able to change permissions too.
	assert(page_insert(kern_pgdir, pp2, (void*) PGSIZE, PTE_W|PTE_U) == 0);
f0101c9e:	6a 06                	push   $0x6
f0101ca0:	68 00 10 00 00       	push   $0x1000
f0101ca5:	53                   	push   %ebx
f0101ca6:	ff 35 88 59 19 f0    	pushl  0xf0195988
f0101cac:	e8 87 fb ff ff       	call   f0101838 <page_insert>
f0101cb1:	83 c4 10             	add    $0x10,%esp
f0101cb4:	85 c0                	test   %eax,%eax
f0101cb6:	74 19                	je     f0101cd1 <check_page+0x438>
f0101cb8:	68 fc 51 10 f0       	push   $0xf01051fc
f0101cbd:	68 7a 55 10 f0       	push   $0xf010557a
f0101cc2:	68 78 03 00 00       	push   $0x378
f0101cc7:	68 5b 55 10 f0       	push   $0xf010555b
f0101ccc:	e8 d8 e3 ff ff       	call   f01000a9 <_panic>
	assert(check_va2pa(kern_pgdir, PGSIZE) == page2pa(pp2));
f0101cd1:	8b 3d 88 59 19 f0    	mov    0xf0195988,%edi
f0101cd7:	ba 00 10 00 00       	mov    $0x1000,%edx
f0101cdc:	89 f8                	mov    %edi,%eax
f0101cde:	e8 44 ee ff ff       	call   f0100b27 <check_va2pa>
f0101ce3:	89 45 d0             	mov    %eax,-0x30(%ebp)
f0101ce6:	89 d8                	mov    %ebx,%eax
f0101ce8:	e8 50 ed ff ff       	call   f0100a3d <page2pa>
f0101ced:	39 45 d0             	cmp    %eax,-0x30(%ebp)
f0101cf0:	74 19                	je     f0101d0b <check_page+0x472>
f0101cf2:	68 8c 51 10 f0       	push   $0xf010518c
f0101cf7:	68 7a 55 10 f0       	push   $0xf010557a
f0101cfc:	68 79 03 00 00       	push   $0x379
f0101d01:	68 5b 55 10 f0       	push   $0xf010555b
f0101d06:	e8 9e e3 ff ff       	call   f01000a9 <_panic>
	assert(pp2->pp_ref == 1);
f0101d0b:	66 83 7b 04 01       	cmpw   $0x1,0x4(%ebx)
f0101d10:	74 19                	je     f0101d2b <check_page+0x492>
f0101d12:	68 c9 57 10 f0       	push   $0xf01057c9
f0101d17:	68 7a 55 10 f0       	push   $0xf010557a
f0101d1c:	68 7a 03 00 00       	push   $0x37a
f0101d21:	68 5b 55 10 f0       	push   $0xf010555b
f0101d26:	e8 7e e3 ff ff       	call   f01000a9 <_panic>
	assert(*pgdir_walk(kern_pgdir, (void*) PGSIZE, 0) & PTE_U);
f0101d2b:	83 ec 04             	sub    $0x4,%esp
f0101d2e:	6a 00                	push   $0x0
f0101d30:	68 00 10 00 00       	push   $0x1000
f0101d35:	57                   	push   %edi
f0101d36:	e8 0a f9 ff ff       	call   f0101645 <pgdir_walk>
f0101d3b:	83 c4 10             	add    $0x10,%esp
f0101d3e:	f6 00 04             	testb  $0x4,(%eax)
f0101d41:	75 19                	jne    f0101d5c <check_page+0x4c3>
f0101d43:	68 3c 52 10 f0       	push   $0xf010523c
f0101d48:	68 7a 55 10 f0       	push   $0xf010557a
f0101d4d:	68 7b 03 00 00       	push   $0x37b
f0101d52:	68 5b 55 10 f0       	push   $0xf010555b
f0101d57:	e8 4d e3 ff ff       	call   f01000a9 <_panic>
	assert(kern_pgdir[0] & PTE_U);
f0101d5c:	a1 88 59 19 f0       	mov    0xf0195988,%eax
f0101d61:	f6 00 04             	testb  $0x4,(%eax)
f0101d64:	75 19                	jne    f0101d7f <check_page+0x4e6>
f0101d66:	68 da 57 10 f0       	push   $0xf01057da
f0101d6b:	68 7a 55 10 f0       	push   $0xf010557a
f0101d70:	68 7c 03 00 00       	push   $0x37c
f0101d75:	68 5b 55 10 f0       	push   $0xf010555b
f0101d7a:	e8 2a e3 ff ff       	call   f01000a9 <_panic>

	// should be able to remap with fewer permissions
	assert(page_insert(kern_pgdir, pp2, (void*) PGSIZE, PTE_W) == 0);
f0101d7f:	6a 02                	push   $0x2
f0101d81:	68 00 10 00 00       	push   $0x1000
f0101d86:	53                   	push   %ebx
f0101d87:	50                   	push   %eax
f0101d88:	e8 ab fa ff ff       	call   f0101838 <page_insert>
f0101d8d:	83 c4 10             	add    $0x10,%esp
f0101d90:	85 c0                	test   %eax,%eax
f0101d92:	74 19                	je     f0101dad <check_page+0x514>
f0101d94:	68 50 51 10 f0       	push   $0xf0105150
f0101d99:	68 7a 55 10 f0       	push   $0xf010557a
f0101d9e:	68 7f 03 00 00       	push   $0x37f
f0101da3:	68 5b 55 10 f0       	push   $0xf010555b
f0101da8:	e8 fc e2 ff ff       	call   f01000a9 <_panic>
	assert(*pgdir_walk(kern_pgdir, (void*) PGSIZE, 0) & PTE_W);
f0101dad:	83 ec 04             	sub    $0x4,%esp
f0101db0:	6a 00                	push   $0x0
f0101db2:	68 00 10 00 00       	push   $0x1000
f0101db7:	ff 35 88 59 19 f0    	pushl  0xf0195988
f0101dbd:	e8 83 f8 ff ff       	call   f0101645 <pgdir_walk>
f0101dc2:	83 c4 10             	add    $0x10,%esp
f0101dc5:	f6 00 02             	testb  $0x2,(%eax)
f0101dc8:	75 19                	jne    f0101de3 <check_page+0x54a>
f0101dca:	68 70 52 10 f0       	push   $0xf0105270
f0101dcf:	68 7a 55 10 f0       	push   $0xf010557a
f0101dd4:	68 80 03 00 00       	push   $0x380
f0101dd9:	68 5b 55 10 f0       	push   $0xf010555b
f0101dde:	e8 c6 e2 ff ff       	call   f01000a9 <_panic>
	assert(!(*pgdir_walk(kern_pgdir, (void*) PGSIZE, 0) & PTE_U));
f0101de3:	83 ec 04             	sub    $0x4,%esp
f0101de6:	6a 00                	push   $0x0
f0101de8:	68 00 10 00 00       	push   $0x1000
f0101ded:	ff 35 88 59 19 f0    	pushl  0xf0195988
f0101df3:	e8 4d f8 ff ff       	call   f0101645 <pgdir_walk>
f0101df8:	83 c4 10             	add    $0x10,%esp
f0101dfb:	f6 00 04             	testb  $0x4,(%eax)
f0101dfe:	74 19                	je     f0101e19 <check_page+0x580>
f0101e00:	68 a4 52 10 f0       	push   $0xf01052a4
f0101e05:	68 7a 55 10 f0       	push   $0xf010557a
f0101e0a:	68 81 03 00 00       	push   $0x381
f0101e0f:	68 5b 55 10 f0       	push   $0xf010555b
f0101e14:	e8 90 e2 ff ff       	call   f01000a9 <_panic>

	// should not be able to map at PTSIZE because need free page for page table
	assert(page_insert(kern_pgdir, pp0, (void*) PTSIZE, PTE_W) < 0);
f0101e19:	6a 02                	push   $0x2
f0101e1b:	68 00 00 40 00       	push   $0x400000
f0101e20:	ff 75 d4             	pushl  -0x2c(%ebp)
f0101e23:	ff 35 88 59 19 f0    	pushl  0xf0195988
f0101e29:	e8 0a fa ff ff       	call   f0101838 <page_insert>
f0101e2e:	83 c4 10             	add    $0x10,%esp
f0101e31:	85 c0                	test   %eax,%eax
f0101e33:	78 19                	js     f0101e4e <check_page+0x5b5>
f0101e35:	68 dc 52 10 f0       	push   $0xf01052dc
f0101e3a:	68 7a 55 10 f0       	push   $0xf010557a
f0101e3f:	68 84 03 00 00       	push   $0x384
f0101e44:	68 5b 55 10 f0       	push   $0xf010555b
f0101e49:	e8 5b e2 ff ff       	call   f01000a9 <_panic>

	// insert pp1 at PGSIZE (replacing pp2)
	assert(page_insert(kern_pgdir, pp1, (void*) PGSIZE, PTE_W) == 0);
f0101e4e:	6a 02                	push   $0x2
f0101e50:	68 00 10 00 00       	push   $0x1000
f0101e55:	56                   	push   %esi
f0101e56:	ff 35 88 59 19 f0    	pushl  0xf0195988
f0101e5c:	e8 d7 f9 ff ff       	call   f0101838 <page_insert>
f0101e61:	83 c4 10             	add    $0x10,%esp
f0101e64:	85 c0                	test   %eax,%eax
f0101e66:	74 19                	je     f0101e81 <check_page+0x5e8>
f0101e68:	68 14 53 10 f0       	push   $0xf0105314
f0101e6d:	68 7a 55 10 f0       	push   $0xf010557a
f0101e72:	68 87 03 00 00       	push   $0x387
f0101e77:	68 5b 55 10 f0       	push   $0xf010555b
f0101e7c:	e8 28 e2 ff ff       	call   f01000a9 <_panic>
	assert(!(*pgdir_walk(kern_pgdir, (void*) PGSIZE, 0) & PTE_U));
f0101e81:	83 ec 04             	sub    $0x4,%esp
f0101e84:	6a 00                	push   $0x0
f0101e86:	68 00 10 00 00       	push   $0x1000
f0101e8b:	ff 35 88 59 19 f0    	pushl  0xf0195988
f0101e91:	e8 af f7 ff ff       	call   f0101645 <pgdir_walk>
f0101e96:	83 c4 10             	add    $0x10,%esp
f0101e99:	f6 00 04             	testb  $0x4,(%eax)
f0101e9c:	74 19                	je     f0101eb7 <check_page+0x61e>
f0101e9e:	68 a4 52 10 f0       	push   $0xf01052a4
f0101ea3:	68 7a 55 10 f0       	push   $0xf010557a
f0101ea8:	68 88 03 00 00       	push   $0x388
f0101ead:	68 5b 55 10 f0       	push   $0xf010555b
f0101eb2:	e8 f2 e1 ff ff       	call   f01000a9 <_panic>

	// should have pp1 at both 0 and PGSIZE, pp2 nowhere, ...
	assert(check_va2pa(kern_pgdir, 0) == page2pa(pp1));
f0101eb7:	8b 3d 88 59 19 f0    	mov    0xf0195988,%edi
f0101ebd:	ba 00 00 00 00       	mov    $0x0,%edx
f0101ec2:	89 f8                	mov    %edi,%eax
f0101ec4:	e8 5e ec ff ff       	call   f0100b27 <check_va2pa>
f0101ec9:	89 45 d0             	mov    %eax,-0x30(%ebp)
f0101ecc:	89 f0                	mov    %esi,%eax
f0101ece:	e8 6a eb ff ff       	call   f0100a3d <page2pa>
f0101ed3:	39 45 d0             	cmp    %eax,-0x30(%ebp)
f0101ed6:	74 19                	je     f0101ef1 <check_page+0x658>
f0101ed8:	68 50 53 10 f0       	push   $0xf0105350
f0101edd:	68 7a 55 10 f0       	push   $0xf010557a
f0101ee2:	68 8b 03 00 00       	push   $0x38b
f0101ee7:	68 5b 55 10 f0       	push   $0xf010555b
f0101eec:	e8 b8 e1 ff ff       	call   f01000a9 <_panic>
	assert(check_va2pa(kern_pgdir, PGSIZE) == page2pa(pp1));
f0101ef1:	ba 00 10 00 00       	mov    $0x1000,%edx
f0101ef6:	89 f8                	mov    %edi,%eax
f0101ef8:	e8 2a ec ff ff       	call   f0100b27 <check_va2pa>
f0101efd:	39 45 d0             	cmp    %eax,-0x30(%ebp)
f0101f00:	74 19                	je     f0101f1b <check_page+0x682>
f0101f02:	68 7c 53 10 f0       	push   $0xf010537c
f0101f07:	68 7a 55 10 f0       	push   $0xf010557a
f0101f0c:	68 8c 03 00 00       	push   $0x38c
f0101f11:	68 5b 55 10 f0       	push   $0xf010555b
f0101f16:	e8 8e e1 ff ff       	call   f01000a9 <_panic>
	// ... and ref counts should reflect this
	assert(pp1->pp_ref == 2);
f0101f1b:	66 83 7e 04 02       	cmpw   $0x2,0x4(%esi)
f0101f20:	74 19                	je     f0101f3b <check_page+0x6a2>
f0101f22:	68 f0 57 10 f0       	push   $0xf01057f0
f0101f27:	68 7a 55 10 f0       	push   $0xf010557a
f0101f2c:	68 8e 03 00 00       	push   $0x38e
f0101f31:	68 5b 55 10 f0       	push   $0xf010555b
f0101f36:	e8 6e e1 ff ff       	call   f01000a9 <_panic>
	assert(pp2->pp_ref == 0);
f0101f3b:	66 83 7b 04 00       	cmpw   $0x0,0x4(%ebx)
f0101f40:	74 19                	je     f0101f5b <check_page+0x6c2>
f0101f42:	68 01 58 10 f0       	push   $0xf0105801
f0101f47:	68 7a 55 10 f0       	push   $0xf010557a
f0101f4c:	68 8f 03 00 00       	push   $0x38f
f0101f51:	68 5b 55 10 f0       	push   $0xf010555b
f0101f56:	e8 4e e1 ff ff       	call   f01000a9 <_panic>

	// pp2 should be returned by page_alloc
	assert((pp = page_alloc(0)) && pp == pp2);
f0101f5b:	83 ec 0c             	sub    $0xc,%esp
f0101f5e:	6a 00                	push   $0x0
f0101f60:	e8 55 f2 ff ff       	call   f01011ba <page_alloc>
f0101f65:	83 c4 10             	add    $0x10,%esp
f0101f68:	39 c3                	cmp    %eax,%ebx
f0101f6a:	75 04                	jne    f0101f70 <check_page+0x6d7>
f0101f6c:	85 c0                	test   %eax,%eax
f0101f6e:	75 19                	jne    f0101f89 <check_page+0x6f0>
f0101f70:	68 ac 53 10 f0       	push   $0xf01053ac
f0101f75:	68 7a 55 10 f0       	push   $0xf010557a
f0101f7a:	68 92 03 00 00       	push   $0x392
f0101f7f:	68 5b 55 10 f0       	push   $0xf010555b
f0101f84:	e8 20 e1 ff ff       	call   f01000a9 <_panic>

	// unmapping pp1 at 0 should keep pp1 at PGSIZE
	page_remove(kern_pgdir, 0x0);
f0101f89:	83 ec 08             	sub    $0x8,%esp
f0101f8c:	6a 00                	push   $0x0
f0101f8e:	ff 35 88 59 19 f0    	pushl  0xf0195988
f0101f94:	e8 59 f8 ff ff       	call   f01017f2 <page_remove>
	assert(check_va2pa(kern_pgdir, 0x0) == ~0);
f0101f99:	8b 3d 88 59 19 f0    	mov    0xf0195988,%edi
f0101f9f:	ba 00 00 00 00       	mov    $0x0,%edx
f0101fa4:	89 f8                	mov    %edi,%eax
f0101fa6:	e8 7c eb ff ff       	call   f0100b27 <check_va2pa>
f0101fab:	83 c4 10             	add    $0x10,%esp
f0101fae:	83 f8 ff             	cmp    $0xffffffff,%eax
f0101fb1:	74 19                	je     f0101fcc <check_page+0x733>
f0101fb3:	68 d0 53 10 f0       	push   $0xf01053d0
f0101fb8:	68 7a 55 10 f0       	push   $0xf010557a
f0101fbd:	68 96 03 00 00       	push   $0x396
f0101fc2:	68 5b 55 10 f0       	push   $0xf010555b
f0101fc7:	e8 dd e0 ff ff       	call   f01000a9 <_panic>
	assert(check_va2pa(kern_pgdir, PGSIZE) == page2pa(pp1));
f0101fcc:	ba 00 10 00 00       	mov    $0x1000,%edx
f0101fd1:	89 f8                	mov    %edi,%eax
f0101fd3:	e8 4f eb ff ff       	call   f0100b27 <check_va2pa>
f0101fd8:	89 45 d0             	mov    %eax,-0x30(%ebp)
f0101fdb:	89 f0                	mov    %esi,%eax
f0101fdd:	e8 5b ea ff ff       	call   f0100a3d <page2pa>
f0101fe2:	39 45 d0             	cmp    %eax,-0x30(%ebp)
f0101fe5:	74 19                	je     f0102000 <check_page+0x767>
f0101fe7:	68 7c 53 10 f0       	push   $0xf010537c
f0101fec:	68 7a 55 10 f0       	push   $0xf010557a
f0101ff1:	68 97 03 00 00       	push   $0x397
f0101ff6:	68 5b 55 10 f0       	push   $0xf010555b
f0101ffb:	e8 a9 e0 ff ff       	call   f01000a9 <_panic>
	assert(pp1->pp_ref == 1);
f0102000:	66 83 7e 04 01       	cmpw   $0x1,0x4(%esi)
f0102005:	74 19                	je     f0102020 <check_page+0x787>
f0102007:	68 a7 57 10 f0       	push   $0xf01057a7
f010200c:	68 7a 55 10 f0       	push   $0xf010557a
f0102011:	68 98 03 00 00       	push   $0x398
f0102016:	68 5b 55 10 f0       	push   $0xf010555b
f010201b:	e8 89 e0 ff ff       	call   f01000a9 <_panic>
	assert(pp2->pp_ref == 0);
f0102020:	66 83 7b 04 00       	cmpw   $0x0,0x4(%ebx)
f0102025:	74 19                	je     f0102040 <check_page+0x7a7>
f0102027:	68 01 58 10 f0       	push   $0xf0105801
f010202c:	68 7a 55 10 f0       	push   $0xf010557a
f0102031:	68 99 03 00 00       	push   $0x399
f0102036:	68 5b 55 10 f0       	push   $0xf010555b
f010203b:	e8 69 e0 ff ff       	call   f01000a9 <_panic>

	// test re-inserting pp1 at PGSIZE
	assert(page_insert(kern_pgdir, pp1, (void*) PGSIZE, 0) == 0);
f0102040:	6a 00                	push   $0x0
f0102042:	68 00 10 00 00       	push   $0x1000
f0102047:	56                   	push   %esi
f0102048:	57                   	push   %edi
f0102049:	e8 ea f7 ff ff       	call   f0101838 <page_insert>
f010204e:	83 c4 10             	add    $0x10,%esp
f0102051:	85 c0                	test   %eax,%eax
f0102053:	74 19                	je     f010206e <check_page+0x7d5>
f0102055:	68 f4 53 10 f0       	push   $0xf01053f4
f010205a:	68 7a 55 10 f0       	push   $0xf010557a
f010205f:	68 9c 03 00 00       	push   $0x39c
f0102064:	68 5b 55 10 f0       	push   $0xf010555b
f0102069:	e8 3b e0 ff ff       	call   f01000a9 <_panic>
	assert(pp1->pp_ref);
f010206e:	66 83 7e 04 00       	cmpw   $0x0,0x4(%esi)
f0102073:	75 19                	jne    f010208e <check_page+0x7f5>
f0102075:	68 12 58 10 f0       	push   $0xf0105812
f010207a:	68 7a 55 10 f0       	push   $0xf010557a
f010207f:	68 9d 03 00 00       	push   $0x39d
f0102084:	68 5b 55 10 f0       	push   $0xf010555b
f0102089:	e8 1b e0 ff ff       	call   f01000a9 <_panic>
	assert(pp1->pp_link == NULL);
f010208e:	83 3e 00             	cmpl   $0x0,(%esi)
f0102091:	74 19                	je     f01020ac <check_page+0x813>
f0102093:	68 1e 58 10 f0       	push   $0xf010581e
f0102098:	68 7a 55 10 f0       	push   $0xf010557a
f010209d:	68 9e 03 00 00       	push   $0x39e
f01020a2:	68 5b 55 10 f0       	push   $0xf010555b
f01020a7:	e8 fd df ff ff       	call   f01000a9 <_panic>

	// unmapping pp1 at PGSIZE should free it
	page_remove(kern_pgdir, (void*) PGSIZE);
f01020ac:	83 ec 08             	sub    $0x8,%esp
f01020af:	68 00 10 00 00       	push   $0x1000
f01020b4:	ff 35 88 59 19 f0    	pushl  0xf0195988
f01020ba:	e8 33 f7 ff ff       	call   f01017f2 <page_remove>
	assert(check_va2pa(kern_pgdir, 0x0) == ~0);
f01020bf:	8b 3d 88 59 19 f0    	mov    0xf0195988,%edi
f01020c5:	ba 00 00 00 00       	mov    $0x0,%edx
f01020ca:	89 f8                	mov    %edi,%eax
f01020cc:	e8 56 ea ff ff       	call   f0100b27 <check_va2pa>
f01020d1:	83 c4 10             	add    $0x10,%esp
f01020d4:	83 f8 ff             	cmp    $0xffffffff,%eax
f01020d7:	74 19                	je     f01020f2 <check_page+0x859>
f01020d9:	68 d0 53 10 f0       	push   $0xf01053d0
f01020de:	68 7a 55 10 f0       	push   $0xf010557a
f01020e3:	68 a2 03 00 00       	push   $0x3a2
f01020e8:	68 5b 55 10 f0       	push   $0xf010555b
f01020ed:	e8 b7 df ff ff       	call   f01000a9 <_panic>
	assert(check_va2pa(kern_pgdir, PGSIZE) == ~0);
f01020f2:	ba 00 10 00 00       	mov    $0x1000,%edx
f01020f7:	89 f8                	mov    %edi,%eax
f01020f9:	e8 29 ea ff ff       	call   f0100b27 <check_va2pa>
f01020fe:	83 f8 ff             	cmp    $0xffffffff,%eax
f0102101:	74 19                	je     f010211c <check_page+0x883>
f0102103:	68 2c 54 10 f0       	push   $0xf010542c
f0102108:	68 7a 55 10 f0       	push   $0xf010557a
f010210d:	68 a3 03 00 00       	push   $0x3a3
f0102112:	68 5b 55 10 f0       	push   $0xf010555b
f0102117:	e8 8d df ff ff       	call   f01000a9 <_panic>
	assert(pp1->pp_ref == 0);
f010211c:	66 83 7e 04 00       	cmpw   $0x0,0x4(%esi)
f0102121:	74 19                	je     f010213c <check_page+0x8a3>
f0102123:	68 33 58 10 f0       	push   $0xf0105833
f0102128:	68 7a 55 10 f0       	push   $0xf010557a
f010212d:	68 a4 03 00 00       	push   $0x3a4
f0102132:	68 5b 55 10 f0       	push   $0xf010555b
f0102137:	e8 6d df ff ff       	call   f01000a9 <_panic>
	assert(pp2->pp_ref == 0);
f010213c:	66 83 7b 04 00       	cmpw   $0x0,0x4(%ebx)
f0102141:	74 19                	je     f010215c <check_page+0x8c3>
f0102143:	68 01 58 10 f0       	push   $0xf0105801
f0102148:	68 7a 55 10 f0       	push   $0xf010557a
f010214d:	68 a5 03 00 00       	push   $0x3a5
f0102152:	68 5b 55 10 f0       	push   $0xf010555b
f0102157:	e8 4d df ff ff       	call   f01000a9 <_panic>

	// so it should be returned by page_alloc
	assert((pp = page_alloc(0)) && pp == pp1);
f010215c:	83 ec 0c             	sub    $0xc,%esp
f010215f:	6a 00                	push   $0x0
f0102161:	e8 54 f0 ff ff       	call   f01011ba <page_alloc>
f0102166:	83 c4 10             	add    $0x10,%esp
f0102169:	39 c6                	cmp    %eax,%esi
f010216b:	75 04                	jne    f0102171 <check_page+0x8d8>
f010216d:	85 c0                	test   %eax,%eax
f010216f:	75 19                	jne    f010218a <check_page+0x8f1>
f0102171:	68 54 54 10 f0       	push   $0xf0105454
f0102176:	68 7a 55 10 f0       	push   $0xf010557a
f010217b:	68 a8 03 00 00       	push   $0x3a8
f0102180:	68 5b 55 10 f0       	push   $0xf010555b
f0102185:	e8 1f df ff ff       	call   f01000a9 <_panic>

	// should be no free memory
	assert(!page_alloc(0));
f010218a:	83 ec 0c             	sub    $0xc,%esp
f010218d:	6a 00                	push   $0x0
f010218f:	e8 26 f0 ff ff       	call   f01011ba <page_alloc>
f0102194:	83 c4 10             	add    $0x10,%esp
f0102197:	85 c0                	test   %eax,%eax
f0102199:	74 19                	je     f01021b4 <check_page+0x91b>
f010219b:	68 20 57 10 f0       	push   $0xf0105720
f01021a0:	68 7a 55 10 f0       	push   $0xf010557a
f01021a5:	68 ab 03 00 00       	push   $0x3ab
f01021aa:	68 5b 55 10 f0       	push   $0xf010555b
f01021af:	e8 f5 de ff ff       	call   f01000a9 <_panic>

	// forcibly take pp0 back
	assert(PTE_ADDR(kern_pgdir[0]) == page2pa(pp0));
f01021b4:	8b 3d 88 59 19 f0    	mov    0xf0195988,%edi
f01021ba:	8b 45 d4             	mov    -0x2c(%ebp),%eax
f01021bd:	e8 7b e8 ff ff       	call   f0100a3d <page2pa>
f01021c2:	8b 17                	mov    (%edi),%edx
f01021c4:	81 e2 00 f0 ff ff    	and    $0xfffff000,%edx
f01021ca:	39 c2                	cmp    %eax,%edx
f01021cc:	74 19                	je     f01021e7 <check_page+0x94e>
f01021ce:	68 f8 50 10 f0       	push   $0xf01050f8
f01021d3:	68 7a 55 10 f0       	push   $0xf010557a
f01021d8:	68 ae 03 00 00       	push   $0x3ae
f01021dd:	68 5b 55 10 f0       	push   $0xf010555b
f01021e2:	e8 c2 de ff ff       	call   f01000a9 <_panic>
	kern_pgdir[0] = 0;
f01021e7:	c7 07 00 00 00 00    	movl   $0x0,(%edi)
	assert(pp0->pp_ref == 1);
f01021ed:	8b 45 d4             	mov    -0x2c(%ebp),%eax
f01021f0:	66 83 78 04 01       	cmpw   $0x1,0x4(%eax)
f01021f5:	74 19                	je     f0102210 <check_page+0x977>
f01021f7:	68 b8 57 10 f0       	push   $0xf01057b8
f01021fc:	68 7a 55 10 f0       	push   $0xf010557a
f0102201:	68 b0 03 00 00       	push   $0x3b0
f0102206:	68 5b 55 10 f0       	push   $0xf010555b
f010220b:	e8 99 de ff ff       	call   f01000a9 <_panic>
	pp0->pp_ref = 0;
f0102210:	8b 45 d4             	mov    -0x2c(%ebp),%eax
f0102213:	66 c7 40 04 00 00    	movw   $0x0,0x4(%eax)

	// check pointer arithmetic in pgdir_walk
	page_free(pp0);
f0102219:	83 ec 0c             	sub    $0xc,%esp
f010221c:	50                   	push   %eax
f010221d:	e8 dd ef ff ff       	call   f01011ff <page_free>
	va = (void*)(PGSIZE * NPDENTRIES + PGSIZE);
	ptep = pgdir_walk(kern_pgdir, va, 1);
f0102222:	83 c4 0c             	add    $0xc,%esp
f0102225:	6a 01                	push   $0x1
f0102227:	68 00 10 40 00       	push   $0x401000
f010222c:	ff 35 88 59 19 f0    	pushl  0xf0195988
f0102232:	e8 0e f4 ff ff       	call   f0101645 <pgdir_walk>
f0102237:	89 45 d0             	mov    %eax,-0x30(%ebp)
f010223a:	89 45 e4             	mov    %eax,-0x1c(%ebp)
	ptep1 = (pte_t *) KADDR(PTE_ADDR(kern_pgdir[PDX(va)]));
f010223d:	8b 3d 88 59 19 f0    	mov    0xf0195988,%edi
f0102243:	8b 4f 04             	mov    0x4(%edi),%ecx
f0102246:	81 e1 00 f0 ff ff    	and    $0xfffff000,%ecx
f010224c:	ba b7 03 00 00       	mov    $0x3b7,%edx
f0102251:	b8 5b 55 10 f0       	mov    $0xf010555b,%eax
f0102256:	e8 82 e8 ff ff       	call   f0100add <_kaddr>
	assert(ptep == ptep1 + PTX(va));
f010225b:	83 c0 04             	add    $0x4,%eax
f010225e:	83 c4 10             	add    $0x10,%esp
f0102261:	39 45 d0             	cmp    %eax,-0x30(%ebp)
f0102264:	74 19                	je     f010227f <check_page+0x9e6>
f0102266:	68 44 58 10 f0       	push   $0xf0105844
f010226b:	68 7a 55 10 f0       	push   $0xf010557a
f0102270:	68 b8 03 00 00       	push   $0x3b8
f0102275:	68 5b 55 10 f0       	push   $0xf010555b
f010227a:	e8 2a de ff ff       	call   f01000a9 <_panic>
	kern_pgdir[PDX(va)] = 0;
f010227f:	c7 47 04 00 00 00 00 	movl   $0x0,0x4(%edi)
	pp0->pp_ref = 0;
f0102286:	8b 7d d4             	mov    -0x2c(%ebp),%edi
f0102289:	89 f8                	mov    %edi,%eax
f010228b:	66 c7 47 04 00 00    	movw   $0x0,0x4(%edi)

	// check that new page tables get cleared
	memset(page2kva(pp0), 0xFF, PGSIZE);
f0102291:	e8 73 e8 ff ff       	call   f0100b09 <page2kva>
f0102296:	83 ec 04             	sub    $0x4,%esp
f0102299:	68 00 10 00 00       	push   $0x1000
f010229e:	68 ff 00 00 00       	push   $0xff
f01022a3:	50                   	push   %eax
f01022a4:	e8 d6 20 00 00       	call   f010437f <memset>
	page_free(pp0);
f01022a9:	89 3c 24             	mov    %edi,(%esp)
f01022ac:	e8 4e ef ff ff       	call   f01011ff <page_free>
	pgdir_walk(kern_pgdir, 0x0, 1);
f01022b1:	83 c4 0c             	add    $0xc,%esp
f01022b4:	6a 01                	push   $0x1
f01022b6:	6a 00                	push   $0x0
f01022b8:	ff 35 88 59 19 f0    	pushl  0xf0195988
f01022be:	e8 82 f3 ff ff       	call   f0101645 <pgdir_walk>
	ptep = (pte_t *) page2kva(pp0);
f01022c3:	89 f8                	mov    %edi,%eax
f01022c5:	e8 3f e8 ff ff       	call   f0100b09 <page2kva>
f01022ca:	89 45 e4             	mov    %eax,-0x1c(%ebp)
f01022cd:	89 c2                	mov    %eax,%edx
f01022cf:	05 00 10 00 00       	add    $0x1000,%eax
f01022d4:	83 c4 10             	add    $0x10,%esp
	for(i=0; i<NPTENTRIES; i++)
		assert((ptep[i] & PTE_P) == 0);
f01022d7:	f6 02 01             	testb  $0x1,(%edx)
f01022da:	74 19                	je     f01022f5 <check_page+0xa5c>
f01022dc:	68 5c 58 10 f0       	push   $0xf010585c
f01022e1:	68 7a 55 10 f0       	push   $0xf010557a
f01022e6:	68 c2 03 00 00       	push   $0x3c2
f01022eb:	68 5b 55 10 f0       	push   $0xf010555b
f01022f0:	e8 b4 dd ff ff       	call   f01000a9 <_panic>
f01022f5:	83 c2 04             	add    $0x4,%edx
	// check that new page tables get cleared
	memset(page2kva(pp0), 0xFF, PGSIZE);
	page_free(pp0);
	pgdir_walk(kern_pgdir, 0x0, 1);
	ptep = (pte_t *) page2kva(pp0);
	for(i=0; i<NPTENTRIES; i++)
f01022f8:	39 c2                	cmp    %eax,%edx
f01022fa:	75 db                	jne    f01022d7 <check_page+0xa3e>
		assert((ptep[i] & PTE_P) == 0);
	kern_pgdir[0] = 0;
f01022fc:	a1 88 59 19 f0       	mov    0xf0195988,%eax
f0102301:	c7 00 00 00 00 00    	movl   $0x0,(%eax)
	pp0->pp_ref = 0;
f0102307:	8b 45 d4             	mov    -0x2c(%ebp),%eax
f010230a:	66 c7 40 04 00 00    	movw   $0x0,0x4(%eax)

	// give free list back
	page_free_list = fl;
f0102310:	8b 4d cc             	mov    -0x34(%ebp),%ecx
f0102313:	89 0d c0 3c 19 f0    	mov    %ecx,0xf0193cc0

	// free the pages we took
	page_free(pp0);
f0102319:	83 ec 0c             	sub    $0xc,%esp
f010231c:	50                   	push   %eax
f010231d:	e8 dd ee ff ff       	call   f01011ff <page_free>
	page_free(pp1);
f0102322:	89 34 24             	mov    %esi,(%esp)
f0102325:	e8 d5 ee ff ff       	call   f01011ff <page_free>
	page_free(pp2);
f010232a:	89 1c 24             	mov    %ebx,(%esp)
f010232d:	e8 cd ee ff ff       	call   f01011ff <page_free>

	cprintf("check_page() succeeded!\n");
f0102332:	c7 04 24 73 58 10 f0 	movl   $0xf0105873,(%esp)
f0102339:	e8 3a 0c 00 00       	call   f0102f78 <cprintf>
}
f010233e:	83 c4 10             	add    $0x10,%esp
f0102341:	8d 65 f4             	lea    -0xc(%ebp),%esp
f0102344:	5b                   	pop    %ebx
f0102345:	5e                   	pop    %esi
f0102346:	5f                   	pop    %edi
f0102347:	5d                   	pop    %ebp
f0102348:	c3                   	ret    

f0102349 <check_page_installed_pgdir>:

// check page_insert, page_remove, &c, with an installed kern_pgdir
static void
check_page_installed_pgdir(void)
{
f0102349:	55                   	push   %ebp
f010234a:	89 e5                	mov    %esp,%ebp
f010234c:	57                   	push   %edi
f010234d:	56                   	push   %esi
f010234e:	53                   	push   %ebx
f010234f:	83 ec 18             	sub    $0x18,%esp
	uintptr_t va;
	int i;

	// check that we can read and write installed pages
	pp1 = pp2 = 0;
	assert((pp0 = page_alloc(0)));
f0102352:	6a 00                	push   $0x0
f0102354:	e8 61 ee ff ff       	call   f01011ba <page_alloc>
f0102359:	83 c4 10             	add    $0x10,%esp
f010235c:	85 c0                	test   %eax,%eax
f010235e:	75 19                	jne    f0102379 <check_page_installed_pgdir+0x30>
f0102360:	68 75 56 10 f0       	push   $0xf0105675
f0102365:	68 7a 55 10 f0       	push   $0xf010557a
f010236a:	68 dd 03 00 00       	push   $0x3dd
f010236f:	68 5b 55 10 f0       	push   $0xf010555b
f0102374:	e8 30 dd ff ff       	call   f01000a9 <_panic>
f0102379:	89 c6                	mov    %eax,%esi
	assert((pp1 = page_alloc(0)));
f010237b:	83 ec 0c             	sub    $0xc,%esp
f010237e:	6a 00                	push   $0x0
f0102380:	e8 35 ee ff ff       	call   f01011ba <page_alloc>
f0102385:	89 c7                	mov    %eax,%edi
f0102387:	83 c4 10             	add    $0x10,%esp
f010238a:	85 c0                	test   %eax,%eax
f010238c:	75 19                	jne    f01023a7 <check_page_installed_pgdir+0x5e>
f010238e:	68 8b 56 10 f0       	push   $0xf010568b
f0102393:	68 7a 55 10 f0       	push   $0xf010557a
f0102398:	68 de 03 00 00       	push   $0x3de
f010239d:	68 5b 55 10 f0       	push   $0xf010555b
f01023a2:	e8 02 dd ff ff       	call   f01000a9 <_panic>
	assert((pp2 = page_alloc(0)));
f01023a7:	83 ec 0c             	sub    $0xc,%esp
f01023aa:	6a 00                	push   $0x0
f01023ac:	e8 09 ee ff ff       	call   f01011ba <page_alloc>
f01023b1:	89 c3                	mov    %eax,%ebx
f01023b3:	83 c4 10             	add    $0x10,%esp
f01023b6:	85 c0                	test   %eax,%eax
f01023b8:	75 19                	jne    f01023d3 <check_page_installed_pgdir+0x8a>
f01023ba:	68 a1 56 10 f0       	push   $0xf01056a1
f01023bf:	68 7a 55 10 f0       	push   $0xf010557a
f01023c4:	68 df 03 00 00       	push   $0x3df
f01023c9:	68 5b 55 10 f0       	push   $0xf010555b
f01023ce:	e8 d6 dc ff ff       	call   f01000a9 <_panic>
	page_free(pp0);
f01023d3:	83 ec 0c             	sub    $0xc,%esp
f01023d6:	56                   	push   %esi
f01023d7:	e8 23 ee ff ff       	call   f01011ff <page_free>
	memset(page2kva(pp1), 1, PGSIZE);
f01023dc:	89 f8                	mov    %edi,%eax
f01023de:	e8 26 e7 ff ff       	call   f0100b09 <page2kva>
f01023e3:	83 c4 0c             	add    $0xc,%esp
f01023e6:	68 00 10 00 00       	push   $0x1000
f01023eb:	6a 01                	push   $0x1
f01023ed:	50                   	push   %eax
f01023ee:	e8 8c 1f 00 00       	call   f010437f <memset>
	memset(page2kva(pp2), 2, PGSIZE);
f01023f3:	89 d8                	mov    %ebx,%eax
f01023f5:	e8 0f e7 ff ff       	call   f0100b09 <page2kva>
f01023fa:	83 c4 0c             	add    $0xc,%esp
f01023fd:	68 00 10 00 00       	push   $0x1000
f0102402:	6a 02                	push   $0x2
f0102404:	50                   	push   %eax
f0102405:	e8 75 1f 00 00       	call   f010437f <memset>
	page_insert(kern_pgdir, pp1, (void*) PGSIZE, PTE_W);
f010240a:	6a 02                	push   $0x2
f010240c:	68 00 10 00 00       	push   $0x1000
f0102411:	57                   	push   %edi
f0102412:	ff 35 88 59 19 f0    	pushl  0xf0195988
f0102418:	e8 1b f4 ff ff       	call   f0101838 <page_insert>
	assert(pp1->pp_ref == 1);
f010241d:	83 c4 20             	add    $0x20,%esp
f0102420:	66 83 7f 04 01       	cmpw   $0x1,0x4(%edi)
f0102425:	74 19                	je     f0102440 <check_page_installed_pgdir+0xf7>
f0102427:	68 a7 57 10 f0       	push   $0xf01057a7
f010242c:	68 7a 55 10 f0       	push   $0xf010557a
f0102431:	68 e4 03 00 00       	push   $0x3e4
f0102436:	68 5b 55 10 f0       	push   $0xf010555b
f010243b:	e8 69 dc ff ff       	call   f01000a9 <_panic>
	assert(*(uint32_t *)PGSIZE == 0x01010101U);
f0102440:	81 3d 00 10 00 00 01 	cmpl   $0x1010101,0x1000
f0102447:	01 01 01 
f010244a:	74 19                	je     f0102465 <check_page_installed_pgdir+0x11c>
f010244c:	68 78 54 10 f0       	push   $0xf0105478
f0102451:	68 7a 55 10 f0       	push   $0xf010557a
f0102456:	68 e5 03 00 00       	push   $0x3e5
f010245b:	68 5b 55 10 f0       	push   $0xf010555b
f0102460:	e8 44 dc ff ff       	call   f01000a9 <_panic>
	page_insert(kern_pgdir, pp2, (void*) PGSIZE, PTE_W);
f0102465:	6a 02                	push   $0x2
f0102467:	68 00 10 00 00       	push   $0x1000
f010246c:	53                   	push   %ebx
f010246d:	ff 35 88 59 19 f0    	pushl  0xf0195988
f0102473:	e8 c0 f3 ff ff       	call   f0101838 <page_insert>
	assert(*(uint32_t *)PGSIZE == 0x02020202U);
f0102478:	83 c4 10             	add    $0x10,%esp
f010247b:	81 3d 00 10 00 00 02 	cmpl   $0x2020202,0x1000
f0102482:	02 02 02 
f0102485:	74 19                	je     f01024a0 <check_page_installed_pgdir+0x157>
f0102487:	68 9c 54 10 f0       	push   $0xf010549c
f010248c:	68 7a 55 10 f0       	push   $0xf010557a
f0102491:	68 e7 03 00 00       	push   $0x3e7
f0102496:	68 5b 55 10 f0       	push   $0xf010555b
f010249b:	e8 09 dc ff ff       	call   f01000a9 <_panic>
	assert(pp2->pp_ref == 1);
f01024a0:	66 83 7b 04 01       	cmpw   $0x1,0x4(%ebx)
f01024a5:	74 19                	je     f01024c0 <check_page_installed_pgdir+0x177>
f01024a7:	68 c9 57 10 f0       	push   $0xf01057c9
f01024ac:	68 7a 55 10 f0       	push   $0xf010557a
f01024b1:	68 e8 03 00 00       	push   $0x3e8
f01024b6:	68 5b 55 10 f0       	push   $0xf010555b
f01024bb:	e8 e9 db ff ff       	call   f01000a9 <_panic>
	assert(pp1->pp_ref == 0);
f01024c0:	66 83 7f 04 00       	cmpw   $0x0,0x4(%edi)
f01024c5:	74 19                	je     f01024e0 <check_page_installed_pgdir+0x197>
f01024c7:	68 33 58 10 f0       	push   $0xf0105833
f01024cc:	68 7a 55 10 f0       	push   $0xf010557a
f01024d1:	68 e9 03 00 00       	push   $0x3e9
f01024d6:	68 5b 55 10 f0       	push   $0xf010555b
f01024db:	e8 c9 db ff ff       	call   f01000a9 <_panic>
	*(uint32_t *)PGSIZE = 0x03030303U;
f01024e0:	c7 05 00 10 00 00 03 	movl   $0x3030303,0x1000
f01024e7:	03 03 03 
	assert(*(uint32_t *)page2kva(pp2) == 0x03030303U);
f01024ea:	89 d8                	mov    %ebx,%eax
f01024ec:	e8 18 e6 ff ff       	call   f0100b09 <page2kva>
f01024f1:	81 38 03 03 03 03    	cmpl   $0x3030303,(%eax)
f01024f7:	74 19                	je     f0102512 <check_page_installed_pgdir+0x1c9>
f01024f9:	68 c0 54 10 f0       	push   $0xf01054c0
f01024fe:	68 7a 55 10 f0       	push   $0xf010557a
f0102503:	68 eb 03 00 00       	push   $0x3eb
f0102508:	68 5b 55 10 f0       	push   $0xf010555b
f010250d:	e8 97 db ff ff       	call   f01000a9 <_panic>
	page_remove(kern_pgdir, (void*) PGSIZE);
f0102512:	83 ec 08             	sub    $0x8,%esp
f0102515:	68 00 10 00 00       	push   $0x1000
f010251a:	ff 35 88 59 19 f0    	pushl  0xf0195988
f0102520:	e8 cd f2 ff ff       	call   f01017f2 <page_remove>
	assert(pp2->pp_ref == 0);
f0102525:	83 c4 10             	add    $0x10,%esp
f0102528:	66 83 7b 04 00       	cmpw   $0x0,0x4(%ebx)
f010252d:	74 19                	je     f0102548 <check_page_installed_pgdir+0x1ff>
f010252f:	68 01 58 10 f0       	push   $0xf0105801
f0102534:	68 7a 55 10 f0       	push   $0xf010557a
f0102539:	68 ed 03 00 00       	push   $0x3ed
f010253e:	68 5b 55 10 f0       	push   $0xf010555b
f0102543:	e8 61 db ff ff       	call   f01000a9 <_panic>

	// forcibly take pp0 back
	assert(PTE_ADDR(kern_pgdir[0]) == page2pa(pp0));
f0102548:	8b 1d 88 59 19 f0    	mov    0xf0195988,%ebx
f010254e:	89 f0                	mov    %esi,%eax
f0102550:	e8 e8 e4 ff ff       	call   f0100a3d <page2pa>
f0102555:	8b 13                	mov    (%ebx),%edx
f0102557:	81 e2 00 f0 ff ff    	and    $0xfffff000,%edx
f010255d:	39 c2                	cmp    %eax,%edx
f010255f:	74 19                	je     f010257a <check_page_installed_pgdir+0x231>
f0102561:	68 f8 50 10 f0       	push   $0xf01050f8
f0102566:	68 7a 55 10 f0       	push   $0xf010557a
f010256b:	68 f0 03 00 00       	push   $0x3f0
f0102570:	68 5b 55 10 f0       	push   $0xf010555b
f0102575:	e8 2f db ff ff       	call   f01000a9 <_panic>
	kern_pgdir[0] = 0;
f010257a:	c7 03 00 00 00 00    	movl   $0x0,(%ebx)
	assert(pp0->pp_ref == 1);
f0102580:	66 83 7e 04 01       	cmpw   $0x1,0x4(%esi)
f0102585:	74 19                	je     f01025a0 <check_page_installed_pgdir+0x257>
f0102587:	68 b8 57 10 f0       	push   $0xf01057b8
f010258c:	68 7a 55 10 f0       	push   $0xf010557a
f0102591:	68 f2 03 00 00       	push   $0x3f2
f0102596:	68 5b 55 10 f0       	push   $0xf010555b
f010259b:	e8 09 db ff ff       	call   f01000a9 <_panic>
	pp0->pp_ref = 0;
f01025a0:	66 c7 46 04 00 00    	movw   $0x0,0x4(%esi)

	// free the pages we took
	page_free(pp0);
f01025a6:	83 ec 0c             	sub    $0xc,%esp
f01025a9:	56                   	push   %esi
f01025aa:	e8 50 ec ff ff       	call   f01011ff <page_free>

	cprintf("check_page_installed_pgdir() succeeded!\n");
f01025af:	c7 04 24 ec 54 10 f0 	movl   $0xf01054ec,(%esp)
f01025b6:	e8 bd 09 00 00       	call   f0102f78 <cprintf>
}
f01025bb:	83 c4 10             	add    $0x10,%esp
f01025be:	8d 65 f4             	lea    -0xc(%ebp),%esp
f01025c1:	5b                   	pop    %ebx
f01025c2:	5e                   	pop    %esi
f01025c3:	5f                   	pop    %edi
f01025c4:	5d                   	pop    %ebp
f01025c5:	c3                   	ret    

f01025c6 <mem_init>:
//
// From UTOP to ULIM, the user is allowed to read but not write.
// Above ULIM the user cannot read or write.
void
mem_init(void)
{
f01025c6:	55                   	push   %ebp
f01025c7:	89 e5                	mov    %esp,%ebp
f01025c9:	53                   	push   %ebx
f01025ca:	83 ec 04             	sub    $0x4,%esp
	uint32_t cr0;
	size_t n;

	// Find out how much memory the machine has (npages & npages_basemem).
	i386_detect_memory();
f01025cd:	e8 a5 e4 ff ff       	call   f0100a77 <i386_detect_memory>
	// Remove this line when you're ready to test this function.
	//panic("mem_init: This function is not finished\n");

	//////////////////////////////////////////////////////////////////////
	// create initial page directory.
	kern_pgdir = (pde_t *) boot_alloc(PGSIZE);
f01025d2:	b8 00 10 00 00       	mov    $0x1000,%eax
f01025d7:	e8 dd e5 ff ff       	call   f0100bb9 <boot_alloc>
f01025dc:	a3 88 59 19 f0       	mov    %eax,0xf0195988
	memset(kern_pgdir, 0, PGSIZE);
f01025e1:	83 ec 04             	sub    $0x4,%esp
f01025e4:	68 00 10 00 00       	push   $0x1000
f01025e9:	6a 00                	push   $0x0
f01025eb:	50                   	push   %eax
f01025ec:	e8 8e 1d 00 00       	call   f010437f <memset>
	// a virtual page table at virtual address UVPT.
	// (For now, you don't have understand the greater purpose of the
	// following line.)

	// Permissions: kernel R, user R
	kern_pgdir[PDX(UVPT)] = PADDR(kern_pgdir) | PTE_U | PTE_P;
f01025f1:	8b 1d 88 59 19 f0    	mov    0xf0195988,%ebx
f01025f7:	89 d9                	mov    %ebx,%ecx
f01025f9:	ba 93 00 00 00       	mov    $0x93,%edx
f01025fe:	b8 5b 55 10 f0       	mov    $0xf010555b,%eax
f0102603:	e8 8f e5 ff ff       	call   f0100b97 <_paddr>
f0102608:	83 c8 05             	or     $0x5,%eax
f010260b:	89 83 f4 0e 00 00    	mov    %eax,0xef4(%ebx)
	// The kernel uses this array to keep track of physical pages: for
	// each physical page, there is a corresponding struct PageInfo in this
	// array.  'npages' is the number of physical pages in memory.  Use memset
	// to initialize all fields of each struct PageInfo to 0.
	// Your code goes here:
	pages=boot_alloc(npages //[page]
f0102611:	a1 84 59 19 f0       	mov    0xf0195984,%eax
f0102616:	c1 e0 03             	shl    $0x3,%eax
f0102619:	e8 9b e5 ff ff       	call   f0100bb9 <boot_alloc>
f010261e:	a3 8c 59 19 f0       	mov    %eax,0xf019598c
					 * sizeof(struct PageInfo));//[B/page]
	memset(pages,0,npages*sizeof(struct PageInfo));
f0102623:	83 c4 0c             	add    $0xc,%esp
f0102626:	8b 1d 84 59 19 f0    	mov    0xf0195984,%ebx
f010262c:	8d 14 dd 00 00 00 00 	lea    0x0(,%ebx,8),%edx
f0102633:	52                   	push   %edx
f0102634:	6a 00                	push   $0x0
f0102636:	50                   	push   %eax
f0102637:	e8 43 1d 00 00       	call   f010437f <memset>
	//////////////////////////////////////////////////////////////////////
	// Make 'envs' point to an array of size 'NENV' of 'struct Env'.
	// LAB 3: Your code here.

	envs = boot_alloc(NENV*sizeof(struct Env));
f010263c:	b8 00 80 01 00       	mov    $0x18000,%eax
f0102641:	e8 73 e5 ff ff       	call   f0100bb9 <boot_alloc>
f0102646:	a3 c8 3c 19 f0       	mov    %eax,0xf0193cc8
	memset(envs,0, NENV*sizeof(struct Env));
f010264b:	83 c4 0c             	add    $0xc,%esp
f010264e:	68 00 80 01 00       	push   $0x18000
f0102653:	6a 00                	push   $0x0
f0102655:	50                   	push   %eax
f0102656:	e8 24 1d 00 00       	call   f010437f <memset>
	// Now that we've allocated the initial kernel data structures, we set
	// up the list of free physical pages. Once we've done so, all further
	// memory management will go through the page_* functions. In
	// particular, we can now map memory using boot_map_region
	// or page_insert
	page_init();
f010265b:	e8 dc ea ff ff       	call   f010113c <page_init>

	check_page_free_list(1);
f0102660:	b8 01 00 00 00       	mov    $0x1,%eax
f0102665:	e8 2e e8 ff ff       	call   f0100e98 <check_page_free_list>
	check_page_alloc();
f010266a:	e8 e2 eb ff ff       	call   f0101251 <check_page_alloc>
	check_page();
f010266f:	e8 25 f2 ff ff       	call   f0101899 <check_page>
	// Permissions:
	//    - the new image at UPAGES -- kernel R, user R
	//      (ie. perm = PTE_U | PTE_P)
	//    - pages itself -- kernel RW, user NONE
	// Your code goes here:
	boot_map_region(kern_pgdir,UPAGES,npages*sizeof(struct PageInfo),PADDR(pages),PTE_U|PTE_P);
f0102674:	8b 0d 8c 59 19 f0    	mov    0xf019598c,%ecx
f010267a:	ba bd 00 00 00       	mov    $0xbd,%edx
f010267f:	b8 5b 55 10 f0       	mov    $0xf010555b,%eax
f0102684:	e8 0e e5 ff ff       	call   f0100b97 <_paddr>
f0102689:	8b 1d 84 59 19 f0    	mov    0xf0195984,%ebx
f010268f:	8d 0c dd 00 00 00 00 	lea    0x0(,%ebx,8),%ecx
f0102696:	83 c4 08             	add    $0x8,%esp
f0102699:	6a 05                	push   $0x5
f010269b:	50                   	push   %eax
f010269c:	ba 00 00 00 ef       	mov    $0xef000000,%edx
f01026a1:	a1 88 59 19 f0       	mov    0xf0195988,%eax
f01026a6:	e8 39 f0 ff ff       	call   f01016e4 <boot_map_region>
	// (ie. perm = PTE_U | PTE_P).
	// Permissions:
	//    - the new image at UENVS  -- kernel R, user R
	//    - envs itself -- kernel RW, user NONE
	// LAB 3: Your code here.
	boot_map_region(kern_pgdir, UENVS, NENV*sizeof(struct Env), PADDR(envs), PTE_U|PTE_P);
f01026ab:	8b 0d c8 3c 19 f0    	mov    0xf0193cc8,%ecx
f01026b1:	ba c5 00 00 00       	mov    $0xc5,%edx
f01026b6:	b8 5b 55 10 f0       	mov    $0xf010555b,%eax
f01026bb:	e8 d7 e4 ff ff       	call   f0100b97 <_paddr>
f01026c0:	83 c4 08             	add    $0x8,%esp
f01026c3:	6a 05                	push   $0x5
f01026c5:	50                   	push   %eax
f01026c6:	b9 00 80 01 00       	mov    $0x18000,%ecx
f01026cb:	ba 00 00 c0 ee       	mov    $0xeec00000,%edx
f01026d0:	a1 88 59 19 f0       	mov    0xf0195988,%eax
f01026d5:	e8 0a f0 ff ff       	call   f01016e4 <boot_map_region>
	//     * [KSTACKTOP-PTSIZE, KSTACKTOP-KSTKSIZE) -- not backed; so if
	//       the kernel overflows its stack, it will fault rather than
	//       overwrite memory.  Known as a "guard page".
	//     Permissions: kernel RW, user NONE
	// Your code goes here:
	boot_map_region(kern_pgdir,KSTACKTOP-KSTKSIZE,KSTKSIZE,PADDR(bootstack),PTE_P|PTE_W);
f01026da:	b9 00 70 10 f0       	mov    $0xf0107000,%ecx
f01026df:	ba d2 00 00 00       	mov    $0xd2,%edx
f01026e4:	b8 5b 55 10 f0       	mov    $0xf010555b,%eax
f01026e9:	e8 a9 e4 ff ff       	call   f0100b97 <_paddr>
f01026ee:	83 c4 08             	add    $0x8,%esp
f01026f1:	6a 03                	push   $0x3
f01026f3:	50                   	push   %eax
f01026f4:	b9 00 80 00 00       	mov    $0x8000,%ecx
f01026f9:	ba 00 80 ff ef       	mov    $0xefff8000,%edx
f01026fe:	a1 88 59 19 f0       	mov    0xf0195988,%eax
f0102703:	e8 dc ef ff ff       	call   f01016e4 <boot_map_region>
	//      the PA range [0, 2^32 - KERNBASE)
	// We might not have 2^32 - KERNBASE bytes of physical memory, but
	// we just set up the mapping anyway.
	// Permissions: kernel RW, user NONE
	// Your code goes here:
	boot_map_region(kern_pgdir,KERNBASE,~0x0-KERNBASE+1,0,PTE_P|PTE_W);
f0102708:	83 c4 08             	add    $0x8,%esp
f010270b:	6a 03                	push   $0x3
f010270d:	6a 00                	push   $0x0
f010270f:	b9 00 00 00 10       	mov    $0x10000000,%ecx
f0102714:	ba 00 00 00 f0       	mov    $0xf0000000,%edx
f0102719:	a1 88 59 19 f0       	mov    0xf0195988,%eax
f010271e:	e8 c1 ef ff ff       	call   f01016e4 <boot_map_region>
	// Check that the initial page directory has been set up correctly.
	check_kern_pgdir();
f0102723:	e8 0d e5 ff ff       	call   f0100c35 <check_kern_pgdir>
	// somewhere between KERNBASE and KERNBASE+4MB right now, which is
	// mapped the same way by both page tables.
	//
	// If the machine reboots at this point, you've probably set up your
	// kern_pgdir wrong.
	lcr3(PADDR(kern_pgdir));
f0102728:	8b 0d 88 59 19 f0    	mov    0xf0195988,%ecx
f010272e:	ba e7 00 00 00       	mov    $0xe7,%edx
f0102733:	b8 5b 55 10 f0       	mov    $0xf010555b,%eax
f0102738:	e8 5a e4 ff ff       	call   f0100b97 <_paddr>
f010273d:	e8 f3 e2 ff ff       	call   f0100a35 <lcr3>

	check_page_free_list(0);
f0102742:	b8 00 00 00 00       	mov    $0x0,%eax
f0102747:	e8 4c e7 ff ff       	call   f0100e98 <check_page_free_list>

	// entry.S set the really important flags in cr0 (including enabling
	// paging).  Here we configure the rest of the flags that we care about.
	cr0 = rcr0();
f010274c:	e8 dc e2 ff ff       	call   f0100a2d <rcr0>
f0102751:	83 e0 f3             	and    $0xfffffff3,%eax
	cr0 |= CR0_PE|CR0_PG|CR0_AM|CR0_WP|CR0_NE|CR0_MP;
	cr0 &= ~(CR0_TS|CR0_EM);
	lcr0(cr0);
f0102754:	0d 23 00 05 80       	or     $0x80050023,%eax
f0102759:	e8 c7 e2 ff ff       	call   f0100a25 <lcr0>

	// Some more checks, only possible after kern_pgdir is installed.
	check_page_installed_pgdir();
f010275e:	e8 e6 fb ff ff       	call   f0102349 <check_page_installed_pgdir>
}
f0102763:	83 c4 10             	add    $0x10,%esp
f0102766:	8b 5d fc             	mov    -0x4(%ebp),%ebx
f0102769:	c9                   	leave  
f010276a:	c3                   	ret    

f010276b <user_mem_check>:
// Returns 0 if the user program can access this range of addresses,
// and -E_FAULT otherwise.
//
int
user_mem_check(struct Env *env, const void *va, size_t len, int perm)
{
f010276b:	55                   	push   %ebp
f010276c:	89 e5                	mov    %esp,%ebp
f010276e:	57                   	push   %edi
f010276f:	56                   	push   %esi
f0102770:	53                   	push   %ebx
f0102771:	83 ec 2c             	sub    $0x2c,%esp
f0102774:	8b 45 0c             	mov    0xc(%ebp),%eax
f0102777:	8b 75 14             	mov    0x14(%ebp),%esi
	// LAB 3: Your code here.
	//MARTIN_TP2_PARTE5
	uintptr_t xva = (uintptr_t) va;
	uintptr_t lim_va = xva+len;
f010277a:	89 c1                	mov    %eax,%ecx
f010277c:	03 4d 10             	add    0x10(%ebp),%ecx
f010277f:	89 4d d4             	mov    %ecx,-0x2c(%ebp)
	if (xva >= ULIM){
f0102782:	3d ff ff 7f ef       	cmp    $0xef7fffff,%eax
f0102787:	76 0c                	jbe    f0102795 <user_mem_check+0x2a>
		user_mem_check_addr = xva;
f0102789:	a3 bc 3c 19 f0       	mov    %eax,0xf0193cbc
		return -E_FAULT;
f010278e:	b8 fa ff ff ff       	mov    $0xfffffffa,%eax
f0102793:	eb 6e                	jmp    f0102803 <user_mem_check+0x98>
f0102795:	89 c3                	mov    %eax,%ebx
	}
	if (lim_va >= ULIM || lim_va < xva){ //Bolzano dice que esto anda
f0102797:	8b 4d d4             	mov    -0x2c(%ebp),%ecx
f010279a:	81 f9 ff ff 7f ef    	cmp    $0xef7fffff,%ecx
f01027a0:	77 07                	ja     f01027a9 <user_mem_check+0x3e>
		return -E_FAULT;		
	}

	pte_t* pteaddr;
	while(xva<lim_va){ 
		if (!page_lookup(env->env_pgdir,(void*) xva,&pteaddr)){	//si no esta alojada o !PTE_P
f01027a2:	8d 7d e4             	lea    -0x1c(%ebp),%edi
	uintptr_t lim_va = xva+len;
	if (xva >= ULIM){
		user_mem_check_addr = xva;
		return -E_FAULT;
	}
	if (lim_va >= ULIM || lim_va < xva){ //Bolzano dice que esto anda
f01027a5:	39 c8                	cmp    %ecx,%eax
f01027a7:	76 50                	jbe    f01027f9 <user_mem_check+0x8e>
		user_mem_check_addr = ULIM; 
f01027a9:	c7 05 bc 3c 19 f0 00 	movl   $0xef800000,0xf0193cbc
f01027b0:	00 80 ef 
		return -E_FAULT;		
f01027b3:	b8 fa ff ff ff       	mov    $0xfffffffa,%eax
f01027b8:	eb 49                	jmp    f0102803 <user_mem_check+0x98>
	}

	pte_t* pteaddr;
	while(xva<lim_va){ 
		if (!page_lookup(env->env_pgdir,(void*) xva,&pteaddr)){	//si no esta alojada o !PTE_P
f01027ba:	83 ec 04             	sub    $0x4,%esp
f01027bd:	57                   	push   %edi
f01027be:	53                   	push   %ebx
f01027bf:	8b 45 08             	mov    0x8(%ebp),%eax
f01027c2:	ff 70 5c             	pushl  0x5c(%eax)
f01027c5:	e8 d3 ef ff ff       	call   f010179d <page_lookup>
f01027ca:	83 c4 10             	add    $0x10,%esp
f01027cd:	85 c0                	test   %eax,%eax
f01027cf:	75 0d                	jne    f01027de <user_mem_check+0x73>
			user_mem_check_addr = xva;
f01027d1:	89 1d bc 3c 19 f0    	mov    %ebx,0xf0193cbc
			return -E_FAULT;
f01027d7:	b8 fa ff ff ff       	mov    $0xfffffffa,%eax
f01027dc:	eb 25                	jmp    f0102803 <user_mem_check+0x98>
		}
		if ((*pteaddr & perm) != perm){ //si no tiene permisos perm (PTE_P ya chequeado)
f01027de:	8b 45 e4             	mov    -0x1c(%ebp),%eax
f01027e1:	89 f2                	mov    %esi,%edx
f01027e3:	23 10                	and    (%eax),%edx
f01027e5:	39 d6                	cmp    %edx,%esi
f01027e7:	74 0d                	je     f01027f6 <user_mem_check+0x8b>
			user_mem_check_addr = xva;
f01027e9:	89 1d bc 3c 19 f0    	mov    %ebx,0xf0193cbc
			return -E_FAULT;
f01027ef:	b8 fa ff ff ff       	mov    $0xfffffffa,%eax
f01027f4:	eb 0d                	jmp    f0102803 <user_mem_check+0x98>
		}
		ROUNDUP(++xva,PGSIZE);
f01027f6:	83 c3 01             	add    $0x1,%ebx
		user_mem_check_addr = ULIM; 
		return -E_FAULT;		
	}

	pte_t* pteaddr;
	while(xva<lim_va){ 
f01027f9:	3b 5d d4             	cmp    -0x2c(%ebp),%ebx
f01027fc:	72 bc                	jb     f01027ba <user_mem_check+0x4f>
			user_mem_check_addr = xva;
			return -E_FAULT;
		}
		ROUNDUP(++xva,PGSIZE);
	}
	return 0;
f01027fe:	b8 00 00 00 00       	mov    $0x0,%eax
}
f0102803:	8d 65 f4             	lea    -0xc(%ebp),%esp
f0102806:	5b                   	pop    %ebx
f0102807:	5e                   	pop    %esi
f0102808:	5f                   	pop    %edi
f0102809:	5d                   	pop    %ebp
f010280a:	c3                   	ret    

f010280b <user_mem_assert>:
// If it cannot, 'env' is destroyed and, if env is the current
// environment, this function will not return.
//
void
user_mem_assert(struct Env *env, const void *va, size_t len, int perm)
{
f010280b:	55                   	push   %ebp
f010280c:	89 e5                	mov    %esp,%ebp
f010280e:	53                   	push   %ebx
f010280f:	83 ec 04             	sub    $0x4,%esp
f0102812:	8b 5d 08             	mov    0x8(%ebp),%ebx
	if (user_mem_check(env, va, len, perm | PTE_U) < 0) {
f0102815:	8b 45 14             	mov    0x14(%ebp),%eax
f0102818:	83 c8 04             	or     $0x4,%eax
f010281b:	50                   	push   %eax
f010281c:	ff 75 10             	pushl  0x10(%ebp)
f010281f:	ff 75 0c             	pushl  0xc(%ebp)
f0102822:	53                   	push   %ebx
f0102823:	e8 43 ff ff ff       	call   f010276b <user_mem_check>
f0102828:	83 c4 10             	add    $0x10,%esp
f010282b:	85 c0                	test   %eax,%eax
f010282d:	79 21                	jns    f0102850 <user_mem_assert+0x45>
		cprintf("[%08x] user_mem_check assertion failure for "
f010282f:	83 ec 04             	sub    $0x4,%esp
f0102832:	ff 35 bc 3c 19 f0    	pushl  0xf0193cbc
f0102838:	ff 73 48             	pushl  0x48(%ebx)
f010283b:	68 18 55 10 f0       	push   $0xf0105518
f0102840:	e8 33 07 00 00       	call   f0102f78 <cprintf>
			"va %08x\n", env->env_id, user_mem_check_addr);
		env_destroy(env);	// may not return
f0102845:	89 1c 24             	mov    %ebx,(%esp)
f0102848:	e8 02 06 00 00       	call   f0102e4f <env_destroy>
f010284d:	83 c4 10             	add    $0x10,%esp
	}
}
f0102850:	8b 5d fc             	mov    -0x4(%ebp),%ebx
f0102853:	c9                   	leave  
f0102854:	c3                   	ret    

f0102855 <lgdt>:
	asm volatile("lidt (%0)" : : "r" (p));
}

static inline void
lgdt(void *p)
{
f0102855:	55                   	push   %ebp
f0102856:	89 e5                	mov    %esp,%ebp
	asm volatile("lgdt (%0)" : : "r" (p));
f0102858:	0f 01 10             	lgdtl  (%eax)
}
f010285b:	5d                   	pop    %ebp
f010285c:	c3                   	ret    

f010285d <lldt>:

static inline void
lldt(uint16_t sel)
{
f010285d:	55                   	push   %ebp
f010285e:	89 e5                	mov    %esp,%ebp
	asm volatile("lldt %0" : : "r" (sel));
f0102860:	0f 00 d0             	lldt   %ax
}
f0102863:	5d                   	pop    %ebp
f0102864:	c3                   	ret    

f0102865 <lcr3>:
	return val;
}

static inline void
lcr3(uint32_t val)
{
f0102865:	55                   	push   %ebp
f0102866:	89 e5                	mov    %esp,%ebp
	asm volatile("movl %0,%%cr3" : : "r" (val));
f0102868:	0f 22 d8             	mov    %eax,%cr3
}
f010286b:	5d                   	pop    %ebp
f010286c:	c3                   	ret    

f010286d <page2pa>:
int	user_mem_check(struct Env *env, const void *va, size_t len, int perm);
void	user_mem_assert(struct Env *env, const void *va, size_t len, int perm);

static inline physaddr_t
page2pa(struct PageInfo *pp)
{
f010286d:	55                   	push   %ebp
f010286e:	89 e5                	mov    %esp,%ebp
	return (pp - pages) << PGSHIFT;
f0102870:	2b 05 8c 59 19 f0    	sub    0xf019598c,%eax
f0102876:	c1 f8 03             	sar    $0x3,%eax
f0102879:	c1 e0 0c             	shl    $0xc,%eax
}
f010287c:	5d                   	pop    %ebp
f010287d:	c3                   	ret    

f010287e <_kaddr>:
 * virtual address.  It panics if you pass an invalid physical address. */
#define KADDR(pa) _kaddr(__FILE__, __LINE__, pa)

static inline void*
_kaddr(const char *file, int line, physaddr_t pa)
{
f010287e:	55                   	push   %ebp
f010287f:	89 e5                	mov    %esp,%ebp
f0102881:	53                   	push   %ebx
f0102882:	83 ec 04             	sub    $0x4,%esp
	if (PGNUM(pa) >= npages)
f0102885:	89 cb                	mov    %ecx,%ebx
f0102887:	c1 eb 0c             	shr    $0xc,%ebx
f010288a:	3b 1d 84 59 19 f0    	cmp    0xf0195984,%ebx
f0102890:	72 0d                	jb     f010289f <_kaddr+0x21>
		_panic(file, line, "KADDR called with invalid pa %08lx", pa);
f0102892:	51                   	push   %ecx
f0102893:	68 a0 4d 10 f0       	push   $0xf0104da0
f0102898:	52                   	push   %edx
f0102899:	50                   	push   %eax
f010289a:	e8 0a d8 ff ff       	call   f01000a9 <_panic>
	return (void *)(pa + KERNBASE);
f010289f:	8d 81 00 00 00 f0    	lea    -0x10000000(%ecx),%eax
}
f01028a5:	8b 5d fc             	mov    -0x4(%ebp),%ebx
f01028a8:	c9                   	leave  
f01028a9:	c3                   	ret    

f01028aa <page2kva>:
	return &pages[PGNUM(pa)];
}

static inline void*
page2kva(struct PageInfo *pp)
{
f01028aa:	55                   	push   %ebp
f01028ab:	89 e5                	mov    %esp,%ebp
f01028ad:	83 ec 08             	sub    $0x8,%esp
	return KADDR(page2pa(pp));
f01028b0:	e8 b8 ff ff ff       	call   f010286d <page2pa>
f01028b5:	89 c1                	mov    %eax,%ecx
f01028b7:	ba 56 00 00 00       	mov    $0x56,%edx
f01028bc:	b8 4d 55 10 f0       	mov    $0xf010554d,%eax
f01028c1:	e8 b8 ff ff ff       	call   f010287e <_kaddr>
}
f01028c6:	c9                   	leave  
f01028c7:	c3                   	ret    

f01028c8 <_paddr>:
#define PADDR(kva) _paddr(__FILE__, __LINE__, kva)

static inline physaddr_t
_paddr(const char *file, int line, void *kva)
{
	if ((uint32_t)kva < KERNBASE)
f01028c8:	81 f9 ff ff ff ef    	cmp    $0xefffffff,%ecx
f01028ce:	77 13                	ja     f01028e3 <_paddr+0x1b>
 */
#define PADDR(kva) _paddr(__FILE__, __LINE__, kva)

static inline physaddr_t
_paddr(const char *file, int line, void *kva)
{
f01028d0:	55                   	push   %ebp
f01028d1:	89 e5                	mov    %esp,%ebp
f01028d3:	83 ec 08             	sub    $0x8,%esp
	if ((uint32_t)kva < KERNBASE)
		_panic(file, line, "PADDR called with invalid kva %08lx", kva);
f01028d6:	51                   	push   %ecx
f01028d7:	68 c4 4d 10 f0       	push   $0xf0104dc4
f01028dc:	52                   	push   %edx
f01028dd:	50                   	push   %eax
f01028de:	e8 c6 d7 ff ff       	call   f01000a9 <_panic>
	return (physaddr_t)kva - KERNBASE;
f01028e3:	8d 81 00 00 00 10    	lea    0x10000000(%ecx),%eax
}
f01028e9:	c3                   	ret    

f01028ea <env_setup_vm>:
// Returns 0 on success, < 0 on error.  Errors include:
//	-E_NO_MEM if page directory or table could not be allocated.
//
static int
env_setup_vm(struct Env *e)
{
f01028ea:	55                   	push   %ebp
f01028eb:	89 e5                	mov    %esp,%ebp
f01028ed:	56                   	push   %esi
f01028ee:	53                   	push   %ebx
f01028ef:	89 c6                	mov    %eax,%esi
	int i;
	struct PageInfo *p = NULL;

	// Allocate a page for the page directory
	if (!(p = page_alloc(ALLOC_ZERO)))
f01028f1:	83 ec 0c             	sub    $0xc,%esp
f01028f4:	6a 01                	push   $0x1
f01028f6:	e8 bf e8 ff ff       	call   f01011ba <page_alloc>
f01028fb:	83 c4 10             	add    $0x10,%esp
f01028fe:	85 c0                	test   %eax,%eax
f0102900:	74 4a                	je     f010294c <env_setup_vm+0x62>
f0102902:	89 c3                	mov    %eax,%ebx
	//	is an exception -- you need to increment env_pgdir's
	//	pp_ref for env_free to work correctly.
	//    - The functions in kern/pmap.h are handy.

	// LAB 3: Your code here.
	e->env_pgdir= page2kva(p);
f0102904:	e8 a1 ff ff ff       	call   f01028aa <page2kva>
f0102909:	89 46 5c             	mov    %eax,0x5c(%esi)
	memcpy(e->env_pgdir,kern_pgdir,PGSIZE);
f010290c:	83 ec 04             	sub    $0x4,%esp
f010290f:	68 00 10 00 00       	push   $0x1000
f0102914:	ff 35 88 59 19 f0    	pushl  0xf0195988
f010291a:	50                   	push   %eax
f010291b:	e8 15 1b 00 00       	call   f0104435 <memcpy>
	p->pp_ref++;
f0102920:	66 83 43 04 01       	addw   $0x1,0x4(%ebx)
	// UVPT maps the env's own page table read-only.
	// Permissions: kernel R, user R
	e->env_pgdir[PDX(UVPT)] = PADDR(e->env_pgdir) | PTE_P | PTE_U;
f0102925:	8b 5e 5c             	mov    0x5c(%esi),%ebx
f0102928:	89 d9                	mov    %ebx,%ecx
f010292a:	ba bf 00 00 00       	mov    $0xbf,%edx
f010292f:	b8 e2 58 10 f0       	mov    $0xf01058e2,%eax
f0102934:	e8 8f ff ff ff       	call   f01028c8 <_paddr>
f0102939:	83 c8 05             	or     $0x5,%eax
f010293c:	89 83 f4 0e 00 00    	mov    %eax,0xef4(%ebx)

	return 0;
f0102942:	83 c4 10             	add    $0x10,%esp
f0102945:	b8 00 00 00 00       	mov    $0x0,%eax
f010294a:	eb 05                	jmp    f0102951 <env_setup_vm+0x67>
	int i;
	struct PageInfo *p = NULL;

	// Allocate a page for the page directory
	if (!(p = page_alloc(ALLOC_ZERO)))
		return -E_NO_MEM;
f010294c:	b8 fc ff ff ff       	mov    $0xfffffffc,%eax
	// UVPT maps the env's own page table read-only.
	// Permissions: kernel R, user R
	e->env_pgdir[PDX(UVPT)] = PADDR(e->env_pgdir) | PTE_P | PTE_U;

	return 0;
}
f0102951:	8d 65 f8             	lea    -0x8(%ebp),%esp
f0102954:	5b                   	pop    %ebx
f0102955:	5e                   	pop    %esi
f0102956:	5d                   	pop    %ebp
f0102957:	c3                   	ret    

f0102958 <pa2page>:
}

static inline struct PageInfo*
pa2page(physaddr_t pa)
{
	if (PGNUM(pa) >= npages)
f0102958:	c1 e8 0c             	shr    $0xc,%eax
f010295b:	3b 05 84 59 19 f0    	cmp    0xf0195984,%eax
f0102961:	72 17                	jb     f010297a <pa2page+0x22>
	return (pp - pages) << PGSHIFT;
}

static inline struct PageInfo*
pa2page(physaddr_t pa)
{
f0102963:	55                   	push   %ebp
f0102964:	89 e5                	mov    %esp,%ebp
f0102966:	83 ec 0c             	sub    $0xc,%esp
	if (PGNUM(pa) >= npages)
		panic("pa2page called with invalid pa");
f0102969:	68 d4 4f 10 f0       	push   $0xf0104fd4
f010296e:	6a 4f                	push   $0x4f
f0102970:	68 4d 55 10 f0       	push   $0xf010554d
f0102975:	e8 2f d7 ff ff       	call   f01000a9 <_panic>
	return &pages[PGNUM(pa)];
f010297a:	8b 15 8c 59 19 f0    	mov    0xf019598c,%edx
f0102980:	8d 04 c2             	lea    (%edx,%eax,8),%eax
}
f0102983:	c3                   	ret    

f0102984 <region_alloc>:
	//   You should round va down, and round (va + len) up.
	//   (Watch out for corner-cases!)
	void* in = ROUNDDOWN(va,PGSIZE);
	void* fin = ROUNDUP(va + len,PGSIZE);
	struct PageInfo * p;
	if(len==0)
f0102984:	85 c9                	test   %ecx,%ecx
f0102986:	0f 84 85 00 00 00    	je     f0102a11 <region_alloc+0x8d>
// Pages should be writable by user and kernel.
// Panic if any allocation attempt fails.
//
static void
region_alloc(struct Env *e, void *va, size_t len)
{
f010298c:	55                   	push   %ebp
f010298d:	89 e5                	mov    %esp,%ebp
f010298f:	57                   	push   %edi
f0102990:	56                   	push   %esi
f0102991:	53                   	push   %ebx
f0102992:	83 ec 0c             	sub    $0xc,%esp
f0102995:	89 c7                	mov    %eax,%edi
	//
	// Hint: It is easier to use region_alloc if the caller can pass
	//   'va' and 'len' values that are not page-aligned.
	//   You should round va down, and round (va + len) up.
	//   (Watch out for corner-cases!)
	void* in = ROUNDDOWN(va,PGSIZE);
f0102997:	89 d3                	mov    %edx,%ebx
f0102999:	81 e3 00 f0 ff ff    	and    $0xfffff000,%ebx
	void* fin = ROUNDUP(va + len,PGSIZE);
f010299f:	8d b4 0a ff 0f 00 00 	lea    0xfff(%edx,%ecx,1),%esi
f01029a6:	81 e6 00 f0 ff ff    	and    $0xfffff000,%esi
f01029ac:	eb 58                	jmp    f0102a06 <region_alloc+0x82>
	struct PageInfo * p;
	if(len==0)
		return;
	for(void* i = in ; i < fin ; i+=PGSIZE){
		if(!(p = page_alloc(0)))
f01029ae:	83 ec 0c             	sub    $0xc,%esp
f01029b1:	6a 00                	push   $0x0
f01029b3:	e8 02 e8 ff ff       	call   f01011ba <page_alloc>
f01029b8:	83 c4 10             	add    $0x10,%esp
f01029bb:	85 c0                	test   %eax,%eax
f01029bd:	75 17                	jne    f01029d6 <region_alloc+0x52>
			panic("Page Alloc Fail:region_alloc");
f01029bf:	83 ec 04             	sub    $0x4,%esp
f01029c2:	68 ed 58 10 f0       	push   $0xf01058ed
f01029c7:	68 1b 01 00 00       	push   $0x11b
f01029cc:	68 e2 58 10 f0       	push   $0xf01058e2
f01029d1:	e8 d3 d6 ff ff       	call   f01000a9 <_panic>
		if(page_insert(e->env_pgdir,p,i,PTE_U | PTE_W ))
f01029d6:	6a 06                	push   $0x6
f01029d8:	53                   	push   %ebx
f01029d9:	50                   	push   %eax
f01029da:	ff 77 5c             	pushl  0x5c(%edi)
f01029dd:	e8 56 ee ff ff       	call   f0101838 <page_insert>
f01029e2:	83 c4 10             	add    $0x10,%esp
f01029e5:	85 c0                	test   %eax,%eax
f01029e7:	74 17                	je     f0102a00 <region_alloc+0x7c>
			panic("Page Insert Fail: region_alloc");
f01029e9:	83 ec 04             	sub    $0x4,%esp
f01029ec:	68 8c 58 10 f0       	push   $0xf010588c
f01029f1:	68 1d 01 00 00       	push   $0x11d
f01029f6:	68 e2 58 10 f0       	push   $0xf01058e2
f01029fb:	e8 a9 d6 ff ff       	call   f01000a9 <_panic>
	void* in = ROUNDDOWN(va,PGSIZE);
	void* fin = ROUNDUP(va + len,PGSIZE);
	struct PageInfo * p;
	if(len==0)
		return;
	for(void* i = in ; i < fin ; i+=PGSIZE){
f0102a00:	81 c3 00 10 00 00    	add    $0x1000,%ebx
f0102a06:	39 f3                	cmp    %esi,%ebx
f0102a08:	72 a4                	jb     f01029ae <region_alloc+0x2a>
		if(!(p = page_alloc(0)))
			panic("Page Alloc Fail:region_alloc");
		if(page_insert(e->env_pgdir,p,i,PTE_U | PTE_W ))
			panic("Page Insert Fail: region_alloc");
	}
}
f0102a0a:	8d 65 f4             	lea    -0xc(%ebp),%esp
f0102a0d:	5b                   	pop    %ebx
f0102a0e:	5e                   	pop    %esi
f0102a0f:	5f                   	pop    %edi
f0102a10:	5d                   	pop    %ebp
f0102a11:	f3 c3                	repz ret 

f0102a13 <load_icode>:
// load_icode panics if it encounters problems.
//  - How might load_icode fail?  What might be wrong with the given input?
//
static void
load_icode(struct Env *e, uint8_t *binary)
{
f0102a13:	55                   	push   %ebp
f0102a14:	89 e5                	mov    %esp,%ebp
f0102a16:	57                   	push   %edi
f0102a17:	56                   	push   %esi
f0102a18:	53                   	push   %ebx
f0102a19:	83 ec 1c             	sub    $0x1c,%esp
f0102a1c:	89 45 e4             	mov    %eax,-0x1c(%ebp)
	//  What?  (See env_run() and env_pop_tf() below.)

	// LAB 3: Your code here.
	struct Proghdr *ph,*eph;
	struct Elf* elf_file= (struct Elf*)binary;
	if(elf_file->e_magic != ELF_MAGIC)
f0102a1f:	81 3a 7f 45 4c 46    	cmpl   $0x464c457f,(%edx)
f0102a25:	74 17                	je     f0102a3e <load_icode+0x2b>
		panic("You have been a very bad elf.");
f0102a27:	83 ec 04             	sub    $0x4,%esp
f0102a2a:	68 0a 59 10 f0       	push   $0xf010590a
f0102a2f:	68 5a 01 00 00       	push   $0x15a
f0102a34:	68 e2 58 10 f0       	push   $0xf01058e2
f0102a39:	e8 6b d6 ff ff       	call   f01000a9 <_panic>
f0102a3e:	89 d7                	mov    %edx,%edi
	ph = (struct Proghdr *)((uint8_t *)elf_file + elf_file->e_phoff);
f0102a40:	89 d3                	mov    %edx,%ebx
f0102a42:	03 5a 1c             	add    0x1c(%edx),%ebx
	eph = ph + elf_file->e_phnum;
f0102a45:	0f b7 72 2c          	movzwl 0x2c(%edx),%esi
f0102a49:	c1 e6 05             	shl    $0x5,%esi
f0102a4c:	01 de                	add    %ebx,%esi
	pde_t* aux_pgdir = kern_pgdir;
f0102a4e:	a1 88 59 19 f0       	mov    0xf0195988,%eax
f0102a53:	89 45 e0             	mov    %eax,-0x20(%ebp)
	lcr3(PADDR(e->env_pgdir));
f0102a56:	8b 45 e4             	mov    -0x1c(%ebp),%eax
f0102a59:	8b 48 5c             	mov    0x5c(%eax),%ecx
f0102a5c:	ba 5e 01 00 00       	mov    $0x15e,%edx
f0102a61:	b8 e2 58 10 f0       	mov    $0xf01058e2,%eax
f0102a66:	e8 5d fe ff ff       	call   f01028c8 <_paddr>
f0102a6b:	e8 f5 fd ff ff       	call   f0102865 <lcr3>
	for(; ph < eph; ph++){
f0102a70:	eb 44                	jmp    f0102ab6 <load_icode+0xa3>
		if(ph->p_type == ELF_PROG_LOAD){
f0102a72:	83 3b 01             	cmpl   $0x1,(%ebx)
f0102a75:	75 3c                	jne    f0102ab3 <load_icode+0xa0>
			region_alloc(e,(void *)ph->p_va,ph->p_memsz);
f0102a77:	8b 4b 14             	mov    0x14(%ebx),%ecx
f0102a7a:	8b 53 08             	mov    0x8(%ebx),%edx
f0102a7d:	8b 45 e4             	mov    -0x1c(%ebp),%eax
f0102a80:	e8 ff fe ff ff       	call   f0102984 <region_alloc>
			memcpy((void *)ph->p_va,binary+ph->p_offset,ph->p_filesz);
f0102a85:	83 ec 04             	sub    $0x4,%esp
f0102a88:	ff 73 10             	pushl  0x10(%ebx)
f0102a8b:	89 f8                	mov    %edi,%eax
f0102a8d:	03 43 04             	add    0x4(%ebx),%eax
f0102a90:	50                   	push   %eax
f0102a91:	ff 73 08             	pushl  0x8(%ebx)
f0102a94:	e8 9c 19 00 00       	call   f0104435 <memcpy>
			memset((void *)ph->p_va+ph->p_filesz,0,ph->p_memsz-ph->p_filesz);
f0102a99:	8b 43 10             	mov    0x10(%ebx),%eax
f0102a9c:	83 c4 0c             	add    $0xc,%esp
f0102a9f:	8b 53 14             	mov    0x14(%ebx),%edx
f0102aa2:	29 c2                	sub    %eax,%edx
f0102aa4:	52                   	push   %edx
f0102aa5:	6a 00                	push   $0x0
f0102aa7:	03 43 08             	add    0x8(%ebx),%eax
f0102aaa:	50                   	push   %eax
f0102aab:	e8 cf 18 00 00       	call   f010437f <memset>
f0102ab0:	83 c4 10             	add    $0x10,%esp
		panic("You have been a very bad elf.");
	ph = (struct Proghdr *)((uint8_t *)elf_file + elf_file->e_phoff);
	eph = ph + elf_file->e_phnum;
	pde_t* aux_pgdir = kern_pgdir;
	lcr3(PADDR(e->env_pgdir));
	for(; ph < eph; ph++){
f0102ab3:	83 c3 20             	add    $0x20,%ebx
f0102ab6:	39 f3                	cmp    %esi,%ebx
f0102ab8:	72 b8                	jb     f0102a72 <load_icode+0x5f>
	// Now map one page for the program's initial stack
	// at virtual address USTACKTOP - PGSIZE.

	// LAB 3: Your code here.
	void* ustack_va = (void*)(USTACKTOP-PGSIZE);
	region_alloc(e,ustack_va,PGSIZE);
f0102aba:	b9 00 10 00 00       	mov    $0x1000,%ecx
f0102abf:	ba 00 d0 bf ee       	mov    $0xeebfd000,%edx
f0102ac4:	8b 75 e4             	mov    -0x1c(%ebp),%esi
f0102ac7:	89 f0                	mov    %esi,%eax
f0102ac9:	e8 b6 fe ff ff       	call   f0102984 <region_alloc>
	e->env_tf.tf_eip = elf_file->e_entry;
f0102ace:	8b 47 18             	mov    0x18(%edi),%eax
f0102ad1:	89 46 30             	mov    %eax,0x30(%esi)
	lcr3(PADDR(aux_pgdir));
f0102ad4:	8b 4d e0             	mov    -0x20(%ebp),%ecx
f0102ad7:	ba 6e 01 00 00       	mov    $0x16e,%edx
f0102adc:	b8 e2 58 10 f0       	mov    $0xf01058e2,%eax
f0102ae1:	e8 e2 fd ff ff       	call   f01028c8 <_paddr>
f0102ae6:	e8 7a fd ff ff       	call   f0102865 <lcr3>
}
f0102aeb:	8d 65 f4             	lea    -0xc(%ebp),%esp
f0102aee:	5b                   	pop    %ebx
f0102aef:	5e                   	pop    %esi
f0102af0:	5f                   	pop    %edi
f0102af1:	5d                   	pop    %ebp
f0102af2:	c3                   	ret    

f0102af3 <envid2env>:
//   On success, sets *env_store to the environment.
//   On error, sets *env_store to NULL.
//
int
envid2env(envid_t envid, struct Env **env_store, bool checkperm)
{
f0102af3:	55                   	push   %ebp
f0102af4:	89 e5                	mov    %esp,%ebp
f0102af6:	8b 55 08             	mov    0x8(%ebp),%edx
f0102af9:	8b 4d 10             	mov    0x10(%ebp),%ecx
	struct Env *e;

	// If envid is zero, return the current environment.
	if (envid == 0) {
f0102afc:	85 d2                	test   %edx,%edx
f0102afe:	75 11                	jne    f0102b11 <envid2env+0x1e>
		*env_store = curenv;
f0102b00:	a1 c4 3c 19 f0       	mov    0xf0193cc4,%eax
f0102b05:	8b 4d 0c             	mov    0xc(%ebp),%ecx
f0102b08:	89 01                	mov    %eax,(%ecx)
		return 0;
f0102b0a:	b8 00 00 00 00       	mov    $0x0,%eax
f0102b0f:	eb 5e                	jmp    f0102b6f <envid2env+0x7c>
	// Look up the Env structure via the index part of the envid,
	// then check the env_id field in that struct Env
	// to ensure that the envid is not stale
	// (i.e., does not refer to a _previous_ environment
	// that used the same slot in the envs[] array).
	e = &envs[ENVX(envid)];
f0102b11:	89 d0                	mov    %edx,%eax
f0102b13:	25 ff 03 00 00       	and    $0x3ff,%eax
f0102b18:	8d 04 40             	lea    (%eax,%eax,2),%eax
f0102b1b:	c1 e0 05             	shl    $0x5,%eax
f0102b1e:	03 05 c8 3c 19 f0    	add    0xf0193cc8,%eax
	if (e->env_status == ENV_FREE || e->env_id != envid) {
f0102b24:	83 78 54 00          	cmpl   $0x0,0x54(%eax)
f0102b28:	74 05                	je     f0102b2f <envid2env+0x3c>
f0102b2a:	3b 50 48             	cmp    0x48(%eax),%edx
f0102b2d:	74 10                	je     f0102b3f <envid2env+0x4c>
		*env_store = 0;
f0102b2f:	8b 45 0c             	mov    0xc(%ebp),%eax
f0102b32:	c7 00 00 00 00 00    	movl   $0x0,(%eax)
		return -E_BAD_ENV;
f0102b38:	b8 fe ff ff ff       	mov    $0xfffffffe,%eax
f0102b3d:	eb 30                	jmp    f0102b6f <envid2env+0x7c>
	// Check that the calling environment has legitimate permission
	// to manipulate the specified environment.
	// If checkperm is set, the specified environment
	// must be either the current environment
	// or an immediate child of the current environment.
	if (checkperm && e != curenv && e->env_parent_id != curenv->env_id) {
f0102b3f:	84 c9                	test   %cl,%cl
f0102b41:	74 22                	je     f0102b65 <envid2env+0x72>
f0102b43:	8b 15 c4 3c 19 f0    	mov    0xf0193cc4,%edx
f0102b49:	39 d0                	cmp    %edx,%eax
f0102b4b:	74 18                	je     f0102b65 <envid2env+0x72>
f0102b4d:	8b 4a 48             	mov    0x48(%edx),%ecx
f0102b50:	39 48 4c             	cmp    %ecx,0x4c(%eax)
f0102b53:	74 10                	je     f0102b65 <envid2env+0x72>
		*env_store = 0;
f0102b55:	8b 45 0c             	mov    0xc(%ebp),%eax
f0102b58:	c7 00 00 00 00 00    	movl   $0x0,(%eax)
		return -E_BAD_ENV;
f0102b5e:	b8 fe ff ff ff       	mov    $0xfffffffe,%eax
f0102b63:	eb 0a                	jmp    f0102b6f <envid2env+0x7c>
	}

	*env_store = e;
f0102b65:	8b 4d 0c             	mov    0xc(%ebp),%ecx
f0102b68:	89 01                	mov    %eax,(%ecx)
	return 0;
f0102b6a:	b8 00 00 00 00       	mov    $0x0,%eax
}
f0102b6f:	5d                   	pop    %ebp
f0102b70:	c3                   	ret    

f0102b71 <env_init_percpu>:
}

// Load GDT and segment descriptors.
void
env_init_percpu(void)
{
f0102b71:	55                   	push   %ebp
f0102b72:	89 e5                	mov    %esp,%ebp
	lgdt(&gdt_pd);
f0102b74:	b8 00 03 11 f0       	mov    $0xf0110300,%eax
f0102b79:	e8 d7 fc ff ff       	call   f0102855 <lgdt>
	// The kernel never uses GS or FS, so we leave those set to
	// the user data segment.
	asm volatile("movw %%ax,%%gs" : : "a"(GD_UD | 3));
f0102b7e:	b8 23 00 00 00       	mov    $0x23,%eax
f0102b83:	8e e8                	mov    %eax,%gs
	asm volatile("movw %%ax,%%fs" : : "a"(GD_UD | 3));
f0102b85:	8e e0                	mov    %eax,%fs
	// The kernel does use ES, DS, and SS.  We'll change between
	// the kernel and user data segments as needed.
	asm volatile("movw %%ax,%%es" : : "a"(GD_KD));
f0102b87:	b8 10 00 00 00       	mov    $0x10,%eax
f0102b8c:	8e c0                	mov    %eax,%es
	asm volatile("movw %%ax,%%ds" : : "a"(GD_KD));
f0102b8e:	8e d8                	mov    %eax,%ds
	asm volatile("movw %%ax,%%ss" : : "a"(GD_KD));
f0102b90:	8e d0                	mov    %eax,%ss
	// Load the kernel text segment into CS.
	asm volatile("ljmp %0,$1f\n 1:\n" : : "i"(GD_KT));
f0102b92:	ea 99 2b 10 f0 08 00 	ljmp   $0x8,$0xf0102b99
	// For good measure, clear the local descriptor table (LDT),
	// since we don't use it.
	lldt(0);
f0102b99:	b8 00 00 00 00       	mov    $0x0,%eax
f0102b9e:	e8 ba fc ff ff       	call   f010285d <lldt>
}
f0102ba3:	5d                   	pop    %ebp
f0102ba4:	c3                   	ret    

f0102ba5 <env_init>:
void
env_init(void)
{
	// Set up envs array
	// LAB 3: Your code here.
	env_free_list = &envs[0];
f0102ba5:	8b 0d c8 3c 19 f0    	mov    0xf0193cc8,%ecx
f0102bab:	89 0d cc 3c 19 f0    	mov    %ecx,0xf0193ccc
f0102bb1:	8d 41 60             	lea    0x60(%ecx),%eax
f0102bb4:	8d 91 00 80 01 00    	lea    0x18000(%ecx),%edx
	for(int i=0;i<NENV-1;i++){
		envs[i].env_status = ENV_FREE;
f0102bba:	c7 40 f4 00 00 00 00 	movl   $0x0,-0xc(%eax)
		envs[i].env_link = &envs[i+1];
f0102bc1:	89 40 e4             	mov    %eax,-0x1c(%eax)
		envs[i].env_id =0;
f0102bc4:	c7 40 e8 00 00 00 00 	movl   $0x0,-0x18(%eax)
f0102bcb:	83 c0 60             	add    $0x60,%eax
env_init(void)
{
	// Set up envs array
	// LAB 3: Your code here.
	env_free_list = &envs[0];
	for(int i=0;i<NENV-1;i++){
f0102bce:	39 d0                	cmp    %edx,%eax
f0102bd0:	75 e8                	jne    f0102bba <env_init+0x15>
// they are in the envs array (i.e., so that the first call to
// env_alloc() returns envs[0]).
//
void
env_init(void)
{
f0102bd2:	55                   	push   %ebp
f0102bd3:	89 e5                	mov    %esp,%ebp
	for(int i=0;i<NENV-1;i++){
		envs[i].env_status = ENV_FREE;
		envs[i].env_link = &envs[i+1];
		envs[i].env_id =0;
	}
	envs[NENV-1].env_status = ENV_FREE;
f0102bd5:	c7 81 f4 7f 01 00 00 	movl   $0x0,0x17ff4(%ecx)
f0102bdc:	00 00 00 
	envs[NENV-1].env_id =0;
f0102bdf:	c7 81 e8 7f 01 00 00 	movl   $0x0,0x17fe8(%ecx)
f0102be6:	00 00 00 
	// Per-CPU part of the initialization
	env_init_percpu();
f0102be9:	e8 83 ff ff ff       	call   f0102b71 <env_init_percpu>
}
f0102bee:	5d                   	pop    %ebp
f0102bef:	c3                   	ret    

f0102bf0 <env_alloc>:
//	-E_NO_FREE_ENV if all NENVS environments are allocated
//	-E_NO_MEM on memory exhaustion
//
int
env_alloc(struct Env **newenv_store, envid_t parent_id)
{
f0102bf0:	55                   	push   %ebp
f0102bf1:	89 e5                	mov    %esp,%ebp
f0102bf3:	53                   	push   %ebx
f0102bf4:	83 ec 04             	sub    $0x4,%esp
	int32_t generation;
	int r;
	struct Env *e;

	if (!(e = env_free_list))
f0102bf7:	8b 1d cc 3c 19 f0    	mov    0xf0193ccc,%ebx
f0102bfd:	85 db                	test   %ebx,%ebx
f0102bff:	0f 84 c0 00 00 00    	je     f0102cc5 <env_alloc+0xd5>
		return -E_NO_FREE_ENV;

	// Allocate and set up the page directory for this environment.
	if ((r = env_setup_vm(e)) < 0)
f0102c05:	89 d8                	mov    %ebx,%eax
f0102c07:	e8 de fc ff ff       	call   f01028ea <env_setup_vm>
f0102c0c:	85 c0                	test   %eax,%eax
f0102c0e:	0f 88 b6 00 00 00    	js     f0102cca <env_alloc+0xda>
		return r;

	// Generate an env_id for this environment.
	generation = (e->env_id + (1 << ENVGENSHIFT)) & ~(NENV - 1);
f0102c14:	8b 43 48             	mov    0x48(%ebx),%eax
f0102c17:	05 00 10 00 00       	add    $0x1000,%eax
	if (generation <= 0)  // Don't create a negative env_id.
f0102c1c:	25 00 fc ff ff       	and    $0xfffffc00,%eax
		generation = 1 << ENVGENSHIFT;
f0102c21:	ba 00 10 00 00       	mov    $0x1000,%edx
f0102c26:	0f 4e c2             	cmovle %edx,%eax
	e->env_id = generation | (e - envs);
f0102c29:	89 da                	mov    %ebx,%edx
f0102c2b:	2b 15 c8 3c 19 f0    	sub    0xf0193cc8,%edx
f0102c31:	c1 fa 05             	sar    $0x5,%edx
f0102c34:	69 d2 ab aa aa aa    	imul   $0xaaaaaaab,%edx,%edx
f0102c3a:	09 d0                	or     %edx,%eax
f0102c3c:	89 43 48             	mov    %eax,0x48(%ebx)

	// Set the basic status variables.
	e->env_parent_id = parent_id;
f0102c3f:	8b 45 0c             	mov    0xc(%ebp),%eax
f0102c42:	89 43 4c             	mov    %eax,0x4c(%ebx)
	e->env_type = ENV_TYPE_USER;
f0102c45:	c7 43 50 00 00 00 00 	movl   $0x0,0x50(%ebx)
	e->env_status = ENV_RUNNABLE;
f0102c4c:	c7 43 54 02 00 00 00 	movl   $0x2,0x54(%ebx)
	e->env_runs = 0;
f0102c53:	c7 43 58 00 00 00 00 	movl   $0x0,0x58(%ebx)

	// Clear out all the saved register state,
	// to prevent the register values
	// of a prior environment inhabiting this Env structure
	// from "leaking" into our new environment.
	memset(&e->env_tf, 0, sizeof(e->env_tf));
f0102c5a:	83 ec 04             	sub    $0x4,%esp
f0102c5d:	6a 44                	push   $0x44
f0102c5f:	6a 00                	push   $0x0
f0102c61:	53                   	push   %ebx
f0102c62:	e8 18 17 00 00       	call   f010437f <memset>
	// The low 2 bits of each segment register contains the
	// Requestor Privilege Level (RPL); 3 means user mode.  When
	// we switch privilege levels, the hardware does various
	// checks involving the RPL and the Descriptor Privilege Level
	// (DPL) stored in the descriptors themselves.
	e->env_tf.tf_ds = GD_UD | 3;
f0102c67:	66 c7 43 24 23 00    	movw   $0x23,0x24(%ebx)
	e->env_tf.tf_es = GD_UD | 3;
f0102c6d:	66 c7 43 20 23 00    	movw   $0x23,0x20(%ebx)
	e->env_tf.tf_ss = GD_UD | 3;
f0102c73:	66 c7 43 40 23 00    	movw   $0x23,0x40(%ebx)
	e->env_tf.tf_esp = USTACKTOP;
f0102c79:	c7 43 3c 00 e0 bf ee 	movl   $0xeebfe000,0x3c(%ebx)
	e->env_tf.tf_cs = GD_UT | 3;
f0102c80:	66 c7 43 34 1b 00    	movw   $0x1b,0x34(%ebx)
	// You will set e->env_tf.tf_eip later.

	// commit the allocation
	env_free_list = e->env_link;
f0102c86:	8b 43 44             	mov    0x44(%ebx),%eax
f0102c89:	a3 cc 3c 19 f0       	mov    %eax,0xf0193ccc
	*newenv_store = e;
f0102c8e:	8b 45 08             	mov    0x8(%ebp),%eax
f0102c91:	89 18                	mov    %ebx,(%eax)

	cprintf("[%08x] new env %08x\n", curenv ? curenv->env_id : 0, e->env_id);
f0102c93:	8b 53 48             	mov    0x48(%ebx),%edx
f0102c96:	a1 c4 3c 19 f0       	mov    0xf0193cc4,%eax
f0102c9b:	83 c4 10             	add    $0x10,%esp
f0102c9e:	85 c0                	test   %eax,%eax
f0102ca0:	74 05                	je     f0102ca7 <env_alloc+0xb7>
f0102ca2:	8b 40 48             	mov    0x48(%eax),%eax
f0102ca5:	eb 05                	jmp    f0102cac <env_alloc+0xbc>
f0102ca7:	b8 00 00 00 00       	mov    $0x0,%eax
f0102cac:	83 ec 04             	sub    $0x4,%esp
f0102caf:	52                   	push   %edx
f0102cb0:	50                   	push   %eax
f0102cb1:	68 28 59 10 f0       	push   $0xf0105928
f0102cb6:	e8 bd 02 00 00       	call   f0102f78 <cprintf>
	return 0;
f0102cbb:	83 c4 10             	add    $0x10,%esp
f0102cbe:	b8 00 00 00 00       	mov    $0x0,%eax
f0102cc3:	eb 05                	jmp    f0102cca <env_alloc+0xda>
	int32_t generation;
	int r;
	struct Env *e;

	if (!(e = env_free_list))
		return -E_NO_FREE_ENV;
f0102cc5:	b8 fb ff ff ff       	mov    $0xfffffffb,%eax
	env_free_list = e->env_link;
	*newenv_store = e;

	cprintf("[%08x] new env %08x\n", curenv ? curenv->env_id : 0, e->env_id);
	return 0;
}
f0102cca:	8b 5d fc             	mov    -0x4(%ebp),%ebx
f0102ccd:	c9                   	leave  
f0102cce:	c3                   	ret    

f0102ccf <env_create>:
// before running the first user-mode environment.
// The new env's parent ID is set to 0.
//
void
env_create(uint8_t *binary, enum EnvType type)
{
f0102ccf:	55                   	push   %ebp
f0102cd0:	89 e5                	mov    %esp,%ebp
f0102cd2:	83 ec 20             	sub    $0x20,%esp
	// LAB 3: Your code here.
	struct Env* new_env;
	int err = env_alloc(&new_env,0);
f0102cd5:	6a 00                	push   $0x0
f0102cd7:	8d 45 f4             	lea    -0xc(%ebp),%eax
f0102cda:	50                   	push   %eax
f0102cdb:	e8 10 ff ff ff       	call   f0102bf0 <env_alloc>
	if(err < 0)
f0102ce0:	83 c4 10             	add    $0x10,%esp
f0102ce3:	85 c0                	test   %eax,%eax
f0102ce5:	79 15                	jns    f0102cfc <env_create+0x2d>
		panic("env_create: %e ",err);
f0102ce7:	50                   	push   %eax
f0102ce8:	68 3d 59 10 f0       	push   $0xf010593d
f0102ced:	68 7f 01 00 00       	push   $0x17f
f0102cf2:	68 e2 58 10 f0       	push   $0xf01058e2
f0102cf7:	e8 ad d3 ff ff       	call   f01000a9 <_panic>
	load_icode(new_env,binary);
f0102cfc:	8b 55 08             	mov    0x8(%ebp),%edx
f0102cff:	8b 45 f4             	mov    -0xc(%ebp),%eax
f0102d02:	e8 0c fd ff ff       	call   f0102a13 <load_icode>
	new_env->env_type = type;
f0102d07:	8b 45 f4             	mov    -0xc(%ebp),%eax
f0102d0a:	8b 55 0c             	mov    0xc(%ebp),%edx
f0102d0d:	89 50 50             	mov    %edx,0x50(%eax)
}
f0102d10:	c9                   	leave  
f0102d11:	c3                   	ret    

f0102d12 <env_free>:
//
// Frees env e and all memory it uses.
//
void
env_free(struct Env *e)
{
f0102d12:	55                   	push   %ebp
f0102d13:	89 e5                	mov    %esp,%ebp
f0102d15:	57                   	push   %edi
f0102d16:	56                   	push   %esi
f0102d17:	53                   	push   %ebx
f0102d18:	83 ec 1c             	sub    $0x1c,%esp
f0102d1b:	8b 7d 08             	mov    0x8(%ebp),%edi
	physaddr_t pa;

	// If freeing the current environment, switch to kern_pgdir
	// before freeing the page directory, just in case the page
	// gets reused.
	if (e == curenv)
f0102d1e:	39 3d c4 3c 19 f0    	cmp    %edi,0xf0193cc4
f0102d24:	75 1a                	jne    f0102d40 <env_free+0x2e>
		lcr3(PADDR(kern_pgdir));
f0102d26:	8b 0d 88 59 19 f0    	mov    0xf0195988,%ecx
f0102d2c:	ba 92 01 00 00       	mov    $0x192,%edx
f0102d31:	b8 e2 58 10 f0       	mov    $0xf01058e2,%eax
f0102d36:	e8 8d fb ff ff       	call   f01028c8 <_paddr>
f0102d3b:	e8 25 fb ff ff       	call   f0102865 <lcr3>

	// Note the environment's demise.
	cprintf("[%08x] free env %08x\n", curenv ? curenv->env_id : 0, e->env_id);
f0102d40:	8b 57 48             	mov    0x48(%edi),%edx
f0102d43:	a1 c4 3c 19 f0       	mov    0xf0193cc4,%eax
f0102d48:	85 c0                	test   %eax,%eax
f0102d4a:	74 05                	je     f0102d51 <env_free+0x3f>
f0102d4c:	8b 40 48             	mov    0x48(%eax),%eax
f0102d4f:	eb 05                	jmp    f0102d56 <env_free+0x44>
f0102d51:	b8 00 00 00 00       	mov    $0x0,%eax
f0102d56:	83 ec 04             	sub    $0x4,%esp
f0102d59:	52                   	push   %edx
f0102d5a:	50                   	push   %eax
f0102d5b:	68 4d 59 10 f0       	push   $0xf010594d
f0102d60:	e8 13 02 00 00       	call   f0102f78 <cprintf>
f0102d65:	83 c4 10             	add    $0x10,%esp

	// Flush all mapped pages in the user portion of the address space
	static_assert(UTOP % PTSIZE == 0);
	for (pdeno = 0; pdeno < PDX(UTOP); pdeno++) {
f0102d68:	c7 45 e0 00 00 00 00 	movl   $0x0,-0x20(%ebp)
f0102d6f:	8b 4d e0             	mov    -0x20(%ebp),%ecx
f0102d72:	89 c8                	mov    %ecx,%eax
f0102d74:	c1 e0 02             	shl    $0x2,%eax
f0102d77:	89 45 dc             	mov    %eax,-0x24(%ebp)
		// only look at mapped page tables
		if (!(e->env_pgdir[pdeno] & PTE_P))
f0102d7a:	8b 47 5c             	mov    0x5c(%edi),%eax
f0102d7d:	8b 04 88             	mov    (%eax,%ecx,4),%eax
f0102d80:	a8 01                	test   $0x1,%al
f0102d82:	74 72                	je     f0102df6 <env_free+0xe4>
			continue;

		// find the pa and va of the page table
		pa = PTE_ADDR(e->env_pgdir[pdeno]);
f0102d84:	25 00 f0 ff ff       	and    $0xfffff000,%eax
f0102d89:	89 45 d8             	mov    %eax,-0x28(%ebp)
		pt = (pte_t *) KADDR(pa);
f0102d8c:	89 c1                	mov    %eax,%ecx
f0102d8e:	ba a0 01 00 00       	mov    $0x1a0,%edx
f0102d93:	b8 e2 58 10 f0       	mov    $0xf01058e2,%eax
f0102d98:	e8 e1 fa ff ff       	call   f010287e <_kaddr>
f0102d9d:	89 c6                	mov    %eax,%esi

		// unmap all PTEs in this page table
		for (pteno = 0; pteno <= PTX(~0); pteno++) {
			if (pt[pteno] & PTE_P)
				page_remove(e->env_pgdir, PGADDR(pdeno, pteno, 0));
f0102d9f:	8b 45 e0             	mov    -0x20(%ebp),%eax
f0102da2:	c1 e0 16             	shl    $0x16,%eax
f0102da5:	89 45 e4             	mov    %eax,-0x1c(%ebp)
		// find the pa and va of the page table
		pa = PTE_ADDR(e->env_pgdir[pdeno]);
		pt = (pte_t *) KADDR(pa);

		// unmap all PTEs in this page table
		for (pteno = 0; pteno <= PTX(~0); pteno++) {
f0102da8:	bb 00 00 00 00       	mov    $0x0,%ebx
			if (pt[pteno] & PTE_P)
f0102dad:	f6 04 9e 01          	testb  $0x1,(%esi,%ebx,4)
f0102db1:	74 17                	je     f0102dca <env_free+0xb8>
				page_remove(e->env_pgdir, PGADDR(pdeno, pteno, 0));
f0102db3:	83 ec 08             	sub    $0x8,%esp
f0102db6:	89 d8                	mov    %ebx,%eax
f0102db8:	c1 e0 0c             	shl    $0xc,%eax
f0102dbb:	0b 45 e4             	or     -0x1c(%ebp),%eax
f0102dbe:	50                   	push   %eax
f0102dbf:	ff 77 5c             	pushl  0x5c(%edi)
f0102dc2:	e8 2b ea ff ff       	call   f01017f2 <page_remove>
f0102dc7:	83 c4 10             	add    $0x10,%esp
		// find the pa and va of the page table
		pa = PTE_ADDR(e->env_pgdir[pdeno]);
		pt = (pte_t *) KADDR(pa);

		// unmap all PTEs in this page table
		for (pteno = 0; pteno <= PTX(~0); pteno++) {
f0102dca:	83 c3 01             	add    $0x1,%ebx
f0102dcd:	81 fb 00 04 00 00    	cmp    $0x400,%ebx
f0102dd3:	75 d8                	jne    f0102dad <env_free+0x9b>
			if (pt[pteno] & PTE_P)
				page_remove(e->env_pgdir, PGADDR(pdeno, pteno, 0));
		}

		// free the page table itself
		e->env_pgdir[pdeno] = 0;
f0102dd5:	8b 47 5c             	mov    0x5c(%edi),%eax
f0102dd8:	8b 4d dc             	mov    -0x24(%ebp),%ecx
f0102ddb:	c7 04 08 00 00 00 00 	movl   $0x0,(%eax,%ecx,1)
		page_decref(pa2page(pa));
f0102de2:	8b 45 d8             	mov    -0x28(%ebp),%eax
f0102de5:	e8 6e fb ff ff       	call   f0102958 <pa2page>
f0102dea:	83 ec 0c             	sub    $0xc,%esp
f0102ded:	50                   	push   %eax
f0102dee:	e8 2b e8 ff ff       	call   f010161e <page_decref>
f0102df3:	83 c4 10             	add    $0x10,%esp
	// Note the environment's demise.
	cprintf("[%08x] free env %08x\n", curenv ? curenv->env_id : 0, e->env_id);

	// Flush all mapped pages in the user portion of the address space
	static_assert(UTOP % PTSIZE == 0);
	for (pdeno = 0; pdeno < PDX(UTOP); pdeno++) {
f0102df6:	83 45 e0 01          	addl   $0x1,-0x20(%ebp)
f0102dfa:	8b 45 e0             	mov    -0x20(%ebp),%eax
f0102dfd:	3d bb 03 00 00       	cmp    $0x3bb,%eax
f0102e02:	0f 85 67 ff ff ff    	jne    f0102d6f <env_free+0x5d>
		e->env_pgdir[pdeno] = 0;
		page_decref(pa2page(pa));
	}

	// free the page directory
	pa = PADDR(e->env_pgdir);
f0102e08:	8b 4f 5c             	mov    0x5c(%edi),%ecx
f0102e0b:	ba ae 01 00 00       	mov    $0x1ae,%edx
f0102e10:	b8 e2 58 10 f0       	mov    $0xf01058e2,%eax
f0102e15:	e8 ae fa ff ff       	call   f01028c8 <_paddr>
	e->env_pgdir = 0;
f0102e1a:	c7 47 5c 00 00 00 00 	movl   $0x0,0x5c(%edi)
	page_decref(pa2page(pa));
f0102e21:	e8 32 fb ff ff       	call   f0102958 <pa2page>
f0102e26:	83 ec 0c             	sub    $0xc,%esp
f0102e29:	50                   	push   %eax
f0102e2a:	e8 ef e7 ff ff       	call   f010161e <page_decref>

	// return the environment to the free list
	e->env_status = ENV_FREE;
f0102e2f:	c7 47 54 00 00 00 00 	movl   $0x0,0x54(%edi)
	e->env_link = env_free_list;
f0102e36:	a1 cc 3c 19 f0       	mov    0xf0193ccc,%eax
f0102e3b:	89 47 44             	mov    %eax,0x44(%edi)
	env_free_list = e;
f0102e3e:	89 3d cc 3c 19 f0    	mov    %edi,0xf0193ccc
}
f0102e44:	83 c4 10             	add    $0x10,%esp
f0102e47:	8d 65 f4             	lea    -0xc(%ebp),%esp
f0102e4a:	5b                   	pop    %ebx
f0102e4b:	5e                   	pop    %esi
f0102e4c:	5f                   	pop    %edi
f0102e4d:	5d                   	pop    %ebp
f0102e4e:	c3                   	ret    

f0102e4f <env_destroy>:
//
// Frees environment e.
//
void
env_destroy(struct Env *e)
{
f0102e4f:	55                   	push   %ebp
f0102e50:	89 e5                	mov    %esp,%ebp
f0102e52:	83 ec 14             	sub    $0x14,%esp
	env_free(e);
f0102e55:	ff 75 08             	pushl  0x8(%ebp)
f0102e58:	e8 b5 fe ff ff       	call   f0102d12 <env_free>

	cprintf("Destroyed the only environment - nothing more to do!\n");
f0102e5d:	c7 04 24 ac 58 10 f0 	movl   $0xf01058ac,(%esp)
f0102e64:	e8 0f 01 00 00       	call   f0102f78 <cprintf>
f0102e69:	83 c4 10             	add    $0x10,%esp
	while (1)
		monitor(NULL);
f0102e6c:	83 ec 0c             	sub    $0xc,%esp
f0102e6f:	6a 00                	push   $0x0
f0102e71:	e8 50 db ff ff       	call   f01009c6 <monitor>
f0102e76:	83 c4 10             	add    $0x10,%esp
f0102e79:	eb f1                	jmp    f0102e6c <env_destroy+0x1d>

f0102e7b <env_pop_tf>:
//
// This function does not return.
//
void
env_pop_tf(struct Trapframe *tf)
{
f0102e7b:	55                   	push   %ebp
f0102e7c:	89 e5                	mov    %esp,%ebp
f0102e7e:	83 ec 0c             	sub    $0xc,%esp
	asm volatile("\tmovl %0,%%esp\n"
f0102e81:	8b 65 08             	mov    0x8(%ebp),%esp
f0102e84:	61                   	popa   
f0102e85:	07                   	pop    %es
f0102e86:	1f                   	pop    %ds
f0102e87:	83 c4 08             	add    $0x8,%esp
f0102e8a:	cf                   	iret   
	             "\taddl $0x8,%%esp\n" /* skip tf_trapno and tf_errcode */
	             "\tiret\n"
	             :
	             : "g"(tf)
	             : "memory");
	panic("iret failed"); /* mostly to placate the compiler */
f0102e8b:	68 63 59 10 f0       	push   $0xf0105963
f0102e90:	68 d8 01 00 00       	push   $0x1d8
f0102e95:	68 e2 58 10 f0       	push   $0xf01058e2
f0102e9a:	e8 0a d2 ff ff       	call   f01000a9 <_panic>

f0102e9f <env_run>:
//
// This function does not return.
//
void
env_run(struct Env *e)
{
f0102e9f:	55                   	push   %ebp
f0102ea0:	89 e5                	mov    %esp,%ebp
f0102ea2:	53                   	push   %ebx
f0102ea3:	83 ec 04             	sub    $0x4,%esp
f0102ea6:	8b 5d 08             	mov    0x8(%ebp),%ebx
	//	e->env_tf.  Go back through the code you wrote above
	//	and make sure you have set the relevant parts of
	//	e->env_tf to sensible values.

	// LAB 3: Your code here.
	if(curenv){
f0102ea9:	a1 c4 3c 19 f0       	mov    0xf0193cc4,%eax
f0102eae:	85 c0                	test   %eax,%eax
f0102eb0:	74 07                	je     f0102eb9 <env_run+0x1a>
		curenv->env_status = ENV_RUNNABLE;
f0102eb2:	c7 40 54 02 00 00 00 	movl   $0x2,0x54(%eax)
	}
	curenv = e;
f0102eb9:	89 1d c4 3c 19 f0    	mov    %ebx,0xf0193cc4
	e->env_status = ENV_RUNNING;
f0102ebf:	c7 43 54 03 00 00 00 	movl   $0x3,0x54(%ebx)
	e->env_runs+=1;
f0102ec6:	83 43 58 01          	addl   $0x1,0x58(%ebx)
	lcr3(PADDR(e->env_pgdir));
f0102eca:	8b 4b 5c             	mov    0x5c(%ebx),%ecx
f0102ecd:	ba fc 01 00 00       	mov    $0x1fc,%edx
f0102ed2:	b8 e2 58 10 f0       	mov    $0xf01058e2,%eax
f0102ed7:	e8 ec f9 ff ff       	call   f01028c8 <_paddr>
f0102edc:	e8 84 f9 ff ff       	call   f0102865 <lcr3>
	env_pop_tf(&e->env_tf);
f0102ee1:	83 ec 0c             	sub    $0xc,%esp
f0102ee4:	53                   	push   %ebx
f0102ee5:	e8 91 ff ff ff       	call   f0102e7b <env_pop_tf>

f0102eea <inb>:
	asm volatile("int3");
}

static inline uint8_t
inb(int port)
{
f0102eea:	55                   	push   %ebp
f0102eeb:	89 e5                	mov    %esp,%ebp
	uint8_t data;
	asm volatile("inb %w1,%0" : "=a" (data) : "d" (port));
f0102eed:	89 c2                	mov    %eax,%edx
f0102eef:	ec                   	in     (%dx),%al
	return data;
}
f0102ef0:	5d                   	pop    %ebp
f0102ef1:	c3                   	ret    

f0102ef2 <outb>:
		     : "memory", "cc");
}

static inline void
outb(int port, uint8_t data)
{
f0102ef2:	55                   	push   %ebp
f0102ef3:	89 e5                	mov    %esp,%ebp
f0102ef5:	89 c1                	mov    %eax,%ecx
f0102ef7:	89 d0                	mov    %edx,%eax
	asm volatile("outb %0,%w1" : : "a" (data), "d" (port));
f0102ef9:	89 ca                	mov    %ecx,%edx
f0102efb:	ee                   	out    %al,(%dx)
}
f0102efc:	5d                   	pop    %ebp
f0102efd:	c3                   	ret    

f0102efe <mc146818_read>:
#include <kern/kclock.h>


unsigned
mc146818_read(unsigned reg)
{
f0102efe:	55                   	push   %ebp
f0102eff:	89 e5                	mov    %esp,%ebp
	outb(IO_RTC, reg);
f0102f01:	0f b6 55 08          	movzbl 0x8(%ebp),%edx
f0102f05:	b8 70 00 00 00       	mov    $0x70,%eax
f0102f0a:	e8 e3 ff ff ff       	call   f0102ef2 <outb>
	return inb(IO_RTC+1);
f0102f0f:	b8 71 00 00 00       	mov    $0x71,%eax
f0102f14:	e8 d1 ff ff ff       	call   f0102eea <inb>
f0102f19:	0f b6 c0             	movzbl %al,%eax
}
f0102f1c:	5d                   	pop    %ebp
f0102f1d:	c3                   	ret    

f0102f1e <mc146818_write>:

void
mc146818_write(unsigned reg, unsigned datum)
{
f0102f1e:	55                   	push   %ebp
f0102f1f:	89 e5                	mov    %esp,%ebp
	outb(IO_RTC, reg);
f0102f21:	0f b6 55 08          	movzbl 0x8(%ebp),%edx
f0102f25:	b8 70 00 00 00       	mov    $0x70,%eax
f0102f2a:	e8 c3 ff ff ff       	call   f0102ef2 <outb>
	outb(IO_RTC+1, datum);
f0102f2f:	0f b6 55 0c          	movzbl 0xc(%ebp),%edx
f0102f33:	b8 71 00 00 00       	mov    $0x71,%eax
f0102f38:	e8 b5 ff ff ff       	call   f0102ef2 <outb>
}
f0102f3d:	5d                   	pop    %ebp
f0102f3e:	c3                   	ret    

f0102f3f <putch>:
#include <inc/stdarg.h>


static void
putch(int ch, int *cnt)
{
f0102f3f:	55                   	push   %ebp
f0102f40:	89 e5                	mov    %esp,%ebp
f0102f42:	83 ec 14             	sub    $0x14,%esp
	cputchar(ch);
f0102f45:	ff 75 08             	pushl  0x8(%ebp)
f0102f48:	e8 d6 d7 ff ff       	call   f0100723 <cputchar>
	*cnt++;
}
f0102f4d:	83 c4 10             	add    $0x10,%esp
f0102f50:	c9                   	leave  
f0102f51:	c3                   	ret    

f0102f52 <vcprintf>:

int
vcprintf(const char *fmt, va_list ap)
{
f0102f52:	55                   	push   %ebp
f0102f53:	89 e5                	mov    %esp,%ebp
f0102f55:	83 ec 18             	sub    $0x18,%esp
	int cnt = 0;
f0102f58:	c7 45 f4 00 00 00 00 	movl   $0x0,-0xc(%ebp)

	vprintfmt((void*)putch, &cnt, fmt, ap);
f0102f5f:	ff 75 0c             	pushl  0xc(%ebp)
f0102f62:	ff 75 08             	pushl  0x8(%ebp)
f0102f65:	8d 45 f4             	lea    -0xc(%ebp),%eax
f0102f68:	50                   	push   %eax
f0102f69:	68 3f 2f 10 f0       	push   $0xf0102f3f
f0102f6e:	e8 e5 0d 00 00       	call   f0103d58 <vprintfmt>
	return cnt;
}
f0102f73:	8b 45 f4             	mov    -0xc(%ebp),%eax
f0102f76:	c9                   	leave  
f0102f77:	c3                   	ret    

f0102f78 <cprintf>:

int
cprintf(const char *fmt, ...)
{
f0102f78:	55                   	push   %ebp
f0102f79:	89 e5                	mov    %esp,%ebp
f0102f7b:	83 ec 10             	sub    $0x10,%esp
	va_list ap;
	int cnt;

	va_start(ap, fmt);
f0102f7e:	8d 45 0c             	lea    0xc(%ebp),%eax
	cnt = vcprintf(fmt, ap);
f0102f81:	50                   	push   %eax
f0102f82:	ff 75 08             	pushl  0x8(%ebp)
f0102f85:	e8 c8 ff ff ff       	call   f0102f52 <vcprintf>
	va_end(ap);

	return cnt;
}
f0102f8a:	c9                   	leave  
f0102f8b:	c3                   	ret    

f0102f8c <lidt>:
	asm volatile("invlpg (%0)" : : "r" (addr) : "memory");
}

static inline void
lidt(void *p)
{
f0102f8c:	55                   	push   %ebp
f0102f8d:	89 e5                	mov    %esp,%ebp
	asm volatile("lidt (%0)" : : "r" (p));
f0102f8f:	0f 01 18             	lidtl  (%eax)
}
f0102f92:	5d                   	pop    %ebp
f0102f93:	c3                   	ret    

f0102f94 <ltr>:
	asm volatile("lldt %0" : : "r" (sel));
}

static inline void
ltr(uint16_t sel)
{
f0102f94:	55                   	push   %ebp
f0102f95:	89 e5                	mov    %esp,%ebp
	asm volatile("ltr %0" : : "r" (sel));
f0102f97:	0f 00 d8             	ltr    %ax
}
f0102f9a:	5d                   	pop    %ebp
f0102f9b:	c3                   	ret    

f0102f9c <rcr2>:
	return val;
}

static inline uint32_t
rcr2(void)
{
f0102f9c:	55                   	push   %ebp
f0102f9d:	89 e5                	mov    %esp,%ebp
	uint32_t val;
	asm volatile("movl %%cr2,%0" : "=r" (val));
f0102f9f:	0f 20 d0             	mov    %cr2,%eax
	return val;
}
f0102fa2:	5d                   	pop    %ebp
f0102fa3:	c3                   	ret    

f0102fa4 <read_eflags>:
	asm volatile("movl %0,%%cr3" : : "r" (cr3));
}

static inline uint32_t
read_eflags(void)
{
f0102fa4:	55                   	push   %ebp
f0102fa5:	89 e5                	mov    %esp,%ebp
	uint32_t eflags;
	asm volatile("pushfl; popl %0" : "=r" (eflags));
f0102fa7:	9c                   	pushf  
f0102fa8:	58                   	pop    %eax
	return eflags;
}
f0102fa9:	5d                   	pop    %ebp
f0102faa:	c3                   	ret    

f0102fab <trapname>:
struct Pseudodesc idt_pd = { sizeof(idt) - 1, (uint32_t) idt };


static const char *
trapname(int trapno)
{
f0102fab:	55                   	push   %ebp
f0102fac:	89 e5                	mov    %esp,%ebp
		"Alignment Check",
		"Machine-Check",
		"SIMD Floating-Point Exception"
	};

	if (trapno < ARRAY_SIZE(excnames))
f0102fae:	83 f8 13             	cmp    $0x13,%eax
f0102fb1:	77 09                	ja     f0102fbc <trapname+0x11>
		return excnames[trapno];
f0102fb3:	8b 04 85 40 5d 10 f0 	mov    -0xfefa2c0(,%eax,4),%eax
f0102fba:	eb 10                	jmp    f0102fcc <trapname+0x21>
	if (trapno == T_SYSCALL)
f0102fbc:	83 f8 30             	cmp    $0x30,%eax
		return "System call";
	return "(unknown trap)";
f0102fbf:	ba 7b 59 10 f0       	mov    $0xf010597b,%edx
f0102fc4:	b8 6f 59 10 f0       	mov    $0xf010596f,%eax
f0102fc9:	0f 45 c2             	cmovne %edx,%eax
}
f0102fcc:	5d                   	pop    %ebp
f0102fcd:	c3                   	ret    

f0102fce <trap_init_percpu>:
}

// Initialize and load the per-CPU TSS and IDT
void
trap_init_percpu(void)
{
f0102fce:	55                   	push   %ebp
f0102fcf:	89 e5                	mov    %esp,%ebp
	// Setup a TSS so that we get the right stack
	// when we trap to the kernel.
	ts.ts_esp0 = KSTACKTOP;
f0102fd1:	b8 00 45 19 f0       	mov    $0xf0194500,%eax
f0102fd6:	c7 05 04 45 19 f0 00 	movl   $0xf0000000,0xf0194504
f0102fdd:	00 00 f0 
	ts.ts_ss0 = GD_KD;
f0102fe0:	66 c7 05 08 45 19 f0 	movw   $0x10,0xf0194508
f0102fe7:	10 00 

	// Initialize the TSS slot of the gdt.
	gdt[GD_TSS0 >> 3] =
f0102fe9:	66 c7 05 48 03 11 f0 	movw   $0x67,0xf0110348
f0102ff0:	67 00 
f0102ff2:	66 a3 4a 03 11 f0    	mov    %ax,0xf011034a
f0102ff8:	89 c2                	mov    %eax,%edx
f0102ffa:	c1 ea 10             	shr    $0x10,%edx
f0102ffd:	88 15 4c 03 11 f0    	mov    %dl,0xf011034c
f0103003:	c6 05 4e 03 11 f0 40 	movb   $0x40,0xf011034e
f010300a:	c1 e8 18             	shr    $0x18,%eax
f010300d:	a2 4f 03 11 f0       	mov    %al,0xf011034f
	        SEG16(STS_T32A, (uint32_t)(&ts), sizeof(struct Taskstate) - 1, 0);
	gdt[GD_TSS0 >> 3].sd_s = 0;
f0103012:	c6 05 4d 03 11 f0 89 	movb   $0x89,0xf011034d

	// Load the TSS selector (like other segment selectors, the
	// bottom three bits are special; we leave them 0)
	ltr(GD_TSS0);
f0103019:	b8 28 00 00 00       	mov    $0x28,%eax
f010301e:	e8 71 ff ff ff       	call   f0102f94 <ltr>

	// Load the IDT
	lidt(&idt_pd);
f0103023:	b8 50 03 11 f0       	mov    $0xf0110350,%eax
f0103028:	e8 5f ff ff ff       	call   f0102f8c <lidt>
}
f010302d:	5d                   	pop    %ebp
f010302e:	c3                   	ret    

f010302f <trap_init>:
void Trap_48();


void
trap_init(void)
{
f010302f:	55                   	push   %ebp
f0103030:	89 e5                	mov    %esp,%ebp
f0103032:	83 ec 14             	sub    $0x14,%esp
	cprintf("Se setean los gates \n");
f0103035:	68 8a 59 10 f0       	push   $0xf010598a
f010303a:	e8 39 ff ff ff       	call   f0102f78 <cprintf>
	extern struct Segdesc gdt[];

	// LAB 3: Your code here.
	SETGATE(idt[0], 1, GD_KT, Trap_0, 0);
f010303f:	b8 24 37 10 f0       	mov    $0xf0103724,%eax
f0103044:	66 a3 e0 3c 19 f0    	mov    %ax,0xf0193ce0
f010304a:	66 c7 05 e2 3c 19 f0 	movw   $0x8,0xf0193ce2
f0103051:	08 00 
f0103053:	c6 05 e4 3c 19 f0 00 	movb   $0x0,0xf0193ce4
f010305a:	c6 05 e5 3c 19 f0 8f 	movb   $0x8f,0xf0193ce5
f0103061:	c1 e8 10             	shr    $0x10,%eax
f0103064:	66 a3 e6 3c 19 f0    	mov    %ax,0xf0193ce6
	SETGATE(idt[1], 1, GD_KT, Trap_1, 0);
f010306a:	b8 2a 37 10 f0       	mov    $0xf010372a,%eax
f010306f:	66 a3 e8 3c 19 f0    	mov    %ax,0xf0193ce8
f0103075:	66 c7 05 ea 3c 19 f0 	movw   $0x8,0xf0193cea
f010307c:	08 00 
f010307e:	c6 05 ec 3c 19 f0 00 	movb   $0x0,0xf0193cec
f0103085:	c6 05 ed 3c 19 f0 8f 	movb   $0x8f,0xf0193ced
f010308c:	c1 e8 10             	shr    $0x10,%eax
f010308f:	66 a3 ee 3c 19 f0    	mov    %ax,0xf0193cee
	SETGATE(idt[2], 1, GD_KT, Trap_2, 0); 
f0103095:	b8 30 37 10 f0       	mov    $0xf0103730,%eax
f010309a:	66 a3 f0 3c 19 f0    	mov    %ax,0xf0193cf0
f01030a0:	66 c7 05 f2 3c 19 f0 	movw   $0x8,0xf0193cf2
f01030a7:	08 00 
f01030a9:	c6 05 f4 3c 19 f0 00 	movb   $0x0,0xf0193cf4
f01030b0:	c6 05 f5 3c 19 f0 8f 	movb   $0x8f,0xf0193cf5
f01030b7:	c1 e8 10             	shr    $0x10,%eax
f01030ba:	66 a3 f6 3c 19 f0    	mov    %ax,0xf0193cf6
	SETGATE(idt[3], 0, GD_KT, Trap_3, 3);
f01030c0:	b8 36 37 10 f0       	mov    $0xf0103736,%eax
f01030c5:	66 a3 f8 3c 19 f0    	mov    %ax,0xf0193cf8
f01030cb:	66 c7 05 fa 3c 19 f0 	movw   $0x8,0xf0193cfa
f01030d2:	08 00 
f01030d4:	c6 05 fc 3c 19 f0 00 	movb   $0x0,0xf0193cfc
f01030db:	c6 05 fd 3c 19 f0 ee 	movb   $0xee,0xf0193cfd
f01030e2:	c1 e8 10             	shr    $0x10,%eax
f01030e5:	66 a3 fe 3c 19 f0    	mov    %ax,0xf0193cfe
	SETGATE(idt[4], 1, GD_KT, Trap_4, 0);
f01030eb:	b8 3c 37 10 f0       	mov    $0xf010373c,%eax
f01030f0:	66 a3 00 3d 19 f0    	mov    %ax,0xf0193d00
f01030f6:	66 c7 05 02 3d 19 f0 	movw   $0x8,0xf0193d02
f01030fd:	08 00 
f01030ff:	c6 05 04 3d 19 f0 00 	movb   $0x0,0xf0193d04
f0103106:	c6 05 05 3d 19 f0 8f 	movb   $0x8f,0xf0193d05
f010310d:	c1 e8 10             	shr    $0x10,%eax
f0103110:	66 a3 06 3d 19 f0    	mov    %ax,0xf0193d06
	SETGATE(idt[5], 1, GD_KT, Trap_5, 0);
f0103116:	b8 42 37 10 f0       	mov    $0xf0103742,%eax
f010311b:	66 a3 08 3d 19 f0    	mov    %ax,0xf0193d08
f0103121:	66 c7 05 0a 3d 19 f0 	movw   $0x8,0xf0193d0a
f0103128:	08 00 
f010312a:	c6 05 0c 3d 19 f0 00 	movb   $0x0,0xf0193d0c
f0103131:	c6 05 0d 3d 19 f0 8f 	movb   $0x8f,0xf0193d0d
f0103138:	c1 e8 10             	shr    $0x10,%eax
f010313b:	66 a3 0e 3d 19 f0    	mov    %ax,0xf0193d0e
	SETGATE(idt[6], 1, GD_KT, Trap_6, 0);
f0103141:	b8 48 37 10 f0       	mov    $0xf0103748,%eax
f0103146:	66 a3 10 3d 19 f0    	mov    %ax,0xf0193d10
f010314c:	66 c7 05 12 3d 19 f0 	movw   $0x8,0xf0193d12
f0103153:	08 00 
f0103155:	c6 05 14 3d 19 f0 00 	movb   $0x0,0xf0193d14
f010315c:	c6 05 15 3d 19 f0 8f 	movb   $0x8f,0xf0193d15
f0103163:	c1 e8 10             	shr    $0x10,%eax
f0103166:	66 a3 16 3d 19 f0    	mov    %ax,0xf0193d16
	SETGATE(idt[7], 1, GD_KT, Trap_7, 0);
f010316c:	b8 4e 37 10 f0       	mov    $0xf010374e,%eax
f0103171:	66 a3 18 3d 19 f0    	mov    %ax,0xf0193d18
f0103177:	66 c7 05 1a 3d 19 f0 	movw   $0x8,0xf0193d1a
f010317e:	08 00 
f0103180:	c6 05 1c 3d 19 f0 00 	movb   $0x0,0xf0193d1c
f0103187:	c6 05 1d 3d 19 f0 8f 	movb   $0x8f,0xf0193d1d
f010318e:	c1 e8 10             	shr    $0x10,%eax
f0103191:	66 a3 1e 3d 19 f0    	mov    %ax,0xf0193d1e
	SETGATE(idt[8], 1, GD_KT, Trap_8, 0); 
f0103197:	b8 54 37 10 f0       	mov    $0xf0103754,%eax
f010319c:	66 a3 20 3d 19 f0    	mov    %ax,0xf0193d20
f01031a2:	66 c7 05 22 3d 19 f0 	movw   $0x8,0xf0193d22
f01031a9:	08 00 
f01031ab:	c6 05 24 3d 19 f0 00 	movb   $0x0,0xf0193d24
f01031b2:	c6 05 25 3d 19 f0 8f 	movb   $0x8f,0xf0193d25
f01031b9:	c1 e8 10             	shr    $0x10,%eax
f01031bc:	66 a3 26 3d 19 f0    	mov    %ax,0xf0193d26
	SETGATE(idt[10], 1, GD_KT, Trap_10, 0); 
f01031c2:	b8 58 37 10 f0       	mov    $0xf0103758,%eax
f01031c7:	66 a3 30 3d 19 f0    	mov    %ax,0xf0193d30
f01031cd:	66 c7 05 32 3d 19 f0 	movw   $0x8,0xf0193d32
f01031d4:	08 00 
f01031d6:	c6 05 34 3d 19 f0 00 	movb   $0x0,0xf0193d34
f01031dd:	c6 05 35 3d 19 f0 8f 	movb   $0x8f,0xf0193d35
f01031e4:	c1 e8 10             	shr    $0x10,%eax
f01031e7:	66 a3 36 3d 19 f0    	mov    %ax,0xf0193d36
	SETGATE(idt[11], 1, GD_KT, Trap_11, 0); 
f01031ed:	b8 5c 37 10 f0       	mov    $0xf010375c,%eax
f01031f2:	66 a3 38 3d 19 f0    	mov    %ax,0xf0193d38
f01031f8:	66 c7 05 3a 3d 19 f0 	movw   $0x8,0xf0193d3a
f01031ff:	08 00 
f0103201:	c6 05 3c 3d 19 f0 00 	movb   $0x0,0xf0193d3c
f0103208:	c6 05 3d 3d 19 f0 8f 	movb   $0x8f,0xf0193d3d
f010320f:	c1 e8 10             	shr    $0x10,%eax
f0103212:	66 a3 3e 3d 19 f0    	mov    %ax,0xf0193d3e
	SETGATE(idt[12], 1, GD_KT, Trap_12, 0); 
f0103218:	b8 60 37 10 f0       	mov    $0xf0103760,%eax
f010321d:	66 a3 40 3d 19 f0    	mov    %ax,0xf0193d40
f0103223:	66 c7 05 42 3d 19 f0 	movw   $0x8,0xf0193d42
f010322a:	08 00 
f010322c:	c6 05 44 3d 19 f0 00 	movb   $0x0,0xf0193d44
f0103233:	c6 05 45 3d 19 f0 8f 	movb   $0x8f,0xf0193d45
f010323a:	c1 e8 10             	shr    $0x10,%eax
f010323d:	66 a3 46 3d 19 f0    	mov    %ax,0xf0193d46
	SETGATE(idt[13], 1, GD_KT, Trap_13, 0); 
f0103243:	b8 64 37 10 f0       	mov    $0xf0103764,%eax
f0103248:	66 a3 48 3d 19 f0    	mov    %ax,0xf0193d48
f010324e:	66 c7 05 4a 3d 19 f0 	movw   $0x8,0xf0193d4a
f0103255:	08 00 
f0103257:	c6 05 4c 3d 19 f0 00 	movb   $0x0,0xf0193d4c
f010325e:	c6 05 4d 3d 19 f0 8f 	movb   $0x8f,0xf0193d4d
f0103265:	c1 e8 10             	shr    $0x10,%eax
f0103268:	66 a3 4e 3d 19 f0    	mov    %ax,0xf0193d4e
	SETGATE(idt[14], 1, GD_KT, Trap_14, 0); 
f010326e:	b8 68 37 10 f0       	mov    $0xf0103768,%eax
f0103273:	66 a3 50 3d 19 f0    	mov    %ax,0xf0193d50
f0103279:	66 c7 05 52 3d 19 f0 	movw   $0x8,0xf0193d52
f0103280:	08 00 
f0103282:	c6 05 54 3d 19 f0 00 	movb   $0x0,0xf0193d54
f0103289:	c6 05 55 3d 19 f0 8f 	movb   $0x8f,0xf0193d55
f0103290:	c1 e8 10             	shr    $0x10,%eax
f0103293:	66 a3 56 3d 19 f0    	mov    %ax,0xf0193d56
	SETGATE(idt[16], 1, GD_KT, Trap_16, 0);
f0103299:	b8 6c 37 10 f0       	mov    $0xf010376c,%eax
f010329e:	66 a3 60 3d 19 f0    	mov    %ax,0xf0193d60
f01032a4:	66 c7 05 62 3d 19 f0 	movw   $0x8,0xf0193d62
f01032ab:	08 00 
f01032ad:	c6 05 64 3d 19 f0 00 	movb   $0x0,0xf0193d64
f01032b4:	c6 05 65 3d 19 f0 8f 	movb   $0x8f,0xf0193d65
f01032bb:	c1 e8 10             	shr    $0x10,%eax
f01032be:	66 a3 66 3d 19 f0    	mov    %ax,0xf0193d66
	SETGATE(idt[17], 1, GD_KT, Trap_17, 0); 
f01032c4:	b8 72 37 10 f0       	mov    $0xf0103772,%eax
f01032c9:	66 a3 68 3d 19 f0    	mov    %ax,0xf0193d68
f01032cf:	66 c7 05 6a 3d 19 f0 	movw   $0x8,0xf0193d6a
f01032d6:	08 00 
f01032d8:	c6 05 6c 3d 19 f0 00 	movb   $0x0,0xf0193d6c
f01032df:	c6 05 6d 3d 19 f0 8f 	movb   $0x8f,0xf0193d6d
f01032e6:	c1 e8 10             	shr    $0x10,%eax
f01032e9:	66 a3 6e 3d 19 f0    	mov    %ax,0xf0193d6e
	SETGATE(idt[18], 1, GD_KT, Trap_18, 0); 
f01032ef:	b8 76 37 10 f0       	mov    $0xf0103776,%eax
f01032f4:	66 a3 70 3d 19 f0    	mov    %ax,0xf0193d70
f01032fa:	66 c7 05 72 3d 19 f0 	movw   $0x8,0xf0193d72
f0103301:	08 00 
f0103303:	c6 05 74 3d 19 f0 00 	movb   $0x0,0xf0193d74
f010330a:	c6 05 75 3d 19 f0 8f 	movb   $0x8f,0xf0193d75
f0103311:	c1 e8 10             	shr    $0x10,%eax
f0103314:	66 a3 76 3d 19 f0    	mov    %ax,0xf0193d76
	SETGATE(idt[19], 1, GD_KT, Trap_19, 0); 
f010331a:	b8 7c 37 10 f0       	mov    $0xf010377c,%eax
f010331f:	66 a3 78 3d 19 f0    	mov    %ax,0xf0193d78
f0103325:	66 c7 05 7a 3d 19 f0 	movw   $0x8,0xf0193d7a
f010332c:	08 00 
f010332e:	c6 05 7c 3d 19 f0 00 	movb   $0x0,0xf0193d7c
f0103335:	c6 05 7d 3d 19 f0 8f 	movb   $0x8f,0xf0193d7d
f010333c:	c1 e8 10             	shr    $0x10,%eax
f010333f:	66 a3 7e 3d 19 f0    	mov    %ax,0xf0193d7e
	SETGATE(idt[48], 0, GD_KT, Trap_48, 3);
f0103345:	b8 82 37 10 f0       	mov    $0xf0103782,%eax
f010334a:	66 a3 60 3e 19 f0    	mov    %ax,0xf0193e60
f0103350:	66 c7 05 62 3e 19 f0 	movw   $0x8,0xf0193e62
f0103357:	08 00 
f0103359:	c6 05 64 3e 19 f0 00 	movb   $0x0,0xf0193e64
f0103360:	c6 05 65 3e 19 f0 ee 	movb   $0xee,0xf0193e65
f0103367:	c1 e8 10             	shr    $0x10,%eax
f010336a:	66 a3 66 3e 19 f0    	mov    %ax,0xf0193e66

	cprintf("Se setearon los gates\n");
f0103370:	c7 04 24 a0 59 10 f0 	movl   $0xf01059a0,(%esp)
f0103377:	e8 fc fb ff ff       	call   f0102f78 <cprintf>

	// Per-CPU setup
	trap_init_percpu();
f010337c:	e8 4d fc ff ff       	call   f0102fce <trap_init_percpu>
}
f0103381:	83 c4 10             	add    $0x10,%esp
f0103384:	c9                   	leave  
f0103385:	c3                   	ret    

f0103386 <print_regs>:
	}
}

void
print_regs(struct PushRegs *regs)
{
f0103386:	55                   	push   %ebp
f0103387:	89 e5                	mov    %esp,%ebp
f0103389:	53                   	push   %ebx
f010338a:	83 ec 0c             	sub    $0xc,%esp
f010338d:	8b 5d 08             	mov    0x8(%ebp),%ebx
	cprintf("  edi  0x%08x\n", regs->reg_edi);
f0103390:	ff 33                	pushl  (%ebx)
f0103392:	68 b7 59 10 f0       	push   $0xf01059b7
f0103397:	e8 dc fb ff ff       	call   f0102f78 <cprintf>
	cprintf("  esi  0x%08x\n", regs->reg_esi);
f010339c:	83 c4 08             	add    $0x8,%esp
f010339f:	ff 73 04             	pushl  0x4(%ebx)
f01033a2:	68 c6 59 10 f0       	push   $0xf01059c6
f01033a7:	e8 cc fb ff ff       	call   f0102f78 <cprintf>
	cprintf("  ebp  0x%08x\n", regs->reg_ebp);
f01033ac:	83 c4 08             	add    $0x8,%esp
f01033af:	ff 73 08             	pushl  0x8(%ebx)
f01033b2:	68 d5 59 10 f0       	push   $0xf01059d5
f01033b7:	e8 bc fb ff ff       	call   f0102f78 <cprintf>
	cprintf("  oesp 0x%08x\n", regs->reg_oesp);
f01033bc:	83 c4 08             	add    $0x8,%esp
f01033bf:	ff 73 0c             	pushl  0xc(%ebx)
f01033c2:	68 e4 59 10 f0       	push   $0xf01059e4
f01033c7:	e8 ac fb ff ff       	call   f0102f78 <cprintf>
	cprintf("  ebx  0x%08x\n", regs->reg_ebx);
f01033cc:	83 c4 08             	add    $0x8,%esp
f01033cf:	ff 73 10             	pushl  0x10(%ebx)
f01033d2:	68 f3 59 10 f0       	push   $0xf01059f3
f01033d7:	e8 9c fb ff ff       	call   f0102f78 <cprintf>
	cprintf("  edx  0x%08x\n", regs->reg_edx);
f01033dc:	83 c4 08             	add    $0x8,%esp
f01033df:	ff 73 14             	pushl  0x14(%ebx)
f01033e2:	68 02 5a 10 f0       	push   $0xf0105a02
f01033e7:	e8 8c fb ff ff       	call   f0102f78 <cprintf>
	cprintf("  ecx  0x%08x\n", regs->reg_ecx);
f01033ec:	83 c4 08             	add    $0x8,%esp
f01033ef:	ff 73 18             	pushl  0x18(%ebx)
f01033f2:	68 11 5a 10 f0       	push   $0xf0105a11
f01033f7:	e8 7c fb ff ff       	call   f0102f78 <cprintf>
	cprintf("  eax  0x%08x\n", regs->reg_eax);
f01033fc:	83 c4 08             	add    $0x8,%esp
f01033ff:	ff 73 1c             	pushl  0x1c(%ebx)
f0103402:	68 20 5a 10 f0       	push   $0xf0105a20
f0103407:	e8 6c fb ff ff       	call   f0102f78 <cprintf>
}
f010340c:	83 c4 10             	add    $0x10,%esp
f010340f:	8b 5d fc             	mov    -0x4(%ebp),%ebx
f0103412:	c9                   	leave  
f0103413:	c3                   	ret    

f0103414 <print_trapframe>:
	lidt(&idt_pd);
}

void
print_trapframe(struct Trapframe *tf)
{
f0103414:	55                   	push   %ebp
f0103415:	89 e5                	mov    %esp,%ebp
f0103417:	56                   	push   %esi
f0103418:	53                   	push   %ebx
f0103419:	8b 5d 08             	mov    0x8(%ebp),%ebx
	cprintf("TRAP frame at %p\n", tf);
f010341c:	83 ec 08             	sub    $0x8,%esp
f010341f:	53                   	push   %ebx
f0103420:	68 54 5b 10 f0       	push   $0xf0105b54
f0103425:	e8 4e fb ff ff       	call   f0102f78 <cprintf>
	print_regs(&tf->tf_regs);
f010342a:	89 1c 24             	mov    %ebx,(%esp)
f010342d:	e8 54 ff ff ff       	call   f0103386 <print_regs>
	cprintf("  es   0x----%04x\n", tf->tf_es);
f0103432:	83 c4 08             	add    $0x8,%esp
f0103435:	0f b7 43 20          	movzwl 0x20(%ebx),%eax
f0103439:	50                   	push   %eax
f010343a:	68 56 5a 10 f0       	push   $0xf0105a56
f010343f:	e8 34 fb ff ff       	call   f0102f78 <cprintf>
	cprintf("  ds   0x----%04x\n", tf->tf_ds);
f0103444:	83 c4 08             	add    $0x8,%esp
f0103447:	0f b7 43 24          	movzwl 0x24(%ebx),%eax
f010344b:	50                   	push   %eax
f010344c:	68 69 5a 10 f0       	push   $0xf0105a69
f0103451:	e8 22 fb ff ff       	call   f0102f78 <cprintf>
	cprintf("  trap 0x%08x %s\n", tf->tf_trapno, trapname(tf->tf_trapno));
f0103456:	8b 73 28             	mov    0x28(%ebx),%esi
f0103459:	89 f0                	mov    %esi,%eax
f010345b:	e8 4b fb ff ff       	call   f0102fab <trapname>
f0103460:	83 c4 0c             	add    $0xc,%esp
f0103463:	50                   	push   %eax
f0103464:	56                   	push   %esi
f0103465:	68 7c 5a 10 f0       	push   $0xf0105a7c
f010346a:	e8 09 fb ff ff       	call   f0102f78 <cprintf>
	// If this trap was a page fault that just happened
	// (so %cr2 is meaningful), print the faulting linear address.
	if (tf == last_tf && tf->tf_trapno == T_PGFLT)
f010346f:	83 c4 10             	add    $0x10,%esp
f0103472:	3b 1d e0 44 19 f0    	cmp    0xf01944e0,%ebx
f0103478:	75 1c                	jne    f0103496 <print_trapframe+0x82>
f010347a:	83 7b 28 0e          	cmpl   $0xe,0x28(%ebx)
f010347e:	75 16                	jne    f0103496 <print_trapframe+0x82>
		cprintf("  cr2  0x%08x\n", rcr2());
f0103480:	e8 17 fb ff ff       	call   f0102f9c <rcr2>
f0103485:	83 ec 08             	sub    $0x8,%esp
f0103488:	50                   	push   %eax
f0103489:	68 8e 5a 10 f0       	push   $0xf0105a8e
f010348e:	e8 e5 fa ff ff       	call   f0102f78 <cprintf>
f0103493:	83 c4 10             	add    $0x10,%esp
	cprintf("  err  0x%08x", tf->tf_err);
f0103496:	83 ec 08             	sub    $0x8,%esp
f0103499:	ff 73 2c             	pushl  0x2c(%ebx)
f010349c:	68 9d 5a 10 f0       	push   $0xf0105a9d
f01034a1:	e8 d2 fa ff ff       	call   f0102f78 <cprintf>
	// For page faults, print decoded fault error code:
	// U/K=fault occurred in user/kernel mode
	// W/R=a write/read caused the fault
	// PR=a protection violation caused the fault (NP=page not present).
	if (tf->tf_trapno == T_PGFLT)
f01034a6:	83 c4 10             	add    $0x10,%esp
f01034a9:	83 7b 28 0e          	cmpl   $0xe,0x28(%ebx)
f01034ad:	75 49                	jne    f01034f8 <print_trapframe+0xe4>
		cprintf(" [%s, %s, %s]\n",
		        tf->tf_err & 4 ? "user" : "kernel",
		        tf->tf_err & 2 ? "write" : "read",
		        tf->tf_err & 1 ? "protection" : "not-present");
f01034af:	8b 43 2c             	mov    0x2c(%ebx),%eax
	// For page faults, print decoded fault error code:
	// U/K=fault occurred in user/kernel mode
	// W/R=a write/read caused the fault
	// PR=a protection violation caused the fault (NP=page not present).
	if (tf->tf_trapno == T_PGFLT)
		cprintf(" [%s, %s, %s]\n",
f01034b2:	89 c2                	mov    %eax,%edx
f01034b4:	83 e2 01             	and    $0x1,%edx
f01034b7:	ba 3a 5a 10 f0       	mov    $0xf0105a3a,%edx
f01034bc:	b9 2f 5a 10 f0       	mov    $0xf0105a2f,%ecx
f01034c1:	0f 44 ca             	cmove  %edx,%ecx
f01034c4:	89 c2                	mov    %eax,%edx
f01034c6:	83 e2 02             	and    $0x2,%edx
f01034c9:	ba 4c 5a 10 f0       	mov    $0xf0105a4c,%edx
f01034ce:	be 46 5a 10 f0       	mov    $0xf0105a46,%esi
f01034d3:	0f 45 d6             	cmovne %esi,%edx
f01034d6:	83 e0 04             	and    $0x4,%eax
f01034d9:	be 2b 5b 10 f0       	mov    $0xf0105b2b,%esi
f01034de:	b8 51 5a 10 f0       	mov    $0xf0105a51,%eax
f01034e3:	0f 44 c6             	cmove  %esi,%eax
f01034e6:	51                   	push   %ecx
f01034e7:	52                   	push   %edx
f01034e8:	50                   	push   %eax
f01034e9:	68 ab 5a 10 f0       	push   $0xf0105aab
f01034ee:	e8 85 fa ff ff       	call   f0102f78 <cprintf>
f01034f3:	83 c4 10             	add    $0x10,%esp
f01034f6:	eb 10                	jmp    f0103508 <print_trapframe+0xf4>
		        tf->tf_err & 4 ? "user" : "kernel",
		        tf->tf_err & 2 ? "write" : "read",
		        tf->tf_err & 1 ? "protection" : "not-present");
	else
		cprintf("\n");
f01034f8:	83 ec 0c             	sub    $0xc,%esp
f01034fb:	68 9e 59 10 f0       	push   $0xf010599e
f0103500:	e8 73 fa ff ff       	call   f0102f78 <cprintf>
f0103505:	83 c4 10             	add    $0x10,%esp
	cprintf("  eip  0x%08x\n", tf->tf_eip);
f0103508:	83 ec 08             	sub    $0x8,%esp
f010350b:	ff 73 30             	pushl  0x30(%ebx)
f010350e:	68 ba 5a 10 f0       	push   $0xf0105aba
f0103513:	e8 60 fa ff ff       	call   f0102f78 <cprintf>
	cprintf("  cs   0x----%04x\n", tf->tf_cs);
f0103518:	83 c4 08             	add    $0x8,%esp
f010351b:	0f b7 43 34          	movzwl 0x34(%ebx),%eax
f010351f:	50                   	push   %eax
f0103520:	68 c9 5a 10 f0       	push   $0xf0105ac9
f0103525:	e8 4e fa ff ff       	call   f0102f78 <cprintf>
	cprintf("  flag 0x%08x\n", tf->tf_eflags);
f010352a:	83 c4 08             	add    $0x8,%esp
f010352d:	ff 73 38             	pushl  0x38(%ebx)
f0103530:	68 dc 5a 10 f0       	push   $0xf0105adc
f0103535:	e8 3e fa ff ff       	call   f0102f78 <cprintf>
	if ((tf->tf_cs & 3) != 0) {
f010353a:	83 c4 10             	add    $0x10,%esp
f010353d:	f6 43 34 03          	testb  $0x3,0x34(%ebx)
f0103541:	74 25                	je     f0103568 <print_trapframe+0x154>
		cprintf("  esp  0x%08x\n", tf->tf_esp);
f0103543:	83 ec 08             	sub    $0x8,%esp
f0103546:	ff 73 3c             	pushl  0x3c(%ebx)
f0103549:	68 eb 5a 10 f0       	push   $0xf0105aeb
f010354e:	e8 25 fa ff ff       	call   f0102f78 <cprintf>
		cprintf("  ss   0x----%04x\n", tf->tf_ss);
f0103553:	83 c4 08             	add    $0x8,%esp
f0103556:	0f b7 43 40          	movzwl 0x40(%ebx),%eax
f010355a:	50                   	push   %eax
f010355b:	68 fa 5a 10 f0       	push   $0xf0105afa
f0103560:	e8 13 fa ff ff       	call   f0102f78 <cprintf>
f0103565:	83 c4 10             	add    $0x10,%esp
	}
}
f0103568:	8d 65 f8             	lea    -0x8(%ebp),%esp
f010356b:	5b                   	pop    %ebx
f010356c:	5e                   	pop    %esi
f010356d:	5d                   	pop    %ebp
f010356e:	c3                   	ret    

f010356f <page_fault_handler>:
}


void
page_fault_handler(struct Trapframe *tf)
{
f010356f:	55                   	push   %ebp
f0103570:	89 e5                	mov    %esp,%ebp
f0103572:	53                   	push   %ebx
f0103573:	83 ec 04             	sub    $0x4,%esp
f0103576:	8b 5d 08             	mov    0x8(%ebp),%ebx
	uint32_t fault_va;

	// Read processor's CR2 register to find the faulting address
	fault_va = rcr2();
f0103579:	e8 1e fa ff ff       	call   f0102f9c <rcr2>

	// Handle kernel-mode page faults.

	// LAB 3: Your code here.
	//MARTIN_TP2_PARTE5
	if (!(tf->tf_cs & 0x3)) { //si CPL==0 es ring0 aka kernel
f010357e:	0f b7 53 34          	movzwl 0x34(%ebx),%edx
f0103582:	f6 c2 03             	test   $0x3,%dl
f0103585:	75 18                	jne    f010359f <page_fault_handler+0x30>
		panic("Kernel-mode page fault!!tf_cs=%p",tf->tf_cs);
f0103587:	0f b7 d2             	movzwl %dx,%edx
f010358a:	52                   	push   %edx
f010358b:	68 b0 5c 10 f0       	push   $0xf0105cb0
f0103590:	68 0b 01 00 00       	push   $0x10b
f0103595:	68 0d 5b 10 f0       	push   $0xf0105b0d
f010359a:	e8 0a cb ff ff       	call   f01000a9 <_panic>
	}
	// We've already handled kernel-mode exceptions, so if we get here,
	// the page fault happened in user mode.

	// Destroy the environment that caused the fault.
	cprintf("[%08x] user fault va %08x ip %08x\n",
f010359f:	ff 73 30             	pushl  0x30(%ebx)
f01035a2:	50                   	push   %eax
f01035a3:	a1 c4 3c 19 f0       	mov    0xf0193cc4,%eax
f01035a8:	ff 70 48             	pushl  0x48(%eax)
f01035ab:	68 d4 5c 10 f0       	push   $0xf0105cd4
f01035b0:	e8 c3 f9 ff ff       	call   f0102f78 <cprintf>
	        curenv->env_id,
	        fault_va,
	        tf->tf_eip);
	print_trapframe(tf);
f01035b5:	89 1c 24             	mov    %ebx,(%esp)
f01035b8:	e8 57 fe ff ff       	call   f0103414 <print_trapframe>
	env_destroy(curenv);
f01035bd:	83 c4 04             	add    $0x4,%esp
f01035c0:	ff 35 c4 3c 19 f0    	pushl  0xf0193cc4
f01035c6:	e8 84 f8 ff ff       	call   f0102e4f <env_destroy>
}
f01035cb:	83 c4 10             	add    $0x10,%esp
f01035ce:	8b 5d fc             	mov    -0x4(%ebp),%ebx
f01035d1:	c9                   	leave  
f01035d2:	c3                   	ret    

f01035d3 <trap_dispatch>:
	cprintf("  eax  0x%08x\n", regs->reg_eax);
}

static void
trap_dispatch(struct Trapframe *tf)
{
f01035d3:	55                   	push   %ebp
f01035d4:	89 e5                	mov    %esp,%ebp
f01035d6:	53                   	push   %ebx
f01035d7:	83 ec 04             	sub    $0x4,%esp
f01035da:	89 c3                	mov    %eax,%ebx
	// Handle processor exceptions.
	// LAB 3: Your code here.
	if(tf->tf_trapno == T_BRKPT){
f01035dc:	8b 40 28             	mov    0x28(%eax),%eax
f01035df:	83 f8 03             	cmp    $0x3,%eax
f01035e2:	75 0e                	jne    f01035f2 <trap_dispatch+0x1f>
		monitor(tf);	
f01035e4:	83 ec 0c             	sub    $0xc,%esp
f01035e7:	53                   	push   %ebx
f01035e8:	e8 d9 d3 ff ff       	call   f01009c6 <monitor>
		return;
f01035ed:	83 c4 10             	add    $0x10,%esp
f01035f0:	eb 74                	jmp    f0103666 <trap_dispatch+0x93>
	}
	if(tf->tf_trapno == T_PGFLT){
f01035f2:	83 f8 0e             	cmp    $0xe,%eax
f01035f5:	75 0e                	jne    f0103605 <trap_dispatch+0x32>
		page_fault_handler(tf);
f01035f7:	83 ec 0c             	sub    $0xc,%esp
f01035fa:	53                   	push   %ebx
f01035fb:	e8 6f ff ff ff       	call   f010356f <page_fault_handler>
		return;
f0103600:	83 c4 10             	add    $0x10,%esp
f0103603:	eb 61                	jmp    f0103666 <trap_dispatch+0x93>
	}
	if(tf->tf_trapno == T_SYSCALL){
f0103605:	83 f8 30             	cmp    $0x30,%eax
f0103608:	75 21                	jne    f010362b <trap_dispatch+0x58>
		uint32_t resultado = syscall(tf->tf_regs.reg_eax, tf->tf_regs.reg_edx, tf->tf_regs.reg_ecx, tf->tf_regs.reg_ebx, tf->tf_regs.reg_edi, tf->tf_regs.reg_esi);
f010360a:	83 ec 08             	sub    $0x8,%esp
f010360d:	ff 73 04             	pushl  0x4(%ebx)
f0103610:	ff 33                	pushl  (%ebx)
f0103612:	ff 73 10             	pushl  0x10(%ebx)
f0103615:	ff 73 18             	pushl  0x18(%ebx)
f0103618:	ff 73 14             	pushl  0x14(%ebx)
f010361b:	ff 73 1c             	pushl  0x1c(%ebx)
f010361e:	e8 51 02 00 00       	call   f0103874 <syscall>

		//guardar resultado en eax;
		tf->tf_regs.reg_eax = resultado;
f0103623:	89 43 1c             	mov    %eax,0x1c(%ebx)
		return;
f0103626:	83 c4 20             	add    $0x20,%esp
f0103629:	eb 3b                	jmp    f0103666 <trap_dispatch+0x93>
	}


	// Unexpected trap: The user process or the kernel has a bug.
	print_trapframe(tf);
f010362b:	83 ec 0c             	sub    $0xc,%esp
f010362e:	53                   	push   %ebx
f010362f:	e8 e0 fd ff ff       	call   f0103414 <print_trapframe>
	if (tf->tf_cs == GD_KT)
f0103634:	83 c4 10             	add    $0x10,%esp
f0103637:	66 83 7b 34 08       	cmpw   $0x8,0x34(%ebx)
f010363c:	75 17                	jne    f0103655 <trap_dispatch+0x82>
		panic("unhandled trap in kernel");
f010363e:	83 ec 04             	sub    $0x4,%esp
f0103641:	68 19 5b 10 f0       	push   $0xf0105b19
f0103646:	68 d0 00 00 00       	push   $0xd0
f010364b:	68 0d 5b 10 f0       	push   $0xf0105b0d
f0103650:	e8 54 ca ff ff       	call   f01000a9 <_panic>
	else {
		env_destroy(curenv);
f0103655:	83 ec 0c             	sub    $0xc,%esp
f0103658:	ff 35 c4 3c 19 f0    	pushl  0xf0193cc4
f010365e:	e8 ec f7 ff ff       	call   f0102e4f <env_destroy>
		return;
f0103663:	83 c4 10             	add    $0x10,%esp
	}
}
f0103666:	8b 5d fc             	mov    -0x4(%ebp),%ebx
f0103669:	c9                   	leave  
f010366a:	c3                   	ret    

f010366b <trap>:

void
trap(struct Trapframe *tf)
{
f010366b:	55                   	push   %ebp
f010366c:	89 e5                	mov    %esp,%ebp
f010366e:	57                   	push   %edi
f010366f:	56                   	push   %esi
f0103670:	8b 75 08             	mov    0x8(%ebp),%esi
	// The environment may have set DF and some versions
	// of GCC rely on DF being clear
	asm volatile("cld" ::: "cc");
f0103673:	fc                   	cld    

	// Check that interrupts are disabled.  If this assertion
	// fails, DO NOT be tempted to fix it by inserting a "cli" in
	// the interrupt path.
	assert(!(read_eflags() & FL_IF));
f0103674:	e8 2b f9 ff ff       	call   f0102fa4 <read_eflags>
f0103679:	f6 c4 02             	test   $0x2,%ah
f010367c:	74 19                	je     f0103697 <trap+0x2c>
f010367e:	68 32 5b 10 f0       	push   $0xf0105b32
f0103683:	68 7a 55 10 f0       	push   $0xf010557a
f0103688:	68 e1 00 00 00       	push   $0xe1
f010368d:	68 0d 5b 10 f0       	push   $0xf0105b0d
f0103692:	e8 12 ca ff ff       	call   f01000a9 <_panic>

	cprintf("Incoming TRAP frame at %p\n", tf);
f0103697:	83 ec 08             	sub    $0x8,%esp
f010369a:	56                   	push   %esi
f010369b:	68 4b 5b 10 f0       	push   $0xf0105b4b
f01036a0:	e8 d3 f8 ff ff       	call   f0102f78 <cprintf>

	if ((tf->tf_cs & 3) == 3) {
f01036a5:	0f b7 46 34          	movzwl 0x34(%esi),%eax
f01036a9:	83 e0 03             	and    $0x3,%eax
f01036ac:	83 c4 10             	add    $0x10,%esp
f01036af:	66 83 f8 03          	cmp    $0x3,%ax
f01036b3:	75 31                	jne    f01036e6 <trap+0x7b>
		// Trapped from user mode.
		assert(curenv);
f01036b5:	a1 c4 3c 19 f0       	mov    0xf0193cc4,%eax
f01036ba:	85 c0                	test   %eax,%eax
f01036bc:	75 19                	jne    f01036d7 <trap+0x6c>
f01036be:	68 66 5b 10 f0       	push   $0xf0105b66
f01036c3:	68 7a 55 10 f0       	push   $0xf010557a
f01036c8:	68 e7 00 00 00       	push   $0xe7
f01036cd:	68 0d 5b 10 f0       	push   $0xf0105b0d
f01036d2:	e8 d2 c9 ff ff       	call   f01000a9 <_panic>

		// Copy trap frame (which is currently on the stack)
		// into 'curenv->env_tf', so that running the environment
		// will restart at the trap point.
		curenv->env_tf = *tf;
f01036d7:	b9 11 00 00 00       	mov    $0x11,%ecx
f01036dc:	89 c7                	mov    %eax,%edi
f01036de:	f3 a5                	rep movsl %ds:(%esi),%es:(%edi)
		// The trapframe on the stack should be ignored from here on.
		tf = &curenv->env_tf;
f01036e0:	8b 35 c4 3c 19 f0    	mov    0xf0193cc4,%esi
	}

	// Record that tf is the last real trapframe so
	// print_trapframe can print some additional information.
	last_tf = tf;
f01036e6:	89 35 e0 44 19 f0    	mov    %esi,0xf01944e0

	// Dispatch based on what type of trap occurred
	trap_dispatch(tf);
f01036ec:	89 f0                	mov    %esi,%eax
f01036ee:	e8 e0 fe ff ff       	call   f01035d3 <trap_dispatch>

	// Return to the current environment, which should be running.
	assert(curenv && curenv->env_status == ENV_RUNNING);
f01036f3:	a1 c4 3c 19 f0       	mov    0xf0193cc4,%eax
f01036f8:	85 c0                	test   %eax,%eax
f01036fa:	74 06                	je     f0103702 <trap+0x97>
f01036fc:	83 78 54 03          	cmpl   $0x3,0x54(%eax)
f0103700:	74 19                	je     f010371b <trap+0xb0>
f0103702:	68 f8 5c 10 f0       	push   $0xf0105cf8
f0103707:	68 7a 55 10 f0       	push   $0xf010557a
f010370c:	68 f9 00 00 00       	push   $0xf9
f0103711:	68 0d 5b 10 f0       	push   $0xf0105b0d
f0103716:	e8 8e c9 ff ff       	call   f01000a9 <_panic>
	env_run(curenv);
f010371b:	83 ec 0c             	sub    $0xc,%esp
f010371e:	50                   	push   %eax
f010371f:	e8 7b f7 ff ff       	call   f0102e9f <env_run>

f0103724 <Trap_0>:
.text

/*
 * Lab 3: Your code here for generating entry points for the different traps.
 */
TRAPHANDLER_NOEC(Trap_0, T_DIVIDE)
f0103724:	6a 00                	push   $0x0
f0103726:	6a 00                	push   $0x0
f0103728:	eb 5e                	jmp    f0103788 <_alltraps>

f010372a <Trap_1>:
TRAPHANDLER_NOEC(Trap_1, T_DEBUG)
f010372a:	6a 00                	push   $0x0
f010372c:	6a 01                	push   $0x1
f010372e:	eb 58                	jmp    f0103788 <_alltraps>

f0103730 <Trap_2>:
TRAPHANDLER_NOEC(Trap_2, T_NMI)
f0103730:	6a 00                	push   $0x0
f0103732:	6a 02                	push   $0x2
f0103734:	eb 52                	jmp    f0103788 <_alltraps>

f0103736 <Trap_3>:
TRAPHANDLER_NOEC(Trap_3, T_BRKPT)
f0103736:	6a 00                	push   $0x0
f0103738:	6a 03                	push   $0x3
f010373a:	eb 4c                	jmp    f0103788 <_alltraps>

f010373c <Trap_4>:
TRAPHANDLER_NOEC(Trap_4, T_OFLOW)
f010373c:	6a 00                	push   $0x0
f010373e:	6a 04                	push   $0x4
f0103740:	eb 46                	jmp    f0103788 <_alltraps>

f0103742 <Trap_5>:
TRAPHANDLER_NOEC(Trap_5, T_BOUND)
f0103742:	6a 00                	push   $0x0
f0103744:	6a 05                	push   $0x5
f0103746:	eb 40                	jmp    f0103788 <_alltraps>

f0103748 <Trap_6>:
TRAPHANDLER_NOEC(Trap_6, T_ILLOP)
f0103748:	6a 00                	push   $0x0
f010374a:	6a 06                	push   $0x6
f010374c:	eb 3a                	jmp    f0103788 <_alltraps>

f010374e <Trap_7>:
TRAPHANDLER_NOEC(Trap_7, T_DEVICE)
f010374e:	6a 00                	push   $0x0
f0103750:	6a 07                	push   $0x7
f0103752:	eb 34                	jmp    f0103788 <_alltraps>

f0103754 <Trap_8>:
TRAPHANDLER(Trap_8, T_DBLFLT)
f0103754:	6a 08                	push   $0x8
f0103756:	eb 30                	jmp    f0103788 <_alltraps>

f0103758 <Trap_10>:
TRAPHANDLER(Trap_10, T_TSS)
f0103758:	6a 0a                	push   $0xa
f010375a:	eb 2c                	jmp    f0103788 <_alltraps>

f010375c <Trap_11>:
TRAPHANDLER(Trap_11, T_SEGNP)
f010375c:	6a 0b                	push   $0xb
f010375e:	eb 28                	jmp    f0103788 <_alltraps>

f0103760 <Trap_12>:
TRAPHANDLER(Trap_12, T_STACK)
f0103760:	6a 0c                	push   $0xc
f0103762:	eb 24                	jmp    f0103788 <_alltraps>

f0103764 <Trap_13>:
TRAPHANDLER(Trap_13, T_GPFLT)
f0103764:	6a 0d                	push   $0xd
f0103766:	eb 20                	jmp    f0103788 <_alltraps>

f0103768 <Trap_14>:
TRAPHANDLER(Trap_14, T_PGFLT)
f0103768:	6a 0e                	push   $0xe
f010376a:	eb 1c                	jmp    f0103788 <_alltraps>

f010376c <Trap_16>:
TRAPHANDLER_NOEC(Trap_16, T_FPERR)
f010376c:	6a 00                	push   $0x0
f010376e:	6a 10                	push   $0x10
f0103770:	eb 16                	jmp    f0103788 <_alltraps>

f0103772 <Trap_17>:
TRAPHANDLER(Trap_17, T_ALIGN)
f0103772:	6a 11                	push   $0x11
f0103774:	eb 12                	jmp    f0103788 <_alltraps>

f0103776 <Trap_18>:
TRAPHANDLER_NOEC(Trap_18, T_MCHK)
f0103776:	6a 00                	push   $0x0
f0103778:	6a 12                	push   $0x12
f010377a:	eb 0c                	jmp    f0103788 <_alltraps>

f010377c <Trap_19>:
TRAPHANDLER_NOEC(Trap_19, T_SIMDERR)
f010377c:	6a 00                	push   $0x0
f010377e:	6a 13                	push   $0x13
f0103780:	eb 06                	jmp    f0103788 <_alltraps>

f0103782 <Trap_48>:
TRAPHANDLER_NOEC(Trap_48, T_SYSCALL)
f0103782:	6a 00                	push   $0x0
f0103784:	6a 30                	push   $0x30
f0103786:	eb 00                	jmp    f0103788 <_alltraps>

f0103788 <_alltraps>:
/*
 * Lab 3: Your code here for _alltraps
 */

_alltraps:
	pushl %ds
f0103788:	1e                   	push   %ds
    pushl %es
f0103789:	06                   	push   %es
	pushal
f010378a:	60                   	pusha  

	movw $GD_KD, %ax
f010378b:	66 b8 10 00          	mov    $0x10,%ax
	movw %ax, %ds
f010378f:	8e d8                	mov    %eax,%ds
	movw %ax, %es 
f0103791:	8e c0                	mov    %eax,%es

    pushl %esp
f0103793:	54                   	push   %esp
    call trap	
f0103794:	e8 d2 fe ff ff       	call   f010366b <trap>

f0103799 <sys_getenvid>:
}

// Returns the current environment's envid.
static envid_t
sys_getenvid(void)
{
f0103799:	55                   	push   %ebp
f010379a:	89 e5                	mov    %esp,%ebp
f010379c:	83 ec 14             	sub    $0x14,%esp
	cprintf("Entre a f3()\n");
f010379f:	68 90 5d 10 f0       	push   $0xf0105d90
f01037a4:	e8 cf f7 ff ff       	call   f0102f78 <cprintf>
	return curenv->env_id;
f01037a9:	a1 c4 3c 19 f0       	mov    0xf0193cc4,%eax
f01037ae:	8b 40 48             	mov    0x48(%eax),%eax
}
f01037b1:	c9                   	leave  
f01037b2:	c3                   	ret    

f01037b3 <sys_cputs>:
// Print a string to the system console.
// The string is exactly 'len' characters long.
// Destroys the environment on memory errors.
static void
sys_cputs(const char *s, size_t len)
{
f01037b3:	55                   	push   %ebp
f01037b4:	89 e5                	mov    %esp,%ebp
f01037b6:	56                   	push   %esi
f01037b7:	53                   	push   %ebx
f01037b8:	89 c6                	mov    %eax,%esi
f01037ba:	89 d3                	mov    %edx,%ebx
	// Check that the user has permission to read memory [s, s+len).
	// Destroy the environment if not.

	// LAB 3: Your code here.
	//MARTIN_TP2_PARTE
	user_mem_assert(curenv,s,len,0);
f01037bc:	6a 00                	push   $0x0
f01037be:	52                   	push   %edx
f01037bf:	50                   	push   %eax
f01037c0:	ff 35 c4 3c 19 f0    	pushl  0xf0193cc4
f01037c6:	e8 40 f0 ff ff       	call   f010280b <user_mem_assert>
	

	// Print the string supplied by the user.
	cprintf("%.*s", len, s);
f01037cb:	83 c4 0c             	add    $0xc,%esp
f01037ce:	56                   	push   %esi
f01037cf:	53                   	push   %ebx
f01037d0:	68 9e 5d 10 f0       	push   $0xf0105d9e
f01037d5:	e8 9e f7 ff ff       	call   f0102f78 <cprintf>
}
f01037da:	83 c4 10             	add    $0x10,%esp
f01037dd:	8d 65 f8             	lea    -0x8(%ebp),%esp
f01037e0:	5b                   	pop    %ebx
f01037e1:	5e                   	pop    %esi
f01037e2:	5d                   	pop    %ebp
f01037e3:	c3                   	ret    

f01037e4 <sys_cgetc>:

// Read a character from the system console without blocking.
// Returns the character, or 0 if there is no input waiting.
static int
sys_cgetc(void)
{
f01037e4:	55                   	push   %ebp
f01037e5:	89 e5                	mov    %esp,%ebp
f01037e7:	83 ec 14             	sub    $0x14,%esp
	cprintf("Entre a f2()\n");
f01037ea:	68 a3 5d 10 f0       	push   $0xf0105da3
f01037ef:	e8 84 f7 ff ff       	call   f0102f78 <cprintf>
	return cons_getc();
f01037f4:	e8 b5 ce ff ff       	call   f01006ae <cons_getc>
}
f01037f9:	c9                   	leave  
f01037fa:	c3                   	ret    

f01037fb <sys_env_destroy>:
// Returns 0 on success, < 0 on error.  Errors are:
//	-E_BAD_ENV if environment envid doesn't currently exist,
//		or the caller doesn't have permission to change envid.
static int
sys_env_destroy(envid_t envid)
{
f01037fb:	55                   	push   %ebp
f01037fc:	89 e5                	mov    %esp,%ebp
f01037fe:	53                   	push   %ebx
f01037ff:	83 ec 20             	sub    $0x20,%esp
f0103802:	89 c3                	mov    %eax,%ebx
	cprintf("Entre a f4()\n");
f0103804:	68 b1 5d 10 f0       	push   $0xf0105db1
f0103809:	e8 6a f7 ff ff       	call   f0102f78 <cprintf>
	int r;
	struct Env *e;

	if ((r = envid2env(envid, &e, 1)) < 0)
f010380e:	83 c4 0c             	add    $0xc,%esp
f0103811:	6a 01                	push   $0x1
f0103813:	8d 45 f4             	lea    -0xc(%ebp),%eax
f0103816:	50                   	push   %eax
f0103817:	53                   	push   %ebx
f0103818:	e8 d6 f2 ff ff       	call   f0102af3 <envid2env>
f010381d:	83 c4 10             	add    $0x10,%esp
f0103820:	85 c0                	test   %eax,%eax
f0103822:	78 4b                	js     f010386f <sys_env_destroy+0x74>
		return r;
	if (e == curenv)
f0103824:	8b 45 f4             	mov    -0xc(%ebp),%eax
f0103827:	8b 15 c4 3c 19 f0    	mov    0xf0193cc4,%edx
f010382d:	39 d0                	cmp    %edx,%eax
f010382f:	75 15                	jne    f0103846 <sys_env_destroy+0x4b>
		cprintf("[%08x] exiting gracefully\n", curenv->env_id);
f0103831:	83 ec 08             	sub    $0x8,%esp
f0103834:	ff 70 48             	pushl  0x48(%eax)
f0103837:	68 bf 5d 10 f0       	push   $0xf0105dbf
f010383c:	e8 37 f7 ff ff       	call   f0102f78 <cprintf>
f0103841:	83 c4 10             	add    $0x10,%esp
f0103844:	eb 16                	jmp    f010385c <sys_env_destroy+0x61>
	else
		cprintf("[%08x] destroying %08x\n", curenv->env_id, e->env_id);
f0103846:	83 ec 04             	sub    $0x4,%esp
f0103849:	ff 70 48             	pushl  0x48(%eax)
f010384c:	ff 72 48             	pushl  0x48(%edx)
f010384f:	68 da 5d 10 f0       	push   $0xf0105dda
f0103854:	e8 1f f7 ff ff       	call   f0102f78 <cprintf>
f0103859:	83 c4 10             	add    $0x10,%esp
	env_destroy(e);
f010385c:	83 ec 0c             	sub    $0xc,%esp
f010385f:	ff 75 f4             	pushl  -0xc(%ebp)
f0103862:	e8 e8 f5 ff ff       	call   f0102e4f <env_destroy>
	return 0;
f0103867:	83 c4 10             	add    $0x10,%esp
f010386a:	b8 00 00 00 00       	mov    $0x0,%eax
}
f010386f:	8b 5d fc             	mov    -0x4(%ebp),%ebx
f0103872:	c9                   	leave  
f0103873:	c3                   	ret    

f0103874 <syscall>:

// Dispatches to the correct kernel function, passing the arguments.
int32_t
syscall(uint32_t syscallno, uint32_t a1, uint32_t a2, uint32_t a3, uint32_t a4, uint32_t a5)
{
f0103874:	55                   	push   %ebp
f0103875:	89 e5                	mov    %esp,%ebp
f0103877:	53                   	push   %ebx
f0103878:	83 ec 10             	sub    $0x10,%esp
f010387b:	8b 5d 08             	mov    0x8(%ebp),%ebx
	// Call the function corresponding to the 'syscallno' parameter.
	// Return any appropriate return value.
	// LAB 3: Your code here.

	//panic("syscall not implemented");
	cprintf("Entre a syscall()\n");
f010387e:	68 f2 5d 10 f0       	push   $0xf0105df2
f0103883:	e8 f0 f6 ff ff       	call   f0102f78 <cprintf>
	switch (syscallno) {
f0103888:	83 c4 10             	add    $0x10,%esp
f010388b:	83 fb 01             	cmp    $0x1,%ebx
f010388e:	74 1c                	je     f01038ac <syscall+0x38>
f0103890:	83 fb 01             	cmp    $0x1,%ebx
f0103893:	72 0c                	jb     f01038a1 <syscall+0x2d>
f0103895:	83 fb 02             	cmp    $0x2,%ebx
f0103898:	74 19                	je     f01038b3 <syscall+0x3f>
f010389a:	83 fb 03             	cmp    $0x3,%ebx
f010389d:	74 1b                	je     f01038ba <syscall+0x46>
f010389f:	eb 23                	jmp    f01038c4 <syscall+0x50>
	case SYS_cputs:
		sys_cputs((char *)a1, a2);
f01038a1:	8b 55 10             	mov    0x10(%ebp),%edx
f01038a4:	8b 45 0c             	mov    0xc(%ebp),%eax
f01038a7:	e8 07 ff ff ff       	call   f01037b3 <sys_cputs>
	case SYS_cgetc:
		return sys_cgetc();
f01038ac:	e8 33 ff ff ff       	call   f01037e4 <sys_cgetc>
f01038b1:	eb 16                	jmp    f01038c9 <syscall+0x55>
	case SYS_getenvid:
		return sys_getenvid();
f01038b3:	e8 e1 fe ff ff       	call   f0103799 <sys_getenvid>
f01038b8:	eb 0f                	jmp    f01038c9 <syscall+0x55>
	case SYS_env_destroy:
		return sys_env_destroy(a1);
f01038ba:	8b 45 0c             	mov    0xc(%ebp),%eax
f01038bd:	e8 39 ff ff ff       	call   f01037fb <sys_env_destroy>
f01038c2:	eb 05                	jmp    f01038c9 <syscall+0x55>
	default:
		return -E_INVAL;
f01038c4:	b8 fd ff ff ff       	mov    $0xfffffffd,%eax
	}
}
f01038c9:	8b 5d fc             	mov    -0x4(%ebp),%ebx
f01038cc:	c9                   	leave  
f01038cd:	c3                   	ret    

f01038ce <stab_binsearch>:
stab_binsearch(const struct Stab *stabs,
               int *region_left,
               int *region_right,
               int type,
               uintptr_t addr)
{
f01038ce:	55                   	push   %ebp
f01038cf:	89 e5                	mov    %esp,%ebp
f01038d1:	57                   	push   %edi
f01038d2:	56                   	push   %esi
f01038d3:	53                   	push   %ebx
f01038d4:	83 ec 14             	sub    $0x14,%esp
f01038d7:	89 45 ec             	mov    %eax,-0x14(%ebp)
f01038da:	89 55 e4             	mov    %edx,-0x1c(%ebp)
f01038dd:	89 4d e0             	mov    %ecx,-0x20(%ebp)
f01038e0:	8b 7d 08             	mov    0x8(%ebp),%edi
	int l = *region_left, r = *region_right, any_matches = 0;
f01038e3:	8b 1a                	mov    (%edx),%ebx
f01038e5:	8b 01                	mov    (%ecx),%eax
f01038e7:	89 45 f0             	mov    %eax,-0x10(%ebp)
f01038ea:	c7 45 e8 00 00 00 00 	movl   $0x0,-0x18(%ebp)

	while (l <= r) {
f01038f1:	eb 7f                	jmp    f0103972 <stab_binsearch+0xa4>
		int true_m = (l + r) / 2, m = true_m;
f01038f3:	8b 45 f0             	mov    -0x10(%ebp),%eax
f01038f6:	01 d8                	add    %ebx,%eax
f01038f8:	89 c6                	mov    %eax,%esi
f01038fa:	c1 ee 1f             	shr    $0x1f,%esi
f01038fd:	01 c6                	add    %eax,%esi
f01038ff:	d1 fe                	sar    %esi
f0103901:	8d 04 76             	lea    (%esi,%esi,2),%eax
f0103904:	8b 4d ec             	mov    -0x14(%ebp),%ecx
f0103907:	8d 14 81             	lea    (%ecx,%eax,4),%edx
f010390a:	89 f0                	mov    %esi,%eax

		// search for earliest stab with right type
		while (m >= l && stabs[m].n_type != type)
f010390c:	eb 03                	jmp    f0103911 <stab_binsearch+0x43>
			m--;
f010390e:	83 e8 01             	sub    $0x1,%eax

	while (l <= r) {
		int true_m = (l + r) / 2, m = true_m;

		// search for earliest stab with right type
		while (m >= l && stabs[m].n_type != type)
f0103911:	39 c3                	cmp    %eax,%ebx
f0103913:	7f 0d                	jg     f0103922 <stab_binsearch+0x54>
f0103915:	0f b6 4a 04          	movzbl 0x4(%edx),%ecx
f0103919:	83 ea 0c             	sub    $0xc,%edx
f010391c:	39 f9                	cmp    %edi,%ecx
f010391e:	75 ee                	jne    f010390e <stab_binsearch+0x40>
f0103920:	eb 05                	jmp    f0103927 <stab_binsearch+0x59>
			m--;
		if (m < l) {  // no match in [l, m]
			l = true_m + 1;
f0103922:	8d 5e 01             	lea    0x1(%esi),%ebx
			continue;
f0103925:	eb 4b                	jmp    f0103972 <stab_binsearch+0xa4>
		}

		// actual binary search
		any_matches = 1;
		if (stabs[m].n_value < addr) {
f0103927:	8d 14 40             	lea    (%eax,%eax,2),%edx
f010392a:	8b 4d ec             	mov    -0x14(%ebp),%ecx
f010392d:	8b 54 91 08          	mov    0x8(%ecx,%edx,4),%edx
f0103931:	39 55 0c             	cmp    %edx,0xc(%ebp)
f0103934:	76 11                	jbe    f0103947 <stab_binsearch+0x79>
			*region_left = m;
f0103936:	8b 5d e4             	mov    -0x1c(%ebp),%ebx
f0103939:	89 03                	mov    %eax,(%ebx)
			l = true_m + 1;
f010393b:	8d 5e 01             	lea    0x1(%esi),%ebx
			l = true_m + 1;
			continue;
		}

		// actual binary search
		any_matches = 1;
f010393e:	c7 45 e8 01 00 00 00 	movl   $0x1,-0x18(%ebp)
f0103945:	eb 2b                	jmp    f0103972 <stab_binsearch+0xa4>
		if (stabs[m].n_value < addr) {
			*region_left = m;
			l = true_m + 1;
		} else if (stabs[m].n_value > addr) {
f0103947:	39 55 0c             	cmp    %edx,0xc(%ebp)
f010394a:	73 14                	jae    f0103960 <stab_binsearch+0x92>
			*region_right = m - 1;
f010394c:	83 e8 01             	sub    $0x1,%eax
f010394f:	89 45 f0             	mov    %eax,-0x10(%ebp)
f0103952:	8b 75 e0             	mov    -0x20(%ebp),%esi
f0103955:	89 06                	mov    %eax,(%esi)
			l = true_m + 1;
			continue;
		}

		// actual binary search
		any_matches = 1;
f0103957:	c7 45 e8 01 00 00 00 	movl   $0x1,-0x18(%ebp)
f010395e:	eb 12                	jmp    f0103972 <stab_binsearch+0xa4>
			*region_right = m - 1;
			r = m - 1;
		} else {
			// exact match for 'addr', but continue loop to find
			// *region_right
			*region_left = m;
f0103960:	8b 75 e4             	mov    -0x1c(%ebp),%esi
f0103963:	89 06                	mov    %eax,(%esi)
			l = m;
			addr++;
f0103965:	83 45 0c 01          	addl   $0x1,0xc(%ebp)
f0103969:	89 c3                	mov    %eax,%ebx
			l = true_m + 1;
			continue;
		}

		// actual binary search
		any_matches = 1;
f010396b:	c7 45 e8 01 00 00 00 	movl   $0x1,-0x18(%ebp)
               int type,
               uintptr_t addr)
{
	int l = *region_left, r = *region_right, any_matches = 0;

	while (l <= r) {
f0103972:	3b 5d f0             	cmp    -0x10(%ebp),%ebx
f0103975:	0f 8e 78 ff ff ff    	jle    f01038f3 <stab_binsearch+0x25>
			l = m;
			addr++;
		}
	}

	if (!any_matches)
f010397b:	83 7d e8 00          	cmpl   $0x0,-0x18(%ebp)
f010397f:	75 0f                	jne    f0103990 <stab_binsearch+0xc2>
		*region_right = *region_left - 1;
f0103981:	8b 45 e4             	mov    -0x1c(%ebp),%eax
f0103984:	8b 00                	mov    (%eax),%eax
f0103986:	83 e8 01             	sub    $0x1,%eax
f0103989:	8b 75 e0             	mov    -0x20(%ebp),%esi
f010398c:	89 06                	mov    %eax,(%esi)
f010398e:	eb 2c                	jmp    f01039bc <stab_binsearch+0xee>
	else {
		// find rightmost region containing 'addr'
		for (l = *region_right;
f0103990:	8b 45 e0             	mov    -0x20(%ebp),%eax
f0103993:	8b 00                	mov    (%eax),%eax
		     l > *region_left && stabs[l].n_type != type;
f0103995:	8b 75 e4             	mov    -0x1c(%ebp),%esi
f0103998:	8b 0e                	mov    (%esi),%ecx
f010399a:	8d 14 40             	lea    (%eax,%eax,2),%edx
f010399d:	8b 75 ec             	mov    -0x14(%ebp),%esi
f01039a0:	8d 14 96             	lea    (%esi,%edx,4),%edx

	if (!any_matches)
		*region_right = *region_left - 1;
	else {
		// find rightmost region containing 'addr'
		for (l = *region_right;
f01039a3:	eb 03                	jmp    f01039a8 <stab_binsearch+0xda>
		     l > *region_left && stabs[l].n_type != type;
		     l--)
f01039a5:	83 e8 01             	sub    $0x1,%eax

	if (!any_matches)
		*region_right = *region_left - 1;
	else {
		// find rightmost region containing 'addr'
		for (l = *region_right;
f01039a8:	39 c8                	cmp    %ecx,%eax
f01039aa:	7e 0b                	jle    f01039b7 <stab_binsearch+0xe9>
		     l > *region_left && stabs[l].n_type != type;
f01039ac:	0f b6 5a 04          	movzbl 0x4(%edx),%ebx
f01039b0:	83 ea 0c             	sub    $0xc,%edx
f01039b3:	39 df                	cmp    %ebx,%edi
f01039b5:	75 ee                	jne    f01039a5 <stab_binsearch+0xd7>
		     l--)
			/* do nothing */;
		*region_left = l;
f01039b7:	8b 75 e4             	mov    -0x1c(%ebp),%esi
f01039ba:	89 06                	mov    %eax,(%esi)
	}
}
f01039bc:	83 c4 14             	add    $0x14,%esp
f01039bf:	5b                   	pop    %ebx
f01039c0:	5e                   	pop    %esi
f01039c1:	5f                   	pop    %edi
f01039c2:	5d                   	pop    %ebp
f01039c3:	c3                   	ret    

f01039c4 <debuginfo_eip>:
//	negative if not.  But even if it returns negative it has stored some
//	information into '*info'.
//
int
debuginfo_eip(uintptr_t addr, struct Eipdebuginfo *info)
{
f01039c4:	55                   	push   %ebp
f01039c5:	89 e5                	mov    %esp,%ebp
f01039c7:	57                   	push   %edi
f01039c8:	56                   	push   %esi
f01039c9:	53                   	push   %ebx
f01039ca:	83 ec 3c             	sub    $0x3c,%esp
f01039cd:	8b 75 08             	mov    0x8(%ebp),%esi
f01039d0:	8b 5d 0c             	mov    0xc(%ebp),%ebx
	const struct Stab *stabs, *stab_end;
	const char *stabstr, *stabstr_end;
	int lfile, rfile, lfun, rfun, lline, rline;

	// Initialize *info
	info->eip_file = "<unknown>";
f01039d3:	c7 03 05 5e 10 f0    	movl   $0xf0105e05,(%ebx)
	info->eip_line = 0;
f01039d9:	c7 43 04 00 00 00 00 	movl   $0x0,0x4(%ebx)
	info->eip_fn_name = "<unknown>";
f01039e0:	c7 43 08 05 5e 10 f0 	movl   $0xf0105e05,0x8(%ebx)
	info->eip_fn_namelen = 9;
f01039e7:	c7 43 0c 09 00 00 00 	movl   $0x9,0xc(%ebx)
	info->eip_fn_addr = addr;
f01039ee:	89 73 10             	mov    %esi,0x10(%ebx)
	info->eip_fn_narg = 0;
f01039f1:	c7 43 14 00 00 00 00 	movl   $0x0,0x14(%ebx)

	// Find the relevant set of stabs
	if (addr >= ULIM) {
f01039f8:	81 fe ff ff 7f ef    	cmp    $0xef7fffff,%esi
f01039fe:	77 21                	ja     f0103a21 <debuginfo_eip+0x5d>

		// Make sure this memory is valid.
		// Return -1 if it is not.  Hint: Call user_mem_check.
		// LAB 3: Your code here.

		stabs = usd->stabs;
f0103a00:	a1 00 00 20 00       	mov    0x200000,%eax
f0103a05:	89 45 c0             	mov    %eax,-0x40(%ebp)
		stab_end = usd->stab_end;
f0103a08:	a1 04 00 20 00       	mov    0x200004,%eax
		stabstr = usd->stabstr;
f0103a0d:	8b 3d 08 00 20 00    	mov    0x200008,%edi
f0103a13:	89 7d b8             	mov    %edi,-0x48(%ebp)
		stabstr_end = usd->stabstr_end;
f0103a16:	8b 3d 0c 00 20 00    	mov    0x20000c,%edi
f0103a1c:	89 7d bc             	mov    %edi,-0x44(%ebp)
f0103a1f:	eb 1a                	jmp    f0103a3b <debuginfo_eip+0x77>
	// Find the relevant set of stabs
	if (addr >= ULIM) {
		stabs = __STAB_BEGIN__;
		stab_end = __STAB_END__;
		stabstr = __STABSTR_BEGIN__;
		stabstr_end = __STABSTR_END__;
f0103a21:	c7 45 bc 21 60 10 f0 	movl   $0xf0106021,-0x44(%ebp)

	// Find the relevant set of stabs
	if (addr >= ULIM) {
		stabs = __STAB_BEGIN__;
		stab_end = __STAB_END__;
		stabstr = __STABSTR_BEGIN__;
f0103a28:	c7 45 b8 21 60 10 f0 	movl   $0xf0106021,-0x48(%ebp)
	info->eip_fn_narg = 0;

	// Find the relevant set of stabs
	if (addr >= ULIM) {
		stabs = __STAB_BEGIN__;
		stab_end = __STAB_END__;
f0103a2f:	b8 20 60 10 f0       	mov    $0xf0106020,%eax
	info->eip_fn_addr = addr;
	info->eip_fn_narg = 0;

	// Find the relevant set of stabs
	if (addr >= ULIM) {
		stabs = __STAB_BEGIN__;
f0103a34:	c7 45 c0 20 60 10 f0 	movl   $0xf0106020,-0x40(%ebp)
		// Make sure the STABS and string table memory is valid.
		// LAB 3: Your code here.
	}

	// String table validity checks
	if (stabstr_end <= stabstr || stabstr_end[-1] != 0)
f0103a3b:	8b 7d bc             	mov    -0x44(%ebp),%edi
f0103a3e:	39 7d b8             	cmp    %edi,-0x48(%ebp)
f0103a41:	0f 83 9a 01 00 00    	jae    f0103be1 <debuginfo_eip+0x21d>
f0103a47:	80 7f ff 00          	cmpb   $0x0,-0x1(%edi)
f0103a4b:	0f 85 97 01 00 00    	jne    f0103be8 <debuginfo_eip+0x224>
	// 'eip'.  First, we find the basic source file containing 'eip'.
	// Then, we look in that source file for the function.  Then we look
	// for the line number.

	// Search the entire set of stabs for the source file (type N_SO).
	lfile = 0;
f0103a51:	c7 45 e4 00 00 00 00 	movl   $0x0,-0x1c(%ebp)
	rfile = (stab_end - stabs) - 1;
f0103a58:	8b 7d c0             	mov    -0x40(%ebp),%edi
f0103a5b:	29 f8                	sub    %edi,%eax
f0103a5d:	c1 f8 02             	sar    $0x2,%eax
f0103a60:	69 c0 ab aa aa aa    	imul   $0xaaaaaaab,%eax,%eax
f0103a66:	83 e8 01             	sub    $0x1,%eax
f0103a69:	89 45 e0             	mov    %eax,-0x20(%ebp)
	stab_binsearch(stabs, &lfile, &rfile, N_SO, addr);
f0103a6c:	56                   	push   %esi
f0103a6d:	6a 64                	push   $0x64
f0103a6f:	8d 45 e0             	lea    -0x20(%ebp),%eax
f0103a72:	89 c1                	mov    %eax,%ecx
f0103a74:	8d 55 e4             	lea    -0x1c(%ebp),%edx
f0103a77:	89 f8                	mov    %edi,%eax
f0103a79:	e8 50 fe ff ff       	call   f01038ce <stab_binsearch>
	if (lfile == 0)
f0103a7e:	8b 45 e4             	mov    -0x1c(%ebp),%eax
f0103a81:	83 c4 08             	add    $0x8,%esp
f0103a84:	85 c0                	test   %eax,%eax
f0103a86:	0f 84 63 01 00 00    	je     f0103bef <debuginfo_eip+0x22b>
		return -1;

	// Search within that file's stabs for the function definition
	// (N_FUN).
	lfun = lfile;
f0103a8c:	89 45 dc             	mov    %eax,-0x24(%ebp)
	rfun = rfile;
f0103a8f:	8b 45 e0             	mov    -0x20(%ebp),%eax
f0103a92:	89 45 d8             	mov    %eax,-0x28(%ebp)
	stab_binsearch(stabs, &lfun, &rfun, N_FUN, addr);
f0103a95:	56                   	push   %esi
f0103a96:	6a 24                	push   $0x24
f0103a98:	8d 45 d8             	lea    -0x28(%ebp),%eax
f0103a9b:	89 c1                	mov    %eax,%ecx
f0103a9d:	8d 55 dc             	lea    -0x24(%ebp),%edx
f0103aa0:	89 f8                	mov    %edi,%eax
f0103aa2:	e8 27 fe ff ff       	call   f01038ce <stab_binsearch>

	if (lfun <= rfun) {
f0103aa7:	8b 45 dc             	mov    -0x24(%ebp),%eax
f0103aaa:	8b 55 d8             	mov    -0x28(%ebp),%edx
f0103aad:	89 55 c4             	mov    %edx,-0x3c(%ebp)
f0103ab0:	83 c4 08             	add    $0x8,%esp
f0103ab3:	39 d0                	cmp    %edx,%eax
f0103ab5:	7f 2b                	jg     f0103ae2 <debuginfo_eip+0x11e>
		// stabs[lfun] points to the function name
		// in the string table, but check bounds just in case.
		if (stabs[lfun].n_strx < stabstr_end - stabstr)
f0103ab7:	8d 14 40             	lea    (%eax,%eax,2),%edx
f0103aba:	8d 0c 97             	lea    (%edi,%edx,4),%ecx
f0103abd:	8b 11                	mov    (%ecx),%edx
f0103abf:	8b 7d bc             	mov    -0x44(%ebp),%edi
f0103ac2:	2b 7d b8             	sub    -0x48(%ebp),%edi
f0103ac5:	39 fa                	cmp    %edi,%edx
f0103ac7:	73 06                	jae    f0103acf <debuginfo_eip+0x10b>
			info->eip_fn_name = stabstr + stabs[lfun].n_strx;
f0103ac9:	03 55 b8             	add    -0x48(%ebp),%edx
f0103acc:	89 53 08             	mov    %edx,0x8(%ebx)
		info->eip_fn_addr = stabs[lfun].n_value;
f0103acf:	8b 51 08             	mov    0x8(%ecx),%edx
f0103ad2:	89 53 10             	mov    %edx,0x10(%ebx)
		addr -= info->eip_fn_addr;
f0103ad5:	29 d6                	sub    %edx,%esi
		// Search within the function definition for the line number.
		lline = lfun;
f0103ad7:	89 45 d4             	mov    %eax,-0x2c(%ebp)
		rline = rfun;
f0103ada:	8b 45 c4             	mov    -0x3c(%ebp),%eax
f0103add:	89 45 d0             	mov    %eax,-0x30(%ebp)
f0103ae0:	eb 0f                	jmp    f0103af1 <debuginfo_eip+0x12d>
	} else {
		// Couldn't find function stab!  Maybe we're in an assembly
		// file.  Search the whole file for the line number.
		info->eip_fn_addr = addr;
f0103ae2:	89 73 10             	mov    %esi,0x10(%ebx)
		lline = lfile;
f0103ae5:	8b 45 e4             	mov    -0x1c(%ebp),%eax
f0103ae8:	89 45 d4             	mov    %eax,-0x2c(%ebp)
		rline = rfile;
f0103aeb:	8b 45 e0             	mov    -0x20(%ebp),%eax
f0103aee:	89 45 d0             	mov    %eax,-0x30(%ebp)
	}
	// Ignore stuff after the colon.
	info->eip_fn_namelen = strfind(info->eip_fn_name, ':') - info->eip_fn_name;
f0103af1:	83 ec 08             	sub    $0x8,%esp
f0103af4:	6a 3a                	push   $0x3a
f0103af6:	ff 73 08             	pushl  0x8(%ebx)
f0103af9:	e8 65 08 00 00       	call   f0104363 <strfind>
f0103afe:	2b 43 08             	sub    0x8(%ebx),%eax
f0103b01:	89 43 0c             	mov    %eax,0xc(%ebx)
	//	There's a particular stabs type used for line numbers.
	//	Look at the STABS documentation and <inc/stab.h> to find
	//	which one.
	// Your code here.

	stab_binsearch(stabs, &lline, &rline, N_SLINE, addr);
f0103b04:	83 c4 08             	add    $0x8,%esp
f0103b07:	56                   	push   %esi
f0103b08:	6a 44                	push   $0x44
f0103b0a:	8d 4d d0             	lea    -0x30(%ebp),%ecx
f0103b0d:	8d 55 d4             	lea    -0x2c(%ebp),%edx
f0103b10:	8b 75 c0             	mov    -0x40(%ebp),%esi
f0103b13:	89 f0                	mov    %esi,%eax
f0103b15:	e8 b4 fd ff ff       	call   f01038ce <stab_binsearch>
	if (lline <= rline) {
f0103b1a:	8b 55 d4             	mov    -0x2c(%ebp),%edx
f0103b1d:	83 c4 10             	add    $0x10,%esp
f0103b20:	3b 55 d0             	cmp    -0x30(%ebp),%edx
f0103b23:	7f 0b                	jg     f0103b30 <debuginfo_eip+0x16c>
		info->eip_line = stabs[lline].n_desc;
f0103b25:	8d 04 52             	lea    (%edx,%edx,2),%eax
f0103b28:	0f b7 44 86 06       	movzwl 0x6(%esi,%eax,4),%eax
f0103b2d:	89 43 04             	mov    %eax,0x4(%ebx)
	// Search backwards from the line number for the relevant filename
	// stab.
	// We can't just use the "lfile" stab because inlined functions
	// can interpolate code from a different file!
	// Such included source files use the N_SOL stab type.
	while (lline >= lfile && stabs[lline].n_type != N_SOL &&
f0103b30:	8b 7d e4             	mov    -0x1c(%ebp),%edi
f0103b33:	89 d0                	mov    %edx,%eax
f0103b35:	8d 14 52             	lea    (%edx,%edx,2),%edx
f0103b38:	8b 75 c0             	mov    -0x40(%ebp),%esi
f0103b3b:	8d 14 96             	lea    (%esi,%edx,4),%edx
f0103b3e:	c6 45 c4 00          	movb   $0x0,-0x3c(%ebp)
f0103b42:	89 5d 0c             	mov    %ebx,0xc(%ebp)
f0103b45:	eb 0a                	jmp    f0103b51 <debuginfo_eip+0x18d>
f0103b47:	83 e8 01             	sub    $0x1,%eax
f0103b4a:	83 ea 0c             	sub    $0xc,%edx
f0103b4d:	c6 45 c4 01          	movb   $0x1,-0x3c(%ebp)
f0103b51:	39 c7                	cmp    %eax,%edi
f0103b53:	7e 05                	jle    f0103b5a <debuginfo_eip+0x196>
f0103b55:	8b 5d 0c             	mov    0xc(%ebp),%ebx
f0103b58:	eb 47                	jmp    f0103ba1 <debuginfo_eip+0x1dd>
f0103b5a:	0f b6 4a 04          	movzbl 0x4(%edx),%ecx
f0103b5e:	80 f9 84             	cmp    $0x84,%cl
f0103b61:	75 0e                	jne    f0103b71 <debuginfo_eip+0x1ad>
f0103b63:	8b 5d 0c             	mov    0xc(%ebp),%ebx
f0103b66:	80 7d c4 00          	cmpb   $0x0,-0x3c(%ebp)
f0103b6a:	74 1c                	je     f0103b88 <debuginfo_eip+0x1c4>
f0103b6c:	89 45 d4             	mov    %eax,-0x2c(%ebp)
f0103b6f:	eb 17                	jmp    f0103b88 <debuginfo_eip+0x1c4>
f0103b71:	80 f9 64             	cmp    $0x64,%cl
f0103b74:	75 d1                	jne    f0103b47 <debuginfo_eip+0x183>
	       (stabs[lline].n_type != N_SO || !stabs[lline].n_value))
f0103b76:	83 7a 08 00          	cmpl   $0x0,0x8(%edx)
f0103b7a:	74 cb                	je     f0103b47 <debuginfo_eip+0x183>
f0103b7c:	8b 5d 0c             	mov    0xc(%ebp),%ebx
f0103b7f:	80 7d c4 00          	cmpb   $0x0,-0x3c(%ebp)
f0103b83:	74 03                	je     f0103b88 <debuginfo_eip+0x1c4>
f0103b85:	89 45 d4             	mov    %eax,-0x2c(%ebp)
		lline--;
	if (lline >= lfile && stabs[lline].n_strx < stabstr_end - stabstr)
f0103b88:	8d 04 40             	lea    (%eax,%eax,2),%eax
f0103b8b:	8b 75 c0             	mov    -0x40(%ebp),%esi
f0103b8e:	8b 14 86             	mov    (%esi,%eax,4),%edx
f0103b91:	8b 45 bc             	mov    -0x44(%ebp),%eax
f0103b94:	8b 7d b8             	mov    -0x48(%ebp),%edi
f0103b97:	29 f8                	sub    %edi,%eax
f0103b99:	39 c2                	cmp    %eax,%edx
f0103b9b:	73 04                	jae    f0103ba1 <debuginfo_eip+0x1dd>
		info->eip_file = stabstr + stabs[lline].n_strx;
f0103b9d:	01 fa                	add    %edi,%edx
f0103b9f:	89 13                	mov    %edx,(%ebx)


	// Set eip_fn_narg to the number of arguments taken by the function,
	// or 0 if there was no containing function.
	if (lfun < rfun)
f0103ba1:	8b 55 dc             	mov    -0x24(%ebp),%edx
f0103ba4:	8b 75 d8             	mov    -0x28(%ebp),%esi
		for (lline = lfun + 1;
		     lline < rfun && stabs[lline].n_type == N_PSYM;
		     lline++)
			info->eip_fn_narg++;

	return 0;
f0103ba7:	b8 00 00 00 00       	mov    $0x0,%eax
		info->eip_file = stabstr + stabs[lline].n_strx;


	// Set eip_fn_narg to the number of arguments taken by the function,
	// or 0 if there was no containing function.
	if (lfun < rfun)
f0103bac:	39 f2                	cmp    %esi,%edx
f0103bae:	7d 4b                	jge    f0103bfb <debuginfo_eip+0x237>
		for (lline = lfun + 1;
f0103bb0:	83 c2 01             	add    $0x1,%edx
f0103bb3:	89 55 d4             	mov    %edx,-0x2c(%ebp)
f0103bb6:	89 d0                	mov    %edx,%eax
f0103bb8:	8d 14 52             	lea    (%edx,%edx,2),%edx
f0103bbb:	8b 7d c0             	mov    -0x40(%ebp),%edi
f0103bbe:	8d 14 97             	lea    (%edi,%edx,4),%edx
f0103bc1:	eb 04                	jmp    f0103bc7 <debuginfo_eip+0x203>
		     lline < rfun && stabs[lline].n_type == N_PSYM;
		     lline++)
			info->eip_fn_narg++;
f0103bc3:	83 43 14 01          	addl   $0x1,0x14(%ebx)


	// Set eip_fn_narg to the number of arguments taken by the function,
	// or 0 if there was no containing function.
	if (lfun < rfun)
		for (lline = lfun + 1;
f0103bc7:	39 c6                	cmp    %eax,%esi
f0103bc9:	7e 2b                	jle    f0103bf6 <debuginfo_eip+0x232>
		     lline < rfun && stabs[lline].n_type == N_PSYM;
f0103bcb:	0f b6 4a 04          	movzbl 0x4(%edx),%ecx
f0103bcf:	83 c0 01             	add    $0x1,%eax
f0103bd2:	83 c2 0c             	add    $0xc,%edx
f0103bd5:	80 f9 a0             	cmp    $0xa0,%cl
f0103bd8:	74 e9                	je     f0103bc3 <debuginfo_eip+0x1ff>
		     lline++)
			info->eip_fn_narg++;

	return 0;
f0103bda:	b8 00 00 00 00       	mov    $0x0,%eax
f0103bdf:	eb 1a                	jmp    f0103bfb <debuginfo_eip+0x237>
		// LAB 3: Your code here.
	}

	// String table validity checks
	if (stabstr_end <= stabstr || stabstr_end[-1] != 0)
		return -1;
f0103be1:	b8 ff ff ff ff       	mov    $0xffffffff,%eax
f0103be6:	eb 13                	jmp    f0103bfb <debuginfo_eip+0x237>
f0103be8:	b8 ff ff ff ff       	mov    $0xffffffff,%eax
f0103bed:	eb 0c                	jmp    f0103bfb <debuginfo_eip+0x237>
	// Search the entire set of stabs for the source file (type N_SO).
	lfile = 0;
	rfile = (stab_end - stabs) - 1;
	stab_binsearch(stabs, &lfile, &rfile, N_SO, addr);
	if (lfile == 0)
		return -1;
f0103bef:	b8 ff ff ff ff       	mov    $0xffffffff,%eax
f0103bf4:	eb 05                	jmp    f0103bfb <debuginfo_eip+0x237>
		for (lline = lfun + 1;
		     lline < rfun && stabs[lline].n_type == N_PSYM;
		     lline++)
			info->eip_fn_narg++;

	return 0;
f0103bf6:	b8 00 00 00 00       	mov    $0x0,%eax
}
f0103bfb:	8d 65 f4             	lea    -0xc(%ebp),%esp
f0103bfe:	5b                   	pop    %ebx
f0103bff:	5e                   	pop    %esi
f0103c00:	5f                   	pop    %edi
f0103c01:	5d                   	pop    %ebp
f0103c02:	c3                   	ret    

f0103c03 <printnum>:
 * using specified putch function and associated pointer putdat.
 */
static void
printnum(void (*putch)(int, void*), void *putdat,
	 unsigned long long num, unsigned base, int width, int padc)
{
f0103c03:	55                   	push   %ebp
f0103c04:	89 e5                	mov    %esp,%ebp
f0103c06:	57                   	push   %edi
f0103c07:	56                   	push   %esi
f0103c08:	53                   	push   %ebx
f0103c09:	83 ec 1c             	sub    $0x1c,%esp
f0103c0c:	89 c7                	mov    %eax,%edi
f0103c0e:	89 d6                	mov    %edx,%esi
f0103c10:	8b 45 08             	mov    0x8(%ebp),%eax
f0103c13:	8b 55 0c             	mov    0xc(%ebp),%edx
f0103c16:	89 45 d8             	mov    %eax,-0x28(%ebp)
f0103c19:	89 55 dc             	mov    %edx,-0x24(%ebp)
	// first recursively print all preceding (more significant) digits
	if (num >= base) {
f0103c1c:	8b 4d 10             	mov    0x10(%ebp),%ecx
f0103c1f:	bb 00 00 00 00       	mov    $0x0,%ebx
f0103c24:	89 4d e0             	mov    %ecx,-0x20(%ebp)
f0103c27:	89 5d e4             	mov    %ebx,-0x1c(%ebp)
f0103c2a:	39 d3                	cmp    %edx,%ebx
f0103c2c:	72 05                	jb     f0103c33 <printnum+0x30>
f0103c2e:	39 45 10             	cmp    %eax,0x10(%ebp)
f0103c31:	77 45                	ja     f0103c78 <printnum+0x75>
		printnum(putch, putdat, num / base, base, width - 1, padc);
f0103c33:	83 ec 0c             	sub    $0xc,%esp
f0103c36:	ff 75 18             	pushl  0x18(%ebp)
f0103c39:	8b 45 14             	mov    0x14(%ebp),%eax
f0103c3c:	8d 58 ff             	lea    -0x1(%eax),%ebx
f0103c3f:	53                   	push   %ebx
f0103c40:	ff 75 10             	pushl  0x10(%ebp)
f0103c43:	83 ec 08             	sub    $0x8,%esp
f0103c46:	ff 75 e4             	pushl  -0x1c(%ebp)
f0103c49:	ff 75 e0             	pushl  -0x20(%ebp)
f0103c4c:	ff 75 dc             	pushl  -0x24(%ebp)
f0103c4f:	ff 75 d8             	pushl  -0x28(%ebp)
f0103c52:	e8 29 09 00 00       	call   f0104580 <__udivdi3>
f0103c57:	83 c4 18             	add    $0x18,%esp
f0103c5a:	52                   	push   %edx
f0103c5b:	50                   	push   %eax
f0103c5c:	89 f2                	mov    %esi,%edx
f0103c5e:	89 f8                	mov    %edi,%eax
f0103c60:	e8 9e ff ff ff       	call   f0103c03 <printnum>
f0103c65:	83 c4 20             	add    $0x20,%esp
f0103c68:	eb 18                	jmp    f0103c82 <printnum+0x7f>
	} else {
		// print any needed pad characters before first digit
		while (--width > 0)
			putch(padc, putdat);
f0103c6a:	83 ec 08             	sub    $0x8,%esp
f0103c6d:	56                   	push   %esi
f0103c6e:	ff 75 18             	pushl  0x18(%ebp)
f0103c71:	ff d7                	call   *%edi
f0103c73:	83 c4 10             	add    $0x10,%esp
f0103c76:	eb 03                	jmp    f0103c7b <printnum+0x78>
f0103c78:	8b 5d 14             	mov    0x14(%ebp),%ebx
	// first recursively print all preceding (more significant) digits
	if (num >= base) {
		printnum(putch, putdat, num / base, base, width - 1, padc);
	} else {
		// print any needed pad characters before first digit
		while (--width > 0)
f0103c7b:	83 eb 01             	sub    $0x1,%ebx
f0103c7e:	85 db                	test   %ebx,%ebx
f0103c80:	7f e8                	jg     f0103c6a <printnum+0x67>
			putch(padc, putdat);
	}

	// then print this (the least significant) digit
	putch("0123456789abcdef"[num % base], putdat);
f0103c82:	83 ec 08             	sub    $0x8,%esp
f0103c85:	56                   	push   %esi
f0103c86:	83 ec 04             	sub    $0x4,%esp
f0103c89:	ff 75 e4             	pushl  -0x1c(%ebp)
f0103c8c:	ff 75 e0             	pushl  -0x20(%ebp)
f0103c8f:	ff 75 dc             	pushl  -0x24(%ebp)
f0103c92:	ff 75 d8             	pushl  -0x28(%ebp)
f0103c95:	e8 16 0a 00 00       	call   f01046b0 <__umoddi3>
f0103c9a:	83 c4 14             	add    $0x14,%esp
f0103c9d:	0f be 80 0f 5e 10 f0 	movsbl -0xfefa1f1(%eax),%eax
f0103ca4:	50                   	push   %eax
f0103ca5:	ff d7                	call   *%edi
}
f0103ca7:	83 c4 10             	add    $0x10,%esp
f0103caa:	8d 65 f4             	lea    -0xc(%ebp),%esp
f0103cad:	5b                   	pop    %ebx
f0103cae:	5e                   	pop    %esi
f0103caf:	5f                   	pop    %edi
f0103cb0:	5d                   	pop    %ebp
f0103cb1:	c3                   	ret    

f0103cb2 <getuint>:

// Get an unsigned int of various possible sizes from a varargs list,
// depending on the lflag parameter.
static unsigned long long
getuint(va_list *ap, int lflag)
{
f0103cb2:	55                   	push   %ebp
f0103cb3:	89 e5                	mov    %esp,%ebp
	if (lflag >= 2)
f0103cb5:	83 fa 01             	cmp    $0x1,%edx
f0103cb8:	7e 0e                	jle    f0103cc8 <getuint+0x16>
		return va_arg(*ap, unsigned long long);
f0103cba:	8b 10                	mov    (%eax),%edx
f0103cbc:	8d 4a 08             	lea    0x8(%edx),%ecx
f0103cbf:	89 08                	mov    %ecx,(%eax)
f0103cc1:	8b 02                	mov    (%edx),%eax
f0103cc3:	8b 52 04             	mov    0x4(%edx),%edx
f0103cc6:	eb 22                	jmp    f0103cea <getuint+0x38>
	else if (lflag)
f0103cc8:	85 d2                	test   %edx,%edx
f0103cca:	74 10                	je     f0103cdc <getuint+0x2a>
		return va_arg(*ap, unsigned long);
f0103ccc:	8b 10                	mov    (%eax),%edx
f0103cce:	8d 4a 04             	lea    0x4(%edx),%ecx
f0103cd1:	89 08                	mov    %ecx,(%eax)
f0103cd3:	8b 02                	mov    (%edx),%eax
f0103cd5:	ba 00 00 00 00       	mov    $0x0,%edx
f0103cda:	eb 0e                	jmp    f0103cea <getuint+0x38>
	else
		return va_arg(*ap, unsigned int);
f0103cdc:	8b 10                	mov    (%eax),%edx
f0103cde:	8d 4a 04             	lea    0x4(%edx),%ecx
f0103ce1:	89 08                	mov    %ecx,(%eax)
f0103ce3:	8b 02                	mov    (%edx),%eax
f0103ce5:	ba 00 00 00 00       	mov    $0x0,%edx
}
f0103cea:	5d                   	pop    %ebp
f0103ceb:	c3                   	ret    

f0103cec <getint>:

// Same as getuint but signed - can't use getuint
// because of sign extension
static long long
getint(va_list *ap, int lflag)
{
f0103cec:	55                   	push   %ebp
f0103ced:	89 e5                	mov    %esp,%ebp
	if (lflag >= 2)
f0103cef:	83 fa 01             	cmp    $0x1,%edx
f0103cf2:	7e 0e                	jle    f0103d02 <getint+0x16>
		return va_arg(*ap, long long);
f0103cf4:	8b 10                	mov    (%eax),%edx
f0103cf6:	8d 4a 08             	lea    0x8(%edx),%ecx
f0103cf9:	89 08                	mov    %ecx,(%eax)
f0103cfb:	8b 02                	mov    (%edx),%eax
f0103cfd:	8b 52 04             	mov    0x4(%edx),%edx
f0103d00:	eb 1a                	jmp    f0103d1c <getint+0x30>
	else if (lflag)
f0103d02:	85 d2                	test   %edx,%edx
f0103d04:	74 0c                	je     f0103d12 <getint+0x26>
		return va_arg(*ap, long);
f0103d06:	8b 10                	mov    (%eax),%edx
f0103d08:	8d 4a 04             	lea    0x4(%edx),%ecx
f0103d0b:	89 08                	mov    %ecx,(%eax)
f0103d0d:	8b 02                	mov    (%edx),%eax
f0103d0f:	99                   	cltd   
f0103d10:	eb 0a                	jmp    f0103d1c <getint+0x30>
	else
		return va_arg(*ap, int);
f0103d12:	8b 10                	mov    (%eax),%edx
f0103d14:	8d 4a 04             	lea    0x4(%edx),%ecx
f0103d17:	89 08                	mov    %ecx,(%eax)
f0103d19:	8b 02                	mov    (%edx),%eax
f0103d1b:	99                   	cltd   
}
f0103d1c:	5d                   	pop    %ebp
f0103d1d:	c3                   	ret    

f0103d1e <sprintputch>:
	int cnt;
};

static void
sprintputch(int ch, struct sprintbuf *b)
{
f0103d1e:	55                   	push   %ebp
f0103d1f:	89 e5                	mov    %esp,%ebp
f0103d21:	8b 45 0c             	mov    0xc(%ebp),%eax
	b->cnt++;
f0103d24:	83 40 08 01          	addl   $0x1,0x8(%eax)
	if (b->buf < b->ebuf)
f0103d28:	8b 10                	mov    (%eax),%edx
f0103d2a:	3b 50 04             	cmp    0x4(%eax),%edx
f0103d2d:	73 0a                	jae    f0103d39 <sprintputch+0x1b>
		*b->buf++ = ch;
f0103d2f:	8d 4a 01             	lea    0x1(%edx),%ecx
f0103d32:	89 08                	mov    %ecx,(%eax)
f0103d34:	8b 45 08             	mov    0x8(%ebp),%eax
f0103d37:	88 02                	mov    %al,(%edx)
}
f0103d39:	5d                   	pop    %ebp
f0103d3a:	c3                   	ret    

f0103d3b <printfmt>:
	}
}

void
printfmt(void (*putch)(int, void*), void *putdat, const char *fmt, ...)
{
f0103d3b:	55                   	push   %ebp
f0103d3c:	89 e5                	mov    %esp,%ebp
f0103d3e:	83 ec 08             	sub    $0x8,%esp
	va_list ap;

	va_start(ap, fmt);
f0103d41:	8d 45 14             	lea    0x14(%ebp),%eax
	vprintfmt(putch, putdat, fmt, ap);
f0103d44:	50                   	push   %eax
f0103d45:	ff 75 10             	pushl  0x10(%ebp)
f0103d48:	ff 75 0c             	pushl  0xc(%ebp)
f0103d4b:	ff 75 08             	pushl  0x8(%ebp)
f0103d4e:	e8 05 00 00 00       	call   f0103d58 <vprintfmt>
	va_end(ap);
}
f0103d53:	83 c4 10             	add    $0x10,%esp
f0103d56:	c9                   	leave  
f0103d57:	c3                   	ret    

f0103d58 <vprintfmt>:
// Main function to format and print a string.
void printfmt(void (*putch)(int, void*), void *putdat, const char *fmt, ...);

void
vprintfmt(void (*putch)(int, void*), void *putdat, const char *fmt, va_list ap)
{
f0103d58:	55                   	push   %ebp
f0103d59:	89 e5                	mov    %esp,%ebp
f0103d5b:	57                   	push   %edi
f0103d5c:	56                   	push   %esi
f0103d5d:	53                   	push   %ebx
f0103d5e:	83 ec 2c             	sub    $0x2c,%esp
f0103d61:	8b 75 08             	mov    0x8(%ebp),%esi
f0103d64:	8b 5d 0c             	mov    0xc(%ebp),%ebx
f0103d67:	8b 7d 10             	mov    0x10(%ebp),%edi
f0103d6a:	eb 12                	jmp    f0103d7e <vprintfmt+0x26>
	int base, lflag, width, precision, altflag;
	char padc;

	while (1) {
		while ((ch = *(unsigned char *) fmt++) != '%') {
			if (ch == '\0')
f0103d6c:	85 c0                	test   %eax,%eax
f0103d6e:	0f 84 44 03 00 00    	je     f01040b8 <vprintfmt+0x360>
				return;
			putch(ch, putdat);
f0103d74:	83 ec 08             	sub    $0x8,%esp
f0103d77:	53                   	push   %ebx
f0103d78:	50                   	push   %eax
f0103d79:	ff d6                	call   *%esi
f0103d7b:	83 c4 10             	add    $0x10,%esp
	unsigned long long num;
	int base, lflag, width, precision, altflag;
	char padc;

	while (1) {
		while ((ch = *(unsigned char *) fmt++) != '%') {
f0103d7e:	83 c7 01             	add    $0x1,%edi
f0103d81:	0f b6 47 ff          	movzbl -0x1(%edi),%eax
f0103d85:	83 f8 25             	cmp    $0x25,%eax
f0103d88:	75 e2                	jne    f0103d6c <vprintfmt+0x14>
f0103d8a:	c6 45 d4 20          	movb   $0x20,-0x2c(%ebp)
f0103d8e:	c7 45 d8 00 00 00 00 	movl   $0x0,-0x28(%ebp)
f0103d95:	c7 45 d0 ff ff ff ff 	movl   $0xffffffff,-0x30(%ebp)
f0103d9c:	c7 45 e0 ff ff ff ff 	movl   $0xffffffff,-0x20(%ebp)
f0103da3:	ba 00 00 00 00       	mov    $0x0,%edx
f0103da8:	eb 07                	jmp    f0103db1 <vprintfmt+0x59>
		width = -1;
		precision = -1;
		lflag = 0;
		altflag = 0;
	reswitch:
		switch (ch = *(unsigned char *) fmt++) {
f0103daa:	8b 7d e4             	mov    -0x1c(%ebp),%edi

		// flag to pad on the right
		case '-':
			padc = '-';
f0103dad:	c6 45 d4 2d          	movb   $0x2d,-0x2c(%ebp)
		width = -1;
		precision = -1;
		lflag = 0;
		altflag = 0;
	reswitch:
		switch (ch = *(unsigned char *) fmt++) {
f0103db1:	8d 47 01             	lea    0x1(%edi),%eax
f0103db4:	89 45 e4             	mov    %eax,-0x1c(%ebp)
f0103db7:	0f b6 07             	movzbl (%edi),%eax
f0103dba:	0f b6 c8             	movzbl %al,%ecx
f0103dbd:	83 e8 23             	sub    $0x23,%eax
f0103dc0:	3c 55                	cmp    $0x55,%al
f0103dc2:	0f 87 d5 02 00 00    	ja     f010409d <vprintfmt+0x345>
f0103dc8:	0f b6 c0             	movzbl %al,%eax
f0103dcb:	ff 24 85 9c 5e 10 f0 	jmp    *-0xfefa164(,%eax,4)
f0103dd2:	8b 7d e4             	mov    -0x1c(%ebp),%edi
			padc = '-';
			goto reswitch;

		// flag to pad with 0's instead of spaces
		case '0':
			padc = '0';
f0103dd5:	c6 45 d4 30          	movb   $0x30,-0x2c(%ebp)
f0103dd9:	eb d6                	jmp    f0103db1 <vprintfmt+0x59>
		width = -1;
		precision = -1;
		lflag = 0;
		altflag = 0;
	reswitch:
		switch (ch = *(unsigned char *) fmt++) {
f0103ddb:	8b 7d e4             	mov    -0x1c(%ebp),%edi
f0103dde:	b8 00 00 00 00       	mov    $0x0,%eax
f0103de3:	89 55 e4             	mov    %edx,-0x1c(%ebp)
		case '6':
		case '7':
		case '8':
		case '9':
			for (precision = 0; ; ++fmt) {
				precision = precision * 10 + ch - '0';
f0103de6:	8d 04 80             	lea    (%eax,%eax,4),%eax
f0103de9:	8d 44 41 d0          	lea    -0x30(%ecx,%eax,2),%eax
				ch = *fmt;
f0103ded:	0f be 0f             	movsbl (%edi),%ecx
				if (ch < '0' || ch > '9')
f0103df0:	8d 51 d0             	lea    -0x30(%ecx),%edx
f0103df3:	83 fa 09             	cmp    $0x9,%edx
f0103df6:	77 39                	ja     f0103e31 <vprintfmt+0xd9>
		case '5':
		case '6':
		case '7':
		case '8':
		case '9':
			for (precision = 0; ; ++fmt) {
f0103df8:	83 c7 01             	add    $0x1,%edi
				precision = precision * 10 + ch - '0';
				ch = *fmt;
				if (ch < '0' || ch > '9')
					break;
			}
f0103dfb:	eb e9                	jmp    f0103de6 <vprintfmt+0x8e>
			goto process_precision;

		case '*':
			precision = va_arg(ap, int);
f0103dfd:	8b 45 14             	mov    0x14(%ebp),%eax
f0103e00:	8d 48 04             	lea    0x4(%eax),%ecx
f0103e03:	89 4d 14             	mov    %ecx,0x14(%ebp)
f0103e06:	8b 00                	mov    (%eax),%eax
f0103e08:	89 45 d0             	mov    %eax,-0x30(%ebp)
		width = -1;
		precision = -1;
		lflag = 0;
		altflag = 0;
	reswitch:
		switch (ch = *(unsigned char *) fmt++) {
f0103e0b:	8b 7d e4             	mov    -0x1c(%ebp),%edi
			}
			goto process_precision;

		case '*':
			precision = va_arg(ap, int);
			goto process_precision;
f0103e0e:	eb 27                	jmp    f0103e37 <vprintfmt+0xdf>
f0103e10:	8b 45 e0             	mov    -0x20(%ebp),%eax
f0103e13:	85 c0                	test   %eax,%eax
f0103e15:	b9 00 00 00 00       	mov    $0x0,%ecx
f0103e1a:	0f 49 c8             	cmovns %eax,%ecx
f0103e1d:	89 4d e0             	mov    %ecx,-0x20(%ebp)
		width = -1;
		precision = -1;
		lflag = 0;
		altflag = 0;
	reswitch:
		switch (ch = *(unsigned char *) fmt++) {
f0103e20:	8b 7d e4             	mov    -0x1c(%ebp),%edi
f0103e23:	eb 8c                	jmp    f0103db1 <vprintfmt+0x59>
f0103e25:	8b 7d e4             	mov    -0x1c(%ebp),%edi
			if (width < 0)
				width = 0;
			goto reswitch;

		case '#':
			altflag = 1;
f0103e28:	c7 45 d8 01 00 00 00 	movl   $0x1,-0x28(%ebp)
			goto reswitch;
f0103e2f:	eb 80                	jmp    f0103db1 <vprintfmt+0x59>
f0103e31:	8b 55 e4             	mov    -0x1c(%ebp),%edx
f0103e34:	89 45 d0             	mov    %eax,-0x30(%ebp)

		process_precision:
			if (width < 0)
f0103e37:	83 7d e0 00          	cmpl   $0x0,-0x20(%ebp)
f0103e3b:	0f 89 70 ff ff ff    	jns    f0103db1 <vprintfmt+0x59>
				width = precision, precision = -1;
f0103e41:	8b 45 d0             	mov    -0x30(%ebp),%eax
f0103e44:	89 45 e0             	mov    %eax,-0x20(%ebp)
f0103e47:	c7 45 d0 ff ff ff ff 	movl   $0xffffffff,-0x30(%ebp)
f0103e4e:	e9 5e ff ff ff       	jmp    f0103db1 <vprintfmt+0x59>
			goto reswitch;

		// long flag (doubled for long long)
		case 'l':
			lflag++;
f0103e53:	83 c2 01             	add    $0x1,%edx
		width = -1;
		precision = -1;
		lflag = 0;
		altflag = 0;
	reswitch:
		switch (ch = *(unsigned char *) fmt++) {
f0103e56:	8b 7d e4             	mov    -0x1c(%ebp),%edi
			goto reswitch;

		// long flag (doubled for long long)
		case 'l':
			lflag++;
			goto reswitch;
f0103e59:	e9 53 ff ff ff       	jmp    f0103db1 <vprintfmt+0x59>

		// character
		case 'c':
			putch(va_arg(ap, int), putdat);
f0103e5e:	8b 45 14             	mov    0x14(%ebp),%eax
f0103e61:	8d 50 04             	lea    0x4(%eax),%edx
f0103e64:	89 55 14             	mov    %edx,0x14(%ebp)
f0103e67:	83 ec 08             	sub    $0x8,%esp
f0103e6a:	53                   	push   %ebx
f0103e6b:	ff 30                	pushl  (%eax)
f0103e6d:	ff d6                	call   *%esi
			break;
f0103e6f:	83 c4 10             	add    $0x10,%esp
		width = -1;
		precision = -1;
		lflag = 0;
		altflag = 0;
	reswitch:
		switch (ch = *(unsigned char *) fmt++) {
f0103e72:	8b 7d e4             	mov    -0x1c(%ebp),%edi
			goto reswitch;

		// character
		case 'c':
			putch(va_arg(ap, int), putdat);
			break;
f0103e75:	e9 04 ff ff ff       	jmp    f0103d7e <vprintfmt+0x26>

		// error message
		case 'e':
			err = va_arg(ap, int);
f0103e7a:	8b 45 14             	mov    0x14(%ebp),%eax
f0103e7d:	8d 50 04             	lea    0x4(%eax),%edx
f0103e80:	89 55 14             	mov    %edx,0x14(%ebp)
f0103e83:	8b 00                	mov    (%eax),%eax
f0103e85:	99                   	cltd   
f0103e86:	31 d0                	xor    %edx,%eax
f0103e88:	29 d0                	sub    %edx,%eax
			if (err < 0)
				err = -err;
			if (err >= MAXERROR || (p = error_string[err]) == NULL)
f0103e8a:	83 f8 06             	cmp    $0x6,%eax
f0103e8d:	7f 0b                	jg     f0103e9a <vprintfmt+0x142>
f0103e8f:	8b 14 85 f4 5f 10 f0 	mov    -0xfefa00c(,%eax,4),%edx
f0103e96:	85 d2                	test   %edx,%edx
f0103e98:	75 18                	jne    f0103eb2 <vprintfmt+0x15a>
				printfmt(putch, putdat, "error %d", err);
f0103e9a:	50                   	push   %eax
f0103e9b:	68 27 5e 10 f0       	push   $0xf0105e27
f0103ea0:	53                   	push   %ebx
f0103ea1:	56                   	push   %esi
f0103ea2:	e8 94 fe ff ff       	call   f0103d3b <printfmt>
f0103ea7:	83 c4 10             	add    $0x10,%esp
		width = -1;
		precision = -1;
		lflag = 0;
		altflag = 0;
	reswitch:
		switch (ch = *(unsigned char *) fmt++) {
f0103eaa:	8b 7d e4             	mov    -0x1c(%ebp),%edi
		case 'e':
			err = va_arg(ap, int);
			if (err < 0)
				err = -err;
			if (err >= MAXERROR || (p = error_string[err]) == NULL)
				printfmt(putch, putdat, "error %d", err);
f0103ead:	e9 cc fe ff ff       	jmp    f0103d7e <vprintfmt+0x26>
			else
				printfmt(putch, putdat, "%s", p);
f0103eb2:	52                   	push   %edx
f0103eb3:	68 8c 55 10 f0       	push   $0xf010558c
f0103eb8:	53                   	push   %ebx
f0103eb9:	56                   	push   %esi
f0103eba:	e8 7c fe ff ff       	call   f0103d3b <printfmt>
f0103ebf:	83 c4 10             	add    $0x10,%esp
		width = -1;
		precision = -1;
		lflag = 0;
		altflag = 0;
	reswitch:
		switch (ch = *(unsigned char *) fmt++) {
f0103ec2:	8b 7d e4             	mov    -0x1c(%ebp),%edi
f0103ec5:	e9 b4 fe ff ff       	jmp    f0103d7e <vprintfmt+0x26>
				printfmt(putch, putdat, "%s", p);
			break;

		// string
		case 's':
			if ((p = va_arg(ap, char *)) == NULL)
f0103eca:	8b 45 14             	mov    0x14(%ebp),%eax
f0103ecd:	8d 50 04             	lea    0x4(%eax),%edx
f0103ed0:	89 55 14             	mov    %edx,0x14(%ebp)
f0103ed3:	8b 38                	mov    (%eax),%edi
				p = "(null)";
f0103ed5:	85 ff                	test   %edi,%edi
f0103ed7:	b8 20 5e 10 f0       	mov    $0xf0105e20,%eax
f0103edc:	0f 44 f8             	cmove  %eax,%edi
			if (width > 0 && padc != '-')
f0103edf:	83 7d e0 00          	cmpl   $0x0,-0x20(%ebp)
f0103ee3:	0f 8e 94 00 00 00    	jle    f0103f7d <vprintfmt+0x225>
f0103ee9:	80 7d d4 2d          	cmpb   $0x2d,-0x2c(%ebp)
f0103eed:	0f 84 98 00 00 00    	je     f0103f8b <vprintfmt+0x233>
				for (width -= strnlen(p, precision); width > 0; width--)
f0103ef3:	83 ec 08             	sub    $0x8,%esp
f0103ef6:	ff 75 d0             	pushl  -0x30(%ebp)
f0103ef9:	57                   	push   %edi
f0103efa:	e8 1a 03 00 00       	call   f0104219 <strnlen>
f0103eff:	8b 4d e0             	mov    -0x20(%ebp),%ecx
f0103f02:	29 c1                	sub    %eax,%ecx
f0103f04:	89 4d cc             	mov    %ecx,-0x34(%ebp)
f0103f07:	83 c4 10             	add    $0x10,%esp
					putch(padc, putdat);
f0103f0a:	0f be 45 d4          	movsbl -0x2c(%ebp),%eax
f0103f0e:	89 45 e0             	mov    %eax,-0x20(%ebp)
f0103f11:	89 7d d4             	mov    %edi,-0x2c(%ebp)
f0103f14:	89 cf                	mov    %ecx,%edi
		// string
		case 's':
			if ((p = va_arg(ap, char *)) == NULL)
				p = "(null)";
			if (width > 0 && padc != '-')
				for (width -= strnlen(p, precision); width > 0; width--)
f0103f16:	eb 0f                	jmp    f0103f27 <vprintfmt+0x1cf>
					putch(padc, putdat);
f0103f18:	83 ec 08             	sub    $0x8,%esp
f0103f1b:	53                   	push   %ebx
f0103f1c:	ff 75 e0             	pushl  -0x20(%ebp)
f0103f1f:	ff d6                	call   *%esi
		// string
		case 's':
			if ((p = va_arg(ap, char *)) == NULL)
				p = "(null)";
			if (width > 0 && padc != '-')
				for (width -= strnlen(p, precision); width > 0; width--)
f0103f21:	83 ef 01             	sub    $0x1,%edi
f0103f24:	83 c4 10             	add    $0x10,%esp
f0103f27:	85 ff                	test   %edi,%edi
f0103f29:	7f ed                	jg     f0103f18 <vprintfmt+0x1c0>
f0103f2b:	8b 7d d4             	mov    -0x2c(%ebp),%edi
f0103f2e:	8b 4d cc             	mov    -0x34(%ebp),%ecx
f0103f31:	85 c9                	test   %ecx,%ecx
f0103f33:	b8 00 00 00 00       	mov    $0x0,%eax
f0103f38:	0f 49 c1             	cmovns %ecx,%eax
f0103f3b:	29 c1                	sub    %eax,%ecx
f0103f3d:	89 75 08             	mov    %esi,0x8(%ebp)
f0103f40:	8b 75 d0             	mov    -0x30(%ebp),%esi
f0103f43:	89 5d 0c             	mov    %ebx,0xc(%ebp)
f0103f46:	89 cb                	mov    %ecx,%ebx
f0103f48:	eb 4d                	jmp    f0103f97 <vprintfmt+0x23f>
					putch(padc, putdat);
			for (; (ch = *p++) != '\0' && (precision < 0 || --precision >= 0); width--)
				if (altflag && (ch < ' ' || ch > '~'))
f0103f4a:	83 7d d8 00          	cmpl   $0x0,-0x28(%ebp)
f0103f4e:	74 1b                	je     f0103f6b <vprintfmt+0x213>
f0103f50:	0f be c0             	movsbl %al,%eax
f0103f53:	83 e8 20             	sub    $0x20,%eax
f0103f56:	83 f8 5e             	cmp    $0x5e,%eax
f0103f59:	76 10                	jbe    f0103f6b <vprintfmt+0x213>
					putch('?', putdat);
f0103f5b:	83 ec 08             	sub    $0x8,%esp
f0103f5e:	ff 75 0c             	pushl  0xc(%ebp)
f0103f61:	6a 3f                	push   $0x3f
f0103f63:	ff 55 08             	call   *0x8(%ebp)
f0103f66:	83 c4 10             	add    $0x10,%esp
f0103f69:	eb 0d                	jmp    f0103f78 <vprintfmt+0x220>
				else
					putch(ch, putdat);
f0103f6b:	83 ec 08             	sub    $0x8,%esp
f0103f6e:	ff 75 0c             	pushl  0xc(%ebp)
f0103f71:	52                   	push   %edx
f0103f72:	ff 55 08             	call   *0x8(%ebp)
f0103f75:	83 c4 10             	add    $0x10,%esp
			if ((p = va_arg(ap, char *)) == NULL)
				p = "(null)";
			if (width > 0 && padc != '-')
				for (width -= strnlen(p, precision); width > 0; width--)
					putch(padc, putdat);
			for (; (ch = *p++) != '\0' && (precision < 0 || --precision >= 0); width--)
f0103f78:	83 eb 01             	sub    $0x1,%ebx
f0103f7b:	eb 1a                	jmp    f0103f97 <vprintfmt+0x23f>
f0103f7d:	89 75 08             	mov    %esi,0x8(%ebp)
f0103f80:	8b 75 d0             	mov    -0x30(%ebp),%esi
f0103f83:	89 5d 0c             	mov    %ebx,0xc(%ebp)
f0103f86:	8b 5d e0             	mov    -0x20(%ebp),%ebx
f0103f89:	eb 0c                	jmp    f0103f97 <vprintfmt+0x23f>
f0103f8b:	89 75 08             	mov    %esi,0x8(%ebp)
f0103f8e:	8b 75 d0             	mov    -0x30(%ebp),%esi
f0103f91:	89 5d 0c             	mov    %ebx,0xc(%ebp)
f0103f94:	8b 5d e0             	mov    -0x20(%ebp),%ebx
f0103f97:	83 c7 01             	add    $0x1,%edi
f0103f9a:	0f b6 47 ff          	movzbl -0x1(%edi),%eax
f0103f9e:	0f be d0             	movsbl %al,%edx
f0103fa1:	85 d2                	test   %edx,%edx
f0103fa3:	74 23                	je     f0103fc8 <vprintfmt+0x270>
f0103fa5:	85 f6                	test   %esi,%esi
f0103fa7:	78 a1                	js     f0103f4a <vprintfmt+0x1f2>
f0103fa9:	83 ee 01             	sub    $0x1,%esi
f0103fac:	79 9c                	jns    f0103f4a <vprintfmt+0x1f2>
f0103fae:	89 df                	mov    %ebx,%edi
f0103fb0:	8b 75 08             	mov    0x8(%ebp),%esi
f0103fb3:	8b 5d 0c             	mov    0xc(%ebp),%ebx
f0103fb6:	eb 18                	jmp    f0103fd0 <vprintfmt+0x278>
				if (altflag && (ch < ' ' || ch > '~'))
					putch('?', putdat);
				else
					putch(ch, putdat);
			for (; width > 0; width--)
				putch(' ', putdat);
f0103fb8:	83 ec 08             	sub    $0x8,%esp
f0103fbb:	53                   	push   %ebx
f0103fbc:	6a 20                	push   $0x20
f0103fbe:	ff d6                	call   *%esi
			for (; (ch = *p++) != '\0' && (precision < 0 || --precision >= 0); width--)
				if (altflag && (ch < ' ' || ch > '~'))
					putch('?', putdat);
				else
					putch(ch, putdat);
			for (; width > 0; width--)
f0103fc0:	83 ef 01             	sub    $0x1,%edi
f0103fc3:	83 c4 10             	add    $0x10,%esp
f0103fc6:	eb 08                	jmp    f0103fd0 <vprintfmt+0x278>
f0103fc8:	89 df                	mov    %ebx,%edi
f0103fca:	8b 75 08             	mov    0x8(%ebp),%esi
f0103fcd:	8b 5d 0c             	mov    0xc(%ebp),%ebx
f0103fd0:	85 ff                	test   %edi,%edi
f0103fd2:	7f e4                	jg     f0103fb8 <vprintfmt+0x260>
		width = -1;
		precision = -1;
		lflag = 0;
		altflag = 0;
	reswitch:
		switch (ch = *(unsigned char *) fmt++) {
f0103fd4:	8b 7d e4             	mov    -0x1c(%ebp),%edi
f0103fd7:	e9 a2 fd ff ff       	jmp    f0103d7e <vprintfmt+0x26>
				putch(' ', putdat);
			break;

		// (signed) decimal
		case 'd':
			num = getint(&ap, lflag);
f0103fdc:	8d 45 14             	lea    0x14(%ebp),%eax
f0103fdf:	e8 08 fd ff ff       	call   f0103cec <getint>
f0103fe4:	89 45 d8             	mov    %eax,-0x28(%ebp)
f0103fe7:	89 55 dc             	mov    %edx,-0x24(%ebp)
			if ((long long) num < 0) {
				putch('-', putdat);
				num = -(long long) num;
			}
			base = 10;
f0103fea:	b9 0a 00 00 00       	mov    $0xa,%ecx
			break;

		// (signed) decimal
		case 'd':
			num = getint(&ap, lflag);
			if ((long long) num < 0) {
f0103fef:	83 7d dc 00          	cmpl   $0x0,-0x24(%ebp)
f0103ff3:	79 74                	jns    f0104069 <vprintfmt+0x311>
				putch('-', putdat);
f0103ff5:	83 ec 08             	sub    $0x8,%esp
f0103ff8:	53                   	push   %ebx
f0103ff9:	6a 2d                	push   $0x2d
f0103ffb:	ff d6                	call   *%esi
				num = -(long long) num;
f0103ffd:	8b 45 d8             	mov    -0x28(%ebp),%eax
f0104000:	8b 55 dc             	mov    -0x24(%ebp),%edx
f0104003:	f7 d8                	neg    %eax
f0104005:	83 d2 00             	adc    $0x0,%edx
f0104008:	f7 da                	neg    %edx
f010400a:	83 c4 10             	add    $0x10,%esp
			}
			base = 10;
f010400d:	b9 0a 00 00 00       	mov    $0xa,%ecx
f0104012:	eb 55                	jmp    f0104069 <vprintfmt+0x311>
			goto number;

		// unsigned decimal
		case 'u':
			num = getuint(&ap, lflag);
f0104014:	8d 45 14             	lea    0x14(%ebp),%eax
f0104017:	e8 96 fc ff ff       	call   f0103cb2 <getuint>
			base = 10;
f010401c:	b9 0a 00 00 00       	mov    $0xa,%ecx
			goto number;
f0104021:	eb 46                	jmp    f0104069 <vprintfmt+0x311>

		// (unsigned) octal
		case 'o':
			num = getuint(&ap, lflag);
f0104023:	8d 45 14             	lea    0x14(%ebp),%eax
f0104026:	e8 87 fc ff ff       	call   f0103cb2 <getuint>
			base = 8;
f010402b:	b9 08 00 00 00       	mov    $0x8,%ecx
			goto number;
f0104030:	eb 37                	jmp    f0104069 <vprintfmt+0x311>

		// pointer
		case 'p':
			putch('0', putdat);
f0104032:	83 ec 08             	sub    $0x8,%esp
f0104035:	53                   	push   %ebx
f0104036:	6a 30                	push   $0x30
f0104038:	ff d6                	call   *%esi
			putch('x', putdat);
f010403a:	83 c4 08             	add    $0x8,%esp
f010403d:	53                   	push   %ebx
f010403e:	6a 78                	push   $0x78
f0104040:	ff d6                	call   *%esi
			num = (unsigned long long)
				(uintptr_t) va_arg(ap, void *);
f0104042:	8b 45 14             	mov    0x14(%ebp),%eax
f0104045:	8d 50 04             	lea    0x4(%eax),%edx
f0104048:	89 55 14             	mov    %edx,0x14(%ebp)

		// pointer
		case 'p':
			putch('0', putdat);
			putch('x', putdat);
			num = (unsigned long long)
f010404b:	8b 00                	mov    (%eax),%eax
f010404d:	ba 00 00 00 00       	mov    $0x0,%edx
				(uintptr_t) va_arg(ap, void *);
			base = 16;
			goto number;
f0104052:	83 c4 10             	add    $0x10,%esp
		case 'p':
			putch('0', putdat);
			putch('x', putdat);
			num = (unsigned long long)
				(uintptr_t) va_arg(ap, void *);
			base = 16;
f0104055:	b9 10 00 00 00       	mov    $0x10,%ecx
			goto number;
f010405a:	eb 0d                	jmp    f0104069 <vprintfmt+0x311>

		// (unsigned) hexadecimal
		case 'x':
			num = getuint(&ap, lflag);
f010405c:	8d 45 14             	lea    0x14(%ebp),%eax
f010405f:	e8 4e fc ff ff       	call   f0103cb2 <getuint>
			base = 16;
f0104064:	b9 10 00 00 00       	mov    $0x10,%ecx
		number:
			printnum(putch, putdat, num, base, width, padc);
f0104069:	83 ec 0c             	sub    $0xc,%esp
f010406c:	0f be 7d d4          	movsbl -0x2c(%ebp),%edi
f0104070:	57                   	push   %edi
f0104071:	ff 75 e0             	pushl  -0x20(%ebp)
f0104074:	51                   	push   %ecx
f0104075:	52                   	push   %edx
f0104076:	50                   	push   %eax
f0104077:	89 da                	mov    %ebx,%edx
f0104079:	89 f0                	mov    %esi,%eax
f010407b:	e8 83 fb ff ff       	call   f0103c03 <printnum>
			break;
f0104080:	83 c4 20             	add    $0x20,%esp
f0104083:	8b 7d e4             	mov    -0x1c(%ebp),%edi
f0104086:	e9 f3 fc ff ff       	jmp    f0103d7e <vprintfmt+0x26>

		// escaped '%' character
		case '%':
			putch(ch, putdat);
f010408b:	83 ec 08             	sub    $0x8,%esp
f010408e:	53                   	push   %ebx
f010408f:	51                   	push   %ecx
f0104090:	ff d6                	call   *%esi
			break;
f0104092:	83 c4 10             	add    $0x10,%esp
		width = -1;
		precision = -1;
		lflag = 0;
		altflag = 0;
	reswitch:
		switch (ch = *(unsigned char *) fmt++) {
f0104095:	8b 7d e4             	mov    -0x1c(%ebp),%edi
			break;

		// escaped '%' character
		case '%':
			putch(ch, putdat);
			break;
f0104098:	e9 e1 fc ff ff       	jmp    f0103d7e <vprintfmt+0x26>

		// unrecognized escape sequence - just print it literally
		default:
			putch('%', putdat);
f010409d:	83 ec 08             	sub    $0x8,%esp
f01040a0:	53                   	push   %ebx
f01040a1:	6a 25                	push   $0x25
f01040a3:	ff d6                	call   *%esi
			for (fmt--; fmt[-1] != '%'; fmt--)
f01040a5:	83 c4 10             	add    $0x10,%esp
f01040a8:	eb 03                	jmp    f01040ad <vprintfmt+0x355>
f01040aa:	83 ef 01             	sub    $0x1,%edi
f01040ad:	80 7f ff 25          	cmpb   $0x25,-0x1(%edi)
f01040b1:	75 f7                	jne    f01040aa <vprintfmt+0x352>
f01040b3:	e9 c6 fc ff ff       	jmp    f0103d7e <vprintfmt+0x26>
				/* do nothing */;
			break;
		}
	}
}
f01040b8:	8d 65 f4             	lea    -0xc(%ebp),%esp
f01040bb:	5b                   	pop    %ebx
f01040bc:	5e                   	pop    %esi
f01040bd:	5f                   	pop    %edi
f01040be:	5d                   	pop    %ebp
f01040bf:	c3                   	ret    

f01040c0 <vsnprintf>:
		*b->buf++ = ch;
}

int
vsnprintf(char *buf, int n, const char *fmt, va_list ap)
{
f01040c0:	55                   	push   %ebp
f01040c1:	89 e5                	mov    %esp,%ebp
f01040c3:	83 ec 18             	sub    $0x18,%esp
f01040c6:	8b 45 08             	mov    0x8(%ebp),%eax
f01040c9:	8b 55 0c             	mov    0xc(%ebp),%edx
	struct sprintbuf b = {buf, buf+n-1, 0};
f01040cc:	89 45 ec             	mov    %eax,-0x14(%ebp)
f01040cf:	8d 4c 10 ff          	lea    -0x1(%eax,%edx,1),%ecx
f01040d3:	89 4d f0             	mov    %ecx,-0x10(%ebp)
f01040d6:	c7 45 f4 00 00 00 00 	movl   $0x0,-0xc(%ebp)

	if (buf == NULL || n < 1)
f01040dd:	85 c0                	test   %eax,%eax
f01040df:	74 26                	je     f0104107 <vsnprintf+0x47>
f01040e1:	85 d2                	test   %edx,%edx
f01040e3:	7e 22                	jle    f0104107 <vsnprintf+0x47>
		return -E_INVAL;

	// print the string to the buffer
	vprintfmt((void*)sprintputch, &b, fmt, ap);
f01040e5:	ff 75 14             	pushl  0x14(%ebp)
f01040e8:	ff 75 10             	pushl  0x10(%ebp)
f01040eb:	8d 45 ec             	lea    -0x14(%ebp),%eax
f01040ee:	50                   	push   %eax
f01040ef:	68 1e 3d 10 f0       	push   $0xf0103d1e
f01040f4:	e8 5f fc ff ff       	call   f0103d58 <vprintfmt>

	// null terminate the buffer
	*b.buf = '\0';
f01040f9:	8b 45 ec             	mov    -0x14(%ebp),%eax
f01040fc:	c6 00 00             	movb   $0x0,(%eax)

	return b.cnt;
f01040ff:	8b 45 f4             	mov    -0xc(%ebp),%eax
f0104102:	83 c4 10             	add    $0x10,%esp
f0104105:	eb 05                	jmp    f010410c <vsnprintf+0x4c>
vsnprintf(char *buf, int n, const char *fmt, va_list ap)
{
	struct sprintbuf b = {buf, buf+n-1, 0};

	if (buf == NULL || n < 1)
		return -E_INVAL;
f0104107:	b8 fd ff ff ff       	mov    $0xfffffffd,%eax

	// null terminate the buffer
	*b.buf = '\0';

	return b.cnt;
}
f010410c:	c9                   	leave  
f010410d:	c3                   	ret    

f010410e <snprintf>:

int
snprintf(char *buf, int n, const char *fmt, ...)
{
f010410e:	55                   	push   %ebp
f010410f:	89 e5                	mov    %esp,%ebp
f0104111:	83 ec 08             	sub    $0x8,%esp
	va_list ap;
	int rc;

	va_start(ap, fmt);
f0104114:	8d 45 14             	lea    0x14(%ebp),%eax
	rc = vsnprintf(buf, n, fmt, ap);
f0104117:	50                   	push   %eax
f0104118:	ff 75 10             	pushl  0x10(%ebp)
f010411b:	ff 75 0c             	pushl  0xc(%ebp)
f010411e:	ff 75 08             	pushl  0x8(%ebp)
f0104121:	e8 9a ff ff ff       	call   f01040c0 <vsnprintf>
	va_end(ap);

	return rc;
}
f0104126:	c9                   	leave  
f0104127:	c3                   	ret    

f0104128 <readline>:
#define BUFLEN 1024
static char buf[BUFLEN];

char *
readline(const char *prompt)
{
f0104128:	55                   	push   %ebp
f0104129:	89 e5                	mov    %esp,%ebp
f010412b:	57                   	push   %edi
f010412c:	56                   	push   %esi
f010412d:	53                   	push   %ebx
f010412e:	83 ec 0c             	sub    $0xc,%esp
f0104131:	8b 45 08             	mov    0x8(%ebp),%eax
	int i, c, echoing;

	if (prompt != NULL)
f0104134:	85 c0                	test   %eax,%eax
f0104136:	74 11                	je     f0104149 <readline+0x21>
		cprintf("%s", prompt);
f0104138:	83 ec 08             	sub    $0x8,%esp
f010413b:	50                   	push   %eax
f010413c:	68 8c 55 10 f0       	push   $0xf010558c
f0104141:	e8 32 ee ff ff       	call   f0102f78 <cprintf>
f0104146:	83 c4 10             	add    $0x10,%esp

	i = 0;
	echoing = iscons(0);
f0104149:	83 ec 0c             	sub    $0xc,%esp
f010414c:	6a 00                	push   $0x0
f010414e:	e8 f1 c5 ff ff       	call   f0100744 <iscons>
f0104153:	89 c7                	mov    %eax,%edi
f0104155:	83 c4 10             	add    $0x10,%esp
	int i, c, echoing;

	if (prompt != NULL)
		cprintf("%s", prompt);

	i = 0;
f0104158:	be 00 00 00 00       	mov    $0x0,%esi
	echoing = iscons(0);
	while (1) {
		c = getchar();
f010415d:	e8 d1 c5 ff ff       	call   f0100733 <getchar>
f0104162:	89 c3                	mov    %eax,%ebx
		if (c < 0) {
f0104164:	85 c0                	test   %eax,%eax
f0104166:	79 18                	jns    f0104180 <readline+0x58>
			cprintf("read error: %e\n", c);
f0104168:	83 ec 08             	sub    $0x8,%esp
f010416b:	50                   	push   %eax
f010416c:	68 10 60 10 f0       	push   $0xf0106010
f0104171:	e8 02 ee ff ff       	call   f0102f78 <cprintf>
			return NULL;
f0104176:	83 c4 10             	add    $0x10,%esp
f0104179:	b8 00 00 00 00       	mov    $0x0,%eax
f010417e:	eb 79                	jmp    f01041f9 <readline+0xd1>
		} else if ((c == '\b' || c == '\x7f') && i > 0) {
f0104180:	83 f8 08             	cmp    $0x8,%eax
f0104183:	0f 94 c2             	sete   %dl
f0104186:	83 f8 7f             	cmp    $0x7f,%eax
f0104189:	0f 94 c0             	sete   %al
f010418c:	08 c2                	or     %al,%dl
f010418e:	74 1a                	je     f01041aa <readline+0x82>
f0104190:	85 f6                	test   %esi,%esi
f0104192:	7e 16                	jle    f01041aa <readline+0x82>
			if (echoing)
f0104194:	85 ff                	test   %edi,%edi
f0104196:	74 0d                	je     f01041a5 <readline+0x7d>
				cputchar('\b');
f0104198:	83 ec 0c             	sub    $0xc,%esp
f010419b:	6a 08                	push   $0x8
f010419d:	e8 81 c5 ff ff       	call   f0100723 <cputchar>
f01041a2:	83 c4 10             	add    $0x10,%esp
			i--;
f01041a5:	83 ee 01             	sub    $0x1,%esi
f01041a8:	eb b3                	jmp    f010415d <readline+0x35>
		} else if (c >= ' ' && i < BUFLEN-1) {
f01041aa:	83 fb 1f             	cmp    $0x1f,%ebx
f01041ad:	7e 23                	jle    f01041d2 <readline+0xaa>
f01041af:	81 fe fe 03 00 00    	cmp    $0x3fe,%esi
f01041b5:	7f 1b                	jg     f01041d2 <readline+0xaa>
			if (echoing)
f01041b7:	85 ff                	test   %edi,%edi
f01041b9:	74 0c                	je     f01041c7 <readline+0x9f>
				cputchar(c);
f01041bb:	83 ec 0c             	sub    $0xc,%esp
f01041be:	53                   	push   %ebx
f01041bf:	e8 5f c5 ff ff       	call   f0100723 <cputchar>
f01041c4:	83 c4 10             	add    $0x10,%esp
			buf[i++] = c;
f01041c7:	88 9e 80 45 19 f0    	mov    %bl,-0xfe6ba80(%esi)
f01041cd:	8d 76 01             	lea    0x1(%esi),%esi
f01041d0:	eb 8b                	jmp    f010415d <readline+0x35>
		} else if (c == '\n' || c == '\r') {
f01041d2:	83 fb 0a             	cmp    $0xa,%ebx
f01041d5:	74 05                	je     f01041dc <readline+0xb4>
f01041d7:	83 fb 0d             	cmp    $0xd,%ebx
f01041da:	75 81                	jne    f010415d <readline+0x35>
			if (echoing)
f01041dc:	85 ff                	test   %edi,%edi
f01041de:	74 0d                	je     f01041ed <readline+0xc5>
				cputchar('\n');
f01041e0:	83 ec 0c             	sub    $0xc,%esp
f01041e3:	6a 0a                	push   $0xa
f01041e5:	e8 39 c5 ff ff       	call   f0100723 <cputchar>
f01041ea:	83 c4 10             	add    $0x10,%esp
			buf[i] = 0;
f01041ed:	c6 86 80 45 19 f0 00 	movb   $0x0,-0xfe6ba80(%esi)
			return buf;
f01041f4:	b8 80 45 19 f0       	mov    $0xf0194580,%eax
		}
	}
}
f01041f9:	8d 65 f4             	lea    -0xc(%ebp),%esp
f01041fc:	5b                   	pop    %ebx
f01041fd:	5e                   	pop    %esi
f01041fe:	5f                   	pop    %edi
f01041ff:	5d                   	pop    %ebp
f0104200:	c3                   	ret    

f0104201 <strlen>:
// Primespipe runs 3x faster this way.
#define ASM 1

int
strlen(const char *s)
{
f0104201:	55                   	push   %ebp
f0104202:	89 e5                	mov    %esp,%ebp
f0104204:	8b 55 08             	mov    0x8(%ebp),%edx
	int n;

	for (n = 0; *s != '\0'; s++)
f0104207:	b8 00 00 00 00       	mov    $0x0,%eax
f010420c:	eb 03                	jmp    f0104211 <strlen+0x10>
		n++;
f010420e:	83 c0 01             	add    $0x1,%eax
int
strlen(const char *s)
{
	int n;

	for (n = 0; *s != '\0'; s++)
f0104211:	80 3c 02 00          	cmpb   $0x0,(%edx,%eax,1)
f0104215:	75 f7                	jne    f010420e <strlen+0xd>
		n++;
	return n;
}
f0104217:	5d                   	pop    %ebp
f0104218:	c3                   	ret    

f0104219 <strnlen>:

int
strnlen(const char *s, size_t size)
{
f0104219:	55                   	push   %ebp
f010421a:	89 e5                	mov    %esp,%ebp
f010421c:	8b 4d 08             	mov    0x8(%ebp),%ecx
f010421f:	8b 45 0c             	mov    0xc(%ebp),%eax
	int n;

	for (n = 0; size > 0 && *s != '\0'; s++, size--)
f0104222:	ba 00 00 00 00       	mov    $0x0,%edx
f0104227:	eb 03                	jmp    f010422c <strnlen+0x13>
		n++;
f0104229:	83 c2 01             	add    $0x1,%edx
int
strnlen(const char *s, size_t size)
{
	int n;

	for (n = 0; size > 0 && *s != '\0'; s++, size--)
f010422c:	39 c2                	cmp    %eax,%edx
f010422e:	74 08                	je     f0104238 <strnlen+0x1f>
f0104230:	80 3c 11 00          	cmpb   $0x0,(%ecx,%edx,1)
f0104234:	75 f3                	jne    f0104229 <strnlen+0x10>
f0104236:	89 d0                	mov    %edx,%eax
		n++;
	return n;
}
f0104238:	5d                   	pop    %ebp
f0104239:	c3                   	ret    

f010423a <strcpy>:

char *
strcpy(char *dst, const char *src)
{
f010423a:	55                   	push   %ebp
f010423b:	89 e5                	mov    %esp,%ebp
f010423d:	53                   	push   %ebx
f010423e:	8b 45 08             	mov    0x8(%ebp),%eax
f0104241:	8b 4d 0c             	mov    0xc(%ebp),%ecx
	char *ret;

	ret = dst;
	while ((*dst++ = *src++) != '\0')
f0104244:	89 c2                	mov    %eax,%edx
f0104246:	83 c2 01             	add    $0x1,%edx
f0104249:	83 c1 01             	add    $0x1,%ecx
f010424c:	0f b6 59 ff          	movzbl -0x1(%ecx),%ebx
f0104250:	88 5a ff             	mov    %bl,-0x1(%edx)
f0104253:	84 db                	test   %bl,%bl
f0104255:	75 ef                	jne    f0104246 <strcpy+0xc>
		/* do nothing */;
	return ret;
}
f0104257:	5b                   	pop    %ebx
f0104258:	5d                   	pop    %ebp
f0104259:	c3                   	ret    

f010425a <strcat>:

char *
strcat(char *dst, const char *src)
{
f010425a:	55                   	push   %ebp
f010425b:	89 e5                	mov    %esp,%ebp
f010425d:	53                   	push   %ebx
f010425e:	8b 5d 08             	mov    0x8(%ebp),%ebx
	int len = strlen(dst);
f0104261:	53                   	push   %ebx
f0104262:	e8 9a ff ff ff       	call   f0104201 <strlen>
f0104267:	83 c4 04             	add    $0x4,%esp
	strcpy(dst + len, src);
f010426a:	ff 75 0c             	pushl  0xc(%ebp)
f010426d:	01 d8                	add    %ebx,%eax
f010426f:	50                   	push   %eax
f0104270:	e8 c5 ff ff ff       	call   f010423a <strcpy>
	return dst;
}
f0104275:	89 d8                	mov    %ebx,%eax
f0104277:	8b 5d fc             	mov    -0x4(%ebp),%ebx
f010427a:	c9                   	leave  
f010427b:	c3                   	ret    

f010427c <strncpy>:

char *
strncpy(char *dst, const char *src, size_t size) {
f010427c:	55                   	push   %ebp
f010427d:	89 e5                	mov    %esp,%ebp
f010427f:	56                   	push   %esi
f0104280:	53                   	push   %ebx
f0104281:	8b 75 08             	mov    0x8(%ebp),%esi
f0104284:	8b 4d 0c             	mov    0xc(%ebp),%ecx
f0104287:	89 f3                	mov    %esi,%ebx
f0104289:	03 5d 10             	add    0x10(%ebp),%ebx
	size_t i;
	char *ret;

	ret = dst;
	for (i = 0; i < size; i++) {
f010428c:	89 f2                	mov    %esi,%edx
f010428e:	eb 0f                	jmp    f010429f <strncpy+0x23>
		*dst++ = *src;
f0104290:	83 c2 01             	add    $0x1,%edx
f0104293:	0f b6 01             	movzbl (%ecx),%eax
f0104296:	88 42 ff             	mov    %al,-0x1(%edx)
		// If strlen(src) < size, null-pad 'dst' out to 'size' chars
		if (*src != '\0')
			src++;
f0104299:	80 39 01             	cmpb   $0x1,(%ecx)
f010429c:	83 d9 ff             	sbb    $0xffffffff,%ecx
strncpy(char *dst, const char *src, size_t size) {
	size_t i;
	char *ret;

	ret = dst;
	for (i = 0; i < size; i++) {
f010429f:	39 da                	cmp    %ebx,%edx
f01042a1:	75 ed                	jne    f0104290 <strncpy+0x14>
		// If strlen(src) < size, null-pad 'dst' out to 'size' chars
		if (*src != '\0')
			src++;
	}
	return ret;
}
f01042a3:	89 f0                	mov    %esi,%eax
f01042a5:	5b                   	pop    %ebx
f01042a6:	5e                   	pop    %esi
f01042a7:	5d                   	pop    %ebp
f01042a8:	c3                   	ret    

f01042a9 <strlcpy>:

size_t
strlcpy(char *dst, const char *src, size_t size)
{
f01042a9:	55                   	push   %ebp
f01042aa:	89 e5                	mov    %esp,%ebp
f01042ac:	56                   	push   %esi
f01042ad:	53                   	push   %ebx
f01042ae:	8b 75 08             	mov    0x8(%ebp),%esi
f01042b1:	8b 4d 0c             	mov    0xc(%ebp),%ecx
f01042b4:	8b 55 10             	mov    0x10(%ebp),%edx
f01042b7:	89 f0                	mov    %esi,%eax
	char *dst_in;

	dst_in = dst;
	if (size > 0) {
f01042b9:	85 d2                	test   %edx,%edx
f01042bb:	74 21                	je     f01042de <strlcpy+0x35>
f01042bd:	8d 44 16 ff          	lea    -0x1(%esi,%edx,1),%eax
f01042c1:	89 f2                	mov    %esi,%edx
f01042c3:	eb 09                	jmp    f01042ce <strlcpy+0x25>
		while (--size > 0 && *src != '\0')
			*dst++ = *src++;
f01042c5:	83 c2 01             	add    $0x1,%edx
f01042c8:	83 c1 01             	add    $0x1,%ecx
f01042cb:	88 5a ff             	mov    %bl,-0x1(%edx)
{
	char *dst_in;

	dst_in = dst;
	if (size > 0) {
		while (--size > 0 && *src != '\0')
f01042ce:	39 c2                	cmp    %eax,%edx
f01042d0:	74 09                	je     f01042db <strlcpy+0x32>
f01042d2:	0f b6 19             	movzbl (%ecx),%ebx
f01042d5:	84 db                	test   %bl,%bl
f01042d7:	75 ec                	jne    f01042c5 <strlcpy+0x1c>
f01042d9:	89 d0                	mov    %edx,%eax
			*dst++ = *src++;
		*dst = '\0';
f01042db:	c6 00 00             	movb   $0x0,(%eax)
	}
	return dst - dst_in;
f01042de:	29 f0                	sub    %esi,%eax
}
f01042e0:	5b                   	pop    %ebx
f01042e1:	5e                   	pop    %esi
f01042e2:	5d                   	pop    %ebp
f01042e3:	c3                   	ret    

f01042e4 <strcmp>:

int
strcmp(const char *p, const char *q)
{
f01042e4:	55                   	push   %ebp
f01042e5:	89 e5                	mov    %esp,%ebp
f01042e7:	8b 4d 08             	mov    0x8(%ebp),%ecx
f01042ea:	8b 55 0c             	mov    0xc(%ebp),%edx
	while (*p && *p == *q)
f01042ed:	eb 06                	jmp    f01042f5 <strcmp+0x11>
		p++, q++;
f01042ef:	83 c1 01             	add    $0x1,%ecx
f01042f2:	83 c2 01             	add    $0x1,%edx
}

int
strcmp(const char *p, const char *q)
{
	while (*p && *p == *q)
f01042f5:	0f b6 01             	movzbl (%ecx),%eax
f01042f8:	84 c0                	test   %al,%al
f01042fa:	74 04                	je     f0104300 <strcmp+0x1c>
f01042fc:	3a 02                	cmp    (%edx),%al
f01042fe:	74 ef                	je     f01042ef <strcmp+0xb>
		p++, q++;
	return (int) ((unsigned char) *p - (unsigned char) *q);
f0104300:	0f b6 c0             	movzbl %al,%eax
f0104303:	0f b6 12             	movzbl (%edx),%edx
f0104306:	29 d0                	sub    %edx,%eax
}
f0104308:	5d                   	pop    %ebp
f0104309:	c3                   	ret    

f010430a <strncmp>:

int
strncmp(const char *p, const char *q, size_t n)
{
f010430a:	55                   	push   %ebp
f010430b:	89 e5                	mov    %esp,%ebp
f010430d:	53                   	push   %ebx
f010430e:	8b 45 08             	mov    0x8(%ebp),%eax
f0104311:	8b 55 0c             	mov    0xc(%ebp),%edx
f0104314:	89 c3                	mov    %eax,%ebx
f0104316:	03 5d 10             	add    0x10(%ebp),%ebx
	while (n > 0 && *p && *p == *q)
f0104319:	eb 06                	jmp    f0104321 <strncmp+0x17>
		n--, p++, q++;
f010431b:	83 c0 01             	add    $0x1,%eax
f010431e:	83 c2 01             	add    $0x1,%edx
}

int
strncmp(const char *p, const char *q, size_t n)
{
	while (n > 0 && *p && *p == *q)
f0104321:	39 d8                	cmp    %ebx,%eax
f0104323:	74 15                	je     f010433a <strncmp+0x30>
f0104325:	0f b6 08             	movzbl (%eax),%ecx
f0104328:	84 c9                	test   %cl,%cl
f010432a:	74 04                	je     f0104330 <strncmp+0x26>
f010432c:	3a 0a                	cmp    (%edx),%cl
f010432e:	74 eb                	je     f010431b <strncmp+0x11>
		n--, p++, q++;
	if (n == 0)
		return 0;
	else
		return (int) ((unsigned char) *p - (unsigned char) *q);
f0104330:	0f b6 00             	movzbl (%eax),%eax
f0104333:	0f b6 12             	movzbl (%edx),%edx
f0104336:	29 d0                	sub    %edx,%eax
f0104338:	eb 05                	jmp    f010433f <strncmp+0x35>
strncmp(const char *p, const char *q, size_t n)
{
	while (n > 0 && *p && *p == *q)
		n--, p++, q++;
	if (n == 0)
		return 0;
f010433a:	b8 00 00 00 00       	mov    $0x0,%eax
	else
		return (int) ((unsigned char) *p - (unsigned char) *q);
}
f010433f:	5b                   	pop    %ebx
f0104340:	5d                   	pop    %ebp
f0104341:	c3                   	ret    

f0104342 <strchr>:

// Return a pointer to the first occurrence of 'c' in 's',
// or a null pointer if the string has no 'c'.
char *
strchr(const char *s, char c)
{
f0104342:	55                   	push   %ebp
f0104343:	89 e5                	mov    %esp,%ebp
f0104345:	8b 45 08             	mov    0x8(%ebp),%eax
f0104348:	0f b6 4d 0c          	movzbl 0xc(%ebp),%ecx
	for (; *s; s++)
f010434c:	eb 07                	jmp    f0104355 <strchr+0x13>
		if (*s == c)
f010434e:	38 ca                	cmp    %cl,%dl
f0104350:	74 0f                	je     f0104361 <strchr+0x1f>
// Return a pointer to the first occurrence of 'c' in 's',
// or a null pointer if the string has no 'c'.
char *
strchr(const char *s, char c)
{
	for (; *s; s++)
f0104352:	83 c0 01             	add    $0x1,%eax
f0104355:	0f b6 10             	movzbl (%eax),%edx
f0104358:	84 d2                	test   %dl,%dl
f010435a:	75 f2                	jne    f010434e <strchr+0xc>
		if (*s == c)
			return (char *) s;
	return 0;
f010435c:	b8 00 00 00 00       	mov    $0x0,%eax
}
f0104361:	5d                   	pop    %ebp
f0104362:	c3                   	ret    

f0104363 <strfind>:

// Return a pointer to the first occurrence of 'c' in 's',
// or a pointer to the string-ending null character if the string has no 'c'.
char *
strfind(const char *s, char c)
{
f0104363:	55                   	push   %ebp
f0104364:	89 e5                	mov    %esp,%ebp
f0104366:	8b 45 08             	mov    0x8(%ebp),%eax
f0104369:	0f b6 4d 0c          	movzbl 0xc(%ebp),%ecx
	for (; *s; s++)
f010436d:	eb 03                	jmp    f0104372 <strfind+0xf>
f010436f:	83 c0 01             	add    $0x1,%eax
f0104372:	0f b6 10             	movzbl (%eax),%edx
		if (*s == c)
f0104375:	38 ca                	cmp    %cl,%dl
f0104377:	74 04                	je     f010437d <strfind+0x1a>
f0104379:	84 d2                	test   %dl,%dl
f010437b:	75 f2                	jne    f010436f <strfind+0xc>
			break;
	return (char *) s;
}
f010437d:	5d                   	pop    %ebp
f010437e:	c3                   	ret    

f010437f <memset>:

#if ASM
void *
memset(void *v, int c, size_t n)
{
f010437f:	55                   	push   %ebp
f0104380:	89 e5                	mov    %esp,%ebp
f0104382:	57                   	push   %edi
f0104383:	56                   	push   %esi
f0104384:	53                   	push   %ebx
f0104385:	8b 55 08             	mov    0x8(%ebp),%edx
f0104388:	8b 4d 10             	mov    0x10(%ebp),%ecx
	char *p = v;

	if (n == 0)
f010438b:	85 c9                	test   %ecx,%ecx
f010438d:	74 37                	je     f01043c6 <memset+0x47>
		return v;
	if ((int)v%4 == 0 && n%4 == 0) {
f010438f:	f6 c2 03             	test   $0x3,%dl
f0104392:	75 2a                	jne    f01043be <memset+0x3f>
f0104394:	f6 c1 03             	test   $0x3,%cl
f0104397:	75 25                	jne    f01043be <memset+0x3f>
		c &= 0xFF;
f0104399:	0f b6 5d 0c          	movzbl 0xc(%ebp),%ebx
		c = (c<<24)|(c<<16)|(c<<8)|c;
f010439d:	89 df                	mov    %ebx,%edi
f010439f:	c1 e7 08             	shl    $0x8,%edi
f01043a2:	89 de                	mov    %ebx,%esi
f01043a4:	c1 e6 18             	shl    $0x18,%esi
f01043a7:	89 d8                	mov    %ebx,%eax
f01043a9:	c1 e0 10             	shl    $0x10,%eax
f01043ac:	09 f0                	or     %esi,%eax
f01043ae:	09 c3                	or     %eax,%ebx
		asm volatile("cld; rep stosl\n"
			: "=D" (p), "=c" (n)
			: "D" (p), "a" (c), "c" (n/4)
f01043b0:	c1 e9 02             	shr    $0x2,%ecx
	if (n == 0)
		return v;
	if ((int)v%4 == 0 && n%4 == 0) {
		c &= 0xFF;
		c = (c<<24)|(c<<16)|(c<<8)|c;
		asm volatile("cld; rep stosl\n"
f01043b3:	89 f8                	mov    %edi,%eax
f01043b5:	09 d8                	or     %ebx,%eax
f01043b7:	89 d7                	mov    %edx,%edi
f01043b9:	fc                   	cld    
f01043ba:	f3 ab                	rep stos %eax,%es:(%edi)
f01043bc:	eb 08                	jmp    f01043c6 <memset+0x47>
			: "=D" (p), "=c" (n)
			: "D" (p), "a" (c), "c" (n/4)
			: "cc", "memory");
	} else
		asm volatile("cld; rep stosb\n"
f01043be:	89 d7                	mov    %edx,%edi
f01043c0:	8b 45 0c             	mov    0xc(%ebp),%eax
f01043c3:	fc                   	cld    
f01043c4:	f3 aa                	rep stos %al,%es:(%edi)
			: "=D" (p), "=c" (n)
			: "0" (p), "a" (c), "1" (n)
			: "cc", "memory");
	return v;
}
f01043c6:	89 d0                	mov    %edx,%eax
f01043c8:	5b                   	pop    %ebx
f01043c9:	5e                   	pop    %esi
f01043ca:	5f                   	pop    %edi
f01043cb:	5d                   	pop    %ebp
f01043cc:	c3                   	ret    

f01043cd <memmove>:

void *
memmove(void *dst, const void *src, size_t n)
{
f01043cd:	55                   	push   %ebp
f01043ce:	89 e5                	mov    %esp,%ebp
f01043d0:	57                   	push   %edi
f01043d1:	56                   	push   %esi
f01043d2:	8b 45 08             	mov    0x8(%ebp),%eax
f01043d5:	8b 75 0c             	mov    0xc(%ebp),%esi
f01043d8:	8b 4d 10             	mov    0x10(%ebp),%ecx
	const char *s;
	char *d;

	s = src;
	d = dst;
	if (s < d && s + n > d) {
f01043db:	39 c6                	cmp    %eax,%esi
f01043dd:	73 35                	jae    f0104414 <memmove+0x47>
f01043df:	8d 14 0e             	lea    (%esi,%ecx,1),%edx
f01043e2:	39 d0                	cmp    %edx,%eax
f01043e4:	73 2e                	jae    f0104414 <memmove+0x47>
		s += n;
		d += n;
f01043e6:	8d 3c 08             	lea    (%eax,%ecx,1),%edi
		if ((int)s%4 == 0 && (int)d%4 == 0 && n%4 == 0)
f01043e9:	89 d6                	mov    %edx,%esi
f01043eb:	09 fe                	or     %edi,%esi
f01043ed:	f7 c6 03 00 00 00    	test   $0x3,%esi
f01043f3:	75 13                	jne    f0104408 <memmove+0x3b>
f01043f5:	f6 c1 03             	test   $0x3,%cl
f01043f8:	75 0e                	jne    f0104408 <memmove+0x3b>
			asm volatile("std; rep movsl\n"
f01043fa:	83 ef 04             	sub    $0x4,%edi
f01043fd:	8d 72 fc             	lea    -0x4(%edx),%esi
f0104400:	c1 e9 02             	shr    $0x2,%ecx
f0104403:	fd                   	std    
f0104404:	f3 a5                	rep movsl %ds:(%esi),%es:(%edi)
f0104406:	eb 09                	jmp    f0104411 <memmove+0x44>
				:: "D" (d-4), "S" (s-4), "c" (n/4) : "cc", "memory");
		else
			asm volatile("std; rep movsb\n"
f0104408:	83 ef 01             	sub    $0x1,%edi
f010440b:	8d 72 ff             	lea    -0x1(%edx),%esi
f010440e:	fd                   	std    
f010440f:	f3 a4                	rep movsb %ds:(%esi),%es:(%edi)
				:: "D" (d-1), "S" (s-1), "c" (n) : "cc", "memory");
		// Some versions of GCC rely on DF being clear
		asm volatile("cld" ::: "cc");
f0104411:	fc                   	cld    
f0104412:	eb 1d                	jmp    f0104431 <memmove+0x64>
	} else {
		if ((int)s%4 == 0 && (int)d%4 == 0 && n%4 == 0)
f0104414:	89 f2                	mov    %esi,%edx
f0104416:	09 c2                	or     %eax,%edx
f0104418:	f6 c2 03             	test   $0x3,%dl
f010441b:	75 0f                	jne    f010442c <memmove+0x5f>
f010441d:	f6 c1 03             	test   $0x3,%cl
f0104420:	75 0a                	jne    f010442c <memmove+0x5f>
			asm volatile("cld; rep movsl\n"
f0104422:	c1 e9 02             	shr    $0x2,%ecx
f0104425:	89 c7                	mov    %eax,%edi
f0104427:	fc                   	cld    
f0104428:	f3 a5                	rep movsl %ds:(%esi),%es:(%edi)
f010442a:	eb 05                	jmp    f0104431 <memmove+0x64>
				:: "D" (d), "S" (s), "c" (n/4) : "cc", "memory");
		else
			asm volatile("cld; rep movsb\n"
f010442c:	89 c7                	mov    %eax,%edi
f010442e:	fc                   	cld    
f010442f:	f3 a4                	rep movsb %ds:(%esi),%es:(%edi)
				:: "D" (d), "S" (s), "c" (n) : "cc", "memory");
	}
	return dst;
}
f0104431:	5e                   	pop    %esi
f0104432:	5f                   	pop    %edi
f0104433:	5d                   	pop    %ebp
f0104434:	c3                   	ret    

f0104435 <memcpy>:
}
#endif

void *
memcpy(void *dst, const void *src, size_t n)
{
f0104435:	55                   	push   %ebp
f0104436:	89 e5                	mov    %esp,%ebp
	return memmove(dst, src, n);
f0104438:	ff 75 10             	pushl  0x10(%ebp)
f010443b:	ff 75 0c             	pushl  0xc(%ebp)
f010443e:	ff 75 08             	pushl  0x8(%ebp)
f0104441:	e8 87 ff ff ff       	call   f01043cd <memmove>
}
f0104446:	c9                   	leave  
f0104447:	c3                   	ret    

f0104448 <memcmp>:

int
memcmp(const void *v1, const void *v2, size_t n)
{
f0104448:	55                   	push   %ebp
f0104449:	89 e5                	mov    %esp,%ebp
f010444b:	56                   	push   %esi
f010444c:	53                   	push   %ebx
f010444d:	8b 45 08             	mov    0x8(%ebp),%eax
f0104450:	8b 55 0c             	mov    0xc(%ebp),%edx
f0104453:	89 c6                	mov    %eax,%esi
f0104455:	03 75 10             	add    0x10(%ebp),%esi
	const uint8_t *s1 = (const uint8_t *) v1;
	const uint8_t *s2 = (const uint8_t *) v2;

	while (n-- > 0) {
f0104458:	eb 1a                	jmp    f0104474 <memcmp+0x2c>
		if (*s1 != *s2)
f010445a:	0f b6 08             	movzbl (%eax),%ecx
f010445d:	0f b6 1a             	movzbl (%edx),%ebx
f0104460:	38 d9                	cmp    %bl,%cl
f0104462:	74 0a                	je     f010446e <memcmp+0x26>
			return (int) *s1 - (int) *s2;
f0104464:	0f b6 c1             	movzbl %cl,%eax
f0104467:	0f b6 db             	movzbl %bl,%ebx
f010446a:	29 d8                	sub    %ebx,%eax
f010446c:	eb 0f                	jmp    f010447d <memcmp+0x35>
		s1++, s2++;
f010446e:	83 c0 01             	add    $0x1,%eax
f0104471:	83 c2 01             	add    $0x1,%edx
memcmp(const void *v1, const void *v2, size_t n)
{
	const uint8_t *s1 = (const uint8_t *) v1;
	const uint8_t *s2 = (const uint8_t *) v2;

	while (n-- > 0) {
f0104474:	39 f0                	cmp    %esi,%eax
f0104476:	75 e2                	jne    f010445a <memcmp+0x12>
		if (*s1 != *s2)
			return (int) *s1 - (int) *s2;
		s1++, s2++;
	}

	return 0;
f0104478:	b8 00 00 00 00       	mov    $0x0,%eax
}
f010447d:	5b                   	pop    %ebx
f010447e:	5e                   	pop    %esi
f010447f:	5d                   	pop    %ebp
f0104480:	c3                   	ret    

f0104481 <memfind>:

void *
memfind(const void *s, int c, size_t n)
{
f0104481:	55                   	push   %ebp
f0104482:	89 e5                	mov    %esp,%ebp
f0104484:	8b 45 08             	mov    0x8(%ebp),%eax
f0104487:	8b 4d 0c             	mov    0xc(%ebp),%ecx
	const void *ends = (const char *) s + n;
f010448a:	89 c2                	mov    %eax,%edx
f010448c:	03 55 10             	add    0x10(%ebp),%edx
	for (; s < ends; s++)
f010448f:	eb 07                	jmp    f0104498 <memfind+0x17>
		if (*(const unsigned char *) s == (unsigned char) c)
f0104491:	38 08                	cmp    %cl,(%eax)
f0104493:	74 07                	je     f010449c <memfind+0x1b>

void *
memfind(const void *s, int c, size_t n)
{
	const void *ends = (const char *) s + n;
	for (; s < ends; s++)
f0104495:	83 c0 01             	add    $0x1,%eax
f0104498:	39 d0                	cmp    %edx,%eax
f010449a:	72 f5                	jb     f0104491 <memfind+0x10>
		if (*(const unsigned char *) s == (unsigned char) c)
			break;
	return (void *) s;
}
f010449c:	5d                   	pop    %ebp
f010449d:	c3                   	ret    

f010449e <strtol>:

long
strtol(const char *s, char **endptr, int base)
{
f010449e:	55                   	push   %ebp
f010449f:	89 e5                	mov    %esp,%ebp
f01044a1:	57                   	push   %edi
f01044a2:	56                   	push   %esi
f01044a3:	53                   	push   %ebx
f01044a4:	8b 4d 08             	mov    0x8(%ebp),%ecx
f01044a7:	8b 5d 10             	mov    0x10(%ebp),%ebx
	int neg = 0;
	long val = 0;

	// gobble initial whitespace
	while (*s == ' ' || *s == '\t')
f01044aa:	eb 03                	jmp    f01044af <strtol+0x11>
		s++;
f01044ac:	83 c1 01             	add    $0x1,%ecx
{
	int neg = 0;
	long val = 0;

	// gobble initial whitespace
	while (*s == ' ' || *s == '\t')
f01044af:	0f b6 01             	movzbl (%ecx),%eax
f01044b2:	3c 20                	cmp    $0x20,%al
f01044b4:	74 f6                	je     f01044ac <strtol+0xe>
f01044b6:	3c 09                	cmp    $0x9,%al
f01044b8:	74 f2                	je     f01044ac <strtol+0xe>
		s++;

	// plus/minus sign
	if (*s == '+')
f01044ba:	3c 2b                	cmp    $0x2b,%al
f01044bc:	75 0a                	jne    f01044c8 <strtol+0x2a>
		s++;
f01044be:	83 c1 01             	add    $0x1,%ecx
}

long
strtol(const char *s, char **endptr, int base)
{
	int neg = 0;
f01044c1:	bf 00 00 00 00       	mov    $0x0,%edi
f01044c6:	eb 11                	jmp    f01044d9 <strtol+0x3b>
f01044c8:	bf 00 00 00 00       	mov    $0x0,%edi
		s++;

	// plus/minus sign
	if (*s == '+')
		s++;
	else if (*s == '-')
f01044cd:	3c 2d                	cmp    $0x2d,%al
f01044cf:	75 08                	jne    f01044d9 <strtol+0x3b>
		s++, neg = 1;
f01044d1:	83 c1 01             	add    $0x1,%ecx
f01044d4:	bf 01 00 00 00       	mov    $0x1,%edi

	// hex or octal base prefix
	if ((base == 0 || base == 16) && (s[0] == '0' && s[1] == 'x'))
f01044d9:	f7 c3 ef ff ff ff    	test   $0xffffffef,%ebx
f01044df:	75 15                	jne    f01044f6 <strtol+0x58>
f01044e1:	80 39 30             	cmpb   $0x30,(%ecx)
f01044e4:	75 10                	jne    f01044f6 <strtol+0x58>
f01044e6:	80 79 01 78          	cmpb   $0x78,0x1(%ecx)
f01044ea:	75 7c                	jne    f0104568 <strtol+0xca>
		s += 2, base = 16;
f01044ec:	83 c1 02             	add    $0x2,%ecx
f01044ef:	bb 10 00 00 00       	mov    $0x10,%ebx
f01044f4:	eb 16                	jmp    f010450c <strtol+0x6e>
	else if (base == 0 && s[0] == '0')
f01044f6:	85 db                	test   %ebx,%ebx
f01044f8:	75 12                	jne    f010450c <strtol+0x6e>
		s++, base = 8;
	else if (base == 0)
		base = 10;
f01044fa:	bb 0a 00 00 00       	mov    $0xa,%ebx
		s++, neg = 1;

	// hex or octal base prefix
	if ((base == 0 || base == 16) && (s[0] == '0' && s[1] == 'x'))
		s += 2, base = 16;
	else if (base == 0 && s[0] == '0')
f01044ff:	80 39 30             	cmpb   $0x30,(%ecx)
f0104502:	75 08                	jne    f010450c <strtol+0x6e>
		s++, base = 8;
f0104504:	83 c1 01             	add    $0x1,%ecx
f0104507:	bb 08 00 00 00       	mov    $0x8,%ebx
	else if (base == 0)
		base = 10;
f010450c:	b8 00 00 00 00       	mov    $0x0,%eax
f0104511:	89 5d 10             	mov    %ebx,0x10(%ebp)

	// digits
	while (1) {
		int dig;

		if (*s >= '0' && *s <= '9')
f0104514:	0f b6 11             	movzbl (%ecx),%edx
f0104517:	8d 72 d0             	lea    -0x30(%edx),%esi
f010451a:	89 f3                	mov    %esi,%ebx
f010451c:	80 fb 09             	cmp    $0x9,%bl
f010451f:	77 08                	ja     f0104529 <strtol+0x8b>
			dig = *s - '0';
f0104521:	0f be d2             	movsbl %dl,%edx
f0104524:	83 ea 30             	sub    $0x30,%edx
f0104527:	eb 22                	jmp    f010454b <strtol+0xad>
		else if (*s >= 'a' && *s <= 'z')
f0104529:	8d 72 9f             	lea    -0x61(%edx),%esi
f010452c:	89 f3                	mov    %esi,%ebx
f010452e:	80 fb 19             	cmp    $0x19,%bl
f0104531:	77 08                	ja     f010453b <strtol+0x9d>
			dig = *s - 'a' + 10;
f0104533:	0f be d2             	movsbl %dl,%edx
f0104536:	83 ea 57             	sub    $0x57,%edx
f0104539:	eb 10                	jmp    f010454b <strtol+0xad>
		else if (*s >= 'A' && *s <= 'Z')
f010453b:	8d 72 bf             	lea    -0x41(%edx),%esi
f010453e:	89 f3                	mov    %esi,%ebx
f0104540:	80 fb 19             	cmp    $0x19,%bl
f0104543:	77 16                	ja     f010455b <strtol+0xbd>
			dig = *s - 'A' + 10;
f0104545:	0f be d2             	movsbl %dl,%edx
f0104548:	83 ea 37             	sub    $0x37,%edx
		else
			break;
		if (dig >= base)
f010454b:	3b 55 10             	cmp    0x10(%ebp),%edx
f010454e:	7d 0b                	jge    f010455b <strtol+0xbd>
			break;
		s++, val = (val * base) + dig;
f0104550:	83 c1 01             	add    $0x1,%ecx
f0104553:	0f af 45 10          	imul   0x10(%ebp),%eax
f0104557:	01 d0                	add    %edx,%eax
		// we don't properly detect overflow!
	}
f0104559:	eb b9                	jmp    f0104514 <strtol+0x76>

	if (endptr)
f010455b:	83 7d 0c 00          	cmpl   $0x0,0xc(%ebp)
f010455f:	74 0d                	je     f010456e <strtol+0xd0>
		*endptr = (char *) s;
f0104561:	8b 75 0c             	mov    0xc(%ebp),%esi
f0104564:	89 0e                	mov    %ecx,(%esi)
f0104566:	eb 06                	jmp    f010456e <strtol+0xd0>
		s++, neg = 1;

	// hex or octal base prefix
	if ((base == 0 || base == 16) && (s[0] == '0' && s[1] == 'x'))
		s += 2, base = 16;
	else if (base == 0 && s[0] == '0')
f0104568:	85 db                	test   %ebx,%ebx
f010456a:	74 98                	je     f0104504 <strtol+0x66>
f010456c:	eb 9e                	jmp    f010450c <strtol+0x6e>
		// we don't properly detect overflow!
	}

	if (endptr)
		*endptr = (char *) s;
	return (neg ? -val : val);
f010456e:	89 c2                	mov    %eax,%edx
f0104570:	f7 da                	neg    %edx
f0104572:	85 ff                	test   %edi,%edi
f0104574:	0f 45 c2             	cmovne %edx,%eax
}
f0104577:	5b                   	pop    %ebx
f0104578:	5e                   	pop    %esi
f0104579:	5f                   	pop    %edi
f010457a:	5d                   	pop    %ebp
f010457b:	c3                   	ret    
f010457c:	66 90                	xchg   %ax,%ax
f010457e:	66 90                	xchg   %ax,%ax

f0104580 <__udivdi3>:
f0104580:	55                   	push   %ebp
f0104581:	57                   	push   %edi
f0104582:	56                   	push   %esi
f0104583:	53                   	push   %ebx
f0104584:	83 ec 1c             	sub    $0x1c,%esp
f0104587:	8b 74 24 3c          	mov    0x3c(%esp),%esi
f010458b:	8b 5c 24 30          	mov    0x30(%esp),%ebx
f010458f:	8b 4c 24 34          	mov    0x34(%esp),%ecx
f0104593:	8b 7c 24 38          	mov    0x38(%esp),%edi
f0104597:	85 f6                	test   %esi,%esi
f0104599:	89 5c 24 08          	mov    %ebx,0x8(%esp)
f010459d:	89 ca                	mov    %ecx,%edx
f010459f:	89 f8                	mov    %edi,%eax
f01045a1:	75 3d                	jne    f01045e0 <__udivdi3+0x60>
f01045a3:	39 cf                	cmp    %ecx,%edi
f01045a5:	0f 87 c5 00 00 00    	ja     f0104670 <__udivdi3+0xf0>
f01045ab:	85 ff                	test   %edi,%edi
f01045ad:	89 fd                	mov    %edi,%ebp
f01045af:	75 0b                	jne    f01045bc <__udivdi3+0x3c>
f01045b1:	b8 01 00 00 00       	mov    $0x1,%eax
f01045b6:	31 d2                	xor    %edx,%edx
f01045b8:	f7 f7                	div    %edi
f01045ba:	89 c5                	mov    %eax,%ebp
f01045bc:	89 c8                	mov    %ecx,%eax
f01045be:	31 d2                	xor    %edx,%edx
f01045c0:	f7 f5                	div    %ebp
f01045c2:	89 c1                	mov    %eax,%ecx
f01045c4:	89 d8                	mov    %ebx,%eax
f01045c6:	89 cf                	mov    %ecx,%edi
f01045c8:	f7 f5                	div    %ebp
f01045ca:	89 c3                	mov    %eax,%ebx
f01045cc:	89 d8                	mov    %ebx,%eax
f01045ce:	89 fa                	mov    %edi,%edx
f01045d0:	83 c4 1c             	add    $0x1c,%esp
f01045d3:	5b                   	pop    %ebx
f01045d4:	5e                   	pop    %esi
f01045d5:	5f                   	pop    %edi
f01045d6:	5d                   	pop    %ebp
f01045d7:	c3                   	ret    
f01045d8:	90                   	nop
f01045d9:	8d b4 26 00 00 00 00 	lea    0x0(%esi,%eiz,1),%esi
f01045e0:	39 ce                	cmp    %ecx,%esi
f01045e2:	77 74                	ja     f0104658 <__udivdi3+0xd8>
f01045e4:	0f bd fe             	bsr    %esi,%edi
f01045e7:	83 f7 1f             	xor    $0x1f,%edi
f01045ea:	0f 84 98 00 00 00    	je     f0104688 <__udivdi3+0x108>
f01045f0:	bb 20 00 00 00       	mov    $0x20,%ebx
f01045f5:	89 f9                	mov    %edi,%ecx
f01045f7:	89 c5                	mov    %eax,%ebp
f01045f9:	29 fb                	sub    %edi,%ebx
f01045fb:	d3 e6                	shl    %cl,%esi
f01045fd:	89 d9                	mov    %ebx,%ecx
f01045ff:	d3 ed                	shr    %cl,%ebp
f0104601:	89 f9                	mov    %edi,%ecx
f0104603:	d3 e0                	shl    %cl,%eax
f0104605:	09 ee                	or     %ebp,%esi
f0104607:	89 d9                	mov    %ebx,%ecx
f0104609:	89 44 24 0c          	mov    %eax,0xc(%esp)
f010460d:	89 d5                	mov    %edx,%ebp
f010460f:	8b 44 24 08          	mov    0x8(%esp),%eax
f0104613:	d3 ed                	shr    %cl,%ebp
f0104615:	89 f9                	mov    %edi,%ecx
f0104617:	d3 e2                	shl    %cl,%edx
f0104619:	89 d9                	mov    %ebx,%ecx
f010461b:	d3 e8                	shr    %cl,%eax
f010461d:	09 c2                	or     %eax,%edx
f010461f:	89 d0                	mov    %edx,%eax
f0104621:	89 ea                	mov    %ebp,%edx
f0104623:	f7 f6                	div    %esi
f0104625:	89 d5                	mov    %edx,%ebp
f0104627:	89 c3                	mov    %eax,%ebx
f0104629:	f7 64 24 0c          	mull   0xc(%esp)
f010462d:	39 d5                	cmp    %edx,%ebp
f010462f:	72 10                	jb     f0104641 <__udivdi3+0xc1>
f0104631:	8b 74 24 08          	mov    0x8(%esp),%esi
f0104635:	89 f9                	mov    %edi,%ecx
f0104637:	d3 e6                	shl    %cl,%esi
f0104639:	39 c6                	cmp    %eax,%esi
f010463b:	73 07                	jae    f0104644 <__udivdi3+0xc4>
f010463d:	39 d5                	cmp    %edx,%ebp
f010463f:	75 03                	jne    f0104644 <__udivdi3+0xc4>
f0104641:	83 eb 01             	sub    $0x1,%ebx
f0104644:	31 ff                	xor    %edi,%edi
f0104646:	89 d8                	mov    %ebx,%eax
f0104648:	89 fa                	mov    %edi,%edx
f010464a:	83 c4 1c             	add    $0x1c,%esp
f010464d:	5b                   	pop    %ebx
f010464e:	5e                   	pop    %esi
f010464f:	5f                   	pop    %edi
f0104650:	5d                   	pop    %ebp
f0104651:	c3                   	ret    
f0104652:	8d b6 00 00 00 00    	lea    0x0(%esi),%esi
f0104658:	31 ff                	xor    %edi,%edi
f010465a:	31 db                	xor    %ebx,%ebx
f010465c:	89 d8                	mov    %ebx,%eax
f010465e:	89 fa                	mov    %edi,%edx
f0104660:	83 c4 1c             	add    $0x1c,%esp
f0104663:	5b                   	pop    %ebx
f0104664:	5e                   	pop    %esi
f0104665:	5f                   	pop    %edi
f0104666:	5d                   	pop    %ebp
f0104667:	c3                   	ret    
f0104668:	90                   	nop
f0104669:	8d b4 26 00 00 00 00 	lea    0x0(%esi,%eiz,1),%esi
f0104670:	89 d8                	mov    %ebx,%eax
f0104672:	f7 f7                	div    %edi
f0104674:	31 ff                	xor    %edi,%edi
f0104676:	89 c3                	mov    %eax,%ebx
f0104678:	89 d8                	mov    %ebx,%eax
f010467a:	89 fa                	mov    %edi,%edx
f010467c:	83 c4 1c             	add    $0x1c,%esp
f010467f:	5b                   	pop    %ebx
f0104680:	5e                   	pop    %esi
f0104681:	5f                   	pop    %edi
f0104682:	5d                   	pop    %ebp
f0104683:	c3                   	ret    
f0104684:	8d 74 26 00          	lea    0x0(%esi,%eiz,1),%esi
f0104688:	39 ce                	cmp    %ecx,%esi
f010468a:	72 0c                	jb     f0104698 <__udivdi3+0x118>
f010468c:	31 db                	xor    %ebx,%ebx
f010468e:	3b 44 24 08          	cmp    0x8(%esp),%eax
f0104692:	0f 87 34 ff ff ff    	ja     f01045cc <__udivdi3+0x4c>
f0104698:	bb 01 00 00 00       	mov    $0x1,%ebx
f010469d:	e9 2a ff ff ff       	jmp    f01045cc <__udivdi3+0x4c>
f01046a2:	66 90                	xchg   %ax,%ax
f01046a4:	66 90                	xchg   %ax,%ax
f01046a6:	66 90                	xchg   %ax,%ax
f01046a8:	66 90                	xchg   %ax,%ax
f01046aa:	66 90                	xchg   %ax,%ax
f01046ac:	66 90                	xchg   %ax,%ax
f01046ae:	66 90                	xchg   %ax,%ax

f01046b0 <__umoddi3>:
f01046b0:	55                   	push   %ebp
f01046b1:	57                   	push   %edi
f01046b2:	56                   	push   %esi
f01046b3:	53                   	push   %ebx
f01046b4:	83 ec 1c             	sub    $0x1c,%esp
f01046b7:	8b 54 24 3c          	mov    0x3c(%esp),%edx
f01046bb:	8b 4c 24 30          	mov    0x30(%esp),%ecx
f01046bf:	8b 74 24 34          	mov    0x34(%esp),%esi
f01046c3:	8b 7c 24 38          	mov    0x38(%esp),%edi
f01046c7:	85 d2                	test   %edx,%edx
f01046c9:	89 4c 24 0c          	mov    %ecx,0xc(%esp)
f01046cd:	89 4c 24 08          	mov    %ecx,0x8(%esp)
f01046d1:	89 f3                	mov    %esi,%ebx
f01046d3:	89 3c 24             	mov    %edi,(%esp)
f01046d6:	89 74 24 04          	mov    %esi,0x4(%esp)
f01046da:	75 1c                	jne    f01046f8 <__umoddi3+0x48>
f01046dc:	39 f7                	cmp    %esi,%edi
f01046de:	76 50                	jbe    f0104730 <__umoddi3+0x80>
f01046e0:	89 c8                	mov    %ecx,%eax
f01046e2:	89 f2                	mov    %esi,%edx
f01046e4:	f7 f7                	div    %edi
f01046e6:	89 d0                	mov    %edx,%eax
f01046e8:	31 d2                	xor    %edx,%edx
f01046ea:	83 c4 1c             	add    $0x1c,%esp
f01046ed:	5b                   	pop    %ebx
f01046ee:	5e                   	pop    %esi
f01046ef:	5f                   	pop    %edi
f01046f0:	5d                   	pop    %ebp
f01046f1:	c3                   	ret    
f01046f2:	8d b6 00 00 00 00    	lea    0x0(%esi),%esi
f01046f8:	39 f2                	cmp    %esi,%edx
f01046fa:	89 d0                	mov    %edx,%eax
f01046fc:	77 52                	ja     f0104750 <__umoddi3+0xa0>
f01046fe:	0f bd ea             	bsr    %edx,%ebp
f0104701:	83 f5 1f             	xor    $0x1f,%ebp
f0104704:	75 5a                	jne    f0104760 <__umoddi3+0xb0>
f0104706:	3b 54 24 04          	cmp    0x4(%esp),%edx
f010470a:	0f 82 e0 00 00 00    	jb     f01047f0 <__umoddi3+0x140>
f0104710:	39 0c 24             	cmp    %ecx,(%esp)
f0104713:	0f 86 d7 00 00 00    	jbe    f01047f0 <__umoddi3+0x140>
f0104719:	8b 44 24 08          	mov    0x8(%esp),%eax
f010471d:	8b 54 24 04          	mov    0x4(%esp),%edx
f0104721:	83 c4 1c             	add    $0x1c,%esp
f0104724:	5b                   	pop    %ebx
f0104725:	5e                   	pop    %esi
f0104726:	5f                   	pop    %edi
f0104727:	5d                   	pop    %ebp
f0104728:	c3                   	ret    
f0104729:	8d b4 26 00 00 00 00 	lea    0x0(%esi,%eiz,1),%esi
f0104730:	85 ff                	test   %edi,%edi
f0104732:	89 fd                	mov    %edi,%ebp
f0104734:	75 0b                	jne    f0104741 <__umoddi3+0x91>
f0104736:	b8 01 00 00 00       	mov    $0x1,%eax
f010473b:	31 d2                	xor    %edx,%edx
f010473d:	f7 f7                	div    %edi
f010473f:	89 c5                	mov    %eax,%ebp
f0104741:	89 f0                	mov    %esi,%eax
f0104743:	31 d2                	xor    %edx,%edx
f0104745:	f7 f5                	div    %ebp
f0104747:	89 c8                	mov    %ecx,%eax
f0104749:	f7 f5                	div    %ebp
f010474b:	89 d0                	mov    %edx,%eax
f010474d:	eb 99                	jmp    f01046e8 <__umoddi3+0x38>
f010474f:	90                   	nop
f0104750:	89 c8                	mov    %ecx,%eax
f0104752:	89 f2                	mov    %esi,%edx
f0104754:	83 c4 1c             	add    $0x1c,%esp
f0104757:	5b                   	pop    %ebx
f0104758:	5e                   	pop    %esi
f0104759:	5f                   	pop    %edi
f010475a:	5d                   	pop    %ebp
f010475b:	c3                   	ret    
f010475c:	8d 74 26 00          	lea    0x0(%esi,%eiz,1),%esi
f0104760:	8b 34 24             	mov    (%esp),%esi
f0104763:	bf 20 00 00 00       	mov    $0x20,%edi
f0104768:	89 e9                	mov    %ebp,%ecx
f010476a:	29 ef                	sub    %ebp,%edi
f010476c:	d3 e0                	shl    %cl,%eax
f010476e:	89 f9                	mov    %edi,%ecx
f0104770:	89 f2                	mov    %esi,%edx
f0104772:	d3 ea                	shr    %cl,%edx
f0104774:	89 e9                	mov    %ebp,%ecx
f0104776:	09 c2                	or     %eax,%edx
f0104778:	89 d8                	mov    %ebx,%eax
f010477a:	89 14 24             	mov    %edx,(%esp)
f010477d:	89 f2                	mov    %esi,%edx
f010477f:	d3 e2                	shl    %cl,%edx
f0104781:	89 f9                	mov    %edi,%ecx
f0104783:	89 54 24 04          	mov    %edx,0x4(%esp)
f0104787:	8b 54 24 0c          	mov    0xc(%esp),%edx
f010478b:	d3 e8                	shr    %cl,%eax
f010478d:	89 e9                	mov    %ebp,%ecx
f010478f:	89 c6                	mov    %eax,%esi
f0104791:	d3 e3                	shl    %cl,%ebx
f0104793:	89 f9                	mov    %edi,%ecx
f0104795:	89 d0                	mov    %edx,%eax
f0104797:	d3 e8                	shr    %cl,%eax
f0104799:	89 e9                	mov    %ebp,%ecx
f010479b:	09 d8                	or     %ebx,%eax
f010479d:	89 d3                	mov    %edx,%ebx
f010479f:	89 f2                	mov    %esi,%edx
f01047a1:	f7 34 24             	divl   (%esp)
f01047a4:	89 d6                	mov    %edx,%esi
f01047a6:	d3 e3                	shl    %cl,%ebx
f01047a8:	f7 64 24 04          	mull   0x4(%esp)
f01047ac:	39 d6                	cmp    %edx,%esi
f01047ae:	89 5c 24 08          	mov    %ebx,0x8(%esp)
f01047b2:	89 d1                	mov    %edx,%ecx
f01047b4:	89 c3                	mov    %eax,%ebx
f01047b6:	72 08                	jb     f01047c0 <__umoddi3+0x110>
f01047b8:	75 11                	jne    f01047cb <__umoddi3+0x11b>
f01047ba:	39 44 24 08          	cmp    %eax,0x8(%esp)
f01047be:	73 0b                	jae    f01047cb <__umoddi3+0x11b>
f01047c0:	2b 44 24 04          	sub    0x4(%esp),%eax
f01047c4:	1b 14 24             	sbb    (%esp),%edx
f01047c7:	89 d1                	mov    %edx,%ecx
f01047c9:	89 c3                	mov    %eax,%ebx
f01047cb:	8b 54 24 08          	mov    0x8(%esp),%edx
f01047cf:	29 da                	sub    %ebx,%edx
f01047d1:	19 ce                	sbb    %ecx,%esi
f01047d3:	89 f9                	mov    %edi,%ecx
f01047d5:	89 f0                	mov    %esi,%eax
f01047d7:	d3 e0                	shl    %cl,%eax
f01047d9:	89 e9                	mov    %ebp,%ecx
f01047db:	d3 ea                	shr    %cl,%edx
f01047dd:	89 e9                	mov    %ebp,%ecx
f01047df:	d3 ee                	shr    %cl,%esi
f01047e1:	09 d0                	or     %edx,%eax
f01047e3:	89 f2                	mov    %esi,%edx
f01047e5:	83 c4 1c             	add    $0x1c,%esp
f01047e8:	5b                   	pop    %ebx
f01047e9:	5e                   	pop    %esi
f01047ea:	5f                   	pop    %edi
f01047eb:	5d                   	pop    %ebp
f01047ec:	c3                   	ret    
f01047ed:	8d 76 00             	lea    0x0(%esi),%esi
f01047f0:	29 f9                	sub    %edi,%ecx
f01047f2:	19 d6                	sbb    %edx,%esi
f01047f4:	89 74 24 04          	mov    %esi,0x4(%esp)
f01047f8:	89 4c 24 08          	mov    %ecx,0x8(%esp)
f01047fc:	e9 18 ff ff ff       	jmp    f0104719 <__umoddi3+0x69>
