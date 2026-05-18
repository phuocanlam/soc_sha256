#include <iostream>
#include <cstdint>
#include <vector>
#include <fstream>
#include <iomanip>
#include <sstream>
#include <string>

uint32_t Rot_Right_n(uint32_t x, int n)
{
    n = n % 32;
    return (x >> n) | (x << (32 - n));
}

uint32_t Shift_Right_n(uint32_t x, int n)
{
    return x >> n;
}

uint32_t sigma_0_f (uint32_t x)
{
    uint32_t a, b, c;
    a = Rot_Right_n(x, 7);
    b = Rot_Right_n(x, 18);
    c = Shift_Right_n(x, 3);
    return (a ^ b ^ c);
}

uint32_t sigma_0_compression (uint32_t x)
{
    uint32_t a, b, c;
    a = Rot_Right_n(x, 2);
    b = Rot_Right_n(x, 13);
    c = Rot_Right_n(x, 22);
    return (a ^ b ^ c);
}

uint32_t sigma_1_f (uint32_t x)
{
    uint32_t a, b, c;
    a = Rot_Right_n(x, 17);
    b = Rot_Right_n(x, 19);
    c = Shift_Right_n(x, 10);
    return (a ^ b ^ c);
}

uint32_t sigma_1_compression (uint32_t x)
{
    uint32_t a, b, c;
    a = Rot_Right_n(x, 6);
    b = Rot_Right_n(x, 11);
    c = Rot_Right_n(x, 25);
    return (a ^ b ^ c);
}

uint32_t Ch(uint32_t a, uint32_t b, uint32_t c)
{
    return ((a & b) ^ (~a & c));
}

uint32_t Maj(uint32_t a, uint32_t b, uint32_t c)
{
    return ((a & b) ^ (a & c) ^ (b & c));
}

//================ FILE READ =================//
bool load_hex_file(const std::string &filename, uint32_t arr[], int size)
{
    std::ifstream file(filename);
    if (!file)
    {
        std::cerr << "Cannot open " << filename << "\n";
        return false;
    }

    std::string line;
    int i = 0;

    while (std::getline(file, line) && i < size)
    {
        arr[i] = std::stoul(line, nullptr, 16);
        i++;
    }

    file.close();

    if (i != size)
    {
        std::cerr << "Warning: expected " << size << " values, got " << i << "\n";
    }

    return true;
}

//================ PRINT =================//
void print_array(const std::string &name, uint32_t arr[], int start, int end)
{
    for (int i = start; i <= end; i++)
    {
        std::cout << name << "[" << std::dec << std::setw(3) << i << "] = 0x"
                  << std::hex << std::setw(8) << std::setfill('0')
                  << arr[i] << std::endl;
    }
}

//================ WRITE FILE =================//
bool write_W_to_file(const std::string &filename, uint32_t W[], int size)
{
    std::ofstream outfile(filename);
    if (!outfile)
    {
        std::cerr << "Cannot open " << filename << "\n";
        return false;
    }

    for (int i = 0; i < size; i++)
    {
        outfile << std::hex
                << std::setw(8)
                << std::setfill('0')
                << W[i] << "\n";
    }

    outfile.close();
    return true;
}

bool stringToHex (const std::string &filename_in, const std::string &filename_out) {
    std::ifstream inputFile(filename_in, std::ios::binary);
    std::ofstream outputFile(filename_out);
    if (!inputFile || !outputFile)
    {
        std::cerr << "Cannot open files\n";
        return false;
    }

    unsigned char buffer[4];
    uint64_t words_written = 0;
    
    inputFile.seekg(0, std::ios::end);
    uint64_t total_bytes = inputFile.tellg();
    uint64_t total_bits = total_bytes * 8;
    inputFile.seekg(0, std::ios::beg); 


    bool file_ended = false;

    while (!file_ended) {
        inputFile.read(reinterpret_cast<char*>(buffer), 4);
        std::streamsize bytesRead = inputFile.gcount();

        if (bytesRead == 4) {
            uint32_t word = 0;
            for (int i = 0; i < 4; ++i) {
                word |= (static_cast<uint32_t>(buffer[i]) << (8 * (3 - i)));
            }
            outputFile << std::setfill('0') << std::setw(8) << std::hex << std::uppercase << word << std::endl;
            words_written++;
        } 
        else {
            uint32_t word = 0;
            
            for (int i = 0; i < bytesRead; ++i) {
                word |= (static_cast<uint32_t>(buffer[i]) << (8 * (3 - i)));
            }
            // Padding bit 1 (0x80) 
            word |= (0x80 << (8 * (3 - bytesRead)));
            outputFile << std::setfill('0') << std::setw(8) << std::hex << std::uppercase << word << std::endl;
            words_written++;
            file_ended = true; 
        }
    }
    while ((words_written % 16) != 14) {
        outputFile << "00000000" << std::endl;
        words_written++;
    }
    
    uint32_t high_word = static_cast<uint32_t>(total_bits >> 32);
    uint32_t low_word = static_cast<uint32_t>(total_bits & 0xFFFFFFFF);
    outputFile << std::setfill('0') << std::setw(8) << std::hex << std::uppercase << high_word << std::endl;
    outputFile << std::setfill('0') << std::setw(8) << std::hex << std::uppercase << low_word;
    words_written += 2;
    std::cout << "Successful !!! Total lines written: " << std::dec << words_written << std::endl;
    inputFile.close();
    outputFile.close();
    return true;
}


