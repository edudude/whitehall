Given /^the organisation "([^"]*)" contains some policies$/ do |name|
  editions = Array.new(5) { build(:published_policy) } + Array.new(2) { build(:draft_policy) }
  create(:ministerial_department, name: name, editions: editions)
end

Given /^other organisations also have policies$/ do
  create(:organisation, editions: [build(:published_policy)])
  create(:organisation, editions: [build(:published_policy)])
end

Given /^the organisation "([^"]*)" exists$/ do |name|
  create(:ministerial_department, name: name)
end

Given /^the organisation "([^"]*)" is inactive/ do |name|
  organisation = Organisation.find_by_name(name) || create(:ministerial_department, name: name)
  organisation.update_column(:active, false)
end

Given /^two organisations "([^"]*)" and "([^"]*)" exist$/ do |first_organisation, second_organisation|
  create(:organisation, name: first_organisation)
  create(:organisation, name: second_organisation)
end

Given /^the "([^"]*)" organisation contains:$/ do |organisation_name, table|
  organisation = Organisation.find_by_name(organisation_name) || create(:ministerial_department, name: organisation_name)
  table.hashes.each do |row|
    person = find_or_create_person(row["Person"])
    ministerial_role = MinisterialRole.find_or_create_by_name(row["Ministerial Role"])
    organisation.ministerial_roles << ministerial_role
    create(:role_appointment, role: ministerial_role, person: person)
  end
end

Given /^the "([^"]*)" organisation is associated with several ministers and civil servants$/ do |organisation_name|
  organisation = Organisation.find_by_name(organisation_name) || create(:ministerial_department, name: organisation_name)
  3.times do |x|
    person = create(:person)
    ministerial_role = create(:ministerial_role, cabinet_member: (x == 1))
    organisation.ministerial_roles << ministerial_role
    create(:role_appointment, role: ministerial_role, person: person)
  end
  3.times do |x|
    person = create(:person)
    role = create(:board_member_role, permanent_secretary: (x == 1))
    organisation.roles << role
    create(:role_appointment, role: role, person: person)
  end
end

Given /^that "([^"]*)" is responsible for "([^"]*)" and "([^"]*)"$/ do |parent_org_name, child_org_1_name, child_org_2_name|
  child_organisations = [
    create(:organisation, name: child_org_1_name),
    create(:organisation, name: child_org_2_name)
  ]
  create(:ministerial_department, name: parent_org_name, child_organisations: child_organisations)
end

Given /^that "([^"]*)" is the responsibility of "([^"]*)" and "([^"]*)"$/ do |child_org_name, parent_org_1_name, parent_org_2_name|
  org_type = OrganisationType.find_or_create_by_name("Ministerial department")
  parent_org_1 = create(:organisation, name: parent_org_1_name, organisation_type: org_type)
  parent_org_2 = create(:organisation, name: parent_org_2_name, organisation_type: org_type)
  create(:organisation, name: child_org_name, parent_organisations: [parent_org_1, parent_org_2])
end

Given /^a submitted corporate publication "([^"]*)" about the "([^"]*)"$/ do |publication_title, organisation_name|
  organisation = Organisation.find_by_name(organisation_name)
  create(:submitted_corporate_publication, title: publication_title, organisations: [organisation])
end

Given /^the organisation "([^"]*)" is associated with consultations "([^"]*)" and "([^"]*)"$/ do |name, consultation_1, consultation_2|
  organisation = create(:organisation, name: name)
  create(:published_consultation, title: consultation_1, organisations: [organisation])
  create(:published_consultation, title: consultation_2, organisations: [organisation])
end

When /^I visit the "([^"]*)" organisation$/ do |name|
  visit_organisation name
end

When /^I visit the organisations page$/ do
  visit organisations_path
end

When /^I set the featured news articles in the "([^"]*)" organisation to:$/ do |name, table|
  organisation = Organisation.find_by_name!(name)
  visit admin_organisation_path(organisation)
  table.rows.each do |title|
    news_article = NewsArticle.find_by_title(title)
    within record_css_selector(news_article) do
      click_button "Feature"
    end
  end
