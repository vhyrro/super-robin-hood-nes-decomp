end_of_bank13_data:
BANK_13_SIZE = 49152 - end_of_bank13_data
bank13_size_word:
.byte >(BANK_13_SIZE)
.byte <(BANK_13_SIZE)