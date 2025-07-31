persons = [
    30,  # youxam
    16,  # xy
    19,  # hhy
    19,  # hh
]

total = 810 + 68 / 9 * 4

for person in persons:
    print(person, person / sum(persons) * total)
