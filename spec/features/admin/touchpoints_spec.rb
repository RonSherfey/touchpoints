require 'rails_helper'

feature "Touchpoints", js: true do
  context "as Admin" do
    describe "/touchpoints" do
      describe "#index" do
        let(:user) { FactoryBot.create(:user, :admin) }
        let!(:organization) { FactoryBot.create(:organization) }
        let!(:container) { FactoryBot.create(:container) }
        let!(:form) { FactoryBot.create(:form) }
        let(:future_date) {
          Time.now + 3.days
        }

        before "user creates a Touchpoint" do
          login_as user
          visit new_admin_touchpoint_path
          fill_in("touchpoint[name]", with: "Test Touchpoint")
          select(container.service.name, from: "touchpoint[service_id]")
          select(container.name, from: "touchpoint[container_id]")

          # FIXME
          # this is non-conventional, because USWDS hides inputs and uses CSS :before
          first("label[for=touchpoint_form_id_1]").click
          fill_in("touchpoint[purpose]", with: "Compliance")
          fill_in("touchpoint[expiration_date]", with: future_date.strftime("%m/%d/%Y"))
          fill_in("touchpoint[omb_approval_number]", with: "12345")
          fill_in("touchpoint[meaningful_response_size]", with: 50)
          fill_in("touchpoint[behavior_change]", with: "to be determined")
          fill_in("touchpoint[notification_emails]", with: "admin@example.gov")
          click_button "Create Touchpoint"
        end

        it "redirect to /touchpoints/:id with a success flash message" do
          expect(page.current_path).to eq(admin_touchpoint_path(Touchpoint.first.id))
          expect(page).to have_content("Touchpoint was successfully created.")
          expect(page).to have_content(future_date.to_date.to_s)
          expect(page).to have_content("Notification emails: admin@example.gov")
          expect(page).to have_content("12345")
        end
      end

      describe "#edit" do
        let(:user) { FactoryBot.create(:user, :admin) }
        let!(:organization) { FactoryBot.create(:organization) }
        let!(:container) { FactoryBot.create(:container) }
        let!(:touchpoint) { FactoryBot.create(:touchpoint, container: container)}
        let!(:form) { FactoryBot.create(:form) }

        before "user creates a Touchpoint" do
          login_as user
          visit edit_admin_touchpoint_path(touchpoint.id)
          fill_in("touchpoint[name]", with: "New Name")
          click_button "Update Touchpoint"
        end

        it "redirect to /touchpoints/:id with a success flash message" do
          expect(page.current_path).to eq(admin_touchpoint_path(touchpoint.id))
          expect(page).to have_content("Touchpoint was successfully updated.")
          expect(page).to have_content("New Name")
        end
      end
    end
  end

  context "as Webmaster" do
    describe "/touchpoints" do
      describe "#index" do
        let!(:organization) { FactoryBot.create(:organization) }
        let!(:container) { FactoryBot.create(:container) }
        let(:user) { FactoryBot.create(:user, :admin, organization: organization) }
        let!(:form) { FactoryBot.create(:form) }

        before "user completes (TEST) Sign Up form" do
          login_as user
          visit new_admin_touchpoint_path
          fill_in("touchpoint[name]", with: "Test Touchpoint")
          select(container.service.name, from: "touchpoint[service_id]")
          select(container.name, from: "touchpoint[container_id]")

          # FIXME
          # this is non-conventional, because USWDS hides inputs and uses CSS :before
          first("label[for=touchpoint_form_id_1]").click
          fill_in("touchpoint[purpose]", with: "Compliance")
          fill_in("touchpoint[meaningful_response_size]", with: 50)
          fill_in("touchpoint[behavior_change]", with: "to be determined")
          fill_in("touchpoint[notification_emails]", with: "admin@example.gov")
          click_button "Create Touchpoint"
        end

        it "redirect to /touchpoints/:id with a success flash message" do
          expect(page.current_path).to eq(admin_touchpoint_path(Touchpoint.first.id))
          expect(page).to have_content("Touchpoint was successfully created.")

          expect(page).to have_content("Notification emails: admin@example.gov")
        end
      end
    end
  end
end
