["Prime Minister, First Lord of the Treasury and Minister for the Civil Service",
"Deputy Prime Minister and Lord President of the Council",
"First Secretary of State and Secretary of State for Foreign and Commonwealth Affairs",
"Chancellor of the Exchequer",
"Chief Secretary to the Treasury",
"Secretary of State for the Home Department",
"Secretary of State for Defence",
"Secretary of State for Business, Innovation and Skills and President of the Board of Trade",
"Secretary of State for Work and Pensions",
"Lord Chancellor and Secretary of State for Justice",
"Secretary of State for Education",
"Secretary of State for Communities and Local Government",
"Secretary of State for Health",
"Secretary of State for Environment, Food and Rural Affairs",
"Secretary of State for International Development",
"Secretary of State for Scotland",
"Secretary of State for Energy and Climate Change",
"Secretary of State for Transport",
"Secretary of State for Culture, Media and Sport",
"Secretary of State for Northern Ireland",
"Secretary of State for Wales",
"Leader of the House of Lords and Chancellor of the Duchy of Lancaster",
"Chairman of the Conservative Party"].each_with_index do |name, i|
  Role.where(name: name).update_all seniority: i
end
