import { application } from "./application"
import EstimateItemsController from "./estimate_items_controller"
import DismissibleController from "./dismissible_controller"
import StarRatingController from "./star_rating_controller"
import PhotoUploadController from "./photo_upload_controller"
import InsuranceFormController from "./insurance_form_controller"
import MobileMenuController from "./mobile_menu_controller"
import FormValidationController from "./form_validation_controller"
import ToastController from "./toast_controller"
import ToggleController from "./toggle_controller"
import BottomSheetController from "./bottom_sheet_controller"
import TabController from "./tab_controller"
import ScrollRevealController from "./scroll_reveal_controller"
import NativeBridgeController from "./native_bridge_controller"
import CheckWizardController from "./check_wizard_controller"
import FileCounterController from "./file_counter_controller"
import AddressSearchController from "./address_search_controller"

application.register("estimate-items", EstimateItemsController)
application.register("dismissible", DismissibleController)
application.register("star-rating", StarRatingController)
application.register("photo-upload", PhotoUploadController)
application.register("insurance-form", InsuranceFormController)
application.register("mobile-menu", MobileMenuController)
application.register("form-validation", FormValidationController)
application.register("toast", ToastController)
application.register("toggle", ToggleController)
application.register("bottom-sheet", BottomSheetController)
application.register("tab", TabController)
application.register("scroll-reveal", ScrollRevealController)
application.register("native-bridge", NativeBridgeController)
application.register("check-wizard", CheckWizardController)
application.register("file-counter", FileCounterController)
application.register("address-search", AddressSearchController)
