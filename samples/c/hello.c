/*
 * hello.c - Render "HELLO WORLD" on the rpusbdisp framebuffer.
 *
 * Uses the Linux framebuffer API (fbdev) with mmap.  Includes a minimal
 * built-in 8x16 bitmap font for uppercase A-Z, digits, space, and basic
 * punctuation.
 *
 * Usage:
 *   ./hello [/dev/fbN]
 *
 * If no argument is given, scans /proc/fb for "rpusbdisp-fb".
 * Falls back to /dev/fb0 if not found.
 *
 * Compile:
 *   gcc -O2 -Wall -o hello hello.c
 */

#include <stdio.h>
#include <stdlib.h>
#include <string.h>
#include <fcntl.h>
#include <unistd.h>
#include <sys/ioctl.h>
#include <sys/mman.h>
#include <linux/fb.h>

/* ======================================================================
 * Minimal 8x16 bitmap font
 * Each character is 16 bytes, one byte per row, MSB = leftmost pixel.
 * Covers: space, ! through /, 0-9, : through @, A-Z, [ through `, a-z
 * We only define what we need: A-Z, 0-9, space, and a few extras.
 * ====================================================================== */

#define FONT_W 8
#define FONT_H 16

/* clang-format off */
static const unsigned char font_space[16] =
    {0x00,0x00,0x00,0x00,0x00,0x00,0x00,0x00,
     0x00,0x00,0x00,0x00,0x00,0x00,0x00,0x00};

static const unsigned char font_A[16] =
    {0x00,0x00,0x18,0x3C,0x66,0x66,0xC3,0xC3,
     0xFF,0xC3,0xC3,0xC3,0xC3,0x00,0x00,0x00};
static const unsigned char font_B[16] =
    {0x00,0x00,0xFE,0xC3,0xC3,0xC3,0xFE,0xC3,
     0xC3,0xC3,0xC3,0xFE,0x00,0x00,0x00,0x00};
static const unsigned char font_C[16] =
    {0x00,0x00,0x3E,0x63,0xC0,0xC0,0xC0,0xC0,
     0xC0,0xC0,0x63,0x3E,0x00,0x00,0x00,0x00};
static const unsigned char font_D[16] =
    {0x00,0x00,0xFC,0xC6,0xC3,0xC3,0xC3,0xC3,
     0xC3,0xC3,0xC6,0xFC,0x00,0x00,0x00,0x00};
static const unsigned char font_E[16] =
    {0x00,0x00,0xFF,0xC0,0xC0,0xC0,0xFE,0xC0,
     0xC0,0xC0,0xC0,0xFF,0x00,0x00,0x00,0x00};
static const unsigned char font_F[16] =
    {0x00,0x00,0xFF,0xC0,0xC0,0xC0,0xFE,0xC0,
     0xC0,0xC0,0xC0,0xC0,0x00,0x00,0x00,0x00};
static const unsigned char font_G[16] =
    {0x00,0x00,0x3E,0x63,0xC0,0xC0,0xC0,0xCF,
     0xC3,0xC3,0x63,0x3E,0x00,0x00,0x00,0x00};
static const unsigned char font_H[16] =
    {0x00,0x00,0xC3,0xC3,0xC3,0xC3,0xFF,0xC3,
     0xC3,0xC3,0xC3,0xC3,0x00,0x00,0x00,0x00};
static const unsigned char font_I[16] =
    {0x00,0x00,0x7E,0x18,0x18,0x18,0x18,0x18,
     0x18,0x18,0x18,0x7E,0x00,0x00,0x00,0x00};
static const unsigned char font_J[16] =
    {0x00,0x00,0x1F,0x06,0x06,0x06,0x06,0x06,
     0x06,0xC6,0xC6,0x7C,0x00,0x00,0x00,0x00};
static const unsigned char font_K[16] =
    {0x00,0x00,0xC6,0xCC,0xD8,0xF0,0xE0,0xF0,
     0xD8,0xCC,0xC6,0xC3,0x00,0x00,0x00,0x00};
static const unsigned char font_L[16] =
    {0x00,0x00,0xC0,0xC0,0xC0,0xC0,0xC0,0xC0,
     0xC0,0xC0,0xC0,0xFF,0x00,0x00,0x00,0x00};
static const unsigned char font_M[16] =
    {0x00,0x00,0xC3,0xE7,0xFF,0xDB,0xDB,0xC3,
     0xC3,0xC3,0xC3,0xC3,0x00,0x00,0x00,0x00};
static const unsigned char font_N[16] =
    {0x00,0x00,0xC3,0xE3,0xF3,0xDB,0xCB,0xCF,
     0xC7,0xC3,0xC3,0xC3,0x00,0x00,0x00,0x00};
