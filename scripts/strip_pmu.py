
import sys

def remove_pmu_nodes(filename):
    with open(filename, 'r') as f:
        lines = f.readlines()

    output = []
    skip_until = None
    brace_count = 0
    
    # Nodes we want to excise completely
    nodes_to_remove = [
        "pmu@0", 
        "rp_memory_slave_pmu@0", 
        "rp_gpio_pmu_intr@0", 
        "rp_gpio_pmu@0",
        "lmb_pmu@0"
    ]

    for line in lines:
        if skip_until:
            brace_count += line.count('{')
            brace_count -= line.count('}')
            if brace_count <= 0:
                skip_until = None
            continue

        skip = False
        for node in nodes_to_remove:
            if node + " {" in line:
                skip_until = node
                brace_count = 1
                skip = True
                break
        
        if not skip:
            output.append(line)

    with open(filename, 'w') as f:
        f.writelines(output)
    print(f"Patched {filename} successfully.")

if __name__ == "__main__":
    if len(sys.argv) > 1:
        remove_pmu_nodes(sys.argv[1])
