
#import <stddef.h>

extern int should_exit;

void LoadProgram(const char *data, size_t size);
void ExecuteInstruction();
void DestroyProgram();

void UpdateKey(unsigned char index, unsigned char value);
void ReleaseKeys();

int ShouldUpdateScreen();
unsigned int GetScreenWidth();
unsigned int GetScreenHeight();
int GetScreenPixel(unsigned int x, unsigned int y);

int UpdateTimers();