end

When /^I order the featured items in the "([^"]*)" organisation as:$/ do |name, table|
  organisation = Organisation.find_by_name!(name)
  visit admin_organisation_path(organisation)
  table.rows.each_with_index do |(title), index|
    fill_in title, with: index
  end
  click_button "Save"
end

When /^I navigate to the "([^"]*)" organisation's (.*) page$/ do |organisation_name, page_name|
  navigate_to_organisation(page_name)
end

When /^I delete the organisation "([^"]*)"$/ do |name|
  organisation = Organisation.find_by_name!(name)
  visit edit_admin_organisation_path(organisation)
  click_button "delete"
end

Then /^there should not be an organisation called "([^"]*)"$/ do |name|
  refute Organisation.find_by_name(name)
end

Then /^I should see the top minister for the "([^"]*)" organisation$/ do |name|
  organisation = Organisation.find_by_name!(name)
  assert page.has_css?(record_css_selector(organisation.top_ministerial_role))
end

Then /^I should see the top civil servant for the "([^"]*)" organisation$/ do |name|
  organisation = Organisation.find_by_name!(name)
  assert page.has_css?(record_css_selector(organisation.top_civil_servant))
end

Then /^I should be able to view all ministers for the "([^"]*)" organisation on a separate page$/ do |name|
  organisation = Organisation.find_by_name!(name)
  navigate_to_organisation('Ministers')
  organisation.ministerial_roles.each do |role|
    assert page.has_css?(record_css_selector(role))
  end
end

Then /^I should see the featured news articles in the "([^"]*)" organisation are:$/ do |name, expected_table|
  visit_organisation name
  rows = find(featured_news_articles_selector).all('.news_article')
  table = rows.map { |r| r.all('a.title').map { |c| c.text.strip } }
  expected_table.diff!(table)
end

Then /^I should only see published policies belonging to the "([^"]*)" organisation$/ do |name|
  organisation = Organisation.find_by_name!(name)
  editions = records_from_elements(Edition, page.all(".document"))
  assert editions.all? { |edition| organisation.editions.published.include?(edition) }
end

Then /^I should see "([^"]*)" has the "([^"]*)" ministerial role$/ do |person_name, role_name|
  person = find_person(person_name)
  ministerial_role = person.current_ministerial_roles.find_by_name!(role_name)
  assert page.has_css?(".ministerial_role", text: ministerial_role.name)
  assert page.has_css?(".ministerial_role .current_appointee", text: person.name)
end

Then /^I should see that "([^"]*)" is responsible for "([^"]*)"$/ do |parent_org_name, child_org_name|
  child_org = Organisation.find_by_name!(child_org_name)
  assert page.has_css?("#child_organisations #{record_css_selector(child_org)}")
end

Then /^I should see that "([^"]*)" is the responsibility of "([^"]*)"$/ do |child_org_name, parent_org_name|
  parent_org = Organisation.find_by_name!(parent_org_name)
  assert page.has_css?(".parent_organisations a[href='#{organisation_path(parent_org)}']")
end

Then /^I should see the following speeches are associated with the "([^"]*)" organisation:$/ do |name, table|
  table.hashes.each do |row|
    assert page.has_css?("#speeches .speech .title", row["Title"])
  end
end

Then /^I should see the organisation navigation$/ do
  assert page.has_css?('.organisation nav')
end

Then /^I should see the "([^"]*)" organisation's (.*) page$/ do |organisation_name, page_name|
  title =
    case page_name
    when 'about'    then "About"
    when 'news'     then "News"
    when 'home'     then organisation_name
    when 'policies' then  "Policies"
    when 'publications' then "Publications"
    end

  assert page.has_css?('title', text: title)
end

Then /^I should see an organisation called "([^"]*)"$/ do |name|
  assert page.has_css?(".organisation", text: name)
end

Then /^I should not see a link to the organisation called "([^"]*)"$/ do |text|
  refute page.has_css?(".organisation a", text: text)
end

def navigate_to_organisation(page_name)
  within('nav.sub_navigation') do
    click_link page_name
  end
end