int main()
{
    uint32_t W[64] = {0};
    uint32_t H[8]  = {0};
    uint32_t K[64] = {0};
    uint32_t T1, T2;
    std::cout << "\nPre-Processing\n";
    // if (!stringToHex("text.txt", "output.hex")) return 1;
    if (!stringToHex("text.txt", "input.txt")) return 1;
    if (!load_hex_file("input.txt", W, 16)) return 1;
    if (!load_hex_file("hash_init_value_input.txt", H, 8)) return 1;
    if (!load_hex_file("K_init_value_input.txt", K, 64)) return 1;

    // Print initial W
    std::cout << "Initial W[0..15]:\n";
    print_array("W", W, 0, 15);
    // Generate W[16..63]
    for (int t = 16; t < 64; t++)
    {
        W[t] = sigma_1_f(W[t - 2]) + W[t - 7]
             + sigma_0_f(W[t - 15]) + W[t - 16];
    }
    std::cout << "\nGenerated W[0..63]:\n";
    print_array("W", W, 0, 63);
    std::cout << "\nGenerated H[0..7]:\n";
    print_array("H", H, 0, 7);

    uint32_t a, b, c, d, e, f, g, h;
    a = H[0];
    b = H[1];
    c = H[2];
    d = H[3];
    e = H[4];
    f = H[5];
    g = H[6];
    h = H[7];

    for (int i = 0; i < 64; i++)
    {
        T1 = h + sigma_1_compression(e) + Ch(e, f, g) + K[i] + W[i];
        T2 = sigma_0_compression(a) + Maj(a, b, c);
        h = g;
        g = f;
        f = e;
        e = d + T1;
        d = c;
        c = b;
        b = a;
        a = T1 + T2;
        /*
        std::cout << "At cycle "
                    << std::dec 
                    << std::setw(2) 
                    << i
                    << " => T1 = "
                    << std::hex
                    << std::setw(8)
                    << std::setfill('0')
                    << T1
                    << " & T2 = "
                    << std::hex
                    << std::setw(8)
                    << std::setfill('0')
                    << T2 << std::endl;
        */
    }

    H[0] = H[0] + a;
    H[1] = H[1] + b;
    H[2] = H[2] + c;
    H[3] = H[3] + d;
    H[4] = H[4] + e;
    H[5] = H[5] + f;
    H[6] = H[6] + g;
    H[7] = H[7] + h;

    std::cout << "\nPrint Digest result\n";
    for (int i = 0; i < 8; i++)
    {
        std::cout << std::hex
                << std::setw(8)
                << std::setfill('0')
                << H[i];
    }
    std::cout << std::endl;

    std::cout << "\nCompare Digest result\n";
    std::stringstream ss;
    for (int i = 0; i < 8; i++)
    {
        ss << std::hex
        << std::setw(8)
        << std::setfill('0')
        << H[i];
    }

    std::string digest_calculation = ss.str();
    std::string digest_golden = "ed878761fb060ed7c836149beeda722c3d0e5a7d6dc0cd6a3bd92a2d46a6f72f";
    if (digest_calculation == digest_golden) {
        std::cout << "Pass";
    }
    else std::cout << "Failed";
    
    return 0;
}
