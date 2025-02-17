require 'rails_helper'

feature "Touchpoints", js: true do
  let(:organization) { FactoryBot.create(:organization) }

  context "as Admin" do
    let!(:user) { FactoryBot.create(:user, :admin, organization: organization) }
    let!(:form) { FactoryBot.create(:form, :open_ended_form, organization: organization, user: user) }

    describe "/touchpoints" do
      context "default success text" do
        before do
          visit touchpoint_path(form)
          expect(page.current_path).to eq("/touchpoints/#{form.short_uuid}/submit")
          expect(page).to have_content("OMB Approval ##{form.omb_approval_number}")
          expect(page).to have_content("Expiration Date #{form.expiration_date.strftime("%m/%d/%Y")}")
          fill_in("answer_01", with: "User feedback")
          click_button "Submit"
        end

        describe "display default success text" do
          it "renders success flash message" do
            expect(page).to have_content("Thank you. Your feedback has been received.")
            expect(page.current_path).to eq("/touchpoints/#{form.short_uuid}/submit") # stays on
          end
        end
      end

      context "SPAMBOT" do
        before do
          visit touchpoint_path(form)
          page.execute_script("$('#fba_directive').val('SPAM Text')")
          click_button "Submit"
        end

        it "fails the submission" do
          expect(page).to have_content("this submission was not successful")
          expect(page.current_path).to eq("/touchpoints/#{form.short_uuid}/submit") # stays on
        end

      end

      context "custom success text" do
        before do
          form.update(success_text: "Much success. \n With a second line.")
          form.reload
          visit touchpoint_path(form)
          expect(page.current_path).to eq("/touchpoints/#{form.short_uuid}/submit")
          expect(page).to have_content("OMB Approval ##{form.omb_approval_number}")
          expect(page).to have_content("Expiration Date #{form.expiration_date.strftime("%m/%d/%Y")}")
          fill_in("answer_01", with: "User feedback")
          click_button "Submit"
        end

        describe "display custom success text" do
          it "renders success flash message" do
            expect(page).to have_text(form.success_text.gsub("\n ", "")) # convert the line break and following space to html text
            expect(page.current_path).to eq("/touchpoints/#{form.short_uuid}/submit") # stays on same page
          end
        end
      end
    end

    describe "checkbox question" do
      let!(:checkbox_form) { FactoryBot.create(:form, :checkbox_form, organization: organization, user: user) }

      before do
        visit touchpoint_path(checkbox_form)
        all('.usa-checkbox__label').each do |checkbox_label|
          checkbox_label.click
        end
        click_on "Submit"
      end

      it "persists checkbox question values to db as comma separated list" do
        expect(page).to have_content("Thank you. Your feedback has been received.")
        expect(Submission.last.answer_03).to eq "One,Two,Three,Four"
      end

      context "with an question option of 'other'" do
        before do
          checkbox_form.questions.first.question_options.create!(text: "other", position: 5)
          checkbox_form.questions.first.question_options.create!(text: "otro", position: 6)
          visit touchpoint_path(checkbox_form)
        end

        context "default 'other' value" do
          before do
            all('.usa-checkbox__label').each do |checkbox_label|
              checkbox_label.click
            end
            click_on "Submit"
          end

          it "persists 'other' checkbox question default values to db as comma separated list" do
            expect(page).to have_content("Thank you. Your feedback has been received.")
            expect(Submission.last.answer_03).to eq "One,Two,Three,Four,other,otro"
          end
        end

        context "user-entered 'other' value" do
          before do
            all('.usa-checkbox__label').each do |checkbox_label|
              checkbox_label.click
            end

            inputs = find_all("input")
            inputs.first.set("hi")
            inputs.last.set("bye")
            click_on "Submit"
          end

          it "persists 'other' checkbox question custom values to db as comma separated list" do
            expect(page).to have_content("Thank you. Your feedback has been received.")
            expect(Submission.last.answer_03).to eq "One,Two,Three,Four,hi,bye"
          end
        end
      end

    end

    describe "radio buttons question" do
      let!(:radio_button_form) { FactoryBot.create(:form, :radio_button_form, organization: organization, user: user) }
      let!(:last_radio_option) {radio_button_form.questions.first.question_options.create!(text: 'other', value: 'other', position: 6)}

      before do
        visit touchpoint_path(radio_button_form)
        all('.usa-radio__label').each do |radio_button_label|
          radio_button_label.click
        end
        click_on "Submit"
      end

      it "persists radio button question values to db" do
        expect(page).to have_content("Thank you. Your feedback has been received.")
        # implicitly test radio options
        expect(Submission.last.answer_03).to eq last_radio_option.value
        # explicitly test that the default "other" value works (separately from the input box)
        expect(Submission.last.answer_03).to eq "other"
      end

      context "with an question option of 'other'" do
        context "user-entered 'other' value" do
          before do
            visit touchpoint_path(radio_button_form)
            all('.usa-radio__label').each do |radio_label|
              radio_label.click
            end

            inputs = find_all("input")
            inputs.first.set("hi")
            inputs.last.set("bye")
            click_on "Submit"
          end

          it "persists 'other' checkbox question custom values to db as comma separated list" do
            expect(page).to have_content("Thank you. Your feedback has been received.")
            expect(Submission.last.answer_03).to eq "bye"
          end
        end
      end
    end

    describe "states dropdown question" do
      let!(:dropdown_form) { FactoryBot.create(:form, :states_dropdown_form, organization: organization, user: user) }

      before do
        visit touchpoint_path(dropdown_form)
        select("CA", from: "answer_03")
        click_on "Submit"
      end

      it "persists question values to db" do
        expect(page).to have_content("Thank you. Your feedback has been received.")
        expect(Submission.last.answer_03).to eq "CA"
      end

      context "when required" do
        before do
          dropdown_form.questions.first.update(is_required: true)
          visit touchpoint_path(dropdown_form)
        end

        it "display flash message" do
          click_on "Submit"
          expect(page).to have_content("You must respond to question:")
        end
      end
    end

    describe "phone number question" do
      let!(:dropdown_form) { FactoryBot.create(:form, :phone, organization: organization, user: user) }

      before do
        visit touchpoint_path(dropdown_form)
      end

      it "allows numeric input and a maximum of 10 numbers" do
        fill_in "answer_03", with: "12345678901234"
        expect(find("#answer_03").value).to eq("(123) 456-7890")
      end

      it "disallows text input" do
        fill_in "answer_03", with: "abc"
        expect(find("#answer_03").value).to eq("")
      end
    end

    describe "hidden_field question" do

      let!(:hidden_field_form) { FactoryBot.create(:form, :hidden_field_form, organization: organization, user: user) }

      context "render" do
        before do
          visit submit_touchpoint_path(hidden_field_form)
        end

        it "generates hidden field" do
          expect(find("#answer_01", :visible => false).value).to eq("hidden value")
        end
      end

      context "submit" do
        before do
          visit touchpoint_path(hidden_field_form)
          click_button "Submit"
        end

        it "persists the hidden field" do
          expect(page).to have_content("Thank you. Your feedback has been received.")
          expect(Submission.last.answer_01).to eq "hidden value"
        end
      end
    end

    describe "email question" do
      let!(:dropdown_form) { FactoryBot.create(:form, :email, organization: organization, user: user) }

      before do
        visit touchpoint_path(dropdown_form)
      end

      it "allows valid email address" do
        fill_in "answer_03", with: "test@test.com"
        find("#answer_03").native.send_key :tab
        expect(find("#answer_03").value).to eq("test@test.com")
      end

      it "disallows invalid text input" do
        fill_in "answer_03", with: "test@testcom"
        find("#answer_03").native.send_key :tab
        expect(page).to have_content("Please enter a valid email")
      end
    end

    describe "required question" do
      before do
        form.questions.first.update(is_required: true)
        visit touchpoint_path(form)
        click_on "Submit"
      end

      it "displays an error message" do
        expect(page).to have_content("You must respond to question: Test Open Area")
      end

      it "regression: does not display invisible error message inputs" do
        expect(page).to have_no_css("input", visible: true)
      end

      it "can successfully submit after completing the required question" do
        fill_in("answer_01", with: "a response to this required question")
        find(".submit_form_button").click
        expect(page).to have_content("Thank you. Your feedback has been received.")
      end
    end

    describe "character_limit" do
      before do
        question = form.questions.first
        question.update(character_limit: 150)
        visit touchpoint_path(form)
        expect(page.current_path).to eq("/touchpoints/#{form.short_uuid}/submit")
        expect(page).to have_content("OMB Approval ##{form.omb_approval_number}")
        expect(page).to have_content("Expiration Date #{form.expiration_date.strftime("%m/%d/%Y")}")
        fill_in("answer_01", with: "T" * 145)
      end

      describe "character counter" do
        it "updates character count" do
          expect(page).to have_content("5 characters left")
        end
      end
    end

    describe "/touchpoints?location_code=" do
      before do
        visit submit_touchpoint_path(form, location_code: "TEST_LOCATION_CODE")
        fill_in("answer_01", with: "User feedback")
        click_button "Submit"
      end

      describe "#show" do
        it "renders success flash message and persists location_code" do
          expect(page).to have_content("Thank you. Your feedback has been received.")
          expect(page).to have_current_path("/touchpoints/#{form.short_uuid}/submit?location_code=TEST_LOCATION_CODE") # stays on same page after form submission

          # Asserting against the database/model directly here isn't ideal.
          # An alternative is to send location_code back to the client and assert against it
          expect(Submission.last.location_code).to eq "TEST_LOCATION_CODE"
        end
      end
    end

    describe "A-11 Version 2 Form" do
      let!(:custom_form) { FactoryBot.create(:form, :a11_v2, organization: organization, user: user) }

      before do
        visit submit_touchpoint_path(custom_form)
        find("label[for='star4']").click
        # fill_in("answer_02", with: "User feedback")
        fill_in("answer_03", with: "User feedback")
        click_button "Submit"
      end

      it "" do
        expect(page).to have_content("Thank you. Your feedback has been received.")

        # Asserting against the database/model directly here isn't ideal.
        # An alternative is to send location_code back to the client and assert against it
        last_submission = Submission.last
        expect(last_submission.answer_01).to eq "4"
        # expect(last_submission.answer_02).to eq "TEST_LOCATION_CODE"
        expect(last_submission.answer_03).to eq "User feedback"
      end
    end
  end

  context "as public user" do
    let!(:admin) { FactoryBot.create(:user, :admin, organization: organization) }

    describe "/touchpoints" do
      let!(:form) { FactoryBot.create(:form, :open_ended_form, organization: organization, user: admin, aasm_state: 'in_development') }

      context "for an in_development form" do
        before do
          visit touchpoint_path(form)
        end

        it "redirect to index and display a flash message" do
          expect(page).to have_content("Form is not currently deployed.")
          expect(page.current_path).to eq(index_path)
        end
      end
    end

    describe "/touchpoints" do
      let!(:form) { FactoryBot.create(:form, :open_ended_form, organization: organization, user: admin, aasm_state: 'archived') }

      context "for an archived form" do
        before do
          visit touchpoint_path(form)
        end

        it "render archived/inactive message" do
          expect(page).to have_content("This form is not currently accepting feedback")
          expect(page).to have_content(form.title)
          expect(page.current_path).to eq(submit_touchpoint_path(form))
        end
      end
    end

    describe "/touchpoints" do
      let!(:form) { FactoryBot.create(:form, :open_ended_form, organization: organization, user: admin, aasm_state: 'live') }

      context "for a live form" do
        before do
          visit touchpoint_path(form)
        end

        it "render the form" do
          expect(page).to have_css(".touchpoint-form")
          expect(page).to have_content(form.title)
        end
      end
    end
  end
end
