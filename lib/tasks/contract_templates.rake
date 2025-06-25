namespace :contracts do
  desc "Create contract templates in the DB"
  task create_templates: :environment do
    Contract.contract_templates.each do |tpl|
      Contract.create!(
        name: tpl[:name],
        description: tpl[:description],
        contract_type: Contract.contract_types[tpl[:contract_type]],
        category: Contract.categories[tpl[:category]],
        content: tpl[:template],
        status: :draft,
        action: 'draft',
        date_created: Date.today
      )
      puts "Created template: #{tpl[:name]}"
    end
  end
end