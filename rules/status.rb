#!/usr/bin/env ruby

require 'set'

# Get status of the extra container images (in deploy/containers/)
def status_containers
    hashes = Hash.new
    `git ls-tree -z HEAD deploy/containers/`.each_line("\0", chomp: true) do |line|
        line, _, path = line.partition("\t")
        _, type, hash = line.split
        next unless type == 'tree'
        name = path.split('/')[2] # drop deploy/containers/ prefix
        hashes[name] = hash
    end
    dirty = Set.new
    `git status -z deploy/containers/`.each_line("\0", chomp: true) do |line|
        name = line[3..-1].split('/')[2]
        dirty << name
    end

    results = Hash.new
    hashes.each_pair do |key, value|
        name = "STABLE_CONTAINERS_#{key.upcase}"
        if dirty.include? key
            results[name] = "#{value}-dirty"
            results["#{name}_PULL_POLICY"] = 'Always'
        else
            results[name] = value
        end
    end
    results
end

results = Hash.new
results.update status_containers
results.each_pair do |key, value|
    puts "#{key.upcase.tr('^A-Z', '_')} #{value}"
end