static const unsigned char font_O[16] =
    {0x00,0x00,0x3C,0x66,0xC3,0xC3,0xC3,0xC3,
     0xC3,0xC3,0x66,0x3C,0x00,0x00,0x00,0x00};
static const unsigned char font_P[16] =
    {0x00,0x00,0xFE,0xC3,0xC3,0xC3,0xFE,0xC0,
     0xC0,0xC0,0xC0,0xC0,0x00,0x00,0x00,0x00};
static const unsigned char font_Q[16] =
    {0x00,0x00,0x3C,0x66,0xC3,0xC3,0xC3,0xC3,
     0xC3,0xCB,0x66,0x3C,0x06,0x00,0x00,0x00};
static const unsigned char font_R[16] =
    {0x00,0x00,0xFE,0xC3,0xC3,0xC3,0xFE,0xF0,
     0xD8,0xCC,0xC6,0xC3,0x00,0x00,0x00,0x00};
static const unsigned char font_S[16] =
    {0x00,0x00,0x7E,0xC3,0xC0,0xC0,0x7E,0x03,
     0x03,0xC3,0xC3,0x7E,0x00,0x00,0x00,0x00};
static const unsigned char font_T[16] =
    {0x00,0x00,0xFF,0x18,0x18,0x18,0x18,0x18,
     0x18,0x18,0x18,0x18,0x00,0x00,0x00,0x00};
static const unsigned char font_U[16] =
    {0x00,0x00,0xC3,0xC3,0xC3,0xC3,0xC3,0xC3,
     0xC3,0xC3,0xC3,0x7E,0x00,0x00,0x00,0x00};
static const unsigned char font_V[16] =
    {0x00,0x00,0xC3,0xC3,0xC3,0xC3,0x66,0x66,
     0x3C,0x3C,0x18,0x18,0x00,0x00,0x00,0x00};
static const unsigned char font_W[16] =
    {0x00,0x00,0xC3,0xC3,0xC3,0xC3,0xDB,0xDB,
     0xFF,0xE7,0xC3,0xC3,0x00,0x00,0x00,0x00};
static const unsigned char font_X[16] =
    {0x00,0x00,0xC3,0xC3,0x66,0x3C,0x18,0x18,
     0x3C,0x66,0xC3,0xC3,0x00,0x00,0x00,0x00};
static const unsigned char font_Y[16] =
    {0x00,0x00,0xC3,0xC3,0x66,0x3C,0x18,0x18,
     0x18,0x18,0x18,0x18,0x00,0x00,0x00,0x00};
static const unsigned char font_Z[16] =
    {0x00,0x00,0xFF,0x03,0x06,0x0C,0x18,0x30,
     0x60,0xC0,0xC0,0xFF,0x00,0x00,0x00,0x00};
/* clang-format on */

/* Lookup table indexed by ASCII value.  NULL = unsupported character. */
static const unsigned char *font_table[128];

static void init_font_table(void)
{
    memset(font_table, 0, sizeof(font_table));
    font_table[' '] = font_space;
    font_table['A'] = font_A; font_table['B'] = font_B;
    font_table['C'] = font_C; font_table['D'] = font_D;
    font_table['E'] = font_E; font_table['F'] = font_F;
    font_table['G'] = font_G; font_table['H'] = font_H;
    font_table['I'] = font_I; font_table['J'] = font_J;
    font_table['K'] = font_K; font_table['L'] = font_L;
    font_table['M'] = font_M; font_table['N'] = font_N;
    font_table['O'] = font_O; font_table['P'] = font_P;
    font_table['Q'] = font_Q; font_table['R'] = font_R;
    font_table['S'] = font_S; font_table['T'] = font_T;
    font_table['U'] = font_U; font_table['V'] = font_V;
    font_table['W'] = font_W; font_table['X'] = font_X;
    font_table['Y'] = font_Y; font_table['Z'] = font_Z;
}

/* -------------------------------------------------------------------
 * Auto-detect rpusbdisp framebuffer by scanning /proc/fb
 * ------------------------------------------------------------------- */
static int detect_rpusbdisp_fb(char *out, size_t outlen)
{
    FILE *fp = fopen("/proc/fb", "r");
    if (!fp)
        return -1;

    char line[256];
    while (fgets(line, sizeof(line), fp)) {
        int num;
        char name[128];
        if (sscanf(line, "%d %127s", &num, name) == 2) {
            if (strcmp(name, "rpusbdisp-fb") == 0) {
                snprintf(out, outlen, "/dev/fb%d", num);
                fclose(fp);
                return 0;
            }
        }
    }
    fclose(fp);
    return -1;
}

/* -------------------------------------------------------------------
 * Draw a single character at (x, y) with the given scale factor.
 * ------------------------------------------------------------------- */
