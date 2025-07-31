// test break
int main() {
    int i;
    i = 0;
    int sum;
    sum = 0;
    while (i < 10) {
        if (i == 5) {
            break;
        }
        sum = sum + i;
        i = i + 1;
    }
    return sum;
}