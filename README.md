# BIOS Snake

A tiny snake game written in raw x86 assembly (NASM) that runs directly on real-mode BIOS interrupts — no operating system, no C runtime, just a CPU, RAM, and the BIOS.



<img width="400" height="225" alt="snake3" src="https://github.com/user-attachments/assets/225e3be8-4fda-4d11-a934-4fdf996d0dc8" />




## How it works

The whole game loop lives inside a boot-stage binary:

- **Rendering** — `INT 10h` (video services) is used two ways: `AH=02h` to move the text-mode cursor to a `(row, col)` position, and `AH=0Eh` (teletype output) to print the `o` character that represents each snake segment.
- **Input** — `INT 16h` (keyboard services) polls for a keypress. Extended scan codes for the arrow keys (`0x48` up, `0x50` down, `0x4B` left, `0x4D` right) are captured and stored in the `onclick` byte.
- **Timing** — `INT 15h, AH=86h` (BIOS wait function) is used to pace movement so the snake doesn't move at CPU speed.
- **Snake state** — the snake's head position is tracked directly in the `AL` (column) / `AH` (row) register pair. The `body` array holds the row/col pairs for each body segment, terminated with a `$` sentinel byte. On every move, `swap` shifts each segment's coordinates into the next one, so the tail "follows" the path the head took.
- **Movement** — `up`, `down`, `left`, and `right` each adjust `AH`/`AL` by one, then `update_and_ptbody` clears the old tail cell, shifts the body, and redraws the whole snake.

## Project structure

| Routine | Purpose |
|---|---|
| `init` | Sets up the initial body coordinates and does the first draw |
| `print_whole_body` | Draws tail → body → head each frame |
| `body_loop_print` | Walks the `body` array and prints each segment |
| `key` / `cls_key` / `checktwice` | Reads and filters keyboard scan codes |
| `swap` / `swap_body_loop` | Shifts body segment coordinates for movement |
| `set_head_cursor` / `set_tail_cursor` / `set_body_cursor` | Position the text cursor for drawing |
| `time_interval` | BIOS delay between moves |
| `start` / `continue_start` | Main game loop, dispatches on the pressed key |

## Requirements

- [NASM](https://www.nasm.us/) to assemble
- [QEMU](https://www.qemu.org/) (or a VM / real hardware) to run it

## Building

```bash
nasm -f bin snake.asm -o snake.bin
```

## Running

> **Note:** this file is assembled with `ORG 0x7e00`, meaning it expects to be *loaded into memory at 0x7e00* — the address right after a standard 512-byte boot sector at `0x7c00`. It's written as a **second-stage** loader, not a standalone boot sector. To run it you'll need either:
>
> 1. A minimal first-stage boot sector that reads this binary's sectors off disk into memory at `0x7e00` and jumps there, or
> 2. To temporarily change `ORG` to `0x7c00`, add the `TIMES 510-($-$$) DB 0` padding and `DW 0xaa55` boot signature (both are already present but commented out at the bottom of the file), and boot it directly as a floppy/MBR image.

For quick testing as a direct boot sector (option 2):

```bash
qemu-system-x86_64 -fda snake.bin
```

## Controls

| Key | Action |
|---|---|
| ↑ | Move up |
| ↓ | Move down |
| ← | Move left |
| → | Move right |

## Known limitations

- Fixed-length snake — there's no food or growth mechanic yet
- No self-collision or wall-collision detection (the snake can move off-screen)
- No score tracking
- The down-arrow path currently ends in `HLT` instructions rather than looping, so moving down halts the CPU

## Roadmap ideas

- Add food spawning and body growth
- Add collision detection and a game-over state
- Add a score display using `printax`
- Randomize the timer/speed as the snake grows

## License

MIT — do whatever you like with it.