static void draw_char(unsigned char *fb, int fb_width, int fb_height,
                       int bpp, char ch, int x, int y, int scale)
{
    const unsigned char *glyph = NULL;
    if ((unsigned char)ch < 128)
        glyph = font_table[(unsigned char)ch];
    if (!glyph)
        glyph = font_space;

    int bytes_per_pixel = bpp / 8;

    for (int row = 0; row < FONT_H; row++) {
        unsigned char bits = glyph[row];
        for (int col = 0; col < FONT_W; col++) {
            if (bits & (0x80 >> col)) {
                for (int sy = 0; sy < scale; sy++) {
                    for (int sx = 0; sx < scale; sx++) {
                        int px = x + col * scale + sx;
                        int py = y + row * scale + sy;
                        if (px < 0 || px >= fb_width ||
                            py < 0 || py >= fb_height)
                            continue;
                        int offset = (py * fb_width + px) * bytes_per_pixel;

                        if (bpp == 16) {
                            /* RGB565 white */
                            fb[offset]     = 0xFF;
                            fb[offset + 1] = 0xFF;
                        } else if (bpp == 24) {
                            fb[offset]     = 0xFF; /* B */
                            fb[offset + 1] = 0xFF; /* G */
                            fb[offset + 2] = 0xFF; /* R */
                        } else if (bpp == 32) {
                            fb[offset]     = 0xFF; /* B */
                            fb[offset + 1] = 0xFF; /* G */
                            fb[offset + 2] = 0xFF; /* R */
                            fb[offset + 3] = 0xFF; /* A */
                        }
                    }
                }
            }
        }
    }
}

/* -------------------------------------------------------------------
 * Draw a string centred on the framebuffer.
 * ------------------------------------------------------------------- */
static void draw_string(unsigned char *fb, int fb_width, int fb_height,
                         int bpp, const char *text, int scale)
{
    int len = (int)strlen(text);
    int total_w = len * FONT_W * scale;
    int total_h = FONT_H * scale;
    int start_x = (fb_width  - total_w) / 2;
    int start_y = (fb_height - total_h) / 2;

    for (int i = 0; i < len; i++) {
        draw_char(fb, fb_width, fb_height, bpp,
                  text[i], start_x + i * FONT_W * scale, start_y, scale);
    }
}

int main(int argc, char *argv[])
{
    char fb_path[64] = "/dev/fb0";

    init_font_table();

    /* Determine the framebuffer device */
    if (argc > 1) {
        strncpy(fb_path, argv[1], sizeof(fb_path) - 1);
        fb_path[sizeof(fb_path) - 1] = '\0';
        fprintf(stderr, "Using framebuffer device from argument: %s\n", fb_path);
    } else if (detect_rpusbdisp_fb(fb_path, sizeof(fb_path)) == 0) {
        fprintf(stderr, "Auto-detected rpusbdisp framebuffer: %s\n", fb_path);
    } else {
        fprintf(stderr,
                "WARNING: rpusbdisp-fb not found in /proc/fb; "
                "defaulting to %s\n", fb_path);
    }

    /* Open the framebuffer */
    int fd = open(fb_path, O_RDWR);
    if (fd < 0) {
        perror("open framebuffer");
        return 1;
    }

    /* Query screen info */
    struct fb_var_screeninfo vinfo;
    if (ioctl(fd, FBIOGET_VSCREENINFO, &vinfo) < 0) {
        perror("ioctl FBIOGET_VSCREENINFO");
        close(fd);
        return 1;
    }

    int width  = (int)vinfo.xres;
    int height = (int)vinfo.yres;
    int bpp    = (int)vinfo.bits_per_pixel;

    fprintf(stderr, "Resolution: %dx%d, depth: %d bpp\n", width, height, bpp);

    if (bpp != 16 && bpp != 24 && bpp != 32) {
        fprintf(stderr, "ERROR: unsupported bits_per_pixel=%d\n", bpp);
        close(fd);
        return 1;
    }

    /* mmap the framebuffer */
    size_t fb_size = (size_t)width * height * (bpp / 8);
    unsigned char *fb = mmap(NULL, fb_size, PROT_READ | PROT_WRITE,
                             MAP_SHARED, fd, 0);
    if (fb == MAP_FAILED) {
        perror("mmap");
        close(fd);
        return 1;
    }

    /* Clear to black */
    memset(fb, 0, fb_size);

    /* Choose a scale factor so text is roughly 60% of screen width */
    const char *text = "HELLO WORLD";
    int text_pixel_w = (int)strlen(text) * FONT_W;
    int target_w = (int)(width * 0.6);
    int scale = target_w / text_pixel_w;
    if (scale < 1)
        scale = 1;

    fprintf(stderr, "Rendering \"%s\" with scale %dx...\n", text, scale);

    draw_string(fb, width, height, bpp, text, scale);

    /* Clean up */
    munmap(fb, fb_size);
    close(fd);

    fprintf(stderr, "Done. \"%s\" written to %s.\n", text, fb_path);
    return 0;
}
