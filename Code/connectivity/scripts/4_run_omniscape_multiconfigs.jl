##Running multiple Omniscape configuration files

using Pkg; Pkg.add("Glob")

using Omniscape 
using Glob

# Directory containing the configuration files
config_dir = "/Data/Connectivity_Data/data/omni_config"

# Identify all files ending with ".ini in the directory
config_files = glob("*.ini", config_dir)

# Print the identified files (optional)
println("Configuration files found:")
println(config_files)

# Loop through each configuration file and run Omniscape
for config_file in config_files
    println("Processing configuration file: $config_file")
    try
        run_omniscape(config_file)  # Run the configuration file
        println("Successfully processed: $config_file")
    catch e
        println("Error processing $config_file: $e")
    end
end
