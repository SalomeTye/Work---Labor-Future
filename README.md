A blockchain-powered platform that protects gig workers and freelancers from wage theft, unfair contracts, and lack of protections through smart contract automation.

## ✨ Key Features

- 🔒 **Escrow Protection**: Guaranteed payments through smart contract escrow
- 📝 **Immutable Work History**: Permanent records of all work completed
- 🛡️ **Micro-Insurance**: Built-in insurance fund for worker protection
- ⚖️ **Dispute Resolution**: Fair arbitration system for contract disputes
- 🏆 **Reputation System**: Build trust through transparent scoring

## 🚀 Getting Started

### Prerequisites

- Clarinet CLI installed
- STX testnet tokens for testing

### Installation

1. Clone the repository
2. Navigate to project directory
3. Run `clarinet console` to start testing

## 📋 Usage Instructions

### For Workers 👷‍♀️

1. **Register as Worker**
   ```clarity
   (contract-call? .Work---Labor-Future register-worker)
   ```

2. **Complete Work**
   ```clarity
   (contract-call? .Work---Labor-Future complete-work u1)
   ```

3. **Claim Insurance (if needed)**
   ```clarity
   (contract-call? .Work---Labor-Future claim-insurance u1 "Contract violation")
   ```

### For Clients 👔

1. **Register as Client**
   ```clarity
   (contract-call? .Work---Labor-Future register-client)
   ```

2. **Create Work Contract**
   ```clarity
   (contract-call? .Work---Labor-Future create-work-contract 'ST1WORKER... u1000000 "Website development")
   ```

3. **Approve Completed Work**
   ```clarity
   (contract-call? .Work---Labor-Future approve-work u1)
   ```

### Dispute Management ⚖️

1. **Raise Dispute**
   ```clarity
   (contract-call? .Work---Labor-Future raise-dispute u1 "Work not delivered as specified")
   ```

2. **Platform Admin Resolution**
   ```clarity
   (contract-call? .Work---Labor-Future resolve-dispute u1 true)
   ```

## 🔍 Contract Features

### Payment Protection 💰
- All payments held in escrow until work completion
- Automatic release upon approval or dispute resolution
- 5% insurance contribution for worker protection fund
- 2% platform fee for operations

### Work History Tracking 📊
- Immutable record of all contracts and completions
- Reputation scoring based on successful deliveries
- Transparent work history for both parties

### Insurance System 🛡️
- Workers contribute to collective insurance fund
- Claims available for contract violations or non-payment
- Platform-administered claim approval process

## 🎛️ Read-Only Functions

- `get-worker-profile`: View worker stats and reputation
- `get-client-profile`: View client spending and reputation
- `get-work-contract`: Check contract details and status
- `get-escrow-balance`: View escrowed funds for a contract
- `get-dispute`: Check dispute status and details
- `get-insurance-claim`: View insurance claim information
- `get-insurance-fund-balance`: Total insurance fund available

## ⚠️ Error Codes

- `u100`: Not authorized for this action
- `u101`: Record already exists
- `u102`: Record not found
- `u103`: Invalid amount specified
- `u104`: Insufficient balance
- `u105`: Work not completed yet
- `u106`: Work already completed
- `u107`: Dispute already exists
- `u108`: Invalid status for operation

## 🛠️ Testing

Run the test suite:
```bash
clarinet test
```

## 🤝 Contributing

1. Fork the repository
2. Create feature branch
3. Commit changes
4. Push to branch
5. Open Pull Request

## 📜 License

MIT License - see LICENSE file for details

## 🌟 Future Enhancements

- Multi-sig dispute resolution
- Tiered insurance premiums
- Cross-chain payment support
- Mobile app integration
- Advanced reputation algorithms

---

Built with ❤️ for the future of work

## 🆕 Recent Enhancements

### Worker Profile Status Toggle 🔄
Empowers registered workers to dynamically control their availability status on the platform. This feature allows workers to toggle between active and inactive states, providing greater flexibility in managing their professional engagement.

**Usage for Workers:**
4. **Toggle Availability Status**
   ```clarity
   (contract-call? .Work---Labor-Future toggle-worker-status)
   ```

**Benefits:**
- Enhanced worker autonomy and control over availability
- Improved client experience by filtering available workers
- Streamlined platform operations with real-time status updates
- Minimal gas costs for status changes

### Milestone-Based Payments 📈
Revolutionizes project management by enabling phased payment structures that align with project progress. This innovative approach allows clients to define specific deliverables and release payments incrementally, fostering trust and reducing financial risk for both parties.

**Usage for Clients:**
4. **Add Milestone to Contract**
   ```clarity
   (contract-call? .Work---Labor-Future add-milestone u1 "Design phase completed" u500000)
   ```

**Usage for Workers:**
4. **Complete Milestone**
   ```clarity
   (contract-call? .Work---Labor-Future complete-milestone u1 u1)
   ```

**Usage for Clients:**
5. **Approve Milestone Payment**
   ```clarity
   (contract-call? .Work---Labor-Future approve-milestone u1 u1)
   ```

**Benefits:**
- Granular project tracking with clear deliverable checkpoints
- Reduced financial exposure through incremental payment releases
- Enhanced project transparency and accountability
- Flexible payment structures for complex, multi-stage projects
- Improved cash flow management for both clients and workers

### Contract Cancellation Mechanism 🛑
Introduces a flexible exit strategy for clients, enabling them to terminate active contracts before completion while maintaining platform integrity. This feature provides clients with the autonomy to cancel engagements that no longer align with their needs, with a structured penalty system that protects worker interests and platform sustainability.

**Usage for Clients:**
6. **Cancel Active Contract**
   ```clarity
   (contract-call? .Work---Labor-Future cancel-work-contract u1)
   ```

**Benefits:**
- Empowers clients with decision-making flexibility during project lifecycles
- Implements fair penalty structure (10% cancellation fee) to discourage frivolous terminations
- Protects worker expectations by preventing arbitrary contract abandonment
- Maintains escrow security with controlled fund release mechanisms
- Enhances platform trust through transparent cancellation protocols
- Reduces administrative overhead by automating contract termination processes
