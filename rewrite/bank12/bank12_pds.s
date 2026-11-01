end_of_bank12_data:
BANK_12_SIZE = $C000 - end_of_bank12_data
bank12_size_word:
.byte >(BANK_12_SIZE)
.byte <(BANK_12_SIZE)
