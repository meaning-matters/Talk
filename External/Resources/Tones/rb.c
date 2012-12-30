// Source of RBTs: http://www.cs.columbia.edu/sip/drafts/draft-roach-voip-ringtone-00.txt
// Has been edited (Germany, Kenya and few others) to fit in PJSIP structure.
// Other good resource: http://www.itu.int/dms_pub/itu-t/opb/sp/T-SP-E.180-2010-PDF-E.pdf

#include <stdio.h>
#include <string.h>
#include <ctype.h>
int main(void)
{
    FILE* file = fopen("RingbackTones.txt", "r");
    char  buffer[100];
    int   state;
    char* line;
    int  first = 1;
    char  name[100];

    printf("{\n");
    while ((line = fgets(buffer, sizeof(buffer), file)) != NULL)
    {
        if (strlen(line) == 1)
        {
            state = 0;
        }
        else if (state == 0)
        {
            char prefix[100];
            sscanf(line, " %s", prefix);
            line[strlen(line) - 1] = 0;
            strcpy(name, line + strlen(prefix) + 2);
            state = 1;
        }
        else if (state == 1)
        {
            if (!first)
            {
                printf(",\n");
            }
            first = 0;

            char code[100];
            sscanf(line, " Code: %s\n", code);
            printf("    \"%c%c\" :\n", toupper(code[0]), toupper(code[1]));
            printf("    {\n");
            printf("        \"name\" : \"%s\",\n", name);
            state = 2;
        }
        else if (state == 2)
        {
            int freq1 = 0;
            int freq2 = 0;
            int count;
            count = sscanf(line, " Frequency: %d Hz + %d Hz\n", &freq1, &freq2);    // Modulated tones are not supported.
            if (count == 0)
            {
                printf("################################\n");
            }
            printf("        \"frequency1\" : %d,\n", freq1);
            printf("        \"frequency1\" : %d,\n", freq2);
            state = 3;
        }
        else if (state == 3)
        {
            int times[10];
            int count = 0;
            int on;
            int off;
            int interval;

            if (sscanf(line, " - CONTINUOUS") == 1)
            {
                printf("        \"on\" : 2000,\n");
                printf("        \"off\" : 0,\n");
                printf("        \"count\" : 1,\n");
                printf("        \"interval\" : 0,\n");
            }
            else
            {
                do
                {
                    float   time;
                    sscanf(line, " - %f", &time);
                    times[count++] = time * 1000;

                    if (strlen(line) == 1)
                    {
                        break;
                    }
                }
                while ((line = fgets(buffer, sizeof(buffer), file)) != NULL);

                printf("        \"on\" : %d,\n", times[0]);
                printf("        \"off\" : %d,\n", times[1]);
                printf("        \"count\" : %d,\n", count / 2);
                printf("        \"interval\" : %d\n", times[count - 1]);
                printf("    }");
            }

            state = 0;
        }
    }

    printf("\n}\n");
}
