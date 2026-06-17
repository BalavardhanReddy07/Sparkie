


    get productOptions() {
     return this.products.map((item) => {
        // Step 1: Split off the Scheme Category (after " -- ")
        const mainParts = item.split(" -- ");
        const displayPart = mainParts[0] ? mainParts[0].trim() : item;
        const schemeCategory = mainParts[1] ? mainParts[1].trim() : "";

        // Step 2: displayPart is "AccountNumber - Designation" — use as-is for label
        const label = displayPart;

        return {
            label: label,
            value: schemeCategory
        };
    });
    }
